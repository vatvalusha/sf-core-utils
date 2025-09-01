/**
 * @description Default implementation of the RetentionStrategy interface that handles
 * standard Salesforce objects for data retention processing. This strategy provides
 * dynamic SOQL query building and supports simulate, soft delete, and hard delete modes.
 * 
 * This implementation uses the existing DmlResultService for consistent error handling
 * and leverages WITH SECURITY_ENFORCED for proper permission checks during queries.
 * 
 * Special handling is provided for Files (ContentDocument/ContentVersion) and legacy
 * Attachments when the appropriate flags are set in the retention configuration.
 * 
 * @author Valerii Artemenko
 * @version 1.0
 * @since 2025-01-28
 */
public with sharing class DefaultRetentionStrategy implements RetentionStrategy {

    /**
     * @description Builds a Database.QueryLocator for identifying records eligible for deletion
     * @param retentionConfig Retention rule configuration
     * @param cutoffDate Records older than this date are eligible for deletion
     * @return Database.QueryLocator for batch processing
     */
    public Database.QueryLocator buildQuery(Retention__c retentionConfig, Datetime cutoffDate) {
        if (retentionConfig == null) {
            throw new IllegalArgumentException('Retention configuration cannot be null');
        }

        if (String.isBlank(retentionConfig.TargetObject__c)) {
            throw new IllegalArgumentException('Target object must be specified');
        }

        String objectApiName = retentionConfig.TargetObject__c.trim();
        String dateField = String.isNotBlank(retentionConfig.DateFieldAPI__c)
                ? retentionConfig.DateFieldAPI__c.trim()
                : Constants.DEFAULT_DATE_FIELD;

        // Build dynamic SOQL query
        String soqlQuery = 'SELECT Id, ' + dateField + ' FROM ' + objectApiName;

        // Add WHERE clause for date filter
        soqlQuery += ' WHERE ' + dateField + ' < :cutoffDate';

        // Add additional filter conditions if provided
        if (String.isNotBlank(retentionConfig.FilterCondition__c)) {
            String filterCondition = retentionConfig.FilterCondition__c.trim();
            // Ensure the filter doesn't start with AND/OR
            if (!filterCondition.toUpperCase().startsWith('AND ') &&
                    !filterCondition.toUpperCase().startsWith('OR ')) {
                soqlQuery += ' AND (' + filterCondition + ')';
            } else {
                soqlQuery += ' ' + filterCondition;
            }
        }

        // Add limit if specified
        if (retentionConfig.RecordLimitPerRun__c != null && retentionConfig.RecordLimitPerRun__c > 0) {
            soqlQuery += ' LIMIT ' + Integer.valueOf(retentionConfig.RecordLimitPerRun__c);
        }

        // Add security enforcement
        soqlQuery += ' WITH SECURITY_ENFORCED';

        try {
            return Database.getQueryLocator(soqlQuery);
        } catch (Exception e) {
            throw new IllegalArgumentException(
                    'Failed to build query for object ' + objectApiName + ': ' + e.getMessage()
            );
        }
    }

    /**
     * @description Processes a batch scope of records according to retention configuration
     * @param retentionConfig Configuration specifying how to process records
     * @param scope List of records to process
     * @return DeleteResultSummary Summary of processing results
     */
    public DeleteResultSummary processScope(Retention__c retentionConfig, List<SObject> scope) {
        if (retentionConfig == null) {
            throw new IllegalArgumentException('Retention configuration cannot be null');
        }

        if (scope == null || scope.isEmpty()) {
            return new DeleteResultSummary(0, retentionConfig.TargetObject__c, getActionType(retentionConfig));
        }

        String actionType = getActionType(retentionConfig);
        DeleteResultSummary summary = new DeleteResultSummary(
                scope.size(),
                retentionConfig.TargetObject__c,
                actionType
        );

        // Handle simulation mode
        if (retentionConfig.Simulate__c == true) {
            return processSimulation(scope, summary);
        }

        // Handle actual deletion
        return processActualDeletion(retentionConfig, scope, summary);
    }

    /**
     * @description Validates retention configuration for compatibility with this strategy
     * @param retentionConfig Configuration to validate
     * @return Boolean True if configuration is valid
     */
    public Boolean validateConfiguration(Retention__c retentionConfig) {
        System.debug('*** retentionConfig: ' + JSON.serialize(retentionConfig));
        if (retentionConfig == null || String.isBlank(retentionConfig.TargetObject__c)) {
            return false;
        }
        System.debug('*** AFTER ****');

        // Check if object exists in schema
        String objectApiName = retentionConfig.TargetObject__c.trim();
        System.debug('*** objectApiName: ' + objectApiName);
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

        if (!globalDescribe.containsKey(objectApiName)) {
            return false;
        }

        // Validate date field if specified
        String dateField = String.isNotBlank(retentionConfig.DateFieldAPI__c)
                ? retentionConfig.DateFieldAPI__c.trim()
                : Constants.DEFAULT_DATE_FIELD;

        System.debug('*** dateField: ' + dateField);

        try {
            Schema.SObjectType objectType = globalDescribe.get(objectApiName);
            Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();

            if (!fieldMap.containsKey(dateField.toLowerCase())) {
                return false;
            }

            // Verify the field is a date or datetime field
            Schema.DisplayType fieldType = fieldMap.get(dateField.toLowerCase()).getDescribe().getType();
            if (fieldType != Schema.DisplayType.Date && fieldType != Schema.DisplayType.DateTime) {
                return false;
            }
        } catch (Exception e) {
            return false;
        }

        // Validate filter condition if provided (basic syntax check)
        if (String.isNotBlank(retentionConfig.FilterCondition__c)) {
            if (!isValidFilterCondition(retentionConfig.FilterCondition__c)) {
                return false;
            }
        }

        return true;
    }

    /**
     * @description Determines if this strategy supports the specified object type
     * @param objectApiName API name of object to check
     * @return Boolean True if supported (all standard objects and custom objects)
     */
    public Boolean supportsObjectType(String objectApiName) {
        if (String.isBlank(objectApiName)) {
            return false;
        }

        // This default strategy supports all objects except those with special handling
        String objectName = objectApiName.toLowerCase();

        // Return false for objects that need special strategies
        return !(objectName.equals('contentdocument') ||
                objectName.equals('contentversion') ||
                objectName.equals('attachment'));
    }

    /**
     * @description Processes records in simulation mode (no actual deletion)
     * @param scope Records to simulate processing
     * @param summary Summary object to update
     * @return DeleteResultSummary Updated summary
     */
    private DeleteResultSummary processSimulation(List<SObject> scope, DeleteResultSummary summary) {
        // In simulation mode, we just count the records and collect sample IDs
        for (SObject record : scope) {
            summary.recordsProcessed++;
            summary.addSampleId(record.Id);
        }

        return summary;
    }

    /**
     * @description Processes actual deletion of records
     * @param retentionConfig Configuration specifying deletion mode
     * @param scope Records to delete
     * @param summary Summary object to update
     * @return DeleteResultSummary Updated summary with DML results
     */
    private DeleteResultSummary processActualDeletion(
            Retention__c retentionConfig,
            List<SObject> scope,
            DeleteResultSummary summary
    ) {
        List<DmlResult> dmlResults;

        if (retentionConfig.HardDelete__c == true) {
            // Hard delete - use Database.delete with allOrNone = false
            List<Database.DeleteResult> deleteResults = Database.delete(scope, false);
            dmlResults = DmlResultService.getGenericErrorResults(deleteResults);
        } else {
            // Soft delete - use the DmlResultService for consistent handling
            dmlResults = DmlResultService.bulkDelete(scope);
        }

        // Add results to summary
        summary.addDmlResults(dmlResults);

        return summary;
    }

    /**
     * @description Determines the action type based on configuration settings
     * @param retentionConfig Configuration to analyze
     * @return String Action type constant
     */
    private String getActionType(Retention__c retentionConfig) {
        if (retentionConfig.Simulate__c == true) {
            return Constants.ACTION_SIMULATE;
        } else if (retentionConfig.HardDelete__c == true) {
            return Constants.ACTION_HARD_DELETE;
        } else {
            return Constants.ACTION_SOFT_DELETE;
        }
    }

    /**
     * @description Basic validation of filter condition syntax
     * @param filterCondition SOQL WHERE clause fragment to validate
     * @return Boolean True if condition appears to be valid
     */
    private Boolean isValidFilterCondition(String filterCondition) {
        if (String.isBlank(filterCondition)) {
            return true;
        }

        String condition = filterCondition.trim().toLowerCase();

        // Check for common SQL injection patterns
        List<String> dangerousKeywords = new List<String>{
                'drop ', 'delete ', 'insert ', 'update ', 'create ', 'alter ', 'truncate '
        };

        for (String keyword : dangerousKeywords) {
            if (condition.contains(keyword)) {
                return false;
            }
        }

        // Check for unbalanced parentheses
        Integer openParens = 0;
        for (Integer i = 0; i < filterCondition.length(); i++) {
            if (filterCondition.substring(i, i + 1) == '(') {
                openParens++;
            } else if (filterCondition.substring(i, i + 1) == ')') {
                openParens--;
                if (openParens < 0) {
                    return false;
                }
            }
        }

        return openParens == 0;
    }
}
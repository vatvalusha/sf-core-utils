/**
 * @description Apex controller for the Retention Rule Editor LWC component.
 * Provides server-side methods for managing retention rules and retrieving execution history.
 * 
 * @author Valerii Artemenko
 * @version 1.0
 * @since 2025-01-28
 */
public with sharing class RetentionRuleEditorController {

    /**
     * @description Retrieves retention run history for a specific retention rule
     * @param retentionId ID of the retention rule
     * @return List<Retention_Run__c> List of retention runs with execution details
     */
    @AuraEnabled(cacheable=true)
    public static List<Retention_Run__c> getRetentionRuns(Id retentionId) {
        try {
            return [
                    SELECT Id, Name, VAL1__Status__c, VAL1__Found__c, VAL1__Deleted__c, VAL1__Errors__c,
                            VAL1__StartedAt__c, VAL1__FinishedAt__c, VAL1__ReportFileId__c
                    FROM VAL1__Retention_Run__c
                    WHERE VAL1__Retention__c = :retentionId
                    WITH SECURITY_ENFORCED
                    ORDER BY StartedAt__c DESC
                    LIMIT 100
            ];
        } catch (QueryException e) {
            throw new AuraHandledException('Error retrieving retention runs: ' + e.getMessage());
        }
    }

    /**
     * @description Validates a retention rule configuration
     * @param retentionRule The retention rule to validate
     * @return Boolean True if the rule is valid
     */
    @AuraEnabled
    public static Boolean validateRetentionRule(VAL1__Retention__c retentionRule) {
        try {

            // Get the appropriate strategy for validation
            RetentionStrategy strategy = RetentionStrategyRegistry.getStrategy(retentionRule);

            System.debug('*** retentionRule: ' + JSON.serialize(retentionRule));

            // Validate the configuration
            Boolean isValid = strategy.validateConfiguration(retentionRule);

            System.debug('*** isValid: ' + isValid);

            if (!isValid) {
                throw new AuraHandledException('Invalid retention rule configuration. Please check your settings.');
            }

            // Additional business logic validation
            validateBusinessRules(retentionRule);

            return true;

        } catch (Exception e) {
            throw new AuraHandledException('Validation failed: ' + e.getMessage());
        }
    }

    /**
     * @description Executes a retention rule on-demand
     * @param retentionId ID of the retention rule to execute
     * @return String Batch job ID
     */
    @AuraEnabled
    public static String executeRetentionRule(Id retentionId) {
        try {
            // Verify the retention rule exists and is valid
            VAL1__Retention__c retentionRule = getRetentionRule(retentionId);

            if (!retentionRule.Active__c) {
                throw new AuraHandledException('Cannot execute inactive retention rule');
            }

            // Execute the batch
            Id batchJobId = RetentionBatch.execute(retentionId);

            return String.valueOf(batchJobId);

        } catch (Exception e) {
            throw new AuraHandledException('Error executing retention rule: ' + e.getMessage());
        }
    }

    /**
     * @description Gets picklist values for retention unit field
     * @return List<PicklistOption> List of picklist options
     */
    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getRetentionUnitOptions() {
        return getPicklistValues('VAL1__Retention__c', 'VAL1__RetentionUnit__c');
    }

    /**
     * @description Gets picklist values for run method field
     * @return List<PicklistOption> List of picklist options
     */
    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getRunMethodOptions() {
        return getPicklistValues('VAL1__Retention__c', 'VAL1__RunMethod__c');
    }

    /**
     * @description Gets picklist values for batch frequency field
     * @return List<PicklistOption> List of picklist options
     */
    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getBatchFrequencyOptions() {
        return getPicklistValues('VAL1__Retention__c', 'VAL1__BatchFrequency__c');
    }

    /**
     * @description Gets available sObject types for retention processing
     * @return List<ObjectOption> List of available objects
     */
    @AuraEnabled(Cacheable=true)
    public static List<ObjectOption> getAvailableObjects() {
        List<ObjectOption> options = new List<ObjectOption>();

        try {
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

            for (String objectName : globalDescribe.keySet()) {
                Schema.SObjectType objectType = globalDescribe.get(objectName);
                Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();

                // Filter for custom objects and commonly used standard objects
                if (objectDescribe.isCustom() || isStandardObjectSupported(objectName)) {
                    if (objectDescribe.isDeletable() && objectDescribe.isQueryable()) {
                        options.add(new ObjectOption(objectDescribe.getLabel(), objectName));
                    }
                }
            }

            options.sort();

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error getting available objects: ' + e.getMessage());
        }

        return options;
    }

    /**
     * @description Gets date fields for a specific sObject
     * @param objectApiName API name of the object
     * @return List<FieldOption> List of date/datetime fields
     */
    @AuraEnabled(Cacheable=true)
    public static List<FieldOption> getDateFields(String objectApiName) {
        List<FieldOption> options = new List<FieldOption>();

        try {
            if (String.isBlank(objectApiName)) {
                return options;
            }

            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
            if (objectType == null) {
                return options;
            }

            Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();

            for (String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                Schema.DisplayType fieldType = fieldDescribe.getType();

                // Include Date and DateTime fields
                if (fieldType == Schema.DisplayType.Date || fieldType == Schema.DisplayType.DateTime) {
                    options.add(new FieldOption(fieldDescribe.getLabel(), fieldDescribe.getName()));
                }
            }

            // Sort by label
            options.sort();

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error getting date fields: ' + e.getMessage());
        }

        return options;
    }

    /**
     * @description Retrieves a retention rule with all necessary fields
     * @param retentionId ID of the retention rule
     * @return VAL1__Retention__c The retention rule record
     */
    private static VAL1__Retention__c getRetentionRule(Id retentionId) {
        try {
            return [
                    SELECT Id
                            , Name
                            , TargetObject__c
                            , DateFieldAPI__c
                            , RetentionAge__c
                            , RetentionUnit__c
                            , Active__c
                            , Simulate__c
                            , HardDelete__c
                            , RunMethod__c
                            , BatchFrequency__c
                            , RunTimeGMT__c
                            , FilterCondition__c
                            , BatchChunkSize__c
                            , RecordLimitPerRun__c
                            , HandleFiles__c
                            , HandleAttachments__c
                    FROM VAL1__Retention__c
                    WHERE Id = :retentionId
                    WITH SECURITY_ENFORCED
                    LIMIT 1
            ];
        } catch (QueryException e) {
            throw new AuraHandledException('Retention rule not found: ' + e.getMessage());
        }
    }

    /**
     * @description Validates business rules for retention configuration
     * @param retentionRule The retention rule to validate
     */
    private static void validateBusinessRules(VAL1__Retention__c retentionRule) {
        // Validate retention age is positive
        if (retentionRule.VAL1__RetentionAge__c <= 0) {
            throw new AuraHandledException('Retention age must be greater than zero');
        }

        // Validate batch chunk size is within reasonable limits
        if (retentionRule.VAL1__BatchChunkSize__c != null &&
                (retentionRule.VAL1__BatchChunkSize__c < 1 || retentionRule.VAL1__BatchChunkSize__c > 2000)) {
            throw new AuraHandledException('Batch chunk size must be between 1 and 2000');
        }

        // Validate record limit is reasonable
        if (retentionRule.VAL1__RecordLimitPerRun__c != null && retentionRule.VAL1__RecordLimitPerRun__c < 1) {
            throw new AuraHandledException('Record limit per run must be at least 1');
        }

        // Validate target object is specified
        if (String.isBlank(retentionRule.VAL1__TargetObject__c)) {
            throw new AuraHandledException('Target object must be specified');
        }
    }

    /**
     * @description Gets picklist values for a specific field
     * @param objectApiName API name of the object
     * @param fieldApiName API name of the field
     * @return List<PicklistOption> List of picklist options
     */
    private static List<PicklistOption> getPicklistValues(String objectApiName, String fieldApiName) {
        List<PicklistOption> options = new List<PicklistOption>();

        try {
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
            Schema.SObjectField field = objectType.getDescribe().fields.getMap().get(fieldApiName);
            List<Schema.PicklistEntry> picklistEntries = field.getDescribe().getPicklistValues();

            for (Schema.PicklistEntry entry : picklistEntries) {
                if (entry.isActive()) {
                    options.add(new PicklistOption(entry.getLabel(), entry.getValue()));
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error getting picklist values: ' + e.getMessage());
        }

        return options;
    }

    /**
     * @description Determines if a standard object is supported for retention
     * @param objectName API name of the object
     * @return Boolean True if the standard object is supported
     */
    private static Boolean isStandardObjectSupported(String objectName) {
        Set<String> supportedObjects = new Set<String>{
                'account', 'contact', 'lead', 'opportunity', 'case', 'task', 'event',
                'contentdocument', 'contentversion', 'attachment', 'note',
                'campaignmember', 'opportunitylineitem', 'product2'
        };

        return supportedObjects.contains(objectName.toLowerCase());
    }

    /**
     * @description Wrapper class for picklist options
     */
    public class PicklistOption implements Comparable {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }

        public Integer compareTo(Object other) {
            PicklistOption otherOption = (PicklistOption) other;
            return this.label.compareTo(otherOption.label);
        }
    }

    /**
     * @description Wrapper class for object options
     */
    public class ObjectOption implements Comparable {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public ObjectOption(String label, String value) {
            this.label = label;
            this.value = value;
        }

        public Integer compareTo(Object other) {
            ObjectOption otherOption = (ObjectOption) other;
            return this.label.compareTo(otherOption.label);
        }
    }

    /**
     * @description Wrapper class for field options
     */
    public class FieldOption implements Comparable {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public FieldOption(String label, String value) {
            this.label = label;
            this.value = value;
        }

        public Integer compareTo(Object other) {
            FieldOption otherOption = (FieldOption) other;
            return this.label.compareTo(otherOption.label);
        }
    }
}
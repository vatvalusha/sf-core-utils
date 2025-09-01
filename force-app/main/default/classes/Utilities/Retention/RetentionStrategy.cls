/**
 * @description Interface defining the contract for retention strategies used to process 
 * different types of objects in the retention framework. Implementations of this interface
 * handle the specific logic for querying records and processing deletions for different
 * object types, including special cases like Files and Attachments.
 * 
 * This interface supports the Strategy pattern, allowing the retention framework to
 * handle different object types with specialized processing logic while maintaining
 * a consistent interface for the batch processing engine.
 * 
 * @author Valerii Artemenko
 * @version 1.0
 * @since 2025-01-28
 */
public interface RetentionStrategy {
    
    /**
     * @description Builds a Database.QueryLocator for identifying records that meet
     * the retention criteria specified in the configuration. The query should include
     * all necessary fields for deletion and reporting, and must include proper WHERE
     * clause conditions for the cutoff date and any additional filters.
     * 
     * @param retentionConfig The retention rule configuration containing target object,
     *                       date field, filter conditions, and limits
     * @param cutoffDate The calculated cutoff datetime - records older than this should be included
     * @return Database.QueryLocator Query locator for batch processing of eligible records
     * @throws RetentionException If the query cannot be built due to invalid configuration
     * 
     * @example
     * Retention__c config = new Retention__c(
     *     TargetObject__c = 'Account',
     *     DateFieldAPI__c = 'CreatedDate',
     *     FilterCondition__c = 'Type = \'Inactive\''
     * );
     * Datetime cutoff = Datetime.now().addMonths(-6);
     * Database.QueryLocator locator = strategy.buildQuery(config, cutoff);
     */
    Database.QueryLocator buildQuery(Retention__c retentionConfig, Datetime cutoffDate);
    
    /**
     * @description Processes a batch scope of records according to the retention configuration.
     * This method handles the actual deletion operations (simulate, soft delete, or hard delete)
     * and returns a summary of the results including success counts, errors, and sample IDs.
     * 
     * The method should use the existing DmlResultService for consistent error handling
     * and should respect the simulation mode specified in the retention configuration.
     * 
     * @param retentionConfig The retention rule configuration specifying how to process records
     * @param scope List of SObject records to process in this batch iteration
     * @return DeleteResultSummary Summary of the processing results including counts and errors
     * @throws RetentionException If processing fails due to system errors
     * 
     * @example
     * List<Account> accounts = [SELECT Id FROM Account WHERE CreatedDate < :cutoffDate];
     * DeleteResultSummary summary = strategy.processScope(retentionConfig, accounts);
     * System.debug('Processed: ' + summary.recordsProcessed + ', Errors: ' + summary.recordsWithErrors);
     */
    DeleteResultSummary processScope(Retention__c retentionConfig, List<SObject> scope);
    
    /**
     * @description Validates that the retention configuration is compatible with this strategy.
     * This method should check that the target object exists, the specified date field is valid,
     * and any filter conditions can be properly applied. It should also verify that the current
     * user has the necessary permissions to query and delete records from the target object.
     * 
     * @param retentionConfig The retention configuration to validate
     * @return Boolean True if the configuration is valid and can be processed by this strategy
     * 
     * @example
     * Retention__c config = new Retention__c(TargetObject__c = 'InvalidObject__c');
     * Boolean isValid = strategy.validateConfiguration(config); // Returns false
     */
    Boolean validateConfiguration(Retention__c retentionConfig);
    
    /**
     * @description Determines if this strategy can handle the specified object type.
     * This method is used by the RetentionStrategyRegistry to select the appropriate
     * strategy for a given retention configuration.
     * 
     * @param objectApiName API name of the object to check compatibility
     * @return Boolean True if this strategy can process the specified object type
     * 
     * @example
     * Boolean canHandle = strategy.supportsObjectType('Account'); // Returns true for DefaultRetentionStrategy
     * Boolean canHandle = strategy.supportsObjectType('ContentDocument'); // Returns true for FileRetentionStrategy
     */
    Boolean supportsObjectType(String objectApiName);
}
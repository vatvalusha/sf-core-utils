/**
 * @description Batchable class for executing data retention rules. Processes records
 * according to retention configuration settings and generates detailed execution logs.
 * 
 * This class implements Database.Batchable<SObject> and Database.Stateful to maintain
 * state across batch iterations and provide comprehensive reporting of the retention process.
 * 
 * @author Valerii Artemenko
 * @version 1.0
 * @since 2025-01-28
 */
public with sharing class RetentionBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private Retention__c retentionConfig;
    private Retention_Run__c runLog;
    private RetentionStrategy strategy;
    private Datetime cutoffDate;
    private DeleteResultSummary overallSummary;
    
    /**
     * @description Constructor for retention batch processing
     * @param retentionConfigId ID of the retention rule to execute
     */
    public RetentionBatch(Id retentionConfigId) {
        this.retentionConfig = getRetentionConfig(retentionConfigId);
        this.strategy = RetentionStrategyRegistry.getStrategy(this.retentionConfig);
        this.cutoffDate = RetentionDateUtility.calculateCutoffDate(this.retentionConfig);
        this.overallSummary = new DeleteResultSummary(
            0,
            this.retentionConfig.TargetObject__c,
            getActionType()
        );
    }
    
    /**
     * @description Constructor with retention config object
     * @param config Retention configuration record
     */
    public RetentionBatch(Retention__c config) {
        this.retentionConfig = config;
        this.strategy = RetentionStrategyRegistry.getStrategy(this.retentionConfig);
        this.cutoffDate = RetentionDateUtility.calculateCutoffDate(this.retentionConfig);
        this.overallSummary = new DeleteResultSummary(
            0,
            this.retentionConfig.TargetObject__c,
            getActionType()
        );
    }
    
    /**
     * @description Start method for batch execution
     * @param bc Batch context
     * @return Database.QueryLocator Query locator for eligible records
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        try {
            // Validate configuration
            if (!this.strategy.validateConfiguration(this.retentionConfig)) {
                throw new IllegalArgumentException('Invalid retention configuration');
            }
            
            // Start logging
            this.runLog = RetentionRunLogger.startRetentionRun(this.retentionConfig);
            
            // Build and return query locator
            return this.strategy.buildQuery(this.retentionConfig, this.cutoffDate);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in RetentionBatch.start: ' + e.getMessage());
            
            if (this.runLog == null) {
                try {
                    this.runLog = RetentionRunLogger.startRetentionRun(this.retentionConfig);
                } catch (Exception logException) {
                    // If we can't even start logging, throw the original error
                    throw e;
                }
            }
            
            RetentionRunLogger.failRetentionRun(this.runLog, e.getMessage());
            throw e;
        }
    }
    
    /**
     * @description Execute method for processing each batch scope
     * @param bc Batch context
     * @param scope List of records to process in this iteration
     */
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            if (scope == null || scope.isEmpty()) {
                return;
            }
            
            // Update overall found count
            this.overallSummary.recordsFound += scope.size();
            
            // Process the scope using the strategy
            DeleteResultSummary scopeSummary = this.strategy.processScope(this.retentionConfig, scope);
            
            // Aggregate results
            this.overallSummary.recordsProcessed += scopeSummary.recordsProcessed;
            this.overallSummary.recordsWithErrors += scopeSummary.recordsWithErrors;
            this.overallSummary.dmlResults.addAll(scopeSummary.dmlResults);
            
            // Add sample IDs (limited by constant)
            for (Id sampleId : scopeSummary.sampleIds) {
                if (this.overallSummary.sampleIds.size() >= Constants.MAX_SAMPLE_IDS_TO_STORE) {
                    break;
                }
                this.overallSummary.addSampleId(sampleId);
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in RetentionBatch.execute: ' + e.getMessage());
            
            // Track the error in overall summary
            this.overallSummary.recordsWithErrors += (scope != null ? scope.size() : 0);
            
            // Create error DML result for tracking
            DmlResult errorResult = new DmlResult();
            errorResult.success = false;
            errorResult.recordId = (scope != null && !scope.isEmpty()) ? scope[0].Id : null;
            
            DmlError error = new DmlError();
            error.message = e.getMessage();
            error.statusCode = 'BATCH_ERROR';
            error.fields = new List<String>();
            
            errorResult.errors.add(error);
            this.overallSummary.dmlResults.add(errorResult);
        }
    }
    
    /**
     * @description Finish method called when batch completes
     * @param bc Batch context
     */
    public void finish(Database.BatchableContext bc) {
        try {
            if (this.runLog != null) {
                RetentionRunLogger.finishRetentionRun(this.runLog, this.overallSummary);
            }
            
            // Log completion summary
            System.debug(LoggingLevel.INFO, 'Retention batch completed: ' + this.overallSummary.getSummaryMessage());
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in RetentionBatch.finish: ' + e.getMessage());
            
            if (this.runLog != null) {
                try {
                    RetentionRunLogger.failRetentionRun(this.runLog, 'Finish method failed: ' + e.getMessage());
                } catch (Exception logException) {
                    System.debug(LoggingLevel.ERROR, 'Failed to log error in finish method: ' + logException.getMessage());
                }
            }
        }
    }
    
    /**
     * @description Retrieves retention configuration with all necessary fields
     * @param retentionConfigId ID of the retention config
     * @return Retention__c The retention configuration record
     */
    private Retention__c getRetentionConfig(Id retentionConfigId) {
        try {
            return [
                SELECT Id, Name, TargetObject__c, DateFieldAPI__c, RetentionAge__c, RetentionUnit__c,
                       Active__c, Simulate__c, HardDelete__c, RunMethod__c, BatchFrequency__c, RunTimeGMT__c,
                       FilterCondition__c, BatchChunkSize__c, RecordLimitPerRun__c, HandleFiles__c, HandleAttachments__c,
                       CreatedDate, CreatedById, LastModifiedDate, LastModifiedById
                FROM Retention__c 
                WHERE Id = :retentionConfigId 
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
        } catch (QueryException e) {
            throw new IllegalArgumentException('Could not retrieve retention configuration: ' + e.getMessage());
        }
    }
    
    /**
     * @description Determines the action type based on configuration
     * @return String Action type constant
     */
    private String getActionType() {
        if (this.retentionConfig.Simulate__c == true) {
            return Constants.ACTION_SIMULATE;
        } else if (this.retentionConfig.HardDelete__c == true) {
            return Constants.ACTION_HARD_DELETE;
        } else {
            return Constants.ACTION_SOFT_DELETE;
        }
    }
    
    /**
     * @description Static method to execute retention batch for a specific configuration
     * @param retentionConfigId ID of retention configuration to execute
     * @return Id The batch job ID
     */
    public static Id execute(Id retentionConfigId) {
        RetentionBatch batchInstance = new RetentionBatch(retentionConfigId);
        
        // Determine batch size from configuration or use default
        Integer batchSize = Constants.DEFAULT_BATCH_CHUNK_SIZE;
        
        try {
            Retention__c config = [
                SELECT BatchChunkSize__c 
                FROM Retention__c 
                WHERE Id = :retentionConfigId 
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            if (config.BatchChunkSize__c != null && config.BatchChunkSize__c > 0) {
                batchSize = Integer.valueOf(config.BatchChunkSize__c);
            }
        } catch (Exception e) {
            // Use default batch size if we can't retrieve configuration
            System.debug('Using default batch size due to error: ' + e.getMessage());
        }
        
        return Database.executeBatch(batchInstance, batchSize);
    }
    
    /**
     * @description Static method to execute retention batch with custom batch size
     * @param retentionConfigId ID of retention configuration to execute
     * @param batchSize Custom batch size to use
     * @return Id The batch job ID
     */
    public static Id execute(Id retentionConfigId, Integer batchSize) {
        RetentionBatch batchInstance = new RetentionBatch(retentionConfigId);
        return Database.executeBatch(batchInstance, batchSize);
    }
}
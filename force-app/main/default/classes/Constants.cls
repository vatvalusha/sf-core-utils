/**
 * @description A utility class containing constant values used across the application
 * @author Valerii Artemenko
 * @version 1.1
 * @since 2025-06-28
 */
public with sharing class Constants {
    /**
     * @description Default value to use when a value is not known or cannot be determined
     */
    public static final String UNKNOWN = 'Unknown';
    
    // ========================================
    // RETENTION FRAMEWORK CONSTANTS
    // ========================================
    
    /**
     * @description Retention Unit picklist values
     */
    public static final String RETENTION_UNIT_DAY = 'Day';
    public static final String RETENTION_UNIT_MONTH = 'Month';
    public static final String RETENTION_UNIT_YEAR = 'Year';
    
    /**
     * @description Run Method picklist values
     */
    public static final String RUN_METHOD_SCHEDULED = 'Scheduled';
    public static final String RUN_METHOD_ON_DEMAND = 'OnDemand';
    
    /**
     * @description Batch Frequency picklist values
     */
    public static final String BATCH_FREQUENCY_DAILY = 'Daily';
    public static final String BATCH_FREQUENCY_WEEKLY = 'Weekly';
    public static final String BATCH_FREQUENCY_MONTHLY = 'Monthly';
    
    /**
     * @description Retention Run Status values
     */
    public static final String RETENTION_STATUS_STARTED = 'In Progress';
    public static final String RETENTION_STATUS_COMPLETED = 'Completed';
    public static final String RETENTION_STATUS_FAILED = 'Failed';
    
    /**
     * @description Default field API names
     */
    public static final String DEFAULT_DATE_FIELD = 'CreatedDate';
    public static final String DEFAULT_BATCH_SIZE = 'DefaultBatchSize';
    
    /**
     * @description File handling object API names
     */
    public static final String CONTENT_DOCUMENT_OBJECT = 'ContentDocument';
    public static final String CONTENT_VERSION_OBJECT = 'ContentVersion';
    public static final String ATTACHMENT_OBJECT = 'Attachment';
    
    /**
     * @description Error messages for retention framework
     */
    public static final String ERROR_INVALID_DATE_FIELD = 'Invalid date field specified for the target object';
    public static final String ERROR_INVALID_SOQL_FILTER = 'Invalid SOQL filter condition provided';
    public static final String ERROR_BATCH_EXECUTION_FAILED = 'Batch execution failed with errors';
    public static final String ERROR_NO_ACTIVE_RULES = 'No active retention rules found for execution';
    public static final String ERROR_STRATEGY_NOT_FOUND = 'No retention strategy found for the specified object type';
    
    /**
     * @description Default configuration values
     */
    public static final Integer DEFAULT_BATCH_CHUNK_SIZE = 200;
    public static final Integer DEFAULT_RECORD_LIMIT_PER_RUN = 10000;
    public static final Integer MAX_SAMPLE_IDS_TO_STORE = 50;
    
    /**
     * @description CSV report headers
     */
    public static final String CSV_HEADER_RECORD_ID = 'Record Id';
    public static final String CSV_HEADER_OBJECT_TYPE = 'Object Type';
    public static final String CSV_HEADER_ACTION = 'Action';
    public static final String CSV_HEADER_STATUS = 'Status';
    public static final String CSV_HEADER_ERROR_MESSAGE = 'Error Message';
    public static final String CSV_HEADER_PROCESSED_DATE = 'Processed Date';
    
    /**
     * @description Report file naming
     */
    public static final String REPORT_FILE_PREFIX = 'Retention_Report_';
    public static final String REPORT_FILE_EXTENSION = '.csv';
    
    /**
     * @description Action types for reporting
     */
    public static final String ACTION_SIMULATE = 'Simulate';
    public static final String ACTION_SOFT_DELETE = 'Soft Delete';
    public static final String ACTION_HARD_DELETE = 'Hard Delete';
    
    /**
     * @description Scheduler job name patterns
     */
    public static final String SCHEDULER_JOB_PREFIX = 'Retention_';
    public static final String SCHEDULER_JOB_DAILY_SUFFIX = '_Daily';
    public static final String SCHEDULER_JOB_WEEKLY_SUFFIX = '_Weekly';
    public static final String SCHEDULER_JOB_MONTHLY_SUFFIX = '_Monthly';
}
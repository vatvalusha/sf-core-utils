/**
 * @description Wrapper class that summarizes the results of deletion operations in a retention batch run.
 * This class encapsulates metrics and details about processed records, successful deletions, 
 * and any errors encountered during the retention process.
 * 
 * @author Valerii Artemenko
 * @version 1.0
 * @since 2025-01-28
 */
public with sharing class DeleteResultSummary {
    
    /**
     * @description Total number of records found matching retention criteria
     */
    public Integer recordsFound { get; set; }
    
    /**
     * @description Number of records successfully deleted or simulated
     */
    public Integer recordsProcessed { get; set; }
    
    /**
     * @description Number of records that failed to delete due to errors
     */
    public Integer recordsWithErrors { get; set; }
    
    /**
     * @description List of sample record IDs that were processed (limited for storage efficiency)
     */
    public List<Id> sampleIds { get; set; }
    
    /**
     * @description List of detailed DML results for audit and error analysis
     */
    public List<DmlResult> dmlResults { get; set; }
    
    /**
     * @description Type of action performed (Simulate, Soft Delete, Hard Delete)
     */
    public String actionType { get; set; }
    
    /**
     * @description Object type that was processed
     */
    public String objectType { get; set; }
    
    /**
     * @description Default constructor initializes all collections and counters
     */
    public DeleteResultSummary() {
        this.recordsFound = 0;
        this.recordsProcessed = 0;
        this.recordsWithErrors = 0;
        this.sampleIds = new List<Id>();
        this.dmlResults = new List<DmlResult>();
        this.actionType = Constants.ACTION_SIMULATE;
        this.objectType = Constants.UNKNOWN;
    }
    
    /**
     * @description Constructor that initializes with basic metrics
     * @param recordsFound Number of records found matching criteria
     * @param objectType Type of object being processed
     * @param actionType Type of action being performed
     */
    public DeleteResultSummary(Integer recordsFound, String objectType, String actionType) {
        this();
        this.recordsFound = recordsFound;
        this.objectType = objectType;
        this.actionType = actionType;
    }
    
    /**
     * @description Adds DML results to the summary and updates counters accordingly
     * @param results List of DML results to process and add to summary
     */
    public void addDmlResults(List<DmlResult> results) {
        if (results == null || results.isEmpty()) {
            return;
        }
        
        this.dmlResults.addAll(results);
        
        for (DmlResult result : results) {
            if (result.success) {
                this.recordsProcessed++;
                // Store sample IDs up to the configured limit
                if (this.sampleIds.size() < Constants.MAX_SAMPLE_IDS_TO_STORE && result.recordId != null) {
                    this.sampleIds.add(result.recordId);
                }
            } else {
                this.recordsWithErrors++;
            }
        }
    }
    
    /**
     * @description Adds a single record ID to the processed sample collection
     * @param recordId ID of the record to add to samples
     */
    public void addSampleId(Id recordId) {
        if (recordId != null && this.sampleIds.size() < Constants.MAX_SAMPLE_IDS_TO_STORE) {
            this.sampleIds.add(recordId);
        }
    }
    
    /**
     * @description Returns comma-separated string of sample IDs for storage
     * @return String Comma-separated list of sample record IDs
     */
    public String getSampleIdsAsString() {
        List<String> idStrings = new List<String>();
        for (Id recordId : this.sampleIds) {
            idStrings.add(String.valueOf(recordId));
        }
        return String.join(idStrings, ', ');
    }
    
    /**
     * @description Calculates success rate as percentage
     * @return Decimal Success rate as percentage (0-100)
     */
    public Decimal getSuccessRate() {
        if (this.recordsFound == 0) {
            return 100.0;
        }
        return (Decimal.valueOf(this.recordsProcessed) / Decimal.valueOf(this.recordsFound)) * 100;
    }
    
    /**
     * @description Determines if the deletion operation was successful overall
     * @return Boolean True if no errors occurred, false otherwise
     */
    public Boolean isSuccessful() {
        return this.recordsWithErrors == 0;
    }
    
    /**
     * @description Returns a human-readable summary of the operation results
     * @return String Summary string describing the operation results
     */
    public String getSummaryMessage() {
        return String.format(
            '{0}: Found {1} records, processed {2} successfully, {3} errors. Success rate: {4}%',
            new List<Object>{
                this.actionType,
                this.recordsFound,
                this.recordsProcessed,
                this.recordsWithErrors,
                this.getSuccessRate().setScale(1)
            }
        );
    }
}
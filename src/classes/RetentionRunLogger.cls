/**
 * @description Utility class for logging retention run execution and generating CSV reports.
 * Handles creation of Retention_Run__c records and ContentVersion attachments.
 * 
 * @author Valerii Artemenko
 * @version 1.0
 * @since 2025-01-28
 */
public with sharing class RetentionRunLogger {
    
    /**
     * @description Starts a new retention run log entry
     * @param retentionConfig The retention rule being executed
     * @return Retention_Run__c The created run log record
     */
    public static Retention_Run__c startRetentionRun(Retention__c retentionConfig) {
        Retention_Run__c runLog = new Retention_Run__c(
            Retention__c = retentionConfig.Id,
            Status__c = Constants.RETENTION_STATUS_STARTED,
            StartedAt__c = Datetime.now(),
            Found__c = 0,
            Deleted__c = 0,
            Errors__c = 0
        );
        
        insert runLog;
        return runLog;
    }
    
    /**
     * @description Finishes a retention run log with results
     * @param runLog The run log record to update
     * @param summary Summary of processing results
     */
    public static void finishRetentionRun(Retention_Run__c runLog, DeleteResultSummary summary) {
        runLog.Status__c = summary.isSuccessful() ? Constants.RETENTION_STATUS_COMPLETED : Constants.RETENTION_STATUS_FAILED;
        runLog.FinishedAt__c = Datetime.now();
        runLog.Found__c = summary.recordsFound;
        runLog.Deleted__c = summary.recordsProcessed;
        runLog.Errors__c = summary.recordsWithErrors;
        runLog.SampleIds__c = summary.getSampleIdsAsString();
        
        // Generate and attach CSV report
        Id reportFileId = generateCsvReport(runLog.Id, summary);
        if (reportFileId != null) {
            runLog.ReportFileId__c = reportFileId;
        }
        
        update runLog;
    }
    
    /**
     * @description Marks a retention run as failed
     * @param runLog The run log record to update
     * @param errorMessage Error message to log
     */
    public static void failRetentionRun(Retention_Run__c runLog, String errorMessage) {
        runLog.Status__c = Constants.RETENTION_STATUS_FAILED;
        runLog.FinishedAt__c = Datetime.now();
        
        // Store error in sample IDs field for debugging
        runLog.SampleIds__c = 'ERROR: ' + (String.isNotBlank(errorMessage) ? errorMessage : 'Unknown error occurred');
        
        update runLog;
    }
    
    /**
     * @description Generates a CSV report of retention processing results
     * @param runLogId ID of the retention run log
     * @param summary Processing results summary
     * @return Id ContentDocument ID of the generated report
     */
    public static Id generateCsvReport(Id runLogId, DeleteResultSummary summary) {
        try {
            String csvContent = buildCsvContent(summary);
            String fileName = Constants.REPORT_FILE_PREFIX + 
                             Datetime.now().format('yyyy-MM-dd_HH-mm-ss') + 
                             Constants.REPORT_FILE_EXTENSION;
            
            ContentVersion contentVersion = new ContentVersion(
                Title = fileName,
                PathOnClient = fileName,
                VersionData = Blob.valueOf(csvContent),
                Origin = 'H',
                ContentLocation = 'S'
            );
            
            insert contentVersion;
            
            // Get the ContentDocument ID
            ContentVersion insertedVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
            
            return insertedVersion.ContentDocumentId;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to generate CSV report: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Builds CSV content from processing results
     * @param summary Processing results summary
     * @return String CSV formatted content
     */
    private static String buildCsvContent(DeleteResultSummary summary) {
        List<String> csvLines = new List<String>();
        
        // Add header row
        List<String> headers = new List<String>{
            Constants.CSV_HEADER_RECORD_ID,
            Constants.CSV_HEADER_OBJECT_TYPE,
            Constants.CSV_HEADER_ACTION,
            Constants.CSV_HEADER_STATUS,
            Constants.CSV_HEADER_ERROR_MESSAGE,
            Constants.CSV_HEADER_PROCESSED_DATE
        };
        csvLines.add(String.join(headers, ','));
        
        // Add data rows from DML results
        String processedDate = RetentionDateUtility.formatDateTimeForReport(Datetime.now());
        
        if (summary.dmlResults != null && !summary.dmlResults.isEmpty()) {
            for (DmlResult result : summary.dmlResults) {
                List<String> rowData = new List<String>{
                    String.valueOf(result.recordId),
                    escapeCsvValue(summary.objectType),
                    escapeCsvValue(summary.actionType),
                    result.success ? 'Success' : 'Failed',
                    result.success ? '' : escapeCsvValue(getErrorMessage(result)),
                    escapeCsvValue(processedDate)
                };
                csvLines.add(String.join(rowData, ','));
            }
        } else {
            // If no DML results, add summary information
            for (Id sampleId : summary.sampleIds) {
                List<String> rowData = new List<String>{
                    String.valueOf(sampleId),
                    escapeCsvValue(summary.objectType),
                    escapeCsvValue(summary.actionType),
                    'Success',
                    '',
                    escapeCsvValue(processedDate)
                };
                csvLines.add(String.join(rowData, ','));
            }
        }
        
        return String.join(csvLines, '\n');
    }
    
    /**
     * @description Escapes CSV values to handle commas and quotes
     * @param value Value to escape
     * @return String Escaped CSV value
     */
    private static String escapeCsvValue(String value) {
        if (String.isBlank(value)) {
            return '';
        }
        
        // Escape quotes and wrap in quotes if necessary
        if (value.contains(',') || value.contains('"') || value.contains('\n')) {
            value = value.replace('"', '""');
            return '"' + value + '"';
        }
        
        return value;
    }
    
    /**
     * @description Extracts error message from DML result
     * @param result DML result with potential errors
     * @return String Concatenated error messages
     */
    private static String getErrorMessage(DmlResult result) {
        if (result.errors == null || result.errors.isEmpty()) {
            return '';
        }
        
        List<String> errorMessages = new List<String>();
        for (DmlError error : result.errors) {
            errorMessages.add(error.message);
        }
        
        return String.join(errorMessages, '; ');
    }
}
/**
 * @description Utility class for calculating cutoff dates based on retention rules.
 * Provides methods to compute the threshold datetime for determining which records
 * should be eligible for deletion based on retention age and unit specifications.
 * 
 * @example
 * // Calculate cutoff date for records older than 3 months
 * Datetime cutoff = RetentionDateUtility.calculateCutoffDate(3, 'Month');
 * 
 * // Calculate cutoff date using a Retention__c configuration
 * Retention__c config = [SELECT RetentionAge__c, RetentionUnit__c FROM Retention__c LIMIT 1];
 * Datetime cutoff = RetentionDateUtility.calculateCutoffDate(config);
 * 
 * @author Valerii Artemenko
 * @version 1.0
 * @since 2025-01-28
 */
public with sharing class RetentionDateUtility {
    
    /**
     * @description Calculates the cutoff datetime for retention based on age and unit
     * @param retentionAge Number of units to subtract from current time
     * @param retentionUnit Unit of time (Day, Month, Year) from Constants
     * @return Datetime The calculated cutoff datetime
     * @throws IllegalArgumentException if retentionAge is negative or retentionUnit is invalid
     */
    public static Datetime calculateCutoffDate(Decimal retentionAge, String retentionUnit) {
        if (retentionAge < 0) {
            throw new IllegalArgumentException('Retention age cannot be negative');
        }
        
        if (String.isBlank(retentionUnit)) {
            throw new IllegalArgumentException('Retention unit cannot be blank');
        }
        
        Datetime currentTime = Datetime.now();
        Datetime cutoffDate;
        
        switch on retentionUnit.toLowerCase() {
            when 'day' {
                cutoffDate = currentTime.addDays(-Integer.valueOf(retentionAge));
            }
            when 'month' {
                cutoffDate = currentTime.addMonths(-Integer.valueOf(retentionAge));
            }
            when 'year' {
                cutoffDate = currentTime.addYears(-Integer.valueOf(retentionAge));
            }
            when else {
                throw new IllegalArgumentException(
                    'Invalid retention unit: ' + retentionUnit + 
                    '. Valid values are: Day, Month, Year'
                );
            }
        }
        
        return cutoffDate;
    }
    
    /**
     * @description Calculates the cutoff datetime using a Retention__c configuration record
     * @param retentionConfig Retention configuration record containing age and unit
     * @return Datetime The calculated cutoff datetime
     * @throws IllegalArgumentException if configuration is null or contains invalid values
     */
    public static Datetime calculateCutoffDate(Retention__c retentionConfig) {
        if (retentionConfig == null) {
            throw new IllegalArgumentException('Retention configuration cannot be null');
        }
        
        if (retentionConfig.RetentionAge__c == null) {
            throw new IllegalArgumentException('Retention age must be specified');
        }
        
        if (String.isBlank(retentionConfig.RetentionUnit__c)) {
            throw new IllegalArgumentException('Retention unit must be specified');
        }
        
        return calculateCutoffDate(retentionConfig.RetentionAge__c, retentionConfig.RetentionUnit__c);
    }
    
    /**
     * @description Validates that a retention configuration has valid date calculation parameters
     * @param retentionConfig Retention configuration to validate
     * @return Boolean True if configuration is valid for date calculations
     */
    public static Boolean isValidDateConfiguration(Retention__c retentionConfig) {
        try {
            calculateCutoffDate(retentionConfig);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
    
    /**
     * @description Formats a datetime for display in retention reports
     * @param dateTimeValue Datetime to format
     * @return String Formatted datetime string suitable for reports
     */
    public static String formatDateTimeForReport(Datetime dateTimeValue) {
        if (dateTimeValue == null) {
            return '';
        }
        return dateTimeValue.format('yyyy-MM-dd HH:mm:ss z');
    }
    
    /**
     * @description Calculates the number of days between two datetime values
     * @param startDate Earlier datetime
     * @param endDate Later datetime
     * @return Integer Number of days between the dates (rounded up)
     */
    public static Integer daysBetween(Datetime startDate, Datetime endDate) {
        if (startDate == null || endDate == null) {
            return 0;
        }
        
        if (startDate > endDate) {
            // Swap if start is after end
            Datetime temp = startDate;
            startDate = endDate;
            endDate = temp;
        }
        
        // Calculate difference in milliseconds and convert to days
        Long millisecondsDiff = endDate.getTime() - startDate.getTime();
        Long daysDiff = millisecondsDiff / (1000 * 60 * 60 * 24);
        
        // Round up to next day if there are partial days
        if (Math.mod(millisecondsDiff, (1000 * 60 * 60 * 24)) > 0) {
            daysDiff++;
        }
        
        return Integer.valueOf(daysDiff);
    }
    
    /**
     * @description Determines if a given datetime is older than the cutoff date
     * @param recordDate Datetime from the record to check
     * @param cutoffDate Cutoff datetime calculated from retention rules
     * @return Boolean True if record date is older than cutoff (eligible for deletion)
     */
    public static Boolean isEligibleForDeletion(Datetime recordDate, Datetime cutoffDate) {
        if (recordDate == null || cutoffDate == null) {
            return false;
        }
        return recordDate < cutoffDate;
    }
    
    /**
     * @description Calculates next scheduled run time based on frequency and time settings
     * @param frequency Frequency setting (Daily, Weekly, Monthly)
     * @param runTime Time of day to run (null defaults to current time)
     * @return Datetime Next scheduled execution datetime
     */
    public static Datetime calculateNextRunTime(String frequency, Time runTime) {
        if (String.isBlank(frequency)) {
            frequency = Constants.BATCH_FREQUENCY_WEEKLY;
        }
        
        Datetime currentTime = Datetime.now();
        Date today = Date.today();
        
        // Use provided time or current time
        Time scheduleTime = runTime != null ? runTime : currentTime.time();
        
        Datetime nextRun;
        
        switch on frequency.toLowerCase() {
            when 'daily' {
                nextRun = Datetime.newInstance(today.addDays(1), scheduleTime);
            }
            when 'weekly' {
                nextRun = Datetime.newInstance(today.addDays(7), scheduleTime);
            }
            when 'monthly' {
                nextRun = Datetime.newInstance(today.addMonths(1), scheduleTime);
            }
            when else {
                // Default to weekly if frequency is invalid
                nextRun = Datetime.newInstance(today.addDays(7), scheduleTime);
            }
        }
        
        // If calculated time is in the past, move to next occurrence
        if (nextRun <= currentTime) {
            switch on frequency.toLowerCase() {
                when 'daily' {
                    nextRun = nextRun.addDays(1);
                }
                when 'weekly' {
                    nextRun = nextRun.addDays(7);
                }
                when 'monthly' {
                    nextRun = nextRun.addMonths(1);
                }
            }
        }
        
        return nextRun;
    }
}
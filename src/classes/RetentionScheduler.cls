/**
 * @description Schedulable class for automated execution of retention rules.
 * Processes active retention rules based on their frequency settings and schedules
 * the appropriate batch jobs for execution.
 * 
 * @author Valerii Artemenko
 * @version 1.0
 * @since 2025-01-28
 */
public with sharing class RetentionScheduler implements Schedulable {

    private String batchFrequency;

    /**
     * @description Default constructor for scheduled execution
     */
    public RetentionScheduler() {
        this.batchFrequency = null;
    }

    /**
     * @description Constructor with specific frequency filter
     * @param frequency Frequency to filter retention rules (Daily, Weekly, Monthly)
     */
    public RetentionScheduler(String frequency) {
        this.batchFrequency = frequency;
    }

    /**
     * @description Main execute method called by the Salesforce scheduler
     * @param sc Scheduled execution context
     */
    public void execute(SchedulableContext sc) {
        try {
            List<Retention__c> activeRules = getActiveScheduledRules();

            if (activeRules.isEmpty()) {
                System.debug(LoggingLevel.INFO, 'No active retention rules found for execution');
                return;
            }

            System.debug(LoggingLevel.INFO, 'Processing ' + activeRules.size() + ' active retention rules');

            // Execute each active rule
            for (Retention__c rule : activeRules) {
                executeRetentionRule(rule);
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in RetentionScheduler.execute: ' + e.getMessage());
            // Log error but don't throw to prevent scheduler from stopping
        }
    }

    /**
     * @description Gets active retention rules eligible for scheduled execution
     * @return List<Retention__c> List of active retention rules
     */
    private List<Retention__c> getActiveScheduledRules() {
        String soqlQuery =
                'SELECT Id, Name, VAL1__TargetObject__c, VAL1__DateFieldAPI__c, VAL1__RetentionAge__c, VAL1__RetentionUnit__c, ' +
                        'VAL1__Active__c, VAL1__Simulate__c, VAL1__HardDelete__c, VAL1__RunMethod__c, VAL1__BatchFrequency__c, VAL1__RunTimeGMT__c, ' +
                        'VAL1__FilterCondition__c, VAL1__BatchChunkSize__c, VAL1__RecordLimitPerRun__c, VAL1__HandleFiles__c, VAL1__HandleAttachments__c ' +
                        'FROM VAL1__Retention__c ' +
                        'WHERE VAL1__Active__c = true ' +
                        'AND VAL1__RunMethod__c = :runMethodScheduled';

        Map<String, Object> bindVariables = new Map<String, Object>{
                'runMethodScheduled' => Constants.RUN_METHOD_SCHEDULED
        };

        // Add frequency filter if specified
        if (String.isNotBlank(this.batchFrequency)) {
            soqlQuery += ' AND VAL1__BatchFrequency__c = :batchFrequency';
            bindVariables.put('batchFrequency', this.batchFrequency);
        }

        soqlQuery += ' WITH SECURITY_ENFORCED ORDER BY Name';

        try {
            return Database.query(soqlQuery);
        } catch (QueryException e) {
            System.debug(LoggingLevel.ERROR, 'Error querying retention rules: ' + e.getMessage());
            return new List<Retention__c>();
        }
    }

    /**
     * @description Executes a retention rule by starting a batch job
     * @param retentionRule The retention rule to execute
     */
    private void executeRetentionRule(Retention__c retentionRule) {
        try {
            // Validate the rule before execution
            RetentionStrategy strategy = RetentionStrategyRegistry.getStrategy(retentionRule);

            if (!strategy.validateConfiguration(retentionRule)) {
                System.debug(LoggingLevel.WARN, 'Skipping invalid retention rule: ' + retentionRule.Name);
                return;
            }

            // Start the batch job
            Id batchJobId = RetentionBatch.execute(retentionRule.Id);

            System.debug(LoggingLevel.INFO,
                    'Started retention batch for rule: ' + retentionRule.Name +
                            ', Batch Job ID: ' + batchJobId
            );

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                    'Failed to execute retention rule ' + retentionRule.Name + ': ' + e.getMessage()
            );
        }
    }

    /**
     * @description Schedules daily retention rule execution
     * @param cronExpression Cron expression for scheduling (optional, defaults to 2 AM)
     * @return Id Scheduled job ID
     */
    public static Id scheduleDailyExecution(String cronExpression) {
        if (String.isBlank(cronExpression)) {
            cronExpression = '0 0 2 * * ?'; // Default to 2 AM daily
        }

        String jobName = Constants.SCHEDULER_JOB_PREFIX +
                Constants.BATCH_FREQUENCY_DAILY +
                Constants.SCHEDULER_JOB_DAILY_SUFFIX;

        RetentionScheduler scheduler = new RetentionScheduler(Constants.BATCH_FREQUENCY_DAILY);
        return System.schedule(jobName, cronExpression, scheduler);
    }

    /**
     * @description Schedules weekly retention rule execution
     * @param cronExpression Cron expression for scheduling (optional, defaults to Sunday 2 AM)
     * @return Id Scheduled job ID
     */
    public static Id scheduleWeeklyExecution(String cronExpression) {
        if (String.isBlank(cronExpression)) {
            cronExpression = '0 0 2 ? * SUN'; // Default to Sunday 2 AM
        }

        String jobName = Constants.SCHEDULER_JOB_PREFIX +
                Constants.BATCH_FREQUENCY_WEEKLY +
                Constants.SCHEDULER_JOB_WEEKLY_SUFFIX;

        RetentionScheduler scheduler = new RetentionScheduler(Constants.BATCH_FREQUENCY_WEEKLY);
        return System.schedule(jobName, cronExpression, scheduler);
    }

    /**
     * @description Schedules monthly retention rule execution
     * @param cronExpression Cron expression for scheduling (optional, defaults to 1st of month 2 AM)
     * @return Id Scheduled job ID
     */
    public static Id scheduleMonthlyExecution(String cronExpression) {
        if (String.isBlank(cronExpression)) {
            cronExpression = '0 0 2 1 * ?'; // Default to 1st of month 2 AM
        }

        String jobName = Constants.SCHEDULER_JOB_PREFIX +
                Constants.BATCH_FREQUENCY_MONTHLY +
                Constants.SCHEDULER_JOB_MONTHLY_SUFFIX;

        RetentionScheduler scheduler = new RetentionScheduler(Constants.BATCH_FREQUENCY_MONTHLY);
        return System.schedule(jobName, cronExpression, scheduler);
    }

    /**
     * @description Schedules all retention execution frequencies with default cron expressions
     * @return Map<String, Id> Map of frequency to scheduled job ID
     */
    public static Map<String, Id> scheduleAllFrequencies() {
        Map<String, Id> scheduledJobs = new Map<String, Id>();

        try {
            scheduledJobs.put(Constants.BATCH_FREQUENCY_DAILY, scheduleDailyExecution(null));
            scheduledJobs.put(Constants.BATCH_FREQUENCY_WEEKLY, scheduleWeeklyExecution(null));
            scheduledJobs.put(Constants.BATCH_FREQUENCY_MONTHLY, scheduleMonthlyExecution(null));
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error scheduling retention jobs: ' + e.getMessage());
        }

        return scheduledJobs;
    }

    /**
     * @description Removes all retention scheduler jobs
     */
    public static void unscheduleAllJobs() {
        try {
            List<CronTrigger> jobs = [
                    SELECT Id, CronJobDetail.Name
                    FROM CronTrigger
                    WHERE CronJobDetail.Name LIKE :Constants.SCHEDULER_JOB_PREFIX + '%'
                    WITH SECURITY_ENFORCED
            ];

            for (CronTrigger job : jobs) {
                System.abortJob(job.Id);
                System.debug(LoggingLevel.INFO, 'Aborted job: ' + job.CronJobDetail.Name);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error unscheduling retention jobs: ' + e.getMessage());
        }
    }

    /**
     * @description Gets status of all scheduled retention jobs
     * @return List<CronTrigger> List of scheduled retention jobs
     */
    public static List<CronTrigger> getScheduledJobs() {
        try {
            return [
                    SELECT Id, CronJobDetail.Name, NextFireTime, PreviousFireTime, State,
                            StartTime, EndTime, CronExpression, TimesTriggered
                    FROM CronTrigger
                    WHERE CronJobDetail.Name LIKE :Constants.SCHEDULER_JOB_PREFIX + '%'
                    WITH SECURITY_ENFORCED
                    ORDER BY CronJobDetail.Name
            ];
        } catch (QueryException e) {
            System.debug(LoggingLevel.ERROR, 'Error querying scheduled jobs: ' + e.getMessage());
            return new List<CronTrigger>();
        }
    }
}
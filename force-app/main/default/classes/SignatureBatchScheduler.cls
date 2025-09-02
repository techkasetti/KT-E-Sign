public class SignatureBatchScheduler implements Schedulable {
    private String operationType;
    
    public SignatureBatchScheduler(String operation) {
        this.operationType = operation;
    }
    
    public void execute(SchedulableContext sc) {
        try {
            SignatureBatchProcessor batch = new SignatureBatchProcessor(operationType);
            Database.executeBatch(batch, 200);
            
            // Log scheduled execution
            AuditTrailManager.logSystemActivity(
                'SCHEDULED_BATCH_EXECUTED',
                'SUCCESS',
                'Scheduled batch operation started: ' + operationType
            );
            
        } catch (Exception e) {
            System.debug('Scheduler Error: ' + e.getMessage());
            AuditTrailManager.logSystemActivity(
                'SCHEDULED_BATCH_ERROR',
                'ERROR',
                'Failed to execute scheduled batch: ' + e.getMessage()
            );
        }
    }




    //     SignatureBatchProcessor batch = new SignatureBatchProcessor(operationType);
    //     Database.executeBatch(batch, 200);
    // }





        public static void scheduleAllJobs() {
        try {
            // Schedule daily reminder emails at 9 AM
            System.schedule(
                'Daily Signature Reminders',
                '0 0 9 * * ?',
                new SignatureBatchScheduler('SEND_REMINDERS')
            );
            
            // Schedule weekly request expiration at midnight Sunday
            System.schedule(
                'Weekly Request Expiration',
                '0 0 0 ? * SUN',
                new SignatureBatchScheduler('EXPIRE_REQUESTS')
            );
            
            // Schedule monthly audit cleanup at 2 AM first day of month
            System.schedule(
                'Monthly Audit Cleanup',
                '0 0 2 1 * ?',
                new SignatureBatchScheduler('CLEANUP_AUDIT')
            );
            
            // Schedule monthly performance reports at 6 AM first day of month
            System.schedule(
                'Monthly Performance Reports',
                '0 0 6 1 * ?',
                new SignatureBatchScheduler('GENERATE_REPORTS')
            );
            
            System.debug('✓ All scheduled jobs configured successfully');
            
        } catch (Exception e) {
            System.debug('Failed to schedule jobs: ' + e.getMessage());
        }
    }

}
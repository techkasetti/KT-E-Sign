public class BatchProcessingScheduler implements Schedulable {
    public void execute(SchedulableContext context) {
        // Schedule different batch jobs based on time and requirements
        
        
        // Daily fraud detection analysis
        Map<String, Object> fraudParams = new Map<String, Object>();
        fraudParams.put('lookbackDays', 1);
        
        BatchProcessingManager fraudBatch = new BatchProcessingManager(
            'FRAUD_DETECTION_ANALYSIS',
        200,
        fraudParams
            );
        Database.executeBatch(fraudBatch, 200);
        
        // Weekly compliance verification
        if (isWeeklySchedule()) {
            BatchProcessingManager complianceBatch = new BatchProcessingManager(
                'COMPLIANCE_VERIFICATION',
            100,
            new Map<String, Object>()
                );
            Database.executeBatch(complianceBatch, 100);
        }
        
        // Monthly performance analytics
        if (isMonthlySchedule()) {
            BatchProcessingManager performanceBatch = new BatchProcessingManager(
                'PERFORMANCE_ANALYTICS',
            500,
            new Map<String, Object>()
                );
            Database.executeBatch(performanceBatch, 500);
            
            // Monthly security cleanup
            Map<String, Object> cleanupParams = new Map<String, Object>();
            cleanupParams.put('retentionDays', 90);
            
            BatchProcessingManager cleanupBatch = new BatchProcessingManager(
                'SECURITY_ASSESSMENT_CLEANUP',
            1000,
            cleanupParams
                );
            Database.executeBatch(cleanupBatch, 1000);
        }
    }
    
    private Boolean isWeeklySchedule() {
        return Math.mod(System.now().day(), 7) == 0;
    }
    
    private Boolean isMonthlySchedule() {
        return System.now().day() == 1;
    }
}
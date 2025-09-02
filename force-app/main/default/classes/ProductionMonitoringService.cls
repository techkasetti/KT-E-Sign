public class ProductionMonitoringService {
    
    @AuraEnabled(cacheable=true)
    public static SystemHealthMetrics getSystemHealth() {
        SystemHealthMetrics metrics = new SystemHealthMetrics();
        
        try {
            // System performance metrics
            metrics.cpuUtilization = getCurrentCPUUsage();
            metrics.memoryUsage = getCurrentMemoryUsage();
            metrics.responseTime = getAverageResponseTime();
            metrics.uptime = getSystemUptime();
            
            // Business metrics
            metrics.activeUsers = getActiveUserCount();
            metrics.documentsProcessedToday = getDocumentsProcessedToday();
            metrics.signatureCompletionRate = getSignatureCompletionRate();
            metrics.errorRate = getErrorRate();
            
            // Security metrics
            metrics.securityAlerts = getActiveSecurityAlerts();
            metrics.fraudAttempts = getFraudAttemptsToday();
            metrics.failedLogins = getFailedLoginsToday();
            
            // Compliance metrics
            metrics.complianceScore = getOverallComplianceScore();
            metrics.auditTrailHealth = getAuditTrailHealth();
            
            return metrics;
            
        } catch (Exception e) {
            System.debug('Error getting system health: ' + e.getMessage());
            return new SystemHealthMetrics(); // Return empty metrics
        }
    }
    
    @AuraEnabled
    public static List<AlertNotification> getActiveAlerts() {
        List<AlertNotification> alerts = new List<AlertNotification>();
        
        // Query system alerts
        List<System_Alert__c> systemAlerts = [
            SELECT Id, Alert_Type__c, Severity__c, Message__c, Created_Date__c, Status__c
            FROM System_Alert__c 
            WHERE Status__c = 'ACTIVE' 
            ORDER BY Severity__c DESC, Created_Date__c DESC
            LIMIT 50
        ];
        
        for (System_Alert__c alert : systemAlerts) {
            alerts.add(new AlertNotification(
                alert.Alert_Type__c,
                alert.Severity__c,
                alert.Message__c,
                alert.Created_Date__c
            ));
        }
        
        return alerts;
    }
    
    @AuraEnabled
    public static PerformanceTrend getPerformanceTrend(Integer days) {
        PerformanceTrend trend = new PerformanceTrend();
        
      // Compute the start date dynamically
Date startDate = Date.today().addDays(-days);

// Get performance data for the specified number of days
List<Performance_Metric__c> metrics = [
    SELECT Date__c, Response_Time__c, Document_Processing_Time__c, 
           Error_Count__c, User_Count__c
    FROM Performance_Metric__c
    WHERE Date__c >= :startDate
    ORDER BY Date__c ASC
];

        
        for (Performance_Metric__c metric : metrics) {
            trend.dates.add(metric.Date__c.format());
            trend.responseTimes.add(metric.Response_Time__c);
            trend.processingTimes.add(metric.Document_Processing_Time__c);
            trend.errorCounts.add(metric.Error_Count__c.intValue());
            trend.userCounts.add(metric.User_Count__c.intValue());
        }
        
        return trend;
    }
    
    private static Decimal getCurrentCPUUsage() {
        // In production, integrate with actual system monitoring
        return Math.random() * 100;
    }
    
    private static Decimal getCurrentMemoryUsage() {
        // Get current heap size usage
        Integer heapUsed = Limits.getHeapSize();
        Integer heapLimit = Limits.getLimitHeapSize();
        return (Decimal.valueOf(heapUsed) / Decimal.valueOf(heapLimit)) * 100;
    }
    
    private static Decimal getAverageResponseTime() {
        List<AggregateResult> results = [
            SELECT AVG(Response_Time__c) avgTime
            FROM Performance_Log__c 
            WHERE CreatedDate = TODAY
        ];
        
        if (!results.isEmpty() && results[0].get('avgTime') != null) {
            return (Decimal)results[0].get('avgTime');
        }
        return 0;
    }
    
    private static Integer getActiveUserCount() {
        return [
            SELECT COUNT() 
            FROM User_Session__c 
            WHERE Status__c = 'ACTIVE' 
            AND Last_Activity__c = TODAY
        ];
    }
    
    private static Integer getDocumentsProcessedToday() {
        return [
            SELECT COUNT() 
            FROM DocumentLifecycleConfiguration__c 
            WHERE CreatedDate = TODAY
        ];
    }
    
    private static Decimal getSignatureCompletionRate() {
       // Total count of records this week
AggregateResult totalResult = [
    SELECT COUNT(Id) total
    FROM Signature_Request__c
    WHERE CreatedDate = THIS_WEEK
];

// Count of completed records this week
AggregateResult completedResult = [
    SELECT COUNT(Id) completed
    FROM Signature_Request__c
    WHERE CreatedDate = THIS_WEEK AND Status__c = 'Completed'
];

// Extract results
Integer total = (Integer) totalResult.get('total');
Integer completed = (Integer) completedResult.get('completed');

        if (!results.isEmpty()) {
            Integer total = (Integer)results[0].get('total');
            Integer completed = (Integer)results[0].get('completed');
            if (total > 0) {
                return (Decimal.valueOf(completed) / Decimal.valueOf(total)) * 100;
            }
        }
        return 0;
    }
}

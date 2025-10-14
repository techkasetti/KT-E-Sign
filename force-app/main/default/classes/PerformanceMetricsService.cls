public class PerformanceMetricsService {
        
    @AuraEnabled(cacheable=true)
    public static PerformanceDashboard getPerformanceMetrics() {
        PerformanceDashboard dashboard = new PerformanceDashboard();
        
        // System performance metrics
        dashboard.averageDocumentGenerationTime = calculateAverageGenerationTime();
        dashboard.averageSignatureProcessingTime = calculateAverageProcessingTime();
        dashboard.systemUptime = calculateSystemUptime();
        dashboard.errorRate = calculateErrorRate();
        
        // User engagement metrics
        dashboard.activeUsers = countActiveUsers();
        dashboard.documentsGenerated = countDocumentsGenerated();
        dashboard.signaturesCompleted = countSignaturesCompleted();
        
        // Security metrics
        dashboard.securityIncidents = countSecurityIncidents();
        dashboard.fraudAttempts = countFraudAttempts();
        dashboard.successfulAuthentications = countSuccessfulAuthentications();
        
        return dashboard;
    }
    
    private static Decimal calculateAverageGenerationTime() {
        List<AggregateResult> results = [
            SELECT AVG(Processing_Time_Seconds__c) avgTime
            FROM DocumentLifecycleConfiguration__c 
            WHERE CreatedDate = LAST_N_DAYS:7 AND Processing_Time_Seconds__c != null
        ];
        
        return results.isEmpty() ? 0 : (Decimal) results[0].get('avgTime');
    }
    
    private static Integer countActiveUsers() {
        return [
            SELECT COUNT_DISTINCT(CreatedById) userCount
            FROM Signature_Request__c 
            WHERE CreatedDate = LAST_N_DAYS:30
        ][0].get('userCount');
    }
    
    @AuraEnabled
    public static void updatePerformanceMetrics() {
        // Real-time metrics update
        Performance_Metrics__c metrics = Performance_Metrics__c.getOrgDefaults();
        if (metrics == null) {
            metrics = new Performance_Metrics__c();
        }
        
        metrics.Last_Updated__c = System.now();
        metrics.Documents_Generated_Today__c = countTodayDocuments();
        metrics.Signatures_Completed_Today__c = countTodaySignatures();
        metrics.System_Health_Score__c = calculateHealthScore();
        
        upsert metrics;
    }
}
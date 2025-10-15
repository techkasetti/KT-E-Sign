public class AdvancedNotificationService {
     @AuraEnabled
    public class AnalyticsSummary {
        @AuraEnabled public Integer totalDocuments;
        @AuraEnabled public Decimal averageGenerationTimeSeconds;
        @AuraEnabled public Map<String,Integer> docsByRegion;
        @AuraEnabled public Map<String, Decimal> performanceByTemplate;
        @AuraEnabled public Decimal overallComplianceScore;
        @AuraEnabled public List<String> insights;
        public AnalyticsSummary(){ docsByRegion = new Map<String,Integer>(); performanceByTemplate = new Map<String,Decimal>(); insights = new List<String>(); }
    }

     public static AnalyticsSummary calculateSummary(Date startDate, Date endDate) {
        AnalyticsSummary s = new AnalyticsSummary();
        try {
            // Document generation metrics (safe aggregates) - pattern appears throughout analytics code @33 @73
            List<AggregateResult> genStats = [
                SELECT COUNT(Id) totalDocuments, AVG(Generation_Time_Seconds__c) avgGenerationTime
                FROM DocumentLifecycleConfiguration__c
                WHERE CreatedDate >= :startDate AND CreatedDate <= :endDate
            ];
            if (!genStats.isEmpty()) {
                s.totalDocuments = ((Integer) genStats[0].get('totalDocuments')) ;
                s.averageGenerationTimeSeconds = genStats[0].get('avgGenerationTime') != null ? (Decimal) genStats[0].get('avgGenerationTime') : 0;
            }

            // Documents by region
            List<AggregateResult> byRegion = [
                SELECT Region__c region, COUNT(Id) cnt
                FROM DocumentLifecycleConfiguration__c
                WHERE CreatedDate >= :startDate AND CreatedDate <= :endDate AND Region__c != null
                GROUP BY Region__c
            ];
            for (AggregateResult ar : byRegion) {
                s.docsByRegion.put((String) ar.get('region'), (Integer) ar.get('cnt'));
            }

            // Performance by template
            List<AggregateResult> byTemplate = [
                SELECT Template_Used__c template, AVG(Generation_Time_Seconds__c) avgTime
                FROM DocumentGenerationLog__c
                WHERE CreatedDate >= :startDate AND CreatedDate <= :endDate AND Template_Used__c != null
                GROUP BY Template_Used__c
            ];
            for (AggregateResult ar : byTemplate) {
                s.performanceByTemplate.put((String) ar.get('template'), (Decimal) ar.get('avgTime'));
            }

            // Compliance score average
            List<AggregateResult> compliance = [
                SELECT AVG(Overall_Compliance_Score__c) avgScore
                FROM DocumentLifecycleConfiguration__c
                WHERE CreatedDate >= :startDate AND CreatedDate <= :endDate AND Overall_Compliance_Score__c != null
            ];
            if (!compliance.isEmpty()) s.overallComplianceScore = compliance[0].get('avgScore') != null ? (Decimal) compliance[0].get('avgScore') : 0;

            // Generate simple insights (this can be extended with AI/ML later)
            if (s.totalDocuments == 0) s.insights.add('No documents generated in period');
            if (s.averageGenerationTimeSeconds > 10) s.insights.add('Average generation time exceeds 10s; consider performance review');

        } catch (Exception e) {
            AuditTrailManager.createAuditEntry(null, 'ADVANCED_ANALYTICS_SERVICE', 'ERROR', 'calculateSummary failed: ' + e.getMessage(), null);
        }
        return s;
    }


     public static void persistAnalyticsReport(String name, AnalyticsSummary summary) {
        try {
            Analytics_Report__c rep = new Analytics_Report__c();
            rep.Name = name + ' - ' + System.now().format();
            rep.Generated_Date__c = System.now();
            rep.Total_Documents__c = summary.totalDocuments;
            rep.Average_Generation_Time__c = summary.averageGenerationTimeSeconds;
            rep.Compliance_Average__c = summary.overallComplianceScore;
            rep.Report_JSON__c = JSON.serialize(summary);
            insert rep;
        } catch (Exception e) {
            AuditTrailManager.createAuditEntry(null, 'ADVANCED_ANALYTICS_SERVICE', 'ERROR', 'persistAnalyticsReport failed: ' + e.getMessage(), null);
        }
    }
    @AuraEnabled(cacheable=false)
    public static Boolean sendAdvancedNotification(String notificationType, String recipientId, Map<String, Object> notificationData) {
        try {
            NotificationRequest request = new NotificationRequest();
            request.type = notificationType;
            request.recipientId = recipientId;
            request.data = notificationData;
            request.timestamp = System.now();
            
            // Route to appropriate notification handler
            switch on notificationType {
                when 'SIGNATURE_REQUEST' {
                    return sendSignatureRequestNotification(request);
                }
                when 'SIGNATURE_COMPLETED' {
                    return sendSignatureCompletedNotification(request);
                }
                when 'DOCUMENT_EXPIRED' {
                    return sendDocumentExpiredNotification(request);
                }
                when 'COMPLIANCE_ALERT' {
                    return sendComplianceAlertNotification(request);
                }
                when 'SYSTEM_ALERT' {
                    return sendSystemAlertNotification(request);
                }
                when 'BATCH_REPORT' {
                    return sendBatchReportNotification(request);
                }
                when 'PREDICTIVE_ALERT' {
                    return sendPredictiveAlertNotification(request);
                }
                when else {
                    return sendGenericNotification(request);
                }
            }
            
        } catch (Exception e) {
            System.debug('Error sending advanced notification: ' + e.getMessage());
            // Log notification failure
            logNotificationFailure(notificationType, recipientId, e.getMessage());
            return false;
        }
    }
}
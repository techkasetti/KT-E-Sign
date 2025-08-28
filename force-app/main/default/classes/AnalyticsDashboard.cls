public class AnalyticsDashboard {
        @AuraEnabled public DocumentMetrics documentMetrics;
        @AuraEnabled public ComplianceMetrics complianceMetrics;
        @AuraEnabled public PerformanceMetrics performanceMetrics;
        @AuraEnabled public UserActivityMetrics userActivityMetrics;
        @AuraEnabled public List&lt;AIInsight&gt; insights;
    }
    
    public class DocumentMetrics {
    @AuraEnabled public Integer totalDocuments;
    @AuraEnabled public Integer documentsCreatedToday;
    @AuraEnabled public Integer averageComplianceScore;
    @AuraEnabled public Map<String, Integer> statusBreakdown;
}

public class ComplianceMetrics {
    @AuraEnabled public Integer totalComplianceChecks;
    @AuraEnabled public Integer passRate;
    @AuraEnabled public List<ComplianceTrend> violationTrends;
}

public class PerformanceMetrics {
    @AuraEnabled public Decimal averageProcessingTime;
    @AuraEnabled public Decimal systemUptime;
    @AuraEnabled public Decimal cacheHitRatio;
    @AuraEnabled public Decimal apiResponseTime;
    @AuraEnabled public Map<String, Decimal> operationMetrics;
}

public class UserActivityMetrics {
    @AuraEnabled public Integer totalActiveUsers;
    @AuraEnabled public Map<String, Integer> actionBreakdown;
    @AuraEnabled public List<ActivityTrend> dailyActivity;
}

public class ComplianceTrend {
    @AuraEnabled public String date;
    @AuraEnabled public Integer count;
}

public class ActivityTrend {
    @AuraEnabled public String date;
    @AuraEnabled public Integer userCount;
}

public class AIInsight {
    @AuraEnabled public String category;
    @AuraEnabled public String severity;
    @AuraEnabled public String title;
    @AuraEnabled public String description;
    @AuraEnabled public String recommendation;
    @AuraEnabled public Integer confidence;
}

// Scheduled analytics processing
public static void scheduleAnalyticsProcessing() {
    String jobName = 'Document Analytics Processing';
    String cronExp = '0 0 2 * * ?'; // Daily at 2 AM
    System.schedule(jobName, cronExp, new DocumentAnalyticsScheduler());
}

// Real-time analytics updates
@future
public static void processRealTimeAnalytics(List<Id> documentIds) {
    try {
        for (Id documentId : documentIds) {
            // Update document analytics
            DocumentAnalyticsSnapshot__c snapshot = new DocumentAnalyticsSnapshot__c(
                DocumentId__c = documentId,
                SnapshotDate__c = Date.today(),
                ProcessingTime__c = System.now(),
                ComplianceScore__c = 0, // Calculate actual score
                ViewCount__c = 0 // Get actual view count
            );
            
            // Calculate real-time metrics
            updateDocumentMetrics(documentId, snapshot);
        }
    } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, 'Real-time analytics processing failed: ' + e.getMessage());
    }
}

private static void updateDocumentMetrics(Id documentId, DocumentAnalyticsSnapshot__c snapshot) {
    // Query document-specific metrics
    List<AggregateResult> metrics = [
        SELECT COUNT(Id) totalViews,
               AVG(ReadTime__c) avgReadTime,
               COUNT_DISTINCT(UserId__c) uniqueUsers
        FROM DocumentViewTracking__c 
        WHERE DocumentId__c = :documentId
        AND ViewDate__c = LAST_N_DAYS:30
    ];
    
    if (!metrics.isEmpty()) {
        AggregateResult result = metrics[0];
        snapshot.ViewCount__c = (Integer) result.get('totalViews');
        snapshot.AverageReadTime__c = (Decimal) result.get('avgReadTime');
        snapshot.UniqueUsers__c = (Integer) result.get('uniqueUsers');
    }
    
    // Insert or update snapshot
    upsert snapshot DocumentId__c;
}
}

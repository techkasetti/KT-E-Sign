public with sharing class DocumentAnalyticsEngine {

    // Performance metrics collection
    @AuraEnabled
    public static AnalyticsDashboard generateAnalyticsDashboard() {
        try {
            AnalyticsDashboard dashboard = new AnalyticsDashboard();
            // Document generation metrics
            dashboard.documentMetrics = getDocumentMetrics();
            // Compliance metrics
            dashboard.complianceMetrics = getComplianceMetrics();
            // Performance metrics
            dashboard.performanceMetrics = getPerformanceMetrics();
            // User activity metrics
            dashboard.userActivityMetrics = getUserActivityMetrics();
            // Generate insights using AI
            dashboard.insights = generateAIInsights(dashboard);
            return dashboard;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to generate analytics dashboard: ' + e.getMessage());
        }
    }

    private static DocumentMetrics getDocumentMetrics() {
        DocumentMetrics metrics = new DocumentMetrics();
        // Query document creation statistics
        List<AggregateResult> documentStats = [
            SELECT COUNT(Id) totalDocs, AVG(ComplianceScore__c) avgCompliance, Status__c status
            FROM DocumentLifecycleConfiguration__c
            WHERE CreatedDate = LAST_N_DAYS:30
            GROUP BY Status__c
        ];

        metrics.totalDocuments = 0;
        metrics.averageComplianceScore = 0;
        metrics.documentsCreatedToday = 0;
        metrics.statusBreakdown = new Map<String, Integer>();

        for (AggregateResult stat : documentStats) {
            Integer count = (Integer) stat.get('totalDocs');
            String status = (String) stat.get('status');
            Decimal avgScore = (Decimal) stat.get('avgCompliance');
            metrics.totalDocuments += count;
            metrics.statusBreakdown.put(status, count);
            if (avgScore != null) {
                // Keep the average of averages logic as in the original
                metrics.averageComplianceScore = avgScore.intValue();
            }
        }
        return metrics;
    }

    private static ComplianceMetrics getComplianceMetrics() {
        ComplianceMetrics metrics = new ComplianceMetrics();
        // Query compliance check results using a valid date function
        List<AggregateResult> complianceStats = [
            SELECT COUNT(Id) totalChecks, Status__c status, DAY_ONLY(Timestamp__c) checkDate
            FROM AuditTrail__c
            WHERE Action__c = 'ADVANCED_COMPLIANCE_CHECK' AND Timestamp__c = LAST_N_DAYS:30
            GROUP BY Status__c, DAY_ONLY(Timestamp__c)
            ORDER BY DAY_ONLY(Timestamp__c) DESC
        ];

        metrics.totalComplianceChecks = 0;
        metrics.passRate = 0;
        metrics.violationTrends = new List<ComplianceTrend>();
        Integer passedChecks = 0;
        Map<Date, Integer> dailyCounts = new Map<Date, Integer>();

        for (AggregateResult stat : complianceStats) {
            Integer count = (Integer) stat.get('totalChecks');
            String status = (String) stat.get('status');
            Date checkDate = (Date) stat.get('checkDate');

            metrics.totalComplianceChecks += count;
            if (status == 'COMPLIANT') {
                passedChecks += count;
            }

            // Track daily trends
            if (!dailyCounts.containsKey(checkDate)) {
                dailyCounts.put(checkDate, 0);
            }
            dailyCounts.put(checkDate, dailyCounts.get(checkDate) + count);
        }

        // Calculate pass rate with decimal division to prevent truncation
        if (metrics.totalComplianceChecks > 0) {
            metrics.passRate = ((Decimal.valueOf(passedChecks) * 100) / metrics.totalComplianceChecks).intValue();
        }

        // Create trend data
        for (Date trendDate : dailyCounts.keySet()) {
            ComplianceTrend trend = new ComplianceTrend();
            trend.trendDate = String.valueOf(trendDate); // Corrected syntax
            trend.count = dailyCounts.get(trendDate);
            metrics.violationTrends.add(trend);
        }
        return metrics;
    }

    private static PerformanceMetrics getPerformanceMetrics() {
        PerformanceMetrics metrics = new PerformanceMetrics();
        // Mock performance data
        metrics.averageProcessingTime = 2.5;
        metrics.systemUptime = 99.7;
        metrics.cacheHitRatio = 87.3;
        metrics.apiResponseTime = 150;

        // Corrected SOQL with GROUP BY and corrected loop logic
        List<AggregateResult> benchmarks = [
            SELECT AVG(ExecutionTime__c) avgTime, OperationType__c
            FROM PerformanceBenchmark__c
            WHERE CreatedDate = LAST_N_DAYS:7
            GROUP BY OperationType__c
        ];

        metrics.operationMetrics = new Map<String, Decimal>();
        for (AggregateResult ar : benchmarks) {
            metrics.operationMetrics.put(
                (String)ar.get('OperationType__c'),
                (Decimal)ar.get('avgTime')
            );
        }
        return metrics;
    }

    private static UserActivityMetrics getUserActivityMetrics() {
        UserActivityMetrics metrics = new UserActivityMetrics();
        // Corrected SOQL using DAY_ONLY
        List<AggregateResult> userStats = [
            SELECT COUNT_DISTINCT(UserDetails__c) activeUsers, DAY_ONLY(Timestamp__c) activityDate, Action__c actionType
            FROM AuditTrail__c
            WHERE Timestamp__c = LAST_N_DAYS:30
            GROUP BY DAY_ONLY(Timestamp__c), Action__c
        ];

        metrics.totalActiveUsers = 0;
        metrics.actionBreakdown = new Map<String, Integer>();
        metrics.dailyActivity = new List<ActivityTrend>();
        Map<Date, Integer> dailyUserCounts = new Map<Date, Integer>();

        for (AggregateResult stat : userStats) {
            Integer userCount = (Integer) stat.get('activeUsers');
            Date activityDate = (Date) stat.get('activityDate');
            String actionType = (String) stat.get('actionType');

            if (!metrics.actionBreakdown.containsKey(actionType)) {
                metrics.actionBreakdown.put(actionType, 0);
            }
            metrics.actionBreakdown.put(actionType, metrics.actionBreakdown.get(actionType) + userCount);

            if (!dailyUserCounts.containsKey(activityDate)) {
                dailyUserCounts.put(activityDate, 0);
            }
            dailyUserCounts.put(activityDate, dailyUserCounts.get(activityDate) + userCount);
        }
        
        // Sum up unique users across days for a total
        Set<Id> totalUniqueUsers = new Set<Id>();
        for(AuditTrail__c trail : [SELECT UserDetails__c FROM AuditTrail__c WHERE Timestamp__c = LAST_N_DAYS:30 AND UserDetails__c != null]) {
            totalUniqueUsers.add(trail.UserDetails__c);
        }
        metrics.totalActiveUsers = totalUniqueUsers.size();


        for (Date trendDate : dailyUserCounts.keySet()) {
            ActivityTrend trend = new ActivityTrend();
            trend.trendDate = String.valueOf(trendDate); // Corrected syntax
            trend.userCount = dailyUserCounts.get(trendDate);
            metrics.dailyActivity.add(trend);
        }
        return metrics;
    }

    private static List<AIInsight> generateAIInsights(AnalyticsDashboard dashboard) {
        List<AIInsight> insights = new List<AIInsight>();

        // Compliance insights
        if (dashboard.complianceMetrics.passRate < 90) {
            AIInsight insight = new AIInsight();
            insight.category = 'COMPLIANCE';
            insight.severity = 'HIGH';
            insight.title = 'Compliance Rate Below Target';
            insight.description = 'Current compliance pass rate (' + dashboard.complianceMetrics.passRate + '%) is below the recommended 90% threshold.';
            insight.recommendation = 'Review common violation patterns and enhance document templates.';
            insight.confidence = 95;
            insights.add(insight);
        }

        // Performance insights
        if (dashboard.performanceMetrics.averageProcessingTime > 3.0) {
            AIInsight insight = new AIInsight();
            insight.category = 'PERFORMANCE';
            insight.severity = 'MEDIUM';
            insight.title = 'Processing Time Above Target';
            insight.description = 'Average document processing time (' + dashboard.performanceMetrics.averageProcessingTime + 's) exceeds the 3-second target.';
            insight.recommendation = 'Consider implementing caching strategies or optimizing document templates.';
            insight.confidence = 87;
            insights.add(insight);
        }

        // Usage insights
        if (dashboard.documentMetrics.documentsCreatedToday < 10) {
            AIInsight insight = new AIInsight();
            insight.category = 'USAGE';
            insight.severity = 'LOW';
            insight.title = 'Low Document Creation Activity';
            insight.description = 'Only ' + dashboard.documentMetrics.documentsCreatedToday + ' documents created today, which is below average.';
            insight.recommendation = 'Consider user training or system promotion to increase adoption.';
            insight.confidence = 73;
            insights.add(insight);
        }
        return insights;
    }

    // --- INNER CLASSES TO DEFINE DATA STRUCTURES ---

    public class AnalyticsDashboard {
        @AuraEnabled public DocumentMetrics documentMetrics;
        @AuraEnabled public ComplianceMetrics complianceMetrics;
        @AuraEnabled public PerformanceMetrics performanceMetrics;
        @AuraEnabled public UserActivityMetrics userActivityMetrics;
        @AuraEnabled public List<AIInsight> insights;
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
        @AuraEnabled public String trendDate;
        @AuraEnabled public Integer count;
    }

    public class ActivityTrend {
        @AuraEnabled public String trendDate;
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
}
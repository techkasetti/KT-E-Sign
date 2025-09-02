public class AnalyticsEngineController {
    
    @AuraEnabled(cacheable=false)
    public static DashboardMetrics getRealTimeDashboard() {
        try {
            DashboardMetrics metrics = new DashboardMetrics();
            
            // Document metrics
            metrics.documentMetrics = getDocumentMetrics();
            
            // Signature metrics
            metrics.signatureMetrics = getSignatureMetrics();
            
            // User behavior metrics
            metrics.userMetrics = getUserBehaviorMetrics();
            
            // System performance metrics
            metrics.performanceMetrics = getPerformanceMetrics();
            
            // Compliance metrics
            metrics.complianceMetrics = getComplianceMetrics();
            
            return metrics;
            
        } catch (Exception e) {
            System.debug('Dashboard metrics error: ' + e.getMessage());
            return getDefaultDashboardMetrics();
        }
    }
    
    private static DocumentMetrics getDocumentMetrics() {
        DocumentMetrics docMetrics = new DocumentMetrics();
        
        // Today's document generation
        List<AggregateResult> todayDocs = [
    SELECT Status__c, COUNT(Id) cnt
    FROM DocumentLifecycleConfiguration__c
    WHERE CreatedDate = TODAY
    GROUP BY Status__c
];
        
        Integer totalDocs = 0;
        Integer completedDocs = 0;
        
        for (AggregateResult ar : todayDocs) {
            totalDocs += (Integer) ar.get('cnt');
            if ((String) ar.get('Status__c') == 'Completed') {
                completedDocs = (Integer) ar.get('cnt');
            }
        }
        
        
        if (!todayDocs.isEmpty()) {
            AggregateResult result = todayDocs[0];
            docMetrics.totalDocumentsToday = (Integer) result.get('totalDocs');
            docMetrics.completedDocumentsToday = (Integer) result.get('completedDocs');
            docMetrics.completionRateToday = docMetrics.totalDocumentsToday > 0 ?
                (docMetrics.completedDocumentsToday * 100.0 / docMetrics.totalDocumentsToday) : 0;
        }
        
        // Document type distribution
        List<AggregateResult> typeDistribution = [
            SELECT Contract_Type__c, COUNT(Id) totalcount
            FROM DocumentLifecycleConfiguration__c 
            WHERE CreatedDate = LAST_N_DAYS:30
            GROUP BY Contract_Type__c
            ORDER BY COUNT(Id) DESC
            LIMIT 10
        ];
        
        Map<String, Integer> distribution = new Map<String, Integer>();
        for (AggregateResult result : typeDistribution) {
            distribution.put((String) result.get('Contract_Type__c'), (Integer) result.get('count'));
        }
        docMetrics.typeDistribution = distribution;
        
        // Average generation time
        List<AggregateResult> avgTime = [
            SELECT AVG(Generation_Time_Minutes__c) avgTime
            FROM DocumentLifecycleConfiguration__c 
            WHERE Generation_Time_Minutes__c != null
            AND CreatedDate = LAST_N_DAYS:7
        ];
        
        if (!avgTime.isEmpty() && avgTime[0].get('avgTime') != null) {
            docMetrics.averageGenerationTime = (Decimal) avgTime[0].get('avgTime');
        }
        
        return docMetrics;
    }
    
    private static SignatureMetrics getSignatureMetrics() {
        SignatureMetrics sigMetrics = new SignatureMetrics();
        
        // Overall completion rates
        // Aggregate requests by Status__c
        List<AggregateResult> completionStats = [
    SELECT Status__c, COUNT(Id) cnt
    FROM Signature_Request__c
    WHERE CreatedDate = LAST_N_DAYS:30
    GROUP BY Status__c
];
        
        // Initialize counts
        Integer totalRequests = 0;
        Integer completedRequests = 0;
        Integer expiredRequests = 0;
        
        // Process results
        for (AggregateResult ar : completionStats) {
            Integer count = (Integer) ar.get('cnt');
            totalRequests += count;
            
            String status = (String) ar.get('Status__c');
            if (status == 'Completed') {
                completedRequests = count;
            } else if (status == 'Expired') {
                expiredRequests = count;
            }
        }
        
        // Now you have totalRequests, completedRequests, expiredRequests
        
        if (!completionStats.isEmpty()) {
            AggregateResult stats = completionStats[0];
            sigMetrics.totalRequests = (Integer) stats.get('totalRequests');
            sigMetrics.completedRequests = (Integer) stats.get('completedRequests');
            sigMetrics.expiredRequests = (Integer) stats.get('expiredRequests');
            sigMetrics.completionRate = sigMetrics.totalRequests > 0 ?
                (sigMetrics.completedRequests * 100.0 / sigMetrics.totalRequests) : 0;
        }
        
        // Signature method performance
        // Aggregate by Signature Method
        List<AggregateResult> methodStatsRaw = [
    SELECT Signature_Method__c method,
           Status__c status,
           COUNT(Id) cnt,
           AVG(Time_To_Complete_Hours__c) avgTime
    FROM Signature_Request__c
    WHERE CreatedDate = LAST_N_DAYS:30
    AND Signature_Method__c != null
    GROUP BY Signature_Method__c, Status__c
];
        
        // Map to store results per method
        Map<String, Map<String, Object>> methodStatsMap = new Map<String, Map<String, Object>>();
        
        for (AggregateResult ar : methodStatsRaw) {
            String method = (String) ar.get('method');
            String status = (String) ar.get('status');
            Integer count = (Integer) ar.get('cnt');
            Decimal avgTime = (Decimal) ar.get('avgTime');
            
            if (!methodStatsMap.containsKey(method)) {
                methodStatsMap.put(method, new Map<String, Object>{
                    'totalCount' => 0,
                    'completedCount' => 0,
                    'avgCompletionTime' => avgTime
                });
            }
            
            Map<String, Object> stats = methodStatsMap.get(method);
            stats.put('totalCount', ((Integer)stats.get('totalCount')) + count);
            
            if (status == 'Completed') {
                stats.put('completedCount', count);
            }
            
            stats.put('avgCompletionTime', avgTime);
        }
        
        // Now methodStatsMap contains all the aggregated data per Signature Method
        
        Map<String, MethodPerformance> methodPerformance = new Map<String, MethodPerformance>();
        for (AggregateResult result : methodStats) {
            String method = (String) result.get('Signature_Method__c');
            Integer total = (Integer) result.get('totalCount');
            Integer completed = (Integer) result.get('completedCount');
            Decimal avgTime = (Decimal) result.get('avgCompletionTime');
            
            MethodPerformance performance = new MethodPerformance();
            performance.method = method;
            performance.totalRequests = total;
            performance.completedRequests = completed;
            performance.completionRate = total > 0 ? (completed * 100.0 / total) : 0;
            performance.averageCompletionTime = avgTime;
            
            methodPerformance.put(method, performance);
        }
        sigMetrics.methodPerformance = methodPerformance;
        
        return sigMetrics;
    }
    
    private static UserBehaviorMetrics getUserBehaviorMetrics() {
        UserBehaviorMetrics userMetrics = new UserBehaviorMetrics();
        
        // Active users
        List<AggregateResult> activeUsers = [
            SELECT COUNT_DISTINCT(User_ID__c) activeUsers
            FROM User_Activity_Log__c 
            WHERE Activity_Date__c = LAST_N_DAYS:7
        ];
        
        if (!activeUsers.isEmpty()) {
            userMetrics.weeklyActiveUsers = (Integer) activeUsers[0].get('activeUsers');
        }
        
        // Peak usage hours
        List<AggregateResult> hourlyUsage = [
            SELECT HOUR_IN_DAY(Activity_Timestamp__c) hour, COUNT(Id) activityCount
            FROM User_Activity_Log__c 
            WHERE Activity_Date__c = LAST_N_DAYS:7
            GROUP BY HOUR_IN_DAY(Activity_Timestamp__c)
            ORDER BY COUNT(Id) DESC
            LIMIT 5
        ];
        
        List<Integer> peakHours = new List<Integer>();
        for (AggregateResult result : hourlyUsage) {
            peakHours.add((Integer) result.get('hour'));
        }
        userMetrics.peakUsageHours = peakHours;
        
        // User engagement score
        userMetrics.averageEngagementScore = calculateAverageEngagement();
        
        return userMetrics;
    }
    
    private static PerformanceMetrics getPerformanceMetrics() {
        PerformanceMetrics perfMetrics = new PerformanceMetrics();
        
        // System response times
        List<AggregateResult> responseTimeStats = [
        SELECT AVG(Response_Time_Ms__c) avgResponseTime,
               MAX(Response_Time_Ms__c) maxResponseTime
        FROM System_Performance_Log__c 
        WHERE Log_Timestamp__c >= :System.now().addDays(-1)
    ];
        
        if (!responseTimeStats.isEmpty()) {
            AggregateResult stats = responseTimeStats[0];
            perfMetrics.averageResponseTime = (Decimal) stats.get('avgResponseTime');
            perfMetrics.maxResponseTime = (Decimal) stats.get('maxResponseTime');
        }
        
        // System uptime
        perfMetrics.systemUptime = calculateSystemUptime();
        
        // Cache hit ratio
        perfMetrics.cacheHitRatio = calculateCacheHitRatio();
        
        return perfMetrics;
    }
    
    private static ComplianceMetrics getComplianceMetrics() {
        ComplianceMetrics complianceMetrics = new ComplianceMetrics();
        
        // Overall compliance score
        List<AggregateResult> complianceScores = [
            SELECT AVG(Overall_Compliance_Score__c) avgScore,
                   MIN(Overall_Compliance_Score__c) minScore,
                   MAX(Overall_Compliance_Score__c) maxScore
            FROM Document_Compliance_Tracking__c 
            WHERE Analysis_Date__c = LAST_N_DAYS:30
            AND Overall_Compliance_Score__c != null
        ];
        
        if (!complianceScores.isEmpty()) {
            AggregateResult scores = complianceScores[0];
            complianceMetrics.averageComplianceScore = (Decimal) scores.get('avgScore');
            complianceMetrics.minimumComplianceScore = (Decimal) scores.get('minScore');
            complianceMetrics.maximumComplianceScore = (Decimal) scores.get('maxScore');
        }
        
        // Compliance violations by type
        List<AggregateResult> violationStats = [
            SELECT Violation_Type__c, COUNT(Id) violationCount
            FROM Compliance_Violation__c 
            WHERE Detection_Date__c = LAST_N_DAYS:30
            GROUP BY Violation_Type__c
            ORDER BY COUNT(Id) DESC
        ];
        
        Map<String, Integer> violationsByType = new Map<String, Integer>();
        for (AggregateResult result : violationStats) {
            violationsByType.put(
                (String) result.get('Violation_Type__c'),
            (Integer) result.get('violationCount')
                );
        }
        complianceMetrics.violationsByType = violationsByType;
        
        // Regional compliance status
        List<AggregateResult> regionalCompliance = [
            SELECT Region__c, 
                   AVG(Overall_Compliance_Score__c) avgRegionalScore,
                   COUNT(Id) totalDocuments
            FROM Document_Compliance_Tracking__c 
            WHERE Analysis_Date__c = LAST_N_DAYS:30
            AND Region__c != null
            GROUP BY Region__c
        ];
        
        Map<String, RegionalComplianceStatus> regionalStatus = new Map<String, RegionalComplianceStatus>();
        for (AggregateResult result : regionalCompliance) {
            RegionalComplianceStatus status = new RegionalComplianceStatus();
            status.region = (String) result.get('Region__c');
            status.averageScore = (Decimal) result.get('avgRegionalScore');
            status.totalDocuments = (Integer) result.get('totalDocuments');
            regionalStatus.put(status.region, status);
        }
        complianceMetrics.regionalStatus = regionalStatus;
        
        return complianceMetrics;
    }
    
    private static Decimal calculateAverageEngagement() {
        List<AggregateResult> engagementStats = [
            SELECT AVG(Session_Duration_Minutes__c) avgDuration,
                   AVG(Actions_Per_Session__c) avgActions
            FROM User_Activity_Log__c 
            WHERE Activity_Date__c = LAST_N_DAYS:7
            AND Session_Duration_Minutes__c != null
        ];
        
        if (!engagementStats.isEmpty()) {
            AggregateResult stats = engagementStats[0];
            Decimal avgDuration = (Decimal) stats.get('avgDuration');
            Decimal avgActions = (Decimal) stats.get('avgActions');
            
            // Calculate engagement score (0-100)
            Decimal durationScore = Math.min(50, avgDuration * 2); // Up to 25 minutes = 50 points
            Decimal actionScore = Math.min(50, avgActions * 5); // Up to 10 actions = 50 points
            return durationScore + actionScore;
        }
        
        return 0;
    }
    
    private static Decimal calculateSystemUptime() {
        List<AggregateResult> uptimeStats = [
    SELECT Status__c status, COUNT(Id) checkCount
    FROM System_Health_Check__c
    WHERE Check_Timestamp__c = LAST_N_DAYS:1
    GROUP BY Status__c
];
        
        Integer totalChecks = 0;
        Integer upChecks = 0;
        for (AggregateResult ar : uptimeStats) {
            String status = (String) ar.get('status');
            Integer count = (Integer) ar.get('checkCount');
            totalChecks += count;
            if (status == 'UP') {
                upChecks = count;
            }
        }
        
        
        if (!uptimeStats.isEmpty()) {
            AggregateResult stats = uptimeStats[0];
            Integer total = (Integer) stats.get('totalChecks');
            Integer up = (Integer) stats.get('upChecks');
            return total > 0 ? (up * 100.0 / total) : 100;
        }
        
        return 100;
    }
    
    private static Decimal calculateCacheHitRatio() {
        List<AggregateResult> cacheStats = [
    SELECT Cache_Hit__c hit, COUNT(Id) requestCount
    FROM Cache_Access_Log__c
    WHERE Access_Time__c = LAST_N_DAYS:1
    GROUP BY Cache_Hit__c
];
        
        Integer totalRequests = 0;
        Integer cacheHits = 0;
        
        for (AggregateResult ar : cacheStats) {
            Boolean hit = (Boolean) ar.get('hit');
            Integer count = (Integer) ar.get('requestCount');
            totalRequests += count;
            if (hit == true) {
                cacheHits = count;
            }
        }
        
        
        if (!cacheStats.isEmpty()) {
            AggregateResult stats = cacheStats[0];
            Integer total = (Integer) stats.get('totalRequests');
            Integer hits = (Integer) stats.get('cacheHits');
            return total > 0 ? (hits * 100.0 / total) : 0;
        }
        
        return 85.0; // Default assumption
    }
    
    private static DashboardMetrics getDefaultDashboardMetrics() {
        DashboardMetrics defaultMetrics = new DashboardMetrics();
        defaultMetrics.documentMetrics = new DocumentMetrics();
        defaultMetrics.signatureMetrics = new SignatureMetrics();
        defaultMetrics.userMetrics = new UserBehaviorMetrics();
        defaultMetrics.performanceMetrics = new PerformanceMetrics();
        defaultMetrics.complianceMetrics = new ComplianceMetrics();
        return defaultMetrics;
    }
    
    // Data classes for analytics
    public class DashboardMetrics {
        @AuraEnabled public DocumentMetrics documentMetrics;
        @AuraEnabled public SignatureMetrics signatureMetrics;
        @AuraEnabled public UserBehaviorMetrics userMetrics;
        @AuraEnabled public PerformanceMetrics performanceMetrics;
        @AuraEnabled public ComplianceMetrics complianceMetrics;
    }
    
    public class DocumentMetrics {
        @AuraEnabled public Integer totalDocumentsToday;
        @AuraEnabled public Integer completedDocumentsToday;
        @AuraEnabled public Decimal completionRateToday;
        @AuraEnabled public Map<String, Integer> typeDistribution;
        @AuraEnabled public Decimal averageGenerationTime;
    }
    
    public class SignatureMetrics {
        @AuraEnabled public Integer totalRequests;
        @AuraEnabled public Integer completedRequests;
        @AuraEnabled public Integer expiredRequests;
        @AuraEnabled public Decimal completionRate;
        @AuraEnabled public Map<String, MethodPerformance> methodPerformance;
    }
    
    public class MethodPerformance {
        @AuraEnabled public String method;
        @AuraEnabled public Integer totalRequests;
        @AuraEnabled public Integer completedRequests;
        @AuraEnabled public Decimal completionRate;
        @AuraEnabled public Decimal averageCompletionTime;
    }
    
    public class UserBehaviorMetrics {
        @AuraEnabled public Integer weeklyActiveUsers;
        @AuraEnabled public List<Integer> peakUsageHours;
        @AuraEnabled public Decimal averageEngagementScore;
    }
    
    public class PerformanceMetrics {
        @AuraEnabled public Decimal averageResponseTime;
        @AuraEnabled public Decimal maxResponseTime;
        @AuraEnabled public Decimal systemUptime;
        @AuraEnabled public Decimal cacheHitRatio;
    }
    
    public class ComplianceMetrics {
        @AuraEnabled public Decimal averageComplianceScore;
        @AuraEnabled public Decimal minimumComplianceScore;
        @AuraEnabled public Decimal maximumComplianceScore;
        @AuraEnabled public Map<String, Integer> violationsByType;
        @AuraEnabled public Map<String, RegionalComplianceStatus> regionalStatus;
    }
    
    public class RegionalComplianceStatus {
        @AuraEnabled public String region;
        @AuraEnabled public Decimal averageScore;
        @AuraEnabled public Integer totalDocuments;
    }
}
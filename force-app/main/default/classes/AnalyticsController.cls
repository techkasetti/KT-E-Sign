public class AnalyticsController {
    
//     private static Integer getTotalRequests() {
//         return [SELECT COUNT() FROM Signature_Request__c];
//     }
//     private static Decimal getCompletionRate() {
//         Integer totalRequests     = [SELECT COUNT() FROM Signature_Request__c];
//         Integer completedRequests = [SELECT COUNT() FROM Signature_Request__c WHERE Status__c = 'Completed'];
        
//         return totalRequests > 0
//             ? (Decimal.valueOf(completedRequests) / Decimal.valueOf(totalRequests)) * 100
//             : 0;
//     }
    
//     private static Decimal getAverageCompletionTime() {
//         List<AggregateResult> results = [
//             SELECT AVG(Time_To_Complete_Hours__c) avgTime
//             FROM Signature_Request__c
//             WHERE Status__c = 'Completed' AND Time_To_Complete_Hours__c != null
//         ];
        
//         if (!results.isEmpty() && results[0].get('avgTime') != null) {
//             Decimal avgHours = (Decimal) results[0].get('avgTime');
//             return avgHours / 24; // convert hours to days
//         }
//         return 0;
//     }
    
//     private static Integer getActiveUserCount() {
//         Set<Id> activeUserIds = new Set<Id>();
//         List<Signature_Request__c> recentRequests = [
//             SELECT CreatedById
//             FROM Signature_Request__c
//             WHERE CreatedDate >= :System.now().addDays(-30)
//         ];
        
//         for (Signature_Request__c request : recentRequests) {
//             activeUserIds.add(request.CreatedById);
//         }
//         return activeUserIds.size();
//     }
//     private static Map<String, Integer> getStatusDistribution() {
//         Map<String, Integer> distribution = new Map<String, Integer>();
//         List<AggregateResult> results = [
//             SELECT Status__c, COUNT(Id) 
//             FROM Signature_Request__c
//             GROUP BY Status__c
//         ];
        
//         for (AggregateResult result : results) {
//             distribution.put((String) result.get('Status__c'),
//             (Integer) result.get('count'));
//         }
//         return distribution;
//     }
    
//     private static Map<String, Integer> getMethodDistribution() {
//         Map<String, Integer> distribution = new Map<String, Integer>();
//         List<AggregateResult> results = [
//             SELECT SignatureMethod__c, COUNT(Id) 
//             FROM Signature_Request__c
//             WHERE Status__c = 'Completed' AND SignatureMethod__c != null
//             GROUP BY SignatureMethod__c
//         ];
        
//         for (AggregateResult result : results) {
//             distribution.put((String) result.get('SignatureMethod__c'),
//             (Integer) result.get('count'));
//         }
//         return distribution;
//     }
   
    
//     private static String getSystemStatus() {
//         try {
//             List<AuditTrail__c> recentErrors = [
//                 SELECT Id
//                 FROM AuditTrail__c
//                 WHERE Status__c = 'ERROR'
//                 AND CreatedDate >= :System.now().addHours(-1)
//                 LIMIT 5
//             ];
            
//             if (recentErrors.size() >= 5) {
//                 return 'Critical';
//             } else if (recentErrors.size() >= 2) {
//                 return 'Warning';
//             } else {
//                 return 'Healthy';
//             }
//         } catch (Exception e) {
//             return 'Unknown';
//         }
//     }
    
//     private static Decimal getSystemUptime() {
//         try {
//             Integer totalHours = 24 * 30; // last 30 days
//             Integer errorHours = getErrorHours();
//             return ((Decimal)(totalHours - errorHours) / (Decimal)totalHours) * 100;
//         } catch (Exception e) {
//             return 99.5; // default fallback
//         }
//     }
    
//     private static Integer getErrorHours() {
//         List<AggregateResult> results = [
//             SELECT HOUR_IN_DAY(CreatedDate) errorHour, DAY_ONLY(CreatedDate) errorDay
//             FROM AuditTrail__c
//             WHERE Status__c = 'ERROR'
//             AND CreatedDate >= :System.now().addDays(-30)
//             GROUP BY HOUR_IN_DAY(CreatedDate), DAY_ONLY(CreatedDate)
//         ];
//         return results.size();
//     }
    
//     private static Decimal getPerformanceScore() {
//         try {
//             Decimal score = 100.0;
            
//             // Deduct for completion time
//             Decimal avgCompletionTime = getAverageCompletionTime();
//             if (avgCompletionTime > 7) {
//                 score -= 20;
//             } else if (avgCompletionTime > 3) {
//                 score -= 10;
//             }
            
//             // Deduct for completion rate
//             Decimal completionRate = getCompletionRate();
//             if (completionRate < 70) {
//                 score -= 25;
//             } else if (completionRate < 85) {
//                 score -= 10;
//             }
            
//             // Deduct for errors
//             Integer errorCount = [
//                 SELECT COUNT()
//                 FROM AuditTrail__c
//                 WHERE Status__c = 'ERROR'
//                 AND CreatedDate >= :System.now().addDays(-7)
//             ];
//             if (errorCount > 50) {
//                 score -= 30;
//             } else if (errorCount > 10) {
//                 score -= 15;
//             }
            
//             return Math.max(0, score);
//         } catch (Exception e) {
//             return 75.0;
//         }
//     }
    
//     private static String getActionFromStatus(String status) {
//         switch on status {
//             when 'Pending'   { return 'Signature Request Sent'; }
//             when 'Completed' { return 'Document Signed'; }
//             when 'Rejected'  { return 'Signature Declined'; }
//             when 'Expired'   { return 'Request Expired'; }
//             when else        { return 'Status Updated'; }
//         }
//     }
//     @AuraEnabled(cacheable=true)
//     public static AnalyticsData getAnalyticsData() {
//         try {
//             AnalyticsData data = new AnalyticsData();
            
//             // Get basic metrics
          
//             data.avgCompletionTime = getAverageCompletionTime();
//             data.activeUsers       = getActiveUserCount();
            
//             // Get distribution
//             data.statusDistribution = getStatusDistribution();
//             data.methodDistribution = getMethodDistribution();
//             data.completionTrends   = getCompletionTrends();
            
//             // Get system health
//             data.systemStatus    = getSystemStatus();
//             data.systemUptime    = getSystemUptime();
//             data.performanceScore = getPerformanceScore();
            
//             return data;
//         } catch (Exception e) {
//             System.debug('Analytics Controller Error: ' + e.getMessage());
//             throw new AuraHandledException('Failed to load analytics data: ' + e.getMessage());
//         }
//     }
//     @AuraEnabled(cacheable=true)
//     public static List<RecentActivity> getRecentActivity(Integer limitCount) {
//         try {
//             List<RecentActivity> activities = new List<RecentActivity>();
            
//             List<Signature_Request__c> recentRequests = [
//                 SELECT Id, SignerName__c, Status__c, CreatedDate, CompletedDate__c,
//                        DocumentId__r.DocumentTitle__c
//                 FROM Signature_Request__c
//                 ORDER BY CreatedDate DESC
//                 LIMIT :limitCount
//             ];
            
//             for (Signature_Request__c request : recentRequests) {
//                 RecentActivity activity = new RecentActivity();
//                 activity.id           = request.Id;
//                 activity.documentTitle = request.DocumentId__r.DocumentTitle__c;
//                 activity.signerName   = request.SignerName__c;
//                 activity.status       = request.Status__c;
//                 activity.action       = getActionFromStatus(request.Status__c);
//                 activity.activityDate = request.Status__c == 'Completed'
//                     ? request.CompletedDate__c
//                     : request.CreatedDate;
//                 activities.add(activity);
//             }
//             return activities;
//         } catch (Exception e) {
//             System.debug('Recent Activity Error: ' + e.getMessage());
//             throw new AuraHandledException('Failed to load recent activity: ' + e.getMessage());
//         }
//     }
//     /**
//      * Get comprehensive analytics data for dashboard
//      */
    
    
//     /**
//      * Get document generation metrics
//      */
//     private static DocumentMetrics getDocumentMetrics(Date startDate) {
//         DocumentMetrics metrics = new DocumentMetrics();
        
//         // Total documents
//         metrics.totalDocuments = [
//             SELECT COUNT() 
//             FROM DocumentLifecycleConfiguration__c 
//             WHERE CreatedDate >= :startDate
//         ];
        
//         // Documents by status
//         List<AggregateResult> statusBreakdown = [
//             SELECT Status__c, COUNT(Id) totalcount
//             FROM DocumentLifecycleConfiguration__c 
//             WHERE CreatedDate >= :startDate
//             GROUP BY Status__c
//         ];
        
//         metrics.statusBreakdown = new Map<String, Integer>();
//         for (AggregateResult ar : statusBreakdown) {
//             metrics.statusBreakdown.put(
//                 (String)ar.get('Status__c'),
//             (Integer)ar.get('count')
//                 );
//         }
        
//         // Documents by type
//         List<AggregateResult> typeBreakdown = [
//             SELECT ContractType__c, COUNT(Id) totalcount
//             FROM DocumentLifecycleConfiguration__c 
//             WHERE CreatedDate >= :startDate
//             GROUP BY ContractType__c
//         ];
        
//         metrics.typeBreakdown = new Map<String, Integer>();
//         for (AggregateResult ar : typeBreakdown) {
//             metrics.typeBreakdown.put(
//                 (String)ar.get('ContractType__c'),
//             (Integer)ar.get('count')
//                 );
//         }
        
//         // Average compliance score
//         AggregateResult avgCompliance = [
//             SELECT AVG(ComplianceScore__c) avgScore
//             FROM DocumentLifecycleConfiguration__c 
//             WHERE CreatedDate >= :startDate AND ComplianceScore__c != null
//         ];
        
//         metrics.averageComplianceScore = avgCompliance.get('avgScore') != null ?
//             (Decimal)avgCompliance.get('avgScore') : 0;
        
//         return metrics;
//     }
    
//     /**
//      * Get signature request metrics
//      */
//     private static SignatureMetrics getSignatureMetrics(Date startDate) {
//         SignatureMetrics metrics = new SignatureMetrics();
        
//         // Total signature requests
//         metrics.totalRequests = [
//             SELECT COUNT() 
//             FROM Signature_Request__c 
//             WHERE CreatedDate >= :startDate
//         ];
        
//         // Completed signatures
//         metrics.completedSignatures = [
//             SELECT COUNT() 
//             FROM Signature_Request__c 
//             WHERE CreatedDate >= :startDate AND Status__c = 'Signed'
//         ];
        
//         // Pending signatures
//         metrics.pendingSignatures = [
//             SELECT COUNT() 
//             FROM Signature_Request__c 
//             WHERE CreatedDate >= :startDate AND Status__c = 'Pending'
//         ];
        
//         // Rejected signatures
//         metrics.rejectedSignatures = [
//             SELECT COUNT() 
//             FROM Signature_Request__c 
//             WHERE CreatedDate >= :startDate AND Status__c = 'Rejected'
//         ];
        
//         // Calculate completion rate
//         metrics.completionRate = metrics.totalRequests > 0 ?
//             (Decimal)metrics.completedSignatures / metrics.totalRequests * 100 : 0;
        
//         // Average completion time
//         AggregateResult avgTime = [
//             SELECT AVG(CompletionTimeHours__c) avgTime
//             FROM Signature_Request__c 
//             WHERE CreatedDate >= :startDate 
//             AND Status__c = 'Signed' 
//             AND CompletionTimeHours__c != null
//         ];
        
//         metrics.averageCompletionTime = avgTime.get('avgTime') != null ?
//             (Decimal)avgTime.get('avgTime') : 0;
        
//         return metrics;
//     }
    
//     /**
//      * Get system performance metrics
//      */
//     private static PerformanceMetrics getPerformanceMetrics(Date startDate) {
//         PerformanceMetrics metrics = new PerformanceMetrics();
        
//         // CPU utilization (simulated - replace with actual monitoring)
//         metrics.cpuUtilization = Math.random() * 100;
        
//         // Memory usage (simulated - replace with actual monitoring)
//         metrics.memoryUsage = Math.random() * 100;
        
//         // API response times from logs
//         List<AggregateResult> apiTimes = [
//             SELECT AVG(ResponseTime__c) avgResponse, MAX(ResponseTime__c) maxResponse
//             FROM API_Request_Log__c 
//             WHERE CreatedDate >= :startDate
//         ];
        
//         if (!apiTimes.isEmpty() && apiTimes[0].get('avgResponse') != null) {
//             metrics.averageApiResponseTime = (Decimal)apiTimes[0].get('avgResponse');
//             metrics.maxApiResponseTime = (Decimal)apiTimes[0].get('maxResponse');
//         } else {
//             metrics.averageApiResponseTime = 150; // Default placeholder
//             metrics.maxApiResponseTime = 300; // Default placeholder
//         }
        
//         // System uptime (calculated from last system restart)
//         List<AuditTrail__c> lastRestart = [
//             SELECT CreatedDate 
//             FROM AuditTrail__c 
//             WHERE Action__c = 'SYSTEM_RESTART' 
//             ORDER BY CreatedDate DESC 
//             LIMIT 1
//         ];
        
//         if (!lastRestart.isEmpty()) {
//             Long uptimeMs = System.now().getTime() - lastRestart[0].CreatedDate.getTime();
//             metrics.systemUptimeHours = uptimeMs / (1000 * 60 * 60);
//         } else {
//             metrics.systemUptimeHours = 720; // Default 30 days
//         }
        
//         return metrics;
//     }
    
//     /**
//      * Get compliance metrics
//      */
//     private static ComplianceMetrics getComplianceMetrics(Date startDate) {
//         ComplianceMetrics metrics = new ComplianceMetrics();
        
//         // Total compliance checks
//         metrics.totalChecks = [
//             SELECT COUNT() 
//             FROM AuditTrail__c 
//             WHERE CreatedDate >= :startDate AND Action__c = 'COMPLIANCE_CHECK'
//         ];
        
//         // Passed compliance checks
//         metrics.passedChecks = [
//             SELECT COUNT() 
//             FROM AuditTrail__c 
//             WHERE CreatedDate >= :startDate 
//             AND Action__c = 'COMPLIANCE_CHECK' 
//             AND Status__c = 'SUCCESS'
//         ];
        
//         // Calculate pass rate
//         metrics.passRate = metrics.totalChecks > 0 ?
//             (Decimal)metrics.passedChecks / metrics.totalChecks * 100 : 100;
        
//         // Compliance violations by type
//         List<AggregateResult> violations = [
//             SELECT Details__c violationType, COUNT(Id) totalcount
//             FROM AuditTrail__c 
//             WHERE CreatedDate >= :startDate 
//             AND Action__c = 'COMPLIANCE_VIOLATION'
//             GROUP BY Details__c
//         ];
        
//         metrics.violationBreakdown = new Map<String, Integer>();
//         for (AggregateResult ar : violations) {
//             metrics.violationBreakdown.put(
//                 (String)ar.get('violationType'),
//             (Integer)ar.get('count')
//                 );
//         }
        
//         return metrics;
//     }
    
//     /**
//      * Get user activity metrics
//      */
//     private static UserActivityMetrics getUserActivityMetrics(Date startDate) {
//         UserActivityMetrics metrics = new UserActivityMetrics();
        
//         // Active users
//         Set<Id> activeUserIds = new Set<Id>();
//         for (AuditTrail__c audit : [
//             SELECT UserId__c 
//             FROM AuditTrail__c 
//             WHERE CreatedDate >= :startDate AND UserId__c != null
//         ]) {
//             activeUserIds.add(audit.UserId__c);
//         }
//         metrics.activeUsers = activeUserIds.size();
        
//         // User actions breakdown
//         List<AggregateResult> actions = [
//             SELECT Action__c, COUNT(Id) totalcount
//             FROM AuditTrail__c 
//             WHERE CreatedDate >= :startDate
//             GROUP BY Action__c
//         ];
        
//         metrics.actionBreakdown = new Map<String, Integer>();
//         for (AggregateResult ar : actions) {
//             metrics.actionBreakdown.put(
//                 (String)ar.get('Action__c'),
//             (Integer)ar.get('count')
//                 );
//         }
        
//         // Peak usage hours
//         List<AggregateResult> hourlyUsage = [
//             SELECT HOUR_IN_DAY(CreatedDate) hour, COUNT(Id) totalcount
//             FROM AuditTrail__c 
//             WHERE CreatedDate >= :startDate
//             GROUP BY HOUR_IN_DAY(CreatedDate)
//             ORDER BY COUNT(Id) DESC
//             LIMIT 3
//         ];
        
//         metrics.peakUsageHours = new List<Integer>();
//         for (AggregateResult ar : hourlyUsage) {
//             metrics.peakUsageHours.add((Integer)ar.get('hour'));
//         }
        
//         return metrics;
//     }
    
//     /**
//      * Get trend analysis data
//      */
//     private static TrendAnalysis getTrendAnalysis(Date startDate) {
//         TrendAnalysis trends = new TrendAnalysis();
        
//         // Daily document generation trend
//         List<AggregateResult> dailyDocs = [
//             SELECT DAY_ONLY(CreatedDate) day, COUNT(Id) totalcount
//             FROM DocumentLifecycleConfiguration__c 
//             WHERE CreatedDate >= :startDate
//             GROUP BY DAY_ONLY(CreatedDate)
//             ORDER BY DAY_ONLY(CreatedDate)
//         ];
        
//         trends.dailyDocuments = new Map<Date, Integer>();
//         for (AggregateResult ar : dailyDocs) {
//             trends.dailyDocuments.put(
//                 (Date)ar.get('day'),
//             (Integer)ar.get('count')
//                 );
//         }
        
//         // Weekly signature trend
//         List<AggregateResult> weeklySignatures = [
//             SELECT WEEK_IN_YEAR(CreatedDate) week, COUNT(Id) totalcount
//             FROM Signature_Request__c 
//             WHERE CreatedDate >= :startDate AND Status__c = 'Signed'
//             GROUP BY WEEK_IN_YEAR(CreatedDate)
//             ORDER BY WEEK_IN_YEAR(CreatedDate)
//         ];
       
        
//         trends.weeklySignatures = new Map<Integer, Integer>();
//         for (AggregateResult ar : weeklySignatures) {
//             trends.weeklySignatures.put(
//                 (Integer)ar.get('week'),
//             (Integer)ar.get('count')
//                 );
//         }
        
//         // Monthly compliance trends
//         List<AggregateResult> monthlyCompliance = [
//             SELECT CALENDAR_MONTH(CreatedDate) month, 
//                    AVG(ComplianceScore__c) avgScore,
//                    COUNT(Id) totalDocs
//             FROM DocumentLifecycleConfiguration__c
//             WHERE CreatedDate >= :startDate AND ComplianceScore__c != null
//             GROUP BY CALENDAR_MONTH(CreatedDate)
//             ORDER BY CALENDAR_MONTH(CreatedDate)
//         ];
        
//         trends.monthlyCompliance = new Map<Integer, Decimal>();
//         for (AggregateResult ar : monthlyCompliance) {
//             trends.monthlyCompliance.put(
//                 (Integer)ar.get('month'),
//             (Decimal)ar.get('avgScore')
//                 );
//         }
        
//         return trends;
//     }
    
//     /**
//      * Generate AI-powered insights from analytics data
//      */
//     private static AIInsights generateAIInsights(AnalyticsData data) {
//         AIInsights insights = new AIInsights();
//         insights.insights = new List<String>();
//         insights.recommendations = new List<String>();
//         insights.predictions = new List<String>();
        
//         // Signature completion rate analysis
//         if (data.signatureMetrics.completionRate < 70) {
//             insights.insights.add('Signature completion rate is below optimal threshold at ' +
//                 data.signatureMetrics.completionRate.setScale(1) + '%');
//             insights.recommendations.add('Consider implementing reminder notifications and simplifying signature process');
//         } else if (data.signatureMetrics.completionRate > 90) {
//             insights.insights.add('Excellent signature completion rate of ' +
//                 data.signatureMetrics.completionRate.setScale(1) + '%');
//         }
        
//         // Document generation volume analysis
//         Integer currentVolume = data.documentMetrics.totalDocuments;
//         if (currentVolume > 1000) {
//             insights.insights.add('High document generation volume detected: ' + currentVolume + ' documents');
//             insights.recommendations.add('Consider implementing automated batch processing for better performance');
//         }
        
//         // Compliance score analysis
//         if (data.documentMetrics.averageComplianceScore < 80) {
//             insights.insights.add('Average compliance score is concerning at ' +
//                 data.documentMetrics.averageComplianceScore.setScale(1) + '%');
//             insights.recommendations.add('Review compliance rules and consider additional validation steps');
//         }
        
//         // Performance analysis
//         if (data.performanceMetrics.averageApiResponseTime > 200) {
//             insights.insights.add('API response times are elevated at ' +
//                 data.performanceMetrics.averageApiResponseTime.setScale(0) + 'ms');
//             insights.recommendations.add('Optimize database queries and consider caching strategies');
//         }
        
//         // Predictive insights based on trends
//         if (!data.trendAnalysis.weeklySignatures.isEmpty()) {
//             List<Integer> weeklyValues = data.trendAnalysis.weeklySignatures.values();
//             if (weeklyValues.size() >= 2) {
//                 Integer lastWeek = weeklyValues[weeklyValues.size() - 1];
//                 Integer previousWeek = weeklyValues[weeklyValues.size() - 2];
//                 if (lastWeek > previousWeek * 1.2) {
//                     insights.predictions.add('Signature volume trending upward - expect 20% increase next week');
//                 } else if (lastWeek < previousWeek * 0.8) {
//                     insights.predictions.add('Signature volume declining - investigate potential issues');
//                 }
//             }
//         }
        
//         return insights;
//     }
    
//     /**
//      * Get real-time metrics for dashboard refresh
//      */
//     @AuraEnabled
//     public static RealTimeMetrics getRealTimeMetrics() {
//         try {
//             RealTimeMetrics metrics = new RealTimeMetrics();
            
//             // Today's metrics
//             Date today = Date.today();
            
//             metrics.todayDocuments = [
//                 SELECT COUNT() FROM DocumentLifecycleConfiguration__c 
//                 WHERE CreatedDate = TODAY
//             ];
            
//             metrics.todaySignatures = [
//                 SELECT COUNT() FROM Signature_Request__c 
//                 WHERE CreatedDate = TODAY AND Status__c = 'Signed'
//             ];
            
//             metrics.pendingSignatures = [
//                 SELECT COUNT() FROM Signature_Request__c 
//                 WHERE Status__c = 'Pending'
//             ];
            
         
            
//             // System status
//             metrics.systemStatus = getSystemHealth();
            
//             return metrics;
            
//         } catch (Exception e) {
//             AuditTrailManager.createAuditEntry(
//                 null,
//             'Real-Time Metrics Error',
//             'Error',
//             'Error: ' + e.getMessage()
//                 );
//             throw new AuraHandledException('Unable to retrieve real-time metrics: ' + e.getMessage());
//         }
//     }
    
//     /**
//      * Get system health status
//      */
//     private static String getSystemHealth() {
//         try {
//             // Check recent errors
//             Integer recentErrors = 0;
//             List<AggregateResult> errorResults = [
//                 SELECT COUNT(Id) errorCount FROM AuditTrail__c 
//                 WHERE CreatedDate >= :System.now().addHours(-1) 
//                 AND Status__c = 'ERROR'
//             ];
//             if (!errorResults.isEmpty() && errorResults[0].get('errorCount') != null) {
//                 recentErrors = (Integer)errorResults[0].get('errorCount');
//             }
//             if (recentErrors == 0) {
//                 return 'Healthy';
//             } else if (recentErrors < 5) {
//                 return 'Warning';
//             } else {
//                 return 'Critical';
//             }
//         } catch (Exception e) {
//             return 'Unknown';
//         }
//     }
//     public static List<TrendData> getCompletionTrends() {
//     List<TrendData> trends = new List<TrendData>();
//     Date startDate = System.today().addDays(-30);
//     for (Integer i = 0; i <= 30; i++) {
//         Date currentDate = startDate.addDays(i);
//         TrendData trend = new TrendData();
//         trend.trendDate = currentDate;
//         Integer completed = [
//             SELECT COUNT() FROM Signature_Request__c
//             WHERE Status__c = 'Completed'
//             AND DAY_ONLY(CompletedDate__c) = :currentDate
//         ];
//         Integer created = [
//             SELECT COUNT() FROM Signature_Request__c
//             WHERE DAY_ONLY(CreatedDate) = :currentDate
//         ];
//         trend.completed = completed;
//         trend.created   = created;
//         trends.add(trend);
//     }
//     return trends;
// }public class TrendData {
//     @AuraEnabled public Date trendDate;
//     @AuraEnabled public Integer completed;
//     @AuraEnabled public Integer created;
// }
//     // Data wrapper classes
//     public class AnalyticsData {
//         @AuraEnabled public DocumentMetrics documentMetrics;
//         @AuraEnabled public SignatureMetrics signatureMetrics;
//         @AuraEnabled public PerformanceMetrics performanceMetrics;
//         @AuraEnabled public ComplianceMetrics complianceMetrics;
//         @AuraEnabled public UserActivityMetrics userActivityMetrics;
//         @AuraEnabled public TrendAnalysis trendAnalysis;
//         @AuraEnabled public AIInsights aiInsights;
//         @AuraEnabled public Decimal performanceScore;
//     @AuraEnabled public Integer activeUsers;
//     @AuraEnabled public Map<String, Integer> statusDistribution;
//     @AuraEnabled public Map<String, Integer> methodDistribution;
//     @AuraEnabled public Decimal avgCompletionTime;
//     @AuraEnabled public List<TrendData> completionTrends;
//     @AuraEnabled public String systemStatus;
//     @AuraEnabled public Decimal systemUptime;
//     }
    
//     public class DocumentMetrics {
//         @AuraEnabled public Integer totalDocuments;
//         @AuraEnabled public Map<String, Integer> statusBreakdown;
//         @AuraEnabled public Map<String, Integer> typeBreakdown;
//         @AuraEnabled public Decimal averageComplianceScore;
//     }
    
//     public class SignatureMetrics {
//         @AuraEnabled public Integer totalRequests;
//         @AuraEnabled public Integer completedSignatures;
//         @AuraEnabled public Integer pendingSignatures;
//         @AuraEnabled public Integer rejectedSignatures;
//         @AuraEnabled public Decimal completionRate;
//         @AuraEnabled public Decimal averageCompletionTime;
//     }
    
//     public class PerformanceMetrics {
//         @AuraEnabled public Decimal cpuUtilization;
//         @AuraEnabled public Decimal memoryUsage;
//         @AuraEnabled public Decimal averageApiResponseTime;
//         @AuraEnabled public Decimal maxApiResponseTime;
//         @AuraEnabled public Decimal systemUptimeHours;
//     }
    
//     public class ComplianceMetrics {
//         @AuraEnabled public Integer totalChecks;
//         @AuraEnabled public Integer passedChecks;
//         @AuraEnabled public Decimal passRate;
//         @AuraEnabled public Map<String, Integer> violationBreakdown;
//     }
    
//     public class UserActivityMetrics {
//         @AuraEnabled public Integer activeUsers;
//         @AuraEnabled public Map<String, Integer> actionBreakdown;
//         @AuraEnabled public List<Integer> peakUsageHours;
//     }
    
//     public class TrendAnalysis {
//         @AuraEnabled public Map<Date, Integer> dailyDocuments;
//         @AuraEnabled public Map<Integer, Integer> weeklySignatures;
//         @AuraEnabled public Map<Integer, Decimal> monthlyCompliance;
//     }
    
//     public class AIInsights {
//         @AuraEnabled public List<String> insights;
//         @AuraEnabled public List<String> recommendations;
//         @AuraEnabled public List<String> predictions;
//     }
    
//     public class RealTimeMetrics {
//         @AuraEnabled public Integer todayDocuments;
//         @AuraEnabled public Integer todaySignatures;
//         @AuraEnabled public Integer pendingSignatures;
//         @AuraEnabled public Integer activeUsers;
//         @AuraEnabled public String systemStatus;
//     }
//     public class RecentActivity {
//         @AuraEnabled public String id;
//         @AuraEnabled public String documentTitle;
//         @AuraEnabled public String signerName;
//         @AuraEnabled public String action;
//         @AuraEnabled public String status;
//         @AuraEnabled public DateTime activityDate;
//     }
    
}
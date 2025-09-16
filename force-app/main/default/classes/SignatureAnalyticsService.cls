public with sharing class SignatureAnalyticsService {
    @AuraEnabled(cacheable=true)
    public static SignatureAnalytics getSignatureCompletionAnalytics(String dateRange) {
        Date startDate = getStartDate(dateRange);
        Date endDate = Date.today();
        
        // Get signature requests in date range
        List<AggregateResult> results = [
            SELECT Status__c, COUNT(Id) totalCount
            FROM Signature_Request__c 
            WHERE CreatedDate >= :startDate AND CreatedDate <= :endDate
            GROUP BY Status__c
        ];
        
        SignatureAnalytics analytics = new SignatureAnalytics();
        Integer totalRequests = 0;
        Integer completedRequests = 0;
        
        for (AggregateResult result : results) {
            String status = (String) result.get('Status__c');
            Integer count = (Integer) result.get('totalCount');
            totalRequests += count;
            
            if (status == 'Completed' || status == 'Signed') {
                completedRequests += count;
            }
            
            analytics.statusBreakdown.put(status, count);
        }
        
        analytics.completionRate = totalRequests > 0 ? (Decimal.valueOf(completedRequests) / totalRequests) * 100 : 0;
        analytics.totalRequests = totalRequests;
        analytics.completedRequests = completedRequests;
        
        // Calculate trends
        analytics.trendData = calculateCompletionTrends(startDate, endDate);
        
        return analytics;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<UserBehaviorPattern> analyzeUserBehaviorPatterns() {
        List<UserBehaviorPattern> patterns = new List<UserBehaviorPattern>();
        
        // Analyze signing patterns by user
        List<AggregateResult> userAnalytics = [
            SELECT SignerEmail__c, 
                   AVG(Time_to_Complete__c) avgTime,
                   COUNT(Id) totalSigned,
                   AVG(HOUR_IN_DAY(CompletedDate__c)) avgHour
            FROM Signature_Request__c 
            WHERE Status__c = 'Completed' AND CompletedDate__c = LAST_N_DAYS:30
            GROUP BY SignerEmail__c
            HAVING COUNT(Id) > 1
        ];
        
        for (AggregateResult result : userAnalytics) {
            UserBehaviorPattern pattern = new UserBehaviorPattern();
            pattern.userEmail = (String) result.get('SignerEmail__c');
            pattern.averageCompletionTime = (Decimal) result.get('avgTime');
            pattern.totalSignatures = (Integer) result.get('totalSigned');
            pattern.preferredSigningHour = (Integer) result.get('avgHour');
            
            // Classify user behavior
            if (pattern.averageCompletionTime < 5) {
                pattern.behaviorType = 'Fast Signer';
            } else if (pattern.averageCompletionTime > 24) {
                pattern.behaviorType = 'Delayed Signer';
            } else {
                pattern.behaviorType = 'Normal Signer';
            }
            
            patterns.add(pattern);
        }
        
        return patterns;
    }
    
}
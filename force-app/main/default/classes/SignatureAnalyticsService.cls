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
        
        // Helper map to aggregate data by user email
        Map<String, List<Signature_Request__c>> requestsByUser = new Map<String, List<Signature_Request__c>>();

        // Query for individual signature requests
        List<Signature_Request__c> completedRequests = [
            SELECT SignerEmail__c, Time_to_Complete__c, CompletedDate__c
            FROM Signature_Request__c 
            WHERE Status__c = 'Completed' AND CompletedDate__c = LAST_N_DAYS:30 AND SignerEmail__c != null
        ];

        // Group requests by signer email in Apex
        for (Signature_Request__c req : completedRequests) {
            if (!requestsByUser.containsKey(req.SignerEmail__c)) {
                requestsByUser.put(req.SignerEmail__c, new List<Signature_Request__c>());
            }
            requestsByUser.get(req.SignerEmail__c).add(req);
        }

        // Process each user's aggregated data
        for (String email : requestsByUser.keySet()) {
            List<Signature_Request__c> userRequests = requestsByUser.get(email);
            
            // Skip users with only one signature for this analysis
            if (userRequests.size() <= 1) {
                continue;
            }

            Decimal totalCompletionTime = 0;
            Decimal totalSigningHour = 0;
            for (Signature_Request__c req : userRequests) {
                if (req.Time_to_Complete__c != null) {
                    totalCompletionTime += req.Time_to_Complete__c;
                }
                if (req.CompletedDate__c != null) {
                    totalSigningHour += req.CompletedDate__c.hourGmt();
                }
            }

            UserBehaviorPattern pattern = new UserBehaviorPattern();
            pattern.userEmail = email;
            pattern.totalSignatures = userRequests.size();
            pattern.averageCompletionTime = totalCompletionTime / userRequests.size();
            pattern.preferredSigningHour = (Integer)(totalSigningHour / userRequests.size());
            
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
    
    private static Date getStartDate(String dateRange) {
        Date startDate = Date.today();
        if (dateRange == 'LAST_7_DAYS') {
            startDate = Date.today().addDays(-7);
        } else if (dateRange == 'LAST_30_DAYS') {
            startDate = Date.today().addDays(-30);
        } else if (dateRange == 'LAST_90_DAYS') {
            startDate = Date.today().addDays(-90);
        }
        return startDate;
    }

    private static List<TrendData> calculateCompletionTrends(Date startDate, Date endDate) {
        List<TrendData> trendData = new List<TrendData>();
        Map<Date, Integer> completionCounts = new Map<Date, Integer>();

        List<AggregateResult> results = [
            SELECT CompletedDate__c completedDate, COUNT(Id) total
            FROM Signature_Request__c
            WHERE Status__c = 'Completed' AND CompletedDate__c >= :startDate AND CompletedDate__c <= :endDate
            GROUP BY CompletedDate__c
            ORDER BY CompletedDate__c
        ];

        for (AggregateResult ar : results) {
            Date completedDate = (Date)ar.get('completedDate');
            completionCounts.put(completedDate, (Integer)ar.get('total'));
        }
        
        for (Integer i = 0; i <= startDate.daysBetween(endDate); i++) {
            Date currentDay = startDate.addDays(i);
            Integer count = completionCounts.get(currentDay);
            if (count == null) {
                count = 0;
            }
            trendData.add(new TrendData(currentDay, count));
        }

        return trendData;
    }

    public class SignatureAnalytics {
        @AuraEnabled public Decimal completionRate { get; set; }
        @AuraEnabled public Integer totalRequests { get; set; }
        @AuraEnabled public Integer completedRequests { get; set; }
        @AuraEnabled public Map<String, Integer> statusBreakdown { get; set; }
        @AuraEnabled public List<TrendData> trendData { get; set; }
        public SignatureAnalytics() {
            statusBreakdown = new Map<String, Integer>();
            trendData = new List<TrendData>();
        }
    }

    public class UserBehaviorPattern {
        @AuraEnabled public String userEmail { get; set; }
        @AuraEnabled public Decimal averageCompletionTime { get; set; }
        @AuraEnabled public Integer totalSignatures { get; set; }
        @AuraEnabled public Integer preferredSigningHour { get; set; }
        @AuraEnabled public String behaviorType { get; set; }
    }

    public class TrendData {
        @AuraEnabled public Date dateValue { get; set; }
        @AuraEnabled public Integer count { get; set; }
        public TrendData(Date dateValue, Integer count) {
            this.dateValue = dateValue;
            this.count = count;
        }
    }
}
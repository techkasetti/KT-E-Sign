public class APISecurityManager {
    private static final Integer HOURLY_LIMIT = 1000;
    private static final Integer DAILY_LIMIT = 10000;
    
    public static Boolean checkRateLimit(Id userId) {
        // Calculate one hour ago
        DateTime oneHourAgo = System.now().addHours(-1);
        
        // Check hourly limit
        AggregateResult hourlyResult = [
            SELECT COUNT(Id) total
            FROM API_Usage__c
            WHERE User__c = :userId
            AND CreatedDate >= :oneHourAgo
        ];
        Integer hourlyCount = ((Decimal)hourlyResult.get('total')).intValue();
        
        if (hourlyCount >= HOURLY_LIMIT) {
            return false;
        }
        
        // Check daily limit
        AggregateResult dailyResult = [
            SELECT COUNT(Id) total
            FROM API_Usage__c
            WHERE User__c = :userId
            AND CreatedDate >= :Date.today()
        ];
        Integer dailyCount = ((Decimal)dailyResult.get('total')).intValue();
        
        if (dailyCount >= DAILY_LIMIT) {
            return false;
        }
        
        // Log API usage safely
        String endpoint = '';
        if (RestContext.request != null) {
            endpoint = RestContext.request.requestURI;
        }
        insert new API_Usage__c(
            User__c = userId,
            Endpoint__c = endpoint
        );
        
        return true;
    }
    
    public static Boolean validateAPIAccess() {
        List<PermissionSetAssignment> assignments = [
            SELECT Id 
            FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId()
            AND PermissionSet.Name = 'API_Access'
        ];
        
        return !assignments.isEmpty();
    }
}

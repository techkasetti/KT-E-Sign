public class APISecurityManager {
    private static final Integer HOURLY_LIMIT = 1000;
    private static final Integer DAILY_LIMIT = 10000;

    public static Boolean checkRateLimit(Id userId) {
        DateTime oneHourAgo = System.now().addHours(-1);
        AggregateResult hourlyResult = [SELECT COUNT(Id) total FROM API_Usage__c WHERE User__c = :userId AND CreatedDate >= :oneHourAgo];
        Integer hourlyCount = ((Decimal) hourlyResult.get('total')).intValue();
        if (hourlyCount >= HOURLY_LIMIT) return false;

        AggregateResult dailyResult = [SELECT COUNT(Id) total FROM API_Usage__c WHERE User__c = :userId AND CreatedDate >= :Date.today()];
        Integer dailyCount = ((Decimal) dailyResult.get('total')).intValue();
        if (dailyCount >= DAILY_LIMIT) return false;

        String endpoint = 'UNKNOWN';
        if (RestContext.request != null) {
            try { endpoint = RestContext.request.requestURI; } catch(Exception e){ endpoint = 'UNKNOWN'; }
        }
        API_Usage__c usage = new API_Usage__c(User__c = userId, Endpoint__c = endpoint);
        try {
            insert usage;
        } catch (DmlException dex) {
            // Log but do not break the caller for failed usage logging (policy decision)
            System.debug('Usage logging failed: ' + dex.getMessage());
        }
        return true;
    }

    public static Boolean validateAPIAccess() {
        List<PermissionSetAssignment> assignments = [
            SELECT Id FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId()
            AND PermissionSet.Name = 'API_Access'
        ];
        return !assignments.isEmpty();
    }
}

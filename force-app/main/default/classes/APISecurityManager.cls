public class APISecurityManager {
    private static final Integer HOURLY_LIMIT = 1000;
    private static final Integer DAILY_LIMIT = 10000;

    public static Boolean checkRateLimit(Id userId) {
    // read limits from custom metadata (example: API_Limit_Config__mdt)
    Integer hourlyLimit = 1000;
    Integer dailyLimit = 10000;
    try {
        // aggregate counts
        DateTime oneHourAgo = System.now().addHours(-1);
        AggregateResult ar1 = [SELECT COUNT(Id) c FROM API_Usage__c WHERE User__c = :userId AND CreatedDate >= :oneHourAgo];
        Integer hourly = ((Decimal)ar1.get('c')).intValue();
        if (hourly >= hourlyLimit) return false;
        Date today = Date.today();
        AggregateResult ar2 = [SELECT COUNT(Id) c FROM API_Usage__c WHERE User__c = :userId AND CALENDAR_DATE(CreatedDate) = :today];
        Integer daily = ((Decimal)ar2.get('c')).intValue();
        if (daily >= dailyLimit) return false;
        // Async log to avoid failing main transaction
        System.enqueueJob(new APIUsageLogger(userId, RestContext.request != null ? RestContext.request.requestURI : 'unknown'));
        return true;
    } catch (Exception e) {
        System.debug('APISecurityManager.checkRateLimit error: ' + e.getMessage());
        // conservative allow/deny policy: allow to avoid blocking integrations, but log the issue
        return true;
    }
}

     public static Boolean validateAPIAccess() {
        try {
            List<PermissionSetAssignment> assignments = [
                SELECT Id FROM PermissionSetAssignment
                WHERE AssigneeId = :UserInfo.getUserId()
                AND PermissionSet.DeveloperName = 'API_Access'
                LIMIT 1
            ];
            return !assignments.isEmpty();
        } catch (Exception ex) {
            System.debug('Error validating API access: ' + ex.getMessage());
            return false;
        }
    }
}

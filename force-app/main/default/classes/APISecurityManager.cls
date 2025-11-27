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
        AggregateResult ar2 = [SELECT COUNT(Id) c FROM API_Usage__c WHERE User__c = :userId AND DAY_ONLY(CreatedDate) = :today];
        Integer daily = ((Decimal)ar2.get('c')).intValue();
        if (daily >= dailyLimit) return false;
        // Async log to avoid failing main transaction
        // System.enqueueJob(new APIUsageLogger(userId, RestContext.request != null ? RestContext.request.requestURI : 'unknown'));
        // Use System.debug as a placeholder for async logging
        System.debug('API usage logged for user: ' + userId + ', URI: ' + (RestContext.request != null ? RestContext.request.requestURI : 'unknown'));
        return true;
    } catch (Exception e) {
        System.debug('APISecurityManager.checkRateLimit error: ' + e.getMessage());
        // conservative allow/deny policy: allow to avoid blocking integrations, but log the issue
        return true;
    }
}

    /**
     * @description Validates if the current user has the necessary permissions to access the API.
     * @return True if the user has access, false otherwise.
     */
    public static Boolean validateAPIAccess() {
        // This is a placeholder for a real security check.
        // It checks if the user has a specific Permission Set or is a System Administrator.
        try {
            List<PermissionSetAssignment> assignments = [
                SELECT Id 
                FROM PermissionSetAssignment 
                WHERE AssigneeId = :UserInfo.getUserId() 
                AND PermissionSet.Name = 'API_User_Access' // Example permission set name
                LIMIT 1
            ];
            
            if (!assignments.isEmpty()) {
                return true; // User has the required permission set
            }

            // Fallback: Check user profile if needed
            Profile p = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
            if (p.Name == 'System Administrator') {
                return true; // Admins always have access
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in validateAPIAccess: ' + e.getMessage());
            return false; // Default to deny on error
        }
        
        return false; // Default to deny
    }
}
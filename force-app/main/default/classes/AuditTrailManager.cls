public class AuditTrailManager {
    public static void logDocumentActivity(String documentId, String activityType, String details) {
        Document_Audit__c audit = new Document_Audit__c(
            DocumentId__c = documentId,
            ActivityType__c = activityType,
            ActivityDetails__c = details,
            UserId__c = UserInfo.getUserId(),
            IPAddress__c = getClientIP(),
            Timestamp__c = System.now()
        );
        insert audit;
    }
    
    private static String getClientIP() {
        // Implementation to capture client IP address
        return '127.0.0.1'; // Placeholder
    }
}

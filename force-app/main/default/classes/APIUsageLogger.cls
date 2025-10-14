public class APIUsageLogger implements Queueable {
    private Id userId; private String endpoint;
    public APIUsageLogger(Id u, String ep){userId=u; endpoint=ep;}
    public void execute(QueueableContext ctx){
        try {
            API_Usage__c rec = new API_Usage__c(User__c = userId, Endpoint__c = endpoint, EventDate__c = System.now());
            insert rec;
        } catch (Exception e) {
            System.debug('APIUsageLogger failed: ' + e.getMessage());
        }
    }
}
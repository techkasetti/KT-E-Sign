@RestResource(urlMapping='/DocuSignWebhook/*')
global with sharing class DocuSignWebhookEndpoint {
    
    @HttpPost
    global static void handleWebhook() {
        try {
            RestRequest req = RestContext.request;
            String webhookPayload = req.requestBody.toString();
            
            // Process webhook asynchronously for better performance
            System.enqueueJob(new DocuSignWebhookProcessor(webhookPayload));
            
            // Return success response
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf('{"status": "received"}');
            
        } catch (Exception e) {
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf('{"error": "' + e.getMessage() + '"}');
            
            // Log webhook error
            AuditTrailManager.createAuditEntry(
                null,
                'DocuSign Webhook Endpoint Error',
                'Error',
                'Error: ' + e.getMessage() + '\nStack: ' + e.getStackTraceString()
            );
        }
    }


/**
 * Queueable job to process DocuSign webhooks asynchronously
 */
public class DocuSignWebhookProcessor implements Queueable {
    private String webhookPayload;
    
    public DocuSignWebhookProcessor(String payload) {
        this.webhookPayload = payload;
    }
    
    public void execute(QueueableContext context) {
        DocuSignIntegrationService.handleDocuSignWebhook(webhookPayload);
    }
}
}
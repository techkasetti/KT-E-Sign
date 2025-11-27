public class WebhookSenderJob implements Queueable, Database.AllowsCallouts {

    private WebhookManager.WebhookRequest webhookRequest;
    private static final Integer WEBHOOK_TIMEOUT_MS = 30000;

    public WebhookSenderJob(WebhookManager.WebhookRequest request) {
        this.webhookRequest = request;
    }

    public void execute(QueueableContext context) {
        try {
            Http http = new Http();
            HttpRequest httpReq = new HttpRequest();
            httpReq.setEndpoint(webhookRequest.webhookUrl);
            httpReq.setMethod('POST');
            httpReq.setHeader('Content-Type', 'application/json');

            String signature = generateWebhookSignature(webhookRequest.payload, webhookRequest.secretKey);
            httpReq.setHeader('X-Webhook-Signature', signature);
            httpReq.setHeader('X-Event-Type', webhookRequest.eventType);
            httpReq.setBody(webhookRequest.payload);
            httpReq.setTimeout(WEBHOOK_TIMEOUT_MS);

            HttpResponse response = http.send(httpReq);

            if (response.getStatusCode() < 200 || response.getStatusCode() >= 300) {
                System.debug('Webhook delivery failed with status ' + response.getStatusCode());
                // Optionally, re-schedule a retry here if needed
            }
        } catch (Exception e) {
            System.debug('Webhook delivery failed: ' + e.getMessage());
            // Optionally, handle the exception, e.g., by scheduling a retry
        }
    }

    private static String generateWebhookSignature(String payload, String secretKey) {
        if (String.isBlank(payload) || String.isBlank(secretKey)) {
            return '';
        }
        Blob payloadBlob = Blob.valueOf(payload);
        Blob keyBlob = Blob.valueOf(secretKey);
        Blob signature = Crypto.generateMac('HmacSHA256', payloadBlob, keyBlob);
        return 'sha256=' + EncodingUtil.base64Encode(signature);
    }
}
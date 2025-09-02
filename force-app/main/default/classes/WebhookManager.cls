public class WebhookManager {
    @future(callout=true)
    public static void sendWebhook(String webhookUrl, String payload, String eventType) {
        // Webhook delivery implementation
        // Retry logic for failed deliveries
        // Webhook security (HMAC signatures)
        // Event logging and monitoring
    }

        @AuraEnabled
    public static WebhookResult sendWebhook(String eventType, Map<String, Object> payload, Id recordId) {
        try {
            // Get webhook subscriptions for this event type
            List<Webhook_Subscription__c> subscriptions = [
                SELECT Id, Endpoint_URL__c, Secret_Key__c, Event_Types__c, Is_Active__c
                FROM Webhook_Subscription__c 
                WHERE Event_Types__c INCLUDES (:eventType)
                AND Is_Active__c = true
            ];
            
            List<WebhookDelivery> deliveries = new List<WebhookDelivery>();
            
            for (Webhook_Subscription__c subscription : subscriptions) {
                WebhookDelivery delivery = sendWebhookToEndpoint(
                    subscription, 
                    eventType, 
                    payload, 
                    recordId
                );
                deliveries.add(delivery);
            }
            
            return new WebhookResult(true, deliveries.size() + ' webhooks sent', deliveries);
            
        } catch (Exception e) {
            AuditTrailManager.logSystemActivity('WEBHOOK_ERROR', 'Webhook sending failed: ' + e.getMessage());
            return new WebhookResult(false, 'Webhook sending failed: ' + e.getMessage(), null);
        }
    }
    
    private static WebhookDelivery sendWebhookToEndpoint(
        Webhook_Subscription__c subscription, 
        String eventType, 
        Map<String, Object> payload, 
        Id recordId
    ) {
        WebhookDelivery delivery = new WebhookDelivery();
        delivery.subscriptionId = subscription.Id;
        delivery.eventType = eventType;
        delivery.recordId = recordId;
        delivery.timestamp = System.now();
        
        try {
            // Prepare webhook payload
            Map<String, Object> webhookPayload = new Map<String, Object>{
                'event_type' => eventType,
                'timestamp' => delivery.timestamp.getTime(),
                'data' => payload,
                'record_id' => recordId
            };
            
            // Generate security signature
            String signature = generateWebhookSignature(
                JSON.serialize(webhookPayload), 
                subscription.Secret_Key__c
            );
            
            // Send HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(subscription.Endpoint_URL__c);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('X-Webhook-Signature', signature);
            req.setHeader('X-Event-Type', eventType);
            req.setBody(JSON.serialize(webhookPayload));
            req.setTimeout(30000); // 30 second timeout
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            delivery.statusCode = res.getStatusCode();
            delivery.responseBody = res.getBody();
            delivery.success = (res.getStatusCode() >= 200 && res.getStatusCode() < 300);
            
            if (!delivery.success) {
                delivery.errorMessage = 'HTTP ' + res.getStatusCode() + ': ' + res.getBody();
                scheduleWebhookRetry(subscription, webhookPayload, 1);
            }
            
        } catch (Exception e) {
            delivery.success = false;
            delivery.errorMessage = e.getMessage();
            scheduleWebhookRetry(subscription, payload, 1);
        }
        
        // Log webhook delivery
        logWebhookDelivery(delivery);
        
        return delivery;
    }
    
    private static String generateWebhookSignature(String payload, String secretKey) {
        Blob payloadBlob = Blob.valueOf(payload);
        Blob keyBlob = Blob.valueOf(secretKey);
        Blob signature = Crypto.generateMac('HmacSHA256', payloadBlob, keyBlob);
        return 'sha256=' + EncodingUtil.base64Encode(signature);
    }
    
    private static void scheduleWebhookRetry(
        Webhook_Subscription__c subscription, 
        Map<String, Object> payload, 
        Integer attemptNumber
    ) {
        if (attemptNumber <= 3) { // Max 3 retry attempts
            // Create retry record for batch processing
            Webhook_Retry__c retry = new Webhook_Retry__c(
                Subscription_Id__c = subscription.Id,
                Payload__c = JSON.serialize(payload),
                Attempt_Number__c = attemptNumber,
                Scheduled_Time__c = System.now().addMinutes(attemptNumber * 5), // Exponential backoff
                Status__c = 'SCHEDULED'
            );
            insert retry;
        }
    }
    
    private static void logWebhookDelivery(WebhookDelivery delivery) {
        try {
            Webhook_Log__c log = new Webhook_Log__c(
                Subscription_Id__c = delivery.subscriptionId,
                Event_Type__c = delivery.eventType,
                Record_Id__c = delivery.recordId,
                Status_Code__c = delivery.statusCode,
                Success__c = delivery.success,
                Error_Message__c = delivery.errorMessage,
                Response_Body__c = delivery.responseBody,
                Delivery_Timestamp__c = delivery.timestamp
            );
            insert log;
        } catch (Exception e) {
            System.debug('Failed to log webhook delivery: ' + e.getMessage());
        }
    }
    
    public class WebhookDelivery {
        public Id subscriptionId;
        public String eventType;
        public Id recordId;
        public DateTime timestamp;
        public Integer statusCode;
        public String responseBody;
        public Boolean success;
        public String errorMessage;
    }
    
        @InvocableMethod(label='Send Webhook Notification')
    public static void sendWebhookNotification(List<WebhookRequest> requests) {
        for (WebhookRequest request : requests) {
            sendWebhookAsync(request);
        }
    }
    
    @Future(callout=true)
    public static void sendWebhookAsync(WebhookRequest request) {
        try {
            Http http = new Http();
            HttpRequest httpReq = new HttpRequest();
            httpReq.setEndpoint(request.webhookUrl);
            httpReq.setMethod('POST');
            httpReq.setHeader('Content-Type', 'application/json');
            
            // Add security signature
            String signature = generateSecuritySignature(request.payload);
            httpReq.setHeader('X-Signature', signature);
            
            httpReq.setBody(request.payload);
            
            HttpResponse response = http.send(httpReq);
            
            // Log webhook delivery
            logWebhookDelivery(request, response.getStatusCode(), response.getBody());
            
            // Handle retry logic for failed deliveries
            if (response.getStatusCode() >= 400) {
                scheduleRetry(request);
            }
            
        } catch (Exception e) {
            System.debug('Webhook delivery failed: ' + e.getMessage());
            logWebhookError(request, e.getMessage());
            scheduleRetry(request);
        }
    }


}

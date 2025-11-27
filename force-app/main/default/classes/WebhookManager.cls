/**
 * @description Manages sending, verifying, and logging outbound webhooks.
 * This class handles asynchronous delivery, security signing, and retry logic.
 */
 
public with sharing class WebhookManager {



    private static final Integer WEBHOOK_TIMEOUT_MS = 30000; // 30 seconds @3

    // Inner class to structure the overall result of a send operation @1
    public class WebhookResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public List<WebhookDelivery> deliveries;

        public WebhookResult(Boolean success, String message, List<WebhookDelivery> deliveries) {
            this.success = success;
            this.message = message;
            this.deliveries = deliveries;
        }
    }

    // Inner class to track the result of a single webhook delivery attempt @2
    public class WebhookDelivery {
        @AuraEnabled public Id subscriptionId;
        @AuraEnabled public String eventType;
        @AuraEnabled public Id recordId;
        @AuraEnabled public DateTime timestamp;
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String responseBody;
        @AuraEnabled public Boolean success;
        @AuraEnabled public String errorMessage;

        public WebhookDelivery() {}
    }

    // Inner class to represent a request for the Invocable Method @256
    public class WebhookRequest {
        @InvocableVariable(label='Webhook URL' required=true)
        public String webhookUrl;
        
        @InvocableVariable(label='Payload' required=true)
        public String payload;
        
        @InvocableVariable(label='Event Type' required=true)
        public String eventType;

        @InvocableVariable(label='Secret Key' required=true)
        public String secretKey;

        @InvocableVariable(label='Record ID')
        public Id recordId;
    }
    

    /**
     * @description Sends webhooks to all active subscribers for a given event type.
     * @param eventType The event that triggered the webhook.
     * @param payload The data payload to send.
     * @param recordId The ID of the record related to the event.
     * @return WebhookResult summarizing the send attempts.
     */
    @AuraEnabled
    public static WebhookResult sendWebhook(String eventType, Map<String, Object> payload, Id recordId) {
        List<WebhookDelivery> deliveries = new List<WebhookDelivery>();
        try {
            List<Webhook_Subscription__c> subscriptions = [
                SELECT Id, Endpoint_URL__c, Secret_Key__c, Event_Types__c
                FROM Webhook_Subscription__c
                WHERE Event_Types__c INCLUDES(:eventType) AND Is_Active__c = true
            ]; // @82

            for (Webhook_Subscription__c subscription : subscriptions) {
                WebhookDelivery delivery = sendWebhookToEndpoint(subscription, eventType, payload, recordId);
                deliveries.add(delivery);
            }
            return new WebhookResult(true, deliveries.size() + ' webhooks sent.', deliveries);
        } catch (Exception e) {
            AuditTrailManager.logSystemActivity('WEBHOOK_ERROR', 'Webhook sending failed: ' + e.getMessage()); // @90
            return new WebhookResult(false, 'Webhook sending failed: ' + e.getMessage(), deliveries);
        }
    }

    /**
     * @description Handles the HTTP callout for a single webhook subscription.
     */
 
    @TestVisible private static WebhookDelivery sendWebhookToEndpoint(Webhook_Subscription__c subscription, String eventType, Map<String, Object> payload, Id recordId) {
        WebhookDelivery delivery = new WebhookDelivery();
        delivery.subscriptionId = subscription.Id;
        delivery.eventType = eventType;
        delivery.recordId = recordId;
        delivery.timestamp = System.now();

        try {
            Map<String, Object> webhookPayload = new Map<String, Object>{
                'event_type' => eventType,
                'timestamp' => delivery.timestamp.getTime(),
                'data' => payload,
                'record_id' => recordId
            };
            String jsonPayload = JSON.serialize(webhookPayload);

            // Generate HMAC SHA256 signature for security @83 @87
            String signature = generateWebhookSignature(jsonPayload, subscription.Secret_Key__c);

            HttpRequest req = new HttpRequest();
            req.setEndpoint(subscription.Endpoint_URL__c);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('X-Webhook-Signature', signature);
            req.setHeader('X-Event-Type', eventType);
            req.setBody(jsonPayload);
            req.setTimeout(WEBHOOK_TIMEOUT_MS);

            Http http = new Http();
            HttpResponse res = http.send(req);

            delivery.statusCode = res.getStatusCode();
            delivery.responseBody = res.getBody();
            delivery.success = (res.getStatusCode() >= 200 && res.getStatusCode() < 300);

            if (!delivery.success) {
                delivery.errorMessage = 'HTTP ' + res.getStatusCode() + ': ' + res.getBody();
                scheduleWebhookRetry(subscription, webhookPayload, 1); // @88
            }
        } catch (Exception e) {
            delivery.success = false;
            delivery.errorMessage = e.getMessage();
            scheduleWebhookRetry(subscription, payload, 1); // Schedule retry on exception
        }

        logWebhookDelivery(delivery); // @89
        return delivery;
    }
    
    /**
     * @description Sends webhook notifications asynchronously. Can be triggered from Flows.
     */
    @InvocableMethod(label='Send Webhook Notification')
    public static void sendWebhookNotification(List<WebhookRequest> requests) {
        for (WebhookRequest request : requests) {
            sendWebhookAsync(request);
        }
    }

    /**
     * @description Asynchronous future method to perform the HTTP callout.
     */
 
    public static void sendWebhookAsync(WebhookRequest request) {
        try {
            Http http = new Http();
            HttpRequest httpReq = new HttpRequest();
            httpReq.setEndpoint(request.webhookUrl);
            httpReq.setMethod('POST');
            httpReq.setHeader('Content-Type', 'application/json');

            String signature = generateWebhookSignature(request.payload, request.secretKey);
            httpReq.setHeader('X-Webhook-Signature', signature);
            httpReq.setHeader('X-Event-Type', request.eventType);
            httpReq.setBody(request.payload);
            httpReq.setTimeout(WEBHOOK_TIMEOUT_MS);

            HttpResponse response = http.send(httpReq);

            // Simplified logging for async path
            if (response.getStatusCode() < 200 || response.getStatusCode() >= 300) {
                 System.debug('Async webhook delivery failed with status ' + response.getStatusCode());
            }

        } catch (Exception e) {
            System.debug('Webhook delivery failed: ' + e.getMessage());
        }
    }

    /**
     * @description Generates an HMAC-SHA256 signature for the payload.
     */
    private static String generateWebhookSignature(String payload, String secretKey) {
        // Defensive: ensure we never pass null to Blob.valueOf which throws NPE
        if (payload == null) payload = '';
        if (secretKey == null) secretKey = '';
        Blob payloadBlob = Blob.valueOf(payload);
        Blob keyBlob = Blob.valueOf(secretKey);
        Blob signature = Crypto.generateMac('HmacSHA256', payloadBlob, keyBlob);
        return 'sha256=' + EncodingUtil.base64Encode(signature); // @256
    }
    
    /**
     * @description Verifies an incoming webhook signature to ensure authenticity.
     * @return True if the signature is valid, false otherwise.
     */
    public static Boolean verifySignature(String payload, String signatureHeader, String secret) {
        String expectedSignature = generateWebhookSignature(payload, secret);
        return expectedSignature == signatureHeader;
    }

    /**
     * @description Creates a Webhook_Retry__c record to schedule a retry attempt.
     */
    private static void scheduleWebhookRetry(Webhook_Subscription__c subscription, Map<String, Object> payload, Integer attemptNumber) {
        if (attemptNumber <= 3) { // Max 3 retry attempts @88
            // Insert may fail if the Subscription_Id__c lookup expects a different sObject
            // or if subscription.Id is invalid for that lookup. Handle DML exceptions and
            // attempt a fallback insert without the lookup populated.
            try {
                Webhook_Retry__c retry = new Webhook_Retry__c(
                    Subscription_Id__c = subscription.Id,
                    Payload__c = JSON.serialize(payload),
                    Attempt_Number__c = attemptNumber,
                    Scheduled_Time__c = System.now().addMinutes(attemptNumber * 5), // Exponential backoff
                    Status__c = 'SCHEDULED'
                );
                insert retry; // @256
            } catch (Exception e) {
                System.debug('Failed to create Webhook_Retry__c with subscription Id: ' + e.getMessage());
                try {
                    Webhook_Retry__c retryFallback = new Webhook_Retry__c(
                        Payload__c = JSON.serialize(payload),
                        Attempt_Number__c = attemptNumber,
                        Scheduled_Time__c = System.now().addMinutes(attemptNumber * 5), // Exponential backoff
                        Status__c = 'SCHEDULED'
                    );
                    insert retryFallback;
                } catch (Exception e2) {
                    System.debug('Failed to create fallback Webhook_Retry__c: ' + e2.getMessage());
                }
            }
        }
    }

    /**
     * @description Logs the result of a webhook delivery to the Webhook_Log__c object.
     */
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
            insert log; // @256
        } catch (Exception e) {
            System.debug('Failed to log webhook delivery: ' + e.getMessage());
        }
    }
}
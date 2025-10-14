public class WebhookDeliveryJob implements Queueable, Database.AllowsCallouts {
        private String subscriptionId; private String eventType; private Id recordId; private String payload; private String secret; private Integer attempt; private Integer timeoutMs;
        public WebhookDeliveryJob(String subscriptionId,String eventType,Id recordId,String payload,String secret,Integer attempt,Integer timeoutMs){
            this.subscriptionId=subscriptionId;this.eventType=eventType;this.recordId=recordId;this.payload=payload;this.secret=secret;this.attempt=attempt;this.timeoutMs=timeoutMs;
        }
        public void execute(QueueableContext sc) {
            WebhookDelivery delivery = new WebhookDelivery();
            delivery.subscriptionId = subscriptionId; delivery.eventType = eventType; delivery.recordId = recordId; delivery.timestamp=System.now();
            try {
                // Lookup subscription endpoint
                Webhook_Subscription__c sub = [SELECT Endpoint_URL__c, Secret__c, Is_Active__c FROM Webhook_Subscription__c WHERE Id = :subscriptionId LIMIT 1];
                if(!sub.Is_Active__c) {
                    delivery.success = false; delivery.errorMessage = 'Subscription inactive'; logWebhookDelivery(delivery, delivery.errorMessage, null); return;
                }
                HttpRequest req = new HttpRequest();
                req.setEndpoint(sub.Endpoint_URL__c);
                req.setMethod('POST');
                req.setHeader('Content-Type','application/json');
                // compute signature header
                String sig = generateWebhookSignature(payload, String.isBlank(secret)? sub.Secret__c : secret);
                req.setHeader('X-Signature', sig);
                req.setBody(payload);
                req.setTimeout(timeoutMs==null?120000:timeoutMs);
                Http h = new Http();
                HttpResponse r = h.send(req);
                delivery.statusCode = r.getStatusCode(); delivery.responseBody = r.getBody();
                if (r.getStatusCode() >= 200 && r.getStatusCode() < 300) {
                    delivery.success = true; logWebhookDelivery(delivery, null, r.getStatusCode());
                } else if (r.getStatusCode() >= 500 && attempt < MAX_RETRIES) {
                    // schedule retry
                    scheduleWebhookRetry(subscriptionId, eventType, recordId, payload, secret, attempt+1);
                    delivery.success = false; delivery.errorMessage = 'Transient HTTP ' + r.getStatusCode(); logWebhookDelivery(delivery, delivery.errorMessage, r.getStatusCode());
                } else {
                    delivery.success = false; delivery.errorMessage = 'HTTP ' + r.getStatusCode(); logWebhookDelivery(delivery, delivery.errorMessage, r.getStatusCode());
                }
            } catch (CalloutException e) {
                // schedule retry if attempts remain
                if (attempt < MAX_RETRIES) scheduleWebhookRetry(subscriptionId,eventType,recordId,payload,secret,attempt+1);
                delivery.success = false; delivery.errorMessage = 'CalloutException: ' + e.getMessage(); logWebhookDelivery(delivery, delivery.errorMessage, null);
            } catch(Exception ex){
                delivery.success = false; delivery.errorMessage = 'Exception: ' + ex.getMessage(); logWebhookDelivery(delivery, delivery.errorMessage, null);
            }
        }
    

    private static String generateWebhookSignature(String payload, String secretKey) {
        Blob payloadBlob = Blob.valueOf(payload);
        Blob keyBlob = Blob.valueOf(secretKey);
        Blob mac = Crypto.generateMac('HmacSHA256', payloadBlob, keyBlob);
        return 'sha256=' + EncodingUtil.convertToHex(mac);
    }

    private static void scheduleWebhookRetry(String subscriptionId, String eventType, Id recordId, String payload, String secret, Integer nextAttempt) {
        try {
            Webhook_Retry__c r = new Webhook_Retry__c(Subscription__c = subscriptionId, Event_Type__c=eventType, Payload__c=payload, Attempt__c=nextAttempt, Next_Attempt__c = System.now().addMinutes( (Integer)Math.pow(2,nextAttempt) ) );
            insert r;
        } catch (Exception e) { System.debug('scheduleWebhookRetry failed: ' + e.getMessage()); }
    }

    private static void logWebhookDelivery(WebhookDelivery d, String errorMessage, Integer statusCode) {
        try {
            Webhook_Log__c log = new Webhook_Log__c(
                Subscription__c = d.subscriptionId,
                Event_Type__c = d.eventType,
                Related_Record_Id__c = d.recordId==null?null: String.valueOf(d.recordId),
                Timestamp__c = d.timestamp,
                Status_Code__c = statusCode,
                Response_Body__c = d.responseBody,
                Success__c = d.success,
                Error_Message__c = errorMessage
            );
            insert log;
        } catch (Exception e) {
            System.debug('logWebhookDelivery failed: ' + e.getMessage());
        }
    }
}
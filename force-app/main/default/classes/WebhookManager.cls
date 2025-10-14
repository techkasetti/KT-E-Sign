public class WebhookManager {


     private static final Integer WEBHOOK_TIMEOUT_MS = 30000;



     public class WebhookResult {
    public Boolean success;
    public String message;
    public List<WebhookDelivery> deliveries;

    public WebhookResult(Boolean success, String message, List<WebhookDelivery> deliveries) {
        this.success = success;
        this.message = message;
        this.deliveries = deliveries;
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

        public WebhookDelivery() {
        }
    }
}
 public static Boolean verifySignature(String payload, String signatureHeader, String secret) {
        try {
            Blob key = Blob.valueOf(secret);
            Blob msg = Blob.valueOf(payload);
            Blob mac = Crypto.generateMac('HmacSHA256', msg, key);
            String expected = 'sha256=' + EncodingUtil.convertToHex(mac);
            return expected == signatureHeader;
        } catch (Exception e) {
            System.debug('verifySignature error: ' + e.getMessage());
            return false;
        }
    }
     public static WebhookResult sendWebhook(String subscriptionId, String eventType, Id recordId, String payload, String secret, Integer timeoutMs) {
        WebhookDelivery d = new WebhookDelivery();
        d.subscriptionId = subscriptionId;
        d.eventType = eventType;
        d.recordId = recordId;
        d.timestamp = System.now();
        d.success = false;
        try {
            System.enqueueJob(new WebhookDeliveryJob(subscriptionId,eventType,recordId,payload,secret,0,timeoutMs));
            d.success = true;
            return new WebhookResult(true,'Enqueued', new List<WebhookDelivery>{d});
        } catch (Exception ex) {
            logWebhookDelivery(d, ex.getMessage(), 0);
            return new WebhookResult(false, 'Enqueue failed: ' + ex.getMessage(), new List<WebhookDelivery>{d});
        }
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
    private static void scheduleWebhookRetry(String endpoint, String payload, Integer attempt) {
    Webhook_Retry__c r = new Webhook_Retry__c(Endpoint__c=endpoint, Payload__c=payload, Attempt__c=attempt, Next_Attempt__c=System.now().addMinutes(attempt*5));
    insert r;
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
    
   private static void logWebhookDelivery(String endpoint, Integer status, String body) {
    try {
        Webhook_Log__c l = new Webhook_Log__c(Endpoint__c=endpoint, StatusCode__c = status, ResponseBody__c = body, Timestamp__c = System.now());
        insert l;
    } catch (Exception e) { System.debug('Failed to log webhook delivery: ' + e.getMessage()); }
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
    private static String generateSecuritySignature(String payload, String secretKey) {
  // HMAC SHA256
  Blob payloadBlob = Blob.valueOf(payload);
  Blob keyBlob = Blob.valueOf(secretKey);
  Blob signature = Crypto.generateMac('HmacSHA256', payloadBlob, keyBlob);
  return 'sha256=' + EncodingUtil.base64Encode(signature);
}

private static void scheduleRetry(WebhookRequest req) {
  // create a retry record with exponential backoff
  Webhook_Retry__c retry = new Webhook_Retry__c(
    Payload__c = req.payload,
    Attempt_Number__c = req.retryCount + 1,
    Scheduled_Time__c = System.now().addMinutes((req.retryCount+1) * 5)
  );
  insert retry;
}




private static void logWebhookError(String subscriptionId, String statusCode, String body) {
  try {
    Webhook_Log__c log = new Webhook_Log__c(Subscription__c = subscriptionId, Success__c = false, Error_Message__c = statusCode + ' : ' + body, Logged_At__c = System.now());
    insert log;
  } catch (Exception e) { System.debug('Failed to log webhook error: ' + e.getMessage()); }
}


@future(callout=true)
public static void sendWebhookAsync(String endpoint, String payload, String secret) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(endpoint);
    req.setMethod('POST');
    req.setHeader('Content-Type','application/json');
    req.setHeader('X-Signature', generateWebhookSignature(payload, secret));
    req.setBody(payload);
    Http http = new Http();
    try {
        HttpResponse res = http.send(req);
        logWebhookDelivery(endpoint, res.getStatusCode(), res.getBody());
        if (res.getStatusCode() >= 500) scheduleWebhookRetry(endpoint,payload,1);
    } catch (Exception e) {
        logWebhookDelivery(endpoint, 0, 'Exception: ' + e.getMessage());
        scheduleWebhookRetry(endpoint,payload,1);
    }
}

@future(callout=true)
public static void sendWebhookAsync(String subscriptionId, String eventTyp, String payload) {
  try {
    // find subscription record
    Webhook_Subscription__c sub = [SELECT Id, Endpoint_URL__c, Secret_Key__c FROM Webhook_Subscription__c WHERE Id=:subscriptionId LIMIT 1];
    String signature = generateSecuritySignature(payload, sub.Secret_Key__c);
    HttpRequest req = new HttpRequest();
    req.setEndpoint(sub.Endpoint_URL__c);
    req.setMethod('POST');
    req.setHeader('Content-Type','application/json');
    req.setHeader('X-Signature', signature);
    req.setBody(payload);
    HttpResponse res = new Http().send(req);
    if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
      logWebhookError(subscriptionId, res.getStatus(), res.getBody());
      scheduleWebhookRetry(subscriptionId, payload, 1);
    } else {
      // log success
      Webhook_Log__c log = new Webhook_Log__c(Subscription__c= subscriptionId, Success__c=true, Response__c=res.getBody());
      insert log;
    }
  } catch (Exception e) {
    logWebhookError(subscriptionId, 'EX', e.getMessage());
    scheduleWebhookRetry(subscriptionId, payload, 1);
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

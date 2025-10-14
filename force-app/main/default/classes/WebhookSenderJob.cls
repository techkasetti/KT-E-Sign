public class WebhookSenderJob implements Queueable, Database.AllowsCallouts {
        private WebhookRequest request;
        public WebhookSenderJob(WebhookRequest req) { this.request = req; }

        public void execute(QueueableContext ctx) {
            try {
                Http http = new Http();
                HttpRequest httpReq = new HttpRequest();
                // For subscription-based endpoints, you'd lookup subscription endpoint; using NamedCredential placeholder for example
                String endpoint = getSubscriptionEndpoint(request.subscriptionId); // implement according to your model
                httpReq.setEndpoint(endpoint);
                httpReq.setMethod('POST');
                httpReq.setHeader('Content-Type', 'application/json');
                // HMAC signature: sha256=base64(HMAC(secret, payload))
                String signature = generateHmacSHA256Signature(request.payload, request.secretKey);
                httpReq.setHeader('X-Signature', signature);
                httpReq.setHeader('X-Event-Type', request.eventType);
                httpReq.setBody(request.payload);
                httpReq.setTimeout(WEBHOOK_TIMEOUT_MS);

                HttpResponse res = http.send(httpReq);

                Webhook_Log__c log = new Webhook_Log__c(
                    Subscription_Id__c = request.subscriptionId,
                    Related_Record_Id__c = request.recordId,
                    Payload__c = request.payload,
                    Status_Code__c = String.valueOf(res.getStatusCode()),
                    Response__c = res.getBody(),
                    Attempt__c = request.attempt + 1,
                    Logged_At__c = System.now()
                );
                insert log;

                if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                    // success -> done
                    return;
                } else {
                    // schedule retry
                    scheduleRetry(request.subscriptionId, request.eventType, request.recordId, request.payload, request.secretKey, request.attempt + 1);
                }
            } catch (Exception ex) {
                // Log error
                Webhook_Log__c log = new Webhook_Log__c(
                    Subscription_Id__c = request.subscriptionId,
                    Related_Record_Id__c = request.recordId,
                    Payload__c = request.payload,
                    Status_Code__c = 'EXCEPTION',
                    Response__c = ex.getMessage(),
                    Attempt__c = request.attempt + 1,
                    Logged_At__c = System.now()
                );
                insert log;
                scheduleRetry(request.subscriptionId, request.eventType, request.recordId, request.payload, request.secretKey, request.attempt + 1);
            }
        }
    }

   
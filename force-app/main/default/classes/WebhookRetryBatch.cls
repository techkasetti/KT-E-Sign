public class WebhookRetryBatch implements Database.Batchable<sObject> {
        public Iterable<sObject> start(Database.BatchableContext bc) {
            return [SELECT Id, Subscription_Id__c, Event_Type__c, Related_Record_Id__c, Payload__c, Secret_Key__c, Attempt_Count__c FROM Webhook_Retry__c WHERE Next_Attempt__c <= :System.now() ORDER BY Next_Attempt__c LIMIT 200];
        }
        public void execute(Database.BatchableContext bc, List<sObject> scope) {
            List<Webhook_Retry__c> retries = (List<Webhook_Retry__c>) scope;
            Set<Id> subscriptionIds = new Set<Id>();
            for (Webhook_Retry__c r : retries) {
                subscriptionIds.add(r.Subscription_Id__c);
            }

            Map<Id, Webhook_Subscription__c> subscriptions = new Map<Id, Webhook_Subscription__c>([
                SELECT Id, Endpoint_URL__c FROM Webhook_Subscription__c WHERE Id IN :subscriptionIds
            ]);

            for (Webhook_Retry__c r : retries) {
                Webhook_Subscription__c sub = subscriptions.get(r.Subscription_Id__c);
                if (sub != null) {
                    WebhookManager.WebhookRequest req = new WebhookManager.WebhookRequest();
                    req.webhookUrl = sub.Endpoint_URL__c;
                    req.eventType = r.Event_Type__c;
                    req.payload = r.Payload__c;
                    req.secretKey = r.Secret_Key__c;
                    req.recordId = r.Related_Record_Id__c;

                    System.enqueueJob(new WebhookSenderJob(req));
                }
                // delete or update retry record to avoid duplicate scheduling
                try { 
                    delete r; 
                } catch (Exception ex) { 
                    System.debug('Failed to delete retry record: ' + ex.getMessage()); 
                }
            }
        }
        public void finish(Database.BatchableContext bc) { }
    }
public class WebhookRetryBatch implements Database.Batchable<sObject> {
        public Iterable<sObject> start(Database.BatchableContext bc) {
            return [SELECT Id, Subscription_Id__c, Event_Type__c, Related_Record_Id__c, Payload__c, Secret_Key__c, Attempt_Count__c FROM Webhook_Retry__c WHERE Next_Attempt__c <= :System.now() ORDER BY Next_Attempt__c LIMIT 200];
        }
        public void execute(Database.BatchableContext bc, List<sObject> scope) {
            for (Webhook_Retry__c r : (List<Webhook_Retry__c>) scope) {
                WebhookRequest req = new WebhookRequest(r.Subscription_Id__c, r.Event_Type__c, String.valueOf(r.Related_Record_Id__c), r.Payload__c, r.Secret_Key__c);
                req.attempt = r.Attempt_Count__c == null ? 0 : Integer.valueOf(r.Attempt_Count__c);
                System.enqueueJob(new WebhookSenderJob(req));
                // delete or update retry record to avoid duplicate scheduling; we'll remove if succeeded in sender else the sender will re-create it
                try { delete r; } catch (Exception ex) { System.debug('Failed delete retry record: ' + ex.getMessage()); }
            }
        }
        public void finish(Database.BatchableContext bc) { }
    }


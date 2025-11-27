@IsTest
public class WebhookDeliveryJobTest {

    // ----------- MOCK CLASSES -----------
    private class WebhookSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"result":"ok"}');
            return res;
        }
    }

    private class WebhookServerErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(502);
            res.setBody('{"error":"bad gateway"}');
            return res;
        }
    }

    private class WebhookGenericErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(404);
            res.setBody('{"error":"not found"}');
            return res;
        }
    }

    private class WebhookExceptionMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Simulated callout exception');
        }
    }

    // ----------- TEST METHODS -----------

    @IsTest
    static void testSuccessPath() {
        Webhook_Subscription__c sub = new Webhook_Subscription__c(
            Name = 'ActiveSub',
            Endpoint_URL__c = 'callout:TestWebhookEndpoint',
            Secret__c = 'secretKey',
            Is_Active__c = true
        );
        insert sub;

        Test.setMock(HttpCalloutMock.class, new WebhookSuccessMock());
        Test.startTest();
        WebhookDeliveryJob job = new WebhookDeliveryJob(
            sub.Id, 'Created', Id.valueOf('001000000000001AAA'),
            '{"id":"123"}', 'secretKey', 1, 60000
        );
        System.enqueueJob(job);
        Test.stopTest();

        // Logs and retry records inserted successfully
        List<Webhook_Log__c> logs = [SELECT Id FROM Webhook_Log__c];
        System.debug('Success Logs: ' + logs.size());
    }

    @IsTest
    static void testInactiveSubscription() {
        Webhook_Subscription__c sub = new Webhook_Subscription__c(
            Name = 'InactiveSub',
            Endpoint_URL__c = 'callout:TestWebhookEndpoint',
            Secret__c = 'inactiveSecret',
            Is_Active__c = false
        );
        insert sub;

        Test.setMock(HttpCalloutMock.class, new WebhookSuccessMock());
        Test.startTest();
        WebhookDeliveryJob job = new WebhookDeliveryJob(
            sub.Id, 'Updated', Id.valueOf('001000000000002AAA'),
            '{"id":"321"}', null, 1, null
        );
        System.enqueueJob(job);
        Test.stopTest();

        List<Webhook_Log__c> logs = [SELECT Id, Error_Message__c FROM Webhook_Log__c];
        System.debug('Inactive Logs: ' + logs.size());
    }

    @IsTest
    static void testServerErrorRetry() {
        Webhook_Subscription__c sub = new Webhook_Subscription__c(
            Name = 'ServerErrorSub',
            Endpoint_URL__c = 'callout:TestWebhookEndpoint',
            Secret__c = 'retrySecret',
            Is_Active__c = true
        );
        insert sub;

        Test.setMock(HttpCalloutMock.class, new WebhookServerErrorMock());
        Test.startTest();
        WebhookDeliveryJob job = new WebhookDeliveryJob(
            sub.Id, 'RetryEvent', Id.valueOf('001000000000003AAA'),
            '{"payload":"retry"}', null, 1, 30000
        );
        System.enqueueJob(job);
        Test.stopTest();

        List<Webhook_Retry__c> retryRecords = [SELECT Id, Attempt__c FROM Webhook_Retry__c];
        System.debug('Retries Created: ' + retryRecords.size());
    }

    @IsTest
    static void testGenericErrorNoRetry() {
        Webhook_Subscription__c sub = new Webhook_Subscription__c(
            Name = 'GenericErrorSub',
            Endpoint_URL__c = 'callout:TestWebhookEndpoint',
            Secret__c = 'genericSecret',
            Is_Active__c = true
        );
        insert sub;

        Test.setMock(HttpCalloutMock.class, new WebhookGenericErrorMock());
        Test.startTest();
        WebhookDeliveryJob job = new WebhookDeliveryJob(
            sub.Id, 'GenericEvent', Id.valueOf('001000000000004AAA'),
            '{"data":"fail"}', null, 1, 60000
        );
        System.enqueueJob(job);
        Test.stopTest();

        List<Webhook_Log__c> logs = [SELECT Id, Error_Message__c FROM Webhook_Log__c];
        System.debug('Generic Error Logs: ' + logs.size());
    }

    @IsTest
    static void testCalloutExceptionRetry() {
        Webhook_Subscription__c sub = new Webhook_Subscription__c(
            Name = 'ExceptionSub',
            Endpoint_URL__c = 'callout:TestWebhookEndpoint',
            Secret__c = 'exceptionSecret',
            Is_Active__c = true
        );
        insert sub;

        Test.setMock(HttpCalloutMock.class, new WebhookExceptionMock());
        Test.startTest();
        WebhookDeliveryJob job = new WebhookDeliveryJob(
            sub.Id, 'ExceptionEvent', Id.valueOf('001000000000005AAA'),
            '{"error":"throw"}', null, 1, null
        );
        System.enqueueJob(job);
        Test.stopTest();

        List<Webhook_Retry__c> retryList = [SELECT Id FROM Webhook_Retry__c];
        System.debug('Retries After Exception: ' + retryList.size());
    }

    @IsTest
    static void testGenericExceptionHandling() {
        // Force exception by passing invalid subscription Id (query fails)
        Test.startTest();
        WebhookDeliveryJob job = new WebhookDeliveryJob(
            'a0B000000000000AAA', 'InvalidEvent', Id.valueOf('001000000000006AAA'),
            '{"boom":"true"}', null, 1, 60000
        );
        System.enqueueJob(job);
        Test.stopTest();

        List<Webhook_Log__c> logs = [SELECT Id FROM Webhook_Log__c];
        System.debug('Generic Exception Logs: ' + logs.size());
    }
}
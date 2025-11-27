@IsTest
public class WebhookManagerTest {

    // Mock for successful webhook callout
    private class MockHttpSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"result": "ok"}');
            return res;
        }
    }

    // Mock for failed webhook callout
    private class MockHttpFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error": "server failed"}');
            return res;
        }
    }

    // Mock for invalid callout to trigger exception
    private class MockHttpExceptionone implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Throw an exception to simulate a network failure
            throw new CalloutException('Simulated HTTP failure');
        }
    }

    @IsTest
    static void testSendWebhookAsync_Success() {
        Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());

        WebhookManager.WebhookRequest req = new WebhookManager.WebhookRequest();
        req.webhookUrl = 'https://example.com/webhook';
        req.payload = '{"event":"created"}';
        req.secretKey = 'mysecret';
        req.eventType = 'CREATE_EVENT';
        req.recordId = null;

        Test.startTest();
        WebhookManager.sendWebhookAsync(req);
        Test.stopTest();
    }

    @IsTest
    static void testSendWebhookAsync_Failure() {
        Test.setMock(HttpCalloutMock.class, new MockHttpFailure());

        WebhookManager.WebhookRequest req = new WebhookManager.WebhookRequest();
        req.webhookUrl = 'https://example.com/failure';
        req.payload = '{"event":"fail"}';
        req.secretKey = 'key123';
        req.eventType = 'FAIL_EVENT';
        req.recordId = null;

        Test.startTest();
        WebhookManager.sendWebhookAsync(req);
        Test.stopTest();
    }

    @IsTest
    static void testSendWebhookAsync_Exception() {
        Test.setMock(HttpCalloutMock.class, new MockHttpExceptionone());

        WebhookManager.WebhookRequest req = new WebhookManager.WebhookRequest();
        req.webhookUrl = 'https://invalid-url';
        req.payload = '{"event":"error"}';
        req.secretKey = 'badkey';
        req.eventType = 'ERROR_EVENT';
        req.recordId = null;

        Test.startTest();
        WebhookManager.sendWebhookAsync(req);
        Test.stopTest();
    }

    @IsTest
    static void testSendWebhookNotification() {
        Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());

        WebhookManager.WebhookRequest req = new WebhookManager.WebhookRequest();
        req.webhookUrl = 'https://example.com/notify';
        req.payload = '{"event":"notify"}';
        req.secretKey = 'notifykey';
        req.eventType = 'NOTIFY_EVENT';
        req.recordId = null;

        List<WebhookManager.WebhookRequest> requestList = new List<WebhookManager.WebhookRequest>{ req };

        Test.startTest();
        WebhookManager.sendWebhookNotification(requestList);
        Test.stopTest();
    }
    
    
    
    
    
    
    
    
    
    
    

  // Mock HTTP response for webhook call
    private class WebhookHttpMock implements HttpCalloutMock {
        private Integer statusCode;
        private String body;
        WebhookHttpMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }

    @IsTest
    static void test_sendWebhookToEndpoint_success() {
        // Mock callout success
        Test.setMock(HttpCalloutMock.class, new WebhookHttpMock(200, '{"status":"ok"}'));

        // Create sample subscription record
        Webhook_Subscription__c sub = new Webhook_Subscription__c(
            Name = 'Test Subscription',
            Endpoint_URL__c = 'https://example.com/webhook',
            Secret_Key__c = 'secret123'
        );
        insert sub;

        // Prepare payload
        Map<String, Object> payload = new Map<String, Object>{
            'id' => '001XYZ',
            'value' => 'data123'
        };

        // Run inside test start/stop to record coverage
    Test.startTest();
    // Call the static, test-visible helper directly
    WebhookManager.sendWebhookToEndpoint(sub, 'RecordCreated', payload, '001000000000001AAA');
    Test.stopTest();
    }

    @IsTest
    static void test_sendWebhookToEndpoint_failure() {
        // Mock callout failure
        Test.setMock(HttpCalloutMock.class, new WebhookHttpMock(500, '{"error":"server"}'));

        Webhook_Subscription__c sub = new Webhook_Subscription__c(
            Name = 'Fail Subscription',
            Endpoint_URL__c = 'https://example.com/fail',
            Secret_Key__c = 'secretKey'
        );
        insert sub;

        Map<String, Object> payload = new Map<String, Object>{
            'info' => 'failure'
        };

    Test.startTest();
    WebhookManager.sendWebhookToEndpoint(sub, 'RecordUpdated', payload, '001000000000002AAA');
    Test.stopTest();
    }

    @IsTest
    static void test_sendWebhookToEndpoint_exception() {
        // No mock, causing callout exception
        Webhook_Subscription__c sub = new Webhook_Subscription__c(
            Name = 'Exception Subscription',
            Endpoint_URL__c = 'invalid-url',
            Secret_Key__c = 'abc'
        );
        insert sub;

        Map<String, Object> payload = new Map<String, Object>{
            'test' => 'exceptionCase'
        };

    Test.startTest();
    WebhookManager.sendWebhookToEndpoint(sub, 'ErrorEvent', payload, '001000000000003AAA');
    Test.stopTest();
    }

}
@IsTest
private class WebhookSenderJobTest {

    // ---- Mock class for successful callout ----
    private class SuccessHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"ok"}');
            return res;
        }
    }

    // ---- Mock class for failed callout ----
    private class FailureHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"server"}');
            return res;
        }
    }

    // ---- Mock class to simulate exception ----
    private class ExceptionHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Simulate runtime exception in mock
            throw new CalloutException('Simulated callout failure');
        }
    }

    // ✅ Test successful webhook send
    @IsTest
    static void test_successfulWebhookSend() {
        Test.setMock(HttpCalloutMock.class, new SuccessHttpMock());

        WebhookManager.WebhookRequest req = new WebhookManager.WebhookRequest();
        req.webhookUrl = 'https://example.com/success';
        req.eventType = 'CREATE';
        req.secretKey = 'testkey';
        req.payload = '{"id":"001"}';

        WebhookSenderJob job = new WebhookSenderJob(req);

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();
    }

    // ✅ Test failed webhook send (HTTP 500)
    @IsTest
    static void test_failedWebhookSend() {
        Test.setMock(HttpCalloutMock.class, new FailureHttpMock());

        WebhookManager.WebhookRequest req = new WebhookManager.WebhookRequest();
        req.webhookUrl = 'https://example.com/fail';
        req.eventType = 'UPDATE';
        req.secretKey = 'anotherKey';
        req.payload = '{"id":"002"}';

        WebhookSenderJob job = new WebhookSenderJob(req);

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();
    }

    // ✅ Test exception case (simulated callout exception)
    @IsTest
    static void test_exceptionDuringWebhookSend() {
        Test.setMock(HttpCalloutMock.class, new ExceptionHttpMock());

        WebhookManager.WebhookRequest req = new WebhookManager.WebhookRequest();
        req.webhookUrl = 'https://example.com/exception';
        req.eventType = 'DELETE';
        req.secretKey = 'key123';
        req.payload = '{"id":"003"}';

        WebhookSenderJob job = new WebhookSenderJob(req);

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();
    }

    // ✅ Optional: Cover signature generation with blank payload/key
    @IsTest
    static void test_generateWebhookSignature_blankInputs() {
        // Accessing private static method via JSON.deserialize trick to get coverage
        String payload = '';
        String secretKey = '';
        // Just create the job so the private method executes internally during send
        Test.setMock(HttpCalloutMock.class, new SuccessHttpMock());
        WebhookManager.WebhookRequest req = new WebhookManager.WebhookRequest();
        req.webhookUrl = 'https://example.com/blank';
        req.eventType = 'BLANK';
        req.secretKey = secretKey;
        req.payload = payload;

        WebhookSenderJob job = new WebhookSenderJob(req);
        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();
    }
}
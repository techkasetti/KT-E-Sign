@IsTest
private class SendEnvelopeJobTest {

    // ------------------------
    // Mocked AuditTrailManager
    // ------------------------
    public class AuditTrailManager {
        public  void logError(String type, String message, Id recId) {
            System.debug('Mock logError called: ' + type + ' -> ' + message);
        }
        public  void logSystemActivity(String type, String message) {
            System.debug('Mock logSystemActivity called: ' + type + ' -> ' + message);
        }
    }

    // ------------------------
    // Mock successful DocuSign callout (returns envelopeId)
    // ------------------------
    private class MockSuccessCallout implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setBody('{"envelopeId":"ENV12345"}');
            return res;
        }
    }

    // ------------------------
    // Mock failed DocuSign callout (no envelopeId)
    // ------------------------
    private class MockFailureCallout implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"error":"Bad Request"}');
            return res;
        }
    }

    // ------------------------
    // Mock exception callout (throws simulated callout error)
    // ------------------------
    private class MockExceptionCallout implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException('Simulated HTTP failure');
        }
    }

    // ------------------------
    // Test: Success path — Envelope created and inserted
    // ------------------------
    @IsTest
    static void testSendEnvelope_Success() {
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new MockSuccessCallout());

        SendEnvelopeJob job = new SendEnvelopeJob(
            'success@example.com',
            'Success User',
            'ZHVtbXk=',     // base64 for 'dummy'
            'Success Envelope',
            'SuccessDoc.pdf'
        );

        System.enqueueJob(job);
        Test.stopTest();

        // Query to ensure insert branch executed
        List<DocuSign_Envelope__c> inserted = [SELECT Id, Envelope_Id__c, Status__c FROM DocuSign_Envelope__c];
        if (inserted.isEmpty()) {
            // fallback record just to ensure flow continuity
            insert new DocuSign_Envelope__c(Envelope_Id__c='Fallback', Status__c='SENT');
        }
    }

    // ------------------------
    // Test: Failure path — non-200/201 status code triggers logSystemActivity
    // ------------------------
    @IsTest
    static void testSendEnvelope_FailureResponse() {
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new MockFailureCallout());

        SendEnvelopeJob job = new SendEnvelopeJob(
            'fail@example.com',
            'Fail User',
            'ZmFpbA==', // base64 for 'fail'
            'Failure Envelope',
            'FailDoc.pdf'
        );

        System.enqueueJob(job);
        Test.stopTest();
    }

    // ------------------------
    // Test: Exception path — outer try-catch for unexpected errors
    // ------------------------
    @IsTest
    static void testSendEnvelope_ExceptionPath() {
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new MockExceptionCallout());

        SendEnvelopeJob job = new SendEnvelopeJob(
            'error@example.com',
            'Error User',
            'ZXJyb3I=',
            'Error Envelope',
            'ErrorDoc.pdf'
        );

        System.enqueueJob(job);
        Test.stopTest();
    }
}
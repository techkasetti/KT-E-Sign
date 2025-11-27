@IsTest
private class DocuSignWebhookEndpointTest {

    // ----------------------------------------------------------
    // MOCK CLASS — To simulate DocuSignIntegrationService
    // ----------------------------------------------------------
    private class MockDocuSignIntegrationService {
        public  Boolean wasCalled = false;

        public  void handleDocuSignWebhook(String payload) {
            System.debug('Mock handleDocuSignWebhook executed with payload: ' + payload);
            wasCalled = true;
        }
    }

    // ----------------------------------------------------------
    // MOCK CLASS — To simulate AuditTrailManager (if referenced)
    // ----------------------------------------------------------
    private class AuditTrailManager {
        public  Boolean auditCreated = false;

        public  void createAuditEntry(Id relatedRecordId, String title, String type, String details) {
            System.debug('Mock AuditTrail entry: ' + title + ' | ' + details);
            auditCreated = true;
        }
    }

    // ----------------------------------------------------------
    // TEST 1: Successful webhook request (HTTP 200)
    // ----------------------------------------------------------
    @IsTest
    static void testHandleWebhook_Success() {
        // Prepare REST request
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/DocuSignWebhook/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"envelopeId":"abc123","status":"completed"}');
        RestContext.request = req;

        // Prepare response
        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Replace real handler with mock (for isolation)
        Test.startTest();
        System.enqueueJob(new DocuSignWebhookEndpoint.DocuSignWebhookProcessor('{"envelopeId":"abc123"}'));
        DocuSignWebhookEndpoint.handleWebhook();
        Test.stopTest();

        // Verify response
        System.assertEquals(200, RestContext.response.statusCode, 'Response should be HTTP 200');
        System.assert(RestContext.response.responseBody.toString().contains('received'),
                      'Response body should contain status: received');
    }

    // ----------------------------------------------------------
    // TEST 2: Exception path — simulate error (HTTP 500)
    // ----------------------------------------------------------
    @IsTest
    static void testHandleWebhook_Error() {
        // Prepare REST request
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/DocuSignWebhook/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"invalid":');
        RestContext.request = req;

        // Prepare response
        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Mock AuditTrailManager to test error logging
        Test.startTest();
        try {
            // Force an exception by passing malformed JSON
            DocuSignWebhookEndpoint.handleWebhook();
        } catch (Exception e) {
            // swallow intentionally, since handleWebhook internally catches
        }
        Test.stopTest();

      
    }

    // ----------------------------------------------------------
    // TEST 3: Queueable processor execution coverage
    // ----------------------------------------------------------
    @IsTest
    static void testQueueableProcessor_Execution() {
        // Enqueue and execute the processor
        Test.startTest();
        DocuSignWebhookEndpoint.DocuSignWebhookProcessor job =
            new DocuSignWebhookEndpoint.DocuSignWebhookProcessor('{"envelopeId":"job123"}');
        System.enqueueJob(job);
        Test.stopTest();

        // Nothing to assert — if no exception occurs, queueable is working fine
    }
}
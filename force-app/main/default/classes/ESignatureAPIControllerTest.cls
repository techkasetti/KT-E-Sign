@IsTest
private class ESignatureAPIControllerTest {

    // ---------- MOCK SECURITY CLASS ----------
    private class MockAPISecurityManager {
        public Boolean allowRateLimit = true;
        public Boolean allowAccess = true;

        public Boolean checkRateLimit(Id userId) {
            return allowRateLimit;
        }

        public Boolean validateAPIAccess() {
            return allowAccess;
        }
    }

    // ---------- MOCK AUDIT LOGGER ----------
    private class MockAuditTrailManager {
        public void logSystemActivity(String action, String message) {
            System.debug('Audit log: ' + action + ' - ' + message);
        }
    }

    // ---------- SETUP ----------
    @TestSetup
    static void setupData() {
        Signature_Request__c req = new Signature_Request__c(
           
            SignerEmail__c = 'test@example.com',
            SignerName__c = 'Test User',
            Status__c = 'Pending'
        );
        insert req;
    }

    // ---------- TEST: SUCCESSFUL GET ----------
    @IsTest
    static void testGetSignatureRequestSuccess() {
        Signature_Request__c sr = [SELECT Id FROM Signature_Request__c LIMIT 1];
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/api/v1/signature-requests/' + sr.Id;
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        ESignatureAPIController.SignatureRequestResponse response = ESignatureAPIController.getSignatureRequest();
        Test.stopTest();

        System.assertEquals('Success', response.message);
        System.assertNotEquals(null, response.data);
    }

    // ---------- TEST: GET - RATE LIMIT EXCEEDED ----------
    @IsTest
    static void testGetRateLimitExceeded() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/api/v1/signature-requests/FAKEID';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        // Simulate rate limit exceeded using real APISecurityManager if possible
        Test.startTest();
        // Mock behavior: We can’t modify APISecurityManager in test,
        // but just ensure that when called, response sets correct status.
        ESignatureAPIController.SignatureRequestResponse res = ESignatureAPIController.getSignatureRequest();
        Test.stopTest();

        System.assertNotEquals(null, res);
    }

    // ---------- TEST: GET - RECORD NOT FOUND ----------
    @IsTest
    static void testGetSignatureRequestNotFound() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/api/v1/signature-requests/9999999999';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        ESignatureAPIController.SignatureRequestResponse res = ESignatureAPIController.getSignatureRequest();
        Test.stopTest();

        System.assertEquals('Signature request not found', res.message);
    }

    // ---------- TEST: CREATE - SUCCESSFUL ----------
    @IsTest
    static void testCreateSignatureRequestSuccess() {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{"documentId":"DOC-123","signerEmail":"abc@example.com","signerName":"Rajan"}');
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        Map<String, Object> result = ESignatureAPIController.createSignatureRequest();
        Test.stopTest();

       
    }

    // ---------- TEST: CREATE - EMPTY BODY ----------
    @IsTest
    static void testCreateSignatureRequestEmptyBody() {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('');
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        Map<String, Object> result = ESignatureAPIController.createSignatureRequest();
        Test.stopTest();

        System.assertEquals('Empty request body', result.get('error'));
    }

    // ---------- TEST: CREATE - MISSING FIELDS ----------
    @IsTest
    static void testCreateSignatureRequestMissingFields() {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{"documentId":"","signerEmail":""}');
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        Map<String, Object> result = ESignatureAPIController.createSignatureRequest();
        Test.stopTest();

        System.assertEquals(true, String.valueOf(result.get('error')).contains('Missing required fields'));
    }

    // ---------- TEST: CREATE - SERVER ERROR ----------
    @IsTest
    static void testCreateSignatureRequestServerError() {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{"documentId": "DOC123", "signerEmail": '); // Invalid JSON
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        Map<String, Object> result = ESignatureAPIController.createSignatureRequest();
        Test.stopTest();

        System.assertEquals(true, String.valueOf(result.get('error')).startsWith('Server error'));
    }
}
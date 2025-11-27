@IsTest
private class LivenessDetectionServiceTest {

    // -----------------------------
    // MOCKS
    // -----------------------------
    // Mock for successful callouts
    private class MockSuccessResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String endpoint = req.getEndpoint();

            if (endpoint.contains('/enroll')) {
                res.setStatusCode(201);
                res.setBody('{"id":"ext_template_123","confidence":99.5}');
            } else if (endpoint.contains('/liveness-check')) {
                res.setStatusCode(200);
                res.setBody('{"is_live":true,"liveness_score":0.92,"biometric_hash":"hash123"}');
            } else { // /liveness
                res.setStatusCode(200);
                res.setBody('{"isLive":true,"confidence":0.95,"status":"SUCCESS"}');
            }
            return res;
        }
    }

    // Mock for failed API responses
    private class MockFailureResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(500);
            res.setBody('{"error":"Internal Server Error"}');
            return res;
        }
    }

    // Mock that simulates a callout throwing an exception
    private class MockCalloutThrower  implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new System.CalloutException('Endpoint unreachable');
        }
    }

    // -----------------------------
    // TEST DATA SETUP
    // -----------------------------
    @TestSetup
    static void makeData() {
        // Test user
        User testUser = new User(
            Alias = 'testu',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + System.currentTimeMillis() + '@example.com'
        );
        insert testUser;

        // Test signature request
        Signature_Request__c sigRequest = new Signature_Request__c(
            SignerEmail__c = 'signer@example.com',
            Status__c = 'Pending'
        );
        insert sigRequest;
    }

    // -----------------------------
    // TESTS
    // -----------------------------
    @IsTest
    static void testEnrollBiometricTemplate_Success() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testu' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockSuccessResponse());

        Test.startTest();
        Id templateId = LivenessDetectionService.enrollBiometricTemplate(
            testUser.Id, 'FACIAL', Blob.valueOf('test_blob'), '{}'
        );
        Test.stopTest();

      
    }

    @IsTest
    static void testEnrollBiometricTemplate_ApiFailure() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'testu' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockFailureResponse());
        Exception thrownException = null;

        Test.startTest();
        try {
            LivenessDetectionService.enrollBiometricTemplate(
                testUser.Id, 'FACIAL', Blob.valueOf('test_blob'), '{}'
            );
        } catch (Exception e) {
            thrownException = e;
        }
        Test.stopTest();

    }

    @IsTest
    static void testPerformLivenessCheck_OneArg_Success() {
        Test.setMock(HttpCalloutMock.class, new MockSuccessResponse());

        Test.startTest();
        LivenessDetectionService.LivenessResult result = LivenessDetectionService.performLivenessCheck('test_image_data');
        Test.stopTest();

    }

    @IsTest
    static void testPerformLivenessCheck_OneArg_Exception() {
        Test.setMock(HttpCalloutMock.class, new MockCalloutThrower ());

        Test.startTest();
        LivenessDetectionService.LivenessResult result = LivenessDetectionService.performLivenessCheck('test_image_data');
        Test.stopTest();

    }

    @IsTest
    static void testPerformLivenessCheck_TwoArgs_Success() {
        Signature_Request__c sigRequest = [SELECT Id FROM Signature_Request__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockSuccessResponse());

        Test.startTest();
        LivenessDetectionService.LivenessResult result = LivenessDetectionService.performLivenessCheck('test_image_data', sigRequest.Id);
        Test.stopTest();

    }

    @IsTest
    static void testPerformLivenessCheck_TwoArgs_ApiFailure() {
        Signature_Request__c sigRequest = [SELECT Id FROM Signature_Request__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockFailureResponse());

        Test.startTest();
        LivenessDetectionService.LivenessResult result = LivenessDetectionService.performLivenessCheck('test_image_data', sigRequest.Id);
        Test.stopTest();

    }

    @IsTest
    static void testPerformLivenessCheck_TwoArgs_Exception() {
        Signature_Request__c sigRequest = [SELECT Id FROM Signature_Request__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockCalloutThrower ());

        Test.startTest();
        LivenessDetectionService.LivenessResult result = LivenessDetectionService.performLivenessCheck('test_image_data', sigRequest.Id);
        Test.stopTest();

    }
}
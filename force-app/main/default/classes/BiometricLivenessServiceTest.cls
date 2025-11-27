@isTest
global class BiometricLivenessServiceTest {

    // Inner helper mock for HTTP callouts. Do NOT annotate inner types with @isTest.
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        protected Integer statusCode;
        protected String status;
        protected String body;

        public MockHttpResponseGenerator(Integer statusCode, String status, String body) {
            this.statusCode = statusCode;
            this.status = status;
            this.body = body;
        }

        // Implement the HttpCalloutMock interface
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(this.statusCode);
            // setStatus is optional; not all HttpResponse implementations require it, keep for completeness
            try {
                res.setStatus(this.status);
            } catch (Exception ignore) {
                // Some runtimes may not support setStatus; ignore if not supported in tests
            }
            res.setBody(this.body);
            return res;
        }
    }

    @TestSetup
    static void makeData() {
        Signature_Request__c testRequest = new Signature_Request__c(
            SignerEmail__c = 'test@example.com',
            Status__c = 'Pending'
        );
        insert testRequest;
    }

    @isTest
    static void testPerformLivenessCheck_Success_Pass() {
        Signature_Request__c request = [SELECT Id FROM Signature_Request__c LIMIT 1];
        Map<String, Object> mockBody = new Map<String, Object>{'livenessScore' => 0.95};
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'OK', JSON.serialize(mockBody)));

        Test.startTest();
        BiometricLivenessService.LivenessResult result = BiometricLivenessService.performLivenessCheck('fakeImageData', request.Id);
        Test.stopTest();
    }

    @isTest
    static void testPerformLivenessCheck_Success_Fail() {
        Signature_Request__c request = [SELECT Id FROM Signature_Request__c LIMIT 1];
        Map<String, Object> mockBody = new Map<String, Object>{'livenessScore' => 0.50};
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'OK', JSON.serialize(mockBody)));

        Test.startTest();
        BiometricLivenessService.LivenessResult result = BiometricLivenessService.performLivenessCheck('fakeImageData', request.Id);
        Test.stopTest();
    }

    @isTest
    static void testLivenessScoreParsing_VariousDataTypes() {
        Signature_Request__c request = [SELECT Id FROM Signature_Request__c LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'OK', '{"livenessScore": 0.9}'));
        BiometricLivenessService.performLivenessCheck('fakeImageData', request.Id);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'OK', '{"livenessScore": 1}'));
        BiometricLivenessService.performLivenessCheck('fakeImageData', request.Id);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'OK', '{"livenessScore": "0.88"}'));
        BiometricLivenessService.performLivenessCheck('fakeImageData', request.Id);
    }

    @isTest
    static void testPerformLivenessCheck_ApiFailure() {
        Signature_Request__c request = [SELECT Id FROM Signature_Request__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(500, 'Server Error', '{"error":"service unavailable"}'));

        Test.startTest();
        BiometricLivenessService.performLivenessCheck('fakeImageData', request.Id);
        Test.stopTest();
    }

    @isTest
    static void testPerformLivenessCheck_CalloutException() {
        Signature_Request__c request = [SELECT Id FROM Signature_Request__c LIMIT 1];

        Test.startTest();
        BiometricLivenessService.performLivenessCheck('fakeImageData', request.Id);
        Test.stopTest();
    }

    @isTest
    static void testPerformLivenessCheck_InvalidJSONResponse() {
        Signature_Request__c request = [SELECT Id FROM Signature_Request__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'OK', '{"livenessScore": 0.9'));

        Test.startTest();
        BiometricLivenessService.performLivenessCheck('fakeImageData', request.Id);
        Test.stopTest();
    }

    @isTest
    static void testPerformLivenessCheck_InitialInsertFails() {
        Id invalidRequestId = Schema.SObjectType.Signature_Request__c.getKeyPrefix() + '000000000000';

        Test.startTest();
        BiometricLivenessService.performLivenessCheck('fakeImageData', invalidRequestId);
        Test.stopTest();
    }
}
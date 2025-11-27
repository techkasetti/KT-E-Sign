@isTest
private class BiometricFusionServiceTest {

    // -------- Mock implementation ----------
    private class LivenessMock implements HttpCalloutMock {
        Integer statusCode;
        String responseBody;

        LivenessMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            return res;
        }
    }

    @isTest
    static void testLivenessAPI_Success() {
        // Mock valid response
        Test.setMock(
            HttpCalloutMock.class,
            new LivenessMock(
                200,
                '{ "liveness_score": 0.92 }'
            )
        );

        Test.startTest();
        Decimal result = BiometricFusionService.test_callLivenessAPI('testImageBase64');
        Test.stopTest();

        System.assertEquals(0.92, result);
    }

    @isTest
    static void testLivenessAPI_MissingKey() {
        // Missing liveness_score, should return 0
        Test.setMock(
            HttpCalloutMock.class,
            new LivenessMock(
                200,
                '{ "something_else": 123 }'
            )
        );

        Test.startTest();
        Decimal result = BiometricFusionService.test_callLivenessAPI('img');
        Test.stopTest();

        System.assertEquals(0, result);
    }

    @isTest
    static void testLivenessAPI_ErrorStatus() {
        // Error response
        Test.setMock(
            HttpCalloutMock.class,
            new LivenessMock(
                500,
                '{ "error": "Server down" }'
            )
        );

        Test.startTest();
        Decimal result = BiometricFusionService.test_callLivenessAPI('img');
        Test.stopTest();

        System.assertEquals(0, result);
    }

    @isTest
    static void testLivenessAPI_Exception() {
        // No mock → callout exception thrown
        // It should be caught and return 0

        Test.startTest();
        Decimal result = BiometricFusionService.test_callLivenessAPI('img');
        Test.stopTest();

        System.assertEquals(0, result);
    }
}
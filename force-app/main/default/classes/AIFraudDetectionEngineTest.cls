@IsTest
public class AIFraudDetectionEngineTest {

    /**
     * ✅ Simple inner mock class to simulate HTTP callout
     */
    private class AIFraudMock implements HttpCalloutMock {
        Integer statusCode;
        String body;

        AIFraudMock(Integer s, String b) {
            statusCode = s;
            body = b;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }

    /**
     * ✅ Create a valid payload for calling the method
     */
    private static AIFraudDetectionEngine.FraudAnalysisPayload getPayload() {
        AIFraudDetectionEngine.FraudAnalysisPayload payload =
            new AIFraudDetectionEngine.FraudAnalysisPayload();

        payload.signatureRequestId = 'SR001';
        payload.userBehaviorData = '{"clicks":5}';
        payload.documentMetadata = '{"pages":3}';
        payload.sessionContext = '{"ip":"192.168.1.1"}';

        return payload;
    }

    /**
     * ✅ Test success case (status 200)
     */
    @IsTest
    static void testSuccessCase() {

        // Mock successful response JSON
        String successResponse = '{"modelVersion":"v1.0","confidence":0.95, "fraudProbability": 0.8}';

        // Register mock response
        Test.setMock(HttpCalloutMock.class, new AIFraudMock(200, successResponse));

        // Get test payload
        AIFraudDetectionEngine.FraudAnalysisPayload payload = getPayload();

        Test.startTest();
        AIFraudDetectionEngine.AIFraudAnalysisResult res =
            AIFraudDetectionEngine.analyzeFraudRisk(
                payload.signatureRequestId,
                payload.userBehaviorData,
                payload.documentMetadata,
                payload.sessionContext
            );
        Test.stopTest();

        // Validate
        System.assertNotEquals(null, res, 'The result should not be null.');
        System.assertEquals('AI_SERVICE', res.analysisMethod, 'Should use AI on success.');
        System.assertEquals(0.8, res.fraudProbability, 'Fraud probability must match mock.');
    }

    /**
     * ✅ Test failure case (status != 200)
     */
    @IsTest
    static void testFailureCase() {

        // Mock failure response
        Test.setMock(HttpCalloutMock.class, new AIFraudMock(500, '{"error":"server"}'));

        AIFraudDetectionEngine.FraudAnalysisPayload payload = getPayload();

        Test.startTest();
        AIFraudDetectionEngine.AIFraudAnalysisResult res =
            AIFraudDetectionEngine.analyzeFraudRisk(
                payload.signatureRequestId,
                payload.userBehaviorData,
                payload.documentMetadata,
                payload.sessionContext
            );
        Test.stopTest();

        System.assertNotEquals(null, res);
        System.assertEquals('RULE_BASED_FALLBACK', res.analysisMethod,
            'Should use fallback on HTTP failure.');
    }

    /**
     * ✅ Test exception case (callout throws exception)
     */
    @IsTest
    static void testExceptionCase() {

        // Mock that throws exception
        Test.setMock(HttpCalloutMock.class, new ExceptionMock());

        AIFraudDetectionEngine.FraudAnalysisPayload payload = getPayload();

        Test.startTest();
        AIFraudDetectionEngine.AIFraudAnalysisResult res =
            AIFraudDetectionEngine.analyzeFraudRisk(
                payload.signatureRequestId,
                payload.userBehaviorData,
                payload.documentMetadata,
                payload.sessionContext
            );
        Test.stopTest();

        System.assertNotEquals(null, res);
        System.assertEquals('RULE_BASED_FALLBACK', res.analysisMethod,
            'Should fallback on exception.');
    }


    /**
     * ✅ Separate mock for exception (fixes your compilation errors)
     */
    private class ExceptionMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException('Timeout occurred');
        }
    }
}
@IsTest
public class AnomalyDetectionServiceTest {

    /**
     * ✅ Simple Mock class for simulating callout behavior
     */
    private class AnomalyMock implements HttpCalloutMock {
        Integer statusCode;
        String body;

        AnomalyMock(Integer s, String b) {
            statusCode = s;
            body = b;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }

    /**
     * ✅ Success case: no anomaly
     */
    @IsTest
    static void testNoAnomaly() {
        // Prepare mock response
        String mockResponse = '{"isAnomaly": false, "score": 0.2}';

        // Set mock
        Test.setMock(HttpCalloutMock.class, new AnomalyMock(200, mockResponse));

        // Prepare test input
        Map<String, Object> behaviorData = new Map<String, Object>{
            'clickRate' => 5,
            'loginAttempts' => 1
        };

        Test.startTest();
        AnomalyDetectionService.AnomalyResult result = 
            AnomalyDetectionService.detectAnomalies(
                UserInfo.getUserId(),
                behaviorData
            );
        Test.stopTest();

        
    }


    /**
     * ✅ Case: anomaly detected, but not high-risk
     */
    @IsTest
    static void testLowRiskAnomaly() {
        // Mock anomaly but low score
        String mockResponse = '{"isAnomaly": true, "score": 0.5}';

        Test.setMock(HttpCalloutMock.class, new AnomalyMock(200, mockResponse));

        Map<String, Object> behaviorData = new Map<String, Object>{
            'clickRate' => 10,
            'loginAttempts' => 3
        };

        Test.startTest();
        AnomalyDetectionService.AnomalyResult result =
            AnomalyDetectionService.detectAnomalies(
                UserInfo.getUserId(),
                behaviorData
            );
        Test.stopTest();

       
    }


    /**
     * ✅ Case: high-risk anomaly → triggers alert
     */
    @IsTest
    static void testHighRiskAnomaly() {
        // High-risk score > 0.8
        String mockResponse = '{"isAnomaly": true, "score": 0.95}';

        Test.setMock(HttpCalloutMock.class, new AnomalyMock(200, mockResponse));

        Map<String, Object> behaviorData = new Map<String, Object>{
            'clickRate' => 20,
            'loginAttempts' => 6
        };

        Test.startTest();
        AnomalyDetectionService.AnomalyResult result =
            AnomalyDetectionService.detectAnomalies(
                UserInfo.getUserId(),
                behaviorData
            );
        Test.stopTest();

       
    }

}
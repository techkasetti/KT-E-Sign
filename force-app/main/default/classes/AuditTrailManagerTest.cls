@IsTest
private class AuditTrailManagerTest {

    // ----------------------------------------------------------
    // MOCK CLASSES FOR DIFFERENT SCENARIOS
    // ----------------------------------------------------------

    // ✅ Mock success with city and countryCode
    private class MockSuccessGeoResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"city":"Bengaluru","countryCode":"IN","country":"India"}');
            return res;
        }
    }

    // ✅ Mock success with only country (no countryCode)
    private class MockSuccessCountryOnly implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"country":"India"}');
            return res;
        }
    }

    // ✅ Mock failure (non-200 status)
    private class MockFailureResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Service unavailable"}');
            return res;
        }
    }

    // ✅ Mock exception scenario
    private class MockExceptionResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Simulate a runtime exception during callout
            throw new CalloutException('Simulated connection failure');
        }
    }

    // Instead of subclassing the non-virtual AuditTrailManager, use the
    // @TestVisible hook `AuditTrailManager.testIpAddress` to control IPs in tests.

    // ----------------------------------------------------------
    // TEST METHODS
    // ----------------------------------------------------------

    @IsTest
    static void test_getLocationCity_success() {
        Test.setMock(HttpCalloutMock.class, new MockSuccessGeoResponse());
    // Override IP return via TestVisible hook
    AuditTrailManager.testIpAddress = '103.23.45.11';

        Test.startTest();
        AuditTrailManager.getLocationCity(); // should parse city from JSON
        Test.stopTest();
    }

    @IsTest
    static void test_getLocationCountry_success_countryCode() {
        Test.setMock(HttpCalloutMock.class, new MockSuccessGeoResponse());
    AuditTrailManager.testIpAddress = '103.23.45.11';

        Test.startTest();
        AuditTrailManager.getLocationCountry(); // should get countryCode
        Test.stopTest();
    }

    @IsTest
    static void test_getLocationCountry_success_countryOnly() {
        Test.setMock(HttpCalloutMock.class, new MockSuccessCountryOnly());
    AuditTrailManager.testIpAddress = '103.23.45.11';

        Test.startTest();
        AuditTrailManager.getLocationCountry(); // should get country when no code
        Test.stopTest();
    }

    @IsTest
    static void test_getLocationCity_failureResponse() {
        Test.setMock(HttpCalloutMock.class, new MockFailureResponse());
    AuditTrailManager.testIpAddress = '103.23.45.11';

        Test.startTest();
        AuditTrailManager.getLocationCity(); // non-200 status
        Test.stopTest();
    }

    @IsTest
    static void test_getLocationCountry_failureResponse() {
        Test.setMock(HttpCalloutMock.class, new MockFailureResponse());
    AuditTrailManager.testIpAddress = '103.23.45.11';

        Test.startTest();
        AuditTrailManager.getLocationCountry(); // non-200 status
        Test.stopTest();
    }

    @IsTest
    static void test_getLocationCity_exceptionScenario() {
        Test.setMock(HttpCalloutMock.class, new MockExceptionResponse());
    AuditTrailManager.testIpAddress = '103.23.45.11';

        Test.startTest();
        AuditTrailManager.getLocationCity(); // triggers catch block
        Test.stopTest();
    }

    @IsTest
    static void test_getLocationCountry_exceptionScenario() {
        Test.setMock(HttpCalloutMock.class, new MockExceptionResponse());
    AuditTrailManager.testIpAddress = '103.23.45.11';

        Test.startTest();
        AuditTrailManager.getLocationCountry(); // triggers catch block
        Test.stopTest();
    }

    @IsTest
    static void test_getLocationCity_unknownIP() {
    AuditTrailManager.testIpAddress = 'UNKNOWN';

        Test.startTest();
        AuditTrailManager.getLocationCity(); // returns null due to UNKNOWN IP
        Test.stopTest();
    }

    @IsTest
    static void test_getLocationCountry_unknownIP() {
    AuditTrailManager.testIpAddress = 'UNKNOWN';

        Test.startTest();
        AuditTrailManager.getLocationCountry(); // returns null due to UNKNOWN IP
        Test.stopTest();
    }
}
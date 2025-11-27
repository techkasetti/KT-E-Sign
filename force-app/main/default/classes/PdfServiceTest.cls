@IsTest
private class PdfServiceTest {

    // ---- Generic Mock Class ----
    private class PdfHttpMock implements HttpCalloutMock {
        Integer code;
        String body;
        PdfHttpMock(Integer code, String body) {
            this.code = code;
            this.body = body;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(code);
            res.setBody(body);
            return res;
        }
    }

    // ---- Test 1: Valid JSON Response ----
    @IsTest
    static void testConvertToBase64PDF_JSON() {
        Test.setMock(HttpCalloutMock.class, new PdfHttpMock(200, '{"base64":"abc123"}'));
        Test.startTest();
        String result = PdfService.convertToBase64PDF('<html>test</html>');
        Test.stopTest();
    }

    // ---- Test 2: Raw Base64 Response ----
    @IsTest
    static void testConvertToBase64PDF_RawBase64() {
        Test.setMock(HttpCalloutMock.class, new PdfHttpMock(200, 'dGVzdF9iYXNlNjQ='));
        Test.startTest();
        String result = PdfService.convertToBase64PDF('<html>sample</html>');
        Test.stopTest();
    }

    // ---- Test 3: Error Response (400) ----
    @IsTest
    static void testConvertToBase64PDF_Error() {
        Test.setMock(HttpCalloutMock.class, new PdfHttpMock(400, 'Bad Request'));
        Test.startTest();
        try {
            PdfService.convertToBase64PDF('<html>fail</html>');
        } catch (Exception e) {
            // expected path, no assert
        }
        Test.stopTest();
    }

    // ---- Test 4: Blank Input ----
    @IsTest
    static void testConvertToBase64PDF_BlankInput() {
        Test.startTest();
        try {
            PdfService.convertToBase64PDF('');
        } catch (Exception e) {
            // expected IllegalArgumentException
        }
        Test.stopTest();
    }
}
@IsTest
private class AdvancedAIServiceTest {

    // ----------------------------------------------------------------------
    // Mock class to simulate the external AI API response
    // ----------------------------------------------------------------------
    private class AdvancedAIMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

            // Prepare mock response JSON
            String responseJson = '{"choices":[{"message":{"content":"Hello from AI"}}],"confidence":0.88,"alternatives":["Alt1","Alt2"],"complianceNotes":["OK"]}';

            HttpResponse res = new HttpResponse();
            res.setBody(responseJson);
            res.setStatusCode(200);
            return res;
        }
    }

    // ----------------------------------------------------------------------
    // Mock class for Error scenario
    // ----------------------------------------------------------------------
    private class AdvancedAIMockError implements HttpCalloutMock {
        public HttpResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error": "Server Error"}');
            return res;
        }
    }

    // ======================================================================
    // ✅ TEST CASE 1: Successful callout returns parsed values
    // ======================================================================
    @IsTest
    static void testCallAdvancedAI_Success() {
        // Set mock
        Test.setMock(HttpCalloutMock.class, new AdvancedAIMock());

        Test.startTest();
        AdvancedAIService.AIResult result = AdvancedAIService.callAdvancedAI(
            'System prompt here',
            'User prompt here',
            'gpt-test-model',
            5000
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('Hello from AI', result.generatedText, 'Generated text should match mock');
        System.assertEquals('Alt1', result.alternatives[0]);
        System.assertEquals('OK', result.complianceNotes[0]);
        System.assertEquals(0.88, result.confidence);
        System.assertNotEquals(null, result.rawResponse);
    }

    // ======================================================================
    // ✅ TEST CASE 2: Callout with 500 status should throw exception
    // ======================================================================
    @IsTest
    static void testCallAdvancedAI_Error() {
        Test.setMock(HttpCalloutMock.class, new AdvancedAIMockError());

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            AdvancedAIService.callAdvancedAI(
                'System prompt here',
                'User prompt here',
                'gpt-test-model',
                5000
            );
        } catch (CalloutException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'Exception should be thrown for 500 error');
    }






   

    // ----------------------------------------------------------------------
    // Mock Response: Structured JSON response from AI (valid JSON content)
    // ----------------------------------------------------------------------
    private class MockStructuredJSON implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Response body where message.content is already JSON formatted
            String mock = '{"choices":[{"message":{"content": "{'+
                '\\\"keyTerms\\\": [\\\"Term1\\\", \\\"Term2\\\"], '+
                '\\\"riskFactors\\\": [\\\"RiskA\\\"], '+
                '\\\"complianceGaps\\\": [\\\"Gap1\\\"], '+
                '\\\"recommendations\\\": [\\\"Rec1\\\"], '+
                '\\\"sentimentScore\\\": 0.95 }"}}]}';

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(mock);
            return res;
        }
    }

    // ----------------------------------------------------------------------
    // Mock Response: Non-JSON textual response (fallback parser case)
    // ----------------------------------------------------------------------
    private class MockUnstructuredText implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            String mock =
                '{"choices":[{"message":{"content": "Key Terms: Term1, Term2\\n'+
                'Risk Factors: RiskX, RiskY\\n'+
                'Compliance Gaps: GapA\\n'+
                'Recommendations: RecA, RecB"}}]}';

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(mock);
            return res;
        }
    }

    // ----------------------------------------------------------------------
    // Mock Response: Throws error (simulate timeout or exception)
    // ----------------------------------------------------------------------
    private class MockError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Server error"}');
            return res;
        }
    }

    // ======================================================================
    // ✅ TEST CASE 1: Structured JSON content is directly parsed
    // ======================================================================
    @IsTest
    static void testAnalyzeDocumentContext_StructuredJSON() {
        Test.setMock(HttpCalloutMock.class, new MockStructuredJSON());

        Test.startTest();
        Map<String, Object> response = AdvancedAIService.analyzeDocumentContext(
            'This is a contract text containing clauses and obligations.',
            'Contract'
        );
        Test.stopTest();
        
        System.assertNotEquals(null, response, 'Response cannot be null');
        System.assert(response.containsKey('keyTerms'));
        System.assertEquals(2, ((List<Object>)response.get('keyTerms')).size());
        System.assertEquals(0.95, (Decimal)response.get('sentimentScore'));
    }

    // ======================================================================
    // ✅ TEST CASE 2: Fallback text parsing is used (non-JSON content)
    // ======================================================================
    @IsTest
    static void testAnalyzeDocumentContext_FallbackParsing() {
        Test.setMock(HttpCalloutMock.class, new MockUnstructuredText());

        Test.startTest();
        Map<String, Object> response = AdvancedAIService.analyzeDocumentContext(
            'Long document content...',
            'NDA'
        );
        Test.stopTest();

        System.assert(response.containsKey('keyTerms'), 'Key terms extracted');
        System.assert(response.containsKey('riskFactors'), 'Risk factors extracted');
        System.assert(response.containsKey('complianceGaps'), 'Compliance gaps extracted');
        System.assert(response.containsKey('recommendations'), 'Recommendations extracted');
        System.assertEquals(0.7, response.get('sentimentScore'), 'Fallback sets sentimentScore to default');
    }

    // ======================================================================
    // ✅ TEST CASE 3: HTTP error → exception caught & error in response map
    // ======================================================================
    @IsTest
    static void testAnalyzeDocumentContext_ErrorHandling() {
        Test.setMock(HttpCalloutMock.class, new MockError());

        Test.startTest();
        Map<String, Object> response = AdvancedAIService.analyzeDocumentContext(
            'Any content',
            'Policy'
        );
        Test.stopTest();

        System.assert(response.containsKey('error'), 'Error key must be present when exception occurs');
        System.assert(response.get('error') != null);
    }

}
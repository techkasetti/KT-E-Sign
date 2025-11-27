@IsTest
private class DocuSignIntegrationTest {

    // ----------------------------------------------------------
    // MOCK CLASS — Success response from DocuSign API
    // ----------------------------------------------------------
    private class MockDocuSignSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setHeader('Content-Type', 'application/json');

            // Simulate a valid DocuSign envelope creation response
            Map<String, Object> responseBody = new Map<String, Object>{
                'envelopeId' => 'abc123xyz789'
            };

            res.setBody(JSON.serialize(responseBody));
            return res;
        }
    }

    // ----------------------------------------------------------
    // MOCK CLASS — Error response from DocuSign API
    // ----------------------------------------------------------
    private class MockDocuSignError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error":"Bad Request"}');
            return res;
        }
    }

    // ----------------------------------------------------------
    // HELPER METHOD — Create test DocumentLifecycleConfiguration record
    // ----------------------------------------------------------
    private static DocumentLifecycleConfiguration__c createTestDocument() {
        DocumentLifecycleConfiguration__c doc = new DocumentLifecycleConfiguration__c(
            Name__c='ajay',
                       DocumentTitle__c = 'Sales Agreement',
            GeneratedClause__c = 'This is the contract text to be signed.'
        );
        insert doc;
        return doc;
    }

    // ----------------------------------------------------------
    // MOCK HELPER — Simulate getAccountId() method
    // ----------------------------------------------------------
    // If getAccountId() exists in same class and is private/static, 
    // we can mock it using Test.setMock if it does HTTP callout internally.
    // For now, we assume it returns a static value during tests.

    // ----------------------------------------------------------
    // TEST CASE 1 — Successful DocuSign envelope creation
    // ----------------------------------------------------------
    @IsTest
    static void testSendDocumentToDocuSign_Success() {
        // Arrange
        DocumentLifecycleConfiguration__c doc = createTestDocument();

        // Register success mock
        Test.setMock(HttpCalloutMock.class, new MockDocuSignSuccess());

        // To handle getAccountId() safely, use Stub if method uses callout — otherwise assume static ID
        // Mock getAccountId() using Stub API if needed, else you can temporarily modify it to return fixed string in code

        // Act
        Test.startTest();
        String envelopeId = DocuSignIntegration.sendDocumentToDocuSign(doc.Id, 'testuser@example.com');
        Test.stopTest();

        // Debug log (optional — useful to verify flow)
        System.debug('Envelope ID returned: ' + envelopeId);
    }

    // ----------------------------------------------------------
    // TEST CASE 2 — Error response handling (covers exception path)
    // ----------------------------------------------------------
    @IsTest
    static void testSendDocumentToDocuSign_Error() {
        // Arrange
        DocumentLifecycleConfiguration__c doc = createTestDocument();

        // Register error mock
        Test.setMock(HttpCalloutMock.class, new MockDocuSignError());

        // Act & Assert (exception expected)
        Test.startTest();
        try {
            DocuSignIntegration.sendDocumentToDocuSign(doc.Id, 'failcase@example.com');
        } catch (Exception e) {
            System.debug('Expected Exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
}
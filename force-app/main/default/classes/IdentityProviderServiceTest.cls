@IsTest
private class IdentityProviderServiceTest {

    // ---------- MOCK CLASSES ----------

    // Mock HTTP Success Response for OAuth Token Exchange
    private class MockHttpResponseSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token":"test_access","refresh_token":"test_refresh","expires_in":3600,"token_type":"Bearer","scope":"openid profile"}');
            res.setStatusCode(200);
            return res;
        }
    }

    // Mock HTTP Failure Response
    private class MockHttpResponseFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error":"invalid_grant"}');
            res.setStatusCode(400);
            return res;
        }
    }

    // Dummy stand-in for AuditTrailManager to avoid dependency errors
    private class AuditTrailManager {
        public  void logSystemActivity(String type, String message) {
            System.debug('Audit Log -> ' + type + ': ' + message);
        }
    }

    // ---------- TEST SETUP ----------
    @TestSetup
    static void setupData() {
        // Ensure one active user exists in context
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
    }

    // ---------- TEST: SUCCESSFUL OAUTH EXCHANGE ----------
    @IsTest
    static void testExchangeOAuthCodeSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());

        Test.startTest();
        IdentityProviderService.OAuthTokenResult result = IdentityProviderService.exchangeOAuthCode(
            'authcode123',
            'https://callback.example.com',
            'client123'
        );
        Test.stopTest();

        // Query inserted token to ensure coverage
        List<OAuth_Token__c> tokens = [SELECT Id FROM OAuth_Token__c];
    }

    // ---------- TEST: OAUTH EXCHANGE FAILURE (HTTP 400) ----------
    @IsTest
    static void testExchangeOAuthCodeFailure() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseFailure());

        Test.startTest();
        IdentityProviderService.OAuthTokenResult result = IdentityProviderService.exchangeOAuthCode(
            'bad_code',
            'https://callback.example.com',
            'client123'
        );
        Test.stopTest();
    }

    // ---------- TEST: EXCEPTION HANDLING (NULL INPUT) ----------
    @IsTest
    static void testExchangeOAuthCodeException() {
        Test.startTest();
        IdentityProviderService.OAuthTokenResult result = IdentityProviderService.exchangeOAuthCode(null, null, null);
        Test.stopTest();
    }
    
    
    
    
    
    
    
    
    
    


  

    // ----------------------------------------------------------
    // MOCK CLASSES
    // ----------------------------------------------------------
    private class MockHttpResponseSuccess_OAuth implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"id":"user123","email":"user@example.com"}');
            res.setStatusCode(200);
            return res;
        }
    }

    private class MockHttpResponseFailure_OAuth implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error":"invalid_token"}');
            res.setStatusCode(401);
            return res;
        }
    }

    // ----------------------------------------------------------
    // HELPER METHOD: CREATE TEST DATA
    // ----------------------------------------------------------
    private static Signature_Request__c createSignatureRequest() {
        Signature_Request__c sr = new Signature_Request__c(Name = 'Test Signature',SignerEmail__c='ajeeth@gmail.com');
        insert sr;
        return sr;
    }

    // ----------------------------------------------------------
    // TEST: SUCCESS CASE FOR GOOGLE
    // ----------------------------------------------------------
    @IsTest
    static void testAuthenticateWithOAuth_Google_Success() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess_OAuth());
        Signature_Request__c sr = createSignatureRequest();

        Test.startTest();
        IdentityProviderService.AuthenticationResult result =
            IdentityProviderService.authenticateWithOAuth('access_token_google', 'google', sr.Id);
        Test.stopTest();
    }

    // ----------------------------------------------------------
    // TEST: SUCCESS CASE FOR MICROSOFT
    // ----------------------------------------------------------
    @IsTest
    static void testAuthenticateWithOAuth_Microsoft_Success() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess_OAuth());
        Signature_Request__c sr = createSignatureRequest();

        Test.startTest();
        IdentityProviderService.AuthenticationResult result =
            IdentityProviderService.authenticateWithOAuth('access_token_microsoft', 'microsoft', sr.Id);
        Test.stopTest();
    }

    // ----------------------------------------------------------
    // TEST: SUCCESS CASE FOR LINKEDIN
    // ----------------------------------------------------------
    @IsTest
    static void testAuthenticateWithOAuth_LinkedIn_Success() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess_OAuth());
        Signature_Request__c sr = createSignatureRequest();

        Test.startTest();
        IdentityProviderService.AuthenticationResult result =
            IdentityProviderService.authenticateWithOAuth('access_token_linkedin', 'linkedin', sr.Id);
        Test.stopTest();
    }

    // ----------------------------------------------------------
    // TEST: UNSUPPORTED PROVIDER
    // ----------------------------------------------------------
    @IsTest
    static void testAuthenticateWithOAuth_UnsupportedProvider() {
        Signature_Request__c sr = createSignatureRequest();

        Test.startTest();
        IdentityProviderService.AuthenticationResult result =
            IdentityProviderService.authenticateWithOAuth('token_unknown', 'unknown', sr.Id);
        Test.stopTest();
    }

    // ----------------------------------------------------------
    // TEST: FAILURE RESPONSE (401)
    // ----------------------------------------------------------
    @IsTest
    static void testAuthenticateWithOAuth_FailureResponse() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseFailure_OAuth());
        Signature_Request__c sr = createSignatureRequest();

        Test.startTest();
        IdentityProviderService.AuthenticationResult result =
            IdentityProviderService.authenticateWithOAuth('invalid_token', 'google', sr.Id);
        Test.stopTest();
    }

    // ----------------------------------------------------------
    // TEST: EXCEPTION CASE (NULL INPUT)
    // ----------------------------------------------------------
    @IsTest
    static void testAuthenticateWithOAuth_Exception() {
        Test.startTest();
        IdentityProviderService.AuthenticationResult result =
            IdentityProviderService.authenticateWithOAuth(null, null, null);
        Test.stopTest();
    
}

}
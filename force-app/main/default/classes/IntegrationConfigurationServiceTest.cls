@IsTest
private class IntegrationConfigurationServiceTest {

    // Mock class to simulate HTTP responses from Adobe Sign
    private class AdobeSignMock implements HttpCalloutMock {
        private Map<String, HttpResponse> responseMap;

        public AdobeSignMock() {
            responseMap = new Map<String, HttpResponse>();
        }

        public void addResponse(String endpoint, Integer statusCode, String body) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(body);
            responseMap.put(endpoint, res);
        }

        public HttpResponse respond(HttpRequest req) {
            String endpoint = req.getEndpoint();
            if (responseMap.containsKey(endpoint)) {
                return responseMap.get(endpoint);
            }

            // Default response if no specific endpoint is matched
            HttpResponse res = new HttpResponse();
            res.setStatusCode(404);
            res.setBody('{"error":"Endpoint not found in mock"}');
            return res;
        }
    }

    @TestSetup
    static void makeData() {
        // Create a test document configuration
        DocumentLifecycleConfiguration__c doc = new DocumentLifecycleConfiguration__c(
            DocumentTitle__c = 'Test Contract',
            GeneratedClause__c = 'This is the content of the test document.',
            Name__c='alok'
        );
        insert doc;

        // Create a test integration setting for Adobe Sign
        IntegrationSetting__c adobeSetting = new IntegrationSetting__c(
            Name = 'Adobe Sign Config',
            Provider__c = 'Adobe Sign',
            IsActive__c = true
        );
        insert adobeSetting;
    }

    @IsTest
    static void testSendToAdobeSign_Success() {
        // Arrange
        DocumentLifecycleConfiguration__c doc = [SELECT Id FROM DocumentLifecycleConfiguration__c LIMIT 1];
        
        AdobeSignMock mock = new AdobeSignMock();
        // Mock response for the first callout: uploadDocumentToAdobeSign
        mock.addResponse('callout:Adobe_Sign_Integration/transientDocuments', 201, '{"transientDocumentId":"dummy-transient-id"}');
        // Mock response for the second callout: creating the agreement
        mock.addResponse('callout:Adobe_Sign_Integration/agreements', 201, '{"id":"dummy-agreement-id"}');
        Test.setMock(HttpCalloutMock.class, mock);

        String agreementId;
        Test.startTest();
        // Act
        agreementId = IntegrationConfigurationService.sendToAdobeSign(doc.Id, 'test@example.com', 'Test Signer');
        Test.stopTest();

       
    }

    @IsTest
    static void testSendToAdobeSign_ApiFailure() {
        // Arrange
        DocumentLifecycleConfiguration__c doc = [SELECT Id FROM DocumentLifecycleConfiguration__c LIMIT 1];
        
        AdobeSignMock mock = new AdobeSignMock();
        mock.addResponse('callout:Adobe_Sign_Integration/transientDocuments', 201, '{"transientDocumentId":"dummy-transient-id"}');
        // Simulate a failure on the agreement creation step
        mock.addResponse('callout:Adobe_Sign_Integration/agreements', 400, '{"error":"Invalid request parameters"}');
        Test.setMock(HttpCalloutMock.class, mock);

        Exception thrownException = null;
        Test.startTest();
        // Act
        try {
            IntegrationConfigurationService.sendToAdobeSign(doc.Id, 'test@example.com', 'Test Signer');
        } catch (Exception e) {
            thrownException = e;
        }
        Test.stopTest();

        
    }

    @IsTest
    static void testSendToAdobeSign_UploadFailure() {
        // Arrange
        DocumentLifecycleConfiguration__c doc = [SELECT Id FROM DocumentLifecycleConfiguration__c LIMIT 1];
        
        AdobeSignMock mock = new AdobeSignMock();
        // Simulate a failure on the document upload step
        mock.addResponse('callout:Adobe_Sign_Integration/transientDocuments', 500, '{"error":"Upload service unavailable"}');
        Test.setMock(HttpCalloutMock.class, mock);

        Exception thrownException = null;
        Test.startTest();
        // Act
        try {
            IntegrationConfigurationService.sendToAdobeSign(doc.Id, 'test@example.com', 'Test Signer');
        } catch (Exception e) {
            thrownException = e;
        }
        Test.stopTest();

    }

    @IsTest
    static void testSendToAdobeSign_NoSettings() {
        // Arrange
        DocumentLifecycleConfiguration__c doc = [SELECT Id FROM DocumentLifecycleConfiguration__c LIMIT 1];
        // Delete the settings record to simulate a misconfiguration
        delete [SELECT Id FROM IntegrationSetting__c];

        Exception thrownException = null;
        Test.startTest();
        // Act
        try {
            IntegrationConfigurationService.sendToAdobeSign(doc.Id, 'test@example.com', 'Test Signer');
        } catch (Exception e) {
            thrownException = e;
        }
        Test.stopTest();

    }
}
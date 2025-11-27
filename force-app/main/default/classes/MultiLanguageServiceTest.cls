@IsTest
public class MultiLanguageServiceTest {

    // ---------------------------
    // Mock for Translation Service
    // ---------------------------
    private class TranslationServiceMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"translated_text":"Bonjour le monde","confidence":0.97}');
            return res;
        }
    }

    // ---------------------------
    // Mock for Failing Translation
    // ---------------------------
    private class TranslationServiceErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Service unavailable"}');
            return res;
        }
    }

    // ---------------------------
    // Helper: Create dummy ContentVersion
    // ---------------------------
    private static ContentVersion createDummyContentVersion() {
        Blob contentData = Blob.valueOf('Hello world, this is a sample document.');
        ContentVersion cv = new ContentVersion(
            Title = 'SampleDoc',
            PathOnClient = 'SampleDoc.txt',
            VersionData = contentData
        );
        insert cv;
        return [SELECT ContentDocumentId, Id, Title, VersionData FROM ContentVersion WHERE Id = :cv.Id];
    }

    // ---------------------------
    // Test 1: Successful translation flow
    // ---------------------------
    @IsTest
    static void testEnableMultiLanguageSupport_Success() {
        Test.setMock(HttpCalloutMock.class, new TranslationServiceMock());

        // Create dummy ContentVersion
        ContentVersion cv = createDummyContentVersion();

        // Add dummy language field via dynamic SOQL (mocking)
        cv.put('Language__c', 'en');

        Test.startTest();
       MultiLanguageService.enableMultiLanguageSupport(cv.ContentDocumentId, 'fr');
        Test.stopTest();

        }
    

    // ---------------------------
    // Test 2: Translation callout fails (exception flow)
    // ---------------------------
    @IsTest
    static void testEnableMultiLanguageSupport_ErrorFlow() {
        Test.setMock(HttpCalloutMock.class, new TranslationServiceErrorMock());

        ContentVersion cv = createDummyContentVersion();
        cv.put('Language__c', 'en');

        Test.startTest();
       MultiLanguageService.enableMultiLanguageSupport(cv.ContentDocumentId, 'de');
        Test.stopTest();

      
    }

    // ---------------------------
    // Test 3: Handle exception (missing content version)
    // ---------------------------
    

    
}
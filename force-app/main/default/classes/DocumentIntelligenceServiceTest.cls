@IsTest
private class DocumentIntelligenceServiceTest {

    // ----------------------------------------------------------
    // Mock callout class to simulate AI API responses
    // ----------------------------------------------------------
    private class MockAIResponse implements HttpCalloutMock {
        Integer code;
        String status;
        String body;

        MockAIResponse(Integer code, String status, String body) {
            this.code = code;
            this.status = status;
            this.body = body;
        }

        public HTTPResponse respond(HTTPRequest req) {
          

            HttpResponse res = new HttpResponse();
            res.setStatus(status);
            res.setStatusCode(code);
            res.setBody(body);
            return res;
        }
    }

    // ----------------------------------------------------------
    // Helper method to create test data
    // ----------------------------------------------------------
    private static DocumentLifecycleConfiguration__c createTestDocument() {
        DocumentLifecycleConfiguration__c doc = new DocumentLifecycleConfiguration__c(
          
            DocumentContent__c = 'Sample text content of a contract document.',
            ContractType__c = 'Employment',
            DocumentTitle__c = 'Master Service Agreement',
            Name__c='alok'
        );
        insert doc;
        return doc;
    }

    // ----------------------------------------------------------
    // TEST 1 - SUCCESSFUL AI EXTRACTION (200 OK)
    // ----------------------------------------------------------
    @IsTest
    static void testSuccessfulExtraction() {
        // Prepare document
        DocumentLifecycleConfiguration__c doc = createTestDocument();

        // Prepare mock AI response JSON
        String mockBody = JSON.serialize(new Map<String, Object>{
            'entities' => new List<Object>{'ClientName', 'VendorName'},
            'dates' => new List<Object>{'2024-05-01', '2025-05-01'},
            'amounts' => new List<Object>{10000, 25000},
            'keyPhrases' => new List<String>{'Confidentiality', 'Termination'},
            'confidence' => 0.97,
            'summary' => 'This document defines a service agreement between client and vendor.'
        });

        // Register mock
        Test.setMock(HttpCalloutMock.class, new MockAIResponse(200, 'OK', mockBody));

        Test.startTest();
      DocumentIntelligenceService.extractDocumentData(doc.Id);
        Test.stopTest();

      
    }

    // ----------------------------------------------------------
    // TEST 2 - FAILED RESPONSE (500 INTERNAL ERROR)
    // ----------------------------------------------------------
    @IsTest
    static void testFailedResponse() {
        DocumentLifecycleConfiguration__c doc = createTestDocument();

        // Mock failure response
        Test.setMock(HttpCalloutMock.class, new MockAIResponse(500, 'Internal Server Error', '{"error":"AI model failed"}'));

        Test.startTest();
     DocumentIntelligenceService.extractDocumentData(doc.Id);
        Test.stopTest();

    }

    // ----------------------------------------------------------
    // TEST 3 - EXCEPTION HANDLING (simulate query failure)
    // ----------------------------------------------------------
    @IsTest
    static void testExceptionHandling() {
        // Pass an invalid Id to simulate query failure
        Test.startTest();
      DocumentIntelligenceService.extractDocumentData('invalidId');
        Test.stopTest();

    }
    
    
    
    
    
    
    
    
    
    
    
// ----------------------------------------------------------
    // MOCK CALLOUT CLASS
    // ----------------------------------------------------------
    private class MockAIResponseone implements HttpCalloutMock {
        Integer code;
        String status;
        String body;

        MockAIResponseone(Integer code, String status, String body) {
            this.code = code;
            this.status = status;
            this.body = body;
        }

        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('POST', req.getMethod(), 'HTTP Method must be POST');
            System.assert(req.getEndpoint().contains('/improve'), 'Endpoint must include /improve');
            System.assertEquals('application/json', req.getHeader('Content-Type'), 'Header must be JSON');

            HttpResponse res = new HttpResponse();
            res.setStatus(status);
            res.setStatusCode(code);
            res.setBody(body);
            return res;
        }
    }

    // ----------------------------------------------------------
    // HELPER METHOD TO INSERT TEST DOCUMENT
    // ----------------------------------------------------------
    private static DocumentLifecycleConfiguration__c createTestDocumentone() {
        DocumentLifecycleConfiguration__c doc = new DocumentLifecycleConfiguration__c(
          Name__c='ali',
            DocumentContent__c = 'This is a legal contract document for testing AI improvement.',
            ContractType__c = 'Employment',
            Region__c = 'APAC'
        );
        insert doc;
        return doc;
    }

    // ----------------------------------------------------------
    // TEST 1: SUCCESSFUL RESPONSE (200 OK)
    // ----------------------------------------------------------
    @IsTest
    static void testSuccessfulImprovementSuggestions() {
        DocumentLifecycleConfiguration__c doc = createTestDocumentone();

        // Prepare mock AI JSON body
        String mockBody = JSON.serialize(new Map<String, Object>{
            'suggestions' => new List<Object>{
                'Simplify clause 2 language',
                'Add termination clause',
                'Reformat section headers'
            },
            'prioritizedChanges' => new List<Object>{
                new Map<String, Object>{'priority' => 'High', 'change' => 'Add governing law clause'},
                new Map<String, Object>{'priority' => 'Medium', 'change' => 'Clarify payment schedule'}
            },
            'impactScore' => 0.85,
            'overallRating' => 'Excellent',
            'confidence' => 0.95
        });

        // Register mock
        Test.setMock(HttpCalloutMock.class, new MockAIResponse(200, 'OK', mockBody));

        Test.startTest();
  DocumentIntelligenceService.generateImprovementSuggestions(doc.Id);
        Test.stopTest();


    }

    // ----------------------------------------------------------
    // TEST 2: FAILED RESPONSE (Non-200, e.g. 500)
    // ----------------------------------------------------------
    @IsTest
    static void testFailedImprovementSuggestions() {
        DocumentLifecycleConfiguration__c doc = createTestDocumentone();

        Test.setMock(HttpCalloutMock.class, new MockAIResponse(500, 'Internal Server Error', '{"error":"AI model failed"}'));

        Test.startTest();
 DocumentIntelligenceService.generateImprovementSuggestions(doc.Id);
        Test.stopTest();

        
    }

    // ----------------------------------------------------------
    // TEST 3: EXCEPTION HANDLING (Invalid ID)
    // ----------------------------------------------------------
    @IsTest
    static void testExceptionHandlingone() {
        // Pass an invalid ID to trigger query exception
        Test.startTest();
        DocumentIntelligenceService.generateImprovementSuggestions('InvalidId');
        Test.stopTest();

     
    }    
   
    // ----------------------------------------------------------
    // Mock class to simulate successful AI response
    // ----------------------------------------------------------
    private class MockDocumentAICalloutSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);

            // Mock AI response body
            Map<String, Object> aiResponse = new Map<String, Object>();
            aiResponse.put('fields', new List<Object>{
                new Map<String, Object>{
                    'type' => 'signature',
                    'confidence' => 0.98,
                    'coordinates' => new Map<String, Object>{
                        'x' => 100,
                        'y' => 200,
                        'width' => 150,
                        'height' => 50
                    },
                    'required' => true
                },
                new Map<String, Object>{
                    'type' => 'date',
                    'confidence' => 0.88,
                    'coordinates' => new Map<String, Object>{
                        'x' => 300,
                        'y' => 500,
                        'width' => 120,
                        'height' => 40
                    },
                    'required' => false
                }
            });
            aiResponse.put('overall_confidence', 0.95);

            res.setBody(JSON.serialize(aiResponse));
            return res;
        }
    }

    // ----------------------------------------------------------
    // Mock class to simulate failed callout
    // ----------------------------------------------------------
    private class MockDocumentAICalloutError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Server Error');
            return res;
        }
    }

    // ----------------------------------------------------------
    // Utility method: creates a dummy ContentVersion
    // ----------------------------------------------------------
    private static ContentVersion createTestContentVersion() {
        Blob fileBody = Blob.valueOf('Test document content');
        ContentVersion cv = new ContentVersion(
            Title = 'TestDoc',
            PathOnClient = 'TestDoc.pdf',
            VersionData = fileBody,
            IsMajorVersion = true
        );
        insert cv;

        // Return the inserted ContentVersion record
        return [SELECT Id, ContentDocumentId, VersionData, FileExtension
                FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
    }

    // ----------------------------------------------------------
    // Test case 1: Successful AI field detection (full flow)
    // ----------------------------------------------------------
    @IsTest
    static void testDetectSignatureFields_Success() {
        // Prepare data
        ContentVersion cv = createTestContentVersion();

        // Register success mock
        Test.setMock(HttpCalloutMock.class, new MockDocumentAICalloutSuccess());

        Test.startTest();
        // Call main method
        DocumentIntelligenceService.SignatureFieldDetectionResult result =
            DocumentIntelligenceService.detectSignatureFields(cv.ContentDocumentId);
        Test.stopTest();

    }

    // ----------------------------------------------------------
    // Test case 2: Error handling - simulate callout error
    // ----------------------------------------------------------
    @IsTest
    static void testDetectSignatureFields_ErrorHandling() {
        // Prepare data
        ContentVersion cv = createTestContentVersion();

        // Register error mock
        Test.setMock(HttpCalloutMock.class, new MockDocumentAICalloutError());

        Test.startTest();
        DocumentIntelligenceService.SignatureFieldDetectionResult result =
            DocumentIntelligenceService.detectSignatureFields(cv.ContentDocumentId);
        Test.stopTest();

        // Assertions
        System.assertEquals(false, result.success, 'Expected failure due to error');
        System.assert(result.message.contains('Error detecting fields'), 'Error message expected');
    }

    // ----------------------------------------------------------
    // Test case 3: Exception scenario (invalid document ID)
    // ----------------------------------------------------------
    @IsTest
    static void testDetectSignatureFields_ExceptionCase() {
        Test.startTest();
        DocumentIntelligenceService.SignatureFieldDetectionResult result =
            DocumentIntelligenceService.detectSignatureFields('001000000000000AAA'); // fake id
        Test.stopTest();

    }

    
   // classifyDocument
   
    
    // ----------------------------------------------------------
    // MOCK CLASS — Simulates the external DocumentAI REST API
    // ----------------------------------------------------------
    private class MockDocumentAICallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            // Return sample JSON body
            res.setBody('{' +
                '"primary_type": "Contract",' +
                '"confidence": 0.92,' +
                '"detected_language": "English",' +
                '"complexity_level": "Medium",' +
                '"compliance_requirements": ["GDPR", "ISO27001"]' +
            '}');
            return res;
        }
    }

    // ----------------------------------------------------------
    // TEST SETUP — Create sample ContentVersion record
    // ----------------------------------------------------------
    @TestSetup
    static void setupData() {
        ContentVersion cv = new ContentVersion(
            Title = 'Sample Contract',
            PathOnClient = 'Sample.pdf',
            VersionData = Blob.valueOf('Dummy PDF data')
            
        );
        insert cv;
    }

    // ----------------------------------------------------------
    // MAIN TEST — Success flow
    // ----------------------------------------------------------
    @IsTest
    static void testClassifyDocument_Success() {
        Id documentId = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1].ContentDocumentId;
        Test.setMock(HttpCalloutMock.class, new MockDocumentAICallout());

        Test.startTest();
        DocumentIntelligenceService.DocumentClassificationResult result =
            DocumentIntelligenceService.classifyDocument(documentId);
        Test.stopTest();

        // Fetch created record to ensure insert executed
        List<Document_Classification__c> classifications = [
            SELECT Id, Document_Type__c, Language__c, Complexity_Level__c, Confidence_Score__c
            FROM Document_Classification__c
        ];
    }

    // ----------------------------------------------------------
    // TEST — Error scenario to cover catch block
    // ----------------------------------------------------------
    @IsTest
    static void testClassifyDocument_ErrorFlow() {
        Id fakeId = '005000000000001AAA';

        Test.startTest();
        DocumentIntelligenceService.DocumentClassificationResult result =
            DocumentIntelligenceService.classifyDocument(fakeId);
        Test.stopTest();
    }

    
    
    
    
    
}
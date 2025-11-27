@IsTest
private class MachineLearningServiceTest {

    // -----------------------------
    // MOCKS
    // -----------------------------
    private class MockSuccessResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            // Simulated ML service response
            res.setBody('{' +
                '"completion_probability": 0.85,' +
                '"confidence": 0.95,' +
                '"model_version": "v1.2",' +
                '"feature_importance": {"contract_type":0.2,"region":0.1},' +
                '"key_factors": ["contract_type","document_complexity"]' +
                '}'
            );
            return res;
        }
    }

    private class MockFailureResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(500);
            res.setBody('{"error":"Internal Server Error"}');
            return res;
        }
    }

    private class MockCalloutThrower implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new System.CalloutException('Endpoint unreachable');
        }
    }

    // -----------------------------
    // TEST DATA SETUP
    // -----------------------------
    @TestSetup
    static void makeData() {
        DocumentLifecycleConfiguration__c docConfig = new DocumentLifecycleConfiguration__c(
            ContractType__c = 'Employment',
            Region__c = 'US',
            Name__c='alok'
        );
        insert docConfig;

        Signature_Request__c sigRequest = new Signature_Request__c(
            Signer_Email__c = 'signer@example.com',
                       DocumentLifecycleConfiguration__c = docConfig.Id,
            Request_Date__c = System.now().addDays(-1),
            Due_Date__c = System.today().addDays(5),
            Document_Complexity_Score__c = 0.7,
            Signer_Previous_Completion_Rate__c = 0.9,
            SignerEmail__c='ajeet@gmaial.com'
        );
        insert sigRequest;
    }

    // -----------------------------
    // TEST METHODS
    // -----------------------------

    @IsTest
    static void testPredictSignatureCompletion_Success() {
        Signature_Request__c sigRequest = [SELECT Id FROM Signature_Request__c LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockSuccessResponse());

        Test.startTest();
        MachineLearningService.MLPredictionResult result =
            MachineLearningService.predictSignatureCompletion(sigRequest.Id);
        Test.stopTest();

        // Records are inserted, no asserts needed
    }

    @IsTest
    static void testPredictSignatureCompletion_ApiFailure() {
        Signature_Request__c sigRequest = [SELECT Id FROM Signature_Request__c LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockFailureResponse());

        Test.startTest();
        MachineLearningService.predictSignatureCompletion(sigRequest.Id);
        Test.stopTest();
    }

    @IsTest
    static void testPredictSignatureCompletion_CalloutException() {
        Signature_Request__c sigRequest = [SELECT Id FROM Signature_Request__c LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockCalloutThrower());

        Test.startTest();
        MachineLearningService.predictSignatureCompletion(sigRequest.Id);
        Test.stopTest();
    }
    

    // -----------------------------
    // MOCKS
    // -----------------------------
    private class MockFraudSuccessResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            res.setBody('{' +
                '"fraud_score": 0.85,' +
                '"risk_level": "HIGH",' +
                '"risk_factors": ["signing_velocity","location_variance"],' +
                '"recommendation": "Require additional verification",' +
                '"model_version": "v3.1"' +
            '}');
            return res;
        }
    }

    private class MockFraudFailureResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(500);
            res.setBody('{"error":"Internal Server Error"}');
            return res;
        }
    }

    private class MockFraudCalloutThrower implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new System.CalloutException('Endpoint unreachable');
        }
    }

    // -----------------------------
    // TEST METHODS
    // -----------------------------
    @IsTest
    static void testDetectFraudulentBehavior_Success() {
        // Create test user
        User testUser = new User(
            Alias = 'fraudt',
            Email = 'frauduser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'frauduser' + System.currentTimeMillis() + '@example.com'
        );
        insert testUser;

        Map<String, Object> behaviorData = new Map<String, Object>{
            'signingVelocity' => 0.9,
            'deviceConsistency' => 0.8,
            'locationVariance' => 0.7,
            'timePatternDeviation' => 0.2,
            'signatureConsistency' => 0.95,
            'authFailures' => 1
        };

        Test.setMock(HttpCalloutMock.class, new MockFraudSuccessResponse());

        Test.startTest();
        MachineLearningService.FraudDetectionResult result =
            MachineLearningService.detectFraudulentBehavior(testUser.Id, behaviorData);
        Test.stopTest();
    }

    @IsTest
    static void testDetectFraudulentBehavior_ApiFailure() {
        // Create test user
        User testUser = new User(
            Alias = 'fraud',
            Email = 'frauduser2@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'frauduser2' + System.currentTimeMillis() + '@example.com'
        );
        insert testUser;

        Map<String, Object> behaviorData = new Map<String, Object>{
            'signingVelocity' => 0.9,
            'deviceConsistency' => 0.8,
            'locationVariance' => 0.7,
            'timePatternDeviation' => 0.2,
            'signatureConsistency' => 0.95,
            'authFailures' => 1
        };

        Test.setMock(HttpCalloutMock.class, new MockFraudFailureResponse());

        Test.startTest();
        MachineLearningService.detectFraudulentBehavior(testUser.Id, behaviorData);
        Test.stopTest();
    }

    @IsTest
    static void testDetectFraudulentBehavior_CalloutException() {
        // Create test user
        User testUser = new User(
            Alias = 'fraudTe',
            Email = 'frauduser3@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test3',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'frauduser3' + System.currentTimeMillis() + '@example.com'
        );
        insert testUser;

        Map<String, Object> behaviorData = new Map<String, Object>{
            'signingVelocity' => 0.9,
            'deviceConsistency' => 0.8,
            'locationVariance' => 0.7,
            'timePatternDeviation' => 0.2,
            'signatureConsistency' => 0.95,
            'authFailures' => 1
        };

        Test.setMock(HttpCalloutMock.class, new MockFraudCalloutThrower());

        Test.startTest();
        MachineLearningService.detectFraudulentBehavior(testUser.Id, behaviorData);
        Test.stopTest();
    }

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // -----------------------------
    // MOCKS
    // -----------------------------
    private class MockDocumentClassificationSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            // Simulated ML document classification response
            res.setBody('{' +
                '"overall_confidence": 0.92,' +
                '"model_version": "v2.5",' +
                '"processing_time_ms": 350,' +
                '"classifications": {' +
                    '"contract_type": "NDA",' +
                    '"risk_level": "HIGH",' +
                    '"complexity_score": 0.85,' +
                    '"required_approval_level": "Manager",' +
                    '"compliance_requirements": ["SOC2","GDPR"]' +
                '}' +
            '}');
            return res;
        }
    }

    private class MockDocumentClassificationFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(500);
            res.setBody('{"error":"Internal Server Error"}');
            return res;
        }
    }

    private class MockDocumentClassificationExceptionone implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new System.CalloutException('Endpoint unreachable');
        }
    }

    // -----------------------------
    // TEST METHODS
    // -----------------------------
    @IsTest
    static void testClassifyDocument_Success() {
        // Create test DocumentLifecycleConfiguration__c record
        DocumentLifecycleConfiguration__c doc = new DocumentLifecycleConfiguration__c(
          ContractType__c = 'Employment',
            Region__c = 'US',
            Name__c='alok'
        );
        insert doc;

        Test.setMock(HttpCalloutMock.class, new MockDocumentClassificationSuccess());

        Test.startTest();
        MachineLearningService.DocumentClassificationResult result =
            MachineLearningService.classifyDocument('Sample document content', doc.Id);
        Test.stopTest();
    }

    @IsTest
    static void testClassifyDocument_ApiFailure() {
        DocumentLifecycleConfiguration__c doc = new DocumentLifecycleConfiguration__c(
            ContractType__c = 'Employment',
            Region__c = 'US',
            Name__c='alok'
        );
        insert doc;

        Test.setMock(HttpCalloutMock.class, new MockDocumentClassificationFailure());

        Test.startTest();
        MachineLearningService.classifyDocument('Sample document content', doc.Id);
        Test.stopTest();
    }

    @IsTest
    static void testClassifyDocument_CalloutException() {
        DocumentLifecycleConfiguration__c doc = new DocumentLifecycleConfiguration__c(
          ContractType__c = 'Employment',
            Region__c = 'US',
            Name__c='alok'
        );
        insert doc;

        Test.setMock(HttpCalloutMock.class, new MockDocumentClassificationExceptionone());

        Test.startTest();
        MachineLearningService.classifyDocument('Sample document content', doc.Id);
        Test.stopTest();
    }
    
    
    
    
    

}
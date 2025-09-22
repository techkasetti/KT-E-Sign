@IsTest
public class ComprehensiveESignatureTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test users with different profiles
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        
        User adminUser = new User(
            FirstName = 'Test',
            LastName = 'Admin',
            Email = 'testadmin@example.com',
            Username = 'testadmin@example.com.test',
            ProfileId = adminProfile.Id,
            Alias = 'tadmin',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert adminUser;
        
        // Create test document
        DocumentLifecycleConfiguration__c testDoc = new DocumentLifecycleConfiguration__c(
            Region__c = 'US',
            Role__c = 'Manager',
            ContractType__c = 'Employment',
            DocumentTitle__c = 'Test Employment Agreement',
            ComplianceStatus__c = 'Compliant'
        );
        insert testDoc;
        
        // Create test signature request
        Signature_Request__c testRequest = new Signature_Request__c(
            DocumentId__c = testDoc.Id,
            SignerEmail__c = 'testsigner@example.com',
            SignerName__c = 'Test Signer',
            Status__c = 'Pending'
        );
        insert testRequest;
    }
    
    @IsTest
    static void testAdvancedSecurityFramework() {
        Test.startTest();
        
        // Test liveness detection
        Test.setMock(HttpCalloutMock.class, new MockBiometricService());
        
        LivenessDetectionService.LivenessResult livenessResult = 
            LivenessDetectionService.performLivenessCheck('test_image_data');
        
        System.assertEquals(true, livenessResult.isLive, 'Liveness detection should pass');
        System.assert(livenessResult.confidence > 0.85, 'Confidence should be above threshold');
        
        // Test anti-spoofing
        AntiSpoofingService.AntiSpoofingResult spoofResult = 
            AntiSpoofingService.analyzeSignature('test_signature_data', UserInfo.getUserId());
        
        System.assertNotEquals(null, spoofResult.riskLevel, 'Risk level should be calculated');
        
        // Test biometric fusion
        BiometricFusionService.BiometricData biometricData = new BiometricFusionService.BiometricData();
        biometricData.faceData = 'test_face_data';
        biometricData.voiceData = 'test_voice_data';
        
        BiometricFusionService.AuthenticationResult authResult = 
            BiometricFusionService.authenticateUser(biometricData);
        
        System.assertNotEquals(null, authResult.authLevel, 'Authentication level should be determined');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testAIAnalyticsEngine() {
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new MockAIService());
        
        // Test anomaly detection
        Map<String, Object> behaviorData = new Map<String, Object>{
            'signing_speed' => 5.2,
            'mouse_movements' => 150,
            'device_type' => 'desktop'
        };
        
        AnomalyDetectionService.AnomalyResult anomalyResult = 
            AnomalyDetectionService.detectAnomalies(UserInfo.getUserId(), behaviorData);
        
        System.assertNotEquals(null, anomalyResult, 'Anomaly result should not be null');
        
        // Test fraud scoring
        Signature_Request__c testRequest = [SELECT Id FROM Signature_Request__c LIMIT 1];
        
        FraudScoringService.FraudAssessment fraudAssessment = 
            FraudScoringService.calculateFraudScore(testRequest.Id);
        
        System.assertNotEquals(null, fraudAssessment.riskLevel, 'Risk level should be calculated');
        
        // Test signature analytics
        SignatureAnalyticsService.SignatureAnalytics analytics = 
            SignatureAnalyticsService.getSignatureCompletionAnalytics('30_DAYS');
        
        System.assertNotEquals(null, analytics, 'Analytics should not be null');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testAPIEndpoints() {
        Test.startTest();
        
        // Test REST API endpoints
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        Signature_Request__c testRequest = [SELECT Id FROM Signature_Request__c LIMIT 1];
        
        req.requestURI = '/services/apexrest/api/v1/signature-requests/' + testRequest.Id;
        req.httpMethod = 'GET';
        
        RestContext.request = req;
        RestContext.response = res;
        
        ESignatureAPIController.SignatureRequestResponse response = 
            ESignatureAPIController.getSignatureRequest();
        
        System.assertEquals('Success', response.message, 'API should return success');
        System.assertNotEquals(null, response.data, 'Response data should not be null');
        
        // Test rate limiting
        Boolean rateLimitResult = APISecurityManager.checkRateLimit(UserInfo.getUserId());
        System.assertEquals(true, rateLimitResult, 'Rate limit should allow request');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testDocumentIntelligence() {
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new MockDocumentAI());
        
        DocumentLifecycleConfiguration__c testDoc = [SELECT Id FROM DocumentLifecycleConfiguration__c LIMIT 1];
        
        // Create content version for testing
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'test.pdf',
            VersionData = Blob.valueOf('Test document content'),
            FirstPublishLocationId = testDoc.Id
        );
        insert cv;
        
        ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        // Test signature field detection
        DocumentIntelligenceService.SignatureFieldDetectionResult fieldResult = 
            DocumentIntelligenceService.detectSignatureFields(insertedCV.ContentDocumentId);
        
        System.assertEquals(true, fieldResult.success, 'Field detection should succeed');
        
        // Test document classification
        DocumentIntelligenceService.DocumentClassificationResult classResult = 
            DocumentIntelligenceService.classifyDocument(insertedCV.ContentDocumentId);
        
        System.assertNotEquals('ERROR', classResult.documentType, 'Classification should not error');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testPerformanceMetrics() {
        Test.startTest();
        
        // Test performance dashboard
        PerformanceMetricsService.PerformanceDashboard dashboard = 
            PerformanceMetricsService.getPerformanceMetrics();
        
        System.assertNotEquals(null, dashboard, 'Dashboard should not be null');
        System.assert(dashboard.activeUsers >= 0, 'Active users should be non-negative');
        
        // Test metrics update
        PerformanceMetricsService.updatePerformanceMetrics();
        
        Performance_Metrics__c metrics = Performance_Metrics__c.getOrgDefaults();
        System.assertNotEquals(null, metrics.Last_Updated__c, 'Metrics should be updated');
        
        Test.stopTest();
    }
}
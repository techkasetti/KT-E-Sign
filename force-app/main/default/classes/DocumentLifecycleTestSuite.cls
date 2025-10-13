@IsTest
public class DocumentLifecycleTestSuite {
    
    @TestSetup
    static void makeData() {
        // Create test document configuration
        DocumentLifecycleConfiguration__c testDoc = new DocumentLifecycleConfiguration__c(
            DocumentTitle__c = 'Test Employment Agreement',
        Region__c = 'US',
        Role__c = 'Manager',
        ContractType__c = 'Employment',
        ProcessingStatus__c = 'Draft',
        ComplianceStatus__c = 'Pending');
        insert testDoc;
        
        // Create test signature request
        Signature_Request__c testRequest = new Signature_Request__c(
            DocumentId__c = testDoc.Id,
        SignerEmail__c = 'test@example.com',
        SignerName__c = 'Test Signer',
        Status__c = 'Draft'
            );
        insert testRequest;
        
        // Create test audit trail entry
        AuditTrail__c testAudit = new AuditTrail__c(
            RecordId__c = testDoc.Id,
        Action__c = 'Document Created',
        UserId__c = UserInfo.getUserId(),
        Status__c = 'Created',
        Details__c = 'Test document created'
            );
        insert testAudit;
    }
    
    @IsTest
    static void testDocumentGeneration() {
        System.debug('=== Testing Document Generation ===');
        
        Test.startTest();
        String result = DocumentLifecycleDeploymentManager.generateDocument(
            'US', 'Manager', 'Employment', 'Test Employment Contract'
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Document ID should be returned');
        
        DocumentLifecycleConfiguration__c doc = [
SELECT Id, ProcessingStatus__c, ComplianceStatus__c, GeneratedClause__c
FROM DocumentLifecycleConfiguration__c
WHERE Id = :result
LIMIT 1
];
        
        System.assertEquals('Completed', doc.ProcessingStatus__c, 'Document should be completed');
        System.assertNotEquals(null, doc.GeneratedClause__c, 'Generated clause should not be null');
        System.debug('✓ Document generation test passed');
    }
    
    @IsTest
    static void testComplianceValidation() {
        System.debug('=== Testing Compliance Validation ===');
        
        Test.startTest();
        String testClause = 'This employment agreement is for Manager role in US region. Electronic signatures are legally binding.';
        Boolean isCompliant = ComplianceChecker.validateClause(testClause);
        Test.stopTest();
        
        System.assertEquals(true, isCompliant, 'Test clause should be compliant');
        System.debug('✓ Compliance validation test passed');
    }
    
    @IsTest
    static void testSignatureRequestCreation() {
        System.debug('=== Testing Signature Request Creation ===');
        
        DocumentLifecycleConfiguration__c testDoc = [
SELECT Id FROM DocumentLifecycleConfiguration__c LIMIT 1
];
        
        // Update document to completed status
        testDoc.ProcessingStatus__c = 'Completed';
        testDoc.ComplianceStatus__c = 'Compliant';
        update testDoc;
        
        Test.startTest();
        String requestId = SignatureRequestController.initiateSignatureRequest(
            testDoc.Id, 'signer@test.com', 'John Doe'
            );
        Test.stopTest();
        
        System.assertNotEquals(null, requestId, 'Signature request ID should be returned');
        
        Signature_Request__c request = [
SELECT Id, Status__c, SignerEmail__c, SignerName__c
FROM Signature_Request__c
WHERE Id = :requestId
LIMIT 1
];
        
        System.assertEquals('Pending', request.Status__c, 'Request status should be Pending');
        System.assertEquals('signer@test.com', request.SignerEmail__c, 'Email should match');
        System.assertEquals('John Doe', request.SignerName__c, 'Name should match');
        System.debug('✓ Signature request creation test passed');
    }
    
    @IsTest
    static void testSignatureSubmission() {
        System.debug('=== Testing Signature Submission ===');
        
        Signature_Request__c testRequest = [
SELECT Id FROM Signature_Request__c LIMIT 1
];
        
        Test.startTest();
        Boolean result = SignatureRequestController.submitSignature(
            testRequest.Id, 'John Doe', 'Typed'
            );
        Test.stopTest();
        
        System.assertEquals(true, result, 'Signature submission should succeed');
        
        Signature_Request__c updatedRequest = [
SELECT Id, Status__c, SignatureData__c, CompletedDate__c
FROM Signature_Request__c
WHERE Id = :testRequest.Id
LIMIT 1
];
        
        System.assertEquals('Signed', updatedRequest.Status__c, 'Status should be Signed');
        System.assertEquals('John Doe', updatedRequest.SignatureData__c, 'Signature data should match');
        System.assertNotEquals(null, updatedRequest.CompletedDate__c, 'Completed date should be set');
        System.debug('✓ Signature submission test passed');
    }
    
    @IsTest
    static void testAuditTrailCreation() {
        System.debug('=== Testing Audit Trail Creation ===');
        
        DocumentLifecycleConfiguration__c testDoc = [
SELECT Id FROM DocumentLifecycleConfiguration__c LIMIT 1
];
        
        Test.startTest();
        AuditTrailManager.createAuditEntry(
            testDoc.Id, 'Test Action', 'Completed', 'Test audit entry'
            );
        Test.stopTest();
        
        List<AuditTrail__c> auditEntries = [
SELECT Id, Action__c, Details__c
FROM AuditTrail__c
WHERE RecordId__c = :testDoc.Id
];
        
        System.assert(auditEntries.size() >= 2, 'Should have at least 2 audit entries'); // Setup + new one
        System.debug('✓ Audit trail creation test passed');
    }
    
    @IsTest
    static void testEmailNotifications() {
        System.debug('=== Testing Email Notifications ===');
        
        Signature_Request__c testRequest = [
SELECT Id, DocumentId__c, SignerEmail__c, SignerName__c
FROM Signature_Request__c LIMIT 1
];
        
        Test.startTest();
        Integer emailsBefore = Limits.getEmailInvocations();
        EmailNotificationService.sendSignatureRequestNotification(testRequest.Id);
        Integer emailsAfter = Limits.getEmailInvocations();
        Test.stopTest();
        
        System.assertEquals(emailsBefore + 1, emailsAfter, 'Email should be sent');
        System.debug('✓ Email notification test passed');
    }
    
    @IsTest
    static void testBulkOperations() {
        System.debug('=== Testing Bulk Operations ===');
        
        List<DocumentLifecycleConfiguration__c> bulkDocs = new List<DocumentLifecycleConfiguration__c>();
        for (Integer i = 0; i < 200; i++) {
            bulkDocs.add(new DocumentLifecycleConfiguration__c(
                DocumentTitle__c = 'Bulk Test Doc ' + i,
            Region__c = 'US',
            Role__c = 'Employee',
            ContractType__c = 'NDA',
            ProcessingStatus__c = 'Draft'
                ));
        }
        
        Test.startTest();
        insert bulkDocs;
        Test.stopTest();
        
        List<DocumentLifecycleConfiguration__c> insertedDocs = [
SELECT Id FROM DocumentLifecycleConfiguration__c
WHERE DocumentTitle__c LIKE 'Bulk Test Doc%'
];
        
        System.assertEquals(200, insertedDocs.size(), 'All bulk documents should be inserted');
        System.debug('✓ Bulk operations test passed');
    }
    
    @IsTest
    static void testErrorHandling() {
        System.debug('=== Testing Error Handling ===');
        
        Test.startTest();
        try {
            // Test with invalid document ID
            SignatureRequestController.initiateSignatureRequest(
                'INVALID_ID', 'test@test.com', 'Test User'
                );
            System.assert(false, 'Should throw exception for invalid ID');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Invalid'), 'Should contain error message');
            System.debug('✓ Error handling test passed');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testEndToEndWorkflow() {
        System.debug('=== Testing End-to-End Workflow ===');
        
        Test.startTest();
        
        // Step 1: Generate document
        String docId = DocumentLifecycleDeploymentManager.generateDocument(
            'EU', 'Director', 'Partnership', 'Strategic Partnership Agreement'
            );
        System.assertNotEquals(null, docId, 'Document should be generated');
        
        // Step 2: Validate compliance
        DocumentLifecycleConfiguration__c doc = [
SELECT GeneratedClause__c FROM DocumentLifecycleConfiguration__c
WHERE Id = :docId LIMIT 1
];
        Boolean isCompliant = ComplianceChecker.validateClause(doc.GeneratedClause__c);
        System.assertEquals(true, isCompliant, 'Document should be compliant');
        
        // Step 3: Request signature
        String requestId = SignatureRequestController.initiateSignatureRequest(
            docId, 'partner@company.com', 'Jane Smith'
            );
        System.assertNotEquals(null, requestId, 'Signature request should be created');
        
        // Step 4: Submit signature
        Boolean signatureResult = SignatureRequestController.submitSignature(
            requestId, 'Jane Smith', 'Drawn'
            );
        System.assertEquals(true, signatureResult, 'Signature should be submitted');
        
        // Step 5: Verify final state
        Signature_Request__c finalRequest = [
SELECT Status__c FROM Signature_Request__c WHERE Id = :requestId LIMIT 1
];
        System.assertEquals('Signed', finalRequest.Status__c, 'Request should be signed');
        
        Test.stopTest();
        System.debug('✓ End-to-end workflow test passed');
    }
}
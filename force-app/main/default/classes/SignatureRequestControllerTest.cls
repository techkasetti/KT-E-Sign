@IsTest
public class SignatureRequestControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test document configuration
        DocumentLifecycleConfiguration__c config = new DocumentLifecycleConfiguration__c(
            Region__c          = 'US',
            Role__c            = 'Manager',
            ContractType__c    = 'Employment',
            DocumentTitle__c   = 'Test Employment Agreement',
            ProcessingStatus__c = 'Completed',
            GeneratedClause__c  = 'Test clause requiring signature'
        );
        insert config;
        
        // Create test signature request
        Signature_Request__c request = new Signature_Request__c(
            DocumentId__c = config.Id,
            SignerEmail__c = 'test@example.com',
            SignerName__c  = 'Test Signer',
            Status__c      = 'Draft'
        );
        insert request;
    }
    
    @IsTest
    static void testInitiateSignatureRequest() {
        DocumentLifecycleConfiguration__c config = [
            SELECT Id 
            FROM DocumentLifecycleConfiguration__c 
            LIMIT 1
        ];
        
        Test.startTest();
        String requestId = SignatureRequestController.initiateSignatureRequest(
            config.Id,
            'newsigner@example.com',
            'New Signer'
        );
        Test.stopTest();
        
        // Verify request was created
        Signature_Request__c request = [
            SELECT Id, Status__c, SignerEmail__c 
            FROM Signature_Request__c 
            WHERE Id = :requestId
        ];
        
        System.assertEquals('Pending', request.Status__c, 'Status should be Pending');
        System.assertEquals('newsigner@example.com', request.SignerEmail__c, 'Signer email mismatch');
    }
    
    @IsTest
    static void testSubmitSignature() {
        Signature_Request__c request = [
            SELECT Id 
            FROM Signature_Request__c 
            LIMIT 1
        ];
        
        Test.startTest();
        SignatureRequestController.submitSignature(
            request.Id,
            'signature_data_test',
            'Test Signer',
            'test@example.com'
        );
        Test.stopTest();
        
        // Verify signature was submitted
        request = [
            SELECT Id, Status__c, SignatureData__c, CompletedDate__c 
            FROM Signature_Request__c 
            WHERE Id = :request.Id
        ];
        
        System.assertEquals('Signed', request.Status__c, 'Status should be Signed');
        System.assertEquals('signature_data_test', request.SignatureData__c, 'Signature data mismatch');
        System.assertNotEquals(null, request.CompletedDate__c, 'Completed date should not be null');
    }
    
    @IsTest
    static void testGetSignatureRequests() {
        DocumentLifecycleConfiguration__c config = [
            SELECT Id 
            FROM DocumentLifecycleConfiguration__c 
            LIMIT 1
        ];
        
        Test.startTest();
        List<Signature_Request__c> requests = SignatureRequestController.getSignatureRequests(config.Id);
        Test.stopTest();
        
        System.assertEquals(1, requests.size(), 'Should return 1 request');
        System.assertEquals('Test Signer', requests[0].SignerName__c, 'Signer name mismatch');
    }
}

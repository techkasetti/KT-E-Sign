@IsTest
public class CRMSyncServiceTest {

//     // ----------------------------------------------------------
//     // UNIVERSAL MOCK CLASS FOR ALL CALL OUTS
//     // ----------------------------------------------------------
//     private class MockCRMCallout implements HttpCalloutMock {
//         Integer code;
//         String status;
//         String body;

//         MockCRMCallout(Integer code, String status, String body) {
//             this.code = code;
//             this.status = status;
//             this.body = body;
//         }

//         public HTTPResponse respond(HTTPRequest req) {
//             HttpResponse res = new HttpResponse();
//             res.setStatusCode(code);
//             res.setStatus(status);
//             res.setBody(body);
//             return res;
//         }
//     }


//     // ----------------------------------------------------------
//     // TEST DATA
//     // ----------------------------------------------------------
//     @TestSetup
//     static void setupTestData() {
//         // Related DocumentLifecycleConfiguration__c
//         DocumentLifecycleConfiguration__c dlc = new DocumentLifecycleConfiguration__c(
//             DocumentTitle__c = 'Test Doc',
//             ContractType__c = 'NDA',
//             Name__c='kase'
//         );
//         insert dlc;

//         // Signature request
//         Signature_Request__c sr = new Signature_Request__c(
//             Signer_Email__c = 'test@example.com',
//             Signer_Name__c = 'John Doe',
//             Status__c = 'Pending',
//             Completion_Date__c = System.today(),
//             Document_Hash__c = 'HASH_123',
//             Signature_Method__c = 'Digital',
//             DocumentLifecycleConfiguration__c = dlc.Id,
//             SignerEmail__c='kase@gmail.com'
//         );
//         insert sr;
//     }


//     // ----------------------------------------------------------
//     // SUCCESS CASE - HTTP 200
//     // ----------------------------------------------------------
//     @IsTest
//     static void test_synchronizeSignatureData_success() {
//         Signature_Request__c req = [SELECT Id FROM Signature_Request__c LIMIT 1];

//         // Mock successful CRM API
//         String crmResponseJson = '{"id":"CRM-999","status":"success"}';
//         Test.setMock(HttpCalloutMock.class,
//             new MockCRMCallout(200, 'OK', crmResponseJson)
//         );

//         Test.startTest();
//         CRMSyncService.SyncResult result =
//             CRMSyncService.synchronizeSignatureData(req.Id, 'Salesforce');
//         Test.stopTest();

//         // Just verify something basic (you can remove asserts if you want)

//         // Make sure Sync record was created
//         List<CRM_Sync_Record__c> syncs =
//             [SELECT Id, CRM_Record_Id__c, Sync_Status__c
//              FROM CRM_Sync_Record__c];
//         System.assertEquals(1, syncs.size());
//         System.assertEquals('Success', syncs[0].Sync_Status__c);
//     }


//     // ----------------------------------------------------------
//     // FAILURE CASE - NON 200 RETURN
//     // ----------------------------------------------------------
//     @IsTest
//     static void test_synchronizeSignatureData_httpFailure() {
//         Signature_Request__c req = [SELECT Id FROM Signature_Request__c LIMIT 1];

//         // Mock failure response (any non-2xx)
//         Test.setMock(HttpCalloutMock.class,
//             new MockCRMCallout(500, 'Server Error', '{"error":"something bad"}')
//         );

//         Test.startTest();
//         CRMSyncService.SyncResult result =
//             CRMSyncService.synchronizeSignatureData(req.Id, 'Salesforce');
//         Test.stopTest();


       
//     }

// // Mock for successful callout
//     private class SuccessMock implements HttpCalloutMock {
//         public HTTPResponse respond(HTTPRequest req) {
//             HttpResponse res = new HttpResponse();
//             res.setStatusCode(200);
//             res.setBody('{ "result": "ok" }');
//             return res;
//         }
//     }

//     // Mock throwing an exception
//     private class ExceptionMock implements HttpCalloutMock {
//         public HttpResponse respond(HTTPRequest req) {
//             // force exception by throwing
//             throw new CalloutException('Mock callout failure');
//         }
//     }


//     @IsTest
//     static void testSyncWithCRM_success() {
//         // Create test data
//         Signature_Request__c r = new Signature_Request__c(
//             SignerEmail__c = 'test@example.com',
//             SignerName__c = 'Test User',
//             Payment_Status__c = 'Completed'
//         );
//         insert r;

//         // Register success mock
//         Test.setMock(HttpCalloutMock.class, new SuccessMock());

//         Test.startTest();
//         // Call future method
//         CRMSyncService.syncWithCRM(r.Id, 'SalesforceCRM');
//         Test.stopTest(); // Executes the future call

//         // Assertions
//         System.assert(true, 'Future call executed successfully');
//     }


//     @IsTest
//     static void testSyncWithCRM_recordNotFound() {
//         // Register mock
//         Test.setMock(HttpCalloutMock.class, new SuccessMock());

//         Test.startTest();
//         // Pass INVALID ID – SELECT query returns exception, caught by try/catch
//         CRMSyncService.syncWithCRM('001000000000000AAA', 'CRM');
//         Test.stopTest();

//         System.assert(true, 'Handled invalid Id gracefully');
//     }


//     @IsTest
//     static void testSyncWithCRM_calloutException() {
//         // Insert valid record
//         Signature_Request__c r = new Signature_Request__c(
//             SignerEmail__c = 'abc@x.com',
//             SignerName__c = 'Test',
//             Payment_Status__c = 'Pending'
//         );
//         insert r;

//         // Register exception mock
//         Test.setMock(HttpCalloutMock.class, new ExceptionMock());

//         Test.startTest();
//         CRMSyncService.syncWithCRM(r.Id, 'OtherCRM');
//         Test.stopTest();

//         // No exception should bubble up
//         System.assert(true, 'Exception handled inside method');
//     }

    
    
    
// // ----------------------------------------------------------
//     // UNIVERSAL MOCK CLASS FOR ALL CALL OUTS
//     // ----------------------------------------------------------
//     private class MockCRMCalloutone implements HttpCalloutMock {
//         Integer code;
//         String status;
//         String body;

//         MockCRMCalloutone(Integer code, String status, String body) {
//             this.code = code;
//             this.status = status;
//             this.body = body;
//         }

//         public HTTPResponse respond(HTTPRequest req) {
//             System.assertEquals('POST', req.getMethod());
//             System.assert(req.getEndpoint().contains('callout:CRM_System/contacts'));
//             System.assert(req.getHeader('Content-Type') == 'application/json');
//             System.assert(req.getBody() != null);

//             HttpResponse res = new HttpResponse();
//             res.setStatusCode(code);
//             res.setStatus(status);
//             res.setBody(body);
//             return res;
//         }
//     }

//     // ----------------------------------------------------------
//     // TEST SETUP - Insert required data
//     // ----------------------------------------------------------
//     @IsTest
// static void testSuccessfulSync() {
//     Signature_Request__c sig = new Signature_Request__c(
//         SignerEmail__c = 'abc@x.com',
//         SignerName__c = 'Test User',
//         Status__c = 'Completed',
//         Payment_Status__c = 'Paid',
//         Document_Title__c = 'Agreement Document'
        
//     );
//     insert sig;

//     Test.setMock(HttpCalloutMock.class, new MockCRMCallout(200, 'OK', '{"result":"success"}'));

//     Test.startTest();
//     CRMSyncService.syncToCRMAsync(sig.Id);
//     Test.stopTest();

// }


//     // ----------------------------------------------------------
//     // TEST CASE 1 - Valid request, 200 OK response
//     // ----------------------------------------------------------
//     @IsTest
//     static void testSuccessfulSyncone() {
//         // Fetch a valid Signature_Request record
//         Signature_Request__c sig = [SELECT Id FROM Signature_Request__c LIMIT 1];

//         // Register Mock response for a successful HTTP callout
//         Test.setMock(HttpCalloutMock.class, new MockCRMCallout(200, 'OK', '{"result":"success"}'));

//         Test.startTest();
//         CRMSyncService.syncToCRMAsync(sig.Id);
//         Test.stopTest();

      
//     }

//     // ----------------------------------------------------------
//     // TEST CASE 2 - Valid ID but failed (500) response
//     // ----------------------------------------------------------
//     @IsTest
//     static void testFailedSync() {
//         Signature_Request__c sig = [SELECT Id FROM Signature_Request__c LIMIT 1];

//         // Register mock for failed callout
//         Test.setMock(HttpCalloutMock.class, new MockCRMCallout(500, 'Internal Server Error', '{"error":"failure"}'));

//         Test.startTest();
//         CRMSyncService.syncToCRMAsync(sig.Id);
//         Test.stopTest();

//     }

//     // ----------------------------------------------------------
//     // TEST CASE 3 - Invalid ID string (should log error, not throw exception)
//     // ----------------------------------------------------------
//     @IsTest
//     static void testInvalidIdHandling() {
//         Test.startTest();
//         // Pass an invalid Id string
//         CRMSyncService.syncToCRMAsync('Error');
//         Test.stopTest();

//     }

//     // ----------------------------------------------------------
//     // TEST CASE 4 - Valid ID but internal exception (simulate DML failure)
//     // ----------------------------------------------------------
//     @IsTest
//     static void testDmlExceptionRecovery() {
//         // Simulate success response but nullify ID later to hit error log retry
//         Signature_Request__c sig = [SELECT Id FROM Signature_Request__c LIMIT 1];
//         Test.setMock(HttpCalloutMock.class, new MockCRMCallout(200, 'OK', '{"msg":"fine"}'));

//         // Temporarily override insert permission using a mock approach
//         Test.startTest();
//         // Pass valid id but the future method internally will handle retry logic
//         CRMSyncService.syncToCRMAsync(sig.Id);
//         Test.stopTest();

//     }
    
    
    
    
    
    
    



}
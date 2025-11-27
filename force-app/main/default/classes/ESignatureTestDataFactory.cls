public class ESignatureTestDataFactory {
    
    public static final String TEST_DOCUMENT_TITLE = 'Test Contract Document';
    public static final String TEST_SIGNER_NAME   = 'John Test Signer';
    public static final String TEST_SIGNER_EMAIL  = 'testsigner@example.com';
    
    // ------------------- USER FACTORY -------------------
    public static User createTestUser(String profileName) {
        Profile testProfile = [
            SELECT Id 
            FROM Profile 
            WHERE Name = :profileName 
            LIMIT 1
        ];
        
        User testUser = new User(
            FirstName        = 'Test',
            LastName         = 'User',
            Email            = 'testuser@example.com',
            Username         = 'testuser' + System.currentTimeMillis() + '@test.com',
            ProfileId        = testProfile.Id,
            Alias            = 'tuser',
            TimeZoneSidKey   = 'America/Los_Angeles',
            LocaleSidKey     = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        return testUser;
    }
    
//     // ------------------- DOCUMENT CONFIG FACTORY -------------------
//     public static DocumentLifecycleConfiguration__c createDocumentConfiguration() {
//         DocumentLifecycleConfiguration__c config = new DocumentLifecycleConfiguration__c(
           
//             DocumentTitle__c       = TEST_DOCUMENT_TITLE,
//             DocumentType__c        = 'Contract',
//             Template__c            = 'Standard Contract Template',
//             RequiredSigners__c     = 1,
//             ExpirationDays__c      = 30,
//             IsActive__c            = true,
//             RequiresNotarization__c = false,
//             AllowElectronicSignature__c = true,
//             ComplianceLevel__c     = 'Standard'
//         );
//         insert config;
//         return config;
//     }
    
//     public static List<DocumentLifecycleConfiguration__c> createMultipleDocumentConfigurations(Integer count) {
//         List<DocumentLifecycleConfiguration__c> configs = new List<DocumentLifecycleConfiguration__c>();
        
//         for (Integer i = 1; i <= count; i++) {
//             DocumentLifecycleConfiguration__c config = new DocumentLifecycleConfiguration__c(
               
//                 DocumentTitle__c  = TEST_DOCUMENT_TITLE + ' ' + i,
//                 DocumentType__c   = 'Contract',
//                 Template__c       = 'Template ' + i,
//                 RequiredSigners__c = Math.mod(i, 3) + 1,
//                 ExpirationDays__c = 30,
//                 IsActive__c       = true
//             );
//             configs.add(config);
//         }
//         insert configs;
//         return configs;
//     }
    
//     // ------------------- SIGNATURE REQUEST FACTORY -------------------
//     public static Signature_Request__c createSignatureRequest(DocumentLifecycleConfiguration__c docConfig) {
//         Signature_Request__c request = new Signature_Request__c(
//             DocumentId__c          = docConfig.Id,
//             SignerName__c          = TEST_SIGNER_NAME,
//             SignerEmail__c         = TEST_SIGNER_EMAIL,
//             Status__c              = 'Pending',
//             RequestedDate__c       = System.now().date(),
//             ExpirationDate__c      = System.now().addDays(30).date(),
//             RequesterUserId__c     = UserInfo.getUserId(),
//             ComplianceValidated__c = false,
//             NotificationsSent__c   = 0,
//             RemindersEnabled__c    = true
//         );
//         insert request;
//         return request;
//     }
    
//     public static List<Signature_Request__c> createMultipleSignatureRequests(DocumentLifecycleConfiguration__c docConfig, Integer count) {
//         List<Signature_Request__c> requests = new List<Signature_Request__c>();
        
//         for (Integer i = 1; i <= count; i++) {
//             Signature_Request__c request = new Signature_Request__c(
//                 DocumentId__c      = docConfig.Id,
//                 SignerName__c      = TEST_SIGNER_NAME + ' ' + i,
//                 SignerEmail__c     = 'testsigner' + i + '@example.com',
//                 Status__c          = getRandomStatus(),
//                 RequestedDate__c   = System.now().addDays(-Math.mod(i, 10)).date(),
//                 ExpirationDate__c  =System.now().addDays(30).date(),
//                 RequesterUserId__c = UserInfo.getUserId()
//             );
//             requests.add(request);
//         }
//         insert requests;
//         return requests;
//     }
    
//     // ------------------- AUDIT TRAIL FACTORY -------------------
//     public static AuditTrail__c createAuditTrailEntry(String action, String status) {
//         AuditTrail__c audit = new AuditTrail__c(
//             UserId__c         = UserInfo.getUserId(),
//             Action__c         = action,
//             Status__c         = status,
//             Details__c        = 'Test audit entry for ' + action,
//             IP_Address__c     = '192.168.1.100',
//             User_Agent__c     = 'Test Browser Agent',
//             Session_Id__c     = UserInfo.getSessionId(),
//             Response_Time_Ms__c = 1500,
//             Record_Id__c      = null
//         );
//         insert audit;
//         return audit;
//     }
    
//     public static List<AuditTrail__c> createMultipleAuditEntries(Integer count) {
//         List<AuditTrail__c> auditEntries = new List<AuditTrail__c>();
        
//         String[] actions  = new String[]{ 'DOCUMENT_GENERATED', 'SIGNATURE_REQUESTED', 'SIGNATURE_COMPLETED', 'NOTIFICATION_SENT', 'SYSTEM_ERROR' };
//         String[] statuses = new String[]{ 'SUCCESS', 'ERROR', 'WARNING', 'INFO' };
        
//         for (Integer i = 0; i < count; i++) {
//             AuditTrail__c audit = new AuditTrail__c(
//                 UserId__c         = UserInfo.getUserId(),
//                 Action__c         = actions[Math.mod(i, actions.size())],
//                 Status__c         = statuses[Math.mod(i, statuses.size())],
//                 Details__c        = 'Test audit entry ' + i,
//                 IP_Address__c     = '192.168.1.' + Math.mod(i, 255),
//                 Response_Time_Ms__c = 1000 + Math.mod(i * 100, 2000)
//             );
//             auditEntries.add(audit);
//         }
//         insert auditEntries;
//         return auditEntries;
//     }
    
//     // ------------------- HELPER -------------------
//     private static String getRandomStatus() {
//         String[] statuses = new String[]{ 'Pending', 'Completed', 'Error', 'Expired' };
//         return statuses[Math.mod(Crypto.getRandomInteger(), statuses.size())];
//     }
 }
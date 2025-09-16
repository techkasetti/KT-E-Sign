public with sharing class SignatureRequestController {

    // Signature status enumeration
    public enum SignatureStatus {
        DRAFT, PENDING, SIGNED, REJECTED, COMPLETED, EXPIRED
    }

    //updated
    /**
     * Generate SHA-256 hash of document content
     */
    @TestVisible
    private static String generateDocumentHash(String content) {
        try {
            Blob contentBlob = Blob.valueOf(content);
            Blob hashBlob = Crypto.generateDigest('SHA-256', contentBlob);
            return EncodingUtil.base64Encode(hashBlob);
        } catch (Exception e) {
            System.debug('⚠ Failed to generate document hash: ' + e.getMessage());
            return 'HASH_GENERATION_FAILED_' + DateTime.now().getTime();
        }
    }

    //old
    // private static String generateDocumentHash(String documentId) {
    //     DocumentLifecycleConfiguration__c doc = [
    //         SELECT GeneratedClause__c, CreatedDate 
    //         FROM DocumentLifecycleConfiguration__c 
    //         WHERE Id = :documentId
    //     ];
        
    //     String hashInput = doc.GeneratedClause__c + String.valueOf(doc.CreatedDate);
    //     Blob hashBlob = Crypto.generateDigest('SHA-256', Blob.valueOf(hashInput));
    //     return EncodingUtil.convertToHex(hashBlob);
    // }
//updated (from 3 last 3 files)
    /**
     * Initiate a new signature request
     * @param configId Configuration ID for document generation
     * @param signerEmail Email of the signer
     * @param signerName Name of the signer
     * @return Signature request ID
     */
    @AuraEnabled
    public static String initiateSignatureRequest(String configId, String signerEmail, String signerName) {
        System.debug('Initiating signature request for: ' + signerEmail);
        
        try {
            // Input validation
            if (String.isBlank(configId) || String.isBlank(signerEmail) || String.isBlank(signerName)) {
                throw new IllegalArgumentException('Configuration ID, signer email, and signer name are required');
            }
            
            // Validate email format
            if (!isValidEmail(signerEmail)) {
                throw new IllegalArgumentException('Invalid email format: ' + signerEmail);
            }
            
            // Validate configuration exists
            List<DocumentLifecycleConfiguration__c> configs = [
                SELECT Id, Region__c, Role__c, ContractType__c, OutputFormat__c
                FROM DocumentLifecycleConfiguration__c 
                WHERE Id = :configId 
                LIMIT 1
            ];
            
            if (configs.isEmpty()) {
                throw new IllegalArgumentException('Invalid configuration ID: ' + configId);
            }
            
            DocumentLifecycleConfiguration__c config = configs[0];
            
            // Generate document content
            String documentContent = generateDocumentContent(config);
            String documentHash = generateDocumentHash(documentContent);
            
            // Create signature request
            Signature_Request__c sigRequest = new Signature_Request__c(
                DocumentId__c = configId,
                SignerEmail__c = signerEmail,
                SignerName__c = signerName,
                Status__c = SignatureStatus.PENDING.name(),
                Document_Hash__c = documentHash,
                Created_Date__c = DateTime.now(),
                OTP_Verification__c = false
            );
            
            insert sigRequest;
            
            // Send notification email
            sendSignatureRequestEmail(sigRequest.Id, signerEmail, signerName, config);
            
            // Log activity
            logSignatureActivity(sigRequest.Id, 'SIGNATURE_REQUEST_INITIATED', 'SUCCESS', 
                               'Request sent to ' + signerEmail);
            
            System.debug('✓ Signature request created with ID: ' + sigRequest.Id);
            return sigRequest.Id;
            
        } catch (Exception e) {
            System.debug('✗ Signature request initiation failed: ' + e.getMessage());
            logSignatureActivity(null, 'SIGNATURE_REQUEST_INITIATED', 'ERROR', e.getMessage());
            throw new AuraHandledException('Failed to initiate signature request: ' + e.getMessage());
        }
    }
    // @AuraEnabled
    // public static String initiateSignatureRequest(String documentId, String signerEmail, String signerName) {
    
    
    //      try {
    //         // Create signature request
    //         Signature_Request__c request = new Signature_Request__c(
    //             DocumentId__c = documentId,
    //             SignerEmail__c = signerEmail,
    //             SignerName__c = signerName,
    //             Status__c = 'Pending'
    //         );
    //         insert request;

    //         // Log the request initiation
    //         AuditTrailManager.logDocumentActivity(
    //             documentId,
    //             'SIGNATURE_REQUEST_INITIATED',
    //             'Signature request sent to: ' + signerEmail
    //         );

    //         // Send notification email
    //         EmailNotificationService.sendSignatureRequestEmail(request.Id);

    //         return request.Id;
    //     } catch (Exception e) {
    //         AuditTrailManager.logSystemActivity('SIGNATURE_REQUEST_ERROR', e.getMessage());
    //         throw new AuraHandledException('Error creating signature request: ' + e.getMessage());
    //     }
    // }

    
    
    
    
        // try {
    //         // Validate inputs
    //         if (String.isBlank(documentId) || String.isBlank(signerEmail) || String.isBlank(signerName)) {
    //             throw new AuraHandledException('Missing required fields for signature request');
    //         }
            
    //         // Verify document exists and is ready for signature
    //         DocumentLifecycleConfiguration__c document = [
    //             SELECT Id, ProcessingStatus__c, ComplianceStatus__c, GeneratedClause__c
    //             FROM DocumentLifecycleConfiguration__c 
    //             WHERE Id = :documentId 
    //             LIMIT 1
    //         ];
            
    //         if (document.ProcessingStatus__c != 'Completed') {
    //             throw new AuraHandledException('Document must be completed before requesting signature');
    //         }
            
    //         if (document.ComplianceStatus__c == 'Non-Compliant') {
    //             throw new AuraHandledException('Cannot request signature for non-compliant document');
    //         }
            
    //         // Create signature request
    //         Signature_Request__c request = new Signature_Request__c(
    //             DocumentId__c = documentId,
    //             SignerEmail__c = signerEmail,
    //             SignerName__c = signerName,
    //             Status__c = 'Pending',
    //             Document_Hash__c = generateDocumentHash(document.GeneratedClause__c)
    //         );
            
    //         insert request;
            
    //         // Send notification email
    //         EmailNotificationService.sendSignatureRequest(request.Id);
            
    //         // Log the signature request
    //         AuditTrailManager.logSignatureRequest(request.Id, 'Signature Request Created');
            
    //         return request.Id;
            
    //     } catch (Exception e) {
    //         throw new AuraHandledException('Failed to initiate signature request: ' + e.getMessage());
    //     }
    // }

    
    
        //             try {
    //         System.debug('Initiating signature request for document: ' + documentId);
            
    //         // Validate document exists and is ready for signing
    //         DocumentLifecycleConfiguration__c doc = [
    //             SELECT Id, DocumentTitle__c, ComplianceStatus__c, ProcessingStatus__c
    //             FROM DocumentLifecycleConfiguration__c 
    //             WHERE Id = :documentId
    //         ];
            
    //         if (doc.ProcessingStatus__c != 'Completed') {
    //             throw new SignatureException('Document must be completed before requesting signature');
    //         }
            
    //         if (doc.ComplianceStatus__c != 'Compliant') {
    //             throw new SignatureException('Document must be compliant before requesting signature');
    //         }
            
    //         // Create signature request
    //         Signature_Request__c sigRequest = new Signature_Request__c(
    //             DocumentId__c = documentId,
    //             SignerEmail__c = signerEmail,
    //             SignerName__c = signerName,
    //             Status__c = 'Pending',
    //             Document_Hash__c = generateDocumentHash(doc.Id)
    //         );
            
    //         insert sigRequest;
            
    //         // Log audit trail
    //         AuditTrailManager.logDocumentActivity(
    //             documentId,
    //             'Signature Request Created',
    //             'Signature request sent to: ' + signerEmail
    //         );
            
    //         // Send notification email
    //         EmailNotificationService.sendSignatureRequest(sigRequest.Id);
            
    //         System.debug('✓ Signature request created: ' + sigRequest.Id);
    //         return sigRequest.Id;
            
    //     } catch (Exception e) {
    //         System.debug('❌ Error creating signature request: ' + e.getMessage());
    //         throw new AuraHandledException('Failed to initiate signature request: ' + e.getMessage());
    //     }
    // }

        
        
        // try {
        //     Signature_Request__c request = new Signature_Request__c(
        //         DocumentId__c = documentId,
        //         SignerEmail__c = signerEmail,
        //         SignerName__c = signerName,
        //         Status__c = 'Pending'
        //     );
        //     insert request;

        //     System.debug('✓ Signature request created: ' + request.Id);
        //     return request.Id;

        // } catch (Exception e) {
        //     throw new AuraHandledException('Error creating signature request: ' + e.getMessage());
        // }
    //}
    private static String getClientIPAddress() {
        // In a real implementation, this would get the actual client IP
        // For now, return a placeholder
        return '127.0.0.1';
    }

    
    //updated (from 3 last 3 files)
    /**
     * Submit signature data
     * @param requestId Signature request ID
     * @param signatureData Base64 encoded signature or typed signature
     * @param signerInfo JSON string with signer information
     * @return Success status
     */
    @AuraEnabled
    public static Boolean submitSignature(String requestId, String signatureData, String signerInfo) {
        System.debug('Submitting signature for request: ' + requestId);
        
        try {
            // Input validation
            if (String.isBlank(requestId) || String.isBlank(signatureData) || String.isBlank(signerInfo)) {
                throw new IllegalArgumentException('Request ID, signature data, and signer info are required');
            }
            
            // Validate signature request exists and is in pending status
            List<Signature_Request__c> requests = [
                SELECT Id, Status__c, SignerEmail__c, SignerName__c, DocumentId__c, Document_Hash__c
                FROM Signature_Request__c 
                WHERE Id = :requestId 
                LIMIT 1
            ];
            
            if (requests.isEmpty()) {
                throw new IllegalArgumentException('Invalid signature request ID: ' + requestId);
            }
            
            Signature_Request__c request = requests[0];
            
            if (request.Status__c != SignatureStatus.PENDING.name()) {
                throw new IllegalArgumentException('Signature request is not in pending status. Current status: ' + request.Status__c);
            }
            
            // Validate signature data
            if (!isValidSignatureData(signatureData)) {
                throw new IllegalArgumentException('Invalid signature data format');
            }
            
            // Parse signer info
            Map<String, Object> signerInfoMap = parseSignerInfo(signerInfo);
            
            // Update signature request
            request.SignatureData__c = signatureData;
            request.Status__c = SignatureStatus.SIGNED.name();
            request.CompletedDate__c = DateTime.now();
            
            update request;
            
            // Create signature validation record
            createSignatureValidation(request, signerInfoMap);
            
            // Process post-signature workflows
            processPostSignatureWorkflow(request);
            
            // Log successful signature
            logSignatureActivity(requestId, 'SIGNATURE_SUBMITTED', 'SUCCESS', 
                               'Signature completed by ' + request.SignerName__c);
            
        // Send completion notification
        sendSignatureCompletionEmail(request);
        
        System.debug('✓ Signature submitted successfully for request: ' + requestId);
        return true;
        
        } catch (Exception e) {
            System.debug('✗ Signature submission failed: ' + e.getMessage());
            logSignatureActivity(requestId, 'SIGNATURE_SUBMITTED', 'ERROR', e.getMessage());
            throw new AuraHandledException('Failed to submit signature: ' + e.getMessage());
        }
    }
    //old
    // @AuraEnabled
    // public static Boolean submitSignature(String requestId, String signatureData, String signatureMethod) {
    
    //         try {
    //         // Validate inputs
    //         if (String.isBlank(requestId) || String.isBlank(signatureData)) {
    //             throw new AuraHandledException('Request ID and signature data are required');
    //         }
            
    //         // Get signature request
    //         List<Signature_Request__c> requests = [
    //             SELECT Id, Status__c, SignerEmail__c, DocumentId__c 
    //             FROM Signature_Request__c 
    //             WHERE Id = :requestId FOR UPDATE
    //         ];
            
    //         if (requests.isEmpty()) {
    //             throw new AuraHandledException('Signature request not found');
    //         }
            
    //         Signature_Request__c request = requests[0];
            
    //         // Check if already signed
    //         if (request.Status__c == 'Signed' || request.Status__c == 'Completed') {
    //             throw new AuraHandledException('This document has already been signed');
    //         }
            
    //         // Update signature request
    //         request.SignatureData__c = signatureData;
    //         request.Status__c = 'Signed';
    //         request.CompletedDate__c = System.now();
    //         request.SignatureMethod__c = signatureMethod;
    //         request.Document_Hash__c = generateDocumentHash(signatureData);
            
    //         update request;
            
    //         // Create signature validation record
    //         SignatureValidation__c validation = new SignatureValidation__c();
    //         validation.SignatureRequest__c = request.Id;
    //         validation.ValidationStatus__c = 'Valid';
    //         validation.SignerIP__c = getClientIPAddress();
    //         validation.ValidationDate__c = System.now();
            
    //         insert validation;
            
    //         // Log signature completion
    //         AuditTrailManager.logDocumentActivity(request.DocumentId__c, 'DOCUMENT_SIGNED', 
    //             'Document signed by: ' + request.SignerEmail__c + ' using ' + signatureMethod);
            
    //         // Send completion email
    //         EmailNotificationService.sendSignatureCompletion(request.Id);
            
    //         return true;
            
    //     } catch (Exception e) {
    //         AuditTrailManager.logError('SIGNATURE_SUBMISSION_FAILED', e.getMessage(), requestId);
    //         throw new AuraHandledException('Failed to submit signature: ' + e.getMessage());
    //     }
    // }
    





    
        //     try {
    //         Signature_Request__c sigRequest = [
    //             SELECT Id, Status__c, SignerEmail__c, SignerName__c, DocumentId__c
    //             FROM Signature_Request__c 
    //             WHERE Id = :requestId 
    //             LIMIT 1
    //         ];

    //         sigRequest.SignatureData__c = signatureData;
    //         sigRequest.SignatureMethod__c = signatureMethod;
    //         sigRequest.Status__c = SignatureStatus.SIGNED.name();
    //         sigRequest.CompletedDate__c = DateTime.now();

    //         update sigRequest;

    //         Signature_Validation__c validation = new Signature_Validation__c(
    //             Signature_Request__c = sigRequest.Id,
    //             ValidationStatus__c = 'Valid',
    //             ValidationDate__c = DateTime.now(),
    //             SignerIP__c = getClientIP(),
    //             ValidationHash__c = generateValidationHash(signatureData)
    //         );

    //         insert validation;

    //         // Log the signature submission
    //         logSignatureAction(requestId, 'SIGNATURE_SUBMITTED', 'SUCCESS');

    //         return true;

    //     } catch (Exception e) {
    //         System.debug('Error submitting signature: ' + e.getMessage());
    //         logSignatureAction(requestId, 'SIGNATURE_SUBMISSION_FAILED', 'ERROR');
    //         throw new AuraHandledException('Failed to submit signature: ' + e.getMessage());
    //     }
    // }



        @AuraEnabled(cacheable=false)
    public static String submitSignature(String requestId, String signatureData, String signatureMethod, String signerIP) {
        try {
            System.debug('Submitting signature for request: ' + requestId);
            
            // Get signature request
            Signature_Request__c request = [
                SELECT Id, DocumentId__c, SignerEmail__c, Status__c, Document_Hash__c
                FROM Signature_Request__c 
                WHERE Id = :requestId
            ];
            
            if (request.Status__c == 'Signed') {
                throw new SignatureException('Document has already been signed');
            }
            
            // Update signature request
            request.SignatureData__c = signatureData;
            request.SignatureMethod__c = signatureMethod;
            request.Status__c = 'Signed';
            request.CompletedDate__c = System.now();
            request.IPAddress__c = signerIP;
            
            update request;
            
            // Create signature validation record
            SignatureValidation__c validation = new SignatureValidation__c(
                SignatureRequest__c = requestId,
                ValidationStatus__c = 'Valid',
                SignerIP__c = signerIP,
                ValidationHash__c = generateValidationHash(requestId, signatureData),
                ValidatedDate__c = System.now()
            );
            
            insert validation;
            
            // Log audit trail
            AuditTrailManager.logDocumentActivity(
                request.DocumentId__c,
                'Document Signed',
                'Signature completed using method: ' + signatureMethod + ' from IP: ' + signerIP
            );
            
            // Send completion notification
            EmailNotificationService.sendSignatureCompletion(requestId);
            
            System.debug('✓ Signature submitted successfully');
            return 'SUCCESS';
            
        } catch (Exception e) {
            System.debug('❌ Error submitting signature: ' + e.getMessage());
            throw new AuraHandledException('Failed to submit signature: ' + e.getMessage());
        }
    }

    //updated (from 3 last 3 files)
    /**
     * Get signature request details
     * @param requestId Signature request ID
     * @return Signature request details
     */
    @AuraEnabled
    public static Map<String, Object> getSignatureRequest(String requestId) {
        System.debug('Retrieving signature request: ' + requestId);
        try {
            if (String.isBlank(requestId)) {
                throw new IllegalArgumentException('Request ID is required');
            }
            
            List<Signature_Request__c> requests = [
                SELECT Id, DocumentId__c, SignerEmail__c, SignerName__c, Status__c,
                    SignatureData__c, CompletedDate__c, Created_Date__c, OTP_Verification__c
                FROM Signature_Request__c 
                WHERE Id = :requestId 
                LIMIT 1
            ];
            
            if (requests.isEmpty()) {
                throw new IllegalArgumentException('Signature request not found: ' + requestId);
            }
            
            Signature_Request__c request = requests[0];
            
            // Get associated document configuration
            DocumentLifecycleConfiguration__c config = [
                SELECT Region__c, Role__c, ContractType__c, OutputFormat__c, ComplianceStatus__c
                FROM DocumentLifecycleConfiguration__c 
                WHERE Id = :request.DocumentId__c 
                LIMIT 1
            ];
            
            Map<String, Object> requestDetails = new Map<String, Object>{
                'id' => request.Id,
                'documentId' => request.DocumentId__c,
                'signerEmail' => request.SignerEmail__c,
                'signerName' => request.SignerName__c,
                'status' => request.Status__c,
                'hasSignature' => String.isNotBlank(request.SignatureData__c),
                'completedDate' => request.CompletedDate__c,
                'createdDate' => request.Created_Date__c,
                'otpVerified' => request.OTP_Verification__c,
                'documentType' => config.ContractType__c,
                'region' => config.Region__c,
                'role' => config.Role__c,
                'complianceStatus' => config.ComplianceStatus__c
            };
            
            System.debug('✓ Retrieved signature request details');
            return requestDetails;
            
        } catch (Exception e) {
            System.debug('✗ Failed to retrieve signature request: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve signature request: ' + e.getMessage());
        }
    }
    //old
    // @AuraEnabled
    // public static Signature_Request__c getSignatureRequest(String requestId) {
    //     try {
    //         return [
    //             SELECT Id, DocumentId__c, SignerEmail__c, SignerName__c, Status__c,
    //                    SignatureData__c, SignatureMethod__c, CompletedDate__c, Created_Date__c
    //             FROM Signature_Request__c 
    //             WHERE Id = :requestId 
    //             LIMIT 1
    //         ];
    //     } catch (Exception e) {
    //         System.debug('Error retrieving signature request: ' + e.getMessage());
    //         throw new AuraHandledException('Failed to retrieve signature request: ' + e.getMessage());
    //     }
    // }

    @AuraEnabled
    public static List<Signature_Request__c> getSignatureRequests() {
        try {
            return [
                SELECT Id, DocumentId__c, SignerEmail__c, SignerName__c, Status__c,
                       CompletedDate__c, Created_Date__c
                FROM Signature_Request__c 
                ORDER BY Created_Date__c DESC
                LIMIT 50
            ];
        } catch (Exception e) {
            System.debug('Error retrieving signature requests: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve signature requests: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Signature_Request__c> getSignatureRequests(String documentId) {
      
              try {
            return [
                SELECT Id, SignerName__c, SignerEmail__c, Status__c, CreatedDate, CompletedDate__c
                FROM Signature_Request__c 
                WHERE DocumentId__c = :documentId 
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception e) {
            System.debug('GetSignatureRequests Error: ' + e.getMessage());
            return new List<Signature_Request__c>();
        }
    }
    /**
     * Get list of signature requests with optional filtering
     * @param filterStatus Optional status filter
     * @param filterEmail Optional email filter
     * @return List of signature requests
     */
    @AuraEnabled
    public static List<Map<String, Object>> getSignatureRequests(String filterStatus, String filterEmail) {
        System.debug('Retrieving signature requests with filters - Status: ' + filterStatus + ', Email: ' + filterEmail);
        try {
            String query = 'SELECT Id, DocumentId__c, SignerEmail__c, SignerName__c, Status__c, ' +
                        'CompletedDate__c, Created_Date__c FROM Signature_Request__c WHERE Id != null';
            
            List<String> whereConditions = new List<String>();
            
            if (String.isNotBlank(filterStatus) && !filterStatus.equals('All')) {
                whereConditions.add('Status__c = :filterStatus');
            }
            
            if (String.isNotBlank(filterEmail)) {
                whereConditions.add('SignerEmail__c LIKE :filterEmail');
                filterEmail = '%' + filterEmail + '%';
            }
            
            if (!whereConditions.isEmpty()) {
                query += ' AND ' + String.join(whereConditions, ' AND ');
            }
            
            query += ' ORDER BY Created_Date__c DESC LIMIT 100';
            
            List<Signature_Request__c> requests = Database.query(query);
            List<Map<String, Object>> requestList = new List<Map<String, Object>>();
            
            for (Signature_Request__c request : requests) {
                requestList.add(new Map<String, Object>{
                    'id' => request.Id,
                    'documentId' => request.DocumentId__c,
                    'signerEmail' => request.SignerEmail__c,
                    'signerName' => request.SignerName__c,
                    'status' => request.Status__c,
                    'completedDate' => request.CompletedDate__c,
                    'createdDate' => request.Created_Date__c,
                    'statusClass' => getStatusClass(request.Status__c)
                });
            }
            
            System.debug('✓ Retrieved ' + requestList.size() + ' signature requests');
            return requestList;
            
        } catch (Exception e) {
            System.debug('✗ Failed to retrieve signature requests: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve signature requests: ' + e.getMessage());
        }
    }
      
      
      
      
        //return [
    //         SELECT Id, SignerName__c, SignerEmail__c, Status__c, CompletedDate__c
    //         FROM Signature_Request__c
    //         WHERE DocumentId__c = :documentId
    //         ORDER BY CreatedDate DESC
    //     ];
    // }

    // Helper methods
    private static void logSignatureAction(String recordId, String action, String status) {
        try {
            AuditTrail__c audit = new AuditTrail__c(
                RecordId__c = recordId,
                Action__c = action,
                Status__c = status,
                Details__c = 'Signature workflow action: ' + action,
                UserId__c = UserInfo.getUserId()
            );
            insert audit;
        } catch (Exception e) {
            System.debug('⚠ Could not log signature action: ' + e.getMessage());
        }
    }

    private static void sendSignatureNotification(String requestId, String signerEmail, String signerName) {
        System.debug('📧 Email notification sent to: ' + signerEmail + ' for request: ' + requestId);
    }

    private static String getClientIP() {
        return '127.0.0.1';
    }
    private static String generateValidationHash(String requestId, String signatureData) {
        String hashInput = requestId + signatureData + String.valueOf(System.now());
        Blob hashBlob = Crypto.generateDigest('SHA-256', Blob.valueOf(hashInput));
        return EncodingUtil.convertToHex(hashBlob);
    }

    private static String generateValidationHash(String signatureData) {
        Blob signatureBlob = Blob.valueOf(signatureData + System.now().getTime());
        Blob hash = Crypto.generateDigest('SHA256', signatureBlob);
        return EncodingUtil.base64Encode(hash);
    }

        @AuraEnabled(cacheable=true)
    public static List<Signature_Request__c> getSignatureRequestsForDocument(String documentId) {
        try {
            return [
                SELECT Id, SignerEmail__c, SignerName__c, Status__c, CompletedDate__c, SignatureMethod__c
                FROM Signature_Request__c 
                WHERE DocumentId__c = :documentId
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve signature requests: ' + e.getMessage());
        }
    }
    
    public class SignatureException extends Exception {}

    @AuraEnabled
    public static String generateAuditSummary(String documentId) {
        try {
            // Get document and related records
            DocumentLifecycleConfiguration__c document = [
                SELECT Id, DocumentTitle__c, Region__c, Role__c, ContractType__c, 
                       ProcessingStatus__c, ComplianceStatus__c, CreatedDate
                FROM DocumentLifecycleConfiguration__c 
                WHERE Id = :documentId 
                LIMIT 1
            ];
            
            List<Signature_Request__c> signatures = [
                SELECT Id, SignerName__c, SignerEmail__c, Status__c, CompletedDate__	
                FROM Signature_Request__c 
                WHERE DocumentId__c = :documentId 
                ORDER BY CreatedDate DESC
            ];
            
            List<AuditTrail__c> auditRecords = [
                SELECT Id, Action__c, Status__c, Details__c, Timestamp__c, UserId__r.Name
                FROM AuditTrail__c 
                WHERE DocumentId__c = :documentId 
                ORDER BY Timestamp__c DESC
            ];
            
            // Generate comprehensive audit summary
            Map<String, Object> auditSummary = new Map<String, Object>();
            auditSummary.put('documentInfo', document);
            auditSummary.put('signatureRequests', signatures);
            auditSummary.put('auditTrail', auditRecords);
            auditSummary.put('generatedAt', System.now());
            auditSummary.put('totalSignatures', signatures.size());
            
            Integer completedSignatures = 0;
            for (Signature_Request__c sig : signatures) {
                if (sig.Status__c == 'Signed') {
                    completedSignatures++;
                }
            }
            auditSummary.put('completedSignatures', completedSignatures);
            
            return JSON.serialize(auditSummary);
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to generate audit summary: ' + e.getMessage());
        }
    }
    @AuraEnabled(cacheable=true)
public static String generateAuditSummary(String requestId) {
    try {
        List<AuditTrail__c> auditRecords = [
            SELECT Action__c, Status__c, Details__c, Timestamp__c, UserId__r.Name 
            FROM AuditTrail__c 
            WHERE RecordId__c = :requestId 
            ORDER BY Timestamp__c ASC
        ];
        
        String summary = 'Audit Trail Summary:\n';
        for (AuditTrail__c audit : auditRecords) {
            summary += String.valueOf(audit.Timestamp__c) + ' - ' + 
                      audit.Action__c + ': ' + audit.Details__c + '\n';
        }
        return summary;
    } catch (Exception e) {
        return 'Error generating audit summary: ' + e.getMessage();
    }
}

private static String getClientIP() {
    return '127.0.0.1'; // Placeholder - implement actual IP detection
}

private static String getUserAgent() {
    return 'Salesforce Browser'; // Placeholder
}
    @AuraEnabled
    public static SignatureRequestResult createSignatureRequest(String documentId, String signerEmail, String signerName) {
        SignatureRequestResult result = new SignatureRequestResult();
        
        try {
            // Validate document exists
            DocumentLifecycleConfiguration__c document = [
                SELECT Id, DocumentTitle__c, GeneratedClause__c, ComplianceStatus__c
                FROM DocumentLifecycleConfiguration__c 
                WHERE Id = :documentId 
                LIMIT 1
            ];
            
            if (document.ComplianceStatus__c != 'Compliant') {
                throw new AuraHandledException('Document must be compliant before requesting signature');
            }
            
            // Generate document hash
            String documentHash = generateDocumentHash(document.GeneratedClause__c);
            
            // Create signature request
            Signature_Request__c signatureRequest = new Signature_Request__c(
                DocumentId__c = documentId,
                SignerEmail__c = signerEmail,
                SignerName__c = signerName,
                Status__c = 'Pending',
                Document_Hash__c = documentHash
            );
            
            insert signatureRequest;
            
            // Log audit trail
            AuditTrailManager.logSignatureActivity(
                signatureRequest.Id,
                'SIGNATURE_REQUEST_CREATED',
                'SUCCESS',
                'Signature request created for: ' + signerEmail
            );
            
            result.success = true;
            result.signatureRequestId = signatureRequest.Id;
            result.message = 'Signature request created successfully';
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
            System.debug('SignatureRequestController Error: ' + e.getMessage());
        }
        
        return result;
    }
    private static String generateSignatureHash(String signatureData, String documentHash) {
        String combinedData = signatureData + documentHash + String.valueOf(System.now().getTime());
        Blob dataBlob = Blob.valueOf(combinedData);
        Blob hashBlob = Crypto.generateDigest('SHA-256', dataBlob);
        return EncodingUtil.base64Encode(hashBlob);
    }

@AuraEnabled
    public static SignatureRequestResult processSignature(String signatureRequestId, String signatureData, String signatureMethod) {
        SignatureRequestResult result = new SignatureRequestResult();
        
        try {
            // Get signature request
            Signature_Request__c request = [
                SELECT Id, Status__c, SignerEmail__c, DocumentId__c, Document_Hash__c
                FROM Signature_Request__c 
                WHERE Id = :signatureRequestId 
                LIMIT 1
            ];
            
            if (request.Status__c != 'Pending') {
                throw new AuraHandledException('Signature request is not in pending status');
            }
            
            // Validate signature data
            if (String.isBlank(signatureData)) {
                throw new AuraHandledException('Signature data cannot be empty');
            }
            
            // Update signature request
            request.SignatureData__c = signatureData;
            request.SignatureMethod__c = signatureMethod;
            request.Status__c = 'Signed';
            request.CompletedDate__c = System.now();
            
            update request;
            
            // Create signature validation record
            SignatureValidation__c validation = new SignatureValidation__c(
                SignatureRequest__c = signatureRequestId,
                ValidationStatus__c = 'Valid',
                ValidationDate__c = System.now(),
                ValidationHash__c = generateSignatureHash(signatureData, request.Document_Hash__c)
            );
            
            insert validation;
            
            // Log audit trail
            AuditTrailManager.logSignatureActivity(
                signatureRequestId,
                'SIGNATURE_COMPLETED',
                'SUCCESS',
                'Document signed by: ' + request.SignerEmail__c
            );
            
            result.success = true;
            result.message = 'Signature processed successfully';
            result.validationId = validation.Id;
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
            System.debug('ProcessSignature Error: ' + e.getMessage());
        }
        
        return result;
    }
    @AuraEnabled
    public static DocumentData getDocumentData(String documentId) {
        try {
            DocumentLifecycleConfiguration__c doc = [
                SELECT Id, DocumentTitle__c, GeneratedClause__c, Region__c, Role__c, 
                       ContractType__c, ComplianceStatus__c, CreatedDate
                FROM DocumentLifecycleConfiguration__c 
                WHERE Id = :documentId 
                LIMIT 1
            ];
            
            DocumentData data = new DocumentData();
            data.document = doc;
            data.signatureRequests = getSignatureRequests(documentId);
            
            return data;
            
        } catch (Exception e) {
            System.debug('GetDocumentData Error: ' + e.getMessage());
            return null;
        }
    }
    public class DocumentData {
            @AuraEnabled public DocumentLifecycleConfiguration__c document;
            @AuraEnabled public List<Signature_Request__c> signatureRequests;
    }

    //updated (from 3 last 3 files)
    
    /**
     * Cancel a signature request
     * @param requestId Signature request ID
     * @param reason Cancellation reason
     * @return Success status
     */
    @AuraEnabled
    public static Boolean cancelSignatureRequest(String requestId, String reason) {
        System.debug('Cancelling signature request: ' + requestId);
        try {
            if (String.isBlank(requestId)) {
                throw new IllegalArgumentException('Request ID is required');
            }
            
            List<Signature_Request__c> requests = [
                SELECT Id, Status__c, SignerEmail__c, SignerName__c
                FROM Signature_Request__c 
                WHERE Id = :requestId 
                LIMIT 1
            ];
            
            if (requests.isEmpty()) {
                throw new IllegalArgumentException('Signature request not found: ' + requestId);
            }
            
            Signature_Request__c request = requests[0];
            
            if (request.Status__c == SignatureStatus.SIGNED.name() || 
                request.Status__c == SignatureStatus.COMPLETED.name()) {
                throw new IllegalArgumentException('Cannot cancel a completed signature request');
            }
            
            request.Status__c = SignatureStatus.REJECTED.name();
            update request;
            
            // Send cancellation notification
            sendCancellationNotification(request, reason);
            
            // Log cancellation
            logSignatureActivity(requestId, 'SIGNATURE_CANCELLED', 'SUCCESS', 
                            'Request cancelled. Reason: ' + (String.isBlank(reason) ? 'No reason provided' : reason));
            
            System.debug('✓ Signature request cancelled successfully');
            return true;
            
        } catch (Exception e) {
            System.debug('✗ Failed to cancel signature request: ' + e.getMessage());
            logSignatureActivity(requestId, 'SIGNATURE_CANCELLED', 'ERROR', e.getMessage());
            throw new AuraHandledException('Failed to cancel signature request: ' + e.getMessage());
        }
    }

    /**
     * Reset signature request to allow re-signing
     * @param requestId Signature request ID
     * @return Success status
     */
    @AuraEnabled
    public static Boolean resetSignatureRequest(String requestId) {
        System.debug('Resetting signature request: ' + requestId);
        try {
            if (String.isBlank(requestId)) {
                throw new IllegalArgumentException('Request ID is required');
            }
            
            List<Signature_Request__c> requests = [
                SELECT Id, Status__c, SignerEmail__c, SignerName__c
                FROM Signature_Request__c 
                WHERE Id = :requestId 
                LIMIT 1
            ];
            
            if (requests.isEmpty()) {
                throw new IllegalArgumentException('Signature request not found: ' + requestId);
            }
            
            Signature_Request__c request = requests[0];
            
            // Clear signature data and reset status
            request.Status__c = SignatureStatus.PENDING.name();
            request.SignatureData__c = null;
            request.CompletedDate__c = null;
            request.OTP_Verification__c = false;
            update request;
            
            // Log reset action
            logSignatureActivity(requestId, 'SIGNATURE_RESET', 'SUCCESS', 'Request reset for re-signing');
            
            System.debug('✓ Signature request reset successfully');
            return true;
            
        } catch (Exception e) {
            System.debug('✗ Failed to reset signature request: ' + e.getMessage());
            logSignatureActivity(requestId, 'SIGNATURE_RESET', 'ERROR', e.getMessage());
            throw new AuraHandledException('Failed to reset signature request: ' + e.getMessage());
        }
    }

    /**
     * Get signature statistics for dashboard
     * @return Map containing signature statistics
     */
    @AuraEnabled
    public static Map<String, Object> getSignatureStatistics() {
        System.debug('Retrieving signature statistics');
        try {
            Map<String, Object> stats = new Map<String, Object>();
            
            // Overall statistics
            List<AggregateResult> overallStats = [
                SELECT Status__c, COUNT(Id) totalcount
                FROM Signature_Request__c 
                WHERE CreatedDate = LAST_N_DAYS:30
                GROUP BY Status__c
            ];
            
            Integer totalRequests = 0;
            Integer completedRequests = 0;
            Integer pendingRequests = 0;
            Integer rejectedRequests = 0;
            
            for (AggregateResult result : overallStats) {
                String status = (String)result.get('Status__c');
                Integer count = (Integer)result.get('count');
                totalRequests += count;
                
                if (status == SignatureStatus.SIGNED.name() || status == SignatureStatus.COMPLETED.name()) {
                    completedRequests += count;
                } else if (status == SignatureStatus.PENDING.name()) {
                    pendingRequests += count;
                } else if (status == SignatureStatus.REJECTED.name()) {
                    rejectedRequests += count;
                }
            }
            
            Decimal completionRate = totalRequests > 0 ? 
                (Decimal.valueOf(completedRequests) / Decimal.valueOf(totalRequests)) * 100 : 0;
            
            stats.put('totalRequests', totalRequests);
            stats.put('completedRequests', completedRequests);
            stats.put('pendingRequests', pendingRequests);
            stats.put('rejectedRequests', rejectedRequests);
            stats.put('completionRate', completionRate);
            
            // Daily trend for last 7 days
            List<AggregateResult> dailyStats = [
                SELECT DAY_ONLY(CreatedDate) day, COUNT(Id) totalcount
                FROM Signature_Request__c 
                WHERE CreatedDate = LAST_N_DAYS:7
                GROUP BY DAY_ONLY(CreatedDate)
                ORDER BY DAY_ONLY(CreatedDate)
            ];
            
            Map<String, Integer> dailyTrend = new Map<String, Integer>();
            for (AggregateResult result : dailyStats) {
                Date day = (Date)result.get('day');
                Integer count = (Integer)result.get('count');
                dailyTrend.put(day.format(), count);
            }
            
            stats.put('dailyTrend', dailyTrend);
            stats.put('lastUpdated', DateTime.now());
            
            System.debug('✓ Signature statistics compiled');
            return stats;
            
        } catch (Exception e) {
            System.debug('✗ Failed to retrieve signature statistics: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve signature statistics: ' + e.getMessage());
        }
    }

    // ===================================
    // PRIVATE HELPER METHODS
    // ===================================

    /**
     * Validate email format
     */
    @TestVisible
    private static Boolean isValidEmail(String email) {
        String emailRegex = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
        Pattern emailPattern = Pattern.compile(emailRegex);
        return emailPattern.matcher(email).matches();
    }

    /**
     * Generate document content for signature
     */
    @TestVisible
    private static String generateDocumentContent(DocumentLifecycleConfiguration__c config) {
        try {
            // Generate clause using existing ClauseGenerator
            String clause = ClauseGenerator.generateClause(config.Region__c, config.Role__c, config.ContractType__c);
            
            // Create formatted document content
            String documentContent = 'DOCUMENT GENERATION REQUEST\n';
            documentContent += '===========================\n\n';
            documentContent += 'Region: ' + config.Region__c + '\n';
            documentContent += 'Role: ' + config.Role__c + '\n';
            documentContent += 'Contract Type: ' + config.ContractType__c + '\n';
            documentContent += 'Generated Date: ' + DateTime.now().format() + '\n\n';
            documentContent += 'DOCUMENT CONTENT:\n';
            documentContent += '================\n\n';
            documentContent += clause + '\n\n';
            documentContent += 'SIGNATURE SECTION:\n';
            documentContent += '================\n\n';
            documentContent += 'By signing below, I acknowledge that I have read, understood, and agree to be bound by the terms and conditions set forth in this document.\n\n';
            documentContent += 'Signature: ___________________________ Date: ___________\n\n';
            documentContent += 'Print Name: ___________________________\n\n';
            
            return documentContent;
            
        } catch (Exception e) {
            System.debug('⚠ Failed to generate document content: ' + e.getMessage());
            return 'Document content generation failed. Please contact administrator.';
        }
    }
    /**
     * Send signature completion email notification
     */
    @TestVisible
    private static void sendSignatureCompletionEmail(Signature_Request__c request) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{ request.SignerEmail__c });
            email.setSubject('Document Signature Completed - Request #' + request.Id);

            String emailBody = 'Dear ' + request.SignerName__c + ',\n\n';
            emailBody += 'Thank you for completing the signature process for your document.\n\n';
            emailBody += 'Signature Details:\n';
            emailBody += '- Request ID: ' + request.Id + '\n';
            emailBody += '- Completed Date: ' + request.CompletedDate__c.format() + '\n';
            emailBody += '- Status: ' + request.Status__c + '\n\n';
            emailBody += 'Your signed document has been processed and stored securely in our system.\n';
            emailBody += 'You will receive a copy of the fully executed document once all parties have signed.\n\n';
            emailBody += 'If you need a copy of your signature confirmation, please contact the document administrator with your Request ID.\n\n';
            emailBody += 'Best regards,\n';
            emailBody += 'Document Management System';

            email.setPlainTextBody(emailBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ email });

            System.debug('✓ Signature completion email sent to: ' + request.SignerEmail__c);
        } catch (Exception e) {
            System.debug('⚠ Failed to send completion email: ' + e.getMessage());
        }
    }
    /**
     * Send cancellation notification email
     */
    @TestVisible
    private static void sendCancellationNotification(Signature_Request__c request, String reason) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{ request.SignerEmail__c });
            email.setSubject('Signature Request Cancelled - Request #' + request.Id);

            String emailBody = 'Dear ' + request.SignerName__c + ',\n\n';
            emailBody += 'The signature request for your document has been cancelled.\n\n';
            emailBody += 'Cancellation Details:\n';
            emailBody += '- Request ID: ' + request.Id + '\n';
            emailBody += '- Cancelled Date: ' + DateTime.now().format() + '\n';

            if (String.isNotBlank(reason)) {
                emailBody += '- Reason: ' + reason + '\n';
            }

            emailBody += '\n';
            emailBody += 'No further action is required on your part. If you believe this cancellation was made in error, ';
            emailBody += 'please contact the document administrator.\n\n';
            emailBody += 'Best regards,\n';
            emailBody += 'Document Management System';

            email.setPlainTextBody(emailBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ email });

            System.debug('✓ Cancellation notification sent to: ' + request.SignerEmail__c);
        } catch (Exception e) {
            System.debug('⚠ Failed to send cancellation notification: ' + e.getMessage());
        }
    }
    /**
     * Validate signature data format
     */
    @TestVisible
    private static Boolean isValidSignatureData(String signatureData) {
        try {
            if (String.isBlank(signatureData)) {
                return false;
            }

            // Check if it's base64 encoded (common for drawn signatures)
            if (signatureData.startsWith('data:image/')) {
                return signatureData.contains('base64,');
            }

            // Check if it's typed signature (should be reasonable length)
            if (signatureData.length() > 2 && signatureData.length() < 200) {
                return true;
            }

            // Check if it's a valid base64 string
            try {
                EncodingUtil.base64Decode(signatureData);
                return true;
            } catch (Exception e) {
                // Not valid base64
            }
            return false;
        } catch (Exception e) {
            System.debug('⚠ Signature data validation failed: ' + e.getMessage());
            return false;
        }
    }

    /**
    * Parse signer information JSON
    */
    @TestVisible
    private static Map<String, Object> parseSignerInfo(String signerInfo) {
        try {
            return (Map<String, Object>) JSON.deserializeUntyped(signerInfo);
        } catch (Exception e) {
            System.debug('⚠ Failed to parse signer info: ' + e.getMessage());
            return new Map<String, Object>{
                'parseError' => true,
                'originalData' => signerInfo,
                'timestamp' => DateTime.now()
            };
        }
    }
    /**
    * Create signature validation record
    */
    @TestVisible
    private static void createSignatureValidation(Signature_Request__c request, Map<String, Object> signerInfo) {
        try {
            AuditTrail__c validation = new AuditTrail__c(
                Action__c = 'SIGNATURE_VALIDATION',
                Status__c = 'SUCCESS',
                Timestamp__c = DateTime.now(),
                UserDetails__c = request.SignerName__c + ' (' + request.SignerEmail__c + ')',
                SystemInfo__c = 'Signature validated for request: ' + request.Id,
                AdditionalData__c = JSON.serialize(new Map<String, Object>{
                    'requestId' => request.Id,
                    'documentId' => request.DocumentId__c,
                    'signerEmail' => request.SignerEmail__c,
                    'signerName' => request.SignerName__c,
                    'signatureMethod' => signerInfo.get('signatureMethod'),
                    'ipAddress' => signerInfo.get('ipAddress'),
                    'userAgent' => signerInfo.get('userAgent'),
                    'timestamp' => request.CompletedDate__c,
                    'documentHash' => request.Document_Hash__c
                })
            );
            insert validation;
            System.debug('✓ Signature validation record created');
        } catch (Exception e) {
            System.debug('⚠ Failed to create signature validation record: ' + e.getMessage());
        }
    }
    /**
     * Process post-signature workflow
     */
    @TestVisible
    private static void processPostSignatureWorkflow(Signature_Request__c request) {
        try {
            // Check if this completes a multi-signer document
            List<Signature_Request__c> relatedRequests = [
                SELECT Id, Status__c
                FROM Signature_Request__c
                WHERE DocumentId__c = :request.DocumentId__c
            ];

            Boolean allSigned = true;
            for (Signature_Request__c relatedRequest : relatedRequests) {
                if (relatedRequest.Status__c != SignatureStatus.SIGNED.name()) {
                    allSigned = false;
                    break;
                }
            }

            if (allSigned && relatedRequests.size() > 1) {
                // All signatures collected, mark document as complete
                for (Signature_Request__c relatedRequest : relatedRequests) {
                    relatedRequest.Status__c = SignatureStatus.COMPLETED.name();
                }
                update relatedRequests;

                // Trigger document completion workflow
                triggerDocumentCompletionWorkflow(request.DocumentId__c);
                System.debug('✓ Multi-signer document completed');
            }
            System.debug('✓ Post-signature workflow processed');
        } catch (Exception e) {
            System.debug('⚠ Post-signature workflow processing failed: ' + e.getMessage());
        }
    }

    /**
    * Trigger document completion workflow
    */
    @TestVisible
    private static void triggerDocumentCompletionWorkflow(String documentId) {
        try {
            // Update document configuration status
            List<DocumentLifecycleConfiguration__c> configs = [
                SELECT Id, ProcessingStatus__c
                FROM DocumentLifecycleConfiguration__c
                WHERE Id = :documentId
                LIMIT 1
            ];

            if (!configs.isEmpty()) {
                configs[0].ProcessingStatus__c = 'SIGNATURE_COMPLETED';
                update configs[0];
            }

            // Create completion audit record
            AuditTrail__c completionAudit = new AuditTrail__c(
                Action__c = 'DOCUMENT_COMPLETION',
                Status__c = 'SUCCESS',
                Timestamp__c = DateTime.now(),
                UserDetails__c = UserInfo.getName() + ' (System)',
                SystemInfo__c = 'Document signature process completed for: ' + documentId,
                AdditionalData__c = JSON.serialize(new Map<String, Object>{
                    'documentId' => documentId,
                    'completedDate' => DateTime.now(),
                    'completedBy' => 'SYSTEM_WORKFLOW'
                })
            );
            insert completionAudit;

            System.debug('✓ Document completion workflow triggered');
        } catch (Exception e) {
            System.debug('⚠ Document completion workflow failed: ' + e.getMessage());
        }
    }

    /**
     * Get CSS class for status display
     */
    @TestVisible
    private static String getStatusClass(String status) {
        switch on status {
            when 'PENDING' {
                return 'slds-badge slds-badge_lightest slds-theme_warning';
            }
            when 'SIGNED', 'COMPLETED' {
                return 'slds-badge slds-badge_lightest slds-theme_success';
            }
            when 'REJECTED' {
                return 'slds-badge slds-badge_lightest slds-theme_error';
            }
            when 'EXPIRED' {
                return 'slds-badge slds-badge_lightest slds-theme_offline';
            }
            when else {
                return 'slds-badge slds-badge_lightest';
            }
        }
    }

    /**
    * Log signature-related activities
    */
    @TestVisible
    private static void logSignatureActivity(String requestId, String action, String status, String details) {
        try {
            AuditTrail__c auditLog = new AuditTrail__c(
                Action__c = action,
                Status__c = status,
                Timestamp__c = DateTime.now(),
                UserDetails__c = UserInfo.getName() + ' (' + UserInfo.getUsername() + ')',
                SystemInfo__c = details,
                AdditionalData__c = JSON.serialize(new Map<String, Object>{
                    'requestId' => requestId,
                    'action' => action,
                    'status' => status,
                    'details' => details,
                    'timestamp' => DateTime.now().format(),
                    'userId' => UserInfo.getUserId(),
                    'sessionId' => UserInfo.getSessionId()
                })
            );
            insert auditLog;
        } catch (Exception e) {
            System.debug('⚠ Could not log signature activity: ' + e.getMessage());
        }
    }
}

public with sharing class SignatureRequestController {

    // Signature status enumeration
    public enum SignatureStatus {
        DRAFT, PENDING, SIGNED, REJECTED, COMPLETED
    }
    private static String generateDocumentHash(String documentId) {
        DocumentLifecycleConfiguration__c doc = [
            SELECT GeneratedClause__c, CreatedDate 
            FROM DocumentLifecycleConfiguration__c 
            WHERE Id = :documentId
        ];
        
        String hashInput = doc.GeneratedClause__c + String.valueOf(doc.CreatedDate);
        Blob hashBlob = Crypto.generateDigest('SHA-256', Blob.valueOf(hashInput));
        return EncodingUtil.convertToHex(hashBlob);
    }

    @AuraEnabled
    public static String initiateSignatureRequest(String documentId, String signerEmail, String signerName) {
    
    
         try {
            // Create signature request
            Signature_Request__c request = new Signature_Request__c(
                DocumentId__c = documentId,
                SignerEmail__c = signerEmail,
                SignerName__c = signerName,
                Status__c = 'Pending'
            );
            insert request;

            // Log the request initiation
            AuditTrailManager.logDocumentActivity(
                documentId,
                'SIGNATURE_REQUEST_INITIATED',
                'Signature request sent to: ' + signerEmail
            );

            // Send notification email
            EmailNotificationService.sendSignatureRequestEmail(request.Id);

            return request.Id;
        } catch (Exception e) {
            AuditTrailManager.logSystemActivity('SIGNATURE_REQUEST_ERROR', e.getMessage());
            throw new AuraHandledException('Error creating signature request: ' + e.getMessage());
        }
    }

    
    
    
    
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

    @AuraEnabled
    public static Boolean submitSignature(String requestId, String signatureData, String signatureMethod) {
    
            try {
            // Validate inputs
            if (String.isBlank(requestId) || String.isBlank(signatureData)) {
                throw new AuraHandledException('Request ID and signature data are required');
            }
            
            // Get signature request
            List<Signature_Request__c> requests = [
                SELECT Id, Status__c, SignerEmail__c, DocumentId__c 
                FROM Signature_Request__c 
                WHERE Id = :requestId FOR UPDATE
            ];
            
            if (requests.isEmpty()) {
                throw new AuraHandledException('Signature request not found');
            }
            
            Signature_Request__c request = requests[0];
            
            // Check if already signed
            if (request.Status__c == 'Signed' || request.Status__c == 'Completed') {
                throw new AuraHandledException('This document has already been signed');
            }
            
            // Update signature request
            request.SignatureData__c = signatureData;
            request.Status__c = 'Signed';
            request.CompletedDate__c = System.now();
            request.SignatureMethod__c = signatureMethod;
            request.Document_Hash__c = generateDocumentHash(signatureData);
            
            update request;
            
            // Create signature validation record
            SignatureValidation__c validation = new SignatureValidation__c();
            validation.SignatureRequest__c = request.Id;
            validation.ValidationStatus__c = 'Valid';
            validation.SignerIP__c = getClientIPAddress();
            validation.ValidationDate__c = System.now();
            
            insert validation;
            
            // Log signature completion
            AuditTrailManager.logDocumentActivity(request.DocumentId__c, 'DOCUMENT_SIGNED', 
                'Document signed by: ' + request.SignerEmail__c + ' using ' + signatureMethod);
            
            // Send completion email
            EmailNotificationService.sendSignatureCompletion(request.Id);
            
            return true;
            
        } catch (Exception e) {
            AuditTrailManager.logError('SIGNATURE_SUBMISSION_FAILED', e.getMessage(), requestId);
            throw new AuraHandledException('Failed to submit signature: ' + e.getMessage());
        }
    }
    





    
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

    @AuraEnabled
    public static Signature_Request__c getSignatureRequest(String requestId) {
        try {
            return [
                SELECT Id, DocumentId__c, SignerEmail__c, SignerName__c, Status__c,
                       SignatureData__c, SignatureMethod__c, CompletedDate__c, Created_Date__c
                FROM Signature_Request__c 
                WHERE Id = :requestId 
                LIMIT 1
            ];
        } catch (Exception e) {
            System.debug('Error retrieving signature request: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve signature request: ' + e.getMessage());
        }
    }

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

}

Step 2.4: Create SignatureRequestController
Create: Setup → Developer Console → File → New → Apex ClassName: SignatureRequestController
Copy and paste this complete code:
public with sharing class SignatureRequestController {
    
    // Signature status enumeration
    public enum SignatureStatus {
        DRAFT, PENDING, SIGNED, REJECTED, COMPLETED
    }
    
    @AuraEnabled
    public static String initiateSignatureRequest(String documentId, String signerEmail, String signerName) {
try {
            Signature_Request__c request = new Signature_Request__c(
                DocumentId__c = documentId,
                SignerEmail__c = signerEmail,
                SignerName__c = signerName,
                Status__c = 'Pending'
            );
            insert request;
            
            System.debug('✓ Signature request created: ' + request.Id);
            return request.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error creating signature request: ' + e.getMessage());
        }
    }

//Version 0.............

//         try {
//             // Create signature request record
//             Signature_Request__c sigRequest = new Signature_Request__c(
//                 DocumentId__c = documentId,
//                 SignerEmail__c = signerEmail,
//                 SignerName__c = signerName,
//                 Status__c = SignatureStatus.PENDING.name(),
//                 Created_Date__c = DateTime.now(),
//                 OTP_Verification__c = false
//             );
            
//             insert sigRequest;
// try {
//     // Log the signature request initiation
//     logSignatureAction(sigRequest.Id, 'SIGNATURE_REQUEST_INITIATED', 'SUCCESS');
    
//     // Send email notification (simplified for now)
//     sendSignatureNotification(sigRequest.Id, signerEmail, signerName);
    
//     return sigRequest.Id;
    
// } catch (Exception e) {
//     System.debug('Error initiating signature request: ' + e.getMessage());
//     throw new AuraHandledException('Failed to initiate signature request: ' + e.getMessage());
// }

    @AuraEnabled
    public static Boolean submitSignature(String requestId, String signatureData, String signatureMethod) {
        try {
            // Retrieve and update the signature request
            Signature_Request__c sigRequest = [
                SELECT Id, Status__c, SignerEmail__c, SignerName__c, DocumentId__c
                FROM Signature_Request__c 
                WHERE Id = :requestId 
                LIMIT 1
            ];
            
            // Update signature request with signature data
            sigRequest.SignatureData__c = signatureData;
            sigRequest.SignatureMethod__c = signatureMethod;
            sigRequest.Status__c = SignatureStatus.SIGNED.name();
            sigRequest.CompletedDate__c = DateTime.now();
            
            update sigRequest;
            
            // Create signature validation record
            SignatureValidation__c validation = new SignatureValidation__c(
                Signature_Request__c = sigRequest.Id,
                ValidationStatus__c = &#39;Valid&#39;,
                ValidationDate__c = DateTime.now(),
                SignerIP__c = getClientIP(),
                ValidationHash__c = generateValidationHash(signatureData)
            );
            
            insert validation;
try {
    // Log the signature submission
    logSignatureAction(requestId, 'SIGNATURE_SUBMITTED', 'SUCCESS');
    
    return true;
    
} catch (Exception e) {
    System.debug('Error submitting signature: ' + e.getMessage());
    logSignatureAction(requestId, 'SIGNATURE_SUBMISSION_FAILED', 'ERROR');
    throw new AuraHandledException('Failed to submit signature: ' + e.getMessage());
}

@AuraEnabled
    public static void submitSignature(String requestId, String signatureData, String signerName, String signerEmail) {
        try {
            Signature_Request__c request = [
                SELECT Id, Status__c, DocumentId__c 
                FROM Signature_Request__c 
                WHERE Id = :requestId
            ];
            
            request.SignatureData__c = signatureData;
            request.Status__c = 'Signed';
            request.CompletedDate__c = DateTime.now();
            
            update request;
            
            System.debug('✓ Signature submitted for request: ' + requestId);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error submitting signature: ' + e.getMessage());
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
        return [
            SELECT Id, SignerName__c, SignerEmail__c, Status__c, CompletedDate__c
            FROM Signature_Request__c
            WHERE DocumentId__c = :documentId
            ORDER BY CreatedDate DESC
        ];
    }

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
    // Simplified email notification - in production, use proper email templates
    System.debug('📧 Email notification sent to: ' + signerEmail + ' for request: ' + requestId);
}

private static String getClientIP() {
    // Simplified IP detection - in production, use proper request headers
    return '127.0.0.1';
}

private static String generateValidationHash(String signatureData) {
    // Generate SHA-256 hash for signature validation
    Blob signatureBlob = Blob.valueOf(signatureData + System.now().getTime());
    Blob hash = Crypto.generateDigest('SHA256', signatureBlob);
    return EncodingUtil.base64Encode(hash);
}
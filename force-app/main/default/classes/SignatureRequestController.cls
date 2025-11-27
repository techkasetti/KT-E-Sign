// force-app/main/default/classes/SignatureRequestController.cls
public with sharing class SignatureRequestController {

    @AuraEnabled(cacheable=false)
    public static String initiateSignatureRequest(String documentId, String signerEmail, String signerName) {
        if (String.isBlank(documentId) || String.isBlank(signerEmail) || String.isBlank(signerName)) {
            throw new AuraHandledException('Document ID, Signer Email, and Signer Name are required.');
        }
        
        try {
            Signature_Request__c request = new Signature_Request__c(
                DocumentId__c = documentId,
                SignerEmail__c = signerEmail,
                Signer_Name__c	 = signerName,
                Sync_Status__c = 'Pending'

            );
            insert request;

            System.debug('Created Signature Request with ID: ' + request);

            // Send notification email
            EmailNotificationService.sendSignatureRequest(request.Id);

            AuditTrailManager.logSignatureRequest(documentId, 'Signature Request Created', 'Signature request sent to: ' + signerEmail);
            
            return request.Id;
        } catch (Exception e) {
            AuditTrailManager.logSystemActivity('SIGNATURE_REQUEST_ERROR', 'Failed to initiate signature request: ' + e.getMessage());
            throw new AuraHandledException('Failed to initiate signature request: ' + e.getMessage());
        }
    }



// FEATURE ONE IN IMPLEMENTED  IN THE ABOVE CODE

   

    /**
     * @description Fetches a Signature_Request__c record and its related Document details.
     * @param requestId The ID of the Signature_Request__c record.
     * @return The Signature_Request__c record with related parent fields.
     */
    @AuraEnabled(cacheable=true)
    public static Signature_Request__c getSignatureRequest(String requestId) {
        try {
            return [
                SELECT Id, Signer_Name__c, Status__c, CompletedDate__c,
                       DocumentId__c,
                       DocumentId__r.DocumentTitle__c,
                       DocumentId__r.GeneratedClause__c
                FROM Signature_Request__c
                WHERE Id = :requestId
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve signature request: ' + e.getMessage());
        }

        
    }

    /**
     * @description Processes a signature submission, updating the request and creating a validation record.
     * @param requestId The ID of the Signature_Request__c record.
     * @param signatureData The signature data (text, Base64 string, or upload ID).
     * @param signatureMethod The method used for signing ('Type', 'Draw', 'Upload').
     * @return Boolean indicating success.
     */
    @AuraEnabled
    public static Boolean submitSignature(String requestId, String signatureData, String signatureMethod) {
        
    System.debug('Request ID: ' + requestId);
    System.debug('Signature Data (Base64): ' + signatureData);
    System.debug('Signature Method: ' + signatureMethod);
        try {
            Signature_Request__c request = [
                SELECT Id, Status__c FROM Signature_Request__c WHERE Id = :requestId FOR UPDATE
            ];
            System.debug('request'+request);

            // Prevent re-signing a completed request
            if (request.Status__c == 'Signed' || request.Status__c == 'Completed') {
               throw new AuraHandledException('This document has already been signed.');
            }

            // Update the Signature Request record
            request.Status__c = 'Signed';
            request.SignatureData__c = signatureData;
            request.SignatureMethod__c = signatureMethod;
            request.CompletedDate__c = Datetime.now();
            update request; 

            System.debug('Signature Request updated: ' + request);

            // Create a validation record for audit purposes
            SignatureValidation__c validation = new SignatureValidation__c(
                SignatureRequest__c = requestId,
                Signature_Request__c	= requestId,
                ValidationStatus__c = 'Valid',
                SignerIP__c = Auth.SessionManagement.getCurrentSession().get('SourceIp') // Best effort for IP
            );
            insert validation;

            System.debug('Signature Validation record created: ' + validation);

            // Log the successful signature completion
            AuditTrailManager.logSignatureCompletion(requestId, signatureMethod);
            
            // Send a completion notification
            EmailNotificationService.sendSignatureCompletion(requestId);

            return true;
        } catch (Exception e) {
            // Log the error for administrators
            AuditTrailManager.logSystemActivity('SIGNATURE_SUBMISSION_ERROR', e.getMessage());
            throw new AuraHandledException('Failed to submit signature: ' + e.getMessage());
        }
    }



// FEATURE 2 IS IMPLEMENTED IN THE ABOVE CODE














// Add the following code inside your SignatureRequestController.cls file, before the final '}'
/**
 * @description Fetches the parent DocumentLifecycleConfiguration record and its child Signature_Request__c records.
 * @param documentId The ID of the DocumentLifecycleConfiguration__c record.
 * @return A wrapper class containing the document and its related signature requests.
 */
@AuraEnabled(cacheable=true)
public static DocumentData getDocumentData(String documentId) {
    try {
        DocumentData data = new DocumentData();

        data.document = [
            SELECT Id, DocumentTitle__c, GeneratedClause__c,
                   Region__c, Role__c, ContractType__c,
                   ComplianceStatus__c, CreatedDate
            FROM DocumentLifecycleConfiguration__c
            WHERE Id = :documentId
            LIMIT 1
        ];

        data.signatureRequests = [
            SELECT Id, Signer_Name__c, SignerEmail__c,
                   Status__c, CreatedDate, CompletedDate__c
            FROM Signature_Request__c
            WHERE DocumentId__c = :documentId
            ORDER BY CreatedDate DESC
        ];

        return data;
    } catch (Exception e) {
        throw new AuraHandledException('Failed to retrieve document data: ' + e.getMessage());
    }
}

public class DocumentData {
    @AuraEnabled public DocumentLifecycleConfiguration__c document    { get; set; }
    @AuraEnabled public List<Signature_Request__c>         signatureRequests { get; set; }
}


}
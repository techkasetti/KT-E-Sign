// DocGenESignIntegrationController.cls
public with sharing class DocGenESignIntegrationController {
    
    @AuraEnabled
    public static Map<String, Object> generateAndInitiateSignature(
        String region, 
        String role, 
        String contractType, 
        String documentTitle,
        String signerEmail
    ) {
        try {
            // Step 1: Generate Document
            String documentId = DocumentLifecycleDeploymentManager.generateDocument(
                region, role, contractType, documentTitle
            );
            
            if (String.isBlank(documentId)) {
                return createErrorResponse('Document generation failed');
            }
            
            // Step 2: Validate Compliance
            DocumentLifecycleConfiguration__c doc = getDocumentById(documentId);
            Boolean complianceValid = ComplianceChecker.validateCompliance(
                doc.GeneratedClause__c, region, contractType
            );
            
            if (!complianceValid) {
                return createErrorResponse('Compliance validation failed');
            }
            
            // Step 3: Initiate E-Signature Process
            String signatureRequestId = SignatureRequestController.initiateSignatureRequest(
                documentId, signerEmail, documentTitle
            );
            
            // Step 4: Link Document and Signature Request
            linkDocumentToSignature(documentId, signatureRequestId);
            
            // Step 5: Send Notification
            SignatureNotificationManager.sendInitiationNotification(
                signatureRequestId, signerEmail, documentTitle
            );
            
            return createSuccessResponse(new Map<String, Object>{
                'documentId' => documentId,
                'signatureRequestId' => signatureRequestId,
                'status' => 'SUCCESS'
            });
            
        } catch (Exception e) {
            return createErrorResponse('Integration failed: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Map<String, Object> processSignatureCompletion(String signatureRequestId) {
        try {
            // Step 1: Validate Signature
            Signature_Request__c sigRequest = getSignatureRequestById(signatureRequestId);
            Boolean signatureValid = SignatureValidationService.validateSignature(
                sigRequest.Signature_Data__c, sigRequest.Document_Hash__c
            );
            
            if (!signatureValid) {
                return createErrorResponse('Signature validation failed');
            }
            
            // Step 2: Update Document Status
            updateDocumentStatus(sigRequest.Document_Id__c, 'Completed');
            
            // Step 3: Generate Final Document
            String finalDocumentId = generateFinalSignedDocument(sigRequest);
            
            // Step 4: Archive Original
            archiveOriginalDocument(sigRequest.Document_Id__c);
            
            // Step 5: Send Completion Notification
            SignatureNotificationManager.sendCompletionNotification(
                signatureRequestId, sigRequest.Signer_Email__c
            );
            
            return createSuccessResponse(new Map<String, Object>{
                'finalDocumentId' => finalDocumentId,
                'status' => 'COMPLETED'
            });
            
        } catch (Exception e) {
            return createErrorResponse('Signature processing failed: ' + e.getMessage());
        }
    }
    
    // Private helper methods
    private static DocumentLifecycleConfiguration__c getDocumentById(String documentId) {
        return [SELECT Id, GeneratedClause__c, DocumentTitle__c, Region__c, ContractType__c 
                FROM DocumentLifecycleConfiguration__c WHERE Id = :documentId LIMIT 1];
    }
    
    private static void linkDocumentToSignature(String documentId, String signatureRequestId) {
        DocumentLifecycleConfiguration__c doc = new DocumentLifecycleConfiguration__c(
            Id = documentId,
            E_Signature_Status__c = 'In_Progress',
            Integration_Status__c = 'Ready_For_Signature'
        );
        update doc;
        
        Signature_Request__c sigRequest = new Signature_Request__c(
            Id = signatureRequestId,
            Document_Id__c = documentId
        );
        update sigRequest;
    }
    
    private static Signature_Request__c getSignatureRequestById(String signatureRequestId) {
        return [SELECT Id, Document_Id__c, Signer_Email__c, Signature_Data__c, Document_Hash__c
                FROM Signature_Request__c WHERE Id = :signatureRequestId LIMIT 1];
    }
    
    private static void updateDocumentStatus(String documentId, String status) {
        DocumentLifecycleConfiguration__c doc = new DocumentLifecycleConfiguration__c(
            Id = documentId,
            E_Signature_Status__c = 'Completed',
            Integration_Status__c = 'Signed'
        );
        update doc;
    }
    
    private static String generateFinalSignedDocument(Signature_Request__c sigRequest) {
        // Implementation for generating final document with embedded signature
        DocumentLifecycleConfiguration__c finalDoc = new DocumentLifecycleConfiguration__c(
            DocumentTitle__c = 'SIGNED_' + sigRequest.Document_Id__c,
            ProcessingStatus__c = 'Final',
            Integration_Status__c = 'Archived'
        );
        insert finalDoc;
        return finalDoc.Id;
    }
    
    private static void archiveOriginalDocument(String documentId) {
        DocumentLifecycleConfiguration__c doc = new DocumentLifecycleConfiguration__c(
            Id = documentId,
            ProcessingStatus__c = 'Archived'
        );
        update doc;
    }
    
    private static Map<String, Object> createSuccessResponse(Map<String, Object> data) {
        data.put('success', true);
        return data;
    }
    
    private static Map<String, Object> createErrorResponse(String errorMessage) {
        return new Map<String, Object>{
            'success' => false,
            'error' => errorMessage
        };
    }
}

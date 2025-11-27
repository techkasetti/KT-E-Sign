@RestResource(urlMapping='/api/v1/signature-requests/*')
global class ESignatureAPIController {
    
    // @HttpGet
    // global static SignatureRequestResponse getSignatureRequest() {
    //     RestRequest req = RestContext.request;
    //     String requestId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
        
    //     // Rate limiting check
    //     if (!APISecurityManager.checkRateLimit(UserInfo.getUserId())) {
    //         RestContext.response.statusCode = 429;
    //         return new SignatureRequestResponse('Rate limit exceeded', null);
    //     }
        
    //     try {
    //         Signature_Request__c sigRequest = [SELECT Id, SignerEmail__c, Status__c, 
    //                                          DocumentId__c FROM Signature_Request__c 
    //                                          WHERE Id = :requestId];
            
    //         return new SignatureRequestResponse('Success', sigRequest);
    //     } catch (Exception e) {
    //         RestContext.response.statusCode = 404;
    //         return new SignatureRequestResponse('Signature request not found', null);
    //     }
    // }
    
   
    // public static Map<String, Object> createSignatureRequest() {
    //     try {
    //         // Rate limit check
    //         if (!APISecurityManager.checkRateLimit(UserInfo.getUserId())) {
    //             RestContext.response.statusCode = 429;
    //             return new Map<String, Object>{'error' => 'Rate limit exceeded'};
    //         }
    //         // Authorization check
    //         if (!APISecurityManager.validateAPIAccess()) {
    //             RestContext.response.statusCode = 401;
    //             return new Map<String, Object>{'error' => 'Access denied'};
    //         }

    //         String body = RestContext.request.requestBody.toString();
    //         if (String.isBlank(body)) {
    //             RestContext.response.statusCode = 400;
    //             return new Map<String, Object>{'error' => 'Empty request body'};
    //         }

    //         Map<String,Object> payload = (Map<String,Object>) JSON.deserializeUntyped(body);
    //         String documentId = (String) payload.get('documentId');
    //         String signerEmail = (String) payload.get('signerEmail');
    //         String signerName = (String) payload.get('signerName');

    //         if (String.isBlank(documentId) || String.isBlank(signerEmail)) {
    //             RestContext.response.statusCode = 400;
    //             return new Map<String, Object>{'error' => 'Missing required fields: documentId or signerEmail'};
    //         }

    //         Signature_Request__c req = new Signature_Request__c(
    //             DocumentId__c = documentId,
    //             SignerEmail__c = signerEmail,
    //             SignerName__c = signerName,
    //             Status__c = 'Pending'
    //         );
    //         insert req;

    //         // Log
    //         AuditTrailManager.logSystemActivity('API_SIGNATURE_CREATE', 'Created request ' + req.Id);
            
    //         RestContext.response.statusCode = 201;
    //         return new Map<String,Object>{ 'id' => req.Id, 'status' => 'Created' };

    //     } catch (Exception e) {
    //         AuditTrailManager.logSystemActivity('API_SIGNATURE_CREATE_ERROR', e.getMessage());
    //         RestContext.response.statusCode = 500;
    //         return new Map<String, Object>{'error' => 'Server error: ' + e.getMessage()};
    //     }
    // }

    // // Inner class for response structure
    // global class SignatureRequestResponse {
    //     global String message;
    //     global Signature_Request__c data;

    //     global SignatureRequestResponse(String message, Signature_Request__c data) {
    //         this.message = message;
    //         this.data = data;
    //     }
    // }
}
@RestResource(urlMapping='/api/v1/signature-requests/*')
global class ESignatureAPIController {
    
    @HttpGet
    global static SignatureRequestResponse getSignatureRequest() {
        RestRequest req = RestContext.request;
        String requestId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
        
        // Rate limiting check
        if (!APISecurityManager.checkRateLimit(UserInfo.getUserId())) {
            RestContext.response.statusCode = 429;
            return new SignatureRequestResponse('Rate limit exceeded', null);
        }
        
        try {
            Signature_Request__c sigRequest = [SELECT Id, SignerEmail__c, Status__c, 
                                             DocumentId__c FROM Signature_Request__c 
                                             WHERE Id = :requestId];
            
            return new SignatureRequestResponse('Success', sigRequest);
        } catch (Exception e) {
            RestContext.response.statusCode = 404;
            return new SignatureRequestResponse('Signature request not found', null);
        }
    }
    
   @HttpPost
    global static APIResponse createSignatureRequest() {
        try {
            // Rate limit check
            if (!APISecurityManager.checkRateLimit(UserInfo.getUserId())) {
                return new APIResponse(429, 'Rate limit exceeded', null);
            }
            // Authorization check
            if (!APISecurityManager.validateAPIAccess()) {
                return new APIResponse(401, 'Access denied', null);
            }

            String body = RestContext.request.requestBody.toString();
            if (String.isBlank(body)) {
                return new APIResponse(400, 'Empty request body', null);
            }

            Map<String,Object> payload = (Map<String,Object>) JSON.deserializeUntyped(body);
            String documentId = (String) payload.get('documentId');
            String signerEmail = (String) payload.get('signerEmail');
            String signerName = (String) payload.get('signerName');

            if (String.isBlank(documentId) || String.isBlank(signerEmail)) {
                return new APIResponse(400, 'Missing required fields: documentId or signerEmail', null);
            }

            Signature_Request__c req = new Signature_Request__c(
                DocumentId__c = documentId,
                SignerEmail__c = signerEmail,
                SignerName__c = signerName,
                Status__c = 'Pending'
            );
            insert req;

            // Log
            AuditTrailManager.logSystemActivity('API_SIGNATURE_CREATE', 'Created request ' + req.Id);

            return new APIResponse(201, 'Created', new Map<String,Object>{ 'id' => req.Id });

        } catch (Exception e) {
            AuditTrailManager.logSystemActivity('API_SIGNATURE_CREATE_ERROR', e.getMessage());
            return new APIResponse(500, 'Server error: ' + e.getMessage(), null);
        }
    }
}

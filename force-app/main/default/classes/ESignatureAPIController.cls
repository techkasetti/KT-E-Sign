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
    global static SignatureRequestResponse createSignatureRequest(SignatureRequestData requestData) {
        // Validate API access
        if (!APISecurityManager.validateAPIAccess()) {
            RestContext.response.statusCode = 401;
            return new SignatureRequestResponse('Unauthorized', null);
        }
        
        try {
            Signature_Request__c newRequest = new Signature_Request__c();
            newRequest.SignerEmail__c = requestData.signerEmail;
            newRequest.DocumentId__c = requestData.documentId;
            newRequest.Status__c = 'Pending';
            
            insert newRequest;
            
            return new SignatureRequestResponse('Created successfully', newRequest);
        } catch (Exception e) {
            RestContext.response.statusCode = 400;
            return new SignatureRequestResponse('Error creating request: ' + e.getMessage(), null);
        }
    }
}

public class SignatureRequestAPI {
    
    
    // public static APIResponse getSignatureRequest() {
    //     try {
    //         String requestId = RestContext.request.requestURI.substringAfterLast('/');
            
    //         // Rate limiting check
    //         if (!APISecurityManager.checkRateLimit(UserInfo.getUserId())) {
    //             return new APIResponse(429, 'Rate limit exceeded', null);
    //         }
            
    //         Signature_Request__c request = [
    //             SELECT Id, Document_Id__c, Signer_Email__c, Signer_Name__c, 
    //                    Status__c, Signature_Data__c, Completion_Date__c,
    //                    Document_Hash__c, Signature_Method__c, IP_Address__c
    //             FROM Signature_Request__c 
    //             WHERE Id = :requestId
    //             LIMIT 1
    //         ];
            
    //         return new APIResponse(200, 'Success', request);
    //     } catch (Exception e) {
    //         return new APIResponse(500, 'Internal server error: ' + e.getMessage(), null);
    //     }
    // }
    
    
    // public static APIResponse createSignatureRequest() {
    //     try {
    //         // Validate API access
    //         if (!APISecurityManager.validateAPIAccess()) {
    //             return new APIResponse(403, 'Access denied', null);
    //         }
            
    //         String requestBody = RestContext.request.requestBody.toString();
    //         Map<String, Object> requestData = (Map<String, Object>)JSON.deserializeUntyped(requestBody);
            
    //         // Create signature request
    //         Signature_Request__c newRequest = new Signature_Request__c(
    //             Document_Id__c = (String)requestData.get('documentId'),
    //         Signer_Email__c = (String)requestData.get('signerEmail'),
    //         Signer_Name__c = (String)requestData.get('signerName'),
    //         Status__c = 'Pending',
    //         Request_Date__c = System.now(),
    //         IP_Address__c = RestContext.request.headers.get('X-Forwarded-For')
    //             );
            
            
                
            
    //         insert newRequest;
            
    //         // Send signature request email
    //         EmailNotificationService.sendSignatureRequestEmail(newRequest.Id);
            
    //         // Log audit trail
    //         AuditTrailManager.logDocumentActivity(
    //             newRequest.Document_Id__c,
    //         'SIGNATURE_REQUEST_CREATED',
    //         'Signature request created for ' + newRequest.Signer_Email__c
    //             );
            
    //         return new APIResponse(201, 'Signature request created successfully', newRequest);
            
    //     } catch (Exception e) {
    //         AuditTrailManager.logSystemActivity('API_ERROR', 'Signature request creation failed: ' + e.getMessage());
    //         return new APIResponse(500, 'Failed to create signature request: ' + e.getMessage(), null);
    //     }
    // }
    
    
    // public static APIResponse updateSignatureRequest() {
    //     try {
    //         String requestId = RestContext.request.requestURI.substringAfterLast('/');
    //         String requestBody = RestContext.request.requestBody.toString();
    //         Map<String, Object> updateData = (Map<String, Object>)JSON.deserializeUntyped(requestBody);
            
    //         // Validate request exists
    //         Signature_Request__c existingRequest = [
    //         SELECT Id, Status__c, Document_Hash__c 
    //         FROM Signature_Request__c 
    //         WHERE Id = :requestId 
    //         LIMIT 1
    //     ];
            
    //         // Update signature data
    //         if (updateData.containsKey('signatureData')) {
    //             existingRequest.Signature_Data__c = (String)updateData.get('signatureData');
    //             existingRequest.Status__c = 'Completed';
    //             existingRequest.Completion_Date__c = System.now().date();
    //             existingRequest.IP_Address__c = RestContext.request.headers.get('X-Forwarded-For');
                
    //             // Validate document integrity
    //             String providedHash = (String)updateData.get('documentHash');
    //             if (providedHash != existingRequest.Document_Hash__c) {
    //                 return new APIResponse(400, 'Document integrity check failed', null);
    //             }
    //         }
            
    //         update existingRequest;
            
    //         // Trigger completion workflow if signed
    //         if (existingRequest.Status__c == 'Completed') {
    //             // Send completion notifications
    //             EmailNotificationService.sendSignatureCompletionEmail(existingRequest.Id);
                
    //             // Create signature validation record
    //             SignatureValidation__c validation = new SignatureValidation__c(
    //                 Signature_Request__c = existingRequest.Id,
    //             Validation_Status__c = 'Valid',
    //             Validation_Date__c = System.now(),
    //             SignerIP__c = existingRequest.IP_Address__c,
    //             Validation_Method__c = 'API_SUBMISSION'
    //                 );
    //             insert validation;
    //         }
            
    //         return new APIResponse(200, 'Signature request updated successfully', existingRequest);
            
    //     } catch (Exception e) {
    //         return new APIResponse(500, 'Update failed: ' + e.getMessage(), null);
    //     }
    // }
}
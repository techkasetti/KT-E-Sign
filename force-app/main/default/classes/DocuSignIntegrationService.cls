public class DocuSignIntegrationService {
    // // Timeout settings
    // private static final Integer PDF_TIMEOUT_MS = 60000;
    // private static final Integer DOCUSIGN_TIMEOUT_MS = 60000;

    // // DocuSign API endpoints and Named Credential
    // private static final String DOCUSIGN_API_NAMED_CREDENTIAL = 'callout:DocuSign_Production_API';
    // private static final String USER_INFO_ENDPOINT = '/oauth/userinfo';

    // // DocuSign account configuration
    // private static String accountId;
    // private static String baseUrl;

    // static {
    //     initializeDocuSignConfiguration();
    // }

    // /**
    //  * Custom exception for DocuSign operations
    //  */
    // public class DocuSignException extends Exception {}

    // /**
    //  * Initializes DocuSign configuration by getting the account ID and base URL.
    //  */
    // private static void initializeDocuSignConfiguration() {
    //     // In a test context, avoid making a callout.
    //     if (Test.isRunningTest()) {
    //         accountId = 'TEST_ACCOUNT_ID';
    //         baseUrl = 'https://demo.docusign.net/restapi';
    //         return;
    //     }

    //     try {
    //         HttpRequest req = new HttpRequest();
    //         req.setEndpoint(DOCUSIGN_API_NAMED_CREDENTIAL + USER_INFO_ENDPOINT);
    //         req.setMethod('GET');
    //         req.setHeader('Accept', 'application/json');
    //         req.setTimeout(30000);

    //         Http http = new Http();
    //         HttpResponse res = http.send(req);

    //         if (res.getStatusCode() == 200) {
    //             Map<String, Object> userInfo = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    //             List<Object> accounts = (List<Object>) userInfo.get('accounts');
    //             if (accounts != null && !accounts.isEmpty()) {
    //                 Map<String, Object> account = (Map<String, Object>) accounts[0];
    //                 accountId = (String) account.get('account_id');
    //                 baseUrl = (String) account.get('base_uri') + '/restapi';
    //             }
    //         } else {
    //              throw new CalloutException('Failed to initialize DocuSign configuration. Status: ' + res.getStatus() + ' Body: ' + res.getBody());
    //         }
    //     } catch (Exception e) {
    //         System.debug(LoggingLevel.ERROR, 'DocuSign configuration error: ' + e.getMessage() + '. Falling back to demo account details.');
    //         // Fallback for non-test, non-production environments.
    //         // Replace with a more robust configuration method for production.
    //         accountId = 'DEMO_ACCOUNT_ID';
    //         baseUrl = 'https://demo.docusign.net/restapi';
    //     }
    // }

    // /**
    //  * Asynchronously converts HTML to a Base64 encoded PDF and queues the envelope for sending via DocuSign.
    //  * @param signerEmail The email of the signer.
    //  * @param signerName The name of the signer.
    //  * @param htmlContent The HTML content of the document.
    //  * @param subject The email subject for the DocuSign request.
    //  * @param docName The name of the document file.
    //  * @return A string indicating the job was 'QUEUED'.
    //  */
    // @AuraEnabled
    // public static String queueDocumentForSigning(String signerEmail, String signerName, String htmlContent, String subject, String docName) {
    //     if (String.isBlank(signerEmail) || String.isBlank(htmlContent)) {
    //         throw new AuraHandledException('Missing email or document content.');
    //     }
    //     String base64Pdf = convertToBase64PDF(htmlContent);
    //     System.enqueueJob(new SendEnvelopeJob(signerEmail, signerName, base64Pdf, subject, docName));
    //     return 'QUEUED';
    // }

    // /**
    //  * Creates and sends a DocuSign envelope directly.
    //  * @param documentId The Salesforce ID of the DocumentLifecycleConfiguration record.
    //  * @param signerEmail The email of the signer.
    //  * @param signerName The name of the signer.
    //  * @param documentContent The document content to be sent.
    //  * @return A result object containing the status and envelope ID.
    //  */
    // @AuraEnabled
    // public static DocuSignEnvelopeResult createAndSendEnvelope(String documentId, String signerEmail, String signerName, String documentContent) {
    //     try {
    //         DocumentLifecycleConfiguration__c document = [
    //             SELECT Id, DocumentTitle__c, ContractType__c
    //             FROM DocumentLifecycleConfiguration__c
    //             WHERE Id = :documentId
    //             LIMIT 1
    //         ];

    //         Map<String, Object> envelopeRequest = buildEnvelopeRequest(document, signerEmail, signerName, documentContent);

    //         HttpRequest req = new HttpRequest();
    //         req.setEndpoint(baseUrl + '/v2.1/accounts/' + accountId + '/envelopes');
    //         req.setMethod('POST');
    //         req.setHeader('Content-Type', 'application/json');
    //         req.setBody(JSON.serialize(envelopeRequest));
    //         req.setTimeout(DOCUSIGN_TIMEOUT_MS);

    //         Http http = new Http();
    //         HttpResponse res = http.send(req);

    //         DocuSignEnvelopeResult result = new DocuSignEnvelopeResult();
    //         result.success = res.getStatusCode() >= 200 && res.getStatusCode() < 300;

    //         if (result.success) {
    //             Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    //             result.envelopeId = (String) responseData.get('envelopeId');
    //             result.status = (String) responseData.get('status');
    //             result.uri = (String) responseData.get('uri');

    //             updateSignatureRequestWithEnvelopeId(documentId, result.envelopeId);
    //             AuditTrailManager.logDocumentActivity(documentId, 'DOCUSIGN_ENVELOPE_CREATED', 'Envelope ID: ' + result.envelopeId);
    //         } else {
    //             result.errorMessage = 'DocuSign API Error: ' + res.getStatus() + ' - ' + res.getBody();
    //             AuditTrailManager.logSystemActivity('DOCUSIGN_INTEGRATION_FAILED', 'Error: ' + result.errorMessage);
    //         }
    //         return result;
    //     } catch (Exception e) {
    //         DocuSignEnvelopeResult errorResult = new DocuSignEnvelopeResult();
    //         errorResult.success = false;
    //         errorResult.errorMessage = 'Integration exception: ' + e.getMessage();
    //         AuditTrailManager.logSystemActivity('DOCUSIGN_INTEGRATION_EXCEPTION', e.getMessage());
    //         return errorResult;
    //     }
    // }

    // /**
    //  * Handles incoming webhook notifications from DocuSign to update signature status.
    //  * @param webhookData The JSON payload from the DocuSign webhook.
    //  */
    // @AuraEnabled
    // public static void handleDocuSignWebhook(String webhookData) {
    //     try {
    //         Map<String, Object> webhook = (Map<String, Object>) JSON.deserializeUntyped(webhookData);
    //         Map<String, Object> data = (Map<String, Object>) webhook.get('data');
            
    //         if (data == null) return;
            
    //         Map<String, Object> envelopeSummary = (Map<String, Object>) data.get('envelopeSummary');
    //         if (envelopeSummary == null) return;

    //         String envelopeId = (String) data.get('envelopeId');
    //         String status = (String) envelopeSummary.get('status');
            
    //         if (String.isBlank(envelopeId) || String.isBlank(status)) return;

    //         List<Signature_Request__c> requests = [
    //             SELECT Id, DocumentId__c, Status__c
    //             FROM Signature_Request__c
    //             WHERE DocuSignEnvelopeId__c = :envelopeId LIMIT 1
    //         ];

    //         if (!requests.isEmpty()) {
    //             Signature_Request__c request = requests[0];
    //             String oldStatus = request.Status__c;

    //             switch on status {
    //                 when 'completed' {
    //                     request.Status__c = 'Signed';
    //                     request.CompletedDate__c = System.now();
    //                     NotificationService.sendSignatureCompletionNotification(request.Id);
    //                 }
    //                 when 'declined' {
    //                     request.Status__c = 'Rejected';
    //                      NotificationService.sendSignatureRejectionNotification(request.Id, 'Declined via DocuSign');
    //                 }
    //                 when 'voided' {
    //                     request.Status__c = 'Cancelled';
    //                 }
    //                 when 'delivered', 'sent' {
    //                     if(request.Status__c != 'Signed' && request.Status__c != 'Completed') {
    //                        request.Status__c = 'Pending';
    //                     }
    //                 }
    //             }
                
    //             if (request.Status__c != oldStatus) {
    //                 request.IntegrationStatus__c = 'Updated from DocuSign';
    //                 update request;
    //                 AuditTrailManager.logDocumentActivity(request.DocumentId__c, 'DOCUSIGN_WEBHOOK_RECEIVED', 'Status updated to: ' + request.Status__c);
    //             }
    //         } else {
    //             AuditTrailManager.logSystemActivity('DOCUSIGN_WEBHOOK_UNKNOWN_ENVELOPE', 'Envelope ID not found: ' + envelopeId);
    //         }
    //     } catch (Exception e) {
    //         AuditTrailManager.logSystemActivity('DOCUSIGN_WEBHOOK_PROCESSING_ERROR', e.getMessage() + ' | Payload: ' + webhookData);
    //     }
    // }

    // // --- HELPER METHODS ---

    // /**
    //  * Builds the JSON payload for a DocuSign envelope request.
    //  */
    // private static Map<String, Object> buildEnvelopeRequest(DocumentLifecycleConfiguration__c document, String signerEmail, String signerName, String documentContent) {
    //     String base64Pdf = convertToBase64PDF(documentContent);

    //     Map<String, Object> doc = new Map<String, Object>{
    //         'documentId' => '1',
    //         'name' => document.DocumentTitle__c + '.pdf',
    //         'documentBase64' => base64Pdf,
    //         'fileExtension' => 'pdf'
    //     };

    //     Map<String, Object> signHereTab = new Map<String, Object>{
    //         'documentId' => '1',
    //         'pageNumber' => '1',
    //         'xPosition' => '100',
    //         'yPosition' => '100'
    //     };

    //     Map<String, Object> signer = new Map<String, Object>{
    //         'email' => signerEmail,
    //         'name' => signerName,
    //         'recipientId' => '1',
    //         'routingOrder' => '1',
    //         'tabs' => new Map<String, Object>{'signHereTabs' => new List<Object>{signHereTab}}
    //     };

    //     Map<String, Object> textCustomField = new Map<String, Object>{
    //         'name' => 'SalesforceDocumentId',
    //         'value' => document.Id,
    //         'show' => 'false'
    //     };
        
    //     return new Map<String, Object>{
    //         'emailSubject' => 'Please sign: ' + document.DocumentTitle__c,
    //         'documents' => new List<Object>{ doc },
    //         'recipients' => new Map<String, Object>{'signers' => new List<Object>{ signer }},
    //         'customFields' => new Map<String, Object>{'textCustomFields' => new List<Object>{textCustomField}},
    //         'status' => 'sent'
    //     };
    // }

    // /**
    //  * Builds the JSON payload for a DocuSign envelope to be used by the Queueable job.
    //  */
    // private static Map<String, Object> buildDocuSignEnvelopePayload(String base64Pdf, String docName, String signerEmail, String signerName) {
    //     Map<String, Object> doc = new Map<String, Object>{
    //         'documentId' => '1',
    //         'name' => docName,
    //         'documentBase64' => base64Pdf,
    //         'fileExtension' => 'pdf'
    //     };

    //     Map<String, Object> signHereTab = new Map<String, Object>{
    //         'documentId' => '1',
    //         'pageNumber' => '1',
    //         'xPosition' => '100',
    //         'yPosition' => '100'
    //     };

    //     Map<String, Object> signer = new Map<String, Object>{
    //         'email' => signerEmail,
    //         'name' => signerName,
    //         'recipientId' => '1',
    //         'routingOrder' => '1',
    //         'tabs' => new Map<String, Object>{'signHereTabs' => new List<Object>{signHereTab}}
    //     };

    //     return new Map<String, Object>{
    //         'emailSubject' => 'Please sign: ' + docName,
    //         'documents' => new List<Object>{ doc },
    //         'recipients' => new Map<String, Object>{'signers' => new List<Object>{ signer }},
    //         'status' => 'sent'
    //     };
    // }

    // /**
    //  * Converts HTML content to a Base64 encoded PDF string by calling an external service.
    //  */
    // public static String convertToBase64PDF(String htmlContent) {
    //     if (String.isBlank(htmlContent)) {
    //         throw new AuraHandledException('Document content is required for PDF conversion.');
    //     }

    //     HttpRequest req = new HttpRequest();
    //     req.setEndpoint('callout:PDF_Service/convert'); // Requires a Named Credential named "PDF_Service"
    //     req.setMethod('POST');
    //     req.setHeader('Content-Type', 'application/json');
    //     req.setBody(JSON.serialize(new Map<String, Object>{'html' => htmlContent}));
    //     req.setTimeout(PDF_TIMEOUT_MS);

    //     try {
    //         Http http = new Http();
    //         HttpResponse res = http.send(req);
    //         if (res.getStatusCode() == 200) {
    //             Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    //             if (responseBody != null && responseBody.containsKey('base64Pdf')) {
    //                 return (String) responseBody.get('base64Pdf');
    //             }
    //             throw new CalloutException('PDF service returned a valid response but did not contain the "base64Pdf" key.');
    //         }
    //         throw new CalloutException('PDF service returned an error: ' + res.getStatusCode() + ' - ' + res.getBody());
    //     } catch(Exception e) {
    //         System.debug(LoggingLevel.ERROR, 'PDF conversion callout failed: ' + e.getMessage());
    //         throw new AuraHandledException('Failed to generate PDF from content. ' + e.getMessage());
    //     }
    // }

    // /**
    //  * Associates a DocuSign Envelope ID with the corresponding Signature Request record.
    //  */
    // private static void updateSignatureRequestWithEnvelopeId(String documentId, String envelopeId) {
    //     List<Signature_Request__c> requests = [
    //         SELECT Id
    //         FROM Signature_Request__c
    //         WHERE DocumentId__c = :documentId
    //         ORDER BY CreatedDate DESC LIMIT 1
    //     ];
    //     if (!requests.isEmpty()) {
    //         requests[0].DocuSignEnvelopeId__c = envelopeId;
    //         requests[0].IntegrationStatus__c = 'Sent to DocuSign';
    //         update requests[0];
    //     }
    // }

    // // --- INNER CLASSES FOR QUEUEABLE JOB ---

    // /**
    //  * Queueable job to send a DocuSign envelope asynchronously.
    //  */
    // public class SendEnvelopeJob implements Queueable, Database.AllowsCallouts {
    //     private String signerEmail, signerName, base64Pdf, subject, docName;

    //     public SendEnvelopeJob(String signerEmail, String signerName, String base64Pdf, String subject, String docName) {
    //         this.signerEmail = signerEmail;
    //         this.signerName = signerName;
    //         this.base64Pdf = base64Pdf;
    //         this.subject = subject;
    //         this.docName = docName;
    //     }

    //     public void execute(QueueableContext context) {
    //         try {
    //             Map<String,Object> payload = buildDocuSignEnvelopePayload(base64Pdf, docName, signerEmail, signerName);
                
    //             HttpRequest req = new HttpRequest();
    //             req.setEndpoint(baseUrl + '/v2.1/accounts/' + accountId + '/envelopes');
    //             req.setMethod('POST');
    //             req.setHeader('Content-Type','application/json');
    //             req.setBody(JSON.serialize(payload));
    //             req.setTimeout(DOCUSIGN_TIMEOUT_MS);
                
    //             Http http = new Http();
    //             HttpResponse res = http.send(req);
                
    //             if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
    //                  AuditTrailManager.logSystemActivity('DOCUSIGN_SEND_ERROR', 'HTTP ' + res.getStatusCode() + ' - ' + res.getBody());
    //             }
    //         } catch (Exception e) {
    //              AuditTrailManager.logSystemActivity('DOCUSIGN_QUEUE_ERROR', e.getMessage());
    //         }
    //     }
    // }

    // // --- DTO (Data Transfer Object) CLASSES ---

    // public class DocuSignEnvelopeResult {
    //     @AuraEnabled public Boolean success;
    //     @AuraEnabled public String envelopeId;
    //     @AuraEnabled public String status;
    //     @AuraEnabled public String uri;
    //     @AuraEnabled public String errorMessage;
    // }

    // public class DocuSignStatusResult {
    //     @AuraEnabled public Boolean success;
    //     @AuraEnabled public String status;
    //     @AuraEnabled public String envelopeId;
    //     @AuraEnabled public String createdDateTime;
    //     @AuraEnabled public String completedDateTime;
    //     @AuraEnabled public String errorMessage;
    // }
}
public class DocuSignIntegrationService {
    // Timeout settings
      private static final Integer PDF_TIMEOUT_MS = 60000;
    private static final Integer DOCUSIGN_TIMEOUT_MS = 60000;
     

    @TestVisible static String DOCUSIGN_ACCOUNT_ID = null; 
       public class DocuSignException extends Exception {}
    
    // DocuSign API endpoints
    private static final String DOCUSIGN_BASE_URL = 'callout:DocuSign_Production_API';
    private static final String ENVELOPE_ENDPOINT = '/restapi/v2.1/accounts/{accountId}/envelopes';
    private static final String TEMPLATE_ENDPOINT = '/restapi/v2.1/accounts/{accountId}/templates';
    private static final String USER_INFO_ENDPOINT = '/oauth/userinfo';
    
    // DocuSign account configuration
    private static String accountId;
    private static String baseUrl;
    
    static {
        initializeDocuSignConfiguration();
    }
    
    /**
     * Initialize DocuSign configuration
     */
    private static void initializeDocuSignConfiguration() {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(DOCUSIGN_BASE_URL + USER_INFO_ENDPOINT);
            req.setMethod('GET');
            req.setHeader('Accept', 'application/json');
            req.setTimeout(30000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> userInfo = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> accounts = (List<Object>) userInfo.get('accounts');
                
                if (!accounts.isEmpty()) {
                    Map<String, Object> account = (Map<String, Object>) accounts[0];
                    accountId = (String) account.get('account_id');
                    baseUrl = (String) account.get('base_uri') + '/restapi';
                }
            }
        } catch (Exception e) {
            System.debug('DocuSign configuration error: ' + e.getMessage());
            // Fallback to demo account
            accountId = 'DEMO_ACCOUNT_ID'; // TODO: Replace with actual demo account ID
            baseUrl = 'https://demo.docusign.net/restapi';
        }
    }
     public static Map<String,Object> buildDocuSignEnvelopePayload(String base64Pdf, String documentName, String signerEmail, String signerName) {
        Map<String,Object> doc = new Map<String,Object>{
            'documentBase64' => base64Pdf,
            'name' => documentName,
            'fileExtension' => 'pdf',
            'documentId' => '1'
        };

        // Simple anchor tab example using an anchor string placed in the HTML '/sn1/'
        Map<String,Object> signHere = new Map<String,Object>{
            'anchorString' => '/sn1/',
            'anchorUnits' => 'pixels',
            'anchorYOffset' => '0',
            'anchorXOffset' => '0'
        };

        Map<String,Object> signer = new Map<String,Object>{
            'email' => signerEmail,
            'name'  => signerName,
            'recipientId' => '1',
            'routingOrder' => '1',
            'tabs' => new Map<String,Object>{ 'signHereTabs' => new List<Object>{ signHere } }
        };

        Map<String,Object> recipients = new Map<String,Object>{ 'signers' => new List<Object>{ signer } };

        Map<String,Object> envelope = new Map<String,Object>{
            'emailSubject' => 'Please sign the document',
            'documents' => new List<Object>{ doc },
            'recipients' => recipients,
            'status' => 'sent' // "created" if you want to save draft (not sent)
        };

        return envelope;
    }

    public static String sendEnvelope(String signerEmail, String signerName, String documentTitle, String base64Pdf) {
        if (String.isBlank(signerEmail) || String.isBlank(base64Pdf)) {
            throw new DocuSignException('Missing required envelope parameters');
        }

        Map<String,Object> doc = new Map<String,Object>{
            'documentBase64' => base64Pdf,
            'name' => documentTitle,
            'fileExtension' => 'pdf',
            'documentId' => '1'
        };
        Map<String,Object> signer = new Map<String,Object>{
            'email' => signerEmail,
            'name' => signerName,
            'recipientId' => '1',
            'routingOrder' => '1'
        };
        Map<String,Object> recipients = new Map<String,Object>{ 'signers' => new List<Object>{ signer } };
        Map<String,Object> bodyMap = new Map<String,Object>{
            'documents' => new List<Object>{ doc },
            'emailSubject' => 'Please sign: ' + documentTitle,
            'recipients' => recipients,
            'status' => 'sent'
        };

        String acct = DOCUSIGN_ACCOUNT_ID;
        if (String.isBlank(acct)) acct = 'DEMO_ACCOUNT_ID'; // fallback for dev only

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:DocuSign_API/accounts/' + acct + '/envelopes');
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        req.setBody(JSON.serialize(bodyMap));
        req.setTimeout(120000);

        Integer attempts = 0;
        Integer maxAttempts = 3;
        while (attempts < maxAttempts) {
            attempts++;
            try {
                Http http = new Http();
                HttpResponse res = http.send(req);
                if (res.getStatusCode() == 201 || (res.getStatusCode() >= 200 && res.getStatusCode() < 300)) {
                    try {
                        Map<String,Object> parsed = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
                        if (parsed.containsKey('envelopeId')) return (String) parsed.get('envelopeId');
                    } catch(Exception je) {
                        // Some providers return header location instead; fallthrough to generic success case
                        // Return success without envelopeId is risky — surface an error:
                        throw new DocuSignException('DocuSign success response missing envelopeId: ' + res.getBody());
                    }
                } else {
                    if (res.getStatusCode() >= 500 && attempts < maxAttempts) {
                        System.debug('DocuSign server error, retry ' + attempts + ' status ' + res.getStatusCode());
                        // small wait not available in Apex, continue loop
                        continue;
                    }
                    throw new DocuSignException('DocuSign error: ' + res.getStatus() + ' body:' + res.getBody());
                }
            } catch (CalloutException ce) {
                if (attempts >= maxAttempts) throw new DocuSignException('DocuSign callout failed: ' + ce.getMessage());
                System.debug('DocuSign callout exception (retrying): ' + ce.getMessage());
            }
        }
        throw new DocuSignException('DocuSign envelope creation failed after retries');
    }
 @AuraEnabled
    public static String queueDocumentForSigning(String signerEmail, String signerName, String htmlContent, String subject, String docName) {
        if (String.isBlank(signerEmail) || String.isBlank(htmlContent)) {
            throw new AuraHandledException('Missing email or document content');
        }
        String base64Pdf = convertToBase64PDF(htmlContent);
        System.enqueueJob(new SendEnvelopeJob(signerEmail, signerName, base64Pdf, subject, docName));
        return 'QUEUED';
    }


    /**
     * Create and send DocuSign envelope
     */
    @AuraEnabled
    public static DocuSignEnvelopeResult createAndSendEnvelope(
        String documentId, 
        String signerEmail, 
        String signerName,
        String documentTitle,
        String documentContent
    ) {
        try {
            // Get document details
            DocumentLifecycleConfiguration__c document = [
                SELECT Id, DocumentTitle__c, GeneratedClause__c, ContractType__c, Region__c
                FROM DocumentLifecycleConfiguration__c 
                WHERE Id = :documentId 
                LIMIT 1
            ];
            
            // Create envelope request
            Map<String, Object> envelopeRequest = buildEnvelopeRequest(
                document, signerEmail, signerName, documentContent
            );
            
            // Send to DocuSign
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/v2.1/accounts/' + accountId + '/envelopes');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');
            req.setBody(JSON.serialize(envelopeRequest));
            req.setTimeout(60000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            DocuSignEnvelopeResult result = new DocuSignEnvelopeResult();
            result.success = res.getStatusCode() >= 200 && res.getStatusCode() < 300;
            
            if (result.success) {
                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                result.envelopeId = (String) responseData.get('envelopeId');
                result.status = (String) responseData.get('status');
                result.uri = (String) responseData.get('uri');
                
                // Update signature request with DocuSign envelope ID
                updateSignatureRequestWithEnvelopeId(documentId, result.envelopeId);
                
                // Log successful integration
                AuditTrailManager.createAuditEntry(
                    documentId,
                    'DocuSign Envelope Created',
                    'Success',
                    'Envelope ID: ' + result.envelopeId + ', Status: ' + result.status
                );
                
            } else {
                result.errorMessage = 'DocuSign API Error: ' + res.getStatus() + ' - ' + res.getBody();
                
                // Log integration failure
                AuditTrailManager.createAuditEntry(
                    documentId,
                    'DocuSign Integration Failed',
                    'Error',
                    'Status: ' + res.getStatusCode() + ', Error: ' + res.getBody()
                );
            }
            
            return result;
            
        } catch (Exception e) {
            DocuSignEnvelopeResult errorResult = new DocuSignEnvelopeResult();
            errorResult.success = false;
            errorResult.errorMessage = 'Integration exception: ' + e.getMessage();
            
            // Log exception
            AuditTrailManager.createAuditEntry(
                documentId,
                'DocuSign Integration Exception',
                'Error',
                e.getMessage() + '\n' + e.getStackTraceString()
            );
            
            return errorResult;
        }
    }
    
    /**
     * Build DocuSign envelope request payload
     */
    private static Map<String, Object> buildEnvelopeRequest(
        DocumentLifecycleConfiguration__c document,
        String signerEmail,
        String signerName,
        String documentContent
    ) {
        Map<String, Object> envelope = new Map<String, Object>();
        
        // Envelope properties
        envelope.put('emailSubject', 'Please sign: ' + document.DocumentTitle__c);
        envelope.put('emailBlurb', 'Please review and sign the attached document.');
        envelope.put('status', 'sent'); // Send immediately
        
        // Document
        List<Map<String, Object>> documents = new List<Map<String, Object>>();
        Map<String, Object> doc = new Map<String, Object>();
        doc.put('documentId', '1');
        doc.put('name', document.DocumentTitle__c + '.pdf');
        doc.put('documentBase64', convertToBase64PDF(documentContent));
        doc.put('fileExtension', 'pdf');
        documents.add(doc);
        envelope.put('documents', documents);
        
        // Recipients
        Map<String, Object> recipients = new Map<String, Object>();
        List<Map<String, Object>> signers = new List<Map<String, Object>>();
        
        Map<String, Object> signer = new Map<String, Object>();
        signer.put('email', signerEmail);
        signer.put('name', signerName);
        signer.put('recipientId', '1');
        signer.put('routingOrder', '1');
        
        // Add signature tabs
        Map<String, Object> tabs = new Map<String, Object>();
        List<Map<String, Object>> signHereTabs = new List<Map<String, Object>>();
        
        Map<String, Object> signTab = new Map<String, Object>();
        signTab.put('documentId', '1');
        signTab.put('pageNumber', '1');
        signTab.put('xPosition', '100');
        signTab.put('yPosition', '100');
        signTab.put('width', '200');
        signTab.put('height', '50');
        signHereTabs.add(signTab);
        
        tabs.put('signHereTabs', signHereTabs);
        signer.put('tabs', tabs);
        
        signers.add(signer);
        recipients.put('signers', signers);
        envelope.put('recipients', recipients);
        
        // Custom fields for tracking
        List<Map<String, Object>> customFields = new List<Map<String, Object>>();
        Map<String, Object> salesforceField = new Map<String, Object>();
        salesforceField.put('name', 'SalesforceDocumentId');
        salesforceField.put('value', document.Id);
        salesforceField.put('show', 'false');
        customFields.add(salesforceField);
        
        Map<String, Object> contractTypeField = new Map<String, Object>();
        contractTypeField.put('name', 'ContractType');
        contractTypeField.put('value', document.ContractType__c);
        contractTypeField.put('show', 'false');
        customFields.add(contractTypeField);
        
        envelope.put('customFields', new Map<String, Object>{ 'textCustomFields' => customFields });
        
        return envelope;
    }
    public static String convertHtmlToBase64Pdf(String htmlContent) {
try {
// PageReference to a Visualforce page that renders the HTML into PDF.
PageReference pdfPage = Page.DocuSign_PDF_Template;
if (pdfPage == null) {
throw new AuraHandledException('Missing Visualforce page: DocuSign_PDF_Template');
}
pdfPage.getParameters().put('html', htmlContent);
// getContentAsPDF must run synchronously and can throw callout/timeout exceptions.
Blob pdfBlob = pdfPage.getContentAsPDF();
return EncodingUtil.base64Encode(pdfBlob);
} catch (Exception e) {
// If VF rendering fails, fallback to an external PDF generation service (not implemented here).
throw new AuraHandledException('PDF generation failed: ' + e.getMessage());
}
}
    /**
     * Convert document content to Base64 PDF
     * DEVELOPER TODO: Implement PDF conversion logic based on your document format
     * This is a stub that needs completion
     */
    // Convert HTML/text content to PDF base64 using Visualforce renderAs (server side).
// This implementation assumes you can create a VF page Visualforce/Template that accepts content.
// DocuSignIntegrationService - helper
public static String convertToBase64PDF(String htmlContent) {
        if (String.isBlank(htmlContent)) {
            throw new AuraHandledException('Document content required');
        }
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:PDF_Service/convert'); // configure this Named Credential
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        req.setBody(JSON.serialize(new Map<String,Object>{ 'html' => htmlContent }));
        req.setTimeout(PDF_TIMEOUT_MS);
        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            Map<String,Object> b = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
            if (b.containsKey('base64Pdf')) return (String) b.get('base64Pdf');
            throw new CalloutException('PDF service returned no base64Pdf');
        }
        throw new CalloutException('PDF service error: ' + res.getStatusCode() + ' - ' + res.getBody());
    }


    // Create an envelope (example). Use Named Credential "DocuSign_NC" with base URL/auth configured
    public static String createEnvelope(String accountId, String base64Pdf, String signerEmail, String signerName) {
        String endpoint = URL.getSalesforceBaseUrl().toExternalForm(); // not used if Named Credential
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:DocuSign_NC/v2.1/accounts/' + accountId + '/envelopes');
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        Map<String,Object> payload = new Map<String,Object>{
            'emailSubject' => 'Please sign',
            'documents' => new List<Object>{ new Map<String,Object>{
                'documentBase64' => base64Pdf,
                'name' => 'Document.pdf',
                'fileExtension' => 'pdf',
                'documentId' => '1'
            }},
            'recipients' => new Map<String,Object>{ 'signers' => new List<Object>{ new Map<String,Object>{
                'email' => signerEmail,
                'name' => signerName,
                'recipientId' => '1',
                'routingOrder' => '1'
            }}},
            'status' => 'sent'
        };
        req.setBody(JSON.serialize(payload));
        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            Map<String,Object> r = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
            return (String) r.get('envelopeId');
        }
        throw new CalloutException('DocuSign envelope create failed: ' + res.getStatus() + ' ' + res.getBody());
    }


    
    /**
     * Update signature request with DocuSign envelope ID
     */
    private static void updateSignatureRequestWithEnvelopeId(String documentId, String envelopeId) {
        List<Signature_Request__c> requests = [
            SELECT Id FROM Signature_Request__c 
            WHERE DocumentId__c = :documentId 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        
        if (!requests.isEmpty()) {
            requests[0].DocuSignEnvelopeId__c = envelopeId;
            requests[0].IntegrationStatus__c = 'Sent to DocuSign';
            update requests[0];
        }
    }
    
    /**
     * Get envelope status from DocuSign
     */
    @AuraEnabled
    public static DocuSignStatusResult getEnvelopeStatus(String envelopeId) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/v2.1/accounts/' + accountId + '/envelopes/' + envelopeId);
            req.setMethod('GET');
            req.setHeader('Accept', 'application/json');
            req.setTimeout(30000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            DocuSignStatusResult result = new DocuSignStatusResult();
            result.success = res.getStatusCode() == 200;
            
            if (result.success) {
                Map<String, Object> envelope = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                result.status = (String) envelope.get('status');
                result.createdDateTime = (String) envelope.get('createdDateTime');
                result.completedDateTime = (String) envelope.get('completedDateTime');
                result.envelopeId = envelopeId;
            } else {
                result.errorMessage = 'Status check failed: ' + res.getBody();
            }
            
            return result;
            
        } catch (Exception e) {
            DocuSignStatusResult errorResult = new DocuSignStatusResult();
            errorResult.success = false;
            errorResult.errorMessage = 'Status check exception: ' + e.getMessage();
            return errorResult;
        }
    }
    
    /**
     * Webhook handler for DocuSign status updates
     */
@AuraEnabled
public static void handleDocuSignWebhook(String webhookData) {
    try {
        // Deserialize incoming JSON
        Map<String, Object> webhook = (Map<String, Object>) JSON.deserializeUntyped(webhookData);
        Map<String, Object> data = (Map<String, Object>) webhook.get('data');
        
        String envelopeId = (String) data.get('envelopeId');
        String status = (String) data.get('envelopeSummary.status'); // ⚠️ check JSON format here
        
        // Find corresponding signature request
        List<Signature_Request__c> requests = [
            SELECT Id, DocumentId__c, Status__c, DocuSignEnvelopeId__c, CompletedDate__c, IntegrationStatus__c
            FROM Signature_Request__c 
            WHERE DocuSignEnvelopeId__c = :envelopeId 
            LIMIT 1
        ];
        
        if (!requests.isEmpty()) {
            Signature_Request__c request = requests[0];
            
            // Update status based on DocuSign status
            switch on status {
                when 'completed' {
                    request.Status__c = 'Signed';
                    request.CompletedDate__c = System.now();
                }
                when 'declined' {
                    request.Status__c = 'Rejected';
                }
                when 'voided' {
                    request.Status__c = 'Cancelled';
                }
                when 'delivered', 'sent' {
                    request.Status__c = 'Pending';
                }
            }
            
            request.IntegrationStatus__c = 'Updated from DocuSign';
            update request;
            
            // Log webhook processing
            AuditTrailManager.createAuditEntry(
                request.DocumentId__c, 
                'DocuSign Webhook Received',
                'Success',
                'Envelope ID: ' + envelopeId + 
                ', Status: ' + status + 
                ', Updated Salesforce Status: ' + request.Status__c
            );

            // Send notification based on status
            if (status == 'completed') {
                NotificationService.sendSignatureCompletionNotification(request.Id);
            } else if (status == 'declined' || status == 'voided') {
                NotificationService.sendSignatureRejectionNotification(request.Id);
            }
        } else {
            // Log webhook for unknown envelope
            AuditTrailManager.createAuditEntry(
                null,
                'DocuSign Webhook - Unknown Envelope',
                'Warning',
                'Received webhook for envelope ID: ' + envelopeId + ' which is not found in Salesforce'
            );
        }

    } catch (Exception e) {
        // Log webhook processing error
        AuditTrailManager.createAuditEntry(
            null,
            'DocuSign Webhook Processing Error',
            'Error',
            'Error: ' + e.getMessage() + '\nWebhook Data: ' + webhookData
        );
    }
}


    // Result wrapper classes
    public class DocuSignEnvelopeResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String envelopeId;
        @AuraEnabled public String status;
        @AuraEnabled public String uri;
        @AuraEnabled public String errorMessage;
    }

    public class DocuSignStatusResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String status;
        @AuraEnabled public String envelopeId;
        @AuraEnabled public String createdDateTime;
        @AuraEnabled public String completedDateTime;
        @AuraEnabled public String errorMessage;
    }

    // Custom exception for DocuSign operations
    public class DocuSignException extends Exception {}
}

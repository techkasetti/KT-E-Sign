public class DocuSignIntegrationService {
    
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
    
    /**
     * Convert document content to Base64 PDF
     * DEVELOPER TODO: Implement PDF conversion logic based on your document format
     * This is a stub that needs completion
     */
    private static String convertToBase64PDF(String documentContent) {
        // TODO: DEVELOPER IMPLEMENTATION REQUIRED
        // This method should convert the document content to a properly formatted PDF
        // and return the Base64 encoded string
        // 
        // Options:
        // 1. Use Salesforce's built-in PDF generation capabilities
        // 2. Integrate with external PDF generation service
        // 3. Use document templates and merge fields
        
        // PLACEHOLDER IMPLEMENTATION:
        String pdfContent = 'JVBERi0xLjQKJcfsj6IKNSAwIG9iago8PAovTGVuZ3RoIDYgMCBSCi9GaWx0ZXIgL0ZsYXRlRGVjb2RlCj4+CnN0cmVhbQp4nDMwMFAwULA1MABCYyNjc2MLA3Pg3xd8GJkYmJkBOsYmBWABJiZmCoYGRiAFxkZmBGmZGZpZGJqZmVsAm...';
        
        // TODO: Replace with actual PDF generation
        System.debug('WARNING: convertToBase64PDF method needs implementation');
        System.debug('Document content length: ' + documentContent.length());
        
        return pdfContent;
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

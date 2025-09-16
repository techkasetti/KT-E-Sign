public class IntegrationConfigurationService {
    
    // Integration endpoints and settings
    private static final String DOCUSIGN_BASE_URL = 'https://demo.docusign.net/restapi';
    private static final String ADOBE_SIGN_BASE_URL = 'https://api.adobesign.com/api/rest/v6';
    private static final String HELLOSIGN_BASE_URL = 'https://api.hellosign.com/v3';
    
    // Named credentials for security
    private static final String DOCUSIGN_CREDENTIAL = 'DocuSign_Integration';
    private static final String ADOBE_CREDENTIAL = 'Adobe_Sign_Integration';
    private static final String HELLOSIGN_CREDENTIAL = 'HelloSign_Integration';
    
    /**
     * Initialize DocuSign integration
     */
    @AuraEnabled
    public static Map<String, Object> initializeDocuSignIntegration(Map<String, String> credentials) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            // Validate credentials
            if (!validateDocuSignCredentials(credentials)) {
                result.put('success', false);
                result.put('error', 'Invalid DocuSign credentials provided');
                return result;
            }
            
            // Test connection
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:' + DOCUSIGN_CREDENTIAL + '/accounts');
            request.setMethod('GET');
            request.setHeader('Accept', 'application/json');
            request.setHeader('Authorization', 'Bearer ' + credentials.get('accessToken'));
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                // Parse account information
                Map<String, Object> responseData = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                List<Object> accounts = (List<Object>)responseData.get('accounts');
                
                if (!accounts.isEmpty()) {
                    Map<String, Object> account = (Map<String, Object>)accounts[0];
                    
                    // Store integration settings
                    IntegrationSetting__c setting = new IntegrationSetting__c();
                    setting.Name = 'DocuSign_Configuration';
                    setting.Provider__c = 'DocuSign';
                    setting.IsActive__c = true;
                    setting.AccountId__c = (String)account.get('accountId');
                    setting.BaseURL__c = (String)account.get('baseUri');
                    setting.LastTestDate__c = System.now();
                    setting.Status__c = 'ACTIVE';
                    
                    upsert setting Name;
                    
                    result.put('success', true);
                    result.put('accountId', account.get('accountId'));
                    result.put('accountName', account.get('accountName'));
                    result.put('baseUri', account.get('baseUri'));
                    
                    // Log successful integration setup
                    AuditTrailManager.logAPIActivity(
                        'DocuSign Account Validation',
                        'GET',
                        200,
                        '',
                        response.getBody(),
                        response.getStatusCode().longValue()
                    );
                }
            } else {
                result.put('success', false);
                result.put('error', 'DocuSign connection failed: ' + response.getBody());
                
                // Log failed integration
                AuditTrailManager.logAPIActivity(
                    'DocuSign Integration Failed',
                    'GET',
                    response.getStatusCode(),
                    '',
                    response.getBody(),
                    0
                );
            }
            
        } catch (Exception e) {
            result.put('success', false);
            result.put('error', 'Integration initialization failed: ' + e.getMessage());
            
            AuditTrailManager.createAuditEntry(
                null,
                'DOCUSIGN_INIT_ERROR',
                'ERROR',
                'DocuSign initialization exception: ' + e.getMessage()
            );
        }
        
        return result;
    }
    
    /**
     * Send document to DocuSign for signature
     */
    @AuraEnabled
    public static String sendToDocuSign(String documentId, String signerEmail, String signerName) {
        try {
            // Get integration settings
            IntegrationSetting__c docuSignSettings = getIntegrationSettings('DocuSign');
            if (docuSignSettings == null || !docuSignSettings.IsActive__c) {
                throw new AuraHandledException('DocuSign integration not configured');
            }
            
            // Get document details
            DocumentLifecycleConfiguration__c doc = [
                SELECT Id, DocumentTitle__c, GeneratedContent__c, ContractType__c
                FROM DocumentLifecycleConfiguration__c
                WHERE Id = :documentId
                LIMIT 1
            ];
            
            // Create envelope request
            Map<String, Object> envelopeRequest = new Map<String, Object>();
            envelopeRequest.put('emailSubject', 'Please sign: ' + doc.DocumentTitle__c);
            envelopeRequest.put('status', 'sent');
            
            // Add document
            List<Map<String, Object>> documents = new List<Map<String, Object>>();
            Map<String, Object> document = new Map<String, Object>();
            document.put('documentBase64', EncodingUtil.base64Encode(Blob.valueOf(doc.GeneratedContent__c)));
            document.put('name', doc.DocumentTitle__c + '.pdf');
            document.put('fileExtension', 'pdf');
            document.put('documentId', '1');
            documents.add(document);
            envelopeRequest.put('documents', documents);
            
            // Add recipients
            List<Map<String, Object>> signers = new List<Map<String, Object>>();
            Map<String, Object> signer = new Map<String, Object>();
            signer.put('email', signerEmail);
            signer.put('name', signerName);
            signer.put('recipientId', '1');
            signer.put('routingOrder', '1');
            
            // Add signature tabs
            Map<String, Object> tabs = new Map<String, Object>();
            List<Map<String, Object>> signHereTabs = new List<Map<String, Object>>();
            Map<String, Object> signHere = new Map<String, Object>();
            signHere.put('documentId', '1');
            signHere.put('pageNumber', '1');
            signHere.put('xPosition', '100');
            signHere.put('yPosition', '100');
            signHereTabs.add(signHere);
            tabs.put('signHereTabs', signHereTabs);
            signer.put('tabs', tabs);
            
            signers.add(signer);
            
            Map<String, Object> recipients = new Map<String, Object>();
            recipients.put('signers', signers);
            envelopeRequest.put('recipients', recipients);
            
            // Send to DocuSign
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:' + DOCUSIGN_CREDENTIAL + '/accounts/' + docuSignSettings.AccountId__);
HttpRequest request = new HttpRequest();

request.setEndpoint('callout:' + DOCUSIGN_CREDENTIAL + '/accounts/' + docuSignSettings.AccountId__c + '/envelopes');
request.setMethod('POST');
request.setHeader('Content-Type', 'application/json');
request.setHeader('Accept', 'application/json');
request.setBody(JSON.serialize(envelopeRequest));
request.setTimeout(30000);

Http http = new Http();
HttpResponse response = http.send(request);

if (response.getStatusCode() == 201) {
    Map<String, Object> responseData = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
    String envelopeId = (String)responseData.get('envelopeId');
    String envelopeUri = (String)responseData.get('uri');
    
    // Create external signature request record
    ExternalSignatureRequest__c externalRequest = new ExternalSignatureRequest__c();
    externalRequest.DocumentId__c = documentId;
    externalRequest.Provider__c = 'DocuSign';
    externalRequest.ExternalId__c = envelopeId;
    externalRequest.Status__c = 'Sent';
    externalRequest.SignerEmail__c = signerEmail;
    externalRequest.SignerName__c = signerName;
    externalRequest.SentDate__c = System.now();
    externalRequest.ExternalURL__c = docuSignSettings.BaseURL__c + envelopeUri;
    
    insert externalRequest;
    
    // Log successful DocuSign integration
    AuditTrailManager.logAPIActivity(
        'DocuSign Envelope Creation',
        'POST',
        201,
        JSON.serialize(envelopeRequest),
        response.getBody(),
        response.getStatusCode().longValue()
    );
    
    return envelopeId;
    
} else {
    // Log failed DocuSign request
    AuditTrailManager.logAPIActivity(
        'DocuSign Envelope Failed',
        'POST',
        response.getStatusCode(),
        JSON.serialize(envelopeRequest),
        response.getBody(),
        0
    );
    
    throw new AuraHandledException('DocuSign envelope creation failed: ' + response.getBody());
}

} catch (Exception e) {
    AuditTrailManager.createAuditEntry(
        documentId,
        'DOCUSIGN_SEND_ERROR',
        'ERROR',
        'DocuSign send exception: ' + e.getMessage()
    );
    throw new AuraHandledException('Failed to send to DocuSign: ' + e.getMessage());
}

}

/**
 * Initialize Adobe Sign integration
 */
@AuraEnabled
public static Map<String, Object> initializeAdobeSignIntegration(Map<String, String> credentials) {
Map<String, Object> result = new Map<String, Object>();

try {
    // Test Adobe Sign connection
    HttpRequest request = new HttpRequest();
    request.setEndpoint('callout:' + ADOBE_CREDENTIAL + '/account');
    request.setMethod('GET');
    request.setHeader('Authorization', 'Bearer ' + credentials.get('accessToken'));
    request.setHeader('Accept', 'application/json');
    
    Http http = new Http();
    HttpResponse response = http.send(request);
    
    if (response.getStatusCode() == 200) {
        Map<String, Object> responseData = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
        
        // Store Adobe Sign settings
        IntegrationSetting__c setting = new IntegrationSetting__c();
        setting.Name = 'Adobe_Sign_Configuration';
        setting.Provider__c = 'Adobe Sign';
        setting.IsActive__c = true;
        setting.AccountId__c = (String)responseData.get('accountId');
        setting.BaseURL__c = ADOBE_SIGN_BASE_URL;
        setting.LastTestDate__c = System.now();
        setting.Status__c = 'ACTIVE';
        
        upsert setting Name;
        
        result.put('success', true);
        result.put('accountId', responseData.get('accountId'));
        result.put('accountName', responseData.get('companyName'));
        
        AuditTrailManager.logAPIActivity(
            'Adobe Sign Account Validation',
            'GET',
            200,
            '',
            response.getBody(),
            response.getStatusCode().longValue()
        );
        
    } else {
        result.put('success', false);
        result.put('error', 'Adobe Sign connection failed: ' + response.getBody());
        
        AuditTrailManager.logAPIActivity(
            'Adobe Sign Integration Failed',
            'GET',
            response.getStatusCode(),
            '',
            response.getBody(),
            0
        );
    }
    
} catch (Exception e) {
    result.put('success', false);
    result.put('error', 'Adobe Sign initialization failed: ' + e.getMessage());
    
    AuditTrailManager.createAuditEntry(
        null,
        'ADOBE_SIGN_INIT_ERROR',
        'ERROR',
        'Adobe Sign initialization exception: ' + e.getMessage()
    );
}

return result;

}

/**
 * Send document to Adobe Sign for signature
 */
@AuraEnabled
public static String sendToAdobeSign(String documentId, String signerEmail, String signerName) {
try {
    // Get integration settings
    IntegrationSetting__c adobeSettings = getIntegrationSettings('Adobe Sign');
    if (adobeSettings == null || !adobeSettings.IsActive__c) {
        throw new AuraHandledException('Adobe Sign integration not configured');
    }
    
    // Get document details
    DocumentLifecycleConfiguration__c doc = [
        SELECT Id, DocumentTitle__c, GeneratedContent__c, ContractType__c
        FROM DocumentLifecycleConfiguration__c
        WHERE Id = :documentId
        LIMIT 1
    ];
    
    // Step 1: Upload document
    String documentUploadId = uploadDocumentToAdobeSign(doc);
    
    // Step 2: Create agreement request
    Map<String, Object> agreementRequest = new Map<String, Object>();
    agreementRequest.put('name', doc.DocumentTitle__c);
    agreementRequest.put('signatureType', 'ESIGN');
    agreementRequest.put('state', 'IN_PROCESS');
    
    // Add file info
    List<Map<String, Object>> fileInfos = new List<Map<String, Object>>();
    Map<String, Object> fileInfo = new Map<String, Object>();
    fileInfo.put('transientDocumentId', documentUploadId);
    fileInfos.add(fileInfo);
    agreementRequest.put('fileInfos', fileInfos);
    
    // Add participant info
    List<Map<String, Object>> participantSetsInfo = new List<Map<String, Object>>();
    Map<String, Object> participantSet = new Map<String, Object>();
    participantSet.put('order', 1);
    participantSet.put('role', 'SIGNER');
    
    List<Map<String, Object>> memberInfos = new List<Map<String, Object>>();
    Map<String, Object> memberInfo = new Map<String, Object>();
    memberInfo.put('email', signerEmail);
    memberInfo.put('name', signerName);
    memberInfos.add(memberInfo);
    
    participantSet.put('memberInfos', memberInfos);
    participantSetsInfo.add(participantSet);
    agreementRequest.put('participantSetsInfo', participantSetsInfo);
    
    // Send agreement request
    HttpRequest request = new HttpRequest();
    request.setEndpoint('callout:' + ADOBE_CREDENTIAL + '/agreements');
    request.setMethod('POST');
    request.setHeader('Content-Type', 'application/json');
    request.setHeader('Accept', 'application/json');
    request.setBody(JSON.serialize(agreementRequest));
    request.setTimeout(30000);
    
    Http http = new Http();
    HttpResponse response = http.send(request);
    
    if (response.getStatusCode() == 201) {
        Map<String, Object> responseData = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
        String agreementId = (String)responseData.get('id');
        
        // Create external signature request record
        ExternalSignatureRequest__c externalRequest = new ExternalSignatureRequest__c();
        externalRequest.DocumentId__c = documentId;
        externalRequest.Provider__c = 'Adobe Sign';
        externalRequest.ExternalId__c = agreementId;
        externalRequest.Status__c = 'Sent';
        externalRequest.SignerEmail__c = signerEmail;
        externalRequest.SignerName__c = signerName;
        externalRequest.SentDate__c = System.now();
        
        insert externalRequest;
        
        // Log successful Adobe Sign integration
        AuditTrailManager.logAPIActivity(
            'Adobe Sign Agreement Creation',
            'POST',
            201,
            JSON.serialize(agreementRequest),
            response.getBody(),
            response.getStatusCode().longValue()
        );
        
        return agreementId;
        
    } else {
        AuditTrailManager.logAPIActivity(
            'Adobe Sign Agreement Failed',
            'POST',
            response.getStatusCode(),
            JSON.serialize(agreementRequest),
            response.getBody(),
            0
        );
        
        throw new AuraHandledException('Adobe Sign agreement creation failed: ' + response.getBody());
    }
    
} catch (Exception e) {
    AuditTrailManager.createAuditEntry(
        documentId,
        'ADOBE_SIGN_SEND_ERROR',
        'ERROR',
        'Adobe Sign send exception: ' + e.getMessage()
    );
    throw new AuraHandledException('Failed to send to Adobe Sign: ' + e.getMessage());
}

}

/**
 * Initialize HelloSign integration
 */
@AuraEnabled
public static Map<String, Object> initializeHelloSignIntegration(Map<String, String> credentials) {
Map<String, Object> result = new Map<String, Object>();

try {
    // Test HelloSign connection
    HttpRequest request = new HttpRequest();
    request.setEndpoint('callout:' + HELLOSIGN_CREDENTIAL + '/account');
    request.setMethod('GET');
    request.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(credentials.get('apiKey') + ':')));
    request.setHeader('Accept', 'application/json');
    
    Http http = new Http();
    HttpResponse response = http.send(request);
    
    if (response.getStatusCode() == 200) {
        Map<String, Object> responseData = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
        Map<String, Object> account = (Map<String, Object>)responseData.get('account');
        
        // Store HelloSign settings
        IntegrationSetting__c setting = new IntegrationSetting__c();
        setting.Name = 'HelloSign_Configuration';
        setting.Provider__c = 'HelloSign';
        setting.IsActive__c = true;
        setting.AccountId__c = (String)account.get('account_id');
        setting.BaseURL__c = HELLOSIGN_BASE_URL;
        setting.LastTestDate__c = System.now();
        setting.Status__c = 'ACTIVE';
        
        upsert setting Name;
        
        result.put('success', true);
        result.put('accountId', account.get('account_id'));
        result.put('accountEmail', account.get('email_address'));
        
        AuditTrailManager.logAPIActivity(
            'HelloSign Account Validation',
            'GET',
            200,
            '',
            response.getBody(),
            response.getStatusCode().longValue()
        );
        
    } else {
        result.put('success', false);
        result.put('error', 'HelloSign connection failed: ' + response.getBody());
        
        AuditTrailManager.logAPIActivity(
            'HelloSign Integration Failed',
            'GET',
            response.getStatusCode(),
            '',
            response.getBody(),
            0
        );
    }
    
} catch (Exception e) {
    result.put('success', false);
    result.put('error', 'HelloSign initialization failed: ' + e.getMessage());
    
    AuditTrailManager.createAuditEntry(
        null,
        'HELLOSIGN_INIT_ERROR',
        'ERROR',
        'HelloSign initialization exception: ' + e.getMessage()
    );
}

return result;

}

/**
 * Universal integration status checker
 */
@AuraEnabled
public static Map<String, Object> checkIntegrationStatus() {
Map<String, Object> status = new Map<String, Object>();

try {
    // Get all integration settings
    List<IntegrationSetting__c> integrations = [
        SELECT Name, Provider__c, IsActive__c, Status__c, LastTestDate__c, AccountId__c
        FROM IntegrationSetting__c
        WHERE IsActive__c = true
    ];
    
    Map<String, Map<String, Object>> integrationStatus = new Map<String, Map<String, Object>>();
    
    for (IntegrationSetting__c integration : integrations) {
        Map<String, Object> details = new Map<String, Object>();
        details.put('provider', integration.Provider__c);
        details.put('isActive', integration.IsActive__c);
        details.put('status', integration.Status__c);
        details.put('lastTested', integration.LastTestDate__c);
        details.put('accountId', integration.AccountId__c);
        
        // Perform health check
        Boolean healthCheck = performHealthCheck(integration);
        details.put('healthCheck', healthCheck);
        details.put('lastHealthCheck', System.now());
        
        integrationStatus.put(integration.Provider__c, details);
    }
    
    status.put('integrations', integrationStatus);
    status.put('totalIntegrations', integrations.size());
    status.put('activeIntegrations', integrations.size()); // All queried are active
    
    // Calculate overall health score
    Integer healthyCount = 0;
    for (String provider : integrationStatus.keySet()) {
        Map<String, Object> integration = integrationStatus.get(provider);
        if ((Boolean)integration.get('healthCheck')) {
            healthyCount++;
        }
    }
    
    Decimal healthScore = integrations.size() > 0 ? (Decimal.valueOf(healthyCount) / integrations.size()) * 100 : 0;
    status.put('overallHealthScore', healthScore.setScale(1));
    
    // Log status check
    AuditTrailManager.createAuditEntry(
        null,
        'INTEGRATION_STATUS_CHECK',
        'SUCCESS',
        'Integration status checked. Health score: ' + healthScore + '%'
    );
    
} catch (Exception e) {
    status.put('error', 'Failed to check integration status: ' + e.getMessage());
    
    AuditTrailManager.createAuditEntry(
        null,
        'INTEGRATION_STATUS_ERROR',
        'ERROR',
        'Integration status check failed: ' + e.getMessage()
    );
}

return status;

}

/**
 * Webhook handler for external signature status updates
 */
@HttpPost
global static void handleWebhook() {
    try {
        RestRequest request = RestContext.request;
        String requestBody = request.requestBody.toString();
        
        // Parse webhook payload
        Map<String, Object> webhookData = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        String eventType = (String) webhookData.get('event_type');
        
        // Extract externalId from multiple possible providers
        String externalId = (String) webhookData.get('envelope_id'); // DocuSign envelope ID
        if (String.isBlank(externalId)) {
            externalId = (String) webhookData.get('agreement_id'); // Adobe Sign agreement ID
        }
        if (String.isBlank(externalId)) {
            externalId = (String) webhookData.get('signature_request_id'); // HelloSign request ID
        }

        // Find corresponding external signature request
        List<ExternalSignatureRequest__c> externalRequests = [
            SELECT Id, DocumentId__c, Provider__c, Status__c, SignerEmail__c, SignerName__c
            FROM ExternalSignatureRequest__c 
            WHERE ExternalId__c = :externalId
            LIMIT 1
        ];

        if (externalRequests.isEmpty()) {
            RestContext.response.statusCode = 404;
            RestContext.response.responseBody = Blob.valueOf('{"error": "External signature request not found"}');
            return;
        }

        ExternalSignatureRequest__c externalRequest = externalRequests[0];
        
        // Process webhook based on event type and provider
        Boolean processed = false;
        String newStatus = externalRequest.Status__c;
        
        switch on externalRequest.Provider__c {
            when 'DocuSign' {
                processed = processDocuSignWebhook(eventType, webhookData, externalRequest);
                newStatus = mapDocuSignStatus(eventType);
            }
            when 'Adobe Sign' {
                processed = processAdobeSignWebhook(eventType, webhookData, externalRequest);
                newStatus = mapAdobeSignStatus(eventType);
            }
            when 'HelloSign' {
                processed = processHelloSignWebhook(eventType, webhookData, externalRequest);
                newStatus = mapHelloSignStatus(eventType);
            }
        }

        if (processed) {
            // Update external request status
            externalRequest.Status__c = newStatus;
            externalRequest.LastUpdated__c = System.now();
            update externalRequest;

            // Update internal signature request if completed
            if (newStatus == 'Completed') {
                updateInternalSignatureRequest(externalRequest, webhookData);
            }

            // Log webhook processing
            AuditTrailManager.logWebhookActivity(
                externalRequest.Provider__c,
                eventType,
                'SUCCESS',
                'Webhook processed successfully for ' + externalId,
                requestBody
            );

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf('{"status": "processed"}');
        } else {
            RestContext.response.statusCode = 400;
            RestContext.response.responseBody = Blob.valueOf('{"error": "Failed to process webhook"}');
        }

    } catch (Exception e) {
        // Log webhook error
        AuditTrailManager.logWebhookActivity(
            'Unknown',
            'ERROR',
            'ERROR', 
            'Webhook processing exception: ' + e.getMessage(),
            RestContext.request.requestBody.toString()
        );
        
        RestContext.response.statusCode = 500;
        RestContext.response.responseBody = Blob.valueOf('{"error": "Internal server error"}');
    }
}


/**
 * Process DocuSign webhook events
 */
private static Boolean processDocuSignWebhook(String eventType, Map<String, Object> webhookData, ExternalSignatureRequest__c externalRequest) {
    try {
        switch on eventType {
            when 'envelope-sent' {
                // Envelope was successfully sent
                return true;
            }
            when 'envelope-delivered' {
                // Envelope was delivered to signer
                EmailNotificationService.sendSignatureDeliveryConfirmation(externalRequest.Id);
                return true;
            }
            when 'envelope-completed' {
                // All signatures collected
                downloadCompletedDocumentFromDocuSign(externalRequest);
                EmailNotificationService.sendSignatureCompletionNotification(externalRequest.DocumentId__c);
                return true;
            }
            when 'envelope-declined' {
                // Signer declined to sign
                String reason = (String) webhookData.get('decline_reason');
                EmailNotificationService.sendSignatureRejectionNotification(externalRequest.DocumentId__c, reason);
                return true;
            }
            when 'envelope-voided' {
                // Envelope was voided
                handleVoidedEnvelope(externalRequest);
                return true;
            }
            when else {
                System.debug('⚠️ Unhandled DocuSign event: ' + eventType);
                return false;
            }
        }
    } catch (Exception e) {
        System.debug('❌ DocuSign webhook processing error: ' + e.getMessage());
        System.debug(e.getStackTraceString());
        return false;
    }
}

/**
 * Process Adobe Sign webhook events
 */
private static Boolean processAdobeSignWebhook(String eventType, Map<String, Object> webhookData, ExternalSignatureRequest__c externalRequest) {
    try {
        switch on eventType {
            when 'AGREEMENT_WORKFLOW_COMPLETED' {
                // Agreement fully completed
                downloadCompletedDocumentFromAdobeSign(externalRequest);
                EmailNotificationService.sendSignatureCompletionNotification(externalRequest.DocumentId__c);
                return true;
            }
            when 'AGREEMENT_USER_ACK_AGREEMENT_MODIFIED' {
                // User acknowledged agreement modification
                return true;
            }
            when 'AGREEMENT_REJECTED' {
                String reason = 'Agreement rejected by signer';
                EmailNotificationService.sendSignatureRejectionNotification(externalRequest.DocumentId__c, reason);
                return true;
            }
            when 'AGREEMENT_RECALLED' {
                // Agreement recalled/withdrawn
                handleRecalledAgreement(externalRequest);
                return true;
            }
            when else {
                System.debug('Unhandled Adobe Sign event: ' + eventType);
                return false;
            }
        }
    } catch (Exception e) {
        System.debug('Adobe Sign webhook processing error: ' + e.getMessage());
        return false;
    }
}


/**
 * Process HelloSign webhook events  
 */
private static Boolean processHelloSignWebhook(String eventType, Map<String, Object> webhookData, ExternalSignatureRequest__c externalRequest) {
    try {
        switch on eventType {
            when 'signature_request_all_signed' {
                // Download completed document and send notification
                downloadCompletedDocumentFromHelloSign(externalRequest);
                EmailNotificationService.sendSignatureCompletionNotification(externalRequest.DocumentId__c);
                return true;
            }
            when 'signature_request_declined' {
                // Handle declined request
                String reason = 'Signature request declined';
                EmailNotificationService.sendSignatureRejectionNotification(externalRequest.DocumentId__c, reason);
                return true;
            }
            when 'signature_request_remind' {
                // Reminder event received
                return true;
            }
            when else {
                System.debug('⚠️ Unhandled HelloSign event: ' + eventType);
                return false;
            }
        }
    } catch (Exception e) {
        System.debug('❌ HelloSign webhook processing error: ' + e.getMessage());
        return false;
    }
}


/**
 * Download completed document from DocuSign
 */
/**
 * Download completed document from DocuSign
 */
private static void downloadCompletedDocumentFromDocuSign(ExternalSignatureRequest__c externalRequest) {
    try {
        IntegrationSetting__c docuSignSettings = getIntegrationSettings('DocuSign');
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + DOCUSIGN_CREDENTIAL + '/accounts/' + 
                           docuSignSettings.AccountId__c + '/envelopes/' + 
                           externalRequest.ExternalId__c + '/documents/combined');
        request.setMethod('GET');
        request.setHeader('Accept', 'application/pdf');
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            // Store completed document
            Attachment signedDoc = new Attachment();
            signedDoc.Name = 'Signed_Document.pdf';
            signedDoc.ParentId = externalRequest.DocumentId__c;
            signedDoc.Body = response.getBodyAsBlob();
            signedDoc.ContentType = 'application/pdf';
            insert signedDoc;
            
            // Update external request
            externalRequest.SignedDocumentId__c = signedDoc.Id;
            externalRequest.CompletedDate__c = System.now();
        }
    } catch (Exception e) {
        System.debug('❌ Failed to download DocuSign document: ' + e.getMessage());
    }
}

/**
 * Download completed document from Adobe Sign
 */
private static void downloadCompletedDocumentFromAdobeSign(ExternalSignatureRequest__c externalRequest) {
    try {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + ADOBE_CREDENTIAL + '/agreements/' + 
                           externalRequest.ExternalId__c + '/combinedDocument');
        request.setMethod('GET');
        request.setHeader('Accept', 'application/pdf');
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            // Store completed document
            Attachment signedDoc = new Attachment();
            signedDoc.Name = 'Signed_Document.pdf';
            signedDoc.ParentId = externalRequest.DocumentId__c;
            signedDoc.Body = response.getBodyAsBlob();
            signedDoc.ContentType = 'application/pdf';
            insert signedDoc;
            
            // Update external request
            externalRequest.SignedDocumentId__c = signedDoc.Id;
            externalRequest.CompletedDate__c = System.now();
        }
    } catch (Exception e) {
        System.debug('❌ Failed to download Adobe Sign document: ' + e.getMessage());
    }
}

/**
 * Download completed document from HelloSign
 */
private static void downloadCompletedDocumentFromHelloSign(ExternalSignatureRequest__c externalRequest) {
    try {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + HELLOSIGN_CREDENTIAL + '/signature_request/files/' + 
                           externalRequest.ExternalId__c);
        request.setMethod('GET');
        request.setHeader('Accept', 'application/pdf');
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            // Store completed document
            Attachment signedDoc = new Attachment();
            signedDoc.Name = 'Signed_Document.pdf';
            signedDoc.ParentId = externalRequest.DocumentId__c;
            signedDoc.Body = response.getBodyAsBlob();
            signedDoc.ContentType = 'application/pdf';
            insert signedDoc;
            
            // Update external request
            externalRequest.SignedDocumentId__c = signedDoc.Id;
            externalRequest.CompletedDate__c = System.now();
        }
    } catch (Exception e) {
        System.debug('❌ Failed to download HelloSign document: ' + e.getMessage());
    }
}

/**
 * Update internal signature request when external signing is completed
 */
/**
 * Update internal signature request when external webhook is received
 */
private static void updateInternalSignatureRequest(ExternalSignatureRequest__c externalRequest, Map<String, Object> webhookData) {
    try {
        // Find corresponding internal signature request
        List<Signature_Request__c> signatureRequests = [
            SELECT Id, Status__c, DocumentId__c
            FROM Signature_Request__c 
            WHERE DocumentId__c = :externalRequest.DocumentId__c
            AND SignerEmail__c = :externalRequest.SignerEmail__c
            AND Status__c = 'Pending'
            LIMIT 1
        ];
        
        if (!signatureRequests.isEmpty()) {
            Signature_Request__c signatureRequest = signatureRequests[0];
            signatureRequest.Status__c = 'Completed';
            signatureRequest.CompletedDate__c = System.now();
            signatureRequest.ExternalProvider__c = externalRequest.Provider__c;
            signatureRequest.ExternalId__c = externalRequest.ExternalId__c;
            
            update signatureRequest;
            
            // Create signature validation record
            SignatureValidation__c validation = new SignatureValidation__c();
            validation.SignatureRequest__c = signatureRequest.Id;
            validation.ValidationStatus__c = 'Valid';
            validation.SignatureData__c = 'Externally signed via ' + externalRequest.Provider__c;
            validation.ValidatedDate__c = System.now();
            validation.ValidationHash__c = generateValidationHash(signatureRequest.Id, externalRequest.ExternalId__c);
            
            insert validation;
            
            // Log completion
            AuditTrailManager.logDocumentActivity(
                signatureRequest.DocumentId__c,
                'EXTERNAL_SIGNATURE_COMPLETED',
                'Document signed externally via ' + externalRequest.Provider__c + ' by: ' + externalRequest.SignerEmail__c
            );
        }
    } catch (Exception e) {
        System.debug('❌ Failed to update internal signature request: ' + e.getMessage());
    }
}

/**
 * Map DocuSign event types to internal status
 */
private static String mapDocuSignStatus(String eventType) {
    switch on eventType {
        when 'envelope-sent'     { return 'Sent'; }
        when 'envelope-delivered'{ return 'Delivered'; }
        when 'envelope-completed'{ return 'Completed'; }
        when 'envelope-declined' { return 'Declined'; }
        when 'envelope-voided'   { return 'Voided'; }
        when else                { return 'Unknown'; }
    }
}

/**
 * Map Adobe Sign event types to internal status  
 */
private static String mapAdobeSignStatus(String eventType) {
    switch on eventType {
        when 'AGREEMENT_WORKFLOW_COMPLETED' { return 'Completed'; }
        when 'AGREEMENT_REJECTED'           { return 'Rejected'; }
        when 'AGREEMENT_RECALLED'           { return 'Recalled'; }
        when else                           { return 'In Progress'; }
    }
}

/**
 * Map HelloSign event types to internal status
 */
private static String mapHelloSignStatus(String eventType) {
    switch on eventType {
        when 'signature_request_all_signed' { return 'Completed'; }
        when 'signature_request_declined'   { return 'Declined'; }
        when else                           { return 'Pending'; }
    }
}

/**
 * Upload document to Adobe Sign (helper method)
 */
private static String uploadDocumentToAdobeSign(DocumentLifecycleConfiguration__c doc) {
    try {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + ADOBE_CREDENTIAL + '/transientDocuments');
        request.setMethod('POST');
        
        // Create multipart form data
        String boundary = '----WebKitFormBoundary' + String.valueOf(Crypto.getRandomLong());
        String formData = '--' + boundary + '\r\n';
        formData += 'Content-Disposition: form-data; name="File"; filename="' + doc.DocumentTitle__c + '.pdf"\r\n';
        formData += 'Content-Type: application/pdf\r\n\r\n';
        
        Blob documentBlob = Blob.valueOf(doc.GeneratedContent__c);
        String documentData = EncodingUtil.base64Encode(documentBlob);
        
        formData += documentData;
        formData += '\r\n--' + boundary + '--';
        
        request.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
        request.setBodyAsBlob(Blob.valueOf(formData));
        request.setTimeout(30000);
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 201) {
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            return (String) responseData.get('transientDocumentId');
        } else {
            throw new AuraHandledException('❌ Failed to upload document to Adobe Sign: ' + response.getBody());
        }
    } catch (Exception e) {
        System.debug('❌ Adobe Sign document upload error: ' + e.getMessage());
        throw e;
    }
}

/**
 * Get integration settings by provider
 */
private static IntegrationSetting__c getIntegrationSettings(String provider) {
    try {
        return [
            SELECT Id, Name, Provider__c, IsActive__c, Status__c, AccountId__c, BaseURL__c
            FROM IntegrationSetting__c
            WHERE Provider__c = :provider
            AND IsActive__c = true
            LIMIT 1
        ];
    } catch (QueryException e) {
        return null;
    }
}

/**
 * Perform health check on integration
 */
private static Boolean performHealthCheck(IntegrationSetting__c integration) {
    try {
        HttpRequest request = new HttpRequest();
        request.setTimeout(10000); // Shorter timeout for health check
        
        switch on integration.Provider__c {
            when 'DocuSign' {
                request.setEndpoint('callout:' + DOCUSIGN_CREDENTIAL + '/accounts/' + integration.AccountId__c);
                request.setMethod('GET');
                request.setHeader('Accept', 'application/json');
            }
            when 'Adobe Sign' {
                request.setEndpoint('callout:' + ADOBE_CREDENTIAL + '/account');
                request.setMethod('GET');
                request.setHeader('Accept', 'application/json');
            }
            when 'HelloSign' {
                request.setEndpoint('callout:' + HELLOSIGN_CREDENTIAL + '/account');
                request.setMethod('GET');
                request.setHeader('Accept', 'application/json');
            }
            when else {
                return false;
            }
        }
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        return response.getStatusCode() >= 200 && response.getStatusCode() < 300;
    } catch (Exception e) {
        System.debug('❌ Health check failed for ' + integration.Provider__c + ': ' + e.getMessage());
        return false;
    }
}

/**
 * Validate DocuSign credentials
 */
private static Boolean validateDocuSignCredentials(Map<String, String> credentials) {
    return credentials.containsKey('accessToken') && String.isNotBlank(credentials.get('accessToken'));
}

/**
 * Generate validation hash for signature
 */
private static String generateValidationHash(String requestId, String externalId) {
    String dataToHash = requestId + externalId + System.now().getTime();
    Blob hashBlob = Crypto.generateDigest('SHA-256', Blob.valueOf(dataToHash));
    return EncodingUtil.base64Encode(hashBlob);
}

/**
 * Handle voided envelope from DocuSign
 */
private static void handleVoidedEnvelope(ExternalSignatureRequest__c externalRequest) {
    try {
        externalRequest.Status__c = 'Voided';
        externalRequest.VoidedDate__c = System.now();
        
        // Notify document owner
        EmailNotificationService.sendEnvelopeVoidedNotification(externalRequest.Id);
        
        // Log action
        AuditTrailManager.logDocumentActivity(
            externalRequest.DocumentId__c,
            'EXTERNAL_ENVELOPE_VOIDED',
            'DocuSign envelope was voided: ' + externalRequest.ExternalId__c
        );
    } catch (Exception e) {
        System.debug('❌ Error handling voided envelope: ' + e.getMessage());
    }
}

/**
 * Handle recalled agreement from Adobe Sign
 */
private static void handleRecalledAgreement(ExternalSignatureRequest__c externalRequest) {
    try {
        externalRequest.Status__c = 'Recalled';
        externalRequest.RecalledDate__c = System.now();
        
        // Notify document owner
        EmailNotificationService.sendAgreementRecalledNotification(externalRequest.Id);
        
        // Log action
        AuditTrailManager.logDocumentActivity(
            externalRequest.DocumentId__c,
            'EXTERNAL_AGREEMENT_RECALLED',
            'Adobe Sign agreement was recalled: ' + externalRequest.ExternalId__c
        );
    } catch (Exception e) {
        System.debug('❌ Error handling recalled agreement: ' + e.getMessage());
    }
}

/**
 * Get integration metrics for dashboard
 */
@AuraEnabled
public static Map<String, Object> getIntegrationMetrics() {
    Map<String, Object> metrics = new Map<String, Object>();
    try {
        // External requests by provider
        List<AggregateResult> providerStats = [
            SELECT Provider__c, COUNT(Id) totalRequests, COUNT_DISTINCT(DocumentId__c) uniqueDocuments
            FROM ExternalSignatureRequest__c
            WHERE CreatedDate >= :Date.today().addDays(-30)
            GROUP BY Provider__c
        ];
        
        Map<String, Map<String, Object>> providerMetrics = new Map<String, Map<String, Object>>();
        for (AggregateResult ar : providerStats) {
            String provider = (String) ar.get('Provider__c');
            Map<String, Object> providerData = new Map<String, Object>();
            providerData.put('totalRequests', (Integer) ar.get('totalRequests'));
            providerData.put('uniqueDocuments', (Integer) ar.get('uniqueDocuments'));
            providerMetrics.put(provider, providerData);
        }
        metrics.put('providerMetrics', providerMetrics);
        
        // Success rates by provider
        List<AggregateResult> successStats = [
            SELECT Provider__c, Status__c, COUNT(Id) totalcount
            FROM ExternalSignatureRequest__c
            WHERE CreatedDate >= :Date.today().addDays(-30)
            GROUP BY Provider__c, Status__c
        ];
        
        Map<String, Map<String, Integer>> successRates = new Map<String, Map<String, Integer>>();
        for (AggregateResult ar : successStats) {
            String provider = (String) ar.get('Provider__c');
            String status = (String) ar.get('Status__c');
            Integer count = (Integer) ar.get('count');
            
            if (!successRates.containsKey(provider)) {
                successRates.put(provider, new Map<String, Integer>());
            }
            successRates.get(provider).put(status, count);
        }
        metrics.put('successRates', successRates);
        
        // Average completion times
       List<ExternalSignatureRequest__c> completedRequests = [
    SELECT Provider__c, SentDate__c, CompletedDate__c
    FROM ExternalSignatureRequest__c
    WHERE Status__c = 'Completed'
    AND CompletedDate__c >= :Date.today().addDays(-30)
];
        Map<String, Decimal> avgCompletionTimes = new Map<String, Decimal>();
        for (AggregateResult ar : completionTimes) {
            String provider = (String) ar.get('Provider__c');
            Decimal avgTime = (Decimal) ar.get('avgHours');
            avgCompletionTimes.put(provider, avgTime);
        }
        metrics.put('avgCompletionTimes', avgCompletionTimes);
        
        // Recent activity
        List<ExternalSignatureRequest__c> recentActivity = [
            SELECT Id, Provider__c, Status__c, DocumentId__r.DocumentTitle__c, SignerEmail__c, CreatedDate
            FROM ExternalSignatureRequest__c
            WHERE CreatedDate >= :Date.today().addDays(-7)
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
        metrics.put('recentActivity', recentActivity);
        
        // Error rates
        List<AggregateResult> errorStats = [
            SELECT Action__c, Status__c, COUNT(Id) totalcount
            FROM AuditTrail__c
            WHERE CreatedDate >= :Date.today().addDays(-30)
            AND (Action__c LIKE '%DOCUSIGN%' OR Action__c LIKE '%ADOBE%' OR Action__c LIKE '%HELLOSIGN%')
            GROUP BY Action__c, Status__c
        ];
        
        Map<String, Map<String, Integer>> errorRates = new Map<String, Map<String, Integer>>();
        for (AggregateResult ar : errorStats) {
            String action = (String) ar.get('Action__c');
            String status = (String) ar.get('Status__c');
            Integer count = (Integer) ar.get('count');
            
            if (!errorRates.containsKey(action)) {
                errorRates.put(action, new Map<String, Integer>());
            }
            errorRates.get(action).put(status, count);
        }
        metrics.put('errorRates', errorRates);
        
    } catch (Exception e) {
        metrics.put('error', '❌ Failed to retrieve integration metrics: ' + e.getMessage());
    }
    return metrics;
}
}



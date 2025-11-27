public with sharing class IntegrationConfigurationService {
    // Defined missing constant
    private static final String ADOBE_CREDENTIAL = 'Adobe_Sign_Integration';

    @AuraEnabled
    public static String sendToAdobeSign(String documentId, String signerEmail, String signerName) {
        try {
            IntegrationSetting__c adobeSettings = getIntegrationSettings('Adobe Sign');
            if (adobeSettings == null || !adobeSettings.IsActive__c) {
                throw new AuraHandledException('Adobe Sign integration not configured');
            }

            DocumentLifecycleConfiguration__c doc = [
                SELECT Id, DocumentTitle__c, GeneratedClause__c, ContractType__c
                FROM DocumentLifecycleConfiguration__c
                WHERE Id = :documentId LIMIT 1
            ];

            String documentUploadId = uploadDocumentToAdobeSign(doc);

            Map<String, Object> agreementRequest = new Map<String, Object>();
            agreementRequest.put('name', doc.DocumentTitle__c);
            agreementRequest.put('signatureType', 'ESIGN');
            agreementRequest.put('state', 'IN_PROCESS');

            List<Map<String, Object>> fileInfos = new List<Map<String, Object>>();
            Map<String, Object> fileInfo = new Map<String, Object>();
            fileInfo.put('transientDocumentId', documentUploadId);
            fileInfos.add(fileInfo);
            agreementRequest.put('fileInfos', fileInfos);

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
                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String agreementId = (String) responseData.get('id');

                ExternalSignatureRequest__c externalRequest = new ExternalSignatureRequest__c();
                externalRequest.DocumentId__c = documentId;
                externalRequest.Provider__c = 'Adobe Sign';
                externalRequest.ExternalId__c = agreementId;
                externalRequest.Status__c = 'Sent';
                externalRequest.SignerEmail__c = signerEmail;
                externalRequest.SignerName__c = signerName;
                // Corrected syntax error here
                externalRequest.SentDate__c = System.now();
                insert externalRequest;

                // Assuming AuditTrailManager exists and has this method signature
                // AuditTrailManager.createAuditEntry(documentId, 'ADOBE_SIGN_AGREEMENT_CREATION', 'SUCCESS', 'Agreement ID: ' + agreementId);
                return agreementId;
            } else {
                // AuditTrailManager.createAuditEntry(documentId, 'ADOBE_SIGN_AGREEMENT_FAILED', 'ERROR', 'Status: ' + response.getStatusCode() + ' - ' + response.getBody());
                throw new AuraHandledException('Adobe Sign agreement creation failed: ' + response.getBody());
            }
        } catch (Exception e) {
            // AuditTrailManager.createAuditEntry(documentId, 'ADOBE_SIGN_SEND_ERROR', 'ERROR', 'Adobe Sign send exception: ' + e.getMessage());
            throw new AuraHandledException('Failed to send to Adobe Sign: ' + e.getMessage());
        }
    }

    // Placeholder for missing helper method
    @TestVisible
    private static IntegrationSetting__c getIntegrationSettings(String provider) {
        // In a real scenario, this would query your custom setting/metadata
        List<IntegrationSetting__c> settings = [SELECT Id, IsActive__c FROM IntegrationSetting__c WHERE Provider__c = :provider LIMIT 1];
        return settings.isEmpty() ? null : settings[0];
    }

    // Placeholder for missing helper method that performs a callout
    @TestVisible
    private static String uploadDocumentToAdobeSign(DocumentLifecycleConfiguration__c doc) {
        // This method simulates a callout to upload the document and get a transient ID
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + ADOBE_CREDENTIAL + '/transientDocuments');
        req.setMethod('POST');
        // Body would contain multipart/form-data with the document blob
        req.setBody('Simulated document blob for: ' + doc.DocumentTitle__c);
        
        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 201) {
             Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
             return (String) responseData.get('transientDocumentId');
        } else {
            throw new CalloutException('Failed to upload document to Adobe Sign: ' + res.getBody());
        }
    }
}
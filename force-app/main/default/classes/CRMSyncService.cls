public class CRMSyncService {

    @future(callout=true)
    public static void syncWithCRM(String recordId, String crmSystem) {
        // Salesforce-to-external CRM sync
    }

    @AuraEnabled
    public static SyncResult synchronizeSignatureData(Id signatureRequestId, String crmSystem) {
        try {
            // Get signature request with related data
            Signature_Request__c request = [
                SELECT Id, Document_Id__c, Signer_Email__c, Signer_Name__c, Status__c,
                       Completion_Date__c, Document_Hash__c, Signature_Method__c,
                       DocumentLifecycleConfiguration__r.Region__c,
                       DocumentLifecycleConfiguration__r.ContractType__c,
                       DocumentLifecycleConfiguration__r.DocumentTitle__c
                FROM Signature_Request__c 
                WHERE Id = :signatureRequestId 
                LIMIT 1
            ];

            // Prepare sync payload
            Map<String, Object> syncPayload = prepareCRMPayload(request, crmSystem);

            // Call CRM API
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:' + crmSystem + '_CRM/signature-records');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', getCRMAuthHeader(crmSystem));
            req.setBody(JSON.serialize(syncPayload));

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                Map<String, Object> crmResponse = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());

                // Create sync record
                CRM_Sync_Record__c syncRecord = new CRM_Sync_Record__c(
                    Signature_Request__c = signatureRequestId,
                    CRM_System__c = crmSystem,
                    CRM_Record_Id__c = (String)crmResponse.get('id'),
                    Sync_Status__c = 'Success',
                    Sync_Date__c = System.now(),
                    CRM_Response__c = JSON.serialize(crmResponse),
                    Sync_Direction__c = 'Salesforce_to_CRM'
                );
                insert syncRecord;

                // Update signature request
                request.CRM_Sync_Status__c = 'Synced';
                request.CRM_Record_Id__c = (String)crmResponse.get('id');
                update request;

                AuditTrailManager.logSystemActivity(
                    'CRM_SYNC_SUCCESS',
                    'Signature request synced to ' + crmSystem + ' with ID: ' + crmResponse.get('id')
                );

                return new SyncResult(true, 'Sync completed successfully', syncRecord);

            } else {
                throw new CalloutException('CRM sync failed: HTTP ' + res.getStatusCode() + ' - ' + res.getBody());
            }

        } catch (Exception e) {
            AuditTrailManager.logSystemActivity('CRM_SYNC_ERROR', 'CRM sync failed: ' + e.getMessage());

            CRM_Sync_Record__c failedSyncRecord = new CRM_Sync_Record__c(
                Signature_Request__c = signatureRequestId,
                CRM_System__c = crmSystem,
                Sync_Status__c = 'Failed',
                Sync_Date__c = System.now(),
                Error_Message__c = e.getMessage(),
                Retry_Count__c = 0,
                Next_Retry_Date__c = System.now().addMinutes(15),
                Sync_Direction__c = 'Salesforce_to_CRM'
            );
            insert failedSyncRecord;

            return new SyncResult(false, 'CRM sync failed: ' + e.getMessage(), failedSyncRecord);
        }
    }

    @AuraEnabled
    public static BatchSyncResult synchronizeBulkSignatures(List<Id> signatureRequestIds, String crmSystem) {
        BatchSyncResult batchResult = new BatchSyncResult();
        batchResult.totalRecords = signatureRequestIds.size();
        batchResult.successfulSyncs = new List<CRM_Sync_Record__c>();
        batchResult.failedSyncs = new List<CRM_Sync_Record__c>();

        for (Id requestId : signatureRequestIds) {
            try {
                SyncResult individualResult = synchronizeSignatureData(requestId, crmSystem);
                if (individualResult.success) {
                    batchResult.successfulSyncs.add(individualResult.syncRecord);
                } else {
                    batchResult.failedSyncs.add(individualResult.syncRecord);
                }
            } catch (Exception e) {
                CRM_Sync_Record__c failedRecord = new CRM_Sync_Record__c(
                    Signature_Request__c = requestId,
                    CRM_System__c = crmSystem,
                    Sync_Status__c = 'Failed',
                    Error_Message__c = e.getMessage(),
                    Sync_Date__c = System.now()
                );
                batchResult.failedSyncs.add(failedRecord);
            }
        }

        batchResult.successCount = batchResult.successfulSyncs.size();
        batchResult.failureCount = batchResult.failedSyncs.size();

        return batchResult;
    }

    private static Map<String, Object> prepareCRMPayload(Signature_Request__c request, String crmSystem) {
        Map<String, Object> payload = new Map<String, Object>();

        switch on crmSystem.toLowerCase() {
            when 'salesforce' {
                payload.put('Name', request.DocumentLifecycleConfiguration__r.DocumentTitle__c);
                payload.put('Type', 'E-Signature Document');
                payload.put('Status', request.Status__c);
                payload.put('Signer_Email__c', request.Signer_Email__c);
                payload.put('Completion_Date__c', request.Completion_Date__c);
            }
            when 'hubspot' {
                payload.put('properties', new Map<String, Object>{
                    'document_title' => request.DocumentLifecycleConfiguration__r.DocumentTitle__c,
                    'signature_status' => request.Status__c,
                    'signer_email' => request.Signer_Email__c,
                    'completion_date' => request.Completion_Date__c,
                    'document_type' => request.DocumentLifecycleConfiguration__r.ContractType__c
                });
            }
            when 'pipedrive' {
                payload.put('title', request.DocumentLifecycleConfiguration__r.DocumentTitle__c);
                payload.put('status', request.Status__c);
                payload.put('person_id', getPersonIdByEmail(request.Signer_Email__c, 'pipedrive'));
                payload.put('completion_date', request.Completion_Date__c);
            }
            when else {
                payload.put('document_title', request.DocumentLifecycleConfiguration__r.DocumentTitle__c);
                payload.put('signature_status', request.Status__c);
                payload.put('signer_email', request.Signer_Email__c);
                payload.put('signer_name', request.Signer_Name__c);
                payload.put('completion_date', request.Completion_Date__c);
                payload.put('document_hash', request.Document_Hash__c);
                payload.put('signature_method', request.Signature_Method__c);
            }
        }

        return payload;
    }

    private static String getCRMAuthHeader(String crmSystem) {
        switch on crmSystem.toLowerCase() {
            when 'salesforce' { return 'Bearer {!$Credential.Salesforce_CRM.AccessToken}'; }
            when 'hubspot' { return 'Bearer {!$Credential.HubSpot_CRM.APIKey}'; }
            when 'pipedrive' { return 'Bearer {!$Credential.Pipedrive_CRM.APIToken}'; }
            when else { return 'Bearer {!$Credential.' + crmSystem + '_CRM.APIKey}'; }
        }
    }

    public class SyncResult {
        public Boolean success;
        public String message;
        public CRM_Sync_Record__c syncRecord;

        public SyncResult(Boolean success, String message, CRM_Sync_Record__c syncRecord) {
            this.success = success;
            this.message = message;
            this.syncRecord = syncRecord;
        }
    }

    public class BatchSyncResult {
        public Integer totalRecords;
        public Integer successCount;
        public Integer failureCount;
        public List<CRM_Sync_Record__c> successfulSyncs;
        public List<CRM_Sync_Record__c> failedSyncs;
    }
        @InvocableMethod(label='Sync to CRM')
    public static void syncSignatureRequestToCRM(List<String> signatureRequestIds) {
        for (String requestId : signatureRequestIds) {
            syncToCRMAsync(requestId);
        }
    }
    
    @Future(callout=true)
    public static void syncToCRMAsync(String signatureRequestId) {
        try {
            // Get signature request details
            Signature_Request__c sigRequest = [
                SELECT Id, SignerEmail__c, SignerName__c, DocumentId__c, Status__c, 
                       CompletedDate__c, Document_Title__c
                FROM Signature_Request__c 
                WHERE Id = :signatureRequestId
            ];
            
            // Prepare CRM payload
            Map<String, Object> crmData = new Map<String, Object>{
                'contact_email' => sigRequest.SignerEmail__c,
                'contact_name' => sigRequest.SignerName__c,
                'document_title' => sigRequest.Document_Title__c,
                'signature_status' => sigRequest.Status__c,
                'completion_date' => sigRequest.CompletedDate__c,
                'source' => 'E-Signature System',
                'custom_fields' => new Map<String, Object>{
                    'signature_request_id' => signatureRequestId,
                    'document_id' => sigRequest.DocumentId__c
                }
            };
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:CRM_System/contacts');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer ' + getCRMToken());
            request.setBody(JSON.serialize(crmData));
            
            HttpResponse response = http.send(request);
            
            // Log sync result
            CRM_Sync_Log__c syncLog = new CRM_Sync_Log__c();
            syncLog.Signature_Request__c = signatureRequestId;
            syncLog.Sync_Status__c = response.getStatusCode() < 300 ? 'Success' : 'Failed';
            syncLog.Response_Code__c = response.getStatusCode();
            syncLog.Response_Body__c = response.getBody();
            syncLog.Sync_Date__c = System.now();
            insert syncLog;
            
        } catch (Exception e) {
            System.debug('CRM sync error: ' + e.getMessage());
            // Log error
            CRM_Sync_Log__c errorLog = new CRM_Sync_Log__c();
            errorLog.Signature_Request__c = signatureRequestId;
            errorLog.Sync_Status__c = 'Error';
            errorLog.Error_Message__c = e.getMessage();
            errorLog.Sync_Date__c = System.now();
            insert errorLog;
        }
    }
    
    private static String getCRMToken() {
        CRM_Integration_Settings__c settings = CRM_Integration_Settings__c.getOrgDefaults();
        return settings.Access_Token__c;
    }

}

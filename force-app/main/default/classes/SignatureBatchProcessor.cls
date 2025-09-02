public class SignatureBatchProcessor implements Database.Batchable<sObject>, Database.Stateful {
    
    private String operationType;
    private Integer processedRecords = 0;
    private Integer errorCount = 0;
    
    public SignatureBatchProcessor(String operation) {
        this.operationType = operation;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query;
        
        switch on operationType {
            when 'EXPIRE_PENDING_REQUESTS' {
                // Find signature requests pending for more than 30 days
                query = 'SELECT Id, Status__c, CreatedDate FROM Signature_Request__c ' +
                    'WHERE Status__c = \'Pending\' AND CreatedDate < LAST_N_DAYS:30';
            }
            when 'CLEANUP_COMPLETED_REQUESTS' {
                // Find completed requests older than 365 days for archival
                query = 'SELECT Id, Status__c, CompletedDate__c FROM Signature_Request__c ' +
                    'WHERE Status__c = \'Signed\' AND CompletedDate__c < LAST_N_DAYS:365';
            }
            when 'GENERATE_ANALYTICS_SNAPSHOT' {
                // Process all documents for analytics
                query = 'SELECT Id, Region__c, ContractType__c, ProcessingStatus__c, ' +
                    'CreatedDate FROM DocumentLifecycleConfiguration__c';
            }
            when else {
                throw new BatchProcessorException('Unknown operation type: ' + operationType);
            }
        }
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> records) {
        List<sObject> recordsToUpdate = new List<sObject>();
        List<Analytics_Snapshot__c> snapshots = new List<Analytics_Snapshot__c>();
        
        try {
            switch on operationType {
                when 'EXPIRE_PENDING_REQUESTS' {
                    for (Signature_Request__c request : (List<Signature_Request__c>) records) {
                        request.Status__c = 'Expired';
                        request.ExpiredDate__c = System.now();
                        recordsToUpdate.add(request);
                        
                        // Log expiration
                        AuditTrailManager.logDocumentActivity(
                            request.DocumentId__c,
                        'Request Expired',
                        'Signature request expired after 30 days'
                            );
                    }
                }
                when 'CLEANUP_COMPLETED_REQUESTS' {
                    for (Signature_Request__c request : (List<Signature_Request__c>) records) {
                        request.Status__c = 'Archived';
                        request.ArchivedDate__c = System.now();
                        recordsToUpdate.add(request);
                    }
                }
                when 'GENERATE_ANALYTICS_SNAPSHOT' {
                    Date snapshotDate = Date.today();
                    for (DocumentLifecycleConfiguration__c doc : (List<DocumentLifecycleConfiguration__c>) records) {
                        Analytics_Snapshot__c snapshot = new Analytics_Snapshot__c(
                            DocumentId__c = doc.Id,
                        SnapshotDate__c = snapshotDate,
                        Region__c = doc.Region__c,
                        ContractType__c = doc.ContractType__c,
                        ProcessingStatus__c = doc.ProcessingStatus__c,
                        CreatedMonth__c = doc.CreatedDate.month(),
                        CreatedYear__c = doc.CreatedDate.year()
                            );
                        snapshots.add(snapshot);
                    }
                }
            }
            
            // Perform DML operations
            if (!recordsToUpdate.isEmpty()) {
                update recordsToUpdate;
                processedRecords += recordsToUpdate.size();
            }
            
            if (!snapshots.isEmpty()) {
                insert snapshots;
                processedRecords += snapshots.size();
            }
            
        } catch (Exception e) {
            errorCount += records.size();
            System.debug('Batch processing error: ' + e.getMessage());
            
            // Log batch errors
            for (sObject record : records) {
                AuditTrailManager.logDocumentActivity(
                    (String) record.get('Id'),
                'Batch Error',
                'Batch processing failed: ' + e.getMessage()
                    );
            }
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        AsyncApexJob job = [
        SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
        FROM AsyncApexJob 
        WHERE Id = :bc.getJobId()
    ];
        
        System.debug('Batch job completed - Operation: ' + operationType);
        System.debug('Records processed: ' + processedRecords);
        System.debug('Errors encountered: ' + errorCount);
        
        // Send completion notification to administrators
        sendBatchCompletionEmail(job);
        
        // Schedule next batch if needed
        if (operationType == 'EXPIRE_PENDING_REQUESTS') {
            // Schedule next expiration batch for tomorrow
            SignatureBatchScheduler scheduler = new SignatureBatchScheduler('EXPIRE_PENDING_REQUESTS');
            String cronExp = '0 0 2 * * ?'; // Run daily at 2 AM
            System.schedule('Daily Signature Expiration - ' + System.now().format(), cronExp, scheduler);
        }
    }
    
    private void sendBatchCompletionEmail(AsyncApexJob job) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{'admin@company.com'}); // Configure as needed
            email.setSubject('E-Signature Batch Processing Complete - ' + operationType);
            
            String emailBody = 'Batch processing has completed with the following results:\n\n' +
                'Operation: ' + operationType + '\n' +
                'Status: ' + job.Status + '\n' +
                'Records Processed: ' + job.JobItemsProcessed + '\n' +
                'Total Job Items: ' + job.TotalJobItems + '\n' +
                'Errors: ' + job.NumberOfErrors + '\n' +
                'Completion Time: ' + System.now().format();
            
            email.setPlainTextBody(emailBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            
        } catch (Exception e) {
            System.debug('Failed to send batch completion email: ' + e.getMessage());
        }
    }
    
    public class BatchProcessorException extends Exception {}

    private List<String> getAdminEmails() {
        List<String> adminEmails = new List<String>();
        try {
            List<User> admins = [
                SELECT Email 
                FROM User 
                WHERE Profile.Name = 'System Administrator' AND IsActive = true 
                LIMIT 5
            ];
            for (User admin : admins) {
                adminEmails.add(admin.Email);
            }
        } catch (Exception e) {
            System.debug('Failed to get admin emails: ' + e.getMessage());
            adminEmails.add('admin@yourorg.com'); // Fallback
        }
        return adminEmails;
    }

    private void sendBatchErrorNotification(String summary) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(getAdminEmails());
            email.setSubject('E-Signature Batch Operation Error Report');
            email.setPlainTextBody(summary + '\n\nErrors:\n' + String.join(errorMessages, '\n'));
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
        } catch (Exception e) {
            System.debug('Failed to send batch error notification: ' + e.getMessage());
        }
    }
     private void generatePerformanceReports(List<Signature_Request__c> requests) {
        try {
            Map<String, Integer> statusCounts = new Map<String, Integer>();
            Map<String, Integer> methodCounts = new Map<String, Integer>();
            
            for (Signature_Request__c request : requests) {
                recordsProcessed++;
                String status = request.Status__c;
                statusCounts.put(status, statusCounts.get(status) == null ? 1 : statusCounts.get(status) + 1);
                
                if (request.SignatureMethod__c != null) {
                    String method = request.SignatureMethod__c;
                    methodCounts.put(method, methodCounts.get(method) == null ? 1 : methodCounts.get(method) + 1);
                }
            }
            
            Performance_Report__c report = new Performance_Report__c(
                Name = 'Monthly Report - ' + System.now().format('yyyy-MM-dd'),
                Report_Date__c = System.today(),
                Total_Requests__c = recordsProcessed,
                Status_Breakdown__c = JSON.serialize(statusCounts),
                Method_Breakdown__c = JSON.serialize(methodCounts),
                Generated_By_Batch__c = true
            );
            insert report;
            
            recordsSucceeded = recordsProcessed;
            System.debug('✓ Performance report generated: ' + report.Id);
        } catch (Exception e) {
            recordsFailed += requests.size();
            errorMessages.add('Batch error in generatePerformanceReports: ' + e.getMessage());
        }
    }
     private void cleanupAuditTrail(List<AuditTrail__c> auditRecords) {
        try {
            recordsProcessed += auditRecords.size();
            Database.DeleteResult[] results = Database.delete(auditRecords, false);
            
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    recordsSucceeded++;
                } else {
                    recordsFailed++;
                    errorMessages.add(
                        'Failed to delete audit record ' + auditRecords[i].Id + 
                        ': ' + results[i].getErrors()[0].getMessage()
                    );
                }
            }
        } catch (Exception e) {
            recordsFailed += auditRecords.size();
            errorMessages.add('Batch error in cleanupAuditTrail: ' + e.getMessage());
        }
    }
    private void sendReminderNotifications(List<Signature_Request__c> requests) {
        try {
            for (Signature_Request__c request : requests) {
                recordsProcessed++;
                try {
                    EmailNotificationService.sendReminderNotification(request.Id);
                    recordsSucceeded++;
                } catch (Exception e) {
                    recordsFailed++;
                    errorMessages.add(
                        'Failed to send reminder for request ' + request.Id + 
                        ': ' + e.getMessage()
                    );
                }
            }
        } catch (Exception e) {
            recordsFailed += requests.size();
            errorMessages.add('Batch error in sendReminderNotifications: ' + e.getMessage());
        }
    }
    private void expireSignatureRequests(List<Signature_Request__c> requests) {
        try {
            for (Signature_Request__c request : requests) {
                request.Status__c = 'Expired';
                recordsProcessed++;
            }
            
            Database.SaveResult[] results = Database.update(requests, false);
            
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    recordsSucceeded++;
                    try {
                        EmailNotificationService.sendExpirationNotification(requests[i].Id);
                    } catch (Exception e) {
                        System.debug('Failed to send expiration notification: ' + e.getMessage());
                    }
                } else {
                    recordsFailed++;
                    errorMessages.add(
                        'Failed to expire request ' + requests[i].Id + 
                        ': ' + results[i].getErrors()[0].getMessage()
                    );
                }
            }
        } catch (Exception e) {
            recordsFailed += requests.size();
            errorMessages.add('Batch error in expireSignatureRequests: ' + e.getMessage());
        }
    }
}
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
}

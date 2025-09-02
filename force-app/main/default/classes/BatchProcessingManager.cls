public class BatchProcessingManager implements Database.Batchable<SObject>, Database.Stateful {
    private String batchType;
    private Integer batchSize;
    private Map<String, Object> batchParameters;
    private List<String> processingResults;
    private Integer successCount = 0;
    private Integer failureCount = 0;
    
    public BatchProcessingManager(String batchType, Integer batchSize, Map<String, Object> parameters) {
        this.batchType = batchType;
        this.batchSize = batchSize;
        this.batchParameters = parameters;
        this.processingResults = new List<String>();
    }
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        String query = buildBatchQuery();
        System.debug('Starting batch process: ' + batchType + ' with query: ' + query);
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        try {
            switch on batchType {
                when 'DOCUMENT_INTELLIGENCE_ANALYSIS' {
                    processDocumentIntelligenceBatch((List<DocumentLifecycleConfiguration__c>)scope);
                }
                when 'FRAUD_DETECTION_ANALYSIS' {
                    processFraudDetectionBatch((List<Signature_Request__c>)scope);
                }
                when 'PERFORMANCE_ANALYTICS' {
                    processPerformanceAnalyticsBatch((List<Signature_Request__c>)scope);
                }
                when 'USER_BEHAVIOR_ANALYSIS' {
                    processUserBehaviorBatch((List<Signature_Request__c>)scope);
                }
                when 'COMPLIANCE_VERIFICATION' {
                    processComplianceVerificationBatch((List<DocumentLifecycleConfiguration__c>)scope);
                }
                when 'SECURITY_ASSESSMENT_CLEANUP' {
                    processSecurityCleanupBatch((List<Security_Assessment__c>)scope);
                }
                when else {
                    throw new BatchProcessingException('Unknown batch type: ' + batchType);
                }
            }
        } catch (Exception e) {
            failureCount += scope.size();
            processingResults.add('Batch execution failed: ' + e.getMessage());
            System.debug('Batch processing error: ' + e.getMessage());
        }
    }
    
    public void finish(Database.BatchableContext context) {
        BatchProcessingReport report = new BatchProcessingReport();
        report.batchType = this.batchType;
        report.batchJobId = context.getJobId();
        report.completionTime = System.now();
        report.totalRecordsProcessed = successCount + failureCount;
        report.successCount = successCount;
        report.failureCount = failureCount;
        report.processingResults = this.processingResults;
        
        storeBatchReport(report);
        
        if (failureCount > 0) {
            sendBatchFailureNotification(report);
        }
        
        System.debug('Batch process completed: ' + JSON.serialize(report));
    }
    
    private String buildBatchQuery() {
        switch on batchType {
            when 'DOCUMENT_INTELLIGENCE_ANALYSIS' {
                return 'SELECT Id, DocumentContent__c, ContractType__c, DocumentTitle__c, CreatedDate ' +
                    'FROM DocumentLifecycleConfiguration__c ' +
                    'WHERE Document_Intelligence_Analyzed__c = false ' +
                    'AND DocumentContent__c != null ' +
                    'ORDER BY CreatedDate DESC';
            }
            when 'FRAUD_DETECTION_ANALYSIS' {
                Integer lookbackDays = (Integer)batchParameters.get('lookbackDays');
                return 'SELECT Id, SignerEmail__c, SigningLocation__c, DeviceFingerprint__c, ' +
                    'CreatedDate, IP_Address__c, User_Agent__c, SignatureMethod__c, ' +
                    'Time_To_Complete_Hours__c, Session_Duration_Minutes__c ' +
                    'FROM Signature_Request__c ' +
                    'WHERE CreatedDate >= LAST_N_DAYS:' + lookbackDays + ' ' +
                    'AND Fraud_Analysis_Completed__c = false ' +
                    'ORDER BY CreatedDate DESC';
            }
            when 'PERFORMANCE_ANALYTICS' {
                return 'SELECT Id, CreatedDate, Status__c, Time_To_Complete_Hours__c, ' +
                    'SignatureMethod__c, DocumentId__r.ContractType__c, SignerEmail__c ' +
                    'FROM Signature_Request__c ' +
                    'WHERE CreatedDate >= LAST_N_DAYS:30 ' +
                    'AND Performance_Analytics_Updated__c = false ' +
                    'ORDER BY CreatedDate DESC';
            }
            when 'USER_BEHAVIOR_ANALYSIS' {
                return 'SELECT Id, SignerEmail__c, SignatureMethod__c, SigningLocation__c, ' +
                    'Time_To_Complete_Hours__c, Session_Duration_Minutes__c, CreatedDate ' +
                    'FROM Signature_Request__c ' +
                    'WHERE CreatedDate >= LAST_N_DAYS:90 ' +
                    'AND Behavior_Analysis_Completed__c = false ' +
                    'ORDER BY SignerEmail__c, CreatedDate DESC';
            }
            when 'COMPLIANCE_VERIFICATION' {
                return 'SELECT Id, DocumentContent__c, ContractType__c, Region__c, ' +
                    'Overall_Compliance_Score__c, DocumentTitle__c ' +
                    'FROM DocumentLifecycleConfiguration__c ' +
                    'WHERE Compliance_Verification_Date__c < LAST_N_DAYS:30 ' +
                    'OR Compliance_Verification_Date__c = null ' +
                    'ORDER BY CreatedDate DESC';
            }
            when 'SECURITY_ASSESSMENT_CLEANUP' {
                Integer retentionDays = (Integer)batchParameters.get('retentionDays');
                return 'SELECT Id, Assessment_Timestamp__c, Risk_Level__c ' +
                    'FROM Security_Assessment__c ' +
                    'WHERE Assessment_Timestamp__c < LAST_N_DAYS:' + retentionDays + ' ' +
                    'AND Risk_Level__c IN (\'LOW\', \'MEDIUM\') ' +
                    'ORDER BY Assessment_Timestamp__c ASC';
            }
            when else {
                throw new BatchProcessingException('Unknown batch type for query building: ' + batchType);
            }
        }
    }
    
    private void processDocumentIntelligenceBatch(List<DocumentLifecycleConfiguration__c> documents) {
        for (DocumentLifecycleConfiguration__c document : documents) {
            try {
                DocumentIntelligenceService.DocumentExtractionResult extractionResult =
                    DocumentIntelligenceService.extractDocumentData(document.Id);
                DocumentIntelligenceService.DocumentAnalysisResult analysisResult =
                    DocumentIntelligenceService.analyzeDocumentComplexity(document.Id);
                
                if (extractionResult.success && analysisResult.success) {
                    document.Document_Intelligence_Analyzed__c = true;
                    document.Intelligence_Analysis_Date__c = System.now();
                    document.Extraction_Confidence__c = extractionResult.confidence;
                    document.Complexity_Level__c = analysisResult.complexityLevel;
                    document.Readability_Score__c = analysisResult.fleschReadingEase;
                    successCount++;
                    processingResults.add('Document ' + document.Id + ' analyzed successfully');
                } else {
                    failureCount++;
                    processingResults.add('Document ' + document.Id + ' analysis failed');
                }
            } catch (Exception e) {
                failureCount++;
                processingResults.add('Document ' + document.Id + ' processing error: ' + e.getMessage());
            }
        }
        
        try {
            update documents;
        } catch (Exception e) {
            processingResults.add('Batch update failed: ' + e.getMessage());
        }
    }
    
    private void processFraudDetectionBatch(List<Signature_Request__c> requests) {
        for (Signature_Request__c request : requests) {
            try {
                AdvancedSecurityEngine.SecurityAssessmentResult assessment =
                    AdvancedSecurityEngine.performSecurityAssessment(request.Id);
                
                if (assessment.success) {
                    request.Fraud_Analysis_Completed__c = true;
                    request.Fraud_Analysis_Date__c = System.now();
                    request.Fraud_Risk_Score__c = assessment.totalRiskScore;
                    request.Fraud_Risk_Level__c = assessment.riskLevel;
                    successCount++;
                    processingResults.add('Fraud analysis completed for request ' + request.Id);
                } else {
                    failureCount++;
                    processingResults.add('Fraud analysis failed for request ' + request.Id);
                }
            } catch (Exception e) {
                failureCount++;
                processingResults.add('Fraud analysis error for request ' + request.Id + ': ' + e.getMessage());
            }
        }
        
        try {
            update requests;
        } catch (Exception e) {
            processingResults.add('Fraud detection batch update failed: ' + e.getMessage());
        }
    }
    
    private void processPerformanceAnalyticsBatch(List<Signature_Request__c> requests) {
        Map<String, PerformanceMetrics> metricsMap = new Map<String, PerformanceMetrics>();
        
        for (Signature_Request__c request : requests) {
            try {
                String metricKey = request.DocumentId__r.ContractType__c + '_' +
                    String.valueOf(request.CreatedDate.date().month()) + '_' +
                    String.valueOf(request.CreatedDate.date().year());
                
                if (!metricsMap.containsKey(metricKey)) {
                    metricsMap.put(metricKey, new PerformanceMetrics());
                }
                
                PerformanceMetrics metrics = metricsMap.get(metricKey);
                metrics.totalRequests++;
                metrics.totalCompletionTime += (request.Time_To_Complete_Hours__c ?? 0);
                
                if (request.Status__c == 'Completed') {
                    metrics.completedRequests++;
                }
                
                request.Performance_Analytics_Updated__c = true;
                request.Performance_Update_Date__c = System.now();
                successCount++;
            } catch (Exception e) {
                failureCount++;
                processingResults.add('Performance analytics error for request ' + request.Id + ': ' + e.getMessage());
            }
        }
        
        storePerformanceMetrics(metricsMap);
        
        try {
            update requests;
        } catch (Exception e) {
            processingResults.add('Performance analytics batch update failed: ' + e.getMessage());
        }
    }
    
    private void processUserBehaviorBatch(List<Signature_Request__c> requests) {
        Map<String, UserBehaviorProfile> behaviorProfiles = new Map<String, UserBehaviorProfile>();
        
        for (Signature_Request__c request : requests) {
            try {
                String userKey = request.SignerEmail__c;
                
                if (!behaviorProfiles.containsKey(userKey)) {
                    behaviorProfiles.put(userKey, new UserBehaviorProfile(userKey));
                }
                
                UserBehaviorProfile profile = behaviorProfiles.get(userKey);
                profile.addSigningEvent(request);
                
                request.Behavior_Analysis_Completed__c = true;
                request.Behavior_Analysis_Date__c = System.now();
                successCount++;
            } catch (Exception e) {
                failureCount++;
                processingResults.add('User behavior analysis error for request ' + request.Id + ': ' + e.getMessage());
            }
        }
        
        storeBehaviorProfiles(behaviorProfiles);
        
        try {
            update requests;
        } catch (Exception e) {
            processingResults.add('User behavior batch update failed: ' + e.getMessage());
        }
    }
    
    private void processComplianceVerificationBatch(List<DocumentLifecycleConfiguration__c> documents) {
        for (DocumentLifecycleConfiguration__c document : documents) {
            try {
                AdvancedSecurityEngine.ComplianceVerificationResult verification =
                    AdvancedSecurityEngine.verifyAdvancedCompliance(document.Id, document.Region__c);
                
                if (verification.success) {
                    document.Compliance_Verification_Date__c = System.now();
                    document.Overall_Compliance_Score__c = verification.overallComplianceScore;
                    document.Compliance_Level__c = verification.complianceLevel;
                    successCount++;
                    processingResults.add('Compliance verification completed for document ' + document.Id);
                } else {
                    failureCount++;
                    processingResults.add('Compliance verification failed for document ' + document.Id + ': ' + verification.errorMessage);
                }
            } catch (Exception e) {
                failureCount++;
                processingResults.add('Compliance verification error for document ' + document.Id + ': ' + e.getMessage());
            }
        }
        
        try {
            update documents;
        } catch (Exception e) {
            processingResults.add('Compliance verification batch update failed: ' + e.getMessage());
        }
    }
    
    
    
    private void processSecurityCleanupBatch(List<Security_Assessment__c> assessments) {
        List<Security_Assessment__c> toDelete = new List<Security_Assessment__c>();
        List<Security_Assessment__c> toArchive = new List<Security_Assessment__c>();
        
        for (Security_Assessment__c assessment : assessments) {
            try {
                // Archive high-risk assessments, delete low-risk ones
                if (assessment.Risk_Level__c == 'LOW') {
                    toDelete.add(assessment);
                } else {
                    assessment.Archived__c = true;
                    assessment.Archive_Date__c = System.now();
                    toArchive.add(assessment);
                }
                
                successCount++;
                processingResults.add('Security assessment ' + assessment.Id + ' processed for cleanup');
            } catch (Exception e) {
                failureCount++;
                processingResults.add('Security assessment cleanup error for ' + assessment.Id + ': ' + e.getMessage());
            }
        }
        
        // Perform cleanup operations
        try {
            if (!toArchive.isEmpty()) {
                update toArchive;
                processingResults.add('Archived ' + toArchive.size() + ' security assessments');
            }
            if (!toDelete.isEmpty()) {
                delete toDelete;
                processingResults.add('Deleted ' + toDelete.size() + ' low-risk security assessments');
            }
        } catch (Exception e) {
            processingResults.add('Security cleanup batch operation failed: ' + e.getMessage());
        }
    }
    
    // Helper methods for batch processing
    private void storeBatchReport(BatchProcessingReport report) {
        try {
            Batch_Processing_Report__c batchReport = new Batch_Processing_Report__c();
            batchReport.Batch_Type__c = report.batchType;
            batchReport.Batch_Job_Id__c = String.valueOf(report.batchJobId);
            batchReport.Completion_Time__c = report.completionTime;
            batchReport.Total_Records_Processed__c = report.totalRecordsProcessed;
            batchReport.Success_Count__c = report.successCount;
            batchReport.Failure_Count__c = report.failureCount;
            batchReport.Processing_Results_JSON__c = JSON.serialize(report.processingResults);
            batchReport.Status__c = report.failureCount > 0 ? 'COMPLETED_WITH_ERRORS' : 'COMPLETED_SUCCESS';
            
            insert batchReport;
        } catch (Exception e) {
            System.debug('Failed to store batch report: ' + e.getMessage());
        }
    }
    
    private void sendBatchFailureNotification(BatchProcessingReport report) {
        try {
            List<String> toAddresses = new List<String>();
            // Get admin email addresses from custom metadata
            List<System_Configuration__mdt> configs = [
SELECT Email_Address__c 
FROM System_Configuration__mdt 
WHERE Type__c = 'ADMIN_NOTIFICATION' 
AND Active__c = true
];
            
            for (System_Configuration__mdt config : configs) {
                if (String.isNotBlank(config.Email_Address__c)) {
                    toAddresses.add(config.Email_Address__c);
                }
            }
            
            if (!toAddresses.isEmpty()) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(toAddresses);
                email.setSubject('Batch Processing Failure Alert - ' + report.batchType);
                email.setPlainTextBody(buildFailureNotificationBody(report));
                
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            }
        } catch (Exception e) {
            System.debug('Failed to send batch failure notification: ' + e.getMessage());
        }
    }
    
    private String buildFailureNotificationBody(BatchProcessingReport report) {
        StringBuilder body = new StringBuilder();
        body.append('Batch Processing Alert\n');
        body.append('===================\n\n');
        body.append('Batch Type: ').append(report.batchType).append('\n');
        body.append('Job ID: ').append(report.batchJobId).append('\n');
        body.append('Completion Time: ').append(report.completionTime.format()).append('\n');
        body.append('Total Records: ').append(report.totalRecordsProcessed).append('\n');
        body.append('Successful: ').append(report.successCount).append('\n');
        body.append('Failed: ').append(report.failureCount).append('\n\n');
        
        if (!report.processingResults.isEmpty()) {
            body.append('Processing Details:\n');
            body.append('------------------\n');
            for (String result : report.processingResults) {
                body.append('• ').append(result).append('\n');
            }
        }
        
        body.append('\nPlease review the batch processing logs and take appropriate action.');
        return body.toString();
    }
    
    private void storePerformanceMetrics(Map<String, PerformanceMetrics> metricsMap) {
        List<Performance_Metric__c> metricsToInsert = new List<Performance_Metric__c>();
        
        for (String key : metricsMap.keySet()) {
            PerformanceMetrics metrics = metricsMap.get(key);
            List<String> keyParts = key.split('_');
            
            Performance_Metric__c metric = new Performance_Metric__c();
            metric.Contract_Type__c = keyParts[0];
            metric.Month__c = Integer.valueOf(keyParts[1]);
            metric.Year__c = Integer.valueOf(keyParts[2]);
            metric.Total_Requests__c = metrics.totalRequests;
            metric.Completed_Requests__c = metrics.completedRequests;
            metric.Completion_Rate__c = metrics.totalRequests > 0 ?
                (Decimal.valueOf(metrics.completedRequests) / Decimal.valueOf(metrics.totalRequests)) * 100 : 0;
            metric.Average_Completion_Time__c = metrics.totalRequests > 0 ?
                metrics.totalCompletionTime / metrics.totalRequests : 0;
            metric.Metric_Date__c = System.now();
            
            metricsToInsert.add(metric);
        }
        
      try {
    upsert metricsToInsert Performance_Unique_Key__c;
    processingResults.add('Stored ' + metricsToInsert.size() + ' performance metrics');
} catch (Exception e) {
    processingResults.add('Failed to store performance metrics: ' + e.getMessage());
}

    }
    
    private void storeBehaviorProfiles(Map<String, UserBehaviorProfile> behaviorProfiles) {
        List<User_Behavior_Profile__c> profilesToUpsert = new List<User_Behavior_Profile__c>();
        
        for (String userKey : behaviorProfiles.keySet()) {
            UserBehaviorProfile profile = behaviorProfiles.get(userKey);
            
            User_Behavior_Profile__c behaviorRecord = new User_Behavior_Profile__c();
            behaviorRecord.User_Email__c = profile.userEmail;
            behaviorRecord.Total_Signatures__c = profile.totalSignatures;
            behaviorRecord.Average_Completion_Time__c = profile.averageCompletionTime;
            behaviorRecord.Preferred_Signature_Method__c = profile.preferredSignatureMethod;
            behaviorRecord.Average_Session_Duration__c = profile.averageSessionDuration;
            behaviorRecord.Risk_Score__c = profile.calculateRiskScore();
            behaviorRecord.Profile_Updated__c = System.now();
            behaviorRecord.Signing_Patterns_JSON__c = JSON.serialize(profile.signingPatterns);
            
            profilesToUpsert.add(behaviorRecord);
        }
        
        try {
            upsert profilesToUpsert User_Email__c;
            processingResults.add('Stored ' + profilesToUpsert.size() + ' user behavior profiles');
        } catch (Exception e) {
            processingResults.add('Failed to store behavior profiles: ' + e.getMessage());
        }
    }
    
    // Supporting classes for batch processing
    public class BatchProcessingReport {
        public String batchType {get; set;}
        public Id batchJobId {get; set;}
        public DateTime completionTime {get; set;}
        public Integer totalRecordsProcessed {get; set;}
        public Integer successCount {get; set;}
        public Integer failureCount {get; set;}
        public List<String> processingResults {get; set;}
        
        public BatchProcessingReport() {
            this.processingResults = new List<String>();
        }
    }
    
    public class PerformanceMetrics {
        public Integer totalRequests = 0;
        public Integer completedRequests = 0;
        public Decimal totalCompletionTime = 0;
    }
    
    public class UserBehaviorProfile {
        public String userEmail {get; set;}
        public Integer totalSignatures = 0;
        public Decimal averageCompletionTime = 0;
        public String preferredSignatureMethod {get; set;}
        public Decimal averageSessionDuration = 0;
        public Map<String, Integer> signingPatterns {get; set;}
        
        public UserBehaviorProfile(String email) {
            this.userEmail = email;
            this.signingPatterns = new Map<String, Integer>();
        }
        
        public void addSigningEvent(Signature_Request__c request) {
            this.totalSignatures++;
            
            if (request.Time_To_Complete_Hours__c != null) {
                this.averageCompletionTime = ((this.averageCompletionTime * (this.totalSignatures - 1)) +
                    request.Time_To_Complete_Hours__c) / this.totalSignatures;
            }
            
            if (request.Session_Duration_Minutes__c != null) {
                this.averageSessionDuration = ((this.averageSessionDuration * (this.totalSignatures - 1)) +
                    request.Session_Duration_Minutes__c) / this.totalSignatures;
            }
            
            // Track signature method preferences
            if (String.isNotBlank(request.SignatureMethod__c)) {
                Integer currentCount = this.signingPatterns.get(request.SignatureMethod__c);
                this.signingPatterns.put(request.SignatureMethod__c, (currentCount ?? 0) + 1);
                
                // Update preferred method
                String mostUsedMethod = '';
                Integer maxCount = 0;
                for (String method : this.signingPatterns.keySet()) {
                    if (this.signingPatterns.get(method) > maxCount) {
                        maxCount = this.signingPatterns.get(method);
                        mostUsedMethod = method;
                    }
                }
                this.preferredSignatureMethod = mostUsedMethod;
            }
        }
        
        public Decimal calculateRiskScore() {
            Decimal riskScore = 0;
            
            // High completion time increases risk
            if (this.averageCompletionTime > 24) {
                riskScore += 20;
            } else if (this.averageCompletionTime > 12) {
                riskScore += 10;
            }
            
            // Very short completion time also increases risk (potential fraud)
            if (this.averageCompletionTime < 0.1) {
                riskScore += 30;
            }
            
            // Low total signatures might indicate new user (higher risk)
            if (this.totalSignatures < 5) {
                riskScore += 15;
            }
            
            // Variable signing patterns might indicate shared accounts
            if (this.signingPatterns.size() > 2) {
                riskScore += 10;
            }
            
            return Math.min(riskScore, 100); // Cap at 100
        }
    }
    
    public class BatchProcessingException extends Exception {}
}
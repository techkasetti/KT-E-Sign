public class AdvancedAnalyticsBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    // Nested Scheduler Class
    public class AdvancedAnalyticsScheduler {
        // Add scheduling logic here if needed
        public AdvancedAnalyticsScheduler() {}
    }

    // Member Variables
    private String batchType;
    private Date analysisDate;

    // Constructor
    public AdvancedAnalyticsBatch(String batchType, Date analysisDate) {
        this.batchType = batchType;
        this.analysisDate = (analysisDate != null) ? analysisDate : System.today().addDays(-1);
    }

    // Safe Insert Method
    public static void safeInsertRecords(List<SObject> records) {
        if (records == null || records.isEmpty()) return;

        Database.SaveResult[] results = Database.insert(records, false);

        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                String allErr = '';
                for (Database.Error err : results[i].getErrors()) {
                    allErr += err.getMessage() + '; ';
                }

                try {
                    Batch_Error_Log__c log = new Batch_Error_Log__c(
                        Record_Type__c = String.valueOf(records[i].getSObjectType()),
                        Error_Message__c = allErr
                    );
                    insert log;
                } catch (Exception e) {
                    System.debug('Failed to log batch error: ' + e.getMessage());
                }
            }
        }
    }

    // Start Method
    public Database.QueryLocator start(Database.BatchableContext bc) {
        switch on batchType {

            when 'DOCUMENT_INTELLIGENCE' {
                return Database.getQueryLocator([
                    SELECT Id, DocumentContent__c, ContractType__c, Region__c
                    FROM DocumentLifecycleConfiguration__c
                    WHERE CreatedDate = :analysisDate
                    AND ML_Analysis_Completed__c = false
                ]);
            }

            when 'FRAUD_DETECTION' {
                return Database.getQueryLocator([
                    SELECT Id, SignerEmail__c, SigningLocation__c, DeviceFingerprint__c,
                           Time_To_Complete_Hours__c, SignatureMethod__c
                    FROM Signature_Request__c
                    WHERE CreatedDate = :analysisDate
                    AND Fraud_Analysis_Completed__c = false
                ]);
            }

            when else {
                // Default empty query to avoid runtime errors
                return Database.getQueryLocator([
                    SELECT Id
                    FROM DocumentLifecycleConfiguration__c
                    WHERE Id = null
                ]);
            }
        }
    }

    // Execute Method
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            switch on batchType {

                when 'DOCUMENT_INTELLIGENCE' {
                    processDocumentIntelligenceBatch((List<DocumentLifecycleConfiguration__c>) scope);
                }

                when 'FRAUD_DETECTION' {
                    processFraudDetectionBatch((List<Signature_Request__c>) scope);
                }

                when 'PERFORMANCE_ANALYTICS' {
                    processPerformanceAnalyticsBatch((List<DocumentLifecycleConfiguration__c>) scope);
                }

                when 'USER_BEHAVIOR_ANALYSIS' {
                    processUserBehaviorAnalysisBatch((List<Signature_Request__c>) scope);
                }
            }

        } catch (Exception e) {
            System.debug('Advanced analytics batch execution error: ' + e.getMessage());

            insert new Analytics_Batch_Log__c(
                Batch_Type__c = batchType,
                Analysis_Date__c = analysisDate,
                Status__c = 'ERROR',
                Error_Message__c = e.getMessage(),
                Processed_Records__c = 0
            );
        }
    }

    // Finish Method
    public void finish(Database.BatchableContext bc) {
        insert new Analytics_Batch_Log__c(
            Batch_Type__c = batchType,
            Analysis_Date__c = analysisDate,
            Status__c = 'COMPLETED',
            Completion_Time__c = System.now()
        );

        scheduleNextBatch();
    }

    // Document Intelligence Batch Processing
    private void processDocumentIntelligenceBatch(List<DocumentLifecycleConfiguration__c> documents) {
        List<ML_Analysis_Result__c> mlResults = new List<ML_Analysis_Result__c>();
        List<DocumentLifecycleConfiguration__c> docsToUpdate = new List<DocumentLifecycleConfiguration__c>();

        for (DocumentLifecycleConfiguration__c doc : documents) {
            try {
                MLIntegrationService.DocumentClassificationResult classification =
                    MLIntegrationService.classifyDocument(doc.DocumentContent__c, doc.ContractType__c);

                if (classification != null && classification.success) {

                    ML_Analysis_Result__c mlResult = new ML_Analysis_Result__c(
                        Document_Id__c = doc.Id,
                        Classification__c = classification.classification,
                        Confidence_Score__c = classification.confidence,
                        Sentiment_Score__c = classification.sentimentScore,
                        Analysis_Date__c = System.now(),
                        Model_Version__c = 'doc-classifier-v3.2'
                    );
                    mlResults.add(mlResult);

                    DocumentLifecycleConfiguration__c docUpdate = new DocumentLifecycleConfiguration__c(
                        Id = doc.Id,
                        ML_Analysis_Completed__c = true,
                        ML_Classification__c = classification.classification,
                        ML_Confidence_Score__c = classification.confidence
                    );
                    docsToUpdate.add(docUpdate);
                }

            } catch (Exception e) {
                System.debug('Document ML analysis error for ID ' + doc.Id + ': ' + e.getMessage());
            }
        }

        if (!mlResults.isEmpty()) insert mlResults;
        if (!docsToUpdate.isEmpty()) update docsToUpdate;
    }

    // Fraud Detection Batch Processing
    private void processFraudDetectionBatch(List<Signature_Request__c> signatureRequests) {
        List<Fraud_Analysis_Result__c> fraudResults = new List<Fraud_Analysis_Result__c>();
        List<Signature_Request__c> requestsToUpdate = new List<Signature_Request__c>();

        for (Signature_Request__c request : signatureRequests) {
            try {
                Map<String, Object> signatureData = new Map<String, Object>{
                    'signerEmail' => request.SignerEmail__c,
                    'signingLocation' => request.SigningLocation__c,
                    'deviceFingerprint' => request.DeviceFingerprint__c,
                    'timeToComplete' => request.Time_To_Complete_Hours__c,
                    'signatureMethod' => request.SignatureMethod__c
                };

                MLIntegrationService.FraudScoringResult fraudResult =
                    MLIntegrationService.calculateFraudScore(signatureData);

                if (fraudResult != null && fraudResult.success) {

                    Fraud_Analysis_Result__c fraudAnalysis = new Fraud_Analysis_Result__c(
                        Signature_Request_Id__c = request.Id,
                        Fraud_Score__c = fraudResult.fraudScore,
                        Risk_Level__c = fraudResult.riskLevel,
                        Confidence__c = fraudResult.confidence,
                        Analysis_Date__c = System.now(),
                        Model_Version__c = 'fraud-detector-v2.8'
                    );
                    fraudResults.add(fraudAnalysis);

                    Signature_Request__c requestUpdate = new Signature_Request__c(
                        Id = request.Id,
                        Fraud_Analysis_Completed__c = true,
                        Fraud_Risk_Level__c = fraudResult.riskLevel,
                        Fraud_Score__c = fraudResult.fraudScore
                    );
                    requestsToUpdate.add(requestUpdate);
                }

            } catch (Exception e) {
                System.debug('Fraud detection error for request ID ' + request.Id + ': ' + e.getMessage());
            }
        }

        if (!fraudResults.isEmpty()) insert fraudResults;
        if (!requestsToUpdate.isEmpty()) update requestsToUpdate;
    }

    // Performance Analytics Batch Processing
    private void processPerformanceAnalyticsBatch(List<DocumentLifecycleConfiguration__c> documents) {
        Decimal totalGenTime = 0;
        Integer validDocuments = 0;
        Map<String, Integer> typeCount = new Map<String, Integer>();
        Map<String, Decimal> typeGenTime = new Map<String, Decimal>();

        for (DocumentLifecycleConfiguration__c doc : documents) {
            if (doc.Generation_Time_Seconds__c != null) {
                totalGenTime += doc.Generation_Time_Seconds__c;
                validDocuments++;

                String contractType = (doc.ContractType__c != null) ? doc.ContractType__c : 'Unknown';

                typeCount.put(contractType, (typeCount.get(contractType) == null ? 0 : typeCount.get(contractType)) + 1);
                typeGenTime.put(contractType, (typeGenTime.get(contractType) == null ? 0 : typeGenTime.get(contractType)) + doc.Generation_Time_Seconds__c);
            }
        }

        Performance_Analytics__c perfRecord = new Performance_Analytics__c(
            Analysis_Date__c = analysisDate,
            Total_Documents_Processed__c = documents.size(),
            Average_Generation_Time__c = (validDocuments > 0 ? totalGenTime / validDocuments : 0),
            Batch_Type__c = 'DOCUMENT_PERFORMANCE',
            Analysis_Completed_At__c = System.now()
        );

        insert perfRecord;
    }

    // User Behavior Analysis Batch Processing
    private void processUserBehaviorAnalysisBatch(List<Signature_Request__c> signatureRequests) {
        Map<String, List<Signature_Request__c>> userRequests = new Map<String, List<Signature_Request__c>>();

        for (Signature_Request__c req : signatureRequests) {
            if (req.SignerEmail__c != null) {
                if (!userRequests.containsKey(req.SignerEmail__c)) {
                    userRequests.put(req.SignerEmail__c, new List<Signature_Request__c>());
                }
                userRequests.get(req.SignerEmail__c).add(req);
            }
        }

        List<User_Behavior_Analysis__c> behaviorAnalyses = new List<User_Behavior_Analysis__c>();

        for (String email : userRequests.keySet()) {

            List<Signature_Request__c> reqList = userRequests.get(email);

            User_Behavior_Analysis__c analysis = new User_Behavior_Analysis__c(
                User_Email__c = email,
                Analysis_Date__c = analysisDate,
                Total_Signature_Requests__c = reqList.size()
            );

            Decimal totalCompletionTime = 0;
            Integer completedRequests = 0;
            Map<String, Integer> methodUsage = new Map<String, Integer>();

            for (Signature_Request__c req : reqList) {
                if (req.Status__c == 'Completed' && req.Time_To_Complete_Hours__c != null) {
                    totalCompletionTime += req.Time_To_Complete_Hours__c;
                    completedRequests++;
                }

                String method = (req.SignatureMethod__c != null) ? req.SignatureMethod__c : 'Unknown';
                methodUsage.put(method, (methodUsage.get(method) == null ? 0 : methodUsage.get(method)) + 1);
            }

            analysis.Completed_Requests__c = completedRequests;
            analysis.Average_Completion_Time__c = (completedRequests > 0 ? totalCompletionTime / completedRequests : 0);
            analysis.Completion_Rate__c = (completedRequests * 100.0) / reqList.size();

            // Preferred method
            String preferredMethod = 'Unknown';
            Integer maxUsage = 0;

            for (String method : methodUsage.keySet()) {
                if (methodUsage.get(method) > maxUsage) {
                    maxUsage = methodUsage.get(method);
                    preferredMethod = method;
                }
            }

            analysis.Preferred_Signature_Method__c = preferredMethod;

            behaviorAnalyses.add(analysis);
        }

        if (!behaviorAnalyses.isEmpty()) insert behaviorAnalyses;
    }

    // Scheduler for Next Batch
    private void scheduleNextBatch() {
        String cronExpression = '0 0 2 * * ?'; // Run at 2 AM daily
        AdvancedAnalyticsScheduler scheduler = new AdvancedAnalyticsScheduler();

        String jobName = 'AdvancedAnalyticsBatch_' +
                         batchType + '_' +
                         System.now().addDays(1).format('yyyyMMdd');
    }
}
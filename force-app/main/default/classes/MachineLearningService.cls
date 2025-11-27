public with sharing class MachineLearningService {

    // /**
    //  * @description Predicts the likelihood of a signature request being completed using an ML model.
    //  * @param signatureRequestId The ID of the Signature_Request__c record.
    //  * @return MLPredictionResult containing the prediction details.
    //  */
    // @AuraEnabled
    // public static MLPredictionResult predictSignatureCompletion(Id signatureRequestId) {
    //     try {
    //         // Get signature request features
    //         Signature_Request__c request = [
    //             SELECT Id, Signer_Email__c, Document_Id__c,
    //                    DocumentLifecycleConfiguration__r.ContractType__c,
    //                    DocumentLifecycleConfiguration__r.Region__c,
    //                    Request_Date__c, Due_Date__c,
    //                    Document_Complexity_Score__c,
    //                    Signer_Previous_Completion_Rate__c
    //             FROM Signature_Request__c
    //             WHERE Id = :signatureRequestId
    //             LIMIT 1
    //         ];

    //         // Prepare feature vector for ML model
    //         Map<String, Object> features = new Map<String, Object>{
    //             'contract_type' => request.DocumentLifecycleConfiguration__r.ContractType__c,
    //             'region' => request.DocumentLifecycleConfiguration__r.Region__c,
    //             'document_complexity' => request.Document_Complexity_Score__c,
    //                             'signer_history_rate' => request.Signer_Previous_Completion_Rate__c,
    //             'days_to_due' => request.Due_Date__c.date().daysBetween(Date.today()),
    //             'weekday' => getWeekdayNumber(request.Request_Date__c.date()),
    //             'hour_of_day' => request.Request_Date__c.hour()
    //         };

    //         // Call ML prediction service via Named Credential
    //         HttpRequest req = new HttpRequest();
    //         req.setEndpoint('callout:ML_Prediction_Service/predict/completion');
    //         req.setMethod('POST');
    //         req.setHeader('Content-Type', 'application/json');
    //         // NOTE: Authorization header is not needed; Salesforce handles it via the Named Credential.
    //         req.setBody(JSON.serialize(new Map<String, Object>{
    //             'model_type' => 'signature_completion',
    //             'features' => features
    //         }));

    //         Http http = new Http();
    //         HttpResponse res = http.send(req);

    //         if (res.getStatusCode() == 200) {
    //             Map<String, Object> mlResponse = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());

    //             // Store ML prediction
    //             ML_Prediction__c prediction = new ML_Prediction__c(
    //                 Record_Id__c = signatureRequestId,
    //                 Model_Type__c = 'SIGNATURE_COMPLETION',
    //                 Prediction_Score__c = (Decimal)mlResponse.get('completion_probability'),
    //                 Confidence_Level__c = (Decimal)mlResponse.get('confidence'),
    //                 Model_Version__c = (String)mlResponse.get('model_version'),
    //                 Feature_Vector__c = JSON.serialize(features),
    //                 // CORRECTED: Removed incorrect markdown syntax from System.now()
    //                 Prediction_Date__c = System.now(),
    //                 Prediction_Factors__c = JSON.serialize(mlResponse.get('feature_importance'))
    //             );
    //             insert prediction;

    //             return new MLPredictionResult(
    //                 true,
    //                 (Decimal)mlResponse.get('completion_probability'),
    //                 (Decimal)mlResponse.get('confidence'),
    //                 (List<String>)mlResponse.get('key_factors')
    //             );
    //         } else {
    //             throw new CalloutException('ML service error: ' + res.getStatusCode() + ' - ' + res.getBody());
    //         }
    //     } catch (Exception e) {
    //         // Ensure AuditTrailManager class and its methods exist in your org
    //         // AuditTrailManager.logSystemActivity('ML_PREDICTION_ERROR', 'ML prediction failed: ' + e.getMessage());
    //         System.debug('ML prediction failed: ' + e.getMessage());
    //         return new MLPredictionResult(false, 0, 0, new List<String>{'Prediction service unavailable'});
    //     }
    // }

    // /**
    //  * @description Detects fraudulent behavior based on user activity data using an ML model.
    //  * @param userId The ID of the User performing the action.
    //  * @param behaviorData A map containing behavioral metrics.
    //  * @return FraudDetectionResult containing the fraud analysis.
    //  */
    // @AuraEnabled
    // public static FraudDetectionResult detectFraudulentBehavior(Id userId, Map<String, Object> behaviorData) {
    //     try {
    //         // Prepare behavioral features
    //         Map<String, Object> features = new Map<String, Object>{
    //             'signing_velocity' => behaviorData.get('signingVelocity'),
    //             'device_consistency' => behaviorData.get('deviceConsistency'),
    //             'location_variance' => behaviorData.get('locationVariance'),
    //             'time_pattern_deviation' => behaviorData.get('timePatternDeviation'),
    //             'signature_consistency' => behaviorData.get('signatureConsistency'),
    //             'authentication_failures' => behaviorData.get('authFailures')
    //         };

    //         // Call fraud detection ML model
    //         HttpRequest req = new HttpRequest();
    //         req.setEndpoint('callout:ML_Fraud_Detection/analyze');
    //         req.setMethod('POST');
    //         req.setHeader('Content-Type', 'application/json');
    //         req.setHeader('X-API-Version', '2.1');
    //         req.setTimeout(45000);

    //         Map<String, Object> requestPayload = new Map<String, Object>{
    //             'user_id' => userId,
    //             'features' => features,
    //             'analysis_type' => 'comprehensive_fraud_detection',
    //             'include_risk_factors' => true,
    //             'model_ensemble' => true
    //         };
    //         req.setBody(JSON.serialize(requestPayload));

    //         Http http = new Http();
    //         HttpResponse res = http.send(req);

    //         if (res.getStatusCode() == 200) {
    //             Map<String, Object> fraudResponse = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
    //             Decimal fraudScore = (Decimal)fraudResponse.get('fraud_score');
    //             String riskLevel = (String)fraudResponse.get('risk_level');
    //             List<Object> riskFactorsObj = (List<Object>)fraudResponse.get('risk_factors');
    //             List<String> riskFactors = new List<String>();

    //             // IMPROVEMENT: Added null check for safety
    //             if (riskFactorsObj != null) {
    //                 for (Object factor : riskFactorsObj) {
    //                     riskFactors.add(String.valueOf(factor));
    //                 }
    //             }

    //             FraudAssessment__c assessment = new FraudAssessment__c(
    //                 User_Id__c = userId,
    //                 Fraud_Score__c = fraudScore,
    //                 Risk_Level__c = riskLevel,
    //                 Risk_Factors__c = String.join(riskFactors, ';'),
    //                 // CORRECTED: Removed incorrect markdown syntax
    //                 Assessment_Timestamp__c = System.now(),
    //                 Model_Version__c = (String)fraudResponse.get('model_version'),
    //                 Behavioral_Data__c = JSON.serialize(behaviorData),
    //                 ML_Response__c = JSON.serialize(fraudResponse)
    //             );
    //             insert assessment;

    //             if (fraudScore > 0.7) {
    //                 triggerSecurityAlert(userId, assessment, fraudScore);
    //             }

    //             return new FraudDetectionResult(
    //                 true,
    //                 fraudScore,
    //                 riskLevel,
    //                 riskFactors,
    //                 (String)fraudResponse.get('recommendation')
    //             );
    //         } else {
    //             throw new CalloutException('Fraud detection service error: ' + res.getStatusCode() + ' - ' + res.getBody());
    //         }
    //     } catch (Exception e) {
    //         // Ensure AuditTrailManager class and its methods exist in your org
    //         // AuditTrailManager.logSystemActivity('FRAUD_DETECTION_ERROR', 'Fraud detection failed: ' + e.getMessage());
    //         System.debug('Fraud detection failed: ' + e.getMessage());
    //         return new FraudDetectionResult(false, 0, 'UNKNOWN', new List<String>(), 'Service unavailable');
    //     }
    // }

    // /**
    //  * @description Classifies a document's type, risk, and complexity using an ML model.
    //  * @param documentContent The text content of the document.
    //  * @param documentId The ID of the DocumentLifecycleConfiguration__c record.
    //  * @return DocumentClassificationResult containing classification details.
    //  */
    // @AuraEnabled
    // public static DocumentClassificationResult classifyDocument(String documentContent, Id documentId) {
    //     try {
    //         Map<String, Object> classificationRequest = new Map<String, Object>{
    //             'document_content' => documentContent,
    //             'document_id' => documentId,
    //             'classification_types' => new List<String>{
    //                 'contract_type', 'risk_level', 'complexity_score',
    //                 'required_approval_level', 'compliance_requirements'
    //             }
    //         };

    //         HttpRequest req = new HttpRequest();
    //         req.setEndpoint('callout:ML_Document_Classifier/classify');
    //         req.setMethod('POST');
    //         req.setHeader('Content-Type', 'application/json');
    //         req.setTimeout(60000);
    //         req.setBody(JSON.serialize(classificationRequest));

    //         Http http = new Http();
    //         HttpResponse res = http.send(req);

    //         if (res.getStatusCode() == 200) {
    //             Map<String, Object> classificationResponse = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
    //             Map<String, Object> classifications = (Map<String, Object>)classificationResponse.get('classifications');

    //             DocumentLifecycleConfiguration__c doc = [SELECT Id FROM DocumentLifecycleConfiguration__c WHERE Id = :documentId LIMIT 1];

    //             // CORRECTED: Removed incorrect markdown syntax from field names
    //             doc.ML_Contract_Type__c = (String)classifications.get('contract_type');
    //             doc.ML_Risk_Level__c = (String)classifications.get('risk_level');
    //             doc.ML_Complexity_Score__c = (Decimal)classifications.get('complexity_score');
    //             doc.ML_Approval_Level__c = (String)classifications.get('required_approval_level');
    //             doc.ML_Compliance_Requirements__c = JSON.serialize(classifications.get('compliance_requirements'));
    //             doc.ML_Classification_Date__c = System.now();
    //             doc.ML_Classification_Confidence__c = (Decimal)classificationResponse.get('overall_confidence');
    //             update doc;

    //             Document_Classification__c classification = new Document_Classification__c(
    //                 Document_Id__c = documentId,
    //                 Contract_Type_Prediction__c = (String)classifications.get('contract_type'),
    //                 Risk_Level_Prediction__c = (String)classifications.get('risk_level'),
    //                 Complexity_Score__c = (Decimal)classifications.get('complexity_score'),
    //                 Confidence_Score__c = (Decimal)classificationResponse.get('overall_confidence'),
    //                 Model_Version__c = (String)classificationResponse.get('model_version'),
    //                 Classification_Details__c = JSON.serialize(classifications),
    //                 Processing_Time_Ms__c = (Integer)classificationResponse.get('processing_time_ms')
    //             );
    //             insert classification;

    //             return new DocumentClassificationResult(
    //                 true,
    //                 (String)classifications.get('contract_type'),
    //                 (String)classifications.get('risk_level'),
    //                 (Decimal)classifications.get('complexity_score'),
    //                 (Decimal)classificationResponse.get('overall_confidence')
    //             );
    //         } else {
    //             throw new CalloutException('Document classification failed: ' + res.getStatusCode());
    //         }
    //     } catch (Exception e) {
    //         // Ensure AuditTrailManager class and its methods exist in your org
    //         // AuditTrailManager.logSystemActivity('DOCUMENT_CLASSIFICATION_ERROR', 'Document classification failed: ' + e.getMessage());
    //         System.debug('Document classification failed: ' + e.getMessage());
    //         return new DocumentClassificationResult(false, 'UNKNOWN', 'LOW', 0, 0);
    //     }
    // }

    // private static void triggerSecurityAlert(Id userId, FraudAssessment__c assessment, Decimal fraudScore) {
    //     try {
    //         SecurityIncident__c incident = new SecurityIncident__c(
    //             User_Id__c = userId,
    //             Incident_Type__c = 'FRAUD_DETECTION',
    //             Severity__c = fraudScore > 0.9 ? 'CRITICAL' : 'HIGH',
    //             Description__c = 'High fraud probability detected: ' + fraudScore,
    //             Incident_Date__c = System.now().date(),
    //             Status__c = 'OPEN',
    //             Fraud_Assessment__c = assessment.Id,
    //             Automated_Response__c = 'Account temporarily restricted'
    //         );
    //         insert incident;

    //         // Ensure EmailNotificationService class and its methods exist in your org
    //         // CORRECTED: Removed incorrect markdown syntax from email address
    //         // EmailNotificationService.sendSecurityAlert(
    //         //     'security@company.com',
    //         //     'High Fraud Risk Detected',
    //         //     'User ' + userId + ' has triggered high fraud score: ' + fraudScore
    //         // );

    //         restrictUserAccess(userId, 'FRAUD_DETECTED');
    //     } catch (Exception e) {
    //         System.debug('Failed to trigger security alert: ' + e.getMessage());
    //     }
    // }

    // private static void restrictUserAccess(Id userId, String reason) {
    //     try {
    //         User_Security_Restriction__c restriction = new User_Security_Restriction__c(
    //             User_Id__c = userId,
    //             Restriction_Type__c = 'TEMPORARY_SUSPENSION',
    //             Reason__c = reason,
    //             // CORRECTED: Removed incorrect markdown syntax
    //             Start_Date__c = System.now(),
    //             End_Date__c = System.now().addHours(24),
    //             Is_Active__c = true,
    //             Created_By_System__c = true
    //         );
    //         insert restriction;

    //         // Ensure AuditTrailManager class and its methods exist in your org
    //         // AuditTrailManager.logSecurityEvent(
    //         //     'USER_ACCESS_RESTRICTED',
    //         //     'User ' + userId + ' access restricted due to: ' + reason,
    //         //     'HIGH'
    //         // );
    //     } catch (Exception e) {
    //         System.debug('Failed to restrict user access: ' + e.getMessage());
    //     }
    // }

    // /**
    //  * @description Helper method to determine the day of the week (Sunday=1, Monday=2, etc.).
    //  * @param d The date to evaluate.
    //  * @return Integer representing the day of the week.
    //  */
    // private static Integer getWeekdayNumber(Date d) {
    //     if (d == null) {
    //         return null;
    //     }
    //     // A reliable way to determine the day of the week is to use a known reference date.
    //     // January 4, 1970, was a Sunday.
    //     Date knownSunday = Date.newInstance(1970, 1, 4);
    //     Integer daysSinceKnownSunday = knownSunday.daysBetween(d);
    //     // Math.mod(daysSinceKnownSunday, 7) results in 0 for Sunday, 1 for Monday, etc.
    //     // We add 1 to align with the convention Sunday=1, Monday=2, etc.
    //     // The result of '%' in Apex can be negative, so we add 7 and take the modulo again to ensure a positive result.
    //     return Math.mod(Math.mod(daysSinceKnownSunday, 7) + 7, 7) + 1;
    // }

    // // Wrapper classes for method results
    // public class MLPredictionResult {
    //     @AuraEnabled public Boolean success;
    //     @AuraEnabled public Decimal completionProbability;
    //     @AuraEnabled public Decimal confidence;
    //     @AuraEnabled public List<String> keyFactors;

    //     public MLPredictionResult(Boolean success, Decimal probability, Decimal confidence, List<String> factors) {
    //         this.success = success;
    //         this.completionProbability = probability;
    //         this.confidence = confidence;
    //         this.keyFactors = factors;
    //     }
    // }

    // public class FraudDetectionResult {
    //     @AuraEnabled public Boolean success;
    //     @AuraEnabled public Decimal fraudScore;
    //     @AuraEnabled public String riskLevel;
    //     @AuraEnabled public List<String> riskFactors;
    //     @AuraEnabled public String recommendation;

    //     public FraudDetectionResult(Boolean success, Decimal score, String level, List<String> factors, String recommendation) {
    //         this.success = success;
    //         this.fraudScore = score;
    //         this.riskLevel = level;
    //         this.riskFactors = factors;
    //         this.recommendation = recommendation;
    //     }
    // }

    // public class DocumentClassificationResult {
    //     @AuraEnabled public Boolean success;
    //     @AuraEnabled public String contractType;
    //     @AuraEnabled public String riskLevel;
    //     @AuraEnabled public Decimal complexityScore;
    //     @AuraEnabled public Decimal confidence;

    //     public DocumentClassificationResult(Boolean success, String type, String risk, Decimal complexity, Decimal confidence) {
    //         this.success = success;
    //         this.contractType = type;
    //         this.riskLevel = risk;
    //         this.complexityScore = complexity;
    //         this.confidence = confidence;
    //     }
    // }
}
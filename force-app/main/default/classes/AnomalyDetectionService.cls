public class AnomalyDetectionService {
    // Result class for anomaly detection
    public class AnomalyResult {
        @AuraEnabled public Boolean isAnomaly;
        @AuraEnabled public Decimal anomalyScore;
        public AnomalyResult(Boolean isAnomaly, Decimal anomalyScore) {
            this.isAnomaly = isAnomaly;
            this.anomalyScore = anomalyScore;
        }
    }
    // Trigger a security alert for high-risk anomalies
    private static void triggerSecurityAlert(Id userId, Decimal anomalyScore) {
        // Example: send notification or log alert
        System.debug('Security alert triggered for user: ' + userId + ', anomaly score: ' + anomalyScore);
    }
    // Log detected security anomaly
    private static void logSecurityAnomaly(Id userId, Decimal anomalyScore, Map<String, Object> behaviorData) {
        // Example: log anomaly to custom object or audit trail
        // Replace with actual implementation as needed
        System.debug('Security anomaly detected for user: ' + userId + ', score: ' + anomalyScore + ', data: ' + JSON.serialize(behaviorData));
    }
    // Helper to prepare feature vector for ML model
    private static List<Decimal> prepareFeaturesVector(Map<String, Object> behaviorData) {
        List<Decimal> features = new List<Decimal>();
        // Example: extract numeric features from behaviorData
        for (String key : behaviorData.keySet()) {
            Object val = behaviorData.get(key);
            if (val instanceof Decimal) {
                features.add((Decimal)val);
            } else if (val instanceof Integer) {
                features.add(Decimal.valueOf((Integer)val));
            }
            // Add more feature extraction logic as needed
        }
        return features;
    }
    @future(callout=true)
    public static void analyzeUserBehavior(String userId, String sessionData) {
        // Prepare feature vectors for ML model
        // Call Einstein Analytics or external ML service
        // Process anomaly detection results
        // Log and alert on detected anomalies
    }
    @AuraEnabled
    public static AnomalyResult detectAnomalies(Id userId, Map<String, Object> behaviorData) {
        List<Decimal> features = prepareFeaturesVector(behaviorData);
        
        // Call external AI/ML service
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:MLService/anomaly-detection');
        request.setMethod('POST');
        request.setBody(JSON.serialize(new Map<String, Object>{
            'features' => features,
            'userId' => userId
        }));
        
        HttpResponse response = http.send(request);
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        
        Boolean isAnomaly = (Boolean) result.get('isAnomaly');
        Decimal anomalyScore = (Decimal) result.get('score');
        
        // Log anomaly if detected
        if (isAnomaly) {
            logSecurityAnomaly(userId, anomalyScore, behaviorData);
            
            // Trigger alert for high-risk anomalies
            if (anomalyScore > 0.8) {
                triggerSecurityAlert(userId, anomalyScore);
            }
        }
        
        return new AnomalyResult(isAnomaly, anomalyScore);
    }







    //     try {
    //         // Prepare feature vector for ML model
    //         Map<String, Object> features = prepareBehaviorFeatures(userId, behaviorData);
            
    //         // Call AI/ML service for anomaly detection
    //         HttpRequest req = new HttpRequest();
    //         req.setEndpoint('callout:AnomalyDetectionAPI/analyze');
    //         req.setMethod('POST');
    //         req.setHeader('Content-Type', 'application/json');
    //         req.setBody(JSON.serialize(features));
            
    //         Http http = new Http();
    //         HttpResponse res = http.send(req);
            
    //         if (res.getStatusCode() == 200) {
    //             Map<String, Object> mlResponse = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                
    //             // Process ML results
    //             Decimal anomalyScore = (Decimal)mlResponse.get('anomaly_score');
    //             String anomalyType = (String)mlResponse.get('anomaly_type');
    //             Boolean isAnomaly = anomalyScore > 0.7;
                
    //             if (isAnomaly) {
    //                 // Log detected anomaly
    //                 AnomalyDetection__c detection = new AnomalyDetection__c(
    //                     User_Id__c = userId,
    //                     Anomaly_Type__c = anomalyType,
    //                     Anomaly_Score__c = anomalyScore,
    //                     Description__c = (String)mlResponse.get('description'),
    //                     Detection_Timestamp__c = System.now(),
    //                     Status__c = 'DETECTED',
    //                     ML_Model_Version__c = (String)mlResponse.get('model_version')
    //                 );
    //                 insert detection;
                    
    //                 // Trigger security alert for high-risk anomalies
    //                 if (anomalyScore > 0.9) {
    //                     EmailNotificationService.sendSecurityAlert(
    //                         'High-Risk Anomaly Detected',
    //                         'User ' + userId + ' shows anomalous behavior: ' + anomalyType
    //                     );
    //                 }
    //             }
                
    //             return new AnomalyResult(isAnomaly, anomalyScore, anomalyType);
    //         }
    //     } catch (Exception e) {
    //         AuditTrailManager.logSystemActivity('ANOMALY_DETECTION_ERROR', e.getMessage());
    //     }
    //     return new AnomalyResult(false, 0, 'Detection failed');
    // }

}
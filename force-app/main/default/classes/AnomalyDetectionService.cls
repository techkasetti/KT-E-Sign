public class AnomalyDetectionService {
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

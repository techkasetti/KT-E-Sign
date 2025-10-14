
public class MLIntegrationService {
    
    private static final String ML_ENDPOINT = 'callout:ML_Service_Endpoint';
    private static final Integer TIMEOUT_SECONDS = 30;
    
    /**
     * Call external ML model for document classification
     */
    public static DocumentClassificationResult classifyDocument(String documentContent, String documentType) {
        DocumentClassificationResult result = new DocumentClassificationResult();
        
        try {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(ML_ENDPOINT + '/document-classification');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer {!$Credential.ML_Service.AccessToken}');
            
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('content', documentContent);
            payload.put('document_type', documentType);
            payload.put('model_version', 'doc-classifier-v3.2');
            
            request.setBody(JSON.serialize(payload));
            request.setTimeout(TIMEOUT_SECONDS * 1000);
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> mlResponse = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                
                result.classification = (String)mlResponse.get('classification');
                result.confidence = (Decimal)mlResponse.get('confidence');
                result.categories = (List<String>)mlResponse.get('categories');
                result.extractedEntities = (List<Object>)mlResponse.get('entities');
                result.sentimentScore = (Decimal)mlResponse.get('sentiment_score');
                result.keyPhrases = (List<String>)mlResponse.get('key_phrases');
                result.success = true;
            } else {
                result.success = false;
                result.errorMessage = 'Classification service failed: ' + response.getBody();
            }
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'ML classification error: ' + e.getMessage();
        }
        
        return result;
    }
    


    
    public static DocumentClassificationResult classifyDocument(String docText) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:ML_Service/classify');
            req.setMethod('POST');
            req.setHeader('Content-Type','application/json');
            req.setBody(JSON.serialize(new Map<String,Object>{'text'=>docText}));
            Http http = new Http();
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 200) {
                // Expect strict JSON schema
                Map<String,Object> body = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
                DocumentClassificationResult out = new DocumentClassificationResult();
                out.success = Boolean.valueOf(body.get('success') == null ? true : (Boolean)body.get('success'));
                out.classification = (String) body.get('classification');
                out.confidence = body.containsKey('confidence') ? ((Decimal)body.get('confidence')) : 0;
                out.keyPhrases = body.containsKey('keyPhrases') ? (List<String>) body.get('keyPhrases') : new List<String>();
                out.rawResponse = res.getBody();
                return out;
            } else {
                // store raw response for human review (AIInsight__c)
                AIInsight__c ai = new AIInsight__c(DocumentId__c = null, Insight_Type__c='CLASSIFY_ERROR', Confidence_Score__c = 0, Insight_Content__c = res.getBody());
                insert ai;
                DocumentClassificationResult out = new DocumentClassificationResult(); out.success=false; out.rawResponse = res.getBody(); return out;
            }
        } catch (Exception e) {
            String raw = 'ML callout failed: ' + e.getMessage();
            AIInsight__c ai = new AIInsight__c(DocumentId__c = null, Insight_Type__c='CLASSIFY_EXCEPTION', Confidence_Score__c = 0, Insight_Content__c = raw);
            try { insert ai; } catch (Exception x) { System.debug('AIInsight insert failed: ' + x.getMessage()); }
            DocumentClassificationResult out = new DocumentClassificationResult(); out.success=false; out.rawResponse = raw; return out;
        }
    }
    /**
     * Call ML model for fraud detection scoring
     */
    public static FraudScoringResult calculateFraudScore(Map<String, Object> signatureData) {
        FraudScoringResult result = new FraudScoringResult();
        
        try {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(ML_ENDPOINT + '/fraud-detection');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer {!$Credential.ML_Service.AccessToken}');
            
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('signature_data', signatureData);
            payload.put('model_version', 'fraud-detector-v2.8');
            payload.put('include_explanations', true);
            
            request.setBody(JSON.serialize(payload));
            request.setTimeout(TIMEOUT_SECONDS * 1000);
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> mlResponse = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                
                result.fraudScore = (Decimal)mlResponse.get('fraud_score');
                result.riskLevel = (String)mlResponse.get('risk_level');
                result.confidence = (Decimal)mlResponse.get('confidence');
                result.riskFactors = (List<String>)mlResponse.get('risk_factors');
                result.recommendations = (List<String>)mlResponse.get('recommendations');
                result.featureContributions = (Map<String, Object>)mlResponse.get('feature_contributions');
                result.success = true;
            } else {
                result.success = false;
                result.errorMessage = 'Fraud detection service failed: ' + response.getBody();
            }
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Fraud detection error: ' + e.getMessage();
        }
        
        return result;
    }
    
    /**
     * Call ML model for predictive analytics
     */
    public static PredictiveAnalyticsResult generatePredictions(String predictionType, Map<String, Object> inputData) {
        PredictiveAnalyticsResult result = new PredictiveAnalyticsResult();
        
        try {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(ML_ENDPOINT + '/predictive-analytics');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer {!$Credential.ML_Service.AccessToken}');
            
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('prediction_type', predictionType);
            payload.put('input_data', inputData);
            payload.put('forecast_horizon', 30); // 30 days
            payload.put('model_version', 'predictor-v1.5');
            
            request.setBody(JSON.serialize(payload));
            request.setTimeout(45000); // Longer timeout for complex predictions
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> mlResponse = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                
                result.predictions = (List<Object>)mlResponse.get('predictions');
                result.accuracy = (Decimal)mlResponse.get('accuracy');
                result.confidenceInterval = (Decimal)mlResponse.get('confidence_interval');
                result.trendDirection = (String)mlResponse.get('trend_direction');
                result.seasonalFactors = (Map<String, Object>)mlResponse.get('seasonal_factors');
                result.recommendations = (List<String>)mlResponse.get('recommendations');
                result.success = true;
            } else {
                result.success = false;
                result.errorMessage = 'Predictive analytics service failed: ' + response.getBody();
            }
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Predictive analytics error: ' + e.getMessage();
        }
        
        return result;
    }


/**
 * Supporting classes for ML Integration
 */
public class DocumentClassificationResult {
    @AuraEnabled public String classification;
    @AuraEnabled public Decimal confidence;
    @AuraEnabled public List<String> categories;
    @AuraEnabled public List<Object> extractedEntities;
    @AuraEnabled public Decimal sentimentScore;
    @AuraEnabled public List<String> keyPhrases;
    @AuraEnabled public Boolean success;
    @AuraEnabled public String errorMessage;
}

public class FraudScoringResult {
    @AuraEnabled public Decimal fraudScore;
    @AuraEnabled public String riskLevel;
    @AuraEnabled public Decimal confidence;
    @AuraEnabled public List<String> riskFactors;
    @AuraEnabled public List<String> recommendations;
    @AuraEnabled public Map<String, Object> featureContributions;
    @AuraEnabled public Boolean success;
    @AuraEnabled public String errorMessage;
}

public class PredictiveAnalyticsResult {
    @AuraEnabled public List<Object> predictions;
    @AuraEnabled public Decimal accuracy;
    @AuraEnabled public Decimal confidenceInterval;
    @AuraEnabled public String trendDirection;
    @AuraEnabled public Map<String, Object> seasonalFactors;
    @AuraEnabled public List<String> recommendations;
    @AuraEnabled public Boolean success;
    @AuraEnabled public String errorMessage;
}
}
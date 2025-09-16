public class BiometricLivenessService {
    @AuraEnabled(cacheable=false)
    public static BiometricValidationResult performLivenessCheck(String sessionId, Blob imageData) {
        try {
            // Create validation record
            BiometricValidation__c validation = new BiometricValidation__c(
                Session_ID__c = sessionId,
                Validation_Type__c = 'Liveness',
                Status__c = 'In Progress',
                Timestamp__c = System.now()
            );
            insert validation;
            
            // Call external biometric service
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:BiometricAPI/liveness/analyze');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBodyAsBlob(imageData);
            request.setTimeout(30000);
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                Decimal livenessScore = (Decimal) result.get('livenessScore');
                Boolean isLive = livenessScore >= 85; // 85% confidence threshold
                
                // Update validation record
                validation.Liveness_Score__c = livenessScore;
                validation.Is_Live__c = isLive;
                validation.Status__c = isLive ? 'Passed' : 'Failed';
                validation.Analysis_Details__c = JSON.serialize(result);
                update validation;
                
                return new BiometricValidationResult(validation.Id, isLive, livenessScore);
            }
        } catch (Exception e) {
            System.debug('Liveness detection error: ' + e.getMessage());
        }
        return new BiometricValidationResult(null, false, 0);
    }
}

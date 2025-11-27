public class BiometricLivenessService {


     public class LivenessResult {
        @AuraEnabled public Id validationId;
        @AuraEnabled public Boolean isLive;
        @AuraEnabled public Decimal confidence;
        @AuraEnabled public String status;
        public LivenessResult(Id id, Boolean isLive, Decimal confidence, String status) {
            this.validationId = id;
            this.isLive = isLive;
            this.confidence = confidence;
            this.status = status;
        }
    }
     @AuraEnabled(cacheable=false)
    public static LivenessResult performLivenessCheck(String imageDataBase64, Id signatureRequestId) {
        BiometricValidation__c validation = new BiometricValidation__c(
            Signature_Request__c = signatureRequestId,
            Validation_Type__c = 'LIVENESS',
            Status__c = 'IN_PROGRESS',
            Timestamp__c = System.now()
        );
        try {
            insert validation;
        } catch (Exception e) {
            // If insert fails, still attempt to callout? Here we abort and return error result
            System.debug('Failed to create BiometricValidation record: ' + e.getMessage());
            return new LivenessResult(null, false, 0, 'ERROR: Could not create validation record');
        }

        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:BiometricAPI/liveness/analyze');
            req.setMethod('POST');
            req.setHeader('Content-Type','application/json');
            req.setBody(JSON.serialize(new Map<String,Object>{ 'image' => imageDataBase64 }));
            req.setTimeout(30000);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                Map<String,Object> parsed = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
                Decimal livenessScore = 0;
                if (parsed.containsKey('livenessScore')) {
                    Object v = parsed.get('livenessScore');
                    if (v instanceof Decimal) livenessScore = (Decimal) v;
                    else if (v instanceof Double) livenessScore = Decimal.valueOf(String.valueOf((Double)v));
                    else if (v instanceof Integer) livenessScore = Decimal.valueOf((Integer)v);
                    else {
                        try { livenessScore = Decimal.valueOf(String.valueOf(v)); } catch(Exception ex){ livenessScore = 0; }
                    }
                }
                Boolean isLive = livenessScore >= 0.85;
                validation.Liveness_Score__c = livenessScore;
                validation.Is_Live__c = isLive;
                validation.Status__c = isLive ? 'PASSED' : 'FAILED';
                validation.Analysis_Details__c = res.getBody();
                update validation;
                return new LivenessResult(validation.Id, isLive, livenessScore, validation.Status__c);
            } else {
                validation.Status__c = 'ERROR';
                validation.Analysis_Details__c = 'HTTP ' + res.getStatusCode() + ' - ' + res.getBody();
                update validation;
                return new LivenessResult(validation.Id, false, 0, 'ERROR');
            }
        } catch (Exception ex) {
            System.debug('Liveness detection exception: ' + ex.getMessage());
            try {
                validation.Status__c = 'ERROR';
                validation.Analysis_Details__c = 'Exception: ' + ex.getMessage();
                update validation;
            } catch (Exception nested) {
                System.debug('Failed to update validation record after exception: ' + nested.getMessage());
            }
            return new LivenessResult(validation.Id, false, 0, 'ERROR');
        }
    }   
}
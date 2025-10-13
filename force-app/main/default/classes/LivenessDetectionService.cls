public class LivenessDetectionService {
    @AuraEnabled
    public static Id enrollBiometricTemplate(Id userId, String modality, Blob biometricBlob, String metaJson) {
  // call external secure biometric enrollment service (callout)
  HttpRequest req = new HttpRequest();
  req.setEndpoint('callout:BiometricService/enroll');
  req.setMethod('POST');
  req.setHeader('Content-Type','application/json');
  Map<String,Object> payload = new Map<String,Object>{
    'userId' => userId,
    'modality' => modality,
    'data' => EncodingUtil.base64Encode(biometricBlob),
    'metadata' => metaJson
  };
  req.setBody(JSON.serialize(payload));
  Http http = new Http();
  HttpResponse resp = http.send(req);
  if (resp.getStatusCode() == 201) {
    Map<String,Object> r = (Map<String,Object>)JSON.deserializeUntyped(resp.getBody());
    Biometric_Template__c t = new Biometric_Template__c(
       User__c = userId,
       Modality__c = modality,
       External_Template_Id__c = (String)r.get('id'),
       Confidence__c = Decimal.valueOf(r.get('confidence'))
    );
    insert t;
    return t.Id;
  } else {
    // throw detailed exception with audit
    throw new AuraHandledException('Biometric enrollment failed: ' + resp.getBody());
  }
}

    @AuraEnabled
    public static LivenessResult performLivenessCheck(String imageData) {
        try {
            // Integrate with biometric service (AWS Rekognition/Azure Face API)
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:BiometricService/liveness');
            request.setMethod('POST');
            request.setBody(JSON.serialize(new Map<String, Object>{
                'image' => imageData,
                'threshold' => 0.85
            }));
            
            HttpResponse response = http.send(request);
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            
            return new LivenessResult(
                (Boolean) result.get('isLive'),
                (Decimal) result.get('confidence'),
                (String) result.get('status')
            );
        } catch (Exception e) {
            System.debug('Liveness detection error: ' + e.getMessage());
            return new LivenessResult(false, 0, 'ERROR');
        }
    }


        @AuraEnabled
    public static LivenessResult performLivenessCheck(String imageData, Id signatureRequestId) {
        try {
            // Integrate with biometric service
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:BiometricAPI/liveness-check');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(new Map<String, Object>{
                'imageData' => imageData,
                'confidence_threshold' => 0.85
            }));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                
                BiometricValidation__c validation = new BiometricValidation__c(
                    Signature_Request__c = signatureRequestId,
                    LivenessScore__c = (Decimal)response.get('liveness_score'),
                    IsLive__c = (Boolean)response.get('is_live'),
                    BiometricHash__c = (String)response.get('biometric_hash'),
                    ValidationTimestamp__c = System.now()
                );
                insert validation;
                
                return new LivenessResult(
                    (Boolean)response.get('is_live'),
                    (Decimal)response.get('liveness_score'),
                    'Liveness validation completed'
                );
            }
        } catch (Exception e) {
            // Log error and return failure
            AuditTrailManager.logSystemActivity('LIVENESS_DETECTION_ERROR', e.getMessage());
            return new LivenessResult(false, 0, 'Liveness detection failed: ' + e.getMessage());
        }
        return new LivenessResult(false, 0, 'Liveness detection service unavailable');
    }

}

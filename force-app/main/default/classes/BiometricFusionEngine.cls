public class BiometricFusionEngine {
    @AuraEnabled(cacheable=false)
    public static FusionResult fuseMultiModalBiometrics(String sessionId, Map<String, Decimal> biometricScores) {
        BiometricFusion__c fusion = new BiometricFusion__c(
            Session_ID__c = sessionId,
            Fusion_Timestamp__c = System.now(),
            Face_Recognition_Score__c = biometricScores.get('faceRecognition'),
            Voice_Recognition_Score__c = biometricScores.get('voiceRecognition'),
            Fingerprint_Score__c = biometricScores.get('fingerprint'),
            Signature_Pattern_Score__c = biometricScores.get('signaturePattern')
        );
        
        // Apply weighted fusion algorithm
        Decimal weightedScore = calculateWeightedFusion(biometricScores);
        fusion.Weighted_Fusion_Score__c = weightedScore;
        
        // Determine authentication level
        if (weightedScore >= 90) {
            fusion.Authentication_Level__c = 'HIGH_CONFIDENCE';
        } else if (weightedScore >= 75) {
            fusion.Authentication_Level__c = 'MEDIUM_CONFIDENCE';
        } else if (weightedScore >= 60) {
            fusion.Authentication_Level__c = 'LOW_CONFIDENCE';
        } else {
            fusion.Authentication_Level__c = 'FAILED';
        }
        
        insert fusion;
        return new FusionResult(fusion.Authentication_Level__c, weightedScore);
    }
    
    private static Decimal calculateWeightedFusion(Map<String, Decimal> scores) {
    // Try to read from Custom Metadata (Biometric_Weights__mdt), fallback to defaults
    Map<String, Decimal> weights = new Map<String, Decimal>{
        'faceRecognition' => 0.35,
        'voiceRecognition' => 0.25,
        'fingerprint' => 0.25,
        'signaturePattern' => 0.15
    };
    try {
        // Example read; implement your metadata type name
        // Biometric_Weight__mdt[] cfg = [SELECT Face__c, Voice__c, Fingerprint__c, Signature__c FROM Biometric_Weight__mdt LIMIT 1];
        // if (!cfg.isEmpty()) { weights.put('faceRecognition', cfg[0].Face__c); ... }
    } catch (Exception e) {
        System.debug('No custom metadata for biometric weights, using defaults');
    }
    Decimal fused = 0;
    for (String k : weights.keySet()) {
        if (scores.containsKey(k) && scores.get(k) != null) fused += scores.get(k) * weights.get(k);
    }
    return Math.min(100, fused * 100); // return 0-100 scale if input scores are 0-1
}
}

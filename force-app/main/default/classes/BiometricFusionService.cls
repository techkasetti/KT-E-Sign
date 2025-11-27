public class BiometricFusionService {
    public class FusionResult {
        public String authenticationLevel;
        public Decimal fusedScore;
        public FusionResult(String authenticationLevel, Decimal fusedScore) {
            this.authenticationLevel = authenticationLevel;
            this.fusedScore = fusedScore;
        }
    }
@TestVisible
private static Decimal test_callLivenessAPI(String base64Image) {
    return callLivenessAPI(base64Image);
}

    public static FusionResult authenticateUser(Map<String, Decimal> biometricScores) {
        // Weighted fusion algorithm implementation
        Decimal fusedScore = (biometricScores.get('faceScore') * 0.3) +
                             (biometricScores.get('voiceScore') * 0.25) +
                             (biometricScores.get('fingerprintScore') * 0.25) +
                             (biometricScores.get('signatureScore') * 0.2);
        String authenticationLevel = fusedScore >= 0.9 ? 'HIGHEST' :
                                     fusedScore >= 0.8 ? 'HIGH' :
                                     fusedScore >= 0.7 ? 'MEDIUM' : 'LOW';
        return new FusionResult(authenticationLevel, fusedScore);
    }

    public class BiometricScores {
        public Decimal faceScore;
        public Decimal voiceScore;
        public Decimal fingerprintScore;
        public Decimal signatureScore;
        public Decimal fusedScore;
        public String authLevel;
    }

    public class BiometricData {
        public String faceData;
        public String voiceData;
        public String fingerprintData;
        public String signatureData;
    }

    public class AuthenticationResult {
        public Decimal fusedScore;
        public String authLevel;
        public AuthenticationResult(Decimal fusedScore, String authLevel) {
            this.fusedScore = fusedScore;
            this.authLevel = authLevel;
        }
    }

    private static Decimal callLivenessAPI(String base64Image) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:LivenessService/v1/analyze');
    req.setMethod('POST');
    req.setHeader('Content-Type','application/json');
    req.setBody(JSON.serialize(new Map<String,Object>{ 'image' => base64Image }));
    HttpResponse res = new Http().send(req);
    if (res.getStatusCode()==200) {
        Map<String,Object> resp = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
        return (Decimal) resp.get('liveness_score');
    }
    return 0; // fallback
}

    // Helper: Process face biometric
    private static Decimal processFaceBiometric(String faceData) {
        // Example: Implement face recognition logic or call external API
        // Return a score between 0 and 1
        return 0.8;
    }

    // Helper: Process voice biometric
    private static Decimal processVoiceBiometric(String voiceData) {
        // Example: Implement voice recognition logic or call external API
        // Return a score between 0 and 1
        return 0.75;
    }

    // Helper: Process fingerprint biometric
    private static Decimal processFingerprintBiometric(String fingerprintData) {
        // Example: Implement fingerprint recognition logic or call external API
        // Return a score between 0 and 1
        return 0.85;
    }

    // Helper: Process signature biometric
    private static Decimal processSignatureBiometric(String signatureData) {
        // Example: Implement signature recognition logic or call external API
        // Return a score between 0 and 1
        return 0.7;
    }

    // Helper: Process face recognition
    private static Decimal processFaceRecognition(String faceData) {
        // Example: Implement face recognition logic or call external API
        // Return a score between 0 and 1
        return 0.8;
    }

    // Helper: Process voice recognition
    private static Decimal processVoiceRecognition(String voiceData) {
        // Example: Implement voice recognition logic or call external API
        // Return a score between 0 and 1
        return 0.75;
    }

    // Helper: Process fingerprint
    private static Decimal processFingerprint(String fingerprintData) {
        // Example: Implement fingerprint recognition logic or call external API
        // Return a score between 0 and 1
        return 0.85;
    }

    // Helper: Process signature pattern
    private static Decimal processSignaturePattern(String signatureData) {
        // Example: Implement signature recognition logic or call external API
        // Return a score between 0 and 1
        return 0.7;
    }

    @AuraEnabled
    public static BiometricScores authenticateUser(Map<String, Object> biometricData) {
        BiometricScores scores = new BiometricScores();
        
        // Process individual biometric scores
        scores.faceScore = processFaceBiometric((String)biometricData.get('faceData'));
        scores.voiceScore = processVoiceBiometric((String)biometricData.get('voiceData'));
        scores.fingerprintScore = processFingerprintBiometric((String)biometricData.get('fingerprintData'));
        scores.signatureScore = processSignatureBiometric((String)biometricData.get('signatureData'));
        
        // Weighted fusion algorithm
        scores.fusedScore = (scores.faceScore * 0.3) + 
                           (scores.voiceScore * 0.25) + 
                           (scores.fingerprintScore * 0.25) + 
                           (scores.signatureScore * 0.2);
        
        // Determine authentication level
        scores.authLevel = scores.fusedScore >= 0.9 ? 'HIGHEST' :
                          scores.fusedScore >= 0.8 ? 'HIGH' :
                          scores.fusedScore >= 0.7 ? 'MEDIUM' : 'LOW';
        
        // Store fusion results
        BiometricFusion__c fusion = new BiometricFusion__c(
            User_Id__c = UserInfo.getUserId(),
            Face_Score__c = scores.faceScore,
            Voice_Score__c = scores.voiceScore,
            Fingerprint_Score__c = scores.fingerprintScore,
            Signature_Score__c = scores.signatureScore,
            Fused_Score__c = scores.fusedScore,
            Authentication_Level__c = scores.authLevel,
            Fusion_Timestamp__c = System.now()
        );
        insert fusion;
        
        return scores;
    }

    public static AuthenticationResult authenticateUser(BiometricData biometricData) {
        // Face recognition score (weight: 0.3)
        Decimal faceScore = processFaceRecognition(biometricData.faceData);
        
        // Voice recognition score (weight: 0.25)
        Decimal voiceScore = processVoiceRecognition(biometricData.voiceData);
        
        // Fingerprint score (weight: 0.25)
        Decimal fingerprintScore = processFingerprint(biometricData.fingerprintData);
        
        // Signature pattern score (weight: 0.2)
        Decimal signatureScore = processSignaturePattern(biometricData.signatureData);
        
        // Weighted fusion algorithm
        Decimal fusedScore = (faceScore * 0.3) + (voiceScore * 0.25) + 
                           (fingerprintScore * 0.25) + (signatureScore * 0.2);
        
        String authLevel = fusedScore > 0.85 ? 'HIGH' : fusedScore > 0.65 ? 'MEDIUM' : 'LOW';
        
        return new AuthenticationResult(fusedScore, authLevel);
    }

}
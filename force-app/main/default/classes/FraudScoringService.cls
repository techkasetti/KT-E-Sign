public class FraudScoringService {

    /**
     * @description Data Transfer Object (DTO) class to hold the results of a fraud assessment.
     */
    public class FraudAssessment {
        @AuraEnabled public Decimal behavioralScore { get; set; }
        @AuraEnabled public Decimal deviceScore { get; set; }
        @AuraEnabled public Decimal locationScore { get; set; }
        @AuraEnabled public Decimal temporalScore { get; set; }
        @AuraEnabled public Decimal signatureScore { get; set; }
        @AuraEnabled public Decimal velocityScore { get; set; }
        @AuraEnabled public Decimal compositeScore { get; set; }
        @AuraEnabled public String riskLevel { get; set; }
        @AuraEnabled public String recommendedAction { get; set; }

        public FraudAssessment() {}

        public FraudAssessment(Decimal totalScore, String riskLevel) {
            this.compositeScore = totalScore;
            this.riskLevel = riskLevel;
        }
    }

    /**
     * @description DTO class used as a return type for fraud scoring methods.
     * This class was referenced but not defined in the original code.
     */
    public class FraudAssessmentResult {
        // Define properties for this class as needed.
    }

    /**
     * @description Calculates a fraud score in real-time based on context data from a client-side component.
     * @param signatureRequestId The ID of the Signature_Request__c record.
     * @param contextData A map of contextual data (e.g., userId, ipAddress, deviceFingerprint).
     * @return A FraudAssessment object with detailed scoring.
     */
    @AuraEnabled
    public static FraudAssessment calculateRealTimeFraudScore(Id signatureRequestId, Map<String, Object> contextData) {
        FraudAssessment assessment = new FraudAssessment();
        
        Id userId = (Id)contextData.get('userId');
        String deviceFingerprint = (String)contextData.get('deviceFingerprint');
        String ipAddress = (String)contextData.get('ipAddress');

        assessment.behavioralScore = analyzeBehavioralPatterns(userId);
        assessment.deviceScore = analyzeDeviceRisk(deviceFingerprint);
        assessment.locationScore = analyzeLocationRisk(ipAddress, userId);
        assessment.temporalScore = analyzeTemporalPatterns(userId);
        assessment.signatureScore = analyzeSignatureConsistency(signatureRequestId, userId);
        assessment.velocityScore = analyzeSigningVelocity(userId);
        assessment.compositeScore = calculateCompositeScore(assessment);
        assessment.riskLevel = determineRiskLevel(assessment.compositeScore);
        assessment.recommendedAction = getRecommendedAction(assessment.riskLevel);
        
        FraudAssessment__c fraudRecord = new FraudAssessment__c(
            Signature_Request__c = signatureRequestId,
            User_Id__c = userId,
            Behavioral_Score__c = assessment.behavioralScore,
            Device_Score__c = assessment.deviceScore,
            Location_Score__c = assessment.locationScore,
            Temporal_Score__c = assessment.temporalScore,
            Signature_Score__c = assessment.signatureScore,
            Velocity_Score__c = assessment.velocityScore,
            Composite_Score__c = assessment.compositeScore,
            Risk_Level__c = assessment.riskLevel,
            Recommended_Action__c = assessment.recommendedAction,
            Assessment_Timestamp__c = System.now() // CORRECTED: Removed invalid markdown syntax
        );
        insert fraudRecord;
        
        if (assessment.riskLevel == 'HIGH' || assessment.riskLevel == 'CRITICAL') {
            // NOTE: The EmailNotificationService class needs to be implemented.
            // EmailNotificationService.sendSecurityAlert(...);
            System.debug('High-Risk Fraud Activity Detected for Signature Request: ' + signatureRequestId);
        }
        
        return assessment;
    }
    
    /**
     * @description Calculates a fraud score based on a signature request ID, suitable for backend processing.
     * @param signatureRequestId The ID of the Signature_Request__c record.
     * @return A FraudAssessment object containing the total score and risk level.
     */
    public static FraudAssessment calculateFraudScore(String signatureRequestId) {
        Signature_Request__c request = [SELECT Id, SignerEmail__c, IPAddress__c, SignatureData__c, CreatedDate FROM Signature_Request__c WHERE Id = :signatureRequestId];
        
        Decimal behavioralScore = analyzeBehavioralPatterns(request);
        Decimal deviceScore = assessDeviceRisk(request);
        Decimal locationScore = evaluateLocationRisk(request.IPAddress__c);
        Decimal temporalScore = analyzeTemporalPatterns(request);
        Decimal signatureScore = checkSignatureConsistency(request);
        
        Decimal totalScore = behavioralScore + deviceScore + locationScore + temporalScore + signatureScore;
        String riskLevel = totalScore > 70 ? 'HIGH' : totalScore > 40 ? 'MEDIUM' : 'LOW';
        
        insertFraudAssessment(signatureRequestId, totalScore, riskLevel);
        
        if (totalScore > 70) {
            triggerFraudAlert(signatureRequestId, totalScore);
        }
        
        return new FraudAssessment(totalScore, riskLevel);
    }

    // --- STUBBED HELPER METHODS ---
    // NOTE: These methods are placeholders and must be implemented with your specific business logic.

    private static Decimal analyzeBehavioralPatterns(Id userId) { return 10.0; /* Placeholder */ }
    private static Decimal analyzeDeviceRisk(String deviceFingerprint) { return 5.0; /* Placeholder */ }
    private static Decimal analyzeLocationRisk(String ipAddress, Id userId) { return 5.0; /* Placeholder */ }
    private static Decimal analyzeTemporalPatterns(Id userId) { return 10.0; /* Placeholder */ }
    private static Decimal analyzeSignatureConsistency(Id sigReqId, Id userId) { return 10.0; /* Placeholder */ }
    private static Decimal analyzeSigningVelocity(Id userId) { return 5.0; /* Placeholder */ }
    private static Decimal calculateCompositeScore(FraudAssessment assessment) { return 45.0; /* Placeholder */ }
    private static String determineRiskLevel(Decimal score) { return score > 70 ? 'HIGH' : 'MEDIUM'; /* Placeholder */ }
    private static String getRecommendedAction(String riskLevel) { return 'MONITOR'; /* Placeholder */ }
    
    private static Decimal analyzeBehavioralPatterns(SObject request) { return 15.0; /* Placeholder */ }
    private static Decimal assessDeviceRisk(SObject request) { return 10.0; /* Placeholder */ }
    private static Decimal evaluateLocationRisk(String ipAddress) { return 5.0; /* Placeholder */ }
    private static Decimal analyzeTemporalPatterns(SObject request) { return 5.0; /* Placeholder */ }
    private static Decimal checkSignatureConsistency(SObject request) { return 10.0; /* Placeholder */ }
    private static void insertFraudAssessment(String reqId, Decimal score, String riskLevel) { /* Logic to insert record */ }
    private static void triggerFraudAlert(String reqId, Decimal score) { /* Logic to send alert */ }
}
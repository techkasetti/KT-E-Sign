public class FraudScoringService {
    public static FraudAssessmentResult calculateRealTimeFraudScore(String signatureRequestId) {
        // Behavioral pattern analysis
        // Device trust assessment
        // Location risk evaluation
        // Velocity checks
        // ML-based fraud detection
    }
        @AuraEnabled
    public static FraudAssessment calculateRealTimeFraudScore(Id signatureRequestId, Map<String, Object> contextData) {
        FraudAssessment assessment = new FraudAssessment();
        
        // Behavioral pattern analysis
        assessment.behavioralScore = analyzeBehavioralPatterns((Id)contextData.get('userId'));
        
        // Device analysis
        assessment.deviceScore = analyzeDeviceRisk((String)contextData.get('deviceFingerprint'));
        
        // Location analysis
        assessment.locationScore = analyzeLocationRisk((String)contextData.get('ipAddress'), (Id)contextData.get('userId'));
        
        // Temporal analysis
        assessment.temporalScore = analyzeTemporalPatterns((Id)contextData.get('userId'));
        
        // Signature analysis
        assessment.signatureScore = analyzeSignatureConsistency(signatureRequestId, (Id)contextData.get('userId'));
        
        // Velocity analysis
        assessment.velocityScore = analyzeSigningVelocity((Id)contextData.get('userId'));
        
        // ML-based composite score calculation
        assessment.compositeScore = calculateCompositeScore(assessment);
        assessment.riskLevel = determineRiskLevel(assessment.compositeScore);
        assessment.recommendedAction = getRecommendedAction(assessment.riskLevel);
        
        // Store fraud assessment
        FraudAssessment__c fraudRecord = new FraudAssessment__c(
            Signature_Request__c = signatureRequestId,
            User_Id__c = (Id)contextData.get('userId'),
            Behavioral_Score__c = assessment.behavioralScore,
            Device_Score__c = assessment.deviceScore,
            Location_Score__c = assessment.locationScore,
            Temporal_Score__c = assessment.temporalScore,
            Signature_Score__c = assessment.signatureScore,
            Velocity_Score__c = assessment.velocityScore,
            Composite_Score__c = assessment.compositeScore,
            Risk_Level__c = assessment.riskLevel,
            Recommended_Action__c = assessment.recommendedAction,
            Assessment_Timestamp__c = System.now()
        );
        insert fraudRecord;
        
        // Trigger alerts for high-risk scenarios
        if (assessment.riskLevel == 'HIGH' || assessment.riskLevel == 'CRITICAL') {
            EmailNotificationService.sendSecurityAlert(
                'High-Risk Fraud Activity Detected',
                'Fraud score: ' + assessment.compositeScore + ' for signature request: ' + signatureRequestId
            );
        }
        
        return assessment;
    }
public static FraudAssessment calculateFraudScore(String signatureRequestId) {
        Signature_Request__c request = [SELECT Id, SignerEmail__c, IPAddress__c, 
                                      SignatureData__c, CreatedDate FROM Signature_Request__c 
                                      WHERE Id = :signatureRequestId];
        
        // Behavioral pattern analysis (0-25 points)
        Decimal behavioralScore = analyzeBehavioralPatterns(request);
        
        // Device risk assessment (0-25 points)
        Decimal deviceScore = assessDeviceRisk(request);
        
        // Location risk evaluation (0-20 points)
        Decimal locationScore = evaluateLocationRisk(request.IPAddress__c);
        
        // Temporal analysis (0-15 points)
        Decimal temporalScore = analyzeTemporalPatterns(request);
        
        // Signature consistency check (0-15 points)
        Decimal signatureScore = checkSignatureConsistency(request);
        
        Decimal totalScore = behavioralScore + deviceScore + locationScore + 
                           temporalScore + signatureScore;
        
        String riskLevel = totalScore > 70 ? 'HIGH' : totalScore > 40 ? 'MEDIUM' : 'LOW';
        
        // Store fraud assessment
        insertFraudAssessment(signatureRequestId, totalScore, riskLevel);
        
        // Trigger alerts for high-risk scenarios
        if (totalScore > 70) {
            triggerFraudAlert(signatureRequestId, totalScore);
        }
        
        return new FraudAssessment(totalScore, riskLevel);
    }

}

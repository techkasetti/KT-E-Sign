/**
 * @description Provides advanced security services including risk assessment, multi-factor
 * authentication (MFA) validation, and compliance verification for the e-signature process.
 * This class is designed to be robust and handle various data scenarios gracefully.
 */
public with sharing class AdvancedSecurityEngine {

    // =================================================================================
    // Constants and Configuration
    // =================================================================================

    private static final Map<String, Integer> SECURITY_RISK_WEIGHTS = new Map<String, Integer>{
        'LOCATION_ANOMALY' => 25,
        'DEVICE_FINGERPRINT_MISMATCH' => 20,
        'VELOCITY_ANOMALY' => 30,
        'BEHAVIORAL_ANOMALY' => 15,
        'TIME_ANOMALY' => 10
    };

    private static final Integer MAX_MFA_ATTEMPTS = 5;

    // =================================================================================
    // Main Public Methods (AuraEnabled)
    // =================================================================================

    /**
     * @description Performs a comprehensive security assessment for a given signature request.
     * @param signatureRequestId The ID of the Signature_Request__c record.
     * @return A SecurityAssessmentResult object containing the risk analysis.
     */
    @AuraEnabled(cacheable=false)
    public static SecurityAssessmentResult performSecurityAssessment(String signatureRequestId) {
        if (String.isBlank(signatureRequestId)) {
            return createErrorAssessmentResult('Signature Request ID cannot be null.');
        }

        try {
            List<Signature_Request__c> requests = [
                SELECT Id, SignerEmail__c, SigningLocation__c, DeviceFingerprint__c,
                       CreatedDate, Status__c, Time_To_Complete_Hours__c, SignatureMethod__c,
                       IP_Address__c, User_Agent__c, Session_Duration_Minutes__c
                FROM Signature_Request__c
                WHERE Id = :signatureRequestId
                LIMIT 1
            ];

            if (requests.isEmpty()) {
                return createErrorAssessmentResult('Signature Request not found for ID: ' + signatureRequestId);
            }
            Signature_Request__c request = requests[0];

            SecurityAssessmentResult assessment = new SecurityAssessmentResult();
            assessment.signatureRequestId = signatureRequestId;
            assessment.assessmentTimestamp = System.now();
            assessment.riskFactors = new List<RiskFactor>();
            assessment.totalRiskScore = 0;

            // Execute individual risk assessments
            assessment.riskFactors.add(assessLocationRisk(request));
            assessment.riskFactors.add(assessDeviceRisk(request));
            assessment.riskFactors.add(assessVelocityRisk(request));
            assessment.riskFactors.add(assessBehavioralRisk(request));
            assessment.riskFactors.add(assessTimeAnomalies(request));
            
            // Calculate total risk score from factors
            for (RiskFactor factor : assessment.riskFactors) {
                if (factor.riskLevel > 0) {
                    assessment.totalRiskScore += factor.riskLevel;
                }
            }

            assessment.riskLevel = determineRiskLevel(assessment.totalRiskScore);
            assessment.recommendations = generateSecurityRecommendations(assessment);
            assessment.success = true;

            storeSecurityAssessment(assessment);
            return assessment;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Security assessment failed: ' + e.getMessage() + ' Stack: ' + e.getStackTraceString());
            return createErrorAssessmentResult('Security assessment failed: ' + e.getMessage());
        }
    }
    
    /**
     * @description Validates a multi-factor authentication (MFA) request.
     * @param signatureRequestId The ID of the signature request.
     * @param mfaData A map containing MFA details like 'otpCode' and 'authMethod'.
     * @return An MFAValidationResult object.
     */
    @AuraEnabled(cacheable=false)
    public static MFAValidationResult validateMultiFactorAuthentication(String signatureRequestId, Map<String, Object> mfaData) {
        MFAValidationResult result = new MFAValidationResult();
        result.signatureRequestId = signatureRequestId;
        result.validationTimestamp = System.now();
        
        try {
            String otpCode = (String) mfaData.get('otpCode');
            String authMethod = (String) mfaData.get('authMethod');
            result.authMethod = authMethod;

            // Simple placeholder for OTP validation. In a real scenario, this would involve
            // checking a securely stored code with an expiration.
            if (String.isNotBlank(otpCode) && otpCode.length() == 6) {
                result.success = true;
            } else {
                result.success = false;
                result.errorMessage = 'Invalid OTP format.';
                result.failureReason = 'INVALID_FORMAT';
            }
            
            logAuthenticationAttempt(signatureRequestId, authMethod, result.success);
            return result;
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'MFA validation failed: ' + e.getMessage();
            logAuthenticationAttempt(signatureRequestId, (String)mfaData.get('authMethod'), false);
            return result;
        }
    }

    /**
     * @description Verifies advanced compliance rules for a document based on its region.
     * @param documentId The ID of the DocumentLifecycleConfiguration__c record.
     * @param region The region to validate against (e.g., 'EU', 'US').
     * @return A ComplianceVerificationResult object.
     */
    @AuraEnabled(cacheable=false)
    public static ComplianceVerificationResult verifyAdvancedCompliance(String documentId, String region) {
        ComplianceVerificationResult verification = new ComplianceVerificationResult();
        verification.documentId = documentId;
        verification.region = region;
        verification.complianceChecks = new List<ComplianceCheck>();

        try {
            List<DocumentLifecycleConfiguration__c> docs = [
                SELECT Id, DocumentContent__c, ContractType__c, Region__c
                FROM DocumentLifecycleConfiguration__c
                WHERE Id = :documentId LIMIT 1
            ];

            if (docs.isEmpty()) {
                verification.success = false;
                verification.errorMessage = 'Document not found.';
                return verification;
            }
            DocumentLifecycleConfiguration__c document = docs[0];

            if ('EU'.equalsIgnoreCase(region)) {
                verification.complianceChecks.add(checkGDPRCompliance(document));
            } else if ('US'.equalsIgnoreCase(region)) {
                verification.complianceChecks.add(checkHIPAACompliance(document));
                verification.complianceChecks.add(checkSOXCompliance(document));
            }
            
            verification.overallComplianceScore = calculateOverallComplianceScore(verification.complianceChecks);
            verification.complianceLevel = determineComplianceLevel(verification.overallComplianceScore);
            verification.recommendations = generateComplianceRecommendations(verification.complianceChecks);
            verification.success = true;

            storeComplianceVerification(verification);
            return verification;

        } catch (Exception e) {
            verification.success = false;
            verification.errorMessage = 'Compliance verification failed: ' + e.getMessage();
            return verification;
        }
    }

    // =================================================================================
    // Private Helper Methods for Risk Assessment
    // =================================================================================

    private static RiskFactor assessLocationRisk(Signature_Request__c request) {
        RiskFactor factor = new RiskFactor('LOCATION_ANOMALY', 0);
        try {
            List<AggregateResult> locationHistory = [
                SELECT SigningLocation__c, COUNT(Id) locationCount
                FROM Signature_Request__c
                WHERE SignerEmail__c = :request.SignerEmail__c AND SigningLocation__c != null AND CreatedDate >= LAST_N_DAYS:90
                GROUP BY SigningLocation__c ORDER BY COUNT(Id) DESC
            ];

            if (locationHistory.isEmpty()) {
                factor.riskLevel = 5; // Slight risk for a new user/location
                factor.description = 'No historical location data for this user.';
                return factor;
            }

            boolean isKnownLocation = false;
            for (AggregateResult loc : locationHistory) {
                String historicalLocation = (String)loc.get('SigningLocation__c');
                if (request.SigningLocation__c != null && calculateLocationDistance(request.SigningLocation__c, historicalLocation) < 50) { // Within 50km
                    isKnownLocation = true;
                    break;
                }
            }

            if (!isKnownLocation) {
                factor.riskLevel = SECURITY_RISK_WEIGHTS.get('LOCATION_ANOMALY');
                factor.description = 'Signing from a new or unusual geographic location.';
                factor.evidence = 'Current location: ' + request.SigningLocation__c;
            }
        } catch (Exception e) {
            factor.riskLevel = 10;
            factor.description = 'Unable to verify location due to a system error.';
        }
        return factor;
    }

    private static RiskFactor assessDeviceRisk(Signature_Request__c request) {
        RiskFactor factor = new RiskFactor('DEVICE_FINGERPRINT_MISMATCH', 0);
        try {
            List<AggregateResult> deviceHistory = [
                SELECT DeviceFingerprint__c, COUNT(Id) usageCount
                FROM Signature_Request__c
                WHERE SignerEmail__c = :request.SignerEmail__c AND DeviceFingerprint__c != null AND CreatedDate >= LAST_N_DAYS:180
                GROUP BY DeviceFingerprint__c
            ];

            if (deviceHistory.isEmpty() || String.isBlank(request.DeviceFingerprint__c)) {
                 factor.riskLevel = 5;
                 factor.description = 'No historical device data available.';
                 return factor;
            }

            boolean isKnownDevice = false;
            for (AggregateResult dev : deviceHistory) {
                if (request.DeviceFingerprint__c.equals((String)dev.get('DeviceFingerprint__c'))) {
                    isKnownDevice = true;
                    break;
                }
            }

            if (!isKnownDevice) {
                factor.riskLevel = SECURITY_RISK_WEIGHTS.get('DEVICE_FINGERPRINT_MISMATCH');
                factor.description = 'Signature submitted from an unrecognized device.';
                factor.evidence = 'Device fingerprint mismatch.';
            }
        } catch (Exception e) {
            factor.riskLevel = 10;
            factor.description = 'Unable to verify device due to a system error.';
        }
        return factor;
    }

    private static RiskFactor assessVelocityRisk(Signature_Request__c request) {
        RiskFactor factor = new RiskFactor('VELOCITY_ANOMALY', 0);
        try {
            Integer recentCount = [SELECT COUNT() FROM Signature_Request__c WHERE SignerEmail__c = :request.SignerEmail__c AND CreatedDate >= :System.now().addHours(-24)];
            
            List<AggregateResult> dailyCounts = [
                SELECT DAY_ONLY(CreatedDate) day, COUNT(Id) dailyCount
                FROM Signature_Request__c
                WHERE SignerEmail__c = :request.SignerEmail__c AND CreatedDate >= LAST_N_DAYS:30
                GROUP BY DAY_ONLY(CreatedDate)
            ];

            Decimal avgDaily = 0;
            if (!dailyCounts.isEmpty()) {
                Decimal total = 0;
                for (AggregateResult ar : dailyCounts) {
                    total += (Decimal)ar.get('dailyCount');
                }
                avgDaily = total / dailyCounts.size();
            }

            if (recentCount > (avgDaily * 5) && avgDaily > 0) {
                factor.riskLevel = SECURITY_RISK_WEIGHTS.get('VELOCITY_ANOMALY');
                factor.description = 'Unusually high signing velocity detected.';
                factor.evidence = recentCount + ' signatures in 24h (avg: ' + avgDaily.setScale(1) + ')';
            }
        } catch (Exception e) {
            factor.riskLevel = 10;
            factor.description = 'Unable to assess signing velocity due to a system error.';
        }
        return factor;
    }

    private static RiskFactor assessBehavioralRisk(Signature_Request__c request) {
        RiskFactor factor = new RiskFactor('BEHAVIORAL_ANOMALY', 0);
        try {
            List<AggregateResult> behaviorPatterns = [
                SELECT AVG(Time_To_Complete_Hours__c) avgCompletionTime, AVG(Session_Duration_Minutes__c) avgSessionDuration
                FROM Signature_Request__c
                WHERE SignerEmail__c = :request.SignerEmail__c AND Status__c = 'Completed' AND CreatedDate >= LAST_N_DAYS:90
            ];

            if (!behaviorPatterns.isEmpty() && behaviorPatterns[0].get('avgCompletionTime') != null) {
                Decimal avgCompletion = (Decimal)behaviorPatterns[0].get('avgCompletionTime');
                if (request.Time_To_Complete_Hours__c != null && request.Time_To_Complete_Hours__c < (avgCompletion * 0.2)) {
                    factor.riskLevel = SECURITY_RISK_WEIGHTS.get('BEHAVIORAL_ANOMALY');
                    factor.description = 'Signature completed significantly faster than usual.';
                    factor.evidence = 'Current: ' + request.Time_To_Complete_Hours__c.setScale(2) + 'h, Avg: ' + avgCompletion.setScale(2) + 'h';
                }
            }
        } catch (Exception e) {
            factor.riskLevel = 10;
            factor.description = 'Unable to assess behavioral patterns due to a system error.';
        }
        return factor;
    }

    private static RiskFactor assessTimeAnomalies(Signature_Request__c request) {
        RiskFactor factor = new RiskFactor('TIME_ANOMALY', 0);
        Integer currentHour = request.CreatedDate.hour();
        if (currentHour < 6 || currentHour > 22) { // Outside typical 6am-10pm business hours
            factor.riskLevel = SECURITY_RISK_WEIGHTS.get('TIME_ANOMALY');
            factor.description = 'Signature request initiated during off-peak hours.';
            factor.evidence = 'Time: ' + request.CreatedDate.format();
        }
        return factor;
    }

    // =================================================================================
    // Private Helper Methods for Compliance
    // =================================================================================

    private static ComplianceCheck checkGDPRCompliance(DocumentLifecycleConfiguration__c document) {
        ComplianceCheck check = new ComplianceCheck('GDPR', 'General Data Protection Regulation');
        String content = document.DocumentContent__c?.toLowerCase();
        if (content == null) {
            check.violations.add('Document content is empty.');
        } else {
            if (!content.contains('data processing')) check.violations.add('Missing data processing clauses.');
            if (!content.contains('consent')) check.violations.add('Missing explicit consent language.');
        }
        check.complianceScore = Math.max(0, 100 - (check.violations.size() * 40));
        check.status = check.complianceScore >= 80 ? 'COMPLIANT' : 'NON_COMPLIANT';
        return check;
    }

    private static ComplianceCheck checkHIPAACompliance(DocumentLifecycleConfiguration__c document) {
        ComplianceCheck check = new ComplianceCheck('HIPAA', 'Health Insurance Portability and Accountability Act');
         if (!'Healthcare'.equalsIgnoreCase(document.ContractType__c)) {
            check.complianceScore = 100;
            check.status = 'NOT_APPLICABLE';
            return check;
        }
        String content = document.DocumentContent__c?.toLowerCase();
        if (content == null) {
            check.violations.add('Document content is empty.');
        } else {
            if (!content.contains('protected health information') && !content.contains('phi')) check.violations.add('Missing PHI clauses.');
        }
        check.complianceScore = Math.max(0, 100 - (check.violations.size() * 50));
        check.status = check.complianceScore >= 80 ? 'COMPLIANT' : 'NON_COMPLIANT';
        return check;
    }

    private static ComplianceCheck checkSOXCompliance(DocumentLifecycleConfiguration__c document) {
        ComplianceCheck check = new ComplianceCheck('SOX', 'Sarbanes-Oxley Act');
        if (!'Financial'.equalsIgnoreCase(document.ContractType__c)) {
            check.complianceScore = 100;
            check.status = 'NOT_APPLICABLE';
            return check;
        }
        String content = document.DocumentContent__c?.toLowerCase();
        if (content == null) {
            check.violations.add('Document content is empty.');
        } else {
            if (!content.contains('internal controls')) check.violations.add('Missing internal controls references.');
        }
        check.complianceScore = Math.max(0, 100 - (check.violations.size() * 50));
        check.status = check.complianceScore >= 80 ? 'COMPLIANT' : 'NON_COMPLIANT';
        return check;
    }

    // =================================================================================
    // Utility and Storage Methods
    // =================================================================================

    private static String determineRiskLevel(Integer totalRiskScore) {
        if (totalRiskScore >= 75) return 'CRITICAL';
        if (totalRiskScore >= 50) return 'HIGH';
        if (totalRiskScore >= 25) return 'MEDIUM';
        return 'LOW';
    }

    private static List<String> generateSecurityRecommendations(SecurityAssessmentResult assessment) {
        List<String> recommendations = new List<String>();
        switch on assessment.riskLevel {
            when 'CRITICAL' {
                recommendations.add('IMMEDIATE ACTION: Block signature request pending investigation.');
                recommendations.add('Require multi-factor authentication verification.');
            }
            when 'HIGH' {
                recommendations.add('Require additional authentication before processing.');
                recommendations.add('Enable enhanced audit logging.');
            }
            when 'MEDIUM' {
                recommendations.add('Implement additional monitoring for this session.');
                recommendations.add('Review signature request details carefully.');
            }
            when 'LOW' {
                recommendations.add('Process normally with standard security measures.');
            }
        }
        return recommendations;
    }

    private static void storeSecurityAssessment(SecurityAssessmentResult assessment) {
        try {
            Security_Assessment__c record = new Security_Assessment__c(
                Signature_Request_Id__c = assessment.signatureRequestId,
                Assessment_Timestamp__c = assessment.assessmentTimestamp,
                Total_Risk_Score__c = assessment.totalRiskScore,
                Risk_Level__c = assessment.riskLevel,
                Risk_Factors_JSON__c = JSON.serialize(assessment.riskFactors),
                Recommendations_JSON__c = JSON.serialize(assessment.recommendations),
                Assessment_Status__c = 'COMPLETED'
            );
            insert record;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to store security assessment: ' + e.getMessage());
        }
    }
    
    private static void logAuthenticationAttempt(String recordId, String authMethod, Boolean success) {
        try {
            AuditTrail__c log = new AuditTrail__c(
                RecordId__c = recordId,
                Action__c = 'MFA_ATTEMPT',
                Status__c = success ? 'SUCCESS' : 'FAILURE',
                Details__c = 'MFA attempt via ' + authMethod
            );
            insert log;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to log authentication attempt: ' + e.getMessage());
        }
    }

    private static void storeComplianceVerification(ComplianceVerificationResult verification) {
        // Placeholder for storing compliance verification results
    }
    
    private static SecurityAssessmentResult createErrorAssessmentResult(String errorMessage) {
        SecurityAssessmentResult errorResult = new SecurityAssessmentResult();
        errorResult.success = false;
        errorResult.errorMessage = errorMessage;
        return errorResult;
    }
    
    // Placeholder for distance calculation
    private static Decimal calculateLocationDistance(String loc1, String loc2) { return 0; }

    private static Decimal calculateOverallComplianceScore(List<ComplianceCheck> checks) {
        if (checks == null || checks.isEmpty()) return 100;
        Decimal totalScore = 0;
        for (ComplianceCheck check : checks) { totalScore += check.complianceScore; }
        return totalScore / checks.size();
    }
    
    private static String determineComplianceLevel(Decimal score) {
        if (score >= 90) return 'EXCELLENT';
        if (score >= 80) return 'GOOD';
        if (score >= 60) return 'NEEDS_IMPROVEMENT';
        return 'CRITICAL';
    }

    private static List<String> generateComplianceRecommendations(List<ComplianceCheck> checks) {
        List<String> recommendations = new List<String>();
        for (ComplianceCheck check : checks) {
            if ('NON_COMPLIANT'.equals(check.status)) {
                recommendations.add('Review and address violations for ' + check.checkName);
            }
        }
        if (recommendations.isEmpty()) {
            recommendations.add('All compliance checks passed.');
        }
        return recommendations;
    }


    // =================================================================================
    // Inner Classes (Data Transfer Objects)
    // =================================================================================

    public class SecurityAssessmentResult {
        @AuraEnabled public String signatureRequestId { get; set; }
        @AuraEnabled public DateTime assessmentTimestamp { get; set; }
        @AuraEnabled public List<RiskFactor> riskFactors { get; set; }
        @AuraEnabled public Integer totalRiskScore { get; set; }
        @AuraEnabled public String riskLevel { get; set; }
        @AuraEnabled public List<String> recommendations { get; set; }
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
    }

    public class RiskFactor {
        @AuraEnabled public String factorType { get; set; }
        @AuraEnabled public Integer riskLevel { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String evidence { get; set; }
        
        public RiskFactor(String type, Integer level) {
            this.factorType = type;
            this.riskLevel = level;
        }
    }

    public class MFAValidationResult {
        @AuraEnabled public String signatureRequestId { get; set; }
        @AuraEnabled public String authMethod { get; set; }
        @AuraEnabled public DateTime validationTimestamp { get; set; }
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        @AuraEnabled public String failureReason { get; set; }
    }

    public class ComplianceVerificationResult {
        @AuraEnabled public String documentId { get; set; }
        @AuraEnabled public String region { get; set; }
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        @AuraEnabled public List<ComplianceCheck> complianceChecks { get; set; }
        @AuraEnabled public Decimal overallComplianceScore { get; set; }
        @AuraEnabled public String complianceLevel { get; set; }
        @AuraEnabled public List<String> recommendations { get; set; }
    }

    public class ComplianceCheck {
        @AuraEnabled public String regulationType { get; set; }
        @AuraEnabled public String checkName { get; set; }
        @AuraEnabled public String status { get; set; } // e.g., COMPLIANT, NON_COMPLIANT
        @AuraEnabled public Decimal complianceScore { get; set; }
        @AuraEnabled public List<String> violations { get; set; }

        public ComplianceCheck(String type, String name) {
            this.regulationType = type;
            this.checkName = name;
            this.violations = new List<String>();
            this.complianceScore = 100;
        }
    }
}
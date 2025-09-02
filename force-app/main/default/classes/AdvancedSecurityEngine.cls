    public class AdvancedSecurityEngine {
        
        private static final Map<String, Integer> SECURITY_RISK_WEIGHTS = new Map<String, Integer>{
            'LOCATION_ANOMALY' => 25,
            'DEVICE_FINGERPRINT_MISMATCH' => 20,
            'VELOCITY_ANOMALY' => 30,
            'BEHAVIORAL_ANOMALY' => 15,
            'TIME_ANOMALY' => 10
        };
        
        
        /**
         * Comprehensive security assessment for signature requests
         */
        @AuraEnabled
        public static SecurityAssessmentResult performSecurityAssessment(String signatureRequestId) {
            try {
                Signature_Request__c request = [
            SELECT Id, SignerEmail__c, SigningLocation__c, DeviceFingerprint__c, 
                   CreatedDate, Status__c, Time_To_Complete_Hours__c, SignatureMethod__c,
                   IP_Address__c, User_Agent__c, Session_Duration_Minutes__c
            FROM Signature_Request__c 
            WHERE Id = :signatureRequestId 
            LIMIT 1
        ];
                
                SecurityAssessmentResult assessment = new SecurityAssessmentResult();
                assessment.signatureRequestId = signatureRequestId;
                assessment.assessmentTimestamp = System.now();
                assessment.riskFactors = new List<RiskFactor>();
                assessment.totalRiskScore = 0;
                
                // Location-based risk assessment
                RiskFactor locationRisk = assessLocationRisk(request);
                if (locationRisk.riskLevel > 0) {
                    assessment.riskFactors.add(locationRisk);
                    assessment.totalRiskScore += locationRisk.riskLevel;
                }
                
                // Device fingerprint analysis
                RiskFactor deviceRisk = assessDeviceRisk(request);
                if (deviceRisk.riskLevel > 0) {
                    assessment.riskFactors.add(deviceRisk);
                    assessment.totalRiskScore += deviceRisk.riskLevel;
                }
                
                // Velocity pattern analysis
                RiskFactor velocityRisk = assessVelocityRisk(request);
                if (velocityRisk.riskLevel > 0) {
                    assessment.riskFactors.add(velocityRisk);
                    assessment.totalRiskScore += velocityRisk.riskLevel;
                }
                
                // Behavioral pattern analysis
                RiskFactor behavioralRisk = assessBehavioralRisk(request);
                if (behavioralRisk.riskLevel > 0) {
                    assessment.riskFactors.add(behavioralRisk);
                    assessment.totalRiskScore += behavioralRisk.riskLevel;
                }
                
                // Time-based anomaly detection
                RiskFactor timeRisk = assessTimeAnomalies(request);
                if (timeRisk.riskLevel > 0) {
                    assessment.riskFactors.add(timeRisk);
                    assessment.totalRiskScore += timeRisk.riskLevel;
                }
                
                // Determine overall risk level
                assessment.riskLevel = determineRiskLevel(assessment.totalRiskScore);
                assessment.recommendations = generateSecurityRecommendations(assessment);
                assessment.success = true;
                
                // Store security assessment
                storeSecurityAssessment(assessment);
                
                return assessment;
                
            } catch (Exception e) {
                SecurityAssessmentResult errorResult = new SecurityAssessmentResult();
                errorResult.success = false;
                errorResult.errorMessage = 'Security assessment failed: ' + e.getMessage();
                return errorResult;
            }
        }
        
        /**
         * Multi-factor authentication validation
         */
        @AuraEnabled
        public static MFAValidationResult validateMultiFactorAuth(String signatureRequestId, String authToken, String authMethod) {
            try {
                MFAValidationResult result = new MFAValidationResult();
                result.signatureRequestId = signatureRequestId;
                result.authMethod = authMethod;
                result.validationTimestamp = System.now();
                
                switch on authMethod {
                    when 'SMS_OTP' {
                        result = validateSMSOTP(signatureRequestId, authToken);
                    }
                    when 'EMAIL_OTP' {
                        result = validateEmailOTP(signatureRequestId, authToken);
                    }
                    when 'TOTP' {
                        result = validateTOTP(signatureRequestId, authToken);
                    }
                    when 'BIOMETRIC' {
                        result = validateBiometric(signatureRequestId, authToken);
                    }
                    when else {
                        result.success = false;
                        result.errorMessage = 'Unsupported authentication method: ' + authMethod;
                    }
                }
                
                // Log authentication attempt
                logAuthenticationAttempt(result);
                
                return result;
                
            } catch (Exception e) {
                MFAValidationResult errorResult = new MFAValidationResult();
                errorResult.success = false;
                errorResult.errorMessage = 'MFA validation error: ' + e.getMessage();
                return errorResult;
            }
        }
        
        
        /**
         * Advanced compliance verification
         */
        @AuraEnabled
        public static ComplianceVerificationResult verifyAdvancedCompliance(String documentId, String jurisdiction) {
            try {
                DocumentLifecycleConfiguration__c document = [
            SELECT Id, DocumentContent__c, ContractType__c, Region__c, 
                   Overall_Compliance_Score__c, DocumentTitle__c
            FROM DocumentLifecycleConfiguration__c 
            WHERE Id = :documentId 
            LIMIT 1
        ];
                
                ComplianceVerificationResult verification = new ComplianceVerificationResult();
                verification.documentId = documentId;
                verification.jurisdiction = jurisdiction;
                verification.verificationTimestamp = System.now();
                verification.complianceChecks = new List<ComplianceCheck>();
                
                // GDPR Compliance Check
                if (jurisdiction.contains('EU') || jurisdiction.contains('Europe')) {
                    ComplianceCheck gdprCheck = performGDPRCompliance(document);
                    verification.complianceChecks.add(gdprCheck);
                }
                
                // CCPA Compliance Check
                if (jurisdiction.contains('California') || jurisdiction.contains('US')) {
                    ComplianceCheck ccpaCheck = performCCPACompliance(document);
                    verification.complianceChecks.add(ccpaCheck);
                }
                
                // SOX Compliance Check
                if (document.ContractType__c == 'Financial' || document.ContractType__c == 'Audit') {
                    ComplianceCheck soxCheck = performSOXCompliance(document);
                    verification.complianceChecks.add(soxCheck);
                }
                
                // HIPAA Compliance Check
                if (document.ContractType__c == 'Healthcare' || document.DocumentContent__c.containsIgnoreCase('medical')) {
                    ComplianceCheck hipaaCheck = performHIPAACompliance(document);
                    verification.complianceChecks.add(hipaaCheck);
                }
                
                // Calculate overall compliance score
                verification.overallComplianceScore = calculateOverallComplianceScore(verification.complianceChecks);
                verification.complianceLevel = determineComplianceLevel(verification.overallComplianceScore);
                verification.recommendations = generateComplianceRecommendations(verification.complianceChecks);
                verification.success = true;
                
                // Store compliance verification
                storeComplianceVerification(verification);
                
                return verification;
                
            } catch (Exception e) {
                ComplianceVerificationResult errorResult = new ComplianceVerificationResult();
                errorResult.success = false;
                errorResult.errorMessage = 'Compliance verification failed: ' + e.getMessage();
                return errorResult;
            }
        }
        
        // Helper methods for risk assessment
        private static RiskFactor assessLocationRisk(Signature_Request__c request) {
            RiskFactor riskFactor = new RiskFactor();
            riskFactor.factorType = 'LOCATION_ANOMALY';
            riskFactor.riskWeight = SECURITY_RISK_WEIGHTS.get('LOCATION_ANOMALY');
            
            try {
                // Get historical signing locations for this user
                List<AggregateResult> locationHistory = [
            SELECT SigningLocation__c, COUNT(Id) locationCount
            FROM Signature_Request__c 
            WHERE SignerEmail__c = :request.SignerEmail__c 
              AND SigningLocation__c != null 
              AND CreatedDate >= LAST_N_DAYS:90
            GROUP BY SigningLocation__c
            ORDER BY COUNT(Id) DESC
        ];
                
                // Check if current location is known
                Boolean isKnownLocation = false;
                for (AggregateResult location : locationHistory) {
                    String historicalLocation = (String)location.get('SigningLocation__c');
                    if (request.SigningLocation__c != null &&
                    calculateLocationDistance(request.SigningLocation__c, historicalLocation) < 50) { // Within 50km
                        isKnownLocation = true;
                        break;
                    }
                }
                
                if (!isKnownLocation && !locationHistory.isEmpty()) {
                    riskFactor.riskLevel = 25;
                    riskFactor.description = 'Signing from new/unknown geographic location';
                    riskFactor.evidence = 'Location: ' + request.SigningLocation__c + ' not found in user history';
                } else {
                    riskFactor.riskLevel = 0;
                    riskFactor.description = 'Location within normal patterns';
                }
                
            } catch (Exception e) {
                riskFactor.riskLevel = 10;
                riskFactor.description = 'Unable to verify location due to system error';
            }
            
            return riskFactor;
        }
        
        private static RiskFactor assessDeviceRisk(Signature_Request__c request) {
            RiskFactor riskFactor = new RiskFactor();
            riskFactor.factorType = 'DEVICE_FINGERPRINT_MISMATCH';
            riskFactor.riskWeight = SECURITY_RISK_WEIGHTS.get('DEVICE_FINGERPRINT_MISMATCH');
            
            try {
                // Get historical device fingerprints for this user
                List<Signature_Request__c> deviceHistory = [
            SELECT DeviceFingerprint__c, COUNT(Id) usageCount
            FROM Signature_Request__c 
            WHERE SignerEmail__c = :request.SignerEmail__c 
              AND DeviceFingerprint__c != null 
              AND CreatedDate >= LAST_N_DAYS:180
            GROUP BY DeviceFingerprint__c
            HAVING COUNT(Id) > 1
        ];
                
                Boolean isKnownDevice = false;
                for (Signature_Request__c device : deviceHistory) {
                    if (device.DeviceFingerprint__c == request.DeviceFingerprint__c) {
                        isKnownDevice = true;
                        break;
                    }
                }
                
                if (!isKnownDevice && !deviceHistory.isEmpty()) {
                    riskFactor.riskLevel = 20;
                    riskFactor.description = 'Signing from unrecognized device';
                    riskFactor.evidence = 'Device fingerprint not found in user history';
                } else {
                    riskFactor.riskLevel = 0;
                    riskFactor.description = 'Device recognized from previous sessions';
                }
                
            } catch (Exception e) {
                riskFactor.riskLevel = 10;
                riskFactor.description = 'Unable to verify device due to system error';
            }
            
            return riskFactor;
        }
        
        private static RiskFactor assessVelocityRisk(Signature_Request__c request) {
            RiskFactor riskFactor = new RiskFactor();
            riskFactor.factorType = 'VELOCITY_ANOMALY';
            riskFactor.riskWeight = SECURITY_RISK_WEIGHTS.get('VELOCITY_ANOMALY');
            
            try {
                // Check signing velocity patterns in the last 24 hours
                Datetime twentyFourHoursAgo = System.now().addHours(-24);
                
                List<AggregateResult> recentActivity = [
    SELECT COUNT(Id) recentSignatures
    FROM Signature_Request__c
    WHERE SignerEmail__c = :request.SignerEmail__c
      AND CreatedDate >= :twentyFourHoursAgo
];
                
                
                Integer recentCount = 0;
                if (!recentActivity.isEmpty()) {
                    recentCount = (Integer) recentActivity[0].get('recentSignatures');
                }
                
                // Calculate user's historical daily counts over the last 30 days
                List<AggregateResult> dailyCounts = [
    SELECT DAY_ONLY(CreatedDate) day, COUNT(Id) dailyCount
    FROM Signature_Request__c
    WHERE SignerEmail__c = :request.SignerEmail__c
      AND CreatedDate >= LAST_N_DAYS:30
    GROUP BY DAY_ONLY(CreatedDate)
];
                
                // Calculate the average daily count in Apex
                Decimal avgDaily = 0;
                if (!dailyCounts.isEmpty()) {
                    Decimal total = 0;
                    for (AggregateResult ar : dailyCounts) {
                        total += (Decimal) ar.get('dailyCount');
                    }
                    avgDaily = total / dailyCounts.size();
                }
                
                
                Decimal avgDaily = 1.0;
                if (!historicalAverage.isEmpty() && historicalAverage[0].get('avgDaily') != null) {
                    avgDaily = (Decimal)historicalAverage[0].get('avgDaily');
                }
                
                // Flag if current activity is 5x normal rate
                if (recentCount > (avgDaily * 5)) {
                    riskFactor.riskLevel = 30;
                    riskFactor.description = 'Unusually high signing velocity detected';
                    riskFactor.evidence = recentCount + ' signatures in 24h (avg: ' + avgDaily.setScale(1) + ')';
                } else if (recentCount > (avgDaily * 3)) {
                    riskFactor.riskLevel = 15;
                    riskFactor.description = 'Elevated signing activity detected';
                    riskFactor.evidence = recentCount + ' signatures in 24h (avg: ' + avgDaily.setScale(1) + ')';
                } else {
                    riskFactor.riskLevel = 0;
                    riskFactor.description = 'Normal signing velocity patterns';
                }
                
            } catch (Exception e) {
                riskFactor.riskLevel = 10;
                riskFactor.description = 'Unable to assess velocity due to system error';
            }
            
            return riskFactor;
        }
        
        private static RiskFactor assessBehavioralRisk(Signature_Request__c request) {
            RiskFactor riskFactor = new RiskFactor();
            riskFactor.factorType = 'BEHAVIORAL_ANOMALY';
            riskFactor.riskWeight = SECURITY_RISK_WEIGHTS.get('BEHAVIORAL_ANOMALY');
            
            try {
                // Get user's typical completion patterns over the last 90 days
                List<AggregateResult> behaviorPatterns = [
            SELECT AVG(Time_To_Complete_Hours__c) avgCompletionTime,
                   AVG(Session_Duration_Minutes__c) avgSessionDuration,
                   SignatureMethod__c preferredMethod,
                   COUNT(Id) methodUsage
            FROM Signature_Request__c 
            WHERE SignerEmail__c = :request.SignerEmail__c 
              AND Status__c = 'Completed'
              AND CreatedDate >= LAST_N_DAYS:90
            GROUP BY SignatureMethod__c
            ORDER BY COUNT(Id) DESC
            LIMIT 1
        ];
                
                if (!behaviorPatterns.isEmpty()) {
                    AggregateResult pattern = behaviorPatterns[0];
                    Decimal avgCompletion = (Decimal) pattern.get('avgCompletionTime');
                    Decimal avgSession = (Decimal) pattern.get('avgSessionDuration');
                    String preferredMethod = (String) pattern.get('preferredMethod');
                    
                    Integer behaviorScore = 0;
                    
                    // Check completion time anomaly
                    if (request.Time_To_Complete_Hours__c != null && avgCompletion != null) {
                        if (request.Time_To_Complete_Hours__c < (avgCompletion * 0.1)) {
                            behaviorScore += 10; // Suspiciously fast completion
                        } else if (request.Time_To_Complete_Hours__c > (avgCompletion * 10)) {
                            behaviorScore += 5; // Unusually slow completion
                        }
                    }
                    
                    // Check session duration anomaly
                    if (request.Session_Duration_Minutes__c != null && avgSession != null) {
                        if (request.Session_Duration_Minutes__c < (avgSession * 0.2)) {
                            behaviorScore += 5; // Very short session
                        } else if (request.Session_Duration_Minutes__c > (avgSession * 3)) {
                            behaviorScore += 5; // Very long session
                        }
                    }
                    
                    // Check signature method anomaly
                    if (preferredMethod != null && request.SignatureMethod__c != null && request.SignatureMethod__c != preferredMethod) {
                        behaviorScore += 5; // Unusual signature method
                    }
                    
                    riskFactor.riskLevel = behaviorScore;
                    riskFactor.description = 'Behavioral anomaly assessment based on historical patterns';
                } else {
                    riskFactor.riskLevel = 0;
                    riskFactor.description = 'No sufficient historical data for behavioral assessment';
                }
                
            } catch (Exception e) {
                riskFactor.riskLevel = 10;
                riskFactor.description = 'Unable to assess behavioral risk due to system error';
            }
            
            return riskFactor;
        }
        
        // Assess behavioral anomalies
        private static RiskFactor assessBehavioralRisk(Signature_Request__c request) {
            RiskFactor riskFactor = new RiskFactor();
            riskFactor.factorType = 'BEHAVIORAL_ANOMALY';
            riskFactor.riskWeight = SECURITY_RISK_WEIGHTS.get('BEHAVIORAL_ANOMALY');
            
            try {
                // Get user's typical completion patterns
                List<AggregateResult> behaviorPatterns = [
            SELECT AVG(Time_To_Complete_Hours__c) avgCompletionTime,
                   AVG(Session_Duration_Minutes__c) avgSessionDuration,
                   SignatureMethod__c preferredMethod,
                   COUNT(Id) methodUsage
            FROM Signature_Request__c 
            WHERE SignerEmail__c = :request.SignerEmail__c 
              AND Status__c = 'Completed'
              AND CreatedDate >= LAST_N_DAYS:90
            GROUP BY SignatureMethod__c
            ORDER BY COUNT(Id) DESC
            LIMIT 1
        ];
                
                Integer behaviorScore = 0;
                
                if (!behaviorPatterns.isEmpty()) {
                    AggregateResult pattern = behaviorPatterns[0];
                    Decimal avgCompletion = (Decimal) pattern.get('avgCompletionTime');
                    Decimal avgSession = (Decimal) pattern.get('avgSessionDuration');
                    String preferredMethod = (String) pattern.get('preferredMethod');
                    
                    // Check completion time anomaly
                    if (request.Time_To_Complete_Hours__c != null && avgCompletion != null) {
                        if (request.Time_To_Complete_Hours__c < (avgCompletion * 0.1)) {
                            behaviorScore += 10; // Suspiciously fast completion
                        } else if (request.Time_To_Complete_Hours__c > (avgCompletion * 10)) {
                            behaviorScore += 5; // Unusually slow completion
                        }
                    }
                    
                    // Check session duration anomaly
                    if (request.Session_Duration_Minutes__c != null && avgSession != null) {
                        if (request.Session_Duration_Minutes__c < (avgSession * 0.2)) {
                            behaviorScore += 5; // Very short session
                        } else if (request.Session_Duration_Minutes__c > (avgSession * 3)) {
                            behaviorScore += 5; // Very long session
                        }
                    }
                    
                    // Check method deviation
                    if (preferredMethod != null && request.SignatureMethod__c != preferredMethod) {
                        behaviorScore += 5; // Using different method than usual
                    }
                    
                    riskFactor.riskLevel = behaviorScore;
                    riskFactor.description = behaviorScore > 10 ? 'Significant behavioral anomalies detected' :
                        behaviorScore > 5 ? 'Minor behavioral deviations observed' :
                        'Normal behavioral patterns';
                } else {
                    riskFactor.riskLevel = 5; // New user, slight risk increase
                    riskFactor.description = 'No historical behavior data available';
                }
                
            } catch (Exception e) {
                riskFactor.riskLevel = 10;
                riskFactor.description = 'Unable to assess behavior due to system error';
            }
            
            return riskFactor;
        }
        
        // Assess time-based anomalies
        private static RiskFactor assessTimeAnomalies(Signature_Request__c request) {
            RiskFactor riskFactor = new RiskFactor();
            riskFactor.factorType = 'TIME_ANOMALY';
            riskFactor.riskWeight = SECURITY_RISK_WEIGHTS.get('TIME_ANOMALY');
            
            try {
                // Check if signing at unusual hours
                Time currentTime = request.CreatedDate.time();
                Integer currentHour = currentTime.hour();
                
                // Get user's typical signing hours
                List<AggregateResult> timePatterns = [
            SELECT HOUR_IN_DAY(CreatedDate) signHour, COUNT(Id) hourlyCount
            FROM Signature_Request__c 
            WHERE SignerEmail__c = :request.SignerEmail__c 
              AND CreatedDate >= LAST_N_DAYS:90
            GROUP BY HOUR_IN_DAY(CreatedDate)
            HAVING COUNT(Id) > 1
        ];
                
                Boolean isNormalHour = timePatterns.isEmpty(); // If no history, assume normal
                for (AggregateResult timePattern : timePatterns) {
                    Integer historicalHour = (Integer) timePattern.get('signHour');
                    if (Math.abs(currentHour - historicalHour) <= 2) { // Within 2 hours of normal
                        isNormalHour = true;
                        break;
                    }
                }
                
                // Check for off-hours activity (midnight to 5 AM)
                if (currentHour >= 0 && currentHour <= 5 && !isNormalHour) {
                    riskFactor.riskLevel = 10;
                    riskFactor.description = 'Signing during unusual hours';
                    riskFactor.evidence = 'Signing at ' + currentHour + ':00, outside normal patterns';
                } else if (!isNormalHour) {
                    riskFactor.riskLevel = 5;
                    riskFactor.description = 'Signing outside typical time patterns';
                } else {
                    riskFactor.riskLevel = 0;
                    riskFactor.description = 'Normal signing time patterns';
                }
                
            } catch (Exception e) {
                riskFactor.riskLevel = 5;
                riskFactor.description = 'Unable to assess time patterns due to system error';
            }
            
            return riskFactor;
        }
        
        // Helper methods for MFA validation
        private static MFAValidationResult validateSMSOTP(String signatureRequestId, String otpCode) {
            MFAValidationResult result = new MFAValidationResult();
            result.authMethod = 'SMS_OTP';
            
            try {
                // Get stored OTP record
                OTP_Validation__c storedOTP = [
            SELECT Id, OTP_Code__c, Expiration_Time__c, Attempts__c
            FROM OTP_Validation__c 
            WHERE Signature_Request_Id__c = :signatureRequestId 
              AND Auth_Method__c = 'SMS'
              AND Status__c = 'ACTIVE'
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
                
                // Validate OTP
                if (storedOTP.Expiration_Time__c < System.now()) {
                    result.success = false;
                    result.errorMessage = 'OTP has expired';
                    result.failureReason = 'EXPIRED';
                } else if (storedOTP.Attempts__c >= 3) {
                    result.success = false;
                    result.errorMessage = 'Maximum attempts exceeded';
                    result.failureReason = 'MAX_ATTEMPTS';
                } else if (storedOTP.OTP_Code__c != otpCode) {
                    // Increment attempt count
                    storedOTP.Attempts__c = (storedOTP.Attempts__c ?? 0) + 1;
                    update storedOTP;
                    
                    result.success = false;
                    result.errorMessage = 'Invalid OTP code';
                    result.failureReason = 'INVALID_CODE';
                } else {
                    // Valid OTP
                    storedOTP.Status__c = 'VERIFIED';
                    storedOTP.Verified_At__c = System.now();
                    update storedOTP;
                    
                    result.success = true;
                    result.validationScore = 95;
                    result.trustLevel = 'HIGH';
                }
                
            } catch (Exception e) {
                result.success = false;
                result.errorMessage = 'SMS OTP validation error: ' + e.getMessage();
            }
            
            return result;
        }
        
        // Validate Email OTP
        private static MFAValidationResult validateEmailOTP(String signatureRequestId, String otpCode) {
            MFAValidationResult result = new MFAValidationResult();
            result.authMethod = 'EMAIL_OTP';
            
            try {
                OTP_Validation__c storedOTP = [
            SELECT Id, OTP_Code__c, Expiration_Time__c, Attempts__c
            FROM OTP_Validation__c 
            WHERE Signature_Request_Id__c = :signatureRequestId 
              AND Auth_Method__c = 'EMAIL'
              AND Status__c = 'ACTIVE'
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
                
                if (storedOTP.Expiration_Time__c < System.now()) {
                    result.success = false;
                    result.errorMessage = 'Email OTP has expired';
                    result.failureReason = 'EXPIRED';
                } else if (storedOTP.Attempts__c >= 5) { // Allow more attempts for email
                    result.success = false;
                    result.errorMessage = 'Maximum attempts exceeded';
                    result.failureReason = 'MAX_ATTEMPTS';
                } else if (storedOTP.OTP_Code__c != otpCode) {
                    storedOTP.Attempts__c = (storedOTP.Attempts__c ?? 0) + 1;
                    update storedOTP;
                    
                    result.success = false;
                    result.errorMessage = 'Invalid email OTP';
                    result.failureReason = 'INVALID_CODE';
                } else {
                    storedOTP.Status__c = 'VERIFIED';
                    storedOTP.Verified_At__c = System.now();
                    update storedOTP;
                    
                    result.success = true;
                    result.validationScore = 90;
                    result.trustLevel = 'HIGH';
                }
                
            } catch (Exception e) {
                result.success = false;
                result.errorMessage = 'Email OTP validation error: ' + e.getMessage();
            }
            
            return result;
        }
        
        // Validate TOTP
        private static MFAValidationResult validateTOTP(String signatureRequestId, String totpCode) {
            MFAValidationResult result = new MFAValidationResult();
            result.authMethod = 'TOTP';
            
            try {
                // Get user's TOTP secret
                Signature_Request__c request = [
            SELECT SignerEmail__c 
            FROM Signature_Request__c 
            WHERE Id = :signatureRequestId 
            LIMIT 1
        ];
                
                TOTP_Secret__c totpSecret = [
            SELECT Id, Secret_Key__c, Algorithm__c 
            FROM TOTP_Secret__c 
            WHERE User_Email__c = :request.SignerEmail__c 
              AND Status__c = 'ACTIVE' 
            LIMIT 1
        ];
                
                // Validate TOTP (simplified)
                Boolean isValidTOTP = validateTOTPCode(totpSecret.Secret_Key__c, totpCode);
                
                if (isValidTOTP) {
                    result.success = true;
                    result.validationScore = 98;
                    result.trustLevel = 'VERY_HIGH';
                } else {
                    result.success = false;
                    result.errorMessage = 'Invalid TOTP code';
                    result.failureReason = 'INVALID_CODE';
                }
                
            } catch (Exception e) {
                result.success = false;
                result.errorMessage = 'TOTP validation error: ' + e.getMessage();
            }
            
            return result;
        }
       private static MFAValidationResult validateBiometric(String signatureRequestId, String biometricData) {
        MFAValidationResult result = new MFAValidationResult();
        result.authMethod = 'BIOMETRIC'; try {
            // Parse biometric validation data
            Map<String, Object> bioData = (Map<String, Object>)JSON.deserializeUntyped(biometricData); // Get stored biometric template
            Signature_Request__c request = [ SELECT SignerEmail__c FROM Signature_Request__c WHERE Id = :signatureRequestId LIMIT 1
]; Biometric_Template__c storedTemplate = [ SELECT Id, Template_Hash__c, Biometric_Type__c, Quality_Score__c FROM Biometric_Template__c WHERE User_Email__c = :request.SignerEmail__c AND Status__c = 'ACTIVE' AND Biometric_Type__c = :((String)bioData.get('biometricType')) LIMIT 1
]; // Perform biometric matching (simplified)
            Decimal matchScore = calculateBiometricMatch( (String)bioData.get('biometricHash'), storedTemplate.Template_Hash__c, storedTemplate.Biometric_Type__c
            ); if (matchScore >= 0.85) { // 85% match threshold result.success = true; result.validationScore = Integer.valueOf(matchScore * 100); result.trustLevel = matchScore >= 0.95? 'VERY_HIGH' : 'HIGH';
            } else { result.success = false; result.errorMessage = 'Biometric verification failed'; result.failureReason = 'NO_MATCH'; result.validationScore = Integer.valueOf(matchScore * 100);
        } } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Biometric validation error: ' + e.getMessage();
        } return result;
    } // Helper methods for compliance verification
    private static ComplianceCheck performGDPRCompliance(DocumentLifecycleConfiguration__c document) {
        ComplianceCheck check = new ComplianceCheck();
        check.regulationType = 'GDPR';
        check.checkName = 'General Data Protection Regulation';
        check.violations = new List<String>(); String content = document.DocumentContent__c.toLowerCase(); // Check for required GDPR elements
        if (!content.contains('data processing') &&!content.contains('personal data')) { check.violations.add('Missing data processing clauses');
        } if (!content.contains('consent') &&!content.contains('agreement')) { check.violations.add('Missing explicit consent language');
        } if (!content.contains('right to withdraw') &&!content.contains('revoke consent')) { check.violations.add('Missing withdrawal of consent provisions');
        } if (!content.contains('data controller') &&!content.contains('responsible party')) { check.violations.add('Missing data controller identification');
        } if (!content.contains('privacy policy') &&!content.contains('data protection')) { check.violations.add('Missing privacy policy references');
        } // Calculate compliance score
        check.complianceScore = Math.max(0, 100 - (check.violations.size() * 20));
        check.status = check.complianceScore >= 80? 'COMPLIANT' : 'NON_COMPLIANT';
        check.recommendations = generateGDPRRecommendations(check.violations); return check;
    } private static ComplianceCheck performCCPACompliance(DocumentLifecycleConfiguration__c document) {
        ComplianceCheck check = new ComplianceCheck();
        check.regulationType = 'CCPA';
        check.checkName = 'California Consumer Privacy Act';
        check.violations = new List<String>(); String content = document.DocumentContent__c.toLowerCase(); // Check for CCPA requirements
        if (!content.contains('personal information') &&!content.contains('consumer data')) { check.violations.add('Missing personal information definitions');
        } if (!content.contains('right to know') &&!content.contains('disclosure rights')) { check.violations.add('Missing consumer rights disclosure');
        } if (!content.contains('opt-out') &&!content.contains('do not sell')) { check.violations.add('Missing opt-out provisions');
        } if (!content.contains('deletion rights') &&!content.contains('right to delete')) { check.violations.add('Missing deletion rights provisions');
        } // Calculate compliance score
        check.complianceScore = Math.max(0, 100 - (check.violations.size() * 25));
        check.status = check.complianceScore >= 75? 'COMPLIANT' : 'NON_COMPLIANT';
        check.recommendations = generateCCPARecommendations(check.violations); return check;
    } private static ComplianceCheck performSOXCompliance(DocumentLifecycleConfiguration__c document) {
        ComplianceCheck check = new ComplianceCheck();
        check.regulationType = 'SOX';
        check.checkName = 'Sarbanes-Oxley Act';
        check.violations = new List<String>(); String content = document.DocumentContent__c.toLowerCase(); // Check for SOX requirements
        if (!content.contains('financial') &&!content.contains('audit')) { check.violations.add('Missing financial context identification');
        } if (!content.contains('internal controls') &&!content.contains('compliance')) { check.violations.add('Missing internal controls references');
        } if (!content.contains('accuracy') &&!content.contains('truthful')) { check.violations.add('Missing accuracy attestations');
        } if (!content.contains('officer certification') &&!content.contains('executive')) { check.violations.add('Missing officer certification requirements');
        } // Calculate compliance score
        check.complianceScore = Math.max(0, 100 - (check.violations.size() * 30));
        check.status = check.complianceScore >= 85? 'COMPLIANT' : 'NON_COMPLIANT';
        check.recommendations = generateSOXRecommendations(check.violations); return check;
    } private static ComplianceCheck performHIPAACompliance(DocumentLifecycleConfiguration__c document) {
        ComplianceCheck check = new ComplianceCheck();
        check.regulationType = 'HIPAA';
        check.checkName = 'Health Insurance Portability and Accountability Act';
        check.violations = new List<String>(); String content = document.DocumentContent__c.toLowerCase(); // Check for HIPAA requirements
        if (!content.contains('protected health information') &&!content.contains('phi') &&!content.contains('medical')) { check.violations.add('Missing PHI identification and protection clauses');
        } if (!content.contains('minimum necessary') &&!content.contains('limited disclosure')) { check.violations.add('Missing minimum necessary provisions');
        } if (!content.contains('patient rights') &&!content.contains('individual rights')) { check.violations.add('Missing patient rights disclosures');
        } if (!content.contains('business associate') &&!content.contains('covered entity')) { check.violations.add('Missing HIPAA entity role definitions');
        } if (!content.contains('breach notification') &&!content.contains('security incident')) { check.violations.add('Missing breach notification procedures');
        } // Calculate compliance score
        check.complianceScore = Math.max(0, 100 - (check.violations.size() * 20));
        check.status = check.complianceScore >= 90? 'COMPLIANT' : 'NON_COMPLIANT';
        check.recommendations = generateHIPAARecommendations(check.violations); return check;
    } // Utility methods
    private static Decimal calculateLocationDistance(String location1, String location2) {
        // Simplified distance calculation - in production would use proper geolocation API
        try {
            // Parse coordinate strings (format: "lat,lng")
            List<String> coords1 = location1.split(',');
            List<String> coords2 = location2.split(','); if (coords1.size() == 2 && coords2.size() == 2) { Decimal lat1 = Decimal.valueOf(coords1[0].trim()); Decimal lng1 = Decimal.valueOf(coords1[1].trim()); Decimal lat2 = Decimal.valueOf(coords2[0].trim()); Decimal lng2 = Decimal.valueOf(coords2[1].trim()); // Simple distance approximation (Euclidean distance)
                Decimal latDiff = Math.abs(lat1 - lat2);
                Decimal lngDiff = Math.abs(lng1 - lng2);
                return Math.sqrt((latDiff * latDiff) + (lngDiff * lngDiff)) * 111; // Rough km conversion
            }
        } catch (Exception e) {
            System.debug('Location distance calculation error: ' + e.getMessage());
        } return 0; // Default to same location if calculation fails
    } private static Boolean validateTOTPCode(String secretKey, String totpCode) {
        // Simplified TOTP validation - in production would use proper TOTP algorithm
        try {
            // Get current 30-second time window
            Long timeWindow = System.now().getTime() / 30000; // Basic validation simulation return totpCode.length() == 6 && totpCode.isNumeric();
        } catch (Exception e) {
            System.debug('TOTP validation error: ' + e.getMessage());
            return false;
        }
    } private static Decimal calculateBiometricMatch(String providedHash, String storedHash, String biometricType) {
        try {
            // Simplified biometric matching - in production would use ML/AI services
            if (providedHash == storedHash) { return 1.0; // Perfect match
            } // Calculate similarity based on hash comparison
            Integer matchingChars = 0;
            Integer totalChars = Math.min(providedHash.length(), storedHash.length()); for (Integer i = 0; i < totalChars; i++) { if (providedHash.substring(i, i+1) == storedHash.substring(i, i+1)) { matchingChars++;
                }
            } return (Decimal)matchingChars / totalChars;
        } catch (Exception e) {
            System.debug('Biometric match calculation error: ' + e.getMessage());
            return 0.0;
        }
    } private static String determineRiskLevel(Integer totalRiskScore) {
        if (totalRiskScore >= 70) { return 'CRITICAL';
        } else if (totalRiskScore >= 40) { return 'HIGH';
        } else if (totalRiskScore >= 20) { return 'MEDIUM';
        } else { return 'LOW';
        }
    } private static Decimal calculateOverallComplianceScore(List<ComplianceCheck> checks) {
        if (checks.isEmpty()) { return 0;
        } Decimal totalScore = 0;
        for (ComplianceCheck check : checks) {
            totalScore += check.complianceScore;
        } return totalScore / checks.size();
    } private static String determineComplianceLevel(Decimal overallScore) {
        if (overallScore >= 90) { return 'EXCELLENT';
        } else if (overallScore >= 80) { return 'GOOD';
        } else if (overallScore >= 70) { return 'ACCEPTABLE';
        } else if (overallScore >= 60) { return 'NEEDS_IMPROVEMENT';
        } else { return 'CRITICAL';
        }
    } private static List<String> generateSecurityRecommendations(SecurityAssessmentResult assessment) {
        List<String> recommendations = new List<String>(); switch on assessment.riskLevel {
            when 'CRITICAL' {
                recommendations.add('IMMEDIATE ACTION: Block signature request pending investigation');
                recommendations.add('Require multi-factor authentication verification');
                recommendations.add('Contact signer through alternative communication channel');
                recommendations.add('Flag user account for enhanced monitoring');
            } when 'HIGH' {
                recommendations.add('Require additional authentication before processing');
                recommendations.add('Implement step-up verification procedures');
                recommendations.add('Review and verify signer identity manually');
                recommendations.add('Enable enhanced audit logging');
            } when 'MEDIUM' {
                recommendations.add('Consider requiring email verification');
                recommendations.add('Implement additional monitoring for this session');
                recommendations.add('Review signature request details carefully');
            } when 'LOW' {
                recommendations.add('Process normally with standard security measures');
                recommendations.add('Continue routine monitoring');
            }
        } return recommendations;
    } private static List<String> generateComplianceRecommendations(List<ComplianceCheck> checks) {
        List<String> recommendations = new List<String>(); for (ComplianceCheck check : checks) { if (check.status == 'NON_COMPLIANT') { recommendations.addAll(check.recommendations);
            }
        } if (recommendations.isEmpty()) { recommendations.add('All compliance checks passed - no additional action required');
        } return recommendations;
    } private static List<String> generateGDPRRecommendations(List<String> violations) {
        List<String> recommendations = new List<String>(); for (String violation : violations) {
            if (violation.contains('data processing')) { recommendations.add('Add explicit data processing purpose and legal basis clauses');
            } if (violation.contains('consent')) { recommendations.add('Include clear consent language with opt-in mechanisms');
            } if (violation.contains('withdrawal')) { recommendations.add('Add provisions for withdrawing consent at any time');
            } if (violation.contains('controller')) { recommendations.add('Clearly identify the data controller and contact information');
            } if (violation.contains('privacy policy')) { recommendations.add('Reference comprehensive privacy policy and data protection measures');
            }
        } return recommendations;
    } private static List<String> generateCCPARecommendations(List<String> violations) {
        List<String> recommendations = new List<String>(); for (String violation : violations) {
            if (violation.contains('personal information')) { recommendations.add('Define personal information categories being collected');
            } if (violation.contains('consumer rights')) { recommendations.add('Add clear disclosure of consumer rights under CCPA');
            } if (violation.contains('opt-out')) { recommendations.add('Include opt-out mechanisms and "Do Not Sell" provisions');
            } if (violation.contains('deletion')) { recommendations.add('Add consumer rights to request deletion of personal information');
            }
        } return recommendations;
    } private static List<String> generateSOXRecommendations(List<String> violations) {
        List<String> recommendations = new List<String>(); for (String violation : violations) {
            if (violation.contains('financial')) { recommendations.add('Clearly identify financial reporting context and requirements');
            } if (violation.contains('internal controls')) { recommendations.add('Reference internal control frameworks and compliance procedures');
            } if (violation.contains('accuracy')) { recommendations.add('Include accuracy attestations and truthfulness declarations');
            } if (violation.contains('officer')) { recommendations.add('Add officer certification and executive responsibility clauses');
            }
        } return recommendations;
    } private static List<String> generateHIPAARecommendations(List<String> violations) {
        List<String> recommendations = new List<String>(); for (String violation : violations) {
            if (violation.contains('PHI')) { recommendations.add('Add comprehensive PHI protection and handling procedures');
            } if (violation.contains('minimum necessary')) { recommendations.add('Include minimum necessary disclosure provisions');
            } if (violation.contains('patient rights')) { recommendations.add('Add patient rights disclosures and request procedures');
            } if (violation.contains('entity')) { recommendations.add('Define covered entity and business associate relationships');
            } if (violation.contains('breach')) { recommendations.add('Include breach notification and incident response procedures');
            }
        } return recommendations;
    } // Storage methods
    private static void storeSecurityAssessment(SecurityAssessmentResult assessment) {
        try {
            Security_Assessment__c record = new Security_Assessment__c();
            record.Signature_Request_Id__c = assessment.signatureRequestId;
            record.Assessment_Timestamp__c = assessment.assessmentTimestamp;
            record.Total_Risk_Score__c = assessment.totalRiskScore;
            record.Risk_Level__c = assessment.riskLevel;
            record.Risk_Factors_JSON__c = JSON.serialize(assessment.riskFactors);
            record.Recommendations_JSON__c = JSON.serialize(assessment.recommendations);
            record.Assessment_Status__c = 'COMPLETED'; insert record;
        } catch (Exception e) {
            System.debug('Failed to store security assessment: ' + e.getMessage());
        }
    } private static void storeComplianceVerification(ComplianceVerificationResult verification) {
        try {
            Compliance_Verification__c record = new Compliance_Verification__c();
            record.Document_Id__c = verification.documentId;
            record.Jurisdiction__c = verification.jurisdiction;
            record.Verification_Timestamp__c = verification.verificationTimestamp;
            record.Overall_Compliance_Score__c = verification.overallComplianceScore;
            record.Compliance_Level__c = verification.complianceLevel;
            record.Compliance_Checks_JSON__c = JSON.serialize(verification.complianceChecks);
            record.Compliance_Checks_JSON__c = JSON.serialize(verification.complianceChecks);
            record.Recommendations_JSON__c = JSON.serialize(verification.recommendations);
           try {
    record.Verification_Status__c = 'COMPLETED';
    insert record;
} catch (Exception e) {
    System.debug('Failed to store compliance verification: ' + e.getMessage());
}
        }
    }

        private static void logAuthenticationAttempt(MFAValidationResult result) {
    try {
        Authentication_Log__c log = new Authentication_Log__c();
        log.Signature_Request_Id__c = result.signatureRequestId;
        log.Authentication_Method__c = result.authMethod;
        log.Validation_Timestamp__c = result.validationTimestamp;
        log.Success__c = result.success;
        log.Validation_Score__c = result.validationScore;
        log.Trust_Level__c = result.trustLevel;
        log.Failure_Reason__c = result.failureReason;
        log.Error_Message__c = result.errorMessage;

        insert log;
    } catch (Exception e) {
        System.debug('Failed to log authentication attempt: ' + e.getMessage());
    }
}

// Wrapper classes for security results
public class SecurityAssessmentResult {
    @AuraEnabled public String signatureRequestId { get; set; }
    @AuraEnabled public DateTime assessmentTimestamp { get; set; }
    @AuraEnabled public List<RiskFactor> riskFactors { get; set; }
    @AuraEnabled public Integer totalRiskScore { get; set; }
    @AuraEnabled public String riskLevel { get; set; }
    @AuraEnabled public List<String> recommendations { get; set; }
    @AuraEnabled public Boolean success { get; set; }
    @AuraEnabled public String errorMessage { get; set; }

    public SecurityAssessmentResult() {
        this.riskFactors = new List<RiskFactor>();
        this.recommendations = new List<String>();
        this.totalRiskScore = 0;
        this.success = false;
    }
}
public class RiskFactor {
    @AuraEnabled public String factorType { get; set; }
    @AuraEnabled public Integer riskLevel { get; set; }
    @AuraEnabled public Integer riskWeight { get; set; }
    @AuraEnabled public String description { get; set; }
    @AuraEnabled public String evidence { get; set; }
}

public class MFAValidationResult {
    @AuraEnabled public String signatureRequestId { get; set; }
    @AuraEnabled public String authMethod { get; set; }
    @AuraEnabled public DateTime validationTimestamp { get; set; }
    @AuraEnabled public Boolean success { get; set; }
    @AuraEnabled public Integer validationScore { get; set; }
    @AuraEnabled public String trustLevel { get; set; }
    @AuraEnabled public String failureReason { get; set; }
    @AuraEnabled public String errorMessage { get; set; }
}

public class ComplianceVerificationResult {
    @AuraEnabled public String documentId { get; set; }
    @AuraEnabled public String jurisdiction { get; set; }
    @AuraEnabled public DateTime verificationTimestamp { get; set; }
    @AuraEnabled public List<ComplianceCheck> complianceChecks { get; set; }
    @AuraEnabled public Decimal overallComplianceScore { get; set; }
    @AuraEnabled public String complianceLevel { get; set; }
    @AuraEnabled public List<String> recommendations { get; set; }
    @AuraEnabled public Boolean success { get; set; }
    @AuraEnabled public String errorMessage { get; set; }

    public ComplianceVerificationResult() {
        this.complianceChecks = new List<ComplianceCheck>();
        this.recommendations = new List<String>();
        this.success = false;
    }
}

public class ComplianceCheck {
    @AuraEnabled public String regulationType { get; set; }
    @AuraEnabled public String checkName { get; set; }
    @AuraEnabled public List<String> violations { get; set; }
    @AuraEnabled public Decimal complianceScore { get; set; }
    @AuraEnabled public String status { get; set; }
    @AuraEnabled public List<String> recommendations { get; set; }

    public ComplianceCheck() {
        this.violations = new List<String>();
        this.recommendations = new List<String>();
    }
}
    }
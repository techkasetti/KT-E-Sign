public class AdvancedSecurityFramework{
    
    // Security thresholds and configuration
    private static final Decimal BIOMETRIC_CONFIDENCE_THRESHOLD = 85.0;
    private static final Decimal FRAUD_RISK_THRESHOLD = 75.0;
    private static final Integer MAX_FAILED_ATTEMPTS = 3;
    private static final Integer SECURITY_LOCKOUT_MINUTES = 15;
    
    /**
     * Perform comprehensive security validation for signature request
     */
    /** * Validate device fingerprint and detect suspicious devices */
    public static DeviceValidationResult validateDevice(Map<String, Object> securityContext) {
        DeviceValidationResult result = new DeviceValidationResult();
        result.isValid = true;
        result.trustScore = 100.0;
        result.issues = new List<String>();
        
        try {
            if (!securityContext.containsKey('deviceFingerprint')) {
                result.issues.add('Device fingerprint not provided');
                result.trustScore -= 30.0;
                result.isValid = false;
                return result;
            }
            
            Map<String, Object> deviceData = (Map<String, Object>) securityContext.get('deviceFingerprint');
            String deviceId = (String) deviceData.get('deviceId');
            String userAgent = (String) deviceData.get('userAgent');
            String screenResolution = (String) deviceData.get('screenResolution');
            String timezone = (String) deviceData.get('timezone');
            
            // Check device blacklist
            List<SecurityBlacklist__c> blacklistedDevices = [
            SELECT Id, Reason__c
            FROM SecurityBlacklist__c
            WHERE Type__c = 'DEVICE'
            AND Value__c = :deviceId
            AND IsActive__c = true
            LIMIT 1
        ];
            
            if (!blacklistedDevices.isEmpty()) {
                result.issues.add('Device is blacklisted: ' + blacklistedDevices[0].Reason__c);
                result.trustScore = 0.0;
                result.isValid = false;
                return result;
            }
            
            // Analyze device characteristics
            if (isVirtualMachine(userAgent)) {
                result.issues.add('Virtual machine or emulator detected');
                result.trustScore -= 40.0;
            }
            
            if (isSuspiciousUserAgent(userAgent)) {
                result.issues.add('Suspicious or automated user agent detected');
                result.trustScore -= 25.0;
            }
            
            if (isUnusualScreenResolution(screenResolution)) {
                result.issues.add('Unusual screen resolution may indicate automation');
                result.trustScore -= 15.0;
            }
            
            // Check device history
            DeviceHistoryAnalysis historyResult = analyzeDeviceHistory(deviceId);
            if (historyResult.suspiciousActivity) {
                result.issues.addAll(historyResult.concerns);
                result.trustScore -= historyResult.riskDeduction;
            }
            
            result.isValid = result.trustScore > 50.0;
        } catch (Exception e) {
            result.issues.add('Device validation error: ' + e.getMessage());
            result.trustScore = 0.0;
            result.isValid = false;
        }
        
        return result;
    }
    /** * Perform biometric liveness detection */
    public static BiometricValidationResult validateBiometricLiveness(Map<String, Object> biometricData) {
        BiometricValidationResult result = new BiometricValidationResult();
        result.livenessDetected = false;
        result.confidenceScore = 0.0;
        result.spoofingRisk = 100.0;
        result.validationDetails = new List<String>();
        
        try {
            // Extract biometric data
            String faceImageData = (String)biometricData.get('faceImage');
            List<Object> landmarkData = (List<Object>)biometricData.get('facialLandmarks');
            Map<String, Object> motionData = (Map<String, Object>)biometricData.get('motionAnalysis');
            Map<String, Object> depthData = (Map<String, Object>)biometricData.get('depthAnalysis');
            
            // 1. Eye movement and blink detection
            Boolean eyeMovementDetected = analyzeEyeMovement(landmarkData);
            
            if (eyeMovementDetected) {
                result.confidenceScore += 25.0;
                result.validationDetails.add('Natural eye movement detected');
            } else {
                result.validationDetails.add('No eye movement detected - potential static image');
                result.spoofingRisk += 30.0;
            }
            
            // 2. Facial micro-expressions analysis
            Boolean microExpressions = analyzeMicroExpressions(landmarkData);
            if (microExpressions) {
                result.confidenceScore += 20.0;
                result.validationDetails.add('Micro-expressions detected');
            } else {
                result.validationDetails.add('No micro-expressions - possible photo attack');
                result.spoofingRisk += 25.0;
            }
            
            // 3. 3D depth analysis
            if (depthData != null) {
                Boolean depthVariation = (Boolean)depthData.get('hasDepthVariation');
                Decimal depthConsistency = (Decimal)depthData.get('consistencyScore');
                
                if (depthVariation && depthConsistency > 80.0) {
                    result.confidenceScore += 30.0;
                    result.validationDetails.add('3D depth structure confirmed');
                } else {
                    result.validationDetails.add('Flat depth profile - potential 2D attack');
                    result.spoofingRisk += 35.0;
                }
            } else {
                result.validationDetails.add('No depth data available');
                result.spoofingRisk += 20.0;
            }
            
            // 4. Motion analysis
            if (motionData != null) {
                Boolean naturalMotion = (Boolean)motionData.get('naturalMotion');
                Decimal motionSmoothing = (Decimal)motionData.get('smoothingDetected');
                
                if (naturalMotion && motionSmoothing < 20.0) {
                    result.confidenceScore += 15.0;
                    result.validationDetails.add('Natural head movement detected');
                } else {
                    result.validationDetails.add('Artificial motion or excessive smoothing detected');
                    result.spoofingRisk += 20.0;
                }
            }
            
            // 5. Texture analysis for print attacks
            Boolean naturalTexture = analyzeTextureConsistency(faceImageData);
            if (naturalTexture) {
                result.confidenceScore += 10.0;
                result.validationDetails.add('Natural skin texture detected');
            } else {
                result.validationDetails.add('Artificial texture - possible print attack');
                result.spoofingRisk += 15.0;
            }
            
            // Calculate final scores
            result.spoofingRisk = Math.max(0.0, 100.0 - result.confidenceScore);
            result.livenessDetected = result.confidenceScore >= BIOMETRIC_CONFIDENCE_THRESHOLD;
            result.confidenceScore = Math.min(result.confidenceScore, 100.0);
            
            // Store biometric validation record
            BiometricValidation__c validation = new BiometricValidation__c();
            validation.ValidationTimestamp__c = System.now();
            validation.BiometricType__c = 'FACIAL_RECOGNITION';
            validation.ConfidenceScore__c = result.confidenceScore;
            validation.LivenessDetected__c = result.livenessDetected;
            validation.SpoofingRisk__c = result.spoofingRisk;
            validation.ValidationDetails__c = String.join(result.validationDetails, '; ');
            insert validation;
            
            result.validationId = validation.Id;
        } catch (Exception e) {
            result.validationDetails.add('Biometric validation error: ' + e.getMessage());
            result.confidenceScore = 0.0;
            result.livenessDetected = false;
            result.spoofingRisk = 100.0;
        }
        return result;
    } /**
     * Analyze user behavior patterns for anomaly detection
     */
    public static UserBehaviorAnalysisResult analyzeBehaviorPatterns(Signature_Request__c request, Map<String, Object> securityContext) {
        UserBehaviorAnalysisResult result = new UserBehaviorAnalysisResult();
        result.normalityScore = 100.0;
        result.anomaliesDetected = false;
        result.anomalies = new List<String>();
        result.riskIncrement = 0.0; try {
            String signerEmail = request.SignerEmail__c;
            
            // 1. Signing speed analysis
            if (securityContext.containsKey('signingDuration')) {
                Integer signingDuration = (Integer)securityContext.get('signingDuration');
                if (signingDuration < 10) { // Less than 10 seconds
                    result.anomalies.add('Extremely fast signing time: ' + signingDuration + ' seconds');
                    result.riskIncrement += 20.0;
                    result.anomaliesDetected = true;
                }
            }
            
            // 2. Mouse/touch movement analysis
            if (securityContext.containsKey('interactionPatterns')) {
                Map<String, Object> patterns = (Map<String, Object>)securityContext.get('interactionPatterns');
                Boolean roboticMovement = (Boolean)patterns.get('roboticMovement');
                Integer clickAccuracy = (Integer)patterns.get('clickAccuracy');
                
                if (roboticMovement || clickAccuracy > 95) {
                    result.anomalies.add('Robotic interaction patterns detected');
                    result.riskIncrement += 25.0;
                    result.anomaliesDetected = true;
                }
            }
            
            // 3. Historical behavior comparison
            List<AggregateResult> historicalSigning = [
        SELECT AVG(HOUR_IN_DAY(CompletedDate__c)) avgHour,
               COUNT(Id) totalSigned
        FROM Signature_Request__c 
        WHERE SignerEmail__c = :signerEmail 
        AND Status__c = 'Completed'
        AND CreatedDate >= :System.now().addDays(-90)
    ];
            
            if (!historicalSigning.isEmpty() && historicalSigning[0].get('totalSigned') != null) {
                Integer totalSigned = (Integer)historicalSigning[0].get('totalSigned');
                if (totalSigned > 0) {
                    Decimal avgHour = (Decimal)historicalSigning[0].get('avgHour');
                    Integer currentHour = System.now().hour();
                    
                    // Check for unusual time patterns
                    if (Math.abs(currentHour - avgHour) > 8) {
                        result.anomalies.add('Signing at unusual time compared to historical pattern');
                        result.riskIncrement += 10.0;
                        result.anomaliesDetected = true;
                    }
                }
            }
            
            // 4. Frequency analysis - too many signatures in short time
            List<AggregateResult> recentActivity = [
        SELECT COUNT(Id) recentCount
        FROM Signature_Request__c 
        WHERE SignerEmail__c = :signerEmail 
        AND CreatedDate >= :System.now().addHours(-1)
    ];
            
            if (!recentActivity.isEmpty()) {
                Integer recentCount = (Integer)recentActivity[0].get('recentCount');
                if (recentCount > 5) { // More than 5 signatures in 1 hour
                    result.anomalies.add('Excessive signing frequency: ' + recentCount + ' signatures in 1 hour');
                    result.riskIncrement += 30.0;
                    result.anomaliesDetected = true;
                }
            }
            
            // 5. Browser and device consistency
            if (securityContext.containsKey('browserFingerprint')) {
                Map<String, Object> browserData = (Map<String, Object>)securityContext.get('browserFingerprint');
                
                // Check for headless browser indicators
                Boolean headlessBrowser = (Boolean)browserData.get('headlessDetected');
                if (headlessBrowser) {
                    result.anomalies.add('Headless browser detected - automated signing suspected');
                    result.riskIncrement += 40.0;
                    result.anomaliesDetected = true;
                }
                
                // Check for selenium/automation indicators
                List<Object> automationIndicators = (List<Object>)browserData.get('automationIndicators');
                if (automationIndicators != null && !automationIndicators.isEmpty()) {
                    result.anomalies.add('Browser automation detected: ' + String.join((List<String>)automationIndicators, ', '));
                    result.riskIncrement += 35.0;
                    result.anomaliesDetected = true;
                }
            }
            
            result.normalityScore = Math.max(0.0, result.normalityScore - result.riskIncrement);
            
        } catch (Exception e) {
            result.anomalies.add('Behavior analysis error: ' + e.getMessage());
            result.anomaliesDetected = true;
            result.riskIncrement = 25.0;
        } return result;
    } /**
     * Validate geolocation and detect suspicious locations
     */
    public static LocationValidationResult validateLocation(Map<String, Object> securityContext) {
        LocationValidationResult result = new LocationValidationResult();
        result.isValid = true;
        result.trustScore = 100.0;
        result.securityConcerns = new List<String>();
        result.riskIncrement = 0.0; try {
            if (!securityContext.containsKey('geolocation')) {
                result.securityConcerns.add('No geolocation data provided');
                result.trustScore -= 20.0;
                result.riskIncrement += 15.0;
                return result;
            }
            
            Map<String, Object> locationData = (Map<String, Object>)securityContext.get('geolocation');
            String ipAddress = (String)locationData.get('ipAddress');
            String country = (String)locationData.get('country');
            String city = (String)locationData.get('city');
            Boolean vpnDetected = (Boolean)locationData.get('vpnDetected');
            Boolean proxyDetected = (Boolean)locationData.get('proxyDetected');
            
            // 1. Check for VPN/Proxy usage
            if (vpnDetected || proxyDetected) {
                result.securityConcerns.add('VPN or proxy detected - location masking suspected');
                result.trustScore -= 30.0;
                result.riskIncrement += 25.0;
            }
            
            // 2. Check against high-risk countries
            List<String> highRiskCountries = new List<String>{
                'Anonymous Proxy', 'Satellite Provider', 'Unknown'
            };
            
            if (highRiskCountries.contains(country)) {
                result.securityConcerns.add('High-risk or anonymous location detected: ' + country);
                result.trustScore -= 40.0;
                result.riskIncrement += 30.0;
            }
            
            // 3. Check IP reputation
            if (securityContext.containsKey('ipReputation')) {
                Map<String, Object> ipRep = (Map<String, Object>)securityContext.get('ipReputation');
                Boolean malicious = (Boolean)ipRep.get('malicious');
                Integer riskScore = (Integer)ipRep.get('riskScore');
                
                if (malicious || riskScore > 70) {
                    result.securityConcerns.add('Malicious IP detected - Risk score: ' + riskScore);
                    result.trustScore -= 50.0;
                    result.riskIncrement += 40.0;
                }
            }
            
            // 4. Location blacklist check
            List<SecurityBlacklist__c> blacklistedIPs = [
        SELECT Id, Reason__c 
        FROM SecurityBlacklist__c 
        WHERE Type__c = 'IP_ADDRESS' 
        AND Value__c = :ipAddress 
        AND IsActive__c = true 
        LIMIT 1
    ];
            
            if (!blacklistedIPs.isEmpty()) {
                result.securityConcerns.add('IP address is blacklisted: ' + blacklistedIPs[0].Reason__c);
                result.trustScore = 0.0;
                result.riskIncrement = 100.0;
                result.isValid = false;
            }
            
            // 5. Geolocation consistency check
            if (securityContext.containsKey('historicalLocations')) {
                List<Object> historicalLocs = (List<Object>)securityContext.get('historicalLocations');
                Boolean locationJump = analyzeLocationJumping(country, city, historicalLocs);
                
                if (locationJump) {
                    result.securityConcerns.add('Suspicious location jumping detected');
                    result.trustScore -= 25.0;
                    result.riskIncrement += 20.0;
                }
            }
            
            result.isValid = result.trustScore > 30.0;
            
        } catch (Exception e) {
            result.securityConcerns.add('Location validation error: ' + e.getMessage());
            result.trustScore = 50.0; // Neutral score on error
            result.riskIncrement = 15.0;
        } return result;
    } /**
     * Validate time patterns for suspicious signing times
     */
    public static TimeValidationResult validateTimePatterns(Signature_Request__c request, Map<String, Object> securityContext) {
    TimeValidationResult result = new TimeValidationResult();
    result.normalityScore = 100.0;
    result.suspicious = false;
    result.concerns = new List<String>();

    try {
        DateTime requestTime = System.now();
        Integer currentHour = requestTime.hour();
        Integer dayOfWeek = Math.mod(Date.today().toStartofWeek().daysBetween(Date.today()), 7);

        // 1. Check for unusual hours (midnight to 5 AM)
        if (currentHour >= 0 && currentHour <= 5) {
            result.concerns.add('Signing attempt during unusual hours: ' + currentHour + ':00');
            result.normalityScore -= 20.0;
            result.suspicious = true;
        }

        // 2. Weekend signing pattern analysis
        if (dayOfWeek == 0 || dayOfWeek == 6) { // Sunday or Saturday
            result.concerns.add('Weekend signing activity detected');
            result.normalityScore -= 10.0;
        }

        // 3. Holiday checking (if available in custom settings)
        if (isHoliday(Date.today())) {
            result.concerns.add('Signing on holiday date');
            result.normalityScore -= 15.0;
            result.suspicious = true;
        }

        // 4. Rapid successive attempts
        if (securityContext.containsKey('previousAttempts')) {
            List<Object> attempts = (List<Object>)securityContext.get('previousAttempts');
            if (attempts.size() > 3) {
                result.concerns.add('Multiple rapid signing attempts: ' + attempts.size());
                result.normalityScore -= 25.0;
                result.suspicious = true;
            }
        }

        // 5. Time zone consistency
        if (securityContext.containsKey('browserTimezone')) {
            String browserTZ = (String)securityContext.get('browserTimezone');
            String locationTZ = (String)securityContext.get('locationTimezone');

            if (String.isNotBlank(browserTZ) && String.isNotBlank(locationTZ) && !browserTZ.equals(locationTZ)) {
                result.concerns.add('Timezone mismatch between browser and location');
                result.normalityScore -= 20.0;
                result.suspicious = true;
            }
        }
    } catch (Exception e) {
        result.concerns.add('Time validation error: ' + e.getMessage());
        result.normalityScore = 50.0;
        result.suspicious = true;
    }

    return result;
}
 /**
     * Validate multi-factor authentication
     */
    public static MFAValidationResult validateMFA(String signerEmail, Map<String, Object> securityContext) {
        MFAValidationResult result = new MFAValidationResult();
        result.authenticationPassed = false;
        result.authenticationStrength = 0;
        result.factorsVerified = new List<String>();
        result.missingFactors = new List<String>(); try { // 1. Email verification (basic factor) if (securityContext.containsKey('emailVerified') && (Boolean)securityContext.get('emailVerified')) { result.factorsVerified.add('Email'); result.authenticationStrength += 20; } else { result.missingFactors.add('Email verification'); } // 2. SMS verification if (securityContext.containsKey('smsVerified') && (Boolean)securityContext.get('smsVerified')) { result.factorsVerified.add('SMS'); result.authenticationStrength += 25; } else { result.missingFactors.add('SMS verification'); } // 3. Biometric authentication if (securityContext.containsKey('biometricVerified') && (Boolean)securityContext.get('biometricVerified')) { result.factorsVerified.add('Biometric'); result.authenticationStrength += 35; } else { result.missingFactors.add('Biometric authentication'); } // 4. Hardware token (if available) if (securityContext.containsKey('hardwareTokenVerified') && (Boolean)securityContext.get('hardwareTokenVerified')) { result.factorsVerified.add('Hardware Token'); result.authenticationStrength += 20; } // 5. Knowledge-based authentication if (securityContext.containsKey('kbaVerified') && (Boolean)securityContext.get('kbaVerified')) { result.factorsVerified.add('Knowledge-Based Questions'); result.authenticationStrength += 15; } result.authenticationPassed = result.authenticationStrength >= 45; // At least 2 factors // Create MFA record MFAValidation__c mfaRecord = new MFAValidation__c(); mfaRecord.SignerEmail__c = signerEmail; mfaRecord.AuthenticationStrength__c = result.authenticationStrength; mfaRecord.FactorsVerified__c = String.join(result.factorsVerified, ';'); mfaRecord.ValidationTimestamp__c = System.now(); mfaRecord.ValidationPassed__c = result.authenticationPassed; insert mfaRecord; } catch (Exception e) { result.missingFactors.add('MFA validation error: ' + e.getMessage()); result.authenticationStrength = 0;
        } return result;
    } /**
     * Generate security recommendations based on validation results
     */
    private static void generateSecurityRecommendations(SecurityValidationResult result) {
        if (result.deviceScore < 50.0) { result.recommendations.add('BLOCK_DEVICE - Device trust score too low for secure signing'); result.recommendations.add('REQUIRE_DEVICE_REGISTRATION - Register trusted devices for this user');
        } if (result.biometricScore < BIOMETRIC_CONFIDENCE_THRESHOLD) { result.recommendations.add('ENHANCE_BIOMETRIC - Require additional biometric verification'); result.recommendations.add('MANUAL_REVIEW - Human verification recommended');
        } if (result.behaviorScore < 60.0) { result.recommendations.add('BEHAVIORAL_CHALLENGE - Present additional verification challenges'); result.recommendations.add('SLOW_SIGNING - Enforce minimum signing duration');
        } if (result.locationScore < 40.0) { result.recommendations.add('LOCATION_BLOCK - Block signing from this location'); result.recommendations.add('VPN_DETECTION - Require signing without VPN/proxy');
        } if (result.mfaScore < 45) { result.recommendations.add('REQUIRE_MFA - Mandate multi-factor authentication'); result.recommendations.add('PROGRESSIVE_AUTH - Implement stepped authentication process');
        } if (result.overallRiskScore > 90.0) { result.recommendations.add('IMMEDIATE_BLOCK - Signature attempt should be blocked immediately'); result.recommendations.add('SECURITY_ALERT - Notify security team of potential attack');
        }
    } /**
     * Create security assessment record
     */
    private static void createSecurityAssessment(SecurityValidationResult result) {
        try {
            SecurityAssessment__c assessment = new SecurityAssessment__c();
            assessment.SignatureRequestId__c = result.requestId;
            assessment.ValidationTimestamp__c = result.validationTimestamp;
            assessment.OverallRiskScore__c = result.overallRiskScore;
            assessment.ValidationPassed__c = result.validationPassed;
            assessment.DeviceScore__c = result.deviceScore;
            assessment.BiometricScore__c = result.biometricScore;
            assessment.BehaviorScore__c = result.behaviorScore;
            assessment.LocationScore__c = result.locationScore;
            assessment.TimeScore__c = result.timeScore;
            assessment.MFAScore__c = result.mfaScore;
            assessment.SecurityIssues__c = String.join(result.securityIssues, '; ');
            assessment.Recommendations__c = String.join(result.recommendations, '; ');
            insert assessment;
        } catch (Exception e) {
            System.debug('Failed to create security assessment: ' + e.getMessage());
        }
    }
    
    /**
     * Helper method to analyze eye movement in facial landmarks
     */
    private static Boolean analyzeEyeMovement(List<Object> landmarkData) {
        try {
            if (landmarkData == null || landmarkData.isEmpty()) return false;
            
            // Simplified eye movement detection logic
            // In production, this would use advanced ML models
            Integer eyeMovementIndicators = 0;
            for (Object landmark : landmarkData) {
                Map<String, Object> point = (Map<String, Object>)landmark;
                String type = (String)point.get('type');
                if (type != null && (type.contains('EYE') || type.contains('PUPIL'))) {
                    Decimal variance = (Decimal)point.get('variance');
                    if (variance != null && variance > 2.0) {
                        // Some movement detected
                        eyeMovementIndicators++;
                    }
                }
            }
            return eyeMovementIndicators > 3; // At least 3 eye points showing movement
        } catch (Exception e) {
            return false;
        }
    }
    
    /**
     * Helper method to analyze micro-expressions
     */
    private static Boolean analyzeMicroExpressions(List<Object> landmarkData) {
        try {
            if (landmarkData == null || landmarkData.isEmpty()) return false;
            
            // Check for subtle facial muscle movements
            for (Object landmark : landmarkData) {
                Map<String, Object> point = (Map<String, Object>)landmark;
                String type = (String)point.get('type');
                if (type != null && (type.contains('MOUTH') || type.contains('CHEEK') || type.contains('EYEBROW'))) {
                    Decimal movement = (Decimal)point.get('movement');
                    if (movement != null && movement > 0.5) {
                        return true; // Micro-expression detected
                    }
                }
            }
            return false;
        } catch (Exception e) {
            return false;
        }
    }
    
    /**
     * Helper method to analyze texture consistency
     */
    private static Boolean analyzeTextureConsistency(String faceImageData) {
        try {
            if (String.isBlank(faceImageData)) return false;
            
            // Simplified texture analysis
            // In production, this would use computer vision APIs
            Blob imageBlob = EncodingUtil.base64Decode(faceImageData);
            Integer imageSize = imageBlob.size();
            
            // Basic heuristics for texture analysis
            if (imageSize < 10000) return false; // Too small, likely low quality
            
            // Check for repeating patterns (simplified)
            String imageString = EncodingUtil.base64Encode(imageBlob);
            Integer uniqueChars = new Set<String>(imageString.split('')).size();
            Decimal uniquenessRatio = (Decimal)uniqueChars / imageString.length();
            
            return uniquenessRatio > 0.4; // Natural images have higher uniqueness
        } catch (Exception e) {
            return false;
        }
    }
    
    /**
     * Helper method to detect virtual machines
     */
    private static Boolean isVirtualMachine(String userAgent) {
        if (String.isBlank(userAgent)) return false;
        
        List<String> vmIndicators = new List<String>{
            'VirtualBox', 'VMware', 'QEMU', 'Xen', 'Parallels', 'Hyper-V', 'VirtualPC'
        };
        
        String upperAgent = userAgent.toUpperCase();
        for (String indicator : vmIndicators) {
            if (upperAgent.contains(indicator.toUpperCase())) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * Helper method to detect suspicious user agents
     */
    private static Boolean isSuspiciousUserAgent(String userAgent) {
        if (String.isBlank(userAgent)) return true;
        
        List<String> suspiciousIndicators = new List<String>{
            'bot', 'crawler', 'spider', 'selenium', 'phantomjs', 'headless',
            'automated', 'python', 'curl', 'wget'
        };
        
        String lowerAgent = userAgent.toLowerCase();
        for (String indicator : suspiciousIndicators) {
            if (lowerAgent.contains(indicator)) {
                return true;
            }
        }
        
        // Check for too generic user agents
        if (userAgent.length() < 20 || userAgent.length() > 500) {
            return true;
        }
        return false;
    }
    
    /**
     * Helper method to detect unusual screen resolutions
     */
    private static Boolean isUnusualScreenResolution(String screenResolution) {
        if (String.isBlank(screenResolution)) return true;
        
        List<String> commonResolutions = new List<String>{
            '1920x1080', '1366x768', '1536x864', '1440x900', '1280x1024',
            '1280x800', '1024x768', '2560x1440', '3840x2160'
        };
        
        return !commonResolutions.contains(screenResolution);
    }
    
    /**
     * Helper method to analyze device history
     */
    private static DeviceHistoryAnalysis analyzeDeviceHistory(String deviceId) {
        DeviceHistoryAnalysis result = new DeviceHistoryAnalysis();
        result.suspiciousActivity = false;
        result.concerns = new List<String>();
        result.riskDeduction = 0.0;
        
        try {
            // Check for multiple accounts from same device
            List<AggregateResult> accountsFromDevice = [
            SELECT COUNT_DISTINCT(SignerEmail__c) uniqueSigners
            FROM Signature_Request__c
            WHERE DeviceFingerprint__c = :deviceId
            AND CreatedDate >= :System.now().addDays(-30)
        ];
            if (!accountsFromDevice.isEmpty()) {
                Integer uniqueSigners = (Integer)accountsFromDevice[0].get('uniqueSigners');
                if (uniqueSigners > 10) {
                    result.concerns.add('Device used by too many different signers: ' + uniqueSigners);
                    result.riskDeduction += 30.0;
                    result.suspiciousActivity = true;
                }
            }
            
            // Check for rapid signing from same device
            List<AggregateResult> rapidSigning = [
            SELECT COUNT(Id) signatureCount
            FROM Signature_Request__c
            WHERE DeviceFingerprint__c = :deviceId
            AND CreatedDate >= :System.now().addHours(-1)
        ];
            if (!rapidSigning.isEmpty()) {
                Integer signatureCount = (Integer)rapidSigning[0].get('signatureCount');
                if (signatureCount > 5) {
                    result.concerns.add('Too many signatures from device in 1 hour: ' + signatureCount);
                    result.riskDeduction += 25.0;
                    result.suspiciousActivity = true;
                }
            }
        } catch (Exception e) {
            result.concerns.add('Device history analysis error: ' + e.getMessage());
            result.riskDeduction = 10.0;
        }
        return result;
    }
    
    /**
     * Helper method to analyze location jumping
     */
    private static Boolean analyzeLocationJumping(String currentCountry, String currentCity, List<Object> historicalLocations) {
        try {
            if (historicalLocations == null || historicalLocations.isEmpty()) return false;
            
            for (Object histLoc : historicalLocations) {
                Map<String, Object> location = (Map<String, Object>)histLoc;
                String histCountry = (String)location.get('country');
                DateTime histTime = (DateTime)location.get('timestamp');
                
                if (String.isNotBlank(histCountry) && histTime != null) {
                    // Check if location changed too quickly
                    Long timeDiffMinutes = (System.now().getTime() - histTime.getTime()) / (1000 * 60);
                    if (timeDiffMinutes < 60 && !histCountry.equals(currentCountry)) {
                        return true; // Country changed in less than 1 hour
                    }
                }
            }
            return false;
        } catch (Exception e) {
            return false;
        }
    }
    
    /**
     * Helper method to check if date is holiday
     */
    private static Boolean isHoliday(Date checkDate) {
        try {
            List<Holiday> holidays = [
            SELECT Id 
            FROM Holiday 
            WHERE ActivityDate = :checkDate 
            LIMIT 1
        ];
            return !holidays.isEmpty();
        } catch (Exception e) {
            return false; // If Holiday object is not available
        }
    }
    
    // Supporting classes for security validation results
    public class SecurityValidationResult {
        @AuraEnabled public String requestId;
        @AuraEnabled public DateTime validationTimestamp;
        @AuraEnabled public Decimal overallRiskScore;
        @AuraEnabled public Boolean validationPassed;
        @AuraEnabled public Decimal deviceScore;
        @AuraEnabled public Decimal biometricScore;
        @AuraEnabled public Decimal behaviorScore;
        @AuraEnabled public Decimal locationScore;
        @AuraEnabled public Decimal timeScore;
        @AuraEnabled public Decimal mfaScore;
        @AuraEnabled public List<String> securityIssues;
        @AuraEnabled public List<String> recommendations;
    }
    
    public class DeviceValidationResult {
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public Decimal trustScore;
        @AuraEnabled public List<String> issues;
    }
    
    public class BiometricValidationResult {
        @AuraEnabled public String validationId;
        @AuraEnabled public Boolean livenessDetected;
        @AuraEnabled public Decimal confidenceScore;
        @AuraEnabled public Decimal spoofingRisk;
        @AuraEnabled public List<String> validationDetails;
    }
    
    public class UserBehaviorAnalysisResult {
        @AuraEnabled public Decimal normalityScore;
        @AuraEnabled public Boolean anomaliesDetected;
        @AuraEnabled public List<String> anomalies;
        @AuraEnabled public Decimal riskIncrement;
    }
    
    public class LocationValidationResult {
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public Decimal trustScore;
        @AuraEnabled public List<String> securityConcerns;
        @AuraEnabled public Decimal riskIncrement;
    }
    
    public class TimeValidationResult {
        @AuraEnabled public Decimal normalityScore;
        @AuraEnabled public Boolean suspicious;
        @AuraEnabled public List<String> concerns;
    }
    
    public class MFAValidationResult {
        @AuraEnabled public Boolean authenticationPassed;
        @AuraEnabled public Integer authenticationStrength;
        @AuraEnabled public List<String> factorsVerified;
        @AuraEnabled public List<String> missingFactors;
    }
    
    public class DeviceHistoryAnalysis {
        public Boolean suspiciousActivity;
        public List<String> concerns;
        public Decimal riskDeduction;
    }
    
}
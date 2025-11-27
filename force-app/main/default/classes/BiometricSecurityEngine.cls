public class BiometricSecurityEngine {
    
    private static final Map<String, Integer> CONFIDENCE_THRESHOLDS = new Map<String, Integer>{
        'FACIAL_RECOGNITION' => 85,
        'FINGERPRINT' => 90,
        'VOICE_RECOGNITION' => 80,
        'BEHAVIORAL_BIOMETRICS' => 75,
        'IRIS_SCAN' => 95,
        'PALM_VEIN' => 92
    };
    
    private static final Map<String, Decimal> FRAUD_RISK_WEIGHTS = new Map<String, Decimal>{
        'DEVICE_FINGERPRINTING' => 0.2,
        'GEOLOCATION_ANALYSIS' => 0.15,
        'BEHAVIORAL_PATTERNS' => 0.25,
        'BIOMETRIC_CONSISTENCY' => 0.3,
        'TIME_PATTERN_ANALYSIS' => 0.1
    };
    
    @AuraEnabled(cacheable=false)
    public static BiometricValidationResult validateBiometricSignature(
        String signatureRequestId, 
        String biometricData, 
        String biometricType,
        String deviceFingerprint
    ) {
        try {
            BiometricValidationResult result = new BiometricValidationResult();
            result.signatureRequestId = signatureRequestId;
            result.validationTimestamp = System.now();
            result.biometricType = biometricType;
            
            // Perform liveness detection
            LivenessDetectionResult livenessResult = performLivenessDetection(biometricData, biometricType);
            result.livenessDetection = livenessResult;
            
            // Perform biometric matching
            BiometricMatchResult matchResult = performBiometricMatching(signatureRequestId, biometricData, biometricType);
            result.biometricMatch = matchResult;
            
            // Perform fraud detection analysis
            FraudAnalysisResult fraudResult = performFraudAnalysis(signatureRequestId, deviceFingerprint, biometricType);
            result.fraudAnalysis = fraudResult;
            
            // Calculate overall confidence score
            result.overallConfidenceScore = calculateOverallConfidence(livenessResult, matchResult, fraudResult);
            result.validationPassed = result.overallConfidenceScore >= CONFIDENCE_THRESHOLDS.get(biometricType);
            
            // Store biometric validation results
            storeBiometricValidation(result);
            
            // Log security event
            logBiometricValidation(result);
            
            return result;
            
        } catch (Exception e) {
            System.debug('Biometric validation error: ' + e.getMessage());
            return getFailedBiometricResult(signatureRequestId, e.getMessage());
        }
    }
    
    private static LivenessDetectionResult performLivenessDetection(String biometricData, String biometricType) {
        LivenessDetectionResult result = new LivenessDetectionResult();
        
        switch on biometricType {
            when 'FACIAL_RECOGNITION' {
                result = performFacialLivenessDetection(biometricData);
            }
            when 'FINGERPRINT' {
                result = performFingerprintLivenessDetection(biometricData);
            }
            when 'VOICE_RECOGNITION' {
                result = performVoiceLivenessDetection(biometricData);
            }
            when 'IRIS_SCAN' {
                result = performIrisLivenessDetection(biometricData);
            }
            when else {
                result.isLive = false;
                result.confidenceScore = 0;
                result.detectionMethod = 'UNSUPPORTED';
            }
        }
        
        return result;
    }
    
    private static LivenessDetectionResult performFacialLivenessDetection(String facialData) {
        LivenessDetectionResult result = new LivenessDetectionResult();
        
        // Simulated facial liveness detection algorithm
        try {
            // Parse facial biometric data (base64 encoded image data)
            Blob imageBlob = EncodingUtil.base64Decode(facialData);
            
            // Perform anti-spoofing checks
            Map<String, Object> analysisResults = performFacialAntiSpoofing(imageBlob);
            
            // Eye movement detection
            Boolean eyeMovementDetected = (Boolean) analysisResults.get('eyeMovement');
            
            // Depth analysis
            Boolean depthConsistent = (Boolean) analysisResults.get('depthConsistent');
            
            // Texture analysis
            Boolean textureNatural = (Boolean) analysisResults.get('textureNatural');
            
            // Calculate liveness score
            Integer livenessScore = 0;
            if (eyeMovementDetected) livenessScore += 30;
            if (depthConsistent) livenessScore += 35;
            if (textureNatural) livenessScore += 35;
            
            result.confidenceScore = livenessScore;
            result.isLive = livenessScore >= 85;
            result.detectionMethod = 'MULTI_FACTOR_FACIAL_ANALYSIS';
            result.analysisDetails = analysisResults;
            
        } catch (Exception e) {
            result.isLive = false;
            result.confidenceScore = 0;
            result.detectionMethod = 'ERROR';
            result.errorMessage = e.getMessage();
        }
        
        return result;
    }
    
    private static LivenessDetectionResult performFingerprintLivenessDetection(String fingerprintData) {
        LivenessDetectionResult result = new LivenessDetectionResult();
        
        try {
            // Decode fingerprint data
            Map<String, Object> fingerprintMap = (Map<String, Object>) JSON.deserializeUntyped(fingerprintData);
            
            // Perform capacitive sensor analysis
            Boolean capacitiveConsistent = analyzeFingerprintCapacitance(fingerprintMap);
            
            // Pulse detection
            Boolean pulseDetected = detectFingerprintPulse(fingerprintMap);
            
            // Temperature analysis
            Boolean temperatureNormal = analyzeFingerprintTemperature(fingerprintMap);
            
            // Ridge flow analysis
            Boolean ridgeFlowNatural = analyzeRidgeFlow(fingerprintMap);
            
            // Calculate liveness score
            Integer livenessScore = 0;
            if (capacitiveConsistent) livenessScore += 25;
            if (pulseDetected) livenessScore += 30;
            if (temperatureNormal) livenessScore += 20;
            if (ridgeFlowNatural) livenessScore += 25;
            
            result.confidenceScore = livenessScore;
            result.isLive = livenessScore >= 90;
            result.detectionMethod = 'MULTI_SENSOR_FINGERPRINT_ANALYSIS';
            
        } catch (Exception e) {
            result.isLive = false;
            result.confidenceScore = 0;
            result.detectionMethod = 'ERROR';
            result.errorMessage = e.getMessage();
        }
        
        return result;
    }
    
    private static LivenessDetectionResult performVoiceLivenessDetection(String voiceData) {
        LivenessDetectionResult result = new LivenessDetectionResult();
        
        try {
            // Voice analysis for liveness
            Map<String, Object> voiceAnalysis = analyzeVoiceCharacteristics(voiceData);
            
            // Natural speech patterns
            Boolean naturalSpeech = (Boolean) voiceAnalysis.get('naturalSpeech');
            
            // Voice box resonance
            Boolean resonanceNatural = (Boolean) voiceAnalysis.get('resonanceNatural');
            
            // Breathing pattern detection
            Boolean breathingDetected = (Boolean) voiceAnalysis.get('breathingDetected');
            
            // Background noise analysis
            Boolean noisePatternNormal = (Boolean) voiceAnalysis.get('noisePatternNormal');
            
            // Calculate liveness score
            Integer livenessScore = 0;
            if (naturalSpeech) livenessScore += 35;
            if (resonanceNatural) livenessScore += 30;
            if (breathingDetected) livenessScore += 25;
            if (noisePatternNormal) livenessScore += 10;
            
            result.confidenceScore = livenessScore;
            result.isLive = livenessScore >= 80;
            result.detectionMethod = 'VOICE_PATTERN_ANALYSIS';
            
        } catch (Exception e) {
            result.isLive = false;
            result.confidenceScore = 0;
            result.detectionMethod = 'ERROR';
            result.errorMessage = e.getMessage();
        }
        
        return result;
    }
    
    private static LivenessDetectionResult performIrisLivenessDetection(String irisData) {
        LivenessDetectionResult result = new LivenessDetectionResult();
        
        try {
            // Iris-specific liveness checks
            Map<String, Object> irisAnalysis = analyzeIrisCharacteristics(irisData);
            
            // Pupil response to light
            Boolean pupilResponse = (Boolean) irisAnalysis.get('pupilResponse');
            
            // Iris texture analysis
            Boolean textureConsistent = (Boolean) irisAnalysis.get('textureConsistent');
            
            // Eye movement detection
            Boolean eyeMovement = (Boolean) irisAnalysis.get('eyeMovement');
            
            // Reflectance analysis
            Boolean reflectanceNormal = (Boolean) irisAnalysis.get('reflectanceNormal');
            
            // Calculate liveness score
            Integer livenessScore = 0;
            if (pupilResponse) livenessScore += 40;
            if (textureConsistent) livenessScore += 30;
            if (eyeMovement) livenessScore += 15;
            if (reflectanceNormal) livenessScore += 15;
            
            result.confidenceScore = livenessScore;
            result.isLive = livenessScore >= 95;
            result.detectionMethod = 'IRIS_MULTI_FACTOR_ANALYSIS';
            
        } catch (Exception e) {
            result.isLive = false;
            result.confidenceScore = 0;
            result.detectionMethod = 'ERROR';
            result.errorMessage = e.getMessage();
        }
        
        return result;
    }
    
    private static BiometricMatchResult performBiometricMatching(String signatureRequestId, String biometricData, String biometricType) {
        BiometricMatchResult result = new BiometricMatchResult();
        
        try {
            // Get stored biometric template for user
            Signature_Request__c sigRequest = [
                SELECT Id, SignerEmail__c, UserId__c
                FROM Signature_Request__c 
                WHERE Id = :signatureRequestId 
                LIMIT 1
            ];
            
            // Retrieve stored biometric template
            List<Biometric_Template__c> templates = [
                SELECT Id, Template_Data__c, Biometric_Type__c, Confidence_Score__c
                FROM Biometric_Template__c
                WHERE User_Email__c = :sigRequest.SignerEmail__c
                AND Biometric_Type__c = :biometricType
                AND Status__c = 'ACTIVE'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            
            if (templates.isEmpty()) {
                // First-time enrollment
                result = performBiometricEnrollment(sigRequest.SignerEmail__c, biometricData, biometricType);
            } else {
                // Match against existing template
                result = performBiometricComparison(templates[0].Template_Data__c, biometricData, biometricType);
            }
            
        } catch (Exception e) {
            result.matchFound = false;
            result.confidenceScore = 0;
            result.errorMessage = e.getMessage();
        }
        
        return result;
    }
    
    private static BiometricMatchResult performBiometricEnrollment(String userEmail, String biometricData, String biometricType) {
        BiometricMatchResult result = new BiometricMatchResult();
        
        try {
            // Create biometric template
            String templateData = generateBiometricTemplate(biometricData, biometricType);
            
            // Store template
            Biometric_Template__c template = new Biometric_Template__c(
                User_Email__c = userEmail,
                Biometric_Type__c = biometricType,
                Template_Data__c = templateData,
                Enrollment_Date__c = System.now(),
                Status__c = 'ACTIVE',
                Confidence_Score__c = 100
            );
            insert template;
            
            result.matchFound = true;
            result.confidenceScore = 100;
            result.matchType = 'ENROLLMENT';
            result.templateId = template.Id;
            
        } catch (Exception e) {
    result.matchFound = false;
    result.confidenceScore = 0;
    result.matchType = 'ENROLLMENT_FAILED';
    result.errorMessage = e.getMessage();
}
return result;
}
// Helper: Check if location is high risk (dummy implementation)
private static Boolean isHighRiskCountry(String geoLocation) {
    // Simulate high-risk country check
    if (geoLocation != null && geoLocation.contains('NIGERIA')) return true;
    return false;
}
private static BiometricMatchResult performBiometricComparison(String storedTemplate, String currentBiometric, String biometricType) {
    BiometricMatchResult result = new BiometricMatchResult();
    try {
        // Perform biometric comparison based on type
        Decimal matchScore = 0;
        switch on biometricType {
            when 'FACIAL_RECOGNITION' {
                matchScore = compareFacialBiometrics(storedTemplate, currentBiometric);
            }
            when 'FINGERPRINT' {
                matchScore = compareFingerprintBiometrics(storedTemplate, currentBiometric);
            }
            when 'VOICE_RECOGNITION' {
                matchScore = compareVoiceBiometrics(storedTemplate, currentBiometric);
            }
            when 'IRIS_SCAN' {
                matchScore = compareIrisBiometrics(storedTemplate, currentBiometric);
            }
            when else {
                matchScore = 0;
            }
        }
        
        result.confidenceScore = matchScore;
        result.matchFound = matchScore >= CONFIDENCE_THRESHOLDS.get(biometricType);
        result.matchType = 'VERIFICATION';
        
    } catch (Exception e) {
        result.matchFound = false;
        result.confidenceScore = 0;
        result.errorMessage = e.getMessage();
    }
    return result;
}

private static FraudAnalysisResult performFraudAnalysis(String signatureRequestId, String deviceFingerprint, String biometricType) {
    FraudAnalysisResult result = new FraudAnalysisResult();
    try {
        result.riskScore = 0;
        result.riskFactors = new List<RiskFactor>();
        
        // Device fingerprinting analysis
        RiskFactor deviceRisk = analyzeDeviceFingerprint(signatureRequestId, deviceFingerprint);
        result.riskFactors.add(deviceRisk);
        result.riskScore += deviceRisk.riskWeight * deviceRisk.riskLevel;
        
        // Geolocation analysis
        RiskFactor geoRisk = analyzeGeolocationRisk(signatureRequestId);
        result.riskFactors.add(geoRisk);
        result.riskScore += geoRisk.riskWeight * geoRisk.riskLevel;
        
        // Behavioral pattern analysis
        RiskFactor behaviorRisk = analyzeBehavioralPatterns(signatureRequestId, biometricType);
        result.riskFactors.add(behaviorRisk);
        result.riskScore += behaviorRisk.riskWeight * behaviorRisk.riskLevel;
        
        // Time pattern analysis
        RiskFactor timeRisk = analyzeTimePatterns(signatureRequestId);
        result.riskFactors.add(timeRisk);
        result.riskScore += timeRisk.riskWeight * timeRisk.riskLevel;
        
        // Calculate overall fraud risk level
        if (result.riskScore < 30) {
            result.riskLevel = 'LOW';
        } else if (result.riskScore < 70) {
            result.riskLevel = 'MEDIUM';
        } else {
            result.riskLevel = 'HIGH';
        }
        
        result.fraudDetected = result.riskScore > 70;
        
    } catch (Exception e) {
        result.fraudDetected = true;
        result.riskLevel = 'ERROR';
        result.riskScore = 100;
        result.errorMessage = e.getMessage();
    }
    return result;
}
// Helper: Analyze device characteristics
private static Map<String, Object> analyzeDeviceCharacteristics(String deviceFingerprint) {
    Map<String, Object> result = new Map<String, Object>();
    // Simulate device analysis
    result.put('suspiciousDevice', deviceFingerprint != null && deviceFingerprint.startsWith('SUSPICIOUS'));
    return result;
}

// Helper: Calculate location distance (dummy implementation)
private static Decimal calculateLocationDistance(String geo1, String geo2) {
    // Simulate location distance calculation (returns km)
    // In real implementation, parse lat/lng from geo1/geo2 and use Haversine
    if (geo1 == geo2) return 0;
    return 100;
}

// Helper: Analyze device fingerprint
private static RiskFactor analyzeDeviceFingerprint(String signatureRequestId, String deviceFingerprint) {
    RiskFactor riskFactor = new RiskFactor();
    riskFactor.factorType = 'DEVICE_FINGERPRINTING';
    riskFactor.riskWeight = FRAUD_RISK_WEIGHTS.get('DEVICE_FINGERPRINTING');
    try {
        // Check if device has been used before for this user
        Signature_Request__c request = [
            SELECT SignerEmail__c FROM Signature_Request__c 
            WHERE Id = :signatureRequestId LIMIT 1
        ];
       
   
       
        Map<String, Object> deviceAnalysis = analyzeDeviceCharacteristics(deviceFingerprint);
        Boolean suspiciousDevice = (Boolean) deviceAnalysis.get('suspiciousDevice');
        if (suspiciousDevice) {
            riskFactor.riskLevel += 30;
            riskFactor.description += '; Device shows suspicious characteristics';
        }
    } catch (Exception e) {
        riskFactor.riskLevel = 80;
        riskFactor.description = 'Device analysis failed: ' + e.getMessage();
    }
    return riskFactor;
}


private static RiskFactor analyzeGeolocationRisk(String signatureRequestId) {
    RiskFactor riskFactor = new RiskFactor();
    riskFactor.factorType = 'GEOLOCATION_ANALYSIS';
    riskFactor.riskWeight = FRAUD_RISK_WEIGHTS.get('GEOLOCATION_ANALYSIS');
    
    try {
        // Get current request geolocation
        Signature_Request__c request = [
            SELECT SignerEmail__c, IP_Address__c, Geolocation__c 
            FROM Signature_Request__c 
            WHERE Id = :signatureRequestId LIMIT 1
        ];
        
        // Check historical locations for this user
        List<AggregateResult> historicalLocations = [
            SELECT Geolocation__c, COUNT(Id) locationCount
            FROM Biometric_Validation__c 
            WHERE Signer_Email__c = :request.SignerEmail__c
            AND CreatedDate = LAST_N_DAYS:180
            AND Geolocation__c != null
            GROUP BY Geolocation__c
            ORDER BY COUNT(Id) DESC
            LIMIT 10
        ];
        
        Boolean knownLocation = false;
        for (AggregateResult location : historicalLocations) {
            String historicalGeo = (String) location.get('Geolocation__c');
            if (calculateLocationDistance(request.Geolocation__c, historicalGeo) < 50) { // Within 50km
                knownLocation = true;
                break;
            }
        }
        
        if (knownLocation) {
            riskFactor.riskLevel = 5;
            riskFactor.description = 'Signing from known geographic location';
        } else {
            riskFactor.riskLevel = 40;
            riskFactor.description = 'Signing from new geographic location';
            
            // Check if location is from high-risk country
            if (isHighRiskCountry(request.Geolocation__c)) {
                riskFactor.riskLevel += 30;
                riskFactor.description += '; Location flagged as high-risk region';
            }
        }
        
    } catch (Exception e) {
        riskFactor.riskLevel = 60;
        riskFactor.description = 'Geolocation analysis failed: ' + e.getMessage();
    }
    
    return riskFactor;
}

private static RiskFactor analyzeBehavioralPatterns(String signatureRequestId, String biometricType) {
    RiskFactor riskFactor = new RiskFactor();
    riskFactor.factorType = 'BEHAVIORAL_PATTERNS';
    riskFactor.riskWeight = FRAUD_RISK_WEIGHTS.get('BEHAVIORAL_PATTERNS');
    
    try {
        Signature_Request__c request = [
            SELECT SignerEmail__c, CreatedDate FROM Signature_Request__c 
            WHERE Id = :signatureRequestId LIMIT 1
        ];
        
        // Analyze signing behavior patterns
        List<AggregateResult> behaviorStats = [
            SELECT 
                AVG(Time_To_Sign_Minutes__c) avgTimeToSign,
                AVG(Biometric_Attempts__c) avgAttempts,
                COUNT(Id) totalSigning
            FROM Biometric_Validation__c 
            WHERE Signer_Email__c = :request.SignerEmail__c
            AND Biometric_Type__c = :biometricType
            AND CreatedDate = LAST_N_DAYS:90
        ];
        
        if (!behaviorStats.isEmpty() && behaviorStats[0].get('totalSigning') != null) {
            Integer totalSignings = (Integer) behaviorStats[0].get('totalSigning');
            Decimal avgTimeToSign = (Decimal) behaviorStats[0].get('avgTimeToSign');
            Decimal avgAttempts = (Decimal) behaviorStats[0].get('avgAttempts');
            
            if (totalSignings >= 5) { // Sufficient history for analysis
                riskFactor.riskLevel = 15; // Base risk for known user
                riskFactor.description = 'User has established behavioral pattern';
                
                // Check for unusual patterns (would need current session data)
                // This is simplified - in reality you'd compare current session metrics
                
            } else {
                riskFactor.riskLevel = 35;
                riskFactor.description = 'Limited behavioral history for user';
            }
        } else {
            riskFactor.riskLevel = 45;
            riskFactor.description = 'New user with no behavioral history';
        }
        
    } catch (Exception e) {
        riskFactor.riskLevel = 70;
        riskFactor.description = 'Behavioral analysis failed: ' + e.getMessage();
    }
    
    return riskFactor;
}

private static RiskFactor analyzeTimePatterns(String signatureRequestId) {
    RiskFactor riskFactor = new RiskFactor();
    riskFactor.factorType = 'TIME_PATTERN_ANALYSIS';
    riskFactor.riskWeight = FRAUD_RISK_WEIGHTS.get('TIME_PATTERN_ANALYSIS');
    
    try {
        Signature_Request__c request = [
            SELECT SignerEmail__c, CreatedDate FROM Signature_Request__c 
            WHERE Id = :signatureRequestId LIMIT 1
        ];
        
        Time currentTime = request.CreatedDate.time();
        Integer currentHour = currentTime.hour();
        
        // Check typical signing hours for this user
        List<AggregateResult> timeStats = [
            SELECT HOUR_IN_DAY(CreatedDate) signingHour, COUNT(Id) signCount
            FROM Biometric_Validation__c 
            WHERE Signer_Email__c = :request.SignerEmail__c
            AND CreatedDate = LAST_N_DAYS:90
            GROUP BY HOUR_IN_DAY(CreatedDate)
            ORDER BY COUNT(Id) DESC
        ];
        
        Boolean typicalTime = false;
        for (AggregateResult timeStat : timeStats) {
            Integer historicalHour = (Integer) timeStat.get('signingHour');
            if (Math.abs(currentHour - historicalHour) <= 2) { // Within 2 hours of typical time
                typicalTime = true;
                break;
            }
        }
        
        if (typicalTime) {
            riskFactor.riskLevel = 5;
            riskFactor.description = 'Signing at typical time for user';
        } else if (currentHour >= 22 || currentHour <= 5) { // Night hours
            riskFactor.riskLevel = 25;
            riskFactor.description = 'Signing during unusual night hours';
        } else {
            riskFactor.riskLevel = 15;
            riskFactor.description = 'Signing at atypical time for user';
        }
        
    } catch (Exception e) {
        riskFactor.riskLevel = 30;
        riskFactor.description = 'Time pattern analysis failed: ' + e.getMessage();
    }
    
    return riskFactor;
}

private static Decimal calculateOverallConfidence(
    LivenessDetectionResult livenessResult, 
    BiometricMatchResult matchResult, 
    FraudAnalysisResult fraudResult
) {
    // Weighted confidence calculation
    Decimal livenessWeight = 0.4;
    Decimal matchWeight = 0.4;
    Decimal fraudWeight = 0.2;
    
    Decimal livenessConfidence = livenessResult.isLive ? livenessResult.confidenceScore : 0;
    Decimal matchConfidence = matchResult.matchFound ? matchResult.confidenceScore : 0;
    Decimal fraudConfidence = 100 - fraudResult.riskScore; // Invert fraud score
    
    Decimal overallConfidence = 
        (livenessConfidence * livenessWeight) + 
        (matchConfidence * matchWeight) + 
        (fraudConfidence * fraudWeight);
    
    return Math.max(0, Math.min(100, overallConfidence));
}

private static void storeBiometricValidation(BiometricValidationResult result) {
    try {
        Biometric_Validation__c validation = new Biometric_Validation__c(
            Signature_Request_Id__c = result.signatureRequestId,
            Biometric_Type__c = result.biometricType,
            Validation_Timestamp__c = result.validationTimestamp,
            Overall_Confidence_Score__c = result.overallConfidenceScore,
            Validation_Passed__c = result.validationPassed,
            Liveness_Score__c = result.livenessDetection.confidenceScore,
            Match_Score__c = result.biometricMatch.confidenceScore,
            Fraud_Risk_Score__c = result.fraudAnalysis.riskScore,
            Fraud_Risk_Level__c = result.fraudAnalysis.riskLevel,
            Validation_Data__c = JSON.serialize(result)
        );
        
        insert validation;
    } catch (Exception e) {
        System.debug('Failed to store biometric validation: ' + e.getMessage());
    }
}

private static void logBiometricValidation(BiometricValidationResult result) {
    try {
        Security_Event__c securityEvent = new Security_Event__c(
            Event_Type__c = 'BIOMETRIC_VALIDATION',
            Event_Timestamp__c = result.validationTimestamp,
            Related_Record_Id__c = result.signatureRequestId,
            Severity__c = result.validationPassed ? 'INFO' : 'HIGH',
            Description__c = 'Biometric validation ' + (result.validationPassed ? 'passed' : 'failed') + 
                           ' for ' + result.biometricType + ' with confidence ' + result.overallConfidenceScore + '%',
            Event_Details__c = JSON.serialize(result)
        );
        
insert securityEvent;
} catch (Exception e) {
System.debug('Failed to log biometric security event: ' + e.getMessage());
// Create fallback security alert for critical logging failures
createFallbackSecurityAlert('BIOMETRIC_LOGGING_FAILURE', result.signatureRequestId, e.getMessage());
}
}

private static BiometricValidationResult getFailedBiometricResult(String signatureRequestId, String errorMessage) {
    BiometricValidationResult result = new BiometricValidationResult();
    result.signatureRequestId = signatureRequestId;
    result.validationTimestamp = System.now();
    result.validationPassed = false;
    result.overallConfidenceScore = 0;
    result.errorMessage = errorMessage;
    return result;
}

// Helper methods for biometric analysis
private static Map<String, Object> performFacialAntiSpoofing(Blob imageData) {
    Map<String, Object> results = new Map<String, Object>();
    try {
        // Simulated anti-spoofing analysis
        results.put('eyeMovement', Math.random() > 0.2);
        results.put('depthConsistent', Math.random() > 0.15);
        results.put('textureNatural', Math.random() > 0.1);
        results.put('reflectionPattern', Math.random() > 0.25);
    } catch (Exception e) {
        System.debug('Facial anti-spoofing analysis error: ' + e.getMessage());
        results.put('eyeMovement', false);
        results.put('depthConsistent', false);
        results.put('textureNatural', false);
    }
    return results;
}

private static Boolean analyzeFingerprintCapacitance(Map<String, Object> fingerprintData) {
    try {
        // Analyze capacitive sensor readings for liveness
        Double capacitanceValue = (Double) fingerprintData.get('capacitance');
        return capacitanceValue != null && capacitanceValue > 0.5 && capacitanceValue < 2.0;
    } catch (Exception e) {
        System.debug('Fingerprint capacitance analysis error: ' + e.getMessage());
        return false;
    }
}

private static Boolean detectFingerprintPulse(Map<String, Object> fingerprintData) {
    try {
        // Detect pulse through fingerprint sensor
        List<Object> pulseReadings = (List<Object>) fingerprintData.get('pulseData');
        return pulseReadings != null && pulseReadings.size() > 10;
    } catch (Exception e) {
        System.debug('Fingerprint pulse detection error: ' + e.getMessage());
        return false;
    }
}

private static Boolean analyzeFingerprintTemperature(Map<String, Object> fingerprintData) {
    try {
        // Analyze temperature readings for living tissue
        Double temperature = (Double) fingerprintData.get('temperature');
        return temperature != null && temperature >= 36.0 && temperature <= 37.5;
    } catch (Exception e) {
        System.debug('Fingerprint temperature analysis error: ' + e.getMessage());
        return false;
    }
}

private static Boolean analyzeRidgeFlow(Map<String, Object> fingerprintData) {
    try {
        // Analyze natural ridge flow patterns
        String ridgePattern = (String) fingerprintData.get('ridgePattern');
        return ridgePattern != null && ridgePattern.contains('NATURAL_FLOW');
    } catch (Exception e) {
        System.debug('Ridge flow analysis error: ' + e.getMessage());
        return false;
    }
}

private static Map<String, Object> analyzeVoiceCharacteristics(String voiceData) {
    Map<String, Object> results = new Map<String, Object>();
    try {
        // Voice liveness analysis
        results.put('naturalSpeech', Math.random() > 0.1);
        results.put('resonanceNatural', Math.random() > 0.15);
        results.put('breathingDetected', Math.random() > 0.2);
        results.put('noisePatternNormal', Math.random() > 0.25);
    } catch (Exception e) {
        System.debug('Voice characteristics analysis error: ' + e.getMessage());
        results.put('naturalSpeech', false);
        results.put('resonanceNatural', false);
        results.put('breathingDetected', false);
        results.put('noisePatternNormal', false);
    }
    return results;
}

private static Map<String, Object> analyzeIrisCharacteristics(String irisData) {
    Map<String, Object> results = new Map<String, Object>();
    try {
        // Iris liveness analysis
        results.put('pupilResponse', Math.random() > 0.05);
        results.put('textureConsistent', Math.random() > 0.1);
        results.put('eyeMovement', Math.random() > 0.2);
        results.put('reflectanceNormal', Math.random() > 0.15);
    } catch (Exception e) {
        System.debug('Iris characteristics analysis error: ' + e.getMessage());
        results.put('pupilResponse', false);
        results.put('textureConsistent', false);
        results.put('eyeMovement', false);
        results.put('reflectanceNormal', false);
    }
    return results;
}

private static String generateBiometricTemplate(String biometricData, String biometricType) {
    try {
        // Generate secure biometric template
        String templateData = '';
        switch on biometricType {
            when 'FACIAL_RECOGNITION' {
                templateData = generateFacialTemplate(biometricData);
            }
            when 'FINGERPRINT' {
                templateData = generateFingerprintTemplate(biometricData);
            }
            when 'VOICE_RECOGNITION' {
                templateData = generateVoiceTemplate(biometricData);
            }
            when 'IRIS_SCAN' {
                templateData = generateIrisTemplate(biometricData);
            }
            when else {
                throw new BiometricException('Unsupported biometric type: ' + biometricType);
            }
        }
        
        // Encrypt template data for storage
        return encryptBiometricTemplate(templateData);
    } catch (Exception e) {
        System.debug('Biometric template generation error: ' + e.getMessage());
        throw new BiometricException('Failed to generate biometric template: ' + e.getMessage());
    }
}

// Helper: Generate facial template
private static String generateFacialTemplate(String biometricData) {
    // Simulate facial template generation
    return 'FACIAL_TEMPLATE_' + biometricData;
}

// Helper: Generate fingerprint template
private static String generateFingerprintTemplate(String biometricData) {
    // Simulate fingerprint template generation
    return 'FINGERPRINT_TEMPLATE_' + biometricData;
}

// Helper: Generate voice template
private static String generateVoiceTemplate(String biometricData) {
    // Simulate voice template generation
    return 'VOICE_TEMPLATE_' + biometricData;
}

// Helper: Generate iris template
private static String generateIrisTemplate(String biometricData) {
    // Simulate iris template generation
    return 'IRIS_TEMPLATE_' + biometricData;
}

// Helper: Encrypt biometric template
private static String encryptBiometricTemplate(String templateData) {
    // Simulate encryption
    return 'ENCRYPTED_' + templateData;
}

// Helper: Decrypt biometric template
private static String decryptBiometricTemplate(String encryptedData) {
    // Simulate decryption
    if (encryptedData.startsWith('ENCRYPTED_')) {
        return encryptedData.substring(10);
    }
    return encryptedData;
}

// Helper: Calculate facial similarity
private static Decimal calculateFacialSimilarity(String template1, String template2) {
    // Simulate similarity calculation
    return template1 == template2 ? 100 : 75;
}

// Helper: Calculate fingerprint match
private static Decimal calculateFingerprintMatch(String template1, String template2) {
    // Simulate fingerprint match calculation
    return template1 == template2 ? 100 : 70;
}

// Helper: Calculate voice match
private static Decimal calculateVoiceMatch(String template1, String template2) {
    // Simulate voice match calculation
    return template1 == template2 ? 100 : 65;
}

// Helper: Calculate iris match
private static Decimal calculateIrisMatch(String template1, String template2) {
    // Simulate iris match calculation
    return template1 == template2 ? 100 : 80;
}

// Helper: Calculate Haversine distance
private static Decimal calculateHaversineDistance(Decimal lat1, Decimal lng1, Decimal lat2, Decimal lng2) {
    // Simulate Haversine formula (returns km)
    Double R = 6371.0;
    Double dLat = radians((lat2 - lat1).doubleValue());
    Double dLng = radians((lng2 - lng1).doubleValue());
    Double a = Math.sin(dLat/2) * Math.sin(dLat/2) +
               Math.cos(radians(lat1.doubleValue())) * Math.cos(radians(lat2.doubleValue())) *
               Math.sin(dLng/2) * Math.sin(dLng/2);
    Double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    Double distance = R * c;
    return Decimal.valueOf(distance);
}
    // Helper: Convert degrees to radians
    private static Double radians(Double degrees) {
        return degrees * Math.PI / 180.0;
    }
// ...existing code...
private static void createFallbackSecurityAlert(String alertType, String recordId, String errorMessage) {
    try {
        Platform_Event__e fallbackEvent = new Platform_Event__e(
            Event_Type__c = alertType,
            Record_Id__c = recordId,
            Error_Message__c = errorMessage,
            Timestamp__c = System.now()
        );
        
        // Replace with correct EventBus.publish signature
        // EventBus.publish returns a Database.SaveResult[]
        Database.SaveResult[] results = EventBus.publish(new List<Platform_Event__e>{fallbackEvent});
        System.debug('✓ Fallback security alert published');
    } catch (Exception e) {
        System.debug('Failed to create fallback security alert: ' + e.getMessage());
        // Last resort: write to system log
        System.debug('CRITICAL: ' + alertType + ' for record ' + recordId + ': ' + errorMessage);
    }
}

// Biometric result classes
public class BiometricValidationResult {
    @AuraEnabled public String signatureRequestId;
    @AuraEnabled public DateTime validationTimestamp;
    @AuraEnabled public String biometricType;
    @AuraEnabled public Boolean validationPassed;
    @AuraEnabled public Decimal overallConfidenceScore;
    @AuraEnabled public LivenessDetectionResult livenessDetection;
    @AuraEnabled public BiometricMatchResult biometricMatch;
    @AuraEnabled public FraudAnalysisResult fraudAnalysis;
    @AuraEnabled public String errorMessage;
}

public class LivenessDetectionResult {
    @AuraEnabled public Boolean isLive;
    @AuraEnabled public Decimal confidenceScore;
    @AuraEnabled public String detectionMethod;
    @AuraEnabled public Map<String, Object> analysisDetails;
    @AuraEnabled public String errorMessage;
}

public class BiometricMatchResult {
    @AuraEnabled public Boolean matchFound;
    @AuraEnabled public Decimal confidenceScore;
    @AuraEnabled public String matchType;
    @AuraEnabled public String templateId;
    @AuraEnabled public String errorMessage;
}

public class FraudAnalysisResult {
    @AuraEnabled public Boolean fraudDetected;
    @AuraEnabled public String riskLevel;
    @AuraEnabled public Decimal riskScore;
    @AuraEnabled public List<RiskFactor> riskFactors;
    @AuraEnabled public String errorMessage;
}

public class RiskFactor {
    @AuraEnabled public String factorType;
    @AuraEnabled public Decimal riskLevel;
    @AuraEnabled public Decimal riskWeight;
    @AuraEnabled public String description;
}

// Custom exceptions
public class BiometricException extends Exception {}
public class SecurityException extends Exception {}

// Helper: Compare facial biometrics
private static Decimal compareFacialBiometrics(String storedTemplate, String currentBiometric) {
    // Simulate facial biometric comparison
    return storedTemplate == currentBiometric ? 100 : 75;
}

// Helper: Compare fingerprint biometrics
private static Decimal compareFingerprintBiometrics(String storedTemplate, String currentBiometric) {
    // Simulate fingerprint biometric comparison
    return storedTemplate == currentBiometric ? 100 : 70;
}

// Helper: Compare voice biometrics
private static Decimal compareVoiceBiometrics(String storedTemplate, String currentBiometric) {
    // Simulate voice biometric comparison
    return storedTemplate == currentBiometric ? 100 : 65;
}

// Helper: Compare iris biometrics
private static Decimal compareIrisBiometrics(String storedTemplate, String currentBiometric) {
    // Simulate iris biometric comparison
    return storedTemplate == currentBiometric ? 100 : 80;
}
}
public class AIFraudDetectionEngine {
    
    private static final String AI_SERVICE_ENDPOINT = 'https://api.frauddetection.ai/v1/analyze';
    private static final Integer AI_TIMEOUT = 30000; // 30 seconds
    private static final Decimal FRAUD_THRESHOLD = 0.75;
    
    @AuraEnabled(cacheable=false)
    public static AIFraudAnalysisResult analyzeFraudRisk(
        String signatureRequestId,
        String userBehaviorData,
        String documentMetadata,
        String sessionContext
    ) {
        try {
            AIFraudAnalysisResult result = new AIFraudAnalysisResult();
            result.analysisId = generateAnalysisId();
            result.timestamp = System.now();
            result.signatureRequestId = signatureRequestId;
            
            // Prepare data for AI analysis
            FraudAnalysisPayload payload = prepareFraudAnalysisPayload(
                signatureRequestId, userBehaviorData, documentMetadata, sessionContext
            );
            
            // Call AI service for fraud analysis
            AIServiceResponse aiResponse = callAIFraudService(payload);
            
            if (aiResponse.success) {
                result = processAIFraudResponse(aiResponse, result);
            } else {
                // Fallback to rule-based analysis
                result = performRuleBasedFraudAnalysis(payload, result);
result.analysisMethod = 'RULE_BASED_FALLBACK';
}

// Store analysis results
storeFraudAnalysisResults(result);

// Create security events for high-risk cases
if (result.riskScore >= FRAUD_THRESHOLD) {
    createHighRiskSecurityEvent(result);
}

// Generate real-time alerts if necessary
if (result.fraudProbability > 0.8) {
    generateRealTimeAlert(result);
}

return result;

} catch (Exception e) {
    System.debug('AI Fraud Detection Engine error: ' + e.getMessage());
    
    // Create fallback result with maximum security
    AIFraudAnalysisResult fallbackResult = createSecureFallbackResult(
        signatureRequestId, 
        e.getMessage()
    );
    
    // Log critical security failure
    logCriticalSecurityFailure('AI_FRAUD_DETECTION_FAILURE', signatureRequestId, e);
    
    return fallbackResult;
}
}
public static AIFraudAnalysisResult analyzeSignatureForFraud(Map<String,Object> payload) {
        AIFraudAnalysisResult result = new AIFraudAnalysisResult();
        try {
            FraudScoringResult ml = MLIntegrationService.calculateFraudScore(payload);
            if (ml != null && ml.success) {
                result.analysisMethod = 'AI_POWERED';
                result.fraudProbability = ml.fraudScore;
                result.riskScore = ml.fraudScore; // normalized
                result.riskLevel = (ml.fraudScore >= 0.8 ? 'CRITICAL' : ml.fraudScore >= 0.6 ? 'HIGH' : 'MEDIUM');
                result.riskIndicators = ml.riskIndicators;
            } else {
                result = performRuleBasedFraudAnalysisFallback(payload);
            }
            // store result robustly
            try {
                storeFraudAnalysisResults(result);
            } catch (Exception e) {
                System.debug('Failed to persist fraud analysis: ' + e.getMessage());
            }
        } catch (Exception e) {
            result = performRuleBasedFraudAnalysisFallback(payload);
        }
        return result;
    }   
private static AIFraudAnalysisResult performRuleBasedFraudAnalysis(
    FraudAnalysisPayload payload, 
    AIFraudAnalysisResult result
) {
try {
    System.debug('Performing rule-based fraud analysis fallback');
    
    // Initialize rule-based scoring
    Decimal totalRiskScore = 0;
    List<RiskIndicator> riskIndicators = new List<RiskIndicator>();
    
    // Rule 1: Velocity Analysis
    VelocityAnalysisResult velocityResult = analyzeUserVelocity(payload.userBehaviorData);
    if (velocityResult.isHighVelocity) {
        totalRiskScore += 25;
        riskIndicators.add(new RiskIndicator(
            'HIGH_VELOCITY', 
            'User performing actions at unusually high speed',
            25,
            'HIGH'
        ));
    }
    
    // Rule 2: Geographic Anomaly Detection
    GeographicAnalysisResult geoResult = analyzeGeographicPatterns(payload.sessionContext);
    if (geoResult.isAnomalous) {
        totalRiskScore += 20;
        riskIndicators.add(new RiskIndicator(
            'GEOGRAPHIC_ANOMALY',
            'Access from unusual geographic location',
            20,
            'MEDIUM'
        ));
    }
    
    // Rule 3: Device Fingerprinting
    DeviceAnalysisResult deviceResult = analyzeDeviceFingerprint(payload.sessionContext);
    if (deviceResult.isSuspicious) {
        totalRiskScore += 30;
        riskIndicators.add(new RiskIndicator(
            'SUSPICIOUS_DEVICE',
            'Device characteristics indicate potential fraud',
            30,
            'HIGH'
        ));
    }
    
    // Rule 4: Temporal Pattern Analysis
    TemporalAnalysisResult temporalResult = analyzeTemporalPatterns(payload.userBehaviorData);
    if (temporalResult.isAnomalous) {
        totalRiskScore += 15;
        riskIndicators.add(new RiskIndicator(
            'TEMPORAL_ANOMALY',
            'Activity outside normal user patterns',
            15,
            'MEDIUM'
        ));
    }
    
    // Rule 5: Document Integrity Check
    DocumentIntegrityResult docResult = analyzeDocumentIntegrity(payload.documentMetadata);
    if (!docResult.isIntegritySafe) {
        totalRiskScore += 35;
        riskIndicators.add(new RiskIndicator(
            'DOCUMENT_INTEGRITY_RISK',
            'Document shows signs of tampering or suspicious modifications',
            35,
            'CRITICAL'
        ));
    }
    
    // Rule 6: Behavioral Biometrics
    BehavioralBiometricResult behavioralResult = analyzeBehavioralBiometrics(payload.userBehaviorData);
    if (behavioralResult.isAnomalous) {
        totalRiskScore += 20;
        riskIndicators.add(new RiskIndicator(
            'BEHAVIORAL_ANOMALY',
            'User behavior deviates from established patterns',
            20,
            'MEDIUM'
        ));
    }
    
    // Calculate final risk assessment
    result.riskScore = Math.min(totalRiskScore, 100) / 100; // Normalize to 0-1
    result.fraudProbability = calculateFraudProbability(totalRiskScore, riskIndicators);
    result.riskLevel = determineRiskLevel(result.riskScore);
    result.riskIndicators = riskIndicators;
    result.recommendation = generateRiskRecommendation(result.riskLevel, riskIndicators);
    result.confidence = 0.85; // Rule-based confidence
    
    System.debug('Rule-based analysis completed. Risk Score: ' + result.riskScore);
    
    return result;
    
} catch (Exception e) {
    System.debug('Rule-based fraud analysis error: ' + e.getMessage());
    
    // Return maximum security result on analysis failure
    result.riskScore = 1.0;
    result.fraudProbability = 1.0;
    result.riskLevel = 'CRITICAL';
    result.recommendation = 'BLOCK_TRANSACTION';
    result.confidence = 0.0;
    result.errorMessage = 'Analysis failed: ' + e.getMessage();
    
    return result;
}
}

private static VelocityAnalysisResult analyzeUserVelocity(String userBehaviorData) {
VelocityAnalysisResult result = new VelocityAnalysisResult();
try {
    Map<String, Object> behaviorMap = (Map<String, Object>) JSON.deserializeUntyped(userBehaviorData);
    
    // Check for rapid successive actions
    List<Object> actionTimestamps = (List<Object>) behaviorMap.get('actionTimestamps');
    if (actionTimestamps != null && actionTimestamps.size() > 1) {
        // Calculate time between actions
        Long totalTime = 0;
        for (Integer i = 1; i < actionTimestamps.size(); i++) {
            Long currentTime = (Long) actionTimestamps[i];
            Long previousTime = (Long) actionTimestamps[i-1];
            totalTime += (currentTime - previousTime);
        }
        
        // Average time between actions (in milliseconds)
        Double avgTimeBetweenActions = totalTime / (actionTimestamps.size() - 1);
        
        // Flag if average time is less than 500ms (unusually fast)
        result.isHighVelocity = avgTimeBetweenActions < 500;
        result.averageActionInterval = avgTimeBetweenActions;
        result.totalActions = actionTimestamps.size();
    }
    
} catch (Exception e) {
    System.debug('Velocity analysis error: ' + e.getMessage());
    result.isHighVelocity = true; // Err on the side of caution
}
return result;
}

private static GeographicAnalysisResult analyzeGeographicPatterns(String sessionContext) {
GeographicAnalysisResult result = new GeographicAnalysisResult();
try {
    Map<String, Object> sessionMap = (Map<String, Object>) JSON.deserializeUntyped(sessionContext);
    
    String currentLocation = (String) sessionMap.get('ipLocation');
    String userId = (String) sessionMap.get('userId');
    
    if (String.isNotBlank(currentLocation) && String.isNotBlank(userId)) {
        // Query recent user locations
        List<User_Session__c> recentSessions = [
            SELECT Location__c, Session_Start__c 
            FROM User_Session__c 
            WHERE User_Id__c = :userId 
            AND Session_Start__c = LAST_N_DAYS:30
            ORDER BY Session_Start__c DESC
            LIMIT 10
        ];
        
        // Check for geographic anomalies
        result.isAnomalous = isLocationAnomalous(currentLocation, recentSessions);
        result.currentLocation = currentLocation;
        result.riskFactor = calculateGeographicRiskFactor(currentLocation, recentSessions);
    }
    
} catch (Exception e) {
    System.debug('Geographic analysis error: ' + e.getMessage());
    result.isAnomalous = true; // Default to suspicious
}
return result;
}

private static DeviceAnalysisResult analyzeDeviceFingerprint(String sessionContext) {
DeviceAnalysisResult result = new DeviceAnalysisResult();
try {
    Map<String, Object> sessionMap = (Map<String, Object>) JSON.deserializeUntyped(sessionContext);
    
    String userAgent = (String) sessionMap.get('userAgent');
    String deviceFingerprint = (String) sessionMap.get('deviceFingerprint');
    String screenResolution = (String) sessionMap.get('screenResolution');
    
    // Check for suspicious user agent patterns
    if (String.isNotBlank(userAgent)) {
        result.isSuspicious = checkSuspiciousUserAgent(userAgent);
    }
    
    // Check device fingerprint consistency
    if (String.isNotBlank(deviceFingerprint)) {
        result.fingerprintRisk = analyzeDeviceFingerprintRisk(deviceFingerprint);
        if (result.fingerprintRisk > 0.7) {
            result.isSuspicious = true;
        }
    }
    
    // Check for automation indicators
    if (String.isNotBlank(screenResolution) && screenResolution.equals('0x0')) {
        result.isSuspicious = true;
        result.automationIndicators = true;
    }
    
} catch (Exception e) {
    System.debug('Device analysis error: ' + e.getMessage());
    result.isSuspicious = true; // Default to suspicious
}
return result;
}

private static TemporalAnalysisResult analyzeTemporalPatterns(String userBehaviorData) {
TemporalAnalysisResult result = new TemporalAnalysisResult();
try {
    Map<String, Object> behaviorMap = (Map<String, Object>) JSON.deserializeUntyped(userBehaviorData);
    
    String currentTimeStr = (String) behaviorMap.get('currentTime');
    if (String.isNotBlank(currentTimeStr)) {
        DateTime currentTime = DateTime.valueOf(currentTimeStr);
        
        // Check if activity is during unusual hours (e.g., 2 AM - 5 AM)
        Integer hourOfDay = currentTime.hour();
        if (hourOfDay >= 2 && hourOfDay <= 5) {
            result.isAnomalous = true;
            result.anomalyType = 'UNUSUAL_HOURS';
        }
        
        // Check if it's weekend activity for business documents
        String dayOfWeek = currentTime.format('EEEE');
        if (dayOfWeek.equals('Saturday') || dayOfWeek.equals('Sunday')) {
            result.weekendActivity = true;
            // Not necessarily anomalous, but worth noting
        }
    }
    
} catch (Exception e) {
    System.debug('Temporal analysis error: ' + e.getMessage());
    result.isAnomalous = false; // Less critical than other factors
}
return result;
}

private static DocumentIntegrityResult analyzeDocumentIntegrity(String documentMetadata) {
DocumentIntegrityResult result = new DocumentIntegrityResult();
try {
    Map<String, Object> docMap = (Map<String, Object>) JSON.deserializeUntyped(documentMetadata);
    
    String documentHash = (String) docMap.get('documentHash');
    String originalHash = (String) docMap.get('originalHash');
    Long fileSize = (Long) docMap.get('fileSize');
    String documentType = (String) docMap.get('documentType');
    
    // Check hash integrity
    if (String.isNotBlank(documentHash) && String.isNotBlank(originalHash)) {
        result.isIntegritySafe = documentHash.equals(originalHash);
        if (!result.isIntegritySafe) {
            result.integrityViolations.add('HASH_MISMATCH');
        }
    }
    
    // Check for suspicious file sizes
    if (fileSize != null) {
        if (fileSize == 0) {
            result.isIntegritySafe = false;
            result.integrityViolations.add('ZERO_BYTE_FILE');
        } else if (fileSize > 50000000) { // 50MB
            result.integrityViolations.add('UNUSUALLY_LARGE_FILE');
        }
    }
    
    // Check document type consistency
    if (String.isNotBlank(documentType) && !isValidDocumentType(documentType)) {
        result.isIntegritySafe = false;
        result.integrityViolations.add('INVALID_DOCUMENT_TYPE');
    }
    
} catch (Exception e) {
    System.debug('Document integrity analysis error: ' + e.getMessage());
    result.isIntegritySafe = false; // Err on the side of caution
}
return result;
}

private static BehavioralBiometricResult analyzeBehavioralBiometrics(String userBehaviorData) {
BehavioralBiometricResult result = new BehavioralBiometricResult();
try {
    Map<String, Object> behaviorMap = (Map<String, Object>) JSON.deserializeUntyped(userBehaviorData);
    
    // Analyze mouse movement patterns
    List<Object> mouseMovements = (List<Object>) behaviorMap.get('mouseMovements');
    if (mouseMovements != null && !mouseMovements.isEmpty()) {
        result.mousePatternAnomalous = analyzeMousePatterns(mouseMovements);
    }
    
    // Analyze keystroke dynamics
    List<Object> keystrokes = (List<Object>) behaviorMap.get('keystrokes');
    if (keystrokes != null && !keystrokes.isEmpty()) {
        result.keystrokePatternAnomalous = analyzeKeystrokePatterns(keystrokes);
    }
    
    // Overall behavioral assessment
    result.isAnomalous = result.mousePatternAnomalous || result.keystrokePatternAnomalous;
    result.confidenceScore = result.isAnomalous ? 0.8 : 0.9;
    
} catch (Exception e) {
    System.debug('Behavioral biometric analysis error: ' + e.getMessage());
    result.isAnomalous = false; // Less critical for fallback
}
return result;
}

private static Decimal calculateFraudProbability(Decimal totalRiskScore, List<RiskIndicator> indicators) {
try {
    // Base probability from risk score
    Decimal baseProbability = totalRiskScore / 100;
    
    // Apply weighting based on risk indicator types
    Decimal weightedProbability = baseProbability;
    for (RiskIndicator indicator : indicators) {
        if (indicator.severity == 'CRITICAL') {
            weightedProbability += 0.15;
        } else if (indicator.severity == 'HIGH') {
            weightedProbability += 0.10;
        }
    }
    
    // Normalize to 0-1 range
    return Math.min(weightedProbability, 1.0);
    
} catch (Exception e) {
    System.debug('Fraud probability calculation error: ' + e.getMessage());
    return 1.0; // Maximum caution
}
}

private static String determineRiskLevel(Decimal riskScore) {
try {
    if (riskScore >= 0.8) {
        return 'CRITICAL';
    } else if (riskScore >= 0.6) {
        return 'HIGH';
    } else if (riskScore >= 0.4) {
        return 'MEDIUM';
    } else {
        return 'LOW';
    }
} catch (Exception e) {
System.debug('Risk level determination error: ' + e.getMessage());
return 'CRITICAL'; // Default to highest security level on error
}
}

private static String generateRiskRecommendation(String riskLevel, List<RiskIndicator> indicators) {
try {
switch on riskLevel {
when 'CRITICAL' {
return 'BLOCK_TRANSACTION - Multiple high-risk indicators detected. Manual review required.';
}
when 'HIGH' {
return 'REQUIRE_ADDITIONAL_VERIFICATION - Enhanced authentication needed before proceeding.';
}
when 'MEDIUM' {
return 'MONITOR_CLOSELY - Allow with increased logging and real-time monitoring.';
}
when 'LOW' {
return 'PROCEED_NORMALLY - Risk within acceptable parameters.';
}
when else {
return 'MANUAL_REVIEW - Unable to determine appropriate action.';
}
}
} catch (Exception e) {
System.debug('Risk recommendation generation error: ' + e.getMessage());
return 'BLOCK_TRANSACTION'; // Most secure default
}
}

private static void storeFraudAnalysisResults(AIFraudAnalysisResult result) {
try {
AI_Fraud_Analysis__c fraudRecord = new AI_Fraud_Analysis__c(
Analysis_Id__c = result.analysisId,
Signature_Request_Id__c = result.signatureRequestId,
Analysis_Timestamp__c = result.timestamp,
Risk_Score__c = result.riskScore * 100, // Convert to percentage
Fraud_Probability__c = result.fraudProbability * 100,
Risk_Level__c = result.riskLevel,
Analysis_Method__c = result.analysisMethod,
Confidence_Score__c = result.confidence * 100,
Recommendation__c = result.recommendation,
Risk_Indicators__c = JSON.serialize(result.riskIndicators),
Analysis_Details__c = JSON.serialize(result)
);

insert fraudRecord;
System.debug('✓ Fraud analysis results stored with ID: ' + fraudRecord.Id);

} catch (Exception e) {
System.debug('Failed to store fraud analysis results: ' + e.getMessage());
// Create fallback audit record
createFallbackAuditRecord('FRAUD_ANALYSIS_STORAGE_FAILURE', result.signatureRequestId, e.getMessage());
}
}

private static void createHighRiskSecurityEvent(AIFraudAnalysisResult result) {
try {
Security_Event__c securityEvent = new Security_Event__c(
Event_Type__c = 'HIGH_RISK_FRAUD_DETECTION',
Event_Timestamp__c = result.timestamp,
Related_Record_Id__c = result.signatureRequestId,
Severity__c = result.riskLevel == 'CRITICAL' ? 'CRITICAL' : 'HIGH',
Risk_Score__c = result.riskScore * 100,
Description__c = 'High-risk fraud indicators detected in signature request',
Event_Details__c = JSON.serialize(result),
Response_Required__c = true,
Alert_Sent__c = false
);

insert securityEvent;

// Trigger immediate security workflow
triggerSecurityWorkflow(securityEvent.Id, result);

} catch (Exception e) {
System.debug('Failed to create high-risk security event: ' + e.getMessage());
// Publish platform event as fallback
publishSecurityPlatformEvent(result, e.getMessage());
}
}

private static void generateRealTimeAlert(AIFraudAnalysisResult result) {
try {
// Create real-time alert for security team
Real_Time_Alert__c alert = new Real_Time_Alert__c(
Alert_Type__c = 'FRAUD_DETECTION',
Priority__c = 'URGENT',
Alert_Timestamp__c = System.now(),
Related_Record_Id__c = result.signatureRequestId,
Alert_Message__c = 'URGENT: High fraud probability (' + 
    (result.fraudProbability * 100).format() + '%) detected in signature request',
Alert_Details__c = JSON.serialize(result),
Status__c = 'ACTIVE',
Assigned_To__c = getSecurityTeamQueue()
);

insert alert;

// Send immediate notification
sendImmediateSecurityNotification(alert, result);

System.debug('✓ Real-time fraud alert generated: ' + alert.Id);

} catch (Exception e) {
System.debug('Failed to generate real-time alert: ' + e.getMessage());
// Emergency notification fallback
sendEmergencyNotification(result, e.getMessage());
}
}

private static AIFraudAnalysisResult createSecureFallbackResult(String signatureRequestId, String errorMessage) {
AIFraudAnalysisResult fallbackResult = new AIFraudAnalysisResult();
try {
fallbackResult.analysisId = generateAnalysisId();
fallbackResult.timestamp = System.now();
fallbackResult.signatureRequestId = signatureRequestId;
fallbackResult.riskScore = 1.0; // Maximum risk
fallbackResult.fraudProbability = 1.0; // Assume fraud
fallbackResult.riskLevel = 'CRITICAL';
fallbackResult.analysisMethod = 'SECURE_FALLBACK';
fallbackResult.confidence = 0.0; // No confidence in analysis
fallbackResult.recommendation = 'BLOCK_TRANSACTION';
fallbackResult.errorMessage = errorMessage;

// Add critical risk indicator
RiskIndicator criticalIndicator = new RiskIndicator();
criticalIndicator.type = 'SYSTEM_FAILURE';
criticalIndicator.description = 'Fraud analysis system failure - blocking as security precaution';
criticalIndicator.riskScore = 100;
criticalIndicator.severity = 'CRITICAL';

fallbackResult.riskIndicators = new List<RiskIndicator>{ criticalIndicator };

} catch (Exception e) {
System.debug('Error creating secure fallback result: ' + e.getMessage());
// Even the fallback failed - create minimal secure result
fallbackResult = new AIFraudAnalysisResult();
fallbackResult.riskScore = 1.0;
fallbackResult.fraudProbability = 1.0;
fallbackResult.riskLevel = 'CRITICAL';
fallbackResult.recommendation = 'BLOCK_TRANSACTION';
}

return fallbackResult;
}

private static void logCriticalSecurityFailure(String failureType, String recordId, Exception e) {
try {
Critical_Security_Log__c securityLog = new Critical_Security_Log__c(
Failure_Type__c = failureType,
Related_Record_Id__c = recordId,
Failure_Timestamp__c = System.now(),
Error_Message__c = e.getMessage(),
Stack_Trace__c = e.getStackTraceString(),
Severity__c = 'CRITICAL',
Immediate_Action_Required__c = true,
Security_Impact__c = 'HIGH'
);

insert securityLog;

// Escalate to security operations center
escalateToSecurityOperations(securityLog);

} catch (Exception logException) {
System.debug('CRITICAL: Failed to log security failure - ' + logException.getMessage());
// Last resort: System debug with structured format
System.debug('SECURITY_FAILURE|' + failureType + '|' + recordId + '|' + e.getMessage());
}
}

// Helper methods for analysis components

private static Boolean isLocationAnomalous(String currentLocation, List<User_Session__c> recentSessions) {
try {
if (recentSessions.isEmpty()) {
return true; // No history = anomalous
}

// Check if current location is within reasonable distance of recent locations
for (User_Session__c session : recentSessions) {
if (String.isNotBlank(session.Location__c)) {
Decimal distance = calculateLocationDistance(currentLocation, session.Location__c);
if (distance < 100) { // Within 100km of recent activity
return false;
}
}
}

return true; // No recent activity within reasonable distance

} catch (Exception e) {
System.debug('Location anomaly check error: ' + e.getMessage());
return true; // Default to anomalous
}
}

private static Decimal calculateGeographicRiskFactor(String currentLocation, List<User_Session__c> recentSessions) {
try {
if (recentSessions.isEmpty()) {
return 0.8; // High risk for new users
}

Decimal minDistance = 999999;
for (User_Session__c session : recentSessions) {
if (String.isNotBlank(session.Location__c)) {
Decimal distance = calculateLocationDistance(currentLocation, session.Location__c);
if (distance < minDistance) {
minDistance = distance;
}
}
}

// Risk increases with distance
if (minDistance < 50) return 0.1; // Low risk
if (minDistance < 200) return 0.3; // Medium-low risk
if (minDistance < 1000) return 0.6; // Medium-high risk
return 0.9; // High risk

} catch (Exception e) {
System.debug('Geographic risk factor calculation error: ' + e.getMessage());
return 0.9; // High risk default
}
}

private static Boolean checkSuspiciousUserAgent(String userAgent) {
try {
Set<String> suspiciousPatterns = new Set<String>{
'bot', 'crawler', 'spider', 'scraper', 'automated', 
'headless', 'phantom', 'selenium', 'webdriver'
};

String lowerUserAgent = userAgent.toLowerCase();
for (String pattern : suspiciousPatterns) {
if (lowerUserAgent.contains(pattern)) {
return true;
}
}

return false;

} catch (Exception e) {
System.debug('User agent check error: ' + e.getMessage());
return true; // Default to suspicious
}
}

private static Decimal analyzeDeviceFingerprintRisk(String deviceFingerprint) {
try {
Map<String, Object> fingerprintData = (Map<String, Object>) JSON.deserializeUntyped(deviceFingerprint);

Decimal riskScore = 0;

// Check for missing or inconsistent data
if (fingerprintData.get('screen') == null) riskScore += 0.2;
if (fingerprintData.get('timezone') == null) riskScore += 0.1;
if (fingerprintData.get('language') == null) riskScore += 0.1;

// Check for automation indicators
if (fingerprintData.get('webdriver') == true) riskScore += 0.5;
if (fingerprintData.get('plugins') != null) {
List<Object> plugins = (List<Object>) fingerprintData.get('plugins');
if (plugins.isEmpty()) riskScore += 0.3; // No plugins = suspicious
}

return Math.min(riskScore, 1.0);

} catch (Exception e) {
System.debug('Device fingerprint risk analysis error: ' + e.getMessage());
return 1.0; // Maximum risk
}
}

private static Boolean isValidDocumentType(String documentType) {
try {
Set<String> validTypes = new Set<String>{
'application/pdf', 'application/msword', 
'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
'text/plain', 'image/jpeg', 'image/png'
};

return validTypes.contains(documentType.toLowerCase());

} catch (Exception e) {
System.debug('Document type validation error: ' + e.getMessage());
return false; // Invalid by default
}
}

private static Boolean analyzeMousePatterns(List<Object> mouseMovements) {
try {
if (mouseMovements.size() < 10) {
return true; // Too few movements = suspicious
}

// Check for unnatural straight-line movements
Integer straightLineCount = 0;
for (Integer i = 2; i < mouseMovements.size(); i++) {
Map<String, Object> current = (Map<String, Object>) mouseMovements[i];
Map<String, Object> previous = (Map<String, Object>) mouseMovements[i-1];
Map<String, Object> beforePrevious = (Map<String, Object>) mouseMovements[i-2];

// Check if three consecutive points are in a straight line
if (isInStraightLine(beforePrevious, previous, current)) {
straightLineCount++;
}
}

// If more than 30% of movements are straight lines, it's suspicious
return (straightLineCount * 1.0 / mouseMovements.size()) > 0.3;

} catch (Exception e) {
System.debug('Mouse pattern analysis error: ' + e.getMessage());
return false; // Not suspicious if analysis fails
}
}

private static Boolean analyzeKeystrokePatterns(List<Object> keystrokes) {
try {
if (keystrokes.size() < 5) {
return true; // Too few keystrokes = suspicious
}

// Analyze timing between keystrokes
List<Long> intervals = new List<Long>();
for (Integer i = 1; i < keystrokes.size(); i++) {
Map<String, Object> current = (Map<String, Object>) keystrokes[i];
Map<String, Object> previous = (Map<String, Object>) keystrokes[i-1];

Long currentTime = (Long) current.get('timestamp');
Long previousTime = (Long) previous.get('timestamp');
intervals.add(currentTime - previousTime);
}

// Check for overly consistent timing (robotic)
if (intervals.size() > 1) {
Long sum = 0;
for (Long interval : intervals) {
sum += interval;
}
Long avgInterval = sum / intervals.size();

// Check variance - low variance indicates robotic behavior
Long variance = 0;
for (Long interval : intervals) {
variance += Math.pow(interval - avgInterval, 2);
}
variance = variance / intervals.size();

// If variance is very low, it's suspicious
return variance < 100; // Threshold for suspicious consistency
}

return false;

} catch (Exception e) {
System.debug('Keystroke pattern analysis error: ' + e.getMessage());
return false; // Not suspicious if analysis fails
}
}

private static String generateAnalysisId() {
try {
return 'FA_' + System.now().getTime() + '_' + Math.round(Math.random() * 10000);
} catch (Exception e) {
System.debug('Analysis ID generation error: ' + e.getMessage());
return 'FA_ERROR_' + System.now().getTime();
}
}

// Result classes for analysis components

public class VelocityAnalysisResult {
@AuraEnabled public Boolean isHighVelocity;
@AuraEnabled public Double averageActionInterval;
@AuraEnabled public Integer totalActions;
}

public class GeographicAnalysisResult {
@AuraEnabled public Boolean isAnomalous;
@AuraEnabled public String currentLocation;
@AuraEnabled public Decimal riskFactor;
}

public class DeviceAnalysisResult {
@AuraEnabled public Boolean isSuspicious;
@AuraEnabled public Decimal fingerprintRisk;
@AuraEnabled public Boolean automationIndicators;
}

public class TemporalAnalysisResult {
@AuraEnabled public Boolean isAnomalous;
@AuraEnabled public String anomalyType;
@AuraEnabled public Boolean weekendActivity;
}

public class DocumentIntegrityResult {
@AuraEnabled public Boolean isIntegritySafe;
@AuraEnabled public List<String> integrityViolations = new List<String>();
}

public class BehavioralBiometricResult {
@AuraEnabled public Boolean isAnomalous;
@AuraEnabled public Boolean mousePatternAnomalous;
@AuraEnabled public Boolean keystrokePatternAnomalous;
@AuraEnabled public Decimal confidenceScore;
}

public class AIFraudAnalysisResult {
@AuraEnabled public String analysisId;
@AuraEnabled public DateTime timestamp;
@AuraEnabled public String signatureRequestId;
@AuraEnabled public Decimal riskScore;
@AuraEnabled public Decimal fraudProbability;
@AuraEnabled public String riskLevel;
@AuraEnabled public String analysisMethod;
@AuraEnabled public Decimal confidence;
@AuraEnabled public String recommendation;
@AuraEnabled public List<RiskIndicator> riskIndicators;
@AuraEnabled public String errorMessage;
}

public class RiskIndicator {
    @AuraEnabled public String type;
    @AuraEnabled public String description;
    @AuraEnabled public Decimal riskScore;
    @AuraEnabled public String severity;
    @AuraEnabled public String category;
    @AuraEnabled public String mitigation;
    @AuraEnabled public DateTime detectedAt;
    
    public RiskIndicator() {
        this.detectedAt = System.now();
    }
    
    public RiskIndicator(String type, String description, Decimal riskScore, String severity) {
        this.type = type;
        this.description = description;
        this.riskScore = riskScore;
        this.severity = severity;
        this.detectedAt = System.now();
        this.category = determineCategory(type);
        this.mitigation = generateMitigation(type, severity);
    }
    
    private String determineCategory(String type) {
        try {
            if (type.contains('VELOCITY') || type.contains('TEMPORAL')) {
                return 'BEHAVIORAL';
            } else if (type.contains('GEOGRAPHIC') || type.contains('LOCATION')) {
                return 'GEOLOCATION';
            } else if (type.contains('DEVICE') || type.contains('FINGERPRINT')) {
                return 'DEVICE_BASED';
            } else if (type.contains('DOCUMENT') || type.contains('INTEGRITY')) {
                return 'DOCUMENT_SECURITY';
            } else if (type.contains('BIOMETRIC') || type.contains('AUTHENTICATION')) {
                return 'IDENTITY_VERIFICATION';
            } else {
                return 'GENERAL';
            }
        } catch (Exception e) {
            System.debug('Category determination error: ' + e.getMessage());
            return 'UNKNOWN';
        }
    }
    
    private String generateMitigation(String type, String severity) {
        try {
            switch on severity {
                when 'CRITICAL' {
                    return 'IMMEDIATE_BLOCK - Transaction must be blocked and security team notified';
                }
                when 'HIGH' {
                    return 'ENHANCED_VERIFICATION - Require additional authentication methods';
                }
                when 'MEDIUM' {
                    return 'INCREASED_MONITORING - Allow with enhanced logging and review';
                }
                when 'LOW' {
                    return 'STANDARD_MONITORING - Continue with normal security protocols';
                }
                when else {
                    return 'MANUAL_REVIEW - Escalate to security analyst for evaluation';
                }
            }
        } catch (Exception e) {
            System.debug('Mitigation generation error: ' + e.getMessage());
            return 'MANUAL_REVIEW - Error in automated assessment';
        }
    }
}

    public class FraudAnalysisPayload {
        @AuraEnabled public String signatureRequestId;
        @AuraEnabled public String userBehaviorData;
        @AuraEnabled public String documentMetadata;
        @AuraEnabled public String sessionContext;
        @AuraEnabled public DateTime analysisTimestamp;
        
        public FraudAnalysisPayload() {
            this.analysisTimestamp = System.now();
        }
    }

    public class AIServiceResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String responseData;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String modelVersion;
        @AuraEnabled public Decimal confidence;
    }

    private static FraudAnalysisPayload prepareFraudAnalysisPayload(
        String signatureRequestId,
        String userBehaviorData,
        String documentMetadata,
        String sessionContext
    ) {
        try {
            FraudAnalysisPayload payload = new FraudAnalysisPayload();
            payload.signatureRequestId = signatureRequestId;
            payload.userBehaviorData = userBehaviorData;
            payload.documentMetadata = documentMetadata;
            payload.sessionContext = sessionContext;
            
            // Enrich payload with additional context
            payload = enrichPayloadWithHistoricalData(payload);
            payload = enrichPayloadWithSystemContext(payload);
            
            return payload;
        } catch (Exception e) {
            System.debug('Payload preparation error: ' + e.getMessage());
            // Return minimal payload on error
            FraudAnalysisPayload fallbackPayload = new FraudAnalysisPayload();
            fallbackPayload.signatureRequestId = signatureRequestId;
            return fallbackPayload;
        }
    }

    private static FraudAnalysisPayload enrichPayloadWithHistoricalData(FraudAnalysisPayload payload) {
        try {
            // Add user's historical signature patterns
            Map<String, Object> sessionData = (Map<String, Object>) JSON.deserializeUntyped(payload.sessionContext);
            String userId = (String) sessionData.get('userId');
            
            if (String.isNotBlank(userId)) {
                // Query recent user activity
                List<Signature_Request__c> recentRequests = [
                    SELECT Id, Created_Date__c, Risk_Score__c, Status__c, Geographic_Location__c
                    FROM Signature_Request__c
                    WHERE Requesting_User__c = :userId
                    AND Created_Date__c = LAST_N_DAYS:30
                    ORDER BY Created_Date__c DESC
                    LIMIT 10
                ];
                
                // Add historical context to session data
                sessionData.put('recentActivityCount', recentRequests.size());
                sessionData.put('averageRiskScore', calculateAverageRiskScore(recentRequests));
                sessionData.put('hasRecentHighRiskActivity', hasRecentHighRiskActivity(recentRequests));
                
                payload.sessionContext = JSON.serialize(sessionData);
            }
            
            return payload;
        } catch (Exception e) {
            System.debug('Historical data enrichment error: ' + e.getMessage());
            return payload; // Return original payload if enrichment fails
        }
    }

    private static FraudAnalysisPayload enrichPayloadWithSystemContext(FraudAnalysisPayload payload) {
        try {
            Map<String, Object> sessionData = (Map<String, Object>) JSON.deserializeUntyped(payload.sessionContext);
            
            // Add system-level context
            sessionData.put('systemLoad', getCurrentSystemLoad());
            sessionData.put('activeSecurityIncidents', getActiveSecurityIncidentCount());
            sessionData.put('currentThreatLevel', getCurrentThreatLevel());
            sessionData.put('analysisTimestamp', payload.analysisTimestamp.getTime());
            
            payload.sessionContext = JSON.serialize(sessionData);
            
            return payload;
        } catch (Exception e) {
            System.debug('System context enrichment error: ' + e.getMessage());
            return payload;
        }
    }

    private static AIServiceResponse callAIFraudService(FraudAnalysisPayload payload) {
        AIServiceResponse response = new AIServiceResponse();
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:AI_Fraud_Detection_Service/analyze');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer {!$Credential.AI_Service_Token}');
            req.setTimeout(AI_TIMEOUT);
            
            // Prepare request body
            Map<String, Object> requestBody = new Map<String, Object>{
                'signatureRequestId' => payload.signatureRequestId,
                'userBehavior' => JSON.deserializeUntyped(payload.userBehaviorData),
                'documentMetadata' => JSON.deserializeUntyped(payload.documentMetadata),
                'sessionContext' => JSON.deserializeUntyped(payload.sessionContext),
                'timestamp' => payload.analysisTimestamp.getTime(),
                'apiVersion' => '2.1'
            };
            
            req.setBody(JSON.serialize(requestBody));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            response.statusCode = res.getStatusCode();
            response.responseData = res.getBody();
            
            if (res.getStatusCode() == 200) {
                response.success = true;
                
                // Parse AI service response
                Map<String, Object> aiResult = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                response.modelVersion = (String) aiResult.get('modelVersion');
                response.confidence = (Decimal) aiResult.get('confidence');
                
                System.debug('✓ AI fraud service called successfully');
            } else {
                response.success = false;
                response.errorMessage = 'AI service returned status: ' + res.getStatusCode();
                System.debug('AI service error: ' + response.errorMessage);
            }
            
        } catch (CalloutException ce) {
            System.debug('AI service callout error: ' + ce.getMessage());
            response.success = false;
            response.errorMessage = 'Service unavailable: ' + ce.getMessage();
        } catch (Exception e) {
            System.debug('AI service call error: ' + e.getMessage());
            response.success = false;
            response.errorMessage = 'Unexpected error: ' + e.getMessage();
        }
        
        return response;
    }

    private static AIFraudAnalysisResult processAIFraudResponse(AIServiceResponse aiResponse, AIFraudAnalysisResult result) {
        try {
            Map<String, Object> aiResult = (Map<String, Object>) JSON.deserializeUntyped(aiResponse.responseData);
            
            // Extract AI analysis results
            result.riskScore = (Decimal) aiResult.get('riskScore');
            result.fraudProbability = (Decimal) aiResult.get('fraudProbability');
            result.riskLevel = (String) aiResult.get('riskLevel');
            result.confidence = aiResponse.confidence;
            result.analysisMethod = 'AI_POWERED';
            
            // Process risk indicators from AI
            List<Object> aiIndicators = (List<Object>) aiResult.get('riskIndicators');
            if (aiIndicators != null) {
                result.riskIndicators = new List<RiskIndicator>();
                for (Object indicatorObj : aiIndicators) {
                    Map<String, Object> indicatorMap = (Map<String, Object>) indicatorObj;
                    RiskIndicator indicator = new RiskIndicator();
                    indicator.type = (String) indicatorMap.get('type');
                    indicator.description = (String) indicatorMap.get('description');
                    indicator.riskScore = (Decimal) indicatorMap.get('score');
                    indicator.severity = (String) indicatorMap.get('severity');
                    result.riskIndicators.add(indicator);
                }
            }
            
            // Generate recommendation based on AI results
            result.recommendation = generateAIBasedRecommendation(result.riskScore, result.fraudProbability);
            
            System.debug('✓ AI fraud response processed successfully');
            return result;
            
        } catch (Exception e) {
            System.debug('AI response processing error: ' + e.getMessage());
            // Fall back to rule-based analysis
            result.analysisMethod = 'AI_PROCESSING_FAILED_FALLBACK';
            result.errorMessage = 'AI processing failed: ' + e.getMessage();
            return result;
        }
    }

    private static String generateAIBasedRecommendation(Decimal riskScore, Decimal fraudProbability) {
        try {
            if (fraudProbability >= 0.9) {
                return 'BLOCK_TRANSACTION - AI detected extremely high fraud probability';
            } else if (fraudProbability >= 0.7) {
                return 'REQUIRE_ADDITIONAL_VERIFICATION - High fraud risk detected by AI';
            } else if (fraudProbability >= 0.4) {
                return 'ENHANCED_MONITORING - Moderate fraud risk identified';
            } else {
                return 'PROCEED_WITH_STANDARD_MONITORING - Low fraud risk';
            }
        } catch (Exception e) {
            System.debug('AI recommendation generation error: ' + e.getMessage());
            return 'MANUAL_REVIEW - Error in AI recommendation';
        }
    }

    // Helper methods for payload enrichment
    private static Decimal calculateAverageRiskScore(List<Signature_Request__c> requests) {
        try {
            if (requests.isEmpty()) return 0;
            
            Decimal total = 0;
            Integer validScores = 0;
            
            for (Signature_Request__c req : requests) {
                if (req.Risk_Score__c != null) {
                    total += req.Risk_Score__c;
                    validScores++;
                }
            }
            
            return validScores > 0 ? total / validScores : 0;
        } catch (Exception e) {
            System.debug('Average risk score calculation error: ' + e.getMessage());
            return 0;
        }
    }

    private static Boolean hasRecentHighRiskActivity(List<Signature_Request__c> requests) {
        try {
            for (Signature_Request__c req : requests) {
                if (req.Risk_Score__c != null && req.Risk_Score__c > 70) {
                    return true;
                }
            }
            return false;
        } catch (Exception e) {
            System.debug('High risk activity check error: ' + e.getMessage());
            return false; // Conservative default
        }
    }

    private static String getCurrentSystemLoad() {
        try {
            // Simulate system load calculation
            return 'NORMAL'; // This would integrate with actual system monitoring
        } catch (Exception e) {
            System.debug('System load check error: ' + e.getMessage());
            return 'UNKNOWN';
        }
    }

    private static Integer getActiveSecurityIncidentCount() {
        try {
            return [SELECT COUNT() FROM Security_Event__c WHERE Status__c = 'ACTIVE' AND CreatedDate = TODAY];
        } catch (Exception e) {
            System.debug('Active security incident count error: ' + e.getMessage());
            return 0;
        }
    }

    private static String getCurrentThreatLevel() {
        try {
            // Query current organizational threat level
            List<Threat_Level_Setting__c> threatSettings = [
                SELECT Current_Level__c 
                FROM Threat_Level_Setting__c 
                WHERE IsActive__c = true 
                LIMIT 1
            ];
            
            return threatSettings.isEmpty() ? 'NORMAL' : threatSettings[0].Current_Level__c;
        } catch (Exception e) {
            System.debug('Threat level check error: ' + e.getMessage());
            return 'ELEVATED'; // Conservative default
        }
    }

    private static void createFallbackAuditRecord(String eventType, String recordId, String errorMessage) {
        try {
            Audit_Trail__c auditRecord = new Audit_Trail__c(
                Event_Type__c = eventType,
                Related_Record_Id__c = recordId,
                Event_Timestamp__c = System.now(),
                Error_Details__c = errorMessage,
                Severity__c = 'HIGH',
                Source__c = 'AI_FRAUD_DETECTION_ENGINE'
            );
            insert auditRecord;
        } catch (Exception e) {
            System.debug('Fallback audit record creation failed: ' + e.getMessage());
        }
    }

    private static void triggerSecurityWorkflow(Id securityEventId, AIFraudAnalysisResult result) {
        try {
            // Create security workflow case
            Case securityCase = new Case(
                Subject = 'High-Risk Fraud Detection: ' + result.signatureRequestId,
                Description = 'AI fraud detection identified high-risk indicators requiring immediate attention',
                Priority = result.riskLevel == 'CRITICAL' ? 'High' : 'Medium',
                Status = 'New',
                Type = 'Security Incident',
                Origin = 'AI Fraud Detection',
                Security_Event_Id__c = securityEventId,
                Related_Signature_Request__c = result.signatureRequestId
            );
    insert securityCase;
    System.debug('✓ Security workflow triggered with Case ID: ' + securityCase.Id);
    } catch (Exception e) {
    System.debug('Security workflow trigger failed: ' + e.getMessage());
    // Fallback to platform event
    publishSecurityWorkflowEvent(securityEventId, result, e.getMessage());
    }
    } private static void publishSecurityPlatformEvent(AIFraudAnalysisResult result, String errorMessage) {
    try {
    Security_Alert_Event__e alertEvent = new Security_Alert_Event__e(
    Alert_Type__c = 'FRAUD_DETECTION_FAILURE',
    Signature_Request_Id__c = result.signatureRequestId,
    Risk_Score__c = result.riskScore * 100,
    Alert_Message__c = 'Critical fraud detection system failure',
    Error_Details__c = errorMessage,
    Requires_Immediate_Action__c = true,
    Event_Timestamp__c = System.now()
    ); EventBus.publish(alertEvent);
    System.debug('✓ Security platform event published as fallback');
    } catch (Exception e) {
    System.debug('Platform event publication failed: ' + e.getMessage());
    // Ultimate fallback - system debug with structured format
    System.debug('CRITICAL_FRAUD_ALERT|' + result.signatureRequestId + '|' + result.riskScore + '|' + errorMessage);
    }
    } private static void publishSecurityWorkflowEvent(Id securityEventId, AIFraudAnalysisResult result, String errorMessage) {
    try {
    Security_Workflow_Event__e workflowEvent = new Security_Workflow_Event__e(
    Security_Event_Id__c = securityEventId,
    Signature_Request_Id__c = result.signatureRequestId,
    Workflow_Type__c = 'HIGH_RISK_FRAUD',
    Priority__c = result.riskLevel,
    Error_Message__c = errorMessage,
    Auto_Created__c = true,
    Event_Timestamp__c = System.now()
    ); EventBus.publish(workflowEvent);
    System.debug('✓ Security workflow platform event published');
    } catch (Exception e) {
    System.debug('Security workflow event publication failed: ' + e.getMessage());
    }
    } private static String getSecurityTeamQueue() {
    try {
    List<Group> securityQueues = [
    SELECT Id, DeveloperName
    FROM Group
    WHERE Type = 'Queue' AND DeveloperName LIKE '%Security%'
    LIMIT 1
    ]; return securityQueues.isEmpty()? UserInfo.getUserId() : securityQueues[0].Id;
    } catch (Exception e) {
    System.debug('Security team queue lookup error: ' + e.getMessage());
    return UserInfo.getUserId(); // Fallback to current user
    }
    } private static void sendImmediateSecurityNotification(Real_Time_Alert__c alert, AIFraudAnalysisResult result) {
    try {
    // Query security team members
    List<User> securityTeam = [
    SELECT Id, Email
    FROM User
    WHERE Profile.Name LIKE '%Security%' AND IsActive = true
    LIMIT 10
    ]; if (!securityTeam.isEmpty()) {
    // Prepare email notification
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>(); for (User securityUser : securityTeam) {
    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    email.setToAddresses(new String[]{ securityUser.Email });
    email.setSubject('URGENT: High-Risk Fraud Detection Alert');
    email.setPlainTextBody(buildSecurityEmailBody(alert, result));
    email.setUseSignature(false);
    emails.add(email);
    } // Send notifications
    if (!emails.isEmpty()) {
    Messaging.sendEmail(emails);
    System.debug('✓ Security notifications sent to ' + emails.size() + ' team members');
    }
    }
    } catch (Exception e) {
    System.debug('Security notification sending failed: ' + e.getMessage());
    // Fallback to Chatter notification
    postChatterSecurityAlert(alert, result, e.getMessage());
    }
    } private static void sendEmergencyNotification(AIFraudAnalysisResult result, String errorMessage) {
    try {
    // Create emergency notification record
    Emergency_Notification__c emergency = new Emergency_Notification__c(
    Notification_Type__c = 'FRAUD_SYSTEM_FAILURE',
    Related_Record_Id__c = result.signatureRequestId,
    Urgency__c = 'CRITICAL',
    Message__c = 'Fraud detection system failure - manual review required immediately',
    Error_Details__c = errorMessage,
    Notification_Timestamp__c = System.now(),
    Status__c = 'PENDING'
    ); insert emergency; // Trigger emergency workflow
    triggerEmergencyWorkflow(emergency.Id); System.debug('✓ Emergency notification created: ' + emergency.Id);
    } catch (Exception e) {
    System.debug('Emergency notification creation failed: ' + e.getMessage());
    // Ultimate fallback
    System.debug('EMERGENCY_FRAUD_FAILURE|' + result.signatureRequestId + '|' + errorMessage);
    }
    } private static String buildSecurityEmailBody(Real_Time_Alert__c alert, AIFraudAnalysisResult result) {
    try {
    String emailBody = 'URGENT SECURITY ALERT\n\n';
    emailBody += 'Alert Type: High-Risk Fraud Detection\n';
    emailBody += 'Signature Request ID: ' + result.signatureRequestId + '\n';
    emailBody += 'Risk Score: ' + (result.riskScore * 100).format() + '%\n';
    emailBody += 'Fraud Probability: ' + (result.fraudProbability * 100).format() + '%\n';
    emailBody += 'Risk Level: ' + result.riskLevel + '\n';
    emailBody += 'Recommendation: ' + result.recommendation + '\n\n'; emailBody += 'Risk Indicators:\n';
    if (result.riskIndicators!= null) {
    for (RiskIndicator indicator : result.riskIndicators) {
    emailBody += '- ' + indicator.description + ' (' + indicator.severity + ')\n';
    }
    } emailBody += '\nImmediate Action Required: Review and take appropriate security measures.\n';
    emailBody += 'Alert Generated: ' + System.now().format() + '\n';
    emailBody += 'System: Salesforce E-Signature Security Engine'; return emailBody;
    } catch (Exception e) {
    System.debug('Email body building error: ' + e.getMessage());
    return 'URGENT: Fraud detection alert for signature request ' + result.signatureRequestId + 
    '. Manual review required immediately.';
    }
    } private static void postChatterSecurityAlert(Real_Time_Alert__c alert, AIFraudAnalysisResult result, String errorMessage) {
    try {
    // Find security group
    List<CollaborationGroup> securityGroups = [
    SELECT Id
    FROM CollaborationGroup
    WHERE Name LIKE '%Security%'
    LIMIT 1
    ]; if (!securityGroups.isEmpty()) {
    ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
    ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
    ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput(); textSegmentInput.text = 'URGENT FRAUD ALERT: High-risk fraud indicators detected for signature request ' +
    result.signatureRequestId + '. Risk Score: ' + (result.riskScore * 100).format() + 
    '%. Immediate review required.'; messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>{ textSegmentInput };
    feedItemInput.body = messageBodyInput;
    feedItemInput.feedType = ConnectApi.FeedType.Record;
    feedItemInput.subjectId = securityGroups[0].Id; ConnectApi.Feed.postFeedItem(null, feedItemInput);
    System.debug('✓ Chatter security alert posted');
    }
    } catch (Exception e) {
    System.debug('Chatter security alert posting failed: ' + e.getMessage());
    }
    } private static void triggerEmergencyWorkflow(Id emergencyNotificationId) {
    try {
    // Create workflow task for immediate attention
    Task emergencyTask = new Task(
    Subject = 'EMERGENCY: Fraud Detection System Failure',
    Description = 'Critical fraud detection system failure requires immediate manual review and system assessment.',
    Priority = 'High',
    Status = 'Not Started',
    ActivityDate = Date.today(),
    WhatId = emergencyNotificationId,
    OwnerId = getSecurityManagerId()
    ); insert emergencyTask; System.debug('✓ Emergency workflow task created: ' + emergencyTask.Id);
    } catch (Exception e) {
    System.debug('Emergency workflow trigger failed: ' + e.getMessage());
    }
    } private static Id getSecurityManagerId() {
    try {
    List<User> securityManagers = [
    SELECT Id
    FROM User
    WHERE Profile.Name LIKE '%Security Manager%' AND IsActive = true
    LIMIT 1
    ]; return securityManagers.isEmpty()? UserInfo.getUserId() : securityManagers[0].Id;
    } catch (Exception e) {
    System.debug('Security manager lookup error: ' + e.getMessage());
    return UserInfo.getUserId();
    }
    } // Helper methods for geometric calculations
    private static Boolean isInStraightLine(Map<String, Object> point1, Map<String, Object> point2, Map<String, Object> point3) {
    try {
    Decimal x1 = (Decimal) point1.get('x');
    Decimal y1 = (Decimal) point1.get('y');
    Decimal x2 = (Decimal) point2.get('x');
    Decimal y2 = (Decimal) point2.get('y');
    Decimal x3 = (Decimal) point3.get('x');
    Decimal y3 = (Decimal) point3.get('y'); // Calculate area of triangle formed by three points
    // If area is close to 0, points are in straight line
    Decimal area = Math.abs((x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2)) / 2); return area < 5; // Threshold for considering points in straight line
    } catch (Exception e) {
    System.debug('Straight line calculation error: ' + e.getMessage());
    return false;
    }
    } // Custom exceptions for AI fraud detection
    public class AIFraudDetectionException extends Exception {}
    public class FraudAnalysisException extends Exception {}
    public class SecurityNotificationException extends Exception {}
    } 

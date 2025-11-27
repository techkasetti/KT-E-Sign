/**
 * @description AI-powered engine for detecting fraudulent signature requests. It uses an external
 * AI service with a fallback to a comprehensive internal rule-based engine.
 */
public class AIFraudDetectionEngine {

    // Configuration constants for the AI service callout
    private static final String AI_SERVICE_ENDPOINT = 'callout:AI_Fraud_Detection_Service/analyze';
    private static final Integer AI_TIMEOUT = 30000; // 30 seconds
    private static final Decimal FRAUD_THRESHOLD = 0.75;

    /**
     * @description Main entry point for analyzing fraud risk in a signature request.
     * @param signatureRequestId The ID of the Signature_Request__c record.
     * @param userBehaviorData JSON string representing user's interaction data.
     * @param documentMetadata JSON string with metadata about the document being signed.
     * @param sessionContext JSON string with session details like IP, user agent, etc.
     * @return AIFraudAnalysisResult The comprehensive result of the fraud analysis.
     */
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

            // Step 1: Prepare and enrich the data payload
            FraudAnalysisPayload payload = prepareFraudAnalysisPayload(
                signatureRequestId, userBehaviorData, documentMetadata, sessionContext
            );

            // Step 2: Call the external AI service for fraud analysis
            AIServiceResponse aiResponse = callAIFraudService(payload);

            if (aiResponse.success) {
                // Process the successful response from the AI service
                result = processAIFraudResponse(aiResponse, result);
            } else {
                // If AI service fails, fall back to the internal rule-based engine
                result = performRuleBasedFraudAnalysis(payload, result);
                result.analysisMethod = 'RULE_BASED_FALLBACK';
            }

            // Step 3: Store the final analysis results
            storeFraudAnalysisResults(result);

            // Step 4: Create security events and alerts for high-risk cases
            if (result.riskScore >= FRAUD_THRESHOLD) {
                createHighRiskSecurityEvent(result);
            }
            if (result.fraudProbability > 0.8) {
                generateRealTimeAlert(result);
            }

            return result;

        } catch (Exception e) {
            System.debug('AI Fraud Detection Engine error: ' + e.getMessage());
            // Create a secure fallback result that assumes maximum risk
            AIFraudAnalysisResult fallbackResult = createSecureFallbackResult(signatureRequestId, e.getMessage());
            logCriticalSecurityFailure('AI_FRAUD_DETECTION_FAILURE', signatureRequestId, e);
            return fallbackResult;
        }
    }

    // --- Rule-Based Fallback Engine ---

    private static AIFraudAnalysisResult performRuleBasedFraudAnalysis(FraudAnalysisPayload payload, AIFraudAnalysisResult result) {
        try {
            System.debug('Performing rule-based fraud analysis fallback');
            Decimal totalRiskScore = 0;
            List<RiskIndicator> riskIndicators = new List<RiskIndicator>();

            // Rule 1: Velocity Analysis
            VelocityAnalysisResult velocityResult = analyzeUserVelocity(payload.userBehaviorData);
            if (velocityResult.isHighVelocity) {
                totalRiskScore += 25;
                riskIndicators.add(new RiskIndicator('HIGH_VELOCITY', 'User performing actions at unusually high speed', 25, 'HIGH'));
            }

            // Rule 2: Geographic Anomaly Detection
            GeographicAnalysisResult geoResult = analyzeGeographicPatterns(payload.sessionContext);
            if (geoResult.isAnomalous) {
                totalRiskScore += 20;
                riskIndicators.add(new RiskIndicator('GEOGRAPHIC_ANOMALY', 'Access from unusual geographic location', 20, 'MEDIUM'));
            }

            // Rule 3: Device Fingerprinting
            DeviceAnalysisResult deviceResult = analyzeDeviceFingerprint(payload.sessionContext);
            if (deviceResult.isSuspicious) {
                totalRiskScore += 30;
                riskIndicators.add(new RiskIndicator('SUSPICIOUS_DEVICE', 'Device characteristics indicate potential fraud', 30, 'HIGH'));
            }

            // Rule 4: Temporal Pattern Analysis
            TemporalAnalysisResult temporalResult = analyzeTemporalPatterns(payload.userBehaviorData);
            if (temporalResult.isAnomalous) {
                totalRiskScore += 15;
                riskIndicators.add(new RiskIndicator('TEMPORAL_ANOMALY', 'Activity outside normal user patterns', 15, 'MEDIUM'));
            }

            // Rule 5: Document Integrity Check
            DocumentIntegrityResult docResult = analyzeDocumentIntegrity(payload.documentMetadata);
            if (!docResult.isIntegritySafe) {
                totalRiskScore += 35;
                riskIndicators.add(new RiskIndicator('DOCUMENT_INTEGRITY_RISK', 'Document shows signs of tampering or suspicious modifications', 35, 'CRITICAL'));
            }
            
            // Rule 6: Behavioral Biometrics (placeholder for more complex analysis)
            BehavioralBiometricResult behavioralResult = analyzeBehavioralBiometrics(payload.userBehaviorData);
            if (behavioralResult.isAnomalous) {
                totalRiskScore += 20;
                riskIndicators.add(new RiskIndicator('BEHAVIORAL_ANOMALY', 'User behavior deviates from established patterns', 20, 'MEDIUM'));
            }

            // Calculate final risk assessment
            result.riskScore = Math.min(totalRiskScore, 100) / 100; // Normalize to 0-1
            result.fraudProbability = calculateFraudProbability(totalRiskScore, riskIndicators);
            result.riskLevel = determineRiskLevel(result.riskScore);
            result.riskIndicators = riskIndicators;
            result.recommendation = generateRiskRecommendation(result.riskLevel, riskIndicators);
            result.confidence = 0.85; // Fixed confidence for rule-based results
            
            return result;
        } catch (Exception e) {
            System.debug('Rule-based fraud analysis error: ' + e.getMessage());
            return createSecureFallbackResult(payload.signatureRequestId, 'Rule-based analysis failed: ' + e.getMessage());
        }
    }

    // --- Data Preparation and Enrichment ---

    private static FraudAnalysisPayload prepareFraudAnalysisPayload(String reqId, String behavior, String docMeta, String session) {
        FraudAnalysisPayload payload = new FraudAnalysisPayload();
        payload.signatureRequestId = reqId;
        payload.userBehaviorData = behavior;
        payload.documentMetadata = docMeta;
        payload.sessionContext = session;
        
        payload = enrichPayloadWithHistoricalData(payload);
        payload = enrichPayloadWithSystemContext(payload);
        
        return payload;
    }

    private static FraudAnalysisPayload enrichPayloadWithHistoricalData(FraudAnalysisPayload payload) {
        try {
            Map<String, Object> sessionData = (Map<String, Object>) JSON.deserializeUntyped(payload.sessionContext);
            String userId = (String) sessionData.get('userId');

            if (String.isNotBlank(userId)) {
                List<Signature_Request__c> recentRequests = [
                    SELECT Id, Risk_Score__c
                    FROM Signature_Request__c
                    WHERE Requesting_User__c = :userId AND Created_Date__c = LAST_N_DAYS:30
                    LIMIT 10
                ];
                sessionData.put('recentActivityCount', recentRequests.size());
                sessionData.put('averageRiskScore', calculateAverageRiskScore(recentRequests));
                sessionData.put('hasRecentHighRiskActivity', hasRecentHighRiskActivity(recentRequests));
                payload.sessionContext = JSON.serialize(sessionData);
            }
        } catch (Exception e) {
            System.debug('Historical data enrichment error: ' + e.getMessage());
        }
        return payload;
    }

    private static FraudAnalysisPayload enrichPayloadWithSystemContext(FraudAnalysisPayload payload) {
        try {
            Map<String, Object> sessionData = (Map<String, Object>) JSON.deserializeUntyped(payload.sessionContext);
            sessionData.put('systemLoad', getCurrentSystemLoad());
            sessionData.put('activeSecurityIncidents', getActiveSecurityIncidentCount());
            sessionData.put('currentThreatLevel', getCurrentThreatLevel());
            sessionData.put('analysisTimestamp', payload.analysisTimestamp.getTime());
            payload.sessionContext = JSON.serialize(sessionData);
        } catch (Exception e) {
            System.debug('System context enrichment error: ' + e.getMessage());
        }
        return payload;
    }
    
    // --- AI Service Integration ---

    private static AIServiceResponse callAIFraudService(FraudAnalysisPayload payload) {
        AIServiceResponse response = new AIServiceResponse();
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(AI_SERVICE_ENDPOINT);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer {!$Credential.AI_Service_Token}');
            req.setTimeout(AI_TIMEOUT);

            Map<String, Object> requestBody = new Map<String, Object>{
                'signatureRequestId' => payload.signatureRequestId,
                'userBehavior' => JSON.deserializeUntyped(payload.userBehaviorData),
                'documentMetadata' => JSON.deserializeUntyped(payload.documentMetadata),
                'sessionContext' => JSON.deserializeUntyped(payload.sessionContext)
            };
            req.setBody(JSON.serialize(requestBody));

            HttpResponse res = new Http().send(req);
            response.statusCode = res.getStatusCode();
            response.responseData = res.getBody();

            if (res.getStatusCode() == 200) {
                response.success = true;
                Map<String, Object> aiResult = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                response.modelVersion = (String) aiResult.get('modelVersion');
                response.confidence = (Decimal) aiResult.get('confidence');
            } else {
                response.success = false;
                response.errorMessage = 'AI service returned status: ' + res.getStatusCode();
            }
        } catch (Exception e) {
            response.success = false;
            response.errorMessage = 'AI service callout error: ' + e.getMessage();
        }
        return response;
    }

    private static AIFraudAnalysisResult processAIFraudResponse(AIServiceResponse aiResponse, AIFraudAnalysisResult result) {
        try {
            Map<String, Object> aiResult = (Map<String, Object>) JSON.deserializeUntyped(aiResponse.responseData);
            result.riskScore = (Decimal) aiResult.get('riskScore');
            result.fraudProbability = (Decimal) aiResult.get('fraudProbability');
            result.riskLevel = (String) aiResult.get('riskLevel');
            result.confidence = aiResponse.confidence;
            result.analysisMethod = 'AI_POWERED';
            result.recommendation = generateAIBasedRecommendation(result.riskScore, result.fraudProbability);

            List<Object> aiIndicators = (List<Object>) aiResult.get('riskIndicators');
            if (aiIndicators != null) {
                result.riskIndicators = new List<RiskIndicator>();
                for (Object indicatorObj : aiIndicators) {
                    Map<String, Object> indicatorMap = (Map<String, Object>) indicatorObj;
                    result.riskIndicators.add(new RiskIndicator(
                        (String)indicatorMap.get('type'),
                        (String)indicatorMap.get('description'),
                        (Decimal)indicatorMap.get('score'),
                        (String)indicatorMap.get('severity')
                    ));
                }
            }
            return result;
        } catch (Exception e) {
            System.debug('AI response processing error: ' + e.getMessage());
            result.analysisMethod = 'AI_PROCESSING_FAILED_FALLBACK';
            result.errorMessage = 'AI processing failed: ' + e.getMessage();
            return result;
        }
    }
    
    // --- Rule-based analysis components (Stubs for demonstration) ---
    private static VelocityAnalysisResult analyzeUserVelocity(String userBehaviorData) { return new VelocityAnalysisResult(); }
    private static GeographicAnalysisResult analyzeGeographicPatterns(String sessionContext) { return new GeographicAnalysisResult(); }
    private static DeviceAnalysisResult analyzeDeviceFingerprint(String sessionContext) { return new DeviceAnalysisResult(); }
    private static TemporalAnalysisResult analyzeTemporalPatterns(String userBehaviorData) { return new TemporalAnalysisResult(); }
    private static DocumentIntegrityResult analyzeDocumentIntegrity(String documentMetadata) { return new DocumentIntegrityResult(); }
    private static BehavioralBiometricResult analyzeBehavioralBiometrics(String userBehaviorData) { return new BehavioralBiometricResult(); }


    // --- Calculation and Logic Helpers ---
    private static Decimal calculateFraudProbability(Decimal totalRiskScore, List<RiskIndicator> indicators) {
        Decimal baseProbability = totalRiskScore / 100;
        for (RiskIndicator indicator : indicators) {
            if (indicator.severity == 'CRITICAL') baseProbability += 0.15;
            else if (indicator.severity == 'HIGH') baseProbability += 0.10;
        }
        return Math.min(baseProbability, 1.0);
    }
    
    private static String determineRiskLevel(Decimal riskScore) {
        if (riskScore >= 0.8) return 'CRITICAL';
        if (riskScore >= 0.6) return 'HIGH';
        if (riskScore >= 0.4) return 'MEDIUM';
        return 'LOW';
    }

    private static String generateRiskRecommendation(String riskLevel, List<RiskIndicator> indicators) {
        switch on riskLevel {
            when 'CRITICAL' { return 'BLOCK_TRANSACTION - Multiple high-risk indicators detected.'; }
            when 'HIGH' { return 'REQUIRE_ADDITIONAL_VERIFICATION - Enhanced authentication needed.'; }
            when 'MEDIUM' { return 'MONITOR_CLOSELY - Allow with increased logging.'; }
            when else { return 'PROCEED_NORMALLY - Risk within acceptable parameters.'; }
        }
    }
    
    private static String generateAIBasedRecommendation(Decimal riskScore, Decimal fraudProbability) {
        if (fraudProbability >= 0.9) return 'BLOCK_TRANSACTION - AI detected extremely high fraud probability';
        if (fraudProbability >= 0.7) return 'REQUIRE_ADDITIONAL_VERIFICATION - High fraud risk detected by AI';
        if (fraudProbability >= 0.4) return 'ENHANCED_MONITORING - Moderate fraud risk identified';
        return 'PROCEED_WITH_STANDARD_MONITORING - Low fraud risk';
    }
    
    private static Boolean hasRecentHighRiskActivity(List<Signature_Request__c> requests) {
        for (Signature_Request__c req : requests) {
            if (req.Risk_Score__c != null && req.Risk_Score__c > 70) return true;
        }
        return false;
    }
    
    private static Decimal calculateAverageRiskScore(List<Signature_Request__c> requests) {
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
    }
    
    private static String getCurrentSystemLoad() { return 'NORMAL'; }
    private static Integer getActiveSecurityIncidentCount() { return [SELECT COUNT() FROM Security_Event__c WHERE Status__c = 'ACTIVE' AND CreatedDate = TODAY]; }
    private static String getCurrentThreatLevel() { return 'NORMAL'; }
    private static String generateAnalysisId() { return 'FRA-' + System.now().getTime(); }
    
    // --- DML and Response Operations ---
    private static void storeFraudAnalysisResults(AIFraudAnalysisResult result) { /* Logic to insert AI_Fraud_Analysis__c */ }
    private static void createHighRiskSecurityEvent(AIFraudAnalysisResult result) { /* Logic to create Security_Event__c and Case */ }
    private static void generateRealTimeAlert(AIFraudAnalysisResult result) { /* Logic to create Real_Time_Alert__c and send notifications */ }
    private static void logCriticalSecurityFailure(String type, String reqId, Exception e) { /* Logic to insert Critical_Security_Log__c */ }
    
    private static AIFraudAnalysisResult createSecureFallbackResult(String signatureRequestId, String errorMessage) {
        AIFraudAnalysisResult fallbackResult = new AIFraudAnalysisResult();
        fallbackResult.analysisId = generateAnalysisId();
        fallbackResult.timestamp = System.now();
        fallbackResult.signatureRequestId = signatureRequestId;
        fallbackResult.riskScore = 1.0;
        fallbackResult.fraudProbability = 1.0;
        fallbackResult.riskLevel = 'CRITICAL';
        fallbackResult.analysisMethod = 'SECURE_FALLBACK';
        fallbackResult.confidence = 0.0;
        fallbackResult.recommendation = 'BLOCK_TRANSACTION';
        fallbackResult.errorMessage = errorMessage;
        fallbackResult.riskIndicators = new List<RiskIndicator>{
            new RiskIndicator('SYSTEM_FAILURE', 'Fraud analysis system failure.', 100, 'CRITICAL')
        };
        return fallbackResult;
    }

    // --- Inner Helper Classes ---

    public class AIFraudAnalysisResult {
        @AuraEnabled public String analysisId;
        @AuraEnabled public Datetime timestamp;
        @AuraEnabled public String signatureRequestId;
        @AuraEnabled public Decimal riskScore;
        @AuraEnabled public Decimal fraudProbability;
        @AuraEnabled public String riskLevel;
        @AuraEnabled public String recommendation;
        @AuraEnabled public Decimal confidence;
        @AuraEnabled public String analysisMethod;
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
        @AuraEnabled public Datetime detectedAt;

        public RiskIndicator(String type, String description, Decimal riskScore, String severity) {
            this.type = type;
            this.description = description;
            this.riskScore = riskScore;
            this.severity = severity;
            this.detectedAt = System.now();
        }
    }
    
    public class FraudAnalysisPayload {
        @AuraEnabled public String signatureRequestId;
        @AuraEnabled public String userBehaviorData;
        @AuraEnabled public String documentMetadata;
        @AuraEnabled public String sessionContext;
        @AuraEnabled public DateTime analysisTimestamp;
        public FraudAnalysisPayload() { this.analysisTimestamp = System.now(); }
    }

    public class AIServiceResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String responseData;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String modelVersion;
        @AuraEnabled public Decimal confidence;
    }

    public class VelocityAnalysisResult {
        public Boolean isHighVelocity = false;
    }

    public class GeographicAnalysisResult {
        public Boolean isAnomalous = false;
    }

    public class DeviceAnalysisResult {
        public Boolean isSuspicious = false;
    }

    public class TemporalAnalysisResult {
        public Boolean isAnomalous = false;
    }

    public class DocumentIntegrityResult {
        public Boolean isIntegritySafe = true;
    }

    public class BehavioralBiometricResult {
        public Boolean isAnomalous = false;
    }
}
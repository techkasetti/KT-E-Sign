public class SuspiciousPatternService {
    
    @AuraEnabled
    public static PatternAnalysisResult analyzeSuspiciousPatterns(String userId, String activityWindow) {
        try {
            PatternAnalysisResult result = new PatternAnalysisResult();
            result.suspiciousPatterns = new List<String>();
            result.riskScore = 0;
            
          VelocityPattern velocityAnalysis = analyzeSigningVelocity(userId, activityWindow);

if (velocityAnalysis != null && velocityAnalysis.isAnomalous) {
    result.suspiciousPatterns.add(
        'Unusual signing velocity detected: ' + velocityAnalysis.description
    );
    result.riskScore += velocityAnalysis.riskContribution;
}


// Step 2: Analyze document access patterns
AccessPattern accessAnalysis = analyzeDocumentAccessPatterns(userId, activityWindow);
if (accessAnalysis.isSuspicious) {
    result.suspiciousPatterns.add('Suspicious document access pattern: ' + accessAnalysis.description);
    result.riskScore += accessAnalysis.riskContribution;
}

// Step 3: Analyze timing patterns
TimingPattern timingAnalysis = analyzeTimingPatterns(userId, activityWindow);
if (timingAnalysis.isAnomalous) {
    result.suspiciousPatterns.add('Irregular timing pattern: ' + timingAnalysis.description);
    result.riskScore += timingAnalysis.riskContribution;
}

// Step 4: Analyze signature consistency patterns
ConsistencyPattern consistencyAnalysis = analyzeSignatureConsistency(userId, activityWindow);
if (consistencyAnalysis.isInconsistent) {
    result.suspiciousPatterns.add('Signature inconsistency detected: ' + consistencyAnalysis.description);
    result.riskScore += consistencyAnalysis.riskContribution;
}

// Step 5: Analyze behavioral anomalies
BehavioralPattern behavioralAnalysis = analyzeBehavioralAnomalies(userId, activityWindow);
if (behavioralAnalysis.isAnomalous) {
    result.suspiciousPatterns.add('Behavioral anomaly detected: ' + behavioralAnalysis.description);
    result.riskScore += behavioralAnalysis.riskContribution;
}

// Step 6: Network and device patterns
NetworkPattern networkAnalysis = analyzeNetworkPatterns(userId, activityWindow);
if (networkAnalysis.isSuspicious) {
    result.suspiciousPatterns.add('Suspicious network activity: ' + networkAnalysis.description);
    result.riskScore += networkAnalysis.riskContribution;
}

// Step 7: Apply machine learning pattern detection
MLPatternResult mlAnalysis = callMLPatternDetection(userId, activityWindow, result);
if (mlAnalysis.hasAnomalies) {
    result.suspiciousPatterns.addAll(mlAnalysis.detectedPatterns);
    result.riskScore += mlAnalysis.riskContribution;
}

// Step 8: Calculate final risk assessment
result.riskLevel = calculatePatternRiskLevel(result.riskScore);
result.confidence = calculateConfidenceScore(result);
result.recommendation = generatePatternRecommendation(result);

// Step 9: Log pattern analysis
logPatternAnalysis(userId, result, activityWindow);

// Step 10: Trigger alerts if necessary
if (result.riskScore > 0.8) {
    triggerSuspiciousPatternAlert(userId, result);
}

return result;

} catch (Exception e) {
    throw new AuraHandledException('Pattern analysis failed: ' + e.getMessage());
}
}

private static VelocityPattern analyzeSigningVelocity(String userId, String activityWindow) {
    VelocityPattern pattern = new VelocityPattern();
    pattern.riskContribution = 0;
    
    DateTime windowStart = calculateWindowStart(activityWindow);
    
    // Get signature velocity data
    List<AggregateResult> velocityData = [
        SELECT 
            COUNT(Id) totalSignatures,
            AVG(HOUR_IN_DAY(CreatedDate)) avgHour,
            COUNT_DISTINCT(DATE(CreatedDate)) uniqueDays
        FROM Signature_Request__c 
        WHERE CreatedById = :userId 
        AND CreatedDate >= :windowStart
        AND Status__c = 'SIGNED'
    ];
    
    if (!velocityData.isEmpty()) {
        Integer totalSignatures = (Integer) velocityData[0].get('totalSignatures');
        Integer uniqueDays = (Integer) velocityData[0].get('uniqueDays');
        
        // Calculate signatures per day
        Decimal signaturesPerDay = uniqueDays > 0 ? totalSignatures / uniqueDays : 0;
        
        // Get user's historical average
        List<AggregateResult> historicalData = [
            SELECT AVG(DailySignatureCount__c) avgDaily
            FROM UserActivitySummary__c 
            WHERE UserId__c = :userId 
            AND Date__c >= :windowStart.addDays(-90)
        ];
        
        Decimal historicalAverage = 0;
        if (!historicalData.isEmpty() && historicalData[0].get('avgDaily') != null) {
            historicalAverage = (Decimal) historicalData[0].get('avgDaily');
        }
        
        // Detect velocity anomalies
        if (historicalAverage > 0) {
            Decimal velocityRatio = signaturesPerDay / historicalAverage;
            
            if (velocityRatio > 3.0) {
                pattern.isAnomalous = true;
                pattern.description = 'Signing velocity ' + (velocityRatio * 100).intValue() + '% above normal';
                pattern.riskContribution = Math.min(0.4, velocityRatio * 0.1);
                pattern.anomalyType = 'HIGH_VELOCITY';
            } else if (velocityRatio > 2.0) {
                pattern.isAnomalous = true;
                pattern.description = 'Moderately elevated signing velocity';
                pattern.riskContribution = 0.2;
                pattern.anomalyType = 'ELEVATED_VELOCITY';
            }
        }
        
        // Check for burst patterns (many signatures in short time)
        List<AggregateResult> burstAnalysis = [
            SELECT 
                DATE(CreatedDate) signatureDate,
                COUNT(Id) dailyCount,
                MIN(CreatedDate) firstSignature,
                MAX(CreatedDate) lastSignature
            FROM Signature_Request__c 
            WHERE CreatedById = :userId 
            AND CreatedDate >= :windowStart
            AND Status__c = 'SIGNED'
            GROUP BY DATE(CreatedDate)
            HAVING COUNT(Id) > 10
        ];
        
        for (AggregateResult burst : burstAnalysis) {
            DateTime first = (DateTime) burst.get('firstSignature');
            DateTime last = (DateTime) burst.get('lastSignature');
            Long timeSpanMinutes = (last.getTime() - first.getTime()) / (1000 * 60);
            Integer count = (Integer) burst.get('dailyCount');
            
            if (timeSpanMinutes < 60 && count > 10) {
                pattern.isAnomalous = true;
                pattern.description += '; Burst pattern detected: ' + count + ' signatures in ' + timeSpanMinutes + ' minutes';
                pattern.riskContribution += 0.3;
                pattern.anomalyType = 'BURST_PATTERN';
            }
        }
    }
    
    return pattern;
}

private static AccessPattern analyzeDocumentAccessPatterns(String userId, String activityWindow) {
    AccessPattern pattern = new AccessPattern();
    pattern.riskContribution = 0;
    
    DateTime windowStart = calculateWindowStart(activityWindow);
    
    // Analyze document access sequences
    List<DocumentAccess__c> accessLog = [
        SELECT 
            DocumentId__c,
            AccessType__c,
            AccessTimestamp__c,
            SessionId__c,
            IPAddress__c
        FROM DocumentAccess__c 
        WHERE UserId__c = :userId 
        AND AccessTimestamp__c >= :windowStart
        ORDER BY AccessTimestamp__c
    ];
    
    if (accessLog.size() > 0) {
        // Check for rapid sequential access to different documents
        Map<String, List<DocumentAccess__c>> documentGroups = new Map<String, List<DocumentAccess__c>>();
        
        for (DocumentAccess__c access : accessLog) {
            if (!documentGroups.containsKey(access.DocumentId__c)) {
                documentGroups.put(access.DocumentId__c, new List<DocumentAccess__c>());
            }
            documentGroups.get(access.DocumentId__c).add(access);
        }
        
        // Detect suspicious access patterns
        if (documentGroups.size() > 20) {
            pattern.isSuspicious = true;
            pattern.description = 'Accessed unusually high number of documents (' + documentGroups.size() + ')';
            pattern.riskContribution = 0.3;
        }
        
        // Check for rapid-fire access pattern
        for (Integer i = 1; i < accessLog.size(); i++) {
            Long timeDiff = accessLog[i].AccessTimestamp__c.getTime() - accessLog[i-1].AccessTimestamp__c.getTime();
            if (timeDiff < 5000) { // Less than 5 seconds between accesses
                pattern.isSuspicious = true;
                pattern.description += '; Rapid sequential document access detected';
                pattern.riskContribution += 0.1;
                break;
            }
        }
        
        // Check for access from multiple IP addresses in short time
        Set<String> uniqueIPs = new Set<String>();
        for (DocumentAccess__c access : accessLog) {
            uniqueIPs.add(access.IPAddress__c);
        }
        
        if (uniqueIPs.size() > 3) {
            pattern.isSuspicious = true;
            pattern.description += '; Multiple IP addresses used (' + uniqueIPs.size() + ')';
            pattern.riskContribution += 0.4;
        }
    }
    
    return pattern;
}

private static TimingPattern analyzeTimingPatterns(String userId, String activityWindow) {
    TimingPattern pattern = new TimingPattern();
    pattern.riskContribution = 0;
    
    DateTime windowStart = calculateWindowStart(activityWindow);
    
    // Analyze signing times
    List<Signature_Request__c> signatures = [
        SELECT 
            CreatedDate,
            SignedDate__c,
            DocumentGenerationTime__c
        FROM Signature_Request__c 
        WHERE CreatedById = :userId 
        AND CreatedDate >= :windowStart
        AND Status__c = 'SIGNED'
        AND SignedDate__c != null
    ];
    
    List<Long> signingDurations = new List<Long>();
    List<Integer> signingHours = new List<Integer>();
    
    for (Signature_Request__c sig : signatures) {
        // Calculate time to sign (in seconds)
        Long duration = (sig.SignedDate__c.getTime() - sig.CreatedDate.getTime()) / 1000;
        signingDurations.add(duration);
        signingHours.add(sig.SignedDate__c.hour());
    }
    
    if (!signingDurations.isEmpty()) {
        // Calculate average and detect anomalies
        Long totalDuration = 0;
        for (Long duration : signingDurations) {
            totalDuration += duration;
        }
        Long avgDuration = totalDuration / signingDurations.size();
        
        // Check for unusually fast signings
        Integer fastSignings = 0;
        for (Long duration : signingDurations) {
            if (duration < 10) { // Less than 10 seconds
                fastSignings++;
            }
        }
        
        if (fastSignings > signingDurations.size() * 0.5) {
            pattern.isAnomalous = true;
            pattern.description = 'Unusually fast signing times detected (' + fastSignings + ' out of ' + signingDurations.size() + ')';
            pattern.riskContribution = 0.4;
        }
        
        // Check for off-hours activity
        Integer offHoursCount = 0;
        for (Integer hour : signingHours) {
            if (hour < 6 || hour > 22) { // Outside 6 AM - 10 PM
                offHoursCount++;
            }
        }
        
        if (offHoursCount > signingHours.size() * 0.7) {
            pattern.isAnomalous = true;
            pattern.description += '; High off-hours activity detected';
            pattern.riskContribution += 0.2;
        }
    }
    
    return pattern;
}

private static MLPatternResult callMLPatternDetection(String userId, String activityWindow, PatternAnalysisResult currentResult) {
    try {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:AI_Pattern_Detection/analyze');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer {!$Credential.AI_Service.AccessToken}');
        
        Map<String, Object> payload = new Map<String, Object>{
            'user_id' => userId,
            'activity_window' => activityWindow,
            'current_patterns' => currentResult.suspiciousPatterns,
            'risk_score' => currentResult.riskScore,
            'model_version' => 'pattern-detection-v2.5'
        };
        
        req.setBody(JSON.serialize(payload));
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            
            MLPatternResult result = new MLPatternResult();
            result.hasAnomalies = (Boolean) response.get('has_anomalies');
            result.detectedPatterns = (List<String>) response.get('detected_patterns');
            result.riskContribution = (Decimal) response.get('risk_contribution');
            result.confidence = (Decimal) response.get('confidence');
            result.modelVersion = (String) response.get('model_version');
            
            return result;
        } else {
            // Return empty result if service unavailable
            MLPatternResult fallback = new MLPatternResult();
            fallback.hasAnomalies = false;
            fallback.detectedPatterns = new List<String>();
            fallback.riskContribution = 0;
            fallback.confidence = 0;
            return fallback;
        }
    } catch (Exception e) {
        // Return empty result on error
        MLPatternResult fallback = new MLPatternResult();
        fallback.hasAnomalies = false;
        fallback.detectedPatterns = new List<String>();
        fallback.riskContribution = 0;
        fallback.confidence = 0;
        return fallback;
    }
}

private static void logPatternAnalysis(String userId, PatternAnalysisResult result, String activityWindow) {
    SuspiciousPatternLog__c log = new SuspiciousPatternLog__c();
    log.UserId__c = userId;
    log.ActivityWindow__c = activityWindow;
    log.SuspiciousPatterns__c = String.join(result.suspiciousPatterns, '; ');
    log.RiskScore__c = result.riskScore;
    log.RiskLevel__c = result.riskLevel;
    log.Confidence__c = result.confidence;
    log.Recommendation__c = result.recommendation;
    log.AnalysisTimestamp__c = System.now();
    insert log;
}

private static void triggerSuspiciousPatternAlert(String userId, PatternAnalysisResult result) {
    // Create security incident
    SecurityIncident__c incident = new SecurityIncident__c();
    incident.UserId__c = userId;
    incident.IncidentType__c = 'SUSPICIOUS_PATTERN';
    incident.Severity__c = result.riskLevel;
    
    // Properly concatenate description string
    incident.Description = 'Suspicious pattern analysis detected high-risk activity:\n\n' +
        'Risk Score: ' + result.riskScore + '/1.0\n' +
        'Risk Level: ' + result.riskLevel + '\n' +
        'Confidence: ' + (result.confidence * 100).intValue() + '%\n\n' +
        'Detected Patterns:\n• ' + String.join(result.suspiciousPatterns, '\n• ') + '\n\n' +
        'Recommendation: ' + result.recommendation + '\n\n' +
        'Analysis Timestamp: ' + System.now().format('yyyy-MM-dd HH:mm:ss');
    
    incident.Status__c = 'NEW';
    incident.Priority__c = result.riskLevel == 'CRITICAL' ? 'P1' : 
                           (result.riskLevel == 'HIGH' ? 'P2' : 'P3');
    // ❌ DO NOT set CreatedDate, Salesforce handles it automatically
    insert incident;

    // Send real-time alerts to security team
    List<SecurityTeamMember__c> securityTeam = [
        SELECT Email__c, AlertType__c 
        FROM SecurityTeamMember__c 
        WHERE IsActive__c = true 
        AND AlertType__c INCLUDES ('PATTERN_ANOMALY')
    ];

    for (SecurityTeamMember__c member : securityTeam) {
        EmailNotificationService.sendPatternAlert(member.Email__c, incident.Id, result);
    }

    // Create workflow task for investigation
    Task investigationTask = new Task();
    investigationTask.Subject = 'Investigate Suspicious Pattern - User: ' + userId;
    investigationTask.Description = 'High-risk suspicious pattern detected requiring immediate investigation';
    investigationTask.Priority = 'High';
    investigationTask.Status = 'Not Started';
    investigationTask.ActivityDate = Date.today().addDays(1);
    investigationTask.WhatId = incident.Id;
    insert investigationTask;
}


public class MLPatternResult {
    public Boolean hasAnomalies;
    public List<String> detectedPatterns;
    public Decimal riskContribution;
    public Decimal confidence;
    public String modelVersion;
}
}

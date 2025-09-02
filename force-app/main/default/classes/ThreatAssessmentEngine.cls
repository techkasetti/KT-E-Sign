public class ThreatAssessmentEngine {
    private static final Map<String, Decimal> THREAT_WEIGHTS = new Map<String, Decimal>{
        'IDENTITY_SPOOFING' => 0.95,
        'DOCUMENT_TAMPERING' => 0.90,
        'CREDENTIAL_STUFFING' => 0.85,
        'SESSION_HIJACKING' => 0.80,
        'SOCIAL_ENGINEERING' => 0.75,
        'INSIDER_THREAT' => 0.70,
        'MALWARE_DETECTION' => 0.65,
        'PHISHING_ATTEMPT' => 0.60
    };

    @AuraEnabled(cacheable=false)
    public static ThreatAssessmentResult assessComprehensiveThreat(
        String signatureRequestId,
        String userContext,
        String systemContext,
        String networkContext
    ) {
        ThreatAssessmentResult result = new ThreatAssessmentResult();
        try {
            result.assessmentId = generateThreatAssessmentId();
            result.timestamp = System.now();
            result.signatureRequestId = signatureRequestId;

            System.debug('Starting comprehensive threat assessment for: ' + signatureRequestId);

            IdentityThreatResult identityThreats = assessIdentityThreats(userContext, signatureRequestId);
            result.identityThreatScore = identityThreats.threatScore;
            result.detectedThreats.addAll(identityThreats.threats);

            DocumentThreatResult documentThreats = assessDocumentThreats(signatureRequestId, systemContext);
            result.documentThreatScore = documentThreats.threatScore;
            result.detectedThreats.addAll(documentThreats.threats);

            NetworkThreatResult networkThreats = assessNetworkThreats(networkContext, userContext);
            result.networkThreatScore = networkThreats.threatScore;
            result.detectedThreats.addAll(networkThreats.threats);

            BehavioralThreatResult behavioralThreats = assessBehavioralThreats(userContext, signatureRequestId);
            result.behavioralThreatScore = behavioralThreats.threatScore;
            result.detectedThreats.addAll(behavioralThreats.threats);

            APTThreatResult aptThreats = assessAPTThreats(userContext, systemContext, networkContext);
            result.aptThreatScore = aptThreats.threatScore;
            result.detectedThreats.addAll(aptThreats.threats);

            result = calculateOverallThreatScore(result);
            result = determineThreatLevel(result);
            result = generateThreatRecommendations(result);

            storeThreatAssessment(result);

            if (result.overallThreatScore >= 0.8) {
                triggerHighThreatResponse(result);
            }

            System.debug('✓ Comprehensive threat assessment completed. Overall score: ' + result.overallThreatScore);
            return result;
        } catch (Exception e) {
            System.debug('Comprehensive threat assessment error: ' + e.getMessage());
            return createMaximumSecurityThreatResult(signatureRequestId, e.getMessage());
        }
    }

    private static IdentityThreatResult assessIdentityThreats(String userContext, String signatureRequestId) {
        IdentityThreatResult result = new IdentityThreatResult();
        try {
            Map<String, Object> userMap = (Map<String, Object>) JSON.deserializeUntyped(userContext);
            String userId = (String) userMap.get('userId');
            String deviceFingerprint = (String) userMap.get('deviceFingerprint');
            String biometricData = (String) userMap.get('biometricData');

            result.threats = new List<ThreatIndicator>();

            if (detectIdentitySpoofing(userId, deviceFingerprint, biometricData)) {
                ThreatIndicator spoofingThreat = new ThreatIndicator(
                    'IDENTITY_SPOOFING',
                    'Potential identity spoofing detected through biometric analysis',
                    THREAT_WEIGHTS.get('IDENTITY_SPOOFING'),
                    'CRITICAL'
                );
                result.threats.add(spoofingThreat);
            }

            if (detectCredentialStuffing(userId, userMap)) {
                ThreatIndicator credentialThreat = new ThreatIndicator(
                    'CREDENTIAL_STUFFING',
                    'Automated credential testing detected',
                    THREAT_WEIGHTS.get('CREDENTIAL_STUFFING'),
                    'HIGH'
                );
                result.threats.add(credentialThreat);
            }

            if (detectAccountTakeoverSigns(userId, userMap)) {
                ThreatIndicator takeoverThreat = new ThreatIndicator(
                    'ACCOUNT_TAKEOVER',
                    'Account takeover indicators present',
                    0.88,
                    'CRITICAL'
                );
                result.threats.add(takeoverThreat);
            }

            result.threatScore = calculateIdentityThreatScore(result.threats);
        } catch (Exception e) {
            System.debug('Identity threat assessment error: ' + e.getMessage());
            result.threatScore = 1.0;
        }
        return result;
    }

    private static Boolean detectIdentitySpoofing(String userId, String deviceFingerprint, String biometricData) {
        try {
            if (String.isNotBlank(biometricData)) {
                BiometricAnalysisResult biometricResult = analyzeBiometricConsistency(userId, biometricData);
                if (!biometricResult.isConsistent) {
                    return true;
                }
            }

            if (String.isNotBlank(deviceFingerprint)) {
                List<TrustedDevice__c> userDevices = [
                    SELECT DeviceFingerprint__c, TrustLevel__c, LastUsed__c
                    FROM TrustedDevice__c
                    WHERE UserId__c = :userId
                    AND IsActive__c = true
                ];
                Boolean deviceMatch = false;
                for (TrustedDevice__c device : userDevices) {
                    if (device.DeviceFingerprint__c.equals(deviceFingerprint)) {
                        deviceMatch = true;
                        break;
                    }
                }
                if (!deviceMatch && !userDevices.isEmpty()) {
                    return true;
                }
            }

           Datetime twoHoursAgo = System.now().addHours(-2);

List<AuthSession> recentSessions = [
    SELECT UserId, CreatedDate, SourceIp
    FROM AuthSession
    WHERE UserId = :userId
    AND CreatedDate >= :twoHoursAgo
    ORDER BY CreatedDate DESC
    LIMIT 5
];

            if (recentSessions.size() > 1) {
                Set<String> ipAddresses = new Set<String>();
                for (AuthSession session : recentSessions) {
                    ipAddresses.add(session.SourceIp);
                }
                if (ipAddresses.size() > 2) {
                    return true;
                }
            }
            return false;
        } catch (Exception e) {
            System.debug('Identity spoofing detection error: ' + e.getMessage());
            return true;
        }
    }

    private static Boolean detectCredentialStuffing(String userId, Map<String, Object> userContext) {
        try {
            String ipAddress = (String) userContext.get('ipAddress');
            if (String.isNotBlank(ipAddress)) {
              Datetime twoHoursAgo = System.now().addHours(-2);

List<AuthSession> recentSessions = [
    SELECT UserId, CreatedDate, SourceIp
    FROM AuthSession
    WHERE UserId = :userId
    AND CreatedDate >= :twoHoursAgo
    ORDER BY CreatedDate DESC
    LIMIT 5
];

                Integer failedAttempts = 0;
                Set<String> attemptedUsers = new Set<String>();
                for (LoginHistory login : recentLogins) {
                    if (login.Status != 'Success') {
                        failedAttempts++;
                    }
                    attemptedUsers.add(login.UserId);
                }
                if (failedAttempts > 5 || attemptedUsers.size() > 3) {
                    return true;
                }
            }

            Object mouseMovements = userContext.get('mouseMovements');
            Object keystrokes = userContext.get('keystrokes');
            if (mouseMovements == null && keystrokes == null) {
                return true;
            }
            return false;
        } catch (Exception e) {
            System.debug('Credential stuffing detection error: ' + e.getMessage());
            return true;
        }
    }

    private static Boolean detectAccountTakeoverSigns(String userId, Map<String, Object> userContext) {
        try {
            String currentLocation = (String) userContext.get('ipLocation');
            String userAgent = (String) userContext.get('userAgent');

            if (String.isNotBlank(userId)) {
                List<UserBehaviorMetrics__c> behaviorHistory = [
                    SELECT Typical_Access_Hours__c, Common_Locations__c, 
                           Usual_User_Agents__c, Average_Session_Duration__c
                    FROM UserBehaviorMetrics__c
                    WHERE UserId__c = :userId
                    AND CreatedDate = LAST_N_DAYS:30
                    ORDER BY CreatedDate DESC
                    LIMIT 10
                ];
                if (!behaviorHistory.isEmpty()) {
                    UserBehaviorMetrics__c baseline = behaviorHistory[0];
                    if (String.isNotBlank(currentLocation) && String.isNotBlank(baseline.Common_Locations__c)) {
                        if (!baseline.Common_Locations__c.contains(currentLocation)) {
                            return true;
                        }
                    }
                    if (String.isNotBlank(userAgent) && String.isNotBlank(baseline.Usual_User_Agents__c)) {
                        if (!baseline.Usual_User_Agents__c.contains(userAgent)) {
                            return true;
                        }
                    }
                }

                List<PermissionSetAssignment> recentPermissions = [
                    SELECT PermissionSetId, AssigneeId, SystemModstamp
                    FROM PermissionSetAssignment
                    WHERE AssigneeId = :userId
                    AND SystemModstamp = TODAY
                ];
                if (!recentPermissions.isEmpty()) {
                    return true;
                }
            }
            return false;
        } catch (Exception e) {
            System.debug('Account takeover detection error: ' + e.getMessage());
            return false;
        }
    }

    private static Decimal calculateIdentityThreatScore(List<ThreatIndicator> threats) {
        try {
            if (threats.isEmpty()) return 0.0;
            Decimal totalScore = 0.0;
            for (ThreatIndicator threat : threats) {
                totalScore += threat.riskScore;
            }
            Decimal averageScore = totalScore / threats.size();
            Decimal scalingFactor = 1.0 - (0.1 * (threats.size() - 1));
            return Math.min(averageScore * Math.max(scalingFactor, 0.5), 1.0);
        } catch (Exception e) {
            System.debug('Identity threat score calculation error: ' + e.getMessage());
            return 1.0;
        }
    }

    private static Decimal calculateDocumentThreatScore(List<ThreatIndicator> threats) {
        try {
            if (threats.isEmpty()) return 0.0;
            Decimal maxScore = 0.0;
            for (ThreatIndicator threat : threats) {
                if (threat.riskScore > maxScore) {
                    maxScore = threat.riskScore;
                }
            }
            return maxScore;
        } catch (Exception e) {
            System.debug('Document threat score calculation error: ' + e.getMessage());
            return 1.0;
        }
    }

    private static Decimal calculateNetworkThreatScore(List<ThreatIndicator> threats) {
        try {
            if (threats.isEmpty()) return 0.0;
            Decimal weightedScore = 0.0;
            Decimal totalWeight = 0.0;
            for (ThreatIndicator threat : threats) {
                Decimal weight = getNetworkThreatWeight(threat.type);
                weightedScore += (threat.riskScore * weight);
                totalWeight += weight;
            }
            return totalWeight > 0 ? weightedScore / totalWeight : 0.0;
        } catch (Exception e) {
            System.debug('Network threat score calculation error: ' + e.getMessage());
            return 0.7;
        }
    }

    private static Decimal calculateBehavioralThreatScore(List<ThreatIndicator> threats) {
        try {
            if (threats.isEmpty()) return 0.0;
            Decimal cumulativeScore = 0.0;
            for (ThreatIndicator threat : threats) {
                cumulativeScore += threat.riskScore;
            }
            return Math.min(cumulativeScore, 1.0);
        } catch (Exception e) {
            System.debug('Behavioral threat score calculation error: ' + e.getMessage());
            return 0.6;
        }
    }

    private static Decimal calculateAPTThreatScore(List<ThreatIndicator> threats) {
        try {
            if (threats.isEmpty()) return 0.0;
            Decimal baseScore = 0.0;
            Integer threatCount = 0;
            for (ThreatIndicator threat : threats) {
                baseScore += threat.riskScore;
                threatCount++;
            }
            if (threatCount > 1) {
                baseScore *= Math.pow(1.5, threatCount - 1);
            }
            return Math.min(baseScore / threatCount, 1.0);
        } catch (Exception e) {
            System.debug('APT threat score calculation error: ' + e.getMessage());
            return 0.9;
        }
    }

    private static ThreatAssessmentResult calculateOverallThreatScore(ThreatAssessmentResult result) {
        try {
            Map<String, Decimal> categoryWeights = new Map<String, Decimal>{
                'identity' => 0.25,
                'document' => 0.30,
                'network' => 0.15,
                'behavioral' => 0.15,
                'apt' => 0.15
            };
            Decimal weightedScore = 0.0;
            weightedScore += (result.identityThreatScore * categoryWeights.get('identity'));
            weightedScore += (result.documentThreatScore * categoryWeights.get('document'));
            weightedScore += (result.networkThreatScore * categoryWeights.get('network'));
            weightedScore += (result.behavioralThreatScore * categoryWeights.get('behavioral'));
            weightedScore += (result.aptThreatScore * categoryWeights.get('apt'));
            result.overallThreatScore = Math.min(weightedScore, 1.0);
            System.debug('Overall threat score calculated: ' + result.overallThreatScore);
            return result;
        } catch (Exception e) {
            System.debug('Overall threat score calculation error: ' + e.getMessage());
            result.overallThreatScore = 1.0;
            return result;
        }
    }

    private static ThreatAssessmentResult determineThreatLevel(ThreatAssessmentResult result) {
        try {
            if (result.overallThreatScore >= 0.9) {
                result.threatLevel = 'CRITICAL';
                result.requiresImmediateAction = true;
            } else if (result.overallThreatScore >= 0.7) {
                result.threatLevel = 'HIGH';
                result.requiresImmediateAction = true;
            } else if (result.overallThreatScore >= 0.5) {
                result.threatLevel = 'MEDIUM';
                result.requiresImmediateAction = false;
            } else if (result.overallThreatScore >= 0.3) {
                result.threatLevel = 'LOW';
                result.requiresImmediateAction = false;
            } else {
                result.threatLevel = 'MINIMAL';
                result.requiresImmediateAction = false;
            }
            System.debug('Threat level determined: ' + result.threatLevel);
            return result;
        } catch (Exception e) {
            System.debug('Threat level determination error: ' + e.getMessage());
            result.threatLevel = 'CRITICAL';
            result.requiresImmediateAction = true;
            return result;
        }
    }

    private static ThreatAssessmentResult generateThreatRecommendations(ThreatAssessmentResult result) {
        try {
            result.recommendations = new List<String>();
            switch on result.threatLevel {
                when 'CRITICAL' {
                    result.recommendations.add('IMMEDIATE BLOCK - Deny all signature requests from this source');
                    result.recommendations.add('SECURITY ESCALATION - Alert security team immediately');
                    result.recommendations.add('FORENSIC ANALYSIS - Preserve all logs and evidence');
                    result.recommendations.add('USER LOCKOUT - Disable user account pending investigation');
                    result.recommendations.add('NETWORK ISOLATION - Consider IP blocking');
                }
                when 'HIGH' {
                    result.recommendations.add('ENHANCED VERIFICATION - Require additional authentication');
                    result.recommendations.add('MANUAL REVIEW - All signature requests require approval');
                    result.recommendations.add('INCREASED MONITORING - Enable detailed audit logging');
                    result.recommendations.add('SECURITY NOTIFICATION - Alert security analysts');
                    result.recommendations.add('SESSION LIMITATION - Restrict concurrent sessions');
                }
                when 'MEDIUM' {
                    result.recommendations.add('ADDITIONAL AUTHENTICATION - Consider step-up authentication');
                    result.recommendations.add('ENHANCED LOGGING - Increase audit detail level');
                    result.recommendations.add('MONITORING ALERT - Schedule review within 4 hours');
                    result.recommendations.add('DOCUMENT VERIFICATION - Verify document integrity');
                }
                when 'LOW' {
                    result.recommendations.add('STANDARD MONITORING - Continue normal security protocols');
                    result.recommendations.add('PERIODIC REVIEW - Schedule routine security check');
                    result.recommendations.add('LOG RETENTION - Ensure logs are preserved');
                }
                when 'MINIMAL' {
                    result.recommendations.add('NORMAL PROCESSING - Proceed with standard workflow');
                    result.recommendations.add('ROUTINE LOGGING - Standard audit trail sufficient');
                }
            }
            System.debug('Threat recommendations generated: ' + result.recommendations.size() + ' recommendations');
            return result;
        } catch (Exception e) {
            System.debug('Threat recommendations generation error: ' + e.getMessage());
            result.recommendations = new List<String>{'MANUAL REVIEW - Error in automated assessment'};
            return result;
        }
    }

    private static String calculateDocumentHash(String documentId) {
        try {
            return 'calculated_hash_placeholder_' + documentId;
        } catch (Exception e) {
            System.debug('Document hash calculation error: ' + e.getMessage());
            return null;
        }
    }

    private static String getDocumentContent(String documentId) {
        try {
            return 'document_content_placeholder';
        } catch (Exception e) {
            System.debug('Document content retrieval error: ' + e.getMessage());
            return null;
        }
    }

    private static Decimal compareFacialFeatures(String current, String baseline) {
        try {
            if (String.isBlank(current) || String.isBlank(baseline)) {
                return 0.0;
            }
            return 0.85;
        } catch (Exception e) {
            System.debug('Facial feature comparison error: ' + e.getMessage());
            return 0.0;
        }
    }




private static Decimal compareVoicePrint(String current, String baseline) {
    try {
        if (String.isBlank(current) || String.isBlank(baseline)) {
            return 0.0;
        }
        // Placeholder for actual voice print comparison
        return 0.80; // Mock moderate similarity
    } catch (Exception e) {
        System.debug('Voice print comparison error: ' + e.getMessage());
        return 0.0;
    }
}

private static Decimal compareTypingPattern(String current, String baseline) {
    try {
        if (String.isBlank(current) || String.isBlank(baseline)) {
            return 0.0;
        }
        // Placeholder for typing pattern comparison
        return 0.75; // Mock moderate similarity
    } catch (Exception e) {
        System.debug('Typing pattern comparison error: ' + e.getMessage());
        return 0.0;
    }
}

private static Boolean isInternalIP(String ipAddress) {
    try {
        if (String.isBlank(ipAddress)) return false; // Check for private IP ranges
        return ipAddress.startsWith('192.168.') ||
               ipAddress.startsWith('10.') ||
               ipAddress.startsWith('172.16.') ||
               ipAddress.startsWith('172.31.') ||
               ipAddress.equals('127.0.0.1');
    } catch (Exception e) {
        System.debug('Internal IP check error: ' + e.getMessage());
        return false;
    }
}

private static Boolean isDGADomain(String domain) {
    try {
        if (String.isBlank(domain)) return false; // Simple DGA detection - look for domains with high entropy
        Integer vowelCount = 0;
        Integer consonantCount = 0;
        String vowels = 'aeiou';
        for (Integer i = 0; i < domain.length(); i++) {
            String ch = domain.substring(i, i + 1).toLowerCase();
            if (vowels.contains(ch)) {
                vowelCount++;
            } else if (ch.isAlpha()) {
                consonantCount++;
            }
        }
        // DGA domains often have unusual vowel/consonant ratios
        Decimal ratio = consonantCount > 0 ? (Decimal) vowelCount / consonantCount : 0;
        return ratio < 0.2 || ratio > 2.0;
    } catch (Exception e) {
        System.debug('DGA domain detection error: ' + e.getMessage());
        return false;
    }
}

private static Boolean isKnownC2Domain(String domain) {
    try {
        if (String.isBlank(domain)) return false; // Check against known C2 domains database
        List<MaliciousDomain__c> c2Domains = [
            SELECT Domain__c
            FROM MaliciousDomain__c
            WHERE Domain__c = :domain
            AND ThreatType__c = 'C2_SERVER'
            AND IsActive__c = true
            LIMIT 1
        ];
        return !c2Domains.isEmpty();
    } catch (Exception e) {
        System.debug('Known C2 domain check error: ' + e.getMessage());
        return false;
    }
}

private static Boolean hasRegularIntervals(List<Long> intervals) {
    try {
        if (intervals.size() < 3) return false; // Calculate variance in intervals
        Long sum = 0;
        for (Long interval : intervals) {
            sum += interval;
        }
        Long average = sum / intervals.size();
        Long varianceSum = 0;
        for (Long interval : intervals) {
            varianceSum += Math.pow(interval - average, 2);
        }
        Long variance = varianceSum / intervals.size(); // Low variance indicates regular beaconing
        return variance < (average * 0.1); // Within 10% variance
    } catch (Exception e) {
        System.debug('Regular intervals detection error: ' + e.getMessage());
        return false;
    }
}

private static Decimal getNetworkThreatWeight(String threatType) {
    try {
        Map<String, Decimal> networkWeights = new Map<String, Decimal>{
            'TOR_NETWORK' => 0.9,
            'BOTNET_ACTIVITY' => 0.85,
            'DDOS_PATTERN' => 0.7,
            'VPN_PROXY_USAGE' => 0.4
        };
        return networkWeights.containsKey(threatType) ? networkWeights.get(threatType) : 0.5;
    } catch (Exception e) {
        System.debug('Network threat weight error: ' + e.getMessage());
        return 0.5;
    }
}

private static void storeThreatAssessment(ThreatAssessmentResult result) {
    try {
        // Store comprehensive threat assessment result
        Comprehensive_Threat_Assessment__c assessment = new Comprehensive_Threat_Assessment__c(
            Assessment_Id__c = result.assessmentId,
            Signature_Request_Id__c = result.signatureRequestId,
            Overall_Threat_Score__c = result.overallThreatScore * 100,
            Threat_Level__c = result.threatLevel,
            Identity_Score__c = result.identityThreatScore * 100,
            Document_Score__c = result.documentThreatScore * 100,
            Network_Score__c = result.networkThreatScore * 100,
            Behavioral_Score__c = result.behavioralThreatScore * 100,
            APT_Score__c = result.aptThreatScore * 100,
            Requires_Immediate_Action__c = result.requiresImmediateAction,
            Assessment_Timestamp__c = result.timestamp,
            Total_Threats_Detected__c = result.detectedThreats.size(),
            Recommendations__c = String.join(result.recommendations, '; ')
        );
        insert assessment;

        // Store individual threat indicators
        List<Threat_Indicator__c> threatRecords = new List<Threat_Indicator__c>();
        for (ThreatIndicator threat : result.detectedThreats) {
            Threat_Indicator__c threatRecord = new Threat_Indicator__c(
                Assessment_Id__c = result.assessmentId,
                Threat_Type__c = threat.type,
                Threat_Description__c = threat.description,
                Risk_Score__c = threat.riskScore * 100,
                Severity_Level__c = threat.severity,
                Detection_Timestamp__c = System.now()
            );
            threatRecords.add(threatRecord);
        }
        if (!threatRecords.isEmpty()) {
            insert threatRecords;
        }
        System.debug('✓ Threat assessment stored successfully');
    } catch (Exception e) {
        System.debug('Threat assessment storage error: ' + e.getMessage());
        // Continue processing even if storage fails
    }
}

private static void triggerHighThreatResponse(ThreatAssessmentResult result) {
    try {
        System.debug('Triggering high threat response for assessment: ' + result.assessmentId);

        // Create immediate security incident
        Security_Incident__c incident = new Security_Incident__c(
            Incident_Type__c = 'HIGH_THREAT_DETECTION',
            Related_Assessment__c = result.assessmentId,
            Signature_Request_Id__c = result.signatureRequestId,
            Threat_Level__c = result.threatLevel,
            Incident_Status__c = 'OPEN',
            Priority__c = result.threatLevel == 'CRITICAL' ? 'P1' : 'P2',
            Description__c = 'High threat level detected during signature process. Immediate investigation required.',
            Detection_Timestamp__c = System.now(),
            Auto_Generated__c = true
        );
        insert incident;

        // Create security workflow tasks
        List<Task> securityTasks = new List<Task>();

        // Task 1: Immediate threat containment
        Task containmentTask = new Task(
            Subject = 'URGENT: Threat Containment Required',
            Description = 'High threat level (' + result.threatLevel + ') detected. Implement immediate containment measures.',
            Priority = 'High',
            Status = 'Not Started',
            ActivityDate = Date.today(),
            WhatId = incident.Id,
            OwnerId = getSecurityTeamLeadId(),
            Task_Type__c = 'THREAT_CONTAINMENT'
        );
        securityTasks.add(containmentTask);

        // Task 2: Forensic analysis
        Task forensicTask = new Task(
            Subject = 'Forensic Analysis - Threat Assessment ' + result.assessmentId,
            Description = 'Conduct detailed forensic analysis of detected threats and attack vectors.',
            Priority = 'High',
            Status = 'Not Started',
            ActivityDate = Date.today().addDays(1),
            WhatId = incident.Id,
            OwnerId = getForensicAnalystId(),
            Task_Type__c = 'FORENSIC_ANALYSIS'
        );
        securityTasks.add(forensicTask);

        // Task 3: User investigation
        if (result.identityThreatScore > 0.7 || result.behavioralThreatScore > 0.7) {
            Task userInvestigationTask = new Task(
                Subject = 'User Security Investigation',
                Description = 'Investigate user account for potential compromise or insider threat.',
                Priority = 'High',
                Status = 'Not Started',
                ActivityDate = Date.today(),
                WhatId = incident.Id,
                OwnerId = getUserSecurityAnalystId(),
                Task_Type__c = 'USER_INVESTIGATION'
            );
            securityTasks.add(userInvestigationTask);
        }
        insert securityTasks;

        // Send immediate notifications
        sendCriticalThreatNotification(result, incident);

        // Trigger automated response actions
        executeAutomatedThreatResponse(result, incident);

        System.debug('✓ High threat response triggered successfully');
    } catch (Exception e) {
        System.debug('High threat response trigger error: ' + e.getMessage());
        // Create emergency notification even if main process fails
        createEmergencyThreatNotification(result, e.getMessage());
    }
}

private static String generateThreatAssessmentId() {
    try {
        // Generate unique assessment ID
        String timestamp = String.valueOf(System.now().getTime());
        String randomSuffix = String.valueOf(Math.random() * 10000).substring(0, 4);
        return 'TA-' + timestamp + '-' + randomSuffix;
    } catch (Exception e) {
        System.debug('Assessment ID generation error: ' + e.getMessage());
        return 'TA-ERROR-' + String.valueOf(System.now().getTime());
    }
}

private static ThreatAssessmentResult createMaximumSecurityThreatResult(String signatureRequestId, String errorMessage) {
    try {
        ThreatAssessmentResult result = new ThreatAssessmentResult();
        result.assessmentId = generateThreatAssessmentId();
        result.signatureRequestId = signatureRequestId;
        result.timestamp = System.now();
        result.overallThreatScore = 1.0; // Maximum threat
        result.threatLevel = 'CRITICAL';
        result.requiresImmediateAction = true;

        // Set all category scores to maximum
        result.identityThreatScore = 1.0;
        result.documentThreatScore = 1.0;
        result.networkThreatScore = 1.0;
        result.behavioralThreatScore = 1.0;
        result.aptThreatScore = 1.0;

        // Add error indicator threat
        result.detectedThreats = new List<ThreatIndicator>{
            new ThreatIndicator(
                'ASSESSMENT_ERROR',
                'Threat assessment system failure: ' + errorMessage,
                1.0,
                'CRITICAL'
            )
        };

        result.recommendations = new List<String>{
            'IMMEDIATE BLOCK - System error requires manual review',
            'SECURITY ESCALATION - Alert security team about assessment failure',
            'MANUAL VERIFICATION - All processing must be manually verified',
            'SYSTEM INVESTIGATION - Investigate threat assessment system failure'
        };

        System.debug('Maximum security threat result created due to assessment error');
        return result;
    } catch (Exception e) {
        System.debug('Maximum security result creation error: ' + e.getMessage());
        // Return most basic secure result
        ThreatAssessmentResult fallbackResult = new ThreatAssessmentResult();
        fallbackResult.overallThreatScore = 1.0;
        fallbackResult.threatLevel = 'CRITICAL';
        fallbackResult.requiresImmediateAction = true;
        return fallbackResult;
    }
}

private static void sendCriticalThreatNotification(ThreatAssessmentResult result, Security_Incident__c incident) {
    try {
        // Get security team distribution list
        List<User> securityTeam = [
            SELECT Id, Email, Name
            FROM User
            WHERE (Profile.Name LIKE '%Security%' OR UserRole.Name LIKE '%Security%')
              AND IsActive = true
            LIMIT 20
        ];

        if (!securityTeam.isEmpty()) {
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            for (User securityUser : securityTeam) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[]{ securityUser.Email });
                email.setSubject('CRITICAL THREAT ALERT - Incident ' + incident.Id);
                email.setPlainTextBody(buildCriticalThreatEmailBody(result, incident));
                email.setUseSignature(false);
                email.setSaveAsActivity(false);
                emails.add(email);
            }

            // Send notification emails
            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
                System.debug('✓ Critical threat notifications sent to ' + emails.size() + ' security team members');
            }
        }

        // Also create platform events for real-time notifications
        Critical_Threat_Event__e threatEvent = new Critical_Threat_Event__e(
            Assessment_Id__c = result.assessmentId,
            Incident_Id__c = incident.Id,
            Threat_Level__c = result.threatLevel,
            Overall_Score__c = result.overallThreatScore * 100,
            Requires_Action__c = result.requiresImmediateAction,
            Event_Timestamp__c = System.now()
        );
        EventBus.publish(threatEvent);
        System.debug('✓ Critical threat platform event published');

    } catch (Exception e) {
        System.debug('Critical threat notification error: ' + e.getMessage());
        // Fallback to system debugging
        System.debug('CRITICAL_THREAT_NOTIFICATION_FAILED|' + result.assessmentId + '|' + result.threatLevel + '|' + e.getMessage());
    }
}


private static void executeAutomatedThreatResponse(ThreatAssessmentResult result, Security_Incident__c incident) {
try {
    System.debug('Executing automated threat response for: ' + result.assessmentId);

    // Response 1: Automatic user account security measures
    if (result.identityThreatScore > 0.8) {
        executeUserSecurityMeasures(result);
    }

    // Response 2: Network-level protections
    if (result.networkThreatScore > 0.7) {
        executeNetworkProtectionMeasures(result);
    }

    // Response 3: Document access restrictions
    if (result.documentThreatScore > 0.8) {
        executeDocumentProtectionMeasures(result);
    }

    // Response 4: System monitoring enhancements
    if (result.aptThreatScore > 0.6) {
        executeEnhancedMonitoring(result);
    }

    // Response 5: Signature request blocking
    if (result.overallThreatScore >= 0.9) {
        executeSignatureRequestBlocking(result);
    }

    System.debug('✓ Automated threat response executed successfully');
} catch (Exception e) {
    System.debug('Automated threat response execution error: ' + e.getMessage());
}

}

private static void executeUserSecurityMeasures(ThreatAssessmentResult result) {
try {
    List<Signature_Request__c> requests = [
        SELECT RequestingUserId__c
        FROM Signature_Request__c
        WHERE Id = :result.signatureRequestId
        LIMIT 1
    ];

    if (!requests.isEmpty() && String.isNotBlank(requests[0].RequestingUserId__c)) {
        String userId = requests[0].RequestingUserId__c;

        User_Security_Restriction__c restriction = new User_Security_Restriction__c(
            UserId__c = userId,
            Restriction_Type__c = 'HIGH_THREAT_DETECTED',
            Assessment_Id__c = result.assessmentId,
            Restriction_Level__c = result.threatLevel,
            Auto_Generated__c = true,
            Effective_Date__c = System.now(),
            Expiration_Date__c = System.now().addHours(24),
            Status__c = 'ACTIVE',
            Reason__c = 'Automated restriction due to high threat detection'
        );
        insert restriction;

        if (result.identityThreatScore >= 0.9) {
            System.debug('Password reset required for user: ' + userId);
        }

        System.debug('✓ User security measures executed for: ' + userId);
    }
} catch (Exception e) {
    System.debug('User security measures execution error: ' + e.getMessage());
}

}

private static void executeNetworkProtectionMeasures(ThreatAssessmentResult result) {
try {
    Network_Protection_Rule__c protectionRule = new Network_Protection_Rule__c(
        Rule_Type__c = 'THREAT_BASED_BLOCKING',
        Assessment_Id__c = result.assessmentId,
        Threat_Level__c = result.threatLevel,
        Auto_Generated__c = true,
        Effective_Date__c = System.now(),
        Expiration_Date__c = System.now().addHours(12),
        Status__c = 'ACTIVE',
        Rule_Description__c = 'Automated network protection due to high threat score'
    );
    insert protectionRule;

    Network_Security_Action__c securityAction = new Network_Security_Action__c(
        Action_Type__c = 'AUTOMATED_PROTECTION',
        Assessment_Id__c = result.assessmentId,
        Protection_Rule__c = protectionRule.Id,
        Action_Timestamp__c = System.now(),
        Action_Result__c = 'SUCCESS'
    );
    insert securityAction;

    System.debug('✓ Network protection measures executed');
} catch (Exception e) {
    System.debug('Network protection measures execution error: ' + e.getMessage());
}

}

private static void executeDocumentProtectionMeasures(ThreatAssessmentResult result) {
try {
    Document_Access_Restriction__c restriction = new Document_Access_Restriction__c(
        Signature_Request_Id__c = result.signatureRequestId,
        Assessment_Id__c = result.assessmentId,
        Restriction_Type__c = 'THREAT_BASED_BLOCKING',
        Threat_Level__c = result.threatLevel,
        Auto_Generated__c = true,
        Effective_Date__c = System.now(),
        Expiration_Date__c = System.now().addHours(48),
        Status__c = 'ACTIVE',
        Restriction_Reason__c = 'Automated restriction due to document threat detection: ' + result.documentThreatScore
    );
    insert restriction;

    if (result.documentThreatScore >= 0.9) {
        Document_Quarantine__c quarantine = new Document_Quarantine__c(
            Signature_Request_Id__c = result.signatureRequestId,
            Assessment_Id__c = result.assessmentId,
            Quarantine_Reason__c = 'Critical document threat detected',
            Quarantine_Status__c = 'ACTIVE',
            Quarantine_Date__c = System.now(),
            Review_Required__c = true,
            Auto_Generated__c = true
        );
        insert quarantine;
        System.debug('Document quarantined due to critical threat level');
    }

    System.debug('✓ Document protection measures executed');
} catch (Exception e) {
    System.debug('Document protection measures execution error: ' + e.getMessage());
}

}

private static void executeEnhancedMonitoring(ThreatAssessmentResult result) {
try {
    Enhanced_Monitoring_Config__c monitoringConfig = new Enhanced_Monitoring_Config__c(
        Assessment_Id__c = result.assessmentId,
        Monitoring_Level__c = result.aptThreatScore >= 0.8 ? 'MAXIMUM' : 'HIGH',
        Auto_Generated__c = true,
        Start_Date__c = System.now(),
        End_Date__c = System.now().addDays(7),
        Status__c = 'ACTIVE',
        Monitor_Identity__c = true,
        Monitor_Network__c = true,
        Monitor_Documents__c = true,
        Monitor_Behavior__c = true,
        Alert_Threshold__c = 0.3
    );
    insert monitoringConfig;

    List<Task> monitoringTasks = new List<Task>();

    Task identityMonitoringTask = new Task(
        Subject = 'Enhanced Identity Monitoring - APT Detection',
        Description = 'Monitor user identity patterns for potential APT activity. Assessment ID: ' + result.assessmentId,
        Priority = 'High',
        Status = 'Not Started',
        ActivityDate = Date.today(),
        WhatId = monitoringConfig.Id,
        OwnerId = getUserSecurityAnalystId(),
        Task_Type__c = 'ENHANCED_MONITORING'
    );
    monitoringTasks.add(identityMonitoringTask);

    Task networkMonitoringTask = new Task(
        Subject = 'Enhanced Network Monitoring - C2 Detection',
        Description = 'Monitor network traffic patterns for potential command and control activity.',
        Priority = 'High',
        Status = 'Not Started',
        ActivityDate = Date.today(),
        WhatId = monitoringConfig.Id,
        OwnerId = getNetworkAnalystId(),
        Task_Type__c = 'ENHANCED_MONITORING'
    );
    monitoringTasks.add(networkMonitoringTask);

    insert monitoringTasks;
    System.debug('✓ Enhanced monitoring measures executed');
} catch (Exception e) {
    System.debug('Enhanced monitoring execution error: ' + e.getMessage());
}

}

private static void executeSignatureRequestBlocking(ThreatAssessmentResult result) {
try {
    List<Signature_Request__c> requests = [
        SELECT Id, Status__c, Blocked_Reason__c
        FROM Signature_Request__c
        WHERE Id = :result.signatureRequestId
        FOR UPDATE
    ];

    if (!requests.isEmpty()) {
        Signature_Request__c request = requests[0];
        request.Status__c = 'BLOCKED';
        request.Blocked_Reason__c = 'Automated blocking due to critical threat detection (Score: ' +
            (result.overallThreatScore * 100).format() + '%)';
        request.Blocked_Date__c = System.now();
        request.Assessment_Id__c = result.assessmentId;
        update request;
        System.debug('✓ Signature request blocked: ' + result.signatureRequestId);
    }

    Signature_Request_Block__c blockRecord = new Signature_Request_Block__c(
        Signature_Request_Id__c = result.signatureRequestId,
        Assessment_Id__c = result.assessmentId,
        Block_Reason__c = 'CRITICAL_THREAT_DETECTED',
        Threat_Score__c = result.overallThreatScore * 100,
        Block_Timestamp__c = System.now(),
        Auto_Generated__c = true,
        Review_Required__c = true,
        Block_Status__c = 'ACTIVE'
    );
    insert blockRecord;
    System.debug('✓ Signature request blocking executed');
} catch (Exception e) {
    System.debug('Signature request blocking execution error: ' + e.getMessage());
}

}

private static void createEmergencyThreatNotification(ThreatAssessmentResult result, String errorMessage) {
try {
    Emergency_Threat_Notification__c emergency = new Emergency_Threat_Notification__c(
        Assessment_Id__c = result.assessmentId,
        Notification_Type__c = 'SYSTEM_ERROR_HIGH_THREAT',
        Error_Message__c = errorMessage,
        Threat_Level__c = 'CRITICAL',
        Created_Timestamp__c = System.now(),
        Status__c = 'PENDING_REVIEW',
        Requires_Immediate_Action__c = true
    );
    insert emergency;

    List<User> systemAdmins = [
        SELECT Id, Email, Name
        FROM User
        WHERE Profile.Name = 'System Administrator'
        AND IsActive = true
        LIMIT 10
    ];

    if (!systemAdmins.isEmpty()) {
        List<Messaging.SingleEmailMessage> emergencyEmails = new List<Messaging.SingleEmailMessage>();

        for (User admin : systemAdmins) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{ admin.Email });
            email.setSubject('EMERGENCY: Threat Assessment System Failure');
            email.setPlainTextBody(
                'EMERGENCY NOTIFICATION\n\n' +
                'The threat assessment system has encountered a critical error while processing a high-threat signature request.\n\n' +
                'Assessment ID: ' + result.assessmentId + '\n' +
                'Signature Request: ' + result.signatureRequestId + '\n' +
                'Error: ' + errorMessage + '\n\n' +
                'IMMEDIATE ACTION REQUIRED:\n' +
                '1. Investigate threat assessment system failure\n' +
                '2. Manually review the signature request\n' +
                '3. Verify system security status\n' +
                '4. Consider blocking the signature request pending investigation\n\n' +
                'This is an automated emergency notification.'
            );
            emergencyEmails.add(email);
        }

        Messaging.sendEmail(emergencyEmails);
        System.debug('✓ Emergency threat notifications sent to system administrators');
    }
} catch (Exception e) {
    System.debug('Emergency threat notification creation error: ' + e.getMessage());
    System.debug('EMERGENCY_THREAT_SYSTEM_FAILURE|' + result.assessmentId + '|' + errorMessage);
}

}

public class ThreatAssessmentResult {
@AuraEnabled public String assessmentId;
@AuraEnabled public String signatureRequestId;
@AuraEnabled public DateTime timestamp;
@AuraEnabled public Decimal overallThreatScore;
@AuraEnabled public String threatLevel;
@AuraEnabled public Boolean requiresImmediateAction;
@AuraEnabled public Decimal identityThreatScore;
@AuraEnabled public Decimal documentThreatScore;
@AuraEnabled public Decimal networkThreatScore;
@AuraEnabled public Decimal behavioralThreatScore;
@AuraEnabled public Decimal aptThreatScore;
@AuraEnabled public List<ThreatIndicator> detectedThreats;
@AuraEnabled public List<String> recommendations; public ThreatAssessmentResult() {
this.detectedThreats = new List<ThreatIndicator>();
this.recommendations = new List<String>();
this.timestamp = System.now();
}
} public class ThreatIndicator {
@AuraEnabled public String type;
@AuraEnabled public String description;
@AuraEnabled public Decimal riskScore;
@AuraEnabled public String severity; public ThreatIndicator(String type, String description, Decimal riskScore, String severity) {
this.type = type;
this.description = description;
this.riskScore = riskScore;
this.severity = severity;
}
} 
public class IdentityThreatResult {
public List<ThreatIndicator> threats;
public Decimal threatScore; public IdentityThreatResult() {
this.threats = new List<ThreatIndicator>();
this.threatScore = 0.0;
}
} public class DocumentThreatResult {
public List<ThreatIndicator> threats;
public Decimal threatScore; public DocumentThreatResult() {
this.threats = new List<ThreatIndicator>();
this.threatScore = 0.0;
}
} public class NetworkThreatResult {
public List<ThreatIndicator> threats;
public Decimal threatScore; public NetworkThreatResult() {
this.threats = new List<ThreatIndicator>();
this.threatScore = 0.0;
}
} public class BehavioralThreatResult {
public List<ThreatIndicator> threats;
public Decimal threatScore; public BehavioralThreatResult() {
this.threats = new List<ThreatIndicator>();
this.threatScore = 0.0;
}
} public class APTThreatResult {
public List<ThreatIndicator> threats;
public Decimal threatScore; public APTThreatResult() {
this.threats = new List<ThreatIndicator>();
this.threatScore = 0.0;
}
} public class BiometricAnalysisResult {
public Boolean isConsistent;
public Decimal overallSimilarity;
public Decimal confidence; public BiometricAnalysisResult() {
this.isConsistent = false;
this.overallSimilarity = 0.0;
this.confidence = 0.0;
}
}
}

}
public class ContextAwareAccessService {
    
    @AuraEnabled
    public static AccessDecision evaluateContextualAccess(String userId, String resourceId, String action, String contextData) {
        try {
            AccessDecision decision = new AccessDecision();
            decision.isGranted = false;
            decision.conditions = new List<String>();
            decision.restrictions = new List<String>();
            
            // Parse context
            Map<String, Object> context = (Map<String, Object>) JSON.deserializeUntyped(contextData);
            
            // Step 1: Evaluate user context
            UserContextResult userResult = evaluateUserContext(userId, context);
            decision.contextScore += userResult.score;
            
            // Step 2: Evaluate device context
            DeviceContextResult deviceResult = evaluateDeviceContext(context);
            decision.contextScore += deviceResult.score;
            
            // Step 3: Evaluate location context
            LocationContextResult locationResult = evaluateLocationContext(context);
            decision.contextScore += locationResult.score;
            
            // Step 4: Evaluate temporal context
            TemporalContextResult temporalResult = evaluateTemporalContext(userId, context);
            decision.contextScore += temporalResult.score;
            
            // Step 5: Evaluate behavioral context
            BehavioralContextResult behavioralResult = evaluateBehavioralContext(userId, context);
            decision.contextScore += behavioralResult.score;
            
            // Step 6: Calculate final context score (0-1)
            decision.contextScore = decision.contextScore / 5;
            
            // Step 7: Apply context-aware policies
            List<ContextualPolicy__c> policies = getApplicablePolicies(resourceId, action);
            
            for (ContextualPolicy__c policy : policies) {
                PolicyEvaluationResult policyResult = evaluatePolicy(policy, decision.contextScore, context);
                
                if (policyResult.isApplicable) {
                    if (policyResult.isGranted) {
                        decision.conditions.addAll(policyResult.conditions);
                    } else {
                        decision.restrictions.addAll(policyResult.restrictions);
                    }
                }
            }
            
            // Step 8: Make final decision
            decision.isGranted = decision.contextScore >= 0.6 && decision.restrictions.isEmpty();
            decision.confidenceLevel = calculateConfidence(decision.contextScore);
            
            // Step 9: Apply adaptive restrictions
            if (decision.isGranted && decision.contextScore < 0.8) {
                decision = applyAdaptiveRestrictions(decision, context);
            }
            
            // Step 10: Log decision
            logContextualAccessDecision(userId, resourceId, action, decision, context);
            
            return decision;
            
        } catch (Exception e) {
            throw new AuraHandledException('Contextual access evaluation failed: ' + e.getMessage());
        }
    }
    
    private static UserContextResult evaluateUserContext(String userId, Map<String, Object> context) {
        UserContextResult result =
private static UserContextResult evaluateUserContext(String userId, Map<String, Object> context) {
        UserContextResult result = new UserContextResult();
        result.score = 0.5; // Base score
        result.factors = new List<String>();

        try {
            // Step 1: Check user's historical behavior pattern
            List<AggregateResult> userActivity = [
                SELECT AVG(AccessDuration__c) avgDuration,
                       AVG(DocumentsAccessed__c) avgDocuments,
                       COUNT(Id) totalSessions
                FROM UserSession__c 
                WHERE UserId__c = :userId 
                AND CreatedDate = LAST_N_DAYS:30
            ];

            if (!userActivity.isEmpty()) {
                Decimal currentSessionDuration = (Decimal) context.get('sessionDuration');
                Decimal avgDuration = (Decimal) userActivity[0].get('avgDuration');
                
                if (avgDuration != null && currentSessionDuration != null) {
                    Decimal durationRatio = currentSessionDuration / avgDuration;
                    
                    if (durationRatio >= 0.5 && durationRatio <= 2.0) {
                        result.score += 0.1;
                        result.factors.add('Normal session duration pattern');
                    } else {
                        result.score -= 0.1;
                        result.factors.add('Abnormal session duration detected');
                    }
                }
            }

            // Step 2: Evaluate user security profile
            User userRecord = [
                SELECT Profile.Name, LastLoginDate, FailedLoginAttempts__c,
                       SecurityClearance__c, TwoFactorEnabled__c
                FROM User 
                WHERE Id = :userId
                LIMIT 1
            ];

            // Higher score for users with security features enabled
            if (userRecord.TwoFactorEnabled__c) {
                result.score += 0.2;
                result.factors.add('MFA enabled');
            }

            // Security clearance level impact
            if (String.isNotBlank(userRecord.SecurityClearance__c)) {
                switch on userRecord.SecurityClearance__c {
                    when 'HIGH' {
                        result.score += 0.2;
                        result.factors.add('High security clearance');
                    }
                    when 'MEDIUM' {
                        result.score += 0.1;
                        result.factors.add('Medium security clearance');
                    }
                    when 'LOW' {
                        result.score -= 0.1;
                        result.factors.add('Low security clearance');
                    }
                }
            }

            // Step 3: Check for recent security incidents
            List<SecurityIncident__c> recentIncidents = [
                SELECT Id, Severity__c, CreatedDate
                FROM SecurityIncident__c 
                WHERE UserId__c = :userId 
                AND CreatedDate = LAST_N_DAYS:30
                AND Status__c != 'RESOLVED'
            ];

            if (!recentIncidents.isEmpty()) {
                result.score -= 0.3;
                result.factors.add('Recent security incidents: ' + recentIncidents.size());
            }

            // Step 4: Evaluate role-based context
            String userRole = (String) context.get('userRole');
            if (String.isNotBlank(userRole)) {
                Set<String> privilegedRoles = new Set<String>{'System Administrator', 'Security Manager', 'Compliance Officer'};
                if (privilegedRoles.contains(userRole)) {
                    result.score += 0.15;
                    result.factors.add('Privileged role: ' + userRole);
                }
            }

        } catch (Exception e) {
            System.debug('User context evaluation error: ' + e.getMessage());
            result.score = 0.3; // Conservative fallback
            result.factors.add('Error in user context evaluation');
        }

        return result;
    }

    private static DeviceContextResult evaluateDeviceContext(Map<String, Object> context) {
        DeviceContextResult result = new DeviceContextResult();
        result.score = 0.5; // Base score
        result.factors = new List<String>();

        try {
            String deviceFingerprint = (String) context.get('deviceFingerprint');
            String userAgent = (String) context.get('userAgent');
            String deviceId = (String) context.get('deviceId');

            // Step 1: Check if device is trusted
            if (String.isNotBlank(deviceFingerprint)) {
                List<TrustedDevice__c> trustedDevices = [
                    SELECT Id, TrustLevel__c, LastVerified__c, Status__c
                    FROM TrustedDevice__c 
                    WHERE DeviceFingerprint__c = :deviceFingerprint
                    AND UserId__c = :UserInfo.getUserId()
                    LIMIT 1
                ];

                if (!trustedDevices.isEmpty()) {
                    TrustedDevice__c device = trustedDevices[0];
                    switch on device.TrustLevel__c {
                        when 'HIGH' {
                            result.score += 0.3;
                            result.factors.add('Highly trusted device');
                        }
                        when 'MEDIUM' {
                            result.score += 0.1;
                            result.factors.add('Moderately trusted device');
                        }
                        when 'LOW' {
                            result.score -= 0.1;
                            result.factors.add('Low trust device');
                        }
                    }

                    // Check device verification recency
                    if (device.LastVerified__c != null && device.LastVerified__c > DateTime.now().addDays(-7)) {
                        result.score += 0.1;
                        result.factors.add('Recently verified device');
                    }
                } else {
                    result.score -= 0.2;
                    result.factors.add('Unknown/untrusted device');
                }
            }

            // Step 2: Analyze user agent for suspicious patterns
            if (String.isNotBlank(userAgent)) {
                if (userAgent.containsIgnoreCase('bot') || 
                    userAgent.containsIgnoreCase('crawler') || 
                    userAgent.containsIgnoreCase('spider')) {
                    result.score -= 0.5;
                    result.factors.add('Suspicious user agent detected');
                }

                // Check for mobile vs desktop context
                if (userAgent.containsIgnoreCase('mobile')) {
                    Boolean isMobileAllowed = (Boolean) context.get('mobileAccessAllowed');
                    if (isMobileAllowed == false) {
                        result.score -= 0.3;
                        result.factors.add('Mobile access not permitted for this resource');
                    }
                }
            }

            // Step 3: Check device compliance status
            String complianceStatus = (String) context.get('deviceComplianceStatus');
            if (String.isNotBlank(complianceStatus)) {
                switch on complianceStatus {
                    when 'COMPLIANT' {
                        result.score += 0.2;
                        result.factors.add('Device is compliant');
                    }
                    when 'NON_COMPLIANT' {
                        result.score -= 0.4;
                        result.factors.add('Device is non-compliant');
                    }
                    when 'UNKNOWN' {
                        result.score -= 0.1;
                        result.factors.add('Unknown compliance status');
                    }
                }
            }

        } catch (Exception e) {
            System.debug('Device context evaluation error: ' + e.getMessage());
            result.score = 0.3; // Conservative fallback
            result.factors.add('Error in device context evaluation');
        }

        return result;
    }

    private static LocationContextResult evaluateLocationContext(Map<String, Object> context) {
        LocationContextResult result = new LocationContextResult();
        result.score = 0.5; // Base score
        result.factors = new List<String>();

        try {
            String ipAddress = (String) context.get('ipAddress');
            String country = (String) context.get('country');
            String city = (String) context.get('city');
            String geoLocation = (String) context.get('geoLocation');

            // Step 1: Check IP reputation
            if (String.isNotBlank(ipAddress)) {
                // Check against blacklisted IPs
                List<BlacklistedIP__c> blacklistedIPs = [
                    SELECT Id, RiskLevel__c, Reason__c
                    FROM BlacklistedIP__c 
                    WHERE IPAddress__c = :ipAddress
                    LIMIT 1
                ];

                if (!blacklistedIPs.isEmpty()) {
                    result.score -= 0.8;
                    result.factors.add('IP address blacklisted: ' + blacklistedIPs[0].Reason__c);
                } else {
                    // Check IP reputation score
                    Decimal ipReputationScore = getIPReputationScore(ipAddress);
                    if (ipReputationScore > 0.8) {
                        result.score += 0.2;
                        result.factors.add('Good IP reputation');
                    } else if (ipReputationScore < 0.3) {
                        result.score -= 0.3;
                        result.factors.add('Poor IP reputation');
                    }
                }
            }

            // Step 2: Validate geographic location
            if (String.isNotBlank(country)) {
                // Check against allowed countries
                List<AllowedLocation__c> allowedLocations = [
                    SELECT Id, LocationType__c, RiskLevel__c
                    FROM AllowedLocation__c 
                    WHERE (Country__c = :country OR Country__c = 'ALL')
                    AND IsActive__c = true
                ];

                if (allowedLocations.isEmpty()) {
                    result.score -= 0.4;
                    result.factors.add('Access from restricted country: ' + country);
                } else {
                    for (AllowedLocation__c location : allowedLocations) {
                        switch on location.RiskLevel__c {
                            when 'LOW' {
                                result.score += 0.2;
                                result.factors.add('Low-risk geographic location');
                            }
                            when 'MEDIUM' {
                                result.score += 0.0;
                                result.factors.add('Medium-risk geographic location');
                            }
                            when 'HIGH' {
                                result.score -= 0.2;
                                result.factors.add('High-risk geographic location');
                            }
                        }
                    }
                }
            }

            // Step 3: Check for VPN/Proxy usage
            Boolean isVPN = (Boolean) context.get('isVPN');
            Boolean isProxy = (Boolean) context.get('isProxy');

            if (isVPN == true || isProxy == true) {
                result.score -= 0.3;
                result.factors.add('VPN/Proxy usage detected');
                
                // Check if VPN usage is allowed
                Boolean vpnAllowed = (Boolean) context.get('vpnAccessAllowed');
                if (vpnAllowed != true) {
                    result.score -= 0.4;
                    result.factors.add('VPN access not permitted');
                }
            }

            // Step 4: Analyze location consistency
            List<UserLocation__c> recentLocations = [
                SELECT Country__c, City__c, IPAddress__c, AccessTimestamp__c
                FROM UserLocation__c 
                WHERE UserId__c = :UserInfo.getUserId()
                AND AccessTimestamp__c = LAST_N_DAYS:7
                ORDER BY AccessTimestamp__c DESC
                LIMIT 10
            ];

            if (!recentLocations.isEmpty()) {
                // Check for impossible travel scenarios
                for (UserLocation__c recentLoc : recentLocations) {
                    if (recentLoc.Country__c != country && 
                        recentLoc.AccessTimestamp__c > DateTime.now().addHours(-2)) {
                        result.score -= 0.5;
                        result.factors.add('Impossible travel detected');
                        break;
                    }
                }
            }

        } catch (Exception e) {
            System.debug('Location context evaluation error: ' + e.getMessage());
            result.score = 0.3; // Conservative fallback
            result.factors.add('Error in location context evaluation');
        }

        return result;
    }

    private static TemporalContextResult evaluateTemporalContext(String userId, Map<String, Object> context) {
        TemporalContextResult result = new TemporalContextResult();
        result.score = 0.5; // Base score
        result.factors = new List<String>();

        try {
            DateTime currentTime = System.now();
            Integer currentHour = currentTime.hour();
            Integer currentDay = Math.mod(currentTime.dayOfYear(), 7); // 0=Sunday, 6=Saturday

            // Step 1: Check business hours compliance
            BusinessHours businessHours = [
                SELECT Id, MondayStartTime, MondayEndTime, TuesdayStartTime, TuesdayEndTime,
                       WednesdayStartTime, WednesdayEndTime, ThursdayStartTime, ThursdayEndTime,
                       FridayStartTime, FridayEndTime, SaturdayStartTime, SaturdayEndTime,
                       SundayStartTime, SundayEndTime
                FROM BusinessHours 
                WHERE IsDefault = true
                LIMIT 1
            ];

            Boolean isBusinessHours = BusinessHours.isWithin(businessHours.Id, currentTime);
            if (isBusinessHours) {
                result.score += 0.2;
                result.factors.add('Access during business hours');
            } else {
                result.score -= 0.1;
                result.factors.add('Access outside business hours');
            }

            // Step 2: Analyze user's typical access patterns
            List<AggregateResult> accessPatterns = [
                SELECT HOUR_IN_DAY(CreatedDate) accessHour, COUNT(Id) frequency
                FROM UserSession__c 
                WHERE UserId__c = :userId 
                AND CreatedDate = LAST_N_DAYS:30
                GROUP BY HOUR_IN_DAY(CreatedDate)
                ORDER BY COUNT(Id) DESC
            ];

            Boolean isTypicalHour = false;
            for (AggregateResult pattern : accessPatterns) {
                Integer hour = (Integer) pattern.get('accessHour');
                Integer frequency = (Integer) pattern.get('frequency');
                
                if (hour == currentHour && frequency > 3) {
                    isTypicalHour = true;
                    result.score += 0.15;
                    result.factors.add('Access at typical time');
                    break;
                }
            }

            if (!isTypicalHour && !accessPatterns.isEmpty()) {
                result.score -= 0.1;
                result.factors.add('Access at atypical time');
            }

            // Step 3: Check for time-based restrictions
            String timeRestrictions = (String) context.get('timeRestrictions');
            if (String.isNotBlank(timeRestrictions)) {
                Map<String, Object> restrictions = (Map<String, Object>) JSON.deserializeUntyped(timeRestrictions);
                
                List<Object> allowedHours = (List<Object>) restrictions.get('allowedHours');
                if (allowedHours != null && !allowedHours.isEmpty()) {
                    Boolean hourAllowed = false;
                    for (Object hourObj : allowedHours) {
                        if (Integer.valueOf(hourObj) == currentHour) {
                            hourAllowed = true;
                            break;
                        }
                    }
                    
                    if (hourAllowed) {
                        result.score += 0.1;
                        result.factors.add('Access within allowed time window');
                    } else {
                        result.score -= 0.5;
                        result.factors.add('Access outside allowed time
                result.factors.add('Access outside allowed time');
            }
        }
        
        // Check for allowed days
        List<Object> allowedDays = (List<Object>) restrictions.get('allowedDays');
        if (allowedDays != null && !allowedDays.isEmpty()) {
            Boolean dayAllowed = false;
            for (Object dayObj : allowedDays) {
                if (Integer.valueOf(dayObj) == currentDay) {
                    dayAllowed = true;
                    break;
                }
            }
            if (dayAllowed) {
                result.score += 0.1;
                result.factors.add('Access on allowed day');
            } else {
                result.score -= 0.5;
                result.factors.add('Access on restricted day');
            }
        }
    }
    
    // Step 4: Check for unusual access velocity
    List<UserSession__c> recentSessions = [
        SELECT Id, CreatedDate, Duration__c
        FROM UserSession__c
        WHERE UserId__c = :userId
        AND CreatedDate = LAST_N_HOURS:1
        ORDER BY CreatedDate DESC
    ];
    
    if (recentSessions.size() > 5) {
        result.score -= 0.3;
        result.factors.add('Unusual access frequency detected');
    }
    
    // Step 5: Check for maintenance windows
    List<MaintenanceWindow__c> maintenanceWindows = [
        SELECT Id, StartTime__c, EndTime__c, ImpactLevel__c
        FROM MaintenanceWindow__c
        WHERE IsActive__c = true
        AND StartTime__c <= :currentTime
        AND EndTime__c >= :currentTime
    ];
    
    if (!maintenanceWindows.isEmpty()) {
        result.score -= 0.2;
        result.factors.add('Access during maintenance window');
    }
    
} catch (Exception e) {
    System.debug('Temporal context evaluation error: ' + e.getMessage());
    result.score = 0.3; // Conservative fallback
    result.factors.add('Error in temporal context evaluation');
}

return result;
}

private static BehavioralContextResult evaluateBehavioralContext(String userId, Map<String, Object> context) {
BehavioralContextResult result = new BehavioralContextResult();
result.score = 0.5; // Base score
result.factors = new List<String>();

try {
    // Step 1: Analyze typing patterns
    String typingPattern = (String) context.get('typingPattern');
    if (String.isNotBlank(typingPattern)) {
        // Compare with stored user typing biometrics
        List<UserBiometric__c> userBiometrics = [
            SELECT Id, TypingPattern__c, MousePattern__c, BiometricScore__c
            FROM UserBiometric__c
            WHERE UserId__c = :userId
            AND IsActive__c = true
            ORDER BY LastUpdated__c DESC
            LIMIT 1
        ];
        
        if (!userBiometrics.isEmpty()) {
            Decimal similarityScore = calculateTypingSimilarity(
                typingPattern, 
                userBiometrics[0].TypingPattern__c
            );
            
            if (similarityScore > 0.8) {
                result.score += 0.2;
                result.factors.add('Typing pattern matches user profile');
            } else if (similarityScore < 0.4) {
                result.score -= 0.3;
                result.factors.add('Typing pattern anomaly detected');
            }
        }
    }
    
    // Step 2: Check navigation behavior
    List<Object> navigationPath = (List<Object>) context.get('navigationPath');
    if (navigationPath != null && !navigationPath.isEmpty()) {
        // Analyze navigation patterns against user history
        List<UserNavigationPattern__c> patterns = [
            SELECT Id, CommonPaths__c, UsageFrequency__c
            FROM UserNavigationPattern__c
            WHERE UserId__c = :userId
            AND IsActive__c = true
            ORDER BY LastAccessed__c DESC
            LIMIT 5
        ];
        
        Boolean hasTypicalNavigation = false;
        for (UserNavigationPattern__c pattern : patterns) {
            if (isNavigationPathSimilar(navigationPath, pattern.CommonPaths__c)) {
                hasTypicalNavigation = true;
                result.score += 0.15;
                result.factors.add('Typical navigation behavior');
                break;
            }
        }
        
        if (!hasTypicalNavigation && !patterns.isEmpty()) {
            result.score -= 0.1;
            result.factors.add('Unusual navigation pattern');
        }
    }
    
    // Step 3: Analyze interaction velocity
    Integer clicksPerMinute = (Integer) context.get('clicksPerMinute');
    if (clicksPerMinute != null) {
        // Check against user's typical interaction speed
        List<AggregateResult> avgInteractionSpeed = [
            SELECT AVG(InteractionsPerMinute__c) avgSpeed
            FROM UserSession__c
            WHERE UserId__c = :userId
            AND CreatedDate = LAST_N_DAYS:30
            AND InteractionsPerMinute__c != null
        ];
        
        if (!avgInteractionSpeed.isEmpty()) {
            Decimal avgSpeed = (Decimal) avgInteractionSpeed[0].get('avgSpeed');
            if (avgSpeed != null) {
                Decimal speedRatio = clicksPerMinute / avgSpeed;
                
                if (speedRatio >= 0.5 && speedRatio <= 2.0) {
                    result.score += 0.1;
                    result.factors.add('Normal interaction speed');
                } else if (speedRatio > 3.0) {
                    result.score -= 0.2;
                    result.factors.add('Unusually high interaction speed - possible automation');
                } else {
                    result.score -= 0.1;
                    result.factors.add('Unusually low interaction speed');
                }
            }
        }
    }
    
    // Step 4: Check for suspicious behavior indicators
    Boolean hasClipboardActivity = (Boolean) context.get('hasClipboardActivity');
    Boolean hasScreenCapture = (Boolean) context.get('hasScreenCapture');
    Boolean hasUnusualKeystrokes = (Boolean) context.get('hasUnusualKeystrokes');
    
    if (hasClipboardActivity == true) {
        result.score -= 0.1;
        result.factors.add('Clipboard activity detected');
    }
    
    if (hasScreenCapture == true) {
        result.score -= 0.3;
        result.factors.add('Screen capture activity detected');
    }
    
    if (hasUnusualKeystrokes == true) {
        result.score -= 0.2;
        result.factors.add('Unusual keystroke patterns detected');
    }
    
    // Step 5: Analyze session duration patterns
    Integer currentSessionDuration = (Integer) context.get('sessionDuration');
    if (currentSessionDuration != null) {
        List<AggregateResult> avgSessionDuration = [
            SELECT AVG(Duration__c) avgDuration
            FROM UserSession__c
            WHERE UserId__c = :userId
            AND CreatedDate = LAST_N_DAYS:30
            AND Duration__c != null
        ];
        
        if (!avgSessionDuration.isEmpty()) {
            Decimal avgDuration = (Decimal) avgSessionDuration[0].get('avgDuration');
            if (avgDuration != null) {
                Decimal durationRatio = currentSessionDuration / avgDuration;
                
                if (durationRatio >= 0.3 && durationRatio <= 3.0) {
                    result.score += 0.1;
                    result.factors.add('Normal session duration');
                } else {
                    result.score -= 0.1;
                    result.factors.add('Atypical session duration');
                }
            }
        }
    }
    
} catch (Exception e) {
    System.debug('Behavioral context evaluation error: ' + e.getMessage());
    result.score = 0.3; // Conservative fallback
    result.factors.add('Error in behavioral context evaluation');
}

return result;
}

// Helper method to calculate typing pattern similarity
private static Decimal calculateTypingSimilarity(String currentPattern, String storedPattern) {
try {
    if (String.isBlank(currentPattern) || String.isBlank(storedPattern)) {
        return 0;
    }
    
    Map<String, Object> current = (Map<String, Object>) JSON.deserializeUntyped(currentPattern);
    Map<String, Object> stored = (Map<String, Object>) JSON.deserializeUntyped(storedPattern);
    
    Decimal dwellTimeSimilarity = calculateMetricSimilarity(
        (Decimal) current.get('avgDwellTime'),
        (Decimal) stored.get('avgDwellTime')
    );
    
    Decimal flightTimeSimilarity = calculateMetricSimilarity(
        (Decimal) current.get('avgFlightTime'),
        (Decimal) stored.get('avgFlightTime')
    );
    
    Decimal rhythmSimilarity = calculateMetricSimilarity(
        (Decimal) current.get('typingRhythm'),
        (Decimal) stored.get('typingRhythm')
    );
    
    return (dwellTimeSimilarity + flightTimeSimilarity + rhythmSimilarity) / 3;
    
} catch (Exception e) {
    System.debug('Typing similarity calculation error: ' + e.getMessage());
    return 0;
}
}

// Helper method to calculate metric similarity
private static Decimal calculateMetricSimilarity(Decimal current, Decimal stored) {
if (current == null || stored == null || stored == 0) {
    return 0;
}

Decimal difference = Math.abs(current - stored) / stored;
return Math.max(0, 1 - difference);
}

// Helper method to check navigation path similarity
private static Boolean isNavigationPathSimilar(List<Object> currentPath, String storedPaths) {
try {
    if (currentPath == null || String.isBlank(storedPaths)) {
        return false;
    }
    
    List<Object> commonPaths = (List<Object>) JSON.deserializeUntyped(storedPaths);
    
    // Simple similarity check - can be enhanced with more sophisticated algorithms
    Set<String> currentSet = new Set<String>();
    for (Object path : currentPath) {
        currentSet.add(String.valueOf(path));
    }
    
    Set<String> storedSet = new Set<String>();
    for (Object path : commonPaths) {
        storedSet.add(String.valueOf(path));
    }
    
    // Calculate Jaccard similarity
    Set<String> intersection = currentSet.clone();
    intersection.retainAll(storedSet);
    
    Set<String> union = currentSet.clone();
    union.addAll(storedSet);
    
    return union.isEmpty() ? false : (Decimal.valueOf(intersection.size()) / union.size()) > 0.5;
    
} catch (Exception e) {
    System.debug('Navigation path similarity error: ' + e.getMessage());
    return false;
}
}

// Result classes
public class UserContextResult {
@AuraEnabled public Decimal score;
@AuraEnabled public List<String> factors;
}

public class DeviceContextResult {
@AuraEnabled public Decimal score;
@AuraEnabled public List<String> factors;
}

public class LocationContextResult {
@AuraEnabled public Decimal score;
@AuraEnabled public List<String> factors;
}

public class TemporalContextResult {
@AuraEnabled public Decimal score;
@AuraEnabled public List<String> factors;
}

public class BehavioralContextResult {
@AuraEnabled public Decimal score;
@AuraEnabled public List<String> factors;
}

public class AccessDecision {
@AuraEnabled public Boolean isGranted;
@AuraEnabled public Decimal contextScore;
@AuraEnabled public List<String> conditions;
@AuraEnabled public List<String> restrictions;
@AuraEnabled public String confidenceLevel;
}
}

public class ThreatDetectionEngine {
    
    @AuraEnabled
    public static ThreatAssessmentResult assessThreat(String userId, String activity, String contextData) {
        try {
            ThreatAssessmentResult result = new ThreatAssessmentResult();
            result.threatLevel = 'LOW';
            result.riskScore = 0;
            result.threats = new List<String>();
            result.recommendations = new List<String>();
            
            Map<String, Object> context = (Map<String, Object>) JSON.deserializeUntyped(contextData);
            
            // Step 1: Behavioral threat analysis
            BehavioralThreatResult behavioralResult = analyzeBehavioralThreats(userId, activity, context);
            result.riskScore += behavioralResult.riskScore;
            result.threats.addAll(behavioralResult.threats);
            
            // Step 2: Network threat analysis
            NetworkThreatResult networkResult = analyzeNetworkThreats(context);
            result.riskScore += networkResult.riskScore;
            result.threats.addAll(networkResult.threats);
            
            // Step 3: Device threat analysis
            DeviceThreatResult deviceResult = analyzeDeviceThreats(context);
            result.riskScore += deviceResult.riskScore;
            result.threats.addAll(deviceResult.threats);
            
            // Step 4: Data access pattern analysis
            DataAccessThreatResult dataResult = analyzeDataAccessThreats(userId, activity, context);
            result.riskScore += dataResult.riskScore;
            result.threats.addAll(dataResult.threats);
            
            // Step 5: Temporal threat analysis
            TemporalThreatResult temporalResult = analyzeTemporalThreats(userId, context);
            result.riskScore += temporalResult.riskScore;
            result.threats.addAll(temporalResult.threats);
            
            // Step 6: Calculate final threat level
            result.threatLevel = calculateThreatLevel(result.riskScore);
            result.recommendations = generateRecommendations(result);
            
            // Step 7: Log threat assessment
            logThreatAssessment(userId, activity, result, context);
            
            // Step 8: Trigger alerts for high-risk threats
            if (result.riskScore > 70) {
                triggerThreatAlert(userId, activity, result);
            }
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Threat assessment failed: ' + e.getMessage());
        }
    }
    
   private static BehavioralThreatResult analyzeBehavioralThreats(String userId, String activity, Map<String, Object> context) {
    BehavioralThreatResult result = new BehavioralThreatResult();
    result.threats = new List<String>();
    result.riskScore = 0;

    try {
        // Calculate cutoff datetime (last 24 hours)
        Datetime cutoff = System.now().addHours(-24);

        // Recent activity
        List<UserActivity__c> recentActivity = [
            SELECT Id, ActivityType__c, Timestamp__c, Duration__c, ResourceAccessed__c
            FROM UserActivity__c
            WHERE UserId__c = :userId
            AND Timestamp__c >= :cutoff
            ORDER BY Timestamp__c DESC
            LIMIT 100
        ];

        System.debug('✅ Retrieved ' + recentActivity.size() + ' records');

        // Activity frequency
        Map<String, Integer> activityCounts = new Map<String, Integer>();
        for (UserActivity__c act : recentActivity) {
            String actType = act.ActivityType__c;
            activityCounts.put(actType, activityCounts.containsKey(actType) ?
                activityCounts.get(actType) + 1 : 1);
        }
        Integer currentActivityCount = activityCounts.containsKey(activity) ? 
            activityCounts.get(activity) : 0;

        // Baseline check
        List<AggregateResult> baseline = [
            SELECT ActivityType__c, AVG(DailyCount__c) avgCount, STDDEV(DailyCount__c) stdDev
            FROM UserActivityBaseline__c
            WHERE UserId__c = :userId
            AND ActivityType__c = :activity
            AND CreatedDate = LAST_N_DAYS:30
            GROUP BY ActivityType__c
        ];

        if (!baseline.isEmpty()) {
            Decimal avgCount = (Decimal) baseline[0].get('avgCount');
            Decimal stdDev = (Decimal) baseline[0].get('stdDev');

            if (avgCount != null && stdDev != null) {
                Decimal threshold = avgCount + (2 * stdDev);
                if (currentActivityCount > threshold) {
                    result.riskScore += 25;
                    result.threats.add('Unusual activity spike: ' +
                        currentActivityCount + ' vs typical ' + avgCount.intValue());
                }
            }
        }

        // Rapid actions check
        Integer actionsInLastMinute = 0;
        Datetime oneMinuteAgo = Datetime.now().addMinutes(-1);
        for (UserActivity__c act : recentActivity) {
            if (act.Timestamp__c > oneMinuteAgo) {
                actionsInLastMinute++;
            }
        }
        if (actionsInLastMinute > 10) {
            result.riskScore += 20;
            result.threats.add('Rapid successive actions: ' + actionsInLastMinute + ' in 1 min');
        }

        // Resource access check
        Set<String> resourcesAccessed = new Set<String>();
        for (UserActivity__c act : recentActivity) {
            if (String.isNotBlank(act.ResourceAccessed__c)) {
                resourcesAccessed.add(act.ResourceAccessed__c);
            }
        }

        List<UserResourceBaseline__c> resourceBaseline = [
            SELECT Id, TypicalResourceCount__c
            FROM UserResourceBaseline__c
            WHERE UserId__c = :userId
            AND CreatedDate = LAST_N_DAYS:7
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (!resourceBaseline.isEmpty()) {
            Decimal typicalCount = resourceBaseline[0].TypicalResourceCount__c;
            if (typicalCount != null && resourcesAccessed.size() > (typicalCount * 2)) {
                result.riskScore += 15;
                result.threats.add('Unusually high resources accessed: ' +
                    resourcesAccessed.size() + ' vs typical ' + typicalCount.intValue());
            }
        }

        // Off-hours check
        Integer currentHour = Datetime.now().hour();
        if ((currentHour < 7 || currentHour > 22) && activity.contains('DOWNLOAD')) {
            result.riskScore += 20;
            result.threats.add('Sensitive activity during off-hours: ' + currentHour + ':00');
        }

    } catch (Exception e) {
        System.debug('⚠️ Behavioral threat analysis error: ' + e.getMessage());
        result.riskScore = 10;
        result.threats.add('Error in behavioral threat analysis');
    }

    return result;
}

    private static NetworkThreatResult analyzeNetworkThreats(Map<String, Object> context) {
        NetworkThreatResult result = new NetworkThreatResult();
        result.threats = new List<String>();
        result.riskScore = 0;
        
        try {
            String ipAddress = (String) context.get('ipAddress');
            String userAgent = (String) context.get('userAgent');
            String referrer = (String) context.get('referrer');
            
            // Check IP reputation
            if (String.isNotBlank(ipAddress)) {
                List<ThreatIntelligence__c> threatIntel = [
                    SELECT Id, ThreatType__c, RiskLevel__c, LastSeen__c, Description__c
                    FROM ThreatIntelligence__c 
                    WHERE IPAddress__c = :ipAddress 
                    AND IsActive__c = true
                ];
                
                for (ThreatIntelligence__c threat : threatIntel) {
                    switch on threat.RiskLevel__c {
                        when 'CRITICAL' {
                            result.riskScore += 50;
                            result.threats.add('Critical threat IP detected: ' + threat.Description__c);
                        }
                        when 'HIGH' {
                            result.riskScore += 35;
                            result.threats.add('High-risk IP detected: ' + threat.Description__c);
                        }
                        when 'MEDIUM' {
                            result.riskScore += 20;
                            result.threats.add('Medium-risk IP detected: ' + threat.Description__c);
                        }
                    }
                }
                
                // Check for Tor exit nodes
                if (isTorExitNode(ipAddress)) {
                    result.riskScore += 40;
                    result.threats.add('Access from Tor exit node detected');
                }
                
                // Check for known proxy/VPN services
                if (isKnownProxy(ipAddress)) {
                    result.riskScore += 25;
                    result.threats.add('Access from commercial VPN/proxy service');
                }
            }
            
            // Analyze User Agent
            if (String.isNotBlank(userAgent)) {
                // Check for suspicious user agents
                List<String> suspiciousPatterns = new List<String>{
                    'sqlmap', 'nikto', 'nmap', 'burp', 'metasploit', 'curl', 'wget'
                };
                
                String lowerAgent = userAgent.toLowerCase();
                for (String pattern : suspiciousPatterns) {
                    if (lowerAgent.contains(pattern)) {
                        result.riskScore += 45;
                        result.threats.add('Suspicious user agent detected: ' + pattern);
                    }
                }
                
                // Check for unusual user agent length
                if (userAgent.length() > 500 || userAgent.length() < 10) {
                    result.riskScore += 15;
                    result.threats.add('Unusual user agent length: ' + userAgent.length());
                }
            }
            
            // Check connection characteristics
            Boolean isEncrypted = (Boolean) context.get('isEncrypted');
            if (isEncrypted != true) {
                result.riskScore += 30;
                result.threats.add('Unencrypted connection detected');
            }
            
            // Check for suspicious referrer patterns
            if (String.isNotBlank(referrer)) {
                List<String> suspiciousDomains = getSuspiciousDomains();
                String referrerDomain = extractDomain(referrer);
                
                if (suspiciousDomains.contains(referrerDomain)) {
                    result.riskScore += 35;
                    result.threats.add('Suspicious referrer domain: ' + referrerDomain);
                }
            }
            
        } catch (Exception e) {
            System.debug('Network threat analysis error: ' + e.getMessage());
            result.riskScore = 10;
            result.threats.add('Error in network threat analysis');
        }
        
        return result;
    }

    
    private static DeviceThreatResult analyzeDeviceThreats(Map<String, Object> context) {
        DeviceThreatResult result = new DeviceThreatResult();
        result.threats = new List<String>();
        result.riskScore = 0;
        
        try {
            String deviceFingerprint = (String) context.get('deviceFingerprint');
            String osVersion = (String) context.get('osVersion');
            String browserVersion = (String) context.get('browserVersion');
            Boolean isJailbroken = (Boolean) context.get('isJailbroken');
            Boolean hasAntivirus = (Boolean) context.get('hasAntivirus');
            
            // Check device reputation
            if (String.isNotBlank(deviceFingerprint)) {
                List<DeviceThreatReport__c> deviceThreats = [
                    SELECT Id, ThreatType__c, RiskLevel__c, LastReported__c
                    FROM DeviceThreatReport__c 
                    WHERE DeviceFingerprint__c = :deviceFingerprint 
                    AND IsActive__c = true
                ];
                
                for (DeviceThreatReport__c threat : deviceThreats) {
                    switch on threat.RiskLevel__c {
                        when 'CRITICAL' {
                            result.riskScore += 60;
                            result.threats.add('Critical device threat: ' + threat.ThreatType__c);
                        }
                        when 'HIGH' {
                            result.riskScore += 40;
                            result.threats.add('High-risk device detected: ' + threat.ThreatType__c);
                        }
                        when 'MEDIUM' {
                            result.riskScore += 25;
                            result.threats.add('Medium-risk device: ' + threat.ThreatType__c);
                        }
                    }
                }
            }
            
            // Check for jailbroken/rooted devices
            if (isJailbroken == true) {
                result.riskScore += 35;
                result.threats.add('Jailbroken/rooted device detected');
            }
            
            // Check antivirus status
            if (hasAntivirus == false) {
                result.riskScore += 20;
                result.threats.add('No antivirus protection detected');
            }
            
            // Check OS version for known vulnerabilities
            if (String.isNotBlank(osVersion)) {
                List<VulnerableVersion__c> vulnerabilities = [
                    SELECT Id, Severity__c, Description__c
                    FROM VulnerableVersion__c 
                    WHERE OSVersion__c = :osVersion 
                    AND IsActive__c = true
                ];
                
                for (VulnerableVersion__c vuln : vulnerabilities) {
                    switch on vuln.Severity__c {
                        when 'CRITICAL' {
                            result.riskScore += 45;
                            result.threats.add('Critical OS vulnerability: ' + vuln.Description__c);
                        }
                        when 'HIGH' {
                            result.riskScore += 30;
                            result.threats.add('High-severity OS vulnerability: ' + vuln.Description__c);
                        }
                        when 'MEDIUM' {
                            result.riskScore += 15;
                            result.threats.add('Medium-severity OS vulnerability: ' + vuln.Description__c);
                        }
                    }
                }
            }
            
            // Check browser security
            if (String.isNotBlank(browserVersion)) {
                if (isOutdatedBrowser(browserVersion)) {
                    result.riskScore += 25;
                    result.threats.add('Outdated browser version detected: ' + browserVersion);
                }
            }
            
            // Check for development/debugging tools
            Boolean hasDevTools = (Boolean) context.get('hasDevTools');
            if (hasDevTools == true) {
                result.riskScore += 20;
                result.threats.add('Developer tools detected');
            }
            
        } catch (Exception e) {
            System.debug('Device threat analysis error: ' + e.getMessage());
            result.riskScore = 10;
            result.threats.add('Error in device threat analysis');
        }
        
        return result;
    }
    
    private static DataAccessThreatResult analyzeDataAccessThreats(String userId, String activity, Map<String, Object> context) {
        DataAccessThreatResult result = new DataAccessThreatResult();
        result.threats = new List<String>();
        result.riskScore = 0;
        
        try {
            String resourceId = (String) context.get('resourceId');
            String dataClassification = (String) context.get('dataClassification');
            Integer recordCount = (Integer) context.get('recordCount');
            
            // Check data sensitivity
            if (String.isNotBlank(dataClassification)) {
                switch on dataClassification {
                    when 'HIGHLY_CONFIDENTIAL' {
                        result.riskScore += 20;
                        result.threats.add('Access to highly confidential data');
                    }
                    when 'CONFIDENTIAL' {
                        result.riskScore += 15;
                        result.threats.add('Access to confidential data');
                    }
                    when 'RESTRICTED' {
                        result.riskScore += 10;
                        result.threats.add('Access to restricted data');
                    }
                }
            }
            
            // Check for bulk data access
            if (recordCount != null && recordCount > 1000) {
                result.riskScore += 30;
                result.threats.add('Bulk data access detected: ' + recordCount + ' records');
            }
            
            // Check user's typical data access patterns
            List<AggregateResult> dataAccessBaseline = [
                SELECT AVG(RecordCount__c) avgRecords, MAX(RecordCount__c) maxRecords
                FROM DataAccessLog__c 
                WHERE UserId__c = :userId 
                AND ActivityType__c = :activity
                AND CreatedDate = LAST_N_DAYS:30
            ];
            
            if (!dataAccessBaseline.isEmpty() && recordCount != null) {
                Decimal avgRecords = (Decimal) dataAccessBaseline[0].get('avgRecords');
                Decimal maxRecords = (Decimal) dataAccessBaseline[0].get('maxRecords');
                
                if (avgRecords != null && recordCount > (avgRecords * 5)) {
                    result.riskScore += 25;
                    result.threats.add('Accessing significantly more data than typical: ' +
                        recordCount + ' vs avg ' + avgRecords.intValue());
                }
            }
            
            // Check for unauthorized data types
            List<String> accessibleDataTypes = getUserDataTypePermissions(userId);
            String requestedDataType = (String) context.get('dataType');
            
            if (String.isNotBlank(requestedDataType) && !accessibleDataTypes.contains(requestedDataType)) {
                result.riskScore += 40;
                result.threats.add('Unauthorized data type access attempt: ' + requestedDataType);
            }
            
            // Check for cross-department data access
            String userDepartment = getUserDepartment(userId);
            String resourceDepartment = (String) context.get('resourceDepartment');
            
            if (String.isNotBlank(userDepartment) && String.isNotBlank(resourceDepartment) &&
            userDepartment != resourceDepartment) {
                result.riskScore += 15;
                result.threats.add('Cross-department data access: ' + userDepartment + ' → ' + resourceDepartment);
            }
            
        } catch (Exception e) {
            System.debug('Data access threat analysis error: ' + e.getMessage());
            result.riskScore = 10;
            result.threats.add('Error in data access threat analysis');
        }
        
        return result;
    }
    
    // Helper methods
    private static Boolean isTorExitNode(String ipAddress) {
        // Implementation would check against Tor exit node lists
        List<TorExitNode__c> torNodes = [
            SELECT Id FROM TorExitNode__c 
            WHERE IPAddress__c = :ipAddress 
            AND LastUpdated__c = TODAY
        ];
        return !torNodes.isEmpty();
    }
    
  private static Boolean isKnownProxy(String ipAddress) {
    // Implementation would check against known proxy/VPN IP ranges
    List<ProxyService__c> proxyServices = [
        SELECT Id 
        FROM ProxyService__c 
        WHERE IPRange__c LIKE :('%' + ipAddress + '%') 
        AND IsActive__c = true
    ];
    return !proxyServices.isEmpty();
}

    
    private static List<String> getSuspiciousDomains() {
        List<String> domains = new List<String>();
        List<SuspiciousDomain__c> suspiciousDomains = [
        SELECT DomainName__c FROM SuspiciousDomain__c 
        WHERE IsActive__c = true
    ];
        for (SuspiciousDomain__c domain : suspiciousDomains) {
            domains.add(domain.DomainName__c);
        }
        return domains;
    }
    
    private static String extractDomain(String url) {
        try {
            if (String.isBlank(url)) return '';
            String domain = url;
            if (domain.startsWith('http://') || domain.startsWith('https://')) {
                domain = domain.substring(domain.indexOf('://') + 3);
            }
            if (domain.contains('/')) {
                domain = domain.substring(0, domain.indexOf('/'));
            }
            return domain;
        } catch (Exception e) {
            System.debug('Domain extraction error: ' + e.getMessage());
            return '';
        }
    }
    
    private static Boolean isOutdatedBrowser(String browserVersion) {
        // Implementation would check against known outdated browser versions
        List<OutdatedBrowser__c> outdatedBrowsers = [
        SELECT Id FROM OutdatedBrowser__c 
        WHERE BrowserVersion__c = :browserVersion 
        AND IsActive__c = true
    ];
        return !outdatedBrowsers.isEmpty();
    }
    
    private static List<String> getUserDataTypePermissions(String userId) {
        List<String> permissions = new List<String>();
        List<UserDataPermission__c> userPermissions = [
        SELECT DataType__c FROM UserDataPermission__c 
        WHERE UserId__c = :userId AND IsActive__c = true
    ];
        for (UserDataPermission__c permission : userPermissions) {
            permissions.add(permission.DataType__c);
        }
        return permissions;
    }
    
    private static String getUserDepartment(String userId) {
        try {
            User userRecord = [
            SELECT Department FROM User 
            WHERE Id = :userId LIMIT 1
        ];
            return userRecord.Department;
        } catch (Exception e) {
            System.debug('Get user department error: ' + e.getMessage());
            return '';
        }
    }
    
    private static TemporalThreatResult analyzeTemporalThreats(String userId, Map<String, Object> context) {
        TemporalThreatResult result = new TemporalThreatResult();
        result.threats = new List<String>();
        result.riskScore = 0;
        
        try {
            DateTime currentTime = System.now();
            Integer currentHour = currentTime.hour();
            Integer currentDay = Math.mod(currentTime.dayOfYear(), 7); // 0=Sunday, 6=Saturday
            
            // Check for unusual access times
            List<AggregateResult> userAccessPatterns = [
            SELECT HOUR_IN_DAY(CreatedDate) accessHour, COUNT(Id) frequency
            FROM UserActivity__c 
            WHERE UserId__c = :userId 
            AND CreatedDate = LAST_N_DAYS:30 
            GROUP BY HOUR_IN_DAY(CreatedDate)
        ];
            
            // Build typical access hours
            Set<Integer> typicalHours = new Set<Integer>();
            for (AggregateResult pattern : userAccessPatterns) {
                Integer hour = (Integer) pattern.get('accessHour');
                Integer frequency = (Integer) pattern.get('frequency');
                if (frequency > 2) { // More than 2 accesses in this hour over 30 days
                    typicalHours.add(hour);
                }
            }
            
            if (!typicalHours.isEmpty() && !typicalHours.contains(currentHour)) {
                result.riskScore += 20;
                result.threats.add('Access at unusual time: ' + currentHour + ':00 (typical: ' + typicalHours + ')');
            }
            
            // Check for holiday/weekend access with sensitive data
            String dataClassification = (String) context.get('dataClassification');
            if ((currentDay == 0 || currentDay == 6) && // Weekend
            ('CONFIDENTIAL'.equals(dataClassification) || 'HIGHLY_CONFIDENTIAL'.equals(dataClassification))) {
                result.riskScore += 25;
                result.threats.add('Weekend access to sensitive data');
            }
            
            // Check access during known maintenance windows
            List<MaintenanceWindow__c> activeMaintenanceWindows = [
            SELECT Id, Description__c FROM MaintenanceWindow__c 
            WHERE StartTime__c <= :currentTime 
            AND EndTime__c >= :currentTime 
            AND IsActive__c = true
        ];
            
            if (!activeMaintenanceWindows.isEmpty()) {
                result.riskScore += 15;
                result.threats.add('Access during maintenance window');
            }
            
           // Calculate 1 hour ago
Datetime oneHourAgo = System.now().addHours(-1);

// Check for rapid successive logins
List<LoginHistory> recentLogins = [
    SELECT Id, LoginTime, SourceIp 
    FROM LoginHistory 
    WHERE UserId = :userId
    AND LoginTime >= :oneHourAgo
    ORDER BY LoginTime DESC
];

            
            if (recentLogins.size() > 5) {
                result.riskScore += 30;
                result.threats.add('Multiple logins in short timeframe: ' + recentLogins.size() + ' in 1 hour');
            }
            
            // Check for impossible travel
            if (recentLogins.size() >= 2) {
                String currentIP = (String) context.get('ipAddress');
                String previousIP = recentLogins[1].SourceIp;
                
                if (String.isNotBlank(currentIP) && String.isNotBlank(previousIP) &&
                !currentIP.equals(previousIP)) {
                    
                    // Simple check - in real implementation, would use geolocation API
                    if (isImpossibleTravel(previousIP, currentIP, recentLogins[1].LoginTime, currentTime)) {
                        result.riskScore += 45;
                        result.threats.add('Impossible travel detected: ' + previousIP + ' → ' + currentIP);
                    }
                }
            }
            
        } catch (Exception e) {
            System.debug('Temporal threat analysis error: ' + e.getMessage());
            result.riskScore = 10;
            result.threats.add('Error in temporal threat analysis');
        }
        
        return result;
    }
    
    private static Boolean isImpossibleTravel(String fromIP, String toIP, DateTime fromTime, DateTime toTime) {
        // Simplified impossible travel detection
        // In production, would use geolocation services to calculate distances and travel time
        try {
            // Get approximate locations for IPs
            String fromCountry = getCountryForIP(fromIP);
            String toCountry = getCountryForIP(toIP);
            
            if (String.isBlank(fromCountry) || String.isBlank(toCountry)) {
                return false;
            }
            
            // If different countries and less than 2 hours apart, flag as suspicious
            if (!fromCountry.equals(toCountry)) {
                Long timeDiffMinutes = (toTime.getTime() - fromTime.getTime()) / 60000;
                return timeDiffMinutes < 120; // Less than 2 hours
            }
            
            return false;
        } catch (Exception e) {
            System.debug('Impossible travel check error: ' + e.getMessage());
            return false;
        }
    }
    
    private static String getCountryForIP(String ipAddress) {
        // Implementation would use IP geolocation service
        List<IPGeolocation__c> geoData = [
        SELECT Country__c FROM IPGeolocation__c 
        WHERE IPAddress__c = :ipAddress LIMIT 1
    ];
        return geoData.isEmpty() ? '' : geoData[0].Country__c;
    }
    
    private static String calculateThreatLevel(Decimal riskScore) {
        if (riskScore >= 80) return 'CRITICAL';
        if (riskScore >= 60) return 'HIGH';
        if (riskScore >= 40) return 'MEDIUM';
        if (riskScore >= 20) return 'LOW';
        return 'MINIMAL';
    }
    
    private static List<String> generateRecommendations(ThreatAssessmentResult result) {
        List<String> recommendations = new List<String>();
        
        switch on result.threatLevel {
            when 'CRITICAL' {
                recommendations.add('Immediately revoke user access');
                recommendations.add('Initiate security incident response');
                recommendations.add('Require security team approval for future access');
                recommendations.add('Mandatory security review and training');
            }
            when 'HIGH' {
                recommendations.add('Require multi-factor authentication');
                recommendations.add('Limit access to non-sensitive resources only');
                recommendations.add('Increase monitoring and logging');
                recommendations.add('Schedule security assessment within 24 hours');
            }
            when 'MEDIUM' {
                recommendations.add('Enable enhanced monitoring');
                recommendations.add('Require supervisor approval for sensitive actions');
                recommendations.add('Implement additional identity verification');
            }
            when 'LOW' {
                recommendations.add('Continue normal monitoring');
                recommendations.add('Log activity for future analysis');
            }
            when 'MINIMAL' {
                recommendations.add('Standard monitoring protocols');
            }
        }
        
        return recommendations;
    }
    
    private static void logThreatAssessment(String userId, String activity, ThreatAssessmentResult result, Map<String, Object> context) {
        try {
            ThreatAssessmentLog__c log = new ThreatAssessmentLog__c();
            log.UserId__c = userId;
            log.Activity__c = activity;
            log.ThreatLevel__c = result.threatLevel;
            log.RiskScore__c = result.riskScore;
            log.ThreatsDetected__c = String.join(result.threats, '; ');
            log.Recommendations__c = String.join(result.recommendations, '; ');
            log.AssessmentTimestamp__c = System.now();
            log.Context__c = JSON.serialize(context);
            
            insert log;
        } catch (Exception e) {
            System.debug('Threat assessment logging error: ' + e.getMessage());
        }
    }
    
    private static void triggerThreatAlert(String userId, String activity, ThreatAssessmentResult result) {
        try {
            // Create security incident
            SecurityIncident__c incident = new SecurityIncident__c();
            incident.UserId__c = userId;
            incident.IncidentType__c = 'THREAT_DETECTED';
            incident.Severity__c = result.threatLevel;
            incident.Description__c = 'High-risk threat detected during ' + activity + '. Threats: ' + String.join(result.threats, ', ');
            incident.Status__c = 'NEW';
            incident.DetectedTimestamp__c = System.now();
            incident.RiskScore__c = result.riskScore;
            
            insert incident;
            
            // Send immediate alerts to security team
            List<SecurityTeamMember__c> securityTeam = [
            SELECT Email__c, AlertType__c FROM SecurityTeamMember__c 
            WHERE IsActive__c = true 
            AND AlertType__c = 'THREAT_DETECTION'
        ];
            
            for (SecurityTeamMember__c member : securityTeam) {
                EmailNotificationService.sendThreatAlert(member.Email__c, incident.Id, result);
            }
            
            // Auto-trigger immediate response for critical threats
            if (result.threatLevel == 'CRITICAL') {
                initiateEmergencyResponse(userId, incident.Id, result);
            }
            
        } catch (Exception e) {
            System.debug('Threat alert trigger error: ' + e.getMessage());
        }
    }
    
    private static void initiateEmergencyResponse(String userId, String incidentId, ThreatAssessmentResult result) {
        try {
            // Create emergency response workflow
            EmergencyResponse__c response = new EmergencyResponse__c();
            response.UserId__c = userId;
            response.IncidentId__c = incidentId;
            response.ResponseType__c = 'AUTO_TRIGGERED';
            response.Status__c = 'INITIATED';
            response.ResponseTimestamp__c = System.now();
            response.Actions__c = String.join(result.recommendations, '; ');
            
            insert response;
            
            // Automatically disable user access for critical threats
            if (result.riskScore >= 90) {
                disableUserAccess(userId, 'CRITICAL_THREAT_AUTO_DISABLE');
            }
            
        } catch (Exception e) {
            System.debug('Emergency response initiation error: ' + e.getMessage());
        }
    }
    
    private static void disableUserAccess(String userId, String reason) {
        try {
            User userRecord = [SELECT Id, IsActive FROM User WHERE Id = :userId LIMIT 1];
            userRecord.IsActive = false;
            
            // Create audit record
            UserAccessChange__c auditRecord = new UserAccessChange__c();
            auditRecord.UserId__c = userId;
            auditRecord.ChangeType__c = 'DISABLED';
            auditRecord.Reason__c = reason;
            auditRecord.ChangedBy__c = UserInfo.getUserId();
            auditRecord.ChangeTimestamp__c = System.now();
            
            update userRecord;
            insert auditRecord;
            
        } catch (Exception e) {
            System.debug('User access disable error: ' + e.getMessage());
        }
    }
    
    // Result classes
    public class ThreatAssessmentResult {
        @AuraEnabled public String threatLevel;
        @AuraEnabled public Decimal riskScore;
        @AuraEnabled public List<String> threats;
        @AuraEnabled public List<String> recommendations;
    }
    
    public class BehavioralThreatResult {
        public List<String> threats;
        public Decimal riskScore;
    }
    
    public class NetworkThreatResult {
        public List<String> threats;
        public Decimal riskScore;
    }
    
    public class DeviceThreatResult {
        public List<String> threats;
        public Decimal riskScore;
    }
    
    public class DataAccessThreatResult {
        public List<String> threats;
        public Decimal riskScore;
    }
    
    public class TemporalThreatResult {
        public List<String> threats;
        public Decimal riskScore;
    }
}

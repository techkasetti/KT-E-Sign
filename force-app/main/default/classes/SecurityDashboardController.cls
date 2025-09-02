public class SecurityDashboardController {
    
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getThreatMetrics() {
        Map<String, Object> metrics = new Map<String, Object>();
        
        try {
            // Get threat level distribution
           Map<String, Integer> threatDistribution = new Map<String, Integer>();

List<AggregateResult> threatStats = [
    SELECT ThreatLevel__c, COUNT(Id) threatCount
    FROM ThreatAssessmentLog__c 
    WHERE CreatedDate = TODAY
    GROUP BY ThreatLevel__c
];

for (AggregateResult stat : threatStats) {
    String level = (String) stat.get('ThreatLevel__c');
    Integer count = (Integer) stat.get('threatCount');
    threatDistribution.put(level, count);
}
metrics.put('threatLevelDistribution', threatDistribution);

// Get average risk score
List<AggregateResult> riskScoreStats = [
    SELECT AVG(RiskScore__c) avgRisk, MAX(RiskScore__c) maxRisk
    FROM ThreatAssessmentLog__c 
    WHERE CreatedDate = TODAY
];

if (!riskScoreStats.isEmpty()) {
    metrics.put('averageRiskScore', riskScoreStats[0].get('avgRisk'));
    metrics.put('maxRiskScore', riskScoreStats[0].get('maxRisk'));
}

// Get risk score history for trending
List<RiskScoreHistory> riskHistory = new List<RiskScoreHistory>();
List<AggregateResult> historyStats = [
    SELECT DAY_ONLY(CreatedDate) day, AVG(RiskScore__c) avgScore, MAX(RiskScore__c) maxScore
    FROM ThreatAssessmentLog__c 
    WHERE CreatedDate = LAST_N_DAYS:7
    GROUP BY DAY_ONLY(CreatedDate)
    ORDER BY DAY_ONLY(CreatedDate)
];

for (AggregateResult stat : historyStats) {
    Date day = (Date) stat.get('day');
    Decimal avgScore = (Decimal) stat.get('avgScore');
    Decimal maxScore = (Decimal) stat.get('maxScore');
    
    RiskScoreHistory history = new RiskScoreHistory();
    history.timestamp = day.format();
    history.avgRiskScore = avgScore != null ? avgScore.intValue() : 0;
    history.maxRiskScore = maxScore != null ? maxScore.intValue() : 0;
    riskHistory.add(history);
}
metrics.put('riskScoreHistory', riskHistory);

// Get active user metrics
List<AggregateResult> userStats = [
    SELECT COUNT_DISTINCT(UserId__c) activeUsers
    FROM ThreatAssessmentLog__c 
    WHERE CreatedDate = TODAY
];
metrics.put('activeUsers', userStats.isEmpty() ? 0 : userStats[0].get('activeUsers'));

// Get suspicious activity count
List<AggregateResult> suspiciousStats = [
    SELECT COUNT(Id) suspiciousCount
    FROM ThreatAssessmentLog__c 
    WHERE CreatedDate = TODAY AND RiskScore__c >= 40
];
metrics.put('suspiciousActivities', suspiciousStats.isEmpty() ? 0 : suspiciousStats[0].get('suspiciousCount'));

// Get blocked attempts
List<AggregateResult> blockedStats = [
    SELECT COUNT(Id) blockedCount
    FROM SecurityIncident__c 
    WHERE CreatedDate = TODAY AND Status__c = 'BLOCKED'
];
metrics.put('blockedAttempts', blockedStats.isEmpty() ? 0 : blockedStats[0].get('blockedCount'));

// Get IP threat analysis
List<IPThreatSummary> ipThreats = new List<IPThreatSummary>();
List<AggregateResult> ipStats = [
    SELECT IPAddress__c ip, ThreatType__c threatType, RiskLevel__c riskLevel, COUNT(Id) occurrences
    FROM ThreatIntelligence__c 
    WHERE IsActive__c = true AND LastSeen__c = TODAY
    GROUP BY IPAddress__c, ThreatType__c, RiskLevel__c
    ORDER BY COUNT(Id) DESC
    LIMIT 10
];

for (AggregateResult stat : ipStats) {
    IPThreatSummary threat = new IPThreatSummary();
    threat.ip = (String) stat.get('ip');
    threat.threatType = (String) stat.get('threatType');
    threat.riskLevel = (String) stat.get('riskLevel');
    threat.occurrences = (Integer) stat.get('occurrences');
    threat.badgeVariant = getBadgeVariant(threat.riskLevel);
    ipThreats.add(threat);
}
metrics.put('ipThreats', ipThreats);

// Get geographic data
List<GeoThreatData> geoData = new List<GeoThreatData>();
List<AggregateResult> geoStats = [
    SELECT Country__c country, COUNT(Id) threatCount, AVG(RiskScore__c) avgRisk
    FROM ThreatAssessmentLog__c 
    WHERE CreatedDate = LAST_N_DAYS:7 AND Country__c != null
    GROUP BY Country__c
    ORDER BY COUNT(Id) DESC
    LIMIT 20
];

for (AggregateResult stat : geoStats) {
    GeoThreatData geo = new GeoThreatData();
    geo.country = (String) stat.get('country');
    geo.threatCount = (Integer) stat.get('threatCount');
    geo.avgRiskScore = stat.get('avgRisk') != null ? ((Decimal) stat.get('avgRisk')).intValue() : 0;
    geoData.add(geo);
}
metrics.put('geoData', geoData);

// Get compliance metrics
ComplianceMetrics compliance = getComplianceMetrics();
metrics.put('complianceScore', compliance.overallScore);
metrics.put('complianceDetails', compliance.details);
metrics.put('complianceViolations', compliance.recentViolations);

// Get system health status
String systemHealth = calculateSystemHealth();
metrics.put('systemHealth', systemHealth);

        } catch (Exception e) {
            System.debug('Error getting threat metrics: ' + e.getMessage());
            // Return default metrics
            metrics.put('averageRiskScore', 0);
            metrics.put('systemHealth', 'UNKNOWN');
        }
        
        return metrics;
    }
    
    @AuraEnabled(cacheable=false)
    public static List<ActiveThreat> getActiveThreats() {
        List<ActiveThreat> activeThreats = new List<ActiveThreat>();
        
        try {
            List<ThreatAssessmentLog__c> threats = [
                SELECT Id, UserId__c, ThreatLevel__c, RiskScore__c, ThreatsDetected__c, 
                       AssessmentTimestamp__c, Activity__c, User__r.Name
                FROM ThreatAssessmentLog__c 
                WHERE CreatedDate = TODAY AND RiskScore__c >= 40
                ORDER BY RiskScore__c DESC, AssessmentTimestamp__c DESC
                LIMIT 50
            ];
            
            for (ThreatAssessmentLog__c threat : threats) {
                ActiveThreat activeThreat = new ActiveThreat();
                activeThreat.id = threat.Id;
                activeThreat.userId = threat.User__r.Name != null ? threat.User__r.Name : threat.UserId__c;
                activeThreat.threatLevel = threat.ThreatLevel__c;
                activeThreat.riskScore = threat.RiskScore__c.intValue();
                activeThreat.description = threat.ThreatsDetected__c;
                activeThreat.activity = threat.Activity__c;
                activeThreat.timestamp = threat.AssessmentTimestamp__c;
                activeThreat.formattedTimestamp = formatTimestamp(threat.AssessmentTimestamp__c);
                activeThreats.add(activeThreat);
            }
            
        } catch (Exception e) {
            System.debug('Error getting active threats: ' + e.getMessage());
        }
        
        return activeThreats;
    }
    
    @AuraEnabled(cacheable=false)
    public static List<SecurityAlert> getSecurityAlerts() {
        List<SecurityAlert> alerts = new List<SecurityAlert>();
        
        try {
            List<SecurityIncident__c> incidents = [
                SELECT Id, IncidentType__c, Severity__c, Description__c, 
                       DetectedTimestamp__c, Status__c, UserId__c, User__r.Name
                FROM SecurityIncident__c 
                WHERE CreatedDate = TODAY
                ORDER BY DetectedTimestamp__c DESC
                LIMIT 25
            ];
            
            for (SecurityIncident__c incident : incidents) {
                SecurityAlert alert = new SecurityAlert();
                alert.id = incident.Id;
                alert.title = incident.IncidentType__c;
                alert.message = incident.Description__c;
                alert.severity = incident.Severity__c;
                alert.status = incident.Status__c;
                alert.timestamp = incident.DetectedTimestamp__c;
                alert.formattedTimestamp = formatTimestamp(incident.DetectedTimestamp__c);
                alert.userId = incident.User__r.Name != null ? incident.User__r.Name : incident.UserId__c;
                alert.variant = getAlertVariant(incident.Severity__c);
                alert.iconName = getAlertIcon(incident.IncidentType__c);
                alerts.add(alert);
            }
            
        } catch (Exception e) {
            System.debug('Error getting security alerts: ' + e.getMessage());
        }
        
        return alerts;
    }
    
    private static String getBadgeVariant(String riskLevel) {
        switch on riskLevel {
            when 'CRITICAL' { return 'error'; }
            when 'HIGH' { return 'warning'; }
            when 'MEDIUM' { return 'base'; }
            when 'LOW' { return 'success'; }
            when else { return 'base'; }
        }
    }
    
    private static String getAlertVariant(String severity) {
        switch on severity {
            when 'CRITICAL' { return 'error'; }
            when 'HIGH' { return 'warning'; }
            when 'MEDIUM' { return 'base'; }
            when 'LOW' { return 'success'; }
            when else { return 'base'; }
        }
    }
    
    private static String getAlertIcon(String incidentType) {
        switch on incidentType {
            when 'THREAT_DETECTED' { return 'utility:warning'; }
            when 'UNAUTHORIZED_ACCESS' { return 'utility:lock'; }
            when 'DATA_BREACH' { return 'utility:database'; }
            when 'SUSPICIOUS_ACTIVITY' { return 'utility:search'; }
            when else { return 'utility:notification'; }
        }
    }
    
    private static ComplianceMetrics getComplianceMetrics() {
        ComplianceMetrics metrics = new ComplianceMetrics();
        
        try {
            // Calculate overall compliance score
            List<AggregateResult> complianceStats = [
                SELECT AVG(ComplianceScore__c) avgScore
                FROM ComplianceAssessment__c 
                WHERE AssessmentDate__c = LAST_N_DAYS:30
            ];
            
            if (!complianceStats.isEmpty() && complianceStats[0].get('avgScore') != null) {
                metrics.overallScore = ((Decimal) complianceStats[0].get('avgScore')).intValue();
            } else {
                metrics.overallScore = 85; // Default score
            }
            
            // Get compliance details by standard
            List<ComplianceDetail> details = new List<ComplianceDetail>();
            List<AggregateResult> detailStats = [
                SELECT Standard__c, AVG(ComplianceScore__c) avgScore, COUNT(Id) assessments
                FROM ComplianceAssessment__c 
                WHERE AssessmentDate__c = LAST_N_DAYS:30
                GROUP BY Standard__c
            ];
            
            for (AggregateResult stat : detailStats) {
                ComplianceDetail detail = new ComplianceDetail();
                detail.standard = (String) stat.get('Standard__c');
                Decimal avgScore = (Decimal) stat.get('avgScore');
                detail.score = avgScore != null ? avgScore.intValue() : 0;
                detail.status = detail.score >= 90 ? 'COMPLIANT' : 
                              detail.score >= 70 ? 'PARTIAL' : 'NON_COMPLIANT';
                detail.statusVariant = detail.score >= 90 ? 'success' : 
                                      detail.score >= 70 ? 'warning' : 'error';
                details.add(detail);
            }
            metrics.details = details;
            
            // Get recent violations
            List<ComplianceViolation> violations = new List<ComplianceViolation>();
            List<ComplianceViolationLog__c> violationLogs = [
                SELECT Id, ViolationType__c, Severity__c, Description__c, 
                       DetectedDate__c, Status__c, UserId__c, User__r.Name
                FROM ComplianceViolationLog__c 
                WHERE DetectedDate__c = LAST_N_DAYS:7
                ORDER BY DetectedDate__c DESC
                LIMIT 10
            ];
            
            for (ComplianceViolationLog__c log : violationLogs) {
                ComplianceViolation violation = new ComplianceViolation();
                violation.id = log.Id;
                violation.violationType = log.ViolationType__c;
                violation.severity = log.Severity__c;
                violation.description = log.Description__c;
                violation.detectedDate = log.DetectedDate__c;
                violation.status = log.Status__c;
                violation.userId = log.User__r.Name != null ? log.User__r.Name : log.UserId__c;
                violations.add(violation);
            }
            metrics.recentViolations = violations;
            
        } catch (Exception e) {
            System.debug('Error getting compliance metrics: ' + e.getMessage());
            metrics.overallScore = 0;
            metrics.details = new List<ComplianceDetail>();
            metrics.recentViolations = new List<ComplianceViolation>();
        }
        
        return metrics;
    }
    
    private static String calculateSystemHealth() {
        try {
            // Check critical system metrics
            Decimal avgProcessingTime = getAverageProcessingTime();
            Decimal systemUptime = getSystemUptime();
            Integer criticalIncidents = getCriticalIncidentCount();
            
            // Determine health status based on thresholds
            if (avgProcessingTime > 5.0 || systemUptime < 99.0 || criticalIncidents > 5) {
                return 'CRITICAL';
            } else if (avgProcessingTime > 3.0 || systemUptime < 99.5 || criticalIncidents > 2) {
                return 'DEGRADED';
            } else {
                return 'HEALTHY';
            }
            
        } catch (Exception e) {
            System.debug('Error calculating system health: ' + e.getMessage());
            return 'UNKNOWN';
        }
    }
    
    private static Decimal getAverageProcessingTime() {
        List<AggregateResult> timeStats = [
            SELECT AVG(ProcessingTime__c) avgTime
            FROM PerformanceMetric__c 
            WHERE MetricDate__c = TODAY
        ];
        return timeStats.isEmpty() || timeStats[0].get('avgTime') == null ? 
               2.0 : (Decimal) timeStats[0].get('avgTime');
    }
    private static Decimal getSystemUptime() {
    List<AggregateResult> uptimeStats = [
        SELECT AVG(UptimePercentage__c) avgUptime
        FROM SystemHealthMetric__c
        WHERE MetricDate__c = LAST_N_DAYS:1
    ];
    
    if (!uptimeStats.isEmpty() && uptimeStats[0].get('avgUptime') != null) {
        return (Decimal)uptimeStats[0].get('avgUptime');
    }
    return 0;



return uptimeStats.isEmpty() || uptimeStats[0].get('avgUptime') == null ? 99.5 : (Decimal) uptimeStats[0].get('avgUptime');
}

private static Integer getCriticalIncidentCount() {
    List<AggregateResult> incidentStats = [
        SELECT COUNT(Id) criticalCount
        FROM SecurityIncident__c
        WHERE CreatedDate = TODAY
        AND Severity__c = 'CRITICAL'
        AND Status__c != 'RESOLVED'
    ];
    
    return incidentStats.isEmpty() ? 0 : (Integer) incidentStats[0].get('criticalCount');
}

private static String formatTimestamp(DateTime timestamp) {
    if (timestamp == null) return '';
    
    DateTime now = System.now();
    Long diffInMinutes = (now.getTime() - timestamp.getTime()) / 60000;
    
    if (diffInMinutes < 1) {
        return 'Just now';
    } else if (diffInMinutes < 60) {
        return diffInMinutes + ' min ago';
    } else if (diffInMinutes < 1440) {
        return (diffInMinutes / 60) + ' hr ago';
    } else {
        return timestamp.format('MMM d, h:mm a');
    }
}

// Data classes for responses
public class RiskScoreHistory {
    @AuraEnabled public String timestamp;
    @AuraEnabled public Integer avgRiskScore;
    @AuraEnabled public Integer maxRiskScore;
}

public class IPThreatSummary {
    @AuraEnabled public String ip;
    @AuraEnabled public String threatType;
    @AuraEnabled public String riskLevel;
    @AuraEnabled public Integer occurrences;
    @AuraEnabled public String badgeVariant;
}

public class GeoThreatData {
    @AuraEnabled public String country;
    @AuraEnabled public Integer threatCount;
    @AuraEnabled public Integer avgRiskScore;
}

public class ActiveThreat {
    @AuraEnabled public String id;
    @AuraEnabled public String userId;
    @AuraEnabled public String threatLevel;
    @AuraEnabled public Integer riskScore;
    @AuraEnabled public String description;
    @AuraEnabled public String activity;
    @AuraEnabled public DateTime timestamp;
    @AuraEnabled public String formattedTimestamp;
}

public class SecurityAlert {
    @AuraEnabled public String id;
    @AuraEnabled public String title;
    @AuraEnabled public String message;
    @AuraEnabled public String severity;
    @AuraEnabled public String status;
    @AuraEnabled public DateTime timestamp;
    @AuraEnabled public String formattedTimestamp;
    @AuraEnabled public String userId;
    @AuraEnabled public String variant;
    @AuraEnabled public String iconName;
}

public class ComplianceMetrics {
    @AuraEnabled public Integer overallScore;
    @AuraEnabled public List<ComplianceDetail> details;
    @AuraEnabled public List<ComplianceViolation> recentViolations;
}

public class ComplianceDetail {
    @AuraEnabled public String standard;
    @AuraEnabled public Integer score;
    @AuraEnabled public String status;
    @AuraEnabled public String statusVariant;
}

public class ComplianceViolation {
    @AuraEnabled public String id;
    @AuraEnabled public String violationType;
    @AuraEnabled public String severity;
    @AuraEnabled public String description;
    @AuraEnabled public DateTime detectedDate;
    @AuraEnabled public String status;
    @AuraEnabled public String userId;
}
}

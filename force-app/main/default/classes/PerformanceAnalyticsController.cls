public class PerformanceAnalyticsController {
    
    @AuraEnabled(cacheable=false)
    public static PerformanceMetrics getPerformanceMetrics() {
        PerformanceMetrics metrics = new PerformanceMetrics();
        
        try {
            // Document generation performance
            metrics.documentMetrics = getDocumentPerformanceMetrics();
            
            // Signature completion analytics
            metrics.signatureMetrics = getSignaturePerformanceMetrics();
            
            // System resource utilization
            metrics.systemMetrics = getSystemResourceMetrics();
            
            // User activity patterns
            metrics.userMetrics = getUserActivityMetrics();
            
            // Compliance performance
            metrics.complianceMetrics = getCompliancePerformanceMetrics();
            
        } catch (Exception e) {
            System.debug('Error retrieving performance metrics: ' + e.getMessage());
            metrics = getDefaultMetrics();
        }
        
        return metrics;
    }
    
    private static DocumentPerformanceMetrics getDocumentPerformanceMetrics() {
        DocumentPerformanceMetrics docMetrics = new DocumentPerformanceMetrics();
        
        try {
            // Document generation times
            List<AggregateResult> generationStats = [
                SELECT 
                    AVG(GenerationTime__c) avgTime,
                    MAX(GenerationTime__c) maxTime,
                    MIN(GenerationTime__c) minTime,
                    COUNT(Id) totalDocs
                FROM DocumentLifecycleConfiguration__c
                WHERE CreatedDate = LAST_N_DAYS:30
                AND GenerationTime__c != null
            ];
            
            if (!generationStats.isEmpty()) {
                AggregateResult stat = generationStats[0];
                docMetrics.avgGenerationTime = (Decimal) stat.get('avgTime');
                docMetrics.maxGenerationTime = (Decimal) stat.get('maxTime');
                docMetrics.minGenerationTime = (Decimal) stat.get('minTime');
                docMetrics.totalDocuments = (Integer) stat.get('totalDocs');
            }
            
            // Document types performance
            List<AggregateResult> typeStats = [
                SELECT 
                    ContractType__c contractType,
                    AVG(GenerationTime__c) avgTime,
                    COUNT(Id) docCount
                FROM DocumentLifecycleConfiguration__c
                WHERE CreatedDate = LAST_N_DAYS:30
                AND GenerationTime__c != null
                GROUP BY ContractType__c
                ORDER BY AVG(GenerationTime__c) DESC
            ];
            
            List<DocumentTypePerformance> typePerformance = new List<DocumentTypePerformance>();
            for (AggregateResult stat : typeStats) {
                DocumentTypePerformance perf = new DocumentTypePerformance();
                perf.contractType = (String) stat.get('contractType');
                perf.avgGenerationTime = (Decimal) stat.get('avgTime');
                perf.documentCount = (Integer) stat.get('docCount');
                typePerformance.add(perf);
            }
            docMetrics.typePerformance = typePerformance;
            
            // Performance trends over time
            List<AggregateResult> trendStats = [
                SELECT 
                    DAY_ONLY(CreatedDate) day,
                    AVG(GenerationTime__c) avgTime,
                    COUNT(Id) docCount
                FROM DocumentLifecycleConfiguration__c
                WHERE CreatedDate = LAST_N_DAYS:14
                AND GenerationTime__c != null
                GROUP BY DAY_ONLY(CreatedDate)
                ORDER BY DAY_ONLY(CreatedDate)
            ];
            
            List<DailyPerformanceTrend> trends = new List<DailyPerformanceTrend>();
            for (AggregateResult stat : trendStats) {
                DailyPerformanceTrend trend = new DailyPerformanceTrend();
                trend.performanceDate = ((Date) stat.get('day')).format();
                trend.avgGenerationTime = (Decimal) stat.get('avgTime');
                trend.documentCount = (Integer) stat.get('docCount');
                trends.add(trend);
            }
            docMetrics.performanceTrends = trends;
            
        } catch (Exception e) {
            System.debug('Error getting document performance metrics: ' + e.getMessage());
        }
        
        return docMetrics;
    }
    
    private static SignaturePerformanceMetrics getSignaturePerformanceMetrics() {
        SignaturePerformanceMetrics sigMetrics = new SignaturePerformanceMetrics();
        
        try {
            // Signature completion rates
            List<AggregateResult> completionStats = [
                SELECT 
                    Status__c,
                    COUNT(Id) statusCount
                FROM Signature_Request__c
                WHERE CreatedDate = LAST_N_DAYS:30
                GROUP BY Status__c
            ];
            
            Integer totalRequests = 0;
            Integer completedRequests = 0;
            Map<String, Integer> statusBreakdown = new Map<String, Integer>();
            
            for (AggregateResult stat : completionStats) {
                String status = (String) stat.get('Status__c');
                Integer count = (Integer) stat.get('statusCount');
                statusBreakdown.put(status, count);
                totalRequests += count;
                
                if (status == 'Signed' || status == 'Completed') {
                    completedRequests += count;
                }
            }
            
            sigMetrics.totalRequests = totalRequests;
            sigMetrics.completedRequests = completedRequests;
            sigMetrics.completionRate = totalRequests > 0 ? (completedRequests * 100.0 / totalRequests) : 0;
            sigMetrics.statusBreakdown = statusBreakdown;
            
            // Average time to signature
            List<AggregateResult> timeStats = [
                SELECT AVG(TimeToSignature__c) avgTime
                FROM Signature_Request__c
                WHERE Status__c IN ('Signed', 'Completed')
                AND CreatedDate = LAST_N_DAYS:30
                AND TimeToSignature__c != null
            ];
            
            if (!timeStats.isEmpty() && timeStats[0].get('avgTime') != null) {
                sigMetrics.avgTimeToSignature = (Decimal) timeStats[0].get('avgTime');
            }
            
            // Signature method preferences
            List<AggregateResult> methodStats = [
                SELECT 
                    SignatureMethod__c method,
                    COUNT(Id) methodCount
                FROM Signature_Request__c
                WHERE Status__c IN ('Signed', 'Completed')
                AND CreatedDate = LAST_N_DAYS:30
                AND SignatureMethod__c != null
                GROUP BY SignatureMethod__c
                ORDER BY COUNT(Id) DESC
            ];
            
            List<SignatureMethodStats> methodPreferences = new List<SignatureMethodStats>();
            for (AggregateResult stat : methodStats) {
                SignatureMethodStats methodStat = new SignatureMethodStats();
                methodStat.method = (String) stat.get('method');
                methodStat.count = (Integer) stat.get('methodCount');
                methodStat.percentage = completedRequests > 0 ? (methodStat.count * 100.0 / completedRequests) : 0;
                methodPreferences.add(methodStat);
            }
            sigMetrics.methodPreferences = methodPreferences;
            
        } catch (Exception e) {
            System.debug('Error getting signature performance metrics: ' + e.getMessage());
        }
        
        return sigMetrics;
    }
    
    private static SystemResourceMetrics getSystemResourceMetrics() {
    SystemResourceMetrics sysMetrics = new SystemResourceMetrics();

    try {
        // CPU and memory utilization
        List<SystemMetricsSnapshot__c> recentSnapshots = [
            SELECT 
                Average_Response_Time__c,
                System_Uptime__c,
                Concurrent_Users__c,
                Cache_Hit_Ratio__c,
                Documents_Generated_Hourly__c,
                Timestamp__c
            FROM SystemMetricsSnapshot__c
            WHERE Timestamp__c >= :System.now().addHours(-24)
            ORDER BY Timestamp__c DESC
            LIMIT 24
        ];

        if (!recentSnapshots.isEmpty()) {
            // Calculate averages
            Decimal totalResponseTime = 0;
            Decimal totalUptime = 0;
            Decimal totalCacheHit = 0;
            Integer maxConcurrentUsers = 0;
            Integer totalDocuments = 0;

            for (SystemMetricsSnapshot__c snapshot : recentSnapshots) {
                if (snapshot.Average_Response_Time__c != null) {
                    totalResponseTime += snapshot.Average_Response_Time__c;
                }
                if (snapshot.System_Uptime__c != null) {
                    totalUptime += snapshot.System_Uptime__c;
                }
                if (snapshot.Cache_Hit_Ratio__c != null) {
                    totalCacheHit += snapshot.Cache_Hit_Ratio__c;
                }
                if (snapshot.Concurrent_Users__c != null && snapshot.Concurrent_Users__c > maxConcurrentUsers) {
                    maxConcurrentUsers = snapshot.Concurrent_Users__c.intValue();
                }
                if (snapshot.Documents_Generated_Hourly__c != null) {
                    totalDocuments += snapshot.Documents_Generated_Hourly__c.intValue();
                }
            }

            Integer snapshotCount = recentSnapshots.size();
            sysMetrics.avgResponseTime = totalResponseTime / snapshotCount;
            sysMetrics.avgUptime = totalUptime / snapshotCount;
            sysMetrics.avgCacheHitRatio = totalCacheHit / snapshotCount;
            sysMetrics.maxConcurrentUsers = maxConcurrentUsers;
            sysMetrics.totalDocumentsGenerated = totalDocuments;

            // Performance trends
            List<HourlyPerformance> hourlyTrends = new List<HourlyPerformance>();
            for (SystemMetricsSnapshot__c snapshot : recentSnapshots) {
                HourlyPerformance hourly = new HourlyPerformance();

                if (snapshot.Timestamp__c != null) {
                    hourly.timestamp = snapshot.Timestamp__c.format('yyyy-MM-dd HH:mm');
                } else {
                    hourly.timestamp = 'N/A';
                }

                hourly.responseTime = snapshot.Average_Response_Time__c != null ? snapshot.Average_Response_Time__c : 0;
                hourly.uptime = snapshot.System_Uptime__c != null ? snapshot.System_Uptime__c : 0;
                hourly.cacheHitRatio = snapshot.Cache_Hit_Ratio__c != null ? snapshot.Cache_Hit_Ratio__c : 0;
                hourly.concurrentUsers = snapshot.Concurrent_Users__c != null ? snapshot.Concurrent_Users__c.intValue() : 0;

                hourlyTrends.add(hourly);
            }

            sysMetrics.hourlyTrends = hourlyTrends;
        }

        // Resource alerts
        List<SystemAlert> resourceAlerts = new List<SystemAlert>();
        List<SystemAlert__c> alerts = [
            SELECT Id, AlertType__c, Message__c, Severity__c, Timestamp__c, IsResolved__c
            FROM SystemAlert__c
            WHERE CreatedDate = TODAY
            AND IsResolved__c = false
            ORDER BY Timestamp__c DESC
            LIMIT 10
        ];

        for (SystemAlert__c alert : alerts) {
            SystemAlert sysAlert = new SystemAlert();
            sysAlert.id = alert.Id;
            sysAlert.alertType = alert.AlertType__c;
            sysAlert.message = alert.Message__c;
            sysAlert.severity = alert.Severity__c;
            sysAlert.timestamp = alert.Timestamp__c;
            sysAlert.variant = getAlertVariant(alert.Severity__c);
            resourceAlerts.add(sysAlert);
        }

        sysMetrics.activeAlerts = resourceAlerts;

    } catch (Exception e) {
        System.debug('⚠️ Error getting system resource metrics: ' + e.getMessage());
    }

    return sysMetrics;
}


private static UserActivityMetrics getUserActivityMetrics() {
    UserActivityMetrics userMetrics = new UserActivityMetrics();
    
    try {
        // Active users in last 24 hours
       List<AggregateResult> activeUserStats = [
    SELECT COUNT_DISTINCT(UserId__c) activeUsers
    FROM AuditTrail__c
    WHERE Timestamp__c >= :System.now().addHours(-24)
];

        
        
        if (!activeUserStats.isEmpty()) {
            userMetrics.activeUsers24h = (Integer) activeUserStats[0].get('activeUsers');
        }
        
        // Most active users
        List<AggregateResult> topUserStats = [
            SELECT UserId__c userId, User__r.Name userName, COUNT(Id) activityCount
            FROM AuditTrail__c
            WHERE Timestamp__c = LAST_N_DAYS:7
            GROUP BY UserId__c, User__r.Name
            ORDER BY COUNT(Id) DESC
            LIMIT 10
        ];
        
        List<TopUser> topUsers = new List<TopUser>();
        for (AggregateResult stat : topUserStats) {
            TopUser user = new TopUser();
            user.userId = (String) stat.get('userId');
            user.userName = (String) stat.get('userName');
            user.activityCount = (Integer) stat.get('activityCount');
            topUsers.add(user);
        }
        userMetrics.topUsers = topUsers;
        
        // Activity by hour patterns
        List<AggregateResult> hourlyActivity = [
            SELECT HOUR_IN_DAY(Timestamp__c) hour, COUNT(Id) activityCount
            FROM AuditTrail__c
            WHERE Timestamp__c = LAST_N_DAYS:7
            GROUP BY HOUR_IN_DAY(Timestamp__c)
            ORDER BY HOUR_IN_DAY(Timestamp__c)
        ];
        
        List<HourlyActivity> activityPatterns = new List<HourlyActivity>();
        for (AggregateResult stat : hourlyActivity) {
            HourlyActivity activity = new HourlyActivity();
            activity.hour = (Integer) stat.get('hour');
            activity.activityCount = (Integer) stat.get('activityCount');
            activityPatterns.add(activity);
        }
        userMetrics.activityPatterns = activityPatterns;
        
        // User session analytics
        List<AggregateResult> sessionStats = [
            SELECT AVG(SessionDuration__c) avgDuration, MAX(SessionDuration__c) maxDuration
            FROM UserSession__c
            WHERE CreatedDate = LAST_N_DAYS:7
            AND SessionDuration__c != null
        ];
        
        if (!sessionStats.isEmpty()) {
            userMetrics.avgSessionDuration = (Decimal) sessionStats[0].get('avgDuration');
            userMetrics.maxSessionDuration = (Decimal) sessionStats[0].get('maxDuration');
        }
        
    } catch (Exception e) {
        System.debug('Error getting user activity metrics: ' + e.getMessage());
    }
    return userMetrics;
}

private static CompliancePerformanceMetrics getCompliancePerformanceMetrics() {
    CompliancePerformanceMetrics compMetrics = new CompliancePerformanceMetrics();
    
    try {
        // Overall compliance score trend
        List<AggregateResult> compliancetrends = [
            SELECT DAY_ONLY(AssessmentDate__c) day, AVG(ComplianceScore__c) avgScore
            FROM ComplianceAssessment__c
            WHERE AssessmentDate__c = LAST_N_DAYS:30
            GROUP BY DAY_ONLY(AssessmentDate__c)
            ORDER BY DAY_ONLY(AssessmentDate__c)
        ];
        
        List<ComplianceTrend> trends = new List<ComplianceTrend>();
        for (AggregateResult stat : compliancetrends) {
            ComplianceTrend trend = new ComplianceTrend();
            trend.assessmentDate = ((Date) stat.get('day')).format();
            trend.avgScore = (Decimal) stat.get('avgScore');
            trends.add(trend);
        }
        compMetrics.complianceTrends = trends;
        
        // Compliance by region
        List<AggregateResult> regionStats = [
            SELECT Region__c, AVG(ComplianceScore__c) avgScore, COUNT(Id) assessmentCount
            FROM ComplianceAssessment__c
            WHERE AssessmentDate__c = LAST_N_DAYS:30
            GROUP BY Region__c
            ORDER BY AVG(ComplianceScore__c) DESC
        ];
        
        List<RegionalCompliance> regionalData = new List<RegionalCompliance>();
        for (AggregateResult stat : regionStats) {
            RegionalCompliance regional = new RegionalCompliance();
            regional.region = (String) stat.get('Region__c');
            regional.avgScore = (Decimal) stat.get('avgScore');
            regional.assessmentCount = (Integer) stat.get('assessmentCount');
            regional.status = regional.avgScore >= 90 ? 'EXCELLENT' : regional.avgScore >= 80 ? 'GOOD' : 'NEEDS_IMPROVEMENT';
            regionalData.add(regional);
        }
        compMetrics.regionalCompliance = regionalData;
        
        // Violation frequency analysis
        List<AggregateResult> violationStats = [
            SELECT ViolationType__c, COUNT(Id) violationCount
            FROM ComplianceViolationLog__c
            WHERE DetectedDate__c = LAST_N_DAYS:30
            GROUP BY ViolationType__c
            ORDER BY COUNT(Id) DESC
        ];
        
        List<ViolationFrequency> violationData = new List<ViolationFrequency>();
        for (AggregateResult stat : violationStats) {
            ViolationFrequency violation = new ViolationFrequency();
            violation.violationType = (String) stat.get('ViolationType__c');
            violation.frequency = (Integer) stat.get('violationCount');
            violation.avgSeverity = (Decimal) stat.get('avgSeverity');
            violationData.add(violation);
        }
        compMetrics.violationFrequency = violationData;
        
    } catch (Exception e) {
        System.debug('Error getting compliance performance metrics: ' + e.getMessage());
    }
    return compMetrics;
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

private static PerformanceMetrics getDefaultMetrics() {
    PerformanceMetrics metrics = new PerformanceMetrics();
    metrics.documentMetrics = new DocumentPerformanceMetrics();
    metrics.signatureMetrics = new SignaturePerformanceMetrics();
    metrics.systemMetrics = new SystemResourceMetrics();
    metrics.userMetrics = new UserActivityMetrics();
    metrics.complianceMetrics = new CompliancePerformanceMetrics();
    return metrics;
}

// Data classes for performance analytics
public class PerformanceMetrics {
    @AuraEnabled public DocumentPerformanceMetrics documentMetrics;
    @AuraEnabled public SignaturePerformanceMetrics signatureMetrics;
    @AuraEnabled public SystemResourceMetrics systemMetrics;
    @AuraEnabled public UserActivityMetrics userMetrics;
    @AuraEnabled public CompliancePerformanceMetrics complianceMetrics;
}

public class DocumentPerformanceMetrics {
    @AuraEnabled public Decimal avgGenerationTime;
    @AuraEnabled public Decimal maxGenerationTime;
    @AuraEnabled public Decimal minGenerationTime;
    @AuraEnabled public Integer totalDocuments;
    @AuraEnabled public List<DocumentTypePerformance> typePerformance;
    @AuraEnabled public List<DailyPerformanceTrend> performanceTrends;
}

public class DocumentTypePerformance {
    @AuraEnabled public String contractType;
    @AuraEnabled public Decimal avgGenerationTime;
    @AuraEnabled public Integer documentCount;
}

public class DailyPerformanceTrend {
    @AuraEnabled public String performanceDate;
    @AuraEnabled public Decimal avgGenerationTime;
    @AuraEnabled public Integer documentCount;
}

public class SignaturePerformanceMetrics {
    @AuraEnabled public Integer totalRequests;
    @AuraEnabled public Integer completedRequests;
    @AuraEnabled public Decimal completionRate;
    @AuraEnabled public Decimal avgTimeToSignature;
    @AuraEnabled public Map<String, Integer> statusBreakdown;
    @AuraEnabled public List<SignatureMethodStats> methodPreferences;
}

public class SignatureMethodStats {
    @AuraEnabled public String method;
    @AuraEnabled public Integer count;
    @AuraEnabled public Decimal percentage;
}

public class SystemResourceMetrics {
    @AuraEnabled public Decimal avgResponseTime;
    @AuraEnabled public Decimal avgUptime;
    @AuraEnabled public Decimal avgCacheHitRatio;
    @AuraEnabled public Integer maxConcurrentUsers;
    @AuraEnabled public Integer totalDocumentsGenerated;
    @AuraEnabled public List<HourlyPerformance> hourlyTrends;
    @AuraEnabled public List<SystemAlert> activeAlerts;
}

public class HourlyPerformance {
    @AuraEnabled public String timestamp;
    @AuraEnabled public Decimal responseTime;
    @AuraEnabled public Decimal uptime;
    @AuraEnabled public Decimal cacheHitRatio;
    @AuraEnabled public Integer concurrentUsers;
}

public class SystemAlert {
    @AuraEnabled public String id;
    @AuraEnabled public String alertType;
    @AuraEnabled public String message;
    @AuraEnabled public String severity;
    @AuraEnabled public DateTime timestamp;
    @AuraEnabled public String variant;
}

public class UserActivityMetrics {
    @AuraEnabled public Integer activeUsers24h;
    @AuraEnabled public List<TopUser> topUsers;
    @AuraEnabled public List<HourlyActivity> activityPatterns;
    @AuraEnabled public Decimal avgSessionDuration;
    @AuraEnabled public Decimal maxSessionDuration;
}

public class TopUser {
    @AuraEnabled public String userId;
    @AuraEnabled public String userName;
    @AuraEnabled public Integer activityCount;
}

public class HourlyActivity {
    @AuraEnabled public Integer hour;
    @AuraEnabled public Integer activityCount;
}

public class CompliancePerformanceMetrics {
    @AuraEnabled public List<ComplianceTrend> complianceTrends;
    @AuraEnabled public List<RegionalCompliance> regionalCompliance;
    @AuraEnabled public List<ViolationFrequency> violationFrequency;
}

public class ComplianceTrend {
    @AuraEnabled public String assessmentDate;
    @AuraEnabled public Decimal avgScore;
}

public class RegionalCompliance {
    @AuraEnabled public String region;
    @AuraEnabled public Decimal avgScore;
    @AuraEnabled public Integer assessmentCount;
    @AuraEnabled public String status;
}

public class ViolationFrequency {
    @AuraEnabled public String violationType;
    @AuraEnabled public Integer frequency;
    @AuraEnabled public Decimal avgSeverity;
}
}
public class AdvancedAnalyticsEngine {
    
    // Analytics constants
    private static final Integer DEFAULT_ANALYTICS_PERIOD_DAYS = 30;
    private static final Integer MAX_ANALYTICS_RECORDS = 10000;
public class AnalyticsReport {
    public String reportType;
    public DateTime generatedAt;
    public DateTime periodStart;
    public DateTime periodEnd;
    public String generatedBy;
    public Map<String, Object> metrics;
    public List<AnalyticsInsight> insights;
    public String executiveSummary;
    public Decimal overallScore;
    public String recommendedActions;
    public Map<String, List<Object>> chartData;
    public Boolean hasAnomalies;
    public List<String> criticalFindings;
    
    public AnalyticsReport() {
        this.metrics = new Map<String, Object>();
        this.insights = new List<AnalyticsInsight>();
        this.chartData = new Map<String, List<Object>>();
        this.criticalFindings = new List<String>();
        this.generatedAt = DateTime.now();
        this.generatedBy = UserInfo.getName();
        this.hasAnomalies = false;
    }
}

/**
 * Individual analytics insight structure
 */
public class AnalyticsInsight {
    public String category;
    public String title;
    public String description;
    public String severity; // LOW, MEDIUM, HIGH, CRITICAL
    public Decimal impact; // 0-100 scale
    public String recommendation;
    public Map<String, Object> supportingData;
    public DateTime discoveredAt;
    
    public AnalyticsInsight(String category, String title, String description, String severity) {
        this.category = category;
        this.title = title;
        this.description = description;
        this.severity = severity;
        this.supportingData = new Map<String, Object>();
        this.discoveredAt = DateTime.now();
    }
}

/**
 * Document generation analytics data
 */
public class DocumentGenerationAnalytics {
    public Integer totalDocuments;
    public Integer successfulGenerations;
    public Integer failedGenerations;
    public Decimal successRate;
    public Decimal averageGenerationTime;
    public Map<String, Integer> documentTypeBreakdown;
    public Map<String, Integer> templateUsageStats;
    public List<String> mostPopularTemplates;
    public Map<String, Decimal> performanceByTemplate;
    public Integer peakHourlyGeneration;
    public List<Object> generationTrends;
    
    public DocumentGenerationAnalytics() {
        this.documentTypeBreakdown = new Map<String, Integer>();
        this.templateUsageStats = new Map<String, Integer>();
        this.mostPopularTemplates = new List<String>();
        this.performanceByTemplate = new Map<String, Decimal>();
        this.generationTrends = new List<Object>();
    }
}

/**
 * Compliance analytics data
 */
public class ComplianceAnalytics {
    public Decimal overallComplianceScore;
    public Map<String, Decimal> regulationScores; // GDPR, HIPAA, SOX, etc.
    public Integer totalViolations;
    public Integer criticalViolations;
    public Integer activeViolations;
    public Map<String, Integer> violationsByType;
    public Map<String, Integer> violationsByRegulation;
    public List<String> topViolationCategories;
    public Decimal complianceTrend; // Positive/negative trend
    public Integer documentsUnderReview;
    public Map<String, Object> riskAssessment;
    
    public ComplianceAnalytics() {
        this.regulationScores = new Map<String, Decimal>();
        this.violationsByType = new Map<String, Integer>();
        this.violationsByRegulation = new Map<String, Integer>();
        this.topViolationCategories = new List<String>();
        this.riskAssessment = new Map<String, Object>();
    }
}

/**
 * User activity analytics
 */
public class UserActivityAnalytics {
    public Integer totalActiveUsers;
    public Integer newUsers;
    public Integer returningUsers;
    public Map<String, Integer> usersByRole;
    public Map<String, Integer> activityByHour;
    public Map<String, Integer> featureUsageStats;
    public List<String> mostActiveUsers;
    public Decimal averageSessionDuration;
    public Integer totalSessions;
    public Map<String, Object> geographicDistribution;
    
    public UserActivityAnalytics() {
        this.usersByRole = new Map<String, Integer>();
        this.activityByHour = new Map<String, Integer>();
        this.featureUsageStats = new Map<String, Integer>();
        this.mostActiveUsers = new List<String>();
        this.geographicDistribution = new Map<String, Object>();
    }
}

/**
 * System performance analytics
 */
public class SystemPerformanceAnalytics {
    public Decimal averageResponseTime;
    public Decimal cacheHitRatio;
    public Decimal systemUptime;
    public Integer totalAPIRequests;
    public Integer failedAPIRequests;
    public Decimal apiSuccessRate;
    public Map<String, Decimal> performanceByEndpoint;
    public List<String> performanceBottlenecks;
    public Map<String, Object> resourceUtilization;
    public Integer concurrentUsersPeak;
    public List<Object> performanceTrends;
    
    public SystemPerformanceAnalytics() {
        this.performanceByEndpoint = new Map<String, Decimal>();
        this.performanceBottlenecks = new List<String>();
        this.resourceUtilization = new Map<String, Object>();
        this.performanceTrends = new List<Object>();
    }
}
public static AnalyticsReport generateComprehensiveReport(String reportType, DateTime periodStart, DateTime periodEnd) {
    try {
        AnalyticsReport report = new AnalyticsReport();
        report.reportType = reportType;
        report.periodStart = periodStart;
        report.periodEnd = periodEnd;
        
        // Generate different types of reports
        switch on reportType.toUpperCase() {
            when 'EXECUTIVE_SUMMARY' {
                generateExecutiveSummaryReport(report);
            }
            when 'DOCUMENT_GENERATION' {
                generateDocumentGenerationReport(report);
            }
            when 'COMPLIANCE_OVERVIEW' {
                generateComplianceReport(report);
            }
            when 'USER_ACTIVITY' {
                generateUserActivityReport(report);
            }
            when 'SYSTEM_PERFORMANCE' {
                generateSystemPerformanceReport(report);
            }
            when 'SECURITY_AUDIT' {
                generateSecurityAuditReport(report);
            }
            when else {
                generateExecutiveSummaryReport(report); // Default
            }
        }
        
        // Store report in custom object for future reference
        storeAnalyticsReport(report);
        
        return report;
        
    } catch (Exception e) {
        System.debug('Analytics report generation error: ' + e.getMessage());
        throw new AnalyticsException('Failed to generate analytics report: ' + e.getMessage());
    }
}

/**
 * Generate executive summary report
 */
private static void generateExecutiveSummaryReport(AnalyticsReport report) {
    // Get high-level metrics
    DocumentGenerationAnalytics docAnalytics = getDocumentGenerationAnalytics(report.periodStart, report.periodEnd);
    ComplianceAnalytics complianceAnalytics = getComplianceAnalytics(report.periodStart, report.periodEnd);
    UserActivityAnalytics userAnalytics = getUserActivityAnalytics(report.periodStart, report.periodEnd);
    SystemPerformanceAnalytics perfAnalytics = getSystemPerformanceAnalytics(report.periodStart, report.periodEnd);
    
    // Populate report metrics
    report.metrics.put('totalDocuments', docAnalytics.totalDocuments);
    report.metrics.put('documentSuccessRate', docAnalytics.successRate);
    report.metrics.put('overallComplianceScore', complianceAnalytics.overallComplianceScore);
    report.metrics.put('activeUsers', userAnalytics.totalActiveUsers);
    report.metrics.put('systemUptime', perfAnalytics.systemUptime);
    report.metrics.put('averageResponseTime', perfAnalytics.averageResponseTime);
    
    // Calculate overall system health score
    Decimal systemHealthScore = calculateSystemHealthScore(docAnalytics, complianceAnalytics, perfAnalytics);
    report.overallScore = systemHealthScore;
    
    // Generate insights
    if (docAnalytics.successRate < 95) {
        report.insights.add(new AnalyticsInsight(
            'PERFORMANCE', 
            'Document Generation Success Rate Below Target',
            'Current success rate is ' + docAnalytics.successRate.format() + '%, below the 95% target.',
            'HIGH'
        ));
        report.hasAnomalies = true;
    }
    
    if (complianceAnalytics.criticalViolations > 0) {
        report.insights.add(new AnalyticsInsight(
            'COMPLIANCE',
            'Critical Compliance Violations Detected',
            complianceAnalytics.criticalViolations + ' critical violations require immediate attention.',
            'CRITICAL'
        ));
        report.criticalFindings.add('Critical compliance violations: ' + complianceAnalytics.criticalViolations);
        report.hasAnomalies = true;
    }
    
    if (perfAnalytics.systemUptime < 99.5) {
        report.insights.add(new AnalyticsInsight(
            'PERFORMANCE',
            'System Uptime Below SLA',
            'System uptime is ' + perfAnalytics.systemUptime.format() + '%, below 99.5% SLA.',
            'HIGH'
        ));
        report.hasAnomalies = true;
    }
    
    // Generate executive summary
    StringBuilder summary = new StringBuilder();
    summary.append('Executive Summary for ').append(report.periodStart.format('MM/dd/yyyy')).append(' - ').append(report.periodEnd.format('MM/dd/yyyy')).append('\n\n');
    summary.append('Key Performance Indicators:\n');
    summary.append('• Documents Generated: ').append(docAnalytics.totalDocuments).append('\n');
    summary.append('• Success Rate: ').append(docAnalytics.successRate.format()).append('%\n');
    summary.append('• Compliance Score: ').append(complianceAnalytics.overallComplianceScore.format()).append('%\n');
    summary.append('• System Health: ').append(systemHealthScore.format()).append('%\n');
    summary.append('• Active Users: ').append(userAnalytics.totalActiveUsers).append('\n\n');
    
    if (report.hasAnomalies) {
        summary.append('⚠️ Critical Issues Requiring Attention:\n');
        for (String finding : report.criticalFindings) {
            summary.append('• ').append(finding).append('\n');
        }
    } else {
        summary.append('✅ All systems operating within normal parameters.\n');
    }
    
    report.executiveSummary = summary.toString();
    
    // Generate chart data for dashboard
    generateExecutiveDashboardCharts(report, docAnalytics, complianceAnalytics, userAnalytics, perfAnalytics);
}
private static DocumentGenerationAnalytics getDocumentGenerationAnalytics(DateTime startTime, DateTime endTime) {
    DocumentGenerationAnalytics analytics = new DocumentGenerationAnalytics();
    
    try {
        // Query document generation records
        List<AggregateResult> docStats = [
            SELECT 
                COUNT(Id) totalDocs,
                COUNT_DISTINCT(Template_Used__c) uniqueTemplates,
                AVG(Generation_Time_Ms__c) avgTime
            FROM DocumentGenerationLog__c 
            WHERE CreatedDate >= :startTime 
            AND CreatedDate <= :endTime
        ];
        
        if (!docStats.isEmpty()) {
            AggregateResult stat = docStats[0];
            analytics.totalDocuments = Integer.valueOf(stat.get('totalDocs'));
            analytics.averageGenerationTime = (Decimal)stat.get('avgTime');
        }
        
        // Get success/failure breakdown
        List<AggregateResult> statusStats = [
            SELECT 
                Status__c status,
                COUNT(Id) count
            FROM DocumentGenerationLog__c 
            WHERE CreatedDate >= :startTime 
            AND CreatedDate <= :endTime
            GROUP BY Status__c
        ];
        
        for (AggregateResult result : statusStats) {
            String status = (String)result.get('status');
            Integer count = Integer.valueOf(result.get('count'));
            
            if (status == 'SUCCESS') {
                analytics.successfulGenerations = count;
            } else if (status == 'FAILED') {
                analytics.failedGenerations = count;
            }
        }
        
        // Calculate success rate
        if (analytics.totalDocuments > 0) {
            analytics.successRate = (Decimal.valueOf(analytics.successfulGenerations) / Decimal.valueOf(analytics.totalDocuments)) * 100;
        }
        
        // Get template usage statistics
        List<AggregateResult> templateStats = [
            SELECT 
                Template_Used__c template,
                COUNT(Id) usage_count,
                AVG(Generation_Time_Ms__c) avg_time
            FROM DocumentGenerationLog__c 
            WHERE CreatedDate >= :startTime 
            AND CreatedDate <= :endTime
            AND Template_Used__c != NULL
            GROUP BY Template_Used__c
            ORDER BY COUNT(Id) DESC
            LIMIT 20
        ];
        
        for (AggregateResult result : templateStats) {
            String template = (String)result.get('template');
            Integer usageCount = Integer.valueOf(result.get('usage_count'));
            Decimal avgTime = (Decimal)result.get('avg_time');
            
            analytics.templateUsageStats.put(template, usageCount);
            analytics.performanceByTemplate.put(template, avgTime);
            
            if (analytics.mostPopularTemplates.size() < 10) {
                analytics.mostPopularTemplates.add(template);
            }
        }
        
        // Get document type breakdown
        List<AggregateResult> typeStats = [
            SELECT 
                Document_Type__c docType,
                COUNT(Id) count
            FROM DocumentGenerationLog__c 
            WHERE CreatedDate >= :startTime 
            AND CreatedDate <= :endTime
            AND Document_Type__c != NULL
            GROUP BY Document_Type__c
        ];
        
        for (AggregateResult result : typeStats) {
            String docType = (String)result.get('docType');
            Integer count = Integer.valueOf(result.get('count'));
            analytics.documentTypeBreakdown.put(docType, count);
        }
        
        // Get peak hourly generation
        List<AggregateResult> hourlyStats = [
            SELECT 
                HOUR_IN_DAY(CreatedDate) hour,
                COUNT(Id) count
            FROM DocumentGenerationLog__c 
            WHERE CreatedDate >= :startTime 
            AND CreatedDate <= :endTime
            GROUP BY HOUR_IN_DAY(CreatedDate)
            ORDER BY COUNT(Id) DESC
            LIMIT 1
        ];
        
        if (!hourlyStats.isEmpty()) {
            analytics.peakHourlyGeneration = Integer.valueOf(hourlyStats[0].get('count'));
        }
        
    } catch (Exception e) {
        System.debug('Document generation analytics error: ' + e.getMessage());
    }
    
    return analytics;
}
private static ComplianceAnalytics getComplianceAnalytics(DateTime startTime, DateTime endTime) {
    ComplianceAnalytics analytics = new ComplianceAnalytics();
    
    try {
        // Get overall compliance score from recent assessments
        List<AggregateResult> complianceScores = [
            SELECT AVG(Overall_Compliance_Score__c) avgScore
            FROM DocumentComplianceTracking__c
            WHERE Analysis_Date__c >= :startTime
            AND Analysis_Date__c <= :endTime
            AND Overall_Compliance_Score__c != null
        ];
        if (!complianceScores.isEmpty() && complianceScores[0].get('avgScore') != null) {
            analytics.overallComplianceScore = (Decimal)complianceScores[0].get('avgScore');
        } else {
            analytics.overallComplianceScore = 0;
        }
        
        // Get regulation-specific scores
        Map<String, String> regulationFields = new Map<String, String>{
            'GDPR' => 'GDPR_Compliance_Score__c',
            'HIPAA' => 'HIPAA_Compliance_Score__c',
            'SOX' => 'SOX_Compliance_Score__c',
            'CCPA' => 'CCPA_Compliance_Score__c',
            'PCI_DSS' => 'PCI_DSS_Compliance_Score__c'
        };
        for (String regulation : regulationFields.keySet()) {
            String fieldName = regulationFields.get(regulation);
            String query = 'SELECT AVG(' + fieldName + ') avgScore FROM DocumentComplianceTracking__c WHERE Analysis_Date__c >= :startTime AND Analysis_Date__c <= :endTime AND ' + fieldName + ' != null';
            List<AggregateResult> regScores = Database.query(query);
            if (!regScores.isEmpty() && regScores[0].get('avgScore') != null) {
                analytics.regulationScores.put(regulation, (Decimal)regScores[0].get('avgScore'));
            } else {
                analytics.regulationScores.put(regulation, 0);
            }
        }
        
        // Get violation statistics
        List<AggregateResult> violationStats = [
            SELECT Severity__c severity, COUNT(Id) count
            FROM DocumentComplianceFinding__c
            WHERE CreatedDate >= :startTime AND CreatedDate <= :endTime
            GROUP BY Severity__c
        ];
        analytics.totalViolations = 0;
        for (AggregateResult result : violationStats) {
            String severity = (String)result.get('severity');
            Integer count = Integer.valueOf(result.get('count'));
            analytics.totalViolations += count;
            analytics.violationsByType.put(severity, count);
            if (severity == 'CRITICAL') {
                analytics.criticalViolations = count;
            }
        }
        
        // Get active violations
        analytics.activeViolations = [
            SELECT COUNT()
            FROM DocumentComplianceFinding__c
            WHERE Status__c = 'OPEN'
            AND CreatedDate >= :startTime
        ];
        
        // Get violations by regulation
        List<AggregateResult> regulationViolations = [
            SELECT Regulation_Type__c regulation, COUNT(Id) count
            FROM DocumentComplianceFinding__c
            WHERE CreatedDate >= :startTime
            AND CreatedDate <= :endTime
            AND Regulation_Type__c != null
            GROUP BY Regulation_Type__c
        ];
        for (AggregateResult result : regulationViolations) {
            String regulation = (String)result.get('regulation');
            Integer count = Integer.valueOf(result.get('count'));
            analytics.violationsByRegulation.put(regulation, count);
        }
        
        // Get top violation categories
        List<AggregateResult> categoryViolations = [
            SELECT Violation_Category__c category, COUNT(Id) count
            FROM DocumentComplianceFinding__c
            WHERE CreatedDate >= :startTime
            AND CreatedDate <= :endTime
            AND Violation_Category__c != null
            GROUP BY Violation_Category__c
            ORDER BY COUNT(Id) DESC
            LIMIT 10
        ];
        for (AggregateResult result : categoryViolations) {
            analytics.topViolationCategories.add((String)result.get('category'));
        }
        
        // Calculate compliance trend
        DateTime previousPeriodStart = startTime.addDays(-30);
        List<AggregateResult> previousPeriodScore = [
            SELECT AVG(Overall_Compliance_Score__c) avgScore
            FROM DocumentComplianceTracking__c
            WHERE Analysis_Date__c >= :previousPeriodStart
            AND Analysis_Date__c < :startTime
            AND Overall_Compliance_Score__c != null
        ];
        if (!previousPeriodScore.isEmpty() && previousPeriodScore[0].get('avgScore') != null) {
            Decimal previousScore = (Decimal)previousPeriodScore[0].get('avgScore');
            analytics.complianceTrend = analytics.overallComplianceScore - previousScore;
        }
        
        // Get documents under review
        analytics.documentsUnderReview = [
            SELECT COUNT()
            FROM DocumentLifecycleConfiguration__c
            WHERE ComplianceStatus__c = 'UNDER_REVIEW'
            AND CreatedDate >= :startTime
        ];
        
        // Risk assessment
        analytics.riskAssessment.put('highRiskDocuments', [
            SELECT COUNT()
            FROM DocumentLifecycleConfiguration__c
            WHERE Risk_Level__c = 'HIGH'
            AND CreatedDate >= :startTime
        ]);
        analytics.riskAssessment.put('criticalIssues', analytics.criticalViolations);
        analytics.riskAssessment.put('overallRiskLevel', analytics.criticalViolations > 0 ? 'HIGH' : (analytics.totalViolations > 10 ? 'MEDIUM' : 'LOW'));
        
    } catch (Exception e) {
        System.debug('Compliance analytics error: ' + e.getMessage());
    }
    
    return analytics;
}
private static UserActivityAnalytics getUserActivityAnalytics(DateTime startTime, DateTime endTime) {
    UserActivityAnalytics analytics = new UserActivityAnalytics();
    
    try {
        // Get unique active users
        List<AggregateResult> userStats = [
            SELECT COUNT_DISTINCT(UserDetails__c) activeUsers, COUNT_DISTINCT(CALENDAR_MONTH(CreatedDate)) distinctMonths
            FROM AuditTrail__c
            WHERE CreatedDate >= :startTime AND CreatedDate <= :endTime
        ];
        if (!userStats.isEmpty()) {
            analytics.totalActiveUsers = Integer.valueOf(userStats[0].get('activeUsers'));
        }
        
        // Identify new vs returning users
        DateTime userThreshold = startTime.addDays(-90);
        List<User> allUsers = [SELECT Id, CreatedDate FROM User WHERE LastLoginDate >= :startTime AND IsActive = true];
        analytics.newUsers = 0;
        analytics.returningUsers = 0;
        for (User user : allUsers) {
            if (user.CreatedDate >= userThreshold) {
                analytics.newUsers++;
            } else {
                analytics.returningUsers++;
            }
        }
        
        // Get activity by user role
        List<AggregateResult> roleStats = [
            SELECT u.Profile.Name profileName, COUNT(DISTINCT a.UserDetails__c) userCount
            FROM AuditTrail__c a JOIN User u ON a.UserDetails__c = u.Id
            WHERE a.CreatedDate >= :startTime AND a.CreatedDate <= :endTime
            AND u.IsActive = true
            GROUP BY u.Profile.Name
        ];
        for (AggregateResult result : roleStats) {
            String profileName = (String)result.get('profileName');
            Integer userCount = Integer.valueOf(result.get('userCount'));
            analytics.usersByRole.put(profileName, userCount);
        }
        
        // Get activity by hour
        List<AggregateResult> hourlyActivity = [
            SELECT HOUR_IN_DAY(CreatedDate) hour, COUNT(Id) activityCount
            FROM AuditTrail__c
            WHERE CreatedDate >= :startTime AND CreatedDate <= :endTime
            GROUP BY HOUR_IN_DAY(CreatedDate)
        ];
        for (AggregateResult result : hourlyActivity) {
            Integer hour = Integer.valueOf(result.get('hour'));
            Integer count = Integer.valueOf(result.get('activityCount'));
            analytics.activityByHour.put(String.valueOf(hour), count);
        }
        
        // Get feature usage statistics
        List<AggregateResult> featureStats = [
            SELECT Action__c action, COUNT(Id) usageCount
            FROM AuditTrail__c
            WHERE CreatedDate >= :startTime AND CreatedDate <= :endTime AND Action__c != null
            GROUP BY Action__c
            ORDER BY COUNT(Id) DESC
        ];
        for (AggregateResult result : featureStats) {
            String action = (String)result.get('action');
            Integer count = Integer.valueOf(result.get('usageCount'));
            analytics.featureUsageStats.put(action, count);
        }
        
        // Get most active users
        List<AggregateResult> activeUserStats = [
            SELECT UserDetails__c userId, u.Name userName, COUNT(Id) activityCount
            FROM AuditTrail__c a JOIN User u ON a.UserDetails__c = u.Id
            WHERE a.CreatedDate >= :startTime AND a.CreatedDate <= :endTime
            GROUP BY UserDetails__c, u.Name
            ORDER BY COUNT(Id) DESC
            LIMIT 10
        ];
        for (AggregateResult result : activeUserStats) {
            String userName = (String)result.get('userName');
            Integer activityCount = Integer.valueOf(result.get('activityCount'));
            analytics.mostActiveUsers.add(userName + ' (' + activityCount + ' activities)');
        }
        
        // Calculate average session duration (simplified estimation)
        List<AggregateResult> sessionStats = [
            SELECT AVG(Session_Duration_Minutes__c) avgDuration, COUNT(Id) totalSessions
            FROM UserSessionLog__c
            WHERE Session_Start__c >= :startTime AND Session_Start__c <= :endTime
        ];
        if (!sessionStats.isEmpty()) {
            analytics.averageSessionDuration = (Decimal)sessionStats[0].get('avgDuration');
            analytics.totalSessions = Integer.valueOf(sessionStats[0].get('totalSessions'));
        }
        
    } catch (Exception e) {
        System.debug('User activity analytics error: ' + e.getMessage());
    }
    
    return analytics;
}

private static SystemPerformanceAnalytics getSystemPerformanceAnalytics(DateTime startTime, DateTime endTime) {
    SystemPerformanceAnalytics analytics = new SystemPerformanceAnalytics();
    
    try {
        // Get performance metrics from snapshots
        List<AggregateResult> performanceStats = [
            SELECT AVG(Average_Response_Time__c) avgResponseTime, AVG(Cache_Hit_Ratio__c) avgCacheHit,
                   AVG(System_Uptime__c) avgUptime, MAX(Concurrent_Users__c) maxConcurrentUsers
            FROM SystemMetricsSnapshot__c
            WHERE Timestamp__c >= :startTime AND Timestamp__c <= :endTime
        ];
        if (!performanceStats.isEmpty()) {
            AggregateResult stats = performanceStats[0];
            analytics.averageResponseTime = (Decimal)stats.get('avgResponseTime');
            analytics.cacheHitRatio = (Decimal)stats.get('avgCacheHit');
            analytics.systemUptime = (Decimal)stats.get('avgUptime');
            analytics.concurrentUsersPeak = Integer.valueOf(stats.get('maxConcurrentUsers'));
        }
        
        // Get API request statistics
        List<AggregateResult> apiStats = [
            SELECT Status__c status, COUNT(Id) requestCount
            FROM APIRequestLog__c
            WHERE Request_Time__c >= :startTime AND Request_Time__c <= :endTime
            GROUP BY Status__c
        ];
        analytics.totalAPIRequests = 0;
        analytics.failedAPIRequests = 0;
        for (AggregateResult result : apiStats) {
            String status = (String)result.get('status');
            Integer count = Integer.valueOf(result.get('requestCount'));
            analytics.totalAPIRequests += count;
            if (status != 'SUCCESS') {
                analytics.failedAPIRequests += count;
            }
        }
        
        // Calculate API success rate
        if (analytics.totalAPIRequests > 0) {
            analytics.apiSuccessRate = ((Decimal)(analytics.totalAPIRequests - analytics.failedAPIRequests) / analytics.totalAPIRequests) * 100;
        }
        
        // Get performance by endpoint
        List<AggregateResult> endpointStats = [
            SELECT Endpoint__c endpoint, AVG(Response_Time_Ms__c) avgTime
            FROM APIRequestLog__c
            WHERE Request_Time__c >= :startTime AND Request_Time__c <= :endTime
            AND Endpoint__c != null
            GROUP BY Endpoint__c
        ];
        for (AggregateResult result : endpointStats) {
            String endpoint = (String)result.get('endpoint');
            Decimal avgTime = (Decimal)result.get('avgTime');
            analytics.performanceByEndpoint.put(endpoint, avgTime);
            
            // Identify bottlenecks
            if (avgTime > 5000) {
                analytics.performanceBottlenecks.add(endpoint + ' (' + avgTime.format() + 'ms)');
            }
        }
        
        // Resource utilization (simplified)
        analytics.resourceUtilization.put('averageMemoryUsage', 75);
        analytics.resourceUtilization.put('peakCPUUsage', 85);
        analytics.resourceUtilization.put('diskSpaceUsed', 60);
        
        // Performance trends over time
        List<AggregateResult> trendData = [
            SELECT DAY_ONLY(Timestamp__c) date, AVG(Average_Response_Time__c) avgTime
            FROM SystemMetricsSnapshot__c
            WHERE Timestamp__c >= :startTime AND Timestamp__c <= :endTime
            GROUP BY DAY_ONLY(Timestamp__c)
            ORDER BY DAY_ONLY(Timestamp__c)
        ];
        for (AggregateResult result : trendData) {
            Date recordDate = (Date)result.get('date');
            Decimal avgTime = (Decimal)result.get('avgTime');
            Map<String, Object> trendPoint = new Map<String, Object>();
            trendPoint.put('date', recordDate);
            trendPoint.put('responseTime', avgTime);
            analytics.performanceTrends.add(trendPoint);
        }
        
    } catch (Exception e) {
        System.debug('System performance analytics error: ' + e.getMessage());
    }
    
    return analytics;
}
private static Decimal calculateSystemHealthScore(
    DocumentGenerationAnalytics docAnalytics,
    ComplianceAnalytics complianceAnalytics,
    SystemPerformanceAnalytics perfAnalytics
) {
    Decimal healthScore = 100;
    try {
        // Document generation health (25% weight)
        if (docAnalytics.successRate < 95) {
            healthScore -= (95 - docAnalytics.successRate) * 0.5;
        }
        
        // Compliance health (30% weight)
        if (complianceAnalytics.overallComplianceScore < 90) {
            healthScore -= (90 - complianceAnalytics.overallComplianceScore) * 0.3;
        }
        
        // Critical violations impact
        if (complianceAnalytics.criticalViolations > 0) {
            healthScore -= complianceAnalytics.criticalViolations * 5;
        }
        
        // System performance health (25% weight)
        if (perfAnalytics.systemUptime < 99.5) {
            healthScore -= (99.5 - perfAnalytics.systemUptime) * 2;
        }
        if (perfAnalytics.averageResponseTime > 5000) {
            healthScore -= ((perfAnalytics.averageResponseTime - 5000) / 1000) * 5;
        }
        
        // API performance health (20% weight)
        if (perfAnalytics.apiSuccessRate < 95) {
            healthScore -= (95 - perfAnalytics.apiSuccessRate) * 0.4;
        }
        
        // Ensure score doesn't go below 0
        healthScore = Math.max(healthScore, 0);
        
    } catch (Exception e) {
        System.debug('Health score calculation error: ' + e.getMessage());
        healthScore = 50; // Default to fair health on error
    }
    
    return healthScore.setScale(1);
}

private static void generateExecutiveDashboardCharts(
    AnalyticsReport report,
    DocumentGenerationAnalytics docAnalytics,
    ComplianceAnalytics complianceAnalytics,
    UserActivityAnalytics userAnalytics,
    SystemPerformanceAnalytics perfAnalytics
) {
    try {
        // Document generation success rate pie chart
        List<Object> successRateChart = new List<Object>();
        Map<String, Object> successData = new Map<String, Object>();
        successData.put('label', 'Successful');
        successData.put('value', docAnalytics.successfulGenerations);
        successData.put('color', '#28a745');
        Map<String, Object> failureData = new Map<String, Object>();
        failureData.put('label', 'Failed');
        failureData.put('value', docAnalytics.failedGenerations);
        failureData.put('color', '#dc3545');
        successRateChart.add(successData);
        successRateChart.add(failureData);
        report.chartData.put('documentSuccessRate', successRateChart);

        // Compliance scores by regulation
        List<Object> complianceChart = new List<Object>();
        for (String regulation : complianceAnalytics.regulationScores.keySet()) {
            Map<String, Object> regData = new Map<String, Object>();
            regData.put('regulation', regulation);
            regData.put('score', complianceAnalytics.regulationScores.get(regulation));
            complianceChart.add(regData);
        }
        report.chartData.put('complianceByRegulation', complianceChart);

        // User activity by hour
        List<Object> activityChart = new List<Object>();
        for (String hour : userAnalytics.activityByHour.keySet()) {
            Map<String, Object> hourData = new Map<String, Object>();
            hourData.put('hour', hour + ':00');
            hourData.put('activity', userAnalytics.activityByHour.get(hour));
            activityChart.add(hourData);
        }
        report.chartData.put('userActivityByHour', activityChart);

        // Performance trends over time
        List<Object> performanceChart = new List<Object>();
        for (Object trendPoint : perfAnalytics.performanceTrends) {
            Map<String, Object> trend = (Map<String, Object>)trendPoint;
            Map<String, Object> chartPoint = new Map<String, Object>();
            chartPoint.put('date', trend.get('date'));
            chartPoint.put('responseTime', trend.get('responseTime'));
            chartPoint.put('target', 5000); // SLA target
            performanceChart.add(chartPoint);
        }
        report.chartData.put('performanceTrends', performanceChart);

        // Document types distribution
        List<Object> documentTypeChart = new List<Object>();
        for (String docType : docAnalytics.documentTypeBreakdown.keySet()) {
            Map<String, Object> typeData = new Map<String, Object>();
            typeData.put('type', docType);
            typeData.put('count', docAnalytics.documentTypeBreakdown.get(docType));
            documentTypeChart.add(typeData);
        }
        report.chartData.put('documentTypes', documentTypeChart);

        // Violation severity breakdown
        List<Object> violationChart = new List<Object>();
        for (String severity : complianceAnalytics.violationsByType.keySet()) {
            Map<String, Object> severityData = new Map<String, Object>();
            severityData.put('severity', severity);
            severityData.put('count', complianceAnalytics.violationsByType.get(severity));
            String color = getSeverityColor(severity);
            severityData.put('color', color);
            violationChart.add(severityData);
        }
        report.chartData.put('violationsBySeverity', violationChart);

    } catch (Exception e) {
        System.debug('Chart generation error: ' + e.getMessage());
    }
}

private static String getSeverityColor(String severity) {
    switch on severity?.toUpperCase() {
        when 'CRITICAL' {
            return '#8b0000'; // Dark red
        }
        when 'HIGH' {
            return '#dc3545'; // Red
        }
        when 'MEDIUM' {
            return '#ffc107'; // Yellow
        }
        when 'LOW' {
            return '#28a745'; // Green
        }
        when else {
            return '#6c757d'; // Gray
        }
    }
}
private static void storeAnalyticsReport(AnalyticsReport report) {
    try {
        AnalyticsReportArchive__c archive = new AnalyticsReportArchive__c(
            Report_Type__c = report.reportType,
            Generated_Date__c = report.generatedAt,
            Period_Start__c = report.periodStart,
            Period_End__c = report.periodEnd,
            Generated_By__c = report.generatedBy,
            Overall_Score__c = report.overallScore,
            Executive_Summary__c = report.executiveSummary,
            Metrics_JSON__c = JSON.serialize(report.metrics),
            Insights_JSON__c = JSON.serialize(report.insights),
            Chart_Data_JSON__c = JSON.serialize(report.chartData),
            Has_Anomalies__c = report.hasAnomalies,
            Critical_Findings_Count__c = report.criticalFindings.size()
        );
        insert archive;
    } catch (Exception e) {
        System.debug('Analytics report storage error: ' + e.getMessage());
    }
}

/** 
 * Generate document generation detailed report 
 */
private static void generateDocumentGenerationReport(AnalyticsReport report) {
    DocumentGenerationAnalytics analytics = getDocumentGenerationAnalytics(report.periodStart, report.periodEnd);
    
    // Populate detailed metrics
    report.metrics.put('totalDocuments', analytics.totalDocuments);
    report.metrics.put('successfulGenerations', analytics.successfulGenerations);
    report.metrics.put('failedGenerations', analytics.failedGenerations);
    report.metrics.put('successRate', analytics.successRate);
    report.metrics.put('averageGenerationTime', analytics.averageGenerationTime);
    report.metrics.put('peakHourlyGeneration', analytics.peakHourlyGeneration);
    report.metrics.put('uniqueTemplatesUsed', analytics.templateUsageStats.size());
    report.metrics.put('mostPopularTemplate', analytics.mostPopularTemplates.isEmpty() ? 'None' : analytics.mostPopularTemplates[0]);
    
    // Generate insights
    if (analytics.averageGenerationTime > 10000) {
        report.insights.add(new AnalyticsInsight(
            'PERFORMANCE',
            'Slow Document Generation',
            'Average generation time is ' + (analytics.averageGenerationTime/1000).format() + ' seconds, exceeding optimal performance.',
            'MEDIUM'
        ));
    }
    if (analytics.successRate < 98) {
        report.insights.add(new AnalyticsInsight(
            'RELIABILITY',
            'Document Generation Failures',
            'Success rate of ' + analytics.successRate.format() + '% indicates reliability issues requiring investigation.',
            'HIGH'
        ));
        report.hasAnomalies = true;
    }
    
    // Check for template performance issues
    for (String template : analytics.performanceByTemplate.keySet()) {
        Decimal templateTime = analytics.performanceByTemplate.get(template);
        if (templateTime > 15000) {
            report.insights.add(new AnalyticsInsight(
                'TEMPLATE_PERFORMANCE',
                'Slow Template Performance',
                'Template "' + template + '" averages ' + (templateTime/1000).format() + ' seconds, needs optimization.',
                'MEDIUM'
            ));
        }
    }
    
    // Generate executive summary
    StringBuilder summary = new StringBuilder();
    summary.append('Document Generation Report\n');
    summary.append('Period: ').append(report.periodStart.format('MM/dd/yyyy')).append(' - ').append(report.periodEnd.format('MM/dd/yyyy')).append('\n\n');
    summary.append('Overview:\n');
    summary.append('• Total Documents Generated: ').append(analytics.totalDocuments).append('\n');
    summary.append('• Success Rate: ').append(analytics.successRate.format()).append('%\n');
    summary.append('• Average Generation Time: ').append((analytics.averageGenerationTime/1000).format()).append(' seconds\n');
    summary.append('• Peak Hourly Volume: ').append(analytics.peakHourlyGeneration).append(' documents\n\n');
    
    summary.append('Top Performing Templates:\n');
    Integer templateCount = 0;
    for (String template : analytics.mostPopularTemplates) {
        if (templateCount >= 5) break;
        Integer usage = analytics.templateUsageStats.get(template);
        Decimal avgTime = analytics.performanceByTemplate.get(template);
        summary.append('• ').append(template).append(': ').append(usage).append(' uses, ').append((avgTime/1000).format()).append('s avg\n');
        templateCount++;
    }
    
    summary.append('\nDocument Type Distribution:\n');
    for (String docType : analytics.documentTypeBreakdown.keySet()) {
        Integer count = analytics.documentTypeBreakdown.get(docType);
        Decimal percentage = (Decimal.valueOf(count) / analytics.totalDocuments) * 100;
        summary.append('• ').append(docType).append(': ').append(count).append(' (').append(percentage.format()).append('%)\n');
    }
    
    report.executiveSummary = summary.toString();
    
    // Calculate overall score
    Decimal performanceScore = 100;
    if (analytics.successRate < 100) {
        performanceScore -= (100 - analytics.successRate);
    }
    if (analytics.averageGenerationTime > 5000) {
        performanceScore -= ((analytics.averageGenerationTime - 5000) / 1000) * 2;
    }
    report.overallScore = Math.max(performanceScore, 0);
    
    // Generate chart data
    generateDocumentGenerationCharts(report, analytics);
}

/** 
 * Generate document generation specific charts 
 */
private static void generateDocumentGenerationCharts(AnalyticsReport report, DocumentGenerationAnalytics analytics) {
    // Template usage chart
    List<Object> templateChart = new List<Object>();
    for (String template : analytics.templateUsageStats.keySet()) {
        Map<String, Object> templateData = new Map<String, Object>();
        templateData.put('template', template);
        templateData.put('usage', analytics.templateUsageStats.get(template));
        templateData.put('averageTime', analytics.performanceByTemplate.get(template));
        templateChart.add(templateData);
    }
    report.chartData.put('templateUsage', templateChart);
    
    // Generation trends (placeholder for time-series data)
    List<Object> generationTrends = new List<Object>();
    report.chartData.put('generationTrends', generationTrends);
}
private static void generateSecurityAuditReport(AnalyticsReport report) {
    try {
        // Security metrics
        Map<String, Object> securityMetrics = new Map<String, Object>();

        // Authentication attempts
        List<AggregateResult> authStats = [
            SELECT COUNT(Id) totalAttempts, COUNT(CASE WHEN Status__c = 'SUCCESS' THEN 1 END) successfulAttempts
            FROM AuthenticationLog__c
            WHERE CreatedDate >= :report.periodStart AND CreatedDate <= :report.periodEnd
        ];
        if (!authStats.isEmpty()) {
            Integer totalAttempts = Integer.valueOf(authStats[0].get('totalAttempts'));
            Integer successfulAttempts = Integer.valueOf(authStats[0].get('successfulAttempts'));
            securityMetrics.put('totalAuthAttempts', totalAttempts);
            securityMetrics.put('successfulAuthAttempts', successfulAttempts);
            securityMetrics.put('failedAuthAttempts', totalAttempts - successfulAttempts);
            if (totalAttempts > 0) {
                Decimal successRate = (Decimal.valueOf(successfulAttempts) / totalAttempts) * 100;
                securityMetrics.put('authSuccessRate', successRate);
            }
        }

        // Permission violations
        List<AggregateResult> permissionViolations = [
            SELECT COUNT(Id) violationCount
            FROM SecurityViolationLog__c
            WHERE CreatedDate >= :report.periodStart AND CreatedDate <= :report.periodEnd
        ];
        if (!permissionViolations.isEmpty()) {
            securityMetrics.put('permissionViolations', permissionViolations[0].get('violationCount'));
        }

        // Data access patterns
        List<AggregateResult> dataAccess = [
            SELECT COUNT(DISTINCT UserDetails__c) uniqueUsers, COUNT(Id) totalAccess
            FROM AuditTrail__c
            WHERE CreatedDate >= :report.periodStart AND CreatedDate <= :report.periodEnd
            AND Action__c LIKE '%VIEW%'
        ];
        if (!dataAccess.isEmpty()) {
            securityMetrics.put('uniqueDataAccessUsers', dataAccess[0].get('uniqueUsers'));
            securityMetrics.put('totalDataAccessEvents', dataAccess[0].get('totalAccess'));
        }

        // Suspicious activity detection
        Integer suspiciousActivities = 0;
        List<AggregateResult> suspiciousLogins = [
            SELECT UserDetails__c userId, COUNT(Id) loginCount
            FROM AuthenticationLog__c
            WHERE CreatedDate >= :report.periodStart AND CreatedDate <= :report.periodEnd
            GROUP BY UserDetails__c
            HAVING COUNT(Id) > 100
        ];
        suspiciousActivities += suspiciousLogins.size();
        securityMetrics.put('suspiciousActivities', suspiciousActivities);

        report.metrics.putAll(securityMetrics);

        // Security insights
        Integer failedAttempts = (Integer)securityMetrics.get('failedAuthAttempts');
        if (failedAttempts != null && failedAttempts > 50) {
            report.insights.add(new AnalyticsInsight(
                'SECURITY',
                'High Failed Authentication Attempts',
                failedAttempts + ' failed authentication attempts detected, indicating potential brute force attacks.',
                'HIGH'
            ));
            report.hasAnomalies = true;
        }

        Integer violations = (Integer)securityMetrics.get('permissionViolations');
        if (violations != null && violations > 0) {
            report.insights.add(new AnalyticsInsight(
                'SECURITY',
                'Permission Violations Detected',
                violations + ' permission violations require immediate review and remediation.',
                'CRITICAL'
            ));
            report.criticalFindings.add('Permission violations: ' + violations);
            report.hasAnomalies = true;
        }

        if (suspiciousActivities > 0) {
            report.insights.add(new AnalyticsInsight(
                'SECURITY',
                'Suspicious User Activity',
                suspiciousActivities + ' users with unusual login patterns detected.',
                'MEDIUM'
            ));
        }

        // Generate security summary
        StringBuilder summary = new StringBuilder();
        summary.append('Security Audit Report\n');
        summary.append('Period: ').append(report.periodStart.format('MM/dd/yyyy')).append(' - ').append(report.periodEnd.format('MM/dd/yyyy')).append('\n\n');
        summary.append('Authentication Summary:\n');
        summary.append('• Total Authentication Attempts: ').append(securityMetrics.get('totalAuthAttempts')).append('\n');
        summary.append('• Successful Authentications: ').append(securityMetrics.get('successfulAuthAttempts')).append('\n');
        summary.append('• Failed Attempts: ').append(securityMetrics.get('failedAuthAttempts')).append('\n');
        if (securityMetrics.containsKey('authSuccessRate')) {
            summary.append('• Success Rate: ').append(((Decimal)securityMetrics.get('authSuccessRate')).format()).append('%\n');
        }
        summary.append('\nData Access Summary:\n');
        summary.append('• Unique Users Accessing Data: ').append(securityMetrics.get('uniqueDataAccessUsers')).append('\n');
        summary.append('• Total Data Access Events: ').append(securityMetrics.get('totalDataAccessEvents')).append('\n');
        summary.append('\nSecurity Violations:\n');
        summary.append('• Permission Violations: ').append(securityMetrics.get('permissionViolations')).append('\n');
        summary.append('• Suspicious Activities: ').append(securityMetrics.get('suspiciousActivities')).append('\n');

        if (report.hasAnomalies) {
            summary.append('\n⚠️ Security Issues Requiring Attention:\n');
            for (AnalyticsInsight insight : report.insights) {
                if (insight.category == 'SECURITY') {
                    summary.append('• ').append(insight.title).append('\n');
                }
            }
        }

        report.executiveSummary = summary.toString();

        // Calculate security score
        Decimal securityScore = 100;
        if (failedAttempts != null && failedAttempts > 0) {
            securityScore -= Math.min(failedAttempts * 0.5, 25); // Cap at 25 point deduction
        }
        if (violations != null && violations > 0) {
            securityScore -= violations * 10; // 10 points per violation
        }
        if (suspiciousActivities > 0) {
            securityScore -= suspiciousActivities * 5; // 5 points per suspicious user
        }

        report.overallScore = Math.max(securityScore, 0);

    } catch (Exception e) {
        System.debug('Security audit report error: ' + e.getMessage());
    }
}

private static void generateUserActivityReport(AnalyticsReport report) {
    UserActivityAnalytics analytics = getUserActivityAnalytics(report.periodStart, report.periodEnd);

    // Populate metrics
    report.metrics.put('totalActiveUsers', analytics.totalActiveUsers);
    report.metrics.put('newUsers', analytics.newUsers);
    report.metrics.put('returningUsers', analytics.returningUsers);
    report.metrics.put('averageSessionDuration', analytics.averageSessionDuration);
    report.metrics.put('totalSessions', analytics.totalSessions);
    report.metrics.put('topFeaturesUsed', analytics.featureUsageStats.size());

    // User activity insights
    if (analytics.newUsers > analytics.returningUsers) {
        report.insights.add(new AnalyticsInsight(
            'USER_GROWTH',
            'High New User Adoption',
            'New users (' + analytics.newUsers + ') exceed returning users (' + analytics.returningUsers + '), indicating strong adoption.',
            'LOW'
        ));
    }

    if (analytics.averageSessionDuration != null && analytics.averageSessionDuration < 5) {
        report.insights.add(new AnalyticsInsight(
            'USER_ENGAGEMENT',
            'Low Session Duration',
            'Average session duration is ' + analytics.averageSessionDuration.format() + ' minutes, suggesting low user engagement.',
            'MEDIUM'
        ));
        report.hasAnomalies = true;
    }

    // Analyze feature adoption
    Map<String, Integer> featureUsage = analytics.featureUsageStats;
    String mostUsedFeature = null;
    String leastUsedFeature = null;
    Integer maxUsage = 0;
    Integer minUsage = Integer.MAX_VALUE;

    for (String feature : featureUsage.keySet()) {
        Integer usage = featureUsage.get(feature);
        if (usage > maxUsage) {
            maxUsage = usage;
            mostUsedFeature = feature;
        }
        if (usage < minUsage) {
            minUsage = usage;
            leastUsedFeature = feature;
        }
    }

    if (mostUsedFeature != null && leastUsedFeature != null) {
        report.insights.add(new AnalyticsInsight(
            'FEATURE_ADOPTION',
            'Feature Usage Disparity',
            'Most used feature: ' + mostUsedFeature + ' (' + maxUsage + ' uses). Least used: ' + leastUsedFeature + ' (' + minUsage + ' uses).',
            'LOW'
        ));
    }

    // Check for unusual activity patterns
    Map<String, Integer> hourlyActivity = analytics.activityByHour;
    Integer peakHour = 0;
    Integer peakActivity = 0;

    for (String hourStr : hourlyActivity.keySet()) {
        Integer hour = Integer.valueOf(hourStr);
        Integer activity = hourlyActivity.get(hourStr);
        if (activity > peakActivity) {
            peakActivity = activity;
            peakHour = hour;
        }
    }

    if (peakHour < 6 || peakHour > 22) {
        report.insights.add(new AnalyticsInsight(
            'USAGE_PATTERN',
            'Off-Hours Activity',
            'Peak activity at ' + peakHour + ':00 indicates significant off-hours usage.',
            'LOW'
        ));
    }

    // Generate user activity summary
    StringBuilder summary = new StringBuilder();
    summary.append('User Activity Report\n');
    summary.append('Period: ').append(report.periodStart.format('MM/dd/yyyy')).append(' - ').append(report.periodEnd.format('MM/dd/yyyy')).append('\n\n');
    summary.append('User Engagement Overview:\n');
    summary.append('• Total Active Users: ').append(analytics.totalActiveUsers).append('\n');
    summary.append('• New Users: ').append(analytics.newUsers).append('\n');
    summary.append('• Returning Users: ').append(analytics.returningUsers).append('\n');
    if (analytics.averageSessionDuration != null) {
        summary.append('• Average Session Duration: ').append(analytics.averageSessionDuration.format()).append(' minutes\n');
    }
    summary.append('• Total Sessions: ').append(analytics.totalSessions).append('\n\n');
    summary.append('Activity Patterns:\n');
    summary.append('• Peak Activity Hour: ').append(peakHour).append(':00 (').append(peakActivity).append(' activities)\n');
    if (mostUsedFeature != null) {
        summary.append('• Most Popular Feature: ').append(mostUsedFeature).append(' (').append(maxUsage).append(' uses)\n');
    }

    summary.append('\nUser Distribution by Role:\n');
    for (String role : analytics.usersByRole.keySet()) {
        Integer userCount = analytics.usersByRole.get(role);
        Decimal percentage = analytics.totalActiveUsers > 0 ? (Decimal.valueOf(userCount) / analytics.totalActiveUsers) * 100 : 0;
        summary.append('• ').append(role).append(': ').append(userCount).append(' users (').append(percentage.format()).append('%)\n');
    }

    summary.append('\nTop Active Users:\n');
    for (String activeUser : analytics.mostActiveUsers) {
        summary.append('• ').append(activeUser).append('\n');
    }

    report.executiveSummary = summary.toString();

    // Calculate user engagement score
    Decimal engagementScore = 100;
    if (analytics.averageSessionDuration != null && analytics.averageSessionDuration < 10) {
        engagementScore -= (10 - analytics.averageSessionDuration) * 2;
    }

    if (analytics.totalActiveUsers > 0) {
        Decimal newUserRatio = Decimal.valueOf(analytics.newUsers) / analytics.totalActiveUsers;
        if (newUserRatio > 0.7) {
            engagementScore -= 10;
        } else if (newUserRatio < 0.1) {
            engagementScore -= 5;
        }
    }

    report.overallScore = Math.max(engagementScore, 0);

    // Generate user activity charts
    generateUserActivityCharts(report, analytics);
}
private static void generateUserActivityCharts(AnalyticsReport report, UserActivityAnalytics analytics) {
    // User growth chart
    List<Object> userGrowthChart = new List<Object>();
    Map<String, Object> newUserData = new Map<String, Object>();
    newUserData.put('category', 'New Users');
    newUserData.put('count', analytics.newUsers);
    newUserData.put('color', '#28a745');

    Map<String, Object> returningUserData = new Map<String, Object>();
    returningUserData.put('category', 'Returning Users');
    returningUserData.put('count', analytics.returningUsers);
    returningUserData.put('color', '#007bff');

    userGrowthChart.add(newUserData);
    userGrowthChart.add(returningUserData);
    report.chartData.put('userGrowth', userGrowthChart);

    // Feature usage chart
    List<Object> featureChart = new List<Object>();
    for (String feature : analytics.featureUsageStats.keySet()) {
        Map<String, Object> featureData = new Map<String, Object>();
        featureData.put('feature', feature);
        featureData.put('usage', analytics.featureUsageStats.get(feature));
        featureChart.add(featureData);
    }
    report.chartData.put('featureUsage', featureChart);

    // Activity by role chart
    List<Object> roleChart = new List<Object>();
    for (String role : analytics.usersByRole.keySet()) {
        Map<String, Object> roleData = new Map<String, Object>();
        roleData.put('role', role);
        roleData.put('users', analytics.usersByRole.get(role));
        roleChart.add(roleData);
    }
    report.chartData.put('usersByRole', roleChart);
}

private static void generateSystemPerformanceReport(AnalyticsReport report) {
    SystemPerformanceAnalytics analytics = getSystemPerformanceAnalytics(report.periodStart, report.periodEnd);

    // Populate performance metrics
    report.metrics.put('averageResponseTime', analytics.averageResponseTime);
    report.metrics.put('cacheHitRatio', analytics.cacheHitRatio);
    report.metrics.put('systemUptime', analytics.systemUptime);
    report.metrics.put('totalAPIRequests', analytics.totalAPIRequests);
    report.metrics.put('apiSuccessRate', analytics.apiSuccessRate);
    report.metrics.put('concurrentUsersPeak', analytics.concurrentUsersPeak);
    report.metrics.put('performanceBottlenecks', analytics.performanceBottlenecks.size());

    // Performance insights
    if (analytics.averageResponseTime > 5000) {
        report.insights.add(new AnalyticsInsight(
            'PERFORMANCE',
            'Slow Response Time',
            'Average response time of ' + (analytics.averageResponseTime/1000).format() + ' seconds exceeds the 5-second SLA target.',
            'HIGH'
        ));
        report.hasAnomalies = true;
    }

    if (analytics.cacheHitRatio < 85) {
        report.insights.add(new AnalyticsInsight(
            'PERFORMANCE',
            'Low Cache Efficiency',
            'Cache hit ratio of ' + analytics.cacheHitRatio.format() + '% is below the 85% target, impacting performance.',
            'MEDIUM'
        ));
    }

    if (analytics.systemUptime < 99.5) {
        report.insights.add(new AnalyticsInsight(
            'AVAILABILITY',
            'System Uptime Below SLA',
            'System uptime of ' + analytics.systemUptime.format() + '% is below the 99.5% SLA requirement.',
            'CRITICAL'
        ));
        report.criticalFindings.add('System uptime SLA violation: ' + analytics.systemUptime.format() + '%');
        report.hasAnomalies = true;
    }

    if (analytics.apiSuccessRate < 95) {
        report.insights.add(new AnalyticsInsight(
            'API_RELIABILITY',
            'API Success Rate Below Target',
            'API success rate of ' + analytics.apiSuccessRate.format() + '% indicates reliability issues requiring investigation.',
            'HIGH'
        ));
        report.hasAnomalies = true;
    }

    // Identify performance bottlenecks
    for (String bottleneck : analytics.performanceBottlenecks) {
        report.insights.add(new AnalyticsInsight(
            'PERFORMANCE_BOTTLENECK',
            'Slow Endpoint Detected',
            'Endpoint experiencing performance issues: ' + bottleneck,
            'MEDIUM'
        ));
    }

    // Generate performance summary
    StringBuilder summary = new StringBuilder();
    summary.append('System Performance Report\n');
    summary.append('Period: ').append(report.periodStart.format('MM/dd/yyyy')).append(' - ').append(report.periodEnd.format('MM/dd/yyyy')).append('\n\n');
    summary.append('Performance Overview:\n');
    summary.append('• Average Response Time: ').append((analytics.averageResponseTime/1000).format()).append(' seconds (Target: <5s)\n');
    summary.append('• Cache Hit Ratio: ').append(analytics.cacheHitRatio.format()).append('% (Target: >85%)\n');
    summary.append('• System Uptime: ').append(analytics.systemUptime.format()).append('% (Target: >99.5%)\n');
    summary.append('• Peak Concurrent Users: ').append(analytics.concurrentUsersPeak).append('\n\n');
    summary.append('API Performance:\n');
    summary.append('• Total API Requests: ').append(analytics.totalAPIRequests).append('\n');
    summary.append('• Failed Requests: ').append(analytics.failedAPIRequests).append('\n');
    summary.append('• API Success Rate: ').append(analytics.apiSuccessRate.format()).append('% (Target: >95%)\n\n');

    if (!analytics.performanceBottlenecks.isEmpty()) {
        summary.append('Performance Bottlenecks:\n');
        for (String bottleneck : analytics.performanceBottlenecks) {
            summary.append('• ').append(bottleneck).append('\n');
        }
        summary.append('\n');
    }

    summary.append('Resource Utilization:\n');
    Map<String, Object> resources = analytics.resourceUtilization;
    for (String resource : resources.keySet()) {
        summary.append('• ').append(resource).append(': ').append(resources.get(resource)).append('%\n');
    }

    summary.append('\nSLA Compliance Status:\n');
    summary.append('• Response Time SLA: ').append(analytics.averageResponseTime <= 5000 ? '✓ COMPLIANT' : '✗ NON-COMPLIANT').append('\n');
    summary.append('• Cache Performance SLA: ').append(analytics.cacheHitRatio >= 85 ? '✓ COMPLIANT' : '✗ NON-COMPLIANT').append('\n');
    summary.append('• System Uptime SLA: ').append(analytics.systemUptime >= 99.5 ? '✓ COMPLIANT' : '✗ NON-COMPLIANT').append('\n');
    summary.append('• API Reliability SLA: ').append(analytics.apiSuccessRate >= 95 ? '✓ COMPLIANT' : '✗ NON-COMPLIANT').append('\n');

    report.executiveSummary = summary.toString();

    // Calculate performance score
    Decimal performanceScore = 100;
    if (analytics.averageResponseTime > 5000) {
        performanceScore -= ((analytics.averageResponseTime - 5000) / 1000) * 5;
    }
    if (analytics.cacheHitRatio < 85) {
        performanceScore -= (85 - analytics.cacheHitRatio) * 0.5;
    }
    if (analytics.systemUptime < 99.5) {
        performanceScore -= (99.5 - analytics.systemUptime) * 10;
    }
    if (analytics.apiSuccessRate < 95) {
        performanceScore -= (95 - analytics.apiSuccessRate) * 2;
    }

    report.overallScore = Math.max(performanceScore, 0);

    // Generate performance charts
    generateSystemPerformanceCharts(report, analytics);
}

private static void generateSystemPerformanceCharts(AnalyticsReport report, SystemPerformanceAnalytics analytics) {
    // API success rate pie chart
    List<Object> apiChart = new List<Object>();
    Map<String, Object> successData = new Map<String, Object>();
    successData.put('label', 'Successful');
    successData.put('value', analytics.totalAPIRequests - analytics.failedAPIRequests);
    successData.put('color', '#28a745');

    Map<String, Object> failedData = new Map<String, Object>();
    failedData.put('label', 'Failed');
    failedData.put('value', analytics.failedAPIRequests);
    failedData.put('color', '#dc3545');

    apiChart.add(successData);
    apiChart.add(failedData);
    report.chartData.put('apiSuccessRate', apiChart);

    // Endpoint performance chart
    List<Object> endpointChart = new List<Object>();
    for (String endpoint : analytics.performanceByEndpoint.keySet()) {
        Map<String, Object> endpointData = new Map<String, Object>();
        endpointData.put('endpoint', endpoint);
        endpointData.put('responseTime', analytics.performanceByEndpoint.get(endpoint));
        endpointData.put('target', 5000); // SLA target
        endpointChart.add(endpointData);
    }
    report.chartData.put('endpointPerformance', endpointChart);

    // Resource utilization chart
    List<Object> resourceChart = new List<Object>();
    for (String resource : analytics.resourceUtilization.keySet()) {
        Map<String, Object> resourceData = new Map<String, Object>();
        resourceData.put('resource', resource);
        resourceData.put('utilization', analytics.resourceUtilization.get(resource));
        resourceChart.add(resourceData);
    }
    report.chartData.put('resourceUtilization', resourceChart);
}
public static AnalyticsReport getStoredAnalyticsReport(String reportId) {
    try {
        List<AnalyticsReportArchive__c> archives = [
            SELECT Report_Type__c, Generated_Date__c, Period_Start__c, Period_End__c, 
                   Generated_By__c, Overall_Score__c, Executive_Summary__c, Metrics_JSON__c, 
                   Insights_JSON__c, Chart_Data_JSON__c, Has_Anomalies__c 
            FROM AnalyticsReportArchive__c 
            WHERE Id = :reportId 
            LIMIT 1
        ];

        if (archives.isEmpty()) {
            throw new AnalyticsException('Report not found: ' + reportId);
        }

        AnalyticsReportArchive__c archive = archives[0];
        AnalyticsReport report = new AnalyticsReport();

        report.reportType = archive.Report_Type__c;
        report.generatedAt = archive.Generated_Date__c;
        report.periodStart = archive.Period_Start__c;
        report.periodEnd = archive.Period_End__c;
        report.generatedBy = archive.Generated_By__c;
        report.overallScore = archive.Overall_Score__c;
        report.executiveSummary = archive.Executive_Summary__c;
        report.hasAnomalies = archive.Has_Anomalies__c;

        if (String.isNotBlank(archive.Metrics_JSON__c)) {
            report.metrics = (Map<String, Object>) JSON.deserializeUntyped(archive.Metrics_JSON__c);
        }

        if (String.isNotBlank(archive.Insights_JSON__c)) {
            List<Object> insightObjects = (List<Object>) JSON.deserializeUntyped(archive.Insights_JSON__c);
            report.insights = new List<AnalyticsInsight>();

            for (Object insightObj : insightObjects) {
                Map<String, Object> insightMap = (Map<String, Object>) insightObj;
                AnalyticsInsight insight = new AnalyticsInsight(
                    (String) insightMap.get('category'),
                    (String) insightMap.get('title'),
                    (String) insightMap.get('description'),
                    (String) insightMap.get('severity')
                );

                if (insightMap.containsKey('impact')) {
                    insight.impact = (Decimal) insightMap.get('impact');
                }
                if (insightMap.containsKey('recommendation')) {
                    insight.recommendation = (String) insightMap.get('recommendation');
                }
                if (insightMap.containsKey('supportingData')) {
                    insight.supportingData = (Map<String, Object>) insightMap.get('supportingData');
                }
                if (insightMap.containsKey('discoveredAt')) {
                    String dateStr = (String) insightMap.get('discoveredAt');
                    insight.discoveredAt = DateTime.valueOf(dateStr);
                }

                report.insights.add(insight);
            }
        }

        if (String.isNotBlank(archive.Chart_Data_JSON__c)) {
            report.chartData = (Map<String, List<Object>>) JSON.deserializeUntyped(archive.Chart_Data_JSON__c);
        }

        return report;

    } catch (Exception e) {
        System.debug('Error retrieving stored analytics report: ' + e.getMessage());
        throw new AnalyticsException('Failed to retrieve analytics report: ' + e.getMessage());
    }
}

/**
 * Generate recommended actions based on report insights
 */
public static List<String> generateRecommendedActions(AnalyticsReport report) {
    List<String> recommendations = new List<String>();

    try {
        // Analyze insights and generate actionable recommendations
        for (AnalyticsInsight insight : report.insights) {
            switch on insight.category.toUpperCase() {
                when 'PERFORMANCE' {
                    if (insight.severity == 'CRITICAL' || insight.severity == 'HIGH') {
                        if (insight.title.contains('Response Time')) {
                            recommendations.add('Optimize database queries and implement response caching');
                            recommendations.add('Review and scale server resources');
                            recommendations.add('Implement load balancing for high-traffic endpoints');
                        }
                        if (insight.title.contains('Cache')) {
                            recommendations.add('Review cache configuration and increase cache size');
                            recommendations.add('Implement cache warming strategies');
                            recommendations.add('Analyze cache eviction patterns');
                        }
                    }
                }
                when 'COMPLIANCE' {
                    if (insight.severity == 'CRITICAL') {
                        recommendations.add('Immediate compliance team review required');
                        recommendations.add('Implement automated compliance monitoring');
                        recommendations.add('Schedule emergency compliance audit');
                    }
                    if (insight.title.contains('Violation')) {
                        recommendations.add('Review and update compliance policies');
                        recommendations.add('Provide additional staff compliance training');
                        recommendations.add('Implement stricter access controls');
                    }
                }
                when 'SECURITY' {
                    if (insight.severity == 'CRITICAL' || insight.severity == 'HIGH') {
                        recommendations.add('Conduct immediate security assessment');
                        recommendations.add('Review and strengthen authentication mechanisms');
                        recommendations.add('Implement additional monitoring and alerting');
                    }
                    if (insight.title.contains('Failed Authentication')) {
                        recommendations.add('Implement account lockout policies');
                        recommendations.add('Deploy CAPTCHA for repeated failures');
                        recommendations.add('Review IP-based access restrictions');
                    }
                }
                when 'USER_ENGAGEMENT' {
                    if (insight.title.contains('Low Session')) {
                        recommendations.add('Conduct user experience analysis');
                        recommendations.add('Implement user onboarding improvements');
                        recommendations.add('Survey users for feedback on system usability');
                    }
                    if (insight.title.contains('Feature')) {
                        recommendations.add('Provide targeted feature training');
                        recommendations.add('Improve feature discoverability');
                        recommendations.add('Consider feature usage analytics dashboard');
                    }
                }
                when 'AVAILABILITY' {
                    if (insight.severity == 'CRITICAL') {
                        recommendations.add('Investigate system stability issues immediately');
                        recommendations.add('Review disaster recovery procedures');
                        recommendations.add('Implement redundancy and failover mechanisms');
                    }
                }
            }
        }

        // Add general recommendations based on overall score
        if (report.overallScore < 70) {
            recommendations.add('Conduct comprehensive system health review');
            recommendations.add('Prioritize critical issues identified in this report');
            recommendations.add('Schedule weekly monitoring reviews until scores improve');
        } else if (report.overallScore < 85) {
            recommendations.add('Focus on identified medium-priority improvements');
            recommendations.add('Monitor trends to prevent score degradation');
        }

        // Remove duplicates
        Set<String> uniqueRecommendations = new Set<String>(recommendations);
        return new List<String>(uniqueRecommendations);

    } catch (Exception e) {
        System.debug('Error generating recommendations: ' + e.getMessage());
        return new List<String>{'Review system performance and address identified issues'};
    }
}

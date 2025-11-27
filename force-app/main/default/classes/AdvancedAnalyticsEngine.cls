public with sharing class AdvancedAnalyticsEngine {
    // Analytics constants
    private static final Integer DEFAULT_ANALYTICS_PERIOD_DAYS = 30;
    private static final Integer MAX_ANALYTICS_RECORDS = 10000;

    // --- Nested Data Structure Definitions ---

    /**
     * Main container for a generated report.
     */
    public class AnalyticsReport {
        @AuraEnabled public String reportType;
        @AuraEnabled public DateTime generatedAt;
        @AuraEnabled public DateTime periodStart;
        @AuraEnabled public DateTime periodEnd;
        @AuraEnabled public String generatedBy;
        @AuraEnabled public Map<String, Object> metrics;
        @AuraEnabled public List<AnalyticsInsight> insights;
        @AuraEnabled public String executiveSummary;
        @AuraEnabled public Decimal overallScore;
        @AuraEnabled public String recommendedActions;
        @AuraEnabled public Map<String, List<Object>> chartData;
        @AuraEnabled public Boolean hasAnomalies;
        @AuraEnabled public List<String> criticalFindings;

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
     * Structure for individual analytics insights or anomalies.
     */
    public class AnalyticsInsight {
        @AuraEnabled public String category;
        @AuraEnabled public String title;
        @AuraEnabled public String description;
        @AuraEnabled public String severity; // LOW, MEDIUM, HIGH, CRITICAL
        @AuraEnabled public Decimal impact; // 0-100 scale
        @AuraEnabled public String recommendation;
        @AuraEnabled public Map<String, Object> supportingData;
        @AuraEnabled public DateTime discoveredAt;

        public AnalyticsInsight(String category, String title, String description, String severity) {
            this.category = category;
            this.title = title;
            this.description = description;
            this.severity = severity;
            this.supportingData = new Map<String, Object>();
            this.discoveredAt = DateTime.now();
        }
    }

    // --- Data Classes for Specific Analytics Modules ---

    public class DocumentGenerationAnalytics {
        @AuraEnabled public Integer totalDocuments;
        @AuraEnabled public Integer successfulGenerations;
        @AuraEnabled public Integer failedGenerations;
        @AuraEnabled public Decimal successRate;
        @AuraEnabled public Decimal averageGenerationTime;
        @AuraEnabled public Map<String, Integer> documentTypeBreakdown;
        @AuraEnabled public Map<String, Integer> templateUsageStats;
    }

    public class ComplianceAnalytics {
        @AuraEnabled public Decimal overallComplianceScore;
        @AuraEnabled public Map<String, Decimal> regulationScores; // GDPR, HIPAA, etc.
        @AuraEnabled public Integer totalViolations;
        @AuraEnabled public Map<String, Integer> violationsBySeverity;
    }

    public class UserActivityAnalytics {
        @AuraEnabled public Integer totalActiveUsers;
        @AuraEnabled public Map<String, Integer> usersByRole;
        @AuraEnabled public Map<String, Integer> featureUsageStats;
        @AuraEnabled public Decimal averageSessionDuration;
    }

    public class SystemPerformanceAnalytics {
        @AuraEnabled public Decimal averageResponseTime;
        @AuraEnabled public Decimal cacheHitRatio;
        @AuraEnabled public Decimal systemUptime;
        @AuraEnabled public Integer totalApiRequests;
        @AuraEnabled public Decimal apiSuccessRate;
    }

    // --- Core Method for Report Generation ---

    /**
     * Main entry point for generating reports based on a report type.
     */
    public static AnalyticsReport generateComprehensiveReport(String reportType, DateTime periodStart, DateTime periodEnd) {
        try {
            AnalyticsReport report = new AnalyticsReport();
            report.reportType = reportType;
            report.periodStart = periodStart;
            report.periodEnd = periodEnd;

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

            // Store report in a custom object for future reference
            storeAnalyticsReport(report);
            return report;

        } catch (Exception e) {
            System.debug('Analytics report generation error: ' + e.getMessage());
            throw new AnalyticsException('Failed to generate analytics report: ' + e.getMessage());
        }
    }

    // --- Public Methods ---

    /**
     * @AuraEnabled method to generate and return a comprehensive analytics report.
     * @param reportType The type of report to generate (e.g., 'EXECUTIVE_SUMMARY').
     * @param periodStart The start date/time for the report period.
     * @param periodEnd The end date/time for the report period.
     * @return AnalyticsReport The generated analytics report.
     */
    @AuraEnabled(cacheable=true)
    public static AnalyticsReport getComprehensiveAnalytics(String reportType, DateTime periodStart, DateTime periodEnd) {
        return generateComprehensiveReport(reportType, periodStart, periodEnd);
    }

    /**
     * @AuraEnabled method to generate an analytics report and export it as a CSV formatted string.
     * @param reportType The type of report to generate.
     * @param periodStart The start date for the report period.
     * @param periodEnd The end date for the report period.
     * @return String The report data formatted as a CSV.
     */
    @AuraEnabled(cacheable=true)
    public static String exportAnalyticsReport(String reportType, DateTime periodStart, DateTime periodEnd) {
        try {
            // 1. Generate the report data
            AnalyticsReport report = generateComprehensiveReport(reportType, periodStart, periodEnd);

            // 2. Build the CSV string
            List<String> csvLines = new List<String>();

            // Report Metadata
            csvLines.add('Analytics Report');
            csvLines.add('Report Type,"' + report.reportType + '"');
            csvLines.add('Generated At,"' + report.generatedAt.format() + '"');
            csvLines.add('Period,"' + report.periodStart.format() + ' - ' + report.periodEnd.format() + '"');
            csvLines.add(''); // Blank line

            // Summary
            csvLines.add('Overall Score,"' + report.overallScore + '"');
            if (String.isNotBlank(report.executiveSummary)) {
                csvLines.add('Executive Summary,"' + report.executiveSummary.replace('"', '""') + '"');
            }
            csvLines.add(''); // Blank line

            // Insights Section
            if (report.insights != null && !report.insights.isEmpty()) {
                csvLines.add('Insights');
                csvLines.add('Category,Title,Description,Severity,Recommendation');
                for (AnalyticsInsight insight : report.insights) {
                    String line = '"' + insight.category + '","' + insight.title + '","' + insight.description.replace('"', '""') + '","' + insight.severity + '","' + (String.isNotBlank(insight.recommendation) ? insight.recommendation.replace('"', '""') : '') + '"';
                    csvLines.add(line);
                }
            }
            csvLines.add(''); // Blank line

            // Metrics Section
            if (report.metrics != null && !report.metrics.isEmpty()) {
                csvLines.add('Metrics');
                csvLines.add('Metric,Key,Value');
                for (String metricName : report.metrics.keySet()) {
                    Object metricData = report.metrics.get(metricName);
                    Map<String, Object> metricMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(metricData));
                    for (String key : metricMap.keySet()) {
                        String value = String.valueOf(metricMap.get(key));
                        csvLines.add('"' + metricName + '","' + key + '","' + value.replace('"', '""') + '"');
                    }
                }
            }

            return String.join(csvLines, '\n');

        } catch (Exception e) {
            System.debug('Failed to export analytics report: ' + e.getMessage());
            throw new AnalyticsException('Failed to export analytics report: ' + e.getMessage());
        }
    }

    // --- Private Helper Methods for Specific Reports ---

    private static void generateExecutiveSummaryReport(AnalyticsReport report) {
        DocumentGenerationAnalytics docGen = getDocumentGenerationAnalytics(report.periodStart, report.periodEnd);
        ComplianceAnalytics compliance = getComplianceAnalytics(report.periodStart, report.periodEnd);
        UserActivityAnalytics userActivity = getUserActivityAnalytics(report.periodStart, report.periodEnd);
        SystemPerformanceAnalytics performance = getSystemPerformanceAnalytics(report.periodStart, report.periodEnd);

        report.metrics.put('documentGeneration', docGen);
        report.metrics.put('compliance', compliance);
        report.metrics.put('userActivity', userActivity);
        report.metrics.put('performance', performance);

        report.overallScore = calculateSystemHealthScore(docGen, compliance, userActivity, performance);
        // Additional logic to populate insights, summary, and charts
        generateExecutiveDashboardCharts(report);
    }

    private static void generateDocumentGenerationReport(AnalyticsReport report) {
        DocumentGenerationAnalytics docGen = getDocumentGenerationAnalytics(report.periodStart, report.periodEnd);
        report.metrics.put('documentGeneration', docGen);
        
        // Generate insights based on thresholds (e.g., slow generation time, low success rate)
        if (docGen.averageGenerationTime > 5.0) {
            report.insights.add(new AnalyticsInsight('Performance', 'Slow Document Generation', 'Average generation time is ' + docGen.averageGenerationTime + 's, exceeding the 5s threshold.', 'MEDIUM'));
        }
        if (docGen.successRate < 95.0) {
            report.insights.add(new AnalyticsInsight('Reliability', 'Low Success Rate', 'Document generation success rate is ' + docGen.successRate + '%, below the 95% target.', 'HIGH'));
        }
        
        // Calculate a performance score
        report.overallScore = (docGen.successRate > 0) ? docGen.successRate : 0;
    }
    
    private static void generateComplianceReport(AnalyticsReport report) {
        ComplianceAnalytics compliance = getComplianceAnalytics(report.periodStart, report.periodEnd);
        report.metrics.put('compliance', compliance);
        report.overallScore = compliance.overallComplianceScore;
    }

    private static void generateUserActivityReport(AnalyticsReport report) {
        UserActivityAnalytics userActivity = getUserActivityAnalytics(report.periodStart, report.periodEnd);
        report.metrics.put('userActivity', userActivity);
        Decimal engagementScore = (userActivity.totalActiveUsers > 0 && userActivity.averageSessionDuration > 0) ? (userActivity.totalActiveUsers * userActivity.averageSessionDuration / 1000) : 0;
        report.overallScore = engagementScore.setScale(2);
    }

    private static void generateSystemPerformanceReport(AnalyticsReport report) {
        SystemPerformanceAnalytics performance = getSystemPerformanceAnalytics(report.periodStart, report.periodEnd);
        report.metrics.put('performance', performance);
        report.overallScore = (performance.systemUptime + performance.apiSuccessRate) / 2;
    }

    private static void generateSecurityAuditReport(AnalyticsReport report) {
        // Mock query for security metrics
        Integer failedLogins = [SELECT COUNT() FROM AuthenticationLog__c WHERE Status__c = 'Failed' AND CreatedDate >= :report.periodStart AND CreatedDate <= :report.periodEnd];
        Integer violations = [SELECT COUNT() FROM SecurityViolationLog__c WHERE CreatedDate >= :report.periodStart AND CreatedDate <= :report.periodEnd];
        
        report.metrics.put('failedLogins', failedLogins);
        report.metrics.put('permissionViolations', violations);

        if (failedLogins > 100) {
            report.insights.add(new AnalyticsInsight('Security', 'High Failed Login Attempts', 'Detected ' + failedLogins + ' failed login attempts.', 'HIGH'));
        }
        report.overallScore = Math.max(0, 100 - (failedLogins + violations * 5));
    }

    // --- Data Retrieval Methods (SOQL Queries) ---

    private static DocumentGenerationAnalytics getDocumentGenerationAnalytics(DateTime startTime, DateTime endTime) {
        DocumentGenerationAnalytics analytics = new DocumentGenerationAnalytics();
        List<AggregateResult> results = [
            SELECT COUNT(Id) total, Status__c, Document_Type__c, Template_Used__c, AVG(Generation_Time_Ms__c) avgTime
            FROM DocumentGenerationLog__c
            WHERE CreatedDate >= :startTime AND CreatedDate <= :endTime
            GROUP BY Status__c, Document_Type__c, Template_Used__c
        ];
        // ... Logic to parse AggregateResult list and populate analytics object ...
        return analytics;
    }

    private static ComplianceAnalytics getComplianceAnalytics(DateTime startTime, DateTime endTime) {
        ComplianceAnalytics analytics = new ComplianceAnalytics();
        List<AggregateResult> results = [
            SELECT AVG(Overall_Score__c) avgScore, COUNT(Id) totalViolations, Severity__c
            FROM DocumentComplianceTracking__c
            WHERE CreatedDate >= :startTime AND CreatedDate <= :endTime
            GROUP BY Severity__c
        ];
        // ... Logic to parse AggregateResult list and populate analytics object ...
        return analytics;
    }

    private static UserActivityAnalytics getUserActivityAnalytics(DateTime startTime, DateTime endTime) {
        UserActivityAnalytics analytics = new UserActivityAnalytics();
        List<AggregateResult> results = [SELECT COUNT_DISTINCT(UserId__c) activeUsers FROM AuditTrail__c WHERE Timestamp__c >= :startTime AND Timestamp__c <= :endTime];
        if (!results.isEmpty()) {
            analytics.totalActiveUsers = (Integer)results[0].get('activeUsers');
        } else {
            analytics.totalActiveUsers = 0;
        }
        // ... Additional queries for role breakdown, feature usage, session duration ...
        return analytics;
    }

    private static SystemPerformanceAnalytics getSystemPerformanceAnalytics(DateTime startTime, DateTime endTime) {
        SystemPerformanceAnalytics analytics = new SystemPerformanceAnalytics();
        List<AggregateResult> results = [
            SELECT AVG(ResponseTime__c) avgResp, AVG(CacheHitRatio__c) avgCache
            FROM SystemMetricsSnapshot__c
            WHERE CreatedDate >= :startTime AND CreatedDate <= :endTime
        ];
        // ... Logic to parse AggregateResult and query APIRequestLog__c to populate analytics object ...
        return analytics;
    }
    
    // --- Utility and Persistence Methods ---

    private static Decimal calculateSystemHealthScore(DocumentGenerationAnalytics docGen, ComplianceAnalytics compliance, UserActivityAnalytics user, SystemPerformanceAnalytics perf) {
        // Weighted score calculation
        Decimal docScore = (docGen.successRate != null ? docGen.successRate : 80) * 0.3;
        Decimal complianceScore = (compliance.overallComplianceScore != null ? compliance.overallComplianceScore : 80) * 0.3;
        Decimal perfScore = (perf.apiSuccessRate != null ? perf.apiSuccessRate : 80) * 0.25;
        Decimal userScore = (user.totalActiveUsers != null && user.totalActiveUsers > 10 ? 90 : 70) * 0.15;
        return (docScore + complianceScore + perfScore + userScore).setScale(2);
    }
    
    private static void generateExecutiveDashboardCharts(AnalyticsReport report) {
        // Placeholder for chart data generation logic
        report.chartData.put('documentVolume', new List<Object>());
        report.chartData.put('complianceTrend', new List<Object>());
    }

    private static void storeAnalyticsReport(AnalyticsReport report) {
        try {
            AnalyticsReportArchive__c archive = new AnalyticsReportArchive__c(
                Report_Type__c = report.reportType,
                Generated_Date__c = report.generatedAt.date(),
                Period_Start_Date__c = report.periodStart.date(),
                Period_End_Date__c = report.periodEnd.date(),
                Overall_Score__c = report.overallScore,
                Executive_Summary__c = report.executiveSummary,
                Has_Anomalies__c = report.hasAnomalies,
                Metrics_JSON__c = JSON.serialize(report.metrics),
                Insights_JSON__c = JSON.serialize(report.insights),
                Chart_Data_JSON__c = JSON.serialize(report.chartData)
            );
            insert archive;
        } catch (Exception e) {
            System.debug('Failed to store analytics report: ' + e.getMessage());
        }
    }
    
    // Custom Exception Class
    public class AnalyticsException extends Exception {}
}
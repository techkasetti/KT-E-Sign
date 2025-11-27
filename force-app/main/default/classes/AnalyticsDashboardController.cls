public with sharing class AnalyticsDashboardController {
    // Stub methods moved to top-level class
    private static AnalyticsReport generateComprehensiveReport(String type, DateTime startTime, DateTime endTime) {
        return new AnalyticsReport();
    }
    private static AnalyticsReport getStoredAnalyticsReport(String reportId) {
        return new AnalyticsReport();
    }
    private static Map<String, Object> getRealTimeDashboardData() {
        return new Map<String, Object>();
    }
    private static List<String> generateRecommendedActions(AnalyticsReport report) {
        return new List<String>();
    }

    public class AnalyticsReport {
        public String reportType;
        public DateTime generatedAt;
        public DateTime periodStart;
        public DateTime periodEnd;
        public Decimal overallScore;
        public String executiveSummary;
        public Boolean hasAnomalies;
        public Map<String, Object> metrics;
        public List<AnalyticsInsight> insights;
        public Object chartData;
        public Object criticalFindings;
    }

    public class AnalyticsInsight {
        public String category;
        public String title;
        public String description;
        public String severity;
        public String impact;
        public String recommendation;
        public DateTime discoveredAt;
        public Object supportingData;
    }
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDashboardData(String reportType, String timeframe) {
        try {
            DateTime endTime = DateTime.now();
            DateTime startTime;
            
            // Determine time range based on timeframe
            switch on timeframe?.toLowerCase() {
                when 'today' { startTime = DateTime.newInstance(Date.today(), Time.newInstance(0,0,0,0)); }
                when 'week'  { startTime = endTime.addDays(-7); }
                when 'month' { startTime = endTime.addDays(-30); }
                when 'quarter' { startTime = endTime.addDays(-90); }
                when else { startTime = endTime.addDays(-7); }
            }
            
            // Generate report based on type
            AnalyticsReport report;
            switch on reportType?.toLowerCase() {
                when 'executive' { report = generateComprehensiveReport('EXECUTIVE_SUMMARY', startTime, endTime); }
                when 'performance' { report = generateComprehensiveReport('SYSTEM_PERFORMANCE', startTime, endTime); }
                when 'compliance' { report = generateComprehensiveReport('COMPLIANCE_OVERVIEW', startTime, endTime); }
                when 'documents' { report = generateComprehensiveReport('DOCUMENT_GENERATION', startTime, endTime); }
                when 'security' { report = generateComprehensiveReport('SECURITY_AUDIT', startTime, endTime); }
                when 'users' { report = generateComprehensiveReport('USER_ACTIVITY', startTime, endTime); }
                when else { report = generateComprehensiveReport('EXECUTIVE_SUMMARY', startTime, endTime); }
            }
            
            return formatReportForLWC(report);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error loading dashboard data: ' + e.getMessage());
        }
    }

@AuraEnabled
public static Map<String, Object> getRealTimeMetrics() {
    try {
    return getRealTimeDashboardData();
    } catch (Exception e) {
        throw new AuraHandledException('Error loading real-time metrics: ' + e.getMessage());
    }
}

@AuraEnabled
public static List<Map<String, Object>> getAvailableReports() {
    try {
        List<Map<String, Object>> reports = new List<Map<String, Object>>();
        List<AnalyticsReportArchive__c> archives = [
            SELECT Id, Report_Type__c, Generated_Date__c, Overall_Score__c, Has_Anomalies__c, Generated_By__c
            FROM AnalyticsReportArchive__c
            ORDER BY Generated_Date__c DESC
            LIMIT 50
        ];
        
        for (AnalyticsReportArchive__c archive : archives) {
            Map<String, Object> reportInfo = new Map<String, Object>();
            reportInfo.put('id', archive.Id);
            reportInfo.put('type', archive.Report_Type__c);
            reportInfo.put('generatedDate', archive.Generated_Date__c);
            reportInfo.put('overallScore', archive.Overall_Score__c);
            reportInfo.put('hasAnomalies', archive.Has_Anomalies__c);
            reportInfo.put('generatedBy', archive.Generated_By__c);
            reports.add(reportInfo);
        }
        return reports;
        
    } catch (Exception e) {
        throw new AuraHandledException('Error loading available reports: ' + e.getMessage());
    }
}

@AuraEnabled
public static Map<String, Object> getStoredReport(String reportId) {
    try {
    AnalyticsReport report = getStoredAnalyticsReport(reportId);
        return formatReportForLWC(report);
    } catch (Exception e) {
        throw new AuraHandledException('Error loading stored report: ' + e.getMessage());
    }
}

@AuraEnabled
    public static List<String> generateRecommendations(String reportId) {
        try {
        AnalyticsReport analyticsReport = getStoredAnalyticsReport(reportId);
        return generateRecommendedActions(analyticsReport);
        } catch (Exception e) {
            throw new AuraHandledException('Error generating recommendations: ' + e.getMessage());
        }
    }

@AuraEnabled
public static String exportReportToPDF(String reportId) {
    try {
    AnalyticsReport report = getStoredAnalyticsReport(reportId);
    return generatePDFReport(report);
    } catch (Exception e) {
        throw new AuraHandledException('Error exporting report to PDF: ' + e.getMessage());
    }
}

@AuraEnabled
public static void scheduleReport(String reportType, String frequency, String recipients) {
    try {
        // Implementation for scheduling reports
        // This would integrate with Salesforce's scheduling framework
        System.debug('Scheduling report: ' + reportType + ', frequency: ' + frequency + ', recipients: ' + recipients);
    } catch (Exception e) {
        throw new AuraHandledException('Error scheduling report: ' + e.getMessage());
    }
}

/** Format report for Lightning Web Component consumption */
private static Map<String, Object> formatReportForLWC(AnalyticsReport report) {
    Map<String, Object> formattedReport = new Map<String, Object>();
    
    formattedReport.put('reportType', report.reportType);
        formattedReport.put('generatedAt', report.generatedAt);
    formattedReport.put('periodStart', report.periodStart);
    formattedReport.put('periodEnd', report.periodEnd);
    formattedReport.put('overallScore', report.overallScore);
    formattedReport.put('executiveSummary', report.executiveSummary);
    formattedReport.put('hasAnomalies', report.hasAnomalies);
    
    // Metrics
    formattedReport.put('metrics', report.metrics);
    
    // Format insights
    List<Map<String, Object>> formattedInsights = new List<Map<String, Object>>();
    for (AnalyticsInsight insight : report.insights) {
        Map<String, Object> insightData = new Map<String, Object>();
        insightData.put('category', insight.category);
        insightData.put('title', insight.title);
        insightData.put('description', insight.description);
        insightData.put('severity', insight.severity);
        insightData.put('impact', insight.impact);
        insightData.put('recommendation', insight.recommendation);
        insightData.put('discoveredAt', insight.discoveredAt);
        insightData.put('supportingData', insight.supportingData);
        
        // Add severity styling
        insightData.put('severityClass', getSeverityClass(insight.severity));
        insightData.put('severityIcon', getSeverityIcon(insight.severity));
        formattedInsights.add(insightData);
    }
    formattedReport.put('insights', formattedInsights);
    
    // Chart data
    formattedReport.put('chartData', report.chartData);
    
    // Critical findings
    formattedReport.put('criticalFindings', report.criticalFindings);
    
    return formattedReport;
}

/** Get CSS class for severity */
private static String getSeverityClass(String severity) {
    switch on severity?.toUpperCase() {
        when 'CRITICAL' { return 'slds-theme_error'; }
        when 'HIGH'     { return 'slds-theme_warning'; }
        when 'MEDIUM'   { return 'slds-theme_info'; }
        when 'LOW'      { return 'slds-theme_success'; }
        when else       { return 'slds-theme_default'; }
    }
}

/** Get icon for severity */
private static String getSeverityIcon(String severity) {
    switch on severity?.toUpperCase() {
        when 'CRITICAL' { return 'utility:error'; }
        when 'HIGH'     { return 'utility:warning'; }
        when 'MEDIUM'   { return 'utility:info'; }
        when 'LOW'      { return 'utility:success'; }
        when else       { return 'utility:info'; }
    }
}

/** Generate PDF report */
private static String generatePDFReport(AnalyticsReport report) {
    // This would integrate with a PDF generation service
    return 'PDF generation not implemented - would generate PDF for report: ' + report.reportType;
}
}
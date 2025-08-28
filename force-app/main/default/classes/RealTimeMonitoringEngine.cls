public class RealTimeMonitoringEngine {
    
    // Monitoring constants
    private static final Integer PERFORMANCE_THRESHOLD_MS = 5000; // 5 seconds SLA
    private static final Integer CACHE_HIT_THRESHOLD = 85; // 85% cache hit ratio
    private static final Decimal SYSTEM_UPTIME_THRESHOLD = 99.5; // 99.5% uptime
    
    /**
     * System metrics collection class
     */
    public class SystemMetrics {
        public Decimal averageResponseTime;
        public Decimal cacheHitRatio;
        public Decimal systemUptime;
        public Integer concurrentUsers;
        public Integer documentsGenerated;
        public Integer complianceScore;
        public List&lt;String&gt; activeAlerts;
        public Map&lt;String, Object&gt; performanceBreakdown;
        public DateTime lastUpdated;
    }
    
    /**
     * Performance monitoring data point
     */
    public class PerformanceDataPoint {
        public String operationType;
        public Decimal executionTime;
        public String status;
        public DateTime timestamp;
        public String userId;
        public String documentType;
        public String region;
        public Map&lt;String, Object&gt; additionalMetrics;
    }
    
    /**
     * Collect and analyze real-time system metrics
     */
    @future(callout=true)
    public static void collectSystemMetrics() {
        try {
            SystemMetrics metrics = new SystemMetrics();
            
            // Collect performance metrics
            metrics = collectPerformanceMetrics(metrics);
            
            // Collect cache metrics
            metrics = collectCacheMetrics(metrics);
            
            // Collect system availability metrics
            metrics = collectAvailabilityMetrics(metrics);
            
            // Collect user activity metrics
            metrics = collectUserActivityMetrics(metrics);
            
            // Collect compliance metrics
            metrics = collectComplianceMetrics(metrics);
            
            // Store metrics
            storeSystemMetrics(metrics);
            
            // Check for threshold violations and generate alerts
            checkPerformanceThresholds(metrics);
            
            // Update real-time dashboard
            updateMonitoringDashboard(metrics);
} catch (Exception e) {
    System.debug('System metrics collection error: ' + e.getMessage());
    createMonitoringAlert('METRICS_COLLECTION_ERROR', e.getMessage());
}
}

/**
 * Collect performance metrics from recent operations
 */
private static SystemMetrics collectPerformanceMetrics(SystemMetrics metrics) {
    try {
        // Get performance data from last 5 minutes
        List<PerformanceBenchmark__c> recentPerformance = [
            SELECT ExecutionTime__c, OperationType__c, ErrorMessage__c, StartTime__c
            FROM PerformanceBenchmark__c
            WHERE StartTime__c >= :DateTime.now().addMinutes(-5)
            ORDER BY StartTime__c DESC
            LIMIT 100
        ];

        if (!recentPerformance.isEmpty()) {
            Decimal totalTime = 0;
            Integer successfulOperations = 0;
            Map<String, List<Decimal>> operationTimes = new Map<String, List<Decimal>>();

            for (PerformanceBenchmark__c perf : recentPerformance) {
                if (String.isBlank(perf.ErrorMessage__c)) {
                    totalTime += perf.ExecutionTime__c;
                    successfulOperations++;

                    // Group by operation type for detailed analysis
                    if (!operationTimes.containsKey(perf.OperationType__c)) {
                        operationTimes.put(perf.OperationType__c, new List<Decimal>());
                    }
                    operationTimes.get(perf.OperationType__c).add(perf.ExecutionTime__c);
                }
            }

            // Calculate average response time
            if (successfulOperations > 0) {
                metrics.averageResponseTime = totalTime / successfulOperations;
            } else {
                metrics.averageResponseTime = 0;
            }

            // Create performance breakdown by operation type
            metrics.performanceBreakdown = new Map<String, Object>();
            for (String operationType : operationTimes.keySet()) {
                List<Decimal> times = operationTimes.get(operationType);
                Decimal avgTime = 0;
                for (Decimal time : times) {
                    avgTime += time;
                }
                avgTime = avgTime / times.size();
                metrics.performanceBreakdown.put(operationType, avgTime);
            }
        } else {
            metrics.averageResponseTime = 0;
            metrics.performanceBreakdown = new Map<String, Object>();
        }

    } catch (Exception e) {
        System.debug('Performance metrics collection error: ' + e.getMessage());
        metrics.averageResponseTime = -1; // Error indicator
    }

    return metrics;
}
/**
     * Collect cache performance metrics
     */
    private static SystemMetrics collectCacheMetrics(SystemMetrics metrics) {
        try {
            // Get cache statistics from custom cache implementation
            List&lt;CacheMetrics__c&gt; cacheStats = [
                SELECT Cache_Hits__c, Cache_Misses__c, Cache_Type__c, Timestamp__c
                FROM CacheMetrics__c 
                WHERE Timestamp__c &gt;= :DateTime.now().addMinutes(-5)
                ORDER BY Timestamp__c DESC
                LIMIT 50
            ];
            
            if (!cacheStats.isEmpty()) {
                Decimal totalHits = 0;
                Decimal totalMisses = 0;
                
                for (CacheMetrics__c cacheStat : cacheStats) {
                    totalHits += cacheStat.Cache_Hits__c;
                    totalMisses += cacheStat.Cache_Misses__c;
                }
                
                if ((totalHits + totalMisses) &gt; 0) {
                    metrics.cacheHitRatio = (totalHits / (totalHits + totalMisses)) * 100;
                } else {
                    metrics.cacheHitRatio = 0;
                }
            } else {
                metrics.cacheHitRatio = 0;
            }
} catch (Exception e) {
    System.debug('Cache metrics collection error: ' + e.getMessage());
    metrics.cacheHitRatio = -1; // Error indicator
}

return metrics;
}
/**
 * Collect system availability and uptime metrics
 */
private static SystemMetrics collectAvailabilityMetrics(SystemMetrics metrics) {
    try {
        // Calculate uptime based on system health checks in last 24 hours
        List<SystemHealthCheck__c> healthChecks = [
            SELECT Status__c, Check_Time__c
            FROM SystemHealthCheck__c 
            WHERE Check_Time__c >= :DateTime.now().addHours(-24)
            ORDER BY Check_Time__c DESC
            LIMIT 288 // 24 hours * 12 checks per hour (5-minute intervals)
        ];
        
        if (!healthChecks.isEmpty()) {
            Integer totalChecks = healthChecks.size();
            Integer successfulChecks = 0;
            
            for (SystemHealthCheck__c healthCheck : healthChecks) {
                if (healthCheck.Status__c == 'HEALTHY' || healthCheck.Status__c == 'OK') {
                    successfulChecks++;
                }
            }
            
            // Calculate uptime percentage
            if (totalChecks > 0) {
                metrics.systemUptime = 
                    (Decimal.valueOf(successfulChecks) / Decimal.valueOf(totalChecks)) * 100;
            } else {
                metrics.systemUptime = 0;
            }
        } else {
            // No health check data - assume system is up if we can execute this code
            metrics.systemUptime = 100.0;
        }
        
        // Perform real-time health check
        Boolean currentHealthStatus = performRealTimeHealthCheck();
        if (!currentHealthStatus && metrics.systemUptime > 0) {
            // System is currently down - adjust uptime calculation
            metrics.systemUptime = Math.max(metrics.systemUptime - 5, 0);
        }
        
    } catch (Exception e) {
        System.debug('Availability metrics collection error: ' + e.getMessage());
        metrics.systemUptime = -1; // Error indicator
    }
    
    return metrics;
}

/**
 * Collect user activity and concurrency metrics
 */
private static SystemMetrics collectUserActivityMetrics(SystemMetrics metrics) {
    try {
        // Count active users in the last 15 minutes
        List<AggregateResult> activeUserStats = [
            SELECT COUNT(DISTINCT UserDetails__c) activeUsers
            FROM AuditTrail__c 
            WHERE Timestamp__c >= :DateTime.now().addMinutes(-15)
            AND Action__c IN ('DOCUMENT_GENERATED', 'SIGNATURE_REQUESTED', 'COMPLIANCE_CHECKED')
        ];
        
        if (!activeUserStats.isEmpty()) {
            metrics.concurrentUsers = (Integer)activeUserStats[0].get('activeUsers');
        } else {
            metrics.concurrentUsers = 0;
        }
        
        // Count documents generated in the last hour
        List<AggregateResult> documentStats = [
            SELECT COUNT() documentsGenerated
            FROM AuditTrail__c 
            WHERE Timestamp__c >= :DateTime.now().addHours(-1)
            AND Action__c = 'DOCUMENT_GENERATED'
            AND Status__c = 'SUCCESS'
        ];
        
        if (!documentStats.isEmpty()) {
            metrics.documentsGenerated = (Integer)documentStats[0].get('documentsGenerated');
        } else {
            metrics.documentsGenerated = 0;
        }
        
    } catch (Exception e) {
        System.debug('User activity metrics collection error: ' + e.getMessage());
        metrics.concurrentUsers = -1;   // Error indicator
        metrics.documentsGenerated = -1; // Error indicator
    }
    
    return metrics;
}
/**
 * Collect compliance score metrics
 */
private static SystemMetrics collectComplianceMetrics(SystemMetrics metrics) {
    try {
        // Calculate overall compliance score from recent documents
        List<AggregateResult> complianceStats = [
            SELECT AVG(ComplianceScore__c) avgScore
            FROM DocumentLifecycleConfiguration__c 
            WHERE CreatedDate__c >= :DateTime.now().addDays(-7)
            AND ComplianceScore__c != null
        ];
        
        if (!complianceStats.isEmpty() && complianceStats[0].get('avgScore') != null) {
            metrics.complianceScore = ((Decimal)complianceStats[0].get('avgScore')).intValue();
        } else {
            metrics.complianceScore = 0;
        }
        
        // Get active alerts
        metrics.activeAlerts = new List<String>();
        List<SLAViolationAlert__c> alerts = [
            SELECT Alert_Type__c, Severity__c 
            FROM SLAViolationAlert__c 
            WHERE Status__c = 'OPEN'
            AND Timestamp__c >= :DateTime.now().addHours(-24)
            ORDER BY Severity__c DESC, Timestamp__c DESC
            LIMIT 10
        ];
        
        for (SLAViolationAlert__c alert : alerts) {
            metrics.activeAlerts.add(alert.Severity__c + ': ' + alert.Alert_Type__c);
        }
        
    } catch (Exception e) {
        System.debug('Compliance metrics collection error: ' + e.getMessage());
        metrics.complianceScore = -1; 
        metrics.activeAlerts = new List<String>{'Error collecting alerts'};
    }
    
    return metrics;
}

/**
 * Perform real-time system health check
 */
private static Boolean performRealTimeHealthCheck() {
    try {
        // Test database connectivity
        Integer recordCount = [SELECT COUNT() FROM DocumentLifecycleConfiguration__c LIMIT 1];
        
        // Test custom objects accessibility
        Boolean customObjectsAccessible = testCustomObjectsAccess();
        
        // Test integration endpoints (simplified)
        Boolean integrationsHealthy = testIntegrationHealth();
        
        // Create health check record
        SystemHealthCheck__c healthCheck = new SystemHealthCheck__c(
            Status__c = (customObjectsAccessible && integrationsHealthy) ? 'HEALTHY' : 'DEGRADED',
            Check_Time__c = DateTime.now(),
            Database_Status__c = 'HEALTHY',
            Integration_Status__c = integrationsHealthy ? 'HEALTHY' : 'DEGRADED',
            Custom_Objects_Status__c = customObjectsAccessible ? 'HEALTHY' : 'ERROR',
            Response_Time__c = 100
        );
        
        insert healthCheck;
        
        return healthCheck.Status__c == 'HEALTHY';
        
    } catch (Exception e) {
        System.debug('Real-time health check error: ' + e.getMessage());
        
        // Create error health check record
        try {
            SystemHealthCheck__c errorHealthCheck = new SystemHealthCheck__c(
                Status__c = 'ERROR',
                Check_Time__c = DateTime.now(),
                Database_Status__c = 'ERROR',
                Integration_Status__c = 'UNKNOWN',
                Custom_Objects_Status__c = 'ERROR',
                Error_Message__c = e.getMessage(),
                Response_Time__c = -1
            );
            insert errorHealthCheck;
        } catch (Exception insertError) {
            System.debug('Failed to create error health check: ' + insertError.getMessage());
        }
        
        return false;
    }
}

/**
 * Test custom objects accessibility
 */
private static Boolean testCustomObjectsAccess() {
    try {
        // Test access to key custom objects
        Integer configCount = [SELECT COUNT() FROM DocumentLifecycleConfiguration__c LIMIT 1];
        Integer auditCount = [SELECT COUNT() FROM AuditTrail__c LIMIT 1];
        Integer alertCount = [SELECT COUNT() FROM SLAViolationAlert__c LIMIT 1];
        
        return true;
    } catch (Exception e) {
        System.debug('Custom objects access test failed: ' + e.getMessage());
        return false;
    }
}

/**
 * Test integration health (simplified)
 */
private static Boolean testIntegrationHealth() {
    try {
        // In a real implementation, this would test external API endpoints
        List<NamedCredential> credentials = [
            SELECT Id, MasterLabel 
            FROM NamedCredential 
            WHERE MasterLabel IN ('OpenAI_API', 'DocuSign_API', 'ComplianceCheck_API')
            LIMIT 3
        ];
        
        return credentials.size() >= 2; 
    } catch (Exception e) {
        System.debug('Integration health test failed: ' + e.getMessage());
        return false;
    }
}

/**
 * Store system metrics for historical analysis
 */
private static void storeSystemMetrics(SystemMetrics metrics) {
    try {
        metrics.lastUpdated = DateTime.now();
        
        SystemMetricsSnapshot__c snapshot = new SystemMetricsSnapshot__c(
            Timestamp__c = metrics.lastUpdated,
            Average_Response_Time__c = metrics.averageResponseTime,
            Cache_Hit_Ratio__c = metrics.cacheHitRatio,
            System_Uptime__c = metrics.systemUptime,
            Concurrent_Users__c = metrics.concurrentUsers,
            Documents_Generated_Hourly__c = metrics.documentsGenerated,
            Compliance_Score__c = metrics.complianceScore,
            Active_Alerts_Count__c = metrics.activeAlerts?.size(),
            Performance_Breakdown__c = JSON.serialize(metrics.performanceBreakdown),
            Status__c = determineSystemStatus(metrics)
        );
        
        insert snapshot;
        
        // Keep only last 7 days of snapshots for performance
        cleanupOldMetrics();
        
    } catch (Exception e) {
        System.debug('Metrics storage error: ' + e.getMessage());
    }
}
/**
 * Clean up old metrics data
 */
private static void cleanupOldMetrics() {
    try {
        List<SystemMetricsSnapshot__c> oldSnapshots = [
            SELECT Id 
            FROM SystemMetricsSnapshot__c 
            WHERE Timestamp__c < :DateTime.now().addDays(-7)
            LIMIT 100
        ];
        
        if (!oldSnapshots.isEmpty()) {
            delete oldSnapshots;
        }
    } catch (Exception e) {
        System.debug('Metrics cleanup error: ' + e.getMessage());
    }
}

/**
 * Determine overall system status based on metrics
 */
private static String determineSystemStatus(SystemMetrics metrics) {
    Integer healthScore = 100;
    
    // Performance impact
    if (metrics.averageResponseTime > PERFORMANCE_THRESHOLD_MS) {
        healthScore -= 20;
    }
    
    // Cache performance impact
    if (metrics.cacheHitRatio < CACHE_HIT_THRESHOLD) {
        healthScore -= 15;
    }
    
    // Uptime impact
    if (metrics.systemUptime < SYSTEM_UPTIME_THRESHOLD) {
        healthScore -= 25;
    }
    
    // Compliance impact
    if (metrics.complianceScore < 90) {
        healthScore -= 10;
    }
    
    // Active alerts impact
    if (metrics.activeAlerts?.size() > 5) {
        healthScore -= 10;
    }
    
    // Determine status based on health score
    if (healthScore >= 90) return 'EXCELLENT';
    if (healthScore >= 75) return 'GOOD';
    if (healthScore >= 60) return 'FAIR';
    if (healthScore >= 40) return 'POOR';
    return 'CRITICAL';
}

/**
 * Check performance thresholds and generate alerts
 */
private static void checkPerformanceThresholds(SystemMetrics metrics) {
    try {
        List<SLAViolationAlert__c> newAlerts = new List<SLAViolationAlert__c>();
        
        // Check response time threshold
        if (metrics.averageResponseTime > PERFORMANCE_THRESHOLD_MS) {
            newAlerts.add(createPerformanceAlert(
                'RESPONSE_TIME_VIOLATION',
                'HIGH',
                'Average response time (' + metrics.averageResponseTime + 'ms) exceeds threshold (' + PERFORMANCE_THRESHOLD_MS + 'ms)',
                metrics
            ));
        }
        
        // Check cache hit ratio threshold
        if (metrics.cacheHitRatio < CACHE_HIT_THRESHOLD) {
            newAlerts.add(createPerformanceAlert(
                'CACHE_PERFORMANCE_LOW',
                'MEDIUM',
                'Cache hit ratio (' + metrics.cacheHitRatio + '%) below threshold (' + CACHE_HIT_THRESHOLD + '%)',
                metrics
            ));
        }
        
        // Check system uptime threshold
        if (metrics.systemUptime < SYSTEM_UPTIME_THRESHOLD) {
            newAlerts.add(createPerformanceAlert(
                'SYSTEM_UPTIME_LOW',
                'CRITICAL',
                'System uptime (' + metrics.systemUptime + '%) below SLA threshold (' + SYSTEM_UPTIME_THRESHOLD + '%)',
                metrics
            ));
        }
        
        // Check compliance score
        if (metrics.complianceScore < 85) {
            newAlerts.add(createPerformanceAlert(
                'COMPLIANCE_SCORE_LOW',
                'HIGH',
                'Compliance score (' + metrics.complianceScore + '%) below acceptable threshold (85%)',
                metrics
            ));
        }
        
        // Insert new alerts
        if (!newAlerts.isEmpty()) {
            insert newAlerts;
            
            // Send notifications for critical alerts
            for (SLAViolationAlert__c alert : newAlerts) {
                if (alert.Severity__c == 'CRITICAL') {
                    sendCriticalAlertNotification(alert, metrics);
                }
            }
        }
        
    } catch (Exception e) {
        System.debug('Threshold checking error: ' + e.getMessage());
    }
}

/**
 * Create performance alert record
 */
private static SLAViolationAlert__c createPerformanceAlert(
    String alertType, 
    String severity, 
    String message, 
    SystemMetrics metrics
) {
    return new SLAViolationAlert__c(
        Alert_Type__c = alertType,
        Severity__c = severity,
        Message__c = message,
        Timestamp__c = DateTime.now(),
        Status__c = 'OPEN',
        Assigned_To__c = getSystemAdminId(),
        Auto_Generated__c = true,
        System_Metrics__c = JSON.serialize(metrics),
        Response_Time_Ms__c = metrics.averageResponseTime,
        Cache_Hit_Ratio__c = metrics.cacheHitRatio,
        System_Uptime__c = metrics.systemUptime
    );
}

/**
 * Send critical alert notification
 */
private static void sendCriticalAlertNotification(SLAViolationAlert__c alert, SystemMetrics metrics) {
    try {
        List<User> systemAdmins = [
            SELECT Id, Email, Name 
            FROM User 
            WHERE Profile.Name LIKE '%System Administrator%' 
            AND IsActive = true 
            LIMIT 3
        ];
        
        if (!systemAdmins.isEmpty()) {
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            
            for (User admin : systemAdmins) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[]{admin.Email});
                mail.setSubject('CRITICAL ALERT: DocGen System Performance Issue');
                
                String emailBody = buildCriticalAlertEmail(alert, metrics, admin.Name);
                mail.setPlainTextBody(emailBody);
                mail.setHtmlBody(buildCriticalAlertEmailHTML(alert, metrics, admin.Name));
                
                emails.add(mail);
            }
            
            Messaging.sendEmail(emails);
        }
        
    } catch (Exception e) {
        System.debug('Critical alert notification error: ' + e.getMessage());
    }
}
/**
 * Build critical alert email content
 */
private static String buildCriticalAlertEmail(
    SLAViolationAlert__c alert, 
    SystemMetrics metrics, 
    String adminName
) {
    StringBuilder email = new StringBuilder();
    
    email.append('CRITICAL SYSTEM ALERT\n');
    email.append('====================\n\n');
    
    email.append('Hello ').append(adminName).append(',\n\n');
    email.append('A critical performance issue has been detected in the DocGen system:\n\n');
    email.append('ALERT DETAILS:\n');
    email.append('- Alert Type: ').append(alert.Alert_Type__c).append('\n');
    email.append('- Severity: ').append(alert.Severity__c).append('\n');
    email.append('- Message: ').append(alert.Message__c).append('\n');
    email.append('- Detected At: ').append(alert.Timestamp__c.format()).append('\n\n');

    email.append('CURRENT SYSTEM METRICS:\n');
    email.append('- Average Response Time: ').append(metrics.averageResponseTime?.format()).append(' ms');
    if (metrics.averageResponseTime > PERFORMANCE_THRESHOLD_MS) {
        email.append(' [EXCEEDS SLA: ').append(PERFORMANCE_THRESHOLD_MS).append(' ms]');
    }
    email.append('\n');

    email.append('- Cache Hit Ratio: ').append(metrics.cacheHitRatio?.format()).append('%');
    if (metrics.cacheHitRatio < CACHE_HIT_THRESHOLD) {
        email.append(' [BELOW THRESHOLD: ').append(CACHE_HIT_THRESHOLD).append('%]');
    }
    email.append('\n');

    email.append('- System Uptime: ').append(metrics.systemUptime?.format()).append('%');
    if (metrics.systemUptime < SYSTEM_UPTIME_THRESHOLD) {
        email.append(' [BELOW SLA: ').append(SYSTEM_UPTIME_THRESHOLD).append('%]');
    }
    email.append('\n');

    email.append('- Concurrent Users: ').append(metrics.concurrentUsers).append('\n');
    email.append('- Documents Generated (Last Hour): ').append(metrics.documentsGenerated).append('\n');
    email.append('- Compliance Score: ').append(metrics.complianceScore).append('%\n');
    email.append('- Active Alerts Count: ').append(metrics.activeAlerts?.size()).append('\n\n');

    email.append('PERFORMANCE BREAKDOWN BY OPERATION:\n');
    if (metrics.performanceBreakdown != null && !metrics.performanceBreakdown.isEmpty()) {
        for (String operationType : metrics.performanceBreakdown.keySet()) {
            Object avgTime = metrics.performanceBreakdown.get(operationType);
            email.append('- ').append(operationType).append(': ')
                 .append(String.valueOf(avgTime)).append(' ms\n');
        }
    } else {
        email.append('- No detailed breakdown available\n');
    }

    email.append('\nACTIVE ALERTS:\n');
    if (metrics.activeAlerts != null && !metrics.activeAlerts.isEmpty()) {
        for (String activeAlert : metrics.activeAlerts) {
            email.append('- ').append(activeAlert).append('\n');
        }
    } else {
        email.append('- No other active alerts\n');
    }

    email.append('\nRECOMMENDED ACTIONS:\n');
    email.append('1. Log into the DocGen monitoring dashboard immediately\n');
    email.append('2. Check system resources and governor limit usage\n');
    email.append('3. Review recent batch processing jobs for bottlenecks\n');
    email.append('4. Verify external integration health (OpenAI, DocuSign, etc.)\n');
    email.append('5. Check cache performance and invalidation logs\n');
    email.append('6. Review audit trail for unusual activity patterns\n\n');

    if (alert.Severity__c == 'CRITICAL') {
        email.append('⚠️ IMMEDIATE ACTION REQUIRED ⚠️\n');
        email.append('This is a CRITICAL alert that requires immediate attention.\n');
        email.append('System performance may be severely impacted.\n\n');
    }

    email.append('SYSTEM HEALTH DASHBOARD: ');
    email.append(URL.getSalesforceBaseUrl().toExternalForm())
         .append('/lightning/n/System_Monitoring\n\n');

    email.append('TROUBLESHOOTING LINKS:\n');
    email.append('- Performance Metrics: ')
         .append(URL.getSalesforceBaseUrl().toExternalForm())
         .append('/lightning/o/PerformanceBenchmark__c/list\n');
    email.append('- System Health Checks: ')
         .append(URL.getSalesforceBaseUrl().toExternalForm())
         .append('/lightning/o/SystemHealthCheck__c/list\n');
    email.append('- Audit Trail: ')
         .append(URL.getSalesforceBaseUrl().toExternalForm())
         .append('/lightning/o/AuditTrail__c/list\n');
    email.append('- SLA Violation Alerts: ')
         .append(URL.getSalesforceBaseUrl().toExternalForm())
         .append('/lightning/o/SLAViolationAlert__c/list\n\n');

    email.append('Alert ID: ').append(alert.Id).append('\n');
    email.append('Generated at: ').append(DateTime.now().format()).append('\n\n');

    email.append('This is an automated alert from the DocGen Monitoring System.\n');
    email.append('Please acknowledge this alert in the system after taking action.\n\n');

    email.append('Best regards,\n');
    email.append('DocGen Monitoring System\n');

    return email.toString();
}
/**
 * Build HTML version of critical alert email
 */
private static String buildCriticalAlertEmailHTML(
    SLAViolationAlert__c alert, 
    SystemMetrics metrics, 
    String adminName
) {
    StringBuilder emailHTML = new StringBuilder();
    
    emailHTML.append('<html><body style="font-family: Arial, sans-serif;">');
    emailHTML.append('<div style="max-width: 800px; margin: 0 auto; padding: 20px;">');

    // Header
    emailHTML.append('<div style="background-color: #dc3545; color: white; padding: 15px; border-radius: 5px; margin-bottom: 20px;">');
    emailHTML.append('<h1 style="margin: 0; font-size: 24px;">🚨 CRITICAL SYSTEM ALERT</h1>');
    emailHTML.append('<p style="margin: 10px 0 0 0; font-size: 16px;">DocGen System Performance Issue Detected</p>');
    emailHTML.append('</div>');

    emailHTML.append('<p>Hello <strong>').append(adminName).append('</strong>,</p>');
    emailHTML.append('<p>A critical performance issue has been detected in the DocGen system:</p>');

    // Alert Details
    emailHTML.append('<div style="background-color: #f8f9fa; border-left: 4px solid #dc3545; padding: 15px; margin: 20px 0;">');
    emailHTML.append('<h3 style="color: #dc3545; margin-top: 0;">Alert Details</h3>');
    emailHTML.append('<table style="width: 100%; border-collapse: collapse;">');
    emailHTML.append('<tr><td style="padding: 5px; font-weight: bold;">Alert Type:</td><td style="padding: 5px;">')
             .append(alert.Alert_Type__c).append('</td></tr>');
    emailHTML.append('<tr><td style="padding: 5px; font-weight: bold;">Severity:</td><td style="padding: 5px; color: #dc3545; font-weight: bold;">')
             .append(alert.Severity__c).append('</td></tr>');
    emailHTML.append('<tr><td style="padding: 5px; font-weight: bold;">Message:</td><td style="padding: 5px;">')
             .append(alert.Message__c).append('</td></tr>');
    emailHTML.append('<tr><td style="padding: 5px; font-weight: bold;">Detected At:</td><td style="padding: 5px;">')
             .append(alert.Timestamp__c.format()).append('</td></tr>');
    emailHTML.append('</table></div>');

    // System Metrics
    emailHTML.append('<div style="background-color: #e9ecef; border-left: 4px solid #6c757d; padding: 15px; margin: 20px 0;">');
    emailHTML.append('<h3 style="color: #495057; margin-top: 0;">Current System Metrics</h3>');
    emailHTML.append('<table style="width: 100%; border-collapse: collapse;">');

    // Response Time
    String responseTimeStyle = metrics.averageResponseTime > PERFORMANCE_THRESHOLD_MS ? 
        'color: #dc3545; font-weight: bold;' : 'color: #28a745;';
    emailHTML.append('<tr><td style="padding: 5px; font-weight: bold;">Average Response Time:</td><td style="padding: 5px; ')
             .append(responseTimeStyle).append('">').append(metrics.averageResponseTime?.format()).append(' ms');
    if (metrics.averageResponseTime > PERFORMANCE_THRESHOLD_MS) {
        emailHTML.append(' <span style="background-color: #dc3545; color: white; padding: 2px 6px; border-radius: 3px; font-size: 12px;">EXCEEDS SLA</span>');
    }
    emailHTML.append('</td></tr>');

    // Cache Hit Ratio
    String cacheStyle = metrics.cacheHitRatio < CACHE_HIT_THRESHOLD ? 
        'color: #ffc107; font-weight: bold;' : 'color: #28a745;';
    emailHTML.append('<tr><td style="padding: 5px; font-weight: bold;">Cache Hit Ratio:</td><td style="padding: 5px; ')
             .append(cacheStyle).append('">').append(metrics.cacheHitRatio?.format()).append('%');
    if (metrics.cacheHitRatio < CACHE_HIT_THRESHOLD) {
        emailHTML.append(' <span style="background-color: #ffc107; color: #212529; padding: 2px 6px; border-radius: 3px; font-size: 12px;">BELOW THRESHOLD</span>');
    }
    emailHTML.append('</td></tr>');

    // System Uptime
    String uptimeStyle = metrics.systemUptime < SYSTEM_UPTIME_THRESHOLD ? 
        'color: #dc3545; font-weight: bold;' : 'color: #28a745;';
    emailHTML.append('<tr><td style="padding: 5px; font-weight: bold;">System Uptime:</td><td style="padding: 5px; ')
             .append(uptimeStyle).append('">').append(metrics.systemUptime?.format()).append('%');
    if (metrics.systemUptime < SYSTEM_UPTIME_THRESHOLD) {
        emailHTML.append(' <span style="background-color: #dc3545; color: white; padding: 2px 6px; border-radius: 3px; font-size: 12px;">BELOW SLA</span>');
    }
    emailHTML.append('</td></tr>');

    // Other metrics
    emailHTML.append('<tr><td style="padding: 5px; font-weight: bold;">Concurrent Users:</td><td style="padding: 5px;">')
             .append(metrics.concurrentUsers).append('</td></tr>');
    emailHTML.append('<tr><td style="padding: 5px; font-weight: bold;">Documents Generated (Last Hour):</td><td style="padding: 5px;">')
             .append(metrics.documentsGenerated).append('</td></tr>');

    String complianceStyle = metrics.complianceScore < 85 ? 
        'color: #ffc107; font-weight: bold;' : 'color: #28a745;';
    emailHTML.append('<tr><td style="padding: 5px; font-weight: bold;">Compliance Score:</td><td style="padding: 5px; ')
             .append(complianceStyle).append('">').append(metrics.complianceScore).append('%</td></tr>');

    emailHTML.append('<tr><td style="padding: 5px; font-weight: bold;">Active Alerts:</td><td style="padding: 5px;">')
             .append(metrics.activeAlerts?.size()).append('</td></tr>');

    emailHTML.append('</table></div>');

    // Performance Breakdown
    if (metrics.performanceBreakdown != null && !metrics.performanceBreakdown.isEmpty()) {
        emailHTML.append('<div style="background-color: #d1ecf1; border-left: 4px solid #0dcaf0; padding: 15px; margin: 20px 0;">');
        emailHTML.append('<h3 style="color: #0c63e4; margin-top: 0;">Performance Breakdown by Operation</h3>');
        emailHTML.append('<ul style="margin: 0; padding-left: 20px;">');
        for (String operationType : metrics.performanceBreakdown.keySet()) {
            Object avgTime = metrics.performanceBreakdown.get(operationType);
            emailHTML.append('<li style="padding: 2px 0;"><strong>').append(operationType).append(':</strong> ')
                     .append(String.valueOf(avgTime)).append(' ms</li>');
        }
        emailHTML.append('</ul></div>');
    }

    emailHTML.append('</div></body></html>');

    return emailHTML.toString();
}
    emailHTML.append('<p style="font-size: 16px;">This is a CRITICAL alert that requires immediate attention.<br/>System performance may be severely impacted.</p>');
    emailHTML.append('</div>');
}

// Footer
emailHTML.append('<p style="margin-top: 20px;">Alert ID: ').append(alert.Id).append('<br/>');
emailHTML.append('Generated at: ').append(DateTime.now().format()).append('</p>');

emailHTML.append('<p>This is an automated alert from the DocGen Monitoring System.<br/>Please acknowledge this alert in the system after taking action.</p>');

emailHTML.append('<p>Best regards,<br/>DocGen Monitoring System</p>');

emailHTML.append('</div></body></html>');

return emailHTML.toString();
emailHTML.append('<p style="color: #721c24; font-weight: bold; font-size: 16px; margin: 10px 0;">This is a CRITICAL alert that requires immediate attention.</p>');
emailHTML.append('<p style="color: #721c24; font-size: 14px; margin-bottom: 0;">System performance may be severely impacted.</p>');
emailHTML.append('</div>');

// Footer
emailHTML.append('<div style="border-top: 1px solid #dee2e6; margin-top: 30px; padding-top: 20px; font-size: 12px; color: #6c757d;">');
emailHTML.append('<p><strong>Alert ID:</strong> ').append(alert.Id).append('</p>');
emailHTML.append('<p><strong>Generated at:</strong> ').append(DateTime.now().format()).append('</p>');
emailHTML.append('<p>This is an automated alert from the DocGen Monitoring System.</p>');
emailHTML.append('<p>Please acknowledge this alert in the system after taking action.</p>');
emailHTML.append('<p style="margin-bottom: 0;"><em>DocGen Monitoring System</em></p>');
emailHTML.append('</div>');

emailHTML.append('</div>');
emailHTML.append('</body></html>');

return emailHTML.toString();
private static String getSystemAdminId() {
    List<User> systemAdmins = [
        SELECT Id 
        FROM User 
        WHERE Profile.Name LIKE '%System Administrator%' 
        AND IsActive = true 
        LIMIT 1
    ];
    
    return systemAdmins.isEmpty() ? UserInfo.getUserId() : systemAdmins[0].Id;
}

/**
 * Update monitoring dashboard with real-time data
 */
@future(callout=false)
private static void updateMonitoringDashboard(SystemMetrics metrics) {
    try {
        // Update dashboard configuration record
        List<MonitoringDashboardConfig__c> dashboardConfigs = [
            SELECT Id FROM MonitoringDashboardConfig__c 
            WHERE Name = 'Main_Dashboard' 
            LIMIT 1
        ];
        
        MonitoringDashboardConfig__c config;
        if (dashboardConfigs.isEmpty()) {
            config = new MonitoringDashboardConfig__c(
                Name = 'Main_Dashboard'
            );
        } else {
            config = dashboardConfigs[0];
        }
        
        // Update with current metrics
        config.Last_Updated__c = DateTime.now();
        config.Average_Response_Time__c = metrics.averageResponseTime;
        config.Cache_Hit_Ratio__c = metrics.cacheHitRatio;
        config.System_Uptime__c = metrics.systemUptime;
        config.Concurrent_Users__c = metrics.concurrentUsers;
        config.Documents_Generated_Hourly__c = metrics.documentsGenerated;
        config.Compliance_Score__c = metrics.complianceScore;
        config.Active_Alerts_Count__c = metrics.activeAlerts?.size();
        config.System_Status__c = determineSystemStatus(metrics);
        config.Performance_Breakdown_JSON__c = JSON.serialize(metrics.performanceBreakdown);
        
        if (dashboardConfigs.isEmpty()) {
            insert config;
        } else {
            update config;
        }
        
        // Publish platform event for real-time dashboard updates
        publishRealTimeUpdate(metrics);
        
    } catch (Exception e) {
        System.debug('Dashboard update error: ' + e.getMessage());
    }
}

/**
 * Publish real-time update platform event
 */
private static void publishRealTimeUpdate(SystemMetrics metrics) {
    try {
        SystemMetricsUpdate__e updateEvent = new SystemMetricsUpdate__e(
            Average_Response_Time__c = metrics.averageResponseTime,
            Cache_Hit_Ratio__c = metrics.cacheHitRatio,
            System_Uptime__c = metrics.systemUptime,
            Concurrent_Users__c = metrics.concurrentUsers,
            Documents_Generated__c = metrics.documentsGenerated,
            Compliance_Score__c = metrics.complianceScore,
            System_Status__c = determineSystemStatus(metrics),
            Update_Timestamp__c = DateTime.now(),
            Active_Alerts_JSON__c = JSON.serialize(metrics.activeAlerts)
        );
        
        EventBus.publish(updateEvent);
        
    } catch (Exception e) {
        System.debug('Platform event publishing error: ' + e.getMessage());
    }
}

/**
 * Create monitoring alert for system issues
 */
private static void createMonitoringAlert(String alertType, String message) {
    try {
        SLAViolationAlert__c alert = new SLAViolationAlert__c(
            Alert_Type__c = alertType,
            Severity__c = 'HIGH',
            Message__c = message,
            Timestamp__c = DateTime.now(),
            Status__c = 'OPEN',
            Assigned_To__c = getSystemAdminId(),
            Auto_Generated__c = true,
            Source__c = 'MONITORING_ENGINE'
        );
        
        insert alert;
        
    } catch (Exception e) {
        System.debug('Monitoring alert creation error: ' + e.getMessage());
    }
}

/**
 * Public method to get current system metrics
 */
public static SystemMetrics getCurrentSystemMetrics() {
    SystemMetrics metrics = new SystemMetrics();
    
    try {
        // Get the latest metrics snapshot
        List<SystemMetricsSnapshot__c> latestSnapshot = [
            SELECT Average_Response_Time__c, Cache_Hit_Ratio__c, System_Uptime__c,
                   Concurrent_Users__c, Documents_Generated_Hourly__c, Compliance_Score__c,
                   Active_Alerts_Count__c, Performance_Breakdown__c, Timestamp__c
            FROM SystemMetricsSnapshot__c 
            ORDER BY Timestamp__c DESC 
            LIMIT 1
        ];
        
        if (!latestSnapshot.isEmpty()) {
            SystemMetricsSnapshot__c snapshot = latestSnapshot[0];
            metrics.averageResponseTime = snapshot.Average_Response_Time__c;
            metrics.cacheHitRatio = snapshot.Cache_Hit_Ratio__c;
            metrics.systemUptime = snapshot.System_Uptime__c;
            metrics.concurrentUsers = Integer.valueOf(snapshot.Concurrent_Users__c);
            metrics.documentsGenerated = Integer.valueOf(snapshot.Documents_Generated_Hourly__c);
            metrics.complianceScore = Integer.valueOf(snapshot.Compliance_Score__c);
            metrics.lastUpdated = snapshot.Timestamp__c;
            
            // Parse performance breakdown
            if (String.isNotBlank(snapshot.Performance_Breakdown__c)) {
                metrics.performanceBreakdown = (Map<String, Object>)JSON.deserializeUntyped(snapshot.Performance_Breakdown__c);
            }
            
            // Get active alerts
            metrics.activeAlerts = new List<String>();
            List<SLAViolationAlert__c> alerts = [
                SELECT Alert_Type__c, Severity__c 
                FROM SLAViolationAlert__c 
                WHERE Status__c = 'OPEN' 
                ORDER BY Severity__c DESC, Timestamp__c DESC 
                LIMIT 10
            ];
            
            for (SLAViolationAlert__c alert : alerts) {
                metrics.activeAlerts.add(alert.Severity__c + ': ' + alert.Alert_Type__c);
            }
        } else {
            // No snapshots available - collect fresh metrics
            collectSystemMetrics();
            return getCurrentSystemMetrics(); // Recursive call after collection
        }
        
    } catch (Exception e) {
        System.debug('Current metrics retrieval error: ' + e.getMessage());
        // Return empty metrics on error
        metrics.averageResponseTime = 0;
        metrics.cacheHitRatio = 0;
        metrics.systemUptime = 0;
        metrics.concurrentUsers = 0;
        metrics.documentsGenerated = 0;
        metrics.complianceScore = 0;
        metrics.activeAlerts = new List<String>{'Error retrieving metrics'};
        metrics.lastUpdated = DateTime.now();
    }
    
    return metrics;
}

/**
 * Method to manually trigger metrics collection (for admin use)
 */
public static void triggerMetricsCollection() {
    collectSystemMetrics();
}

/**
 * Generate performance report for a specific time period
 */
public static String generatePerformanceReport(DateTime startTime, DateTime endTime) {
    try {
        List<SystemMetricsSnapshot__c> snapshots = [
            SELECT Average_Response_Time__c, Cache_Hit_Ratio__c, System_Uptime__c,
                   Concurrent_Users__c, Documents_Generated_Hourly__c, Compliance_Score__c,
                   Timestamp__c, Status__c
            FROM SystemMetricsSnapshot__c 
            WHERE Timestamp__c >= :startTime 
            AND Timestamp__c <= :endTime
            ORDER BY Timestamp__c ASC
        ];
        
        if (snapshots.isEmpty()) {
            return 'No performance data available for the specified time period.';
        }
        
        // Calculate statistics
        Decimal avgResponseTime = 0;
        Decimal avgCacheHitRatio = 0;
        Decimal avgUptime = 0;
        Decimal avgComplianceScore = 0;
        Integer totalDocuments = 0;
        Integer maxConcurrentUsers = 0;
        
        for (SystemMetricsSnapshot__c snapshot : snapshots) {
            if (snapshot.Average_Response_Time__c != null) {
                avgResponseTime += snapshot.Average_Response_Time__c;
            }
            if (snapshot.Cache_Hit_Ratio__c != null) {
                avgCacheHitRatio += snapshot.Cache_Hit_Ratio__c;
            }
            if (snapshot.System_Uptime__c != null) {
                avgUptime += snapshot.System_Uptime__c;
            }
            if (snapshot.Compliance_Score__c != null) {
                avgComplianceScore += snapshot.Compliance_Score__c;
            }
            if (snapshot.Documents_Generated_Hourly__c != null) {
                totalDocuments += Integer.valueOf(snapshot.Documents_Generated_Hourly__c);
            }
            if (snapshot.Concurrent_Users__c != null && snapshot.Concurrent_Users__c > maxConcurrentUsers) {
                maxConcurrentUsers = Integer.valueOf(snapshot.Concurrent_Users__c);
            }
        }
        
        Integer snapshotCount = snapshots.size();
        avgResponseTime = avgResponseTime / snapshotCount;
        avgCacheHitRatio = avgCacheHitRatio / snapshotCount;
        avgUptime = avgUptime / snapshotCount;
        avgComplianceScore = avgComplianceScore / snapshotCount;
        
        // Build report
        StringBuilder report = new StringBuilder();
        report.append('DOCGEN PERFORMANCE REPORT\n');
        report.append('=========================\n\n');
        report.append('Report Period: ').append(startTime.format()).append(' - ').append(endTime.format()).append('\n');
        report.append('Data Points: ').append(snapshotCount).append(' snapshots\n\n');
        
        report.append('PERFORMANCE SUMMARY:\n');
        report.append('- Average Response Time: ').append(avgResponseTime.format()).append(' ms\n');
        report.append('- Average Cache Hit Ratio: ').append(avgCacheHitRatio.format()).append('%\n');
        report.append('- Average System Uptime: ').append(avgUptime.format()).append('%\n');
        report.append('- Average Compliance Score: ').append(avgComplianceScore.format()).append('%\n');
        report.append('- Total Documents Generated: ').append(totalDocuments).append('\n');
        report.append('- Peak Concurrent Users: ').append(maxConcurrentUsers).append('\n\n');
        
        // SLA Compliance Check
        report.append('SLA COMPLIANCE:\n');
        report.append('- Response Time SLA (< ').append(PERFORMANCE_THRESHOLD_MS).append(' ms): ');
        report.append(avgResponseTime < PERFORMANCE_THRESHOLD_MS ? '✓ COMPLIANT' : '✗ NON-COMPLIANT').append('\n');
        
        report.append('- Cache Performance SLA (> ').append(CACHE_HIT_THRESHOLD).append('%): ');
        report.append(avgCacheHitRatio > CACHE_HIT_THRESHOLD ? '✓ COMPLIANT' : '✗ NON-COMPLIANT').append('\n');
        
        report.append('- System Uptime SLA (> ').append(SYSTEM_UPTIME_THRESHOLD).append('%): ');
        report.append(avgUptime > SYSTEM_UPTIME_THRESHOLD ? '✓ COMPLIANT' : '✗ NON-COMPLIANT').append('\n');
        
        return report.toString();
        
    } catch (Exception e) {
        return 'Error generating performance report: ' + e.getMessage();
    }
}
}

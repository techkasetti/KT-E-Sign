public class RealTimeMonitoringEngine {
    // Monitoring constants
    private static final Integer PERFORMANCE_THRESHOLD_MS = 5000; // 5 seconds SLA
    private static final Integer CACHE_HIT_THRESHOLD = 85; // 85% cache hit ratio
    private static final Decimal SYSTEM_UPTIME_THRESHOLD = 99.5; // 99.5% uptime

    /**
     * System metrics collection class
     */
    public class SystemMetrics {
        @AuraEnabled public Decimal averageResponseTime;
        @AuraEnabled public Decimal cacheHitRatio;
        @AuraEnabled public Decimal systemUptime;
        @AuraEnabled public Integer concurrentUsers;
        @AuraEnabled public Integer documentsGenerated;
        @AuraEnabled public Integer complianceScore;
        @AuraEnabled public List<String> activeAlerts;
        @AuraEnabled public Map<String, Object> performanceBreakdown;
        @AuraEnabled public DateTime lastUpdated;
    }

    /**
     * Performance monitoring data point
     */
    public class PerformanceDataPoint {
        @AuraEnabled public String operationType;
        @AuraEnabled public Decimal executionTime;
        @AuraEnabled public String status;
        @AuraEnabled public DateTime timestamp;
        @AuraEnabled public String userId;
        @AuraEnabled public String documentType;
        @AuraEnabled public String region;
        @AuraEnabled public Map<String, Object> additionalMetrics;
    }

    /**
     * Collect and analyze real-time system metrics asynchronously.
     */
    @future(callout=true)
    public static void collectSystemMetrics() {
        try {
            SystemMetrics metrics = new SystemMetrics();
            metrics = collectPerformanceMetrics(metrics);
            metrics = collectCacheMetrics(metrics);
            metrics = collectAvailabilityMetrics(metrics);
            metrics = collectUserActivityMetrics(metrics);
            metrics = collectComplianceMetrics(metrics);
            
            storeSystemMetrics(metrics);
            checkPerformanceThresholds(metrics);
            updateMonitoringDashboard(metrics);
            publishRealTimeUpdate(metrics);

        } catch (Exception e) {
            System.debug('System metrics collection error: ' + e.getMessage());
            createMonitoringAlert('METRICS_COLLECTION_ERROR', e.getMessage());
        }
    }

    // --- Private Metric Collection Methods ---

    private static SystemMetrics collectPerformanceMetrics(SystemMetrics metrics) {
        try {
            List<PerformanceBenchmark__c> recentPerformance = [
                SELECT ExecutionTime__c, OperationType__c, ErrorMessage__c FROM PerformanceBenchmark__c 
                WHERE StartTime__c >= :DateTime.now().addMinutes(-5) ORDER BY StartTime__c DESC LIMIT 100
            ];
            
            if (!recentPerformance.isEmpty()) {
                Decimal totalTime = 0;
                Integer successfulOperations = 0;
                Map<String, List<Decimal>> operationTimes = new Map<String, List<Decimal>>();
                for (PerformanceBenchmark__c perf : recentPerformance) {
                    if (String.isBlank(perf.ErrorMessage__c)) {
                        totalTime += perf.ExecutionTime__c;
                        successfulOperations++;
                        if (!operationTimes.containsKey(perf.OperationType__c)) {
                            operationTimes.put(perf.OperationType__c, new List<Decimal>());
                        }
                        operationTimes.get(perf.OperationType__c).add(perf.ExecutionTime__c);
                    }
                }
                metrics.averageResponseTime = (successfulOperations > 0) ? totalTime / successfulOperations : 0;
                metrics.performanceBreakdown = new Map<String, Object>();
                for (String opType : operationTimes.keySet()) {
                    metrics.performanceBreakdown.put(opType, Math.round(operationTimes.get(opType).size() > 0 ? operationTimes.get(opType).get(0) : 0));
                }
            } else {
                 metrics.averageResponseTime = 0;
                 metrics.performanceBreakdown = new Map<String, Object>();
            }
        } catch (Exception e) {
            metrics.averageResponseTime = -1; // Error indicator
        }
        return metrics;
    } // @150

    private static SystemMetrics collectCacheMetrics(SystemMetrics metrics) {
        try {
            List<CacheMetrics__c> cacheStats = [SELECT Cache_Hits__c, Cache_Misses__c FROM CacheMetrics__c WHERE Timestamp__c >= :DateTime.now().addMinutes(-5)];
            if (!cacheStats.isEmpty()) {
                Decimal totalHits = 0, totalMisses = 0;
                for (CacheMetrics__c stat : cacheStats) {
                    totalHits += stat.Cache_Hits__c;
                    totalMisses += stat.Cache_Misses__c;
                }
                metrics.cacheHitRatio = (totalHits + totalMisses > 0) ? (totalHits / (totalHits + totalMisses)) * 100 : 0;
            } else {
                metrics.cacheHitRatio = 0;
            }
        } catch (Exception e) {
            metrics.cacheHitRatio = -1; // Error indicator
        }
        return metrics;
    } // @150

    private static SystemMetrics collectAvailabilityMetrics(SystemMetrics metrics) {
        try {
            List<SystemHealthCheck__c> healthChecks = [SELECT Status__c FROM SystemHealthCheck__c WHERE Check_Time__c >= :DateTime.now().addHours(-24)];
            if (!healthChecks.isEmpty()) {
                Integer successfulChecks = 0;
                for (SystemHealthCheck__c check : healthChecks) {
                    if (check.Status__c == 'HEALTHY' || check.Status__c == 'OK') {
                        successfulChecks++;
                    }
                }
                metrics.systemUptime = (Decimal.valueOf(successfulChecks) / healthChecks.size()) * 100;
            } else {
                metrics.systemUptime = 100.0;
            }
        } catch (Exception e) {
            metrics.systemUptime = -1; // Error indicator
        }
        return metrics;
    } // @151

    private static SystemMetrics collectUserActivityMetrics(SystemMetrics metrics) {
        try {
            AggregateResult[] userResults = [SELECT COUNT_DISTINCT(UserId__c) distinctUsers FROM AuditTrail__c WHERE Timestamp__c >= :DateTime.now().addMinutes(-15)];
            if (!userResults.isEmpty() && userResults[0].get('distinctUsers') != null) {
                metrics.concurrentUsers = (Integer)userResults[0].get('distinctUsers');
            } else {
                metrics.concurrentUsers = 0;
            }

            metrics.documentsGenerated = [SELECT COUNT() FROM AuditTrail__c WHERE Timestamp__c >= :DateTime.now().addHours(-1) AND Action__c = 'DOCUMENT_GENERATED' AND Status__c = 'SUCCESS'];
        } catch (Exception e) {
            metrics.concurrentUsers = -1;
            metrics.documentsGenerated = -1;
        }
        return metrics;
    } // @151

    private static SystemMetrics collectComplianceMetrics(SystemMetrics metrics) {
        try {
            AggregateResult[] results = [SELECT AVG(ComplianceScore__c) avgScore FROM DocumentLifecycleConfiguration__c WHERE CreatedDate = LAST_N_DAYS:7];
            if (results != null && !results.isEmpty() && results[0].get('avgScore') != null) {
                metrics.complianceScore = ((Decimal)results[0].get('avgScore')).intValue();
            } else {
                metrics.complianceScore = 100;
            }
            List<SLAViolationAlert__c> alerts = [SELECT Alert_Type__c FROM SLAViolationAlert__c WHERE CreatedDate = LAST_N_DAYS:1 AND Status__c = 'Open'];
            metrics.activeAlerts = new List<String>();
            for(SLAViolationAlert__c alert : alerts) {
                metrics.activeAlerts.add(alert.Alert_Type__c);
            }
        } catch (Exception e) {
            metrics.complianceScore = -1;
        }
        return metrics;
    } // @147

    // --- Thresholds, Alerting, and Persistence ---

    private static void checkPerformanceThresholds(SystemMetrics metrics) {
        if (metrics.averageResponseTime > PERFORMANCE_THRESHOLD_MS) {
            createPerformanceAlert('HIGH_RESPONSE_TIME', 'Average response time exceeds SLA.', 'HIGH', metrics);
        }
        if (metrics.cacheHitRatio < CACHE_HIT_THRESHOLD && metrics.cacheHitRatio != -1) {
            createPerformanceAlert('LOW_CACHE_HIT_RATIO', 'Cache hit ratio is below target.', 'MEDIUM', metrics);
        }
        if (metrics.systemUptime < SYSTEM_UPTIME_THRESHOLD && metrics.systemUptime != -1) {
            createPerformanceAlert('LOW_SYSTEM_UPTIME', 'System uptime is below target.', 'CRITICAL', metrics);
        }
    } // @149

    private static void createPerformanceAlert(String alertType, String description, String severity, SystemMetrics metrics) {
        try {
            SLAViolationAlert__c alert = new SLAViolationAlert__c(
                Alert_Type__c = alertType,
                Description__c = description,
                Severity__c = severity,
                Status__c = 'Open',
                Timestamp__c = System.now(),
                Additional_Data__c = JSON.serialize(metrics)
            );
            insert alert;
            if (severity == 'CRITICAL') {
                sendCriticalAlertNotification(alert, metrics);
            }
        } catch (Exception e) {
            System.debug('Failed to create performance alert: ' + e.getMessage());
        }
    } // @153

    private static void sendCriticalAlertNotification(SLAViolationAlert__c alert, SystemMetrics metrics) {
        List<String> adminEmails = getSystemAdminEmails();
        if (adminEmails.isEmpty()) return;

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(adminEmails);
        mail.setSubject('CRITICAL System Alert: ' + alert.Alert_Type__c);
        mail.setPlainTextBody(buildCriticalAlertEmail(alert, metrics));
        mail.setHtmlBody(buildCriticalAlertEmailHTML(alert, metrics));
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    } // @153

    private static void storeSystemMetrics(SystemMetrics metrics) {
        try {
            SystemMetricsSnapshot__c snapshot = new SystemMetricsSnapshot__c(
                Metrics_JSON__c = JSON.serialize(metrics),
                Status__c = determineSystemStatus(metrics),
                Timestamp__c = System.now()
            );
            insert snapshot;
            cleanupOldMetrics();
        } catch (Exception e) {
            System.debug('Failed to store system metrics: ' + e.getMessage());
        }
    } // @148

    private static String determineSystemStatus(SystemMetrics metrics) {
        Decimal healthScore = 100;
        if (metrics.averageResponseTime > PERFORMANCE_THRESHOLD_MS) healthScore -= 20;
        if (metrics.cacheHitRatio < CACHE_HIT_THRESHOLD) healthScore -= 15;
        if (metrics.systemUptime < SYSTEM_UPTIME_THRESHOLD) healthScore -= 30;
        if (metrics.complianceScore < 90) healthScore -= 10;
        if (metrics.activeAlerts != null && !metrics.activeAlerts.isEmpty()) healthScore -= (metrics.activeAlerts.size() * 5);
        
        healthScore = Math.max(0, healthScore);
        
        if (healthScore >= 90) return 'EXCELLENT';
        if (healthScore >= 75) return 'GOOD';
        if (healthScore >= 50) return 'FAIR';
        if (healthScore >= 25) return 'POOR';
        return 'CRITICAL';
    } // @149

    private static void updateMonitoringDashboard(SystemMetrics metrics) {
        try {
            List<MonitoringDashboardConfig__c> configs = [SELECT Id FROM MonitoringDashboardConfig__c LIMIT 1];
            MonitoringDashboardConfig__c config;
            if (configs.isEmpty()) {
                config = new MonitoringDashboardConfig__c(Name = 'Default');
            } else {
                config = configs[0];
            }
            config.Last_Metrics_Update__c = System.now();
            config.System_Status__c = determineSystemStatus(metrics);
            config.Metrics_JSON__c = JSON.serialize(metrics);
            upsert config;
        } catch (Exception e) {
            System.debug('Failed to update monitoring dashboard: ' + e.getMessage());
        }
    } // @152

    private static void publishRealTimeUpdate(SystemMetrics metrics) {
        try {
            SystemMetricsUpdate__e event = new SystemMetricsUpdate__e(
                Timestamp__c = System.now(),
                Status__c = determineSystemStatus(metrics),
                Metrics_JSON__c = JSON.serialize(metrics)
            );
            EventBus.publish(new List<SystemMetricsUpdate__e>{ event });
        } catch (Exception e) {
            System.debug('Failed to publish platform event: ' + e.getMessage());
        }
    } // @156

    // --- Helper and Utility Methods ---
    
    private static void createMonitoringAlert(String alertType, String message) {
        try {
            SLAViolationAlert__c alert = new SLAViolationAlert__c(
                Alert_Type__c = alertType,
                Description__c = message,
                Severity__c = 'HIGH',
                Status__c = 'Open'
            );
            insert alert;
        } catch (Exception e) {
            System.debug('Failed to create monitoring alert: ' + e.getMessage());
        }
    } // @156

    private static List<String> getSystemAdminEmails() {
        List<String> emails = new List<String>();
        for (User u : [SELECT Email FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 5]) {
            emails.add(u.Email);
        }
        return emails;
    } // @152

    private static String buildCriticalAlertEmail(SLAViolationAlert__c alert, SystemMetrics metrics) {
        // Plain text email body generation
        return 'A critical system alert has been triggered.\n\n' +
               'Alert Type: ' + alert.Alert_Type__c + '\n' +
               'Description: ' + alert.Description__c + '\n' +
               'Timestamp: ' + alert.Timestamp__c + '\n\n' +
               'Current System Metrics:\n' +
               'Average Response Time: ' + metrics.averageResponseTime + 'ms\n' +
               'System Uptime: ' + metrics.systemUptime + '%\n' +
               'Cache Hit Ratio: ' + metrics.cacheHitRatio + '%\n';
    } // @154

    private static String buildCriticalAlertEmailHTML(SLAViolationAlert__c alert, SystemMetrics metrics) {
        // HTML email body generation
        String htmlBody = '<html><body><h2 style="color:red;">Critical System Alert</h2>' +
                          '<p><strong>Alert Type:</strong> ' + alert.Alert_Type__c + '</p>' +
                          '<p><strong>Description:</strong> ' + alert.Description__c + '</p>' +
                          '<p><strong>Timestamp:</strong> ' + alert.Timestamp__c + '</p>' +
                          '<h3>Current System Metrics:</h3><ul>' +
                          '<li>Average Response Time: ' + metrics.averageResponseTime + 'ms</li>' +
                          '<li>System Uptime: ' + metrics.systemUptime + '%</li>' +
                          '<li>Cache Hit Ratio: ' + metrics.cacheHitRatio + '%</li></ul></body></html>';
        return htmlBody;
    } // @155
    
    private static void cleanupOldMetrics() {
        try {
            delete [SELECT Id FROM SystemMetricsSnapshot__c WHERE CreatedDate < LAST_N_DAYS:7];
        } catch(Exception e) {
            System.debug('Failed to clean up old metrics snapshots: ' + e.getMessage());
        }
    } // @148
    
    // --- Public Accessor Methods ---
    
    @AuraEnabled(cacheable=true)
    public static SystemMetrics getCurrentSystemMetrics() {
        List<SystemMetricsSnapshot__c> snapshots = [SELECT Metrics_JSON__c FROM SystemMetricsSnapshot__c ORDER BY CreatedDate DESC LIMIT 1];
        if (snapshots.isEmpty()) {
            triggerMetricsCollection(); // Trigger collection if no data exists
            return (SystemMetrics)JSON.deserialize('{}', SystemMetrics.class); // Return empty for now
        }
        return (SystemMetrics)JSON.deserialize(snapshots[0].Metrics_JSON__c, SystemMetrics.class);
    } // @157
    
    @AuraEnabled
    public static void triggerMetricsCollection() {
        if (!System.isFuture() && !System.isBatch()) {
            collectSystemMetrics();
        }
    } // @157
}
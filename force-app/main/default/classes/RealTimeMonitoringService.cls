public class RealTimeMonitoringService {
    // Run alert processing asynchronously (allows callouts)
    @future(callout = true)
    public static void processRealTimeAlerts(Set<String> recordIds, String alertType) {
        try {
            switch on alertType {
                when 'HIGH_FRAUD_RISK' {
                    processHighFraudRiskAlerts(recordIds);
                }
                when 'SYSTEM_PERFORMANCE' {
                    processSystemPerformanceAlerts(recordIds);
                }
                when 'COMPLIANCE_VIOLATION' {
                    processComplianceViolationAlerts(recordIds);
                }
                when 'ANOMALY_DETECTION' {
                    processAnomalyDetectionAlerts(recordIds);
                }
            }
        } catch (Exception e) {
            System.debug('Real-time monitoring error: ' + e.getMessage());
            logMonitoringError(alertType, e.getMessage());
        }
    }

    // ---------------------------
    // Handlers per alert category
    // ---------------------------

    private static void processHighFraudRiskAlerts(Set<String> signatureRequestIds) {
        List<Signature_Request__c> highRiskRequests = [
            SELECT Id, SignerEmail__c, Fraud_Score__c, Status__c
            FROM Signature_Request__c
            WHERE Id IN :signatureRequestIds
            AND Fraud_Score__c > 70
        ];

        for (Signature_Request__c request : highRiskRequests) {
            Alert_Notification__c alert = new Alert_Notification__c();
            alert.Alert_Type__c        = 'HIGH_FRAUD_RISK';
            alert.Priority__c          = 'HIGH';
            alert.Related_Record_Id__c = request.Id;
            alert.Message__c           = 'High fraud risk detected for signature request: ' + request.Id;
            alert.Created_At__c        = System.now();
            alert.Status__c            = 'ACTIVE';

            sendSecurityAlert(alert);
        }
    }

    private static void processSystemPerformanceAlerts(Set<String> metricIds) {
        List<Performance_Metric__c> criticalMetrics = [
            SELECT Id, CPU_Utilization__c, Memory_Utilization__c, Response_Time_Ms__c
            FROM Performance_Metric__c
            WHERE Id IN :metricIds
            AND (CPU_Utilization__c > 90 OR Memory_Utilization__c > 85 OR Response_Time_Ms__c > 5000)
        ];

        for (Performance_Metric__c metric : criticalMetrics) {
            Alert_Notification__c alert = new Alert_Notification__c();
            alert.Alert_Type__c        = 'SYSTEM_PERFORMANCE';
            alert.Priority__c          = 'CRITICAL';
            alert.Related_Record_Id__c = metric.Id;
            alert.Message__c           = 'System performance degradation detected';
            alert.Created_At__c        = System.now();
            alert.Status__c            = 'ACTIVE';

            sendSystemAlert(alert);
        }
    }

    private static void processComplianceViolationAlerts(Set<String> documentIds) {
        List<DocumentLifecycleConfiguration__c> nonCompliantDocs = [
            SELECT Id, DocumentTitle__c, Overall_Compliance_Score__c, Region__c
            FROM DocumentLifecycleConfiguration__c
            WHERE Id IN :documentIds
            AND Overall_Compliance_Score__c < 70
        ];

        for (DocumentLifecycleConfiguration__c doc : nonCompliantDocs) {
            Alert_Notification__c alert = new Alert_Notification__c();
            alert.Alert_Type__c        = 'COMPLIANCE_VIOLATION';
            alert.Priority__c          = 'HIGH';
            alert.Related_Record_Id__c = doc.Id;
            alert.Message__c           = 'Compliance violation detected in document: ' + doc.DocumentTitle__c;
            alert.Created_At__c        = System.now();
            alert.Status__c            = 'ACTIVE';

            sendComplianceAlert(alert);
        }
    }

    private static void processAnomalyDetectionAlerts(Set<String> anomalyIds) {
        List<Anomaly_Detection__c> criticalAnomalies = [
            SELECT Id, Anomaly_Type__c, Anomaly_Score__c, Related_Record_Id__c
            FROM Anomaly_Detection__c
            WHERE Id IN :anomalyIds
            AND Anomaly_Score__c > 80
        ];

        for (Anomaly_Detection__c anomaly : criticalAnomalies) {
            Alert_Notification__c alert = new Alert_Notification__c();
            alert.Alert_Type__c        = 'ANOMALY_DETECTION';
            alert.Priority__c          = 'MEDIUM';
            alert.Related_Record_Id__c = anomaly.Id;
            alert.Message__c           = 'Anomaly detected: ' + anomaly.Anomaly_Type__c;
            alert.Created_At__c        = System.now();
            alert.Status__c            = 'ACTIVE';

            sendAnomalyAlert(alert);
        }
    }

    // ---------------------------
    // Senders
    // ---------------------------

    private static void sendSecurityAlert(Alert_Notification__c alert) {
        System.debug('Security alert sent: ' + alert.Message__c);
        insert alert;
        sendAlertNotification(alert, 'security_team@company.com');
    }

    private static void sendSystemAlert(Alert_Notification__c alert) {
        System.debug('System alert sent: ' + alert.Message__c);
        insert alert;
        sendAlertNotification(alert, 'sysadmin@company.com');
    }

    private static void sendComplianceAlert(Alert_Notification__c alert) {
        System.debug('Compliance alert sent: ' + alert.Message__c);
        insert alert;
        sendAlertNotification(alert, 'compliance@company.com');
    }

    private static void sendAnomalyAlert(Alert_Notification__c alert) {
        System.debug('Anomaly alert sent: ' + alert.Message__c);
        insert alert;
        sendAlertNotification(alert, 'analytics@company.com');
    }

    private static void sendAlertNotification(Alert_Notification__c alert, String recipientEmail) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { recipientEmail });
            email.setSubject('[ALERT] ' + alert.Alert_Type__c + ' - ' + alert.Priority__c + ' Priority');

            String emailBody = buildAlertEmailBody(alert);
            email.setPlainTextBody(emailBody);
            email.setHtmlBody(buildAlertEmailHTML(alert));

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage> { email });

            alert.Notification_Sent__c     = true;
            alert.Notification_Sent_At__c  = System.now();
            update alert;
        } catch (Exception e) {
            System.debug('Alert notification sending failed: ' + e.getMessage());
        }
    }

    // ---------------------------
    // Email Builders
    // ---------------------------

    private static String buildAlertEmailBody(Alert_Notification__c alert) {
        StringBuilder body = new StringBuilder();
        body.append('SYSTEM ALERT NOTIFICATION\n');
        body.append('========================\n\n');
        body.append('Alert Type: ').append(alert.Alert_Type__c).append('\n');
        body.append('Priority: ').append(alert.Priority__c).append('\n');
        body.append('Timestamp: ').append(alert.Created_At__c.format()).append('\n');
        body.append('Related Record: ').append(alert.Related_Record_Id__c).append('\n\n');
        body.append('Message: ').append(alert.Message__c).append('\n\n');
        body.append('Please review and take appropriate action.\n');
        body.append('System: Salesforce E-Signature Platform\n');
        return body.toString();
    }

    private static String buildAlertEmailHTML(Alert_Notification__c alert) {
        String priorityColor =
            alert.Priority__c == 'CRITICAL' ? '#dc3545' :
            alert.Priority__c == 'HIGH'     ? '#fd7e14' : '#28a745';

        return '<html><body style="font-family: Arial, sans-serif;">' +
               '<div style="background-color: ' + priorityColor + '; color: white; padding: 15px; margin-bottom: 20px;">' +
               '<h2 style="margin: 0;">🚨 SYSTEM ALERT - ' + alert.Priority__c + ' PRIORITY</h2>' +
               '</div>' +
               '<table style="width: 100%; border-collapse: collapse;">' +
               '<tr><td style="padding: 10px; border: 1px solid #ddd; font-weight: bold;">Alert Type:</td>' +
               '<td style="padding: 10px; border: 1px solid #ddd;">' + alert.Alert_Type__c + '</td></tr>' +
               '<tr><td style="padding: 10px; border: 1px solid #ddd; font-weight: bold;">Priority:</td>' +
               '<td style="padding: 10px; border: 1px solid #ddd; color: ' + priorityColor + '; font-weight: bold;">' + alert.Priority__c + '</td></tr>' +
               '<tr><td style="padding: 10px; border: 1px solid #ddd; font-weight: bold;">Timestamp:</td>' +
               '<td style="padding: 10px; border: 1px solid #ddd;">' + alert.Created_At__c.format() + '</td></tr>' +
               '<tr><td style="padding: 10px; border: 1px solid #ddd; font-weight: bold;">Related Record:</td>' +
               '<td style="padding: 10px; border: 1px solid #ddd;">' + alert.Related_Record_Id__c + '</td></tr>' +
               '</table>' +
               '<div style="margin: 20px 0; padding: 15px; background-color: #f8f9fa; border-left: 4px solid ' + priorityColor + ';">' +
               '<h3>Alert Details:</h3>' +
               '<p>' + alert.Message__c + '</p>' +
               '</div>' +
               '<p><strong>Action Required:</strong> Please review and take appropriate action immediately.</p>' +
               '</body></html>';
    }

    // ---------------------------
    // Error logging
    // ---------------------------

    private static void logMonitoringError(String alertType, String errorMessage) {
        insert new Monitoring_Error_Log__c(
            Alert_Type__c       = alertType,
            Error_Message__c    = errorMessage,
            Error_Timestamp__c  = System.now(),
            Status__c           = 'UNRESOLVED'
        );
    }

    // ---------------------------
    // Configuration
    // ---------------------------

    /**
     * Advanced Analytics Custom Setting Manager
     */
    public static Map<String, Object> getAnalyticsConfiguration() {
        Map<String, Object> config = new Map<String, Object>();

        // ML Model Configuration
        config.put('mlModelVersion', 'v3.2.1');
        config.put('fraudDetectionThreshold', 75.0);
        config.put('anomalyDetectionSensitivity', 0.85);
        config.put('predictionAccuracyTarget', 0.92);

        // Performance Thresholds
        config.put('maxResponseTimeMs', 5000);
        config.put('minComplianceScore', 80.0);
        config.put('maxFraudScore', 70.0);
        config.put('systemHealthThreshold', 85.0);

        // Batch Processing Configuration
        config.put('documentIntelligenceBatchSize', 50);
        config.put('fraudDetectionBatchSize', 25);
        config.put('performanceAnalyticsBatchSize', 100);
        config.put('userBehaviorBatchSize', 75);

        // Alert Configuration
        config.put('enableRealTimeAlerts', true);
        config.put('alertRetentionDays', 90);
        config.put('criticalAlertEscalationMinutes', 15);
        config.put('securityTeamEmail', 'security@company.com');

        return config;
    }
 
    @future(callout=true)
    public static void collectSystemMetricsAsync() {
        // gather metrics and persist snapshot (SystemMetricsSnapshot__c)
        SystemMetricsSnapshot__c snap = new SystemMetricsSnapshot__c(
            Timestamp__c = System.now(),
            CPU_Usage__c = getCurrentCPUUsage(), // helper implemented separately
            Memory_Usage__c = getCurrentMemoryUsage()
        );
        insert snap;
    }

    @AuraEnabled(cacheable=true)
    public static SystemMetricsSnapshot__c getLatestSystemSnapshot() {
        List<SystemMetricsSnapshot__c> snaps = [
            SELECT Id, Timestamp__c, CPU_Usage__c, Memory_Usage__c, ResponseTimeMs__c
            FROM SystemMetricsSnapshot__c ORDER BY Timestamp__c DESC LIMIT 1
        ];
        if(snaps.isEmpty()){
            // schedule collection async and return null/default snapshot; UI can retry/poll
            collectSystemMetricsAsync();
            return null;
        }
        return snaps[0];
    }


}

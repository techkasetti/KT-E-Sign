public class PerformanceMonitoringScheduler implements Schedulable {
    public void execute(SchedulableContext context) {
        try {
            // Generate daily performance report
            generateDailyPerformanceReport();
            
            // Check system health thresholds
            checkSystemHealthThresholds();
            
            // Archive old audit records
            archiveOldAuditRecords();
            
        } catch (Exception e) {
            System.debug('Performance monitoring scheduler error: ' + e.getMessage());
            
            // Send error notification
            try {
                EmailNotificationService.sendSystemAlert(
                    'Performance Monitoring Error',
                'The daily performance monitoring job failed: ' + e.getMessage()
                    );
            } catch (Exception emailEx) {
                System.debug('Failed to send performance monitoring error notification: ' + emailEx.getMessage());
            }
        }
    }
    
    private void generateDailyPerformanceReport() {
        // Get yesterday's metrics
        Date yesterday = System.today().addDays(-1);
        
        Map<String, Object> dailyMetrics = new Map<String, Object>();
        
        // Document generation metrics
        List<DocumentLifecycleConfiguration__c> dailyDocs = [
            SELECT Id, CreatedDate, ProcessingStatus__c
            FROM DocumentLifecycleConfiguration__c
            WHERE CreatedDate >= :yesterday
            AND CreatedDate < :System.today()
        ];
        
        dailyMetrics.put('documentsGenerated', dailyDocs.size());
        
        // Signature request metrics
        List<Signature_Request__c> dailyRequests = [
            SELECT Id, Status__c, Time_To_Complete_Hours__c
            FROM Signature_Request__c
            WHERE CreatedDate >= :yesterday
            AND CreatedDate < :System.today()
        ];
        
        Integer completedRequests = 0;
        Decimal totalCompletionTime = 0;
        
        for (Signature_Request__c request : dailyRequests) {
            if (request.Status__c == 'Completed') {
                completedRequests++;
                if (request.Time_To_Complete_Hours__c != null) {
                    totalCompletionTime += request.Time_To_Complete_Hours__c;
                }
            }
        }
        
        dailyMetrics.put('signatureRequests', dailyRequests.size());
        dailyMetrics.put('completedRequests', completedRequests);
        dailyMetrics.put('averageCompletionTime',
        completedRequests > 0 ? totalCompletionTime / completedRequests : 0);
        
        // Security assessment metrics
        List<Security_Assessment__c> dailyAssessments = [
            SELECT Id, Risk_Level__c
            FROM Security_Assessment__c
            WHERE Assessment_Timestamp__c >= :yesterday
            AND Assessment_Timestamp__c < :System.today()
        ];
        
        dailyMetrics.put('securityAssessments', dailyAssessments.size());
        
        // Store daily report
        Daily_Performance_Report__c report = new Daily_Performance_Report__c(
            Report_Date__c = yesterday,
        Documents_Generated__c = dailyDocs.size(),
        Signature_Requests__c = dailyRequests.size(),
        Completed_Requests__c = completedRequests,
        Average_Completion_Time__c = completedRequests > 0 ? totalCompletionTime / completedRequests : 0,
        Security_Assessments__c = dailyAssessments.size(),
        Metrics_JSON__c = JSON.serialize(dailyMetrics)
            );
        
        try {
            insert report;
            System.debug('Daily performance report generated for: ' + yesterday);
        } catch (Exception e) {
            System.debug('Failed to store daily performance report: ' + e.getMessage());
        }
    }
    
    private void checkSystemHealthThresholds() {
    Map<String, Object> healthStatus = ProductionDeploymentManager.getSystemHealthStatus();

    Decimal healthScore = (Decimal)healthStatus.get('overallHealthScore');
    String healthLevel = (String)healthStatus.get('healthLevel');

    // Check if health score is below threshold
    if (healthScore < 60) {
        EmailNotificationService.sendSystemAlert(
            'System Health Alert - ' + healthLevel,
            'System health score has dropped to ' + healthScore + '%. Please review system performance and address any issues.'
        );
    }

    // Check for high-risk security assessments
    Map<String, Object> securityMetrics = (Map<String, Object>)healthStatus.get('securityAssessments');
    Integer criticalRisk = (Integer)securityMetrics.get('critical');
    Integer highRisk = (Integer)securityMetrics.get('high');

    if (criticalRisk > 0 || highRisk > 5) {
        EmailNotificationService.sendSecurityAlert(
            'High-Risk Security Activity Detected',
            'Critical risk assessments have identified ' + criticalRisk +
            ' critical risk(s) and ' + highRisk + ' high risk(s) in the system. ' +
            'Immediate attention required for security review and threat mitigation.'
        );

        // Create security incident record for tracking
        Security_Incident__c securityIncident = new Security_Incident__c(
            Incident_Type__c = 'HIGH_RISK_ACTIVITY',
            Severity__c = criticalRisk > 0 ? 'CRITICAL' : 'HIGH',
            Description__c = 'Automated security threshold breach detected',
            Critical_Risk_Count__c = criticalRisk,
            High_Risk_Count__c = highRisk,
            Detection_Timestamp__c = System.now(),
            Status__c = 'OPEN',
            Requires_Immediate_Action__c = true
        );

        try {
            insert securityIncident;

            // Log the security event in audit trail
            AuditTrailManager.logSecurityEvent(
                'SECURITY_THRESHOLD_BREACH',
                'High-risk security activity detected - Incident ID: ' + securityIncident.Id,
                'CRITICAL'
            );

            // If critical risk exists, trigger emergency response
            if (criticalRisk > 0) {
                triggerEmergencySecurityResponse(securityIncident.Id, criticalRisk);
            }

            // Update system health metrics
            updateSecurityHealthMetrics(criticalRisk, highRisk);

        } catch (Exception e) {
            System.debug('Failed to create security incident record: ' + e.getMessage());
            // Fallback - still send the alert even if record creation fails
            AuditTrailManager.logSystemActivity(
                'SECURITY_ALERT_FALLBACK',
                'Security alert sent but incident record creation failed: ' + e.getMessage()
            );
        }

        // Continue with regular system health monitoring
        monitorOngoingSecurityMetrics();
    }
}

        /**
         * Triggers emergency security response for critical threats
         */
        private void triggerEmergencySecurityResponse(Id incidentId, Integer criticalRiskCount) {
            try {
                // Create emergency response case
                Case emergencyCase = new Case(
                    Subject = 'EMERGENCY: Critical Security Threat Detected',
                Description = 'Critical security risk threshold breached with ' + criticalRiskCount + ' critical risk(s). ' +
                    'Immediate security team intervention required. Incident ID: ' + incidentId,
                Priority = 'High',
                Status = 'New',
                Origin = 'Security Monitoring System',
                Type = 'Security Incident',
                Security_Incident__c = incidentId
                    );
                
                insert emergencyCase;
                
                // Send emergency notification to security team
                EmailNotificationService.sendEmergencySecurityNotification(
                    'CRITICAL SECURITY ALERT - Immediate Action Required',
                'A critical security threshold has been breached. Case created: ' + emergencyCase.CaseNumber +
                    '. Please review and respond immediately.'
                    );
                
                // If configured, automatically disable high-risk users
                if (criticalRiskCount >= 3) {
                    initiateAutomaticUserLockdown(incidentId);
                }
                
            } catch (Exception e) {
                System.debug('Emergency security response failed: ' + e.getMessage());
                AuditTrailManager.logSystemActivity(
                    'EMERGENCY_RESPONSE_FAILED',
                'Emergency security response failed for incident ' + incidentId + ': ' + e.getMessage()
                    );
            }
        }
    

        /**
         * Updates security health metrics based on risk assessments
         */
        private void updateSecurityHealthMetrics(Integer criticalRisk, Integer highRisk) {
            try {
                Security_Health_Metrics__c metrics = new Security_Health_Metrics__c(
                    Metric_Date__c = System.today(),
                Critical_Risk_Count__c = criticalRisk,
                High_Risk_Count__c = highRisk,
                Alert_Triggered__c = true,
                Alert_Timestamp__c = System.now(),
                Overall_Risk_Score__c = calculateOverallRiskScore(criticalRisk, highRisk),
                Requires_Review__c = true
                    );
                
                // Upsert based on today's date to avoid duplicates
                Database.upsert(metrics, Security_Health_Metrics__c.Metric_Date__c);
                
            } catch (Exception e) {
                System.debug('Failed to update security health metrics: ' + e.getMessage());
            }
        }
    
        
        /**
         * Calculates overall risk score based on risk counts
         */
        private Decimal calculateOverallRiskScore(Integer criticalRisk, Integer highRisk) {
            // Critical risks weighted at 10 points each, high risks at 3 points each
            Decimal riskScore = (criticalRisk * 10) + (highRisk * 3);
            
            // Cap at 100 for scoring purposes
            return Math.min(riskScore, 100);
        }
    

        /**
         * Initiates automatic user lockdown for severe security threats
         */
        private void initiateAutomaticUserLockdown(Id incidentId) {
            try {
                // Query recent high-risk users from security assessments
             // Calculate 24 hours ago
DateTime twentyFourHoursAgo = System.now().addHours(-24);

List<Security_Assessment__c> highRiskAssessments = [
    SELECT Id, User_Id__c, Risk_Level__c, Assessment_Timestamp__c
    FROM Security_Assessment__c 
    WHERE Risk_Level__c IN ('CRITICAL', 'HIGH')
    AND Assessment_Timestamp__c >= :twentyFourHoursAgo
    ORDER BY Assessment_Timestamp__c DESC
];

                Set<Id> usersToLock = new Set<Id>();
                for (Security_Assessment__c assessment : highRiskAssessments) {
                    if (assessment.Risk_Level__c == 'CRITICAL') {
                        usersToLock.add(assessment.User_Id__c);
                    }
                }
                
                if (!usersToLock.isEmpty()) {
                    // Create user lockdown records
                    List<User_Security_Lockdown__c> lockdownRecords = new List<User_Security_Lockdown__c>();
                    for (Id userId : usersToLock) {
                        lockdownRecords.add(new User_Security_Lockdown__c(
                            User_Id__c = userId,
                        Lockdown_Reason__c = 'Automatic lockdown due to critical security threat',
                        Security_Incident__c = incidentId,
                        Lockdown_Timestamp__c = System.now(),
                        Status__c = 'ACTIVE',
                        Requires_Manual_Review__c = true
                            ));
                    }
                    
                    insert lockdownRecords;
                    
                    // Send notification about automatic lockdowns
                    EmailNotificationService.sendSecurityAlert(
                        'Automatic User Lockdown Initiated',
                    lockdownRecords.size() + ' users have been automatically locked down due to critical security threats. ' +
                        'Manual review required before re-enabling access.'
                        );
                    
                    AuditTrailManager.logSecurityEvent(
                        'AUTOMATIC_USER_LOCKDOWN',
                    'Locked down ' + lockdownRecords.size() + ' users due to critical security incident: ' + incidentId,
                    'CRITICAL'
                        );
                }
                
            } catch (Exception e) {
                System.debug('Automatic user lockdown failed: ' + e.getMessage());
                AuditTrailManager.logSystemActivity(
                    'LOCKDOWN_FAILED',
                'Automatic user lockdown failed for incident ' + incidentId + ': ' + e.getMessage()
                    );
            }
        }
    
        
        /**
         * Continues monitoring ongoing security metrics
         */
        private void monitorOngoingSecurityMetrics() {
            try {
                // Archive old security incidents
                archiveOldSecurityIncidents();
                
                // Update security dashboard metrics
                updateSecurityDashboard();
                
                // Check for trending security patterns
                analyzeSecurityTrends();
                
            } catch (Exception e) {
                System.debug('Ongoing security monitoring error: ' + e.getMessage());
            }
        }
    }


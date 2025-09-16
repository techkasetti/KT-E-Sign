public class SecurityMonitoringController {
    
    @AuraEnabled(cacheable=false)
    public static SecurityDashboardData getSecurityDashboard() {
        try {
            SecurityDashboardData dashboard = new SecurityDashboardData();
            
            // Get security metrics for last 24 hours
            Date yesterday = Date.today().addDays(-1);
            
            // Fraud detection metrics
            dashboard.fraudMetrics = getFraudMetrics(yesterday);
            
            // Authentication security metrics
            dashboard.authMetrics = getAuthenticationMetrics(yesterday);
            
            // System security health
            dashboard.systemHealth = getSystemSecurityHealth();
            
            // Active security incidents
            dashboard.activeIncidents = getActiveSecurityIncidents();
            
            // Security recommendations
            dashboard.recommendations = getSecurityRecommendations();
            
            return dashboard;
            
        } catch (Exception e) {
            AuditTrailManager.logSystemActivity('SECURITY_DASHBOARD_ERROR',
            'Security dashboard error: ' + e.getMessage());
            throw new AuraHandledException('Failed to load security dashboard: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static SecurityIncidentResponse handleSecurityIncident(String incidentId, String action, String notes) {
        try {
            SecurityIncident__c incident = [
            SELECT Id, Incident_Type__c, Severity__c, Status__c, User_Id__c
            FROM SecurityIncident__c 
            WHERE Id = :incidentId 
            LIMIT 1
        ];
            
            // Update status based on action
            switch on action {
                when 'ACKNOWLEDGE' {
                    incident.Status__c = 'ACKNOWLEDGED';
                    incident.Acknowledged_By__c = UserInfo.getUserId();
                    incident.Acknowledged_Date__c = System.now();
                }
                when 'INVESTIGATE' {
                    incident.Status__c = 'INVESTIGATING';
                    incident.Assigned_Investigator__c = UserInfo.getUserId();
                    incident.Investigation_Start__c = System.now();
                }
                when 'RESOLVE' {
                    incident.Status__c = 'RESOLVED';
                    incident.Resolution_Date__c = System.now();
                    incident.Resolved_By__c = UserInfo.getUserId();
                }
                when 'ESCALATE' {
                    incident.Status__c = 'ESCALATED';
                    incident.Escalation_Date__c = System.now();
                    incident.Escalated_By__c = UserInfo.getUserId();
                    sendEscalationAlert(incident);
                }
            }
            
            // Append investigation notes
            if (String.isNotBlank(notes)) {
                incident.Investigation_Notes__c =
                    (incident.Investigation_Notes__c != null ? incident.Investigation_Notes__c + '\n\n' : '') +
                    'Investigation Update - ' + notes;
            }
            
            // Update incident
            update incident;
            
            // Create follow-up tasks for critical incidents
            String riskLevel = incident.Severity__c;
            if (riskLevel == 'CRITICAL') {
                createSecurityEscalationTask(incident.Id);
            }
            
            // Log the activity
            AuditTrailManager.createAuditEntry(
                incident.Id,
            'SECURITY_INVESTIGATION_UPDATED',
            'SUCCESS',
            'Investigation notes updated with findings'
                );
            
            return new SecurityIncidentResponse(true, 'Incident updated successfully');
            
        } catch (Exception e) {
            System.debug('Error updating security incident: ' + e.getMessage());
            return new SecurityIncidentResponse(false, 'Failed to handle incident: ' + e.getMessage());
        }
    }
    
    
}
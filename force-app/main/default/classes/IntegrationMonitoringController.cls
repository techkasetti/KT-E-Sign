public with sharing class IntegrationMonitoringController {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getIntegrationMetrics(String timeframe) {
        Map<String, Object> metrics = new Map<String, Object>();
        
        DateTime startDate = calculateStartDate(timeframe);
        
        try {
            // Document Generation Metrics
            metrics.put('documentsGenerated', getDocumentCount(startDate));
            metrics.put('signatureRequests', getSignatureRequestCount(startDate));
            metrics.put('completedWorkflows', getCompletedWorkflowCount(startDate));
            metrics.put('failedWorkflows', getFailedWorkflowCount(startDate));
            
            // Performance Metrics
            metrics.put('averageProcessingTime', getAverageProcessingTime(startDate));
            metrics.put('successRate', calculateSuccessRate(startDate));
            
            // Compliance Metrics
            metrics.put('complianceRate', getComplianceRate(startDate));
            
            return metrics;
        } catch (Exception e) {
            return new Map<String, Object>{
                'error' => 'Failed to retrieve metrics: ' + e.getMessage()
            };
        }
    }
    
    @AuraEnabled
    public static Map<String, Object> getRealtimeStatus() {
        Map<String, Object> status = new Map<String, Object>();
        
        try {
            // Current active workflows
            Integer activeWorkflows = [SELECT COUNT() FROM Workflow_Instance__c WHERE Status__c = 'In_Progress'];
            
            // Pending signatures
            Integer pendingSignatures = [SELECT COUNT() FROM Signature_Request__c WHERE Status__c = 'Pending'];
            
            // System health
            Map<String, Object> healthCheck = IntegrationDeploymentController.executeIntegrationHealthCheck();
            
            status.put('activeWorkflows', activeWorkflows);
            status.put('pendingSignatures', pendingSignatures);
            status.put('systemHealth', healthCheck.get('status'));
            status.put('lastUpdated', System.now());
            
            return status;
        } catch (Exception e) {
            return new Map<String, Object>{
                'error' => 'Failed to get realtime status: ' + e.getMessage()
            };
        }
    }
    
    // Private helper methods
    private static DateTime calculateStartDate(String timeframe) {
        switch on timeframe {
            when 'today' {
                return System.now().addDays(-1);
            }
            when 'week' {
                return System.now().addDays(-7);
            }
            when 'month' {
                return System.now().addDays(-30);
            }
            when else {
                return System.now().addDays(-7); // Default to week
            }
        }
    }
    
    private static Integer getDocumentCount(DateTime startDate) {
        return [SELECT COUNT() FROM DocumentLifecycleConfiguration__c 
                   WHERE CreatedDate >= :startDate];
    }
    
    private static Integer getSignatureRequestCount(DateTime startDate) {
        return [SELECT COUNT() FROM Signature_Request__c 
                   WHERE CreatedDate >= :startDate];
    }
    
    private static Integer getCompletedWorkflowCount(DateTime startDate) {
        return [SELECT COUNT() FROM Workflow_Instance__c 
                   WHERE Status__c = 'Completed' AND CreatedDate >= :startDate];
    }
    
    private static Integer getFailedWorkflowCount(DateTime startDate) {
        return [SELECT COUNT() FROM Workflow_Instance__c 
                   WHERE Status__c = 'Failed' AND CreatedDate >= :startDate];
    }
    
    private static Decimal getAverageProcessingTime(DateTime startDate) {
        List<AggregateResult> results = [
                SELECT AVG(Processing_Time_Minutes__c) avgTime 
                FROM Workflow_Instance__c 
                WHERE Status__c = 'Completed' AND CreatedDate >= :startDate
            ];
        
        return results.isEmpty() ? 0 : (Decimal)results[0].get('avgTime');
    }
    
    private static Decimal calculateSuccessRate(DateTime startDate) {
        Integer total = [SELECT COUNT() FROM Workflow_Instance__c WHERE CreatedDate >= :startDate];
        Integer successful = [SELECT COUNT() FROM Workflow_Instance__c 
                                WHERE Status__c = 'Completed' AND CreatedDate >= :startDate];
        
        return total > 0 ? (Decimal)successful / total * 100 : 0;
    }
    
    private static Decimal getComplianceRate(DateTime startDate) {
        Integer total = [SELECT COUNT() FROM DocumentLifecycleConfiguration__c 
                           WHERE CreatedDate >= :startDate];
        Integer compliant = [SELECT COUNT() FROM DocumentLifecycleConfiguration__c 
                               WHERE ComplianceStatus__c = 'Compliant' AND CreatedDate >= :startDate];
        
        return total > 0 ? (Decimal)compliant / total * 100 : 0;
    }
}
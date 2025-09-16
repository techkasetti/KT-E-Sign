public with sharing class IntegratedWorkflowController {
    
    @AuraEnabled
    public static Map<String, Object> executeCompleteWorkflow(
        Map<String, Object> documentParams,
        Map<String, Object> signatureParams
    ) {
        try {
            // Step 1: Initialize Workflow
            Workflow_Instance__c workflow = createWorkflowInstance(documentParams, signatureParams);
            
            // Step 2: Execute Document Generation Phase
            Map<String, Object> docResult = executeDocumentPhase(workflow.Id, documentParams);
            if (!(Boolean)docResult.get('success')) {
                updateWorkflowStatus(workflow.Id, 'Failed', (String)docResult.get('error'));
                return docResult;
            }
            
            // Step 3: Execute Signature Phase
            Map<String, Object> sigResult = executeSignaturePhase(
                workflow.Id, 
                (String)docResult.get('documentId'),
                signatureParams
            );
            
            // Step 4: Complete Workflow
            if ((Boolean)sigResult.get('success')) {
                updateWorkflowStatus(workflow.Id, 'Completed', null);
            } else {
                updateWorkflowStatus(workflow.Id, 'Failed', (String)sigResult.get('error'));
            }
            
            return sigResult;
            
        } catch (Exception e) {
            return createErrorResponse('Workflow execution failed: ' + e.getMessage());
        }
    }
    
    // Private methods for workflow management
    private static Workflow_Instance__c createWorkflowInstance(
        Map<String, Object> docParams, 
        Map<String, Object> sigParams
    ) {
        Workflow_Instance__c workflow = new Workflow_Instance__c(
            Document_Type__c = (String)docParams.get('contractType'),
            Signer_Email__c = (String)sigParams.get('signerEmail'),
            Status__c = 'In_Progress',
            Started_Date__c = System.now()
        );
        insert workflow;
        return workflow;
    }
    
    private static Map<String, Object> executeDocumentPhase(
        String workflowId, 
        Map<String, Object> docParams
    ) {
        return DocGenESignIntegrationController.generateAndInitiateSignature(
            (String)docParams.get('region'),
            (String)docParams.get('role'),
            (String)docParams.get('contractType'),
            (String)docParams.get('documentTitle'),
            (String)docParams.get('signerEmail')
        );
    }
    
    private static Map<String, Object> executeSignaturePhase(
        String workflowId,
        String documentId,
        Map<String, Object> sigParams
    ) {
        // Additional signature processing logic
        return new Map<String, Object>{
            'success' => true,
            'workflowId' => workflowId,
            'documentId' => documentId
        };
    }
    
    private static void updateWorkflowStatus(String workflowId, String status, String errorMessage) {
        Workflow_Instance__c workflow = new Workflow_Instance__c(
            Id = workflowId,
            Status__c = status,
            Error_Message__c = errorMessage,
            Completed_Date__c = (status == 'Completed' ? System.now() : null)
        );
        update workflow;
    }
}

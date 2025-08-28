public class ClauseGenerator {
    
    @AuraEnabled
    public static String generateClause(String region, String role, String contractType) {
        try {
            String clause = buildDynamicClause(region, role, contractType);
            logClauseGeneration(region, role, contractType, clause);
            return clause;
        } catch (Exception e) {
            System.debug('Error generating clause: ' + e.getMessage());
            throw new AuraHandledException('Failed to generate clause: ' + e.getMessage());
        }
    }
    
    private static String buildDynamicClause(String region, String role, String contractType) {
        String clause = 'This agreement is governed by the laws of ';
        
        // Region-specific terms
        if (region == 'US') {
            clause += 'the United States of America and applicable federal employment laws. ';
        } else if (region == 'EU') {
            clause += 'the European Union, with full compliance to GDPR regulations. ';
        } else if (region == 'IN') {
            clause += 'India, in accordance with Indian labor regulations and IT Act 2000. ';
        } else {
            clause += 'applicable international law. ';
        }
        
        // Role-specific terms
        if (role == 'Manager') {
            clause += 'As an authorized signatory, you acknowledge management responsibilities and oversight duties. ';
        } else if (role == 'Employee') {
            clause += 'As an employee, you agree to abide by company policies and professional obligations. ';
        } else if (role == 'Admin') {
            clause += 'As an administrator, you have elevated privileges and corresponding accountability. ';
        }
        
        // Contract type specifics
        if (contractType == 'Employment') {
            clause += 'This employment agreement includes compensation terms, benefits, and termination conditions. ';
        } else if (contractType == 'NDA') {
            clause += 'This non-disclosure agreement protects confidential information and trade secrets. ';
        } else if (contractType == 'SLA') {
            clause += 'This service level agreement defines performance standards and metrics. ';
        }
        
clause += &#39;\n\nSignature Required: Yes\nGenerated on: &#39; + DateTime.now().format(&#39;yyyy-MM-dd H
         /// above line is incomplete, need to get it formatted again with AI help       

Continuing from where we left off in the ClauseGenerator class:
        clause += &#39;\n\nSignature Required: Yes\nGenerated on: &#39; + System.now();
        
        return clause;
    }
    
    private static void logClauseGeneration(String region, String role, String contractType, String clause) {
        try {
            AuditTrail__c audit = new AuditTrail__c(
                RecordId__c = &#39;CLAUSE_GEN_&#39; + System.now().getTime(),
                Action__c = &#39;CLAUSE_GENERATED&#39;,
                Status__c = &#39;SUCCESS&#39;,
                Details__c = &#39;Generated clause for &#39; + region + &#39; &#39; + role + &#39; &#39; + contractType,
                UserId__c = UserInfo.getUserId()
            );
            insert audit;
        } catch (Exception e) {
            System.debug(&#39;⚠ Could not log clause generation: &#39; + e.getMessage());
        }
    }
    
    // Custom exception for clause generation errors
    public class ClauseGenerationException extends Exception {}
}





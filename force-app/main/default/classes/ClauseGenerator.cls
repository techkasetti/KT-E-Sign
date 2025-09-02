public class ClauseGenerator {
    
    @AuraEnabled
    public static String generateClause(String region, String role, String contractType) {
    
            String clause = buildDynamicClause(region, role, contractType);
        return clause;
    }




    
    // try {
    //         String baseClause = buildDynamicClause(region, role, contractType);
            
    //         // Log clause generation
    //         AuditTrailManager.logSystemActivity('CLAUSE_GENERATED', 
    //             'Generated clause for: ' + region + '/' + role + '/' + contractType);
            
    //         return baseClause;
            
    //     } catch (Exception e) {
    //         AuditTrailManager.logSystemActivity('CLAUSE_GENERATION_ERROR', e.getMessage());
    //         throw new AuraHandledException('Error generating clause: ' + e.getMessage());
    //     }
    // }

    
    
    
    
    
    
        //     try {
    //         System.debug('Generating clause for: ' + region + ', ' + role + ', ' + contractType);
            
    //         StringBuilder clause = new StringBuilder();
            
    //         // Add region-specific terms
    //         clause.append(getRegionSpecificTerms(region));
    //         clause.append('\n\n');
            
    //         // Add role-specific terms
    //         clause.append(getRoleSpecificTerms(role));
    //         clause.append('\n\n');
            
    //         // Add contract type specific terms
    //         clause.append(getContractTypeTerms(contractType));
    //         clause.append('\n\n');
            
    //         // Add signature requirement
    //         clause.append('SIGNATURE REQUIREMENT:\n');
    //         clause.append('This document requires electronic signature for validity. ');
    //         clause.append('By signing this document electronically, you acknowledge that your electronic signature ');
    //         clause.append('is the legal equivalent of your manual signature on this document.\n');
    //         clause.append('Signature Required: Yes');
            
    //         String finalClause = clause.toString();
            
    //         // Log clause generation
    //         AuditTrailManager.logSystemActivity('Clause Generated', 'Clause generated for ' + contractType);
            
    //         return finalClause;
            
    //     } catch (Exception e) {
    //         throw new ClauseGenerationException('Failed to generate clause: ' + e.getMessage());
    //     }
    // }
    
    private static String getRegionSpecificTerms(String region) {
        switch on region {
            when 'US' {
                return 'UNITED STATES TERMS:\n' +
                    'This agreement is governed by the laws of the United States. ' +
                    'Any disputes shall be resolved in accordance with federal and applicable state laws. ' +
                    'This document complies with the Electronic Signatures in Global and National Commerce Act (E-SIGN).';
            }
            when 'EU' {
                return 'EUROPEAN UNION TERMS:\n' +
                    'This agreement complies with the General Data Protection Regulation (GDPR). ' +
                    'Personal data processing is conducted in accordance with EU privacy laws. ' +
                    'This document complies with the eIDAS Regulation for electronic signatures.';
            }
            when 'APAC' {
                return 'ASIA-PACIFIC TERMS:\n' +
                    'This agreement is subject to regional data protection and privacy laws. ' +
                    'Electronic signatures are recognized under applicable digital transaction laws.';
            }
            when else {
                return 'GLOBAL TERMS:\n' +
                    'This agreement follows international best practices for electronic documentation and signatures.';
            }
        }
    }
    
    private static String getRoleSpecificTerms(String role) {
        switch on role {
            when 'Manager' {
                return 'MANAGEMENT RESPONSIBILITIES:\n' +
                    'As a manager, you acknowledge additional responsibilities for team oversight, ' +
                    'compliance monitoring, and adherence to organizational policies.';
            }
            when 'Director', 'VP', 'C-Level' {
                return 'EXECUTIVE RESPONSIBILITIES:\n' +
                    'As an executive, you acknowledge fiduciary responsibilities, strategic oversight, ' +
                    'and compliance with corporate governance requirements.';
            }
            when 'Employee' {
                return 'EMPLOYEE RESPONSIBILITIES:\n' +
                    'As an employee, you acknowledge your responsibilities to adhere to company policies, ' +
                    'maintain confidentiality of proprietary information, and comply with all applicable ' +
                    'employment terms and conditions as outlined in your employment agreement.';
            }
            when else {
                return 'GENERAL RESPONSIBILITIES:\n' +
                    'All parties acknowledge their responsibility to comply with the terms and conditions ' +
                    'outlined in this agreement and applicable legal requirements.';
            }
        }
    }
    
    private static String getContractTypeTerms(String contractType) {
        switch on contractType {
            when 'Employment' {
                return 'EMPLOYMENT AGREEMENT TERMS:\n' +
                    'This employment agreement establishes the terms of employment including but not limited to: ' +
                    'compensation, benefits, work responsibilities, performance expectations, and termination conditions. ' +
                    'Both parties agree to maintain confidentiality and adhere to non-disclosure obligations.';
            }
            when 'NDA' {
                return 'NON-DISCLOSURE AGREEMENT TERMS:\n' +
                    'This Non-Disclosure Agreement (NDA) establishes confidentiality obligations regarding proprietary information. ' +
                    'The receiving party agrees not to disclose, use, or reproduce confidential information for unauthorized purposes. ' +
                    'This obligation survives termination of the underlying business relationship.';
            }
            when 'Service Agreement' {
                return 'SERVICE AGREEMENT TERMS:\n' +
                    'This service agreement defines the scope of services, deliverables, timelines, and compensation. ' +
                    'Both parties agree to perform their obligations in good faith and in accordance with industry standards. ' +
                    'Service levels and quality standards are as mutually agreed upon.';
            }
            when 'Partnership' {
                return 'PARTNERSHIP AGREEMENT TERMS:\n' +
                    'This partnership agreement establishes the terms of collaboration, shared responsibilities, ' +
                    'profit/loss distribution, and decision-making processes. Both parties commit to acting in ' +
                    'the partnership\'s best interests and maintaining transparency in all dealings.';
            }
            when else {
                return 'GENERAL AGREEMENT TERMS:\n' +
                    'This agreement establishes mutual obligations and responsibilities between the parties. ' +
                    'All terms are binding upon execution and shall remain in effect as specified herein.';
            }
        }
    }
    
    private static String buildDynamicClause(String region, String role, String contractType) {
    
            String clause = 'This document establishes the following terms:\n\n';
        
        // Add region-specific terms
        clause += getRegionSpecificTerms(region) + '\n\n';
        
        // Add role-specific terms  
        clause += getRoleSpecificTerms(role) + '\n\n';
        
        // Add contract type terms
        clause += getContractTypeTerms(contractType) + '\n\n';
        
        // Add signature requirement
        clause += 'ELECTRONIC SIGNATURE REQUIREMENT: By signing this document electronically, ' +
                 'you agree that your electronic signature is the legal equivalent of your manual signature.';
        
        return clause;
    }

    
    
    
    
        //     String clause = 'This agreement is governed by the laws of ';
        
    //     if (region == 'US') {
    //         clause += 'the United States of America and applicable federal employment laws. ';
    //     } else if (region == 'EU') {
    //         clause += 'the European Union, with full compliance to GDPR regulations. ';
    //     } else if (region == 'IN') {
    //         clause += 'India, in accordance with Indian labor regulations and IT Act 2000. ';
    //     } else {
    //         clause += 'applicable international law. ';
    //     }
        
    //     if (role == 'Manager') {
    //         clause += 'As an authorized signatory, you acknowledge management responsibilities and oversight duties. ';
    //     } else if (role == 'Employee') {
    //         clause += 'As an employee, you agree to abide by company policies and professional obligations. ';
    //     } else if (role == 'Admin') {
    //         clause += 'As an administrator, you have elevated privileges and corresponding accountability. ';
    //     }
        
    //     if (contractType == 'Employment') {
    //         clause += 'This employment agreement includes compensation terms, benefits, and termination conditions. ';
    //     } else if (contractType == 'NDA') {
    //         clause += 'This non-disclosure agreement protects confidential information and trade secrets. ';
    //     } else if (contractType == 'SLA') {
    //         clause += 'This service level agreement defines performance standards and metrics. ';
    //     }
        
    //     clause += '\n\nSignature Required: Yes\nGenerated on: ' + System.now().format('yyyy-MM-dd HH:mm:ss');
    //     return clause;
    // }
    
    private static void logClauseGeneration(String region, String role, String contractType, String clause) {
        try {
            AuditTrail__c audit = new AuditTrail__c(
                RecordId__c = 'CLAUSE_GEN_' + System.now().getTime(),
                Action__c = 'CLAUSE_GENERATED',
                Status__c = 'SUCCESS',
                Details__c = 'Generated clause for ' + region + ' ' + role + ' ' + contractType,
                UserId__c = UserInfo.getUserId()
            );
            insert audit;
        } catch (Exception e) {
            System.debug('⚠ Could not log clause generation: ' + e.getMessage());
        }
    }
    
    public class ClauseGenerationException extends Exception {}
}

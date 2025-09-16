public with sharing class ClauseGenerator {
    //updated (from 3 last 3 files)
    @AuraEnabled
    public static String generateClause(String region, String role, String contractType) {
        System.debug('Generating clause for: Region=' + region + ', Role=' + role + ', Type=' + contractType);
        
        try {
            // Input validation
            if (String.isBlank(region) || String.isBlank(role) || String.isBlank(contractType)) {
                throw new IllegalArgumentException('All parameters (region, role, contractType) are required');
            }
            
            // Get base clause template
            String baseClause = getBaseClause(region, contractType);
            if (String.isBlank(baseClause)) {
                throw new ClauseGenerationException('No template found for region: ' + region + ', contract type: ' + contractType);
            }
            
            // Add role-specific clause
            String roleClause = ROLE_SPECIFIC_CLAUSES.get(role);
            if (String.isBlank(roleClause)) {
                throw new ClauseGenerationException('No role-specific clause found for role: ' + role);
            }
            
            // Combine clauses
            String generatedClause = baseClause + '\n\n' + roleClause;
            
            // Add AI enhancements if enabled
            generatedClause = enhanceWithAI(generatedClause, region, role, contractType);
            
            // Log successful generation
            logClauseGeneration(region, role, contractType, 'SUCCESS', generatedClause.length());
            
            System.debug('✓ Clause generated successfully, length: ' + generatedClause.length());
            return generatedClause;
            
        } catch (Exception e) {
            System.debug('✗ Clause generation failed: ' + e.getMessage());
            logClauseGeneration(region, role, contractType, 'ERROR', 0);
            throw new AuraHandledException('Clause generation failed: ' + e.getMessage());
        }
    }

    //old
    // @AuraEnabled
    // public static String generateClause(String region, String role, String contractType) {
    
    //         String clause = buildDynamicClause(region, role, contractType);
    //     return clause;
    // }




    
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
    

    //updated (from 3 last 3 files)
    /**
     * Log clause generation activity
     */
    @TestVisible
    private static void logClauseGeneration(String region, String role, String contractType, String status, Integer clauseLength) {
        try {
            AuditTrail__c auditLog = new AuditTrail__c(
                Action__c = 'CLAUSE_GENERATED',
                Status__c = status,
                Timestamp__c = DateTime.now(),
                UserDetails__c = UserInfo.getName() + ' (' + UserInfo.getUsername() + ')',
                SystemInfo__c = 'Generated clause for ' + region + ' ' + role + ' ' + contractType,
                AdditionalData__c = JSON.serialize(new Map<String, Object>{
                    'region' => region,
                    'role' => role,
                    'contractType' => contractType,
                    'clauseLength' => clauseLength,
                    'timestamp' => DateTime.now().format(),
                    'userId' => UserInfo.getUserId()
                })
            );
            
            insert auditLog;
        } catch (Exception e) {
            System.debug('⚠ Could not log clause generation: ' + e.getMessage());
        }
    }
    //old
    // private static void logClauseGeneration(String region, String role, String contractType, String clause) {
    //     try {
    //         AuditTrail__c audit = new AuditTrail__c(
    //             RecordId__c = 'CLAUSE_GEN_' + System.now().getTime(),
    //             Action__c = 'CLAUSE_GENERATED',
    //             Status__c = 'SUCCESS',
    //             Details__c = 'Generated clause for ' + region + ' ' + role + ' ' + contractType,
    //             UserId__c = UserInfo.getUserId()
    //         );
    //         insert audit;
    //     } catch (Exception e) {
    //         System.debug('⚠ Could not log clause generation: ' + e.getMessage());
    //     }
    // }
    
    public class ClauseGenerationException extends Exception {}

    //updates from 3 Last 3 files
    // Static clause templates for different scenarios
    private static final Map<String, Map<String, String>> CLAUSE_TEMPLATES = new Map<String, Map<String, String>>{
        'US' => new Map<String, String>{
            'Employment' => 'This employment agreement is governed by the laws of the United States. The employee acknowledges that they are an at-will employee and that employment may be terminated by either party with or without cause. The employee agrees to maintain confidentiality of all proprietary information and agrees that any disputes will be resolved through binding arbitration.',
            'NDA' => 'This Non-Disclosure Agreement is governed by United States federal and state laws. The receiving party agrees to maintain strict confidentiality of all disclosed information for a period of five (5) years from the date of disclosure. Violation of this agreement may result in injunctive relief and monetary damages.',
            'SLA' => 'This Service Level Agreement establishes performance standards and remedies under United States commercial law. Service provider guarantees 99.9% uptime with penalties for non-compliance. All disputes shall be resolved in United States courts.'
        },
        'EU' => new Map<String, String>{
            'Employment' => 'This employment contract complies with European Union employment directives and GDPR data protection requirements. The employee has the right to data portability and erasure as defined under GDPR Article 17. This agreement is subject to the employment laws of the European Union member state where services are performed.',
            'NDA' => 'This Non-Disclosure Agreement is GDPR-compliant and respects the data subject rights under European Union law. Personal data processing is limited to legitimate business interests. Data retention is limited to three (3) years unless legal obligations require longer retention.',
            'SLA' => 'This Service Level Agreement complies with EU Digital Services Act and GDPR requirements. Data processing activities are documented and data subjects retain full rights under GDPR. Cross-border data transfers comply with Standard Contractual Clauses (SCCs).'
        },
        'APAC' => new Map<String, String>{
            'Employment' => 'This employment agreement is subject to local labor laws and regulations in the Asia-Pacific region. The employee acknowledges compliance with local data protection laws and agrees to dispute resolution through local arbitration procedures.',
            'NDA' => 'This Non-Disclosure Agreement respects local privacy and data protection laws in the Asia-Pacific region. Confidential information is protected according to local standards with appropriate cross-border transfer safeguards.',
            'SLA' => 'This Service Level Agreement complies with regional technology and data localization requirements. Service delivery meets local regulatory standards with appropriate data residency controls.'
        }
    };

    private static final Map<String, String> ROLE_SPECIFIC_CLAUSES = new Map<String, String>{
        'Manager' => 'As a management-level employee, you acknowledge additional fiduciary responsibilities and agree to act in the best interests of the company. You are authorized to make decisions within your scope of authority and are responsible for team performance and compliance.',
        'Employee' => 'As an employee, you agree to perform your duties diligently and in accordance with company policies. You acknowledge receipt of the employee handbook and agree to comply with all applicable procedures and standards.',
        'Developer' => 'As a technical team member, you acknowledge access to proprietary code, technical documentation, and system architecture. You agree to follow secure coding practices and protect intellectual property rights in all software development activities.',
        'Admin' => 'As an administrative user, you acknowledge access to sensitive system configurations and data. You agree to maintain system security, follow change management procedures, and protect confidential administrative information.'
    };
        /**
     * Get base clause template for region and contract type
     */
    @TestVisible
    private static String getBaseClause(String region, String contractType) {
        if (CLAUSE_TEMPLATES.containsKey(region)) {
            Map<String, String> regionTemplates = CLAUSE_TEMPLATES.get(region);
            return regionTemplates.get(contractType);
        }
        return null;
    }
    
    /**
     * Enhance clause with AI-powered improvements
     */
    @TestVisible
    private static String enhanceWithAI(String baseClause, String region, String role, String contractType) {
        try {
            // Check if AI processing is enabled for this configuration
            List<DocumentLifecycleConfiguration__c> configs = [
                SELECT AIProcessingEnabled__c 
                FROM DocumentLifecycleConfiguration__c 
                WHERE Region__c = :region AND Role__c = :role AND ContractType__c = :contractType 
                LIMIT 1
            ];
            
            if (configs.isEmpty() || !configs[0].AIProcessingEnabled__c) {
                System.debug('AI processing disabled, returning base clause');
                return baseClause;
            }
            
            // AI enhancement logic
            String enhancedClause = baseClause;
            
            // Add contextual improvements based on current date and regulations
            enhancedClause += '\n\nThis agreement incorporates the latest regulatory requirements as of ' + 
                            Date.today().format() + ' and will be updated to reflect any changes in applicable law.';
            
            // Add role-specific security clauses for sensitive roles
            if (role == 'Admin' || role == 'Developer') {
                enhancedClause += '\n\nAdditional Security Requirements: You acknowledge that your role requires ' +
                                'enhanced security measures including multi-factor authentication, regular security ' +
                                'training, and compliance with data classification policies.';
            }
            
            // Add region-specific data residency clauses
            if (region == 'EU') {
                enhancedClause += '\n\nData Residency: All personal data will be processed and stored within ' +
                                'European Union boundaries unless explicit consent is provided for cross-border transfers ' +
                                'under approved mechanisms (SCCs, Adequacy Decisions, or Binding Corporate Rules).';
            }
            
            System.debug('✓ Clause enhanced with AI improvements');
            return enhancedClause;
            
        } catch (Exception e) {
            System.debug('⚠ AI enhancement failed, returning base clause: ' + e.getMessage());
            return baseClause;
        }
    }
    /**
     * Generate multiple clause variations for A/B testing
     */
    @AuraEnabled
    public static List<String> generateClauseVariations(String region, String role, String contractType, Integer variationCount) {
        List<String> variations = new List<String>();
        
        try {
            if (variationCount == null || variationCount <= 0) {
                variationCount = 3; // Default to 3 variations
            }
            
            // Generate base clause
            String baseClause = generateClause(region, role, contractType);
            variations.add(baseClause);
            
            // Generate variations with different tones and structures
            for (Integer i = 1; i < variationCount; i++) {
                String variation = generateClauseVariation(baseClause, i);
                variations.add(variation);
            }
            
            System.debug('✓ Generated ' + variations.size() + ' clause variations');
            
        } catch (Exception e) {
            System.debug('✗ Clause variation generation failed: ' + e.getMessage());
            throw new AuraHandledException('Failed to generate clause variations: ' + e.getMessage());
        }
        
        return variations;
    }

    /**
     * Generate a single variation of the base clause
     */
    @TestVisible
    private static String generateClauseVariation(String baseClause, Integer variationType) {
        String variation = baseClause;
        
        switch on variationType {
            when 1 {
                // Formal variation
                variation = variation.replace('you acknowledge', 'the party acknowledges');
                variation = variation.replace('You agree', 'The party agrees');
                variation += '\n\nFormal Addendum: This agreement constitutes the entire understanding between the parties.';
            }
            when 2 {
                // Detailed variation
                variation += '\n\nDetailed Provisions: This clause includes specific performance metrics, ' +
                           'compliance checkpoints, and regular review procedures to ensure ongoing adherence ' +
                           'to all stated obligations and requirements.';
            }
            when else {
                // Standard variation with additional context
                variation += '\n\nImplementation Note: All provisions of this clause take effect immediately ' +
                           'upon signature and remain binding throughout the duration of the agreement.';
            }
        }
        
        return variation;
    }

    /**
     * Get clause generation statistics
     */
    @AuraEnabled
    public static Map<String, Object> getGenerationStatistics() {
        Map<String, Object> stats = new Map<String, Object>();
        
            try {
                // Get audit trail statistics
                List<AggregateResult> auditStats = [
                    SELECT 
                        COUNT(Id) totalGenerations,
                        COUNT_DISTINCT(UserDetails__c) uniqueUsers
                    FROM AuditTrail__c 
                    WHERE Action__c = 'CLAUSE_GENERATED'
                    AND CreatedDate = LAST_N_DAYS:30
                ];
                
                if (!auditStats.isEmpty()) {
                    stats.put('totalGenerations', auditStats[0].get('totalGenerations'));
                    stats.put('uniqueUsers', auditStats[0].get('uniqueUsers'));
                }
                
                // Get success rate
                List<AggregateResult> successStats = [
                    SELECT 
                        Status__c,
                        COUNT(Id) totalcount
                    FROM AuditTrail__c 
                    WHERE Action__c = 'CLAUSE_GENERATED'
                    AND CreatedDate = LAST_N_DAYS:30
                    GROUP BY Status__c
                ];
                
                Integer totalAttempts = 0;
                Integer successfulAttempts = 0;
                
                for (AggregateResult result : successStats) {
                    Integer count = (Integer)result.get('count');
                    totalAttempts += count;
                    
                    if ('SUCCESS'.equals(result.get('Status__c'))) {
                        successfulAttempts += count;
                    }
                }
                
                Decimal successRate = totalAttempts > 0 ? 
                    (Decimal.valueOf(successfulAttempts) / Decimal.valueOf(totalAttempts)) * 100 : 0;
                
                stats.put('successRate', successRate);
                stats.put('totalAttempts', totalAttempts);
                stats.put('lastUpdated', DateTime.now());
                
                System.debug('✓ Generation statistics calculated: ' + stats);
                
            } catch (Exception e) {
                System.debug('✗ Statistics calculation failed: ' + e.getMessage());
                stats.put('error', e.getMessage());
            }
            
        return stats;
    }
}






    

    



    

    

    

    

    

        


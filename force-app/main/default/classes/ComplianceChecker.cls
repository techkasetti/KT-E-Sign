public with sharing class ComplianceChecker {
    
    private static Decimal calculateComplianceScore(List<String> violations) {
        Integer maxPossibleViolations = 10; // Maximum expected violations
        Integer actualViolations = violations.size();
        Decimal score = ((Decimal)(maxPossibleViolations - actualViolations) / maxPossibleViolations) * 100;
        return score < 0 ? 0 : score;
    }
    private static Integer calculateComplianceScore(String clause, String region, String contractType) {
        Integer score = 0;
        
        // Base score for minimum length
        if (clause.length() >= 100) score += 30;
        if (clause.length() >= 200) score += 10;
        
        // Score for signature requirement
        if (clause.contains('electronic signature')) score += 25;
        
        // Score for regional compliance
        //if (validateRegionalCompliance(clause,
        if (validateRegionalCompliance(clause, region)) score += 25;
        
        // Score for contract type compliance
        if (validateContractTypeCompliance(clause, contractType)) score += 20;
        
        return score;
    }
    private static List<String> generateComplianceRecommendations(List<String> violations) {
        List<String> recommendations = new List<String>();
        
        for (String violation : violations) {
            if (violation.contains('Regional compliance')) {
                recommendations.add('Add region-specific legal language and regulatory references');
            }
            if (violation.contains('Contract type')) {
                recommendations.add('Include contract-specific terms and conditions');
            }
            if (violation.contains('General compliance')) {
                recommendations.add('Ensure document meets minimum length and signature requirements');
            }
        }
        
        return recommendations;
    }
    
    private static List<String> generateComplianceRecommendations(List<String> violations, Decimal complianceScore) {
        List<String> recommendations = new List<String>();
        
        if (complianceScore >= 90) {
            recommendations.add('Document meets excellent compliance standards');
        } else if (complianceScore >= 75) {
            recommendations.add('Document meets acceptable compliance standards with minor improvements needed');
        } else if (complianceScore >= 50) {
            recommendations.add('Document requires significant compliance improvements before use');
        } else {
            recommendations.add('Document requires comprehensive compliance review and revision');
        }
        
        // Add specific recommendations based on violations
        for (String violation : violations) {
            if (violation.contains('electronic signature')) {
                recommendations.add('Add explicit electronic signature validity clause');
            }
            if (violation.contains('E-SIGN') || violation.contains('eIDAS')) {
                recommendations.add('Include region-specific regulatory compliance statements');
            }
            if (violation.contains('insufficient')) {
                recommendations.add('Expand document content to include comprehensive terms and conditions');
            }
        }
        
        return recommendations;
    }
    
    @AuraEnabled
    public static ComplianceValidationResult validateCompliance(String clause, String region, String contractType) {
        
        
        ComplianceValidationResult result = new ComplianceValidationResult();
        List<String> violations = new List<String>();
        List<String> recommendations = new List<String>();
        
        // Validate regional compliance
        if (!validateRegionalCompliance(clause, region)) {
            violations.add('Regional compliance requirements not met for: ' + region);
        }
        
        // Validate contract type compliance
        if (!validateContractTypeCompliance(clause, contractType)) {
            violations.add('Contract type requirements not met for: ' + contractType);
        }
        
        // Validate general compliance
        if (!validateGeneralCompliance(clause)) {
            violations.add('General compliance requirements not met');
        }
        
        // Calculate compliance score
        Integer score = calculateComplianceScore(clause, region, contractType);
        
        result.isCompliant = violations.isEmpty() && score >= 80;
        result.violations = violations;
        result.score = score;
        result.recommendations = generateComplianceRecommendations(violations);
        
        return result;
    }
                                    
                                    
                                    
                                    
                                    
                                    
                                    
                                    
                                    
                                    //             ComplianceValidationResult result = new ComplianceValidationResult();
                                    
                                    //         try {
                                        //             // Perform validation checks
                                        //             validateRegionalCompliance(clause, region, result.violations);
                                        //             validateContractTypeCompliance(clause, contractType, result.violations);
                                        //             validateGeneralCompliance(clause, result.violations);
                                        
                                        //             // Calculate compliance score
                                        //             result.complianceScore = calculateComplianceScore(result.violations);
                                        //             result.isCompliant = result.complianceScore >= 75.0;
                                        
                                        //             // Generate recommendations
                                        //             result.recommendations = generateComplianceRecommendations(result.violations, result.complianceScore);
                                        
                                        //             return result;
                                        
                                    //         } catch (Exception e) {
                                        //             result.isCompliant = false;
                                        // result.violations.add('Compliance validation failed: ' + e.getMessage());
                                        // result.complianceScore = 0;
                                        // result.recommendations.add('Please contact system administrator for compliance validation issues');
                                        // return result;
                                    // }
                                //     }
                                
                                
                                
                                
                                //     try {
                                    //         List<String> violations = new List<String>();
                                    //         Boolean isCompliant = true;
                                    
                                    //         // Regional compliance checks
                                    //         Boolean regionalCompliant = validateRegionalCompliance(clause, region, violations);
                                    
                                    //         // Contract type compliance checks
                                    //         Boolean typeCompliant = validateContractTypeCompliance(clause, contractType, violations);
                                    
                                    //         // General compliance checks
                                    //         Boolean generalCompliant = validateGeneralCompliance(clause, violations);
                                    
                                    //         isCompliant = regionalCompliant && typeCompliant && generalCompliant;
                                    
                                    //         // Calculate compliance score
                                    //         Integer totalChecks = 10; // Base number of compliance checks
                                    //         Integer passedChecks = totalChecks - violations.size();
                                    //         Decimal complianceScore = (Decimal.valueOf(passedChecks) / totalChecks) * 100;
                                    
                                    //         ComplianceValidationResult result = new ComplianceValidationResult();
                                    //         result.isCompliant = isCompliant;
                                    //         result.complianceScore = complianceScore;
                                    //         result.violations = violations;
                                    //         result.recommendation = generateComplianceRecommendation(violations, complianceScore);
                                    
                                    //         // Log compliance check
                                    //         AuditTrailManager.logComplianceCheck(result, region, contractType);
                                    
                                    //         return result;
                                    
                                //     } catch (Exception e) {
                                    //         throw new AuraHandledException('Compliance validation failed: ' + e.getMessage());
                                //     }
                            // }
    private static String generateComplianceRecommendation(List<String> violations, Decimal complianceScore) {
        if (violations.isEmpty()) {
            return 'Document is fully compliant and ready for use.';
        } else if (complianceScore >= 80) {
            return 'Document is mostly compliant with minor issues to address: ' + String.join(violations, '; ');
        } else if (complianceScore >= 60) {
            return 'Document requires moderate compliance improvements: ' + String.join(violations, '; ');
        } else {
            return 'Document requires significant compliance review before use: ' + String.join(violations, '; ');
        }
    }
    
    
    
    
    private String generateComplianceRecommendation(List<String> violations) {
        if (violations.isEmpty()) {
            return 'Document meets all compliance requirements';
        }
        
        String recommendation = 'To improve compliance: ';
        for (Integer i = 0; i < violations.size() && i < 3; i++) {
            recommendation += (i + 1) + '. ' + violations[i] + ' ';
        }
        
        return recommendation;
    }
                            
                            
    private static Boolean validateRegionalCompliance(String clause, String region, List<String> violations) {
        String lowerClause = clause.toLowerCase();
        switch on region {
            when 'US' {
                if (!lowerClause.contains('e-sign') && !lowerClause.contains('electronic signatures')) {
                    violations.add('US documents should reference Electronic Signatures in Global and National Commerce Act (E-SIGN) compliance');
                }
                if (!lowerClause.contains('federal') && !lowerClause.contains('state')) {
                    violations.add('US documents should reference federal and state law compliance');
                }
            }
            when 'EU' {
                if (!lowerClause.contains('eidas') && !lowerClause.contains('gdpr')) {
                    violations.add('EU documents should reference eIDAS regulation and GDPR compliance');
                }
                if (!lowerClause.contains('data protection') && !lowerClause.contains('privacy')) {
                    violations.add('EU documents must include data protection and privacy references');
                }
            }
            when 'APAC' {
                if (!lowerClause.contains('local law') && !lowerClause.contains('jurisdiction')) {
                    violations.add('APAC documents should specify local law compliance and jurisdiction');
                }
            }
            when 'Global' {
                if (!lowerClause.contains('international') && !lowerClause.contains('commercial law')) {
                    violations.add('Global documents should reference international commercial law');
                }
            }
        }
    }
                            
                            
                            
                            
                            
                            
                            
                            //     Boolean compliant = true;
                            //     String lowerClause = clause.toLowerCase();
                            
                            //     switch on region {
                                //         when 'US' {
                                    //             if (!lowerClause.contains('e-sign act') && !lowerClause.contains('electronic signatures')) {
                                        //                 violations.add('US contracts must reference E-SIGN Act compliance');
                                        //                 compliant = false;
                                    //             }
                                //         }
                                //         when 'EU' {
                                    //             if (!lowerClause.contains('gdpr') && !lowerClause.contains('data protection')) {
                                        //                 violations.add('EU contracts must include GDPR compliance language');
                                        //                 compliant = false;
                                    //             }
                                    //             if (!lowerClause.contains('eidas')) {
                                        //                 violations.add('EU contracts should reference eIDAS regulation for electronic signatures');
                                        //                 compliant = false;
                                    //             }
                                //         }
                                //         when 'APAC' {
                                    //             if (!lowerClause.contains('data protection') && !lowerClause.contains('privacy')) {
                                        //                 violations.add('APAC contracts should include data protection references');
                                        //                 compliant = false;
                                    //             }
                                //         }
                            //     }
                            
                            //     return compliant;
                        // }
    private static Boolean validateGeneralCompliance(String clause) {
        return clause.length() >= 100 && clause.contains('electronic signature');
    }
    
    private static Boolean validateGeneralCompliance(String clause, List<String> violations) {
        
        
        if (clause.length() < 200) {
            violations.add('Document content appears insufficient for a complete legal agreement');
        }
        
        // Check for electronic signature requirement
        if (!clause.toLowerCase().contains('electronic signature') && !clause.toLowerCase().contains('e-signature')) {
            violations.add('Document must explicitly state electronic signature requirements');
        }
        
        // Check for legal binding language
        if (!clause.toLowerCase().contains('legally binding') && !clause.toLowerCase().contains('enforceable')) {
            violations.add('Document should state that it is legally binding and enforceable');
        }
    }
                        
                        
                        
                        
                        //     Boolean compliant = true;
                        //     String lowerClause = clause.toLowerCase();
                        
                        //     // Electronic signature compliance
                        //     if (!lowerClause.contains('electronic signature') && !lowerClause.contains('e-signature')) {
                            //         violations.add('Document must reference electronic signature validity');
                            //         compliant = false;
                        //     }
                        
                        //     // Legal binding language
                        //     if (!lowerClause.contains('legally binding') && !lowerClause.contains('legal effect')) {
                            //         violations.add('Document should state that electronic signatures are legally binding');
                            //         compliant = false;
                        //     }
                        
                        //     // Minimum length check
                        //     if (clause.length() < 200) {
                            //         violations.add('Document content appears insufficient for a complete agreement');
                            //         compliant = false;
                        //     }
                        
                        //     return compliant;
                    // }
    //updated (from 3 last 3 files)
    @AuraEnabled
    public static Boolean validateClause(String clauseText, String region, String contractType) {
        System.debug('Validating compliance for: Region=' + region + ', Type=' + contractType);
        
        try {
            // Input validation
            if (String.isBlank(clauseText) || String.isBlank(region) || String.isBlank(contractType)) {
                throw new IllegalArgumentException('All parameters are required for compliance validation');
            }
            
            // Get compliance rules for region and contract type
            List<String> requiredTerms = getComplianceRules(region, contractType);
            if (requiredTerms == null || requiredTerms.isEmpty()) {
                System.debug('⚠ No compliance rules found for ' + region + ' ' + contractType);
                logComplianceCheck(region, contractType, 'WARNING', 'No rules found');
                return true; // Default to compliant if no rules
            }
            
            // Check for required terms
            List<String> missingTerms = new List<String>();
            String clauseLower = clauseText.toLowerCase();
            
            for (String term : requiredTerms) {
                if (!clauseLower.contains(term.toLowerCase())) {
                    missingTerms.add(term);
                }
            }
            
            Boolean isCompliant = missingTerms.isEmpty();
            String status = isCompliant ? 'SUCCESS' : 'VIOLATION';
            String details = isCompliant ? 'All required terms present' : 'Missing terms: ' + String.join(missingTerms, ', ');
            
            // Log compliance check
            logComplianceCheck(region, contractType, status, details);
            
            // Create compliance record for tracking
            createComplianceRecord(clauseText, region, contractType, isCompliant, missingTerms);
            
            System.debug(isCompliant ? '✓ Clause is compliant' : '✗ Clause has violations: ' + details);
            return isCompliant;
            
        } catch (Exception e) {
            System.debug('✗ Compliance validation failed: ' + e.getMessage());
            logComplianceCheck(region, contractType, 'ERROR', e.getMessage());
            throw new AuraHandledException('Compliance validation failed: ' + e.getMessage());
        }
    }
  //old                  
    // @AuraEnabled
    // public static Boolean validateClause(String clause, String region, String contractType) {
        
    //     ComplianceValidationResult result = validateCompliance(clause, region, contractType);
    //     return result.isCompliant;
    // }
                    
                    
                    
                    
                    
                    
                    
                    //     ComplianceResult result = new ComplianceResult();
                    //     List<String> violations = new List<String>();
                    //     Boolean compliant = true;
                    
                    //     try {
                        //         // Basic content validation
                        //         if (String.isBlank(clause) || clause.length() < 50) {
                            //             violations.add('Document content is insufficient');
                            //             compliant = false;
                        //         }
                        
                        //         // Region-specific compliance checks
                        //         compliant = validateRegionCompliance(clause, region, violations) && compliant;
                        
                        //         // Contract type-specific checks
                        //         compliant = validateContractTypeCompliance(clause, contractType, violations) && compliant;
                        
                        //         // Electronic signature compliance
                        //         if (!clause.toLowerCase().contains('electronic signature') &&
                        //             !clause.toLowerCase().contains('e-signature')) {
                            //             violations.add('Document must reference electronic signature requirements');
                            //             compliant = false;
                        //         }
                        
                        //         // Legal binding clause check
                        //         if (!clause.toLowerCase().contains('legally binding') &&
                        //             !clause.toLowerCase().contains('legal equivalent')) {
                            //             violations.add('Document must state that electronic signatures are legally binding');
                            //             compliant = false;
                        //         }
                        
                        //         result.isCompliant = compliant;
                        //         result.violations = violations;
                        //         result.complianceScore = calculateComplianceScore(violations.size());
                        //         result.recommendation = generateComplianceRecommendation(violations);
                        
                        //         // Log compliance check
                        //         AuditTrailManager.logSystemActivity('COMPLIANCE_CHECK',
                        //             'Compliance validation completed. Status: ' + (compliant ? 'COMPLIANT' : 'NON-COMPLIANT'));
                        
                    //     } catch (Exception e) {
                        //         result.isCompliant = false;
                        //         result.violations = new List<String>{'Compliance validation failed: ' + e.getMessage()};
                        //         result.complianceScore = 0;
                    //     }
                    
                    //     return result;
                // }
                
                
                
                
                
                
                
                
                //     try {
                    //         ComplianceValidationResult result = validateCompliance(clause, region, contractType);
                    //         return result.isCompliant;
                //     } catch (Exception e) {
                    //         System.debug('Compliance validation error: ' + e.getMessage());
                    //         return false;
                //     }
            // }
            
            
            
            
            //         try {
                //     System.debug('Starting compliance validation for: ' + region + ', ' + contractType);
                
                //     Boolean isCompliant = true;
                //     List<String> violations = new List<String>();
                
                //     // Basic validation checks
                //     if (String.isBlank(clause) || clause.length() < 100) {
                    //         violations.add('Clause too short - minimum 100 characters required');
                    //         isCompliant = false;
                //     }
                
                //     // Check for required signature clause
                //     if (!clause.containsIgnoreCase('signature required')) {
                    //         violations.add('Missing required signature clause');
                    //         isCompliant = false;
                //     }
                
                //     // Region-specific compliance checks
                //     isCompliant = validateRegionCompliance(clause, region, violations) && isCompliant;
                
                //     // Contract type specific checks
                //     isCompliant = validateContractTypeCompliance(clause, contractType, violations) && isCompliant;
                
                //     // Log compliance check result
                //     AuditTrailManager.logSystemActivity(
                //         'Compliance Check',
                //         'Validation result: ' + (isCompliant ? 'PASSED' : 'FAILED') +
                //         (violations.isEmpty() ? '' : '. Violations: ' + String.join(violations, '; '))
                //     );
                
                //     return isCompliant;
                
            // } catch (Exception e) {
                //     System.debug('❌ Compliance validation error: ' + e.getMessage());
                //     throw new ComplianceException('Compliance validation failed: ' + e.getMessage());
            // }
              
            
        // try {
            //     Boolean isCompliant = performComplianceValidation(clause, region, contractType);
            //     logComplianceCheck(clause, region, contractType, isCompliant);
            //     return isCompliant;
        // } catch (Exception e) {
            //     System.debug('Error validating compliance: ' + e.getMessage());
            //     throw new AuraHandledException('Failed to validate compliance: ' + e.getMessage());
        // }
    //}
    public ComplianceValidationResult() {
        this.violations = new List<String>();
        this.recommendations = new List<String>();
    }
    
    private static Boolean validateContractTypeCompliance(String clause, String contractType, List<String> violations) {
        
        String lowerClause = clause.toLowerCase();
        switch on contractType {
            when 'Employment' {
                if (!lowerClause.contains('employment') && !lowerClause.contains('employee')) {
                    violations.add('Employment contracts must clearly reference employment relationship');
                }
                if (!lowerClause.contains('compensation') && !lowerClause.contains('salary') && !lowerClause.contains('benefits')) {
                    violations.add('Employment contracts should include compensation or benefits information');
                }
            }
            when 'NDA' {
                if (!lowerClause.contains('confidential') && !lowerClause.contains('non-disclosure')) {
                    violations.add('NDA contracts must include confidentiality and non-disclosure terms');
                }
            }
            when 'Service Agreement' {
                if (!lowerClause.contains('service') && !lowerClause.contains('delivery')) {
                    violations.add('Service agreements must define service delivery terms');
                }
            }
            when 'Partnership' {
                if (!lowerClause.contains('partnership') && !lowerClause.contains('collaboration')) {
                    violations.add('Partnership agreements must define collaborative terms');
                }
            }
        }
    }
        
        
        
        
        
        
        
        //     Boolean typeCompliant = true;
        
        //     switch on contractType {
            //         when 'Employment' {
                //             if (!clause.containsIgnoreCase('employment') && !clause.containsIgnoreCase('employee')) {
                    //                 violations.add('Employment contracts must contain employment-specific terms');
                    //                 typeCompliant = false;
                //             }
            //         }
            //         when 'NDA' {
                //             if (!clause.containsIgnoreCase('confidential') && !clause.containsIgnoreCase('disclosure')) {
                    //                 violations.add('NDAs must contain confidentiality language');
                    //                 typeCompliant = false;
                //             }
            //         }
            //         when 'Service Agreement' {
                //             if (!clause.containsIgnoreCase('service') && !clause.containsIgnoreCase('deliverable')) {
                    //                 violations.add('Service agreements must define service terms');
                    //                 typeCompliant = false;
                //             }
            //         }
        //     }
        
        //     return typeCompliant;
    // }
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> performFullComplianceCheck(String documentId) {
        try {
            DocumentLifecycleConfiguration__c doc = [
                SELECT Id, GeneratedClause__c, Region__c, ContractType__c, ComplianceStatus__c
                FROM DocumentLifecycleConfiguration__c 
                WHERE Id = :documentId
            ];
            
            Boolean isCompliant = validateClause(doc.GeneratedClause__c, doc.Region__c, doc.ContractType__c);
            
            // Update compliance status
            doc.ComplianceStatus__c = isCompliant ? 'Compliant' : 'Non-Compliant';
            update doc;
            
            return new Map<String, Object>{
                'isCompliant' => isCompliant,
                'status' => doc.ComplianceStatus__c,
                'documentId' => documentId
            };
            
        } catch (Exception e) {
            throw new AuraHandledException('Compliance check failed: ' + e.getMessage());
        }
    }
    
    
    private static Boolean validateRegionCompliance(String clause, String region, List<String> violations) {
        Boolean regionCompliant = true;
        
        switch on region {
            when 'EU' {
                if (!clause.containsIgnoreCase('GDPR')) {
                    violations.add('EU documents must reference GDPR compliance');
                    regionCompliant = false;
                }
                if (!clause.containsIgnoreCase('eIDAS')) {
                    violations.add('EU documents should reference eIDAS regulation');
                    regionCompliant = false;
                }
            }
            when 'US' {
                if (!clause.containsIgnoreCase('E-SIGN') && !clause.containsIgnoreCase('ESIGN')) {
                    violations.add('US documents should reference E-SIGN Act compliance');
                    regionCompliant = false;
                }
            }
            when 'APAC' {
                if (!clause.containsIgnoreCase('data protection')) {
                    violations.add('APAC documents should reference data protection laws');
                    regionCompliant = false;
                }
            }
        }
        
        return regionCompliant;
    }
    
    
    
    
    public Boolean validateClause(String clause) {
        Boolean isCompliant = true;
        
        try {
            // Log compliance check start
            System.debug('Starting compliance validation for clause');
            
            // Check minimum length requirement
            if (clause.length() < 50) {
                isCompliant = false;
                System.debug('⚠ Clause too short - minimum 50 characters required');
            }
            
            // Check for required signature clause
            if (!clause.containsIgnoreCase('signature required')) {
                isCompliant = false;
                System.debug('⚠ Missing required signature clause');
            }
            
            // Additional compliance checks
            if (!clause.containsIgnoreCase('agreement') && !clause.containsIgnoreCase('contract')) {
                isCompliant = false;
                System.debug('⚠ Document must contain agreement or contract language');
            }
            
            // Log audit trail
            logComplianceCheck(clause, isCompliant);
            
            System.debug(isCompliant ? '✓ Compliance validation passed' : '✗ Compliance validation failed');
            return isCompliant;
            
        } catch (Exception e) {
            System.debug('Error during compliance check: ' + e.getMessage());
            return false;
        }
    }
    
    private static Boolean performComplianceValidation(String clause, String region, String contractType) {
        Boolean isCompliant = true;
        
        // Region-specific compliance checks
        if (region == 'EU') {
            if (!clause.containsIgnoreCase('GDPR') && contractType.containsIgnoreCase('Employment')) {
                isCompliant = false;
                System.debug('⚠ GDPR compliance required for EU employment contracts');
            }
        }
        
        if (region == 'US') {
            if (!clause.containsIgnoreCase('federal') && contractType.containsIgnoreCase('Employment')) {
                System.debug('ℹ US federal law reference recommended');
            }
        }
        
        // General compliance checks
        if (clause.length() < 50) {
            isCompliant = false;
            System.debug('⚠ Clause too short - minimum 50 characters required');
        }
        
        if (!clause.containsIgnoreCase('signature required')) {
            isCompliant = false;
            System.debug('⚠ Signature requirement must be explicitly stated');
        }
        
        return isCompliant;
    }
    
    private static void logComplianceCheck(String clause, String region, String contractType, Boolean isCompliant) {
        try {
            AuditTrail__c audit = new AuditTrail__c(
                RecordId__c = 'COMPLIANCE_' + System.now().getTime(),
            Action__c = isCompliant ? 'COMPLIANCE_CHECK_PASSED' : 'COMPLIANCE_CHECK_FAILED',
            Status__c = isCompliant ? 'SUCCESS' : 'VIOLATION',
            Details__c = 'Compliance validation for ' + region + ' ' + contractType + ': ' +
                (isCompliant ? 'PASSED' : 'FAILED'),
            UserId__c = UserInfo.getUserId()
                );
            insert audit;
        } catch (Exception e) {
            System.debug('⚠ Could not log compliance check: ' + e.getMessage());
        }
    }
    
    private void logComplianceCheck(String clause, Boolean result) {
        try {
            // Create audit record (you may need to create a custom audit object)
            System.debug('Logging compliance check - Result: ' + result);
            System.debug('Clause validated: ' + clause.left(100) + '...');
        } catch (Exception e) {
            System.debug('⚠ Could not log compliance check: ' + e.getMessage());
        }
        
    }
    public class ComplianceException extends Exception {}
    public class ComplianceValidationResult {
        @AuraEnabled public Boolean isCompliant { get; set; }
        @AuraEnabled public Decimal complianceScore { get; set; }
        @AuraEnabled public List<String> violations { get; set; }
        @AuraEnabled public String recommendation { get; set; }
    }
    public class ComplianceResult {
        @AuraEnabled public Boolean isCompliant;
        @AuraEnabled public List<String> violations;
        @AuraEnabled public Decimal complianceScore;
        @AuraEnabled public String recommendation;
        
        public ComplianceResult() {
            this.violations = new List<String>();
        }
    }
    





    //updated (from 3 last 3 files)
    // Compliance rules for different regions and document types
    private static final Map<String, Map<String, List<String>>> COMPLIANCE_RULES = new Map<String, Map<String, List<String>>>{
        'US' => new Map<String, List<String>>{
            'Employment' => new List<String>{'authorized signatory', 'at-will employment', 'binding arbitration'},
            'NDA' => new List<String>{'confidential information', 'injunctive relief', 'monetary damages'},
            'SLA' => new List<String>{'service level', 'uptime', 'performance standards'}
        },
        'EU' => new Map<String, List<String>>{
            'Employment' => new List<String>{'GDPR', 'data portability', 'right to erasure'},
            'NDA' => new List<String>{'GDPR-compliant', 'data subject rights', 'legitimate business interests'},
            'SLA' => new List<String>{'Digital Services Act', 'Standard Contractual Clauses', 'data residency'}
        },
        'APAC' => new Map<String, List<String>>{
            'Employment' => new List<String>{'local labor laws', 'data protection laws', 'local arbitration'},
            'NDA' => new List<String>{'local privacy laws', 'cross-border transfer', 'data localization'},
            'SLA' => new List<String>{'regional technology', 'data residency', 'local regulatory standards'}
        }
    };

    // Risk levels for compliance violations
    public enum RiskLevel { LOW, MEDIUM, HIGH, CRITICAL }
    /**
     * Get detailed compliance analysis
     * @param clauseText The clause text to analyze
     * @param region Geographic region
     * @param contractType Type of contract
     * @return Detailed compliance analysis
     */
    @AuraEnabled
    public static Map<String, Object> getDetailedComplianceAnalysis(String clauseText, String region, String contractType) {
        Map<String, Object> analysis = new Map<String, Object>();
        
        try {
            List<String> requiredTerms = getComplianceRules(region, contractType);
            List<String> presentTerms = new List<String>();
            List<String> missingTerms = new List<String>();
            
            String clauseLower = clauseText.toLowerCase();
            
            for (String term : requiredTerms) {
                if (clauseLower.contains(term.toLowerCase())) {
                    presentTerms.add(term);
                } else {
                    missingTerms.add(term);
                }
            }
            
            // Calculate compliance score
            Decimal complianceScore = requiredTerms.isEmpty() ? 100 : 
                (Decimal.valueOf(presentTerms.size()) / Decimal.valueOf(requiredTerms.size())) * 100;
            
            // Determine risk level
            RiskLevel risk = calculateRiskLevel(missingTerms.size(), requiredTerms.size());
            
            analysis.put('isCompliant', missingTerms.isEmpty());
            analysis.put('complianceScore', complianceScore);
            analysis.put('riskLevel', risk.name());
            analysis.put('presentTerms', presentTerms);
            analysis.put('missingTerms', missingTerms);
            analysis.put('totalRequiredTerms', requiredTerms.size());
            analysis.put('region', region);
            analysis.put('contractType', contractType);
            analysis.put('analysisDate', DateTime.now());
            
            // Add recommendations
            analysis.put('recommendations', generateRecommendations(missingTerms, region, contractType));
            
            System.debug('✓ Detailed compliance analysis completed: ' + complianceScore + '% compliant');
            
        } catch (Exception e) {
            System.debug('✗ Detailed compliance analysis failed: ' + e.getMessage());
            analysis.put('error', e.getMessage());
        }
        
        return analysis;
    }

    /**
     * Get compliance rules for region and contract type
     */
    @TestVisible
    private static List<String> getComplianceRules(String region, String contractType) {
        if (COMPLIANCE_RULES.containsKey(region)) {
            Map<String, List<String>> regionRules = COMPLIANCE_RULES.get(region);
            return regionRules.get(contractType);
        }
        return new List<String>();
    }

    /**
     * Calculate risk level based on missing compliance terms
     */
    @TestVisible
    private static RiskLevel calculateRiskLevel(Integer missingCount, Integer totalCount) {
        if (missingCount == 0) return RiskLevel.LOW;
        
        Decimal missingPercentage = (Decimal.valueOf(missingCount) / Decimal.valueOf(totalCount)) * 100;
        
        if (missingPercentage >= 75) return RiskLevel.CRITICAL;
        if (missingPercentage >= 50) return RiskLevel.HIGH;
        if (missingPercentage >= 25) return RiskLevel.MEDIUM;
        return RiskLevel.LOW;
    }
    /**
     * Generate recommendations for compliance improvements
     */
    @TestVisible
    private static List<String> generateRecommendations(List<String> missingTerms, String region, String contractType) {
        List<String> recommendations = new List<String>();
        
        if (missingTerms.isEmpty()) {
            recommendations.add('Document meets all compliance requirements for ' + region + ' ' + contractType);
            return recommendations;
        }
        
        for (String missingTerm : missingTerms) {
            switch on missingTerm.toLowerCase() {
                when 'gdpr' {
                    recommendations.add('Add GDPR compliance clause including data subject rights and lawful basis for processing');
                }
                when 'authorized signatory' {
                    recommendations.add('Include authorized signatory clause to establish legal authority for agreement execution');
                }
                when 'data residency' {
                    recommendations.add('Add data residency clause specifying geographic boundaries for data processing and storage');
                }
                when 'binding arbitration' {
                    recommendations.add('Include binding arbitration clause for dispute resolution to avoid costly litigation');
                }
                when else {
                    recommendations.add('Include "' + missingTerm + '" clause to meet ' + region + ' regulatory requirements');
                }
            }
        }
        
        return recommendations;
    }
    /**
     * Create compliance record for audit tracking
     */
    @TestVisible
    private static void createComplianceRecord(String clauseText, String region, String contractType, Boolean isCompliant, List<String> missingTerms) {
        try {
            // For now, we'll use custom objects. In a full implementation, you might want a dedicated ComplianceRecord__c object
            AuditTrail__c complianceRecord = new AuditTrail__c(
                Action__c = 'COMPLIANCE_CHECK',
                Status__c = isCompliant ? 'SUCCESS' : 'VIOLATION',
                Timestamp__c = DateTime.now(),
                UserDetails__c = UserInfo.getName() + ' (' + UserInfo.getUsername() + ')',
                SystemInfo__c = 'Compliance validation for ' + region + ' ' + contractType,
                AdditionalData__c = JSON.serialize(new Map<String, Object>{
                    'region' => region,
                    'contractType' => contractType,
                    'isCompliant' => isCompliant,
                    'missingTerms' => missingTerms,
                    'clauseLength' => clauseText.length(),
                    'complianceScore' => missingTerms.isEmpty() ? 100 : 0 // Simplified for this example
                })
            );
            
            insert complianceRecord;
        } catch (Exception e) {
            System.debug('⚠ Could not create compliance record: ' + e.getMessage());
        }
    }
        /**
     * Get compliance reports for management
     * @param region Optional region filter
     * @return Compliance statistics and trends
     */
    @AuraEnabled
    public static Map<String, Object> getComplianceReport(String region) {
        Map<String, Object> report = new Map<String, Object>();
        
        try {
            String regionFilter = String.isNotBlank(region) ? 'AND AdditionalData__c LIKE \'%"region":"' + region + '"%\'' : '';
            
            // Get compliance statistics from last 30 days
            String query = 'SELECT Status__c, COUNT(Id) count FROM AuditTrail__c ' +
                          'WHERE Action__c = \'COMPLIANCE_CHECK\' AND CreatedDate = LAST_N_DAYS:30 ' +
                          regionFilter + ' GROUP BY Status__c';
            
            List<AggregateResult> results = Database.query(query);
            
            Integer totalChecks = 0;
            Integer successfulChecks = 0;
            Integer violations = 0;
            
            for (AggregateResult result : results) {
                Integer count = (Integer)result.get('count');
                String status = (String)result.get('Status__c');
                
                totalChecks += count;
                
                if ('SUCCESS'.equals(status)) {
                    successfulChecks += count;
                } else if ('VIOLATION'.equals(status)) {
                    violations += count;
                }
            }
            
            Decimal complianceRate = totalChecks > 0 ? 
                (Decimal.valueOf(successfulChecks) / Decimal.valueOf(totalChecks)) * 100 : 0;
            
            report.put('totalChecks', totalChecks);
            report.put('successfulChecks', successfulChecks);
            report.put('violations', violations);
            report.put('complianceRate', complianceRate);
            report.put('region', region);
            report.put('reportDate', Date.today());
            report.put('period', 'Last 30 Days');
        
            // Get trending data for compliance over time
            List<AggregateResult> trendingData = [
                SELECT DAY_ONLY(CreatedDate) day, Status__c, COUNT(Id) totalcount
                FROM AuditTrail__c 
                WHERE Action__c = 'COMPLIANCE_CHECK' 
                AND CreatedDate = LAST_N_DAYS:7
                GROUP BY DAY_ONLY(CreatedDate), Status__c
                ORDER BY DAY_ONLY(CreatedDate)
            ];
        
            Map<String, Map<String, Integer>> dailyTrends = new Map<String, Map<String, Integer>>();
            for (AggregateResult trend : trendingData) {
                Date dayOnly = (Date)trend.get('day');
                String dayStr = dayOnly.format();
                String status = (String)trend.get('Status__c');
                Integer count = (Integer)trend.get('count');
                
                if (!dailyTrends.containsKey(dayStr)) {
                    dailyTrends.put(dayStr, new Map<String, Integer>{'SUCCESS' => 0, 'VIOLATION' => 0});
                }
                dailyTrends.get(dayStr).put(status, count);
            }
            
            report.put('dailyTrends', dailyTrends);
        
            // Get top violation patterns
            List<String> topViolations = getTopViolationPatterns(region);
            report.put('topViolations', topViolations);
            
            System.debug('✓ Compliance report generated for ' + (String.isBlank(region) ? 'all regions' : region));
            
        } catch (Exception e) {
            System.debug('✗ Compliance report generation failed: ' + e.getMessage());
            report.put('error', e.getMessage());
        }
        
        return report;
    }

    /**
     * Get top violation patterns for analysis
     */
    @TestVisible
    private static List<String> getTopViolationPatterns(String region) {
        List<String> patterns = new List<String>();
        try {
            String regionFilter = String.isNotBlank(region) ? 
                'AND AdditionalData__c LIKE \'%"region":"' + region + '"%\'' : '';
            
            String query = 'SELECT AdditionalData__c FROM AuditTrail__c ' +
                        'WHERE Action__c = \'COMPLIANCE_CHECK\' ' +
                        'AND Status__c = \'VIOLATION\' ' +
                        'AND CreatedDate = LAST_N_DAYS:30 ' +
                        regionFilter + ' LIMIT 50';
            
            List<AuditTrail__c> violations = Database.query(query);
            Map<String, Integer> termCounts = new Map<String, Integer>();
            
            for (AuditTrail__c violation : violations) {
                try {
                    Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(violation.AdditionalData__c);
                    List<Object> missingTerms = (List<Object>)data.get('missingTerms');
                    
                    if (missingTerms != null) {
                        for (Object term : missingTerms) {
                            String termStr = (String)term;
                            termCounts.put(termStr, termCounts.containsKey(termStr) ? 
                                        termCounts.get(termStr) + 1 : 1);
                        }
                    }
                } catch (Exception e) {
                    System.debug('⚠ Could not parse violation data: ' + e.getMessage());
                }
            }
            
            // Sort and get top 5 violations
            List<Map<String, Object>> sortedViolations = new List<Map<String, Object>>();
            for (String term : termCounts.keySet()) {
                sortedViolations.add(new Map<String, Object>{
                    'term' => term,
                    'count' => termCounts.get(term)
                });
            }
            
            // Simple sorting - in production, consider using a proper sort implementation
            for (Integer i = 0; i < Math.min(5, sortedViolations.size()); i++) {
                Map<String, Object> maxViolation = null;
                Integer maxIndex = -1;
                Integer maxCount = -1;
                
                for (Integer j = i; j < sortedViolations.size(); j++) {
                    Integer count = (Integer)sortedViolations[j].get('count');
                    if (count > maxCount) {
                        maxCount = count;
                        maxViolation = sortedViolations[j];
                        maxIndex = j;
                    }
                }
                
                if (maxViolation != null) {
                    // Swap elements
                    sortedViolations.set(maxIndex, sortedViolations[i]);
                    sortedViolations.set(i, maxViolation);
                    patterns.add((String)maxViolation.get('term') + ' (' + maxCount + ' violations)');
                }
            }
            
        } catch (Exception e) {
            System.debug('⚠ Could not analyze violation patterns: ' + e.getMessage());
            patterns.add('Analysis unavailable');
        }
        
        return patterns;
    }

    /**
     * Log compliance check activity
     */
    @TestVisible
    private static void logComplianceCheck(String region, String contractType, String status, String details) {
        try {
            AuditTrail__c auditLog = new AuditTrail__c(
                Action__c = 'COMPLIANCE_CHECK',
                Status__c = status,
                Timestamp__c = DateTime.now(),
                UserDetails__c = UserInfo.getName() + ' (' + UserInfo.getUsername() + ')',
                SystemInfo__c = 'Compliance check for ' + region + ' ' + contractType + ': ' + details,
                AdditionalData__c = JSON.serialize(new Map<String, Object>{
                    'region' => region,
                    'contractType' => contractType,
                    'details' => details,
                    'timestamp' => DateTime.now().format(),
                    'userId' => UserInfo.getUserId()
                })
            );
            
            insert auditLog;
        } catch (Exception e) {
            System.debug('⚠ Could not log compliance check: ' + e.getMessage());
        }
    }
    /**
     * Batch validate multiple clauses
     * @param clauseRequests List of clause validation requests
     * @return List of validation results
     */
    @AuraEnabled
    public static List<Map<String, Object>> batchValidateClauses(List<Map<String, String>> clauseRequests) {
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        
        try {
            for (Map<String, String> request : clauseRequests) {
                String clauseText = request.get('clauseText');
                String region = request.get('region');
                String contractType = request.get('contractType');
                
                Map<String, Object> result = getDetailedComplianceAnalysis(clauseText, region, contractType);
                result.put('requestId', request.get('id')); // For tracking
                results.add(result);
            }
            
            System.debug('✓ Batch validation completed for ' + results.size() + ' clauses');
        } catch (Exception e) {
            System.debug('✗ Batch validation failed: ' + e.getMessage());
            throw new AuraHandledException('Batch validation failed: ' + e.getMessage());
        }
        
        return results;
    }
    /**
     * Get compliance dashboard data
     * @return Dashboard statistics and metrics
     */
    @AuraEnabled
    public static Map<String, Object> getComplianceDashboard() {
        Map<String, Object> dashboard = new Map<String, Object>();
        
        try {
            // Overall compliance metrics
            List<AggregateResult> overallStats = [
                SELECT Status__c, COUNT(Id) totalcount
                FROM AuditTrail__c 
                WHERE Action__c = 'COMPLIANCE_CHECK' 
                AND CreatedDate = LAST_N_DAYS:30
                GROUP BY Status__c
            ];
            
            Integer totalChecks = 0;
            Integer violations = 0;
            for (AggregateResult stat : overallStats) {
                Integer count = (Integer)stat.get('count');
                totalChecks += count;
                if ('VIOLATION'.equals(stat.get('Status__c'))) {
                    violations += count;
                }
            }
            
            dashboard.put('totalChecks', totalChecks);
            dashboard.put('violations', violations);
            dashboard.put('complianceRate', totalChecks > 0 ? 
                        ((totalChecks - violations) * 100.0 / totalChecks) : 100);
            
            // Regional breakdown
            Map<String, Object> regionalData = new Map<String, Object>();
            for (String region : new List<String>{'US', 'EU', 'APAC'}) {
                Map<String, Object> regionReport = getComplianceReport(region);
                regionalData.put(region, regionReport);
            }
            dashboard.put('regionalBreakdown', regionalData);
            
            // Recent activity
            List<AuditTrail__c> recentActivity = 
            [
                SELECT CreatedDate, Status__c, SystemInfo__c
                FROM AuditTrail__c
                WHERE Action__c = 'COMPLIANCE_CHECK'
                ORDER BY CreatedDate DESC
                LIMIT 10
            ];
            
            List<Map<String, Object>> activityList = new List<Map<String, Object>>();
            for (AuditTrail__c activity : recentActivity) {
                activityList.add(new Map<String, Object>{
                    'date' => activity.CreatedDate,
                    'status' => activity.Status__c,
                    'description' => activity.SystemInfo__c
                });
            }
            dashboard.put('recentActivity', activityList);
            
            dashboard.put('lastUpdated', DateTime.now());
            
            System.debug('✓ Compliance dashboard data compiled');
            
        } catch (Exception e) {
            System.debug('✗ Dashboard compilation failed: ' + e.getMessage());
            dashboard.put('error', e.getMessage());
        }
        
        return dashboard;
    }
}






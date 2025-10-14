public class ComplianceChecker {
                                    
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
        ComplianceValidationResult r = new ComplianceValidationResult();
        try {
            // Basic checks
            if (String.isBlank(clause) || clause.length() < 100) {
                r.violations.add('Clause content insufficient length');
            }
            // eIDAS/GDPR sample check
            if ('EU' == region && !clause.toLowerCase().contains('gdpr') && !clause.toLowerCase().contains('data protection')) {
                r.violations.add('Missing GDPR/data protection clause for EU region');
            }
            // Signature validity check
            if (!clause.toLowerCase().contains('electronic signature') && !clause.toLowerCase().contains('signed electronically')) {
                r.violations.add('Missing explicit electronic signature validity statement');
            }
            // Contract-type specific checks
            if ('Employment' == contractType && !clause.toLowerCase().contains('termination')) {
                r.violations.add('Employment contract missing termination clause');
            }
            // compute score: simple severity weighting
            Integer vCount = r.violations.size();
            Decimal score = Math.max(0, 100 - (vCount * 15));
            r.complianceScore = score;
            r.isCompliant = score >= 75;
            // generate recommendations
            if (!r.isCompliant) {
                r.recommendations.add('Review the violations and add missing clauses.');
                if (r.complianceScore < 50) r.recommendations.add('Send to legal review before publishing.');
            }
            return r;
        } catch (Exception e) {
            r.isCompliant = false;
            r.complianceScore = 0;
            r.violations.add('Exception during compliance check: ' + e.getMessage());
            return r;
        }
    }                             
                                
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
                    
                    @AuraEnabled
                    public static Boolean validateClause(String clause, String region, String contractType) {
                      
                        ComplianceResult result = new ComplianceResult();
                        List<String> violations = new List<String>();
                        Boolean compliant = true;
                    
                        try {
                                // Basic content validation
                                if (String.isBlank(clause) || clause.length() < 50) {
                                        violations.add('Document content is insufficient');
                                        compliant = false;
                                }
                        
                                // Region-specific compliance checks
                                compliant = validateRegionCompliance(clause, region, violations) && compliant;
                        
                                // Contract type-specific checks
                                compliant = validateContractTypeCompliance(clause, contractType, violations) && compliant;
                        
                                // Electronic signature compliance
                                if (!clause.toLowerCase().contains('electronic signature') &&
                                    !clause.toLowerCase().contains('e-signature')) {
                                        violations.add('Document must reference electronic signature requirements');
                                        compliant = false;
                                }
                        
                                // Legal binding clause check
                                if (!clause.toLowerCase().contains('legally binding') &&
                                    !clause.toLowerCase().contains('legal equivalent')) {
                                        violations.add('Document must state that electronic signatures are legally binding');
                                        compliant = false;
                                }
                        
                                result.isCompliant = compliant;
                                result.violations = violations;
                                result.complianceScore = calculateComplianceScore(violations.size());
                                result.recommendation = generateComplianceRecommendation(violations);
                        
                                // Log compliance check
                                AuditTrailManager.logSystemActivity('COMPLIANCE_CHECK',
                                    'Compliance validation completed. Status: ' + (compliant ? 'COMPLIANT' : 'NON-COMPLIANT'));
                        
                        } catch (Exception e) {
                                result.isCompliant = false;
                                result.violations = new List<String>{'Compliance validation failed: ' + e.getMessage()};
                                result.complianceScore = 0;
                        }
                    
                        return result;
                }
                
                
                
                
                
                
                
                
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


    public class ComplianceValidationResult {
        @AuraEnabled public Boolean isCompliant;
        @AuraEnabled public Decimal complianceScore;
        @AuraEnabled public List<String> violations;
        @AuraEnabled public List<String> recommendations;
        public ComplianceValidationResult() { this.violations = new List<String>(); this.recommendations = new List<String>(); this.isCompliant = true; this.complianceScore = 100; }
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
    
}
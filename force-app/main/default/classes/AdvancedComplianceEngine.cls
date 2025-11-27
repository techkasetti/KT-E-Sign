public class AdvancedComplianceEngine {
    
    // Compliance scoring thresholds
   
        public static final Decimal COMPLIANCE_THRESHOLD = 80.0;
    public static final Map<String, Integer> SEVERITY_WEIGHTS = new Map<String, Integer>{
        'CRITICAL' => 50,
        'HIGH' => 25,
        'MEDIUM' => 10,
        'LOW' => 5
    };
// Regional compliance regulations
    public static final Map<String, Set<String>> REGIONAL_REGULATIONS = new Map<String, Set<String>>{
        'EU' => new Set<String>{'GDPR', 'EIDAS'},
        'US' => new Set<String>{'HIPAA', 'SOX', 'CCPA'},
        'CANADA' => new Set<String>{'PIPEDA', 'GDPR'},
        'APAC' => new Set<String>{'LGPD', 'GDPR'}
    };
    

    @AuraEnabled
    public static ComplianceReport performAdvancedCompliance(String documentId, String region, String contractType) {
            try {
            List<ComplianceViolation> violations = new List<ComplianceViolation>();
            
            // Execute region-specific compliance checks
            if (region == 'EU') {
                violations.addAll(checkGDPRCompliance(documentId));
               // violations.addAll(checkEIDASCompliance(documentId));
            }
            
            if (region == 'US') {
                violations.addAll(checkHIPAACompliance(documentId, contractType));
                violations.addAll(checkSOXCompliance(documentId, contractType));
                violations.addAll(checkCCPACompliance(documentId, contractType));
            }
            
            if (region == 'CANADA') {
                violations.addAll(checkPIPEDACompliance(documentId));
                violations.addAll(checkGDPRCompliance(documentId));
            }
            
            if (region == 'APAC') {
                violations.addAll(checkLGPDCompliance(documentId));
                violations.addAll(checkGDPRCompliance(documentId));
            }
            
            // Calculate overall compliance score
            Decimal complianceScore = calculateComplianceScore(violations);
            String overallStatus = complianceScore >= COMPLIANCE_THRESHOLD ? 'Compliant' : 'Non-Compliant';
            
            // Log audit trail
            logComplianceAudit(documentId, overallStatus, violations, complianceScore);
            
            return new ComplianceReport(overallStatus, complianceScore, violations);
            
        } catch (Exception e) {
            throw new AuraHandledException('Advanced compliance check failed: ' + e.getMessage());
        }
    }

    
    
    
        //     try {
    //         ComplianceReport report = new ComplianceReport();
    //         report.documentId   = documentId;
    //         report.region       = region;
    //         report.contractType = contractType;
    //         report.checkDate    = DateTime.now();
            
    //         // Perform multi-layered compliance checks
    //         List<ComplianceViolation> violations = new List<ComplianceViolation>();
            
    //         // GDPR Compliance (EU)
    //         if (region == 'EU') {
    //             violations.addAll(checkGDPRCompliance(documentId, contractType));
    //         }
            
    //         // HIPAA Compliance (Healthcare)
    //         if (contractType.containsIgnoreCase('healthcare') || contractType.containsIgnoreCase('medical')) {
    //             violations.addAll(checkHIPAACompliance(documentId));
    //         }
            
    //         // SOX Compliance (Financial)
    //         if (contractType.containsIgnoreCase('financial') || contractType.containsIgnoreCase('investment')) {
    //             violations.addAll(checkSOXCompliance(documentId));
    //         }
            
    //         // CCPA Compliance (California - Employment)
    //         if (region == 'US' && contractType.containsIgnoreCase('employment')) {
    //             violations.addAll(checkCCPACompliance(documentId));
    //         }
            
    //         // Calculate compliance score
    //         report.violations      = violations;
    //         report.complianceScore = calculateComplianceScore(violations);
    //         report.overallStatus   = report.complianceScore >= COMPLIANCE_THRESHOLD
    //             ? 'COMPLIANT'
    //             : 'NON_COMPLIANT';
            
    //         // Create audit trail
    //         logComplianceAudit(report);
            
    //         return report;
    //     } catch (Exception e) {
    //         throw new AuraHandledException('Advanced compliance check failed: ' + e.getMessage());
    //     }
    // }
    
    private static List<ComplianceViolation> checkLGPDCompliance(String documentId) {
        List<ComplianceViolation> violations = new List<ComplianceViolation>();
        
        DocumentLifecycleConfiguration__c doc = [
            SELECT Id, GeneratedClause__c 
            FROM DocumentLifecycleConfiguration__c 
            WHERE Id = :documentId
        ];
        
        String content = doc.GeneratedClause__c?.toLowerCase() ?? '';
        
        // Check for data processing purpose
        if (!content.contains('processing purpose') && !content.contains('finalidade')) {
            violations.add(new ComplianceViolation(
                'LGPD',
                'Missing Processing Purpose',
                'HIGH',
                'LGPD requires clear specification of data processing purpose',
                'Add specific data processing purpose clauses'
            ));
        }
        
        return violations;
    }
    // private static List<ComplianceViolation> checkEIDASCompliance(String documentId) {
    //     List<ComplianceViolation> violations = new List<ComplianceViolation>();
        
    //     // Check signature method requirements for EU documents
    //     List<Signature_Request__c> signatures = [
    //         SELECT Id, SignatureMethod__c, SignatureData__c 
    //         FROM Signature_Request__c 
    //         WHERE DocumentId__c = :documentId
    //     ];
        
    //     if (!signatures.isEmpty()) {
    //         for (Signature_Request__c sig : signatures) {
    //             if (String.isBlank(sig.SignatureData__c)) {
    //                 violations.add(new ComplianceViolation(
    //                     'EIDAS',
    //                     'Insufficient Signature Data',
    //                     'MEDIUM',
    //                     'eIDAS requires comprehensive signature metadata',
    //                     'Ensure all signature requests capture complete metadata'
    //                 ));
    //             }
    //         }
    //     }
        
    //     return violations;
    // }
   
    private static List<ComplianceViolation> checkGDPRCompliance(String documentId) {
        List<ComplianceViolation> violations = new List<ComplianceViolation>();
        
        DocumentLifecycleConfiguration__c doc = [
            SELECT Id, GeneratedClause__c, Region__c 
            FROM DocumentLifecycleConfiguration__c 
            WHERE Id = :documentId
        ];
        
        String content = doc.GeneratedClause__c?.toLowerCase() ?? '';
        
        // Check for explicit consent clause
        if (!content.contains('explicit consent') && !content.contains('data processing consent')) {
            violations.add(new ComplianceViolation(
                'GDPR',
                'Missing Explicit Consent',
                'CRITICAL',
                'Document must include explicit data processing consent clause',
                'Add explicit consent language for data processing activities'
            ));
        }
        
        // Check for data subject rights
        if (!content.contains('right to access') && !content.contains('data subject rights')) {
            violations.add(new ComplianceViolation(
                'GDPR',
                'Missing Data Subject Rights',
                'HIGH',
                'Document must inform data subjects of their rights',
                'Include comprehensive data subject rights information'
            ));
        }
        
        // Check for lawful basis
        if (!content.contains('lawful basis') && !content.contains('legal basis')) {
            violations.add(new ComplianceViolation(
                'GDPR',
                'Missing Lawful Basis',
                'HIGH',
                'Document must specify lawful basis for processing',
                'Clearly state the lawful basis for data processing'
            ));
        }
        
        return violations;
    }


    private static List<ComplianceViolation> checkPIPEDACompliance(String documentId) {
        List<ComplianceViolation> violations = new List<ComplianceViolation>();
        
        DocumentLifecycleConfiguration__c doc = [
            SELECT Id, GeneratedClause__c 
            FROM DocumentLifecycleConfiguration__c 
            WHERE Id = :documentId
        ];
        
        String content = doc.GeneratedClause__c?.toLowerCase() ?? '';
        
        // Check for meaningful consent
        if (!content.contains('meaningful consent') && !content.contains('informed consent')) {
            violations.add(new ComplianceViolation(
                'PIPEDA',
                'Missing Meaningful Consent',
                'CRITICAL',
                'Canadian privacy law requires meaningful consent',
                'Add meaningful consent provisions'
            ));
        }
        
        return violations;
    }
    


    // GDPR Compliance
    private static List<ComplianceViolation> checkGDPRCompliance(String documentId, String contractType) {
        List<ComplianceViolation> violations = new List<ComplianceViolation>();
        
        ComplianceViolation gdprViolation = new ComplianceViolation();
        gdprViolation.regulationType = 'GDPR';
        gdprViolation.violationType  = 'DATA_PROCESSING_CONSENT';
        gdprViolation.severity       = 'HIGH';
        gdprViolation.description    = 'Document lacks explicit data processing consent clause';
        gdprViolation.recommendation = 'Add GDPR Article 6 lawful basis for processing';
        violations.add(gdprViolation);
        
        return violations;
    }
    private static List<ComplianceViolation> checkHIPAACompliance(String documentId, String contractType) {
        List<ComplianceViolation> violations = new List<ComplianceViolation>();
        
        if (contractType != 'Healthcare' && contractType != 'Medical') {
            return violations; // HIPAA only applies to healthcare contracts
        }
        
        DocumentLifecycleConfiguration__c doc = [
            SELECT Id, GeneratedClause__c 
            FROM DocumentLifecycleConfiguration__c 
            WHERE Id = :documentId
        ];
        
        String content = doc.GeneratedClause__c?.toLowerCase() ?? '';
        
        // Check for PHI safeguards
        if (!content.contains('protected health information') && !content.contains('phi safeguards')) {
            violations.add(new ComplianceViolation(
                'HIPAA',
                'Missing PHI Safeguards',
                'CRITICAL',
                'Healthcare contracts must include PHI protection measures',
                'Add comprehensive PHI safeguard clauses'
            ));
        }
        
        // Check for minimum necessary standard
        if (!content.contains('minimum necessary') && !content.contains('minimum required')) {
            violations.add(new ComplianceViolation(
                'HIPAA',
                'Missing Minimum Necessary',
                'HIGH',
                'Must specify minimum necessary standard for PHI access',
                'Include minimum necessary access provisions'
            ));
        }
        
        return violations;
    }

    // HIPAA Compliance
    private static List<ComplianceViolation> checkHIPAACompliance(String documentId) {
        List<ComplianceViolation> violations = new List<ComplianceViolation>();
        
        ComplianceViolation hipaaViolation = new ComplianceViolation();
        hipaaViolation.regulationType = 'HIPAA';
        hipaaViolation.violationType  = 'PHI_PROTECTION';
        hipaaViolation.severity       = 'CRITICAL';
        hipaaViolation.description    = 'Missing Protected Health Information safeguards';
        hipaaViolation.recommendation = 'Add HIPAA privacy and security rule compliance';
        violations.add(hipaaViolation);
        
        return violations;
    }
    
    // SOX Compliance
    private static List<ComplianceViolation> checkSOXCompliance(String documentId) {
        List<ComplianceViolation> violations = new List<ComplianceViolation>();
        
        ComplianceViolation soxViolation = new ComplianceViolation();
        soxViolation.regulationType = 'SOX';
        soxViolation.violationType  = 'FINANCIAL_CONTROLS';
        soxViolation.severity       = 'HIGH';
        soxViolation.description    = 'Document lacks required financial control attestations';
        soxViolation.recommendation = 'Add SOX Section 404 internal control requirements';
        violations.add(soxViolation);
        
        return violations;
    }
        private static List<ComplianceViolation> checkSOXCompliance(String documentId, String contractType) {
        List<ComplianceViolation> violations = new List<ComplianceViolation>();
        
        if (contractType != 'Financial' && contractType != 'Investment') {
            return violations; // SOX only applies to financial contracts
        }
        
        DocumentLifecycleConfiguration__c doc = [
            SELECT Id, GeneratedClause__c 
            FROM DocumentLifecycleConfiguration__c 
            WHERE Id = :documentId
        ];
        
        String content = doc.GeneratedClause__c?.toLowerCase() ?? '';
        
        // Check for financial control attestations
        if (!content.contains('internal controls') && !content.contains('financial reporting controls')) {
            violations.add(new ComplianceViolation(
                'SOX',
                'Missing Internal Controls',
                'CRITICAL',
                'Financial contracts must reference internal control requirements',
                'Add internal control attestation clauses'
            ));
        }
        
        // Check for audit trail requirements
        if (!content.contains('audit trail') && !content.contains('documentation requirements')) {
            violations.add(new ComplianceViolation(
                'SOX',
                'Missing Audit Trail Requirements',
                'HIGH',
                'Must specify audit trail and documentation requirements',
                'Include comprehensive audit trail provisions'
            ));
        }
        
        return violations;
    }

    // CCPA Compliance
    private static List<ComplianceViolation> checkCCPACompliance(String documentId) {
        List<ComplianceViolation> violations = new List<ComplianceViolation>();
        
        ComplianceViolation ccpaViolation = new ComplianceViolation();
        ccpaViolation.regulationType = 'CCPA';
        ccpaViolation.violationType  = 'CONSUMER_PRIVACY_RIGHTS';
        ccpaViolation.severity       = 'MEDIUM';
        ccpaViolation.description    = 'Missing California consumer privacy rights disclosure';
        ccpaViolation.recommendation = 'Add CCPA consumer rights and opt-out mechanisms';
        violations.add(ccpaViolation);
        
        return violations;
    }
    
    // Score Calculation
    private static Integer calculateComplianceScore(List<ComplianceViolation> violations) {
        Integer totalDeductions = 0;
        
        for (ComplianceViolation violation : violations) {
            totalDeductions += SEVERITY_WEIGHTS.get(violation.severity);
        }
        
        return Math.max(0, 100 - totalDeductions);
    }
        private static List<ComplianceViolation> checkCCPACompliance(String documentId, String contractType) {
        List<ComplianceViolation> violations = new List<ComplianceViolation>();
        
        if (contractType != 'Employment' && contractType != 'Consumer') {
            return violations;
        }
        
        DocumentLifecycleConfiguration__c doc = [
            SELECT Id, GeneratedClause__c 
            FROM DocumentLifecycleConfiguration__c 
            WHERE Id = :documentId
        ];
        
        String content = doc.GeneratedClause__c?.toLowerCase() ?? '';
        
        // Check for California consumer privacy rights
        if (!content.contains('california consumer privacy') && !content.contains('ccpa rights')) {
            violations.add(new ComplianceViolation(
                'CCPA',
                'Missing Consumer Rights',
                'HIGH',
                'California consumers must be informed of their privacy rights',
                'Add CCPA consumer rights disclosure'
            ));
        }
        
        return violations;
    }
    private static void logComplianceAudit(String documentId, String status, 
                                         List<ComplianceViolation> violations, Decimal score) {
        try {
            AuditTrail__c audit = new AuditTrail__c(
                DocumentId__c = documentId,
                Action__c = 'Advanced Compliance Check',
                Details__c = 'Overall Status: ' + status + ', Score: ' + score + 
                           ', Violations: ' + violations.size(),
                Timestamp__c = Datetime.now(),
                UserId__c = UserInfo.getUserId()
            );
            insert audit;
            
            // Create detailed violation records
            if (!violations.isEmpty()) {
                List<ComplianceViolationRecord__c> violationRecords = new List<ComplianceViolationRecord__c>();
                
                for (ComplianceViolation violation : violations) {
                    violationRecords.add(new ComplianceViolationRecord__c(
                        AuditTrail__c = audit.Id,
                        RegulationType__c = violation.regulationType,
                        ViolationType__c = violation.violationType,
                        Severity__c = violation.severity,
                        Description__c = violation.description,
                        Recommendation__c = violation.recommendation,
                        CreatedDate__c = Datetime.now()
                    ));
                }
                
                insert violationRecords;
            }
            
        } catch (Exception e) {
            System.debug('Failed to log compliance audit: ' + e.getMessage());
        }
    }
    
    public class BulkComplianceResult {
        @InvocableVariable public String documentId;
        @InvocableVariable public String region;
        @InvocableVariable public String contractType;
        @InvocableVariable public Integer complianceScore;
        @InvocableVariable public String overallStatus;
    }

    @InvocableMethod(label='Perform Bulk Compliance Check' description='Run advanced compliance checks on multiple documents')
    public static List<BulkComplianceResult> performBulkCompliance(List<BulkComplianceRequest> requests) {
        List<BulkComplianceResult> results = new List<BulkComplianceResult>();
        for (BulkComplianceRequest request : requests) {
            try {
                ComplianceReport report = performAdvancedCompliance(
                    request.documentId, 
                    request.region, 
                    request.contractType
                );
                BulkComplianceResult result = new BulkComplianceResult();
                result.documentId = request.documentId;
                result.region = request.region;
                result.contractType = request.contractType;
                result.complianceScore = (report.complianceScore != null) ? Integer.valueOf(report.complianceScore) : 0;
                result.overallStatus = report.overallStatus;
                results.add(result);
            } catch (Exception e) {
                BulkComplianceResult errorResult = new BulkComplianceResult();
                errorResult.documentId = request.documentId;
                errorResult.region = request.region;
                errorResult.contractType = request.contractType;
                errorResult.complianceScore = 0;
                errorResult.overallStatus = 'ERROR: ' + e.getMessage();
                results.add(errorResult);
            }
        }
        return results;
    }
    

    // Logging
    private static void logComplianceAudit(ComplianceReport report) {
        try {
            AuditTrail__c audit = new AuditTrail__c(
                    RecordId__c    = report.documentId,
                    Action__c      = 'ADVANCED_COMPLIANCE_CHECK',
                    Status__c      = report.overallStatus,
                    Timestamp__c   = Datetime.valueOf(report.timestamp),
                    UserDetails__c = UserInfo.getName() + ' (' + UserInfo.getUsername() + ')',
                    SystemInfo__c  = 'Advanced compliance check for ' + report.region + ' ' + report.contractType,
                    AdditionalInfo__c = 'Score: ' + report.complianceScore + '% | Violations: ' + report.violations.size()
                );
            insert audit;
            
            if (!report.violations.isEmpty()) {
                insert createViolationRecords(report.violations, audit.Id);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to log compliance audit: ' + e.getMessage());
        }
    }
    
    // Violation Records
    private static List<ComplianceViolationRecord__c> createViolationRecords(
        List<ComplianceViolation> violations, Id auditId
    ) {
        List<ComplianceViolationRecord__c> records = new List<ComplianceViolationRecord__c>();
        for (ComplianceViolation violation : violations) {
            ComplianceViolationRecord__c record = new ComplianceViolationRecord__c(
                AuditTrail__c    = auditId,
            RegulationType__c = violation.regulationType,
            ViolationType__c  = violation.violationType,
            Severity__c       = violation.severity,
            Description__c    = violation.description,
            Recommendation__c = violation.recommendation,
            CreatedDate__c    = DateTime.now()
                );
            records.add(record);
        }
        return records;
    }
    
    
    // Wrapper: Compliance Violation
    public class ComplianceViolation {
        @AuraEnabled public String regulationType;
        @AuraEnabled public String violationType;
        @AuraEnabled public String severity;
        @AuraEnabled public String description;
        @AuraEnabled public String recommendation;
            public ComplianceViolation() {}

            public ComplianceViolation(String regulationType, String violationType, String severity, String description, String recommendation) {
                this.regulationType = regulationType;
                this.violationType = violationType;
                this.severity = severity;
                this.description = description;
                this.recommendation = recommendation;
            }
    }
    
   
    
    // Wrapper: Bulk Request
    public class BulkComplianceRequest {
        @InvocableVariable(required=true) public String documentId;
        @InvocableVariable(required=true) public String region;
        @InvocableVariable(required=true) public String contractType;
    }

    // Wrapper Classes
    public class ComplianceReport {
        @AuraEnabled public String documentId { get; set; }
        @AuraEnabled public String region { get; set; }
        @AuraEnabled public String contractType { get; set; }
        @AuraEnabled public String overallStatus { get; set; }
        @AuraEnabled public Decimal complianceScore { get; set; }
        @AuraEnabled public List<ComplianceViolation> violations { get; set; }
        @AuraEnabled public String timestamp { get; set; }
        @AuraEnabled public String recommendation { get; set; }

        public ComplianceReport(String status, Decimal score, List<ComplianceViolation> viols) {
            this.overallStatus = status;
            this.complianceScore = score;
            this.violations = viols;
            this.timestamp = System.now().format();
            this.recommendation = generateOverallRecommendation(viols);
        }

        public ComplianceReport(String documentId, String region, String contractType, String status, Decimal score, List<ComplianceViolation> viols) {
            this.documentId = documentId;
            this.region = region;
            this.contractType = contractType;
            this.overallStatus = status;
            this.complianceScore = score;
            this.violations = viols;
            this.timestamp = System.now().format();
            this.recommendation = generateOverallRecommendation(viols);
        }

        private String generateOverallRecommendation(List<ComplianceViolation> violations) {
            if (violations.isEmpty()) {
                return 'Document is fully compliant with all applicable regulations.';
            }
            Integer criticalCount = 0;
            Integer highCount = 0;
            for (ComplianceViolation violation : violations) {
                if (violation.severity == 'CRITICAL') criticalCount++;
                if (violation.severity == 'HIGH') highCount++;
            }
            if (criticalCount > 0) {
                return 'URGENT: Address ' + criticalCount + ' critical compliance issues before proceeding.';
            } else if (highCount > 0) {
                return 'Review and resolve ' + highCount + ' high-priority compliance issues.';
            } else {
                return 'Minor compliance adjustments recommended for optimal adherence.';
            }
        }
    }


    }
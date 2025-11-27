public class MultiJurisdictionComplianceEngine {
    // Defines compliance configurations for various jurisdictions
    private static final Map<String, JurisdictionConfig> JURISDICTION_CONFIGS = new Map<String, JurisdictionConfig>{
        'US' => new JurisdictionConfig('US', 'ESIGN_ACT', true, 'SHA-256', 2000, true),
        'EU' => new JurisdictionConfig('EU', 'EIDAS', true, 'SHA-256', 2014, true),
        'UK' => new JurisdictionConfig('UK', 'ETA_2000', true, 'SHA-256', 2000, true),
        'CA' => new JurisdictionConfig('CA', 'PIPEDA', true, 'SHA-256', 2000, true),
        'AU' => new JurisdictionConfig('AU', 'ETA_1999', true, 'SHA-256', 1999, true),
        'JP' => new JurisdictionConfig('JP', 'ELECTRONIC_SIGNATURE_LAW', false, 'SHA-256', 2000, false),
        'SG' => new JurisdictionConfig('SG', 'ETA_2010', true, 'SHA-256', 2010, true),
        'IN' => new JurisdictionConfig('IN', 'IT_ACT_2000', true, 'SHA-256', 2000, false),
        'BR' => new JurisdictionConfig('BR', 'ICP_BRASIL', false, 'SHA-256', 2001, false)
    };

    /**
     * @description Validates a document's compliance across multiple jurisdictions.
     * @param documentId The ID of the DocumentLifecycleConfiguration__c record.
     * @param jurisdictions A list of jurisdiction codes (e.g., 'US', 'EU').
     * @param contractType The type of contract being validated.
     * @return JurisdictionValidationResult containing the overall compliance status.
     */
    @AuraEnabled(cacheable=false)
    public static JurisdictionValidationResult validateMultiJurisdictionCompliance(String documentId, List<String> jurisdictions, String contractType) {
        try {
            JurisdictionValidationResult result = new JurisdictionValidationResult();
            result.documentId = documentId;
            // CORRECTED: Removed incorrect markdown syntax from System.now()
            result.validationTimestamp = System.now();
            result.jurisdictionResults = new Map<String, SingleJurisdictionResult>();

            // CORRECTED: Removed duplicate SOQL query for the 'document' variable
            DocumentLifecycleConfiguration__c document = [
                SELECT Id, Region__c, Contract_Type__c, Legal_Requirements__c, Authentication_Method__c, Signature_Standard__c
                FROM DocumentLifecycleConfiguration__c
                WHERE Id = :documentId
                LIMIT 1
            ];

            Boolean overallCompliance = true;
            for (String jurisdiction : jurisdictions) {
                SingleJurisdictionResult jurisdictionResult = validateSingleJurisdiction(document, jurisdiction, contractType);
                result.jurisdictionResults.put(jurisdiction, jurisdictionResult);
                if (!jurisdictionResult.isCompliant) {
                    overallCompliance = false;
                }
            }

            result.overallCompliance = overallCompliance;
            result.complianceScore = calculateMultiJurisdictionScore(result.jurisdictionResults);
            
            storeJurisdictionValidation(result);
            return result;
        } catch (Exception e) {
            System.debug('Multi-jurisdiction validation error: ' + e.getMessage());
            return getDefaultValidationResult();
        }
    }

    private static SingleJurisdictionResult validateSingleJurisdiction(DocumentLifecycleConfiguration__c document, String jurisdiction, String contractType) {
        SingleJurisdictionResult result = new SingleJurisdictionResult();
        result.jurisdiction = jurisdiction;
        result.validationDetails = new List<ValidationDetail>();
        JurisdictionConfig config = JURISDICTION_CONFIGS.get(jurisdiction);

        if (config == null) {
            result.isCompliant = false;
            result.validationDetails.add(new ValidationDetail('UNSUPPORTED_JURISDICTION', 'HIGH', 'Jurisdiction ' + jurisdiction + ' is not supported', 'Contact support for jurisdiction enablement'));
            return result;
        }

        Boolean jurisdictionCompliant = true;
        if (!validateSignatureStandard(document, config, result)) { jurisdictionCompliant = false; }
        if (!validateAuthenticationRequirements(document, config, result)) { jurisdictionCompliant = false; }
        if (!validateDataRetention(document, config, result)) { jurisdictionCompliant = false; }
        if (!validateLegalFramework(document, config, contractType, result)) { jurisdictionCompliant = false; }
        if (!validateCrossBorderTransfer(document, config, result)) { jurisdictionCompliant = false; }

        result.isCompliant = jurisdictionCompliant;
        result.complianceScore = calculateJurisdictionScore(result.validationDetails);
        return result;
    }

    private static Boolean validateSignatureStandard(DocumentLifecycleConfiguration__c document, JurisdictionConfig config, SingleJurisdictionResult result) {
        Boolean compliant = true;
        if (document.Signature_Standard__c != config.requiredEncryption) {
            compliant = false;
            result.validationDetails.add(new ValidationDetail('ENCRYPTION_STANDARD', 'HIGH', 'Document uses ' + document.Signature_Standard__c + ' but ' + config.jurisdiction + ' requires ' + config.requiredEncryption, 'Update signature standard to ' + config.requiredEncryption));
        }
        if (config.requiresAdvancedSignature && document.Authentication_Method__c != 'ADVANCED_ELECTRONIC') {
            compliant = false;
            result.validationDetails.add(new ValidationDetail('ADVANCED_SIGNATURE_REQUIRED', 'HIGH', config.jurisdiction + ' requires advanced electronic signatures', 'Upgrade authentication method to advanced electronic signature'));
        }
        return compliant;
    }

    // CORRECTED: All markdown syntax like [document.Legal] was removed from the methods below.
    private static Boolean validateAuthenticationRequirements(DocumentLifecycleConfiguration__c document, JurisdictionConfig config, SingleJurisdictionResult result) {
        Boolean compliant = true;
        switch on config.jurisdiction {
            when 'EU' {
                if (!document.Legal_Requirements__c?.contains('eIDAS')) {
                    compliant = false;
                    result.validationDetails.add(new ValidationDetail('EIDAS_COMPLIANCE', 'HIGH', 'Document must comply with eIDAS regulation', 'Add eIDAS compliance statements and qualified certificates'));
                }
            }
            when 'US' {
                if (!document.Legal_Requirements__c?.contains('ESIGN')) {
                    compliant = false;
                    result.validationDetails.add(new ValidationDetail('ESIGN_COMPLIANCE', 'HIGH', 'Document must comply with E-SIGN Act', 'Add E-SIGN Act compliance statements and consent records'));
                }
            }
            when 'UK' {
                if (!document.Legal_Requirements__c?.contains('ECA_2000')) {
                    compliant = false;
                    result.validationDetails.add(new ValidationDetail('ECA_COMPLIANCE', 'MEDIUM', 'Document should comply with Electronic Communications Act 2000', 'Add ECA 2000 compliance statements'));
                }
            }
            when 'JP' {
                if (config.requiresQualifiedCertificates && !document.Legal_Requirements__c?.contains('QUALIFIED_CERT')) {
                    compliant = false;
                    result.validationDetails.add(new ValidationDetail('QUALIFIED_CERTIFICATE', 'HIGH', 'Japan requires qualified electronic certificates', 'Implement qualified certificate validation'));
                }
            }
        }
        return compliant;
    }

    private static Boolean validateDataRetention(DocumentLifecycleConfiguration__c document, JurisdictionConfig config, SingleJurisdictionResult result) {
        Boolean compliant = true;
        if (String.isBlank(document.Legal_Requirements__c) || !document.Legal_Requirements__c.contains('RETENTION_POLICY')) {
            compliant = false;
            result.validationDetails.add(new ValidationDetail('DATA_RETENTION_POLICY', 'MEDIUM', 'Document lacks a data retention policy for ' + config.jurisdiction, 'Define and implement jurisdiction-specific retention policies'));
        }
        switch on config.jurisdiction {
            when 'EU' {
                if (!document.Legal_Requirements__c?.contains('GDPR_RETENTION')) {
                    compliant = false;
                    result.validationDetails.add(new ValidationDetail('GDPR_RETENTION', 'HIGH', 'GDPR requires specific data retention and deletion policies', 'Implement GDPR-compliant retention and right-to-erasure procedures'));
                }
            }
            when 'US' {
                if (document.Contract_Type__c == 'Financial' && !document.Legal_Requirements__c?.contains('SOX_RETENTION')) {
                    compliant = false;
                    result.validationDetails.add(new ValidationDetail('SOX_RETENTION', 'HIGH', 'Financial documents require SOX-compliant retention', 'Implement 7-year retention policy for financial documents'));
                }
            }
        }
        return compliant;
    }

    private static Boolean validateLegalFramework(DocumentLifecycleConfiguration__c document, JurisdictionConfig config, String contractType, SingleJurisdictionResult result) {
        Boolean compliant = true;
        switch on contractType {
            when 'Employment' { compliant = validateEmploymentContractCompliance(document, config, result); }
            when 'Financial' { compliant = validateFinancialContractCompliance(document, config, result); }
            when 'Healthcare' { compliant = validateHealthcareContractCompliance(document, config, result); }
            when 'Real_Estate' { compliant = validateRealEstateContractCompliance(document, config, result); }
        }
        return compliant;
    }

    private static Boolean validateEmploymentContractCompliance(DocumentLifecycleConfiguration__c document, JurisdictionConfig config, SingleJurisdictionResult result) {
        Boolean compliant = true;
        switch on config.jurisdiction {
            when 'EU' {
                if (!document.Legal_Requirements__c?.contains('EU_EMPLOYMENT_DIRECTIVE')) {
                    compliant = false;
                    result.validationDetails.add(new ValidationDetail('EU_EMPLOYMENT_COMPLIANCE', 'HIGH', 'Employment contracts must comply with EU Employment Directive', 'Add EU Employment Directive compliance clauses'));
                }
            }
            when 'US' {
                if (!document.Legal_Requirements__c?.contains('FLSA_COMPLIANCE')) {
                    compliant = false;
                    result.validationDetails.add(new ValidationDetail('US_EMPLOYMENT_COMPLIANCE', 'MEDIUM', 'Employment contracts should reference FLSA compliance', 'Add Fair Labor Standards Act compliance statements'));
                }
            }
            when 'UK' {
                if (!document.Legal_Requirements__c?.contains('EMPLOYMENT_RIGHTS_ACT')) {
                    compliant = false;
                    result.validationDetails.add(new ValidationDetail('UK_EMPLOYMENT_COMPLIANCE', 'HIGH', 'Employment contracts must comply with Employment Rights Act', 'Add Employment Rights Act compliance clauses'));
                }
            }
        }
        return compliant;
    }

    private static Boolean validateFinancialContractCompliance(DocumentLifecycleConfiguration__c document, JurisdictionConfig config, SingleJurisdictionResult result) {
        Boolean compliant = true;
        switch on config.jurisdiction {
            when 'US' {
                if (!document.Legal_Requirements__c?.contains('SOX_COMPLIANCE')) {
                    compliant = false;
                    result.validationDetails.add(new ValidationDetail('SOX_COMPLIANCE', 'HIGH', 'Financial contracts require Sarbanes-Oxley compliance', 'Implement SOX-compliant controls and audit trails'));
                }
            }
            when 'EU' {
                if (!document.Legal_Requirements__c?.contains('MIFID_II')) {
                    compliant = false;
                    result.validationDetails.add(new ValidationDetail('MIFID_II_COMPLIANCE', 'HIGH', 'Financial contracts must comply with MiFID II', 'Add MiFID II compliance and disclosure requirements'));
                }
            }
        }
        return compliant;
    }

    private static Boolean validateHealthcareContractCompliance(DocumentLifecycleConfiguration__c document, JurisdictionConfig config, SingleJurisdictionResult result) {
        Boolean compliant = true;
        switch on config.jurisdiction {
            when 'US' {
                if (!document.Legal_Requirements__c?.contains('HIPAA_COMPLIANCE')) {
                    compliant = false;
                    result.validationDetails.add(new ValidationDetail('HIPAA_COMPLIANCE', 'HIGH', 'Healthcare contracts require HIPAA compliance', 'Implement HIPAA-compliant data handling and security measures'));
                }
            }
            when 'EU' {
                if (!document.Legal_Requirements__c?.contains('MDR_COMPLIANCE')) {
                    compliant = false;
                    result.validationDetails.add(new ValidationDetail('MDR_COMPLIANCE', 'HIGH', 'Healthcare contracts must comply with Medical Device Regulation', 'Add MDR compliance statements for medical devices'));
                }
            }
        }
        return compliant;
    }

    private static Boolean validateRealEstateContractCompliance(DocumentLifecycleConfiguration__c document, JurisdictionConfig config, SingleJurisdictionResult result) {
        Boolean compliant = true;
        switch on config.jurisdiction {
            when 'US' {
                if (!document.Legal_Requirements__c?.contains('TRID_COMPLIANCE')) {
                    compliant = false;
                    result.validationDetails.add(new ValidationDetail('TRID_COMPLIANCE', 'HIGH', 'Real estate contracts require TRID compliance', 'Implement TILA-RESPA Integrated Disclosure requirements'));
                }
            }
        }
        return compliant;
    }

    private static Boolean validateCrossBorderTransfer(DocumentLifecycleConfiguration__c document, JurisdictionConfig config, SingleJurisdictionResult result) {
        Boolean compliant = true;
        if (config.jurisdiction == 'EU' && document.Region__c != 'EU') {
            if (!document.Legal_Requirements__c?.contains('ADEQUACY_DECISION') && !document.Legal_Requirements__c?.contains('STANDARD_CONTRACTUAL_CLAUSES')) {
                compliant = false;
                result.validationDetails.add(new ValidationDetail('CROSS_BORDER_TRANSFER', 'HIGH', 'Cross-border data transfer from EU requires an adequacy decision or SCCs', 'Implement Standard Contractual Clauses or ensure an adequacy decision is in place'));
            }
        }
        return compliant;
    }

    private static Decimal calculateJurisdictionScore(List<ValidationDetail> details) {
        if (details.isEmpty()) {
            return 100.0;
        }
        Decimal totalDeductions = 0;
        for (ValidationDetail detail : details) {
            switch on detail.severity {
                when 'HIGH' { totalDeductions += 25; }
                when 'MEDIUM' { totalDeductions += 15; }
                when 'LOW' { totalDeductions += 5; }
            }
        }
        return Math.max(0, 100 - totalDeductions);
    }

    private static Decimal calculateMultiJurisdictionScore(Map<String, SingleJurisdictionResult> results) {
        if (results.isEmpty()) {
            return 0;
        }
        Decimal totalScore = 0;
        for (SingleJurisdictionResult result : results.values()) {
            totalScore += result.complianceScore;
        }
        return totalScore / results.size();
    }

    private static void storeJurisdictionValidation(JurisdictionValidationResult result) {
        Multi_Jurisdiction_Validation__c validationRecord = new Multi_Jurisdiction_Validation__c(
            Document_Id__c = result.documentId,
            Validation_Timestamp__c = result.validationTimestamp,
            Overall_Compliance__c = result.overallCompliance,
            Compliance_Score__c = result.complianceScore,
            Jurisdictions_Tested__c = String.join(new List<String>(result.jurisdictionResults.keySet()), ','),
            Validation_Data__c = JSON.serialize(result)
        );
        insert validationRecord;
    }

    private static JurisdictionValidationResult getDefaultValidationResult() {
        JurisdictionValidationResult defaultResult = new JurisdictionValidationResult();
        defaultResult.overallCompliance = false;
        defaultResult.complianceScore = 0;
        defaultResult.jurisdictionResults = new Map<String, SingleJurisdictionResult>();
        return defaultResult;
    }

    // Data Classes for Multi-Jurisdiction Framework
    public class JurisdictionConfig {
        public String jurisdiction;
        public String legalFramework;
        public Boolean requiresAdvancedSignature;
        public String requiredEncryption;
        public Integer frameworkYear;
        public Boolean requiresQualifiedCertificates;
        public JurisdictionConfig(String jurisdiction, String framework, Boolean advanced, String encryption, Integer year, Boolean qualified) {
            this.jurisdiction = jurisdiction;
            this.legalFramework = framework;
            this.requiresAdvancedSignature = advanced;
            this.requiredEncryption = encryption;
            this.frameworkYear = year;
            this.requiresQualifiedCertificates = qualified;
        }
    }

    public class JurisdictionValidationResult {
        @AuraEnabled public String documentId;
        @AuraEnabled public DateTime validationTimestamp;
        @AuraEnabled public Boolean overallCompliance;
        @AuraEnabled public Decimal complianceScore;
        @AuraEnabled public Map<String, SingleJurisdictionResult> jurisdictionResults;
    }

    public class SingleJurisdictionResult {
        @AuraEnabled public String jurisdiction;
        @AuraEnabled public Boolean isCompliant;
        @AuraEnabled public Decimal complianceScore;
        @AuraEnabled public List<ValidationDetail> validationDetails;
    }

    public class ValidationDetail {
        @AuraEnabled public String violationType;
        @AuraEnabled public String severity;
        @AuraEnabled public String description;
        @AuraEnabled public String recommendation;
        public ValidationDetail(String type, String severity, String description, String recommendation) {
            this.violationType = type;
            this.severity = severity;
            this.description = description;
            this.recommendation = recommendation;
        }
    }
}
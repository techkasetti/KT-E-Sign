            public class DocumentLifecycleDeploymentManager {
                
                public static void initializeCompleteSystem() {
                    try {
                        // Create default configurations
                        List<DocumentLifecycleConfiguration__c> defaultConfigs = new List<DocumentLifecycleConfiguration__c>();
                        
                        // US Configuration
                        defaultConfigs.add(new DocumentLifecycleConfiguration__c(
                            Region__c = 'US',
                        Role__c = 'Employee',
                        ContractType__c = 'Employment',
                        DocumentTitle__c = 'Default US Employment Agreement',
                        GeneratedClause__c = 'Standard US employment terms and conditions apply.',
                        ComplianceStatus__c = 'Compliant',
                        ProcessingStatus__c = 'Completed',
                        OutputFormat__c = 'PDF'
                            ));
                        
                        // EU Configuration
                        defaultConfigs.add(new DocumentLifecycleConfiguration__c(
                            Region__c = 'EU',
                        Role__c = 'Employee',
                        ContractType__c = 'Employment',
                        DocumentTitle__c = 'Default EU Employment Agreement',
                        GeneratedClause__c = 'Standard EU employment terms and GDPR compliance clauses apply.',
                        ComplianceStatus__c = 'Compliant',
                        ProcessingStatus__c = 'Completed',
                        OutputFormat__c = 'PDF'
                            ));
                        
                        insert defaultConfigs;
                        
                        // Initialize audit trail
                        AuditTrailManager.logSystemActivity('System Initialization', 'Default configurations created');
                        
                        System.debug('✓ System initialized successfully');
                        
                    } catch (Exception e) {
                        System.debug('❌ System initialization failed: ' + e.getMessage());
                        throw new AuraHandledException('System initialization failed: ' + e.getMessage());
                    }
                }
            
            
        //     Version 0 ............
        //         try {
        //                 createSystemConfigurations();
        //                 createDefaultPolicies();
        //                 setupMonitoringSchedules();
        //                 logInitialization();
        //                 System.debug('✓ System initialization completed successfully');
        //         } catch (Exception e) {
        //                 System.debug('✗ System initialization failed: ' + e.getMessage());
        //                 throw e;
        //         }
        // }
        
        private static void createSystemConfigurations() {
            List<DocumentLifecycleConfiguration__c> configs = new List<DocumentLifecycleConfiguration__c>();
            
            configs.add(new DocumentLifecycleConfiguration__c(
                Region__c = 'US',
            Role__c = 'Manager',
            ContractType__c = 'Employment',
            ComplianceStatus__c = 'Compliant',
            OutputFormat__c = 'PDF',
            ProcessingStatus__c = 'ACTIVE'
                ));
            
            configs.add(new DocumentLifecycleConfiguration__c(
                Region__c = 'EU',
            Role__c = 'Employee',
            ContractType__c = 'NDA',
            ComplianceStatus__c = 'Compliant',
            OutputFormat__c = 'PDF',
            ProcessingStatus__c = 'ACTIVE'
                ));
            
            insert configs;
            System.debug('✓ Created ' + configs.size() + ' system configurations');
        }
        
        private static void createDefaultPolicies() {
            // This method will be expanded in future phases
            System.debug('✓ Default policies configured');
        }
        
        private static void setupMonitoringSchedules() {
            // This method will be expanded in future phases
            System.debug('✓ Monitoring schedules configured');
        }
        
        private static void logInitialization() {
            AuditTrail__c audit = new AuditTrail__c(
                RecordId__c = UserInfo.getOrganizationId(),
            Action__c = 'SYSTEM_INITIALIZATION',
            Status__c = 'SUCCESS',
            Details__c = 'Document lifecycle system initialized successfully',
            UserId__c = UserInfo.getUserId()
                );
            insert audit;
            System.debug('✓ System initialization logged');
        }
        @AuraEnabled
        public static String generateDocument(String region, String role, String contractType, String title) {
            try {
                // Create document configuration
                DocumentLifecycleConfiguration__c config = new DocumentLifecycleConfiguration__c(
                    Region__c = region,
                Role__c = role,
                ContractType__c = contractType,
                DocumentTitle__c = title,
                ProcessingStatus__c = 'Processing',
                OutputFormat__c = 'PDF'
                    );
                
                // Generate clause based on parameters
                String generatedClause = generateClause(region, role, contractType);
                config.GeneratedClause__c = generatedClause;
                
                // Validate compliance
                ComplianceChecker checker = new ComplianceChecker();
                Boolean isCompliant = checker.validateClause(generatedClause);
                
                if (isCompliant) {
                    config.ProcessingStatus__c = 'Completed';
                    insert config;
                    return config.Id;
                } else {
                    throw new AuraHandledException('Document failed compliance validation');
                }
                
            } catch (Exception e) {
                throw new AuraHandledException('Error generating document: ' + e.getMessage());
            }
        }
        public static String generateDocument(String region, String role, String contractType, String documentTitle) {
            try {
                System.debug('Starting document generation for: ' + documentTitle);
                
                // Create document configuration
                DocumentLifecycleConfiguration__c config = new DocumentLifecycleConfiguration__c(
                    Region__c = region,
                Role__c = role,
                ContractType__c = contractType,
                DocumentTitle__c = documentTitle,
                ProcessingStatus__c = 'Processing',
                ComplianceStatus__c = 'Pending'
                    );
                
                // Generate clause using ClauseGenerator
                String generatedClause = ClauseGenerator.generateClause(region, role, contractType);
                config.GeneratedClause__c = generatedClause;
                
                // Validate compliance
                Boolean isCompliant = ComplianceChecker.validateClause(generatedClause, region, contractType);
                config.ComplianceStatus__c = isCompliant ? 'Compliant' : 'Non-Compliant';
                config.ProcessingStatus__c = 'Completed';
                config.OutputFormat__c = 'PDF';
                
                insert config;
                
                // Log audit trail
                AuditTrailManager.logDocumentActivity(
                    config.Id,
                'Document Generated',
                'Document created with title: ' + documentTitle
                    );
                
                System.debug('✓ Document generated successfully: ' + config.Id);
                return config.Id;
                
            } catch (Exception e) {
                System.debug('❌ Error generating document: ' + e.getMessage());
                throw new AuraHandledException('Failed to generate document: ' + e.getMessage());
            }
        }
        
        
        
        // Version 1...........
        //     PerformanceMonitor.startTracking('DOCUMENT_GENERATION');
        
        //     try {
            //         // Existing document generation code...
            //         String documentId = createDocumentRecord(region, role, contractType, documentTitle, generatedClause);
            
            //         PerformanceMonitor.endTracking('DOCUMENT_GENERATION');
            //         return documentId;
            
        //     } catch (Exception e) {
            //         PerformanceMonitor.endTrackingWithError('DOCUMENT_GENERATION', '', e.getMessage());
            //         throw e;
        //     }
    // }
    
    private static String generateClause(String region, String role, String contractType) {
        String baseClause = 'This ' + contractType + ' agreement is executed in the ' + region + ' region ';
        baseClause += 'for the role of ' + role + '. ';
        baseClause += 'By signing this document, all parties agree to the terms and conditions outlined herein. ';
        baseClause += 'This agreement requires electronic signature for legal validity. ';
        baseClause += 'Signature required to complete this document processing.';
        
        return baseClause;
    }
        @AuraEnabled
    public static DocumentGenerationResult generateDocument(String region, String role, String contractType, String documentTitle) {
        DocumentGenerationResult result = new DocumentGenerationResult();
        
        try {
            // Generate clause using ClauseGenerator
            String generatedClause = ClauseGenerator.generateClause(region, role, contractType);
            
            // Validate compliance using ComplianceChecker  
            Boolean isCompliant = ComplianceChecker.validateClause(generatedClause, region, contractType);
            
            // Create DocumentLifecycleConfiguration record
            DocumentLifecycleConfiguration__c config = new DocumentLifecycleConfiguration__c(
                Region__c = region,
                Role__c = role,
                ContractType__c = contractType,
                DocumentTitle__c = documentTitle,
                GeneratedClause__c = generatedClause,
                ComplianceStatus__c = isCompliant ? 'Compliant' : 'Non-Compliant'
            );
            insert config;
            
            // Log activity
            AuditTrailManager.logDocumentActivity(config.Id, 'DOCUMENT_GENERATED', 'SUCCESS', 'Document generated successfully');
            
            result.success = true;
            result.documentId = config.Id;
            result.generatedClause = generatedClause;
            result.complianceStatus = config.ComplianceStatus__c;
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
        }
        
        return result;
    }

        public class DocumentGenerationResult {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String documentId;
        @AuraEnabled public String generatedClause;
        @AuraEnabled public String complianceStatus;
        @AuraEnabled public String errorMessage;
    }

}
public class DocumentLifecycleDeploymentManager {
//updated
    /**
     * Main system initialization method
     * Creates configurations, policies, schedules, and audit logs
     */
    public static String initializeCompleteSystem() {
        try {
            System.debug('Starting DocGen system initialization...');
            
            createSystemConfigurations();
            createDefaultPolicies();
            setupMonitoringSchedules();
            logInitialization();
            
            System.debug('✓ DocGen system initialization completed successfully');
            return 'System initialized successfully';
            
        } catch (Exception e) {
            System.debug('✗ System initialization failed: ' + e.getMessage());
            logInitializationError(e.getMessage());
            throw new AuraHandledException('System initialization failed: ' + e.getMessage());
        }
    }
    //old
    // public static void initializeCompleteSystem() {
    //     try {
    //         // Create default configurations
    //         List<DocumentLifecycleConfiguration__c> defaultConfigs = new List<DocumentLifecycleConfiguration__c>();
            
    //         // US Configuration
    //         defaultConfigs.add(new DocumentLifecycleConfiguration__c(
    //             Region__c = 'US',
    //         Role__c = 'Employee',
    //         ContractType__c = 'Employment',
    //         DocumentTitle__c = 'Default US Employment Agreement',
    //         GeneratedClause__c = 'Standard US employment terms and conditions apply.',
    //         ComplianceStatus__c = 'Compliant',
    //         ProcessingStatus__c = 'Completed',
    //         OutputFormat__c = 'PDF'
    //             ));
            
    //         // EU Configuration
    //         defaultConfigs.add(new DocumentLifecycleConfiguration__c(
    //             Region__c = 'EU',
    //         Role__c = 'Employee',
    //         ContractType__c = 'Employment',
    //         DocumentTitle__c = 'Default EU Employment Agreement',
    //         GeneratedClause__c = 'Standard EU employment terms and GDPR compliance clauses apply.',
    //         ComplianceStatus__c = 'Compliant',
    //         ProcessingStatus__c = 'Completed',
    //         OutputFormat__c = 'PDF'
    //             ));
            
    //         insert defaultConfigs;
            
    //         // Initialize audit trail
    //         AuditTrailManager.logSystemActivity('System Initialization', 'Default configurations created');
            
    //         System.debug('✓ System initialized successfully');
            
    //     } catch (Exception e) {
    //         System.debug('❌ System initialization failed: ' + e.getMessage());
    //         throw new AuraHandledException('System initialization failed: ' + e.getMessage());
    //     }
    // }

            
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
        
        //updated(from 3 last 3 files)
    /**
     * Create default system configurations for different regions and roles
     */
    @TestVisible
    private static void createSystemConfigurations() {
        List<DocumentLifecycleConfiguration__c> configs = new List<DocumentLifecycleConfiguration__c>();
        
        // US Manager Configuration
        configs.add(new DocumentLifecycleConfiguration__c(
            Region__c = 'US',
            Role__c = 'Manager', 
            ContractType__c = 'Employment',
            ComplianceStatus__c = 'Compliant',
            OutputFormat__c = 'PDF',
            RetentionPeriod__c = 2555, // 7 years
            AIProcessingEnabled__c = true
        ));
        
        // EU Employee Configuration  
        configs.add(new DocumentLifecycleConfiguration__c(
            Region__c = 'EU',
            Role__c = 'Employee',
            ContractType__c = 'Employment', 
            ComplianceStatus__c = 'Compliant',
            OutputFormat__c = 'PDF',
            RetentionPeriod__c = 2555,
            AIProcessingEnabled__c = true
        ));
        
        // APAC NDA Configuration
        configs.add(new DocumentLifecycleConfiguration__c(
            Region__c = 'APAC',
            Role__c = 'Developer',
            ContractType__c = 'NDA',
            ComplianceStatus__c = 'Under Review',
            OutputFormat__c = 'DOCX',
            RetentionPeriod__c = 1825, // 5 years
            AIProcessingEnabled__c = true
        ));
        
        insert configs;
        System.debug('✓ Created ' + configs.size() + ' system configurations');
    }
    //old
        // private static void createSystemConfigurations() {
        //     List<DocumentLifecycleConfiguration__c> configs = new List<DocumentLifecycleConfiguration__c>();
            
        //     configs.add(new DocumentLifecycleConfiguration__c(
        //         Region__c = 'US',
        //     Role__c = 'Manager',
        //     ContractType__c = 'Employment',
        //     ComplianceStatus__c = 'Compliant',
        //     OutputFormat__c = 'PDF',
        //     ProcessingStatus__c = 'ACTIVE'
        //         ));
            
        //     configs.add(new DocumentLifecycleConfiguration__c(
        //         Region__c = 'EU',
        //     Role__c = 'Employee',
        //     ContractType__c = 'NDA',
        //     ComplianceStatus__c = 'Compliant',
        //     OutputFormat__c = 'PDF',
        //     ProcessingStatus__c = 'ACTIVE'
        //         ));
            
        //     insert configs;
        //     System.debug('✓ Created ' + configs.size() + ' system configurations');
        // }
        
    // private static void createDefaultPolicies() {
    //     // This method will be expanded in future phases
    //     System.debug('✓ Default policies configured');
    // }
    /**
     * Create default retention policies for different document types
     */
    @TestVisible
    private static void createDefaultPolicies() {
        List<RetentionPolicy__c> policies = new List<RetentionPolicy__c>();
        
        // Standard Employment Documents Policy
        policies.add(new RetentionPolicy__c(
            Name = 'Standard Employment Policy',
            RetentionPeriod__c = 2555, // 7 years in days
            AutoDelete__c = false,
            Region__c = 'US',
            DocumentType__c = 'Employment'
        ));
        
        // GDPR Personal Data Policy  
        policies.add(new RetentionPolicy__c(
            Name = 'GDPR Personal Data Policy',
            RetentionPeriod__c = 1095, // 3 years
            AutoDelete__c = true,
            Region__c = 'EU', 
            DocumentType__c = 'Personal Data'
        ));
        
        // Financial Records Policy
        policies.add(new RetentionPolicy__c(
            Name = 'Financial Records Policy',
            RetentionPeriod__c = 2555, // 7 years
            AutoDelete__c = false,
            Region__c = 'Global',
            DocumentType__c = 'Financial'
        ));
        
        insert policies;
        System.debug('✓ Created ' + policies.size() + ' retention policies');
    }
    
    // private static void setupMonitoringSchedules() {
    //     // This method will be expanded in future phases
    //     System.debug('✓ Monitoring schedules configured');
    // }
    /**
     * Setup monitoring and scheduled jobs
     */
    @TestVisible  
    private static void setupMonitoringSchedules() {
        try {
            // Schedule document expiration monitoring (daily at 2 AM)
            String cronExp = '0 0 2 * * ?';
            String jobName = 'DocGen_Daily_Monitoring';
                    // Check if job already exists
        List<CronTrigger> existingJobs = [
            SELECT Id, CronJobDetail.Name 
            FROM CronTrigger 
            WHERE CronJobDetail.Name LIKE 'DocGen_Daily_Monitoring%'
            AND State != 'DELETED'
        ];
        
        if (existingJobs.isEmpty()) {
            System.schedule(jobName, cronExp, new DocumentExpirationMonitor());
            System.debug('✓ Scheduled document expiration monitoring job');
        } else {
            System.debug('⚠ Monitoring job already exists, skipping schedule');
        }
        
        // Initialize cache warmup
        DocumentCacheManager.warmupCache();
        
        } catch (Exception e) {
            System.debug('⚠ Warning: Could not setup monitoring schedules: ' + e.getMessage());
            // Don't fail initialization for monitoring setup issues
        }
    }
    //updated(from 3 last 3 files)
    /**
     * Log successful system initialization
     */
    @TestVisible
    private static void logInitialization() {
        AuditTrail__c auditLog = new AuditTrail__c(
            Action__c = 'SYSTEM_INITIALIZATION',
            Status__c = 'SUCCESS',
            Timestamp__c = DateTime.now(),
            UserDetails__c = UserInfo.getName() + ' (' + UserInfo.getUsername() + ')',
            SystemInfo__c = 'DocGen v1.0 initialized successfully',
            AdditionalData__c = JSON.serialize(new Map<String, Object>{
                'version' => '1.0',
                'timestamp' => DateTime.now().format(),
                'user' => UserInfo.getUserId(),
                'org' => UserInfo.getOrganizationId()
            })
        );
        
        insert auditLog;
        System.debug('✓ System initialization logged successfully');
    }
    //old
    // private static void logInitialization() {
    //     AuditTrail__c audit = new AuditTrail__c(
    //         RecordId__c = UserInfo.getOrganizationId(),
    //     Action__c = 'SYSTEM_INITIALIZATION',
    //     Status__c = 'SUCCESS',
    //     Details__c = 'Document lifecycle system initialized successfully',
    //     UserId__c = UserInfo.getUserId()
    //         );
    //     insert audit;
    //     System.debug('✓ System initialization logged');
    // }
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
    /**
     * Log initialization errors
     */
    @TestVisible
    private static void logInitializationError(String errorMessage) {
        try {
            AuditTrail__c errorLog = new AuditTrail__c(
                Action__c = 'SYSTEM_INITIALIZATION',
                Status__c = 'ERROR',
                Timestamp__c = DateTime.now(),
                UserDetails__c = UserInfo.getName() + ' (' + UserInfo.getUsername() + ')',
                SystemInfo__c = 'DocGen initialization failed: ' + errorMessage,
                AdditionalData__c = errorMessage
            );
            
            insert errorLog;
        } catch (Exception e) {
            System.debug('✗ Could not log initialization error: ' + e.getMessage());
        }
    }
    /**
     * Get system health status
     */
    public static Map<String, Object> getSystemHealth() {
        Map<String, Object> healthStatus = new Map<String, Object>();
        
        try {
            // Check configurations
            Integer configCount = [SELECT COUNT() FROM DocumentLifecycleConfiguration__c];
            healthStatus.put('configurations_count', configCount);
            healthStatus.put('configurations_healthy', configCount >= 3);
            
            // Check policies
            Integer policyCount = [SELECT COUNT() FROM RetentionPolicy__c];
            healthStatus.put('policies_count', policyCount);
            healthStatus.put('policies_healthy', policyCount >= 2);
            
            // Check audit trail
            Integer auditCount = [SELECT COUNT() FROM AuditTrail__c WHERE CreatedDate = TODAY];
            healthStatus.put('daily_audit_count', auditCount);
            healthStatus.put('audit_healthy', true);
            
            // Overall system health
            Boolean overallHealth = (Boolean)healthStatus.get('configurations_healthy') && 
                                (Boolean)healthStatus.get('policies_healthy') && 
                                (Boolean)healthStatus.get('audit_healthy');
            
            healthStatus.put('overall_health', overallHealth);
            healthStatus.put('last_check', DateTime.now());
            
            System.debug('✓ System health check completed: ' + (overallHealth ? 'HEALTHY' : 'UNHEALTHY'));
            
        } catch (Exception e) {
            healthStatus.put('overall_health', false);
            healthStatus.put('error', e.getMessage());
            System.debug('✗ System health check failed: ' + e.getMessage());
        }
        
        return healthStatus;
    }
    /**
     * Reset system to defaults (use with caution)
     */
    public static void resetSystemToDefaults() {
        System.debug('⚠ RESETTING SYSTEM TO DEFAULTS - THIS WILL DELETE DATA');
        
        try {
            // Delete existing configurations (this will cascade to related records)
            delete [SELECT Id FROM DocumentLifecycleConfiguration__c];
            delete [SELECT Id FROM RetentionPolicy__c];
            delete [SELECT Id FROM AuditTrail__c WHERE Action__c = 'SYSTEM_INITIALIZATION'];
            
            System.debug('✓ Existing data cleared');
            
            // Reinitialize system
            initializeCompleteSystem();
            
            System.debug('✓ System reset to defaults completed');
            
        } catch (Exception e) {
            System.debug('✗ System reset failed: ' + e.getMessage());
            throw new AuraHandledException('System reset failed: ' + e.getMessage());
        }
    }
}








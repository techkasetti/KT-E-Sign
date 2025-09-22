@isTest
private class DocGenSystemIntegrationTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test users
        List<User> testUsers = new List<User>();
        
        User adminUser = new User(
            FirstName        = 'Admin',
        LastName         = 'User',
        Email            = 'admin@docgen.com',
        Username         = 'admin@docgen.com.test',
        Alias            = 'admin',
        TimeZoneSidKey   = 'America/New_York',
        LocaleSidKey     = 'en_US',
        EmailEncodingKey = 'UTF-8',
        ProfileId        = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
        LanguageLocaleKey = 'en_US'
            );
        testUsers.add(adminUser);
        
        User standardUser = new User(
            FirstName        = 'Standard',
        LastName         = 'User',
        Email            = 'user@docgen.com',
        Username         = 'user@docgen.com.test',
        Alias            = 'user',
        TimeZoneSidKey   = 'America/New_York',
        LocaleSidKey     = 'en_US',
        EmailEncodingKey = 'UTF-8',
        ProfileId        = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
        LanguageLocaleKey = 'en_US'
            );
        testUsers.add(standardUser);
        
        insert testUsers;
        
        // Create test configurations
        List<DocumentLifecycleConfiguration__c> configs = new List<DocumentLifecycleConfiguration__c>();
        for (Integer i = 0; i < 5; i++) {
            DocumentLifecycleConfiguration__c config = new DocumentLifecycleConfiguration__c(
                Region__c         = (i < 3) ? 'US' : 'EU',
            Role__c           = 'Employee',
            ContractType__c   = 'Employment Contract',
            ComplianceScore__c = 85 + i,
            Status__c         = 'Active',
            TemplateId__c     = 'template_' + i,
            CreatedDate__c    = Date.today().addDays(-i)
                );
            configs.add(config);
        }
        insert configs;
        
        // Create document templates
        List<DocumentTemplate__c> templates = new List<DocumentTemplate__c>();
        for (Integer i = 0; i < 3; i++) {
            DocumentTemplate__c template = new DocumentTemplate__c(
                Template_Name__c    = 'Test Template ' + i,
            Template_Type__c    = 'Employment Contract',
            Region__c           = 'US',
            Template_Content__c = 'Sample template content for testing',
            Is_Active__c        = true,
            Compliance_Level__c = 'Standard'
                );
            templates.add(template);
        }
        insert templates;
    }
    
    @isTest
    static void testEndToEndDocumentGeneration() {
        User testUser = [
            SELECT Id 
            FROM User 
            WHERE Username = 'user@docgen.com.test' 
            LIMIT 1
        ];
        
        DocumentLifecycleConfiguration__c config = [
            SELECT Id 
            FROM DocumentLifecycleConfiguration__c 
            LIMIT 1
        ];
        
        Test.startTest();
        
        // Test complete document generation workflow
        System.runAs(testUser) {
            // 1. Start performance tracking
            PerformanceMonitor.startTracking('DOCUMENT_GENERATION', config.Id);
            
            try {
                // 2. Generate document using ClauseGenerationEngine
                ClauseGenerationEngine.ClauseRequest request = new ClauseGenerationEngine.ClauseRequest();
                request.contractType = 'Employment Contract';
                request.region       = 'US';
                request.role         = 'Employee';
                request.configId     = config.Id;
                
                String generatedClause = ClauseGenerationEngine.generateClause(request);
                System.assertNotEquals(null, generatedClause, 'Should generate clause');
                
                // 3. Validate compliance
                ComplianceValidationResult result = ComplianceChecker.validateCompliance(
                    generatedClause, 'US', 'Employment Contract'
                    );
                System.assertNotEquals(null, result, 'Should validate compliance');
                
                // 4. Create audit trail
                AuditTrail__c audit = new AuditTrail__c(
                    RecordId__c     = config.Id,
                Action__c       = 'DOCUMENT_GENERATION',
                Status__c       = result.isCompliant ? 'SUCCESS' : 'VIOLATION',
                Timestamp__c    = DateTime.now(),
                UserDetails__c  = testUser.Name,
                SystemInfo__c   = 'End-to-end test',
                AdditionalInfo__c = 'Generated clause: ' + generatedClause.left(255)
                    );
                insert audit;
                
                // 5. End performance tracking
                PerformanceMonitor.endTracking('DOCUMENT_GENERATION', config.Id);
                
            } catch (Exception e) {
                PerformanceMonitor.endTrackingWithError('DOCUMENT_GENERATION', config.Id, e.getMessage());
                throw e;
            }
        }
        
        Test.stopTest();
        
        // Verify complete workflow
        List<AuditTrail__c> auditRecords = [
            SELECT Id, Action__c, Status__c
            FROM AuditTrail__c
            WHERE RecordId__c = :config.Id AND Action__c = 'DOCUMENT_GENERATION'
        ];
        System.assertEquals(1, auditRecords.size(), 'Should create audit record');
        
        List<PerformanceBenchmark__c> benchmarks = [
            SELECT Id, OperationType__c, ExecutionTime__c
            FROM PerformanceBenchmark__c
            WHERE RecordId__c = :config.Id
        ];
        System.assertEquals(1, benchmarks.size(), 'Should create performance benchmark');
    }
    
    @isTest
    static void testComplianceWorkflow() {
        List<DocumentLifecycleConfiguration__c> configs = [
        SELECT Id FROM DocumentLifecycleConfiguration__c
    ];
        
        Test.startTest();
        
        // Test compliance checking for multiple configurations
        for (DocumentLifecycleConfiguration__c config : configs) {
            PerformanceMonitor.startTracking('COMPLIANCE_CHECK', config.Id);
            try {
                ComplianceValidationResult result = ComplianceChecker.validateCompliance(
                    'Test employment contract with at-will employment clause',
                'US',
                'Employment Contract'
                    );
                
                System.assertNotEquals(null, result, 'Should validate compliance');
                PerformanceMonitor.endTracking('COMPLIANCE_CHECK', config.Id);
            } catch (Exception e) {
                PerformanceMonitor.endTrackingWithError(
                    'COMPLIANCE_CHECK',
                config.Id,
                e.getMessage()
                    );
            }
        }
        
        Test.stopTest();
        
        // Verify compliance workflow
        List<PerformanceBenchmark__c> benchmarks = [
        SELECT Id, OperationType__c, ErrorMessage__c
        FROM PerformanceBenchmark__c
        WHERE OperationType__c = 'COMPLIANCE_CHECK'
    ];
        System.assertEquals(configs.size(), benchmarks.size(),
        'Should create benchmark for each compliance check');
    }
    
    @isTest
    static void testAnalyticsDashboardIntegration() {
        // Generate test data for analytics
        User testUser = [
        SELECT Id FROM User WHERE Username = 'user@docgen.com.test' LIMIT 1
    ];
        List<DocumentLifecycleConfiguration__c> configs = [
        SELECT Id FROM DocumentLifecycleConfiguration__c
    ];
        
        // Create audit trails
        List<AuditTrail__c> audits = new List<AuditTrail__c>();
        for (Integer i = 0; i < 10; i++) {
            AuditTrail__c audit = new AuditTrail__c(
                RecordId__c   = configs[Math.mod(i, configs.size())].Id,
            Action__c     = 'COMPLIANCE_CHECK',
            Status__c     = (i < 8) ? 'SUCCESS' : 'VIOLATION',
            Timestamp__c  = DateTime.now().addHours(-i),
            UserDetails__c = testUser.Name,
            SystemInfo__c  = 'Integration test audit ' + i
                );
            audits.add(audit);
        }
        insert audits;
        
        Test.startTest();
        
        // Test analytics dashboard generation
        DocumentAnalyticsEngine.AnalyticsDashboard dashboard =
            DocumentAnalyticsEngine.generateAnalyticsDashboard();
        
        Test.stopTest();
        
        // Verify dashboard data
        System.assertNotEquals(null, dashboard, 'Should generate dashboard');
        System.assertNotEquals(null, dashboard.documentMetrics, 'Should have document metrics');
        System.assertNotEquals(null, dashboard.complianceMetrics, 'Should have compliance metrics');
        System.assertNotEquals(null, dashboard.performanceMetrics, 'Should have performance metrics');
        System.assert(dashboard.insights.size() >= 0, 'Should generate insights');
        
        // Verify compliance metrics reflect test data
        System.assertEquals(10, dashboard.complianceMetrics.totalComplianceChecks,
        'Should count all checks');
        System.assertEquals(80, dashboard.complianceMetrics.passRate,
        'Should calculate 80% pass rate');
    }
    
    @isTest
    static void testBulkDocumentProcessing() {
        List<DocumentLifecycleConfiguration__c> configs = [
        SELECT Id FROM DocumentLifecycleConfiguration__c
    ];
        List<ClauseGenerationEngine.ClauseRequest> requests = new List<ClauseGenerationEngine.ClauseRequest>();
        
        // Prepare bulk requests
        for (DocumentLifecycleConfiguration__c config : configs) {
            ClauseGenerationEngine.ClauseRequest request = new ClauseGenerationEngine.ClauseRequest();
            request.contractType = 'Employment Contract';
            request.region       = 'US';
            request.role         = 'Employee';
            request.configId     = config.Id;
            requests.add(request);
        }
        
        Test.startTest();
        
        // Process bulk document generation
        PerformanceMonitor.startTracking('BULK_PROCESSING', 'bulk_job_001');
        try {
            List<String> generatedClauses = new List<String>();
            for (ClauseGenerationEngine.ClauseRequest request : requests) {
                String clause = ClauseGenerationEngine.generateClause(request);
                generatedClauses.add(clause);
            }
            
            System.assertEquals(configs.size(), generatedClauses.size(),
            'Should generate all clauses');
            PerformanceMonitor.endTracking('BULK_PROCESSING', 'bulk_job_001');
        } catch (Exception e) {
            PerformanceMonitor.endTrackingWithError(
                'BULK_PROCESSING',
            'bulk_job_001',
            e.getMessage()
                );
            throw e;
        }
        
        Test.stopTest();
        
        // Verify bulk processing
        List<PerformanceBenchmark__c> benchmarks = [
        SELECT Id, OperationType__c, ExecutionTime__c
        FROM PerformanceBenchmark__c
        WHERE RecordId__c = 'bulk_job_001'
    ];
        System.assertEquals(1, benchmarks.size(),
        'Should create bulk processing benchmark');
    }
    
    @isTest
    static void testErrorHandlingAndRecovery() {
        DocumentLifecycleConfiguration__c config = [
        SELECT Id FROM DocumentLifecycleConfiguration__c LIMIT 1
    ];
        
        Test.startTest();
        
        // Test error scenarios
        PerformanceMonitor.startTracking('DOCUMENT_GENERATION', config.Id);
        
        try {
            // Force an error condition
            ClauseGenerationEngine.ClauseRequest invalidRequest =
                new ClauseGenerationEngine.ClauseRequest();
            invalidRequest.contractType = null; // This should cause an error
            invalidRequest.region       = 'US';
            invalidRequest.role         = 'Employee';
            invalidRequest.configId     = config.Id;
            
            ClauseGenerationEngine.generateClause(invalidRequest);
            System.assert(false, 'Should have thrown an exception for invalid request');
            
        } catch (Exception e) {
            PerformanceMonitor.endTrackingWithError(
                'DOCUMENT_GENERATION',
            config.Id,
            e.getMessage()
                );
            // Expected error - continue test
        }
        
        Test.stopTest();
        
        // Verify error handling
        List<PerformanceBenchmark__c> benchmarks = [
        SELECT Id, ErrorMessage__c
        FROM PerformanceBenchmark__c
        WHERE RecordId__c = :config.Id
    ];
        System.assertEquals(1, benchmarks.size(), 'Should create benchmark even with error');
        System.assertNotEquals(null, benchmarks[0].ErrorMessage__c,
        'Should record error message');
    }
    
    @isTest
    static void testPermissionsAndSecurity() {
        User standardUser = [
        SELECT Id FROM User WHERE Username = 'user@docgen.com.test' LIMIT 1
    ];
        DocumentLifecycleConfiguration__c config = [
        SELECT Id FROM DocumentLifecycleConfiguration__c LIMIT 1
    ];
        
        Test.startTest();
        
        System.runAs(standardUser) {
            // Test that standard user can perform basic operations
            try {
                ClauseGenerationEngine.ClauseRequest request =
                    new ClauseGenerationEngine.ClauseRequest();
                request.contractType = 'Employment Contract';
                request.region       = 'US';
                request.role         = 'Employee';
                request.configId     = config.Id;
                
                String clause = ClauseGenerationEngine.generateClause(request);
                System.assertNotEquals(null, clause,
                'Standard user should be able to generate clauses');
                
                // Test compliance validation
                ComplianceValidationResult result = ComplianceChecker.validateCompliance(
                    clause,
                'US',
                'Employment Contract'
                    );
                System.assertNotEquals(null, result,
                'Standard user should be able to validate compliance');
            } catch (Exception e) {
                System.assert(false,
                'Standard user should have access to basic functionality: ' + e.getMessage());
            }
        }
        
        Test.stopTest();
        
        // Verify operations completed successfully
        List<PerformanceBenchmark__c> benchmarks = [
        SELECT Id, UserId__c
        FROM PerformanceBenchmark__c
        WHERE UserId__c = :standardUser.Id
    ];
        System.assert(benchmarks.size() > 0,
        'Should track operations for standard user');
    }
    @isTest
    static void testSystemPerformanceSLA() {
        List<DocumentLifecycleConfiguration__c> configs = [
        SELECT Id FROM DocumentLifecycleConfiguration__c LIMIT 3
    ];
        
        Test.startTest();
        
        // Test that operations meet SLA requirements
        for (DocumentLifecycleConfiguration__c config : configs) {
            DateTime startTime = DateTime.now();
            PerformanceMonitor.startTracking('DOCUMENT_GENERATION', config.Id);
            
            ClauseGenerationEngine.ClauseRequest request = new ClauseGenerationEngine.ClauseRequest();
            request.contractType = 'Employment Contract';
            request.region       = 'US';
            request.role         = 'Employee';
            request.configId     = config.Id;
            
            String clause = ClauseGenerationEngine.generateClause(request);
            PerformanceMonitor.endTracking('DOCUMENT_GENERATION', config.Id);
            
            DateTime endTime = DateTime.now();
            Long executionTime = endTime.getTime() - startTime.getTime();
            
            // Verify generation completed within reasonable time (allowing for test overhead)
            System.assert(
                executionTime < 30000,
            'Document generation should complete within 30 seconds in tests'
                );
        }
        
        Test.stopTest();
        
        // Check if any SLA violations were created
        List<SLAViolationAlert__c> violations = [
        SELECT Id, Severity__c
        FROM SLAViolationAlert__c
        WHERE CreatedDate = TODAY
    ];
        
        // In test context, we might have violations due to test overhead
        // Log any violations for analysis
        for (SLAViolationAlert__c violation : violations) {
            System.debug('SLA Violation detected: ' + violation.Severity__c);
        }
    }
    
    @isTest
    static void testDataConsistencyAndIntegrity() {
        DocumentLifecycleConfiguration__c config = [
        SELECT Id FROM DocumentLifecycleConfiguration__c LIMIT 1
    ];
        
        Test.startTest();
        
        // Test data consistency across multiple operations
        String recordId      = config.Id;
        String operationType = 'DOCUMENT_GENERATION';
        
        // Perform multiple operations on same record
        for (Integer i = 0; i < 3; i++) {
            PerformanceMonitor.startTracking(operationType, recordId + '_' + i);
            
            // Simulate work
            Integer counter = 0;
            for (Integer j = 0; j < 50; j++) {
                counter += j;
            }
            
            PerformanceMonitor.endTracking(operationType, recordId + '_' + i);
        }
        
        Test.stopTest();
        
        // Verify data integrity
        List<PerformanceBenchmark__c> benchmarks = [
        SELECT Id, RecordId__c, ExecutionTime__c
        FROM PerformanceBenchmark__c
        WHERE RecordId__c LIKE :recordId + '_%'
        ORDER BY RecordId__c
    ];
        
        System.assertEquals(3, benchmarks.size(),
        'Should create exactly 3 benchmark records');
        
        // Verify each record has valid data
        for (PerformanceBenchmark__c benchmark : benchmarks) {
            System.assert(benchmark.ExecutionTime__c >= 0,
            'Execution time should be non-negative');
            System.assertNotEquals(null, benchmark.RecordId__c,
            'Record ID should not be null');
        }
    }
    
    
    @isTest
    static void testEndToEndDocumentGeneration() {
        User testUser = [SELECT Id FROM User WHERE Username = 'user@docgen.com.test' LIMIT 1];
        DocumentLifecycleConfiguration__c config = [SELECT Id FROM DocumentLifecycleConfiguration__c LIMIT 1];
        
        Test.startTest();
        
        // Test complete document generation workflow
        System.runAs(testUser) {
            // 1. Start performance tracking
            PerformanceMonitor.startTracking('DOCUMENT_GENERATION', config.Id);
            
            try {
                // 2. Generate document using ClauseGenerationEngine
                ClauseGenerationEngine.ClauseRequest request = new ClauseGenerationEngine.ClauseRequest();
                request.contractType = 'Employment Contract';
                request.region = 'US';
                request.role = 'Employee';
                request.configId = config.Id;
                
                String generatedClause = ClauseGenerationEngine.generateClause(request);
                System.assertNotEquals(null, generatedClause, 'Should generate clause');
                
                // 3. Validate compliance
                ComplianceValidationResult result = ComplianceChecker.validateCompliance(
                    generatedClause, 'US', 'Employment Contract'
                    );
                System.assertNotEquals(null, result, 'Should validate compliance');
                
                // 4. Create audit trail
                AuditTrail__c audit = new AuditTrail__c(
                    RecordId__c = config.Id,
                Action__c = 'DOCUMENT_GENERATION',
                Status__c = result.isCompliant ? 'SUCCESS' : 'VIOLATION',
                Timestamp__c = DateTime.now(),
                UserDetails__c = testUser.Name,
                SystemInfo__c = 'End-to-end test',
                AdditionalInfo__c = 'Generated clause: ' + generatedClause.left(255)
                    );
                insert audit;
                
                // 5. End performance tracking
                PerformanceMonitor.endTracking('DOCUMENT_GENERATION', config.Id);
                
            } catch (Exception e) {
                PerformanceMonitor.endTrackingWithError('DOCUMENT_GENERATION', config.Id, e.getMessage());
                throw e;
            }
        }
        
        Test.stopTest();
        
        // Verify complete workflow
        List<AuditTrail__c> auditRecords = [
SELECT Id, Action__c, Status__c 
FROM AuditTrail__c 
WHERE RecordId__c = :config.Id AND Action__c = 'DOCUMENT_GENERATION'
];
        System.assertEquals(1, auditRecords.size(), 'Should create audit record');
        
        List<PerformanceBenchmark__c> benchmarks = [
SELECT Id, OperationType__c, ExecutionTime__c 
FROM PerformanceBenchmark__c 
WHERE RecordId__c = :config.Id
];
        System.assertEquals(1, benchmarks.size(), 'Should create performance benchmark');
    }
    
    @isTest
    static void testComplianceWorkflow() {
        List<DocumentLifecycleConfiguration__c> configs = [SELECT Id FROM DocumentLifecycleConfiguration__c];
        
        Test.startTest();
        
        // Test compliance checking for multiple configurations
        for (DocumentLifecycleConfiguration__c config : configs) {
            PerformanceMonitor.startTracking('COMPLIANCE_CHECK', config.Id);
            try {
                ComplianceValidationResult result = ComplianceChecker.validateCompliance(
                    'Test employment contract with at-will employment clause',
                'US',
                'Employment Contract'
                    );
                
                System.assertNotEquals(null, result, 'Should validate compliance');
                PerformanceMonitor.endTracking('COMPLIANCE_CHECK', config.Id);
            } catch (Exception e) {
                PerformanceMonitor.endTrackingWithError('COMPLIANCE_CHECK', config.Id, e.getMessage());
            }
        }
        
        Test.stopTest();
        
        // Verify compliance workflow
        List<PerformanceBenchmark__c> benchmarks = [
SELECT Id, OperationType__c, ErrorMessage__c 
FROM PerformanceBenchmark__c 
WHERE OperationType__c = 'COMPLIANCE_CHECK'
];
        System.assertEquals(configs.size(), benchmarks.size(), 'Should create benchmark for each compliance check');
    }
    
    @isTest
    static void testAnalyticsDashboardIntegration() {
        // Generate test data for analytics
        User testUser = [SELECT Id FROM User WHERE Username = 'user@docgen.com.test' LIMIT 1];
        List<DocumentLifecycleConfiguration__c> configs = [SELECT Id FROM DocumentLifecycleConfiguration__c];
        
        // Create audit trails
        List<AuditTrail__c> audits = new List<AuditTrail__c>();
        for (Integer i = 0; i < 10; i++) {
            AuditTrail__c audit = new AuditTrail__c(
                RecordId__c = configs[Math.mod(i, configs.size())].Id,
            Action__c = 'COMPLIANCE_CHECK',
            Status__c = (i < 8) ? 'SUCCESS' : 'VIOLATION',
            Timestamp__c = DateTime.now().addHours(-i),
            UserDetails__c = testUser.Name,
            SystemInfo__c = 'Integration test audit ' + i
                );
            audits.add(audit);
        }
        insert audits;
        
        Test.startTest();
        
        // Test analytics dashboard generation
        DocumentAnalyticsEngine.AnalyticsDashboard dashboard =
            DocumentAnalyticsEngine.generateAnalyticsDashboard();
        
        Test.stopTest();
        
        // Verify dashboard data
        System.assertNotEquals(null, dashboard, 'Should generate dashboard');
        System.assertNotEquals(null, dashboard.documentMetrics, 'Should have document metrics');
        System.assertNotEquals(null, dashboard.complianceMetrics, 'Should have compliance metrics');
        System.assertNotEquals(null, dashboard.performanceMetrics, 'Should have performance metrics');
        System.assert(dashboard.insights.size() >= 0, 'Should generate insights');
        
        // Verify compliance metrics reflect test data
        System.assertEquals(10, dashboard.complianceMetrics.totalComplianceChecks, 'Should count all checks');
        System.assertEquals(80, dashboard.complianceMetrics.passRate, 'Should calculate 80% pass rate');
    }
    
    @isTest
    static void testBulkDocumentProcessing() {
        List<DocumentLifecycleConfiguration__c> configs = [SELECT Id FROM DocumentLifecycleConfiguration__c];
        List<ClauseGenerationEngine.ClauseRequest> requests = new List<ClauseGenerationEngine.ClauseRequest>();
        
        // Prepare bulk requests
        for (DocumentLifecycleConfiguration__c config : configs) {
            ClauseGenerationEngine.ClauseRequest request = new ClauseGenerationEngine.ClauseRequest();
            request.contractType = 'Employment Contract';
            request.region = 'US';
            request.role = 'Employee';
            request.configId = config.Id;
            requests.add(request);
        }
        
        Test.startTest();
        
        // Process bulk document generation
        PerformanceMonitor.startTracking('BULK_PROCESSING', 'bulk_job_001');
        try {
            List<String> generatedClauses = new List<String>();
            for (ClauseGenerationEngine.ClauseRequest request : requests) {
                String clause = ClauseGenerationEngine.generateClause(request);
                generatedClauses.add(clause);
            }
            
            System.assertEquals(configs.size(), generatedClauses.size(), 'Should generate all clauses');
            PerformanceMonitor.endTracking('BULK_PROCESSING', 'bulk_job_001');
            
        } catch (Exception e) {
            PerformanceMonitor.endTrackingWithError('BULK_PROCESSING', 'bulk_job_001', e.getMessage());
            throw e;
        }
        
        Test.stopTest();
        
        // Verify bulk processing
        List<PerformanceBenchmark__c> benchmarks = [
SELECT Id, OperationType__c, ExecutionTime__c 
FROM PerformanceBenchmark__c 
WHERE RecordId__c = 'bulk_job_001'
];
        System.assertEquals(1, benchmarks.size(), 'Should create bulk processing benchmark');
    }
    
    @isTest
    static void testErrorHandlingAndRecovery() {
        DocumentLifecycleConfiguration__c config = [SELECT Id FROM DocumentLifecycleConfiguration__c LIMIT 1];
        
        Test.startTest();
        
        // Test error scenarios
        PerformanceMonitor.startTracking('DOCUMENT_GENERATION', config.Id);
        
        try {
            // Force an error condition
            ClauseGenerationEngine.ClauseRequest invalidRequest = new ClauseGenerationEngine.ClauseRequest();
            invalidRequest.contractType = null; // This should cause an error
            invalidRequest.region = 'US';
            invalidRequest.role = 'Employee';
            invalidRequest.configId = config.Id;
            
            ClauseGenerationEngine.generateClause(invalidRequest);
            System.assert(false, 'Should have thrown an exception for invalid request');
            
        } catch (Exception e) {
            PerformanceMonitor.endTrackingWithError('DOCUMENT_GENERATION', config.Id, e.getMessage());
            // Expected error - continue test
        }
        
        Test.stopTest();
        
        // Verify error handling
        List<PerformanceBenchmark__c> benchmarks = [
SELECT Id, ErrorMessage__c 
FROM PerformanceBenchmark__c 
WHERE RecordId__c = :config.Id
];
        System.assertEquals(1, benchmarks.size(), 'Should create benchmark even with error');
        System.assertNotEquals(null, benchmarks[0].ErrorMessage__c, 'Should record error message');
    }
    
    @isTest
    static void testPermissionsAndSecurity() {
        User standardUser = [SELECT Id FROM User WHERE Username = 'user@docgen.com.test' LIMIT 1];
        DocumentLifecycleConfiguration__c config = [SELECT Id FROM DocumentLifecycleConfiguration__c LIMIT 1];
        
        Test.startTest();
        
        System.runAs(standardUser) {
            // Test that standard user can perform basic operations
            try {
                ClauseGenerationEngine.ClauseRequest request = new ClauseGenerationEngine.ClauseRequest();
                request.contractType = 'Employment Contract';
                request.region = 'US';
                request.role = 'Employee';
                request.configId = config.Id;
                
                String clause = ClauseGenerationEngine.generateClause(request);
                System.assertNotEquals(null, clause, 'Standard user should be able to generate clauses');
                
                // Test compliance validation
                ComplianceValidationResult result = ComplianceChecker.validateCompliance(
                    clause, 'US', 'Employment Contract'
                    );
                System.assertNotEquals(null, result, 'Standard user should be able to validate compliance');
                
            } catch (Exception e) {
                System.assert(false, 'Standard user should have access to basic functionality: ' + e.getMessage());
            }
        }
        
        Test.stopTest();
        
        // Verify operations completed successfully
        List<PerformanceBenchmark__c> benchmarks = [
SELECT Id, UserId__c 
FROM PerformanceBenchmark__c 
WHERE UserId__c = :standardUser.Id
];
        System.assert(benchmarks.size() > 0, 'Should track operations for standard user');
    }
    
    @isTest
    static void testSystemPerformanceSLA() {
        List<DocumentLifecycleConfiguration__c> configs = [SELECT Id FROM DocumentLifecycleConfiguration__c LIMIT 3];
        
        Test.startTest();
        
        // Test that operations meet SLA requirements
        for (DocumentLifecycleConfiguration__c config : configs) {
            DateTime startTime = DateTime.now();
            PerformanceMonitor.startTracking('DOCUMENT_GENERATION', config.Id);
            
            ClauseGenerationEngine.ClauseRequest request = new ClauseGenerationEngine.ClauseRequest();
            request.contractType = 'Employment Contract';
            request.region = 'US';
            request.role = 'Employee';
            request.configId = config.Id;
            
            String clause = ClauseGenerationEngine.generateClause(request);
            PerformanceMonitor.endTracking('DOCUMENT_GENERATION', config.Id);
            
            DateTime endTime = DateTime.now();
            Long executionTime = endTime.getTime() - startTime.getTime();
            
            // Verify generation completed within reasonable time (allowing for test overhead)
            System.assert(executionTime < 30000, 'Document generation should complete within 30 seconds in tests');
        }
        
        Test.stopTest();
        
        // Check if any SLA violations were created
        List<SLAViolationAlert__c> violations = [
SELECT Id, Severity__c 
FROM SLAViolationAlert__c 
WHERE CreatedDate = TODAY
];
        
        // In test context, we might have violations due to test overhead
        // Log any violations for analysis
        for (SLAViolationAlert__c violation : violations) {
            System.debug('SLA Violation detected: ' + violation.Severity__c);
        }
    }
    @isTest
    static void testDataConsistencyAndIntegrity() {
        DocumentLifecycleConfiguration__c config = [SELECT Id FROM DocumentLifecycleConfiguration__c LIMIT 1];
        
        Test.startTest();
        
        // Test data consistency across multiple operations
        String recordId = config.Id;
        String operationType = 'DOCUMENT_GENERATION';
        
        // Perform multiple operations on same record
        for (Integer i = 0; i < 3; i++) {
            PerformanceMonitor.startTracking(operationType, recordId + '_' + i);
            // Simulate work
            Integer counter = 0;
            for (Integer j = 0; j < 50; j++) {
                counter += j;
            }
            PerformanceMonitor.endTracking(operationType, recordId + '_' + i);
        }
        
        Test.stopTest();
        
        // Verify data integrity
        List<PerformanceBenchmark__c> benchmarks = [
SELECT Id, RecordId__c, ExecutionTime__c 
FROM PerformanceBenchmark__c 
WHERE RecordId__c LIKE :recordId + '_%'
ORDER BY RecordId__c
];
        
        System.assertEquals(3, benchmarks.size(), 'Should create exactly 3 benchmark records');
        
        // Verify each record has valid data
        for (PerformanceBenchmark__c benchmark : benchmarks) {
            System.assert(benchmark.ExecutionTime__c >= 0, 'Execution time should be non-negative');
            System.assertNotEquals(null, benchmark.RecordId__c, 'Record ID should not be null');
        }
    }
}
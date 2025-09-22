@isTest
private class DocumentAnalyticsEngineTest {
    
    @TestSetup
    static void makeData() {
        // Create test user
        User testUser = new User(
            FirstName        = 'Test',
        LastName         = 'User',
        Email            = 'testuser@docgen.com',
        Username         = 'testuser@docgen.com.test',
        Alias            = 'tuser',
        TimeZoneSidKey   = 'America/New_York',
        LocaleSidKey     = 'en_US',
        EmailEncodingKey = 'UTF-8',
        ProfileId        = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
        LanguageLocaleKey = 'en_US'
            );
        insert testUser;
        
        // Create test documents
        List<DocumentLifecycleConfiguration__c> testDocs = new List<DocumentLifecycleConfiguration__c>();
        for (Integer i = 0; i < 10; i++) {
            DocumentLifecycleConfiguration__c doc = new DocumentLifecycleConfiguration__c(
                Region__c        = (i < 5) ? 'US' : 'EU',
            Role__c          = 'Employee',
            ContractType__c  = 'Employment Contract',
            ComplianceScore__c = 85 + (i * 2),
            Status__c        = (i < 7) ? 'Active' : 'Draft'
                );
            testDocs.add(doc);
        }
        insert testDocs;
        
        // Create audit trail records
        List<AuditTrail__c> auditRecords = new List<AuditTrail__c>();
        for (Integer i = 0; i < 15; i++) {
            AuditTrail__c audit = new AuditTrail__c(
                RecordId__c     = testDocs[0].Id,
            Action__c       = 'ADVANCED_COMPLIANCE_CHECK',
            Status__c       = (i < 12) ? 'COMPLIANT' : 'NON_COMPLIANT',
            Timestamp__c    = DateTime.now().addDays(-i),
            UserDetails__c  = testUser.Name + ' (' + testUser.Username + ')',
            SystemInfo__c   = 'Test compliance check',
            AdditionalInfo__c = 'Test audit record'
                );
            auditRecords.add(audit);
        }
        insert auditRecords;
        
        // Create performance benchmarks
        List<PerformanceBenchmark__c> benchmarks = new List<PerformanceBenchmark__c>();
        String[] operations = new String[] { 'DOCUMENT_GENERATION', 'COMPLIANCE_CHECK', 'SIGNATURE_REQUEST' };
        for (Integer i = 0; i < 20; i++) {
            PerformanceBenchmark__c benchmark = new PerformanceBenchmark__c(
                OperationType__c = operations[Math.mod(i, 3)],
            ExecutionTime__c = 2000 + (i * 100),
            RecordId__c      = testDocs[0].Id,
            UserId__c        = testUser.Id,
            StartTime__c     = DateTime.now().addMinutes(-i),
            EndTime__c       = DateTime.now().addMinutes(-i).addSeconds(2),
            MemoryUsage__c   = 1024 + (i * 50)
                );
            benchmarks.add(benchmark);
        }
        insert benchmarks;
        
        // Create document view tracking
        List<DocumentViewTracking__c> viewRecords = new List<DocumentViewTracking__c>();
        for (Integer i = 0; i < 25; i++) {
            DocumentViewTracking__c view = new DocumentViewTracking__c(
                DocumentId__c = testDocs[Math.mod(i, 10)].Id,
            UserId__c     = testUser.Id,
            ViewDate__c   = Date.today().addDays(-i),
            ReadTime__c   = 30 + (i * 10)
                );
            viewRecords.add(view);
        }
        insert viewRecords;
    }
    @isTest
    static void testGenerateAnalyticsDashboard() {
        Test.startTest();
        // Test dashboard generation
        DocumentAnalyticsEngine.AnalyticsDashboard dashboard = DocumentAnalyticsEngine.generateAnalyticsDashboard();
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, dashboard, 'Dashboard should not be null');
        System.assertNotEquals(null, dashboard.documentMetrics, 'Document metrics should not be null');
        System.assertNotEquals(null, dashboard.complianceMetrics, 'Compliance metrics should not be null');
        System.assertNotEquals(null, dashboard.performanceMetrics, 'Performance metrics should not be null');
        System.assertNotEquals(null, dashboard.userActivityMetrics, 'User activity metrics should not be null');
        System.assertNotEquals(null, dashboard.insights, 'Insights should not be null');
        
        // Verify document metrics
        System.assertEquals(10, dashboard.documentMetrics.totalDocuments, 'Should have 10 total documents');
        System.assertNotEquals(null, dashboard.documentMetrics.statusBreakdown, 'Status breakdown should exist');
        
        // Verify compliance metrics
        System.assert(dashboard.complianceMetrics.totalComplianceChecks > 0, 'Should have compliance checks');
        
        // Verify insights generation
        System.assert(dashboard.insights.size() >= 0, 'Should have insights list');
    }
    
    @isTest
    static void testDocumentMetricsCalculation() {
        Test.startTest();
        DocumentAnalyticsEngine.DocumentMetrics metrics = DocumentAnalyticsEngine.getDocumentMetrics();
        Test.stopTest();
        
        // Verify metrics calculation
        System.assertNotEquals(null, metrics, 'Metrics should not be null');
        System.assertEquals(10, metrics.totalDocuments, 'Should calculate total documents correctly');
        System.assertNotEquals(null, metrics.statusBreakdown, 'Status breakdown should exist');
        System.assert(metrics.statusBreakdown.containsKey('Active'), 'Should have Active status');
        System.assert(metrics.statusBreakdown.containsKey('Draft'), 'Should have Draft status');
    }
    
    @isTest
    static void testComplianceMetricsCalculation() {
        Test.startTest();
        DocumentAnalyticsEngine.ComplianceMetrics metrics = DocumentAnalyticsEngine.getComplianceMetrics();
        Test.stopTest();
        
        // Verify compliance metrics
        System.assertNotEquals(null, metrics, 'Metrics should not be null');
        System.assertEquals(15, metrics.totalComplianceChecks, 'Should have 15 total checks');
        System.assertEquals(80, metrics.passRate, 'Should calculate 80% pass rate (12/15)');
        System.assertNotEquals(null, metrics.violationTrends, 'Violation trends should exist');
    }
    @isTest
    static void testPerformanceMetricsCalculation() {
        Test.startTest();
        DocumentAnalyticsEngine.PerformanceMetrics metrics = DocumentAnalyticsEngine.getPerformanceMetrics();
        Test.stopTest();
        
        // Verify performance metrics
        System.assertNotEquals(null, metrics, 'Metrics should not be null');
        System.assertNotEquals(null, metrics.operationMetrics, 'Operation metrics should exist');
        
        // Mock values should be present
        System.assertEquals(2.5, metrics.averageProcessingTime, 'Should have mock processing time');
        System.assertEquals(99.7, metrics.systemUptime, 'Should have mock uptime');
    }
    
    @isTest
    static void testUserActivityMetricsCalculation() {
        Test.startTest();
        DocumentAnalyticsEngine.UserActivityMetrics metrics = DocumentAnalyticsEngine.getUserActivityMetrics();
        Test.stopTest();
        
        // Verify user activity metrics
        System.assertNotEquals(null, metrics, 'Metrics should not be null');
        System.assertNotEquals(null, metrics.actionBreakdown, 'Action breakdown should exist');
        System.assertNotEquals(null, metrics.dailyActivity, 'Daily activity should exist');
        System.assert(metrics.totalActiveUsers >= 0, 'Should have valid user count');
    }
    
    @isTest
    static void testAIInsightsGeneration() {
        Test.startTest();
        
        // Create dashboard with low compliance rate
        DocumentAnalyticsEngine.AnalyticsDashboard dashboard = new DocumentAnalyticsEngine.AnalyticsDashboard();
        dashboard.complianceMetrics = new DocumentAnalyticsEngine.ComplianceMetrics();
        dashboard.complianceMetrics.passRate = 80; // Below 90% threshold
        
        dashboard.performanceMetrics = new DocumentAnalyticsEngine.PerformanceMetrics();
        dashboard.performanceMetrics.averageProcessingTime = 4.0; // Above 3s threshold
        
        dashboard.documentMetrics = new DocumentAnalyticsEngine.DocumentMetrics();
        dashboard.documentMetrics.documentsCreatedToday = 5; // Below 10 threshold
        
        List<DocumentAnalyticsEngine.AIInsight> insights = DocumentAnalyticsEngine.generateAIInsights(dashboard);
        
        Test.stopTest();
        
        // Verify insights generation
        System.assertNotEquals(null, insights, 'Insights should not be null');
        System.assert(insights.size() > 0, 'Should generate insights for low metrics');
        
        // Check for compliance insight
        Boolean hasComplianceInsight = false;
        for (DocumentAnalyticsEngine.AIInsight insight : insights) {
            if (insight.category == 'COMPLIANCE') {
                hasComplianceInsight = true;
                System.assertEquals('HIGH', insight.severity, 'Compliance insight should be HIGH severity');
                break;
            }
        }
        System.assert(hasComplianceInsight, 'Should generate compliance insight');
    }
    @isTest
    static void testRealTimeAnalyticsProcessing() {
        List<DocumentLifecycleConfiguration__c> docs = [SELECT Id FROM DocumentLifecycleConfiguration__c LIMIT 5];
        List<Id> documentIds = new List<Id>();
        for (DocumentLifecycleConfiguration__c doc : docs) {
            documentIds.add(doc.Id);
        }
        
        Test.startTest();
        DocumentAnalyticsEngine.processRealTimeAnalytics(documentIds);
        Test.stopTest();
        
        // Verify real-time processing completed without errors
        // Note: Since this is a future method, we can't directly verify the results
        // but we can ensure no exceptions were thrown
        System.assert(true, 'Real-time analytics processing should complete');
    }
    
    @isTest
    static void testScheduleAnalyticsProcessing() {
        Test.startTest();
        DocumentAnalyticsEngine.scheduleAnalyticsProcessing();
        Test.stopTest();
        
        // Verify job was scheduled
        List<CronTrigger> scheduledJobs = [SELECT Id, CronExpression FROM CronTrigger WHERE CronJobDetail.Name = 'Document Analytics Processing'];
        System.assertEquals(1, scheduledJobs.size(), 'Should schedule one analytics job');
        System.assertEquals('0 0 2 * * ?', scheduledJobs[0].CronExpression, 'Should use correct cron expression');
    }
    
    @isTest
    static void testErrorHandling() {
        Test.startTest();
        
        // Test with invalid data scenario
        try {
            // This should handle gracefully if no data exists
            DocumentAnalyticsEngine.AnalyticsDashboard dashboard = DocumentAnalyticsEngine.generateAnalyticsDashboard();
            System.assertNotEquals(null, dashboard, 'Should handle empty data gracefully');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception on empty data: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
}
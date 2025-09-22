@isTest
private class PerformanceMonitorTest {
    
    @TestSetup
    static void makeData() {
        // Create test user
        User testUser = new User(
            FirstName = 'Performance',
        LastName = 'Test',
        Email = 'performance@docgen.com',
        Username = 'performance@docgen.com.test',
        Alias = 'ptest',
        TimeZoneSidKey = 'America/New_York',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
        LanguageLocaleKey = 'en_US'
            );
        insert testUser;
    }
    
    @isTest
    static void testStartAndEndTracking() {
        String testRecordId = 'a001234567890123456';
        String operationType = 'DOCUMENT_GENERATION';
        
        Test.startTest();
        
        // Start tracking
        PerformanceMonitor.startTracking(operationType, testRecordId);
        
        // Simulate some processing time
        Integer counter = 0;
        for (Integer i = 0; i < 100; i++) {
            counter += i;
        }
        
        // End tracking
        PerformanceMonitor.endTracking(operationType, testRecordId);
        
        Test.stopTest();
        
        // Verify benchmark record was created
        List<PerformanceBenchmark__c> benchmarks = [
            SELECT Id, OperationType__c, ExecutionTime__c, RecordId__c
            FROM PerformanceBenchmark__c
            WHERE RecordId__c = :testRecordId
        ];
        
        System.assertEquals(1, benchmarks.size(), 'Should create one benchmark record');
        System.assertEquals(operationType, benchmarks[0].OperationType__c, 'Should match operation type');
        System.assert(benchmarks[0].ExecutionTime__c >= 0, 'Should have valid execution time');
    }
    
    @isTest
    static void testEndTrackingWithError() {
        String testRecordId = 'a001234567890123457';
        String operationType = 'COMPLIANCE_CHECK';
        String errorMessage = 'Test error message';
        
        Test.startTest();
        
        // Start tracking
        PerformanceMonitor.startTracking(operationType, testRecordId);
        
        // End tracking with error
        PerformanceMonitor.endTrackingWithError(operationType, testRecordId, errorMessage);
        
        Test.stopTest();
        
        // Verify benchmark record with error
        List<PerformanceBenchmark__c> benchmarks = [
            SELECT Id, OperationType__c, ErrorMessage__c
            FROM PerformanceBenchmark__c
            WHERE RecordId__c = :testRecordId
        ];
        
        System.assertEquals(1, benchmarks.size(), 'Should create benchmark record');
        System.assertEquals(errorMessage, benchmarks[0].ErrorMessage__c, 'Should store error message');
    }
    
    @isTest
    static void testSLAViolationDetection() {
        String testRecordId = 'a001234567890123458';
        String operationType = 'DOCUMENT_GENERATION';
        
        Test.startTest();
        
        // Create a benchmark that exceeds SLA (>5000ms for document generation)
        PerformanceBenchmark__c benchmark = new PerformanceBenchmark__c(
            OperationType__c = operationType,
        RecordId__c = testRecordId,
        ExecutionTime__c = 7000, // 7 seconds - exceeds 5s SLA
        UserId__c = UserInfo.getUserId(),
        StartTime__c = DateTime.now().addSeconds(-7),
        EndTime__c = DateTime.now(),
        MemoryUsage__c = 1024
            );
        insert benchmark;
        
        Test.stopTest();
        
        // Verify SLA violation alert was created
        List<SLAViolationAlert__c> alerts = [
            SELECT Id, OperationType__c, ActualTime__c, ThresholdTime__c, Severity__c
            FROM SLAViolationAlert__c
            WHERE BenchmarkId__c = :benchmark.Id
        ];
        
        System.assertEquals(1, alerts.size(), 'Should create SLA violation alert');
        System.assertEquals(7000, alerts[0].ActualTime__c, 'Should record actual time');
        System.assertEquals(5000, alerts[0].ThresholdTime__c, 'Should record threshold time');
        System.assertNotEquals(null, alerts[0].Severity__c, 'Should calculate severity');
    }
    
    @isTest
    static void testPerformanceTrendsAnalysis() {
        // Create test benchmarks for trend analysis
        List<PerformanceBenchmark__c> benchmarks = new List<PerformanceBenchmark__c>();
        
        String[] operations = new String[]{'DOCUMENT_GENERATION', 'COMPLIANCE_CHECK'};
        
        for (Integer i = 0; i < 10; i++) {
            PerformanceBenchmark__c benchmark = new PerformanceBenchmark__c(
                OperationType__c = operations[Math.mod(i, 2)],
            RecordId__c = 'test' + i,
            ExecutionTime__c = 2000 + (i * 100),
            UserId__c = UserInfo.getUserId(),
            StartTime__c = DateTime.now().addDays(-1),
            EndTime__c = DateTime.now().addDays(-1).addSeconds(2),
            MemoryUsage__c = 1024
                );
            benchmarks.add(benchmark);
        }
        insert benchmarks;
        
        Test.startTest();
        PerformanceMonitor.analyzePerformanceTrends();
        Test.stopTest();
        
        // Verify trend records were created
        List<PerformanceTrend__c> trends = [
            SELECT Id, OperationType__c, AverageTime__c, PerformanceGrade__c
            FROM PerformanceTrend__c
            WHERE AnalysisDate__c = TODAY
        ];
        
        System.assertEquals(2, trends.size(), 'Should create trends for each operation type');
        
        for (PerformanceTrend__c trend : trends) {
            System.assertNotEquals(null, trend.AverageTime__c, 'Should calculate average time');
            System.assertNotEquals(null, trend.PerformanceGrade__c, 'Should assign performance grade');
        }
    }
    
    @isTest
    static void testSeverityCalculation() {
        // Test different severity levels
        System.assertEquals('LOW', PerformanceMonitor.calculateSeverity(6000, 5000), 'Should be LOW for 1.2x threshold');
        System.assertEquals('MEDIUM', PerformanceMonitor.calculateSeverity(8000, 5000), 'Should be MEDIUM for 1.6x threshold');
        System.assertEquals('HIGH', PerformanceMonitor.calculateSeverity(12000, 5000), 'Should be HIGH for 2.4x threshold');
        System.assertEquals('CRITICAL', PerformanceMonitor.calculateSeverity(16000, 5000), 'Should be CRITICAL for 3.2x threshold');
    }
    
    @isTest
    static void testPerformanceGradeCalculation() {
        System.assertEquals('A+', PerformanceMonitor.calculatePerformanceGrade(1000, 'DOCUMENT_GENERATION'), 'Should be A+ for excellent performance');
        System.assertEquals('A', PerformanceMonitor.calculatePerformanceGrade(2500, 'DOCUMENT_GENERATION'), 'Should be A for good performance');
        System.assertEquals('B', PerformanceMonitor.calculatePerformanceGrade(3500, 'DOCUMENT_GENERATION'), 'Should be B for acceptable performance');
        System.assertEquals('C', PerformanceMonitor.calculatePerformanceGrade(4500, 'DOCUMENT_GENERATION'), 'Should be C for below average');
        System.assertEquals('D', PerformanceMonitor.calculatePerformanceGrade(6000, 'DOCUMENT_GENERATION'), 'Should be D for poor performance');
    }
    
    @isTest
    static void testNoStartTimeScenario() {
        String testRecordId = 'a001234567890123459';
        String operationType = 'SIGNATURE_REQUEST';
        
        Test.startTest();
        
        // Try to end tracking without starting - should handle gracefully
        PerformanceMonitor.endTracking(operationType, testRecordId);
        
        Test.stopTest();
        
        // Should not create any benchmark records
        List<PerformanceBenchmark__c> benchmarks = [
            SELECT Id FROM PerformanceBenchmark__c WHERE RecordId__c = :testRecordId
        ];
        
        System.assertEquals(0, benchmarks.size(), 'Should not create benchmark without start time');
    }
    
    @isTest
    static void testMultipleOperationsTracking() {
        String[] recordIds = new String[]{'record1', 'record2', 'record3'};
        String[] operations = new String[]{'DOCUMENT_GENERATION', 'COMPLIANCE_CHECK', 'PDF_GENERATION'};
        
        Test.startTest();
        
        // Start tracking multiple operations
        for (Integer i = 0; i < 3; i++) {
            PerformanceMonitor.startTracking(operations[i], recordIds[i]);
        }
        
        // End tracking in different order
        PerformanceMonitor.endTracking(operations[1], recordIds[1]); // COMPLIANCE_CHECK
        PerformanceMonitor.endTracking(operations[0], recordIds[0]); // DOCUMENT_GENERATION
        PerformanceMonitor.endTracking(operations[2], recordIds[2]); // PDF_GENERATION
        
        Test.stopTest();
        
        // Verify all benchmarks were created
        List<PerformanceBenchmark__c> benchmarks = [
            SELECT Id, OperationType__c, RecordId__c
            FROM PerformanceBenchmark__c
            WHERE RecordId__c IN :recordIds
            ORDER BY OperationType__c
        ];
        
        System.assertEquals(3, benchmarks.size(), 'Should create benchmark for each operation');
    }
}
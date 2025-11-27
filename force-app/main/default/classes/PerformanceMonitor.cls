public class PerformanceMonitor {
    private static Map<String, DateTime> startTimes = new Map<String, DateTime>();
    private static Map<String, Long> heapSizes = new Map<String, Long>();
    
    // Start performance tracking
    public static void startTracking(String operationType, String recordId) {
        String trackingKey = operationType + '_' + recordId;
        startTimes.put(trackingKey, System.now());
        heapSizes.put(trackingKey, Limits.getHeapSize());
    }
    public static void startTracking(String operationName) {
        startTimes.put(operationName, System.now());
    }
    
    
    // End performance tracking and log results
    public static void endTracking(String operationType, String recordId) {
        String trackingKey = operationType + '_' + recordId;
        
        if (!startTimes.containsKey(trackingKey)) {
            System.debug(LoggingLevel.WARN, 'No start time found for tracking key: ' + trackingKey);
            return;
        }
        
        DateTime startTime = startTimes.get(trackingKey);
        Long startHeap = heapSizes.get(trackingKey);
        DateTime endTime = System.now();
        Long endHeap = Limits.getHeapSize();
        
        Long executionTime = endTime.getTime() - startTime.getTime();
        Long memoryUsage = endHeap - startHeap;
        
        // Log performance benchmark
        logPerformanceBenchmark(operationType, recordId, startTime, endTime, executionTime, memoryUsage, null);
        
        // Clean up tracking data
        startTimes.remove(trackingKey);
        heapSizes.remove(trackingKey);
    }
    
    public static void endTracking(String operationName) {
        DateTime startTime = startTimes.get(operationName);
        if (startTime != null) {
            Long executionTime = System.now().getTime() - startTime.getTime();
            
            // Create performance benchmark record
            PerformanceBenchmark__c benchmark = new PerformanceBenchmark__c(
                OperationType__c = operationName,
                ExecutionTime__c = executionTime,
                Timestamp__c = System.now(),
                UserId__c = UserInfo.getUserId()
            );
            
            insert benchmark;
            
            // Log performance metrics
            System.debug('Performance - ' + operationName + ': ' + executionTime + 'ms');
            
            startTimes.remove(operationName);
        }
    }
    
    
    // End tracking with error
    public static void endTrackingWithError(String operationType, String recordId, String errorMessage) {
        String trackingKey = operationType + '_' + recordId;
        
        if (!startTimes.containsKey(trackingKey)) {
            return;
        }
        
        DateTime startTime = startTimes.get(trackingKey);
        Long startHeap = heapSizes.get(trackingKey);
        DateTime endTime = System.now();
        Long endHeap = Limits.getHeapSize();
        
        Long executionTime = endTime.getTime() - startTime.getTime();
        Long memoryUsage = endHeap - startHeap;
        
        // Log performance benchmark with error
        logPerformanceBenchmark(operationType, recordId, startTime, endTime, executionTime, memoryUsage, errorMessage);
        
        // Clean up
        startTimes.remove(trackingKey);
        heapSizes.remove(trackingKey);
    }
    
    private static void logPerformanceBenchmark(String operationType, String recordId, DateTime startTime, DateTime endTime, Long executionTime, Long memoryUsage, String errorMessage) {
        try {
            PerformanceBenchmark__c benchmark = new PerformanceBenchmark__c(
                OperationType__c = operationType,
            RecordId__c = recordId,
            StartTime__c = startTime,
            EndTime__c = endTime,
            ExecutionTime__c = executionTime,
            MemoryUsage__c = memoryUsage / 1024, // Convert to KB
            UserId__c = UserInfo.getUserId(),
            ErrorMessage__c = errorMessage
                );
            
            insert benchmark;
            
            // Check SLA compliance and alert if necessary
            checkSLACompliance(benchmark);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to log performance benchmark: ' + e.getMessage());
        }
    }
    
    private static void checkSLACompliance(PerformanceBenchmark__c benchmark) {
        Map<String, Long> slaThresholds = new Map<String, Long>{
            'DOCUMENT_GENERATION' => 5000, // 5 seconds
            'COMPLIANCE_CHECK' => 3000,    // 3 seconds
            'SIGNATURE_REQUEST' => 2000,   // 2 seconds
            'PDF_GENERATION' => 10000,     // 10 seconds
            'TEMPLATE_PROCESSING' => 1000  // 1 second
        };
        
        Long threshold = slaThresholds.get(benchmark.OperationType__c);
        if (threshold != null && benchmark.ExecutionTime__c > threshold) {
            // Create SLA violation alert
            createSLAAlert(benchmark, threshold);
        }
    }
    
    private static void createSLAAlert(PerformanceBenchmark__c benchmark, Long threshold) {
        try {
            SLAViolationAlert__c alert = new SLAViolationAlert__c(
                BenchmarkId__c = benchmark.Id,
            OperationType__c = benchmark.OperationType__c,
            ActualTime__c = benchmark.ExecutionTime__c,
            ThresholdTime__c = threshold,
            ExcessTime__c = benchmark.ExecutionTime__c - threshold,
            Severity__c = calculateSeverity(benchmark.ExecutionTime__c, threshold),
            AlertDate__c = System.now()
                );
            
            insert alert;
            
            // Send notification for critical violations
            if (alert.Severity__c == 'CRITICAL') {
                sendCriticalAlert(alert);
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to create SLA alert: ' + e.getMessage());
        }
    }
    
    private static String calculateSeverity(Decimal actualTime, Long threshold) {
        if (threshold == null || threshold == 0) return 'LOW';
        Decimal ratio = actualTime / threshold;
        if (ratio >= 3.0) return 'CRITICAL';
        if (ratio >= 2.0) return 'HIGH';
        if (ratio >= 1.5) return 'MEDIUM';
        return 'LOW';
    }
    
    private static void sendCriticalAlert(SLAViolationAlert__c alert) {
        // Implementation for sending critical alerts
        System.debug(LoggingLevel.WARN, 'CRITICAL SLA Violation: ' + alert.OperationType__c +
            ' took ' + alert.ActualTime__c + 'ms (threshold: ' + alert.ThresholdTime__c + 'ms)');
    }
    
    // Batch performance analysis
    public static void analyzePerformanceTrends() {
        List<AggregateResult> trends = [
            SELECT OperationType__c,
                   AVG(ExecutionTime__c) avgTime,
                   MAX(ExecutionTime__c) maxTime,
                   MIN(ExecutionTime__c) minTime,
                   COUNT(Id) totalOps,
                   COUNT_DISTINCT(RecordId__c) uniqueRecords
            FROM PerformanceBenchmark__c
            WHERE StartTime__c = LAST_N_DAYS:7
            GROUP BY OperationType__c
        ];
        
        for (AggregateResult trend : trends) {
            String operationType = (String) trend.get('OperationType__c');
            Decimal avgTime = (Decimal) trend.get('avgTime');
            Decimal maxTime = (Decimal) trend.get('maxTime');
            Decimal minTime = (Decimal) trend.get('minTime');
            Integer totalOps = (Integer) trend.get('totalOps');
            Integer uniqueRecords = (Integer) trend.get('uniqueRecords');
            
            // Create performance trend record
            PerformanceTrend__c trendRecord = new PerformanceTrend__c(
                OperationType__c = operationType,
            AnalysisDate__c = Date.today(),
            AverageTime__c = avgTime,
            MaxTime__c = maxTime,
            MinTime__c = minTime,
            TotalOperations__c = totalOps,
            UniqueRecords__c = uniqueRecords,
            PerformanceGrade__c = calculatePerformanceGrade(avgTime, operationType)
                );
            
            insert trendRecord;
        }
    }
    
    private static String calculatePerformanceGrade(Decimal avgTime, String operationType) {
        Map<String, Decimal> excellentThresholds = new Map<String, Decimal>{
            'DOCUMENT_GENERATION' => 2000,
            'COMPLIANCE_CHECK' => 1500,
            'SIGNATURE_REQUEST' => 1000,
            'PDF_GENERATION' => 5000,
            'TEMPLATE_PROCESSING' => 500
        };
        
        Decimal excellentThreshold = excellentThresholds.get(operationType);
        if (excellentThreshold != null) {
            if (avgTime <= excellentThreshold) return 'A+';
            if (avgTime <= excellentThreshold * 1.5) return 'A';
            if (avgTime <= excellentThreshold * 2.0) return 'B';
            if (avgTime <= excellentThreshold * 2.5) return 'C';
            return 'D';
        }
        
        return 'N/A';
    }
    
    // Usage example in other classes:
    /*
    public void generateDocument(String documentId) {
        PerformanceMonitor.startTracking('DOCUMENT_GENERATION', documentId);
        
        try {
            // Document generation logic here
            
            PerformanceMonitor.endTracking('DOCUMENT_GENERATION', documentId);
        } catch (Exception e) {
            PerformanceMonitor.endTrackingWithError('DOCUMENT_GENERATION', documentId, e.getMessage());
            throw e;
        }
    }
     */
    
    @AuraEnabled(cacheable=true)
    public static List<PerformanceBenchmark__c> getPerformanceMetrics() {
        return [
            SELECT Id, OperationType__c, ExecutionTime__c, Timestamp__c, ErrorMessage__c
            FROM PerformanceBenchmark__c
            WHERE Timestamp__c >= LAST_N_DAYS:7
            ORDER BY Timestamp__c DESC
            LIMIT 100
        ];
    }
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getPerformanceSummary() {
        List<AggregateResult> results = [
            SELECT OperationType__c, AVG(ExecutionTime__c) avgTime, 
                   MAX(ExecutionTime__c) maxTime, COUNT(Id) operationCount
            FROM PerformanceBenchmark__c
            WHERE Timestamp__c >= LAST_N_DAYS:30
            GROUP BY OperationType__c
        ];
        
        Map<String, Object> summary = new Map<String, Object>();
        for (AggregateResult result : results) {
            Map<String, Object> opMetrics = new Map<String, Object>();
            opMetrics.put('averageTime', result.get('avgTime'));
            opMetrics.put('maxTime', result.get('maxTime'));
            opMetrics.put('operationCount', result.get('operationCount'));
            
            summary.put((String) result.get('OperationType__c'), opMetrics);
        }
        
        return summary;
    }
    
    
}
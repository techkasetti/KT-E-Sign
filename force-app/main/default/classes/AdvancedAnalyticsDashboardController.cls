public class AdvancedAnalyticsDashboardController {

    public class PredictiveAnalyticsResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String forecastType;
        @AuraEnabled public List<Object> predictions;
        @AuraEnabled public String modelVersion;
        @AuraEnabled public String message;
        // Add other fields as needed

        public PredictiveAnalyticsResult() {}
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getAdvancedDashboardData(Integer timeframeDays) {
        try {
            Date startDate = System.today().addDays(-timeframeDays);
            
            // Generate comprehensive analytics using AI engine
            Map<String, Object> dashboardData = AIAnalyticsEngine.generateAnalyticsDashboard('Last' + timeframeDays + 'Days', new List<String>{'performance', 'predictive', 'behavior', 'security', 'cost', 'satisfaction'});
            
            // Add real-time system health
            dashboardData.put('systemHealth', getSystemHealthMetrics());
            
            // Add user engagement metrics
            dashboardData.put('userEngagement', calculateUserEngagementMetrics(startDate));
            
            // Add compliance dashboard
            dashboardData.put('complianceDashboard', generateComplianceDashboard(startDate));
            
            return dashboardData;
            
        } catch (Exception e) {
            throw new AuraHandledException('Advanced dashboard data retrieval failed: ' + e.getMessage());
        }
    }
    
    



@AuraEnabled(cacheable=false)
public static Map<String, Object> getMLInsights(String insightType, Integer timeframeDays) {
    try {
        Date startDate = System.today().addDays(-timeframeDays);
        Map<String, Object> insights = new Map<String, Object>();
        
        switch on insightType {
            when 'document_intelligence' {
                insights = getDocumentIntelligenceInsights(startDate);
            }
            when 'user_behavior' {
                insights = getUserBehaviorInsights(startDate);
            }
            when 'performance_optimization' {
                insights = getPerformanceOptimizationInsights(startDate);
            }
            when 'security_analysis' {
                insights = getSecurityAnalysisInsights(startDate);
            }
            when 'predictive_trends' {
                insights = getPredictiveTrendsInsights(startDate);
            }
            when else {
                throw new IllegalArgumentException('Invalid insight type: ' + insightType);
            }
        }
        
        insights.put('generatedAt', System.now());
        insights.put('timeframe', timeframeDays);
        return insights;
        
    } catch (Exception e) {
        throw new AuraHandledException('ML insights retrieval failed: ' + e.getMessage());
    }
}


@AuraEnabled(cacheable=false)
public static List<Map<String, Object>> getAnomalyDetectionResults(Integer hours) {
    try {
        List<Map<String, Object>> anomalies = new List<Map<String, Object>>();
        DateTime startTime = System.now().addHours(-hours);
        
        // Get document generation anomalies
        List<AIAnalyticsEngine.AnomalyAlert> docAnomalies = AIAnalyticsEngine.detectDocumentGenerationAnomalies();
        for (AIAnalyticsEngine.AnomalyAlert docAnomaly : docAnomalies) {
            if (docAnomaly.timestamp >= startTime) {
                Map<String, Object> anomalyMap = new Map<String, Object>();
                anomalyMap.put('type', docAnomaly.type);
                anomalyMap.put('description', docAnomaly.description);
                anomalyMap.put('severity', docAnomaly.severity);
                anomalyMap.put('timestamp', docAnomaly.timestamp);
                anomalyMap.put('magnitude', docAnomaly.magnitude);
                anomalyMap.put('suggestedActions', docAnomaly.suggestedActions);
                anomalies.add(anomalyMap);
            }
        }
        
        // Get signature request anomalies
        List<AIAnalyticsEngine.AnomalyAlert> sigAnomalies = AIAnalyticsEngine.detectSignatureRequestAnomalies();
        for (AIAnalyticsEngine.AnomalyAlert sigAnomaly : sigAnomalies) {
            if (sigAnomaly.timestamp >= startTime) {
                Map<String, Object> anomalyMap = new Map<String, Object>();
                anomalyMap.put('type', sigAnomaly.type);
                anomalyMap.put('description', sigAnomaly.description);
                anomalyMap.put('severity', sigAnomaly.severity);
                anomalyMap.put('timestamp', sigAnomaly.timestamp);
                anomalyMap.put('magnitude', sigAnomaly.magnitude);
                anomalyMap.put('suggestedActions', sigAnomaly.suggestedActions);
                anomalies.add(anomalyMap);
            }
        }
        
        return anomalies;
        
    } catch (Exception e) {
        throw new AuraHandledException('Anomaly detection failed: ' + e.getMessage());
    }
}

@AuraEnabled(cacheable=false)
public static Map<String, Object> runMLDocumentAnalysis(String documentId) {
    try {
        // Get document content
        DocumentLifecycleConfiguration__c document = [
            SELECT Id, DocumentTitle__c, DocumentContent__c, ContractType__c, Region__c
            FROM DocumentLifecycleConfiguration__c 
            WHERE Id = :documentId 
            LIMIT 1
        ];
        
        // Run ML classification
        MLIntegrationService.DocumentClassificationResult classification = MLIntegrationService.classifyDocument(
            document.DocumentContent__c, 
            document.ContractType__c
        );
        
        Map<String, Object> analysis = new Map<String, Object>();
        analysis.put('documentId', documentId);
        analysis.put('classification', classification);
        analysis.put('timestamp', System.now());
        
        if (classification.success) {
            // Store results in custom object for future reference
            ML_Analysis_Result__c mlResult = new ML_Analysis_Result__c();
            mlResult.Document_Id__c = documentId;
            mlResult.Classification__c = classification.classification;
            mlResult.Confidence_Score__c = classification.confidence;
            mlResult.Sentiment_Score__c = classification.sentimentScore;
            mlResult.Analysis_Date__c = System.now();
            mlResult.Model_Version__c = 'doc-classifier-v3.2';
            insert mlResult;
            
            analysis.put('analysisId', mlResult.Id);
        }
        
        return analysis;
        
    } catch (Exception e) {
        throw new AuraHandledException('ML document analysis failed: ' + e.getMessage());
    }
}
@AuraEnabled(cacheable=false)
public static Map<String, Object> getFraudDetectionAnalysis(String signatureRequestId) {
    try {
        // Get signature request data
        Signature_Request__c sigRequest = [
            SELECT Id, SignerEmail__c, SigningLocation__c, DeviceFingerprint__c, 
                   Time_To_Complete_Hours__c, SignatureMethod__c, Status__c
            FROM Signature_Request__c 
            WHERE Id = :signatureRequestId 
            LIMIT 1
        ];
        
        // Prepare signature data for ML analysis
        Map<String, Object> signatureData = new Map<String, Object>();
        signatureData.put('signerEmail', sigRequest.SignerEmail__c);
        signatureData.put('signingLocation', sigRequest.SigningLocation__c);
        signatureData.put('deviceFingerprint', sigRequest.DeviceFingerprint__c);
        signatureData.put('timeToComplete', sigRequest.Time_To_Complete_Hours__c);
        signatureData.put('signatureMethod', sigRequest.SignatureMethod__c);
        signatureData.put('timestamp', System.now());
        
        // Call ML fraud detection service
        MLIntegrationService.FraudScoringResult fraudResult = MLIntegrationService.calculateFraudScore(signatureData);
        
        Map<String, Object> analysis = new Map<String, Object>();
        analysis.put('signatureRequestId', signatureRequestId);
        analysis.put('fraudAnalysis', fraudResult);
        analysis.put('timestamp', System.now());
        
        if (fraudResult.success) {
            // Store fraud analysis results
            Fraud_Analysis_Result__c fraudAnalysis = new Fraud_Analysis_Result__c();
            fraudAnalysis.Signature_Request_Id__c = signatureRequestId;
            fraudAnalysis.Fraud_Score__c = fraudResult.fraudScore;
            fraudAnalysis.Risk_Level__c = fraudResult.riskLevel;
            fraudAnalysis.Confidence__c = fraudResult.confidence;
            fraudAnalysis.Analysis_Date__c = System.now();
            fraudAnalysis.Model_Version__c = 'fraud-detector-v2.8';
            insert fraudAnalysis;
            
            analysis.put('analysisId', fraudAnalysis.Id);
        }
        
        return analysis;
        
    } catch (Exception e) {
        throw new AuraHandledException('Fraud detection analysis failed: ' + e.getMessage());
    }
}

@AuraEnabled(cacheable=false)
public static Map<String, Object> generatePredictiveForecasts(String forecastType, Integer forecastDays) {
    try {
        Map<String, Object> inputData = new Map<String, Object>();
        inputData.put('forecast_days', forecastDays);
        inputData.put('include_seasonality', true);
        
        // Add historical data based on forecast type
        switch on forecastType {
            when 'document_volume' {
                inputData.put('historical_volumes', getHistoricalDocumentVolumes());
            }
            when 'signature_completion' {
                inputData.put('historical_completions', getHistoricalSignatureCompletions());
            }
            when 'system_load' {
                inputData.put('historical_metrics', getHistoricalSystemMetrics());
            }
        }
        
        // Call ML predictive analytics service
       MLIntegrationService.PredictiveAnalyticsResult prediction = MLIntegrationService.generatePredictions(
    forecastType, inputData
);
        Map<String, Object> forecast = new Map<String, Object>();
        forecast.put('forecastType', forecastType);
        // Add relevant fields from PredictiveAnalyticsResult to the map
        Map<String, Object> predictionMap = new Map<String, Object>();
       
        forecast.put('generatedAt', System.now());
        forecast.put('forecastHorizon', forecastDays);
        return forecast;
        
    } catch (Exception e) {
        throw new AuraHandledException('Predictive forecast generation failed: ' + e.getMessage());
    }
}

// Helper methods for ML insights

private static Map<String, Object> getDocumentIntelligenceInsights(Date startDate) {
    Map<String, Object> insights = new Map<String, Object>();
    
    // Document type distribution analysis
    List<AggregateResult> docTypes = [
        SELECT ContractType__c, COUNT(Id) typeCount, AVG(Generation_Time_Seconds__c) avgGenTime
        FROM DocumentLifecycleConfiguration__c 
        WHERE CreatedDate >= :startDate
        GROUP BY ContractType__c
    ];
    insights.put('documentTypeAnalysis', docTypes);
    
    // Content complexity analysis
    List<AggregateResult> complexityMetrics = [
        SELECT AVG(Content_Word_Count__c) avgWordCount, 
               AVG(Clause_Count__c) avgClauseCount,
               AVG(Overall_Compliance_Score__c) avgComplianceScore
        FROM DocumentLifecycleConfiguration__c 
        WHERE CreatedDate >= :startDate
    ];
    insights.put('complexityMetrics', complexityMetrics);
    
    // Regional generation patterns
    List<AggregateResult> regionalPatterns = [
        SELECT Region__c, COUNT(Id) docCount, AVG(Generation_Time_Seconds__c) avgGenTime
        FROM DocumentLifecycleConfiguration__c 
        WHERE CreatedDate >= :startDate AND Region__c != null
        GROUP BY Region__c
    ];
    insights.put('regionalPatterns', regionalPatterns);
    
    return insights;
}

private static Map<String, Object> getUserBehaviorInsights(Date startDate) {
    Map<String, Object> insights = new Map<String, Object>();
    
    // User engagement patterns
    List<AggregateResult> engagementMetrics = [
        SELECT SignerEmail__c, COUNT(Id) signatureCount, 
               AVG(Time_To_Complete_Hours__c) avgCompletionTime,
               MAX(CreatedDate) lastActivity
        FROM Signature_Request__c 
        WHERE CreatedDate >= :startDate AND SignerEmail__c != null
        GROUP BY SignerEmail__c
        HAVING COUNT(Id) > 1
    ];
    insights.put('userEngagement', engagementMetrics);
    
    // Signing method preferences
    List<AggregateResult> methodPreferences = [
        SELECT SignatureMethod__c, COUNT(Id) methodCount,
               AVG(Time_To_Complete_Hours__c) avgTime
        FROM Signature_Request__c 
        WHERE CreatedDate >= :startDate AND Status__c = 'Completed'
        GROUP BY SignatureMethod__c
    ];
    insights.put('methodPreferences', methodPreferences);
    
    // Device usage patterns
    List<AggregateResult> devicePatterns = [
        SELECT DeviceType__c, COUNT(Id) deviceCount,
               AVG(Time_To_Complete_Hours__c) avgCompletionTime
        FROM Signature_Request__c 
        WHERE CreatedDate >= :startDate AND DeviceType__c != null
        GROUP BY DeviceType__c
    ];
    insights.put('devicePatterns', devicePatterns);
    
    return insights;
}

private static Map<String, Object> getPerformanceOptimizationInsights(Date startDate) {
    Map<String, Object> insights = new Map<String, Object>();
    
    // System performance metrics
    List<AggregateResult> perfMetrics = [
        SELECT AVG(Generation_Time_Seconds__c) avgGenTime,
               MAX(Generation_Time_Seconds__c) maxGenTime,
               MIN(Generation_Time_Seconds__c) minGenTime,
               COUNT(Id) totalDocuments
        FROM DocumentLifecycleConfiguration__c 
        WHERE CreatedDate >= :startDate
    ];
    insights.put('performanceMetrics', perfMetrics);
    
    // Error rate analysis
    List<AggregateResult> errorRates = [
        SELECT Status__c, COUNT(Id) statusCount
        FROM Signature_Request__c 
        WHERE CreatedDate >= :startDate
        GROUP BY Status__c
    ];
    insights.put('errorAnalysis', errorRates);
    
    // Resource utilization insights
    Map<String, Object> resourceMetrics = new Map<String, Object>();
    resourceMetrics.put('averageCPU', 65.0);
    resourceMetrics.put('averageMemory', 78.0);
    resourceMetrics.put('peakLoad', 89.0);
    resourceMetrics.put('recommendedOptimizations', new List<String>{
        'Implement document template caching',
        'Optimize database query performance', 
        'Add horizontal scaling for peak loads'
    });
    insights.put('resourceUtilization', resourceMetrics);
    
    return insights;
}
@AuraEnabled
public static Map<String, Object> getSecurityAnalysisInsights(Date startDate) {
    Map<String, Object> insights = new Map<String, Object>();
    
    // Security event analysis
    List<AggregateResult> securityEvents = [
        SELECT Event_Type__c, COUNT(Id) eventCount, AVG(Risk_Score__c) avgRiskScore
        FROM Security_Event__c 
        WHERE Event_Date__c >= :startDate
        GROUP BY Event_Type__c
    ];
    insights.put('securityEvents', securityEvents);
    
    // Failed authentication attempts
    List<AggregateResult> authFailures = [
        SELECT COUNT(Id) failureCount, SignerEmail__c
        FROM Authentication_Attempt__c 
        WHERE Attempt_Date__c >= :startDate AND Success__c = false
        GROUP BY SignerEmail__c
        HAVING COUNT(Id) > 3
    ];
    insights.put('authenticationFailures', authFailures);
    
    // Fraud detection summary
    List<AggregateResult> fraudSummary = [
        SELECT Risk_Level__c, COUNT(Id) riskCount, AVG(Fraud_Score__c) avgFraudScore
        FROM Fraud_Analysis_Result__c 
        WHERE Analysis_Date__c >= :startDate
        GROUP BY Risk_Level__c
    ];
    insights.put('fraudSummary', fraudSummary);
    
    return insights;
}

private static Map<String, Object> getPredictiveTrendsInsights(Date startDate) {
    Map<String, Object> insights = new Map<String, Object>();
    
    // Document volume trends
    List<AggregateResult> volumeTrends = [
        SELECT DAY_ONLY(CreatedDate) createdDate, COUNT(Id) dailyCount
        FROM DocumentLifecycleConfiguration__c 
        WHERE CreatedDate >= :startDate
        GROUP BY DAY_ONLY(CreatedDate)
        ORDER BY DAY_ONLY(CreatedDate)
    ];
    insights.put('volumeTrends', volumeTrends);
    
List<AggregateResult> totalRequests = [
    SELECT DAY_ONLY(CreatedDate) createdDate,
           COUNT(Id) totalRequests
    FROM Signature_Request__c
    WHERE CreatedDate >= :startDate
    GROUP BY DAY_ONLY(CreatedDate)
    ORDER BY DAY_ONLY(CreatedDate)
];
    // Total requests per day
   

    // Completed requests per day
    List<AggregateResult> completedRequests = [
        SELECT DAY_ONLY(CreatedDate) createdDate,
               COUNT(Id) completedRequests,
               AVG(Time_To_Complete_Hours__c) avgCompletionTime
        FROM Signature_Request__c
        WHERE CreatedDate >= :startDate AND Status__c = 'Completed'
        GROUP BY DAY_ONLY(CreatedDate)
        ORDER BY DAY_ONLY(CreatedDate)
    ];

    List<Map<String, Object>> completionTrends = new List<Map<String, Object>>();
    Map<Date, Integer> totalMap = new Map<Date, Integer>();
    for (AggregateResult tr : totalRequests) {
        Date d = (Date)tr.get('createdDate');
        totalMap.put(d, (Integer)tr.get('totalRequests'));
    }
    Map<Date, AggregateResult> completedMap = new Map<Date, AggregateResult>();
    for (AggregateResult cr : completedRequests) {
        Date d = (Date)cr.get('createdDate');
        completedMap.put(d, cr);
    }
    for (Date d : totalMap.keySet()) {
        Map<String, Object> trend = new Map<String, Object>();
        trend.put('date', d);
        Integer total = totalMap.get(d);
        Integer completed = completedMap.containsKey(d) ? (Integer)completedMap.get(d).get('completedRequests') : 0;
        Decimal avgTime = completedMap.containsKey(d) ? (Decimal)completedMap.get(d).get('avgCompletionTime') : 0;
        trend.put('totalRequests', total);
        trend.put('completedRequests', completed);
        trend.put('avgCompletionTime', avgTime);
        trend.put('completionRate', total > 0 ? (completed * 100.0) / total : 0);
        completionTrends.add(trend);
    }

    insights.put('completionTrends', completionTrends);
    
    // Seasonal patterns analysis
    List<AggregateResult> seasonalPatterns = [
        SELECT HOUR_IN_DAY(CreatedDate) hourOfDay,
               COUNT(Id) hourlyCount,
               AVG(Time_To_Complete_Hours__c) avgHourlyCompletionTime
        FROM Signature_Request__c
        WHERE CreatedDate >= :startDate
        GROUP BY HOUR_IN_DAY(CreatedDate)
        ORDER BY HOUR_IN_DAY(CreatedDate)
    ];
    insights.put('seasonalPatterns', seasonalPatterns);
    
    // Growth rate predictions
    Map<String, Object> growthPredictions = new Map<String, Object>();
    growthPredictions.put('documentVolumeGrowth', calculateGrowthRate('documents', startDate));
    growthPredictions.put('userAdoptionGrowth', calculateGrowthRate('users', startDate));
    growthPredictions.put('completionRateGrowth', calculateGrowthRate('completions', startDate));
    insights.put('growthPredictions', growthPredictions);
    
    return insights;
}


// Helper methods for data retrieval
private static List<Object> getHistoricalDocumentVolumes() {
    List<Object> volumes = new List<Object>();
    List<AggregateResult> dailyVolumes = [
        SELECT DAY_ONLY(CreatedDate) volumeDate, COUNT(Id) dailyCount
        FROM DocumentLifecycleConfiguration__c 
        WHERE CreatedDate >= LAST_N_DAYS:90
        GROUP BY DAY_ONLY(CreatedDate)
        ORDER BY DAY_ONLY(CreatedDate)
    ];
    
    for (AggregateResult volume : dailyVolumes) {
        Map<String, Object> dataPoint = new Map<String, Object>();
        dataPoint.put('date', volume.get('volumeDate'));
        dataPoint.put('volume', volume.get('dailyCount'));
        volumes.add(dataPoint);
    }
    
    return volumes;
}

private static List<Object> getHistoricalSignatureCompletions() {
    List<Object> completions = new List<Object>();
    // Fetch signature requests for the last 90 days
List<Signature_Request__c> sigRequests = [
    SELECT CreatedDate, Status__c
    FROM Signature_Request__c
    WHERE CreatedDate >= LAST_N_DAYS:90
];

// Map to store daily metrics
Map<Date, Map<String, Integer>> dailyCompletionsMap = new Map<Date, Map<String, Integer>>();

// Calculate totals and completed counts per day
for (Signature_Request__c req : sigRequests) {
    Date day = req.CreatedDate.date(); // DAY_ONLY equivalent
    if (!dailyCompletionsMap.containsKey(day)) {
        dailyCompletionsMap.put(day, new Map<String, Integer>{
            'totalRequests' => 0,
            'completedRequests' => 0
        });
    }

    Map<String, Integer> metrics = dailyCompletionsMap.get(day);
    metrics.put('totalRequests', metrics.get('totalRequests') + 1);
    if (req.Status__c == 'Completed') {
        metrics.put('completedRequests', metrics.get('completedRequests') + 1);
    }
}

// Convert to a list if needed
List<Map<String, Object>> dailyCompletions = new List<Map<String, Object>>();
for (Date day : dailyCompletionsMap.keySet()) {
    Map<String, Integer> metrics = dailyCompletionsMap.get(day);
    dailyCompletions.add(new Map<String, Object>{
        'completionDate' => day,
        'totalRequests' => metrics.get('totalRequests'),
        'completedRequests' => metrics.get('completedRequests')
    });
}


    
    for (Map<String, Object> completion : dailyCompletions) {
        Map<String, Object> dataPoint = new Map<String, Object>();
        dataPoint.put('date', completion.get('completionDate'));
        dataPoint.put('totalRequests', completion.get('totalRequests'));
        dataPoint.put('completedRequests', completion.get('completedRequests'));
        Integer total = (Integer)completion.get('totalRequests');
        Integer completed = (Integer)completion.get('completedRequests');
        dataPoint.put('completionRate', total > 0 ? (completed * 100.0) / total : 0);
        completions.add(dataPoint);
    }
    
    return completions;
}

private static List<Object> getHistoricalSystemMetrics() {
    List<Object> metrics = new List<Object>();
    List<Performance_Metric__c> perfMetrics = [
        SELECT MetricDate__c, CPU_Utilization__c, Memory_Utilization__c, 
               Response_Time_Ms__c, Throughput_Per_Second__c
        FROM Performance_Metric__c
        WHERE MetricDate__c >= LAST_N_DAYS:30
        ORDER BY MetricDate__c
    ];
    
    for (Performance_Metric__c metric : perfMetrics) {
        Map<String, Object> dataPoint = new Map<String, Object>();
        dataPoint.put('date', metric.MetricDate__c);
        dataPoint.put('cpuUtilization', metric.CPU_Utilization__c);
        dataPoint.put('memoryUtilization', metric.Memory_Utilization__c);
        dataPoint.put('responseTime', metric.Response_Time_Ms__c);
        dataPoint.put('throughput', metric.Throughput_Per_Second__c);
        metrics.add(dataPoint);
    }
    
    return metrics;
}

private static Map<String, Object> getSystemHealthMetrics() {
    Map<String, Object> health = new Map<String, Object>();
    
    // Current system status
    health.put('overallStatus', 'HEALTHY');
    health.put('uptime', 99.7);
    health.put('lastHealthCheck', System.now());
    
    // Component health
    Map<String, String> componentHealth = new Map<String, String>();
    componentHealth.put('documentGeneration', 'HEALTHY');
    componentHealth.put('signatureProcessing', 'HEALTHY');
    componentHealth.put('complianceEngine', 'WARNING');
    componentHealth.put('mlServices', 'HEALTHY');
    componentHealth.put('database', 'HEALTHY');
    health.put('componentHealth', componentHealth);
    
    // Performance indicators
    Map<String, Object> performance = new Map<String, Object>();
    performance.put('avgResponseTime', 1.8);
    performance.put('throughputPerMinute', 450);
    performance.put('errorRate', 0.3);
    performance.put('memoryUsage', 72.5);
    performance.put('cpuUsage', 68.2);
    health.put('performance', performance);
    
    return health;
}

private static Map<String, Object> calculateUserEngagementMetrics(Date startDate) {
    Map<String, Object> engagement = new Map<String, Object>();
    
    // Daily active users
    List<AggregateResult> dailyUsers = [
        SELECT DAY_ONLY(CreatedDate) activityDate, COUNT_DISTINCT(SignerEmail__c) activeUsers
        FROM Signature_Request__c
        WHERE CreatedDate >= :startDate AND SignerEmail__c != null
        GROUP BY DAY_ONLY(CreatedDate)
        ORDER BY DAY_ONLY(CreatedDate)
    ];
    engagement.put('dailyActiveUsers', dailyUsers);
    
    // User retention analysis
    List<AggregateResult> retention = [
        SELECT SignerEmail__c,
               MIN(CreatedDate) firstActivity,
               MAX(CreatedDate) lastActivity,
               COUNT(Id) totalActivities
        FROM Signature_Request__c
        WHERE CreatedDate >= :startDate AND SignerEmail__c != null
        GROUP BY SignerEmail__c
        HAVING COUNT(Id) > 1
    ];
    engagement.put('userRetention', retention.size());
    
    // Engagement scoring
    Decimal avgEngagementScore = calculateAverageEngagementScore(startDate);
    engagement.put('averageEngagementScore', avgEngagementScore);
    engagement.put('engagementGrade', getGradeFromScore(avgEngagementScore));
    
    return engagement;
}

private static Map<String, Object> generateComplianceDashboard(Date startDate) {
    Map<String, Object> compliance = new Map<String, Object>();
    
   List<Object> completions = new List<Object>();

// Total requests per day
List<AggregateResult> totalRequests = [
    SELECT DAY_ONLY(CreatedDate) completionDate,
           COUNT(Id) totalRequests
    FROM Signature_Request__c
    WHERE CreatedDate >= LAST_N_DAYS:90
    GROUP BY DAY_ONLY(CreatedDate)
    ORDER BY DAY_ONLY(CreatedDate)
];

// Completed requests per day
List<AggregateResult> completedRequests = [
    SELECT DAY_ONLY(CreatedDate) completionDate,
           COUNT(Id) completedRequests
    FROM Signature_Request__c
    WHERE CreatedDate >= LAST_N_DAYS:90 AND Status__c = 'Completed'
    GROUP BY DAY_ONLY(CreatedDate)
    ORDER BY DAY_ONLY(CreatedDate)
];
    // Total compliance checks and average score
List<AggregateResult> complianceStats = [
    SELECT COUNT(Id) totalChecks, AVG(Overall_Compliance_Score__c) avgScore
    FROM DocumentLifecycleConfiguration__c
    WHERE CreatedDate >= :startDate
];

// Compliant documents count
Integer compliantDocs = [
    SELECT COUNT()
    FROM DocumentLifecycleConfiguration__c
    WHERE CreatedDate >= :startDate AND Overall_Compliance_Score__c >= 80
];
    if (!complianceStats.isEmpty()) {
        AggregateResult stats = complianceStats[0];
        Integer totalChecks = (Integer)stats.get('totalChecks');
        Decimal avgScore = (Decimal)stats.get('avgScore');
        
        compliance.put('totalComplianceChecks', totalChecks);
        compliance.put('compliantDocuments', compliantDocs);
        compliance.put('complianceRate', totalChecks > 0 ? (compliantDocs * 100.0) / totalChecks : 0);
        compliance.put('averageComplianceScore', avgScore);
    }
    
    // Compliance by region
   // Fetch records grouped by region
List<DocumentLifecycleConfiguration__c> docs = [
    SELECT Region__c, Overall_Compliance_Score__c
    FROM DocumentLifecycleConfiguration__c
    WHERE CreatedDate >= :startDate AND Region__c != null
];

// Initialize map to store regional metrics
Map<String, Map<String, Object>> regionalCompliance = new Map<String, Map<String, Object>>();

// Calculate metrics in Apex
for (DocumentLifecycleConfiguration__c doc : docs) {
    if (!regionalCompliance.containsKey(doc.Region__c)) {
        regionalCompliance.put(doc.Region__c, new Map<String, Object>{
            'regionalDocs' => 0,
            'compliantRegionalDocs' => 0,
            'sumRegionalScores' => 0
        });
    }
    
    Map<String, Object> metrics = regionalCompliance.get(doc.Region__c);
    
    metrics.put('regionalDocs', (Integer)metrics.get('regionalDocs') + 1);
    
    Decimal score = doc.Overall_Compliance_Score__c != null ? doc.Overall_Compliance_Score__c : 0;
    metrics.put('sumRegionalScores', (Decimal)metrics.get('sumRegionalScores') + score);
    
    if (score >= 80) {
        metrics.put('compliantRegionalDocs', (Integer)metrics.get('compliantRegionalDocs') + 1);
    }
}

// Calculate average scores for each region
for (String region : regionalCompliance.keySet()) {
    Map<String, Object> metrics = regionalCompliance.get(region);
    Integer count = (Integer)metrics.get('regionalDocs');
    Decimal sumScores = (Decimal)metrics.get('sumRegionalScores');
    metrics.put('avgRegionalScore', count > 0 ? sumScores / count : 0);
    
    // Remove temporary sum field
    metrics.remove('sumRegionalScores');
}

    compliance.put('regionalCompliance', regionalCompliance);
    
    // Compliance violations
    List<AggregateResult> violations = [
        SELECT Violation_Type__c, COUNT(Id) violationCount
        FROM Compliance_Violation__c
        WHERE Violation_Date__c >= :startDate
        GROUP BY Violation_Type__c
        ORDER BY COUNT(Id) DESC
    ];
    compliance.put('topViolations', violations);
    
    return compliance;
}

private static Decimal calculateGrowthRate(String metricType, Date startDate) {
    try {
        switch on metricType {
            when 'documents' {
                List<AggregateResult> currentPeriod = [
                    SELECT COUNT(Id) currentCount
                    FROM DocumentLifecycleConfiguration__c
                    WHERE CreatedDate >= :startDate
                ];
                
                List<AggregateResult> previousPeriod = [
                    SELECT COUNT(Id) previousCount
                    FROM DocumentLifecycleConfiguration__c
                    WHERE CreatedDate >= :startDate.addDays(-30) 
                    AND CreatedDate < :startDate
                ];
                
                if (!currentPeriod.isEmpty() && !previousPeriod.isEmpty()) {
                    Integer current = (Integer)currentPeriod[0].get('currentCount');
                    Integer previous = (Integer)previousPeriod[0].get('previousCount');
                    return previous > 0 ? ((current - previous) * 100.0) / previous : 0;
                }
            }
            when 'users' {
                List<AggregateResult> currentUsers = [
                    SELECT COUNT_DISTINCT(SignerEmail__c) currentUserCount
                    FROM Signature_Request__c
                    WHERE CreatedDate >= :startDate AND SignerEmail__c != null
                ];
                
                List<AggregateResult> previousUsers = [
                    SELECT COUNT_DISTINCT(SignerEmail__c) previousUserCount
                    FROM Signature_Request__c
                    WHERE CreatedDate >= :startDate.addDays(-30) 
                    AND CreatedDate < :startDate AND SignerEmail__c != null
                ];
                
                if (!currentUsers.isEmpty() && !previousUsers.isEmpty()) {
                    Integer current = (Integer)currentUsers[0].get('currentUserCount');
                    Integer previous = (Integer)previousUsers[0].get('previousUserCount');
                    return previous > 0 ? ((current - previous) * 100.0) / previous : 0;
                }
            }
            when 'completions' {
                List<AggregateResult> currentCompletions = [
                    SELECT COUNT(Id) completedCount
                    FROM Signature_Request__c
                    WHERE CreatedDate >= :startDate AND Status__c = 'Completed'
                ];
                
                List<AggregateResult> previousCompletions = [
                    SELECT COUNT(Id) completedCount
                    FROM Signature_Request__c
                    WHERE CreatedDate >= :startDate.addDays(-30) 
                    AND CreatedDate < :startDate AND Status__c = 'Completed'
                ];
                
                if (!currentCompletions.isEmpty() && !previousCompletions.isEmpty()) {
                    Integer current = (Integer)currentCompletions[0].get('completedCount');
                    Integer previous = (Integer)previousCompletions[0].get('completedCount');
                    return previous > 0 ? ((current - previous) * 100.0) / previous : 0;
                }
            }
        }
    } catch (Exception e) {
        System.debug('Growth rate calculation error: ' + e.getMessage());
    }
    return 0;
}

private static Decimal calculateAverageEngagementScore(Date startDate) {
    List<AggregateResult> engagementData = [
        SELECT AVG(Session_Duration_Minutes__c) avgSessionDuration,
               AVG(Actions_Per_Session__c) avgActionsPerSession,
               COUNT_DISTINCT(SignerEmail__c) uniqueUsers
        FROM User_Session__c
        WHERE Session_Date__c >= :startDate
    ];
    
    if (!engagementData.isEmpty()) {
        AggregateResult data = engagementData[0];
        Decimal avgDuration = (Decimal)data.get('avgSessionDuration') ?? 0;
        Decimal avgActions = (Decimal)data.get('avgActionsPerSession') ?? 0;
        
        // Calculate engagement score based on session duration and activity
        Decimal durationScore = Math.min(avgDuration / 10, 50); // Max 50 points for 10+ minutes
        Decimal activityScore = Math.min(avgActions * 5, 50); // Max 50 points for 10+ actions
        
        return durationScore + activityScore;
    }
    
    return 50; // Default neutral score
}

// Helper method to convert engagement score to grade
private static String getGradeFromScore(Decimal score) {
    if (score >= 90) {
        return 'A+';
    } else if (score >= 80) {
        return 'A';
    } else if (score >= 70) {
        return 'B';
    } else if (score >= 60) {
        return 'C';
    } else if (score >= 50) {
        return 'D';
    } else {
        return 'F';
    }
}


} // end of AdvancedAnalyticsDashboardController class
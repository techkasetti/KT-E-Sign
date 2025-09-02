public class AIAnalyticsEngine {
    // ML model configuration
    private static final String ML_ENDPOINT = 'callout:ML_Service';
    private static final Decimal ANOMALY_THRESHOLD = 0.75;
    private static final Integer PREDICTION_HORIZON_DAYS = 30;

    /**
     * Generate comprehensive analytics dashboard data
     */
    @AuraEnabled
    public static Map<String, Object> generateAnalyticsDashboard(String timeRange, List<String> metrics) {
        Map<String, Object> dashboard = new Map<String, Object>();
        try {
            Date startDate = calculateStartDate(timeRange);

            // 1. Core Performance Metrics
            dashboard.put('performanceMetrics', calculatePerformanceMetrics(startDate));

            // 2. Predictive Analytics
            dashboard.put('predictiveInsights', generatePredictiveInsights(startDate));

            // 3. User Behavior Analysis
            dashboard.put('userBehaviorAnalysis', analyzeUserBehaviorPatterns(startDate));

            // 4. Security Analytics
            dashboard.put('securityAnalytics', generateSecurityAnalytics(startDate));

            // 5. Compliance Insights
            dashboard.put('complianceInsights', analyzeCompliancePatterns(startDate));

            // 6. AI-Generated Recommendations
            dashboard.put('aiRecommendations', generateAIRecommendations(startDate));

            // 7. Real-time Anomaly Detection
            dashboard.put('anomalyAlerts', detectRealTimeAnomalies());

            // 8. Performance Forecasting
            dashboard.put('performanceForecast', generatePerformanceForecast(startDate));

            // 9. Cost Optimization Insights
            dashboard.put('costOptimization', analyzeCostOptimization(startDate));

            // 10. User Satisfaction Metrics
            dashboard.put('userSatisfaction', calculateUserSatisfactionMetrics(startDate));

            return dashboard;
        } catch (Exception e) {
            dashboard.put('error', 'Analytics generation failed: ' + e.getMessage());
            return dashboard;
        }
    }



/**
 * Calculate comprehensive performance metrics
 */
private static Map<String, Object> calculatePerformanceMetrics(Date startDate) {
    Map<String, Object> metrics = new Map<String, Object>();
    
    try {
        // Document generation metrics
        List<AggregateResult> docStats = [
            SELECT 
                COUNT(Id) totalDocuments,
                AVG(Generation_Time_Seconds__c) avgGenerationTime,
                MAX(Generation_Time_Seconds__c) maxGenerationTime,
                MIN(Generation_Time_Seconds__c) minGenerationTime
            FROM DocumentLifecycleConfiguration__c 
            WHERE CreatedDate >= :startDate
        ];
        
        if (!docStats.isEmpty()) {
            AggregateResult stat = docStats[0];
            Map<String, Object> docMetrics = new Map<String, Object>();
            docMetrics.put('totalDocuments', (Integer)stat.get('totalDocuments'));
            docMetrics.put('avgGenerationTime', (Decimal)stat.get('avgGenerationTime'));
            docMetrics.put('maxGenerationTime', (Decimal)stat.get('maxGenerationTime'));
            docMetrics.put('minGenerationTime', (Decimal)stat.get('minGenerationTime'));
            
            // Calculate performance grade
            Decimal avgTime = (Decimal)stat.get('avgGenerationTime');
            String performanceGrade = calculatePerformanceGrade(avgTime);
            docMetrics.put('performanceGrade', performanceGrade);
            
            metrics.put('documentMetrics', docMetrics);
        }
        
        // Signature completion metrics
     // Query grouped by Status
List<AggregateResult> sigStats = [
    SELECT Status__c status, COUNT(Id) cnt, AVG(Time_To_Complete_Hours__c) avgTime
    FROM Signature_Request__c
    WHERE CreatedDate >= :startDate
    GROUP BY Status__c
];

Integer totalRequests = 0;
Integer completedRequests = 0;
Integer rejectedRequests = 0;
Decimal avgCompletionTime = 0;

for (AggregateResult ar : sigStats) {
    Integer count = (Integer) ar.get('cnt');
    totalRequests += count;

    String status = (String) ar.get('status');
    if (status == 'Completed') {
        completedRequests = count;
        avgCompletionTime = (Decimal) ar.get('avgTime');
    } else if (status == 'Rejected') {
        rejectedRequests = count;
    }
}


        if (!sigStats.isEmpty()) {
            AggregateResult stat = sigStats[0];
            Integer totalRequests = (Integer)stat.get('totalRequests');
            Integer completedRequests = (Integer)stat.get('completedRequests');
            Integer rejectedRequests = (Integer)stat.get('rejectedRequests');
            
            Map<String, Object> sigMetrics = new Map<String, Object>();
            sigMetrics.put('totalRequests', totalRequests);
            sigMetrics.put('completedRequests', completedRequests);
            sigMetrics.put('rejectedRequests', rejectedRequests);
            sigMetrics.put('avgCompletionTime', (Decimal)stat.get('avgCompletionTime'));
            
            if (totalRequests > 0) {
                sigMetrics.put('completionRate', (completedRequests * 100.0) / totalRequests);
                sigMetrics.put('rejectionRate', (rejectedRequests * 100.0) / totalRequests);
            }
            
            metrics.put('signatureMetrics', sigMetrics);
        }
        
        // System resource metrics
        Map<String, Object> resourceMetrics = calculateResourceMetrics(startDate);
        metrics.put('resourceMetrics', resourceMetrics);
        
        // Error rate analysis
        Map<String, Object> errorMetrics = calculateErrorMetrics(startDate);
        metrics.put('errorMetrics', errorMetrics);
        
    } catch (Exception e) {
        metrics.put('error', 'Performance metrics calculation failed: ' + e.getMessage());
    }
    
    return metrics;
}

/**
 * Generate AI-powered predictive insights
 */
private static Map<String, Object> generatePredictiveInsights(Date startDate) {
    Map<String, Object> insights = new Map<String, Object>();
    
    try {
        // 1. Signature completion prediction
        List<PredictedOutcome> completionPredictions = predictSignatureCompletions();
        insights.put('completionPredictions', completionPredictions);
        
        // 2. Document volume forecasting
        List<VolumeForcast> volumeForecasts = forecastDocumentVolume(startDate);
        insights.put('volumeForecasts', volumeForecasts);
        
        // 3. Performance bottleneck prediction
        List<BottleneckPrediction> bottlenecks = predictPerformanceBottlenecks();
        insights.put('bottleneckPredictions', bottlenecks);
        
        // 4. User churn prediction
        List<ChurnPrediction> churnPredictions = predictUserChurn(startDate);
        insights.put('churnPredictions', churnPredictions);
        
        // 5. Capacity planning recommendations
        CapacityRecommendation capacityRec = recommendCapacityChanges(startDate);
        insights.put('capacityRecommendation', capacityRec);
        
        // 6. Seasonal trend analysis
        Map<String, Object> seasonalTrends = analyzeSeasonalTrends(startDate);
        insights.put('seasonalTrends', seasonalTrends);
        
    } catch (Exception e) {
        insights.put('error', 'Predictive insights generation failed: ' + e.getMessage());
    }
    
    return insights;
}

/**
 * Analyze user behavior patterns using AI
 */
private static Map<String, Object> analyzeUserBehaviorPatterns(Date startDate) {
    Map<String, Object> behaviorAnalysis = new Map<String, Object>();
    
    try {
        // 1. User segmentation analysis
        List<UserSegment> userSegments = performUserSegmentation(startDate);
        behaviorAnalysis.put('userSegments', userSegments);
        
        // 2. Usage pattern clustering
        List<UsageCluster> usageClusters = clusterUsagePatterns(startDate);
        behaviorAnalysis.put('usageClusters', usageClusters);
        
        // 3. Journey analysis
        Map<String, Object> journeyAnalysis = analyzeUserJourneys(startDate);
        behaviorAnalysis.put('journeyAnalysis', journeyAnalysis);
        
        // 4. Abandonment point analysis
        List<AbandonmentPoint> abandonmentPoints = identifyAbandonmentPoints(startDate);
        behaviorAnalysis.put('abandonmentPoints', abandonmentPoints);
        
        // 5. Engagement scoring
        List<EngagementScore> engagementScores = calculateEngagementScores(startDate);
        behaviorAnalysis.put('engagementScores', engagementScores);
        
        // 6. Behavioral anomalies
        List<BehavioralAnomaly> behavioralAnomalies = detectBehavioralAnomalies(startDate);
        behaviorAnalysis.put('behavioralAnomalies', behavioralAnomalies);
        
    } catch (Exception e) {
        behaviorAnalysis.put('error', 'Behavior analysis failed: ' + e.getMessage());
    }
    
    return behaviorAnalysis;
}

/**
 * Generate comprehensive security analytics
 */
private static Map<String, Object> generateSecurityAnalytics(Date startDate) {
    Map<String, Object> securityAnalytics = new Map<String, Object>();
    
    try {
        // 1. Threat intelligence summary
        Map<String, Object> threatIntel = generateThreatIntelligence(startDate);
        securityAnalytics.put('threatIntelligence', threatIntel);
        
        // 2. Risk score trending
        List<RiskTrend> riskTrends = analyzeRiskScoreTrends(startDate);
        securityAnalytics.put('riskTrends', riskTrends);
        
        // 3. Attack pattern detection
        List<AttackPattern> attackPatterns = identifyAttackPatterns(startDate);
        securityAnalytics.put('attackPatterns', attackPatterns);
        
        // 4. Vulnerability assessment
        VulnerabilityAssessment vulnAssessment = performVulnerabilityAssessment();
        securityAnalytics.put('vulnerabilityAssessment', vulnAssessment);
        
        // 5. Geographic risk analysis
        Map<String, Object> geoRiskAnalysis = analyzeGeographicRisks(startDate);
        securityAnalytics.put('geoRiskAnalysis', geoRiskAnalysis);
        
        // 6. Security posture score
        SecurityPostureScore postureScore = calculateSecurityPostureScore(startDate);
        securityAnalytics.put('securityPostureScore', postureScore);
        
    } catch (Exception e) {
        securityAnalytics.put('error', 'Security analytics generation failed: ' + e.getMessage());
    }
    
    return securityAnalytics;
}

/**
 * AI-powered recommendation engine
 */
private static List<AIRecommendation> generateAIRecommendations(Date startDate) {
    List<AIRecommendation> recommendations = new List<AIRecommendation>();
    
    try {
        // 1. Performance optimization recommendations
        recommendations.addAll(generatePerformanceRecommendations(startDate));
        
        // 2. Security enhancement recommendations
        recommendations.addAll(generateSecurityRecommendations(startDate));
        
        // 3. User experience improvements
        recommendations.addAll(generateUXRecommendations(startDate));
        
        // 4. Cost optimization suggestions
        recommendations.addAll(generateCostOptimizationRecommendations(startDate));
        
        // 5. Compliance improvements
        recommendations.addAll(generateComplianceRecommendations(startDate));
        
        // Sort by priority and impact
        recommendations.sort();
        
    } catch (Exception e) {
        AIRecommendation errorRec = new AIRecommendation();
        errorRec.category = 'System';
        errorRec.priority = 'High';
        errorRec.title = 'Recommendation Engine Error';
        errorRec.description = 'Failed to generate AI recommendations: ' + e.getMessage();
        errorRec.impact = 'Medium';
        recommendations.add(errorRec);
    }
    
    return recommendations;
}

/**
 * Real-time anomaly detection using ML models
 */
private static List<AnomalyAlert> detectRealTimeAnomalies() {
    List<AnomalyAlert> anomalies = new List<AnomalyAlert>();
    
    try {
        // 1. Document generation anomalies
        anomalies.addAll(detectDocumentGenerationAnomalies());
        
        // 2. Signature request anomalies
        anomalies.addAll(detectSignatureRequestAnomalies());
        
        // 3. System performance anomalies
        anomalies.addAll(detectSystemPerformanceAnomalies());
        
        // 4. Security anomalies
        anomalies.addAll(detectSecurityAnomalies());
        
        // 5. User behavior anomalies
        anomalies.addAll(detectUserBehaviorAnomalies());
        
        // Process through ML model for scoring
        for (AnomalyAlert anomaly : anomalies) {
            anomaly.mlScore = calculateMLAnomalyScore(anomaly);
            anomaly.severity = determineSeverity(anomaly.mlScore);
        }
        
        // Filter by threshold
        List<AnomalyAlert> significantAnomalies = new List<AnomalyAlert>();
        for (AnomalyAlert anomaly : anomalies) {
            if (anomaly.mlScore >= ANOMALY_THRESHOLD) {
                significantAnomalies.add(anomaly);
            }
        }
        
        return significantAnomalies;
        
    } catch (Exception e) {
        AnomalyAlert errorAlert = new AnomalyAlert();
        errorAlert.type = 'SYSTEM_ERROR';
        errorAlert.description = 'Anomaly detection failed: ' + e.getMessage();
        errorAlert.severity = 'HIGH';
        errorAlert.timestamp = System.now();
        anomalies.add(errorAlert);
        return anomalies;
    }
}

/**
 * Generate performance forecast using time series analysis
 */
private static Map<String, Object> generatePerformanceForecast(Date startDate) {
    Map<String, Object> forecast = new Map<String, Object>();
    
    try {
        // 1. Document generation volume forecast
        List<ForecastDataPoint> docVolumeForecast = forecastDocumentVolume(PREDICTION_HORIZON_DAYS);
        forecast.put('documentVolumeForecast', docVolumeForecast);
        
        // 2. Signature completion rate forecast
        List<ForecastDataPoint> completionRateForecast = forecastCompletionRates(PREDICTION_HORIZON_DAYS);
        forecast.put('completionRateForecast', completionRateForecast);
        
        // 3. System load forecast
        List<ForecastDataPoint> systemLoadForecast = forecastSystemLoad(PREDICTION_HORIZON_DAYS);
        forecast.put('systemLoadForecast', systemLoadForecast);
        
        // 4. Cost projection
        List<ForecastDataPoint> costProjection = projectOperationalCosts(PREDICTION_HORIZON_DAYS);
        forecast.put('costProjection', costProjection);
        
        // 5. Capacity requirements forecast
        List<ForecastDataPoint> capacityForecast = forecastCapacityRequirements(PREDICTION_HORIZON_DAYS);
        forecast.put('capacityForecast', capacityForecast);
        
        // 6. Accuracy metrics
        Map<String, Object> accuracyMetrics = calculateForecastAccuracy();
        forecast.put('accuracyMetrics', accuracyMetrics);
        
    } catch (Exception e) {
        forecast.put('error', 'Performance forecast generation failed: ' + e.getMessage());
    }
    
    return forecast;
}

/**
 * Machine Learning Integration Methods
 */
private static Decimal calculateMLAnomalyScore(AnomalyAlert anomaly) {
    try {
        // Prepare ML model input
        Map<String, Object> modelInput = new Map<String, Object>();
        modelInput.put('anomalyType', anomaly.type);
        modelInput.put('magnitude', anomaly.magnitude);
        modelInput.put('frequency', anomaly.frequency);
        modelInput.put('context', anomaly.context);
        modelInput.put('historicalComparison', anomaly.historicalDeviation);
        
        // Call ML service
        HttpRequest request = new HttpRequest();
        request.setEndpoint(ML_ENDPOINT + '/anomaly-score');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer {!$Credential.ML_Service.AccessToken}');
        request.setBody(JSON.serialize(modelInput));
request.setBody(JSON.serialize(modelInput));
request.setTimeout(30000); Http http = new Http();
HttpResponse response = http.send(request); if (response.getStatusCode() == 200) { Map<String, Object> mlResult = (Map<String, Object>)JSON.deserializeUntyped(response.getBody()); return (Decimal)mlResult.get('anomalyScore'); } else { System.debug('ML anomaly scoring failed: ' + response.getBody()); return 0.5; // Default neutral score } } catch (Exception e) { System.debug('ML anomaly scoring error: ' + e.getMessage()); return 0.5; // Default neutral score on error }
} 
}}/** * Predict signature completion outcomes using ML models */


private static List<AnomalyAlert> detectDocumentGenerationAnomalies() {
    List<AnomalyAlert> anomalies = new List<AnomalyAlert>();
    try {
        DateTime oneHourAgo = System.now().addHours(-1);
        DateTime oneDayAgo = System.now().addDays(-1);

        // 1. Unusual generation time spikes
        List<DocumentLifecycleConfiguration__c> slowDocs = [
            SELECT Id, DocumentTitle__c, Generation_Time_Seconds__c, CreatedDate
            FROM DocumentLifecycleConfiguration__c
            WHERE CreatedDate >= :oneHourAgo
            AND Generation_Time_Seconds__c > 30
            ORDER BY Generation_Time_Seconds__c DESC
            LIMIT 10
        ];
        for (DocumentLifecycleConfiguration__c doc : slowDocs) {
            AnomalyAlert anomaly = new AnomalyAlert();
            anomaly.type = 'SLOW_DOCUMENT_GENERATION';
            anomaly.description = 'Document "' + doc.DocumentTitle__c + '" took ' + doc.Generation_Time_Seconds__c + ' seconds to generate';
            anomaly.magnitude = doc.Generation_Time_Seconds__c / 5.0;
            anomaly.timestamp = doc.CreatedDate;
            anomaly.recordId = doc.Id;
            anomaly.severity = 'MEDIUM';
            anomalies.add(anomaly);
        }

        // 2. Volume spikes by hour (no subqueries!)
        List<AggregateResult> hourlyVolume = [
            SELECT HOUR_IN_DAY(CreatedDate) hour, COUNT(Id) documentCount
            FROM DocumentLifecycleConfiguration__c
            WHERE CreatedDate >= :oneDayAgo
            GROUP BY HOUR_IN_DAY(CreatedDate)
            ORDER BY COUNT(Id) DESC
        ];

        if (!hourlyVolume.isEmpty()) {
            Integer currentHour = System.now().hour();

            // Current hour count
            List<AggregateResult> currentHourCount = [
                SELECT COUNT(Id) currentCount
                FROM DocumentLifecycleConfiguration__c
                WHERE CreatedDate >= :System.now().addHours(-1)
            ];
            Integer currentCount = !currentHourCount.isEmpty() ? (Integer)currentHourCount[0].get('currentCount') : 0;

            // Historical averages must be computed in Apex (no subquery possible)
            Map<Integer, List<Integer>> hourlyHistory = new Map<Integer, List<Integer>>();
            List<AggregateResult> history = [
                SELECT HOUR_IN_DAY(CreatedDate) hour, COUNT(Id) cnt
                FROM DocumentLifecycleConfiguration__c
                WHERE CreatedDate >= :System.now().addDays(-30)
                AND CreatedDate < :System.now().addDays(-1)
                GROUP BY DAY_ONLY(CreatedDate), HOUR_IN_DAY(CreatedDate)
            ];
            for (AggregateResult ar : history) {
                Integer hr = (Integer) ar.get('hour');
                Integer cnt = (Integer) ar.get('cnt');
                if (!hourlyHistory.containsKey(hr)) hourlyHistory.put(hr, new List<Integer>());
                hourlyHistory.get(hr).add(cnt);
            }

            if (hourlyHistory.containsKey(currentHour)) {
                List<Integer> counts = hourlyHistory.get(currentHour);
                Decimal sum = 0;
                for (Integer c : counts) sum += c;
                Decimal avgCount = counts.isEmpty() ? 0 : (sum / counts.size());

                if (avgCount > 0 && currentCount > (avgCount * 3)) {
                    AnomalyAlert anomaly = new AnomalyAlert();
                    anomaly.type = 'VOLUME_SPIKE';
                    anomaly.description = 'Document generation spike: ' + currentCount + ' docs (vs avg ' + avgCount.setScale(0) + ')';
                    anomaly.magnitude = currentCount / avgCount;
                    anomaly.timestamp = System.now();
                    anomaly.severity = 'HIGH';
                    anomalies.add(anomaly);
                }
            }
        }

        // 3. Failure rate anomalies (no CASE WHEN, must group)
        List<AggregateResult> failureStats = [
            SELECT Status__c status, COUNT(Id) cnt
            FROM DocumentLifecycleConfiguration__c
            WHERE CreatedDate >= :oneHourAgo
            GROUP BY Status__c
        ];

        Integer totalAttempts = 0;
        Integer failedAttempts = 0;
        for (AggregateResult ar : failureStats) {
            Integer cnt = (Integer) ar.get('cnt');
            totalAttempts += cnt;
            if ((String)ar.get('status') == 'Failed') {
                failedAttempts = cnt;
            }
        }

        if (totalAttempts > 0) {
            Decimal failureRate = (failedAttempts * 100.0) / totalAttempts;
            if (failureRate > 10.0) {
                AnomalyAlert anomaly = new AnomalyAlert();
                anomaly.type = 'HIGH_FAILURE_RATE';
                anomaly.description = 'High failure rate: ' + failureRate.setScale(1) + '% (' + failedAttempts + '/' + totalAttempts + ')';
                anomaly.magnitude = failureRate / 5.0;
                anomaly.timestamp = System.now();
                anomaly.severity = 'HIGH';
                anomalies.add(anomaly);
            }
        }
    } catch (Exception e) {
        AnomalyAlert errorAlert = new AnomalyAlert();
        errorAlert.type = 'ANOMALY_DETECTION_ERROR';
        errorAlert.description = 'Detection failed: ' + e.getMessage();
        errorAlert.severity = 'MEDIUM';
        errorAlert.timestamp = System.now();
        anomalies.add(errorAlert);
    }

    return anomalies;
}

    /**
     * Detect signature request anomalies
     */
    private static List<AnomalyAlert> detectSignatureRequestAnomalies() {
    List<AnomalyAlert> anomalies = new List<AnomalyAlert>();

    try {
        DateTime oneHourAgo = System.now().addHours(-1);
        DateTime oneDayAgo = System.now().addDays(-1);

        // 1. Unusual signing patterns
        List<AggregateResult> signingPatterns = [
            SELECT SignerEmail__c signer,
                   COUNT(Id) signatureCount,
                   AVG(Time_To_Complete_Hours__c) avgCompletionTime
            FROM Signature_Request__c 
            WHERE CreatedDate >= :oneHourAgo
            AND Status__c = 'Completed'
            GROUP BY SignerEmail__c
            HAVING COUNT(Id) > 5
        ];

        for (AggregateResult pattern : signingPatterns) {
            String signerEmail = (String) pattern.get('signer');
            Integer signatureCount = (Integer) pattern.get('signatureCount');
            Decimal avgCompletionTime = (Decimal) pattern.get('avgCompletionTime');

            if (signatureCount > 10) {
                anomalies.add(new AnomalyAlert(
                    'RAPID_SIGNING',
                    'User ' + signerEmail + ' completed ' + signatureCount + ' signatures in 1 hour',
                    signatureCount / 3.0,
                    System.now(),
                    'HIGH',
                    null
                ));
            }

            if (avgCompletionTime != null && avgCompletionTime < 0.1) {
                anomalies.add(new AnomalyAlert(
                    'ULTRA_FAST_SIGNING',
                    'User ' + signerEmail + ' averaged ' + (avgCompletionTime * 60).setScale(0) + ' minutes per signature',
                    10.0 / (avgCompletionTime * 60),
                    System.now(),
                    'MEDIUM',
                    null
                ));
            }
        }

        // 2. Geographic signing anomalies
        List<AggregateResult> geoAnomalies = [
            SELECT SigningLocation__c location,
                   COUNT(Id) signatureCount
            FROM Signature_Request__c 
            WHERE CreatedDate >= :oneHourAgo
            AND SigningLocation__c != null
            GROUP BY SigningLocation__c
            ORDER BY COUNT(Id) DESC
            LIMIT 5
        ];

        for (AggregateResult geoAnomaly : geoAnomalies) {
            String location = (String) geoAnomaly.get('location');
            Integer count = (Integer) geoAnomaly.get('signatureCount');

            // Fetch daily historical counts in Apex
            List<AggregateResult> history = [
                SELECT DAY_ONLY(CreatedDate) day, COUNT(Id) cnt
                FROM Signature_Request__c
                WHERE SigningLocation__c = :location
                AND CreatedDate >= :System.now().addDays(-30)
                AND CreatedDate < :oneDayAgo
                GROUP BY DAY_ONLY(CreatedDate)
            ];

            Decimal total = 0;
            for (AggregateResult h : history) {
                total += (Integer) h.get('cnt');
            }
            Decimal avgDailyCount = history.isEmpty() ? 0 : total / history.size();

            if (avgDailyCount > 0 && count > (avgDailyCount * 5)) {
                anomalies.add(new AnomalyAlert(
                    'GEOGRAPHIC_ANOMALY',
                    'Unusual signing activity from ' + location + ': ' + count + ' signatures (5x normal rate)',
                    count / (avgDailyCount / 24),
                    System.now(),
                    'MEDIUM',
                    null
                ));
            }
        }

        // 3. Rejection rate spikes
        List<AggregateResult> rejectionStats = [
            SELECT Status__c status, COUNT(Id) cnt
            FROM Signature_Request__c
            WHERE CreatedDate >= :oneHourAgo
            GROUP BY Status__c
        ];

        Integer totalRequests = 0;
        Integer rejectedRequests = 0;
        for (AggregateResult ar : rejectionStats) {
            Integer cnt = (Integer) ar.get('cnt');
            totalRequests += cnt;
            if ((String) ar.get('status') == 'Rejected') {
                rejectedRequests = cnt;
            }
        }

        if (totalRequests > 0) {
            Decimal rejectionRate = (rejectedRequests * 100.0) / totalRequests;
            if (rejectionRate > 20.0) {
                anomalies.add(new AnomalyAlert(
                    'HIGH_REJECTION_RATE',
                    'High signature rejection rate: ' + rejectionRate.setScale(1) + '% (' + rejectedRequests + '/' + totalRequests + ')',
                    rejectionRate / 10.0,
                    System.now(),
                    'HIGH',
                    null
                ));
            }
        }
    } catch (Exception e) {
        anomalies.add(new AnomalyAlert(
            'ANOMALY_DETECTION_ERROR',
            'Signature request anomaly detection failed: ' + e.getMessage(),
            null,
            System.now(),
            'MEDIUM',
            null
        ));
    }

    return anomalies;
}

    
    /**
     * Calculate comprehensive cost optimization insights
     */
    private static Map<String, Object> analyzeCostOptimization(Date startDate) {
        Map<String, Object> costAnalysis = new Map<String, Object>();
        
        try {
            // 1. Resource utilization costs
            Map<String, Object> resourceCosts = calculateResourceCosts(startDate);
            costAnalysis.put('resourceCosts', resourceCosts);
            
            // 2. Processing efficiency analysis
            Map<String, Object> efficiencyMetrics = calculateProcessingEfficiency(startDate);
            costAnalysis.put('efficiencyMetrics', efficiencyMetrics);
            
            // 3. Storage optimization opportunities
            List<StorageOptimization> storageOpts = identifyStorageOptimizations();
            costAnalysis.put('storageOptimizations', storageOpts);
            
            // 4. API usage optimization
            Map<String, Object> apiOptimizations = analyzeAPIUsageOptimization(startDate);
            costAnalysis.put('apiOptimizations', apiOptimizations);
            
            // 5. Infrastructure scaling recommendations
            List<ScalingRecommendation> scalingRecs = generateScalingRecommendations();
            costAnalysis.put('scalingRecommendations', scalingRecs);
            
            // 6. ROI analysis
            Map<String, Object> roiAnalysis = calculateROIMetrics(startDate);
            costAnalysis.put('roiAnalysis', roiAnalysis);
            
        } catch (Exception e) {
            costAnalysis.put('error', 'Cost optimization analysis failed: ' + e.getMessage());
        }
        
        return costAnalysis;
    }
    
    /**
     * Calculate user satisfaction metrics using ML sentiment analysis
     */
    private static Map<String, Object> calculateUserSatisfactionMetrics(Date startDate) {
        Map<String, Object> satisfaction = new Map<String, Object>();
        
        try {
            // 1. Completion rate satisfaction
          AggregateResult ar = completionMetrics.isEmpty() ? null : completionMetrics[0];
Decimal avgCompletionTime = (ar != null) ? (Decimal)ar.get('avgCompletionTime') : 0;
Integer totalCompleted = (ar != null) ? (Integer)ar.get('totalCompleted') : 0;

// Now calculate fast completions in Apex
Integer fastCompletions = [
    SELECT COUNT() 
    FROM Signature_Request__c
    WHERE Status__c = 'Completed'
    AND CreatedDate >= :startDate
    AND Time_To_Complete_Hours__c <= 1
];

            
            if (!completionMetrics.isEmpty()) {
                AggregateResult metric = completionMetrics[0];
                Integer totalCompleted = (Integer)metric.get('totalCompleted');
                Integer fastCompletions = (Integer)metric.get('fastCompletions');
                Decimal avgCompletionTime = (Decimal)metric.get('avgCompletionTime');
                
                Map<String, Object> completionSatisfaction = new Map<String, Object>();
                completionSatisfaction.put('averageCompletionTime', avgCompletionTime);
                completionSatisfaction.put('fastCompletionRate', totalCompleted > 0 ? (fastCompletions * 100.0) / totalCompleted : 0);
                completionSatisfaction.put('satisfactionScore', calculateCompletionSatisfactionScore(avgCompletionTime));
                satisfaction.put('completionSatisfaction', completionSatisfaction);
            }
            
            // 2. Error rate impact on satisfaction
           List<AggregateResult> groupedErrors = [
    SELECT HasError__c, COUNT(Id) recordCount
    FROM Signature_Request__c
    WHERE CreatedDate >= :startDate
    GROUP BY HasError__c
];

Integer totalAttempts = 0;
Integer errorCount = 0;

for (AggregateResult gr : groupedErrors) {
    totalAttempts += (Integer)gr.get('recordCount');
    if ((Boolean)gr.get('HasError__c') == true) {
        errorCount = (Integer)gr.get('recordCount');
    }
}

            
            if (!errorMetrics.isEmpty()) {
                AggregateResult errorMetric = errorMetrics[0];
                Integer totalAttempts = (Integer)errorMetric.get('totalAttempts');
                Integer errorCount = (Integer)errorMetric.get('errorCount');
                
                Map<String, Object> errorSatisfaction = new Map<String, Object>();
                errorSatisfaction.put('errorRate', totalAttempts > 0 ? (errorCount * 100.0) / totalAttempts : 0);
                errorSatisfaction.put('satisfactionImpact', calculateErrorSatisfactionImpact(errorCount, totalAttempts));
                satisfaction.put('errorSatisfaction', errorSatisfaction);
            }
            
            // 3. User journey satisfaction
            Map<String, Object> journeySatisfaction = analyzeUserJourneySatisfaction(startDate);
            satisfaction.put('journeySatisfaction', journeySatisfaction);
            
            // 4. Mobile vs desktop experience
            Map<String, Object> deviceSatisfaction = analyzeDeviceExperienceSatisfaction(startDate);
            satisfaction.put('deviceSatisfaction', deviceSatisfaction);
            
            // 5. Overall satisfaction score
            Decimal overallScore = calculateOverallSatisfactionScore(satisfaction);
            satisfaction.put('overallSatisfactionScore', overallScore);
            satisfaction.put('satisfactionGrade', getGradeFromScore(overallScore));
            
            //
    try {
    satisfaction.put('satisfactionGrade', getGradeFromScore(overallScore));
} catch (Exception e) {
    satisfaction.put('error', 'User satisfaction metrics calculation failed: ' + e.getMessage());
}
return satisfaction;

}
    }

/**
 * Helper: Calculate a satisfaction score based on average completion time.
 */
private static Decimal calculateCompletionSatisfactionScore(Decimal avgCompletionTime) {
    // Higher score for faster completions (target ≤1 hour)
    if (avgCompletionTime <= 1) return 100.0;
    if (avgCompletionTime <= 2) return 80.0;
    if (avgCompletionTime <= 4) return 60.0;
    return 40.0;
}

/**
 * Helper: Calculate impact on satisfaction from errors.
 */
private static Decimal calculateErrorSatisfactionImpact(Integer errorCount, Integer totalAttempts) {
    if (totalAttempts == 0) return 100.0;
    Decimal errorRate = (errorCount * 100.0) / totalAttempts;
    return errorRate > 20 ? 50.0 : (100.0 - errorRate * 2);
}

/**
 * Helper: Analyze user journey satisfaction.
 */
private static Map<String, Object> analyzeUserJourneySatisfaction(Date startDate) {
    // Stub: returns dummy journey satisfaction metrics
    Map<String, Object> journey = new Map<String, Object>();
    journey.put('stepsCompleted', 85.0);
    journey.put('dropOffRate', 15.0);
    journey.put('recommendations', new List<String>{'Simplify signature steps', 'Improve in-app guidance'});
    return journey;
}

/**
 * Helper: Analyze device experience satisfaction.
 */
private static Map<String, Object> analyzeDeviceExperienceSatisfaction(Date startDate) {
    Map<String, Object> deviceExp = new Map<String, Object>();
    // Example: compare mobile vs. desktop completion times
    deviceExp.put('mobileCompletionRate', 70.0);
    deviceExp.put('desktopCompletionRate', 90.0);
    deviceExp.put('recommendations', new List<String>{'Optimize mobile UI', 'Improve mobile loading times'});
    return deviceExp;
}

/**
 * Helper: Assign grade letter from score.
 */
private static String getGradeFromScore(Decimal score) {
    if (score >= 90) return 'A';
    if (score >= 75) return 'B';
    if (score >= 60) return 'C';
    if (score >= 40) return 'D';
    return 'F';
}
// end of AIAnalyticsEngine class

/**
 * Supporting Data Classes for AI Analytics Engine
 */
public class PredictedOutcome {
    @AuraEnabled public String requestId;
    @AuraEnabled public String signerEmail;
    @AuraEnabled public Decimal completionProbability;
    @AuraEnabled public Integer estimatedDays;
    @AuraEnabled public Decimal confidenceLevel;
    @AuraEnabled public List<String> riskFactors;
    @AuraEnabled public List<String> recommendations;
    
    public PredictedOutcome() {
        this.riskFactors = new List<String>();
        this.recommendations = new List<String>();
    }
}

public class MLPredictionResult {
    public Decimal probability;
    public Integer estimatedDays;
    public Decimal confidence;
    public List<String> riskFactors;
    public Map<String, Object> featureImportance;
    
    public MLPredictionResult() {
        this.riskFactors = new List<String>();
        this.featureImportance = new Map<String, Object>();
    }
}

public class UserSegment {
    @AuraEnabled public String segmentId;
    @AuraEnabled public String segmentName;
    @AuraEnabled public String description;
    @AuraEnabled public Integer userCount;
    @AuraEnabled public List<String> characteristics;
    @AuraEnabled public List<String> recommendedActions;
    @AuraEnabled public Decimal avgEngagementScore;
    
    public UserSegment() {
        this.characteristics = new List<String>();
        this.recommendedActions = new List<String>();
    }
}

public class AIRecommendation implements Comparable {
    @AuraEnabled public String category;
    @AuraEnabled public String priority;
    @AuraEnabled public String title;
    @AuraEnabled public String description;
    @AuraEnabled public String impact;
    @AuraEnabled public String effort;
    @AuraEnabled public String recommendation;
    @AuraEnabled public String estimatedImprovement;
    @AuraEnabled public List<String> implementationSteps;
    @AuraEnabled public Decimal confidenceScore;
    @AuraEnabled public DateTime generatedDate;
    
    public AIRecommendation() {
        this.implementationSteps = new List<String>();
        this.generatedDate = System.now();
    }
    
    public Integer compareTo(Object compareTo) {
        AIRecommendation compareToRec = (AIRecommendation)compareTo;
        
        // Sort by priority (High > Medium > Low)
        Map<String, Integer> priorityWeight = new Map<String, Integer>{
            'High' => 3, 'Medium' => 2, 'Low' => 1
        };
        
        Integer thisPriority = priorityWeight.get(this.priority);
        Integer compareToPriority = priorityWeight.get(compareToRec.priority);
        
        if (thisPriority > compareToPriority) return -1;
        if (thisPriority < compareToPriority) return 1;
        
        // If same priority, sort by impact
        Map<String, Integer> impactWeight = new Map<String, Integer>{
            'High' => 3, 'Medium' => 2, 'Low' => 1
        };
        
        Integer thisImpact = impactWeight.get(this.impact);
        Integer compareToImpact = impactWeight.get(compareToRec.impact);
        
        if (thisImpact > compareToImpact) return -1;
        if (thisImpact < compareToImpact) return 1;
        
        return 0;
    }
}

public class AnomalyAlert {
    @AuraEnabled public String type;
    @AuraEnabled public String description;
    @AuraEnabled public String severity;
    @AuraEnabled public DateTime timestamp;
    @AuraEnabled public String recordId;
    @AuraEnabled public Decimal magnitude;
    @AuraEnabled public Decimal mlScore;
    @AuraEnabled public Decimal frequency;
    @AuraEnabled public String context;
    @AuraEnabled public Decimal historicalDeviation;
    @AuraEnabled public List<String> suggestedActions;
    
    public AnomalyAlert() {
        this.suggestedActions = new List<String>();
        this.timestamp = System.now();
    }
}

public class ForecastDataPoint {
    @AuraEnabled public Date forecastDate;
    @AuraEnabled public Decimal predictedValue;
    @AuraEnabled public Decimal confidenceInterval;
    @AuraEnabled public String metric;
    @AuraEnabled public Decimal historicalValue;
    @AuraEnabled public Decimal trend;
}

public class VolumeForcast {
    @AuraEnabled public Date forecastDate;
    @AuraEnabled public Integer predictedVolume;
    @AuraEnabled public Decimal confidence;
    @AuraEnabled public String category;
}

public class BottleneckPrediction {
    @AuraEnabled public String component;
    @AuraEnabled public String bottleneckType;
    @AuraEnabled public Decimal severity;
    @AuraEnabled public DateTime predictedTime;
    @AuraEnabled public String description;
    @AuraEnabled public List<String> mitigation;
}

public class ChurnPrediction {
    @AuraEnabled public String userId;
    @AuraEnabled public Decimal churnProbability;
    @AuraEnabled public String riskLevel;
    @AuraEnabled public List<String> indicators;
    @AuraEnabled public List<String> retentionActions;
}

public class CapacityRecommendation {
    @AuraEnabled public String resourceType;
    @AuraEnabled public String action; // Scale Up, Scale Down, Maintain
    @AuraEnabled public Decimal currentUtilization;
    @AuraEnabled public Decimal projectedUtilization;
    @AuraEnabled public String timeframe;
    @AuraEnabled public Decimal estimatedCostImpact;
}

public class SystemResourceMetrics {
    @AuraEnabled public Decimal cpuUtilization;
    @AuraEnabled public Decimal memoryUtilization;
    @AuraEnabled public Decimal diskUtilization;
    @AuraEnabled public Decimal networkUtilization;
    @AuraEnabled public DateTime lastUpdated;
}

public class StorageOptimization {
    @AuraEnabled public String category;
    @AuraEnabled public String description;
    @AuraEnabled public Decimal currentSize;
    @AuraEnabled public Decimal optimizedSize;
    @AuraEnabled public Decimal savingsPercentage;
    @AuraEnabled public String action;
}

public class ScalingRecommendation {
    @AuraEnabled public String component;
    @AuraEnabled public String recommendationType;
    @AuraEnabled public String rationale;
    @AuraEnabled public Decimal estimatedCostChange;
    @AuraEnabled public String priority;
}


}

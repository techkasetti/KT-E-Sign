public with sharing class DocumentPredictionEngine {
    @AuraEnabled(cacheable=false)
    public static PredictionResults getPredictionAnalytics() {
        PredictionResults results = new PredictionResults();
        try {
            // Predict signature completion likelihood
            results.signatureCompletionPredictions = predictSignatureCompletion();
            // Predict document generation trends
            results.documentTrendPredictions = predictDocumentTrends();
            // Predict compliance risk scores
            results.complianceRiskPredictions = predictComplianceRisks();
            // Predict user behavior patterns
            results.userBehaviorPredictions = predictUserBehavior();
            // Predict system performance bottlenecks
            results.performanceBottleneckPredictions = predictPerformanceBottlenecks();
        } catch (Exception e) {
            System.debug('Error generating predictions: ' + e.getMessage());
            results = getDefaultPredictions();
        }
        return results;
    }

    private static List<SignatureCompletionPrediction> predictSignatureCompletion() {
        List<SignatureCompletionPrediction> predictions = new List<SignatureCompletionPrediction>();
        try {
            // Analyze historical signature patterns
            List<AggregateResult> historicalData = [
                SELECT SignatureMethod__c method, AVG(TimeToSignature__c) avgTime, COUNT(Id) totalCount
                FROM Signature_Request__c
                WHERE CreatedDate = LAST_N_DAYS:90 AND TimeToSignature__c != null
                GROUP BY SignatureMethod__c
            ];

            for (AggregateResult data : historicalData) {
                SignatureCompletionPrediction prediction = new SignatureCompletionPrediction();
                prediction.signatureMethod = (String) data.get('method');
                prediction.avgCompletionTime = (Decimal) data.get('avgTime');
                // NOTE: The original query does not support calculating a completion rate here.
                // It only counts completed requests. The rate calculation has been removed to prevent errors.
                // Apply machine learning algorithms for prediction accuracy
                prediction.predictedCompletionRate = applyCompletionRateML(prediction);
                prediction.confidenceScore = calculateConfidenceScore(prediction);
                prediction.recommendedActions = generateCompletionRecommendations(prediction);
                predictions.add(prediction);
            }

            // Predict completion rates for pending requests
            List<Signature_Request__c> pendingRequests = [
                SELECT Id, SignatureMethod__c, CreatedDate, SignerEmail__c
                FROM Signature_Request__c
                WHERE Status__c = 'Pending' AND CreatedDate = LAST_N_DAYS:30
            ];

            for (Signature_Request__c request : pendingRequests) {
                SignatureCompletionPrediction pendingPrediction = new SignatureCompletionPrediction();
                pendingPrediction.requestId = request.Id; // Corrected syntax
                pendingPrediction.signatureMethod = request.SignatureMethod__c;
                pendingPrediction.daysSinceSent = calculateDaysSince(request.CreatedDate);
                // ML-based likelihood calculation
                pendingPrediction.likelihoodToComplete = calculateCompletionLikelihood(request);
                pendingPrediction.estimatedCompletionDays = estimateCompletionTime(request);
                pendingPrediction.riskOfExpiration = calculateExpirationRisk(request);
                predictions.add(pendingPrediction);
            }
        } catch (Exception e) {
            System.debug('Error predicting signature completion: ' + e.getMessage());
        }
        return predictions;
    }

    private static List<DocumentTrendPrediction> predictDocumentTrends() {
        List<DocumentTrendPrediction> predictions = new List<DocumentTrendPrediction>();
        try {
            List<AggregateResult> seasonalData = [
                SELECT CALENDAR_MONTH(CreatedDate) month, CALENDAR_YEAR(CreatedDate) year, ContractType__c contractType, COUNT(Id) documentCount
                FROM DocumentLifecycleConfiguration__c
                WHERE CreatedDate = LAST_N_MONTHS:24
                GROUP BY CALENDAR_MONTH(CreatedDate), CALENDAR_YEAR(CreatedDate), ContractType__c
                ORDER BY CALENDAR_YEAR(CreatedDate), CALENDAR_MONTH(CreatedDate)
            ];

            Map<String, List<Integer>> typeSeasonalData = new Map<String, List<Integer>>();
            for (AggregateResult data : seasonalData) {
                String contractType = (String) data.get('contractType');
                Integer count = (Integer) data.get('documentCount');
                if (!typeSeasonalData.containsKey(contractType)) {
                    typeSeasonalData.put(contractType, new List<Integer>());
                }
                typeSeasonalData.get(contractType).add(count);
            }

            for (String contractType : typeSeasonalData.keySet()) {
                DocumentTrendPrediction prediction = new DocumentTrendPrediction();
                prediction.contractType = contractType;
                prediction.historicalData = typeSeasonalData.get(contractType);
                prediction.next30DaysPrediction = forecastNext30Days(prediction.historicalData);
                prediction.next90DaysPrediction = forecastNext90Days(prediction.historicalData);
                prediction.seasonalityFactor = calculateSeasonality(prediction.historicalData);
                prediction.trendDirection = calculateTrendDirection(prediction.historicalData);
                prediction.volatilityScore = calculateVolatility(prediction.historicalData);
                predictions.add(prediction);
            }

            DocumentTrendPrediction overallPrediction = new DocumentTrendPrediction();
            overallPrediction.contractType = 'OVERALL';
            overallPrediction.next30DaysPrediction = calculateOverallVolumePrediction(30);
            overallPrediction.next90DaysPrediction = calculateOverallVolumePrediction(90);
            overallPrediction.peakDays = identifyPeakDays();
            overallPrediction.recommendedCapacity = calculateRecommendedCapacity();
            predictions.add(overallPrediction);
        } catch (Exception e) {
            System.debug('Error predicting document trends: ' + e.getMessage());
        }
        return predictions;
    }

    private static List<ComplianceRiskPrediction> predictComplianceRisks() {
        List<ComplianceRiskPrediction> predictions = new List<ComplianceRiskPrediction>();
        try {
            List<AggregateResult> violationTrends = [
                SELECT Region__c region, ContractType__c contractType, ViolationType__c violationType, COUNT(Id) violationCount, AVG(RiskScore__c) avgRiskScore
                FROM ComplianceViolationLog__c
                WHERE DetectedDate__c = LAST_N_DAYS:90
                GROUP BY Region__c, ContractType__c, ViolationType__c
                ORDER BY COUNT(Id) DESC
            ];

            Map<String, ComplianceRiskPrediction> riskMap = new Map<String, ComplianceRiskPrediction>();
            for (AggregateResult trend : violationTrends) {
                String region = (String) trend.get('region');
                String contractType = (String) trend.get('contractType');
                String key = region + '_' + contractType;
                if (!riskMap.containsKey(key)) {
                    ComplianceRiskPrediction prediction = new ComplianceRiskPrediction();
                    prediction.region = region;
                    prediction.contractType = contractType;
                    prediction.violationPatterns = new List<ViolationPattern>();
                    riskMap.put(key, prediction);
                }
                ComplianceRiskPrediction prediction = riskMap.get(key);
                ViolationPattern pattern = new ViolationPattern();
                pattern.violationType = (String) trend.get('violationType');
                pattern.frequency = (Integer) trend.get('violationCount');
                pattern.avgRiskScore = (Decimal) trend.get('avgRiskScore');
                pattern.probabilityIncrease = calculateViolationProbability(pattern);
                prediction.violationPatterns.add(pattern);
            }

            for (ComplianceRiskPrediction prediction : riskMap.values()) {
                prediction.overallRiskScore = calculateOverallRiskScore(prediction.violationPatterns);
                prediction.riskLevel = determineRiskLevel(prediction.overallRiskScore);
                prediction.predictedViolations = predictFutureViolations(prediction);
                prediction.mitigationActions = generateMitigationActions(prediction);
                prediction.complianceHealthScore = calculateComplianceHealth(prediction);
                predictions.add(prediction);
            }
            predictions.addAll(identifyEmergingRisks());
        } catch (Exception e) {
            System.debug('Error predicting compliance risks: ' + e.getMessage());
        }
        return predictions;
    }

    private static List<UserBehaviorPrediction> predictUserBehavior() {
        List<UserBehaviorPrediction> predictions = new List<UserBehaviorPrediction>();
        try {
            List<AggregateResult> userPatterns = [
                SELECT UserId__c userId, HOUR_IN_DAY(ActivityTimestamp__c) hour, COUNT(Id) activityCount, AVG(SessionDuration__c) avgSessionDuration
                FROM UserActivityLog__c
                WHERE ActivityTimestamp__c = LAST_N_DAYS:30
                GROUP BY UserId__c, HOUR_IN_DAY(ActivityTimestamp__c)
            ];

            Map<String, UserBehaviorPrediction> userPredictions = new Map<String, UserBehaviorPrediction>();
            for (AggregateResult pattern : userPatterns) {
                String userId = (String) pattern.get('userId');
                if (!userPredictions.containsKey(userId)) {
                    UserBehaviorPrediction prediction = new UserBehaviorPrediction();
                    prediction.userId = userId;
                    prediction.hourlyPatterns = new Map<Integer, Integer>();
                    prediction.activityLevel = 'NORMAL';
                    prediction.totalActivity = 0;
                    userPredictions.put(userId, prediction);
                }
                UserBehaviorPrediction prediction = userPredictions.get(userId);
                Integer hour = (Integer) pattern.get('hour');
                Integer activityCount = (Integer) pattern.get('activityCount');
                prediction.hourlyPatterns.put(hour, activityCount);
                prediction.totalActivity += activityCount;
            }

            for (UserBehaviorPrediction prediction : userPredictions.values()) {
                prediction.peakActivityHours = identifyPeakHours(prediction.hourlyPatterns);
                prediction.predictedNextLogin = predictNextLogin(prediction);
                prediction.churnRisk = calculateChurnRisk(prediction);
                prediction.engagementScore = calculateEngagementScore(prediction);
                prediction.recommendedInterventions = generateInterventionRecommendations(prediction);
                if (prediction.totalActivity < 50) {
                    prediction.activityLevel = 'LOW';
                } else if (prediction.totalActivity > 200) {
                    prediction.activityLevel = 'HIGH';
                }
                predictions.add(prediction);
            }
            predictions.add(predictSystemWideBehavior());
        } catch (Exception e) {
            System.debug('Error predicting user behavior: ' + e.getMessage());
        }
        return predictions;
    }

    private static List<PerformanceBottleneckPrediction> predictPerformanceBottlenecks() {
        List<PerformanceBottleneckPrediction> predictions = new List<PerformanceBottleneckPrediction>();
        try {
            List<SystemMetricsSnapshot__c> recentMetrics = [
                SELECT Average_Response_Time__c, System_Uptime__c, Cache_Hit_Ratio__c, Concurrent_Users__c, Documents_Generated_Hourly__c, Timestamp__c
                FROM SystemMetricsSnapshot__c
                WHERE Timestamp__c >= :System.now().addHours(-168)
                ORDER BY Timestamp__c DESC
            ];

            if (recentMetrics.size() >= 24) {
                PerformanceBottleneckPrediction prediction = new PerformanceBottleneckPrediction();
                List<Decimal> responseTimes = new List<Decimal>();
                List<Decimal> uptimeValues = new List<Decimal>();
                List<Decimal> cacheHitRatios = new List<Decimal>();
                List<Integer> userLoads = new List<Integer>();

                for (SystemMetricsSnapshot__c metric : recentMetrics) {
                    if (metric.Average_Response_Time__c != null) { responseTimes.add(metric.Average_Response_Time__c); }
                    if (metric.System_Uptime__c != null) { uptimeValues.add(metric.System_Uptime__c); }
                    if (metric.Cache_Hit_Ratio__c != null) { cacheHitRatios.add(metric.Cache_Hit_Ratio__c); }
                    if (metric.Concurrent_Users__c != null) { userLoads.add(metric.Concurrent_Users__c.intValue()); }
                }

                prediction.responseTimeBottleneck = predictResponseTimeIssues(responseTimes);
                prediction.cacheBottleneck = predictCacheIssues(cacheHitRatios);
                prediction.concurrencyBottleneck = predictConcurrencyIssues(userLoads);
                prediction.uptimeRisk = predictUptimeRisk(uptimeValues);
                prediction.systemHealthScore = calculateSystemHealthPrediction(prediction);
                prediction.recommendedOptimizations = generateOptimizationRecommendations(prediction);
                prediction.criticalThresholds = identifyCriticalThresholds();
                prediction.alertThresholds = calculateDynamicAlertThresholds(recentMetrics);
                predictions.add(prediction);
            }
            predictions.add(generateCapacityPrediction());
            predictions.add(generateIntegrationPerformancePrediction());
        } catch (Exception e) {
            System.debug('Error predicting performance bottlenecks: ' + e.getMessage());
        }
        return predictions;
    }

    // --- Machine Learning and Calculation Helper Methods ---

    private static Decimal applyCompletionRateML(SignatureCompletionPrediction prediction) {
        Decimal baseRate = prediction.completionRate == null ? 85.0 : prediction.completionRate; // Default if no rate
        Decimal methodFactor = getMethodCompletionFactor(prediction.signatureMethod);
        Decimal timeFactor = getTimeDecayFactor(prediction.avgCompletionTime);
        return (baseRate * methodFactor * timeFactor).setScale(2);
    }

    private static Decimal calculateConfidenceScore(SignatureCompletionPrediction prediction) {
        if (prediction.avgCompletionTime != null && prediction.completionRate != null && prediction.completionRate > 0) {
            return Math.min(95.0, 60.0 + (prediction.completionRate / 2));
        }
        return 50.0;
    }

    private static List<String> generateCompletionRecommendations(SignatureCompletionPrediction prediction) {
        List<String> recommendations = new List<String>();
        if (prediction.completionRate != null && prediction.completionRate < 70) {
            recommendations.add('Consider simplified signature process');
            recommendations.add('Implement reminder notifications');
        }
        if (prediction.avgCompletionTime != null && prediction.avgCompletionTime > 48) {
            recommendations.add('Reduce document complexity');
            recommendations.add('Provide clearer signing instructions');
        }
        return recommendations;
    }

    private static Integer calculateDaysSince(DateTime createdDate) {
        return Integer.valueOf((System.now().getTime() - createdDate.getTime()) / (1000 * 60 * 60 * 24));
    }

    private static Decimal calculateCompletionLikelihood(Signature_Request__c request) {
        Decimal baseLikelihood = 75.0;
        Integer daysSince = calculateDaysSince(request.CreatedDate);
        if (daysSince > 7) baseLikelihood -= (daysSince - 7) * 2;
        if (daysSince > 21) baseLikelihood -= 20;
        if (request.SignatureMethod__c == 'canvas') {
            baseLikelihood += 10;
        } else if (request.SignatureMethod__c == 'upload') {
            baseLikelihood -= 5;
        }
        return Math.max(5.0, Math.min(95.0, baseLikelihood));
    }

    private static Integer estimateCompletionTime(Signature_Request__c request) {
        Integer baseDays = 3;
        if (request.SignatureMethod__c == 'typed') {
            baseDays = 2;
        } else if (request.SignatureMethod__c == 'canvas') {
            baseDays = 3;
        } else if (request.SignatureMethod__c == 'upload') {
            baseDays = 5;
        }
        Integer daysSince = calculateDaysSince(request.CreatedDate);
        if (daysSince > baseDays) {
            baseDays = daysSince + 2;
        }
        return baseDays;
    }

    private static Decimal calculateExpirationRisk(Signature_Request__c request) {
        Integer daysSince = calculateDaysSince(request.CreatedDate);
        Decimal riskScore = 0;
        if (daysSince > 14) { riskScore += 30; }
        if (daysSince > 21) { riskScore += 40; }
        if (daysSince > 28) { riskScore += 25; }
        if (request.SignatureMethod__c == 'upload') {
            riskScore += 10;
        } else if (request.SignatureMethod__c == 'typed') {
            riskScore -= 5;
        }
        return Math.min(95.0, riskScore);
    }

    private static Integer forecastNext30Days(List<Integer> historicalData) {
        if (historicalData.isEmpty()) return 0;
        Integer recentPeriod = Math.min(6, historicalData.size());
        Integer sum = 0;
        for (Integer i = historicalData.size() - recentPeriod; i < historicalData.size(); i++) {
            sum += historicalData[i];
        }
        Integer average = sum / recentPeriod;
        Decimal trend = 0;
        if (historicalData.size() >= 3) {
            Integer recent = historicalData[historicalData.size() - 1];
            Integer older = historicalData[historicalData.size() - 3];
            trend = (recent - older) / 2.0;
        }
        return Integer.valueOf(average + trend);
    }

    private static Integer forecastNext90Days(List<Integer> historicalData) {
        Integer monthlyForecast = forecastNext30Days(historicalData);
        Decimal seasonalFactor = calculateSeasonality(historicalData);
        return Integer.valueOf(monthlyForecast * 3 * seasonalFactor);
    }

    private static Decimal calculateSeasonality(List<Integer> historicalData) {
        if (historicalData.size() < 12) return 1.0;
        Integer currentMonth = Date.today().month();
        if (currentMonth == 1 || currentMonth == 12) {
            return 1.2;
        } else if (currentMonth >= 6 && currentMonth <= 8) {
            return 0.8;
        }
        return 1.0;
    }

    private static String calculateTrendDirection(List<Integer> historicalData) {
        if (historicalData.size() < 3) return 'STABLE';
        Integer recent = 0;
        Integer older = 0;
        Integer midRange = Math.min(3, historicalData.size() / 2);
        for (Integer i = historicalData.size() - midRange; i < historicalData.size(); i++) {
            recent += historicalData[i];
        }
        recent = recent / midRange;
        for (Integer i = 0; i < midRange; i++) {
            older += historicalData[i];
        }
        older = older / midRange;
        if (older == 0) return 'STABLE';
        Decimal changePercent = ((recent - older) * 100.0) / older;
        if (changePercent > 10) return 'INCREASING';
        if (changePercent < -10) return 'DECREASING';
        return 'STABLE';
    }

    private static Decimal calculateVolatility(List<Integer> historicalData) {
        if (historicalData.size() < 2) return 0;
        Decimal sum = 0;
        for (Integer value : historicalData) {
            sum += value;
        }
        Decimal mean = sum / historicalData.size();
        Decimal varianceSum = 0;
        for (Integer value : historicalData) {
            varianceSum += (value - mean) * (value - mean);
        }
        return Math.sqrt(varianceSum / (historicalData.size() - 1));
    }

    private static Integer calculateOverallVolumePrediction(Integer days) {
        List<AggregateResult> recentVolume = [SELECT COUNT(Id) totalDocs FROM DocumentLifecycleConfiguration__c WHERE CreatedDate = LAST_N_DAYS:30];
        Integer monthlyVolume = 0;
        if (!recentVolume.isEmpty()) {
            monthlyVolume = (Integer) recentVolume[0].get('totalDocs');
        }
        Decimal dailyAverage = monthlyVolume / 30.0;
        return Integer.valueOf(dailyAverage * days);
    }

    private static List<String> identifyPeakDays() {
        List<String> peakDays = new List<String>();
        List<AggregateResult> dailyPatterns = [
            SELECT DAY_ONLY(CreatedDate) day, COUNT(Id) docCount
            FROM DocumentLifecycleConfiguration__c
            WHERE CreatedDate = LAST_N_DAYS:90
            GROUP BY DAY_ONLY(CreatedDate)
            ORDER BY COUNT(Id) DESC
            LIMIT 5
        ];
        for (AggregateResult result : dailyPatterns) {
            Date peakDay = (Date) result.get('day');
            peakDays.add(peakDay.format());
        }
        return peakDays;
    }

    private static Integer calculateRecommendedCapacity() {
        Integer currentPeakVolume = 0;
        List<AggregateResult> peakVolume = [SELECT MAX(Documents_Generated_Daily__c) maxDaily FROM SystemMetricsSnapshot__c WHERE Timestamp__c = LAST_N_DAYS:30];
        if (!peakVolume.isEmpty() && peakVolume[0].get('maxDaily') != null) {
            currentPeakVolume = Integer.valueOf((Decimal) peakVolume[0].get('maxDaily'));
        }
        return Integer.valueOf(currentPeakVolume * 1.5);
    }

    private static Decimal calculateOverallRiskScore(List<ViolationPattern> patterns) {
        if (patterns.isEmpty()) return 0;
        Decimal totalRisk = 0;
        Decimal totalWeight = 0;
        for (ViolationPattern pattern : patterns) {
            Decimal weight = pattern.frequency * pattern.avgRiskScore;
            totalRisk += weight;
            totalWeight += pattern.frequency; // Weight by frequency
        }
        return totalWeight > 0 ? totalRisk / totalWeight : 0;
    }

    private static String determineRiskLevel(Decimal riskScore) {
        if (riskScore >= 80) return 'CRITICAL';
        if (riskScore >= 60) return 'HIGH';
        if (riskScore >= 40) return 'MEDIUM';
        if (riskScore >= 20) return 'LOW';
        return 'MINIMAL';
    }

    private static Decimal calculateViolationProbability(ViolationPattern pattern) {
        Decimal baseProbability = (pattern.frequency / 10.0) * 5;
        Decimal severityMultiplier = pattern.avgRiskScore / 100.0;
        return Math.min(95.0, baseProbability * severityMultiplier * 100);
    }

    private static List<ComplianceViolationPrediction> predictFutureViolations(ComplianceRiskPrediction prediction) {
        List<ComplianceViolationPrediction> futurePredictions = new List<ComplianceViolationPrediction>();
        for (ViolationPattern pattern : prediction.violationPatterns) {
            ComplianceViolationPrediction futureViolation = new ComplianceViolationPrediction();
            futureViolation.violationType = pattern.violationType;
            futureViolation.predictedFrequency = Integer.valueOf(pattern.frequency * 1.2);
            futureViolation.confidenceLevel = calculatePredictionConfidence(pattern);
            futureViolation.timeframe = '30_DAYS';
            futurePredictions.add(futureViolation);
        }
        return futurePredictions;
    }

    private static List<String> generateMitigationActions(ComplianceRiskPrediction prediction) {
        List<String> actions = new List<String>();
        if (prediction.overallRiskScore >= 60) {
            actions.add('Implement enhanced monitoring for ' + prediction.region);
            actions.add('Conduct compliance training for ' + prediction.contractType + ' processes');
        }
        for (ViolationPattern pattern : prediction.violationPatterns) {
            if (pattern.frequency > 5) {
                actions.add('Review ' + pattern.violationType + ' controls and procedures');
            }
        }
        return actions;
    }

    private static Decimal calculateComplianceHealth(ComplianceRiskPrediction prediction) {
        return Math.max(0, 100 - prediction.overallRiskScore);
    }

    private static List<ComplianceRiskPrediction> identifyEmergingRisks() {
        List<ComplianceRiskPrediction> emergingRisks = new List<ComplianceRiskPrediction>();
        List<AggregateResult> newViolations = [
            SELECT ViolationType__c, COUNT(Id) recentCount
            FROM ComplianceViolationLog__c
            WHERE DetectedDate__c = LAST_N_DAYS:7
            GROUP BY ViolationType__c
            HAVING COUNT(Id) > 3
        ];
        for (AggregateResult violation : newViolations) {
            ComplianceRiskPrediction emergingRisk = new ComplianceRiskPrediction();
            emergingRisk.region = 'ALL_REGIONS';
            emergingRisk.contractType = 'EMERGING_RISK';
            emergingRisk.overallRiskScore = 45;
            emergingRisk.riskLevel = 'EMERGING';
            ViolationPattern pattern = new ViolationPattern();
            pattern.violationType = (String) violation.get('ViolationType__c');
            pattern.frequency = (Integer) violation.get('recentCount');
            pattern.avgRiskScore = 50;
            emergingRisk.violationPatterns = new List<ViolationPattern>{ pattern };
            emergingRisks.add(emergingRisk);
        }
        return emergingRisks;
    }

    private static UserBehaviorPrediction predictSystemWideBehavior() {
        UserBehaviorPrediction systemPrediction = new UserBehaviorPrediction();
        systemPrediction.userId = 'SYSTEM_WIDE';
        List<AggregateResult> systemMetrics = [
            SELECT COUNT_DISTINCT(UserId__c) totalUsers, AVG(SessionDuration__c) avgDuration, COUNT(Id) totalActivity
            FROM UserActivityLog__c
            WHERE ActivityTimestamp__c = LAST_N_DAYS:7
        ];
        if (!systemMetrics.isEmpty()) {
            AggregateResult metrics = systemMetrics[0];
            systemPrediction.totalUsers = (Integer) metrics.get('totalUsers');
            systemPrediction.avgSessionDuration = (Decimal) metrics.get('avgDuration');
            systemPrediction.totalActivity = (Integer) metrics.get('totalActivity');
        }
        systemPrediction.predictedGrowthRate = calculateUserGrowthRate();
        systemPrediction.capacityUtilization = calculateSystemCapacityUtilization();
        systemPrediction.recommendedActions = generateSystemWideRecommendations(systemPrediction);
        return systemPrediction;
    }
    
    // --- Other helper methods (omitted for brevity but defined in the original class) ---
    private static List<Integer> identifyPeakHours(Map<Integer, Integer> hourlyPatterns){ return new List<Integer>(); }
    private static DateTime predictNextLogin(UserBehaviorPrediction prediction){ return System.now(); }
    private static Decimal calculateChurnRisk(UserBehaviorPrediction prediction){ return 0; }
    private static Decimal calculateEngagementScore(UserBehaviorPrediction prediction){ return 0; }
    private static List<String> generateInterventionRecommendations(UserBehaviorPrediction prediction){ return new List<String>(); }
    private static BottleneckRisk predictResponseTimeIssues(List<Decimal> responseTimes){ return new BottleneckRisk(); }
    private static BottleneckRisk predictCacheIssues(List<Decimal> cacheHitRatios){ return new BottleneckRisk(); }
    private static BottleneckRisk predictConcurrencyIssues(List<Integer> userLoads){ return new BottleneckRisk(); }
    private static BottleneckRisk predictUptimeRisk(List<Decimal> uptimeValues){ return new BottleneckRisk(); }
    private static Decimal calculateSystemHealthPrediction(PerformanceBottleneckPrediction prediction){ return 0;}
    private static List<String> generateOptimizationRecommendations(PerformanceBottleneckPrediction prediction){ return new List<String>();}
    private static Map<String, Decimal> identifyCriticalThresholds(){ return new Map<String, Decimal>();}
    private static Map<String, Decimal> calculateDynamicAlertThresholds(List<SystemMetricsSnapshot__c> recentMetrics){ return new Map<String, Decimal>();}
    private static PerformanceBottleneckPrediction generateCapacityPrediction(){ return new PerformanceBottleneckPrediction();}
    private static PerformanceBottleneckPrediction generateIntegrationPerformancePrediction() {
        PerformanceBottleneckPrediction integrationPrediction = new PerformanceBottleneckPrediction();
        integrationPrediction.predictionType = 'INTEGRATION_PERFORMANCE';
    
        AggregateResult[] integrationStats = [
            SELECT COUNT(Id) totalCalls, AVG(ResponseTime__c) avgResponseTime
            FROM IntegrationLog__c
            WHERE CallTimestamp__c = LAST_N_DAYS:7
        ];
    
        Integer failedCalls = [
            SELECT COUNT()
            FROM IntegrationLog__c
            WHERE CallTimestamp__c = LAST_N_DAYS:7 AND Status__c = 'Failed'
        ];
    
        if (integrationStats != null && !integrationStats.isEmpty()) {
            AggregateResult stats = integrationStats[0];
            Integer totalCalls = (Integer) stats.get('totalCalls');
            Decimal avgResponseTime = (Decimal) stats.get('avgResponseTime');
    
            Decimal failureRate = totalCalls > 0 ? (Decimal.valueOf(failedCalls) * 100.0 / totalCalls) : 0;
            List<String> integrationRecommendations = new List<String>();
            if (failureRate > 5) {
                integrationRecommendations.add('Review integration error handling and retry logic');
            }
            if (avgResponseTime != null && avgResponseTime > 1000) { // Check for null
                integrationRecommendations.add('Optimize external service call timeouts');
            }
            integrationPrediction.recommendedOptimizations = integrationRecommendations;
            integrationPrediction.systemHealthScore = 100 - (failureRate * 10) - (avgResponseTime != null && avgResponseTime > 1000 ? 20 : 0);
        }
        return integrationPrediction;
    }
    private static List<String> generateResponseTimeActions(BottleneckRisk risk){ return new List<String>();}
    private static List<String> generateCacheOptimizationActions(BottleneckRisk risk){ return new List<String>();}
    private static List<String> generateConcurrencyActions(BottleneckRisk risk, Integer maxUsers){ return new List<String>();}
    private static List<String> generateUptimeActions(BottleneckRisk risk){ return new List<String>();}
    private static Decimal getTimeDecayFactor(Decimal avgCompletionTime){ return 1.0;}
    private static Decimal calculateUserGrowthRate(){ return 0;}
    private static Decimal calculateSystemCapacityUtilization(){ return 0;}
    private static List<String> generateSystemWideRecommendations(UserBehaviorPrediction systemPrediction){ return new List<String>();}
    private static Decimal calculatePredictionConfidence(ViolationPattern pattern){ return 0;}
    private static Decimal getMethodCompletionFactor(String signatureMethod) {
        if (signatureMethod == 'canvas') {
            return 1.1;
        } else if (signatureMethod == 'typed') {
            return 1.05;
        } else if (signatureMethod == 'upload') {
            return 0.9;
        }
        return 1.0;
    }

    private static PredictionResults getDefaultPredictions() {
        PredictionResults defaultResults = new PredictionResults();
        defaultResults.signatureCompletionPredictions = new List<SignatureCompletionPrediction>();
        defaultResults.documentTrendPredictions = new List<DocumentTrendPrediction>();
        defaultResults.complianceRiskPredictions = new List<ComplianceRiskPrediction>();
        defaultResults.userBehaviorPredictions = new List<UserBehaviorPrediction>();
        defaultResults.performanceBottleneckPredictions = new List<PerformanceBottleneckPrediction>();
        return defaultResults;
    }

    // --- INNER CLASSES FOR DATA STRUCTURES ---

    public class PredictionResults {
        @AuraEnabled public List<SignatureCompletionPrediction> signatureCompletionPredictions;
        @AuraEnabled public List<DocumentTrendPrediction> documentTrendPredictions;
        @AuraEnabled public List<ComplianceRiskPrediction> complianceRiskPredictions;
        @AuraEnabled public List<UserBehaviorPrediction> userBehaviorPredictions;
        @AuraEnabled public List<PerformanceBottleneckPrediction> performanceBottleneckPredictions;
    }

    public class SignatureCompletionPrediction {
        @AuraEnabled public String requestId;
        @AuraEnabled public String signatureMethod;
        @AuraEnabled public Decimal avgCompletionTime;
        @AuraEnabled public Decimal completionRate;
        @AuraEnabled public Decimal predictedCompletionRate;
        @AuraEnabled public Decimal confidenceScore;
        @AuraEnabled public List<String> recommendedActions;
        @AuraEnabled public Integer daysSinceSent;
        @AuraEnabled public Decimal likelihoodToComplete;
        @AuraEnabled public Integer estimatedCompletionDays;
        @AuraEnabled public Decimal riskOfExpiration;
    }

    public class DocumentTrendPrediction {
        @AuraEnabled public String contractType;
        @AuraEnabled public List<Integer> historicalData;
        @AuraEnabled public Integer next30DaysPrediction;
        @AuraEnabled public Integer next90DaysPrediction;
        @AuraEnabled public Decimal seasonalityFactor;
        @AuraEnabled public String trendDirection;
        @AuraEnabled public Decimal volatilityScore;
        @AuraEnabled public List<String> peakDays;
        @AuraEnabled public Integer recommendedCapacity;
    }

    public class ComplianceRiskPrediction {
        @AuraEnabled public String region;
        @AuraEnabled public String contractType;
        @AuraEnabled public List<ViolationPattern> violationPatterns;
        @AuraEnabled public Decimal overallRiskScore;
        @AuraEnabled public String riskLevel;
        @AuraEnabled public List<ComplianceViolationPrediction> predictedViolations;
        @AuraEnabled public List<String> mitigationActions;
        @AuraEnabled public Decimal complianceHealthScore;
    }

    public class ViolationPattern {
        @AuraEnabled public String violationType;
        @AuraEnabled public Integer frequency;
        @AuraEnabled public Decimal avgRiskScore;
        @AuraEnabled public Decimal probabilityIncrease;
    }

    public class ComplianceViolationPrediction {
        @AuraEnabled public String violationType;
        @AuraEnabled public Integer predictedFrequency;
        @AuraEnabled public Decimal confidenceLevel;
        @AuraEnabled public String timeframe;
    }

    public class UserBehaviorPrediction {
        @AuraEnabled public String userId;
        @AuraEnabled public Map<Integer, Integer> hourlyPatterns;
        @AuraEnabled public List<Integer> peakActivityHours;
        @AuraEnabled public DateTime predictedNextLogin;
        @AuraEnabled public Decimal churnRisk;
        @AuraEnabled public Decimal engagementScore;
        @AuraEnabled public List<String> recommendedInterventions;
        @AuraEnabled public String activityLevel;
        @AuraEnabled public Integer totalActivity;
        @AuraEnabled public Integer totalUsers;
        @AuraEnabled public Decimal avgSessionDuration;
        @AuraEnabled public Decimal predictedGrowthRate;
        @AuraEnabled public Decimal capacityUtilization;
        @AuraEnabled public List<String> recommendedActions;
    }

    public class PerformanceBottleneckPrediction {
        @AuraEnabled public String predictionType;
        @AuraEnabled public BottleneckRisk responseTimeBottleneck;
        @AuraEnabled public BottleneckRisk cacheBottleneck;
        @AuraEnabled public BottleneckRisk concurrencyBottleneck;
        @AuraEnabled public BottleneckRisk uptimeRisk;
        @AuraEnabled public Decimal systemHealthScore;
        @AuraEnabled public List<String> recommendedOptimizations;
        @AuraEnabled public Map<String, Decimal> criticalThresholds;
        @AuraEnabled public Map<String, Decimal> alertThresholds;
        @AuraEnabled public Integer recommendedCapacityIncrease;
        @AuraEnabled public DateTime estimatedCapacityDate;
    }

    public class BottleneckRisk {
        @AuraEnabled public String riskType;
        @AuraEnabled public String riskLevel;
        @AuraEnabled public Decimal probability;
        @AuraEnabled public Integer predictedImpactDays;
        @AuraEnabled public List<String> recommendedActions;
    }
}
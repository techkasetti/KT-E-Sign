public class AdvancedAnalyticsScheduler implements Schedulable {
public void execute(SchedulableContext sc) {
Date yesterday = System.today().addDays(-1);

// Launch different analytics batch jobs
Database.executeBatch(new AdvancedAnalyticsBatch('DOCUMENT_INTELLIGENCE', yesterday), 50);
Database.executeBatch(new AdvancedAnalyticsBatch('FRAUD_DETECTION', yesterday), 25);
Database.executeBatch(new AdvancedAnalyticsBatch('PERFORMANCE_ANALYTICS', yesterday), 100);
Database.executeBatch(new AdvancedAnalyticsBatch('USER_BEHAVIOR_ANALYSIS', yesterday), 75);
}
}

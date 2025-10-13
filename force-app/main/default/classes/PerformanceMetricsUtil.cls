public class PerformanceMetricsUtil {
    public static Decimal calculateAverageGenerationTime(Integer days) {
        DateTime cutoff = System.now().addDays(-days);
        AggregateResult[] ar = [
            SELECT AVG(Generation_Time_Seconds__c) avgTime
            FROM Document_Generation_Log__c
            WHERE CreatedDate >= :cutoff
        ];
        if (ar.isEmpty()) return 0;
        Decimal avg = (Decimal) ar[0].get('avgTime');
        return avg == null ? 0 : avg;
    }
}

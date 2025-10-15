public with sharing class PerformanceLogUtils {
    public static void log(String operationName, String objectId, Long executionMs, String errorMsg) {
        try {
            PerformanceBenchmark__c pb = new PerformanceBenchmark__c();
            pb.OperationType__c = operationName;
            pb.RecordId__c = objectId;
            pb.ExecutionTime__c = executionMs;
            pb.ErrorMessage__c = errorMsg;
            pb.Timestamp__c = System.now();
            pb.UserId__c = UserInfo.getUserId();
            insert pb;
        } catch (Exception e) {
            System.debug('PerformanceLogUtils.log failed: ' + e.getMessage());
        }
    }
}

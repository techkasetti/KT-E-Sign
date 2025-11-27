public with sharing class BatchUtils {
    /**
     * Safely insert a list of sObjects in bulk mode and record failures into Batch_Error_Log__c.
     */
   public static void safeInsert(List<SObject> records) {
        if (records==null || records.isEmpty()) return;
        Database.SaveResult[] results = Database.insert(records, false);
        for (Integer i=0;i<results.size();i++){
            if (!results[i].isSuccess()){
                String msgs='';
                for (Database.Error err : results[i].getErrors()) msgs += err.getMessage() + ' | ';
                try {
                    Batch_Error_Log__c log = new Batch_Error_Log__c(
                        Record_Type__c = String.valueOf(records[i].getSObjectType()),
                        Failed_Record_Id__c = records[i].get('Id')!=null? String.valueOf(records[i].get('Id')) : null,
                        Error_Message__c = msgs,
                        Created_Date__c = System.now()
                    );
                    insert log;
                } catch (Exception e){
                    System.debug('BatchUtils.safeInsert - logging failed: ' + e.getMessage());
                }
            }
        }
    }

    /**
     * Safely update a list of sObjects in bulk mode and record failures into Batch_Error_Log__c.
     */
    public static void safeUpdate(List<SObject> records) {
        if (records==null || records.isEmpty()) return;
        Database.SaveResult[] results = Database.update(records, false);
        for (Integer i=0;i<results.size();i++){
            if (!results[i].isSuccess()){
                String msgs='';
                for (Database.Error err : results[i].getErrors()) msgs += err.getMessage() + ' | ';
                try {
                    Batch_Error_Log__c log = new Batch_Error_Log__c(
                        Record_Type__c = String.valueOf(records[i].getSObjectType()),
                        Failed_Record_Id__c = records[i].get('Id')!=null? String.valueOf(records[i].get('Id')) : null,
                        Error_Message__c = msgs,
                        Created_Date__c = System.now()
                    );
                    insert log;
                } catch (Exception e){
                    System.debug('BatchUtils.safeUpdate - logging failed: ' + e.getMessage());
                }
            }
        }
    }

    /**
     * Best-effort delete: attempt bulk delete, fallback to record-by-record deletes to capture failures.
     */
   public static void safeDelete(List<SObject> records) {
        if (records==null || records.isEmpty()) return;
        try {
            Database.DeleteResult[] results = Database.delete(records, false);
            for (Integer i=0;i<results.size();i++){
                if (!results[i].isSuccess()){
                    String msgs='';
                    for (Database.Error err : results[i].getErrors()) msgs += err.getMessage() + ' | ';
                    try {
                        Batch_Error_Log__c log = new Batch_Error_Log__c(
                            Record_Type__c = String.valueOf(records[i].getSObjectType()),
                            Failed_Record_Id__c = records[i].get('Id')!=null? String.valueOf(records[i].get('Id')) : null,
                            Error_Message__c = msgs,
                            Created_Date__c = System.now()
                        );
                        insert log;
                    } catch (Exception e){
                        System.debug('BatchUtils.safeDelete - logging failed: ' + e.getMessage());
                    }
                }
            }
        } catch (Exception e) {
            // fallback individual delete
            for (SObject s: records) {
                try { delete s; } catch (Exception ex) {
                    try {
                        Batch_Error_Log__c log = new Batch_Error_Log__c(
                            Record_Type__c = String.valueOf(s.getSObjectType()),
                            Failed_Record_Id__c = s.get('Id')!=null? String.valueOf(s.get('Id')) : null,
                            Error_Message__c = ex.getMessage(),
                            Created_Date__c = System.now()
                        );
                        insert log;
                    } catch (Exception ignored) { System.debug('BatchUtils.safeDelete fallback logging failed: ' + ignored.getMessage()); }
                }
            }
        }
    }
}
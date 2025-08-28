public class SignatureBatchScheduler implements Schedulable {
    private String operationType;
    
    public SignatureBatchScheduler(String operation) {
        this.operationType = operation;
    }
    
    public void execute(SchedulableContext sc) {
        SignatureBatchProcessor batch = new SignatureBatchProcessor(operationType);
        Database.executeBatch(batch, 200);
    }
}

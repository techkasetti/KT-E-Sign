/**
 * @description A schedulable class to run the SignatureBatchProcessor for a given operation.
 */
public class SignatureBatchScheduler implements Schedulable {

    private final String operationType;

    /**
     * @description Constructor to specify the batch operation to schedule.
     * @param operation The operation type for the batch processor.
     */
    public SignatureBatchScheduler(String operation) {
        this.operationType = operation;
    }

    /**
     * @description Executes the scheduled job, which in turn starts the batch processor.
     * @param sc The SchedulableContext object.
     */
    public void execute(SchedulableContext sc) {
        SignatureBatchProcessor batch = new SignatureBatchProcessor(operationType);
        Database.executeBatch(batch, 200); // Specify a batch size, e.g., 200
    }
}
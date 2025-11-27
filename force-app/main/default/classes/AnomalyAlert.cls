public class AnomalyAlert {
    public String type;
    public String description;
    public String severity;
    public Datetime timestamp;
    public Decimal magnitude;
    public List<String> suggestedActions;
    public AnomalyAlert() {}
}
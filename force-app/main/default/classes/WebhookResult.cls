    
    public class WebhookResult {
        public Boolean success;
        public String message;
        public List<WebhookDelivery> deliveries;
        
        public WebhookResult(Boolean success, String message, List<WebhookDelivery> deliveries) {
            this.success = success;
            this.message = message;
            this.deliveries = deliveries;
        }
    }

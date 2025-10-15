public class APIResponse {
    @AuraEnabled public Integer statusCode;
    @AuraEnabled public String message;
    @AuraEnabled public Object data;
    public APIResponse(Integer statusCode, String message, Object data) {
        this.statusCode = statusCode;
        this.message = message;
        this.data = data;
    }
}

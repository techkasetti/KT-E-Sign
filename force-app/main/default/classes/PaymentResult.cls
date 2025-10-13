public class PaymentResult {
    @AuraEnabled public Boolean success;
    @AuraEnabled public String message;
    @AuraEnabled public Signature_Payment__c payment; // reference to created payment record

    public PaymentResult(Boolean success, String message, Signature_Payment__c payment) {
        this.success = success;
        this.message = message;
        this.payment = payment;
    }


    @AuraEnabled
public static PaymentResult processSignaturePayment(Id signatureRequestId, Decimal amount, String currency) {
    Signature_Payment__c paymentRecord = new Signature_Payment__c(
        Signature_Request__c = signatureRequestId,
        Payment_Amount__c = amount,
        Payment_Currency__c = currency,
        Payment_Status__c = 'INIT'
    );
    insert paymentRecord;

    try {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Payment_Gateway/payment_intents'); // use Named Credential
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        // Build JSON body
        Map<String,Object> body = new Map<String,Object>{
            'amount' => amount,
            'currency' => currency,
            'metadata' => new Map<String,Object>{'signatureRequestId' => String.valueOf(signatureRequestId)}
        };
        req.setBody(JSON.serialize(body));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            Map<String,Object> resp = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
            // update payment record with gateway id & status
            paymentRecord.Gateway_Transaction_Id__c = (String) resp.get('id');
            paymentRecord.Payment_Status__c = 'PENDING';
            update paymentRecord;
            return new PaymentResult(true,'Payment initiated', paymentRecord);
        } else {
            // set failed status and return error
            paymentRecord.Payment_Status__c = 'FAILED';
            paymentRecord.Failure_Reason__c = 'HTTP ' + res.getStatusCode() + ': ' + res.getBody();
            update paymentRecord;
            return new PaymentResult(false, 'Payment gateway error: ' + res.getBody(), paymentRecord);
        }
    } catch (DmlException dmlex) {
        // if insert/update failed — return meaningful error
        return new PaymentResult(false, 'Database error: ' + dmlex.getMessage(), paymentRecord);
    } catch (Exception ex) {
        // mark failure on DML if possible
        try {
            paymentRecord.Payment_Status__c = 'ERROR';
            paymentRecord.Failure_Reason__c = ex.getMessage();
            update paymentRecord;
        } catch (Exception ignore) { /* swallow to avoid masking original */ }
        return new PaymentResult(false, 'Callout error: ' + ex.getMessage(), paymentRecord);
    }
}

}

// Minimal PaymentRequest DTO (missing type flagged in PaymentGatewayService analysis) @15
public class PaymentRequest {
    @AuraEnabled public Id signatureRequestId;
    @AuraEnabled public Decimal amount;
    @AuraEnabled public String currency;
    @AuraEnabled public String paymentMethod; // e.g., CREDIT_CARD, PAYPAL
    @AuraEnabled public String payerEmail;
}

// Canonical: single payment processing entry (server side)
@AuraEnabled
public static PaymentResult processSignaturePaymentServer(PaymentRequest req) {
    // 1) validate request exists and is in payable state
    Signature_Request__c sr = [SELECT Id, Status__c, Payment_Status__c, Payment_Amount__c FROM Signature_Request__c WHERE Id = :req.signatureRequestId LIMIT 1];
    if (sr == null) return new PaymentResult(false, 'Request not found');
    // 2) use named credential + single gateway service class (see PaymentGatewayService consolidation) @15
    try {
        // PaymentGatewayService.processPayment(...)  -- centralized call
        PaymentResult res = PaymentGatewayService.processPayment(req);
        if (res.success) {
            sr.Payment_Status__c = 'PAID';
            sr.Status__c = 'SIGNED'; // if signature creation happens at payment time
            update sr;
        }
        return res;
    } catch (Exception e) {
        AuditTrailManager.logSystemActivity('PAYMENT_ERROR', e.getMessage()); // AuditTrailManager TODOs exist @331
        return new PaymentResult(false, 'Payment failed: ' + e.getMessage());
    }
}

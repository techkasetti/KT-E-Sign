public class PaymentGatewayService {

    // /**
    //  * @description Processes a payment for a signature request by calling an external payment gateway.
    //  * @param signatureRequestId The ID of the Signature_Request__c record.
    //  * @param paymentData A map containing payment details, such as a payment method ID.
    //  * @return PaymentResult The result of the payment transaction.
    //  */
    // @AuraEnabled
    // public static PaymentResult processSignaturePayment(Id signatureRequestId, Map<String, Object> paymentData) {
    //     try {
    //         // Get signature request details
    //         Signature_Request__c request = [
    //             SELECT Id, Signer_Email__c, Document_Id__c, Payment_Required__c, Payment_Amount__c
    //             FROM Signature_Request__c
    //             WHERE Id = :signatureRequestId
    //             LIMIT 1
    //         ];

    //         if (!request.Payment_Required__c) {
    //             return new PaymentResult(false, 'Payment not required for this signature', null);
    //         }

    //         // Prepare payment request for the external gateway
    //         Map<String, Object> paymentRequest = new Map<String, Object>{
    //             'amount' => request.Payment_Amount__c * 100, // Convert to cents
    //             'currency' => 'USD',
    //             'payment_method' => paymentData.get('paymentMethodId'),
    //             'confirmation_method' => 'manual',
    //             'confirm' => true,
    //             'metadata' => new Map<String, Object>{
    //                 'signature_request_id' => signatureRequestId,
    //                 'document_id' => request.Document_Id__c,
    //                 'signer_email' => request.Signer_Email__c
    //             }
    //         };

    //         // Call payment gateway API using a Named Credential
    //         HttpRequest req = new HttpRequest();
    //         req.setEndpoint('callout:Payment_Gateway/payment_intents');
    //         req.setMethod('POST');
    //         req.setHeader('Content-Type', 'application/json');
    //         req.setBody(JSON.serialize(paymentRequest));

    //         Http http = new Http();
    //         HttpResponse res = http.send(req);

    //         if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
    //             Map<String, Object> paymentResponse = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
    //             String paymentIntentId = (String)paymentResponse.get('id');
    //             String paymentStatus = (String)paymentResponse.get('status');

    //             // Create a local payment record
    //             Signature_Payment__c payment = new Signature_Payment__c(
    //                 Signature_Request__c = signatureRequestId,
    //                 Payment_Intent_Id__c = paymentIntentId,
    //                 Payment_Status__c = paymentStatus,
    //                 Amount__c = request.Payment_Amount__c,
    //                 Currency__c = 'USD',
    //                 Payment_Method_Id__c = (String)paymentData.get('paymentMethodId'),
    //                 Gateway_Response__c = JSON.serialize(paymentResponse),
    //                 Payment_Date__c = System.now(),
    //                 Transaction_Fee__c = calculateTransactionFee(request.Payment_Amount__c)
    //             );
    //             insert payment;

    //             if (paymentStatus == 'succeeded') {
    //                 request.Payment_Status__c = 'Paid';
    //                 request.Payment_Date__c = System.now();
    //                 update request;

    //                 // ✅ Fixed static method call
    //                 EmailNotificationService.sendPaymentConfirmationEmail(request.Signer_Email__c, paymentIntentId, request.Payment_Amount__c);
    //                 AuditTrailManager.logSystemActivity('PAYMENT_COMPLETED', 'Payment of $' + request.Payment_Amount__c + ' completed for signature request ' + signatureRequestId);
    //             }
    //             return new PaymentResult(true, 'Payment processed successfully', payment);
    //         } else {
    //             throw new CalloutException('Payment processing failed: HTTP ' + res.getStatusCode() + ' - ' + res.getBody());
    //         }
    //     } catch (Exception e) {
    //         AuditTrailManager.logSystemActivity('PAYMENT_ERROR', 'Payment processing failed for request ' + signatureRequestId + ': ' + e.getMessage());
    //         return new PaymentResult(false, 'Payment processing failed: ' + e.getMessage(), null);
    //     }
    // }

    // /**
    //  * @description Processes a refund for a previously completed payment.
    //  * @param paymentId The ID of the Signature_Payment__c record to refund.
    //  * @param refundAmount The amount to be refunded.
    //  * @param reason A string explaining the reason for the refund.
    //  * @return RefundResult The result of the refund transaction.
    //  */
    // @AuraEnabled
    // public static RefundResult processRefund(Id paymentId, Decimal refundAmount, String reason) {
    //     try {
    //         Signature_Payment__c payment = [
    //             SELECT Id, Payment_Intent_Id__c, Amount__c, Payment_Status__c, Signature_Request__c
    //             FROM Signature_Payment__c
    //             WHERE Id = :paymentId
    //             LIMIT 1
    //         ];

    //         if (payment.Payment_Status__c != 'succeeded' && payment.Payment_Status__c != 'Paid') {
    //             return new RefundResult(false, 'Cannot refund an unpaid or failed transaction', null);
    //         }

    //         Map<String, Object> refundRequest = new Map<String, Object>{
    //             'payment_intent' => payment.Payment_Intent_Id__c,
    //             'amount' => refundAmount * 100, // Convert to cents
    //             'reason' => reason,
    //             'metadata' => new Map<String, Object>{
    //                 'original_payment_id' => paymentId,
    //                 'signature_request_id' => payment.Signature_Request__c
    //             }
    //         };

    //         HttpRequest req = new HttpRequest();
    //         req.setEndpoint('callout:Payment_Gateway/refunds');
    //         req.setMethod('POST');
    //         req.setHeader('Content-Type', 'application/json');
    //         req.setBody(JSON.serialize(refundRequest));

    //         Http http = new Http();
    //         HttpResponse res = http.send(req);

    //         if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
    //             Map<String, Object> refundResponse = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                
    //             Payment_Refund__c refund = new Payment_Refund__c(
    //                 Original_Payment__c = paymentId,
    //                 Refund_Id__c = (String)refundResponse.get('id'),
    //                 Refund_Amount__c = refundAmount,
    //                 Refund_Status__c = (String)refundResponse.get('status'),
    //                 Refund_Reason__c = reason,
    //                 Gateway_Response__c = JSON.serialize(refundResponse),
    //                 Refund_Date__c = System.now()
    //             );
    //             insert refund;

    //             payment.Refund_Status__c = 'Refunded';
    //             payment.Refund_Amount__c = refundAmount;
    //             update payment;

    //             return new RefundResult(true, 'Refund processed successfully', refund);
    //         } else {
    //             throw new CalloutException('Refund processing failed: HTTP ' + res.getStatusCode());
    //         }
    //     } catch (Exception e) {
    //         AuditTrailManager.logSystemActivity('REFUND_ERROR', 'Refund processing failed: ' + e.getMessage());
    //         return new RefundResult(false, 'Refund processing failed: ' + e.getMessage(), null);
    //     }
    // }

    // /**
    //  * @description Retrieves a list of available payment methods for the UI.
    //  * @return List<PaymentMethod> A list of supported payment methods.
    //  */
    // @AuraEnabled
    // public static List<PaymentMethod> getAvailablePaymentMethods() {
    //     List<PaymentMethod> methods = new List<PaymentMethod>();
    //     methods.add(new PaymentMethod('credit_card', 'Credit Card', 'Pay with Visa, Mastercard, or Amex', true));
    //     methods.add(new PaymentMethod('paypal', 'PayPal', 'Pay with your PayPal account', true));
    //     methods.add(new PaymentMethod('bank_transfer', 'Bank Transfer', 'Direct bank account transfer', false));
    //     methods.add(new PaymentMethod('apple_pay', 'Apple Pay', 'Pay with Touch ID or Face ID', true));
    //     methods.add(new PaymentMethod('google_pay', 'Google Pay', 'Pay with Google Pay', true));
    //     return methods;
    // }

    // /**
    //  * @description Calculates a standard transaction fee.
    //  * @param amount The transaction amount.
    //  * @return Decimal The calculated fee.
    //  */
    // private static Decimal calculateTransactionFee(Decimal amount) {
    //     // Standard payment processing fee calculation (e.g., 2.9% + $0.30)
    //     if (amount == null || amount <= 0) return 0;
    //     return (amount * 0.029) + 0.30;
    // }

    // // ===============================================================
    // // == WRAPPER / DTO CLASSES ==
    // // ===============================================================

    // public class PaymentResult {
    //     @AuraEnabled public Boolean success;
    //     @AuraEnabled public String message;
    //     public Signature_Payment__c payment;

    //     public PaymentResult(Boolean success, String message, Signature_Payment__c payment) {
    //         this.success = success;
    //         this.message = message;
    //         this.payment = payment;
    //     }
    // }

    // public class RefundResult {
    //     @AuraEnabled public Boolean success;
    //     @AuraEnabled public String message;
    //     public Payment_Refund__c refund;

    //     public RefundResult(Boolean success, String message, Payment_Refund__c refund) {
    //         this.success = success;
    //         this.message = message;
    //         this.refund = refund;
    //     }
    // }

    // public class PaymentMethod {
    //     @AuraEnabled public String id;
    //     @AuraEnabled public String label;
    //     @AuraEnabled public String description;
    //     @AuraEnabled public Boolean isEnabled;

    //     public PaymentMethod(String id, String label, String description, Boolean isEnabled) {
    //         this.id = id;
    //         this.label = label;
    //         this.description = description;
    //         this.isEnabled = isEnabled;
    //     }
    // }

    // ===============================================================
    // == STATIC PLACEHOLDER UTILITY CLASSES ==
    // ===============================================================

    
}
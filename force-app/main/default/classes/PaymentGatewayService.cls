public class PaymentGatewayService {
    private static final String ENDPOINT = 'callout:Payment_Gateway'; // Named Credential
public class PaymentRequest {
    @AuraEnabled public Id signatureRequestId;
    @AuraEnabled public Decimal amount;
    @AuraEnabled public String currency;
    @AuraEnabled public String paymentMethodToken;
  }

  public class PaymentResult {
    @AuraEnabled public Boolean success;
    @AuraEnabled public String message;
    @AuraEnabled public String externalId;
    public PaymentResult(Boolean s, String m, String id){ success=s; message=m; externalId=id;}
  }
@future(callout=true)
public static void processPaymentAsync(Id signatureRequestId, Map<String,Object> paymentData) {
    Signature_Request__c r = [SELECT Id, Amount__c FROM Signature_Request__c WHERE Id = :signatureRequestId LIMIT 1];
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:PaymentGateway/charges');
    req.setMethod('POST');
    req.setHeader('Content-Type','application/json');
    req.setBody(JSON.serialize(paymentData));
    Http http = new Http();
    try {
        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            Map<String,Object> resp = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
            Payment_Transaction__c tx = new Payment_Transaction__c(Signature_Request__c = r.Id, Amount__c = r.Amount__c, External_Id__c = (String)resp.get('id'), Payment_Status__c = 'COMPLETED');
            insert tx;
        } else {
            Payment_Transaction__c tx = new Payment_Transaction__c(Signature_Request__c = r.Id, Amount__c = r.Amount__c, Payment_Status__c = 'FAILED', Error_Message__c = res.getBody());
            insert tx;
        }
    } catch (Exception e) {
        System.debug('Payment callout failed: ' + e.getMessage());
        // optionally create a failure record
    }
}


  @AuraEnabled
  public static PaymentResult processPayment(PaymentRequest req) {
    try {
      // validate request state
      Signature_Request__c sr = [SELECT Id, Status__c FROM Signature_Request__c WHERE Id=:req.signatureRequestId LIMIT 1];
      if (sr == null) return new PaymentResult(false, 'Signature request not found', null);
      HttpRequest r = new HttpRequest();
      r.setEndpoint(ENDPOINT + '/v1/payments');
      r.setMethod('POST');
      r.setHeader('Content-Type','application/json');
      Map<String,Object> body = new Map<String,Object>{
        'amount' => req.amount,
        'currency' => req.currency,
        'payment_method_token' => req.paymentMethodToken,
        'reference' => 'SigReq:' + String.valueOf(req.signatureRequestId)
      };
      r.setBody(JSON.serialize(body));
      // Using Named Credential handles auth; do NOT construct Authorization header manually
      Http http = new Http();
      HttpResponse resp = http.send(r);
      Integer status = resp.getStatusCode();
      if (status == 200 || status == 201) {
        Map<String,Object> jr = (Map<String,Object>) JSON.deserializeUntyped(resp.getBody());
        String extId = (String) jr.get('id');
        // record payment
        Signature_Payment__c pay = new Signature_Payment__c(
          Signature_Request__c = req.signatureRequestId,
          Amount__c = req.amount,
          External_Id__c = extId,
          Status__c = 'Completed'
        );
        insert pay;
        // Update signature request if desired
        sr.Status__c = 'Signed';
        update sr;
        return new PaymentResult(true, 'Payment processed', extId);
      } else {
        return new PaymentResult(false, 'Gateway error: ' + resp.getBody(), null);
      }
    } catch (Exception e) {
      AuditTrailManager.logSystemActivity('PAYMENT_ERROR', 'Payment exception: ' + e.getMessage()); //@14
      return new PaymentResult(false, 'Exception: ' + e.getMessage(), null);
    }
  }
@AuraEnabled
    public static PaymentResult processPayment(PaymentRequest request) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT + '/payments');
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        // Use Named Credential auth; do NOT compose Authorization header with inline secrets
        Map<String,Object> payload = new Map<String,Object>{
            'amount' => request.amount,
            'currency' => request.currency,
            'method' => request.paymentMethod,
            'metadata' => new Map<String,String>{'signatureRequestId' => String.valueOf(request.signatureRequestId)}
        };
        req.setBody(JSON.serialize(payload));
        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            // parse response
            return new PaymentResult(true,'Payment processed', JSON.deserializeUntyped(res.getBody()));
        } else {
            return new PaymentResult(false,'Gateway error: ' + res.getBody());
        }
    }



    @future(callout=true)
    public static void processPayment(String signatureRequestId, Decimal amount) {
      // canonical: in ESignatureAPIController.updateSignatureRequest (finish processing and verify)
Signature_Request__c existingRequest = [SELECT Id, DocumentId__c, Status__c, DocumentHash__c
    FROM Signature_Request__c WHERE Id = :signatureRequestId LIMIT 1];

// compute received document hash (helper must be implemented)
String receivedHash = SecurityUtils.computeSha256Base64(receivedDocumentContent);

// verify
if (existingRequest.DocumentHash__c == null || existingRequest.DocumentHash__c != receivedHash) {
    // Record failure and return 409 or 400 depending policy
    AuditTrailManager.createAuditEntry(existingRequest.Id, 'DOCUMENT_HASH_MISMATCH', 'ERROR',
        'Hash mismatch during signature submission');
    return new APIResponse(409, 'Document hash mismatch – signature rejected', null);
}

// proceed to mark request Signed, insert validation record, send notifications
existingRequest.Status__c = 'Signed';
existingRequest.CompletedDate__c = System.now();
update existingRequest;
    }




    @AuraEnabled
  public static PaymentResult processSignaturePayment(Id signatureRequestId, Decimal amount, String paymentMethodToken) {
    try {
      // validate request
      Signature_Request__c req = [SELECT Id, Status__c FROM Signature_Request__c WHERE Id = :signatureRequestId LIMIT 1];
      // prepare payload
      Map<String,Object> payload = new Map<String,Object>{
        'amount' => amount,
        'currency' => 'USD',
        'payment_method_token' => paymentMethodToken,
        'reference' => 'SigReq:' + String.valueOf(signatureRequestId)
      };
      // callout using Named Credential (PaymentGateway)
      HttpRequest r = new HttpRequest();
      r.setEndpoint('callout:PaymentGateway/v1/payments');
      r.setMethod('POST');
      r.setHeader('Content-Type','application/json');
      r.setBody(JSON.serialize(payload));
      // Using Named Credential avoids manual Authorization header
      Http http = new Http();
      HttpResponse resp = http.send(r);
      if (resp.getStatusCode() == 201) {
        Map<String,Object> respJson = (Map<String,Object>) JSON.deserializeUntyped(resp.getBody());
        // create and link payment record
        Signature_Payment__c p = new Signature_Payment__c(
          Signature_Request__c = signatureRequestId,
          Amount__c = amount,
          External_Id__c = (String) respJson.get('id'),
          Status__c = 'COMPLETED'
        );
        insert p;
        return new PaymentResult(true, 'OK', p.Id);
      } else {
        return new PaymentResult(false, 'Gateway failure: ' + resp.getBody(), null);
      }
    } catch (Exception e) {
      return new PaymentResult(false, 'Exception: ' + e.getMessage(), null);
    }
  }
        @AuraEnabled
    public static PaymentResult processSignaturePayment(Id signatureRequestId, Map<String, Object> paymentData) {
        try {
            // Get signature request details
            Signature_Request__c request = [
                SELECT Id, Signer_Email__c, Document_Id__c, Payment_Required__c, Payment_Amount__c
                FROM Signature_Request__c 
                WHERE Id = :signatureRequestId 
                LIMIT 1
            ];
            
            if (!request.Payment_Required__c) {
                return new PaymentResult(false, 'Payment not required for this signature', null);
            }
            
            // Prepare payment request
            Map<String, Object> paymentRequest = new Map<String, Object>{
                'amount' => request.Payment_Amount__c * 100, // Convert to cents
                'currency' => 'USD',
                'payment_method' => paymentData.get('paymentMethodId'),
                'confirmation_method' => 'manual',
                'confirm' => true,
                'metadata' => new Map<String, Object>{
                    'signature_request_id' => signatureRequestId,
                    'document_id' => request.Document_Id__c,
                    'signer_email' => request.Signer_Email__c
                }
            };
            
            // Call payment gateway API
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Payment_Gateway/payment_intents');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer {!$Credential.Payment_Gateway.APIKey}');
            req.setBody(JSON.serialize(paymentRequest));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Map<String, Object> paymentResponse = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                
                String paymentIntentId = (String)paymentResponse.get('id');
                String paymentStatus = (String)paymentResponse.get('status');
                
                // Create payment record
                Signature_Payment__c payment = new Signature_Payment__c(
                    Signature_Request__c = signatureRequestId,
                    Payment_Intent_Id__c = paymentIntentId,
                    Payment_Status__c = paymentStatus,
                    Amount__c = request.Payment_Amount__c,
                    Currency__c = 'USD',
                    Payment_Method_Id__c = (String)paymentData.get('paymentMethodId'),
                    Gateway_Response__c = JSON.serialize(paymentResponse),
                    Payment_Date__c = System.now(),
                    Transaction_Fee__c = calculateTransactionFee(request.Payment_Amount__c)
                );
                insert payment;
                
                // Update signature request with payment status
                if (paymentStatus == 'succeeded') {
                    request.Payment_Status__c = 'Paid';
                    request.Payment_Date__c = System.now();
                    update request;
                    
                    // Send payment confirmation email
                    EmailNotificationService.sendPaymentConfirmationEmail(
                        request.Signer_Email__c,
                        paymentIntentId,
                        request.Payment_Amount__c
                    );
                    
                    // Log successful payment
                    AuditTrailManager.logDocumentActivity(
                        request.Document_Id__c,
                        'PAYMENT_COMPLETED',
                        'Payment of $' + request.Payment_Amount__c + ' completed for signature request'
                    );
                }
                
                return new PaymentResult(true, 'Payment processed successfully', payment);
                
            } else {
                throw new CalloutException('Payment processing failed: HTTP ' + res.getStatusCode());
            }
            
        } catch (Exception e) {
            AuditTrailManager.logSystemActivity('PAYMENT_ERROR', 'Payment processing failed: ' + e.getMessage());
            return new PaymentResult(false, 'Payment processing failed: ' + e.getMessage(), null);
        }
    }
    
    @AuraEnabled
    public static RefundResult processRefund(Id paymentId, Decimal refundAmount, String reason) {
        try {
            // Get payment details
            Signature_Payment__c payment = [
                SELECT Id, Payment_Intent_Id__c, Amount__c, Payment_Status__c, Signature_Request__c
                FROM Signature_Payment__c 
                WHERE Id = :paymentId 
                LIMIT 1
            ];
            
            if (payment.Payment_Status__c != 'Paid') {
                return new RefundResult(false, 'Cannot refund unpaid transaction', null);
            }
            
            // Prepare refund request
            Map<String, Object> refundRequest = new Map<String, Object>{
                'payment_intent' => payment.Payment_Intent_Id__c,
                'amount' => refundAmount * 100, // Convert to cents
                'reason' => reason,
                'metadata' => new Map<String, Object>{
                    'original_payment_id' => paymentId,
                    'signature_request_id' => payment.Signature_Request__c
                }
            };
            
            // Call payment gateway refund API
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Payment_Gateway/refunds');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer {!$Credential.Payment_Gateway.APIKey}');
            req.setBody(JSON.serialize(refundRequest));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Map<String, Object> refundResponse = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                
                // Create refund record
                Payment_Refund__c refund = new Payment_Refund__c(
                    Original_Payment__c = paymentId,
                    Refund_Id__c = (String)refundResponse.get('id'),
                    Refund_Amount__c = refundAmount,
                    Refund_Status__c = (String)refundResponse.get('status'),
                    Refund_Reason__c = reason,
                    Gateway_Response__c = JSON.serialize(refundResponse),
                    Refund_Date__c = System.now()
                );
                insert refund;
                
                // Update original payment status
                payment.Refund_Status__c = 'Refunded';
                payment.Refund_Amount__c = refundAmount;
                update payment;
                
                return new RefundResult(true, 'Refund processed successfully', refund);
                
            } else {
                throw new CalloutException('Refund processing failed: HTTP ' + res.getStatusCode());
            }
            
        } catch (Exception e) {
            AuditTrailManager.logSystemActivity('REFUND_ERROR', 'Refund processing failed: ' + e.getMessage());
            return new RefundResult(false, 'Refund processing failed: ' + e.getMessage(), null);
        }
    }
    
    private static Decimal calculateTransactionFee(Decimal amount) {
        // Standard payment processing fee calculation (2.9% + $0.30)
        return (amount * 0.029) + 0.30;
    }
    
    public class PaymentResult {
        public Boolean success;
        public String message;
        public Signature_Payment__c payment;
        
        public PaymentResult(Boolean success, String message, Signature_Payment__c payment) {
            this.success = success;
            this.message = message;
            this.payment = payment;
        }
    }
    
    public class RefundResult {
        public Boolean success;
        public String message;
        public Payment_Refund__c refund;
        
        public RefundResult(Boolean success, String message, Payment_Refund__c refund) {
            this.success = success;
            this.message = message;
            this.refund = refund;
        }
    }
    public static PaymentResult processSignaturePayment(PaymentRequest paymentRequest) {
        try {
            Http http = new Http();
            

        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:PaymentGateway/charges');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + getPaymentGatewayToken());
        
        // Prepare payment data
        Map<String, Object> paymentData = new Map<String, Object>{
            'amount' => paymentRequest.amount * 100, // Convert to cents
            'currency' => paymentRequest.currency,
            'source' => paymentRequest.paymentMethodId,
            'description' => 'E-Signature Service Fee - ' + paymentRequest.signatureRequestId,
            'metadata' => new Map<String, Object>{
                'signature_request_id' => paymentRequest.signatureRequestId,
                'user_id' => paymentRequest.userId,
                'document_id' => paymentRequest.documentId
            }
        };
        
        request.setBody(JSON.serialize(paymentData));
        request.setTimeout(30000);
        
        HttpResponse response = http.send(request);
        Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        
        if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
            // Create payment record
            Payment_Transaction__c payment = new Payment_Transaction__c();
            payment.Signature_Request__c = paymentRequest.signatureRequestId;
            payment.Amount__c = paymentRequest.amount;
            payment.Currency__c = paymentRequest.currency;
            payment.Payment_Method_Id__c = paymentRequest.paymentMethodId;
            payment.Gateway_Transaction_Id__c = (String) responseData.get('id');
            payment.Status__c = (String) responseData.get('status');
            payment.Payment_Date__c = System.now();
            payment.Gateway_Response__c = JSON.serialize(responseData);
            insert payment;
            
            // Update signature request with payment status
            Signature_Request__c sigRequest = [SELECT Id, Payment_Required__c FROM Signature_Request__c WHERE Id = :paymentRequest.signatureRequestId];
            sigRequest.Payment_Status__c = 'Completed';
            sigRequest.Payment_Transaction__c = payment.Id;
            update sigRequest;
            
            return new PaymentResult(true, 'Payment processed successfully', payment.Id);
        } else {
            return new PaymentResult(false, 'Payment failed: ' + responseData.get('error'), null);
        }
        
    } catch (Exception e) {
        System.debug('Payment processing error: ' + e.getMessage());
        return new PaymentResult(false, 'Payment processing error: ' + e.getMessage(), null);
    }
}

public static String getPaymentGatewayToken() {
    // Retrieve stored payment gateway credentials
    Payment_Gateway_Settings__c settings = Payment_Gateway_Settings__c.getOrgDefaults();
    return settings.API_Key__c;
}
    @AuraEnabled
    public static PaymentResult processSignaturePayment(Id signatureRequestId, Map<String, Object> paymentData) {
        try {
            // Get signature request details
            Signature_Request__c request = [
                SELECT Id, SignerEmail__c, DocumentId__r.DocumentTitle__c, Payment_Amount__c
                FROM Signature_Request__c 
                WHERE Id = :signatureRequestId
            ];
            
            // Create payment record
            Signature_Payment__c payment = new Signature_Payment__c();
            payment.Signature_Request__c = signatureRequestId;
            payment.Payment_Amount__c = (Decimal)paymentData.get('amount');
            payment.Payment_Method__c = (String)paymentData.get('payment_method');
            payment.Payment_Status__c = 'PROCESSING';
            insert payment;
            
            // Process payment through external gateway
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:PaymentGateway/charges');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer {!$Credential.PaymentGateway.AccessToken}');
            
            Map<String, Object> chargeRequest = new Map<String, Object>{
                'amount' => ((Decimal)paymentData.get('amount') * 100).intValue(), // Convert to cents
                'currency' => 'usd',
                'source' => paymentData.get('token'),
                'description' => 'E-Signature Service: ' + request.DocumentId__r.DocumentTitle__c,
                'metadata' => new Map<String, Object>{
                    'signature_request_id' => signatureRequestId,
                    'signer_email' => request.SignerEmail__c
                }
            };
            
            req.setBody(JSON.serialize(chargeRequest));
            HttpResponse res = http.send(req);
            
            Map<String, Object> paymentResponse = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            
            // Update payment record
            payment.External_Payment_Id__c = (String)paymentResponse.get('id');
            payment.Payment_Status__c = res.getStatusCode() == 200 ? 'COMPLETED' : 'FAILED';
            payment.Response_Details__c = res.getBody();
            update payment;
            
            return new PaymentResult(
                payment.Payment_Status__c == 'COMPLETED',
                (String)paymentResponse.get('id'),
                payment.Payment_Status__c
            );
            
        } catch (Exception e) {
            System.debug('Payment processing error: ' + e.getMessage());
            return new PaymentResult(false, null, 'FAILED: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<PaymentMethod> getAvailablePaymentMethods() {
        List<PaymentMethod> methods = new List<PaymentMethod>();
        
        // Credit Card
        methods.add(new PaymentMethod('credit_card', 'Credit Card', 'Pay with Visa, Mastercard, or Amex', true));
        
        // PayPal
        methods.add(new PaymentMethod('paypal', 'PayPal', 'Pay with your PayPal account', true));
        
        // Bank Transfer
        methods.add(new PaymentMethod('bank_transfer', 'Bank Transfer', 'Direct bank account transfer', false));
        
        // Digital Wallets
        methods.add(new PaymentMethod('apple_pay', 'Apple Pay', 'Pay with Touch ID or Face ID', true));
        methods.add(new PaymentMethod('google_pay', 'Google Pay', 'Pay with Google Pay', true));
        
        return methods;
    }

}

@IsTest
private class PaymentGatewayServiceTest {
    
    // Mock HTTP Response Class
    private class PaymentHttpMock implements HttpCalloutMock {
        private Integer code;
        private String body;
        PaymentHttpMock(Integer code, String body) {
            this.code = code;
            this.body = body;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(code);
            res.setBody(body);
            return res;
        }
    }

    // Dummy supporting classes to make the test self-contained
    public class EmailNotificationService {
        public  void sendPaymentConfirmationEmail(String email, String id, Decimal amount) { }
    }
    public class AuditTrailManager {
        public  void logSystemActivity(String type, String msg) { }
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

    // Test Success Scenario (Payment succeeded)
    @IsTest
    static void testProcessSignaturePayment_Success() {
        Signature_Request__c req = new Signature_Request__c(
            Name = 'Req1',
            SignerEmail__c = 'test@example.com',
            
            Payment_Required__c = true,
            Payment_Amount__c = 50
        );
        insert req;

        Test.setMock(HttpCalloutMock.class, new PaymentHttpMock(200, 
            '{"id":"pi_123","status":"succeeded"}'
        ));

        Map<String, Object> paymentData = new Map<String, Object>{
            'paymentMethodId' => 'pm_456'
        };

        Test.startTest();
        PaymentGatewayService.processSignaturePayment(req.Id, paymentData);
        Test.stopTest();

        List<Signature_Payment__c> payments = [
            SELECT Id, Payment_Status__c, Payment_Intent_Id__c 
            FROM Signature_Payment__c
        ];
    }

    // Test Scenario: Payment not required
    @IsTest
    static void testProcessSignaturePayment_NotRequired() {
        Signature_Request__c req = new Signature_Request__c(
            Name = 'Req2',
            SignerEmail__c = 'noPay@example.com',
          
            Payment_Required__c = false,
            Payment_Amount__c = 0
        );
        insert req;

        Map<String, Object> paymentData = new Map<String, Object>{
            'paymentMethodId' => 'pm_none'
        };

        Test.startTest();
        PaymentGatewayService.processSignaturePayment(req.Id, paymentData);
        Test.stopTest();
    }

    // Test Failure Scenario: HTTP Error
    @IsTest
    static void testProcessSignaturePayment_Failure() {
        Signature_Request__c req = new Signature_Request__c(
            Name = 'Req3',
            SignerEmail__c = 'fail@example.com',
            
            Payment_Required__c = true,
            Payment_Amount__c = 100
        );
        insert req;

        Test.setMock(HttpCalloutMock.class, new PaymentHttpMock(400, '{"error":"invalid"}'));

        Map<String, Object> paymentData = new Map<String, Object>{
            'paymentMethodId' => 'pm_fail'
        };

        Test.startTest();
        PaymentGatewayService.processSignaturePayment(req.Id, paymentData);
        Test.stopTest();
    }

    // Test Exception Scenario (query fails or callout missing)
    @IsTest
    static void testProcessSignaturePayment_Exception() {
        Signature_Request__c req = new Signature_Request__c(
            Name = 'Req3',
            SignerEmail__c = 'fail@example.com',
            
            Payment_Required__c = true,
            Payment_Amount__c = 100
        );
        insert req;
        
        Id oneid=[Select Id from Signature_Request__c].Id;
        Map<String, Object> paymentData = new Map<String, Object>{
            'paymentMethodId' => 'pm_123'
        };

        Test.startTest();
        PaymentGatewayService.processSignaturePayment(oneid, paymentData);
        Test.stopTest();
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
   
    
    // ---- Mock HTTP Callout ----
    private class RefundHttpMock implements HttpCalloutMock {
        private Integer code;
        private String body;
        RefundHttpMock(Integer code, String body) {
            this.code = code;
            this.body = body;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(code);
            res.setBody(body);
            return res;
        }
    }

    // ---- Dummy Supporting Classes ----
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

    public class AuditTrailManagerone {
        public  void logSystemActivity(String type, String msg) { }
    }

    // ---- Test Case 1: Successful Refund ----
    @IsTest
    static void testProcessRefund_Success() {
        Signature_Payment__c pay = new Signature_Payment__c(
            Payment_Intent_Id__c = 'pi_12345',
            Amount__c = 200,
            Payment_Status__c = 'succeeded'
        );
        insert pay;

        Test.setMock(HttpCalloutMock.class, new RefundHttpMock(200, 
            '{"id":"re_123","status":"succeeded"}'
        ));

        Test.startTest();
        PaymentGatewayService.processRefund(pay.Id, 50, 'Customer request');
        Test.stopTest();

        List<Payment_Refund__c> refunds = [SELECT Id, Refund_Status__c FROM Payment_Refund__c];
        List<Signature_Payment__c> payments = [SELECT Id, Refund_Status__c FROM Signature_Payment__c];
    }

    // ---- Test Case 2: Payment Not Paid or Failed ----
    @IsTest
    static void testProcessRefund_Unpaid() {
        Signature_Payment__c pay = new Signature_Payment__c(
            Payment_Intent_Id__c = 'pi_unpaid',
            Amount__c = 100,
            Payment_Status__c = 'Pending'
        );
        insert pay;

        Test.startTest();
        PaymentGatewayService.processRefund(pay.Id, 20, 'Unpaid case');
        Test.stopTest();
    }

    // ---- Test Case 3: HTTP Error (400/500) ----
    @IsTest
    static void testProcessRefund_HttpError() {
        Signature_Payment__c pay = new Signature_Payment__c(
            Payment_Intent_Id__c = 'pi_error',
            Amount__c = 150,
            Payment_Status__c = 'Paid'
        );
        insert pay;

        Test.setMock(HttpCalloutMock.class, new RefundHttpMock(400, '{"error":"Invalid"}'));

        Test.startTest();
        PaymentGatewayService.processRefund(pay.Id, 30, 'Bad request');
        Test.stopTest();
    }

    // ---- Test Case 4: Exception (Invalid ID / Query Failure) ----
    @IsTest
    static void testProcessRefund_Exception() {
          Signature_Payment__c pay = new Signature_Payment__c(
            Payment_Intent_Id__c = 'pi_error',
            Amount__c = 150,
            Payment_Status__c = 'Paid'
        );
        insert pay;
        Id payment=[Select Id from Signature_Payment__c ].Id;
        Test.startTest();
        PaymentGatewayService.processRefund(payment, 10, 'Invalid ID');
        Test.stopTest();
    }


    
    
}
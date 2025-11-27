@IsTest
private class PaymentResultTest {

    // ---- Universal Mock ----
    private class PaymentHttpMock implements HttpCalloutMock {
        Integer code;
        String body;
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

    // ---- 1. Success Case (HTTP 200) ----
    @IsTest
    static void testProcessSignaturePayment_Success200() {
        Signature_Request__c req = new Signature_Request__c(
            Name = 'Success200', SignerEmail__c = 'test200@example.com'
        );
        insert req;

        Test.setMock(HttpCalloutMock.class, new PaymentHttpMock(200, '{"id":"pi_200","status":"succeeded"}'));

        Test.startTest();
        PaymentResult result = PaymentResult.processSignaturePayment(req.Id, 150.00, 'USD');
        Test.stopTest();

        
    }

    // ---- 2. Success Case (HTTP 201) ----
    @IsTest
    static void testProcessSignaturePayment_Success201() {
        Signature_Request__c req = new Signature_Request__c(
            Name = 'Success201', SignerEmail__c = 'test201@example.com'
        );
        insert req;

        Test.setMock(HttpCalloutMock.class, new PaymentHttpMock(201, '{"id":"pi_201","status":"succeeded"}'));

        Test.startTest();
        PaymentResult result = PaymentResult.processSignaturePayment(req.Id, 175.00, 'USD');
        Test.stopTest();
    }

    // ---- 3. HTTP Failure Case (HTTP 400) ----
    @IsTest
    static void testProcessSignaturePayment_HttpFail() {
        Signature_Request__c req = new Signature_Request__c(
            Name = 'Fail400', SignerEmail__c = 'test400@example.com'
        );
        insert req;

        Test.setMock(HttpCalloutMock.class, new PaymentHttpMock(400, '{"error":"Invalid"}'));

        Test.startTest();
        PaymentResult result = PaymentResult.processSignaturePayment(req.Id, 99.99, 'USD');
        Test.stopTest();

     
    }

    // ---- 4. JSON Parsing Error → Exception Catch ----
    @IsTest
    static void testProcessSignaturePayment_JsonError() {
        Signature_Request__c req = new Signature_Request__c(
            Name = 'JsonErr', SignerEmail__c = 'jsonerr@example.com'
        );
        insert req;

        // Invalid JSON to force JSON parsing exception
        Test.setMock(HttpCalloutMock.class, new PaymentHttpMock(200, 'INVALID_JSON'));

        Test.startTest();
        PaymentResult result = PaymentResult.processSignaturePayment(req.Id, 120.00, 'USD');
        Test.stopTest();

       
    }

    // ---- 5. Forced DML Exception ----
    @IsTest
    static void testProcessSignaturePayment_ForcedDmlException() {
        Signature_Request__c req = new Signature_Request__c(
            Name = 'ForceDml', SignerEmail__c = 'dmlex@example.com'
        );
        insert req;

        Test.setMock(HttpCalloutMock.class, new PaymentHttpMock(200, '{"id":"pi_DML","status":"ok"}'));

        Test.startTest();
        // Passing -999 triggers DmlException inside method
        PaymentResult result = PaymentResult.processSignaturePayment(req.Id, -999, 'USD');
        Test.stopTest();

        
    }
}
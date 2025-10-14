
    public class SendEnvelopeJob implements Queueable, Database.AllowsCallouts {
        private String signerEmail, signerName, base64Pdf, envelopeSubject, docName;
        public SendEnvelopeJob(String signerEmail, String signerName, String base64Pdf, String envelopeSubject, String docName) {
            this.signerEmail = signerEmail; this.signerName = signerName; this.base64Pdf = base64Pdf; this.envelopeSubject = envelopeSubject; this.docName = docName;
        }
        public void execute(QueueableContext ctx) {
            try {
                Map<String,Object> doc = new Map<String,Object>{ 'documentBase64' => base64Pdf, 'name'=>docName, 'fileExtension'=>'pdf','documentId'=>'1' };
                Map<String,Object> signHere = new Map<String,Object>{ 'documentId'=>'1','pageNumber'=>'1','recipientId'=>'1','xPosition'=>'100','yPosition'=>'150' };
                Map<String,Object> signer = new Map<String,Object>{ 'email'=>signerEmail, 'name'=>signerName,'recipientId'=>'1','routingOrder'=>'1','tabs'=> new Map<String,Object>{ 'signHereTabs'=> new List<Object>{ signHere } } };
                Map<String,Object> recipients = new Map<String,Object>{ 'signers' => new List<Object>{ signer } };
                Map<String,Object> envelopeDef = new Map<String,Object>{ 'emailSubject'=>envelopeSubject, 'documents'=> new List<Object>{ doc }, 'recipients'=>recipients, 'status'=>'sent' };

                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:DocuSign_NC/restapi/v2.1/accounts/{ACCOUNT_ID}/envelopes'); // replace {ACCOUNT_ID} or template usage
                req.setMethod('POST');
                req.setHeader('Content-Type','application/json');
                req.setBody(JSON.serialize(envelopeDef));
                req.setTimeout(DOCUSIGN_TIMEOUT_MS);
                Http http = new Http();
                HttpResponse res = http.send(req);
                if (res.getStatusCode() == 201 || res.getStatusCode() == 200) {
                    Map<String,Object> body = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
                    String envelopeId = (String) body.get('envelopeId');
                    if (envelopeId != null) {
                        try {
                            DocuSign_Envelope__c env = new DocuSign_Envelope__c(Envelope_Id__c = envelopeId, Recipient_Email__c = signerEmail, Status__c = 'SENT', Created_Date__c = System.now());
                            insert env;
                        } catch (Exception e) {
                            AuditTrailManager.logError('DOCUSIGN_PERSIST', e);
                        }
                    }
                } else {
                    AuditTrailManager.logSystemActivity('DOCUSIGN_SEND_ERROR','HTTP ' + res.getStatusCode() + ' - ' + res.getBody());
                }
            } catch (Exception ex) {
                AuditTrailManager.logError('DOCUSIGN_JOB', ex);
            }
        }
    }
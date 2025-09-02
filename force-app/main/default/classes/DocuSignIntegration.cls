public class DocuSignIntegration {
    
    private static final String DOCUSIGN_ENDPOINT = 'https://demo.docusign.net/restapi/v2.1';
    
    public static String sendDocumentToDocuSign(String documentId, String signerEmail) {
        DocumentLifecycleConfiguration__c doc = [
            SELECT Id, DocumentTitle__c, GeneratedClause__c 
            FROM DocumentLifecycleConfiguration__c 
            WHERE Id = :documentId
        ];
        
        // Create DocuSign envelope
        Map<String, Object> envelopeData = new Map<String, Object>{
            'emailSubject' => 'Please sign: ' + doc.DocumentTitle__c,
            'status' => 'sent',
            'recipients' => new Map<String, Object>{
                'signers' => new List<Object>{
                    new Map<String, Object>{
                        'email' => signerEmail,
                        'name' => 'Signer',
                        'recipientId' => '1',
                        'routingOrder' => '1'
                    }
                }
            }
        };
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(DOCUSIGN_ENDPOINT + '/accounts/{accountId}/envelopes');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + getDocuSignAccessToken());
        req.setBody(JSON.serialize(envelopeData));
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 201) {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) response.get('envelopeId');
        } else {
            throw new DocuSignException('Failed to create DocuSign envelope: ' + res.getBody());
        }
    }
    
    private static String getDocuSignAccessToken() {
        // Implementation to get OAuth token from DocuSign
        // This would typically involve stored credentials and OAuth flow
        return 'mock_access_token';
    }
    
    public class DocuSignException extends Exception {}
}
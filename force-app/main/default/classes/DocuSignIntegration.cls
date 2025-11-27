public class DocuSignIntegration {

    /**
     * @description Sends a document to DocuSign for signature. This version is corrected for syntax and runtime logic.
     * @param documentId The ID of the DocumentLifecycleConfiguration__c record containing the document details.
     * @param signerEmail The email address of the person who needs to sign the document.
     * @return The DocuSign Envelope ID upon successful creation.
     */
    public static String sendDocumentToDocuSign(String documentId, String signerEmail) {
        // Corrected: Added LIMIT 1 for SOQL best practices.
        DocumentLifecycleConfiguration__c doc = [
            SELECT Id, DocumentTitle__c, GeneratedClause__c
            FROM DocumentLifecycleConfiguration__c
            WHERE Id = :documentId
            LIMIT 1
        ];

        // Runtime Fix: The DocuSign API requires the document content to be Base64 encoded.
        // We will use the GeneratedClause__c field as the document content.
        String documentBase64 = EncodingUtil.base64Encode(Blob.valueOf(doc.GeneratedClause__c));

        // Runtime Fix: A complete envelope definition requires a 'documents' array with the content
        // and 'tabs' to tell the signer where to sign.
        Map<String, Object> envelopeData = new Map<String, Object>{
            'emailSubject' => 'Please sign: ' + doc.DocumentTitle__c,
            'status' => 'sent',
            'documents' => new List<Object>{
                new Map<String, Object>{
                    'documentBase64' => documentBase64,
                    'name' => doc.DocumentTitle__c + '.txt', // File extension is important
                    'fileExtension' => 'txt',
                    'documentId' => '1'
                }
            },
            'recipients' => new Map<String, Object>{
                'signers' => new List<Object>{
                    new Map<String, Object>{
                        'email' => signerEmail,
                        'name' => 'Signer',
                        'recipientId' => '1',
                        'routingOrder' => '1',
                        // Define where the signer needs to sign on the document
                        'tabs' => new Map<String, Object>{
                            'signHereTabs' => new List<Object>{
                                new Map<String, Object>{
                                    'documentId' => '1',
                                    'pageNumber' => '1',
                                    'xPosition' => '100',
                                    'yPosition' => '150'
                                }
                            }
                        }
                    }
                }
            }
        };

        HttpRequest req = new HttpRequest();

        // Runtime Fix & Best Practice: The endpoint must be dynamically constructed with the Account ID.
        // Using a Named Credential named 'DocuSign_API' is the recommended approach for handling the base URL and authentication.
        String accountId = getAccountId();
        String endpoint = 'callout:DocuSign_API/restapi/v2.1/accounts/' + accountId + '/envelopes';
        req.setEndpoint(endpoint);
        
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        
        // The 'Authorization' header is handled automatically by the Named Credential, so it is removed from this code.
        req.setBody(JSON.serialize(envelopeData));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 201) {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) response.get('envelopeId');
        } else {
            // Provide more details in the exception for easier debugging.
            throw new DocuSignException('Failed to create DocuSign envelope. Status: ' + res.getStatus() + ' Body: ' + res.getBody());
        }
    }

    /**
     * @description Retrieves the DocuSign Account ID from a Custom Metadata Type.
     * @return The configured Account ID or a demo ID as a fallback.
     */
    @TestVisible
    private static String getAccountId() {
        // Corrected: Query for the custom metadata record.
        List<DocuSign_Config__mdt> configs = [SELECT AccountId__c FROM DocuSign_Config__mdt LIMIT 1];
        if (!configs.isEmpty() && String.isNotBlank(configs[0].AccountId__c)) {
            return configs[0].AccountId__c;
        }
        // Fallback for test contexts or if the custom metadata is not configured.
        return 'DEMO_ACCOUNT_ID';
    }

    /**
     * @description DEPRECATED: This method uses a mock token. Authentication is now handled
     * by the Named Credential 'DocuSign_API' for better security and maintainability.
     */
    private static String getDocuSignAccessToken() {
        // This is a placeholder and will not work with the real API.
        return 'mock_access_token';
    }

    /**
     * @description Custom exception for DocuSign integration errors.
     */
    public class DocuSignException extends Exception {}
}
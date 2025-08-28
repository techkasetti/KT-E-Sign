public class EmailNotificationService {
    
    public static void sendSignatureRequest(String signatureRequestId) {
        Signature_Request__c request = [
            SELECT Id, SignerEmail__c, SignerName__c, DocumentId__c,
                   DocumentId__r.DocumentTitle__c
            FROM Signature_Request__c 
            WHERE Id = :signatureRequestId
        ];
        
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{request.SignerEmail__c});
            email.setTemplateId(getSignatureRequestTemplateId());
            email.setWhatId(request.Id);
            email.setSaveAsActivity(true);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            
            // Log the email sent
            AuditTrailManager.logDocumentActivity(
                request.DocumentId__c,
                'Email Sent',
                'Signature request email sent to: ' + request.SignerEmail__c
            );
            
        } catch (Exception e) {
            System.debug('Email sending failed: ' + e.getMessage());
            throw new EmailException('Failed to send signature request email: ' + e.getMessage());
        }
    }
    
    private static Id getSignatureRequestTemplateId() {
        EmailTemplate template = [
            SELECT Id FROM EmailTemplate 
            WHERE DeveloperName = 'Signature_Request_Template' 
            LIMIT 1
        ];
        return template.Id;
    }
    
    public class EmailException extends Exception {}
}

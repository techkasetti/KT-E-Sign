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

    private static String buildSignatureRequestEmailBody(Signature_Request__c request) {
        String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
        String signatureUrl = baseUrl + '/lightning/cmp/c__signaturePad?c__recordId=' + request.Id;
        
        return '<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">' +
               '<h2 style="color: #1589ee;">Electronic Signature Required</h2>' +
               '<p>Dear ' + request.SignerName__c + ',</p>' +
               '<p>You have been requested to electronically sign the following document:</p>' +
               '<div style="background-color: #f8f9fa; padding: 15px; border-left: 4px solid #1589ee; margin: 20px 0;">' +
               '<strong>Document:</strong> ' + request.DocumentId__r.DocumentTitle__c + '<br/>' +
               '<strong>Type:</strong> ' + request.DocumentId__r.ContractType__c +
               '</div>' +
               '<p>Please click the button below to review and sign the document:</p>' +
               '<div style="text-align: center; margin: 30px 0;">' +
               '<a href="' + signatureUrl + '" style="background-color: #1589ee; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">Sign Document Now</a>' +
               '</div>' +
               '<p><strong>Important:</strong> This signature request will expire in 30 days.</p>' +
               '<p>If you have any questions, please contact your document administrator.</p>' +
               '<hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">' +
               '<p style="color: #666; font-size: 12px;">This is an automated message. Please do not reply to this email.</p>' +
               '</div>';
    }


        public static void sendSignatureRequestEmail(String requestId) {
        try {
            Signature_Request__c request = [
                SELECT SignerEmail__c, SignerName__c, DocumentId__r.DocumentTitle__c 
                FROM Signature_Request__c 
                WHERE Id = :requestId
            ];
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{request.SignerEmail__c});
            email.setSubject('Signature Request: ' + request.DocumentId__r.DocumentTitle__c);
            email.setPlainTextBody('Dear ' + request.SignerName__c + ',\n\n' +
                'You have been requested to sign the document: ' + request.DocumentId__r.DocumentTitle__c + '\n' +
                'Please log into the system to complete your signature.\n\n' +
                'Thank you.');
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            
        } catch (Exception e) {
            AuditTrailManager.logSystemActivity('EMAIL_ERROR', 'Failed to send signature request email: ' + e.getMessage());
        }
    }
    public static void sendSignatureCompletionEmail(String requestId) {
        try {
            Signature_Request__c request = [
                SELECT SignerEmail__c, SignerName__c, DocumentId__r.DocumentTitle__c 
                FROM Signature_Request__c 
                WHERE Id = :requestId
            ];
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{request.SignerEmail__c});
            email.setSubject('Signature Completed: ' + request.DocumentId__r.DocumentTitle__c);
            email.setPlainTextBody('Dear ' + request.SignerName__c + ',\n\n' +
                'Your signature has been successfully recorded for: ' + request.DocumentId__r.DocumentTitle__c + '\n' +
                'The document is now complete.\n\n' +
                'Thank you.');
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            
        } catch (Exception e) {
            AuditTrailManager.logSystemActivity('EMAIL_ERROR', 'Failed to send completion email: ' + e.getMessage());
        }
    }
public static void sendSignatureRequestNotification(String signatureRequestId) {
        try {
            // Get signature request details
            Signature_Request__c request = [
                SELECT Id, SignerEmail__c, SignerName__c, 
                       DocumentId__r.DocumentTitle__c, DocumentId__r.ContractType__c, DocumentId__r.Region__c
                FROM Signature_Request__c 
                WHERE Id = :signatureRequestId 
                LIMIT 1
            ];
            
            // Create email message
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{request.SignerEmail__c});
            email.setSubject('Electronic Signature Required - ' + request.DocumentId__r.DocumentTitle__c);
            
            // Build email body
            String emailBody = buildSignatureRequestEmailBody(request);
            email.setHtmlBody(emailBody);
            
            // Set email properties
            email.setWhatId(request.Id);
            email.setSaveAsActivity(true);
            email.setUseSignature(false);
            
            // Send email
            Messaging.SingleEmailMessage[] emails = new Messaging.SingleEmailMessage[]{email};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emails);
            
            if (results[0].isSuccess()) {
                // Log successful notification
                AuditTrailManager.logSignatureActivity(
                    signatureRequestId,
                    'EMAIL_NOTIFICATION_SENT',
                    'SUCCESS',
                    'Signature request notification sent to: ' + request.SignerEmail__c
                );
                System.debug('✓ Email notification sent successfully to: ' + request.SignerEmail__c);
            } else {
                // Log email failure
                AuditTrailManager.logSignatureActivity(
                    signatureRequestId,
                    'EMAIL_NOTIFICATION_FAILED',
                    'ERROR',
                    'Failed to send notification: ' + results[0].getErrors()[0].getMessage()
                );
            }
            
        } catch (Exception e) {
            System.debug('Email Notification Error: ' + e.getMessage());
            AuditTrailManager.logSignatureActivity(
                signatureRequestId,
                'EMAIL_NOTIFICATION_ERROR',
                'ERROR',
                'Exception in email notification: ' + e.getMessage()
            );
        }
    }

    public static void sendSignatureCompletion(String signatureRequestId) {
        try {
            Signature_Request__c request = [
                SELECT Id, SignerEmail__c, SignerName__c, DocumentId__c,
                       DocumentId__r.DocumentTitle__c, CompletedDate__c
                FROM Signature_Request__c 
                WHERE Id = :signatureRequestId
            ];
            
            // Create email message
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{request.SignerEmail__c});
            email.setSubject('Document Signed Successfully: ' + request.DocumentId__r.DocumentTitle__c);
            
            String emailBody = buildCompletionEmail(request);
            email.setHtmlBody(emailBody);
            
            // Send email
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            
            // Log activity
            AuditTrailManager.logDocumentActivity(
                request.DocumentId__c,
                'Completion Email Sent',
                'Signature completion email sent to: ' + request.SignerEmail__c
            );
            
            System.debug('✓ Completion email sent to: ' + request.SignerEmail__c);
            
        } catch (Exception e) {
            System.debug('❌ Failed to send completion email: ' + e.getMessage());
            AuditTrailManager.logError('Completion Email Failed', e.getMessage(), null);
        }
    }
    
    private static String buildSignatureRequestEmail(Signature_Request__c request) {
        String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
        String signatureUrl = baseUrl + '/lightning/cmp/c__signaturePad?c__recordId=' + request.Id;
        
        return '<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">' +
               '<h2 style="color: #1589ee;">Electronic Signature Required</h2>' +
               '<p>Dear ' + request.SignerName__c + ',</p>' +
               '<p>You have been requested to electronically sign the following document:</p>' +
               '<div style="background-color: #f8f9fa; padding: 15px; border-left: 4px solid #1589ee; margin: 20px 0;">' +
               '<h3>' + request.DocumentId__r.DocumentTitle__c + '</h3>' +
               '</div>' +
               '<p>Please click the button below to review and sign the document:</p>' +
               '<div style="text-align: center; margin: 30px 0;">' +
               '<a href="' + signatureUrl + '" style="background-color: #1589ee; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block;">Sign Document Now</a>' +
               '</div>' +
               '<p><strong>Important:</strong> This signature request will expire in 30 days.</p>' +
               '<p>If you have any questions, please contact your document administrator.</p>' +
               '<hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">' +
               '<p style="color: #666; font-size: 12px;">This is an automated message. Please do not reply to this email.</p>' +
               '</div>';
    }
    
    private static String buildCompletionEmail(Signature_Request__c request) {
        return '<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">' +
               '<h2 style="color: #28a745;">Document Successfully Signed</h2>' +
               '<p>Dear ' + request.SignerName__c + ',</p>' +
               '<p>Thank you for signing the following document:</p>' +
               '<div style="background-color: #f8f9fa; padding: 15px; border-left: 4px solid #28a745; margin: 20px 0;">' +
               '<h3>' + request.DocumentId__r.DocumentTitle__c + '</h3>' +
               '<p><strong>Signed on:</strong> ' + request.CompletedDate__c.format('MMMM dd, yyyy \'at\' h:mm a') + '</p>' +
               '</div>' +
               '<p>Your signature has been recorded and the document is now complete.</p>' +
               '<p>A copy of the signed document will be available in your organization\'s document system.</p>' +
               '<hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">' +
               '<p style="color: #666; font-size: 12px;">This is an automated message. Please do not reply to this email.</p>' +
               '</div>';
    }

    public static void sendSignatureCompletionNotification(String signatureRequestId) {
    try {
        // Get signature request details
        Signature_Request__c request = [
            SELECT Id, SignerEmail__c, SignerName__c, CompletedDate__c,
                   DocumentId__r.DocumentTitle__c, DocumentId__r.ContractType__c
            FROM Signature_Request__c 
            WHERE Id = :signatureRequestId 
            LIMIT 1
        ];
        
        // Create completion email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[]{request.SignerEmail__c});
        email.setSubject('Document Signed Successfully - ' + request.DocumentId__r.DocumentTitle__c);
        
        // Build completion email body
        String emailBody = buildSignatureCompletionEmailBody(request);
        email.setHtmlBody(emailBody);
        
        // Set email properties
        email.setWhatId(request.Id);
        email.setSaveAsActivity(true);
        email.setUseSignature(false);
        
        // Send completion email
        Messaging.SingleEmailMessage[] emails = new Messaging.SingleEmailMessage[]{email};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(emails);
        
        if (results[0].isSuccess()) {
            // Log successful completion notification
            AuditTrailManager.logSignatureActivity(
                signatureRequestId,
                'COMPLETION_EMAIL_SENT',
                'SUCCESS',
                'Signature completion notification sent to: ' + request.SignerEmail__c
            );
            System.debug('✓ Completion email sent successfully to: ' + request.SignerEmail__c);
        } else {
            // Log completion email failure
            AuditTrailManager.logSignatureActivity(
                signatureRequestId,
                'COMPLETION_EMAIL_FAILED',
                'ERROR',
                'Failed to send completion email: ' + results[0].getErrors()[0].getMessage()
            );
        }
    } catch (Exception e) {
        System.debug('Completion Email Error: ' + e.getMessage());
        AuditTrailManager.logSignatureActivity(
            signatureRequestId,
            'COMPLETION_EMAIL_ERROR',
            'ERROR',
            'Exception in completion email: ' + e.getMessage()
        );
    }
}
public static void sendReminderNotification(String signatureRequestId) {
    try {
        // Get signature request details
        Signature_Request__c request = [
            SELECT Id, SignerEmail__c, SignerName__c, CreatedDate,
                   DocumentId__r.DocumentTitle__c, Status__c
            FROM Signature_Request__c 
            WHERE Id = :signatureRequestId AND Status__c = 'Pending'
            LIMIT 1
        ];
        
        // Calculate days since request
        Integer daysSinceRequest = Date.today().daysBetween(request.CreatedDate.date());
        
        // Create reminder email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[]{request.SignerEmail__c});
        email.setSubject('Reminder: Signature Required - ' + request.DocumentId__r.DocumentTitle__c);
        
        // Build reminder email body
        String emailBody = buildReminderEmailBody(request, daysSinceRequest);
        email.setHtmlBody(emailBody);
        
        // Send reminder email
        Messaging.SingleEmailMessage[] emails = new Messaging.SingleEmailMessage[]{email};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(emails);
        
        if (results[0].isSuccess()) {
            AuditTrailManager.logSignatureActivity(
                signatureRequestId,
                'REMINDER_EMAIL_SENT',
                'SUCCESS',
                'Reminder notification sent after ' + daysSinceRequest + ' days'
            );
            System.debug('✓ Reminder email sent successfully to: ' + request.SignerEmail__c);
        } else {
            AuditTrailManager.logSignatureActivity(
                signatureRequestId,
                'REMINDER_EMAIL_FAILED',
                'ERROR',
                'Failed to send reminder email: ' + results[0].getErrors()[0].getMessage()
            );
        }
        
    } catch (Exception e) {
        System.debug('Reminder Email Error: ' + e.getMessage());
        AuditTrailManager.logSignatureActivity(
            signatureRequestId,
            'REMINDER_EMAIL_ERROR',
            'ERROR',
            'Exception in reminder email: ' + e.getMessage()
        );
    }
}

    public class EmailException extends Exception {}

    private static String buildSignatureCompletionEmailBody(Signature_Request__c request) {
    return '<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">' +
               '<div style="background-color: #28a745; color: white; padding: 20px; text-align: center;">' +
                   '<h1 style="margin: 0;">Document Signed Successfully</h1>' +
               '</div>' +
               '<div style="padding: 30px;">' +
                   '<p>Dear ' + request.SignerName__c + ',</p>' +
                   '<p>Thank you for signing the document: <strong>' + request.DocumentId__r.DocumentTitle__c + '</strong></p>' +
                   '<div style="background-color: #d4edda; padding: 20px; margin: 20px 0; border-left: 4px solid #28a745;">' +
                       '<h3 style="margin: 0 0 10px 0;">Signature Confirmation</h3>' +
                       '<p><strong>Document:</strong> ' + request.DocumentId__r.DocumentTitle__c + '</p>' +
                       '<p><strong>Signed Date:</strong> ' + String.valueOf(request.CompletedDate__c) + '</p>' +
                       '<p><strong>Status:</strong> Completed</p>' +
                   '</div>' +
                   '<p>Your electronic signature has been recorded and is legally binding. A copy of the signed document has been saved to your records.</p>' +
                   '<p>If you need any assistance or have questions about this document, please contact the document sender.</p>' +
                   '<p style="font-size: 12px; color: #666; margin-top: 30px;">Thank you for using our electronic signature system.</p>' +
               '</div>' +
           '</div>';
}
private static String buildReminderEmailBody(Signature_Request__c request, Integer daysSinceRequest) {
    String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
    String signatureUrl = baseUrl + '/lightning/r/Signature_Request__c/' + request.Id + '/view';

    return '<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">' +
        '<div style="background-color: #ffc107; color: #212529; padding: 20px; text-align: center;">' +
            '<h1 style="margin: 0;">Signature Request Reminder</h1>' +
        '</div>' +
        '<div style="padding: 30px;">' +
            '<p>Dear ' + request.SignerName__c + ',</p>' +
            '<p>This is a friendly reminder that you have a pending signature request for:</p>' +
            '<div style="background-color: #fff3cd; padding: 20px; margin: 20px 0; border-left: 4px solid #ffc107;">' +
                '<h3 style="margin: 0 0 10px 0;">Document: ' + request.DocumentId__r.DocumentTitle__c + '</h3>' +
                '<p><strong>Request sent:</strong> ' + daysSinceRequest + ' days ago</p>' +
                '<p><strong>Status:</strong> Awaiting your signature</p>' +
            '</div>' +
            '<div style="text-align: center; margin: 30px 0;">' +
                '<a href="' + signatureUrl + '" ' +
                   'style="background-color: #ffc107; color: #212529; padding: 15px 30px; ' +
                          'text-decoration: none; border-radius: 5px; font-weight: bold;">' +
                   'Complete Signature Now</a>' +
            '</div>' +
            '<p>Please sign the document at your earliest convenience to avoid any delays.</p>' +
            '<p style="font-size: 12px; color: #666;">' +
                'If you have already signed this document, please disregard this reminder.' +
            '</p>' +
        '</div>' +
    '</div>';
}
public static void scheduleReminderEmails() {
    try {
        // Get pending requests older than 3 days and within last 30 days
        List<Signature_Request__c> pendingRequests = [
            SELECT Id 
            FROM Signature_Request__c 
            WHERE Status__c = 'Pending' 
            AND CreatedDate < :System.now().addDays(-3)
            AND CreatedDate > :System.now().addDays(-30)
        ];
        
        // Send reminder emails for each pending request
        for (Signature_Request__c request : pendingRequests) {
            sendReminderNotification(request.Id);
        }
        
        System.debug('✓ Reminder emails scheduled for ' + pendingRequests.size() + ' requests');
        
    } catch (Exception e) {
        System.debug('Schedule Reminder Error: ' + e.getMessage());
    }
}

}
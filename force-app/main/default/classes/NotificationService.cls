public class NotificationService {
    
//     // Email template constants
//     private static final String SIGNATURE_REQUEST_TEMPLATE = 'SignatureRequestTemplate';
//     private static final String SIGNATURE_REMINDER_TEMPLATE = 'SignatureReminderTemplate';
//     private static final String SIGNATURE_COMPLETED_TEMPLATE = 'SignatureCompletedTemplate';
//     private static final String SIGNATURE_REJECTED_TEMPLATE = 'SignatureRejectedTemplate';
//     private static final String SECURITY_ALERT_TEMPLATE = 'SecurityAlertTemplate';
    
//     /**
//      * Send signature request notification
//      */
//     @AuraEnabled
//     public static Boolean sendSignatureRequestNotification(String requestId) {
//         try {
//             Signature_Request__c request = getSignatureRequestData(requestId);
            
//             // Create email message
//             Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
//             email.setTargetObjectId(request.ContactId__c);
//             email.setTemplateId(getEmailTemplateId(SIGNATURE_REQUEST_TEMPLATE));
//             email.setWhatId(request.Id);
//             email.setSaveAsActivity(true);
//             email.setUseSignature(false);
            
//             // Add custom merge fields
//             Map<String, String> mergeFields = new Map<String, String>();
//             mergeFields.put('{!SignerName}', request.SignerName__c);
//             mergeFields.put('{!DocumentTitle}', request.DocumentId__r.DocumentTitle__c);
//             mergeFields.put('{!ExpirationDate}', request.ExpirationDate__c.format());
//             mergeFields.put('{!SigningURL}', generateSigningURL(requestId));
            
//             // Apply merge fields if template supports them
//             email.setHtmlBody(applyMergeFields(getTemplateBody(SIGNATURE_REQUEST_TEMPLATE), mergeFields));
            
//             // Send email
//             Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            
//             Boolean success = results[0].isSuccess();
            
//             // Log notification activity
//             AuditTrailManager.logEmailActivity(
//                 request.SignerEmail__c,
//                 'SIGNATURE_REQUEST',
//                 success,
//                 success ? 'Signature request email sent successfully' : 
//                          'Email send failed: ' + results[0].getErrors()[0].getMessage()
//             );
            
//             // Update request status
//             if (success) {
//                 request.LastNotificationSent__c = System.now();
//                 request.NotificationCount__c = (request.NotificationCount__c != null ? 
//                                               request.NotificationCount__c + 1 : 1);
//                 update request;
//             }
            
//             return success;
            
//         } catch (Exception e) {
//             AuditTrailManager.logEmailActivity(
//                 null,
//                 'SIGNATURE_REQUEST',
//                 false,
//                 'Exception sending signature request: ' + e.getMessage()
//             );
//             throw new AuraHandledException('Failed to send signature request: ' + e.getMessage());
//         }
//     }
    
//     /**
//      * Send signature completion notification
//      */
//     @AuraEnabled
//     public static Boolean sendSignatureCompletionNotification(String requestId) {
//         try {
//             Signature_Request__c request = getSignatureRequestData(requestId);
            
//             // Send notification to document owner
//             Messaging.SingleEmailMessage ownerEmail = new Messaging.SingleEmailMessage();
//             ownerEmail.setTargetObjectId(request.DocumentId__r.OwnerId);
//             ownerEmail.setTemplateId(getEmailTemplateId(SIGNATURE_COMPLETED_TEMPLATE));
//             ownerEmail.setWhatId(request.Id);
//             ownerEmail.setSaveAsActivity(true);
            
//             // Custom merge fields for completion
//             Map<String, String> mergeFields = new Map<String, String>();
//             mergeFields.put('{!SignerName}', request.SignerName__c);
//             mergeFields.put('{!DocumentTitle}', request.DocumentId__r.DocumentTitle__c);
//             mergeFields.put('{!CompletedDate}', request.CompletedDate__c?.format());
//             mergeFields.put('{!DocumentURL}', generateDocumentURL(request.DocumentId__c));
            
//             ownerEmail.setHtmlBody(applyMergeFields(
//                 getTemplateBody(SIGNATURE_COMPLETED_TEMPLATE), 
//                 mergeFields
//             ));
            
//             // Also send confirmation to signer
//             Messaging.SingleEmailMessage signerEmail = new Messaging.SingleEmailMessage();
//             signerEmail.setToAddresses(new String[]{request.SignerEmail__c});
//             signerEmail.setSubject('Document Signed Successfully - ' + request.DocumentId__r.DocumentTitle__c);
//             signerEmail.setHtmlBody(generateSignerConfirmationEmail(request));
            
//             // Send both emails
//             Messaging.SendEmailResult[] results = Messaging.sendEmail(
//                 new Messaging.SingleEmailMessage[]{ownerEmail, signerEmail}
//             );
            
//             Boolean success = results[0].isSuccess() && results[1].isSuccess();
            
//             // Log notification activity
//             AuditTrailManager.logEmailActivity(
//                 request.SignerEmail__c,
//                 'SIGNATURE_COMPLETED',
//                 success,
//                 success ? 'Signature completion notifications sent successfully' : 
//                          'Email send failed'
//             );
            
//             return success;
            
//         } catch (Exception e) {
//             AuditTrailManager.logEmailActivity(
//                 null,
//                 'SIGNATURE_COMPLETED',
//                 false,
//                 'Exception sending completion notification: ' + e.getMessage()
//             );
//             return false;
//         }
//     }
    
//     /**
//      * Send signature reminder notification
//      */
// /** * Send signature reminder notification */
// @AuraEnabled
// public static Boolean sendSignatureReminderNotification(String requestId) {
//     try {
//         Signature_Request__c request = getSignatureRequestData(requestId);
        
//         // Check if reminder is needed and allowed
//         if (!shouldSendReminder(request)) {
//             return false;
//         }
        
//         // Create reminder email
//         Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
//         email.setToAddresses(new String[]{request.SignerEmail__c});
//         email.setSubject('Reminder: Signature Required - ' + request.DocumentId__r.DocumentTitle__c);
        
//         // Calculate days remaining
//         Integer daysRemaining = request.ExpirationDate__c.daysBetween(Date.today());
//         String urgencyLevel = daysRemaining <= 1 ? 'URGENT' : daysRemaining <= 3 ? 'HIGH' : 'NORMAL';
        
//         // Custom merge fields for reminder
//         Map<String, String> mergeFields = new Map<String, String>();
//         mergeFields.put('{!SignerName}', request.SignerName__c);
//         mergeFields.put('{!DocumentTitle}', request.DocumentId__r.DocumentTitle__c);
//         mergeFields.put('{!DaysRemaining}', String.valueOf(daysRemaining));
//         mergeFields.put('{!UrgencyLevel}', urgencyLevel);
//         mergeFields.put('{!SigningURL}', generateSigningURL(requestId));
//         mergeFields.put('{!ExpirationDate}', request.ExpirationDate__c.format());
        
//         email.setHtmlBody(applyMergeFields(
//             getTemplateBody(SIGNATURE_REMINDER_TEMPLATE), 
//             mergeFields
//         ));
        
//         // Send email
//         Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
//         Boolean success = results[0].isSuccess();
        
//         // Log reminder activity
//         AuditTrailManager.logEmailActivity(
//             request.SignerEmail__c,
//             'SIGNATURE_REMINDER',
//             success,
//             success ? 'Reminder sent successfully. Days remaining: ' + daysRemaining : 
//                      'Reminder send failed: ' + results[0].getErrors()[0].getMessage()
//         );
        
//         // Update reminder tracking
//         if (success) {
//             request.LastReminderSent__c = System.now();
//             request.ReminderCount__c = (request.ReminderCount__c != null ? request.ReminderCount__c + 1 : 1);
//             update request;
//         }
        
//         return success;
        
//     } catch (Exception e) {
//         AuditTrailManager.logEmailActivity(
//             null,
//             'SIGNATURE_REMINDER',
//             false,
//             'Exception sending reminder: ' + e.getMessage()
//         );
//         return false;
//     }
// }

// /**
//  * Send signature rejection notification
//  */
// @AuraEnabled
// public static Boolean sendSignatureRejectionNotification(String requestId, String rejectionReason) {
//     try {
//         Signature_Request__c request = getSignatureRequestData(requestId);
        
//         // Send notification to document owner
//         Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
//         email.setTargetObjectId(request.DocumentId__r.OwnerId);
//         email.setTemplateId(getEmailTemplateId(SIGNATURE_REJECTED_TEMPLATE));
//         email.setWhatId(request.Id);
//         email.setSaveAsActivity(true);
        
//         // Custom merge fields for rejection
//         Map<String, String> mergeFields = new Map<String, String>();
//         mergeFields.put('{!SignerName}', request.SignerName__c);
//         mergeFields.put('{!DocumentTitle}', request.DocumentId__r.DocumentTitle__c);
//         mergeFields.put('{!RejectionReason}', rejectionReason);
//         mergeFields.put('{!RejectionDate}', System.now().format());
//         mergeFields.put('{!DocumentURL}', generateDocumentURL(request.DocumentId__c));
        
//         email.setHtmlBody(applyMergeFields(
//             getTemplateBody(SIGNATURE_REJECTED_TEMPLATE),
//             mergeFields
//         ));
        
//         // Send email
//         Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
//         Boolean success = results[0].isSuccess();
        
//         // Log rejection notification
//         AuditTrailManager.logEmailActivity(
//             request.SignerEmail__c,
//             'SIGNATURE_REJECTED',
//             success,
//             success ? 'Rejection notification sent. Reason: ' + rejectionReason :
//                      'Rejection notification failed'
//         );
        
//         return success;
        
//     } catch (Exception e) {
//         AuditTrailManager.logEmailActivity(
//             null,
//             'SIGNATURE_REJECTED',
//             false,
//             'Exception sending rejection notification: ' + e.getMessage()
//         );
//         return false;
//     }
// }

// /**
//  * Send security alert notification
//  */
// @AuraEnabled
// public static Boolean sendSecurityAlert(String alertType, String description) {
//     try {
//         // Get security administrators
//         List<User> securityAdmins = [
//             SELECT Id, Email
//             FROM User 
//             WHERE IsActive = true 
//             AND Profile.Name IN ('System Administrator', 'Security Administrator')
//         ];
        
//         if (securityAdmins.isEmpty()) {
//             return false;
//         }
        
//         List<Messaging.SingleEmailMessage> alertEmails = new List<Messaging.SingleEmailMessage>();
        
//         for (User admin : securityAdmins) {
//             Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
//             email.setToAddresses(new String[]{admin.Email});
//             email.setSubject('SECURITY ALERT: ' + alertType + ' - E-Signature System');
            
//             // Custom merge fields for security alert
//             Map<String, String> mergeFields = new Map<String, String>();
//             mergeFields.put('{!AlertType}', alertType);
//             mergeFields.put('{!Description}', description);
//             mergeFields.put('{!Timestamp}', System.now().format());
//             mergeFields.put('{!OrganizationName}', UserInfo.getOrganizationName());
//             mergeFields.put('{!SystemURL}',System.URL.getOrgDomainUrl().toExternalForm());
            
//             email.setHtmlBody(generateSecurityAlertEmail(mergeFields));
//             alertEmails.add(email);
//         }
        
//         // Send all alert emails
//         Messaging.SendEmailResult[] results = Messaging.sendEmail(alertEmails);
//         Boolean allSuccess = true;
        
//         for (Messaging.SendEmailResult result : results) {
//             if (!result.isSuccess()) {
//                 allSuccess = false;
//                 break;
//             }
//         }
        
//         // Log security alert
//         AuditTrailManager.logSecurityEvent(
//             alertType,
//             'CRITICAL',
//             'Security alert sent to ' + securityAdmins.size() + ' administrators: ' + description,
//             'NOTIFICATION_SYSTEM'
//         );
        
//         return allSuccess;
        
//     } catch (Exception e) {
//         AuditTrailManager.logSecurityEvent(
//             'NOTIFICATION_FAILURE',
//             'HIGH',
//             'Failed to send security alert: ' + e.getMessage(),
//             'NOTIFICATION_SYSTEM'
//         );
//         return false;
//     }
// }

// /**
//  * Send bulk notifications for multiple requests
//  */
// @AuraEnabled
// public static Map<String, Boolean> sendBulkNotifications(
//     List<String> requestIds, 
//     String notificationType
// ) {
//     Map<String, Boolean> results = new Map<String, Boolean>();
    
//     for (String requestId : requestIds) {
//         Boolean result = false;
        
//         try {
//             switch on notificationType {
//                 when 'SIGNATURE_REQUEST' {
//                     result = sendSignatureRequestNotification(requestId);
//                 }
//                 when 'SIGNATURE_REMINDER' {
//                     result = sendSignatureReminderNotification(requestId);
//                 }
//                 when 'SIGNATURE_COMPLETED' {
//                     result = sendSignatureCompletionNotification(requestId);
//                 }
//                 when else {
//                     result = false;
//                 }
//             }
//         } catch (Exception e) {
//             result = false;
//         }
        
//         results.put(requestId, result);
//     }
    
//     // Log bulk notification activity
//     Integer successCount = 0;
//     for (Boolean success : results.values()) {
//         if (success) successCount++;
//     }
    
//     AuditTrailManager.createAuditEntry(
//         null,
//         'BULK_NOTIFICATION',
//         successCount == requestIds.size() ? 'SUCCESS' : 'PARTIAL',
//         'Bulk ' + notificationType + ' sent. Success: ' + successCount + '/' + requestIds.size()
//     );
    
//     return results;
// }

// /**
//  * Schedule automatic reminders
//  */
// @AuraEnabled
// public static void scheduleAutomaticReminders() {
//     try {
//         // Find requests that need reminders
//         List<Signature_Request__c> pendingRequests = [
//             SELECT Id, SignerEmail__c, SignerName__c, ExpirationDate__c,
//                    LastReminderSent__c, ReminderCount__c,
//                    DocumentId__r.DocumentTitle__c
//             FROM Signature_Request__c
//             WHERE Status__c = 'Pending'
//             AND ExpirationDate__c > TODAY
//             AND ExpirationDate__c <= :Date.today().addDays(3)
//             AND (LastReminderSent__c = null OR LastReminderSent__c < :System.now().addDays(-1))
//             AND (ReminderCount__c = null OR ReminderCount__c < 3)
//         ];
        
//         List<String> requestIds = new List<String>();
//         for (Signature_Request__c request : pendingRequests) {
//             requestIds.add(request.Id);
//         }
        
//         if (!requestIds.isEmpty()) {
//             sendBulkNotifications(requestIds, 'SIGNATURE_REMINDER');
//         }
        
//         // Log scheduled reminder execution
//         AuditTrailManager.createAuditEntry(
//             null,
//             'SCHEDULED_REMINDERS',
//             'SUCCESS',
//             'Automatic reminders processed for ' + requestIds.size() + ' pending requests'
//         );
        
//     } catch (Exception e) {
//         AuditTrailManager.createAuditEntry(
//             null,
//             'SCHEDULED_REMINDERS',
//             'ERROR',
//             'Failed to process automatic reminders: ' + e.getMessage()
//         );
//     }
// }

// // Helper methods

// /**
//  * Get signature request data with related information
//  */
// private static Signature_Request__c getSignatureRequestData(String requestId) {
//     return [
//         SELECT Id, SignerEmail__c, SignerName__c, Status__c,
//                ExpirationDate__c, CompletedDate__c, RejectionReason__c,
//                LastNotificationSent__c, NotificationCount__c,
//                LastReminderSent__c, ReminderCount__c,
//                ContactId__c,
//                DocumentId__c, DocumentId__r.DocumentTitle__c, 
//                DocumentId__r.OwnerId, DocumentId__r.ContractType__c
//         FROM Signature_Request__c
//         WHERE Id = :requestId
//         LIMIT 1
//     ];
// }

// /**
//  * Check if reminder should be sent
//  */
// private static Boolean shouldSendReminder(Signature_Request__c request) {
//     // Don't send if already signed or expired
//     if (request.Status__c != 'Pending' || request.ExpirationDate__c <= Date.today()) {
//         return false;
//     }
    
//     // Don't send more than 3 reminders
//     if (request.ReminderCount__c != null && request.ReminderCount__c >= 3) {
//         return false;
//     }
    
//     // Don't send reminder within 24 hours of last reminder
//     if (request.LastReminderSent__c != null && 
//         request.LastReminderSent__c > System.now().addHours(-24)) {
//         return false;
//     }
    
//     return true;
// }

// /**
//  * Get email template ID by name
//  */
// private static Id getEmailTemplateId(String templateName) {
//     try {
//         EmailTemplate template = [
//             SELECT Id
//             FROM EmailTemplate
//             WHERE DeveloperName = :templateName
//             AND IsActive = true
//             LIMIT 1
//         ];
//         return template.Id;
//     } catch (Exception e) {
//         // Return null if template not found - will use custom HTML body
//         return null;
//     }
// }

// /**
//  * Get email template body
//  */
// private static String getTemplateBody(String templateName) {
//     try {
//         EmailTemplate template = [
//             SELECT HtmlValue
//             FROM EmailTemplate
//             WHERE DeveloperName = :templateName
//             AND IsActive = true
//             LIMIT 1
//         ];
//         return template.HtmlValue;
//     } catch (Exception e) {
//         // Return default template if not found
//         return generateDefaultEmailTemplate(templateName);
//     }
// }

// /**
//  * Apply merge fields to email template
//  */
// private static String applyMergeFields(String template, Map<String, String> mergeFields) {
//     String result = template;
    
//     for (String key : mergeFields.keySet()) {
//         result = result.replace(key, mergeFields.get(key) != null ? mergeFields.get(key) : '');
//     }
    
//     return result;
// }

// /**
//  * Generate signing URL for the request
//  */
// private static String generateSigningURL(String requestId) {
//     String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
//     return baseUrl + '/lightning/r/Signature_Request__c/' + requestId + '/view?mode=sign';
// }

// /**
//  * Generate document viewing URL
//  */
// private static String generateDocumentURL(String documentId) {
//     String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
//     return baseUrl + '/lightning/r/DocumentLifecycleConfiguration__c/' + documentId + '/view';
// }

// /**
//  * Generate signer confirmation email HTML
//  */
// private static String generateSignerConfirmationEmail(Signature_Request__c request) {
//     return '<html><body>' +
//            '<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">' +
//            '<h2 style="color: #28a745;">Document Successfully Signed</h2>' +
//            '<p>Dear ' + request.SignerName__c + ',</p>' +
//            '<p>Thank you for signing the document: <strong>' + request.DocumentId__r.DocumentTitle__c + '</strong></p>' +
//            '<div style="background-color: #f8f9fa; padding: 15px; margin: 20px 0; border-left: 4px solid #28a745;">' +
//            '<p><strong>Completion Details:</strong></p>' +
//            '<p>• Document: ' + request.DocumentId__r.DocumentTitle__c + '</p>' +
//            '<p>• Signed Date: ' + (request.CompletedDate__c != null ? request.CompletedDate__c.format() : 'Just now') + '</p>' +
//            '<p>• Status: Completed</p>' +
//            '</div>' +
//            '<p>Your electronic signature has been recorded and is legally binding. ' +
//            'A copy of the signed document has been saved to your records.</p>' +
//            '<p>If you need any assistance or have questions about this document, ' +
//            'please contact the document sender.</p>' +
//            '<p>Best regards,<br/>' +
//            'E-Signature System</p>' +
//            '</div>' +
//            '</body></html>';
// }

// /**
//  * Generate security alert email
// /** * Generate security alert email HTML */
// private static String generateSecurityAlertEmail(Map<String, String> mergeFields) {
//     return '<html><body style="font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f4f4f4;">' +
//            '<div style="max-width: 600px; margin: 0 auto; background-color: white; padding: 0;">' +
           
//            // Header with critical alert styling
//            '<div style="background: linear-gradient(135deg, #dc3545, #c82333); color: white; padding: 20px; text-align: center;">' +
//            '<h1 style="margin: 0; font-size: 24px;">🚨 CRITICAL SECURITY ALERT</h1>' +
//            '<p style="margin: 10px 0 0 0; font-size: 16px;">E-Signature Security System</p>' +
//            '</div>' +
           
//            // Alert details section
//            '<div style="padding: 30px;">' +
//            '<div style="background-color: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; padding: 15px; border-radius: 5px; margin-bottom: 20px;">' +
//            '<h3 style="margin: 0 0 10px 0; color: #721c24;">Alert Details</h3>' +
//            '<table style="width: 100%; border-collapse: collapse;">' +
//            '<tr><td style="padding: 8px 0; font-weight: bold; width: 30%;">Alert Type:</td><td style="color: #dc3545; font-weight: bold;">' + mergeFields.get('{!AlertType}') + '</td></tr>' +
//            '<tr><td style="padding: 8px 0; font-weight: bold;">Timestamp:</td><td>' + mergeFields.get('{!Timestamp}') + '</td></tr>' +
//            '<tr><td style="padding: 8px 0; font-weight: bold;">Organization:</td><td>' + mergeFields.get('{!OrganizationName}') + '</td></tr>' +
//            '</table>' +
//            '</div>' +
           
//            // Description section
//            '<div style="background-color: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin-bottom: 20px;">' +
//            '<h3 style="margin: 0 0 10px 0; color: #856404;">Incident Description</h3>' +
//            '<p style="margin: 0; line-height: 1.6;">' + mergeFields.get('{!Description}') + '</p>' +
//            '</div>' +
           
//            // Immediate actions section
//            '<div style="background-color: #d1ecf1; border: 1px solid #bee5eb; padding: 15px; border-radius: 5px; margin-bottom: 20px;">' +
//            '<h3 style="margin: 0 0 15px 0; color: #0c5460;">Immediate Actions Required</h3>' +
//            '<ul style="margin: 0; padding-left: 20px; line-height: 1.8;">' +
//            '<li>Review the security incident immediately</li>' +
//            '<li>Check system logs for additional context</li>' +
//            '<li>Verify user access patterns and permissions</li>' +
//            '<li>Consider implementing temporary security restrictions</li>' +
//            '<li>Document all findings and actions taken</li>' +
//            '</ul>' +
//            '</div>' +
           
//            // System access button
//            '<div style="text-align: center; margin: 30px 0;">' +
//            '<a href="' + mergeFields.get('{!SystemURL}') + '" style="background-color: #007bff; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; font-weight: bold; display: inline-block;">Access Security Console</a>' +
//            '</div>' +
           
//            // Footer
//            '<div style="border-top: 1px solid #dee2e6; padding-top: 20px; font-size: 12px; color: #6c757d;">' +
//            '<p><strong>This is an automated security alert.</strong></p>' +
//            '<p>Please acknowledge this alert in the system after taking appropriate action.</p>' +
//            '<p>For urgent security matters, contact your IT security team immediately.</p>' +
//            '<p style="margin-bottom: 0;"><em>E-Signature Security Monitoring System</em></p>' +
//            '</div>' +
           
//            '</div>' +
//            '</div>' +
//            '</body></html>';
// }

// /**
//  * Generate default email template when specific template not found
//  */
// private static String generateDefaultEmailTemplate(String templateType) {
//     String baseTemplate = '<html><body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">';
    
//     switch on templateType {
//         when 'SignatureRequestTemplate' {
//             baseTemplate += '<h2 style="color: #007bff;">Electronic Signature Required</h2>' +
//                            '<p>Dear {!SignerName},</p>' +
//                            '<p>You have been requested to electronically sign the document: <strong>{!DocumentTitle}</strong></p>' +
//                            '<div style="background-color: #f8f9fa; padding: 15px; margin: 20px 0; border-left: 4px solid #007bff;">' +
//                            '<p><strong>Document Details:</strong></p>' +
//                            '<p>• Title: {!DocumentTitle}</p>' +
//                            '<p>• Expiration Date: {!ExpirationDate}</p>' +
//                            '</div>' +
//                            '<div style="text-align: center; margin: 30px 0;">' +
//                            '<a href="{!SigningURL}" style="background-color: #007bff; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; font-weight: bold;">Sign Document</a>' +
//                            '</div>';
//         }
//         when 'SignatureReminderTemplate' {
//             baseTemplate += '<h2 style="color: #ffc107;">Signature Reminder</h2>' +
//                            '<p>Dear {!SignerName},</p>' +
//                            '<p>This is a reminder that you have a pending signature request for: <strong>{!DocumentTitle}</strong></p>' +
//                            '<div style="background-color: #fff3cd; padding: 15px; margin: 20px 0; border-left: 4px solid #ffc107;">' +
//                            '<p><strong>⏰ Urgency Level: {!UrgencyLevel}</strong></p>' +
//                            '<p>• Days Remaining: {!DaysRemaining}</p>' +
//                            '<p>• Expiration Date: {!ExpirationDate}</p>' +
//                            '</div>' +
//                            '<div style="text-align: center; margin: 30px 0;">' +
//                            '<a href="{!SigningURL}" style="background-color: #ffc107; color: #212529; padding: 12px 30px; text-decoration: none; border-radius: 5px; font-weight: bold;">Sign Now</a>' +
//                            '</div>';
//         }
//         when 'SignatureCompletedTemplate' {
//             baseTemplate += '<h2 style="color: #28a745;">Document Signed Successfully</h2>' +
//                            '<p>Good news! The document <strong>{!DocumentTitle}</strong> has been successfully signed.</p>' +
//                            '<div style="background-color: #d4edda; padding: 15px; margin: 20px 0; border-left: 4px solid #28a745;">' +
//                            '<p><strong>Completion Details:</strong></p>' +
//                            '<p>• Signer: {!SignerName}</p>' +
//                            '<p>• Completed: {!CompletedDate}</p>' +
//                            '</div>' +
//                            '<div style="text-align: center; margin: 30px 0;">' +
//                            '<a href="{!DocumentURL}" style="background-color: #28a745; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; font-weight: bold;">View Document</a>' +
//                            '</div>';
//         }
//         when 'SignatureRejectedTemplate' {
//             baseTemplate += '<h2 style="color: #dc3545;">Document Signature Rejected</h2>' +
//                            '<p>The signature request for <strong>{!DocumentTitle}</strong> has been rejected.</p>' +
//                            '<div style="background-color: #f8d7da; padding: 15px; margin: 20px 0; border-left: 4px solid #dc3545;">' +
//                            '<p><strong>Rejection Details:</strong></p>' +
//                            '<p>• Signer: {!SignerName}</p>' +
//                            '<p>• Rejected: {!RejectionDate}</p>' +
//                            '<p>• Reason: {!RejectionReason}</p>' +
//                            '</div>' +
//                            '<div style="text-align: center; margin: 30px 0;">' +
//                            '<a href="{!DocumentURL}" style="background-color: #dc3545; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; font-weight: bold;">Review Document</a>' +
//                            '</div>';
//         }
//         when else {
//             baseTemplate += '<h2>E-Signature System Notification</h2>' +
//                            '<p>You have received a notification from the E-Signature System.</p>' +
//                            '<p>Please log into the system to view the details.</p>';
//         }
//     }
    
//     // Add common footer
//     baseTemplate += '<hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">' +
//                    '<p style="color: #666; font-size: 12px;">This is an automated message. Please do not reply to this email.</p>' +
//                    '<p style="color: #666; font-size: 12px;">If you have questions, contact your document administrator.</p>' +
//                    '</body></html>';
    
//     return baseTemplate;
// }

// /**
//  * Get notification preferences for user
//  */
// @AuraEnabled
// public static Map<String, Object> getNotificationPreferences(String userId) {
//     try {
//         // Check for custom notification preferences object
//         List<NotificationPreference__c> preferences = [
//             SELECT Id, UserId__c, EmailSignatureRequest__c, EmailReminder__c, 
//                    EmailCompletion__c, EmailRejection__c, SMSNotifications__c,
//                    ReminderFrequency__c, MaxReminders__c
//             FROM NotificationPreference__c 
//             WHERE UserId__c = :userId 
//             LIMIT 1
//         ];
        
//         Map<String, Object> prefs = new Map<String, Object>();
        
//         if (!preferences.isEmpty()) {
//             NotificationPreference__c pref = preferences[0];
//             prefs.put('emailSignatureRequest', pref.EmailSignatureRequest__c);
//             prefs.put('emailReminder', pref.EmailReminder__c);
//             prefs.put('emailCompletion', pref.EmailCompletion__c);
//             prefs.put('emailRejection', pref.EmailRejection__c);
//             prefs.put('smsNotifications', pref.SMSNotifications__c);
//             prefs.put('reminderFrequency', pref.ReminderFrequency__c);
//             prefs.put('maxReminders', pref.MaxReminders__c);
//         } else {
//             // Default preferences
//             prefs.put('emailSignatureRequest', true);
//             prefs.put('emailReminder', true);
//             prefs.put('emailCompletion', true);
//             prefs.put('emailRejection', true);
//             prefs.put('smsNotifications', false);
//             prefs.put('reminderFrequency', 24); // hours
//             prefs.put('maxReminders', 3);
//         }
        
//         return prefs;
        
//     } catch (Exception e) {
//         throw new AuraHandledException('Unable to retrieve notification preferences: ' + e.getMessage());
//     }
// }

// /**
//  * Update notification preferences for user
//  */
// @AuraEnabled
// public static Boolean updateNotificationPreferences(String userId, Map<String, Object> preferences) {
//     try {
//         // Check if preferences already exist
//         List<NotificationPreference__c> existingPrefs = [
//             SELECT Id FROM NotificationPreference__c WHERE UserId__c = :userId LIMIT 1
//         ];
        
//         NotificationPreference__c pref;
//         if (!existingPrefs.isEmpty()) {
//             pref = existingPrefs[0];
//         } else {
//             pref = new NotificationPreference__c();
//             pref.UserId__c = userId;
//         }
        
//         // Update preferences
//         pref.EmailSignatureRequest__c = (Boolean)preferences.get('emailSignatureRequest');
//         pref.EmailReminder__c = (Boolean)preferences.get('emailReminder');
//         pref.EmailCompletion__c = (Boolean)preferences.get('emailCompletion');
//         pref.EmailRejection__c = (Boolean)preferences.get('emailRejection');
//         pref.SMSNotifications__c = (Boolean)preferences.get('smsNotifications');
//         pref.ReminderFrequency__c = (Decimal)preferences.get('reminderFrequency');
//         pref.MaxReminders__c = (Decimal)preferences.get('maxReminders');
        
//         upsert pref;
        
//         // Log preference update
//         AuditTrailManager.createAuditEntry(
//             userId,
//             'NOTIFICATION_PREFERENCES_UPDATED',
//             'SUCCESS',
//             'User notification preferences updated successfully'
//         );
        
//         return true;
        
//     } catch (Exception e) {
//         AuditTrailManager.createAuditEntry(
//             userId,
//             'NOTIFICATION_PREFERENCES_ERROR',
//             'ERROR',
//             'Failed to update notification preferences: ' + e.getMessage()
//         );
//         throw new AuraHandledException('Unable to update notification preferences: ' + e.getMessage());
//     }
// }

// /**
//  * Get notification statistics for admin dashboard
//  */
// @AuraEnabled
// public static Map<String, Object> getNotificationStats() {
//     try {
//         Map<String, Object> stats = new Map<String, Object>();
        
//         // Today's notifications
//         Date today = Date.today();
//         List<AggregateResult> todayStats = [
//             SELECT Action__c, COUNT(Id) totalcount
//             FROM AuditTrail__c 
//             WHERE CreatedDate = TODAY 
//             AND Action__c LIKE '%EMAIL%'
//             GROUP BY Action__c
//         ];
        
//         Map<String, Integer> todayBreakdown = new Map<String, Integer>();
//         Integer totalToday = 0;
//         for (AggregateResult ar : todayStats) {
//             Integer count = (Integer)ar.get('count');
//             todayBreakdown.put((String)ar.get('Action__c'), count);
//             totalToday += count;
//         }
        
//         stats.put('todayTotal', totalToday);
//         stats.put('todayBreakdown', todayBreakdown);
        
//         // Weekly trends
//         List<AggregateResult> weeklyStats = [
//             SELECT DAY_ONLY(CreatedDate) day, COUNT(Id) totalcount
//             FROM AuditTrail__c 
//             WHERE CreatedDate >= :Date.today().addDays(-7)
//             AND Action__c LIKE '%EMAIL%'
//             GROUP BY DAY_ONLY(CreatedDate)
//             ORDER BY DAY_ONLY(CreatedDate)
//         ];
        
       
// Map<String, Integer> weeklyTrend = new Map<String, Integer>();
// for (AggregateResult ar : weeklyStats) {
//     Date day = (Date)ar.get('day');
//     Integer count = (Integer)ar.get('count');
//     weeklyTrend.put(day.format(), count);
// }
// stats.put('weeklyTrend', weeklyTrend);

// // Success rate calculation
// List<AggregateResult> successStats = [
//     SELECT Status__c, COUNT(Id) tootalcount
//     FROM AuditTrail__c 
//     WHERE CreatedDate >= :Date.today().addDays(-30)
//     AND Action__c LIKE '%EMAIL%'
//     GROUP BY Status__c
// ];

// Integer totalSent = 0;
// Integer successfulSent = 0;
// for (AggregateResult ar : successStats) {
//     Integer count = (Integer)ar.get('count');
//     totalSent += count;
//     if (ar.get('Status__c') == 'SUCCESS') {
//         successfulSent += count;
//     }
// }

// Decimal successRate = totalSent > 0 ? (Decimal.valueOf(successfulSent) / totalSent) * 100 : 0;
// stats.put('successRate', successRate.setScale(2));
// stats.put('totalSent30Days', totalSent);
// stats.put('successfulSent30Days', successfulSent);

// // Most active notification types
// List<AggregateResult> typeStats = [
//     SELECT Action__c, COUNT(Id) totalcount
//     FROM AuditTrail__c 
//     WHERE CreatedDate >= :Date.today().addDays(-30)
//     AND Action__c LIKE '%EMAIL%'
//     GROUP BY Action__c
//     ORDER BY COUNT(Id) DESC
//     LIMIT 5
// ];

// Map<String, Integer> notificationTypes = new Map<String, Integer>();
// for (AggregateResult ar : typeStats) {
//     notificationTypes.put((String)ar.get('Action__c'), (Integer)ar.get('count'));
// }
// stats.put('topNotificationTypes', notificationTypes);

// // Failed notifications requiring attention
// List<AuditTrail__c> failedNotifications = [
//     SELECT Id, CreatedDate, Action__c, Details__c, RecordId__c
//     FROM AuditTrail__c
//     WHERE CreatedDate >= :Date.today().addDays(-7)
//     AND Action__c LIKE '%EMAIL%'
//     AND Status__c = 'ERROR'
//     ORDER BY CreatedDate DESC
//     LIMIT 10
// ];
// stats.put('recentFailures', failedNotifications);

// return stats;

// } catch (Exception e) {
//     throw new AuraHandledException('Unable to retrieve notification statistics: ' + e.getMessage());
// }
// }

// /**
// * Retry failed notifications
// */
// @AuraEnabled
// public static Map<String, Boolean> retryFailedNotifications(List<String> auditTrailIds) {
//     Map<String, Boolean> retryResults = new Map<String, Boolean>();
    
//     try {
//         // Get failed notification details
//         List<AuditTrail__c> failedNotifications = [
//             SELECT Id, Action__c, RecordId__c, Details__c
//             FROM AuditTrail__c
//             WHERE Id IN :auditTrailIds
//             AND Status__c = 'ERROR'
//             AND Action__c LIKE '%EMAIL%'
//         ];
        
//         for (AuditTrail__c audit : failedNotifications) {
//             Boolean success = false;
            
//             try {
//                 // Determine notification type and retry
//                 if (audit.Action__c.contains('SIGNATURE_REQUEST')) {
//                     success = sendSignatureRequestNotification(audit.RecordId__c);
//                 } else if (audit.Action__c.contains('REMINDER')) {
//                     success = sendSignatureReminderNotification(audit.RecordId__c);
//                 } else if (audit.Action__c.contains('COMPLETED')) {
//                     success = sendSignatureCompletionNotification(audit.RecordId__c);
//                 } else if (audit.Action__c.contains('REJECTED')) {
//                     // Would need rejection reason from original request
//                     Signature_Request__c request = [
//                         SELECT RejectionReason__c 
//                         FROM Signature_Request__c 
//                         WHERE Id = :audit.RecordId__c 
//                         LIMIT 1
//                     ];
//                     success = sendSignatureRejectionNotification(audit.RecordId__c, request.RejectionReason__c);
//                 }
                
//                 retryResults.put(audit.Id, success);
                
//             } catch (Exception e) {
//                 retryResults.put(audit.Id, false);
//                 System.debug('Retry failed for audit ' + audit.Id + ': ' + e.getMessage());
//             }
//         }
        
//         // Log retry attempt
//         AuditTrailManager.createAuditEntry(
//             null,
//             'NOTIFICATION_RETRY',
//             'INFO',
//             'Retry attempted for ' + auditTrailIds.size() + ' failed notifications'
//         );
        
//         return retryResults;
        
//     } catch (Exception e) {
//         throw new AuraHandledException('Unable to retry failed notifications: ' + e.getMessage());
//     }
// }

// /**
// * Send test notification for system verification
// */
// @AuraEnabled
// public static Boolean sendTestNotification(String recipientEmail, String notificationType) {
//     try {
//         Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
//         email.setToAddresses(new String[]{recipientEmail});
//         email.setSubject('E-Signature System Test - ' + notificationType);
        
//         Map<String, String> testMergeFields = new Map<String, String>();
//         testMergeFields.put('{!SignerName}', 'Test User');
//         testMergeFields.put('{!DocumentTitle}', 'Test Document');
//         testMergeFields.put('{!ExpirationDate}', Date.today().addDays(7).format());
//         testMergeFields.put('{!DaysRemaining}', '7');
//         testMergeFields.put('{!UrgencyLevel}', 'NORMAL');
//         testMergeFields.put('{!CompletedDate}', System.now().format());
//         testMergeFields.put('{!RejectionDate}', System.now().format());
//         testMergeFields.put('{!RejectionReason}', 'Test rejection reason');
//         testMergeFields.put('{!SigningURL}', System.URL.getOrgDomainUrl().toExternalForm());
//         testMergeFields.put('{!DocumentURL}', System.URL.getOrgDomainUrl().toExternalForm());
        
//         String templateName = '';
//         switch on notificationType {
//             when 'SIGNATURE_REQUEST' {
//                 templateName = 'SignatureRequestTemplate';
//             }
//             when 'SIGNATURE_REMINDER' {
//                 templateName = 'SignatureReminderTemplate';
//             }
//             when 'SIGNATURE_COMPLETED' {
//                 templateName = 'SignatureCompletedTemplate';
//             }
//             when 'SIGNATURE_REJECTED' {
//                 templateName = 'SignatureRejectedTemplate';
//             }
//             when else {
//                 templateName = 'DefaultTemplate';
//             }
//         }
        
//         String emailBody = applyMergeFields(
//             generateDefaultEmailTemplate(templateName),
//             testMergeFields
//         );
        
//         // Add test banner
//         emailBody = emailBody.replace('<h2', 
//             '<div style="background-color: #fff3cd; border: 1px solid #ffeaa7; padding: 10px; margin-bottom: 20px; text-align: center; color: #856404; font-weight: bold;">⚠️ THIS IS A TEST NOTIFICATION ⚠️</div><h2');
        
//         email.setHtmlBody(emailBody);
        
//         Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
//         Boolean success = results[0].isSuccess();
        
//         // Log test notification
//         AuditTrailManager.logEmailActivity(
//             recipientEmail,
//             'TEST_' + notificationType,
//             success,
//             success ? 'Test notification sent successfully' : 'Test notification failed: ' + results[0].getErrors()[0].getMessage()
//         );
        
//         return success;
        
//     } catch (Exception e) {
//         AuditTrailManager.logEmailActivity(
//             recipientEmail,
//             'TEST_NOTIFICATION_ERROR',
//             false,
//             'Test notification exception: ' + e.getMessage()
//         );
//         throw new AuraHandledException('Test notification failed: ' + e.getMessage());
//     }
// }
}
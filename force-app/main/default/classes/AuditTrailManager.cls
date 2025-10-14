public class AuditTrailManager {


     public class AuditOptions {
        public String recordId;
        public String action;
        public String status;
        public String details;
        public Map<String, Object> metadata;
        public AuditOptions() { metadata = new Map<String,Object>(); }
    }
        // Audit action constants
    public static final String ACTION_DOCUMENT_CREATED = 'DOCUMENT_CREATED';
    public static final String ACTION_DOCUMENT_UPDATED = 'DOCUMENT_UPDATED';
    public static final String ACTION_DOCUMENT_DELETED = 'DOCUMENT_DELETED';
    public static final String ACTION_SIGNATURE_REQUESTED = 'SIGNATURE_REQUESTED';
    public static final String ACTION_SIGNATURE_SUBMITTED = 'SIGNATURE_SUBMITTED';
    public static final String ACTION_SIGNATURE_COMPLETED = 'SIGNATURE_COMPLETED';
    public static final String ACTION_SIGNATURE_REJECTED = 'SIGNATURE_REJECTED';
    public static final String ACTION_SIGNATURE_CANCELLED = 'SIGNATURE_CANCELLED';
    public static final String ACTION_COMPLIANCE_CHECK = 'COMPLIANCE_CHECK';
    public static final String ACTION_COMPLIANCE_VIOLATION = 'COMPLIANCE_VIOLATION';
    public static final String ACTION_EMAIL_SENT = 'EMAIL_SENT';
    public static final String ACTION_EMAIL_FAILED = 'EMAIL_FAILED';
    public static final String ACTION_DOCUSIGN_WEBHOOK = 'DOCUSIGN_WEBHOOK';
    public static final String ACTION_API_REQUEST = 'API_REQUEST';
    public static final String ACTION_API_RESPONSE = 'API_RESPONSE';
    public static final String ACTION_USER_LOGIN = 'USER_LOGIN';
    public static final String ACTION_USER_LOGOUT = 'USER_LOGOUT';
    public static final String ACTION_SECURITY_EVENT = 'SECURITY_EVENT';
    public static final String ACTION_SYSTEM_ERROR = 'SYSTEM_ERROR';
    public static final String ACTION_SYSTEM_RESTART = 'SYSTEM_RESTART';
    
    // Status constants
    public static final String STATUS_SUCCESS = 'SUCCESS';
    public static final String STATUS_ERROR = 'ERROR';
    public static final String STATUS_WARNING = 'WARNING';
    public static final String STATUS_INFO = 'INFO';


    public static void logDocumentActivity(Id documentId, String action, String details) {
        try {
            AuditTrail__c a = new AuditTrail__c(
                RecordId__c = (documentId == null ? null : String.valueOf(documentId)),
                Action__c = action,
                Status__c = 'DOCUMENT',
                Details__c = details,
                Timestamp__c = System.now(),
                UserId__c = UserInfo.getUserId()
            );
            insert a;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'AuditTrailManager.logDocumentActivity failed: ' + e.getMessage());
        }
    }
    public static void logDocumentActivity(String recordId, String action, String status, String details) {
        try {
            AuditTrail__c audit = new AuditTrail__c(
                Action__c = action,
                Status__c = status,
                Details__c = details + ' | Record ID: ' + recordId,
                Timestamp__c = System.now(),
                UserId__c = UserInfo.getUserId()
            );
            insert audit;
        } catch (Exception e) {
            System.debug('AuditTrailManager Error: ' + e.getMessage());
        }
    }

private static String getRequestType(String requestId) {
    try {
        Signature_Request__c request = [
            SELECT DocumentId__r.ContractType__c 
            FROM Signature_Request__c 
            WHERE Id = :requestId 
            LIMIT 1
        ];
        return request.DocumentId__r.ContractType__c;
    } catch (Exception e) {
        return 'UNKNOWN';
    }
}
private static Integer getDocumentCount(String requestId) {
    try {
        return [
            SELECT COUNT() 
            FROM Signature_Request__c 
            WHERE Id = :requestId
        ];
    } catch (Exception e) {
        return 0;
    }
}

private static String getEmailTemplate(String emailType) {
    // Return template name based on email type
    switch on emailType {
        when 'SIGNATURE_REQUEST' { return 'SignatureRequestTemplate'; }
        when 'SIGNATURE_REMINDER' { return 'SignatureReminderTemplate'; }
        when 'SIGNATURE_COMPLETED' { return 'SignatureCompletedTemplate'; }
        when 'SIGNATURE_REJECTED' { return 'SignatureRejectedTemplate'; }
        when default { return 'DefaultEmailTemplate'; }
    }
}

private static String calculateRiskLevel(String severity, String eventType) {
    if (severity.equals('CRITICAL') || eventType.contains('BREACH')) {
        return 'HIGH_RISK';
    } else if (severity.equals('HIGH') || eventType.contains('UNAUTHORIZED')) {
        return 'MEDIUM_RISK';
    } else {
        return 'LOW_RISK';
    }
}

    public static void logSignatureActivity(String signatureRequestId, String action, String status, String details) {
        try {
            AuditTrail__c audit = new AuditTrail__c(
                Action__c = action,
                Status__c = status,
                Details__c = details + ' | Signature Request ID: ' + signatureRequestId,
                Timestamp__c = System.now(),
                UserId__c = UserInfo.getUserId()
            );
            insert audit;
        } catch (Exception e) {
            System.debug('AuditTrailManager Error: ' + e.getMessage());
        }
    }
    
@AuraEnabled(cacheable=true)
    public static List<AuditTrail__c> getAuditTrail(String recordId, Integer limitCount) {
        try {
            String query = 'SELECT Action__c, Status__c, Details__c, Timestamp__c, UserId__c ' +
                          'FROM AuditTrail__c ' +
                          'WHERE Details__c LIKE \'%' + recordId + '%\' ' +
                          'ORDER BY Timestamp__c DESC';
            
            if (limitCount != null && limitCount > 0) {
                query += ' LIMIT ' + limitCount;
            }
            
            return Database.query(query);
            
        } catch (Exception e) {
            System.debug('GetAuditTrail Error: ' + e.getMessage());
            return new List<AuditTrail__c>();
        }
    }

public static void logSignatureActivity(String requestId, String action, String details) {
        createAuditEntry(requestId, action, 'Success', details);
    }


    public static void logSignatureActivity(
        String requestId, 
        String activityType, 
        String signerEmail,
        String details
    ) {
        Map<String, Object> metadata = new Map<String, Object>();
        metadata.put('signerEmail', signerEmail);
        metadata.put('requestType', getRequestType(requestId));
        metadata.put('documentCount', getDocumentCount(requestId));
        
        createAuditEntry(
            requestId, 
            ACTION_SIGNATURE_REQUESTED.replace('REQUESTED', activityType.toUpperCase()), 
            STATUS_SUCCESS, 
            details,
            metadata
        );
    }
private static void publishAuditEvent(AuditTrail__c audit) {
    try {
        AuditTrailEvent__e event = new AuditTrailEvent__e();
        event.AuditRecordId__c = audit.Id;
        event.Action__c = audit.Action__c;
        event.Status__c = audit.Status__c;
        event.UserId__c = audit.UserId__c;
        event.Timestamp__c = audit.Timestamp__c;
        event.Details__c = audit.Details__c;
        
        EventBus.publish(event);
    } catch (Exception e) {
        System.debug('Failed to publish audit event: ' + e.getMessage());
    }
}

// Wrapper classes
public class BulkAuditRequest {
    public String recordId;
    public String action;
    public String status;
    public String details;
    public Map<String, Object> metadata;
}


private static String getClientIPAddressSafe() {
        try {
            if (RestContext.request != null && RestContext.request.headers != null) {
                String xf = RestContext.request.headers.get('X-Forwarded-For');
                if (!String.isBlank(xf)) {
                    // X-Forwarded-For can be comma-separated — take first
                    return xf.split(',')[0].trim();
                }
                // Try request URI remote info if available (platform dependent)
                // On some contexts, remote address is not available, so guard it.
                if (RestContext.request != null && RestContext.request.requestURI != null) {
                    // fallback not ideal but keep for trace
                    return RestContext.request.requestURI;
                }
            }
        } catch (Exception ex) {
            // swallow and return placeholder
        }
        return 'UNKNOWN';
    }


    private static void publishCriticalEvent(AuditTrail__c audit, AuditOptions opts) {
        try {
            // Platform event must be defined: AuditTrailEvent__e with fields: RecordId__c, Action__c, Details__c, Severity__c
            AuditTrailEvent__e ev = new AuditTrailEvent__e(
                RecordId__c = audit.RecordId__c,
                Action__c = audit.Action__c,
                Details__c = audit.Details__c,
                Severity__c = (opts.metadata != null && opts.metadata.containsKey('severity')) ? String.valueOf(opts.metadata.get('severity')) : 'CRITICAL'
            );
            EventBus.publish(ev);
        } catch (Exception ex) {
            // last resort: write to debug
            System.debug('Failed to publish audit event: ' + ex.getMessage());
        }
    }
public static void createAuditEntry(AuditOptions opts) {
        // Best-effort: gather context, then insert audit record.
        try {
            AuditTrail__c audit = new AuditTrail__c();
            audit.RecordId__c = opts.recordId;
            audit.Action__c = opts.action;
            audit.Status__c = opts.status;
            audit.Details__c = opts.details;
            audit.Timestamp__c = System.now();
            audit.UserId__c = UserInfo.getUserId();

            // Context: attempt to read HTTP headers if available
            String ip = getClientIPAddressSafe();
            String ua = getUserAgentSafe();
            String sessionId = UserInfo.getSessionId();

            audit.IP_Address__c = ip;
            audit.User_Agent__c = ua;
            audit.Session_Id__c = sessionId;

            // Optional: include metadata JSON for richer context
            if (opts.metadata != null && !opts.metadata.isEmpty()) {
                audit.Metadata__c = JSON.serialize(opts.metadata);
            }

            insert audit;

            // If event severity is critical, publish platform event for immediate watchers
            if (opts.metadata != null && opts.metadata.containsKey('severity') && String.valueOf(opts.metadata.get('severity')).toUpperCase() == 'CRITICAL') {
                publishCriticalEvent(audit, opts);
            }
        } catch (Exception e) {
            // Fallback: queueable writer to avoid causing caller to fail due to logging problems
            System.enqueueJob(new AuditTrailFallbackQueueable(opts, e.getMessage()));
        }
    }

public static void createAuditEntry(String recordId, String action, String status, String details) {
    try {
      AuditTrail__c a = new AuditTrail__c(
        RecordId__c = recordId,
        Action__c = action,
        Status__c = status,
        Details__c = details,
        Timestamp__c = System.now(),
        UserId__c = UserInfo.getUserId(),
        IP_Address__c = getClientIPAddress(),
        User_Agent__c = getUserAgent()
      );
      Map<String,String> geo = geoForIp(a.IP_Address__c);
      a.Location_City__c = geo.get('city');
      a.Location_Country__c = geo.get('country');
      insert a;
    } catch (Exception e) {
      System.debug('Audit create failed: ' + e.getMessage());
    }
  }


        public static void createAuditEntry(
        String recordId, 
        String action, 
        String status, 
        String details,
        Map<String, Object> additionalData
    ) {
        try {
            AuditTrail__c audit = new AuditTrail__c();
            audit.RecordId__c = recordId;
            audit.Action__c = action;
            audit.Status__c = status;
            audit.Details__c = details;
            audit.Timestamp__c = System.now();
            audit.UserId__c = UserInfo.getUserId();
            audit.UserName__c = UserInfo.getName();
            audit.IPAddress__c = getClientIPAddress();
            audit.SessionId__c = UserInfo.getSessionId();
            audit.OrganizationId__c = UserInfo.getOrganizationId();
            
            // Add browser and device information
            audit.UserAgent__c = getUserAgent();
            audit.DeviceType__c = getDeviceType();
            
            // Add geolocation if available
            audit.LocationCity__c = getLocationCity();
            audit.LocationCountry__c = getLocationCountry();
            
            // Add additional metadata as JSON
            if (additionalData != null && !additionalData.isEmpty()) {
                audit.AdditionalMetadata__c = JSON.serialize(additionalData);
            }
            
            // Add correlation ID for request tracking
            audit.CorrelationId__c = getCorrelationId();
            
            insert audit;
            
            // For critical events, create platform event for real-time monitoring
            if (status == STATUS_ERROR || action.contains('SECURITY') || action.contains('COMPLIANCE_VIOLATION')) {
                publishAuditEvent(audit);
            }
            
        } catch (Exception e) {
            // Fallback logging to system debug
            System.debug(LoggingLevel.ERROR, 'Audit Trail Creation Failed: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Original Action: ' + action + ', Status: ' + status + ', Details: ' + details);
        }
    }
    








    //     String recordId, 
    //     String action, 
    //     String status, 
    //     String details
    // ) {
    //     createAuditEntry(recordId, action, status, details, null);
    // }

    public static void logDocumentActivity(String documentId, String action, String details) {
        try {
            AuditTrail__c audit = new AuditTrail__c(
                DocumentId__c = documentId,
                Action__c = action,
                Status__c = 'SUCCESS',
                Details__c = details,
                Timestamp__c = System.now(),
                UserId__c = UserInfo.getUserId()
            );
            insert audit;
            
            System.debug('✓ Audit trail logged: ' + action);
        } catch (Exception e) {
            System.debug('⚠ Failed to log audit trail: ' + e.getMessage());
            // Don't throw exception to avoid breaking main process
        }
    }
 private static String getClientIP() {
        if(RestContext.request != null){
            // favored header is X‑Forwarded‑For if behind proxy
            String xff = RestContext.request.headers.get('X-Forwarded-For');
            if(String.isNotBlank(xff)) return xff.split(',')[0].trim();
            return RestContext.request.remoteAddress != null ? RestContext.request.remoteAddress : 'UNKNOWN';
        }
        return 'UNKNOWN';
    }

         public static void logSystemActivity(String eventType, String details) {
        try {
            AuditTrail__c a = new AuditTrail__c(
                RecordId__c = null,
                Action__c = eventType,
                Status__c = 'INFO',
                Details__c = details,
                Timestamp__c = System.now(),
                UserId__c = UserInfo.getUserId()
            );
            insert a;
        } catch (Exception e) {
            // Best-effort logging — do not throw to avoid impacting the calling flow
            System.debug(LoggingLevel.WARN, 'AuditTrailManager.logSystemActivity failed: ' + e.getMessage());
        }
    }
    
    public static void logError(String action, String errorMessage, String documentId) {
        try {
            AuditTrail__c audit = new AuditTrail__c(
                DocumentId__c = documentId,
                Action__c = action,
                Status__c = 'ERROR',
                Details__c = 'Error: ' + errorMessage,
                Timestamp__c = System.now(),
                UserId__c = UserInfo.getUserId()
            );
            insert audit;
            
            System.debug('✓ Error logged: ' + action);
        } catch (Exception e) {
            System.debug('⚠ Failed to log error: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<AuditTrail__c> getDocumentAuditTrail(String documentId) {
        try {
            return [
                SELECT Id, Action__c, Status__c, Details__c, Timestamp__c, 
                       UserId__c, User__r.Name
                FROM AuditTrail__c 
                WHERE DocumentId__c = :documentId 
                ORDER BY Timestamp__c DESC
                LIMIT 100
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve audit trail: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getAuditSummary(Integer days) {
        try {
            DateTime cutoffDate = System.now().addDays(-days);
            
            List<AggregateResult> results = [
                SELECT Action__c action, COUNT(Id) totalcount
                FROM AuditTrail__c 
                WHERE Timestamp__c >= :cutoffDate
                GROUP BY Action__c
            ];
            
            Map<String, Integer> summary = new Map<String, Integer>();
            for (AggregateResult result : results) {
                summary.put(
                    (String)result.get('action'), 
                    (Integer)result.get('count')
                );
            }
            
            return summary;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to generate audit summary: ' + e.getMessage());
        }
    }

    
    public static void logSignatureRequest(String requestId, String action) {
        try {
            Signature_Request__c request = [SELECT DocumentId__c FROM Signature_Request__c WHERE Id = :requestId LIMIT 1];
            
            AuditTrail__c audit = new AuditTrail__c(
                DocumentId__c = request.DocumentId__c,
                Action__c = action,
                Status__c = 'In Progress',
                Details__c = 'Signature request created for request ID: ' + requestId,
                Timestamp__c = System.now(),
                UserId__c = UserInfo.getUserId()
            );
            insert audit;
        } catch (Exception e) {
            System.debug('Failed to log signature request audit: ' + e.getMessage());
        }
    }
public static void logSignatureCompletion(String requestId, String signatureMethod) {
   
   
           String details = 'Signature completed using method: ' + signatureMethod;
        createAuditEntry(requestId, 'SIGNATURE_COMPLETED', 'Success', details);
}
   
   
   
   
    //     try {
    //         Signature_Request__c request = [SELECT DocumentId__c, SignerName__c FROM Signature_Request__c WHERE Id = :requestId LIMIT 1];
            
    //         AuditTrail__c audit = new AuditTrail__c(
    //             DocumentId__c = request.DocumentId__c,
    //             Action__c = 'Signature Completed',
    //             Status__c = 'Completed',
    //             Details__c = 'Document signed by ' + request.SignerName__c + ' using method: ' + signatureMethod,
    //             Timestamp__c = System.now(),
    //             UserId__c = UserInfo.getUserId()
    //         );
    //         insert audit;
    //     } catch (Exception e) {
    //         System.debug('Failed to log signature completion audit: ' + e.getMessage());
    //     }
    // }

    public static void logComplianceCheck(
    String recordId,
    Boolean passed,
    String ruleType,
    Decimal score,
    List<String> violations
) {
    // Build metadata
    Map<String, Object> metadata = new Map<String, Object>();
    metadata.put('ruleType', ruleType);
    metadata.put('complianceScore', score);
    metadata.put('violations', violations);
    metadata.put('ruleVersion', getCurrentRuleVersion());

    // Determine status & action
    String status = passed ? STATUS_SUCCESS : STATUS_WARNING;
    String action = passed ? ACTION_COMPLIANCE_CHECK : ACTION_COMPLIANCE_VIOLATION;

    // Build details message
    String details = 'Compliance check ' + (passed ? 'passed' : 'failed') +
                     ' with score: ' + String.valueOf(score) + '%' +
                     ((violations != null && !violations.isEmpty())
                        ? '. Violations: ' + String.join(violations, '; ')
                        : '');

    // Create audit entry
    createAuditEntry(recordId, action, status, details, metadata);
}
public static void logAPIActivity(
    String endpoint,
    String method,
    Integer statusCode,
    String requestBody,
    String responseBody,
    Long responseTime
) {
    Map<String, Object> metadata = new Map<String, Object>();
    metadata.put('endpoint', endpoint);
    metadata.put('method', method);
    metadata.put('statusCode', statusCode);
    metadata.put('responseTime', responseTime);
    metadata.put('requestSize', requestBody?.length());
    metadata.put('responseSize', responseBody?.length());
    
    String status = (statusCode >= 200 && statusCode < 300) ? STATUS_SUCCESS : STATUS_ERROR;
    String details = method + ' request to ' + endpoint + 
                    ' returned ' + statusCode + 
                    ' in ' + responseTime + 'ms';
    
    createAuditEntry(null, ACTION_API_REQUEST, status, details, metadata);
}
public static void logEmailActivity(
    String recipientEmail,
    String emailType,
    Boolean success,
    String details
) {
    Map<String, Object> metadata = new Map<String, Object>();
    metadata.put('recipientEmail', recipientEmail);
    metadata.put('emailType', emailType);
    metadata.put('emailTemplate', getEmailTemplate(emailType));
    
    String action = success ? ACTION_EMAIL_SENT : ACTION_EMAIL_FAILED;
    String status = success ? STATUS_SUCCESS : STATUS_ERROR;
    
    createAuditEntry(null, action, status, details, metadata);
}
public static void logSecurityEvent(
    String eventType,
    String severity,
    String description,
    String affectedResource
) {
    Map<String, Object> metadata = new Map<String, Object>();
    metadata.put('eventType', eventType);
    metadata.put('severity', severity);
    metadata.put('affectedResource', affectedResource);
    metadata.put('detectionMethod', 'AUTOMATED');
    metadata.put('riskLevel', calculateRiskLevel(severity, eventType));
    
    String status = severity.equals('CRITICAL') ? STATUS_ERROR : 
                   severity.equals('HIGH') ? STATUS_WARNING : STATUS_INFO;
    
    createAuditEntry(affectedResource, ACTION_SECURITY_EVENT, status, description, metadata);
    
    // Send immediate notification for critical security events
    if (severity.equals('CRITICAL')) {
        NotificationService.sendSecurityAlert(eventType, description);
    }
}

private static String getClientIPAddress() {
  try {
    if (RestContext.request != null && RestContext.request.headers != null) {
      // X‑Forwarded‑For handling
      String xff = RestContext.request.headers.get('X‑Forwarded‑For');
      if (String.isNotBlank(xff)) {
        // XFF can contain comma list; pick first public IP
        List<String> parts = xff.split(',');
        return parts.size() > 0 ? parts[0].trim() : xff;
      }
      // fallback to request.remoteAddress if available
      if (RestContext.request.remoteAddress != null) return RestContext.request.remoteAddress;
    }
  } catch (Exception e) {
    System.debug('IP detection failed: ' + e.getMessage());
  }
  return 'UNKNOWN';
}
public static String getCountryFromIP(String ip) {
        // TODO: replace with callout to named credential geo service
        return null;
    }
private static Map<String,String> geoForIp(String ip) {
    Map<String,String> out = new Map<String,String>{ 'city'=>null, 'country'=>null };
    // TODO: call IP geolocation (callout:GeoService/locate)
    return out;
  }
private static String getUserAgent() {
  try {
    if (RestContext.request != null && RestContext.request.headers != null) {
      String ua = RestContext.request.headers.get('User‑Agent');
      return ua == null ? 'UNKNOWN' : ua;
    }
  } catch (Exception e) { }
  return 'UNKNOWN';
}

private static String getLocationCountry(String ipAddress) {
  // Integrate with IP geolocation service (callout)
  // Placeholder: return null until service is available
  return null;
}

 private static String getUserAgent() {
        if(RestContext.request != null) {
            return RestContext.request.headers.get('User-Agent') != null ? RestContext.request.headers.get('User-Agent') : 'UNKNOWN';
        }
        return 'UNKNOWN';
    }
private static String getDeviceType() {
    // TODO: DEVELOPER IMPLEMENTATION REQUIRED
    // Determine device type from user agent or other indicators
    return 'UNKNOWN'; // Replace with actual device detection logic
}
private static String getLocationCity() {
    // TODO: DEVELOPER IMPLEMENTATION REQUIRED
    // Implement geolocation service integration
    return null; // Replace with actual geolocation service
}
private static String getLocationCountry() {
    // TODO: DEVELOPER IMPLEMENTATION REQUIRED
    // Implement geolocation service integration
    return null; // Replace with actual geolocation service
}

private static String getCorrelationId() {
    // Generate unique correlation ID for request tracking
    return 'CORR-' + System.now().getTime() + '-' + Math.round(Math.random() * 10000);
}

private static String getCurrentRuleVersion() {
    // TODO: DEVELOPER IMPLEMENTATION REQUIRED
    // Return current compliance rule version
    return 'v1.0.0'; // Replace with actual version tracking
}

private static String getDocumentType(String documentId) {
    try {
        DocumentLifecycleConfiguration__c doc = [
            SELECT ContractType__c 
            FROM DocumentLifecycleConfiguration__c 
            WHERE Id = :documentId 
            LIMIT 1
        ];
        return doc.ContractType__c;
    } catch (Exception e) {
        return 'UNKNOWN';
    }
}
private static String getDocumentRegion(String documentId) {
    try {
        DocumentLifecycleConfiguration__c doc = [
            SELECT Region__c 
            FROM DocumentLifecycleConfiguration__c 
            WHERE Id = :documentId 
            LIMIT 1
        ];
        return doc.Region__c;
    } catch (Exception e) {
        return 'UNKNOWN';
    }
}

public static void createBulkAuditEntries(List<BulkAuditRequest> requests) {
    List<AuditTrail__c> auditRecords = new List<AuditTrail__c>();
    
    for (BulkAuditRequest request : requests) {
        AuditTrail__c audit = new AuditTrail__c();
        audit.RecordId__c = request.recordId;
        audit.Action__c = request.action;
        audit.Status__c = request.status;
        audit.Details__c = request.details;
        audit.Timestamp__c = System.now();
        audit.UserId__c = UserInfo.getUserId();
        audit.UserName__c = UserInfo.getName();
        audit.IPAddress__c = getClientIPAddress();
        audit.SessionId__c = UserInfo.getSessionId();
        audit.OrganizationId__c = UserInfo.getOrganizationId();
        audit.UserAgent__c = getUserAgent();
        audit.DeviceType__c = getDeviceType();
        audit.LocationCity__c = getLocationCity();
        audit.LocationCountry__c = getLocationCountry();
        audit.CorrelationId__c = getCorrelationId();
        
        if (request.metadata != null && !request.metadata.isEmpty()) {
            audit.AdditionalMetadata__c = JSON.serialize(request.metadata);
        }
        
        auditRecords.add(audit);
    }
    
    try {
        insert auditRecords;
    } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, 'Bulk audit creation failed: ' + e.getMessage());
    }
}



public static void logComplianceCheck(ComplianceChecker.ComplianceValidationResult result, String region, String contractType) {
        try {
            String status = result.isCompliant ? 'Compliant' : 'Non-Compliant';
            String details = 'Compliance Score: ' + result.complianceScore + '%. Region: ' + region + ', Contract Type: ' + contractType;
            
            if (!result.violations.isEmpty()) {
                details += '. Violations: ' + String.join(result.violations, '; ');
            }
            
            AuditTrail__c audit = new AuditTrail__c(
                Action__c = 'Compliance Check',
                Status__c = status,
                Details__c = details,
                Timestamp__c = System.now(),
                UserId__c = UserInfo.getUserId()
            );
            insert audit;
        } catch (Exception e) {
            System.debug('Failed to log compliance check audit: ' + e.getMessage());
        }
    }
        @AuraEnabled(cacheable=true)
    public static List<AuditTrail__c> getSystemAuditTrail(Integer recordLimit) {
        try {
            Integer limitValue = recordLimit != null ? recordLimit : 50;
            return [
                SELECT Id, Action__c, Status__c, Details__c, Timestamp__c, UserId__c,
                       User__r.Name
                FROM AuditTrail__c
                ORDER BY Timestamp__c DESC
                LIMIT :limitValue
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve system audit trail: ' + e.getMessage());
        }
    }
    public static String generateAuditSummary(String recordId) {
    try {
        List<AuditTrail__c> trails = getAuditTrail(recordId, 50);
        
        if (trails.isEmpty()) {
            return 'No audit trail found for this record.';
        }
        
        String summary = 'AUDIT TRAIL SUMMARY\n';
        summary += 'Record ID: ' + recordId + '\n';
        summary += 'Total Activities: ' + trails.size() + '\n\n';
        
        for (AuditTrail__c trail : trails) {
            summary += trail.Timestamp__c.format('MM/dd/yyyy HH:mm') + ' - ';
            summary += trail.Action__c + ': ' + trail.Status__c + '\n';
            summary += 'Details: ' + trail.Details__c + '\n\n';
        }
        
        return summary;
    } catch (Exception e) {
        return 'Error generating audit summary: ' + e.getMessage();
    }
}


}



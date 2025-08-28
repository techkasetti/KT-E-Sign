public class ZeroTrustSecurityManager {
    
    // Security constants
    private static final String SECURITY_AUDIT_TYPE = 'SECURITY_VERIFICATION';
    private static final Integer MAX_FAILED_ATTEMPTS = 3;
    private static final Integer LOCKOUT_DURATION_MINUTES = 30;
    
    /**
     * Continuous security verification for document access
     */
    public class SecurityContext {
        public String userId;
        public String sessionId;
        public String deviceId;
        public String ipAddress;
        public String userAgent;
        public String geoLocation;
        public DateTime lastVerification;
        public String riskLevel;
        public List<String> permissions;
        public Map<String, Object> behaviorMetrics;
    }
    
    /**
     * Document access security validation
     */
    public static Boolean validateDocumentAccess(String documentId, String userId, SecurityContext context) {
        try {
            // Step 1: Verify user identity and session
            if (!verifyUserIdentity(userId, context)) {
                logSecurityEvent('IDENTITY_VERIFICATION_FAILED', userId, documentId, context);
                return false;
            }
            
            // Step 2: Check device trust status
            if (!verifyDeviceTrust(context.deviceId, userId)) {
                logSecurityEvent('UNTRUSTED_DEVICE_ACCESS', userId, documentId, context);
                return false;
            }
            
            // Step 3: Validate network context
            if (!validateNetworkSecurity(context.ipAddress, context.geoLocation)) {
                logSecurityEvent('SUSPICIOUS_NETWORK_ACCESS', userId, documentId, context);
                return false;
            }
            
            // Step 4: Perform behavioral analysis
            if (!analyzeBehaviorPattern(userId, context)) {
                logSecurityEvent('ANOMALOUS_BEHAVIOR_DETECTED', userId, documentId, context);
                return false;
            }
            
            // Step 5: Check document-specific permissions
            if (!validateDocumentPermissions(documentId, userId, context.permissions)) {
                logSecurityEvent('INSUFFICIENT_PERMISSIONS', userId, documentId, context);
                return false;
            }
            
            // Step 6: Apply dynamic risk assessment
            String riskLevel = calculateDynamicRisk(userId, documentId, context);
            if (riskLevel == 'HIGH' || riskLevel == 'CRITICAL') {
                // Require additional authentication
                return requireAdditionalAuthentication(userId, documentId, context);
            }
            
            return true;
        } catch (Exception e) {
            logSecurityEvent('SECURITY_VALIDATION_ERROR', userId, documentId, context);
            return false;
        }
    }
}
            // All checks passed - grant access
            logSecurityEvent('ACCESS_GRANTED', userId, documentId, context);
            updateLastVerification(userId, context);
            return true;

        } catch (Exception e) {
            logSecurityEvent('SECURITY_VALIDATION_ERROR', userId, documentId, context);
            System.debug('Security validation error: ' + e.getMessage());
            return false; // Fail secure
        }
    }

    /**
     * Verify user identity with multi-factor authentication
     */
    private static Boolean verifyUserIdentity(String userId, SecurityContext context) {
        try {
            // Check if user session is valid
            List<AuthSession> activeSessions = [
                SELECT Id, UsersId, SessionType, LoginType, LastModifiedDate
                FROM AuthSession
                WHERE UsersId = :userId
                AND Id = :context.sessionId
                AND LastModifiedDate >= :DateTime.now().addHours(-8)
                LIMIT 1
            ];

            if (activeSessions.isEmpty()) {
                return false;
            }

            // Verify session hasn't been compromised
            AuthSession session = activeSessions[0];
            if (isSessionCompromised(session, context)) {
                invalidateSession(session.Id);
                return false;
            }

            // Check for concurrent sessions from different locations
            List<AuthSession> concurrentSessions = [
                SELECT Id, SourceIp, LoginGeoId
                FROM AuthSession
                WHERE UsersId = :userId
                AND Id != :context.sessionId
                AND LastModifiedDate >= :DateTime.now().addMinutes(-30)
            ];

            if (detectSuspiciousConcurrentAccess(concurrentSessions, context)) {
                return false;
            }

            return true;

        } catch (Exception e) {
            System.debug('Identity verification error: ' + e.getMessage());
            return false;
        }
    }

    /**
     * Verify device trust status using device fingerprinting
     */
    private static Boolean verifyDeviceTrust(String deviceId, String userId) {
        try {
            // Check if device is registered and trusted
            List<TrustedDevice__c> trustedDevices = [
                SELECT Id, Device_Id__c, Trust_Level__c, Last_Verified__c, Risk_Score__c
                FROM TrustedDevice__c
                WHERE Device_Id__c = :deviceId
                AND User_Id__c = :userId
                AND Is_Active__c = true
                LIMIT 1
            ];

            if (trustedDevices.isEmpty()) {
                // New device - create pending trust record
                createPendingDeviceVerification(deviceId, userId);
                return false; // Require additional verification for new devices
            }

            TrustedDevice__c device = trustedDevices[0];

            // Check device trust level
            if (device.Trust_Level__c == 'BLOCKED' || device.Risk_Score__c > 70) {
                return false;
            }

            // Verify device hasn't been inactive too long
            if (device.Last_Verified__c < DateTime.now().addDays(-30)) {
                // Device trust expired - require re-verification
                device.Trust_Level__c = 'PENDING_REVERIFICATION';
                update device;
                return false;
            }

            // Update last verification timestamp
            device.Last_Verified__c = DateTime.now();
            update device;

            return device.Trust_Level__c == 'TRUSTED';

        } catch (Exception e) {
            System.debug('Device trust verification error: ' + e.getMessage());
            return false;
        }
    }

    /**
     * Validate network security context
     */
    private static Boolean validateNetworkSecurity(String ipAddress, String geoLocation) {
        try {
            // Check against blocked IP ranges
            List<BlockedIPRange__c> blockedRanges = [
                SELECT IP_Range_Start__c, IP_Range_End__c, Block_Reason__c
                FROM BlockedIPRange__c
                WHERE Is_Active__c = true
            ];

            if (isIPBlocked(ipAddress, blockedRanges)) {
                return false;
            }

            // Check for suspicious geographic access patterns
            if (String.isNotBlank(geoLocation) && isSuspiciousGeographicAccess(geoLocation)) {
                return false;
            }

            // Check for VPN/Proxy usage if restricted
            if (isRestrictedVPNAccess(ipAddress)) {
                return false;
            }

            return true;

        } catch (Exception e) {
            System.debug('Network security validation error: ' + e.getMessage());
            return false;
        }
    }

    /**
     * Analyze user behavior patterns for anomaly detection
     */
    private static Boolean analyzeBehaviorPattern(String userId, SecurityContext context) {
        try {
            // Get recent user behavior history
            List<UserBehaviorMetrics__c> recentBehavior = [
                SELECT Access_Pattern__c, Document_Types_Accessed__c, 
                       Average_Session_Duration__c, Typical_Access_Hours__c,
                       Behavioral_Score__c
                FROM UserBehaviorMetrics__c
                WHERE User_Id__c = :userId
                AND Created_Date__c >= :DateTime.now().addDays(-30)
                ORDER BY Created_Date__c DESC
                LIMIT 10
            ];

            if (recentBehavior.isEmpty()) {
                // New user - create baseline behavior profile
                createBehaviorBaseline(userId, context);
                return true; // Allow access but monitor closely
            }

            // Calculate behavior deviation score
            Decimal deviationScore = calculateBehaviorDeviation(recentBehavior, context);

            // Check if behavior is anomalous
            if (deviationScore > 75) {
                // High deviation - possible account compromise
                return false;
            } else if (deviationScore > 50) {
                // Medium deviation - require additional verification
                return requireBehaviorVerification(userId, context);
            }

            // Update behavior metrics
            updateBehaviorMetrics(userId, context, deviationScore);
            return true;

        } catch (Exception e) {
            System.debug('Behavior analysis error: ' + e.getMessage());
            return true; // Allow access but log error
        }
    }

    /**
     * Validate document-specific permissions with granular controls
     */
    private static Boolean validateDocumentPermissions(String documentId, String userId, List<String> permissions) {
        try {
            // Get document security classification
            DocumentLifecycleConfiguration__c document = [
                SELECT Id, Security_Classification__c, Access_Level_Required__c,
                       Region__c, ContractType__c, Status__c
                FROM DocumentLifecycleConfiguration__c
                WHERE Id = :documentId
                LIMIT 1
            ];

            // Check user's permission level
            String requiredPermission = getRequiredPermission(document);
            if (!permissions.contains(requiredPermission)) {
                return false;
            }

            // Check document-specific access controls
            List<DocumentAccessControl__c> accessControls = [
                SELECT User_Id__c, Permission_Type__c, Expiry_Date__c, Is_Active__c
                FROM DocumentAccessControl__c
                WHERE Document_Id__c = :documentId
                AND (User_Id__c = :userId OR User_Id__c = 'ALL_USERS')
                AND Is_Active__c = true
                AND (Expiry_Date__c = null OR Expiry_Date__c >= :Date.today())
            ];

            // If specific access controls exist, validate against them
            if (!accessControls.isEmpty()) {
                Boolean hasValidAccess = false;
                for (DocumentAccessControl__c control : accessControls) {
                    if (control.Permission_Type__c == 'FULL_ACCESS' || 
                        control.Permission_Type__c == 'READ_ACCESS') {
                        hasValidAccess = true;
                        break;
                    }
                }
                return hasValidAccess;
            }

            // Check time-based access restrictions
            if (!isWithinAllowedAccessHours(document)) {
                return false;
            }

            return true;

        } catch (Exception e) {
            System.debug('Permission validation error: ' + e.getMessage());
            return false;
        }
    }

    /**
     * Calculate dynamic risk score based on multiple factors
     */
    private static String calculateDynamicRisk(String userId, String documentId, SecurityContext context) {
        Decimal riskScore = 0;

        try {
            // Factor 1: User risk profile (30% weight)
            UserSecurityProfile__c userProfile = getUserSecurityProfile(userId);
            if (userProfile != null) {
                riskScore += userProfile.Risk_Score__c * 0.3;
            }

            // Factor 2: Document sensitivity (25% weight)
            DocumentLifecycleConfiguration__c document = [
                SELECT Security_Classification__c, ComplianceScore__c
                FROM DocumentLifecycleConfiguration__c
                WHERE Id = :documentId
                LIMIT 1
            ];
            
            Map<String, Decimal> classificationRisk = new Map<String, Decimal>{
                'PUBLIC' => 10,
                'INTERNAL' => 30,
                'CONFIDENTIAL' => 60,
                'RESTRICTED' => 90
            };
            
            Decimal docRisk = classificationRisk.get(document.Security_Classification__c);
            if (docRisk != null) {
                riskScore += docRisk * 0.25;
            }

            // Factor 3: Access context (20% weight)
            Decimal contextRisk = calculateContextRisk(context);
            riskScore += contextRisk * 0.20;

            // Factor 4: Recent security incidents (15% weight)
            Integer recentIncidents = getRecentSecurityIncidents(userId);
            riskScore += Math.min(recentIncidents * 10, 50) * 0.15;

            // Factor 5: Compliance history (10% weight)
            if (document.ComplianceScore__c != null) {
                riskScore += (100 - document.ComplianceScore__c) * 0.10;
            }

            // Normalize risk score
            riskScore = Math.min(riskScore, 100);

        } catch (Exception e) {
            System.debug('Risk calculation error: ' + e.getMessage());
            riskScore = 50; // Default moderate risk
        }

        // Determine risk level
        if (riskScore >= 80) return 'CRITICAL';
        if (riskScore >= 60) return 'HIGH';
        if (riskScore >= 40) return 'MEDIUM';
        if (riskScore >= 20) return 'LOW';
        return 'MINIMAL';
    }

    /**
     * Require additional authentication for high-risk access
     */
    private static Boolean requireAdditionalAuthentication(String userId, String documentId, SecurityContext context) {
        try {
            // Create MFA challenge record
            MFAChallenge__c challenge = new MFAChallenge__c(
                User_Id__c = userId,
                Document_Id__c = documentId,
                Challenge_Type__c = 'HIGH_RISK_ACCESS',
                Challenge_Code__c = generateSecureChallengeCode(),
                Expiry_Time__c = DateTime.now().addMinutes(10),
                Status__c = 'PENDING',
                Session_Id__c = context.sessionId,
                IP_Address__c = context.ipAddress,
                Device_Id__c = context.deviceId
            );
            insert challenge;

            // Send MFA challenge to user
            sendMFAChallenge(userId, challenge.Challenge_Code__c);

            // Log security event
            logSecurityEvent('MFA_CHALLENGE_SENT', userId, documentId, context);

            return false; // Access denied until MFA completed
            
        } catch (Exception e) {
            System.debug('MFA challenge error: ' + e.getMessage());
            return false; // Fail secure
        }
    }

    /**
     * Validate MFA response for high-risk access
     */
    public static Boolean validateMFAResponse(String userId, String documentId, String challengeCode, String response) {
        try {
            // Find active MFA challenge
            List<MFAChallenge__c> challenges = [
                SELECT Id, Challenge_Code__c, Expiry_Time__c, Attempt_Count__c
                FROM MFAChallenge__c
                WHERE User_Id__c = :userId
                AND Document_Id__c = :documentId
                AND Status__c = 'PENDING'
                AND Expiry_Time__c >= :DateTime.now()
                LIMIT 1
            ];

            if (challenges.isEmpty()) {
                return false; // No valid challenge found
            }

            MFAChallenge__c challenge = challenges[0];

            // Check attempt count
            if (challenge.Attempt_Count__c >= MAX_FAILED_ATTEMPTS) {
                challenge.Status__c = 'FAILED';
                update challenge;
                return false;
            }

            // Validate response
            Boolean isValid = validateChallengeResponse(challenge.Challenge_Code__c, response);

            // Update challenge record
            challenge.Attempt_Count__c = (challenge.Attempt_Count__c != null ? challenge.Attempt_Count__c : 0) + 1;
            
            if (isValid) {
                challenge.Status__c = 'COMPLETED';
                challenge.Completed_Time__c = DateTime.now();
            } else if (challenge.Attempt_Count__c >= MAX_FAILED_ATTEMPTS) {
                challenge.Status__c = 'FAILED';
                // Lock user account temporarily
                lockUserAccount(userId);
            }
            
            update challenge;

            return isValid;

        } catch (Exception e) {
            System.debug('MFA validation error: ' + e.getMessage());
            return false;
        }
    }

    /**
     * Log security events for audit trail
     */
    private static void logSecurityEvent(String eventType, String userId, String documentId, SecurityContext context) {
        try {
            AuditTrail__c securityEvent = new AuditTrail__c(
                RecordId__c = documentId,
                Action__c = eventType,
                Status__c = eventType.contains('FAILED') || eventType.contains('DENIED') ? 'FAILURE' : 'SUCCESS',
                Timestamp__c = DateTime.now(),
                UserDetails__c = userId,
                SystemInfo__c = 'Zero-Trust Security Manager',
                AdditionalInfo__c = buildSecurityEventDetails(context),
                Error_Code__c = eventType,
                Session_ID__c = context?.sessionId,
                Device_Fingerprint__c = context?.deviceId,
                User_Agent__c = context?.userAgent,
                Geographic_Location__c = context?.geoLocation
            );
            insert securityEvent;

            // Create real-time alert for critical events
            if (eventType.contains('FAILED') || eventType.contains('ANOMALOUS') || eventType.contains('SUSPICIOUS')) {
                createSecurityAlert(eventType, userId, documentId, context);
            }

        } catch (Exception e) {
            System.debug('Security event logging error: ' + e.getMessage());
        }
    }

    /**
     * Create real-time security alerts for critical events
     */
    private static void createSecurityAlert(String eventType, String userId, String documentId, SecurityContext context) {
        try {
            SLAViolationAlert__c alert = new SLAViolationAlert__c(
                RecordId__c = documentId,
                Alert_Type__c = 'SECURITY_INCIDENT',
                Severity__c = determineSeverity(eventType),
                Message__c = buildAlertMessage(eventType, userId, documentId, context),
                Timestamp__c = DateTime.now(),
                Status__c = 'OPEN',
                Assigned_To__c = getSecurityManagerId(),
                Auto_Generated__c = true
            );
            insert alert;
// Send immediate notification for critical events
if (alert.Severity__c == 'CRITICAL' || alert.Severity__c == 'HIGH') {
    sendSecurityIncidentNotification(alert, userId, documentId, context);
}
} catch (Exception e) {
    System.debug('Security alert creation error: ' + e.getMessage());
}
}

/**
 * Send immediate security incident notification
 */
private static void sendSecurityIncidentNotification(
    SLAViolationAlert__c alert,
    String userId,
    String documentId,
    SecurityContext context
) {
    try {
        // Get security team members
        List<User> securityTeam = [
            SELECT Id, Email, Name
            FROM User
            WHERE (Profile.Name LIKE '%Security%' OR Profile.Name LIKE '%System Administrator%')
            AND IsActive = true
            LIMIT 5
        ];

        if (securityTeam.isEmpty()) {
            return;
        }

        // Get user details for context
        User targetUser = [
            SELECT Name, Email, Profile.Name
            FROM User
            WHERE Id = :userId
            LIMIT 1
        ];

        // Prepare notification
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (User securityMember : securityTeam) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { securityMember.Email });
            mail.setSubject('SECURITY ALERT: ' + alert.Alert_Type__c + ' - ' + alert.Severity__c);

            String emailBody = buildSecurityNotificationBody(alert, targetUser, documentId, context);
            mail.setPlainTextBody(emailBody);
            mail.setHtmlBody(buildSecurityNotificationHTML(alert, targetUser, documentId, context));

            emails.add(mail);
        }

        // Send notifications
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }

    } catch (Exception e) {
        System.debug('Security notification error: ' + e.getMessage());
    }
}

/**
 * Build detailed security notification body
 */
private static String buildSecurityNotificationBody(
    SLAViolationAlert__c alert,
    User targetUser,
    String documentId,
    SecurityContext context
) {
    StringBuilder body = new StringBuilder();

    body.append('SECURITY INCIDENT DETECTED\n');
    body.append('========================\n\n');

    body.append('Alert Type: ').append(alert.Alert_Type__c).append('\n');
    body.append('Severity: ').append(alert.Severity__c).append('\n');
    body.append('Timestamp: ').append(alert.Timestamp__c.format()).append('\n\n');

    body.append('USER DETAILS:\n');
    body.append('Name: ').append(targetUser.Name).append('\n');
    body.append('Email: ').append(targetUser.Email).append('\n');
    body.append('Profile: ').append(targetUser.Profile.Name).append('\n\n');

    body.append('ACCESS CONTEXT:\n');
    if (context != null) {
        body.append('Session ID: ').append(context.sessionId).append('\n');
        body.append('Device ID: ').append(context.deviceId).append('\n');
        body.append('IP Address: ').append(context.ipAddress).append('\n');
        body.append('Geographic Location: ').append(context.geoLocation).append('\n');
        body.append('User Agent: ').append(context.userAgent).append('\n');
    }

    body.append('Document ID: ').append(documentId).append('\n\n');

    body.append('INCIDENT DETAILS:\n');
    body.append(alert.Message__c).append('\n\n');

    body.append('IMMEDIATE ACTIONS REQUIRED:\n');
    body.append('1. Review user access logs\n');
    body.append('2. Verify user identity if suspicious\n');
    body.append('3. Consider temporary access restriction\n');
    body.append('4. Update security policies if needed\n\n');

    body.append('Alert ID: ').append(alert.Id).append('\n');
    body.append('Please investigate immediately.');

    return body.toString();
}
/**
 * Build detailed HTML security notification
 */
private static String buildSecurityNotificationHTML(
    SLAViolationAlert__c alert,
    User targetUser,
    String documentId,
    SecurityContext context
) {
    String htmlTemplate = 
        '<html><body style="font-family: Arial, sans-serif; color: #333;">' +
            '<div style="background-color: #ff4444; color: white; padding: 15px; border-radius: 5px; margin-bottom: 20px;">' +
                '<h2 style="margin: 0;">🚨 SECURITY INCIDENT DETECTED</h2>' +
            '</div>' +

            '<table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">' +
                '<tr>' +
                    '<td style="padding: 10px; border: 1px solid #ddd; background-color: #f9f9f9; font-weight: bold;">Alert Type:</td>' +
                    '<td style="padding: 10px; border: 1px solid #ddd;">' + alert.Alert_Type__c + '</td>' +
                '</tr>' +
                '<tr>' +
                    '<td style="padding: 10px; border: 1px solid #ddd; background-color: #f9f9f9; font-weight: bold;">Severity:</td>' +
                    '<td style="padding: 10px; border: 1px solid #ddd; color: #ff4444; font-weight: bold;">' + alert.Severity__c + '</td>' +
                '</tr>' +
                '<tr>' +
                    '<td style="padding: 10px; border: 1px solid #ddd; background-color: #f9f9f9; font-weight: bold;">User:</td>' +
                    '<td style="padding: 10px; border: 1px solid #ddd;">' + targetUser.Name + ' (' + targetUser.Email + ')</td>' +
                '</tr>' +
                '<tr>' +
                    '<td style="padding: 10px; border: 1px solid #ddd; background-color: #f9f9f9; font-weight: bold;">Document:</td>' +
                    '<td style="padding: 10px; border: 1px solid #ddd;">' + documentId + '</td>' +
                '</tr>' +
            '</table>' +

            '<div style="background-color: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin-bottom: 20px;">' +
                '<h3 style="margin-top: 0;">Incident Details:</h3>' +
                '<p>' + alert.Message__c + '</p>' +
            '</div>' +

            '<div style="background-color: #d4edda; border: 1px solid #c3e6cb; padding: 15px; border-radius: 5px;">' +
                '<h3 style="margin-top: 0;">Immediate Actions Required:</h3>' +
                '<ul>' +
                    '<li>Review user access logs immediately</li>' +
                    '<li>Verify user identity if behavior is suspicious</li>' +
                    '<li>Consider implementing temporary access restrictions</li>' +
                    '<li>Update security policies if needed</li>' +
                '</ul>' +
            '</div>' +

            '<p style="margin-top: 20px; font-size: 12px; color: #666;">Alert ID: ' + alert.Id + '</p>' +
        '</body></html>';

    return htmlTemplate;
}

/**
 * Check if a session is compromised
 */
private static Boolean isSessionCompromised(
    AuthSession session,
    SecurityContext context
) {
    // Check for session anomalies
    if (session.LoginType != 'Application' && session.SessionType != 'Oauth2') {
        return true;
    }

    // Check for impossible travel (rough implementation)
    if (String.isNotBlank(context.geoLocation)) {
        // Would integrate with geolocation service in real implementation
        return false; // Placeholder
    }

    return false;
}

/**
 * Invalidate a user session
 */
private static void invalidateSession(
    String sessionId
) {
    try {
        // In a real implementation, this would call Salesforce APIs
        System.debug('Invalidating session: ' + sessionId);
    } catch (Exception e) {
        System.debug('Session invalidation error: ' + e.getMessage());
    }
}

/**
 * Detect suspicious concurrent access
 */
private static Boolean detectSuspiciousConcurrentAccess(
    List<AuthSession> sessions,
    SecurityContext context
) {
    if (sessions.size() > 3) {
        // More than 3 concurrent sessions
        return true;
    }

    // Check for sessions from different geographic regions
    // This would be enhanced with actual geolocation data
    return false;
}
// Create a pending trusted device record for user verification
private static void createPendingDeviceVerification(String deviceId, String userId) {
    try {
        TrustedDevice__c pendingDevice = new TrustedDevice__c(
            Device_Id__c              = deviceId,
            User_Id__c                = userId,
            Trust_Level__c            = 'PENDING_VERIFICATION',
            Risk_Score__c             = 50,
            First_Seen__c             = DateTime.now(),
            Last_Verified__c          = DateTime.now(),
            Is_Active__c              = true,
            Verification_Required__c  = true
        );
        insert pendingDevice;

        // Send device verification notification
        sendDeviceVerificationNotification(userId, deviceId);

    } catch (Exception e) {
        System.debug('Pending device creation error: ' + e.getMessage());
    }
}

// Check if IP address is blocked based on defined ranges
private static Boolean isIPBlocked(String ipAddress, List<BlockedIPRange__c> blockedRanges) {
    // Simplified IP blocking check
    for (BlockedIPRange__c range : blockedRanges) {
        if (ipAddress.startsWith(range.IP_Range_Start__c.substring(0, 8))) {
            return true;
        }
    }
    return false;
}

// Check if geographic access is suspicious
private static Boolean isSuspiciousGeographicAccess(String geoLocation) {
    if (geoLocation.contains('Unknown') || geoLocation.contains('Anonymous')) {
        return true;
    }
    return false;
}

// Check if access is from restricted VPN/proxy
private static Boolean isRestrictedVPNAccess(String ipAddress) {
    // Simplified check for common VPN IP ranges
    return ipAddress.startsWith('10.') && !isInternalNetwork(ipAddress);
}

// Check if IP belongs to internal network ranges
private static Boolean isInternalNetwork(String ipAddress) {
    return ipAddress.startsWith('10.0.')
        || ipAddress.startsWith('192.168.')
        || ipAddress.startsWith('172.');
}

// Create baseline behavior metrics for a user
private static void createBehaviorBaseline(String userId, SecurityContext context) {
    try {
        UserBehaviorMetrics__c baseline = new UserBehaviorMetrics__c(
            User_Id__c                = userId,
            Access_Pattern__c         = 'ESTABLISHING_BASELINE',
            Document_Types_Accessed__c = '',
            Average_Session_Duration__c = 0,
            Typical_Access_Hours__c   = String.valueOf(DateTime.now().hour()),
            Behavioral_Score__c       = 50, // Neutral baseline
            Is_Baseline__c            = true,
            Created_Date__c           = DateTime.now()
        );
        insert baseline;

    } catch (Exception e) {
        System.debug('Behavior baseline creation error: ' + e.getMessage());
    }
}
// =====================================================
// METHOD: calculateBehaviorDeviation
// PARAMS: 
//   - recentBehavior (List<UserBehaviorMetrics__c>) 
//   - context (SecurityContext)
// RETURNS: Decimal
// =====================================================
private static Decimal calculateBehaviorDeviation(
    List<UserBehaviorMetrics__c> recentBehavior,
    SecurityContext context
) {
    // Simplified behavior deviation calculation
    Decimal deviationScore = 0;
    
    if (!recentBehavior.isEmpty()) {
        UserBehaviorMetrics__c latestBehavior = recentBehavior[0];
        Integer currentHour = DateTime.now().hour();
        String typicalHours = latestBehavior.Typical_Access_Hours__c;

        // Check if accessing outside typical hours
        if (String.isNotBlank(typicalHours) &&
            !typicalHours.contains(String.valueOf(currentHour))) {
            deviationScore += 20;
        }

        // Add other behavioral checks here
        deviationScore += Math.random() * 10; // Placeholder for complex behavior analysis
    }
    
    return Math.min(deviationScore, 100);
}



// =====================================================
// METHOD: requireBehaviorVerification
// PARAMS: 
//   - userId (String) 
//   - context (SecurityContext)
// RETURNS: Boolean
// =====================================================
private static Boolean requireBehaviorVerification(
    String userId,
    SecurityContext context
) {
    try {
        // Create behavior verification challenge
        BehaviorChallenge__c challenge = new BehaviorChallenge__c(
            User_Id__c       = userId,
            Challenge_Type__c = 'BEHAVIOR_ANOMALY',
            Status__c        = 'PENDING',
            Expiry_Time__c   = DateTime.now().addMinutes(15),
            Session_Id__c    = context.sessionId,
            Created_Date__c  = DateTime.now()
        );
        insert challenge;

        return false; // Deny access until verification
    } catch (Exception e) {
        System.debug('Behavior verification error: ' + e.getMessage());
        return true; // Allow access if verification setup fails
    }
}



// =====================================================
// METHOD: updateBehaviorMetrics
// PARAMS: 
//   - userId (String) 
//   - context (SecurityContext) 
//   - deviationScore (Decimal)
// RETURNS: void
// =====================================================
private static void updateBehaviorMetrics(
    String userId,
    SecurityContext context,
    Decimal deviationScore
) {
    try {
        UserBehaviorMetrics__c metrics = new UserBehaviorMetrics__c(
            User_Id__c                 = userId,
            Access_Pattern__c          = 'NORMAL_ACCESS',
            Document_Types_Accessed__c = '',
            Average_Session_Duration__c = 0,
            Typical_Access_Hours__c    = String.valueOf(DateTime.now().hour()),
            Behavioral_Score__c        = 100 - deviationScore,
            Is_Baseline__c             = false,
            Created_Date__c            = DateTime.now()
        );
        insert metrics;
    } catch (Exception e) {
        System.debug('Behavior metrics update error: ' + e.getMessage());
    }
}



// =====================================================
// METHOD: getRequiredPermission
// PARAMS: 
//   - document (DocumentLifecycleConfiguration__c)
// RETURNS: String
// =====================================================
private static String getRequiredPermission(
    DocumentLifecycleConfiguration__c document
) {
    Map<String, String> classificationPermissions = new Map<String, String>{
        'PUBLIC'       => 'DOCUMENT_USER',
        'INTERNAL'     => 'DOCUMENT_POWER_USER',
        'CONFIDENTIAL' => 'DOCUMENT_ADMIN',
        'RESTRICTED'   => 'DOCUMENT_SUPER_ADMIN'
    };
    
    return classificationPermissions.get(document.Security_Classification__c);
}
// ✅ Check if access is within allowed hours
private static Boolean isWithinAllowedAccessHours(DocumentLifecycleConfiguration__c document) {
    Integer currentHour = DateTime.now().hour();
    if (document.Security_Classification__c == 'RESTRICTED') {
        return currentHour >= 6 && currentHour <= 22; // Business hours only
    }
    return true; // No restrictions for others
}

// ✅ Retrieve user security profile
private static UserSecurityProfile__c getUserSecurityProfile(String userId) {
    try {
        List<UserSecurityProfile__c> profiles = [
            SELECT Risk_Score__c, Security_Clearance__c, Last_Security_Training__c
            FROM UserSecurityProfile__c
            WHERE User_Id__c = :userId AND Is_Active__c = true
            LIMIT 1
        ];
        return profiles.isEmpty() ? null : profiles[0];
    } catch (Exception e) {
        System.debug('Security profile retrieval error: ' + e.getMessage());
        return null;
    }
}

// ✅ Calculate risk score based on security context
private static Decimal calculateContextRisk(SecurityContext context) {
    Decimal contextRisk = 0;

    if (String.isNotBlank(context.geoLocation)) {
        if (context.geoLocation.contains('Unknown') || context.geoLocation.contains('VPN')) {
            contextRisk += 30;
        }
    }

    if (String.isNotBlank(context.userAgent)) {
        if (context.userAgent.contains('Bot') || context.userAgent.contains('Crawler')) {
            contextRisk += 50;
        }
    }

    Integer currentHour = DateTime.now().hour();
    if (currentHour < 6 || currentHour > 22) {
        contextRisk += 10; // Off-hours access
    }

    return Math.min(contextRisk, 100);
}

// ✅ Count recent failed security incidents
private static Integer getRecentSecurityIncidents(String userId) {
    try {
        List<AuditTrail__c> incidents = [
            SELECT Id
            FROM AuditTrail__c
            WHERE UserDetails__c = :userId
              AND Action__c LIKE '%SECURITY%'
              AND Status__c = 'FAILURE'
              AND Timestamp__c >= :DateTime.now().addDays(-30)
        ];
        return incidents.size();
    } catch (Exception e) {
        System.debug('Security incident retrieval error: ' + e.getMessage());
        return 0;
    }
}

// ✅ Generate secure random challenge code
private static String generateSecureChallengeCode() {
    String characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String challengeCode = '';
    for (Integer i = 0; i < 6; i++) {
        challengeCode += characters.substring(
            Math.mod(Math.round(Math.random() * (characters.length() - 1)), characters.length()),
            Math.mod(Math.round(Math.random() * (characters.length() - 1)), characters.length()) + 1
        );
    }
    return challengeCode;
}

// ✅ Send MFA challenge via email
private static void sendMFAChallenge(String userId, String challengeCode) {
    try {
        User user = [SELECT Email, MobilePhone FROM User WHERE Id = :userId LIMIT 1];
        if (String.isNotBlank(user.Email)) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[]{user.Email});
            mail.setSubject('Security Verification Required - DocGen System');
            mail.setPlainTextBody(
                'Your security verification code is: ' + challengeCode +
                '\n\nThis code expires in 10 minutes.' +
                '\n\nIf you did not request this, please contact your system administrator immediately.'
            );
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        }
    } catch (Exception e) {
        System.debug('MFA challenge send error: ' + e.getMessage());
    }
}
// ✅ Send MFA challenge via Email + SMS
private static void sendMFAChallenge(String userId, String challengeCode) {
    try {
        User user = [SELECT Email, MobilePhone FROM User WHERE Id = :userId LIMIT 1];

        // Send email if available
        if (String.isNotBlank(user.Email)) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[]{user.Email});
            mail.setSubject('Security Verification Required - DocGen System');
            mail.setPlainTextBody(
                'Your security verification code is: ' + challengeCode +
                '\n\nThis code expires in 10 minutes.' +
                '\n\nIf you did not request this, please contact your system administrator immediately.'
            );
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        }

        // Also send SMS if mobile phone is available
        if (String.isNotBlank(user.MobilePhone)) {
            // In production, integrate with SMS service
            System.debug('SMS MFA code sent to: ' + user.MobilePhone + ' Code: ' + challengeCode);
        }

    } catch (Exception e) {
        System.debug('MFA challenge sending error: ' + e.getMessage());
    }
}

// ✅ Validate MFA challenge response
private static Boolean validateChallengeResponse(String challengeCode, String response) {
    return challengeCode.equals(response.toUpperCase().trim());
}

// ✅ Lock user account after multiple failed attempts
private static void lockUserAccount(String userId) {
    try {
        UserAccountLock__c lockRecord = new UserAccountLock__c(
            User_Id__c = userId,
            Lock_Reason__c = 'Multiple failed MFA attempts',
            Lock_Start_Time__c = DateTime.now(),
            Lock_End_Time__c = DateTime.now().addMinutes(LOCKOUT_DURATION_MINUTES),
            Is_Active__c = true,
            Lock_Type__c = 'TEMPORARY'
        );
        insert lockRecord;

        // Send account lock notification
        sendAccountLockNotification(userId);

    } catch (Exception e) {
        System.debug('Account lock error: ' + e.getMessage());
    }
}

// ✅ Build security event details JSON
private static String buildSecurityEventDetails(SecurityContext context) {
    if (context == null) return 'No security context available';

    Map<String, Object> details = new Map<String, Object>{
        'sessionId'       => context.sessionId,
        'deviceId'        => context.deviceId,
        'ipAddress'       => context.ipAddress,
        'userAgent'       => context.userAgent,
        'geoLocation'     => context.geoLocation,
        'riskLevel'       => context.riskLevel,
        'lastVerification'=> context.lastVerification
    };

    return JSON.serialize(details);
}

// ✅ Determine severity of a security event
private static String determineSeverity(String eventType) {
    Set<String> criticalEvents = new Set<String>{
        'IDENTITY_VERIFICATION_FAILED',
        'ANOMALOUS_BEHAVIOR_DETECTED',
        'MULTIPLE_FAILED_MFA_ATTEMPTS'
    };

    Set<String> highEvents = new Set<String>{
        'UNTRUSTED_DEVICE_ACCESS',
        'SUSPICIOUS_NETWORK_ACCESS',
        'INSUFFICIENT_PERMISSIONS'
    };

    if (criticalEvents.contains(eventType)) {
        return 'CRITICAL';
    } else if (highEvents.contains(eventType)) {
        return 'HIGH';
    } else {
        return 'MEDIUM';
    }
}
private static String buildAlertMessage(String eventType, String userId, String documentId, SecurityContext context) {
    StringBuilder message = new StringBuilder();
    message.append('Security event detected: ').append(eventType).append('\n');
    message.append('User ID: ').append(userId).append('\n');
    message.append('Document ID: ').append(documentId).append('\n');
    
    if (context != null) {
        message.append('IP Address: ').append(context.ipAddress).append('\n');
        message.append('Device: ').append(context.deviceId).append('\n');
        message.append('Location: ').append(context.geoLocation).append('\n');
    }
    
    return message.toString();
}

private static String getSecurityManagerId() {
    List<User> securityManagers = [
        SELECT Id FROM User 
        WHERE Profile.Name LIKE '%Security%' 
        AND IsActive = true 
        LIMIT 1
    ];
    return securityManagers.isEmpty() ? UserInfo.getUserId() : securityManagers[0].Id;
}

private static void updateLastVerification(String userId, SecurityContext context) {
    try {
        UserSecurityVerification__c verification = new UserSecurityVerification__c(
            User_Id__c = userId,
            Last_Verification__c = DateTime.now(),
            Verification_Type__c = 'ZERO_TRUST_CONTINUOUS',
            Session_Id__c = context.sessionId,
            Device_Id__c = context.deviceId,
            IP_Address__c = context.ipAddress,
            Status__c = 'VERIFIED'
        );
        insert verification;
    } catch (Exception e) {
        System.debug('Verification update error: ' + e.getMessage());
    }
}

private static void sendDeviceVerificationNotification(String userId, String deviceId) {
    try {
        User user = [SELECT Email, Name FROM User WHERE Id = :userId LIMIT 1];
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{user.Email});
        mail.setSubject('New Device Detected - Verification Required');
        mail.setPlainTextBody(
            'Hello ' + user.Name + ',\n\n' +
            'A new device has been detected accessing your account:\n' +
            'Device ID: ' + deviceId + '\n\n' +
            'If this was you, please log in to verify this device.\n' +
            'If this was not you, please contact your system administrator immediately.\n\n' +
            'Thank you,\nDocGen Security Team'
        );
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        
    } catch (Exception e) {
        System.debug('Device verification notification error: ' + e.getMessage());
    }
}

private static void sendAccountLockNotification(String userId) {
    try {
        User user = [SELECT Email, Name FROM User WHERE Id = :userId LIMIT 1];
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{user.Email});
        mail.setSubject('Account Temporarily Locked - Security Protection');
        mail.setPlainTextBody(
            'Hello ' + user.Name + ',\n\n' +
            'Your account has been temporarily locked due to multiple failed authentication attempts.\n\n' +
            'Lockout Duration: ' + LOCKOUT_DURATION_MINUTES + ' minutes\n\n' +
            'This is a security measure to protect your account. If you did not attempt to access your account, ' +
            'please contact your system administrator immediately.\n\n' +
            'The lockout will be automatically lifted after the duration expires.\n\n' +
            'Thank you,\nDocGen Security Team'
        );
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        
    } catch (Exception e) {
        System.debug('Account lock notification error: ' + e.getMessage());
    }
}
/**
 * Public method to check if user account is currently locked
 */
public static Boolean isAccountLocked(String userId) {
    try {
        List<UserAccountLock__c> activeLocks = [
            SELECT Id, Lock_End_Time__c 
            FROM UserAccountLock__c 
            WHERE User_Id__c = :userId 
            AND Is_Active__c = true 
            AND Lock_End_Time__c >= :DateTime.now()
            LIMIT 1
        ];
        
        return !activeLocks.isEmpty();
        
    } catch (Exception e) {
        System.debug('Account lock check error: ' + e.getMessage());
        return false; // Allow access if check fails
    }
}

/**
 * Unlock user account manually (for admin use)
 */
public static void unlockUserAccount(String userId, String reason) {
    try {
        List<UserAccountLock__c> activeLocks = [
            SELECT Id 
            FROM UserAccountLock__c 
            WHERE User_Id__c = :userId 
            AND Is_Active__c = true
        ];
        
        for (UserAccountLock__c lock : activeLocks) {
            lock.Is_Active__c = false;
            lock.Unlock_Reason__c = reason;
            lock.Unlocked_By__c = UserInfo.getUserId();
            lock.Unlock_Time__c = DateTime.now();
        }
        
        if (!activeLocks.isEmpty()) {
            update activeLocks;
            
            // Log unlock event
            logSecurityEvent('ACCOUNT_UNLOCKED', userId, null, null);
        }
        
    } catch (Exception e) {
        System.debug('Account unlock error: ' + e.getMessage());
    }
}

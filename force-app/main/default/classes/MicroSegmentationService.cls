public class MicroSegmentationService {

    /**
     * @description Enforces micro-segmentation policies for a user accessing a resource.
     * @param userId The ID of the User being evaluated.
     * @param resourceId The ID of the resource being accessed.
     * @param action The action being performed (e.g., 'read', 'write').
     * @param context A JSON string containing contextual information (IP, device, etc.).
     * @return SegmentationResult The result of the access evaluation.
     */
    @AuraEnabled
    public static SegmentationResult enforceSegmentation(String userId, String resourceId, String action, String context) {
        try {
            SegmentationResult result = new SegmentationResult();
            result.isAllowed = false;
            result.violations = new List<String>();

            // Step 1: Identify user's micro-segments
            List<UserSegmentMembership__c> userSegments = [
                SELECT MicroSegment__c, MicroSegment__r.SecurityLevel__c,
                       MicroSegment__r.AccessPolicies__c, MicroSegment__r.NetworkZone__c
                FROM UserSegmentMembership__c
                WHERE UserId__c = :userId AND IsActive__c = true
            ];

            if (userSegments.isEmpty()) {
                result.violations.add('User not assigned to any security segment');
                return result;
            }

            // Step 2: Parse request context
            Map<String, Object> requestContext = (Map<String, Object>) JSON.deserializeUntyped(context);

            // Step 3: Evaluate each segment's policies
            Boolean hasValidSegment = false;
            String highestSecurityLevel = 'LOW';

            for (UserSegmentMembership__c membership : userSegments) {
                SegmentValidationResult segmentResult = validateSegmentAccess(
                    membership.MicroSegment__c, resourceId, action, requestContext
                );

                if (segmentResult.isValid) {
                    hasValidSegment = true;
                    // Track highest security level for audit
                    if (compareSecurityLevels(membership.MicroSegment__r.SecurityLevel__c, highestSecurityLevel) > 0) {
                        highestSecurityLevel = membership.MicroSegment__r.SecurityLevel__c;
                    }
                } else {
                    result.violations.addAll(segmentResult.violations);
                }
            }

            // Step 4: Apply network zone restrictions
            if (hasValidSegment) {
                NetworkZoneValidation networkResult = validateNetworkZone(userSegments, requestContext);
                if (!networkResult.isValid) {
                    hasValidSegment = false;
                    result.violations.addAll(networkResult.violations);
                }
            }

            // Step 5: Apply time-based restrictions
            if (hasValidSegment) {
                TimeRestrictionValidation timeResult = validateTimeRestrictions(userSegments, requestContext);
                if (!timeResult.isValid) {
                    hasValidSegment = false;
                    result.violations.addAll(timeResult.violations);
                }
            }

            // Step 6: Apply device restrictions
            if (hasValidSegment) {
                DeviceRestrictionValidation deviceResult = validateDeviceRestrictions(userSegments, requestContext);
                if (!deviceResult.isValid) {
                    hasValidSegment = false;
                    result.violations.addAll(deviceResult.violations);
                }
            }

            result.isAllowed = hasValidSegment;
            result.securityLevel = highestSecurityLevel;
            result.requiresMFA = checkMFARequirement(userSegments, action, highestSecurityLevel);

            // Step 7: Log segmentation decision
            logSegmentationDecision(userId, resourceId, action, result, requestContext);

            // Step 8: Trigger alerts for violations
            if (!result.isAllowed && !result.violations.isEmpty()) {
                triggerSegmentationAlert(userId, resourceId, action, result);
            }

            return result;

        } catch (Exception e) {
            throw new AuraHandledException('Micro-segmentation enforcement failed: ' + e.getMessage());
        }
    }

    private static SegmentValidationResult validateSegmentAccess(String segmentId, String resourceId, String action, Map<String, Object> context) {
        SegmentValidationResult result = new SegmentValidationResult();
        result.violations = new List<String>();

        // Get segment policies
        List<AccessPolicy__c> policies = [
            SELECT ResourceType__c, AllowedActions__c, TimeRestrictions__c,
                   LocationRestrictions__c, DeviceRestrictions__c, RequiresMFA__c
            FROM AccessPolicy__c
            WHERE MicroSegment__c = :segmentId AND IsActive__c = true
        ];

        if (policies.isEmpty()) {
            result.violations.add('No access policies defined for segment');
            result.isValid = false;
            return result;
        }

        // Find applicable policy for resource type
        String resourceType = determineResourceType(resourceId);
        AccessPolicy__c applicablePolicy = null;

        for (AccessPolicy__c policy : policies) {
            if (policy.ResourceType__c == resourceType || policy.ResourceType__c == 'ALL') {
                applicablePolicy = policy;
                break;
            }
        }

        if (applicablePolicy == null) {
            result.violations.add('No policy found for resource type: ' + resourceType);
            result.isValid = false;
            return result;
        }

        // Validate action is allowed
        if (String.isNotBlank(applicablePolicy.AllowedActions__c)) {
            Set<String> allowedActions = new Set<String>(applicablePolicy.AllowedActions__c.split(';'));
            if (!allowedActions.contains(action)) {
                result.violations.add('Action not permitted: ' + action);
                result.isValid = false;
                return result;
            }
        } else {
            result.violations.add('No actions defined for the applicable policy.');
            result.isValid = false;
            return result;
        }


        result.isValid = true;
        result.policy = applicablePolicy;
        return result;
    }

    private static NetworkZoneValidation validateNetworkZone(List<UserSegmentMembership__c> segments, Map<String, Object> context) {
        NetworkZoneValidation result = new NetworkZoneValidation();
        result.isValid = true; // Default to valid
        result.violations = new List<String>();

        String userIPAddress = (String) context.get('ipAddress');
        String userCountry = (String) context.get('country');

        // Get allowed network zones from all segments
        Set<String> allowedZones = new Set<String>();
        for (UserSegmentMembership__c segment : segments) {
            if (String.isNotBlank(segment.MicroSegment__r.NetworkZone__c)) {
                allowedZones.add(segment.MicroSegment__r.NetworkZone__c);
            }
        }

        if (!allowedZones.isEmpty()) {
            // Validate IP address against network zones
            List<NetworkZone__c> validZones = [
                SELECT Id, Name, IPRanges__c, AllowedCountries__c
                FROM NetworkZone__c
                WHERE Name IN :allowedZones AND IsActive__c = true
            ];

            Boolean isInValidZone = false;
            for (NetworkZone__c zone : validZones) {
                if (isIPInRange(userIPAddress, zone.IPRanges__c) || isCountryAllowed(userCountry, zone.AllowedCountries__c)) {
                    isInValidZone = true;
                    break;
                }
            }

            if (!isInValidZone) {
                result.violations.add('Access denied from network zone: ' + userIPAddress);
                result.isValid = false;
                return result;
            }
        }

        return result;
    }

    private static void logSegmentationDecision(String userId, String resourceId, String action, SegmentationResult result, Map<String, Object> context) {
        try {
            SegmentationAuditLog__c log = new SegmentationAuditLog__c();
            log.UserId__c = userId;
            log.ResourceId__c = resourceId;
            log.RequestedAction__c = action;
            log.AccessGranted__c = result.isAllowed;
            log.SecurityLevel__c = result.securityLevel;
            log.Violations__c = String.join(result.violations, '; ');
            log.RequiredMFA__c = result.requiresMFA;
            log.RequestContext__c = JSON.serialize(context);
            // CORRECTED: Replaced markdown link with correct Apex method call
            log.DecisionTimestamp__c = System.now();
            insert log;
        } catch (Exception e) {
            System.debug('Failed to log segmentation decision: ' + e.getMessage());
        }
    }

    // =================================================================================
    // == PLACEHOLDER METHODS - Implement with your own business logic ==
    // =================================================================================
    
    // TODO: Implement your logic to compare security levels (e.g., HIGH > MEDIUM > LOW)
    private static Integer compareSecurityLevels(String level1, String level2) {
        Map<String, Integer> levelWeights = new Map<String, Integer>{'LOW' => 1, 'MEDIUM' => 2, 'HIGH' => 3, 'CRITICAL' => 4};
        Integer weight1 = levelWeights.get(level1 == null ? 'LOW' : level1.toUpperCase());
        Integer weight2 = levelWeights.get(level2 == null ? 'LOW' : level2.toUpperCase());
        if (weight1 == null || weight2 == null) return 0;
        return weight1 - weight2;
    }
    
    // TODO: Implement your logic for time-based access control.
    private static TimeRestrictionValidation validateTimeRestrictions(List<UserSegmentMembership__c> segments, Map<String, Object> context) {
        TimeRestrictionValidation result = new TimeRestrictionValidation();
        result.isValid = true; // Placeholder: Default to valid
        result.violations = new List<String>();
        return result;
    }

    // TODO: Implement your logic for device-based access control.
    private static DeviceRestrictionValidation validateDeviceRestrictions(List<UserSegmentMembership__c> segments, Map<String, Object> context) {
        DeviceRestrictionValidation result = new DeviceRestrictionValidation();
        result.isValid = true; // Placeholder: Default to valid
        result.violations = new List<String>();
        return result;
    }

    // TODO: Implement your logic to determine if MFA is required.
    private static Boolean checkMFARequirement(List<UserSegmentMembership__c> segments, String action, String securityLevel) {
        return false; // Placeholder: Default to not required
    }

    // TODO: Implement your logic to alert security teams of violations.
    private static void triggerSegmentationAlert(String userId, String resourceId, String action, SegmentationResult result) {
        System.debug('SECURITY ALERT: User ' + userId + ' access denied for action ' + action + ' on resource ' + resourceId + '. Violations: ' + String.join(result.violations, ', '));
    }
    
    // TODO: Implement your logic to determine the resource type from its ID.
    private static String determineResourceType(String resourceId) {
        if (String.isNotBlank(resourceId)) {
            try {
                Id recordId = Id.valueOf(resourceId);
                return recordId.getSObjectType().getDescribe().getName();
            } catch (System.StringException e) {
                // Handle cases where the resourceId is not a valid Salesforce ID.
                System.debug('Could not determine SObjectType from resourceId: ' + resourceId + '. Error: ' + e.getMessage());
                return 'UNKNOWN';
            }
        }
        return 'UNKNOWN'; // Placeholder
    }
    
    // TODO: Implement your logic to check if an IP is within a set of ranges.
    private static Boolean isIPInRange(String ipAddress, String ipRanges) {
        return true; // Placeholder: Default to true
    }
    
    // TODO: Implement your logic to check if a country is in an allowed list.
    private static Boolean isCountryAllowed(String country, String allowedCountries) {
        return true; // Placeholder: Default to true
    }

    // =================================================================================
    // == HELPER CLASSES (Inner Classes) ==
    // =================================================================================

    public class SegmentationResult {
        @AuraEnabled public Boolean isAllowed;
        @AuraEnabled public List<String> violations;
        @AuraEnabled public String securityLevel;
        @AuraEnabled public Boolean requiresMFA;
    }

    public class SegmentValidationResult {
        public Boolean isValid;
        public List<String> violations;
        public AccessPolicy__c policy;
    }

    public class NetworkZoneValidation {
        public Boolean isValid;
        public List<String> violations;
    }
    
    // Added missing helper class
    public class TimeRestrictionValidation {
        public Boolean isValid;
        public List<String> violations;
    }

    // Added missing helper class
    public class DeviceRestrictionValidation {
        public Boolean isValid;
        public List<String> violations;
    }
}
public class AuditTrailFallbackQueueable implements Queueable, Database.AllowsCallouts {

    private Map<String, Object> optsMap;
    private String errorMessage;

    /**
     * Main constructor - accepts a Map payload (preferred).
     * Example enqueue: System.enqueueJob(new AuditTrailFallbackQueueable(optsMap, errMsg));
     */
    public AuditTrailFallbackQueueable(Map<String, Object> optsMap, String errorMessage) {
        this.optsMap = (optsMap == null) ? new Map<String, Object>() : optsMap;
        this.errorMessage = errorMessage;
    }

    /**
     * Compatibility constructor - accepts a JSON string (useful when callers have an AuditOptions object).
     * Example enqueue: System.enqueueJob(new AuditTrailFallbackQueueable(JSON.serialize(opts), errMsg));
     */
    public AuditTrailFallbackQueueable(String optsJson, String errorMessage) {
        Map<String, Object> m = new Map<String, Object>();
        if (!String.isBlank(optsJson)) {
            try {
                m = (Map<String, Object>) JSON.deserializeUntyped(optsJson);
            } catch (Exception ex) {
                // Best-effort: if parsing fails, continue with empty map
                System.debug('AuditTrailFallbackQueueable: optsJson parse failed: ' + ex.getMessage());
            }
        }
        this.optsMap = (m == null) ? new Map<String, Object>() : m;
        this.errorMessage = errorMessage;
    }

    /**
     * Executes the fallback audit creation logic.
     * This is designed to never throw exceptions and always handle failures gracefully.
     */
    public void execute(QueueableContext ctx) {
        try {
            AuditTrail__c audit = new AuditTrail__c();

            // ---------------------------
            // Populate core fields (defensive)
            // ---------------------------
            if (optsMap != null) {
                // Common field names expected in optsMap: recordId, action, status, details, metadata
                try { audit.RecordId__c = (String) optsMap.get('recordId'); } catch (Exception e) {}
                try { audit.Action__c   = (String) optsMap.get('action'); } catch (Exception e) {}
                try { audit.Status__c   = (String) optsMap.get('status'); } catch (Exception e) {}

                // Details
                String details;
                try { details = (String) optsMap.get('details'); } catch (Exception e) { details = null; }
                audit.Details__c = String.isBlank(details) ? '' : details;

                // Optional metadata serialization
                Object metaObj = optsMap.get('metadata');
                if (metaObj != null) {
                    try {
                        audit.AdditionalMetadata__c = JSON.serialize(metaObj);
                    } catch (Exception metaEx) {
                        audit.AdditionalMetadata__c =
                            '{ "metadata_serialize_error": "' +
                            String.escapeSingleQuotes(metaEx.getMessage()) +
                            '" }';
                    }
                }
            }

            // Append fallback error information if present
            if (!String.isBlank(errorMessage)) {
                audit.Details__c =
                    String.valueOf(audit.Details__c) + '\n[FALLBACK ERROR] ' + errorMessage;
            }

            // ---------------------------
            // Populate context fields (best-effort)
            // ---------------------------
            try { audit.Timestamp__c = System.now(); } catch (Exception e) {}
            try { audit.UserId__c    = UserInfo.getUserId(); } catch (Exception e) {}
            try { audit.UserName__c  = UserInfo.getName(); } catch (Exception e) {}

            // Defensive defaults for IP / Session fields (field names may vary by org schema)
            try {
                audit.IPAddress__c = String.isBlank(audit.IPAddress__c)
                    ? '0.0.0.0' : audit.IPAddress__c;
            } catch (Exception e) {}

            try {
                audit.SessionId__c = String.isBlank(audit.SessionId__c)
                    ? UserInfo.getSessionId() : audit.SessionId__c;
            } catch (Exception e) {}

            // ---------------------------
            // Insert fallback audit entry (best-effort)
            // ---------------------------
            try {
                insert audit;
            } catch (Exception insertEx) {
                System.debug('AuditTrailFallbackQueueable: insert failed - ' + insertEx.getMessage());
                return; // Nothing more we can do if insert fails
            }

            // ---------------------------
            // Publish platform event for critical events (optional, best-effort)
            // ---------------------------
            try {
                if (audit.Status__c != null && audit.Status__c.toUpperCase() == 'CRITICAL') {
                    // Use a simple platform event payload - field names may vary in the org's event definition
                    AuditTrailEvent__e ev = new AuditTrailEvent__e(
                        RecordId__c  = audit.RecordId__c,
                        Action__c    = audit.Action__c,
                        Status__c    = audit.Status__c,
                        Details__c   = audit.Details__c,
                        Timestamp__c = audit.Timestamp__c
                    );

                    // Publish the event (list overload is safer)
                    EventBus.publish(new List<AuditTrailEvent__e>{ ev });
                }
            } catch (Exception eventEx) {
                System.debug('AuditTrailFallbackQueueable: event publish failed - ' + eventEx.getMessage());
            }

        } catch (Exception e) {
            // Last-resort logging: never throw from a Queueable
            System.debug('AuditTrailFallbackQueueable.execute failed: ' + e.getMessage());
        }
    }
}
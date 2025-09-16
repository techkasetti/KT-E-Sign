public with sharing class DocumentGenerationController {
    /**
     * Create a comprehensive document generation request
     * @param contractType Type of contract (Employment, NDA, SLA)
     * @param region Geographic region (US, EU, APAC)
     * @param role User role (Manager, Employee, Developer, Admin)
     * @param templateId Optional template ID
     * @param additionalRequirements Optional additional requirements
     * @return Document generation request ID
     */
    @AuraEnabled
    public static String createDocumentRequest(String contractType, String region, String role, String templateId, String additionalRequirements) {
        System.debug('Creating document request: Type=' + contractType + ', Region=' + region + ', Role=' + role);
        try {
            // Input validation
            if (String.isBlank(contractType) || String.isBlank(region) || String.isBlank(role)) {
                throw new IllegalArgumentException('Contract type, region, and role are required');
            }
            // Generate AI-powered clause
            String generatedClause = ClauseGenerator.generateClause(region, role, contractType);
            if (String.isBlank(generatedClause)) {
                throw new DocumentGenerationException('Failed to generate document clause');
            }
            // Validate compliance
            Boolean isCompliant = ComplianceChecker.validateClause(generatedClause, region, contractType);
            String complianceStatus = isCompliant ? 'COMPLIANT' : 'REQUIRES_REVIEW';
            // Create document lifecycle configuration
            DocumentLifecycleConfiguration__c docConfig = new DocumentLifecycleConfiguration__c(
                Region__c = region,
                Role__c = role,
                ContractType__c = contractType,
                Clauses__c = generatedClause,
                ComplianceStatus__c = complianceStatus,
                ProcessingStatus__c = 'GENERATED',
                AIProcessingEnabled__c = true,
                CreatedBy__c = UserInfo.getUserId(),
                CreatedDate__c = System.now()
            );
            // Add additional requirements if provided
            if (String.isNotBlank(additionalRequirements)) {
                docConfig.Clauses__c += '\n\nAdditional Requirements:\n' + additionalRequirements;
            }
            insert docConfig;
            // Log successful generation
            logDocumentGeneration(docConfig.Id, contractType, region, role, 'SUCCESS', generatedClause.length());
            System.debug('✓ Document request created with ID: ' + docConfig.Id);
            return docConfig.Id;
        } catch (Exception e) {
            System.debug('✗ Document request creation failed: ' + e.getMessage());
            logDocumentGeneration(null, contractType, region, role, 'ERROR', 0);
            throw new AuraHandledException('Failed to create document request: ' + e.getMessage());
        }
    }

    /**
     * Generate and process complete document with signature request
     * @param configId Document configuration ID
     * @param signerEmail Email of the signer
     * @param signerName Name of the signer
     * @return Map containing document ID and signature request ID
     */
    @AuraEnabled
    public static Map<String, String> generateAndRequestSignature(String configId, String signerEmail, String signerName) {
        System.debug('Generating document and requesting signature: ConfigID=' + configId);
        try {
            // Input validation
            if (String.isBlank(configId) || String.isBlank(signerEmail) || String.isBlank(signerName)) {
                throw new IllegalArgumentException('Configuration ID, signer email, and signer name are required');
            }
            // Validate configuration exists
            List<DocumentLifecycleConfiguration__c> configs = [
                SELECT Id, Region__c, Role__c, ContractType__c, Clauses__c, ComplianceStatus__c
                FROM DocumentLifecycleConfiguration__c
                WHERE Id = :configId
                LIMIT 1
            ];
            if (configs.isEmpty()) {
                throw new IllegalArgumentException('Document configuration not found: ' + configId);
            }
            DocumentLifecycleConfiguration__c config = configs[0];
            // Final compliance check if validation is required
            if (config.ComplianceStatus__c == 'REQUIRES_REVIEW') {
                Boolean finalCompliance = ComplianceChecker.validateClause(config.Clauses__c, config.Region__c, config.ContractType__c);
                if (!finalCompliance) {
                    throw new ComplianceException('Document failed final compliance validation');
                }
                // Update compliance status
                config.ComplianceStatus__c = 'COMPLIANT';
                update config;
            }
            // Initiate signature request
            String signatureRequestId = SignatureRequestController.initiateSignatureRequest(configId, signerEmail, signerName);
            // Update processing status
            config.ProcessingStatus__c = 'SIGNATURE_REQUESTED';
            update config;
            // Return both IDs
            Map<String, String> result = new Map<String, String>{
                'documentId' => configId,
                'signatureRequestId' => signatureRequestId
            };
            System.debug('✓ Document generated and signature requested successfully');
            return result;
        } catch (Exception e) {
            System.debug('✗ Generate and request signature failed: ' + e.getMessage());
            throw new AuraHandledException('Failed to generate document and request signature: ' + e.getMessage());
        }
    }

    /**
     * Get document generation request details
     * @param configId Document configuration ID
     * @return Document details
     */
    @AuraEnabled
    public static Map<String, Object> getDocumentRequest(String configId) {
        System.debug('Retrieving document request: ' + configId);
        try {
            if (String.isBlank(configId)) {
                throw new IllegalArgumentException('Configuration ID is required');
            }
            List<DocumentLifecycleConfiguration__c> configs = [
                SELECT Id, Region__c, Role__c, ContractType__c, Clauses__c,
                       ComplianceStatus__c, ProcessingStatus__c, AIProcessingEnabled__c,
                       CreatedBy__c, CreatedDate__c
                FROM DocumentLifecycleConfiguration__c
                WHERE Id = :configId
                LIMIT 1
            ];
            if (configs.isEmpty()) {
                throw new IllegalArgumentException('Document configuration not found: ' + configId);
            }
            DocumentLifecycleConfiguration__c config = configs[0];
            // Get creator information
            User creator = [
                SELECT Name, Email
                FROM User
                WHERE Id = :config.CreatedBy__c
                LIMIT 1
            ];
  List<Signature_Request__c> signatureRequests = [
    SELECT Id, SignerEmail__c, SignerName__c, Status__c, CompletedDate__c, Created_Date__c
    FROM Signature_Request__c 
    WHERE DocumentId__c = :configId 
    ORDER BY Created_Date__c DESC
];

List<Map<String, Object>> signatureRequestList = new List<Map<String, Object>>();
for (Signature_Request__c sigReq : signatureRequests) {
    signatureRequestList.add(new Map<String, Object>{
        'id' => sigReq.Id,
        'signerEmail' => sigReq.SignerEmail__c,
        'signerName' => sigReq.SignerName__c,
        'status' => sigReq.Status__c,
        'completedDate' => sigReq.CompletedDate__c,
        'createdDate' => sigReq.Created_Date__c
    });
}

// Get compliance analysis
Map<String, Object> complianceAnalysis = ComplianceChecker.getDetailedComplianceAnalysis(
    config.Clauses__c, 
    config.Region__c, 
    config.ContractType__c
);

Map<String, Object> documentDetails = new Map<String, Object>{
    'id' => config.Id,
    'region' => config.Region__c,
    'role' => config.Role__c,
    'contractType' => config.ContractType__c,
    'clauses' => config.Clauses__c,
    'complianceStatus' => config.ComplianceStatus__c,
    'processingStatus' => config.ProcessingStatus__c,
    'aiProcessingEnabled' => config.AIProcessingEnabled__c,
    'createdBy' => creator.Name,
    'createdByEmail' => creator.Email,
    'createdDate' => config.CreatedDate__c,
    'signatureRequests' => signatureRequestList,
    'complianceAnalysis' => complianceAnalysis,
    'clauseWordCount' => config.Clauses__c.split(' ').size(),
    'estimatedReadingTime' => Math.ceil(config.Clauses__c.split(' ').size() / 200.0) // Average reading speed
};

System.debug('✓ Retrieved document request details');
return documentDetails;

} catch (Exception e) {
    System.debug('✗ Failed to retrieve document request: ' + e.getMessage());
    throw new AuraHandledException('Failed to retrieve document request: ' + e.getMessage());
}
}

/**
 * Get list of document generation requests with filtering
 * @param regionFilter Optional region filter
 * @param statusFilter Optional status filter
 * @param contractTypeFilter Optional contract type filter
 * @return List of document requests
 */
@AuraEnabled
public static List<Map<String, Object>> getDocumentRequests(String regionFilter, String statusFilter, String contractTypeFilter) {
System.debug('Retrieving document requests with filters');
try {
    String query = 'SELECT Id, Region__c, Role__c, ContractType__c, ComplianceStatus__c, ' +
                   'ProcessingStatus__c, CreatedDate__c, CreatedBy__c ' +
                   'FROM DocumentLifecycleConfiguration__c WHERE Id != null';
    
    List<String> whereConditions = new List<String>();
    
    if (String.isNotBlank(regionFilter) && !regionFilter.equals('All')) {
        whereConditions.add('Region__c = :regionFilter');
    }
    
    if (String.isNotBlank(statusFilter) && !statusFilter.equals('All')) {
        whereConditions.add('ProcessingStatus__c = :statusFilter');
    }
    
    if (String.isNotBlank(contractTypeFilter) && !contractTypeFilter.equals('All')) {
        whereConditions.add('ContractType__c = :contractTypeFilter');
    }
    
    if (!whereConditions.isEmpty()) {
        query += ' AND ' + String.join(whereConditions, ' AND ');
    }
    
    query += ' ORDER BY CreatedDate__c DESC LIMIT 100';
    
    List<DocumentLifecycleConfiguration__c> configs = Database.query(query);
    
    // Get creator names in bulk
    Set<Id> creatorIds = new Set<Id>();
    for (DocumentLifecycleConfiguration__c config : configs) {
        creatorIds.add(config.CreatedBy__c);
    }
    
    Map<Id, User> creators = new Map<Id, User>([
        SELECT Id, Name 
        FROM User 
        WHERE Id IN :creatorIds
    ]);
    
    List<Map<String, Object>> requestList = new List<Map<String, Object>>();
    for (DocumentLifecycleConfiguration__c config : configs) {
        String creatorName = creators.containsKey(config.CreatedBy__c) ? 
                            creators.get(config.CreatedBy__c).Name : 'Unknown';
        
        requestList.add(new Map<String, Object>{
            'id' => config.Id,
            'region' => config.Region__c,
            'role' => config.Role__c,
            'contractType' => config.ContractType__c,
            'complianceStatus' => config.ComplianceStatus__c,
            'processingStatus' => config.ProcessingStatus__c,
            'createdDate' => config.CreatedDate__c,
            'createdBy' => creatorName,
            'statusClass' => getProcessingStatusClass(config.ProcessingStatus__c),
            'complianceClass' => getComplianceStatusClass(config.ComplianceStatus__c)
        });
    }
    
    System.debug('✓ Retrieved ' + requestList.size() + ' document requests');
    return requestList;

} catch (Exception e) {
    System.debug('✗ Failed to retrieve document requests: ' + e.getMessage());
    throw new AuraHandledException('Failed to retrieve document requests: ' + e.getMessage());
}
}

/**
 * Update document clauses and revalidate compliance
 * @param configId Document configuration ID
 * @param updatedClauses Updated clause content
 * @return Updated compliance status
 */
@AuraEnabled
public static Map<String, Object> updateDocumentClauses(String configId, String updatedClauses) {
System.debug('Updating document clauses for: ' + configId);
try {
    if (String.isBlank(configId) || String.isBlank(updatedClauses)) {
        throw new IllegalArgumentException('Configuration ID and updated clauses are required');
    }
    
    List<DocumentLifecycleConfiguration__c> configs = [
        SELECT Id, Region__c, Role__c, ContractType__c, Clauses__c, ComplianceStatus__c
        FROM DocumentLifecycleConfiguration__c 
        WHERE Id = :configId 
        LIMIT 1
    ];
    
    if (configs.isEmpty()) {
        throw new IllegalArgumentException('Document configuration not found: ' + configId);
    }
    
    DocumentLifecycleConfiguration__c config = configs[0];
    
    // Store original clauses for audit
    String originalClauses = config.Clauses__c;
    
    // Update clauses
    config.Clauses__c = updatedClauses;
    
    // Revalidate compliance
    Boolean isCompliant = ComplianceChecker.validateClause(updatedClauses, config.Region__c, config.ContractType__c);
    config.ComplianceStatus__c = isCompliant ? 'COMPLIANT' : 'REQUIRES_REVIEW';
    
    update config;
    
    // Log the update
    logClauseUpdate(configId, originalClauses, updatedClauses, config.ComplianceStatus__c);
    
    // Get detailed compliance analysis
    Map<String, Object> complianceAnalysis = ComplianceChecker.getDetailedComplianceAnalysis(
        updatedClauses, 
        config.Region__c, 
        config.ContractType__c
    );
    
    Map<String, Object> result = new Map<String, Object>{
        'success' => true,
        'complianceStatus' => config.ComplianceStatus__c,
        'complianceAnalysis' => complianceAnalysis,
        'updatedDate' => DateTime.now()
    };
    
    System.debug('✓ Document clauses updated successfully');
    return result;

} catch (Exception e) {
    System.debug('✗ Failed to update document clauses: ' + e.getMessage());
    throw new AuraHandledException('Failed to update document clauses: ' + e.getMessage());
}
}

/**
 * Delete document generation request
 * @param configId Document configuration ID
 * @return Success status
 */
@AuraEnabled
public static Boolean deleteDocumentRequest(String configId) {
System.debug('Deleting document request: ' + configId);
try {
    if (String.isBlank(configId)) {
        throw new IllegalArgumentException('Configuration ID is required');
    }
    
    List<DocumentLifecycleConfiguration__c> configs = [
        SELECT Id, ProcessingStatus__c 
        FROM DocumentLifecycleConfiguration__c 
        WHERE Id = :configId 
        LIMIT 1
    ];
    
    if (configs.isEmpty()) {
        throw new IllegalArgumentException('Document configuration not found: ' + configId);
    }
    
    DocumentLifecycleConfiguration__c config = configs[0];
    
    // Check if document has active signature requests
    List<Signature_Request__c> activeSignatureRequests = [
        SELECT Id 
        FROM Signature_Request__c 
        WHERE DocumentId__c = :configId 
        AND Status__c IN ('PENDING', 'SIGNED')
    ];
    
    if (!activeSignatureRequests.isEmpty()) {
        throw new IllegalArgumentException('Cannot delete document with active signature requests');
    }
    
    // Delete associated signature requests first
    List<Signature_Request__c> allSignatureRequests = [
        SELECT Id 
        FROM Signature_Request__c 
        WHERE DocumentId__c = :configId
    ];
    
    if (!allSignatureRequests.isEmpty()) {
        delete allSignatureRequests;
    }
    
    // Log deletion
    logDocumentDeletion(configId, config.ProcessingStatus__c);
    
    // Delete the configuration
    delete config;
    
    System.debug('✓ Document request deleted successfully');
    return true;

} catch (Exception e) {
    System.debug('✗ Failed to delete document request: ' + e.getMessage());
    throw new AuraHandledException('Failed to delete document request: ' + e.getMessage());
}
}

/**
 * Get document generation statistics for dashboard
 * @return Map containing generation statistics
 */
@AuraEnabled
public static Map<String, Object> getGenerationStatistics() {
System.debug('Retrieving document generation statistics');
try {
    Map<String, Object> stats = new Map<String, Object>();
    
    // Overall statistics for last 30 days
    List<AggregateResult> overallStats = [
        SELECT ProcessingStatus__c, COUNT(Id) totalcount
        FROM DocumentLifecycleConfiguration__c 
        WHERE CreatedDate__c = LAST_N_DAYS:30
        GROUP BY ProcessingStatus__c
    ];
    
    Integer totalRequests = 0;
    Integer completedRequests = 0;
    Integer pendingRequests = 0;
    Integer errorRequests = 0;
    
    for (AggregateResult result : overallStats) {
        String status = (String)result.get('ProcessingStatus__c');
        Integer count = (Integer)result.get('count');
        totalRequests += count;
        
        if (status == 'SIGNATURE_COMPLETED') {
            completedRequests += count;
        } else if (status == 'GENERATED' || status == 'SIGNATURE_REQUESTED') {
            pendingRequests += count;
        } else if (status == 'ERROR') {
            errorRequests += count;
        }
    }
    
    // Compliance statistics
    List<AggregateResult> complianceStats = [
        SELECT ComplianceStatus__c, COUNT(Id) totalcount
        FROM DocumentLifecycleConfiguration__c 
        WHERE CreatedDate__c = LAST_N_DAYS:30
        GROUP BY ComplianceStatus__c
    ];
    
    Integer compliantDocs = 0;
    Integer nonCompliantDocs = 0;
    
    for (AggregateResult result : complianceStats) {
        String status = (String)result.get('ComplianceStatus__c');
        Integer count = (Integer)result.get('count');
        
        if (status == 'COMPLIANT') {
            compliantDocs += count;
        } else {
            nonCompliantDocs += count;
        }
    }
    
    Decimal completionRate = totalRequests > 0 ? 
        (Decimal.valueOf(completedRequests) / Decimal.valueOf(totalRequests)) * 100 : 0;
    
    Decimal complianceRate = totalRequests > 0 ? 
        (Decimal.valueOf(compliantDocs) / Decimal.valueOf(totalRequests)) * 100 : 0;
    
    stats.put('totalRequests', totalRequests);
    stats.put('completedRequests', completedRequests);
    stats.put('pendingRequests', pendingRequests);
    stats.put('errorRequests', errorRequests);
    stats.put('completionRate', completionRate);
    stats.put('compliantDocs', compliantDocs);
    stats.put('nonCompliantDocs', nonCompliantDocs);
    stats.put('complianceRate', complianceRate);
    
    // Regional distribution
    List<AggregateResult> regionalStats = [
        SELECT Region__c, COUNT(Id) totalcount
        FROM DocumentLifecycleConfiguration__c 
        WHERE CreatedDate__c = LAST_N_DAYS:30
        GROUP BY Region__c
    ];
    
    Map<String, Integer> regionalDistribution = new Map<String, Integer>();
    for (AggregateResult result : regionalStats) {
        String region = (String)result.get('Region__c');
        Integer count = (Integer)result.get('count');
        regionalDistribution.put(region, count);
    }
    
    stats.put('regionalDistribution', regionalDistribution);
    
    // Contract type distribution
    List<AggregateResult> contractStats = [
        SELECT ContractType__c, COUNT(Id) totalcount
        FROM DocumentLifecycleConfiguration__c 
        WHERE CreatedDate__c = LAST_N_DAYS:30
        GROUP BY ContractType__c
    ];
    
    Map<String, Integer> contractDistribution = new Map<String, Integer>();
    for (AggregateResult result : contractStats) {
        String contractType = (String)result.get('ContractType__c');
        Integer count = (Integer)result.get('count');
        contractDistribution.put(contractType, count);
    }
    
    stats.put('contractDistribution', contractDistribution);
    stats.put('lastUpdated', DateTime.now());
    
    System.debug('✓ Generation statistics compiled');
    return stats;

} catch (Exception e) {
    System.debug('✗ Failed to retrieve generation statistics: ' + e.getMessage());
    throw new AuraHandledException('Failed to retrieve generation statistics: ' + e.getMessage());
}
}

// ===================================
// PRIVATE HELPER METHODS
// ===================================

/**
 * Get CSS class for processing status
 */
@TestVisible
private static String getProcessingStatusClass(String status) {
switch on status {
    when 'GENERATED' {
        return 'slds-badge slds-badge_lightest slds-theme_info';
    }
    when 'SIGNATURE_REQUESTED' {
        return 'slds-badge slds-badge_lightest slds-theme_warning';
    }
when 'SIGNATURE_COMPLETED' {
    return 'slds-badge slds-badge_lightest slds-theme_success';
}
when 'ERROR' {
    return 'slds-badge slds-badge_lightest slds-theme_error';
}
when 'CANCELLED' {
    return 'slds-badge slds-badge_lightest slds-theme_offline';
}
when else {
    return 'slds-badge slds-badge_lightest';
}
}
}

/**
 * Get CSS class for compliance status
 */
@TestVisible
private static String getComplianceStatusClass(String status) {
    switch on status {
        when 'COMPLIANT' {
            return 'slds-badge slds-badge_lightest slds-theme_success';
        }
        when 'REQUIRES_REVIEW' {
            return 'slds-badge slds-badge_lightest slds-theme_warning';
        }
        when 'NON_COMPLIANT' {
            return 'slds-badge slds-badge_lightest slds-theme_error';
        }
        when else {
            return 'slds-badge slds-badge_lightest';
        }
    }
}

/**
 * Log document generation activity
 */
@TestVisible
private static void logDocumentGeneration(String configId, String contractType, String region, String role, String status, Integer clauseLength) {
    try {
        AuditTrail__c auditLog = new AuditTrail__c(
            Action__c = 'DOCUMENT_GENERATION',
            Status__c = status,
            Timestamp__c = DateTime.now(),
            UserDetails__c = UserInfo.getName() + ' (' + UserInfo.getUsername() + ')',
            SystemInfo__c = 'Document generated - Type: ' + contractType + ', Region: ' + region + ', Role: ' + role,
            AdditionalData__c = JSON.serialize(new Map<String, Object>{
                'configId' => configId,
                'contractType' => contractType,
                'region' => region,
                'role' => role,
                'clauseLength' => clauseLength,
                'timestamp' => DateTime.now().format(),
                'userId' => UserInfo.getUserId()
            })
        );
        insert auditLog;
    } catch (Exception e) {
        System.debug('⚠ Could not log document generation: ' + e.getMessage());
    }
}

/**
 * Log clause update activity
 */
@TestVisible
private static void logClauseUpdate(String configId, String originalClauses, String updatedClauses, String complianceStatus) {
    try {
        AuditTrail__c auditLog = new AuditTrail__c(
            Action__c = 'CLAUSE_UPDATE',
            Status__c = 'SUCCESS',
            Timestamp__c = DateTime.now(),
            UserDetails__c = UserInfo.getName() + ' (' + UserInfo.getUsername() + ')',
            SystemInfo__c = 'Document clauses updated. New compliance status: ' + complianceStatus,
            AdditionalData__c = JSON.serialize(new Map<String, Object>{
                'configId' => configId,
                'originalLength' => originalClauses.length(),
                'updatedLength' => updatedClauses.length(),
                'complianceStatus' => complianceStatus,
                'timestamp' => DateTime.now().format(),
                'userId' => UserInfo.getUserId(),
                'lengthChange' => updatedClauses.length() - originalClauses.length()
            })
        );
        insert auditLog;
    } catch (Exception e) {
        System.debug('⚠ Could not log clause update: ' + e.getMessage());
    }
}

/**
 * Log document deletion activity
 */
@TestVisible
private static void logDocumentDeletion(String configId, String processingStatus) {
    try {
        AuditTrail__c auditLog = new AuditTrail__c(
            Action__c = 'DOCUMENT_DELETION',
            Status__c = 'SUCCESS',
            Timestamp__c = DateTime.now(),
            UserDetails__c = UserInfo.getName() + ' (' + UserInfo.getUsername() + ')',
            SystemInfo__c = 'Document configuration deleted. Status was: ' + processingStatus,
            AdditionalData__c = JSON.serialize(new Map<String, Object>{
                'configId' => configId,
                'processingStatus' => processingStatus,
                'deletedBy' => UserInfo.getUserId(),
                'deletedDate' => DateTime.now().format()
            })
        );
        insert auditLog;
    } catch (Exception e) {
        System.debug('⚠ Could not log document deletion: ' + e.getMessage());
    }
}

/**
 * Custom exception for document generation failures
 */
public class DocumentGenerationException extends Exception {}

/**
 * Custom exception for compliance failures
 */
public class ComplianceException extends Exception {}
}
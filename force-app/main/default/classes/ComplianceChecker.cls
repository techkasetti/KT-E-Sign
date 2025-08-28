public class ComplianceChecker {

    @AuraEnabled
    public static Boolean validateClause(String clause, String region, String contractType) {
        try {
            Boolean isCompliant = performComplianceValidation(clause, region, contractType);
            logComplianceCheck(clause, region, contractType, isCompliant);
            return isCompliant;
        } catch (Exception e) {
            System.debug('Error validating compliance: ' + e.getMessage());
            throw new AuraHandledException('Failed to validate compliance: ' + e.getMessage());
        }
    }

    public Boolean validateClause(String clause) {
        Boolean isCompliant = true;

        try {
            // Log compliance check start
            System.debug('Starting compliance validation for clause');

            // Check minimum length requirement
            if (clause.length() < 50) {
                isCompliant = false;
                System.debug('⚠ Clause too short - minimum 50 characters required');
            }

            // Check for required signature clause
            if (!clause.containsIgnoreCase('signature required')) {
                isCompliant = false;
                System.debug('⚠ Missing required signature clause');
            }

            // Additional compliance checks
            if (!clause.containsIgnoreCase('agreement') && !clause.containsIgnoreCase('contract')) {
                isCompliant = false;
                System.debug('⚠ Document must contain agreement or contract language');
            }

            // Log audit trail
            logComplianceCheck(clause, isCompliant);

            System.debug(isCompliant ? '✓ Compliance validation passed' : '✗ Compliance validation failed');
            return isCompliant;

        } catch (Exception e) {
            System.debug('Error during compliance check: ' + e.getMessage());
            return false;
        }
    }

    private static Boolean performComplianceValidation(String clause, String region, String contractType) {
        Boolean isCompliant = true;

        // Region-specific compliance checks
        if (region == 'EU') {
            if (!clause.containsIgnoreCase('GDPR') && contractType.containsIgnoreCase('Employment')) {
                isCompliant = false;
                System.debug('⚠ GDPR compliance required for EU employment contracts');
            }
        }

        if (region == 'US') {
            if (!clause.containsIgnoreCase('federal') && contractType.containsIgnoreCase('Employment')) {
                System.debug('ℹ US federal law reference recommended');
            }
        }

        // General compliance checks
        if (clause.length() < 50) {
            isCompliant = false;
            System.debug('⚠ Clause too short - minimum 50 characters required');
        }

        if (!clause.containsIgnoreCase('signature required')) {
            isCompliant = false;
            System.debug('⚠ Signature requirement must be explicitly stated');
        }

        return isCompliant;
    }

    private static void logComplianceCheck(String clause, String region, String contractType, Boolean isCompliant) {
        try {
            AuditTrail__c audit = new AuditTrail__c(
                RecordId__c = 'COMPLIANCE_' + System.now().getTime(),
                Action__c = isCompliant ? 'COMPLIANCE_CHECK_PASSED' : 'COMPLIANCE_CHECK_FAILED',
                Status__c = isCompliant ? 'SUCCESS' : 'VIOLATION',
                Details__c = 'Compliance validation for ' + region + ' ' + contractType + ': ' +
                             (isCompliant ? 'PASSED' : 'FAILED'),
                UserId__c = UserInfo.getUserId()
            );
            insert audit;
        } catch (Exception e) {
            System.debug('⚠ Could not log compliance check: ' + e.getMessage());
        }

            private void logComplianceCheck(String clause, Boolean result) {
        try {
            // Create audit record (you may need to create a custom audit object)
            System.debug('Logging compliance check - Result: ' + result);
            System.debug('Clause validated: ' + clause.left(100) + '...');
        } catch (Exception e) {
            System.debug('⚠ Could not log compliance check: ' + e.getMessage());
        }

    }
}

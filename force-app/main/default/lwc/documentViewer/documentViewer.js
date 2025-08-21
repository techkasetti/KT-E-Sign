import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';

// Import Apex methods
import getSignatureRequests from '@salesforce/apex/SignatureRequestController.getSignatureRequests';
import initiateSignatureRequest from '@salesforce/apex/SignatureRequestController.initiateSignatureRequest';
import generatePDF from '@salesforce/apex/DocumentLifecycleDeploymentManager.generatePDF';

// Import fields
import DOCUMENT_TITLE_FIELD from '@salesforce/schema/DocumentLifecycleConfiguration__c.DocumentTitle__c';
import REGION_FIELD from '@salesforce/schema/DocumentLifecycleConfiguration__c.Region__c';
import ROLE_FIELD from '@salesforce/schema/DocumentLifecycleConfiguration__c.Role__c';
import CONTRACT_TYPE_FIELD from '@salesforce/schema/DocumentLifecycleConfiguration__c.ContractType__c';
import PROCESSING_STATUS_FIELD from '@salesforce/schema/DocumentLifecycleConfiguration__c.ProcessingStatus__c';
import COMPLIANCE_STATUS_FIELD from '@salesforce/schema/DocumentLifecycleConfiguration__c.ComplianceStatus__c';
import GENERATED_CLAUSE_FIELD from '@salesforce/schema/DocumentLifecycleConfiguration__c.GeneratedClause__c';
import CREATED_DATE_FIELD from '@salesforce/schema/DocumentLifecycleConfiguration__c.CreatedDate';
import LAST_MODIFIED_DATE_FIELD from '@salesforce/schema/DocumentLifecycleConfiguration__c.LastModifiedDate';

const FIELDS = [
    DOCUMENT_TITLE_FIELD,
    REGION_FIELD,
    ROLE_FIELD,
    CONTRACT_TYPE_FIELD,
    PROCESSING_STATUS_FIELD,
    COMPLIANCE_STATUS_FIELD,
    GENERATED_CLAUSE_FIELD,
    CREATED_DATE_FIELD,
    LAST_MODIFIED_DATE_FIELD
];

export default class DocumentViewer extends LightningElement {
    @api recordId; // DocumentLifecycleConfiguration__c record ID
    @track documentData = {};
    @track signatureRequests = [];
    @track showSignatureModal = false;
    @track modalSignerEmail = '';
    @track modalSignerName = '';
    @track modalMessage = '';
    
    // Wire properties
    wiredSignatureRequestsResult;

    // Signature request columns for datatable
    signatureColumns = [
        { label: 'Signer Name', fieldName: 'SignerName__c', type: 'text' },
        { label: 'Signer Email', fieldName: 'SignerEmail__c', type: 'email' },
        { label: 'Status', fieldName: 'Status__c', type: 'text' },
        { label: 'Requested Date', fieldName: 'CreatedDate', type: 'date' },
        { label: 'Completed Date', fieldName: 'CompletedDate__c', type: 'date' },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'View', name: 'view' },
                    { label: 'Resend', name: 'resend' },
                    { label: 'Cancel', name: 'cancel' }
                ]
            }
        }
    ];

    // Wire document data
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredDocument({ error, data }) {
        if (data) {
            this.documentData = {
                Id: data.id,
                DocumentTitle__c: getFieldValue(data, DOCUMENT_TITLE_FIELD),
                Region__c: getFieldValue(data, REGION_FIELD),
                Role__c: getFieldValue(data, ROLE_FIELD),
                ContractType__c: getFieldValue(data, CONTRACT_TYPE_FIELD),
                ProcessingStatus__c: getFieldValue(data, PROCESSING_STATUS_FIELD),
                ComplianceStatus__c: getFieldValue(data, COMPLIANCE_STATUS_FIELD),
                GeneratedClause__c: getFieldValue(data, GENERATED_CLAUSE_FIELD),
                CreatedDate: getFieldValue(data, CREATED_DATE_FIELD),
                LastModifiedDate: getFieldValue(data, LAST_MODIFIED_DATE_FIELD)
            };
            this.updateDocumentContent();
        } else if (error) {
            this.showToast('Error', 'Failed to load document data', 'error');
            console.error('Error loading document:', error);
        }
    }

    // Wire signature requests
    @wire(getSignatureRequests, { documentId: '$recordId' })
    wiredSignatureRequests(result) {
        this.wiredSignatureRequestsResult = result;
        if (result.data) {
            this.signatureRequests = result.data.map(request => ({
                ...request,
                CreatedDate: new Date(request.CreatedDate).toLocaleDateString(),
                CompletedDate__c: request.CompletedDate__c ? 
                    new Date(request.CompletedDate__c).toLocaleDateString() : null
            }));
        } else if (result.error) {
            console.error('Error loading signature requests:', result.error);
        }
    }

    // Computed properties
    get hasSignatureRequests() {
        return this.signatureRequests && this.signatureRequests.length > 0;
    }

    get formattedCreatedDate() {
        return this.documentData.CreatedDate ? 
            new Date(this.documentData.CreatedDate).toLocaleDateString() : '';
    }

    get formattedModifiedDate() {
        return this.documentData.LastModifiedDate ? 
            new Date(this.documentData.LastModifiedDate).toLocaleDateString() : '';
    }

    get statusVariant() {
        const status = this.documentData.ProcessingStatus__c;
        switch (status) {
            case 'Completed': return 'success';
            case 'Processing': return 'warning';
            case 'Failed': return 'error';
            default: return 'inverse';
        }
    }

    get complianceStatusClass() {
        const status = this.documentData.ComplianceStatus__c;
        if (status === 'Compliant') {
            return 'compliance-success slds-box slds-theme_success';
        } else if (status === 'Violation') {
            return 'compliance-error slds-box slds-theme_error';
        }
        return 'compliance-warning slds-box slds-theme_warning';
    }

    get complianceIcon() {
        const status = this.documentData.ComplianceStatus__c;
        switch (status) {
            case 'Compliant': return 'utility:success';
            case 'Violation': return 'utility:error';
            default: return 'utility:warning';
        }
    }

    get complianceMessage() {
        const status = this.documentData.ComplianceStatus__c;
        switch (status) {
            case 'Compliant': return 'Document meets all compliance requirements.';
            case 'Violation': return 'Document has compliance violations that need attention.';
            case 'Review': return 'Document is under compliance review.';
            default: return '';
        }
    }

    get isModalDisabled() {
        return !this.modalSignerEmail || !this.modalSignerName;
    }

    // Event handlers
    handleRequestSignature() {
        this.showSignatureModal = true;
        this.modalSignerEmail = '';
        this.modalSignerName = '';
        this.modalMessage = '';
    }

    handleCloseModal() {
        this.showSignatureModal = false;
    }

    handleModalEmailChange(event) {
        this.modalSignerEmail = event.target.value;
    }

    handleModalNameChange(event) {
        this.modalSignerName = event.target.value;
    }

    handleModalMessageChange(event) {
        this.modalMessage = event.target.value;
    }

    async handleSendSignatureRequest() {
        try {
            await initiateSignatureRequest({
                documentId: this.recordId,
                signerEmail: this.modalSignerEmail,
                signerName: this.modalSignerName,
                message: this.modalMessage
            });
            
            this.showToast('Success', 'Signature request sent successfully!', 'success');
            this.showSignatureModal = false;
            
            // Refresh signature requests
            return refreshApex(this.wiredSignatureRequestsResult);
            
        } catch (error) {
            this.showToast('Error', error.body.message || 'Failed to send signature request', 'error');
        }
    }

    async handleDownloadPDF() {
        try {
            const pdfData = await generatePDF({ documentId: this.recordId });
            
            // Create and trigger download
            const link = document.createElement('a');
            link.href = 'data:application/pdf;base64,' + pdfData;
            link.download = `${this.documentData.DocumentTitle__c || 'Document'}.pdf`;
            link.click();
            
            this.showToast('Success', 'PDF downloaded successfully!', 'success');
            
        } catch (error) {
            this.showToast('Error', error.body.message || 'Failed to generate PDF', 'error');
        }
    }

    handleViewHistory() {
        // Navigate to audit trail or history page
        this.showToast('Info', 'View History functionality will be implemented', 'info');
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        
        switch (actionName) {
            case 'view':
                this.viewSignatureRequest(row.Id);
                break;
            case 'resend':
                this.resendSignatureRequest(row.Id);
                break;
            case 'cancel':
                this.cancelSignatureRequest(row.Id);
                break;
        }
    }

    viewSignatureRequest(requestId) {
        // Navigate to signature request record
        window.open(`/lightning/r/Signature_Request__c/${requestId}/view`, '_blank');
    }
 async resendSignatureRequest(requestId) {
        try {
            this.showToast('Info', 'Resend functionality will be implemented', 'info');
            // In real implementation, call Apex method
            // await resendSignatureNotification({ requestId });
            // this.showToast('Success', 'Signature request resent successfully!', 'success');
            // return refreshApex(this.wiredSignatureRequestsResult);
        } catch (error) {
            this.showToast(
                'Error',
                error?.body?.message || 'Failed to resend signature request',
                'error'
            );
        }
    }

    // Cancel Signature Request
    async cancelSignatureRequest(requestId) {
        try {
            this.showToast('Info', 'Cancel functionality will be implemented', 'info');
            // In real implementation, call Apex method
            // await cancelSignatureRequest({ requestId });
            // this.showToast('Success', 'Signature request cancelled successfully!', 'success');
            // return refreshApex(this.wiredSignatureRequestsResult);
        } catch (error) {
            this.showToast(
                'Error',
                error?.body?.message || 'Failed to cancel signature request',
                'error'
            );
        }
    }

    // Update document content dynamically
    updateDocumentContent() {
        if (this.documentData?.GeneratedClause__c) {
            requestAnimationFrame(() => {
                const clauseElement = this.template.querySelector('.clause-text');
                if (clauseElement) {
                    clauseElement.innerHTML = this.formatDocumentText(
                        this.documentData.GeneratedClause__c
                    );
                }
            });
        }
    }

    // Format text with styling
    formatDocumentText(text) {
        return text
            .replace(/\n/g, '<br>')
            .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
            .replace(/\*(.*?)\*/g, '<em>$1</em>');
    }

    // Toast Helper
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(evt);
    }
}
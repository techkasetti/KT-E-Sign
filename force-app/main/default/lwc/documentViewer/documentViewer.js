import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getSignatureRequests from '@salesforce/apex/SignatureRequestController.getSignatureRequests';
import initiateSignatureRequest from '@salesforce/apex/SignatureRequestController.initiateSignatureRequest';

// Define fields to retrieve
const DOCUMENT_FIELDS = [
    'DocumentLifecycleConfiguration__c.Id',
    'DocumentLifecycleConfiguration__c.Region__c',
    'DocumentLifecycleConfiguration__c.Role__c',
    'DocumentLifecycleConfiguration__c.ContractType__c',
    'DocumentLifecycleConfiguration__c.ComplianceStatus__c',
    'DocumentLifecycleConfiguration__c.CreatedDate',
    'DocumentLifecycleConfiguration__c.LastModifiedDate'
];

export default class DocumentViewer extends LightningElement {
    @api recordId; // Document Configuration ID
    
    // Document data
    @track documentContent = '';
    @track documentStatus = 'Draft';
    @track createdDate = '';
    @track lastModifiedDate = '';
    
    // Signature data
    @track signatureRequests = [];
    @track selectedRequestId = '';
    @track showSignatureModal = false;
    
    // Loading states
    @track isLoading = false;
    @track isSignatureDisabled = false;
    
    // Wire document data
    @wire(getRecord, { recordId: '$recordId', fields: DOCUMENT_FIELDS })
    wiredDocument({ error, data }) {
        if (data) {
            this.processDocumentData(data);
        } else if (error) {
            this.showToast('Error', 'Failed to load document: ' + error.body?.message, 'error');
        }
    }
    
    // Wire signature requests
    @wire(getSignatureRequests)
    wiredSignatureRequests({ error, data }) {
        if (data) {
            this.processSignatureRequests(data);
        } else if (error) {
            this.showToast('Error', 'Failed to load signature requests: ' + error.body?.message, 'error');
        }
    }
    
    // Computed properties
    get documentId() {
        return this.recordId ? this.recordId.substring(0, 15) : '';
    }
    
    get statusVariant() {
        switch (this.documentStatus.toLowerCase()) {
            case 'completed': return 'success';
            case 'pending': return 'warning';
            case 'draft': return 'inverse';
            default: return 'neutral';
        }
    }
    
    get hasSignatureRequests() {
        return this.signatureRequests.length > 0;
    }
    
    // Data processing methods
    processDocumentData(data) {
        const region = getFieldValue(data, 'DocumentLifecycleConfiguration__c.Region__c');
        const role = getFieldValue(data, 'DocumentLifecycleConfiguration__c.Role__c');
        const contractType = getFieldValue(data, 'DocumentLifecycleConfiguration__c.ContractType__c');
        const complianceStatus = getFieldValue(data, 'DocumentLifecycleConfiguration__c.ComplianceStatus__c');
        
        // Generate document content based on configuration
        this.documentContent = this.generateDocumentContent(region, role, contractType);
        this.documentStatus = complianceStatus || 'Draft';
        
        const createdDate = getFieldValue(data, 'DocumentLifecycleConfiguration__c.CreatedDate');
        const lastModifiedDate = getFieldValue(data, 'DocumentLifecycleConfiguration__c.LastModifiedDate');
        
        this.createdDate = createdDate ? new Date(createdDate).toLocaleString() : '';
        this.lastModifiedDate = lastModifiedDate ? new Date(lastModifiedDate).toLocaleString() : '';
    }
    
    processSignatureRequests(data) {
        this.signatureRequests = data.map(request => ({
            ...request,
            statusVariant: this.getSignatureStatusVariant(request.Status__c)
        }));
    }
    
    generateDocumentContent(region, role, contractType) {
        return `
            <h2>${contractType} Agreement</h2>
            <p><strong>Region:</strong> ${region}</p>
            <p><strong>Role:</strong> ${role}</p>
            <p><strong>Generated:</strong> ${new Date().toLocaleDateString()}</p>
            
            <h3>Terms and Conditions</h3>
            <p>This document contains the standard ${contractType.toLowerCase()} terms and conditions 
            applicable for ${role} positions in the ${region} region.</p>
            
            <p>All parties are required to review and sign this document electronically.</p>
            
            <div style="margin-top: 20px; padding: 10px; border: 1px solid #ccc;">
                <strong>Signature Required</strong><br>
                Electronic signature is legally binding and equivalent to handwritten signature.
            </div>
        `;
    }

    getSignatureStatusVariant(status) {
        switch (status?.toLowerCase()) {
            case 'signed': return 'success';
            case 'pending': return 'warning';
            case 'rejected': return 'error';
            default: return 'neutral';
        }
    }

    // Event handlers
    async handleRequestSignature() {
        try {
            this.isLoading = true;
            const requestId = await initiateSignatureRequest({
                documentId: this.recordId,
                signerEmail: 'example@company.com', // In production, get from user input
                signerName: 'Document Signer'
            });
            
            this.selectedRequestId = requestId;
            this.showSignatureModal = true;
            this.showToast('Success', 'Signature request created successfully!', 'success');
        } catch (error) {
            this.showToast('Error', 'Failed to request signature: ' + error.body?.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    handleDownloadPDF() {
        // In production, implement actual PDF generation and download
        this.showToast('Info', 'PDF download functionality to be implemented', 'info');
    }
    
    handleViewHistory() {
        // Navigate to audit trail or history view
        this.showToast('Info', 'History view functionality to be implemented', 'info');
    }
    
    handleSignatureComplete(event) {
        this.showSignatureModal = false;
        this.showToast('Success', 'Signature completed successfully!', 'success');
        
        // Refresh signature requests
        return refreshApex(this.wiredSignatureRequests);
    }
    
    handleModalCancel() {
        this.showSignatureModal = false;
    }
    
    // Utility method
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}

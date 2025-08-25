// Developer_build_step_by_step_impl_e_sign v6.............................................................



// import { LightningElement, api, track, wire } from &#39;lwc&#39;;
// import { ShowToastEvent } from &#39;lightning/platformShowToastEvent&#39;;
// import { getRecord, getFieldValue } from &#39;lightning/uiRecordApi&#39;;
// import { refreshApex } from &#39;@salesforce/apex&#39;;
// import { NavigationMixin } from
// import { NavigationMixin } from 'lightning/navigation';

// // Import Apex methods
// import getDocumentWithSignatureRequests from '@salesforce/apex/DocumentLifecycleDeploymentManager.getDocumentWithSignatureRequests';
// import initiateSignatureRequest from '@salesforce/apex/SignatureRequestController.initiateSignatureRequest';
// import getDocumentAuditTrail from '@salesforce/apex/AuditTrailManager.getDocumentAuditTrail';

// // Document fields
// const DOCUMENT_FIELDS = [
//     'DocumentLifecycleConfiguration__c.Id',
//     'DocumentLifecycleConfiguration__c.DocumentTitle__c',
//     'DocumentLifecycleConfiguration__c.ContractType__c',
//     'DocumentLifecycleConfiguration__c.Region__c',
//     'DocumentLifecycleConfiguration__c.Role__c',
//     'DocumentLifecycleConfiguration__c.GeneratedClause__c',
//     'DocumentLifecycleConfiguration__c.ComplianceStatus__c',
//     'DocumentLifecycleConfiguration__c.ProcessingStatus__c',
//     'DocumentLifecycleConfiguration__c.CreatedDate'
// ];

// export default class DocumentViewer extends NavigationMixin(LightningElement) {
//     @api recordId; // Document ID
    
//     // Data properties
//     @track documentData = null;
//     @track signatureRequests = [];
//     @track auditTrail = [];
    
//     // Modal properties
//     @track showSignatureModal = false;
//     @track modalSignerEmail = '';
//     @track modalSignerName = '';
//     @track modalMessage = '';
    
//     // UI state
//     @track isLoading = true;
//     @track hasError = false;
//     @track errorMessage = '';
//     @track showDocumentContent = false;
    
//     // Wire to get document data
//     @wire(getRecord, { recordId: '$recordId', fields: DOCUMENT_FIELDS })
//     documentRecord({ error, data }) {
//         if (data) {
//             this.documentData = data.fields;
//             this.hasError = false;
//             this.loadSignatureRequests();
//         } else if (error) {
//             this.hasError = true;
//             this.errorMessage = 'Failed to load document: ' + error.body?.message;
//             this.isLoading = false;
//         }
//     }
    
//     // Computed properties
//     get hasSignatureRequests() {
//         return this.signatureRequests && this.signatureRequests.length > 0;
//     }
    
//     get signatureRequestColumns() {
//         return [
//             {
//                 label: 'Request #',
//                 fieldName: 'Name',
//                 type: 'text'
//             },
//             {
//                 label: 'Signer Name',
//                 fieldName: 'SignerName__c',
//                 type: 'text'
//             },
//             {
//                 label: 'Signer Email',
//                 fieldName: 'SignerEmail__c',
//                 type: 'email'
//             },
//             {
//                 label: 'Status',
//                 fieldName: 'Status__c',
//                 type: 'text',
//                 cellAttributes: {
//                     class: { fieldName: 'statusClass' }
//                 }
//             },
//             {
//                 label: 'Created Date',
//                 fieldName: 'CreatedDate',
//                 type: 'date',
//                 typeAttributes: {
//                     year: 'numeric',
//                     month: 'short',
//                     day: 'numeric',
//                     hour: '2-digit',
//                     minute: '2-digit'
//                 }
//             },
//             {
//                 type: 'action',
//                 typeAttributes: {
//                     rowActions: [
//                         { label: 'View', name: 'view' },
//                         { label: 'Resend', name: 'resend' },
//                         { label: 'Cancel', name: 'cancel' }
//                     ]
//                 }
//             }
//         ];
//     }
    
//     get formattedCreatedDate() {
//         if (this.documentData?.CreatedDate?.value) {
//             return new Date(this.documentData.CreatedDate.value).toLocaleDateString();
//         }
//         return '';
//     }
    
//     get complianceIcon() {
//         const status = this.documentData?.ComplianceStatus__c?.value;
//         switch (status) {
//             case 'Compliant':
//                 return 'utility:success';
//             case 'Non-Compliant':
//                 return 'utility:error';
//             default:
//                 return 'utility:warning';
//         }
//     }
    
//     get complianceStatusClass() {
//         const status = this.documentData?.ComplianceStatus__c?.value;
//         switch (status) {
//             case 'Compliant':
//                 return 'slds-text-color_success';
//             case 'Non-Compliant':
//                 return 'slds-text-color_error';
//             default:
//                 return 'slds-text-color_default';
//         }
//     }
    
//     get complianceScore() {
//         // This would typically come from a custom field
//         // For now, return a mock score based on compliance status
//         const status = this.documentData?.ComplianceStatus__c?.value;
//         switch (status) {
//             case 'Compliant':
//                 return '95';
//             case 'Non-Compliant':
//                 return '45';
//             default:
//                 return '75';
//         }
//     }
    
//     get isModalDisabled() {
//         return !this.modalSignerEmail || !this.modalSignerName;
//     }
    
//     // Data loading methods
//     async loadSignatureRequests() {
//         try {
//             const result = await getDocumentWithSignatureRequests({
//                 documentId: this.recordId
//             });
            
//             if (result && result.signatureRequests) {
//                 // Add status styling classes
//                 this.signatureRequests = result.signatureRequests.map(request => ({
//                     ...request,
//                     statusClass: this.getStatusClass(request.Status__c)
//                 }));
//             }
//         } catch (error) {
//             console.error('Failed to load signature requests:', error);
//         } finally {
//             this.isLoading = false;
//         }
//     }
    
//     getStatusClass(status) {
//         switch (status) {
//             case 'Signed':
//             case 'Completed':
//                 return 'slds-text-color_success';
//             case 'Pending':
//                 return 'slds-text-color_default';
//             case 'Rejected':
//                 return 'slds-text-color_error';
//             default:
//                 return 'slds-text-color_weak';
//         }
//     }
    
//     // Event handlers
//     handleRequestSignature() {
//         this.showSignatureModal = true;
//     }
    
//     handleDownloadPDF() {
//         // Navigate to the document record's download URL
//         // This is a simplified implementation
//         const documentTitle = this.documentData?.DocumentTitle__c?.value || 'Document';
//         this.showToast('Info', `PDF download for "${documentTitle}" initiated`, 'info');
        
//         // In a real implementation, you would:
//         // 1. Call an Apex method to generate PDF
//         // 2. Return a download URL or blob
//         // 3. Trigger browser download
//     }
    
//     async handleViewAuditTrail() {
//         try {
//             const auditData = await getDocumentAuditTrail({
//                 documentId: this.recordId
//             });
            
//             // Navigate to audit trail view or show in modal
//             this.showToast('Info', `Audit trail contains ${auditData.length} entries`, 'info');
            
//             // In a full implementation, you would show audit trail in a modal or navigate to a detail page
//         } catch (error) {
//             this.showToast('Error', 'Failed to load audit trail: ' + error.body?.message, 'error');
//         }
//     }
    
//     handleRowAction(event) {
//         const actionName = event.detail.action.name;
//         const row = event.detail.row;
        
//         switch (actionName) {
//             case 'view':
//                 this.navigateToSignatureRequest(row.Id);
//                 break;
//             case 'resend':
//                 this.resendSignatureRequest(row.Id);
//                 break;
//             case 'cancel':
//                 this.cancelSignatureRequest(row.Id);
//                 break;
//         }
//     }
    
//     navigateToSignatureRequest(requestId) {
//         this[NavigationMixin.Navigate]({
//             type: 'standard__recordPage',
//             attributes: {
//                 recordId: requestId,
//                 objectApiName: 'Signature_Request__c',
//                 actionName: 'view'
//             }
//         });
//     }
    
//     async resendSignatureRequest(requestId) {
//         try {
//             // In a full implementation, you would call an Apex method to resend
//             this.showToast('Success', 'Signature request resent successfully', 'success');
//             await this.loadSignatureRequests(); // Refresh data
//         } catch (error) {
//             this.showToast('Error', 'Failed to resend signature request', 'error');
//         }
//     }
    
//     async cancelSignatureRequest(requestId) {
//         try {
//             // In a full implementation, you would call an Apex method to cancel
//             this.showToast('Success', 'Signature request cancelled', 'success');
//             await this.loadSignatureRequests(); // Refresh data
//         } catch (error) {
//             this.showToast('Error', 'Failed to cancel signature request', 'error');
//         }
//     }
    
//     // Modal handlers
//     handleCloseModal() {
//         this.showSignatureModal = false;
//         this.modalSignerEmail = '';
//         this.modalSignerName = '';
//         this.modalMessage = '';
//     }
    
//     handleModalSignerEmailChange(event) {
//         this.modalSignerEmail = event.target.value;
//     }
    
//     handleModalSignerNameChange(event) {
//         this.modalSignerName = event.target.value;
//     }
    
//     handleModalMessageChange(event) {
//         this.modalMessage = event.target.value;
//     }
    
//     async handleSendSignatureRequest() {
//         if (this.isModalDisabled) {
//             this.showToast('Error', 'Please fill in all required fields', 'error');
//             return;
//         }
        
//         try {
//             this.isLoading = true;
            
//             const requestId = await initiateSignatureRequest({
//                 documentId: this.recordId,
//                 signerEmail: this.modalSignerEmail,
//                 signerName: this.modalSignerName
//             });
            
//             this.showToast('Success', 'Signature request sent successfully!', 'success');
//             this.handleCloseModal();
            
//             // Refresh the signature requests list
//             await this.loadSignatureRequests();
            
//         } catch (error) {
//             this.showToast('Error', 'Failed to send signature request: ' + error.body?.message, 'error');
//         } finally {
//             this.isLoading = false;
//         }
//     }
    
//     // Toggle document content visibility
//     toggleDocumentContent() {
//         this.showDocumentContent = !this.showDocumentContent;
//     }
    
//     // Utility method
//     showToast(title, message, variant) {
//         const evt = new ShowToastEvent({
//             title: title,
//             message: message,
//             variant: variant
//         });
//         this.dispatchEvent(evt);
//     }
// }




// Developer_build_step_by_step_impl_e_sign v2..........................................................



// import { LightningElement, track, api, wire } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import { refreshApex } from '@salesforce/apex';
// import getDocumentDetails from '@salesforce/apex/DocumentLifecycleDeploymentManager.getDocumentDetails';
// import getSignatureRequests from '@salesforce/apex/SignatureRequestController.getSignatureRequests';
// import getAuditTrail from '@salesforce/apex/DocumentLifecycleDeploymentManager.getAuditTrail';
// import initiateSignatureRequest from '@salesforce/apex/SignatureRequestController.initiateSignatureRequest';

// export default class DocumentViewer extends LightningElement {
//     // Public properties
//     @api recordId;

//     // Component state
//     @track isLoading = true;
//     @track errorMessage = '';
//     @track documentData = null;
//     @track signatureRequests = [];
//     @track auditTrail = [];

//     // Modal states
//     @track showSignatureModal = false;
//     @track showFullScreenModal = false;
//     @track isSendingRequest = false;

//     // Form data
//     @track newSignatureRequest = {
//         signerEmail: '',
//         signerName: '',
//         message: '',
//         dueDate: ''
//     };

//     // Data table columns for signature requests
//     signatureColumns = [
//         {
//             label: 'Signer Name',
//             fieldName: 'SignerName__c',
//             type: 'text'
//         },
//         {
//             label: 'Signer Email',
//             fieldName: 'SignerEmail__c',
//             type: 'email'
//         },
//         {
//             label: 'Status',
//             fieldName: 'Status__c',
//             type: 'text',
//             cellAttributes: {
//                 class: { fieldName: 'statusClass' }
//             }
//         },
//         {
//             label: 'Created Date',
//             fieldName: 'CreatedDate',
//             type: 'date',
//             typeAttributes: {
//                 year: 'numeric',
//                 month: 'short',
//                 day: '2-digit',
//                 hour: '2-digit',
//                 minute: '2-digit'
//             }
//         },
//         {
//             label: 'Completed Date',
//             fieldName: 'CompletedDate__c',
//             type: 'date',
//             typeAttributes: {
//                 year: 'numeric',
//                 month: 'short',
//                 day: '2-digit',
//                 hour: '2-digit',
//                 minute: '2-digit'
//             }
//         },
//         {
//             type: 'action',
//             typeAttributes: {
//                 rowActions: [
//                     { label: 'View', name: 'view' },
//                     { label: 'Resend', name: 'resend' },
//                     { label: 'Cancel', name: 'cancel' }
//                 ]
//             }
//         }
//     ];

//     // Computed properties
//     get statusVariant() {
//         if (!this.documentData) return 'inverse';
//         switch (this.documentData.ProcessingStatus__c) {
//             case 'Completed': return 'success';
//             case 'In Progress': return 'warning';
//             case 'Draft': return 'inverse';
//             case 'Error': return 'error';
//             default: return 'inverse';
//         }
//     }

//     get complianceStatusClass() {
//         if (!this.documentData?.ComplianceStatus__c) return '';
//         switch (this.documentData.ComplianceStatus__c) {
//             case 'Compliant': return 'compliance-success';
//             case 'Non-Compliant': return 'compliance-error';
//             case 'Review': return 'compliance-warning';
//             default: return '';
//         }
//     }

//     get complianceIconName() {
//         if (!this.documentData?.ComplianceStatus__c) return 'utility:info';
//         switch (this.documentData.ComplianceStatus__c) {
//             case 'Compliant': return 'utility:success';
//             case 'Non-Compliant': return 'utility:error';
//             case 'Review': return 'utility:warning';
//             default: return 'utility:info';
//         }
//     }

//     get complianceIconVariant() {
//         if (!this.documentData?.ComplianceStatus__c) return 'inverse';
//         switch (this.documentData.ComplianceStatus__c) {
//             case 'Compliant': return 'success';
//             case 'Non-Compliant': return 'error';
//             case 'Review': return 'warning';
//             default: return 'inverse';
//         }
//     }

//     get complianceScore() {
//         // Calculate compliance score based on status
//         if (!this.documentData?.ComplianceStatus__c) return null;
//         switch (this.documentData.ComplianceStatus__c) {
//             case 'Compliant': return 100;
//             case 'Non-Compliant': return 25;
//             case 'Review': return 75;
//             default: return 50;
//         }
//     }

//     get hasSignatureRequests() {
//         return this.signatureRequests && this.signatureRequests.length > 0;
//     }

//     get hasAuditTrail() {
//         return this.auditTrail && this.auditTrail.length > 0;
//     }

//     get isSignatureRequestDisabled() {
//         return !this.newSignatureRequest.signerEmail || 
//                !this.newSignatureRequest.signerName || 
//                this.isSendingRequest;
//     }

//     // Lifecycle methods
//     connectedCallback() {
//         this.loadDocumentData();
//     }

//     // Data loading methods
//     async loadDocumentData() {
//         if (!this.recordId) {
//             this.errorMessage = 'No document ID provided';
//             this.isLoading = false;
//             return;
//         }

//         try {
//             await Promise.all([
//                 this.loadDocumentDetails(),
//                 this.loadSignatureRequests(),
//                 this.loadAuditTrail()
//             ]);
//         } catch (error) {
//             this.errorMessage = 'Failed to load document data: ' + (error.body?.message || error.message);
//         } finally {
//             this.isLoading = false;
//         }
//     }

//     async loadDocumentDetails() {
//         try {
//             this.documentData = await getDocumentDetails({ documentId: this.recordId });
//         } catch (error) {
//             throw new Error('Document details: ' + (error.body?.message || error.message));
//         }
//     }

//     async loadSignatureRequests() {
//         try {
//             const requests = await getSignatureRequests({ documentId: this.recordId });
//             this.signatureRequests = requests.map(request => ({
//                 ...request,
//                 statusClass: this.getStatusClass(request.Status__c)
//             }));
//         } catch (error) {
//             console.warn('Failed to load signature requests:', error.message);
//             this.signatureRequests = [];
//         }
//     }

//     async loadAuditTrail() {
//         try {
//             const trail = await getAuditTrail({ documentId: this.recordId });
//             this.auditTrail = trail.map(activity => ({
//                 ...activity,
//                 iconName: this.getActivityIcon(activity.Action__c),
//                 iconVariant: this.getActivityIconVariant(activity.Action__c)
//             }));
//         } catch (error) {
//             console.warn('Failed to load audit trail:', error.message);
//             this.auditTrail = [];
//         }
//     }

//     // Event handlers
//     handleRequestSignature() {
//         this.handleNewSignatureRequest();
//     }

//     handleDownloadPDF() {
//         this.showToast('Info', 'PDF download functionality will be implemented in Phase 6', 'info');
//     }

//     handleViewAuditTrail() {
//         // Scroll to audit trail section
//         const auditSection = this.template.querySelector('.activity-timeline-section');
//         if (auditSection) {
//             auditSection.scrollIntoView({ behavior: 'smooth' });
//         }
//     }

//     handleCloneDocument() {
//         // Navigate to document generator with pre-filled data
//         const cloneEvent = new CustomEvent('clonedocument', {
//             detail: {
//                 region: this.documentData.Region__c,
//                 role: this.documentData.Role__c,
//                 contractType: this.documentData.ContractType__c,
//                 documentTitle: this.documentData.DocumentTitle__c + ' (Copy)'
//             }
//         });
//         this.dispatchEvent(cloneEvent);
//         this.showToast('Info', 'Document data copied for cloning', 'info');
//     }

//     handleCopyContent() {
//         if (this.documentData?.GeneratedClause__c) {
//             navigator.clipboard.writeText(this.documentData.GeneratedClause__c)
//                 .then(() => {
//                     this.showToast('Success', 'Content copied to clipboard', 'success');
//                 })
//                 .catch(() => {
//                     this.showToast('Error', 'Failed to copy content', 'error');
//                 });
//         }
//     }

//     handleFullScreen() {
//         this.showFullScreenModal = true;
//     }

//     handleCloseFullScreen() {
//         this.showFullScreenModal = false;
//     }

//     handleNewSignatureRequest() {
//         this.showSignatureModal = true;
//         this.newSignatureRequest = {
//             signerEmail: '',
//             signerName: '',
//             message: '',
//             dueDate: ''
//         };
//     }

//     handleCloseSignatureModal() {
//         this.showSignatureModal = false;
//     }

//     handleSignatureFormChange(event) {
//         const field = event.target.name;
//         const value = event.target.value;
//         this.newSignatureRequest = {
//             ...this.newSignatureRequest,
//             [field]: value
//         };
//     }

//     async handleSendSignatureRequest() {
//         if (this.isSignatureRequestDisabled) {
//             this.showToast('Error', 'Please fill in all required fields', 'error');
//             return;
//         }

//         this.isSendingRequest = true;
//         try {
//             await initiateSignatureRequest({
//                 documentId: this.recordId,
//                 signerEmail: this.newSignatureRequest.signerEmail,
//                 signerName: this.newSignatureRequest.signerName,
//                 message: this.newSignatureRequest.message,
//                 dueDate: this.newSignatureRequest.dueDate
//             });

//             this.showToast('Success', 'Signature request sent successfully!', 'success');
//             this.handleCloseSignatureModal();
//             await this.loadSignatureRequests(); // Refresh the list
//         } catch (error) {
//             this.showToast('Error', 'Failed to send signature request: ' + (error.body?.message || error.message), 'error');
//         } finally {
//             this.isSendingRequest = false;
//         }
//     }

//     handleSignatureRowAction(event) {
//         const actionName = event.detail.action.name;
//         const row = event.detail.row;

//         switch (actionName) {
//             case 'view':
//                 this.viewSignatureRequest(row.Id);
//                 break;
//             case 'resend':
//                 this.resendSignatureRequest(row.Id);
//                 break;
//             case 'cancel':
//                 this.cancelSignatureRequest(row.Id);
//                 break;
//         }
//     }

//     // Helper methods
//     viewSignatureRequest(requestId) {
//         // Navigate to signature request record
//         this.dispatchEvent(new CustomEvent('viewsignature', {
//             detail: { requestId: requestId }
//         }));
//     }

//     resendSignatureRequest(requestId) {
//         this.showToast('Info', 'Resend functionality will be implemented in Phase 6', 'info');
//     }

//     cancelSignatureRequest(requestId) {
//         this.showToast('Info', 'Cancel functionality will be implemented in Phase 6', 'info');
//     }

//     getStatusClass(status) {
//         switch (status) {
//             case 'Pending': return 'slds-text-color_default';
//             case 'Signed': return 'slds-text-color_success';
//             case 'Rejected': return 'slds-text-color_error';
//             case 'Expired': return 'slds-text-color_weak';
//             default: return 'slds-text-color_default';
//         }
//     }

//     getActivityIcon(action) {
//         switch (action?.toLowerCase()) {
//             case 'created': return 'utility:add';
//             case 'sent': return 'utility:email';
//             case 'viewed': return 'utility:preview';
//             case 'signed': return 'utility:signature';
//             case 'completed': return 'utility:success';
//             case 'rejected': return 'utility:close';
//             default: return 'utility:event';
//         }
//     }

//     getActivityIconVariant(action) {
//         switch (action?.toLowerCase()) {
//             case 'created': return 'brand';
//             case 'sent': return 'brand';
//             case 'viewed': return 'warning';
//             case 'signed': return 'success';
//             case 'completed': return 'success';
//             case 'rejected': return 'error';
//             default: return 'inverse';
//         }
//     }

//     showToast(title, message, variant) {
//         const evt = new ShowToastEvent({
//             title: title,
//             message: message,
//             variant: variant
//         });
//         this.dispatchEvent(evt);
//     }
// }



// Developer_build_step_by_step_impl_e_sign v1................................................................c/analyticsDashboard


// import { LightningElement, api, track, wire } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
// import { refreshApex } from '@salesforce/apex';

// // Import Apex methods
// import getSignatureRequests from '@salesforce/apex/SignatureRequestController.getSignatureRequests';
// import initiateSignatureRequest from '@salesforce/apex/SignatureRequestController.initiateSignatureRequest';
// import generatePDF from '@salesforce/apex/DocumentLifecycleDeploymentManager.generatePDF';

// // Import fields
// import DOCUMENT_TITLE_FIELD from '@salesforce/schema/DocumentLifecycleConfiguration__c.DocumentTitle__c';
// import REGION_FIELD from '@salesforce/schema/DocumentLifecycleConfiguration__c.Region__c';
// import ROLE_FIELD from '@salesforce/schema/DocumentLifecycleConfiguration__c.Role__c';
// import CONTRACT_TYPE_FIELD from '@salesforce/schema/DocumentLifecycleConfiguration__c.ContractType__c';
// import PROCESSING_STATUS_FIELD from '@salesforce/schema/DocumentLifecycleConfiguration__c.ProcessingStatus__c';
// import COMPLIANCE_STATUS_FIELD from '@salesforce/schema/DocumentLifecycleConfiguration__c.ComplianceStatus__c';
// import GENERATED_CLAUSE_FIELD from '@salesforce/schema/DocumentLifecycleConfiguration__c.GeneratedClause__c';
// import CREATED_DATE_FIELD from '@salesforce/schema/DocumentLifecycleConfiguration__c.CreatedDate';
// import LAST_MODIFIED_DATE_FIELD from '@salesforce/schema/DocumentLifecycleConfiguration__c.LastModifiedDate';

// const FIELDS = [
//     DOCUMENT_TITLE_FIELD,
//     REGION_FIELD,
//     ROLE_FIELD,
//     CONTRACT_TYPE_FIELD,
//     PROCESSING_STATUS_FIELD,
//     COMPLIANCE_STATUS_FIELD,
//     GENERATED_CLAUSE_FIELD,
//     CREATED_DATE_FIELD,
//     LAST_MODIFIED_DATE_FIELD
// ];

// export default class DocumentViewer extends LightningElement {
//     @api recordId; // DocumentLifecycleConfiguration__c record ID
//     @track documentData = {};
//     @track signatureRequests = [];
//     @track showSignatureModal = false;
//     @track modalSignerEmail = '';
//     @track modalSignerName = '';
//     @track modalMessage = '';
    
//     // Wire properties
//     wiredSignatureRequestsResult;

//     // Signature request columns for datatable
//     signatureColumns = [
//         { label: 'Signer Name', fieldName: 'SignerName__c', type: 'text' },
//         { label: 'Signer Email', fieldName: 'SignerEmail__c', type: 'email' },
//         { label: 'Status', fieldName: 'Status__c', type: 'text' },
//         { label: 'Requested Date', fieldName: 'CreatedDate', type: 'date' },
//         { label: 'Completed Date', fieldName: 'CompletedDate__c', type: 'date' },
//         {
//             type: 'action',
//             typeAttributes: {
//                 rowActions: [
//                     { label: 'View', name: 'view' },
//                     { label: 'Resend', name: 'resend' },
//                     { label: 'Cancel', name: 'cancel' }
//                 ]
//             }
//         }
//     ];

//     // Wire document data
//     @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
//     wiredDocument({ error, data }) {
//         if (data) {
//             this.documentData = {
//                 Id: data.id,
//                 DocumentTitle__c: getFieldValue(data, DOCUMENT_TITLE_FIELD),
//                 Region__c: getFieldValue(data, REGION_FIELD),
//                 Role__c: getFieldValue(data, ROLE_FIELD),
//                 ContractType__c: getFieldValue(data, CONTRACT_TYPE_FIELD),
//                 ProcessingStatus__c: getFieldValue(data, PROCESSING_STATUS_FIELD),
//                 ComplianceStatus__c: getFieldValue(data, COMPLIANCE_STATUS_FIELD),
//                 GeneratedClause__c: getFieldValue(data, GENERATED_CLAUSE_FIELD),
//                 CreatedDate: getFieldValue(data, CREATED_DATE_FIELD),
//                 LastModifiedDate: getFieldValue(data, LAST_MODIFIED_DATE_FIELD)
//             };
//             this.updateDocumentContent();
//         } else if (error) {
//             this.showToast('Error', 'Failed to load document data', 'error');
//             console.error('Error loading document:', error);
//         }
//     }

//     // Wire signature requests
//     @wire(getSignatureRequests, { documentId: '$recordId' })
//     wiredSignatureRequests(result) {
//         this.wiredSignatureRequestsResult = result;
//         if (result.data) {
//             this.signatureRequests = result.data.map(request => ({
//                 ...request,
//                 CreatedDate: new Date(request.CreatedDate).toLocaleDateString(),
//                 CompletedDate__c: request.CompletedDate__c ? 
//                     new Date(request.CompletedDate__c).toLocaleDateString() : null
//             }));
//         } else if (result.error) {
//             console.error('Error loading signature requests:', result.error);
//         }
//     }

//     // Computed properties
//     get hasSignatureRequests() {
//         return this.signatureRequests && this.signatureRequests.length > 0;
//     }

//     get formattedCreatedDate() {
//         return this.documentData.CreatedDate ? 
//             new Date(this.documentData.CreatedDate).toLocaleDateString() : '';
//     }

//     get formattedModifiedDate() {
//         return this.documentData.LastModifiedDate ? 
//             new Date(this.documentData.LastModifiedDate).toLocaleDateString() : '';
//     }

//     get statusVariant() {
//         const status = this.documentData.ProcessingStatus__c;
//         switch (status) {
//             case 'Completed': return 'success';
//             case 'Processing': return 'warning';
//             case 'Failed': return 'error';
//             default: return 'inverse';
//         }
//     }

//     get complianceStatusClass() {
//         const status = this.documentData.ComplianceStatus__c;
//         if (status === 'Compliant') {
//             return 'compliance-success slds-box slds-theme_success';
//         } else if (status === 'Violation') {
//             return 'compliance-error slds-box slds-theme_error';
//         }
//         return 'compliance-warning slds-box slds-theme_warning';
//     }

//     get complianceIcon() {
//         const status = this.documentData.ComplianceStatus__c;
//         switch (status) {
//             case 'Compliant': return 'utility:success';
//             case 'Violation': return 'utility:error';
//             default: return 'utility:warning';
//         }
//     }

//     get complianceMessage() {
//         const status = this.documentData.ComplianceStatus__c;
//         switch (status) {
//             case 'Compliant': return 'Document meets all compliance requirements.';
//             case 'Violation': return 'Document has compliance violations that need attention.';
//             case 'Review': return 'Document is under compliance review.';
//             default: return '';
//         }
//     }

//     get isModalDisabled() {
//         return !this.modalSignerEmail || !this.modalSignerName;
//     }

//     // Event handlers
//     handleRequestSignature() {
//         this.showSignatureModal = true;
//         this.modalSignerEmail = '';
//         this.modalSignerName = '';
//         this.modalMessage = '';
//     }

//     handleCloseModal() {
//         this.showSignatureModal = false;
//     }

//     handleModalEmailChange(event) {
//         this.modalSignerEmail = event.target.value;
//     }

//     handleModalNameChange(event) {
//         this.modalSignerName = event.target.value;
//     }

//     handleModalMessageChange(event) {
//         this.modalMessage = event.target.value;
//     }

//     async handleSendSignatureRequest() {
//         try {
//             await initiateSignatureRequest({
//                 documentId: this.recordId,
//                 signerEmail: this.modalSignerEmail,
//                 signerName: this.modalSignerName,
//                 message: this.modalMessage
//             });
            
//             this.showToast('Success', 'Signature request sent successfully!', 'success');
//             this.showSignatureModal = false;
            
//             // Refresh signature requests
//             return refreshApex(this.wiredSignatureRequestsResult);
            
//         } catch (error) {
//             this.showToast('Error', error.body.message || 'Failed to send signature request', 'error');
//         }
//     }

//     async handleDownloadPDF() {
//         try {
//             const pdfData = await generatePDF({ documentId: this.recordId });
            
//             // Create and trigger download
//             const link = document.createElement('a');
//             link.href = 'data:application/pdf;base64,' + pdfData;
//             link.download = `${this.documentData.DocumentTitle__c || 'Document'}.pdf`;
//             link.click();
            
//             this.showToast('Success', 'PDF downloaded successfully!', 'success');
            
//         } catch (error) {
//             this.showToast('Error', error.body.message || 'Failed to generate PDF', 'error');
//         }
//     }

//     handleViewHistory() {
//         // Navigate to audit trail or history page
//         this.showToast('Info', 'View History functionality will be implemented', 'info');
//     }

//     handleRowAction(event) {
//         const actionName = event.detail.action.name;
//         const row = event.detail.row;
        
//         switch (actionName) {
//             case 'view':
//                 this.viewSignatureRequest(row.Id);
//                 break;
//             case 'resend':
//                 this.resendSignatureRequest(row.Id);
//                 break;
//             case 'cancel':
//                 this.cancelSignatureRequest(row.Id);
//                 break;
//         }
//     }

//     viewSignatureRequest(requestId) {
//         // Navigate to signature request record
//         window.open(`/lightning/r/Signature_Request__c/${requestId}/view`, '_blank');
//     }


                        
// async resendSignatureRequest(requestId) {
//     try {
//         // Implementation for resending signature request
//         this.showToast(&#39;Info&#39;, &#39;Resend functionality will be implemented&#39;, &#39;info&#39;);
//         // In real implementation, call Apex method to resend notification
//         // await resendSignatureNotification({ requestId: requestId });
//         // this.showToast(&#39;Success&#39;, &#39;Signature request resent successfully!&#39;, &#39;success&#39;);
//         // return refreshApex(this.wiredSignatureRequestsResult);
//     } catch (error) {
//         this.showToast(&#39;Error&#39;, error.body.message || &#39;Failed to resend signature request&#39;, &#39;error&#39;);
//     }
// }

// async cancelSignatureRequest(requestId) {
//     try {
//         // Implementation for canceling signature request
//         this.showToast(&#39;Info&#39;, &#39;Cancel functionality will be implemented&#39;, &#39;info&#39;);
//         // In real implementation, update request status to cancelled
//         // await cancelSignatureRequest({ requestId: requestId });
//         // this.showToast(&#39;Success&#39;, &#39;Signature request cancelled successfully!&#39;, &#39;success&#39;);
//         // return refreshApex(this.wiredSignatureRequestsResult);
//     } catch (error) {
//         this.showToast(&#39;Error&#39;, error.body.message || &#39;Failed to cancel signature request&#39;, &#39;error&#39;);
//     }
// }

// // Helper methods
// updateDocumentContent() {
//     if (this.documentData.GeneratedClause__c) {
//         // Use requestAnimationFrame to ensure DOM is ready
//         requestAnimationFrame(() =&gt; {
//             const clauseElement = this.template.querySelector(&#39;.clause-text&#39;);
//             if (clauseElement) {
//                 clauseElement.innerHTML = this.formatDocumentText(this.documentData.GeneratedClause__c);
//             }
//         });
//     }
// }

// formatDocumentText(text) {
//     // Format the document text with proper styling
//     return text
//         .replace(/\n/g, &#39;&lt;br&gt;&#39;)
//         .replace(/\*\*(.*?)\*\*/g, &#39;&lt;strong&gt;$1&lt;/strong&gt;&#39;)
//         .replace(/\*(.*?)\*/g, &#39;&lt;em&gt;$1&lt;/em&gt;&#39;);
// }

// showToast(title, message, variant) {
//     const evt = new ShowToastEvent({
//         title: title,
//         message: message,
//         variant: variant
//     });
//     this.dispatchEvent(evt);
// }
// }




//Developer_build_step_by_step_impl_e_sign.........................................................



// import { LightningElement, api, track, wire } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
// import { refreshApex } from '@salesforce/apex';
// import getSignatureRequests from '@salesforce/apex/SignatureRequestController.getSignatureRequests';
// import initiateSignatureRequest from '@salesforce/apex/SignatureRequestController.initiateSignatureRequest';

// // Fields to retrieve
// const DOCUMENT_FIELDS = [
//     'DocumentLifecycleConfiguration__c.Id',
//     'DocumentLifecycleConfiguration__c.Region__c',
//     'DocumentLifecycleConfiguration__c.Role__c',
//     'DocumentLifecycleConfiguration__c.ContractType__c',
//     'DocumentLifecycleConfiguration__c.ComplianceStatus__c',
//     'DocumentLifecycleConfiguration__c.CreatedDate',
//     'DocumentLifecycleConfiguration__c.LastModifiedDate'
// ];

// export default class DocumentViewer extends LightningElement {
//     @api recordId; // Document Configuration ID

//     @track documentContent = '';
//     @track documentStatus = 'Draft';
//     @track createdDate = '';
//     @track lastModifiedDate = '';

//     @track signatureRequests = [];
//     @track selectedRequestId = '';
//     @track showSignatureModal = false;

//     @track isLoading = false;
//     @track isSignatureDisabled = false;

//     @wire(getRecord, { recordId: '$recordId', fields: DOCUMENT_FIELDS })
//     wiredDocument({ error, data }) {
//         if (data) {
//             this.processDocumentData(data);
//         } else if (error) {
//             this.showToast('Error', 'Failed to load document: ' + error.body?.message, 'error');
//         }
//     }

//     @wire(getSignatureRequests)
//     wiredSignatureRequests({ error, data }) {
//         if (data) {
//             this.processSignatureRequests(data);
//         } else if (error) {
//             this.showToast('Error', 'Failed to load signature requests: ' + error.body?.message, 'error');
//         }
//     }

//     get documentId() {
//         return this.recordId ? this.recordId.substring(0, 15) : '';
//     }

//     get statusVariant() {
//         switch (this.documentStatus.toLowerCase()) {
//             case 'completed': return 'success';
//             case 'pending': return 'warning';
//             case 'draft': return 'inverse';
//             default: return 'neutral';
//         }
//     }

//     get hasSignatureRequests() {
//         return this.signatureRequests.length > 0;
//     }

//     processDocumentData(data) {
//         const region = getFieldValue(data, 'DocumentLifecycleConfiguration__c.Region__c');
//         const role = getFieldValue(data, 'DocumentLifecycleConfiguration__c.Role__c');
//         const contractType = getFieldValue(data, 'DocumentLifecycleConfiguration__c.ContractType__c');
//         const complianceStatus = getFieldValue(data, 'DocumentLifecycleConfiguration__c.ComplianceStatus__c');

//         this.documentContent = this.generateDocumentContent(region, role, contractType);
//         this.documentStatus = complianceStatus || 'Draft';

//         const createdDate = getFieldValue(data, 'DocumentLifecycleConfiguration__c.CreatedDate');
//         const lastModifiedDate = getFieldValue(data, 'DocumentLifecycleConfiguration__c.LastModifiedDate');

//         this.createdDate = createdDate ? new Date(createdDate).toLocaleString() : '';
//         this.lastModifiedDate = lastModifiedDate ? new Date(lastModifiedDate).toLocaleString() : '';
//     }

//     processSignatureRequests(data) {
//         this.signatureRequests = data.map(request => ({
//             ...request,
//             statusVariant: this.getSignatureStatusVariant(request.Status__c)
//         }));
//     }

//     generateDocumentContent(region, role, contractType) {
//         return `
//             <h2>${contractType} Agreement</h2>
//             <p><strong>Region:</strong> ${region}</p>
//             <p><strong>Role:</strong> ${role}</p>
//             <p><strong>Generated:</strong> ${new Date().toLocaleDateString()}</p>

//             <h3>Terms and Conditions</h3>
//             <p>This document contains the standard ${contractType.toLowerCase()} terms and conditions 
//             applicable for ${role} positions in the ${region} region.</p>

//             <p>All parties are required to review and sign this document electronically.</p>

//             <div style="margin-top: 20px; padding: 10px; border: 1px solid #ccc;">
//                 <strong>Signature Required</strong><br>
//                 Electronic signature is legally binding and equivalent to handwritten signature.
//             </div>
//         `;
//     }

//     getSignatureStatusVariant(status) {
//         switch (status?.toLowerCase()) {
//             case 'signed': return 'success';
//             case 'pending': return 'warning';
//             case 'rejected': return 'error';
//             default: return 'neutral';
//         }
//     }

//     async handleRequestSignature() {
//         try {
//             this.isLoading = true;
//             const requestId = await initiateSignatureRequest({
//                 documentId: this.recordId,
//                 signerEmail: 'example@company.com', // Replace with actual input in production
//                 signerName: 'Document Signer'
//             });

//             this.selectedRequestId = requestId;
//             this.showSignatureModal = true;
//             this.showToast('Success', 'Signature request created successfully!', 'success');
//         } catch (error) {
//             this.showToast('Error', 'Failed to request signature: ' + error.body?.message, 'error');
//         } finally {
//             this.isLoading = false;
//         }
//     }

//     handleDownloadPDF() {
//         this.showToast('Info', 'PDF download functionality to be implemented', 'info');
//     }

//     handleViewHistory() {
//         this.showToast('Info', 'History view functionality to be implemented', 'info');
//     }

//     handleSignatureComplete() {
//         this.showSignatureModal = false;
//         this.showToast('Success', 'Signature completed successfully!', 'success');
//     }

//     showToast(title, message, variant) {
//         this.dispatchEvent(
//             new ShowToastEvent({
//                 title,
//                 message,
//                 variant
//             })
//         );
//     }
// }
// Refresh signature requests
//         return refreshApex(this.wiredSignatureRequests);
//     }
    
//     handleModalCancel() {
//         this.showSignatureModal = false;
//     }
    
//     // Utility method
//     showToast(title, message, variant) {
//         const evt = new ShowToastEvent({
//             title: title,
//             message: message,
//             variant: variant
//         });
//         this.dispatchEvent(evt);
//     }
// }

import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

import getDocumentData from '@salesforce/apex/DocumentController.getDocumentData';
import createSignatureRequest from '@salesforce/apex/SignatureRequestController.createSignatureRequest';
import getAuditTrail from '@salesforce/apex/AuditTrailManager.getAuditTrail';

export default class DocumentViewer extends LightningElement {
    @api recordId;
    @track documentData = null;
    @track showSignatureModal = false;
    @track showAuditModal = false;
    @track newSignerEmail = '';
    @track newSignerName = '';
    @track personalMessage = '';
    @track isCreatingRequest = false;
    @track auditTrailData = null;

    wiredDocumentData;

    get signatureColumns() {
        return [
            { label: 'Signer Name', fieldName: 'SignerName__c', type: 'text' },
            { label: 'Signer Email', fieldName: 'SignerEmail__c', type: 'email' },
            { 
                label: 'Status', 
                fieldName: 'Status__c', 
                type: 'text',
                cellAttributes: { class: { fieldName: 'statusClass' } }
            },
            { 
                label: 'Created Date', 
                fieldName: 'CreatedDate', 
                type: 'date',
                typeAttributes: { year: 'numeric', month: '2-digit', day: '2-digit' }
            },
            { 
                label: 'Completed Date', 
                fieldName: 'CompletedDate__c', 
                type: 'date',
                typeAttributes: { year: 'numeric', month: '2-digit', day: '2-digit' }
            },
            {
                type: 'action',
                typeAttributes: {
                    rowActions: [
                        { label: 'View Signature', name: 'view_signature' },
                        { label: 'Resend Request', name: 'resend_request' }
                    ]
                }
            }
        ];
    }

    get auditColumns() {
        return [
            { label: 'Action', fieldName: 'Action__c', type: 'text' },
            { label: 'Status', fieldName: 'Status__c', type: 'text' },
            { label: 'Details', fieldName: 'Details__c', type: 'text', wrapText: true },
            { 
                label: 'Timestamp', 
                fieldName: 'Timestamp__c', 
                type: 'date',
                typeAttributes: { 
                    year: 'numeric', month: '2-digit', day: '2-digit', 
                    hour: '2-digit', minute: '2-digit' 
                }
            }
        ];
    }

    get signatureRequests() {
        if (this.documentData && this.documentData.signatureRequests) {
            return this.documentData.signatureRequests.map(request => ({
                ...request,
                statusClass: this.getStatusClass(request.Status__c)
            }));
        }
        return [];
    }

    get hasSignatureRequests() {
        return this.signatureRequests && this.signatureRequests.length > 0;
    }

    get complianceVariant() {
        if (this.documentData && this.documentData.document) {
            const status = this.documentData.document.ComplianceStatus__c;
            return status === 'Compliant' ? 'success' : 'warning';
        }
        return 'inverse';
    }

    @wire(getDocumentData, { documentId: '$recordId' })
    wiredGetDocumentData(result) {
        this.wiredDocumentData = result;
        if (result.data) {
            this.documentData = result.data;
        } else if (result.error) {
            this.showToast('Error', 'Failed to load document data', 'error');
            console.error('Wire Error:', result.error);
        }
    }

    getStatusClass(status) {
        switch (status) {
            case 'Completed':
            case 'Signed':
                return 'slds-text-color_success';
            case 'Pending':
                return 'slds-text-color_default';
            case 'Rejected':
                return 'slds-text-color_error';
            default:
                return 'slds-text-color_weak';
        }
    }

    showSignatureRequestModal() {
        this.showSignatureModal = true;
    }

    closeSignatureModal() {
        this.showSignatureModal = false;
        this.newSignerEmail = '';
        this.newSignerName = '';
        this.personalMessage = '';
    }

    handleNewSignerEmailChange(event) {
        this.newSignerEmail = event.detail.value;
    }

    handleNewSignerNameChange(event) {
        this.newSignerName = event.detail.value;
    }

    handlePersonalMessageChange(event) {
        this.personalMessage = event.detail.value;
    }

    async createSignatureRequest() {
        if (!this.newSignerEmail || !this.newSignerName) {
            this.showToast('Error', 'Please enter both signer email and name', 'error');
            return;
        }

        this.isCreatingRequest = true;
        try {
            const result = await createSignatureRequest({
                documentId: this.recordId,
                signerEmail: this.newSignerEmail,
                signerName: this.newSignerName
            });

            if (result.success) {
                this.showToast('Success', 'Signature request created successfully', 'success');
                this.closeSignatureModal();
                return refreshApex(this.wiredDocumentData);
            } else {
                this.showToast('Error', result.errorMessage, 'error');
            }
        } catch (error) {
            this.showToast('Error', 'Failed to create signature request', 'error');
            console.error('Create Signature Request Error:', error);
        } finally {
            this.isCreatingRequest = false;
        }
    }

    async showAuditTrail() {
        this.showAuditModal = true;
        try {
            const auditData = await getAuditTrail({ recordId: this.recordId, limitCount: 50 });
            this.auditTrailData = auditData;
        } catch (error) {
            this.showToast('Error', 'Failed to load audit trail', 'error');
            console.error('Load Audit Trail Error:', error);
        }
    }

    closeAuditModal() {
        this.showAuditModal = false;
        this.auditTrailData = null;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'view_signature':
                this.viewSignature(row.Id);
                break;
            case 'resend_request':
                this.resendRequest(row.Id);
                break;
        }
    }

    viewSignature(requestId) {
        // Navigate to signature request record
        window.open(`/lightning/r/Signature_Request__c/${requestId}/view`, '_blank');
    }

    async resendRequest(requestId) {
        try {
            // Logic to resend signature request would go here
            this.showToast('Info', 'Resend functionality to be implemented', 'info');
        } catch (error) {
            this.showToast('Error', 'Failed to resend request', 'error');
            console.error('Resend Request Error:', error);
        }
    }

    async downloadPDF() {
        try {
            // PDF download logic would go here
            this.showToast('Info', 'PDF download functionality to be implemented', 'info');
        } catch (error) {
            this.showToast('Error', 'Failed to download PDF', 'error');
            console.error('Download PDF Error:', error);
        }
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}









// Developer_build_step_by_step_impl_e_sign v11-------------------------------------------------------


// import { LightningElement, api, track, wire } from 'lwc';
// import { getRecord } from 'lightning/uiRecordApi';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import processSignature from '@salesforce/apex/SignatureRequestController.processSignature';

// const SIGNATURE_REQUEST_FIELDS = [
//     'Signature_Request__c.Id',
//     'Signature_Request__c.SignerName__c',
//     'Signature_Request__c.SignerEmail__c',
//     'Signature_Request__c.Status__c',
//     'Signature_Request__c.DocumentId__r.DocumentTitle__c',
//     'Signature_Request__c.DocumentId__r.ContractType__c',
//     'Signature_Request__c.DocumentId__r.Region__c',
//     'Signature_Request__c.DocumentId__r.GeneratedClause__c'
// ];

// export default class SignaturePad extends LightningElement {
//     @api recordId;
    
//     @track signatureRequest = null;
//     @track documentContent = '';
//     @track selectedSignatureMethod = 'type';
//     @track typedSignature = '';
//     @track drawnSignatureData = '';
//     @track uploadedSignatureUrl = '';
//     @track agreementAccepted = false;
//     @track isSignatureComplete = false;
//     @track isProcessing = false;
    
//     canvas;
//     ctx;
//     drawing = false;

//     get signatureMethodOptions() {
//         return [
//             { label: 'Type My Name', value: 'type' },
//             { label: 'Draw Signature', value: 'draw' },
//             { label: 'Upload Image', value: 'upload' }
//         ];
//     }

//     get isTypedSignature() {
//         return this.selectedSignatureMethod === 'type';
//     }

//     get isDrawnSignature() {
//         return this.selectedSignatureMethod === 'draw';
//     }

//     get isUploadSignature() {
//         return this.selectedSignatureMethod === 'upload';
//     }

//     get isSubmitDisabled() {
//         if (!this.agreementAccepted || this.isProcessing) {
//             return true;
//         }

//         switch (this.selectedSignatureMethod) {
//             case 'type':
//                 return !this.typedSignature;
//             case 'draw':
//                 return !this.drawnSignatureData;
//             case 'upload':
//                 return !this.uploadedSignatureUrl;
//             default:
//                 return true;
//         }
//     }

//     @wire(getRecord, { recordId: '$recordId', fields: SIGNATURE_REQUEST_FIELDS })
//     wiredSignatureRequest({ error, data }) {
//         if (data) {
//             this.signatureRequest = data;
//             this.documentContent = data.fields.DocumentId__r.value.fields.GeneratedClause__c.value;
//         } else if (error) {
//             this.showToast('Error', 'Failed to load signature request', 'error');
//             console.error('Wire Error:', error);
//         }
//     }

//     renderedCallback() {
//         if (this.selectedSignatureMethod === 'draw' && !this.canvas) {
//             this.initializeCanvas();
//         }
//     }

//     initializeCanvas() {
//         this.canvas = this.template.querySelector('.signature-canvas');
//         if (this.canvas) {
//             this.ctx = this.canvas.getContext('2d');
//             this.ctx.strokeStyle = '#000000';
//             this.ctx.lineWidth = 2;
//             this.ctx.lineCap = 'round';
            
//             // Mouse events
//             this.canvas.addEventListener('mousedown', this.startDrawing.bind(this));
//             this.canvas.addEventListener('mousemove', this.draw.bind(this));
//             this.canvas.addEventListener('mouseup', this.stopDrawing.bind(this));
            
//             // Touch events for mobile
//             this.canvas.addEventListener('touchstart', this.handleTouch.bind(this));
//             this.canvas.addEventListener('touchmove', this.handleTouch.bind(this));
//             this.canvas.addEventListener('touchend', this.stopDrawing.bind(this));
//         }
//     }

//     handleSignatureMethodChange(event) {
//         this.selectedSignatureMethod = event.detail.value;
//         this.resetSignatureData();
//     }

//     handleTypedSignatureChange(event) {
//         this.typedSignature = event.detail.value;
//     }

//     handleAgreementChange(event) {
//         this.agreementAccepted = event.detail.checked;
//     }

//     handleUploadFinished(event) {
//         const uploadedFiles = event.detail.files;
//         if (uploadedFiles.length > 0) {
//             this.uploadedSignatureUrl = '/sfc/servlet.shepherd/document/download/' + uploadedFiles[0].documentId;
//             this.showToast('Success', 'Signature image uploaded successfully', 'success');
//         }
//     }

//     startDrawing(event) {
//         this.drawing = true;
//         const rect = this.canvas.getBoundingClientRect();
//         this.ctx.beginPath();
//         this.ctx.moveTo(event.clientX - rect.left, event.clientY - rect.top);
//     }

//     draw(event) {
//         if (!this.drawing) return;
//         const rect = this.canvas.getBoundingClientRect();
//         this.ctx.lineTo(event.clientX - rect.left, event.clientY - rect.top);
//         this.ctx.stroke();
//         this.updateDrawnSignatureData();
//     }

//     stopDrawing() {
//         this.drawing = false;
//         this.ctx.beginPath();
//     }

//     handleTouch(event) {
//         event.preventDefault();
//         const touch = event.touches[0];
//         const mouseEvent = new MouseEvent(event.type.replace('touch', 'mouse'), {
//             clientX: touch.clientX,
//             clientY: touch.clientY
//         });
//         this.canvas.dispatchEvent(mouseEvent);
//     }

//     clearCanvas() {
//         this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
//         this.drawnSignatureData = '';
//     }

//     updateDrawnSignatureData() {
//         this.drawnSignatureData = this.canvas.toDataURL();
//     }

//     resetSignatureData() {
//         this.typedSignature = '';
//         this.drawnSignatureData = '';
//         this.uploadedSignatureUrl = '';
//         if (this.canvas) {
//             this.clearCanvas();
//         }
//     }

//     async submitSignature() {
//         this.isProcessing = true;

//         try {
//             let signatureData = '';
//             let signatureMethod = this.selectedSignatureMethod;

//             switch (this.selectedSignatureMethod) {
//                 case 'type':
//                     signatureData = this.typedSignature;
//                     break;
//                 case 'draw':
//                     signatureData = this.drawnSignatureData;
//                     break;
//                 case 'upload':
//                     signatureData = this.uploadedSignatureUrl;
//                     break;
//             }

//             const result = await processSignature({
//                 signatureRequestId: this.recordId,
//                 signatureData: signatureData,
//                 signatureMethod: signatureMethod
//             });

//             if (result.success) {
//                 this.isSignatureComplete = true;
//                 this.showToast('Success', 'Signature submitted successfully', 'success');
//             } else {
//                 this.showToast('Error', result.errorMessage, 'error');
//             }

//         } catch (error) {
//             this.showToast('Error', 'An error occurred while submitting signature', 'error');
//             console.error('Submit Signature Error:', error);
//         } finally {
//             this.isProcessing = false;
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




// Developer_build_step_by_step_impl_e_sign v10------------------------------------------------------------

// import { LightningElement, api, track, wire } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import getSignatureRequest from '@salesforce/apex/SignatureRequestController.getSignatureRequest';
// import submitSignature from '@salesforce/apex/SignatureRequestController.submitSignature';

// export default class SignaturePad extends LightningElement {
//     @api recordId; // Signature Request ID
    
//     @track signatureRequest = null;
//     @track isLoading = true;
//     @track hasError = false;
//     @track errorMessage = '';
//     @track isSignatureComplete = false;
    
//     // Signature method states
//     @track selectedSignatureMethod = 'typed';
//     @track typedSignature = '';
//     @track canvasSignature = '';
//     @track uploadedSignatureUrl = '';
//     @track agreementAccepted = false;
    
//     // Canvas drawing states
//     isDrawing = false;
//     lastX = 0;
//     lastY = 0;
//     canvasContext = null;

//     // Wire the signature request data
//     @wire(getSignatureRequest, { requestId: '$recordId' })
//     wiredSignatureRequest({ error, data }) {
//         this.isLoading = false;
//         if (data) {
//             this.signatureRequest = data;
//             this.hasError = false;
//         } else if (error) {
//             this.hasError = true;
//             this.errorMessage = error.body ? error.body.message : 'Unknown error occurred';
//             this.showToast('Error', 'Failed to load signature request: ' + this.errorMessage, 'error');
//         }
//     }

//     // Computed properties
//     get signatureMethodOptions() {
//         return [
//             { label: 'Type My Name', value: 'typed' },
//             { label: 'Draw Signature', value: 'canvas' },
//             { label: 'Upload Image', value: 'upload' }
//         ];
//     }

//     get isTypedSignature() {
//         return this.selectedSignatureMethod === 'typed';
//     }

//     get isCanvasSignature() {
//         return this.selectedSignatureMethod === 'canvas';
//     }

//     get isUploadSignature() {
//         return this.selectedSignatureMethod === 'upload';
//     }

//     get isSubmitDisabled() {
//         if (!this.agreementAccepted) return true;
        
//         switch (this.selectedSignatureMethod) {
//             case 'typed':
//                 return !this.typedSignature || this.typedSignature.trim().length < 2;
//             case 'canvas':
//                 return !this.hasCanvasSignature();
//             case 'upload':
//                 return !this.uploadedSignatureUrl;
//             default:
//                 return true;
//         }
//     }

//     // Event handlers
//     handleSignatureMethodChange(event) {
//         this.selectedSignatureMethod = event.detail.value;
//         // Clear previous signatures when method changes
//         this.clearCurrentSignature();
//     }

//     handleTypedSignatureChange(event) {
//         this.typedSignature = event.target.value;
//     }

//     handleAgreementChange(event) {
//         this.agreementAccepted = event.target.checked;
//     }

//     handleUploadFinished(event) {
//         const uploadedFiles = event.detail.files;
//         if (uploadedFiles.length > 0) {
//             // In a real implementation, you would get the actual file URL
//             this.uploadedSignatureUrl = '/sfc/servlet.shepherd/version/download/' + uploadedFiles[0].documentId;
//             this.showToast('Success', 'Signature image uploaded successfully', 'success');
//         }
//     }

//     // Canvas methods
//     renderedCallback() {
//         if (this.isCanvasSignature && !this.canvasInitialized) {
//             this.initializeCanvas();
//             this.canvasInitialized = true;
//         }
//     }

//     initializeCanvas() {
//         const canvas = this.template.querySelector('.signature-canvas');
//         if (canvas) {
//             this.canvasContext = canvas.getContext('2d');
//             this.canvasContext.strokeStyle = '#000000';
//             this.canvasContext.lineWidth = 2;
//             this.canvasContext.lineCap = 'round';
//             this.canvasContext.lineJoin = 'round';
//         }
//     }

//     startDrawing(event) {
//         this.isDrawing = true;
//         const rect = event.target.getBoundingClientRect();
        
//         if (event.type === 'touchstart') {
//             const touch = event.touches[0];
//             this.lastX = touch.clientX - rect.left;
//             this.lastY = touch.clientY - rect.top;
//         } else {
//             this.lastX = event.clientX - rect.left;
//             this.lastY = event.clientY - rect.top;
//         }
        
//         event.preventDefault();
//     }

//     draw(event) {
//         if (!this.isDrawing) return;
        
//         const rect = event.target.getBoundingClientRect();
//         let currentX, currentY;
        
//         if (event.type === 'touchmove') {
//             const touch = event.touches[0];
//             currentX = touch.clientX - rect.left;
//             currentY = touch.clientY - rect.top;
//         } else {
//             currentX = event.clientX - rect.left;
//             currentY = event.clientY - rect.top;
//         }
        
//         this.canvasContext.beginPath();
//         this.canvasContext.moveTo(this.lastX, this.lastY);
//         this.canvasContext.lineTo(currentX, currentY);
//         this.canvasContext.stroke();
        
//         this.lastX = currentX;
//         this.lastY = currentY;
        
//         event.preventDefault();
//     }

//     stopDrawing() {
//         this.isDrawing = false;
//     }

//     clearCanvas() {
//         const canvas = this.template.querySelector('.signature-canvas');
//         if (canvas && this.canvasContext) {
//             this.canvasContext.clearRect(0, 0, canvas.width, canvas.height);
//         }
//     }

//     hasCanvasSignature() {
//         const canvas = this.template.querySelector('.signature-canvas');
//         if (!canvas) return false;
        
//         const imageData = this.canvasContext.getImageData(0, 0, canvas.width, canvas.height);
//         // Check if any pixel has been drawn (not transparent)
//         for (let i = 3; i < imageData.data.length; i += 4) {
//             if (imageData.data[i] !== 0) {
//                 return true;
//             }
//         }
//         return false;
//     }

//     getCanvasSignatureData() {
//         const canvas = this.template.querySelector('.signature-canvas');
//         return canvas ? canvas.toDataURL() : '';
//     }

//     clearCurrentSignature() {
//         this.typedSignature = '';
//         this.uploadedSignatureUrl = '';
//         if (this.isCanvasSignature) {
//             this.clearCanvas();
//         }
//     }

//     // Submit signature
//     async handleSubmitSignature() {
//         try {
//             let signatureData = '';
//             let signatureType = '';

//             switch (this.selectedSignatureMethod) {
//                 case 'typed':
//                     signatureData = this.typedSignature;
//                     signatureType = 'Typed';
//                     break;
//                 case 'canvas':
//                     signatureData = this.getCanvasSignatureData();
//                     signatureType = 'Drawn';
//                     break;
//                 case 'upload':
//                     signatureData = this.uploadedSignatureUrl;
//                     signatureType = 'Uploaded';
//                     break;
//             }

//             await submitSignature({
//                 requestId: this.recordId,
//                 signatureData: signatureData,
//                 signatureMethod: signatureType
//             });

//             this.isSignatureComplete = true;
//             this.showToast('Success', 'Signature submitted successfully!', 'success');

//         } catch (error) {
//             this.showToast('Error', 'Failed to submit signature: ' + error.body.message, 'error');
//         }
//     }

//     handleCancel() {
//         // Navigate away or close modal
//         this.dispatchEvent(new CustomEvent('cancel'));
//     }

//     handleClose() {
//         // Navigate away or close modal
//         this.dispatchEvent(new CustomEvent('close'));
//     }

//     retryLoad() {
//         this.isLoading = true;
//         this.hasError = false;
//         // The wire will automatically retry
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




// Developer_build_step_by_step_impl_e_sign v6.............................................................

// import { LightningElement, api, track } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// // Import Apex methods
// import getSignatureRequest from '@salesforce/apex/SignatureRequestController.getSignatureRequest';
// import submitSignature from '@salesforce/apex/SignatureRequestController.submitSignature';

// export default class SignaturePad extends LightningElement {
//     @api recordId; // Signature Request ID
    
//     // Data properties
//     @track signatureRequest = null;
//     @track selectedSignatureMethod = 'typed';
//     @track typedSignature = '';
//     @track drawnSignatureData = '';
//     @track uploadedSignatureUrl = '';
//     @track agreementChecked = false;
//     @track isSignatureComplete = false;
    
//     // State properties
//     @track isLoading = true;
//     @track hasError = false;
//     @track errorMessage = '';
//     canvasInitialized = false;

//     // Canvas drawing properties
//     isDrawing = false;
//     lastX = 0;
//     lastY = 0;

//     // Computed properties
//     get signatureMethodOptions() {
//         return [
//             { label: 'Type My Name', value: 'typed' },
//             { label: 'Draw Signature', value: 'drawn' },
//             { label: 'Upload Image', value: 'uploaded' }
//         ];
//     }

//     get isTypedSignature() {
//         return this.selectedSignatureMethod === 'typed';
//     }

//     get isDrawnSignature() {
//         return this.selectedSignatureMethod === 'drawn';
//     }

//     get isUploadedSignature() {
//         return this.selectedSignatureMethod === 'uploaded';
//     }

//     get isSubmitDisabled() {
//         if (!this.agreementChecked) return true;
        
//         switch (this.selectedSignatureMethod) {
//             case 'typed':
//                 return !this.typedSignature || this.typedSignature.trim().length < 2;
//             case 'drawn':
//                 return !this.drawnSignatureData;
//             case 'uploaded':
//                 return !this.uploadedSignatureUrl;
//             default:
//                 return true;
//         }
//     }

//     // Lifecycle methods
//     connectedCallback() {
//         this.loadSignatureRequest();
//     }

//     renderedCallback() {
//         if (this.isDrawnSignature && !this.canvasInitialized) {
//             this.initializeCanvas();
//         }
//     }

//     // Data loading
//     async loadSignatureRequest() {
//         try {
//             this.isLoading = true;
//             const result = await getSignatureRequest({ requestId: this.recordId });
            
//             if (result) {
//                 this.signatureRequest = result;
//                 this.isSignatureComplete = result.Status__c === 'Signed' || result.Status__c === 'Completed';
//                 this.hasError = false;
//             } else {
//                 this.hasError = true;
//                 this.errorMessage = 'Signature request not found.';
//             }
//         } catch (error) {
//             this.hasError = true;
//             this.errorMessage = 'Failed to load signature request: ' + (error.body?.message || error.message);
//         } finally {
//             this.isLoading = false;
//         }
//     }

//     // Event handlers
//     handleSignatureMethodChange(event) {
//         this.selectedSignatureMethod = event.detail.value;
//         this.clearCurrentSignature();
//     }

//     handleTypedSignatureChange(event) {
//         this.typedSignature = event.target.value;
//     }

//     handleAgreementChange(event) {
//         this.agreementChecked = event.target.checked;
//     }

//     handleUploadFinished(event) {
//         const uploadedFiles = event.detail.files;
//         if (uploadedFiles && uploadedFiles.length > 0) {
//             this.uploadedSignatureUrl =
//                 '/sfc/servlet.shepherd/document/download/' + uploadedFiles[0].documentId;
//             this.showToast('Success', 'Signature image uploaded successfully', 'success');
//         }
//     }

//     // Canvas methods
//     initializeCanvas() {
//         const canvas = this.template.querySelector('[data-id="signatureCanvas"]');
//         if (canvas) {
//             const ctx = canvas.getContext('2d');
//             ctx.strokeStyle = '#000000';
//             ctx.lineWidth = 2;
//             ctx.lineCap = 'round';
//             ctx.lineJoin = 'round';
//             this.canvasInitialized = true;
//         }
//     }

//     handleMouseDown(event) {
//         this.isDrawing = true;
//         const rect = event.target.getBoundingClientRect();
//         this.lastX = event.clientX - rect.left;
//         this.lastY = event.clientY - rect.top;
//     }

//     handleMouseMove(event) {
//         if (!this.isDrawing) return;
//         const canvas = event.target;
//         const ctx = canvas.getContext('2d');
//         const rect = canvas.getBoundingClientRect();
//         const currentX = event.clientX - rect.left;
//         const currentY = event.clientY - rect.top;

//         ctx.beginPath();
//         ctx.moveTo(this.lastX, this.lastY);
//         ctx.lineTo(currentX, currentY);
//         ctx.stroke();

//         this.lastX = currentX;
//         this.lastY = currentY;
//         this.drawnSignatureData = canvas.toDataURL();
//     }

//     handleMouseUp() {
//         this.isDrawing = false;
//     }

//     // Touch events for mobile
//     handleTouchStart(event) {
//         event.preventDefault();
//         const touch = event.touches[0];
//         const rect = event.target.getBoundingClientRect();

//         this.isDrawing = true;
//         this.lastX = touch.clientX - rect.left;
//         this.lastY = touch.clientY - rect.top;
//     }

//     handleTouchMove(event) {
//         event.preventDefault();
//         if (!this.isDrawing) return;

//         const touch = event.touches[0];
//         const canvas = event.target;
//         const ctx = canvas.getContext('2d');
//         const rect = canvas.getBoundingClientRect();
//         const currentX = touch.clientX - rect.left;
//         const currentY = touch.clientY - rect.top;

//         ctx.beginPath();
//         ctx.moveTo(this.lastX, this.lastY);
//         ctx.lineTo(currentX, currentY);
//         ctx.stroke();

//         this.lastX = currentX;
//         this.lastY = currentY;
//         this.drawnSignatureData = canvas.toDataURL();
//     }

//     handleTouchEnd(event) {
//         event.preventDefault();
//         this.isDrawing = false;
//     }

//     handleClearCanvas() {
//         const canvas = this.template.querySelector('[data-id="signatureCanvas"]');
//         if (canvas) {
//             const ctx = canvas.getContext('2d');
//             ctx.clearRect(0, 0, canvas.width, canvas.height);
//             this.drawnSignatureData = '';
//         }
//     }

//     // Clear current signature data
//     clearCurrentSignature() {
//         this.typedSignature = '';
//         this.drawnSignatureData = '';
//         this.uploadedSignatureUrl = '';

//         if (this.selectedSignatureMethod === 'drawn') {
//             this.handleClearCanvas();
//         }
//     }

//     // Submit signature
//     async handleSubmitSignature() {
//         if (this.isSubmitDisabled) {
//             this.showToast('Error', 'Please complete all required fields', 'error');
//             return;
//         }

//         this.isLoading = true;

//         try {
//             let signatureData = '';
//             let signatureMethod = this.selectedSignatureMethod;

//             switch (this.selectedSignatureMethod) {
//                 case 'typed':
//                     signatureData = this.typedSignature;
//                     signatureMethod = 'Typed';
//                     break;
//                 case 'drawn':
//                     signatureData = this.drawnSignatureData;
//                     signatureMethod = 'Drawn';
//                     break;
//                 case 'uploaded':
//                     signatureData = this.uploadedSignatureUrl;
//                     signatureMethod = 'Uploaded';
//                     break;
//             }

//             const result = await submitSignature({
//                 requestId: this.recordId,
//                 signatureData: signatureData,
//                 signatureMethod: signatureMethod
//             });

//             if (result) {
//                 this.isSignatureComplete = true;
//                 this.showToast('Success', 'Signature submitted successfully!', 'success');
//                 await this.loadSignatureRequest();
//             }
//         } catch (error) {
//             this.showToast(
//                 'Error',
//                 'Failed to submit signature: ' + (error.body?.message || error.message),
//                 'error'
//             );
//         } finally {
//             this.isLoading = false;
//         }
//     }

//     // Utility method
//     showToast(title, message, variant) {
//         const evt = new ShowToastEvent({ title, message, variant });
//         this.dispatchEvent(evt);
//     }
// }



// Developer_build_step_by_step_impl_e_sign v3....................................................

// import { LightningElement, api, track, wire } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import getSignatureRequest from '@salesforce/apex/SignatureRequestController.getSignatureRequest';
// import submitSignature from '@salesforce/apex/SignatureRequestController.submitSignature';

// export default class SignaturePad extends LightningElement {
//     @api recordId; // Signature Request ID

//     @track signatureRequest = null;
//     @track selectedSignatureMethod = 'typed';
//     @track typedSignature = '';
//     @track canvasSignature = '';
//     @track uploadedSignatureUrl = '';
//     @track agreementAccepted = false;
//     @track isLoading = false;

//     isDrawing = false;
//     lastX = 0;
//     lastY = 0;
//     canvasInitialized = false;

//     // Wire Apex for loading signature request
//     @wire(getSignatureRequest, { requestId: '$recordId' })
//     wiredSignatureRequest({ error, data }) {
//         if (data) {
//             this.signatureRequest = data;
//         } else if (error) {
//             this.showToast('Error', 'Failed to load signature request: ' + error.body.message, 'error');
//         }
//     }

//     // Signature method options
//     get signatureMethodOptions() {
//         return [
//             { label: 'Type My Name', value: 'typed' },
//             { label: 'Draw Signature', value: 'canvas' },
//             { label: 'Upload Image', value: 'upload' }
//         ];
//     }

//     get isTypedSignature() {
//         return this.selectedSignatureMethod === 'typed';
//     }
//     get isCanvasSignature() {
//         return this.selectedSignatureMethod === 'canvas';
//     }
//     get isUploadSignature() {
//         return this.selectedSignatureMethod === 'upload';
//     }

//     // Disable submit button logic
//     get isSubmitDisabled() {
//         if (!this.agreementAccepted || this.isLoading) return true;

//         switch (this.selectedSignatureMethod) {
//             case 'typed':
//                 return !this.typedSignature || this.typedSignature.trim().length < 2;
//             case 'canvas':
//                 return !this.hasCanvasSignature();
//             case 'upload':
//                 return !this.uploadedSignatureUrl;
//             default:
//                 return true;
//         }
//     }

//     // --- Event Handlers ---
//     handleSignatureMethodChange(event) {
//         this.selectedSignatureMethod = event.detail.value;
//         this.clearCurrentSignature();
//     }

//     handleTypedSignatureChange(event) {
//         this.typedSignature = event.detail.value;
//     }

//     handleAgreementChange(event) {
//         this.agreementAccepted = event.detail.checked;
//     }

//     handleUploadFinished(event) {
//         const uploadedFiles = event.detail.files;
//         if (uploadedFiles.length > 0) {
//             this.uploadedSignatureUrl = uploadedFiles[0].documentId;
//             this.showToast('Success', 'Signature image uploaded successfully', 'success');
//         }
//     }

//     // --- Canvas Methods ---
//     renderedCallback() {
//         if (this.isCanvasSignature && !this.canvasInitialized) {
//             this.initializeCanvas();
//             this.canvasInitialized = true;
//         }
//     }

//     initializeCanvas() {
//         const canvas = this.template.querySelector('canvas.signature-canvas');
//         if (canvas) {
//             const ctx = canvas.getContext('2d');
//             ctx.strokeStyle = '#000000';
//             ctx.lineWidth = 2;
//             ctx.lineCap = 'round';

//             // Mouse events
//             canvas.addEventListener('mousedown', this.startDrawing.bind(this));
//             canvas.addEventListener('mousemove', this.draw.bind(this));
//             canvas.addEventListener('mouseup', this.stopDrawing.bind(this));
//             canvas.addEventListener('mouseout', this.stopDrawing.bind(this));

//             // Touch events
//             canvas.addEventListener('touchstart', this.handleTouchStart.bind(this));
//             canvas.addEventListener('touchmove', this.handleTouchMove.bind(this));
//             canvas.addEventListener('touchend', this.stopDrawing.bind(this));
//         }
//     }

//     startDrawing(event) {
//         this.isDrawing = true;
//         const rect = event.target.getBoundingClientRect();
//         this.lastX = event.clientX - rect.left;
//         this.lastY = event.clientY - rect.top;
//     }

//     draw(event) {
//         if (!this.isDrawing) return;

//         const canvas = this.template.querySelector('canvas.signature-canvas');
//         const ctx = canvas.getContext('2d');
//         const rect = canvas.getBoundingClientRect();

//         const currentX = event.clientX - rect.left;
//         const currentY = event.clientY - rect.top;

//         ctx.beginPath();
//         ctx.moveTo(this.lastX, this.lastY);
//         ctx.lineTo(currentX, currentY);
//         ctx.stroke();

//         this.lastX = currentX;
//         this.lastY = currentY;
//     }

//     stopDrawing() {
//         this.isDrawing = false;
//     }

//     handleTouchStart(event) {
//         event.preventDefault();
//         const touch = event.touches[0];
//         const rect = event.target.getBoundingClientRect();
//         this.isDrawing = true;
//         this.lastX = touch.clientX - rect.left;
//         this.lastY = touch.clientY - rect.top;
//     }

//     handleTouchMove(event) {
//         event.preventDefault();
//         if (!this.isDrawing) return;

//         const touch = event.touches[0];
//         const canvas = this.template.querySelector('canvas.signature-canvas');
//         const ctx = canvas.getContext('2d');
//         const rect = canvas.getBoundingClientRect();
//         const currentX = touch.clientX - rect.left;
//         const currentY = touch.clientY - rect.top;

//         ctx.beginPath();
//         ctx.moveTo(this.lastX, this.lastY);
//         ctx.lineTo(currentX, currentY);
//         ctx.stroke();

//         this.lastX = currentX;
//         this.lastY = currentY;
//     }

//     handleClearCanvas() {
//         const canvas = this.template.querySelector('canvas.signature-canvas');
//         if (canvas) {
//             const ctx = canvas.getContext('2d');
//             ctx.clearRect(0, 0, canvas.width, canvas.height);
//         }
//     }

//     hasCanvasSignature() {
//         const canvas = this.template.querySelector('canvas.signature-canvas');
//         if (!canvas) return false;

//         const ctx = canvas.getContext('2d');
//         const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);

//         return imageData.data.some((value, index) => index % 4 === 3 && value !== 0);
//     }

//     getCanvasSignatureData() {
//         const canvas = this.template.querySelector('canvas.signature-canvas');
//         return canvas ? canvas.toDataURL() : '';
//     }

//     clearCurrentSignature() {
//         this.typedSignature = '';
//         this.uploadedSignatureUrl = '';
//         if (this.isCanvasSignature) {
//             this.handleClearCanvas();
//         }
//     }

//     // --- Submit Signature ---
//     async handleSubmitSignature() {
//         if (this.isSubmitDisabled) {
//             this.showToast('Error', 'Please complete all required fields', 'error');
//             return;
//         }

//         this.isLoading = true;

//         try {
//             let signatureData = '';
//             let signatureType = this.selectedSignatureMethod;

//             switch (this.selectedSignatureMethod) {
//                 case 'typed':
//                     signatureData = this.typedSignature;
//                     signatureType = 'Typed';
//                     break;
//                 case 'canvas':
//                     signatureData = this.getCanvasSignatureData();
//                     signatureType = 'Drawn';
//                     break;
//                 case 'upload':
//                     signatureData = this.uploadedSignatureUrl;
//                     signatureType = 'Uploaded';
//                     break;
//             }

//             await submitSignature({
//                 requestId: this.recordId,
//                 signatureData: signatureData,
//                 signatureType: signatureType
//             });

//             this.showToast('Success', 'Signature submitted successfully!', 'success');
//             this.dispatchEvent(new CustomEvent('success', { detail: { requestId: this.recordId } }));
//         } catch (error) {
//             this.showToast('Error', 'Failed to submit signature: ' + error.body.message, 'error');
//         } finally {
//             this.isLoading = false;
//         }
//     }

//     handleCancel() {
//         this.dispatchEvent(new CustomEvent('cancel'));
//     }

//     showToast(title, message, variant) {
//         this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
//     }
// }








// Developer_build_step_by_step_impl_e_sign v2.......................................................



// import { LightningElement, track, api, wire } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
// import getSignatureRequest from '@salesforce/apex/SignatureRequestController.getSignatureRequest';
// import submitSignature from '@salesforce/apex/SignatureRequestController.submitSignature';

// // Signature Request fields
// const SIGNATURE_REQUEST_FIELDS = [
//     'Signature_Request__c.Id',
//     'Signature_Request__c.SignerName__c',
//     'Signature_Request__c.SignerEmail__c',
//     'Signature_Request__c.Status__c',
//     'Signature_Request__c.CompletedDate__c',
//     'Signature_Request__c.DocumentId__r.DocumentTitle__c',
//     'Signature_Request__c.DocumentId__r.GeneratedClause__c'
// ];

// export default class SignaturePad extends LightningElement {
//     // Public properties
//     @api recordId;
    
//     // Component state
//     @track isLoading = true;
//     @track errorMessage = '';
//     @track signatureRequest = null;
//     @track documentContent = '';
//     @track documentTitle = '';
    
//     // Signature state
//     @track selectedSignatureMethod = 'type';
//     @track typedSignature = '';
//     @track drawnSignatureData = '';
//     @track uploadedSignatureUrl = '';
//     @track agreedToTerms = false;
//     @track isSubmitting = false;
    
//     // Canvas drawing state
//     isDrawing = false;
//     canvas = null;
//     context = null;
//     lastX = 0;
//     lastY = 0;

//     // Computed properties
//     get canSign() {
//         return this.signatureRequest && 
//                this.signatureRequest.Status__c === 'Pending' && 
//                !this.isAlreadySigned;
//     }

//     get isAlreadySigned() {
//         return this.signatureRequest && 
//                this.signatureRequest.Status__c === 'Signed';
//     }

//     get signedDate() {
//         if (this.isAlreadySigned && this.signatureRequest.CompletedDate__c) {
//             return new Date(this.signatureRequest.CompletedDate__c).toLocaleDateString();
//         }
//         return '';
//     }

//     get statusVariant() {
//         if (!this.signatureRequest) return 'inverse';
        
//         switch (this.signatureRequest.Status__c) {
//             case 'Pending': return 'warning';
//             case 'Signed': return 'success';
//             case 'Rejected': return 'error';
//             default: return 'inverse';
//         }
//     }

//     get isTypedSignature() {
//         return this.selectedSignatureMethod === 'type';
//     }

//     get isDrawSignature() {
//         return this.selectedSignatureMethod === 'draw';
//     }

//     get isUploadSignature() {
//         return this.selectedSignatureMethod === 'upload';
//     }

//     get isSubmitDisabled() {
//         if (!this.agreedToTerms || this.isSubmitting) {
//             return true;
//         }

//         switch (this.selectedSignatureMethod) {
//             case 'type':
//                 return !this.typedSignature || this.typedSignature.length < 2;
//             case 'draw':
//                 return !this.drawnSignatureData;
//             case 'upload':
//                 return !this.uploadedSignatureUrl;
//             default:
//                 return true;
//         }
//     }

//     // Lifecycle methods
//     connectedCallback() {
//         this.loadSignatureRequest();
//     }

//     renderedCallback() {
//         if (this.isDrawSignature && !this.canvas) {
//             this.initializeCanvas();
//         }
//     }

//     // Data loading
//     async loadSignatureRequest() {
//         if (!this.recordId) {
//             this.errorMessage = 'No signature request ID provided';
//             this.isLoading = false;
//             return;
//         }

//         try {
//             this.signatureRequest = await getSignatureRequest({ requestId: this.recordId });
            
//             if (this.signatureRequest) {
//                 this.documentTitle = this.signatureRequest.DocumentId__r.DocumentTitle__c;
//                 this.documentContent = this.signatureRequest.DocumentId__r.GeneratedClause__c || 
//                                     'Document content will be displayed here.';
//             } else {
//                 this.errorMessage = 'Signature request not found';
//             }
//         } catch (error) {
//             this.errorMessage = 'Failed to load signature request: ' + (error.body?.message || error.message);
//         } finally {
//             this.isLoading = false;
//         }
//     }

//     // Event handlers
//     handleSignatureMethodChange(event) {
//         this.selectedSignatureMethod = event.target.value;
//         this.clearSignatureData();
        
//         // Initialize canvas if switching to draw mode
//         if (this.selectedSignatureMethod === 'draw') {
//             setTimeout(() => {
//                 this.initializeCanvas();
//             }, 100);
//         }
//     }

//     handleTypedSignatureChange(event) {
//         this.typedSignature = event.detail.value;
//     }

//     handleAgreementChange(event) {
//         this.agreedToTerms = event.detail.checked;
//     }

//     handleUploadFinished(event) {
//         const uploadedFiles = event.detail.files;
//         if (uploadedFiles.length > 0) {
//             // In a real implementation, you'd process the uploaded file
//             this.uploadedSignatureUrl = '/sfc/servlet.shepherd/version/download/' + uploadedFiles[0].documentId;
//             this.showToast('Success', 'Signature image uploaded successfully', 'success');
//         }
//     }

//     async handleSubmitSignature() {
//         if (this.isSubmitDisabled) {
//             this.showToast('Error', 'Please complete all required fields', 'error');
//             return;
//         }

//         this.isSubmitting = true;

//         try {
//             let signatureData = '';
            
//             switch (this.selectedSignatureMethod) {
//                 case 'type':
//                     signatureData = this.typedSignature;
//                     break;
//                 case 'draw':
//                     signatureData = this.drawnSignatureData || this.getCanvasData();
//                     break;
//                 case 'upload':
//                     signatureData = this.uploadedSignatureUrl;
//                     break;
//             }

//             await submitSignature({
//                 requestId: this.recordId,
//                 signatureData: signatureData,
//                 signatureMethod: this.selectedSignatureMethod,
//                 signerIP: await this.getClientIP()
//             });

//             this.showToast('Success', 'Signature submitted successfully!', 'success');
            
//             // Reload to show signed state
//             await this.loadSignatureRequest();
            
//             // Dispatch custom event for parent components
//             this.dispatchEvent(new CustomEvent('signaturecomplete', {
//                 detail: {
//                     requestId: this.recordId,
//                     method: this.selectedSignatureMethod
//                 }
//             }));

//         } catch (error) {
//             this.showToast('Error', 'Failed to submit signature: ' + (error.body?.message || error.message), 'error');
//         } finally {
//             this.isSubmitting = false;
//         }
//     }

//     handleCancel() {
//         this.dispatchEvent(new CustomEvent('cancel'));
//     }

//     handleViewDocument() {
//         // Navigate to document view
//         this.dispatchEvent(new CustomEvent('viewdocument', {
//             detail: {
//                 documentId: this.signatureRequest.DocumentId__c
//             }
//         }));
//     }

//     // Canvas methods
//     initializeCanvas() {
//         const canvas = this.refs.signatureCanvas;
//         if (!canvas) return;

//         this.canvas = canvas;
//         this.context = canvas.getContext('2d');
        
//         // Set up canvas properties
//         this.context.strokeStyle = '#000000';
//         this.context.lineWidth = 2;
//         this.context.lineCap = 'round';
//         this.context.lineJoin = 'round';
        
//         // Set canvas background to white
//         this.context.fillStyle = '#FFFFFF';
//         this.context.fillRect(0, 0, canvas.width, canvas.height);
//     }

//     startDrawing(event) {
//         if (!this.context) return;
        
//         this.isDrawing = true;
//         const rect = this.canvas.getBoundingClientRect();
        
//         if (event.type === 'touchstart') {
//             event.preventDefault();
//             const touch = event.touches[0];
//             this.lastX = touch.clientX - rect.left;
//             this.lastY = touch.clientY - rect.top;
//         } else {
//             this.lastX = event.clientX - rect.left;
//             this.lastY = event.clientY - rect.top;
//         }
        
//         this.context.beginPath();
//         this.context.moveTo(this.lastX, this.lastY);
//     }

//     draw(event) {
//         if (!this.isDrawing || !this.context) return;
        
//         const rect = this.canvas.getBoundingClientRect();
//         let currentX, currentY;
        
//         if (event.type === 'touchmove') {
//             event.preventDefault();
//             const touch = event.touches[0];
//             currentX = touch.clientX - rect.left;
//             currentY = touch.clientY - rect.top;
//         } else {
//             currentX = event.clientX - rect.left;
//             currentY = event.clientY - rect.top;
//         }
        
//         this.context.lineTo(currentX, currentY);
//         this.context.stroke();
        
//         this.lastX = currentX;
//         this.lastY = currentY;
//     }

//     stopDrawing() {
//         if (!this.isDrawing) return;
        
//         this.isDrawing = false;
//         this.context.closePath();
        
//         // Save canvas data
//         this.drawnSignatureData = this.getCanvasData();
//     }

//     clearCanvas() {
//         if (!this.context || !this.canvas) return;
        
//         this.context.fillStyle = '#FFFFFF';
//         this.context.fillRect(0, 0, this.canvas.width, this.canvas.height);
//         this.drawnSignatureData = '';
//     }

//     getCanvasData() {
//         if (!this.canvas) return '';
//         return this.canvas.toDataURL('image/png');
//     }

//     clearSignatureData() {
//         this.typedSignature = '';
//         this.drawnSignatureData = '';
//         this.uploadedSignatureUrl = '';
        
//         if (this.canvas) {
//             this.clearCanvas();
//         }
//     }

//     // Utility methods
//     async getClientIP() {
//         // In a real implementation, you might call an external service
//         // For now, return a placeholder
//         return '127.0.0.1';
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




// Developer_build_step_by_step_impl_e_sign v1..............................................................


// import { LightningElement, api, track, wire } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import { getRecord } from 'lightning/uiRecordApi';
// import submitSignature from '@salesforce/apex/SignatureRequestController.submitSignature';

// const FIELDS = [
//     'Signature_Request__c.SignerName__c',
//     'Signature_Request__c.SignerEmail__c',
//     'Signature_Request__c.Status__c',
//     'Signature_Request__c.DocumentId__c'
// ];

// export default class SignaturePad extends LightningElement {
//     @api recordId;
//     @track signerName = '';
//     @track signerEmail = '';
//     @track selectedSignatureMethod = 'type';
//     @track typedSignature = '';
//     @track hasAgreed = false;
//     @track isSubmitting = false;
//     @track uploadedSignatureUrl = '';
//     @track documentContent = '';
//     @track signatureRequest = {};

//     isDrawing = false;
//     canvas;
//     context;

//     signatureMethodOptions = [
//         { label: 'Type Signature', value: 'type' },
//         { label: 'Draw Signature', value: 'draw' },
//         { label: 'Upload Signature', value: 'upload' }
//     ];

//     @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
//     wiredRecord({ error, data }) {
//         if (data) {
//             this.signatureRequest = data;
//             this.signerName = data.fields.SignerName__c.value;
//             this.signerEmail = data.fields.SignerEmail__c.value;
//             this.loadDocumentContent(data.fields.DocumentId__c.value);
//         } else if (error) {
//             this.showToast('Error', 'Failed to load signature request', 'error');
//         }
//     }

//     // getters
//     get isTypedSignature() {
//         return this.selectedSignatureMethod === 'type';
//     }
//     get isDrawSignature() {
//         return this.selectedSignatureMethod === 'draw';
//     }
//     get isUploadSignature() {
//         return this.selectedSignatureMethod === 'upload';
//     }
//     get isSubmitDisabled() {
//         if (!this.signerName || !this.signerEmail || !this.hasAgreed) {
//             return true;
//         }
//         if (this.isTypedSignature && !this.typedSignature) {
//             return true;
//         }
//         if (this.isDrawSignature && !this.hasCanvasSignature()) {
//             return true;
//         }
//         if (this.isUploadSignature && !this.uploadedSignatureUrl) {
//             return true;
//         }
//         return false;
//     }

//     // handlers
//     handleSignerNameChange(event) {
//         this.signerName = event.target.value;
//     }
//     handleSignerEmailChange(event) {
//         this.signerEmail = event.target.value;
//     }
//     handleSignatureMethodChange(event) {
//         this.selectedSignatureMethod = event.detail.value;
//         this.typedSignature = '';
//         this.uploadedSignatureUrl = '';
//         this.handleClearCanvas();
//     }
//     handleTypedSignatureChange(event) {
//         this.typedSignature = event.target.value;
//     }
//     handleAgreementChange(event) {
//         this.hasAgreed = event.target.checked;
//     }

//     // canvas
//     renderedCallback() {
//         if (this.isDrawSignature) {
//             this.initializeCanvas();
//         }
//     }
//     initializeCanvas() {
//         const canvas = this.template.querySelector('.signature-canvas');
//         if (canvas && !this.canvas) {
//             this.canvas = canvas;
//             this.context = canvas.getContext('2d');
//             this.context.strokeStyle = '#000000';
//             this.context.lineWidth = 2;
//             this.context.lineCap = 'round';

//             this.canvas.addEventListener('mousedown', this.handleMouseDown.bind(this));
//             this.canvas.addEventListener('mousemove', this.handleMouseMove.bind(this));
//             this.canvas.addEventListener('mouseup', this.handleMouseUp.bind(this));
//             this.canvas.addEventListener('mouseleave', this.handleMouseUp.bind(this));
//         }
//     }
//     handleMouseDown(event) {
//         this.isDrawing = true;
//         const rect = this.canvas.getBoundingClientRect();
//         this.context.beginPath();
//         this.context.moveTo(event.clientX - rect.left, event.clientY - rect.top);
//     }
//     handleMouseMove(event) {
//         if (!this.isDrawing) return;
//         const rect = this.canvas.getBoundingClientRect();
//         this.context.lineTo(event.clientX - rect.left, event.clientY - rect.top);
//         this.context.stroke();
//     }
//     handleMouseUp() {
//         this.isDrawing = false;
//     }
//     handleClearCanvas() {
//         if (this.context && this.canvas) {
//             this.context.clearRect(0, 0, this.canvas.width, this.canvas.height);
//         }
//     }
//     hasCanvasSignature() {
//         if (!this.canvas || !this.context) return false;
//         const imageData = this.context.getImageData(0, 0, this.canvas.width, this.canvas.height);
//         for (let i = 3; i < imageData.data.length; i += 4) {
//             if (imageData.data[i] !== 0) return true; // non-transparent pixel
//         }
//         return false;
//     }

//     // upload
//     handleUploadFinished(event) {
//         const uploadedFiles = event.detail.files;
//         if (uploadedFiles.length > 0) {
//             this.uploadedSignatureUrl = `/lightning/r/ContentDocument/${uploadedFiles[0].documentId}/view`;
//             this.showToast('Success', 'Signature image uploaded successfully', 'success');
//         }
//     }

//     // submit
//     async handleSubmitSignature() {
//         this.isSubmitting = true;
//         try {
//             let signatureData = '';
//             if (this.isTypedSignature) {
//                 signatureData = `TYPED:${this.typedSignature}`;
//             } else if (this.isDrawSignature) {
//                 signatureData = `DRAWN:${this.canvas.toDataURL()}`;
//             } else if (this.isUploadSignature) {
//                 signatureData = `UPLOADED:${this.uploadedSignatureUrl}`;
//             }

//             await submitSignature({
//                 requestId: this.recordId,
//                 signatureData,
//                 signerName: this.signerName,
//                 signerEmail: this.signerEmail
//             });

//             this.showToast('Success', 'Signature submitted successfully!', 'success');
//         } catch (error) {
//             this.showToast('Error', error?.body?.message || 'Failed to submit signature', 'error');
//         } finally {
//             this.isSubmitting = false;
//         }
//     }

//     handleCancel() {
//         this.dispatchEvent(new CustomEvent('close'));
//     }

//     loadDocumentContent(documentId) {
//         this.documentContent = `This is a sample document that requires your electronic signature. Document ID: ${documentId}. Please review before signing.`;
//     }

//     showToast(title, message, variant) {
//         this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
//     }
// }



// Developer_build_step_by_step_impl_e_sign............................................................... 


// import { LightningElement, api, track } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import { getRecord } from 'lightning/uiRecordApi';
// import submitSignature from '@salesforce/apex/SignatureRequestController.submitSignature';
// import getSignatureRequest from '@salesforce/apex/SignatureRequestController.getSignatureRequest';

// export default class SignaturePad extends LightningElement {
//     @api recordId; // Signature Request ID
    
//     // Signer information
//     @track signerName = '';
//     @track signerEmail = '';
//     @track documentContent = '';
    
//     // Signature method
//     @track selectedSignatureMethod = 'type';
//     @track typedSignature = '';
//     @track drawnSignatureData = '';
//     @track uploadedImageUrl = '';
    
//     // Canvas drawing state
//     @track isDrawing = false;
//     @track lastX = 0;
//     @track lastY = 0;
    
//     // Form state
//     @track agreementChecked = false;
//     @track isSignatureComplete = false;
//     @track isSubmitting = false;
    
//     // Signature method options
//     signatureMethodOptions = [
//         { label: 'Type Signature', value: 'type' },
//         { label: 'Draw Signature', value: 'draw' },
//         { label: 'Upload Image', value: 'upload' }
//     ];
    
//     // Computed properties
//     get isTypeSignature() {
//         return this.selectedSignatureMethod === 'type';
//     }
    
//     get isDrawSignature() {
//         return this.selectedSignatureMethod === 'draw';
//     }
    
//     get isUploadSignature() {
//         return this.selectedSignatureMethod === 'upload';
//     }
    
//     get isSubmitDisabled() {
//         if (!this.agreementChecked || !this.signerName || !this.signerEmail) {
//             return true;
//         }
        
//         switch (this.selectedSignatureMethod) {
//             case 'type':
//                 return !this.typedSignature;
//             case 'draw':
//                 return !this.drawnSignatureData;
//             case 'upload':
//                 return !this.uploadedImageUrl;
//             default:
//                 return true;
//         }
//     }
    
//     // Lifecycle hooks
//     connectedCallback() {
//         this.loadSignatureRequest();
//         // Set up canvas after component renders
//         setTimeout(() => {
//             this.initializeCanvas();
//         }, 100);
//     }
    
//     renderedCallback() {
//         if (this.isDrawSignature && !this.canvasInitialized) {
//             this.initializeCanvas();
//         }
//     }
    
//     // Data loading
//     async loadSignatureRequest() {
//         if (!this.recordId) return;
        
//         try {
//             const request = await getSignatureRequest({ requestId: this.recordId });
//             this.signerEmail = request.SignerEmail__c;
//             this.signerName = request.SignerName__c;
//             // Load document content (simplified)
//             this.documentContent = 'Document content will be loaded here...';
//         } catch (error) {
//             this.showToast('Error', 'Failed to load signature request: ' + error.body?.message, 'error');
//         }
//     }
    
//     // Canvas initialization and drawing
//     initializeCanvas() {
//         const canvas = this.template.querySelector('.signature-canvas');
//         if (!canvas) return;
        
//         canvas.width = 400;
//         canvas.height = 200;
        
//         const ctx = canvas.getContext('2d');
//         ctx.strokeStyle = '#000000';
//         ctx.lineWidth = 2;
//         ctx.lineCap = 'round';
//         ctx.lineJoin = 'round';
        
//         this.canvas = canvas;
//         this.ctx = ctx;
//         this.canvasInitialized = true;
//     }
    
//     // Event handlers
//     handleSignerNameChange(event) {
//         this.signerName = event.target.value;
//     }
    
//     handleSignerEmailChange(event) {
//         this.signerEmail = event.target.value;
//     }
    
//     handleSignatureMethodChange(event) {
//         this.selectedSignatureMethod = event.detail.value;
//         // Clear previous signature data
//         this.typedSignature = '';
//         this.drawnSignatureData = '';
//         this.uploadedImageUrl = '';
//     }
    
//     handleTypedSignatureChange(event) {
//         this.typedSignature = event.target.value;
//     }
    
//     handleAgreementChange(event) {
//         this.agreementChecked = event.target.checked;
//     }
    
//     // Mouse events for drawing
//         handleMouseDown(event) {
//         this.isDrawing = true;
//         const rect = this.canvas.getBoundingClientRect();
//         this.lastX = event.clientX - rect.left;
//         this.lastY = event.clientY - rect.top;
        
//         this.ctx.beginPath();
//         this.ctx.moveTo(this.lastX, this.lastY);
//     }

//     handleMouseMove(event) {
//         if (!this.isDrawing) return;
        
//         const rect = this.canvas.getBoundingClientRect();
//         const currentX = event.clientX - rect.left;
//         const currentY = event.clientY - rect.top;
        
//         this.ctx.lineTo(currentX, currentY);
//         this.ctx.stroke();
        
//         this.lastX = currentX;
//         this.lastY = currentY;
//     }

//     handleMouseUp() {
//         this.isDrawing = false;
//         this.ctx.beginPath();
//         this.updateDrawnSignature();
//     }

//     // Touch events for mobile support
//     handleTouchStart(event) {
//         event.preventDefault();
//         const touch = event.touches[0];
//         const mouseEvent = new MouseEvent('mousedown', {
//             clientX: touch.clientX,
//             clientY: touch.clientY
//         });
//         this.handleMouseDown(mouseEvent);
//     }

//     handleTouchMove(event) {
//         event.preventDefault();
//         const touch = event.touches[0];
//         const mouseEvent = new MouseEvent('mousemove', {
//             clientX: touch.clientX,
//             clientY: touch.clientY
//         });
//         this.handleMouseMove(mouseEvent);
//     }

//     handleTouchEnd(event) {
//         event.preventDefault();
//         this.handleMouseUp();
//     }

//     // Canvas utility methods
//     handleClearCanvas() {
//         if (this.ctx && this.canvas) {
//             this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
//             this.drawnSignatureData = '';
//         }
//     }

//     updateDrawnSignature() {
//         if (this.canvas) {
//             this.drawnSignatureData = this.canvas.toDataURL('image/png');
//         }
//     }

//     // File upload handler
//     handleUploadFinished(event) {
//         const uploadedFiles = event.detail.files;
//         if (uploadedFiles.length > 0) {
//             // In production, you would get the actual file URL from Salesforce Files
//             this.uploadedImageUrl = '/servlet/servlet.FileDownload?file=' + uploadedFiles[0].documentId;
//             this.showToast('Success', 'Signature image uploaded successfully', 'success');
//         }
//     }

//     // Signature submission
//     async handleSubmitSignature() {
//         this.isSubmitting = true;
        
//         try {
//             const signatureData = this.getSignatureData();
            
//             const result = await submitSignature({
//                 requestId: this.recordId,
//                 signatureData: signatureData,
//                 signatureMethod: this.selectedSignatureMethod
//             });

//             if (result) {
//                 this.isSignatureComplete = true;
//                 this.showToast('Success', 'Signature submitted successfully!', 'success');
                
//                 // Dispatch custom event for parent components
//                 this.dispatchEvent(new CustomEvent('signaturecomplete', {
//                     detail: {
//                         requestId: this.recordId,
//                         signatureMethod: this.selectedSignatureMethod
//                     }
//                 }));
//             }
//         } catch (error) {
//             this.showToast('Error', 'Failed to submit signature: ' + error.body?.message, 'error');
//         } finally {
//             this.isSubmitting = false;
//         }
//     }

//     // Get signature data based on method
//     getSignatureData() {
//         switch (this.selectedSignatureMethod) {
//             case 'type':
//                 return this.typedSignature;
//             case 'draw':
//                 return this.drawnSignatureData;
//             case 'upload':
//                 return this.uploadedImageUrl;
//             default:
//                 return '';
//         }
//     }

//     // Cancel handler
//     handleCancel() {
//         // Navigate back or close modal
//         this.dispatchEvent(new CustomEvent('cancel'));
//     }

//     // Utility method for showing toast messages
//     showToast(title, message, variant) {
//         const evt = new ShowToastEvent({
//             title: title,
//             message: message,
//             variant: variant
//         });
//         this.dispatchEvent(evt);
  //  }
//}

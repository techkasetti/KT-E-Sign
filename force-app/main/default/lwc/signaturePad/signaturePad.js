import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import submitSignature from '@salesforce/apex/SignatureRequestController.submitSignature';

const FIELDS = ['Signature_Request__c.SignerName__c', 'Signature_Request__c.SignerEmail__c', 'Signature_Request__c.Status__c', 'Signature_Request__c.DocumentId__c'];

export default class SignaturePad extends LightningElement {
    @api recordId; // Signature Request ID
    @track signerName = '';
    @track signerEmail = '';
    @track selectedSignatureMethod = 'type';
    @track typedSignature = '';
    @track hasAgreed = false;
    @track isSubmitting = false;
    @track uploadedSignatureUrl = '';
    @track documentContent = '';
    @track signatureRequest = {};
    
    // Canvas drawing variables
    isDrawing = false;
    canvas;
    context;
    
    signatureMethodOptions = [
        { label: 'Type Signature', value: 'type' },
        { label: 'Draw Signature', value: 'draw' },
        { label: 'Upload Signature', value: 'upload' }
    ];

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.signatureRequest = data;
            this.signerName = data.fields.SignerName__c.value;
            this.signerEmail = data.fields.SignerEmail__c.value;
            this.loadDocumentContent(data.fields.DocumentId__c.value);
        } else if (error) {
            this.showToast('Error', 'Failed to load signature request', 'error');
        }
    }

    // Computed properties
    get isTypedSignature() {
        return this.selectedSignatureMethod === 'type';
    }
    
    get isDrawSignature() {
        return this.selectedSignatureMethod === 'draw';
    }
    
    get isUploadSignature() {
        return this.selectedSignatureMethod === 'upload';
    }
    
    get isSubmitDisabled() {
        if (!this.signerName || !this.signerEmail || !this.hasAgreed) {
            return true;
        }
        
        if (this.selectedSignatureMethod === 'type' && !this.typedSignature) {
            return true;
        }
        
        if (this.selectedSignatureMethod === 'draw' && !this.hasCanvasSignature()) {
            return true;
        }
        
        if (this.selectedSignatureMethod === 'upload' && !this.uploadedSignatureUrl) {
            return true;
        }
        
        return false;
    }

    // Event handlers
    handleSignerNameChange(event) {
        this.signerName = event.target.value;
    }
    
    handleSignerEmailChange(event) {
        this.signerEmail = event.target.value;
    }
    
    handleSignatureMethodChange(event) {
        this.selectedSignatureMethod = event.detail.value;
        // Clear previous signature data when method changes
        this.typedSignature = '';
        this.uploadedSignatureUrl = '';
        this.clearCanvas();
    }
    
    handleTypedSignatureChange(event) {
        this.typedSignature = event.target.value;
    }
    
    handleAgreementChange(event) {
        this.hasAgreed = event.target.checked;
    }

    // Canvas drawing methods
    renderedCallback() {
        if (this.selectedSignatureMethod === 'draw') {
            this.initializeCanvas();
        }
    }
    
    initializeCanvas() {
        const canvas = this.template.querySelector('.signature-canvas');
        if (canvas && !this.canvas) {
            this.canvas = canvas;
            this.context = canvas.getContext('2d');
            this.context.strokeStyle = '#000000';
            this.context.lineWidth = 2;
            this.context.lineCap = 'round';
        }
    }
    
    handleMouseDown(event) {
        this.isDrawing = true;
        const rect = this.canvas.getBoundingClientRect();
        const x = event.clientX - rect.left;
        const y = event.clientY - rect.top;
        this.context.beginPath();
        this.context.moveTo(x, y);
    }
    
    handleMouseMove(event) {
        if (!this.isDrawing) return;
        const rect = this.canvas.getBoundingClientRect();
        const x = event.clientX - rect.left;
        const y = event.clientY - rect.top;
        this.context.lineTo(x, y);
        this.context.stroke();
    }
    
    handleMouseUp() {
        this.isDrawing = false;
    }
    
    handleClearCanvas() {
        if (this.context && this.canvas) {
            this.context.clearRect(0, 0, this.canvas.width, this.canvas.height);
        }
    }
    
    hasCanvasSignature() {
        if (!this.canvas || !this.context) return false;
        const imageData = this.context.getImageData(0, 0, this.canvas.width, this.canvas.height);
        return imageData.data.some((channel, index) => index % 4 !== 3 && channel !== 0);
    }

    // File upload handler
    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length > 0) {
            this.uploadedSignatureUrl = `/lightning/r/ContentDocument/${uploadedFiles[0].documentId}/view`;
            this.showToast('Success', 'Signature image uploaded successfully', 'success');
        }
    }

    // Submit signature
    async handleSubmitSignature() {
        this.isSubmitting = true;
        
        try {
            let signatureData = '';
            
            // Prepare signature data based on method
            if (this.selectedSignatureMethod === 'type') {
                signatureData = `TYPED:${this.typedSignature}`;
            } else if (this.selectedSignatureMethod === 'draw') {
                signatureData = `DRAWN:${this.canvas.toDataURL()}`;
            } else if (this.selectedSignatureMethod === 'upload') {
                signatureData = `UPLOADED:${this.uploadedSignatureUrl}`;
            }
            
            // Submit the signature
            await submitSignature({
                requestId: this.recordId,
                signatureData: signatureData,
                signerName: this.signerName,
                signerEmail: this.signerEmail
            });
            
            this.showToast('Success', 'Signature submitted successfully!', 'success');
            
            // Optionally navigate away or refresh
            // this.handleCancel();
            
        } catch (error) {
            this.showToast('Error', error.body.message || 'Failed to submit signature', 'error');
        } finally {
            this.isSubmitting = false;
        }
    }
    
    handleCancel() {
        // Navigate back or close modal
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }
    
    // Helper methods
    loadDocumentContent(documentId) {
        // Mock document content - in real implementation, load from DocumentLifecycleConfiguration__c
        this.documentContent = `This is a sample document that requires your electronic signature. Document ID: ${documentId}. Please review the terms and conditions before signing.`;
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

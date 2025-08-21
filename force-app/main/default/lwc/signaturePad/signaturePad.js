import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import submitSignature from '@salesforce/apex/SignatureRequestController.submitSignature';
import getSignatureRequest from '@salesforce/apex/SignatureRequestController.getSignatureRequest';

export default class SignaturePad extends LightningElement {
    @api recordId; // Signature Request ID
    
    // Signer information
    @track signerName = '';
    @track signerEmail = '';
    @track documentContent = '';
    
    // Signature method
    @track selectedSignatureMethod = 'type';
    @track typedSignature = '';
    @track drawnSignatureData = '';
    @track uploadedImageUrl = '';
    
    // Canvas drawing state
    @track isDrawing = false;
    @track lastX = 0;
    @track lastY = 0;
    
    // Form state
    @track agreementChecked = false;
    @track isSignatureComplete = false;
    @track isSubmitting = false;
    
    // Signature method options
    signatureMethodOptions = [
        { label: 'Type Signature', value: 'type' },
        { label: 'Draw Signature', value: 'draw' },
        { label: 'Upload Image', value: 'upload' }
    ];
    
    // Computed properties
    get isTypeSignature() {
        return this.selectedSignatureMethod === 'type';
    }
    
    get isDrawSignature() {
        return this.selectedSignatureMethod === 'draw';
    }
    
    get isUploadSignature() {
        return this.selectedSignatureMethod === 'upload';
    }
    
    get isSubmitDisabled() {
        if (!this.agreementChecked || !this.signerName || !this.signerEmail) {
            return true;
        }
        
        switch (this.selectedSignatureMethod) {
            case 'type':
                return !this.typedSignature;
            case 'draw':
                return !this.drawnSignatureData;
            case 'upload':
                return !this.uploadedImageUrl;
            default:
                return true;
        }
    }
    
    // Lifecycle hooks
    connectedCallback() {
        this.loadSignatureRequest();
        // Set up canvas after component renders
        setTimeout(() => {
            this.initializeCanvas();
        }, 100);
    }
    
    renderedCallback() {
        if (this.isDrawSignature && !this.canvasInitialized) {
            this.initializeCanvas();
        }
    }
    
    // Data loading
    async loadSignatureRequest() {
        if (!this.recordId) return;
        
        try {
            const request = await getSignatureRequest({ requestId: this.recordId });
            this.signerEmail = request.SignerEmail__c;
            this.signerName = request.SignerName__c;
            // Load document content (simplified)
            this.documentContent = 'Document content will be loaded here...';
        } catch (error) {
            this.showToast('Error', 'Failed to load signature request: ' + error.body?.message, 'error');
        }
    }
    
    // Canvas initialization and drawing
    initializeCanvas() {
        const canvas = this.template.querySelector('.signature-canvas');
        if (!canvas) return;
        
        canvas.width = 400;
        canvas.height = 200;
        
        const ctx = canvas.getContext('2d');
        ctx.strokeStyle = '#000000';
        ctx.lineWidth = 2;
        ctx.lineCap = 'round';
        ctx.lineJoin = 'round';
        
        this.canvas = canvas;
        this.ctx = ctx;
        this.canvasInitialized = true;
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
        // Clear previous signature data
        this.typedSignature = '';
        this.drawnSignatureData = '';
        this.uploadedImageUrl = '';
    }
    
    handleTypedSignatureChange(event) {
        this.typedSignature = event.target.value;
    }
    
    handleAgreementChange(event) {
        this.agreementChecked = event.target.checked;
    }
    
    // Mouse events for drawing
        handleMouseDown(event) {
        this.isDrawing = true;
        const rect = this.canvas.getBoundingClientRect();
        this.lastX = event.clientX - rect.left;
        this.lastY = event.clientY - rect.top;
        
        this.ctx.beginPath();
        this.ctx.moveTo(this.lastX, this.lastY);
    }

    handleMouseMove(event) {
        if (!this.isDrawing) return;
        
        const rect = this.canvas.getBoundingClientRect();
        const currentX = event.clientX - rect.left;
        const currentY = event.clientY - rect.top;
        
        this.ctx.lineTo(currentX, currentY);
        this.ctx.stroke();
        
        this.lastX = currentX;
        this.lastY = currentY;
    }

    handleMouseUp() {
        this.isDrawing = false;
        this.ctx.beginPath();
        this.updateDrawnSignature();
    }

    // Touch events for mobile support
    handleTouchStart(event) {
        event.preventDefault();
        const touch = event.touches[0];
        const mouseEvent = new MouseEvent('mousedown', {
            clientX: touch.clientX,
            clientY: touch.clientY
        });
        this.handleMouseDown(mouseEvent);
    }

    handleTouchMove(event) {
        event.preventDefault();
        const touch = event.touches[0];
        const mouseEvent = new MouseEvent('mousemove', {
            clientX: touch.clientX,
            clientY: touch.clientY
        });
        this.handleMouseMove(mouseEvent);
    }

    handleTouchEnd(event) {
        event.preventDefault();
        this.handleMouseUp();
    }

    // Canvas utility methods
    handleClearCanvas() {
        if (this.ctx && this.canvas) {
            this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
            this.drawnSignatureData = '';
        }
    }

    updateDrawnSignature() {
        if (this.canvas) {
            this.drawnSignatureData = this.canvas.toDataURL('image/png');
        }
    }

    // File upload handler
    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length > 0) {
            // In production, you would get the actual file URL from Salesforce Files
            this.uploadedImageUrl = '/servlet/servlet.FileDownload?file=' + uploadedFiles[0].documentId;
            this.showToast('Success', 'Signature image uploaded successfully', 'success');
        }
    }

    // Signature submission
    async handleSubmitSignature() {
        this.isSubmitting = true;
        
        try {
            const signatureData = this.getSignatureData();
            
            const result = await submitSignature({
                requestId: this.recordId,
                signatureData: signatureData,
                signatureMethod: this.selectedSignatureMethod
            });

            if (result) {
                this.isSignatureComplete = true;
                this.showToast('Success', 'Signature submitted successfully!', 'success');
                
                // Dispatch custom event for parent components
                this.dispatchEvent(new CustomEvent('signaturecomplete', {
                    detail: {
                        requestId: this.recordId,
                        signatureMethod: this.selectedSignatureMethod
                    }
                }));
            }
        } catch (error) {
            this.showToast('Error', 'Failed to submit signature: ' + error.body?.message, 'error');
        } finally {
            this.isSubmitting = false;
        }
    }

    // Get signature data based on method
    getSignatureData() {
        switch (this.selectedSignatureMethod) {
            case 'type':
                return this.typedSignature;
            case 'draw':
                return this.drawnSignatureData;
            case 'upload':
                return this.uploadedImageUrl;
            default:
                return '';
        }
    }

    // Cancel handler
    handleCancel() {
        // Navigate back or close modal
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    // Utility method for showing toast messages
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}

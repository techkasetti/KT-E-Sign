import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import executeCompleteWorkflow from '@salesforce/apex/IntegratedWorkflowController.executeCompleteWorkflow';
import processSignatureCompletion from '@salesforce/apex/DocGenESignIntegrationController.processSignatureCompletion';

export default class IntegratedDocGenSignature extends LightningElement {
    @api recordId;
    @track currentStep = 'document-generation';
    @track isLoading = false;
    @track workflowData = {};
    @track documentId;
    @track signatureRequestId;

    steps = [
        { label: 'Document Generation', value: 'document-generation' },
        { label: 'Review & Approve', value: 'review' },
        { label: 'Electronic Signature', value: 'signature' },
        { label: 'Completion', value: 'complete' }
    ];

    // Document Generation Form Fields
    @track documentForm = {
        region: 'US',
        role: 'Manager',
        contractType: 'Employment',
        documentTitle: '',
        signerEmail: ''
    };

    handleInputChange(event) {
        const field = event.target.dataset.field;
        this.documentForm[field] = event.target.value;
    }

    async handleGenerateAndSign() {
        this.isLoading = true;
        try {
            const result = await executeCompleteWorkflow({
                documentParams: {
                    region: this.documentForm.region,
                    role: this.documentForm.role,
                    contractType: this.documentForm.contractType,
                    documentTitle: this.documentForm.documentTitle,
                    signerEmail: this.documentForm.signerEmail
                },
                signatureParams: {
                    signerEmail: this.documentForm.signerEmail
                }
            });

            if (result.success) {
                this.documentId = result.documentId;
                this.signatureRequestId = result.signatureRequestId;
                this.currentStep = 'review';
                this.showToast('Success', 'Document generated and signature request initiated', 'success');
            } else {
                this.showToast('Error', result.error, 'error');
            }
        } catch (error) {
            this.showToast('Error', 'Workflow execution failed: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleProceedToSignature() {
        this.currentStep = 'signature';
    }

    async handleSignatureComplete() {
        this.isLoading = true;
        try {
            const result = await processSignatureCompletion({
                signatureRequestId: this.signatureRequestId
            });

            if (result.success) {
                this.currentStep = 'complete';
                this.showToast('Success', 'Document signed successfully', 'success');
            } else {
                this.showToast('Error', result.error, 'error');
            }
        } catch (error) {
            this.showToast('Error', 'Signature processing failed: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    get isDocumentGeneration() { return this.currentStep === 'document-generation'; }
    get isReview() { return this.currentStep === 'review'; }
    get isSignature() { return this.currentStep === 'signature'; }
    get isComplete() { return this.currentStep === 'complete'; }
}

import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generateDocument from '@salesforce/apex/DocumentLifecycleDeploymentManager.generateDocument';
import initiateSignatureRequest from '@salesforce/apex/SignatureRequestController.initiateSignatureRequest';

export default class DocumentGenerator extends LightningElement {
    @track currentStep = 'step-1';
    @track selectedRegion = '';
    @track selectedRole = '';
    @track selectedContractType = '';
    @track documentTitle = '';
    @track additionalNotes = '';
    @track generatedClause = '';
    @track generatedDocumentId = '';
    @track complianceStatus = false;
    @track complianceMessage = '';
    @track signerEmail = '';
    @track signerName = '';
    @track isGenerating = false;

    // Options for dropdowns
    regionOptions = [
        { label: 'United States', value: 'US' },
        { label: 'European Union', value: 'EU' },
        { label: 'Asia Pacific', value: 'APAC' },
        { label: 'Global', value: 'Global' }
    ];

    roleOptions = [
        { label: 'Manager', value: 'Manager' },
        { label: 'Director', value: 'Director' },
        { label: 'Vice President', value: 'VP' },
        { label: 'C-Level', value: 'C-Level' }
    ];

    contractTypeOptions = [
        { label: 'Employment Agreement', value: 'Employment' },
        { label: 'Non-Disclosure Agreement', value: 'NDA' },
        { label: 'Service Agreement', value: 'Service Agreement' },
        { label: 'Partnership Agreement', value: 'Partnership' }
    ];

    // Computed properties for step visibility
    get isStep1() { return this.currentStep === 'step-1'; }
    get isStep2() { return this.currentStep === 'step-2'; }
    get isStep3() { return this.currentStep === 'step-3'; }
    get isStep4() { return this.currentStep === 'step-4'; }

    get isNextDisabled() {
        if (this.isStep1) {
            return !this.selectedRegion || !this.selectedRole || !this.selectedContractType;
        }
        if (this.isStep2) {
            return !this.documentTitle;
        }
        return false;
    }

    get isSignatureRequestDisabled() {
        return !this.signerEmail || !this.signerName || !this.generatedDocumentId;
    }

    get complianceStatusClass() {
        return this.complianceStatus ? 'compliance-success' : 'compliance-error';
    }

    get complianceIcon() {
        return this.complianceStatus ? 'utility:success' : 'utility:error';
    }

    // Event handlers
    handleRegionChange(event) { this.selectedRegion = event.detail.value; }
    handleRoleChange(event) { this.selectedRole = event.detail.value; }
    handleContractTypeChange(event) { this.selectedContractType = event.detail.value; }
    handleTitleChange(event) { this.documentTitle = event.detail.value; }
    handleNotesChange(event) { this.additionalNotes = event.detail.value; }
    handleSignerEmailChange(event) { this.signerEmail = event.detail.value; }
    handleSignerNameChange(event) { this.signerName = event.detail.value; }

    handleNext() {
        if (this.currentStep === 'step-1') {
            this.currentStep = 'step-2';
        } else if (this.currentStep === 'step-2') {
            this.currentStep = 'step-3';
        } else if (this.currentStep === 'step-3') {
            this.currentStep = 'step-4';
        }
    }

    handlePrevious() {
        if (this.currentStep === 'step-2') {
            this.currentStep = 'step-1';
        } else if (this.currentStep === 'step-3') {
            this.currentStep = 'step-2';
        } else if (this.currentStep === 'step-4') {
            this.currentStep = 'step-3';
        }
    }

    async handleGenerateDocument() {
        this.isGenerating = true;
        try {
            const documentId = await generateDocument({
                region: this.selectedRegion,
                role: this.selectedRole,
                contractType: this.selectedContractType,
                title: this.documentTitle
            });

            this.generatedDocumentId = documentId;
            this.complianceStatus = true;
            this.complianceMessage = 'Document passed compliance validation';
            
            this.showToast('Success', 'Document generated successfully!', 'success');
            this.handleNext();
        } catch (error) {
            this.showToast('Error', error.body.message, 'error');
            this.complianceStatus = false;
            this.complianceMessage = 'Document failed compliance validation';
        } finally {
            this.isGenerating = false;
        }
    }

    async handleSendSignatureRequest() {
        try {
            const requestId = await initiateSignatureRequest({
                documentId: this.generatedDocumentId,
                signerEmail: this.signerEmail,
                signerName: this.signerName
            });

            this.showToast('Success', 'Signature request sent successfully!', 'success');
            // Reset form or navigate to next step
        } catch (error) {
            this.showToast('Error', error.body.message, 'error');
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

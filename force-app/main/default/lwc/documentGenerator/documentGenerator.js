import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generateClause from '@salesforce/apex/ClauseGenerator.generateClause';
import validateClause from '@salesforce/apex/ComplianceChecker.validateClause';
import initiateSignatureRequest from '@salesforce/apex/SignatureRequestController.initiateSignatureRequest';

export default class DocumentGenerator extends LightningElement {
    // Step management
    @track currentStep = 'step-1';
    
    // Form data
    @track selectedRegion = '';
    @track selectedRole = '';
    @track selectedContractType = '';
    @track documentTitle = '';
    @track additionalNotes = '';
    
    // Generated content
    @track generatedClause = '';
    @track generatedDocumentId = '';
    @track generationTimestamp = '';
    
    // Loading states
    @track isLoadingClause = false;
    @track isCheckingCompliance = false;
    @track isGenerating = false;
    
    // Compliance status
    @track complianceStatus = false;
    @track complianceStatusLabel = 'Pending';
    @track complianceVariant = 'warning';
    
    // Signature modal
    @track showSignatureModal = false;
    @track signerEmail = '';
    @track signerName = '';

    // Options for dropdowns
    regionOptions = [
        { label: 'United States', value: 'US' },
        { label: 'European Union', value: 'EU' },
        { label: 'India', value: 'IN' },
        { label: 'Global', value: 'Global' }
    ];

    roleOptions = [
        { label: 'Manager', value: 'Manager' },
        { label: 'Employee', value: 'Employee' },
        { label: 'Administrator', value: 'Admin' }
    ];

    contractTypeOptions = [
        { label: 'Employment Contract', value: 'Employment' },
        { label: 'Non-Disclosure Agreement', value: 'NDA' },
        { label: 'Service Level Agreement', value: 'SLA' }
    ];

    // Computed properties for step management
    get isStep1() { return this.currentStep === 'step-1'; }
    get isStep2() { return this.currentStep === 'step-2'; }
    get isStep3() { return this.currentStep === 'step-3'; }
    get isStep4() { return this.currentStep === 'step-4'; }
    
    get isFirstStep() { return this.currentStep === 'step-1'; }
    get isLastStep() { return this.currentStep === 'step-4'; }
    
    get isNextDisabled() {
        if (this.isStep1) {
            return !this.selectedRegion || !this.selectedRole || !this.selectedContractType;
        }
        if (this.isStep2) {
            return !this.documentTitle;
        }
        if (this.isStep3) {
            return !this.complianceStatus;
        }
        return false;
    }
    
    get isGenerateDisabled() {
        return this.isStep3 && (!this.complianceStatus || this.isCheckingCompliance);
    }
    
    get isSendDisabled() {
        return !this.signerEmail || !this.signerName;
    }

    // Event handlers for form inputs
    handleRegionChange(event) {
        this.selectedRegion = event.detail.value;
    }

    handleRoleChange(event) {
        this.selectedRole = event.detail.value;
    }

    handleContractTypeChange(event) {
        this.selectedContractType = event.detail.value;
    }

    handleDocumentTitleChange(event) {
        this.documentTitle = event.detail.value;
    }

    handleNotesChange(event) {
        this.additionalNotes = event.detail.value;
    }

    handleSignerEmailChange(event) {
        this.signerEmail = event.detail.value;
    }

    handleSignerNameChange(event) {
        this.signerName = event.detail.value;
    }

    // Navigation handlers
    handleNext() {
        if (this.currentStep === 'step-1') {
            this.currentStep = 'step-2';
        } else if (this.currentStep === 'step-2') {
            this.currentStep = 'step-3';
            this.generateClauseAndValidate();
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

    // Generate clause and validate compliance
    async generateClauseAndValidate() {
        this.isLoadingClause = true;
        this.isCheckingCompliance = true;
        
        try {
            // Generate clause
            const clause = await generateClause({
                region: this.selectedRegion,
                role: this.selectedRole,
                contractType: this.selectedContractType
            });
            
            this.generatedClause = clause;
            this.isLoadingClause = false;
            
            // Validate compliance
            const isCompliant = await validateClause({
                clause: clause,
                region: this.selectedRegion,
                contractType: this.selectedContractType
            });
            
            this.complianceStatus = isCompliant;
            this.complianceStatusLabel = isCompliant ? 'Compliant' : 'Non-Compliant';
            this.complianceVariant = isCompliant ? 'success' : 'error';
            this.isCheckingCompliance = false;
            
        } catch (error) {
            this.isLoadingClause = false;
            this.isCheckingCompliance = false;
            this.showToast('Error', 'Failed to generate clause: ' + error.body?.message, 'error');
        }
    }

    // Generate document
    handleGenerate() {
        this.isGenerating = true;
        
        // Simulate document generation (replace with actual Apex call)
        setTimeout(() => {
            this.generatedDocumentId = 'DOC-' + Date.now();
            this.generationTimestamp = new Date().toLocaleString();
            this.isGenerating = false;
            
            this.showToast('Success', 'Document generated successfully!', 'success');
        }, 3000);
    }

    // Signature request handlers
    handleRequestSignature() {
        this.showSignatureModal = true;
    }

    handleCloseModal() {
        this.showSignatureModal = false;
        this.signerEmail = '';
        this.signerName = '';
    }

    async handleSendSignatureRequest() {
        try {
            const requestId = await initiateSignatureRequest({
                documentId: this.generatedDocumentId,
                signerEmail: this.signerEmail,
                signerName: this.signerName
            });
            
            this.showToast('Success', 'Signature request sent successfully!', 'success');
            this.handleCloseModal();
            
            // Navigate to signature request record (optional)
            // this[NavigationMixin.Navigate]({
            //     type: 'standard__recordPage',
            //     attributes: {
            //         recordId: requestId,
            //         actionName: 'view'
            //     }
            // });
            
       // I notice we already completed the HTML template in the previous response. Let me continue from where the JavaScript file was cut off:
        } catch (error) {
            this.showToast('Error', 'Failed to send signature request: ' + error.body?.message, 'error');
        }
    }

    handleViewDocument() {
        // Navigate to document view (implement based on your document storage)
        this.showToast('Info', 'Document view functionality to be implemented', 'info');
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

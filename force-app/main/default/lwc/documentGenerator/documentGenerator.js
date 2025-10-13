import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generateDocument from '@salesforce/apex/DocumentLifecycleDeploymentManager.generateDocument';
import createSignatureRequest from '@salesforce/apex/SignatureRequestController.createSignatureRequest';

export default class DocumentGenerator extends LightningElement {
    @track selectedRegion = '';
    @track selectedRole = '';
    @track selectedContractType = '';
    @track documentTitle = '';
    @track generatedDocument = null;
    @track generatedClause = '';
    @track complianceStatus = '';
    @track isGenerating = false;
    @track showModal = false;
    @track signerEmail = '';
    @track signerName = '';
    @track isProcessing = false;

    get regionOptions() {
        return [
            { label: 'United States', value: 'US' },
            { label: 'European Union', value: 'EU' },
            { label: 'Asia Pacific', value: 'APAC' },
            { label: 'Global', value: 'Global' }
        ];
    }

    get roleOptions() {
        return [
            { label: 'Manager', value: 'Manager' },
            { label: 'Director', value: 'Director' },
            { label: 'Vice President', value: 'VP' },
            { label: 'C-Level Executive', value: 'C-Level' },
            { label: 'Employee', value: 'Employee' }
        ];
    }

    get contractTypeOptions() {
        return [
            { label: 'Employment Agreement', value: 'Employment' },
            { label: 'Non-Disclosure Agreement', value: 'NDA' },
            { label: 'Service Agreement', value: 'Service Agreement' },
            { label: 'Partnership Agreement', value: 'Partnership' }
        ];
    }

    get complianceVariant() {
        return this.complianceStatus === 'Compliant' ? 'success' : 'warning';
    }

    get isFormValid() {
        return this.selectedRegion && this.selectedRole && this.selectedContractType && this.documentTitle;
    }

    handleRegionChange(event) {
        this.selectedRegion = event.detail.value;
    }

    handleRoleChange(event) {
        this.selectedRole = event.detail.value;
    }

    handleContractTypeChange(event) {
        this.selectedContractType = event.detail.value;
    }

    handleTitleChange(event) {
        this.documentTitle = event.detail.value;
    }

    async generateDocument() {
        if (!this.isFormValid) {
            this.showToast('Error', 'Please fill in all required fields', 'error');
            return;
        }

        this.isGenerating = true;
        try {
            const result = await generateDocument({
                region: this.selectedRegion,
                role: this.selectedRole,
                contractType: this.selectedContractType,
                documentTitle: this.documentTitle
            });

            if (result.success) {
                this.generatedDocument = result;
                this.generatedClause = result.generatedClause;
                this.complianceStatus = result.complianceStatus;
                this.showToast('Success', 'Document generated successfully', 'success');
            } else {
                this.showToast('Error', result.errorMessage, 'error');
            }
        } catch (error) {
            this.showToast('Error', 'An error occurred while generating the document', 'error');
            console.error('Generate Document Error:', error);
        } finally {
            this.isGenerating = false;
        }
    }

    showSignatureRequest() {
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
        this.signerEmail = '';
        this.signerName = '';
    }

    handleSignerEmailChange(event) {
        this.signerEmail = event.detail.value;
    }

    handleSignerNameChange(event) {
        this.signerName = event.detail.value;
    }

    async sendSignatureRequest() {
        if (!this.signerEmail || !this.signerName) {
            this.showToast('Error', 'Please enter signer email and name', 'error');
            return;
        }

        this.isProcessing = true;
        try {
            const result = await createSignatureRequest({
                documentId: this.generatedDocument.documentId,
                signerEmail: this.signerEmail,
                signerName: this.signerName
            });

            if (result.success) {
                this.showToast('Success', 'Signature request sent successfully', 'success');
                this.closeModal();
            } else {
                this.showToast('Error', result.errorMessage, 'error');
            }
        } catch (error) {
            this.showToast('Error', 'An error occurred while sending signature request', 'error');
            console.error('Send Signature Request Error:', error);
        } finally {
            this.isProcessing = false;
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




//  Developer_build_step_by_step_impl_e_sign v10------------------------------------------------------------


// import { LightningElement, track } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import generateDocument from '@salesforce/apex/DocumentLifecycleDeploymentManager.generateDocument';
// import validateCompliance from '@salesforce/apex/ComplianceChecker.validateCompliance';
// import initiateSignatureRequest from '@salesforce/apex/SignatureRequestController.initiateSignatureRequest';
// import generateClause from '@salesforce/apex/ClauseGenerator.generateClause';

// export default class DocumentGenerator extends LightningElement {
//     @track currentStep = 'step1';
//     @track region = '';
//     @track role = '';
//     @track contractType = '';
//     @track documentTitle = '';
//     @track notes = '';
//     @track previewClause = '';
//     @track complianceResult = null;
//     @track complianceScore = 0;
//     @track complianceStatus = '';
//     @track violations = [];
//     @track recommendations = [];
//     @track documentGenerated = false;
//     @track generatedDocumentId = '';
//     @track isGenerating = false;
//     @track showSignatureModal = false;
//     @track signerEmail = '';
//     @track signerName = '';
//     @track signatureMessage = '';

//     // Dropdown options
//     get regionOptions() {
//         return [
//             { label: 'United States', value: 'US' },
//             { label: 'European Union', value: 'EU' },
//             { label: 'Asia Pacific', value: 'APAC' },
//             { label: 'Global', value: 'Global' }
//         ];
//     }

//     get roleOptions() {
//         return [
//             { label: 'Manager', value: 'Manager' },
//             { label: 'Director', value: 'Director' },
//             { label: 'Vice President', value: 'VP' },
//             { label: 'C-Level Executive', value: 'C-Level' },
//             { label: 'Employee', value: 'Employee' }
//         ];
//     }

//     get contractTypeOptions() {
//         return [
//             { label: 'Employment Agreement', value: 'Employment' },
//             { label: 'Non-Disclosure Agreement', value: 'NDA' },
//             { label: 'Service Agreement', value: 'Service Agreement' },
//             { label: 'Partnership Agreement', value: 'Partnership' }
//         ];
//     }

//     // Step visibility computed properties
//     get isStep1() { return this.currentStep === 'step1'; }
//     get isStep2() { return this.currentStep === 'step2'; }
//     get isStep3() { return this.currentStep === 'step3'; }
//     get isStep4() { return this.currentStep === 'step4'; }
//     get isFirstStep() { return this.currentStep === 'step1'; }
//     get isLastStep() { return this.currentStep === 'step4'; }

//     // Validation computed properties
//     get isNextDisabled() {
//         if (this.currentStep === 'step1') {
//             return !this.region || !this.role || !this.contractType || !this.documentTitle;
//         }
//         if (this.currentStep === 'step2') {
//             return !this.previewClause;
//         }
//         if (this.currentStep === 'step3') {
//             return !this.complianceResult || this.complianceScore < 75;
//         }
//         return false;
//     }

//     get isCompleteDisabled() {
//         return !this.documentGenerated;
//     }

//     get isSendDisabled() {
//         return !this.signerEmail || !this.signerName;
//     }

//     // Compliance display properties
//     get complianceBoxClass() {
//         if (this.complianceScore >= 75) {
//             return 'slds-box slds-theme_success';
//         }
//         return 'slds-box slds-theme_warning';
//     }

//     get hasViolations() {
//         return this.violations && this.violations.length > 0;
//     }

//     get hasRecommendations() {
//         return this.recommendations && this.recommendations.length > 0;
//     }

//     // Event handlers
//     handleInputChange(event) {
//         const field = event.target.name;
//         const value = event.target.value;
//         this[field] = value;
//     }

//     handleNext() {
//         const stepOrder = ['step1', 'step2', 'step3', 'step4'];
//         const currentIndex = stepOrder.indexOf(this.currentStep);
//         if (currentIndex < stepOrder.length - 1) {
//             this.currentStep = stepOrder[currentIndex + 1];
//         }
//     }

//     handlePrevious() {
//         const stepOrder = ['step1', 'step2', 'step3', 'step4'];
//         const currentIndex = stepOrder.indexOf(this.currentStep);
//         if (currentIndex > 0) {
//             this.currentStep = stepOrder[currentIndex - 1];
//         }
//     }

//     async generatePreviewClause() {
//         if (!this.region || !this.role || !this.contractType) {
//             this.showToast('Error', 'Please select all required fields', 'error');
//             return;
//         }

//         try {
//             this.previewClause = await generateClause({
//                 region: this.region,
//                 role: this.role,
//                 contractType: this.contractType
//             });
//             this.showToast('Success', 'Preview clause generated successfully', 'success');
//         } catch (error) {
//             this.showToast('Error', 'Failed to generate preview: ' + error.body.message, 'error');
//         }
//     }

//     async performComplianceCheck() {
//         if (!this.previewClause) {
//             this.showToast('Error', 'Please generate preview clause first', 'error');
//             return;
//         }

//         try {
//             this.complianceResult = await validateCompliance({
//                 clause: this.previewClause,
//                 region: this.region,
//                 contractType: this.contractType
//             });
            
//             this.complianceScore = this.complianceResult.complianceScore;
//             this.complianceStatus = this.complianceResult.isCompliant ? 'Compliant' : 'Requires Review';
//             this.violations = this.complianceResult.violations || [];
//             this.recommendations = this.complianceResult.recommendations || [];
            
//             const variant = this.complianceResult.isCompliant ? 'success' : 'warning';
//             this.showToast('Compliance Check Complete', 
//                           'Compliance score: ' + this.complianceScore + '%', 
//                           variant);
//         } catch (error) {
//             this.showToast('Error', 'Compliance check failed: ' + error.body.message, 'error');
//         }
//     }

//     async handleGenerateDocument() {
//         this.isGenerating = true;
        
//         try {
//             this.generatedDocumentId = await generateDocument({
//                 region: this.region,
//                 role: this.role,
//                 contractType: this.contractType,
//                 documentTitle: this.documentTitle
//             });
            
//             this.documentGenerated = true;
//             this.showToast('Success', 'Document generated successfully!', 'success');
//         } catch (error) {
//             this.showToast('Error', 'Failed to generate document: ' + error.body.message, 'error');
//         } finally {
//             this.isGenerating = false;
//         }
//     }

//     openSignatureRequestModal() {
//         this.showSignatureModal = true;
//     }

//     closeSignatureModal() {
//         this.showSignatureModal = false;
//         this.signerEmail = '';
//         this.signerName = '';
//         this.signatureMessage = '';
//     }

//     async sendSignatureRequest() {
//         try {
//             await initiateSignatureRequest({
//                 documentId: this.generatedDocumentId,
//                 signerEmail: this.signerEmail,
//                 signerName: this.signerName
//             });
            
//             this.showToast('Success', 'Signature request sent successfully!', 'success');
//             this.closeSignatureModal();
//         } catch (error) {
//             this.showToast('Error', 'Failed to send signature request: ' + error.body.message, 'error');
//         }
//     }

//     handleComplete() {
//         this.showToast('Complete', 'Document generation workflow completed!', 'success');
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





// Developer_build_step_by_step_impl_e_sign v6................................................................


// import { LightningElement, track } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import { NavigationMixin } from 'lightning/navigation';

// // Import Apex methods
// import generateDocument from '@salesforce/apex/DocumentLifecycleDeploymentManager.generateDocument';
// import validateCompliance from '@salesforce/apex/ComplianceChecker.validateCompliance';
// import initiateSignatureRequest from '@salesforce/apex/SignatureRequestController.initiateSignatureRequest';

// export default class DocumentGenerator extends NavigationMixin(LightningElement) {
//     // Step management
//     @track currentStep = 'step-1';
    
//     // Form data
//     @track selectedRegion = '';
//     @track selectedRole = '';
//     @track selectedContractType = '';
//     @track documentTitle = '';
//     @track documentNotes = '';
    
//     // Generation results
//     @track generatedDocumentId = '';
//     @track complianceResult = null;
//     @track complianceScore = 0;
//     @track complianceStatus = '';
//     @track complianceViolations = [];
//     @track complianceRecommendation = '';
    
//     // Modal data
//     @track showSignatureModal = false;
//     @track signerEmail = '';
//     @track signerName = '';
//     @track signatureMessage = '';
    
//     // Loading states
//     @track isLoading = false;
//     @track isGenerating = false;

//     // Computed properties
//     get isStep1() { return this.currentStep === 'step-1'; }
//     get isStep2() { return this.currentStep === 'step-2'; }
//     get isStep3() { return this.currentStep === 'step-3'; }
//     get isStep4() { return this.currentStep === 'step-4'; }
    
//     get regionOptions() {
//         return [
//             { label: 'United States', value: 'US' },
//             { label: 'European Union', value: 'EU' },
//             { label: 'Asia Pacific', value: 'APAC' },
//             { label: 'Global', value: 'Global' }
//         ];
//     }
    
//     get roleOptions() {
//         return [
//             { label: 'Manager', value: 'Manager' },
//             { label: 'Director', value: 'Director' },
//             { label: 'Vice President', value: 'VP' },
//             { label: 'C-Level Executive', value: 'C-Level' },
//             { label: 'Employee', value: 'Employee' }
//         ];
//     }
    
//     get contractTypeOptions() {
//         return [
//             { label: 'Employment Agreement', value: 'Employment' },
//             { label: 'Non-Disclosure Agreement', value: 'NDA' },
//             { label: 'Service Agreement', value: 'Service Agreement' },
//             { label: 'Partnership Agreement', value: 'Partnership' }
//         ];
//     }
    
//     get isNextDisabled() {
//         if (this.isStep1) {
//             return !this.selectedRegion || !this.selectedRole || !this.selectedContractType;
//         }
//         if (this.isStep2) {
//             return !this.documentTitle;
//         }
//         return false;
//     }
    
//     get isGenerateDisabled() {
//         return !this.selectedRegion || !this.selectedRole || !this.selectedContractType || !this.documentTitle;
//     }
    
//     get isSendDisabled() {
//         return !this.signerEmail || !this.signerName || !this.generatedDocumentId;
//     }
    
//     get complianceStatusClass() {
//         return this.complianceResult?.isCompliant ? 'slds-text-color_success' : 'slds-text-color_error';
//     }
    
//     get complianceIcon() {
//         return this.complianceResult?.isCompliant ? 'utility:success' : 'utility:warning';
//     }
    
//     get hasViolations() {
//         return this.complianceViolations && this.complianceViolations.length > 0;
//     }

//     // Event handlers
//     handleRegionChange(event) {
//         this.selectedRegion = event.detail.value;
//     }
    
//     handleRoleChange(event) {
//         this.selectedRole = event.detail.value;
//     }
    
//     handleContractTypeChange(event) {
//         this.selectedContractType = event.detail.value;
//     }
    
//     handleDocumentTitleChange(event) {
//         this.documentTitle = event.target.value;
//     }
    
//     handleDocumentNotesChange(event) {
//         this.documentNotes = event.target.value;
//     }
    
//     handleSignerEmailChange(event) {
//         this.signerEmail = event.target.value;
//     }
    
//     handleSignerNameChange(event) {
//         this.signerName = event.target.value;
//     }
    
//     handleSignatureMessageChange(event) {
//         this.signatureMessage = event.target.value;
//     }

//     // Navigation methods
//     handleNext() {
//         if (this.isStep1) {
//             this.currentStep = 'step-2';
//         } else if (this.isStep2) {
//             this.currentStep = 'step-3';
//             this.performComplianceCheck();
//         } else if (this.isStep3) {
//             this.currentStep = 'step-4';
//         }
//     }
    
//     handlePrevious() {
//         if (this.isStep2) {
//             this.currentStep = 'step-1';
//         } else if (this.isStep3) {
//             this.currentStep = 'step-2';
//         } else if (this.isStep4) {
//             this.currentStep = 'step-3';
//         }
//     }

//     // Compliance check
//     async performComplianceCheck() {
//         try {
//             // Generate a preview clause for compliance checking
//             const previewClause = this.generatePreviewClause();
            
//             const result = await validateCompliance({
//                 clause: previewClause,
//                 region: this.selectedRegion,
//                 contractType: this.selectedContractType
//             });
            
//             this.complianceResult = result;
//             this.complianceScore = result.complianceScore || 0;
//             this.complianceStatus = result.isCompliant ? 'Compliant' : 'Non-Compliant';
//             this.complianceViolations = result.violations || [];
//             this.complianceRecommendation = result.recommendation || '';
            
//         } catch (error) {
//             this.showToast('Error', 'Failed to check compliance: ' + error.body?.message, 'error');
//         }
//     }
    
//     generatePreviewClause() {
//         return `This ${this.selectedContractType} agreement is for ${this.selectedRole} in ${this.selectedRegion}. 
//                 ${this.documentTitle}. ${this.documentNotes || ''}. 
//                 Electronic signatures are legally binding and equivalent to handwritten signatures.`;
//     }

//     // Document generation
//     async handleGenerateDocument() {
//         this.isGenerating = true;
//         try {
//             const result = await generateDocument({
//                 region: this.selectedRegion,
//                 role: this.selectedRole,
//                 contractType: this.selectedContractType,
//                 documentTitle: this.documentTitle
//             });
            
//             if (result.isSuccess) {
//                 this.generatedDocumentId = result.documentId;
//                 this.showToast('Success', 'Document generated successfully!', 'success');
//             } else {
//                 this.showToast('Error', result.errorMessage, 'error');
//             }
//         } catch (error) {
//             this.showToast('Error', 'Failed to generate document: ' + error.body?.message, 'error');
//         } finally {
//             this.isGenerating = false;
//         }
//     }

//     // Modal management
//     handleOpenSignatureModal() {
//         this.showSignatureModal = true;
//     }
    
//     handleModalCancel() {
//         this.showSignatureModal = false;
//         this.signerEmail = '';
//         this.signerName = '';
//         this.signatureMessage = '';
//     }

//     // Signature request
//     async handleSendSignatureRequest() {
//         this.isLoading = true;
//         try {
//             const requestId = await initiateSignatureRequest({
//                 documentId: this.generatedDocumentId,
//                 signerEmail: this.signerEmail,
//                 signerName: this.signerName
//             });
            
//             this.showToast('Success', 'Signature request sent successfully!', 'success');
//             this.handleModalCancel();
            
//         } catch (error) {
//             this.showToast('Error', 'Failed to send signature request: ' + error.body?.message, 'error');
//         } finally {
//             this.isLoading = false;
//         }
//     }

//     // View document
//     handleViewDocument() {
//         this[NavigationMixin.Navigate]({
//             type: 'standard__recordPage',
//             attributes: {
//                 recordId: this.generatedDocumentId,
//                 objectApiName: 'DocumentLifecycleConfiguration__c',
//                 actionName: 'view'
//             }
//         });
//     }

//     // Reset form
//     handleResetForm() {
//         this.currentStep = 'step-1';
//         this.selectedRegion = '';
//         this.selectedRole = '';
//         this.selectedContractType = '';
//         this.documentTitle = '';
//         this.documentNotes = '';
//         this.generatedDocumentId = '';
//         this.complianceResult = null;
//         this.complianceScore = 0;
//         this.complianceStatus = '';
//         this.complianceViolations = [];
//         this.complianceRecommendation = '';
//         this.signerEmail = '';
//         this.signerName = '';
//         this.signatureMessage = '';
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







// Developer_build_step_by_step_impl_e_sign v3..........................................................


// import { LightningElement, track, api } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import generateDocument from '@salesforce/apex/DocumentLifecycleDeploymentManager.generateDocument';
// import validateCompliance from '@salesforce/apex/ComplianceChecker.validateCompliance';
// import initiateSignatureRequest from '@salesforce/apex/SignatureRequestController.initiateSignatureRequest';

// export default class DocumentGenerator extends LightningElement {
//     // Step management
//     @track currentStep = 'step-1';
    
//     // Form data
//     @track selectedRegion = '';
//     @track selectedRole = '';
//     @track selectedContractType = '';
//     @track documentTitle = '';
//     @track documentNotes = '';
    
//     // Generated content
//     @track previewClause = '';
//     @track generatedDocumentId = '';
    
//     // Compliance data
//     @track complianceResult = null;
//     @track complianceScore = 0;
//     @track complianceStatus = '';
//     @track complianceViolations = [];
//     @track complianceRecommendation = '';
    
//     // Modal data
//     @track showSignatureModal = false;
//     @track signerEmail = '';
//     @track signerName = '';
    
//     // Loading state
//     @track isLoading = false;
    
//     // Computed properties
//     get regionOptions() {
//         return [
//             { label: 'United States', value: 'US' },
//             { label: 'European Union', value: 'EU' },
//             { label: 'Asia Pacific', value: 'APAC' },
//             { label: 'Global', value: 'Global' }
//         ];
//     }
    
//     get roleOptions() {
//         return [
//             { label: 'Manager', value: 'Manager' },
//             { label: 'Director', value: 'Director' },
//             { label: 'VP', value: 'VP' },
//             { label: 'C-Level', value: 'C-Level' },
//             { label: 'Employee', value: 'Employee' }
//         ];
//     }
    
//     get contractTypeOptions() {
//         return [
//             { label: 'Employment Agreement', value: 'Employment' },
//             { label: 'Non-Disclosure Agreement', value: 'NDA' },
//             { label: 'Service Agreement', value: 'Service Agreement' },
//             { label: 'Partnership Agreement', value: 'Partnership' }
//         ];
//     }
    
//     // Step computed properties
//     get isStep1() { return this.currentStep === 'step-1'; }
//     get isStep2() { return this.currentStep === 'step-2'; }
//     get isStep3() { return this.currentStep === 'step-3'; }
//     get isStep4() { return this.currentStep === 'step-4'; }

// get isStep4() {
//     return this.currentStep === 'step-4';
// }

// get isFirstStep() {
//     return this.currentStep === 'step-1';
// }

// get isLastStep() {
//     return this.currentStep === 'step-4';
// }

// get complianceBoxClass() {
//     if (!this.complianceResult) return 'slds-box';
//     return this.complianceResult.isCompliant
//         ? 'slds-box slds-theme_success'
//         : 'slds-box slds-theme_warning';
// }

// get complianceIcon() {
//     if (!this.complianceResult) return 'utility:info';
//     return this.complianceResult.isCompliant
//         ? 'utility:success'
//         : 'utility:warning';
// }

// get complianceStatusClass() {
//     if (!this.complianceResult) return '';
//     return this.complianceResult.isCompliant
//         ? 'slds-text-color_success'
//         : 'slds-text-color_error';
// }

// get hasViolations() {
//     return this.complianceViolations && this.complianceViolations.length > 0;
// }

// // -------------------- Event Handlers --------------------

// handleRegionChange(event) {
//     this.selectedRegion = event.detail.value;
//     this.generatePreviewClause();
// }

// handleRoleChange(event) {
//     this.selectedRole = event.detail.value;
//     this.generatePreviewClause();
// }

// handleContractTypeChange(event) {
//     this.selectedContractType = event.detail.value;
//     this.generatePreviewClause();
// }

// handleDocumentTitleChange(event) {
//     this.documentTitle = event.detail.value;
// }

// handleDocumentNotesChange(event) {
//     this.documentNotes = event.detail.value;
// }

// handleSignerEmailChange(event) {
//     this.signerEmail = event.detail.value;
// }

// handleSignerNameChange(event) {
//     this.signerName = event.detail.value;
// }

// // -------------------- Navigation Handlers --------------------

// handleNext() {
//     if (this.currentStep === 'step-1' && this.validateStep1()) {
//         this.currentStep = 'step-2';
//         this.generatePreviewClause();
//     } else if (this.currentStep === 'step-2') {
//         this.currentStep = 'step-3';
//         this.performComplianceCheck();
//     } else if (this.currentStep === 'step-3' && this.complianceResult) {
//         this.currentStep = 'step-4';
//     }
// }

// handlePrevious() {
//     if (this.currentStep === 'step-2') {
//         this.currentStep = 'step-1';
//     } else if (this.currentStep === 'step-3') {
//         this.currentStep = 'step-2';
//     } else if (this.currentStep === 'step-4') {
//         this.currentStep = 'step-3';
//     }
// }

// validateStep1() {
//     if (
//         !this.selectedRegion ||
//         !this.selectedRole ||
//         !this.selectedContractType ||
//         !this.documentTitle
//     ) {
//         this.showToast('Error', 'Please fill in all required fields', 'error');
//         return false;
//     }
//     return true;
// }

// // -------------------- Document Generation --------------------

// async generatePreviewClause() {
//     if (this.selectedRegion && this.selectedRole && this.selectedContractType) {
//         // For preview, simplified version
//         this.previewClause = `Preview: ${this.selectedContractType} agreement for ${this.selectedRole} in ${this.selectedRegion} region. 
//             This will include region-specific compliance terms and role-appropriate clauses.`;
//     }
// }

// async performComplianceCheck() {
//     this.isLoading = true;
//     try {
//         const result = await validateCompliance({
//             clause: this.previewClause,
//             region: this.selectedRegion,
//             contractType: this.selectedContractType
//         });

//         this.complianceResult = result;
//         this.complianceScore = result.complianceScore || 0;
//         this.complianceStatus = result.isCompliant ? 'Compliant' : 'Requires Review';
//         this.complianceViolations = result.violations || [];
//         this.complianceRecommendation = result.recommendation || '';

//         this.showToast(
//             'Compliance Check Complete',
//             result.isCompliant
//                 ? 'Document passes compliance validation'
//                 : 'Document requires review',
//             result.isCompliant ? 'success' : 'warning'
//         );
//     } catch (error) {
//         this.showToast(
//             'Error',
//             'Compliance check failed: ' + error.body.message,
//             'error'
//         );
//     } finally {
//         this.isLoading = false;
//     }
// }

// async handleGenerateDocument() {
//     this.isLoading = true;
//     try {
//         const documentId = await generateDocument({
//             region: this.selectedRegion,
//             role: this.selectedRole,
//             contractType: this.selectedContractType,
//             documentTitle: this.documentTitle
//         });

//         this.generatedDocumentId = documentId;
//         this.showToast('Success', 'Document generated successfully!', 'success');
//     } catch (error) {
//         this.showToast(
//             'Error',
//             'Document generation failed: ' + error.body.message,
//             'error'
//         );
//     } finally {
//         this.isLoading = false;
//     }
// }

// // -------------------- Modal Handlers --------------------

// handleOpenSignatureModal() {
//     this.showSignatureModal = true;
// }

// handleModalCancel() {
//     this.showSignatureModal = false;
//     this.signerEmail = '';
//     this.signerName = '';
// }

// async handleSendSignatureRequest() {
//     if (!this.signerEmail || !this.signerName) {
//         this.showToast('Error', 'Please provide signer email and name', 'error');
//         return;
//     }

//     this.isLoading = true;
//     try {
//         await initiateSignatureRequest({
//             documentId: this.generatedDocumentId,
//             signerEmail: this.signerEmail,
//             signerName: this.signerName
//         });

//         this.showToast('Success', 'Signature request sent successfully!', 'success');
//         this.handleModalCancel();
//     } catch (error) {
//         this.showToast(
//             'Error',
//             'Failed to send signature request: ' + error.body.message,
//             'error'
//         );
//     } finally {
//         this.isLoading = false;
//     }
// }

// handleViewDocument() {
//     // Navigate to document record page
//     this[NavigationMixin.Navigate]({
//         type: 'standard__recordPage',
//         attributes: {
//             recordId: this.generatedDocumentId,
//             objectApiName: 'DocumentLifecycleConfiguration__c',
//             actionName: 'view'
//         }
//     });
// }

// handleResetForm() {
//     this.currentStep = 'step-1';
//     this.selectedRegion = '';
//     this.selectedRole = '';
//     this.selectedContractType = '';
//     this.documentTitle = '';
//     this.documentNotes = '';
//     this.previewClause = '';
//     this.generatedDocumentId = '';
//     this.complianceResult = null;
//     this.complianceScore = 0;
//     this.complianceStatus = '';
//     this.complianceViolations = [];
//     this.complianceRecommendation = '';
//     this.signerEmail = '';
//     this.signerName = '';
//     this.showSignatureModal = false;
// }

// // -------------------- Utility --------------------

// showToast(title, message, variant) {
//     const evt = new ShowToastEvent({
//         title: title,
//         message: message,
//         variant: variant
//     });
//     this.dispatchEvent(evt);
// }




// Developer_build_step_by_step_impl_e_sign v2...............................................................


// import { LightningElement, track, api } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import generateDocument from '@salesforce/apex/DocumentLifecycleDeploymentManager.generateDocument';
// import performFullComplianceCheck from '@salesforce/apex/ComplianceChecker.performFullComplianceCheck';
// import initiateSignatureRequest from '@salesforce/apex/SignatureRequestController.initiateSignatureRequest';

// export default class DocumentGenerator extends LightningElement {
//     // Step management
//     @track currentStep = 'step-1';
    
//     // Form data
//     @track selectedRegion = '';
//     @track selectedRole = '';
//     @track selectedContractType = '';
//     @track documentTitle = '';
//     @track additionalNotes = '';
    
//     // Generation state
//     @track isGenerating = false;
//     @track generatedDocumentId = '';
//     @track generatedClause = '';
//     @track documentStatus = '';
//     @track generationTimestamp = '';
    
//     // Compliance state
//     @track isCheckingCompliance = false;
//     @track complianceResult = null;
//     @track complianceStatusText = '';
//     @track complianceDetails = '';
//     @track complianceIconName = '';
//     @track complianceIconVariant = '';
//     @track complianceBoxClass = '';
    
//     // Signature modal state
//     @track showSignatureModal = false;
//     @track signerEmail = '';
//     @track signerName = '';
//     @track signatureMessage = '';
//     @track isSendingRequest = false;

//     // Options for dropdowns
//     regionOptions = [
//         { label: 'United States', value: 'US' },
//         { label: 'European Union', value: 'EU' },
//         { label: 'Asia-Pacific', value: 'APAC' },
//         { label: 'Global', value: 'Global' }
//     ];

//     roleOptions = [
//         { label: 'Employee', value: 'Employee' },
//         { label: 'Manager', value: 'Manager' },
//         { label: 'Director', value: 'Director' },
//         { label: 'VP', value: 'VP' },
//         { label: 'C-Level', value: 'C-Level' }
//     ];

//     contractTypeOptions = [
//         { label: 'Employment Agreement', value: 'Employment' },
//         { label: 'Non-Disclosure Agreement', value: 'NDA' },
//         { label: 'Service Agreement', value: 'Service Agreement' },
//         { label: 'Partnership Agreement', value: 'Partnership' }
//     ];

//     // Computed properties for step visibility
//     get isStep1() { return this.currentStep === 'step-1'; }
//     get isStep2() { return this.currentStep === 'step-2'; }
//     get isStep3() { return this.currentStep === 'step-3'; }
//     get isStep4() { return this.currentStep === 'step-4'; }

//     // Navigation button states
//     get isPreviousDisabled() {
//         return this.currentStep === 'step-1' || this.isGenerating || this.isCheckingCompliance;
//     }

//     get isNextDisabled() {
//         if (this.currentStep === 'step-1') {
//             return !this.selectedRegion || !this.selectedRole || !this.selectedContractType || !this.documentTitle;
//         }
//         if (this.currentStep === 'step-2') {
//             return !this.generatedDocumentId || this.isGenerating;
//         }
//         if (this.currentStep === 'step-3') {
//             return !this.complianceResult || this.isCheckingCompliance;
//         }
//         return this.currentStep === 'step-4';
//     }

//     // Event handlers
//     handleRegionChange(event) {
//         this.selectedRegion = event.detail.value;
//     }

//     handleRoleChange(event) {
//         this.selectedRole = event.detail.value;
//     }

//     handleContractTypeChange(event) {
//         this.selectedContractType = event.detail.value;
//     }

//     handleTitleChange(event) {
//         this.documentTitle = event.detail.value;
//     }

//     handleNotesChange(event) {
//         this.additionalNotes = event.detail.value;
//     }

//     handleNext() {
//         const steps = ['step-1', 'step-2', 'step-3', 'step-4'];
//         const currentIndex = steps.indexOf(this.currentStep);
//         if (currentIndex < steps.length - 1) {
//             this.currentStep = steps[currentIndex + 1];
//         }
//     }

//     handlePrevious() {
//         const steps = ['step-1', 'step-2', 'step-3', 'step-4'];
//         const currentIndex = steps.indexOf(this.currentStep);
//         if (currentIndex > 0) {
//             this.currentStep = steps[currentIndex - 1];
//         }
//     }

//     async handleGenerateDocument() {
//         this.isGenerating = true;
//         try {
//             const documentId = await generateDocument({
//                 region: this.selectedRegion,
//                 role: this.selectedRole,
//                 contractType: this.selectedContractType,
//                 documentTitle: this.documentTitle
//             });

//             this.generatedDocumentId = documentId;
//             this.documentStatus = 'Generated';
//             this.generationTimestamp = new Date().toLocaleString();
            
//             this.showToast('Success', 'Document generated successfully!', 'success');
//             this.handleNext();
//         } catch (error) {
//             this.showToast('Error', 'Failed to generate document: ' + error.body.message, 'error');
//         } finally {
//             this.isGenerating = false;
//         }
//     }

//     async handleGeneratePreview() {
//         // For preview, we just simulate the generation without saving
//         this.isGenerating = true;
//         try {
//             // Simulate API call delay
//             await new Promise(resolve => setTimeout(resolve, 1000));
            
//             this.generatedClause = `Preview: This ${this.selectedContractType} document for ${this.selectedRole} in ${this.selectedRegion} region will contain region-specific terms, role-appropriate clauses, and signature requirements.`;
//             this.showToast('Success', 'Preview generated successfully!', 'success');
//         } catch (error) {
//             this.showToast('Error', 'Failed to generate preview: ' + error.message, 'error');
//         } finally {
//             this.isGenerating = false;
//         }
//     }

//     async handleRunComplianceCheck() {
//         if (!this.generatedDocumentId) {
//             this.showToast('Error', 'No document to check compliance for', 'error');
//             return;
//         }

//         this.isCheckingCompliance = true;
//         try {
//             const result = await performFullComplianceCheck({
//                 documentId: this.generatedDocumentId
//             });

//             this.complianceResult = result;
            
//             if (result.isCompliant) {
//                 this.complianceStatusText = 'Compliant';
//                 this.complianceDetails = 'Document meets all compliance requirements';
//                 this.complianceIconName = 'utility:success';
//                 this.complianceIconVariant = 'success';
//                 this.complianceBoxClass = 'slds-box slds-theme_success slds-m-bottom_medium';
//             } else {
//                 this.complianceStatusText = 'Non-Compliant';
//                 this.complianceDetails = 'Document requires review to meet compliance standards';
//                 this.complianceIconName = 'utility:warning';
//                 this.complianceIconVariant = 'warning';
//                 this.complianceBoxClass = 'slds-box slds-theme_warning slds-m-bottom_medium';
//             }

//             this.showToast(
//                 result.isCompliant ? 'Success' : 'Warning', 
//                 result.isCompliant ? 'Document is compliant' : 'Document needs compliance review',
//                 result.isCompliant ? 'success' : 'warning'
//             );
//         } catch (error) {
//             this.showToast('Error', 'Failed to check compliance: ' + error.body.message, 'error');
//             this.complianceResult = null;
//         } finally {
//             this.isCheckingCompliance = false;
//         }
//     }

//     handleOpenSignatureModal() {
//         this.showSignatureModal = true;
//         this.signerEmail = '';
//         this.signerName = '';
//         this.signatureMessage = '';
//     }

//     handleCloseModal() {
//         this.showSignatureModal = false;
//     }

//     handleSignerEmailChange(event) {
//         this.signerEmail = event.detail.value;
//     }

//     handleSignerNameChange(event) {
//         this.signerName = event.detail.value;
//     }

//     handleSignatureMessageChange(event) {
//         this.signatureMessage = event.detail.value;
//     }

//     async handleSendSignatureRequest() {
//         if (!this.signerEmail || !this.signerName) {
//             this.showToast('Error', 'Please provide both signer email and name', 'error');
//             return;
//         }

//         this.isSendingRequest = true;
//         try {
//             const requestId = await initiateSignatureRequest({
//                 documentId: this.generatedDocumentId,
//                 signerEmail: this.signerEmail,
//                 signerName: this.signerName
//             });

//             this.showToast('Success', 'Signature request sent successfully!', 'success');
//             this.handleCloseModal();
//         } catch (error) {
//             this.showToast('Error', 'Failed to send signature request: ' + error.body.message, 'error');
//         } finally {
//             this.isSendingRequest = false;
//         }
//     }

//     handleDownloadDocument() {
//         this.showToast('Info', 'Download functionality will be implemented in Phase 6', 'info');
//     }

//     handleResetForm() {
//         this.currentStep = 'step-1';
//         this.selectedRegion = '';
//         this.selectedRole = '';
//         this.selectedContractType = '';
//         this.documentTitle = '';
//         this.additionalNotes = '';
//         this.generatedDocumentId = '';
//         this.generatedClause = '';
//         this.documentStatus = '';
//         this.generationTimestamp = '';
//         this.complianceResult = null;
//         this.complianceStatusText = '';
//         this.complianceDetails = '';
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




// Developer_build_step_by_step_impl_e_sign v1........................................................


// import { LightningElement, track, wire } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import generateDocument from '@salesforce/apex/DocumentLifecycleDeploymentManager.generateDocument';
// import initiateSignatureRequest from '@salesforce/apex/SignatureRequestController.initiateSignatureRequest';

// export default class DocumentGenerator extends LightningElement {
//     @track currentStep = 'step-1';
//     @track selectedRegion = '';
//     @track selectedRole = '';
//     @track selectedContractType = '';
//     @track documentTitle = '';
//     @track additionalNotes = '';
//     @track generatedClause = '';
//     @track generatedDocumentId = '';
//     @track complianceStatus = false;
//     @track complianceMessage = '';
//     @track signerEmail = '';
//     @track signerName = '';
//     @track isGenerating = false;

//     // Options for dropdowns
//     regionOptions = [
//         { label: 'United States', value: 'US' },
//         { label: 'European Union', value: 'EU' },
//         { label: 'Asia Pacific', value: 'APAC' },
//         { label: 'Global', value: 'Global' }
//     ];

//     roleOptions = [
//         { label: 'Manager', value: 'Manager' },
//         { label: 'Director', value: 'Director' },
//         { label: 'Vice President', value: 'VP' },
//         { label: 'C-Level', value: 'C-Level' }
//     ];

//     contractTypeOptions = [
//         { label: 'Employment Agreement', value: 'Employment' },
//         { label: 'Non-Disclosure Agreement', value: 'NDA' },
//         { label: 'Service Agreement', value: 'Service Agreement' },
//         { label: 'Partnership Agreement', value: 'Partnership' }
//     ];

//     // Computed properties for step visibility
//     get isStep1() { return this.currentStep === 'step-1'; }
//     get isStep2() { return this.currentStep === 'step-2'; }
//     get isStep3() { return this.currentStep === 'step-3'; }
//     get isStep4() { return this.currentStep === 'step-4'; }

//     get isNextDisabled() {
//         if (this.isStep1) {
//             return !this.selectedRegion || !this.selectedRole || !this.selectedContractType;
//         }
//         if (this.isStep2) {
//             return !this.documentTitle;
//         }
//         return false;
//     }

//     get isSignatureRequestDisabled() {
//         return !this.signerEmail || !this.signerName || !this.generatedDocumentId;
//     }

//     get complianceStatusClass() {
//         return this.complianceStatus ? 'compliance-success' : 'compliance-error';
//     }

//     get complianceIcon() {
//         return this.complianceStatus ? 'utility:success' : 'utility:error';
//     }

//     // Event handlers
//     handleRegionChange(event) { this.selectedRegion = event.detail.value; }
//     handleRoleChange(event) { this.selectedRole = event.detail.value; }
//     handleContractTypeChange(event) { this.selectedContractType = event.detail.value; }
//     handleTitleChange(event) { this.documentTitle = event.detail.value; }
//     handleNotesChange(event) { this.additionalNotes = event.detail.value; }
//     handleSignerEmailChange(event) { this.signerEmail = event.detail.value; }
//     handleSignerNameChange(event) { this.signerName = event.detail.value; }

//     handleNext() {
//         if (this.currentStep === 'step-1') {
//             this.currentStep = 'step-2';
//         } else if (this.currentStep === 'step-2') {
//             this.currentStep = 'step-3';
//         } else if (this.currentStep === 'step-3') {
//             this.currentStep = 'step-4';
//         }
//     }

//     handlePrevious() {
//         if (this.currentStep === 'step-2') {
//             this.currentStep = 'step-1';
//         } else if (this.currentStep === 'step-3') {
//             this.currentStep = 'step-2';
//         } else if (this.currentStep === 'step-4') {
//             this.currentStep = 'step-3';
//         }
//     }

//     async handleGenerateDocument() {
//         this.isGenerating = true;
//         try {
//             const documentId = await generateDocument({
//                 region: this.selectedRegion,
//                 role: this.selectedRole,
//                 contractType: this.selectedContractType,
//                 title: this.documentTitle
//             });

//             this.generatedDocumentId = documentId;
//             this.complianceStatus = true;
//             this.complianceMessage = 'Document passed compliance validation';
            
//             this.showToast('Success', 'Document generated successfully!', 'success');
//             this.handleNext();
//         } catch (error) {
//             this.showToast('Error', error.body.message, 'error');
//             this.complianceStatus = false;
//             this.complianceMessage = 'Document failed compliance validation';
//         } finally {
//             this.isGenerating = false;
//         }
//     }

//     async handleSendSignatureRequest() {
//         try {
//             const requestId = await initiateSignatureRequest({
//                 documentId: this.generatedDocumentId,
//                 signerEmail: this.signerEmail,
//                 signerName: this.signerName
//             });

//             this.showToast('Success', 'Signature request sent successfully!', 'success');
//             // Reset form or navigate to next step
//         } catch (error) {
//             this.showToast('Error', error.body.message, 'error');
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





// Developer_build_step_by_step_impl_e_sign.............................................................



// import { LightningElement, track } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import generateClause from '@salesforce/apex/ClauseGenerator.generateClause';
// import validateClause from '@salesforce/apex/ComplianceChecker.validateClause';
// import initiateSignatureRequest from '@salesforce/apex/SignatureRequestController.initiateSignatureRequest';

// export default class DocumentGenerator extends LightningElement {
//     // Step management
//     @track currentStep = 'step-1';
    
//     // Form data
//     @track selectedRegion = '';
//     @track selectedRole = '';
//     @track selectedContractType = '';
//     @track documentTitle = '';
//     @track additionalNotes = '';
    
//     // Generated content
//     @track generatedClause = '';
//     @track generatedDocumentId = '';
//     @track generationTimestamp = '';
    
//     // Loading states
//     @track isLoadingClause = false;
//     @track isCheckingCompliance = false;
//     @track isGenerating = false;
    
//     // Compliance status
//     @track complianceStatus = false;
//     @track complianceStatusLabel = 'Pending';
//     @track complianceVariant = 'warning';
    
//     // Signature modal
//     @track showSignatureModal = false;
//     @track signerEmail = '';
//     @track signerName = '';

//     // Options for dropdowns
//     regionOptions = [
//         { label: 'United States', value: 'US' },
//         { label: 'European Union', value: 'EU' },
//         { label: 'India', value: 'IN' },
//         { label: 'Global', value: 'Global' }
//     ];

//     roleOptions = [
//         { label: 'Manager', value: 'Manager' },
//         { label: 'Employee', value: 'Employee' },
//         { label: 'Administrator', value: 'Admin' }
//     ];

//     contractTypeOptions = [
//         { label: 'Employment Contract', value: 'Employment' },
//         { label: 'Non-Disclosure Agreement', value: 'NDA' },
//         { label: 'Service Level Agreement', value: 'SLA' }
//     ];

//     // Computed properties for step management
//     get isStep1() { return this.currentStep === 'step-1'; }
//     get isStep2() { return this.currentStep === 'step-2'; }
//     get isStep3() { return this.currentStep === 'step-3'; }
//     get isStep4() { return this.currentStep === 'step-4'; }
    
//     get isFirstStep() { return this.currentStep === 'step-1'; }
//     get isLastStep() { return this.currentStep === 'step-4'; }
    
//     get isNextDisabled() {
//         if (this.isStep1) {
//             return !this.selectedRegion || !this.selectedRole || !this.selectedContractType;
//         }
//         if (this.isStep2) {
//             return !this.documentTitle;
//         }
//         if (this.isStep3) {
//             return !this.complianceStatus;
//         }
//         return false;
//     }
    
//     get isGenerateDisabled() {
//         return this.isStep3 && (!this.complianceStatus || this.isCheckingCompliance);
//     }
    
//     get isSendDisabled() {
//         return !this.signerEmail || !this.signerName;
//     }

//     // Event handlers for form inputs
//     handleRegionChange(event) {
//         this.selectedRegion = event.detail.value;
//     }

//     handleRoleChange(event) {
//         this.selectedRole = event.detail.value;
//     }

//     handleContractTypeChange(event) {
//         this.selectedContractType = event.detail.value;
//     }

//     handleDocumentTitleChange(event) {
//         this.documentTitle = event.detail.value;
//     }

//     handleNotesChange(event) {
//         this.additionalNotes = event.detail.value;
//     }

//     handleSignerEmailChange(event) {
//         this.signerEmail = event.detail.value;
//     }

//     handleSignerNameChange(event) {
//         this.signerName = event.detail.value;
//     }

//     // Navigation handlers
//     handleNext() {
//         if (this.currentStep === 'step-1') {
//             this.currentStep = 'step-2';
//         } else if (this.currentStep === 'step-2') {
//             this.currentStep = 'step-3';
//             this.generateClauseAndValidate();
//         } else if (this.currentStep === 'step-3') {
//             this.currentStep = 'step-4';
//         }
//     }

//     handlePrevious() {
//         if (this.currentStep === 'step-2') {
//             this.currentStep = 'step-1';
//         } else if (this.currentStep === 'step-3') {
//             this.currentStep = 'step-2';
//         } else if (this.currentStep === 'step-4') {
//             this.currentStep = 'step-3';
//         }
//     }

//     // Generate clause and validate compliance
//     async generateClauseAndValidate() {
//         this.isLoadingClause = true;
//         this.isCheckingCompliance = true;
        
//         try {
//             // Generate clause
//             const clause = await generateClause({
//                 region: this.selectedRegion,
//                 role: this.selectedRole,
//                 contractType: this.selectedContractType
//             });
            
//             this.generatedClause = clause;
//             this.isLoadingClause = false;
            
//             // Validate compliance
//             const isCompliant = await validateClause({
//                 clause: clause,
//                 region: this.selectedRegion,
//                 contractType: this.selectedContractType
//             });
            
//             this.complianceStatus = isCompliant;
//             this.complianceStatusLabel = isCompliant ? 'Compliant' : 'Non-Compliant';
//             this.complianceVariant = isCompliant ? 'success' : 'error';
//             this.isCheckingCompliance = false;
            
//         } catch (error) {
//             this.isLoadingClause = false;
//             this.isCheckingCompliance = false;
//             this.showToast('Error', 'Failed to generate clause: ' + error.body?.message, 'error');
//         }
//     }

//     // Generate document
//     handleGenerate() {
//         this.isGenerating = true;
        
//         // Simulate document generation (replace with actual Apex call)
//         setTimeout(() => {
//             this.generatedDocumentId = 'DOC-' + Date.now();
//             this.generationTimestamp = new Date().toLocaleString();
//             this.isGenerating = false;
            
//             this.showToast('Success', 'Document generated successfully!', 'success');
//         }, 3000);
//     }

//     // Signature request handlers
//     handleRequestSignature() {
//         this.showSignatureModal = true;
//     }

//     handleCloseModal() {
//         this.showSignatureModal = false;
//         this.signerEmail = '';
//         this.signerName = '';
//     }

//     async handleSendSignatureRequest() {
//         try {
//             const requestId = await initiateSignatureRequest({
//                 documentId: this.generatedDocumentId,
//                 signerEmail: this.signerEmail,
//                 signerName: this.signerName
//             });
            
//             this.showToast('Success', 'Signature request sent successfully!', 'success');
//             this.handleCloseModal();
            
//             // Navigate to signature request record (optional)
//             // this[NavigationMixin.Navigate]({
//             //     type: 'standard__recordPage',
//             //     attributes: {
//             //         recordId: requestId,
//             //         actionName: 'view'
//             //     }
//             // });
            
//         I notice we already completed the HTML template in the previous response. Let me continue from where the JavaScript file was cut off:
//         } catch (error) {
//             this.showToast('Error', 'Failed to send signature request: ' + error.body?.message, 'error');
//         }
//     }

//     handleViewDocument() {
//         // Navigate to document view (implement based on your document storage)
//         this.showToast('Info', 'Document view functionality to be implemented', 'info');
//     }

//     // Utility method for showing toast messages
//     showToast(title, message, variant) {
//         const evt = new ShowToastEvent({
//             title: title,
//             message: message,
//             variant: variant
//         });
//         this.dispatchEvent(evt);
//     }
// }

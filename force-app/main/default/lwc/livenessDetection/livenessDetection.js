
// Developer_build_step_by_step_impl_e_sign v4.................................................................


// import { LightningElement, track, wire } from 'lwc';
// import performLivenessCheck from '@salesforce/apex/LivenessDetectionService.performLivenessCheck';

// export default class LivenessDetection extends LightningElement {
//     @track isDetecting = false;
//     @track detectionResult = null;
//     @track cameraStream = null;
    
//     connectedCallback() {
//         this.initializeCamera();
//     }
    
//     async initializeCamera() {
//         try {
//             this.cameraStream = await navigator.mediaDevices.getUserMedia({ 
//                 video: { width: 640, height: 480 } 
//             });
//             const videoElement = this.template.querySelector('[data-id="camera-preview"]');
//             videoElement.srcObject = this.cameraStream;
//         } catch (error) {
//             this.showError('Camera access denied or unavailable');
//         }
//     }
    
//     handleStartDetection() {
//         this.isDetecting = true;
//         this.captureAndAnalyze();
//     }
    
//     captureAndAnalyze() {
//         const canvas = this.template.querySelector('[data-id="capture-canvas"]');
//         const video = this.template.querySelector('[data-id="camera-preview"]');
//         const ctx = canvas.getContext('2d');
        
//         // Capture frame
//         ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
//         const imageData = canvas.toDataURL('image/jpeg', 0.8);
        
//         // Call Apex for liveness detection
//         performLivenessCheck({ imageData: imageData, method: 'face' })
//             .then(result => {
//                 this.detectionResult = result;
//                 this.isDetecting = false;
//                 if (result.isLive) {
//                     this.dispatchEvent(new CustomEvent('livenessverified', {
//                         detail: { validationId: result.validationId, score: result.score }
//                     }));
//                 }
//             })
//             .catch(error => {
//                 this.isDetecting = false;
//                 this.showError('Liveness detection failed: ' + error.body.message);
//             });
//     }
// }

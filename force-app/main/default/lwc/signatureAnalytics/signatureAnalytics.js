
// Developer_build_step_by_step_impl_e_sign v11 ----------------------------------------------------------------


// import { LightningElement, track, wire } from 'lwc';
// import { refreshApex } from '@salesforce/apex';
// import getAnalyticsData from '@salesforce/apex/AnalyticsController.getAnalyticsData';
// import getRecentActivity from '@salesforce/apex/AnalyticsController.getRecentActivity';
// import { loadScript } from 'lightning/platformResourceLoader';
// import ChartJS from '@salesforce/resourceUrl/ChartJS';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// export default class SignatureAnalytics extends LightningElement {
//     @track analyticsData = null;
//     @track recentActivity = null;
//     @track isChartJsLoaded = false;

//     // Charts
//     statusChart;
//     methodChart;
//     trendsChart;
//     refreshInterval;

//     get activityColumns() {
//         return [
//             { label: 'Document Title', fieldName: 'documentTitle', type: 'text' },
//             { label: 'Signer', fieldName: 'signerName', type: 'text' },
//             { label: 'Action', fieldName: 'action', type: 'text' },
//             { label: 'Status', fieldName: 'status', type: 'text',
//               cellAttributes: { class: { fieldName: 'statusClass' } } },
//             { label: 'Date', fieldName: 'activityDate', type: 'date',
//               typeAttributes: { year: 'numeric', month: '2-digit', day: '2-digit',
//                                 hour: '2-digit', minute: '2-digit' } }
//         ];
//     }

//     // Metrics getters
//     get totalRequests() {
//         return this.analyticsData?.totalRequests || 0;
//     }
//     get completionRate() {
//         return this.analyticsData ? Math.round(this.analyticsData.completionRate) : 0;
//     }
//     get avgCompletionTime() {
//         return this.analyticsData ? `${this.analyticsData.avgCompletionTime} days` : 'N/A';
//     }
//     get activeUsers() {
//         return this.analyticsData?.activeUsers || 0;
//     }
//     get systemStatus() {
//         return this.analyticsData?.systemStatus || 'Unknown';
//     }
//     get systemHealthVariant() {
//         const status = this.systemStatus.toLowerCase();
//         return status === 'healthy' ? 'success' : status === 'warning' ? 'warning' : 'error';
//     }
//     get systemUptime() {
//         return this.analyticsData ? `${this.analyticsData.systemUptime}%` : 'N/A';
//     }
//     get performanceScore() {
//         return this.analyticsData ? Math.round(this.analyticsData.performanceScore) : 0;
//     }

//     // Wires
//     @wire(getAnalyticsData)
//     wiredAnalyticsData(result) {
//         if (result.data) {
//             this.analyticsData = result.data;
//             if (this.isChartJsLoaded) {
//                 this.updateCharts();
//             }
//         } else if (result.error) {
//             console.error('Error loading analytics data:', result.error);
//         }
//     }

//     @wire(getRecentActivity, { limitCount: 10 })
//     wiredRecentActivity(result) {
//         if (result.data) {
//             this.recentActivity = result.data.map(activity => ({
//                 ...activity,
//                 statusClass: this.getStatusClass(activity.status)
//             }));
//         } else if (result.error) {
//             console.error('Error loading recent activity:', result.error);
//         }
//     }

//     async renderedCallback() {
//         if (!this.isChartJsLoaded) {
//             try {
//                 await loadScript(this, ChartJS);
//                 this.isChartJsLoaded = true;
//                 if (this.analyticsData) {
//                     this.updateCharts();
//                 }
//             } catch (error) {
//                 console.error('Error loading Chart.js:', error);
//             }
//         }
//     }

//     updateCharts() {
//         try {
//             this.createStatusChart();
//             this.createMethodChart();
//             this.createTrendsChart();
//         } catch (error) {
//             console.error('Error updating charts:', error);
//         }
//     }

//     createStatusChart() {
//         const canvas = this.template.querySelector('[data-id="statusChart"]');
//         if (!canvas || !this.analyticsData.statusDistribution) return;

//         const ctx = canvas.getContext('2d');
//         const statusData = this.analyticsData.statusDistribution;

//         if (this.statusChart) {
//             this.statusChart.destroy();
//         }

//         this.statusChart = new window.Chart(ctx, {
//             type: 'doughnut',
//             data: {
//                 labels: Object.keys(statusData),
//                 datasets: [{
//                     data: Object.values(statusData),
//                     backgroundColor: ['#28a745', '#ffc107', '#dc3545', '#6c757d', '#17a2b8'],
//                     borderWidth: 2,
//                     borderColor: '#fff'
//                 }]
//             },
//             options: {
//                 responsive: true,
//                 maintainAspectRatio: false,
//                 plugins: {
//                     legend: { position: 'bottom', labels: { padding: 15, usePointStyle: true } },
//                     tooltip: {
//                         callbacks: {
//                             label: function (context) {
//                                 const total = context.dataset.data.reduce((a, b) => a + b, 0);
//                                 const percentage = Math.round((context.parsed / total) * 100);
//                                 return `${context.label}: ${context.parsed} (${percentage}%)`;
//                             }
//                         }
//                     }
//                 }
//             }
//         });
//     }

//     createMethodChart() {
//         const canvas = this.template.querySelector('[data-id="methodChart"]');
//         if (!canvas || !this.analyticsData.methodDistribution) return;

//         const ctx = canvas.getContext('2d');
//         const methodData = this.analyticsData.methodDistribution;

//         if (this.methodChart) {
//             this.methodChart.destroy();
//         }

//         this.methodChart = new window.Chart(ctx, {
//             type: 'bar',
//             data: {
//                 labels: Object.keys(methodData),
//                 datasets: [{
//                     label: 'Number of Signatures',
//                     data: Object.values(methodData),
//                     backgroundColor: ['rgba(23, 162, 184, 0.8)', 'rgba(40, 167, 69, 0.8)', 'rgba(255, 193, 7, 0.8)'],
//                     borderColor: ['#17a2b8', '#28a745', '#ffc107'],
//                     borderWidth: 2
//                 }]
//             },
//             options: {
//                 responsive: true,
//                 maintainAspectRatio: false,
//                 plugins: { legend: { display: false } },
//                 scales: {
//                     y: { beginAtZero: true, ticks: { stepSize: 1 } }
//                 }
//             }
//         });
//     }

//     createTrendsChart() {
//         const canvas = this.template.querySelector('[data-id="trendsChart"]');
//         if (!canvas || !this.analyticsData.completionTrends) return;

//         const ctx = canvas.getContext('2d');
//         const trendsData = this.analyticsData.completionTrends;

//         if (this.trendsChart) {
//             this.trendsChart.destroy();
//         }

//         this.trendsChart = new window.Chart(ctx, {
//             type: 'line',
//             data: {
//                 labels: trendsData.map(item => item.date),
//                 datasets: [
//                     {
//                         label: 'Completed Signatures',
//                         data: trendsData.map(item => item.completed),
//                         borderColor: '#28a745',
//                         backgroundColor: 'rgba(40, 167, 69, 0.1)',
//                         fill: true,
//                         tension: 0.4
//                     },
//                     {
//                         label: 'New Requests',
//                         data: trendsData.map(item => item.created),
//                         borderColor: '#007bff',
//                         backgroundColor: 'rgba(0, 123, 255, 0.1)',
//                         fill: true,
//                         tension: 0.4
//                     }
//                 ]
//             },
//             options: {
//                 responsive: true,
//                 maintainAspectRatio: false,
//                 plugins: { legend: { position: 'top' } },
//                 scales: {
//                     y: { beginAtZero: true, ticks: { stepSize: 1 } },
//                     x: {
//                         type: 'time',
//                         time: { unit: 'day', displayFormats: { day: 'MMM DD' } }
//                     }
//                 }
//             }
//         });
//     }

//     getStatusClass(status) {
//         switch (status?.toLowerCase()) {
//             case 'completed':
//             case 'signed': return 'slds-text-color_success';
//             case 'pending': return 'slds-text-color_default';
//             case 'rejected':
//             case 'expired': return 'slds-text-color_error';
//             default: return 'slds-text-color_weak';
//         }
//     }

//     // Refresh every 5 minutes
//     connectedCallback() {
//         this.refreshInterval = setInterval(() => this.refreshAnalyticsData(), 300000);
//     }

//     disconnectedCallback() {
//         if (this.refreshInterval) clearInterval(this.refreshInterval);
//         if (this.statusChart) this.statusChart.destroy();
//         if (this.methodChart) this.methodChart.destroy();
//         if (this.trendsChart) this.trendsChart.destroy();
//     }

//     async refreshAnalyticsData() {
//         try {
//             await refreshApex(this.wiredAnalyticsData);
//             await refreshApex(this.wiredRecentActivity);
//         } catch (error) {
//             this.dispatchEvent(new ShowToastEvent({
//                 title: 'Error',
//                 message: 'Error refreshing analytics data',
//                 variant: 'error'
//             }));
//             console.error('Error refreshing analytics data:', error);
//         }
//     }
// }

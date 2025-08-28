



// Developer_build_step_by_step_impl_e_sign v11 ------------------------------------------------------

// import { LightningElement, track, wire } from 'lwc';
// import { refreshApex } from '@salesforce/apex';
// import getSystemHealthData from '@salesforce/apex/SystemHealthController.getSystemHealthData';
// import getSystemAlerts from '@salesforce/apex/SystemHealthController.getSystemAlerts';
// import getPerformanceMetrics from '@salesforce/apex/SystemHealthController.getPerformanceMetrics';
// import { loadScript } from 'lightning/platformResourceLoader';
// import ChartJS from '@salesforce/resourceUrl/ChartJS';

// export default class SystemHealthMonitor extends LightningElement {
// @track healthData = null;
// @track systemAlerts = null;
// @track performanceMetrics = null;
// @track isChartJsLoaded = false;

// // Charts
// responseChart;
// loadChart;

// // Auto-refresh interval
// refreshInterval;

// get metricsColumns() {
// return [
// { label: 'Component', fieldName: 'component', type: 'text' },
// { label: 'Status', fieldName: 'status', type: 'text', cellAttributes: { class: { fieldName: 'statusClass' } } },
// { label: 'Response Time', fieldName: 'responseTime', type: 'text' },
// { label: 'Throughput', fieldName: 'throughput', type: 'text' },
// { label: 'Last Check', fieldName: 'lastCheck', type: 'date', typeAttributes: { 
//     year: 'numeric', month: '2-digit', day: '2-digit', 
//     hour: '2-digit', minute: '2-digit' 
// }}
// ];
// }

// // Health status computed properties
// get overallHealthStatus() {
// return this.healthData?.overallStatus || 'Unknown';
// }

// get overallHealthScore() {
// return this.healthData?.healthScore || 0;
// }

// get overallHealthClass() {
// const status = this.overallHealthStatus.toLowerCase();
// return `health-card ${status}`;
// }

// get overallHealthIcon() {
// const status = this.overallHealthStatus.toLowerCase();
// switch (status) {
// case 'healthy': return 'utility:success';
// case 'warning': return 'utility:warning';
// case 'critical': return 'utility:error';
// default: return 'utility:info';
// }
// }

// get overallHealthVariant() {
// const status = this.overallHealthStatus.toLowerCase();
// switch (status) {
// case 'healthy': return 'success';
// case 'warning': return 'warning';
// case 'critical': return 'error';
// default: return 'inverse';
// }
// }

// get systemUptime() {
// return this.healthData?.systemUptime || 'N/A';
// }

// get avgResponseTime() {
// return this.healthData?.avgResponseTime || 'N/A';
// }

// get activeSessions() {
// return this.healthData?.activeSessions || 0;
// }

// get errorRate() {
// return this.healthData?.errorRate || 0;
// }

// get hasAlerts() {
// return this.systemAlerts && this.systemAlerts.length > 0;
// }

// @wire(getSystemHealthData)
// wiredHealthData(result) {
// if (result.data) {
// this.healthData = result.data;
// if (this.isChartJsLoaded) {
// this.updateCharts();
// }
// } else if (result.error) {
// console.error('Error loading health data:', result.error);
// }
// }

// @wire(getSystemAlerts)
// wiredAlerts(result) {
// if (result.data) {
// this.systemAlerts = result.data.map(alert => ({
// ...alert,
// severityClass: this.getAlertClass(alert.severity),
// icon: this.getAlertIcon(alert.severity),
// iconVariant: this.getAlertIconVariant(alert.severity)
// }));
// } else if (result.error) {
// console.error('Error loading alerts:', result.error);
// }
// }

// @wire(getPerformanceMetrics)
// wiredMetrics(result) {
// if (result.data) {
// this.performanceMetrics = result.data.map(metric => ({
// ...metric,
// statusClass: this.getStatusClass(metric.status)
// }));
// } else if (result.error) {
// console.error('Error loading performance metrics:', result.error);
// }
// }

// async renderedCallback() {
// if (!this.isChartJsLoaded) {
// try {
// await loadScript(this, ChartJS);
// this.isChartJsLoaded = true;
// if (this.healthData) {
// this.updateCharts();
// }
// } catch (error) {
// console.error('Error loading Chart.js:', error);
// }
// }
// }

// updateCharts() {
// try {
// this.createResponseTimeChart();
// this.createSystemLoadChart();
// } catch (error) {
// console.error('Error updating charts:', error);
// }
// }

// createResponseTimeChart() {
// const canvas = this.template.querySelector('[data-id="responseChart"]');
// if (!canvas || !this.healthData.responseTimeHistory) return;

// const ctx = canvas.getContext('2d');
// const responseData = this.healthData.responseTimeHistory;

// if (this.responseChart) {
// this.responseChart.destroy();
// }

// this.responseChart = new Chart(ctx, {
// type: 'line',
// data: {
// labels: responseData.map(item => item.timestamp),
// datasets: [{
// label: 'Response Time (ms)',
// data: responseData.map(item => item.responseTime),
// borderColor: '#007bff',
// backgroundColor: 'rgba(0, 123, 255, 0.1)',
// fill: true,
// tension: 0.4
// }]
// },
// options: {
// responsive: true,
// maintainAspectRatio: false,
// plugins: {
// legend: {
// display: false
// }
// },
// scales: {
// y: {
// beginAtZero: true,
// title: {
// display: true,
// text: 'Response Time (ms)'
// }
// },
// x: {
// title: {
// display: true,
// text: 'Time'
// }
// }
// }
// }
// });
// }

// createSystemLoadChart() {
// const canvas = this.template.querySelector('[data-id="loadChart"]');
// if (!canvas || !this.healthData.systemLoadHistory) return;

// const ctx = canvas.getContext('2d');
// const loadData = this.healthData.systemLoadHistory;

// if (this.loadChart) {
// this.loadChart.destroy();
// }

// this.loadChart = new Chart(ctx, {
// type: 'line',
// data: {
// labels: loadData.map(item => item.timestamp),
// datasets: [
// {
// label: 'CPU Usage (%)',
// data: loadData.map(item => item.cpuUsage),
// borderColor: '#28a745',
// backgroundColor: 'rgba(40, 167, 69, 0.1)',
// fill: false
// },
// {
// label: 'Memory Usage (%)',
// data: loadData.map(item => item.memoryUsage),
// borderColor: '#ffc107',
// backgroundColor: 'rgba(255, 193, 7, 0.1)',
// fill: false
// },
// {
// label: 'Active Requests',
// data: loadData.map(item => item.activeRequests),
// borderColor: '#dc3545',
// backgroundColor: 'rgba(220, 53, 69, 0.1)',
// fill: false
// }
// ]
// },
// options: {
// responsive: true,
// maintainAspectRatio: false,
// plugins: {
// legend: {
// position: 'top'
// }
// },
// scales: {
// y: {
// beginAtZero: true,
// max: 100,
// title: {
// display: true,
// text: 'Usage %'
// }
// },
// x: {
// title: {
// display: true,
// text: 'Time'
// }
// }
// }
// }
// });
// }

// getAlertClass(severity) {
// switch (severity?.toLowerCase()) {
// case 'critical': return 'alert-item critical';
// case 'warning': return 'alert-item warning';
// case 'info': return 'alert-item info';
// default: return 'alert-item';
// }
// }

// getAlertIcon(severity) {
// switch (severity?.toLowerCase()) {
// case 'critical': return 'utility:error';
// getAlertIcon(severity) {
// switch (severity?.toLowerCase()) {
// case 'critical': return 'utility:error';
// case 'warning': return 'utility:warning';
// case 'info': return 'utility:info';
// default: return 'utility:notification';
// }
// } getAlertIconVariant(severity) {
// switch (severity?.toLowerCase()) {
// case 'critical': return 'error';
// case 'warning': return 'warning';
// case 'info': return 'inverse';
// default: return 'inverse';
// }
// } getStatusClass(status) {
// switch (status?.toLowerCase()) {
// case 'healthy': return 'slds-text-color_success';
// case 'warning': return 'slds-text-color_default';
// case 'critical': return 'slds-text-color_error';
// default: return 'slds-text-color_weak';
// }
// } connectedCallback() {
// // Auto-refresh every 30 seconds
// this.refreshInterval = setInterval(() => {
// this.refreshHealthData();
// }, 30000);
// } disconnectedCallback() {
// if (this.refreshInterval) {
// clearInterval(this.refreshInterval);
// }
// // Clean up charts
// if (this.responseChart) this.responseChart.destroy();
// if (this.loadChart) this.loadChart.destroy();
// } async refreshHealthData() {
// try {
// await refreshApex(this.wiredHealthData);
// await refreshApex(this.wiredAlerts);
// await refreshApex(this.wiredMetrics);
// } catch (error) {
// console.error('Error refreshing health data:', error);
// }
// }
// }

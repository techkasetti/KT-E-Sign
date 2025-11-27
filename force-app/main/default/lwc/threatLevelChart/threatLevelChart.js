// threatLevelChart.js
import { LightningElement, wire, track, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Import the Apex method to fetch threat metrics
import getThreatMetrics from '@salesforce/apex/SecurityDashboardController.getThreatMetrics';

export default class ThreatLevelChart extends LightningElement {
    @track error;
    @track chart;

    chartjsInitialized = false;
    isChartRendered = false;
    isLoading = true;
    
    @wire(getThreatMetrics)
    wiredThreatMetrics({ error, data }) {
        if (data) {
            this.processChartData(data.threatLevelDistribution);
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.chartData = undefined;
            this.showToast('Data Loading Error', 'Could not retrieve threat metrics from the server.', 'error');
        }
        this.isLoading = false;
    }
    
    renderedCallback() {
        if (this.chartjsInitialized) {
            return;
        }
        this.chartjsInitialized = true;

        loadScript(this, CHARTJS)
            .then(() => {
                // The library is loaded, but data might not be ready.
                // Chart initialization will be triggered by the wired data.
            })
            .catch(error => {
                this.error = error;
                this.showToast('Chart Library Error', 'Failed to load the Chart.js library.', 'error');
                this.isLoading = false;
            });
    }

    processChartData(threatData) {
        if (!threatData || Object.keys(threatData).length === 0) {
            this.hasData = false;
            if (this.chart) {
                this.chart.destroy();
                this.chart = null;
            }
            return;
        }

        const labels = Object.keys(threatData);
        const counts = Object.values(threatData);
        
        // Map severity levels to colors, based on the backend logic in getSeverityColor() @65
        const backgroundColors = labels.map(label => {
            switch (label.toUpperCase()) {
                case 'CRITICAL': return 'rgba(139, 0, 0, 0.7)';      // Dark Red
                case 'HIGH':     return 'rgba(220, 53, 69, 0.7)';      // Red
                case 'MEDIUM':   return 'rgba(255, 193, 7, 0.7)';     // Yellow
                case 'LOW':      return 'rgba(40, 167, 69, 0.7)';     // Green
                case 'MINIMAL':  return 'rgba(108, 117, 125, 0.7)';   // Gray
                default:         return 'rgba(108, 117, 125, 0.7)';
            }
        });
        
        this.hasData = counts.some(count => count > 0);

        // Wait for the canvas element to be available
        setTimeout(() => this.initializeChart(labels, counts, backgroundColors), 0);
    }
    
    initializeChart(labels, counts, backgroundColors) {
        const canvas = this.template.querySelector('canvas.chart');
        if (!canvas) return;

        const ctx = canvas.getContext('2d');
        
        // If a chart instance already exists, destroy it before creating a new one
        if (this.chart) {
            this.chart.destroy();
        }

        this.chart = new window.Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: labels,
                datasets: [{
                    label: 'Threat Count',
                    data: counts,
                    backgroundColor: backgroundColors,
                    borderColor: '#ffffff',
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                legend: {
                    position: 'right',
                    labels: {
                        fontColor: '#555',
                        boxWidth: 20,
                        padding: 15
                    }
                },
                animation: {
                    animateScale: true,
                    animateRotate: true
                },
                tooltips: {
                    callbacks: {
                        label: function(tooltipItem, data) {
                            const dataset = data.datasets[tooltipItem.datasetIndex];
                            const total = dataset.data.reduce((acc, data) => acc + data, 0);
                            const currentValue = dataset.data[tooltipItem.index];
                            const percentage = total > 0 ? ((currentValue / total) * 100).toFixed(1) : 0;
                            return ` ${data.labels[tooltipItem.index]}: ${currentValue} (${percentage}%)`;
                        }
                    }
                }
            }
        });
        this.isChartRendered = true;
    }

    get chartContainerClass() {
        return this.isLoading || !this.hasData ? 'slds-hide' : 'chart-container';
    }

    get errorText() {
        if (this.error && this.error.body && this.error.body.message) {
            return this.error.body.message;
        }
        return 'An unknown error occurred.';
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(event);
    }
}
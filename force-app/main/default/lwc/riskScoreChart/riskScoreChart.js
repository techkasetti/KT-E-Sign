// riskScoreChart.js
import { LightningElement, wire, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import getFraudSummary from '@salesforce/apex/AdvancedAnalyticsDashboardController.getSecurityAnalysisInsights';

export default class RiskScoreChart extends LightningElement {
    @api timeFrameDays = 30; // Make the time frame configurable

    chart;
    chartData;
    error;
    isLoading = true;
    isChartJsInitialized = false;

    // Use the @wire service to fetch data from the Apex controller
    @wire(getFraudSummary, { startDate: '$resolvedStartDate' })
    wiredFraudData({ error, data }) {
        if (data) {
            this.chartData = data.fraudSummary;
            this.error = undefined;
            if (this.isChartJsInitialized) {
                this.initializeChart();
            }
        } else if (error) {
            this.error = error;
            this.chartData = undefined;
        }
        this.isLoading = false;
    }

    // Lifecycle hook to render the chart after the component is in the DOM
    renderedCallback() {
        if (this.isChartJsInitialized) {
            return;
        }
        this.isChartJsInitialized = true;

        loadScript(this, ChartJs)
            .then(() => {
                if (this.chartData) {
                    this.initializeChart();
                }
            })
            .catch(error => {
                this.error = error;
            });
    }

    initializeChart() {
        if (!this.chartData || this.chartData.length === 0) {
            return;
        }
        
        // Destroy previous chart instance if it exists
        if (this.chart) {
            this.chart.destroy();
        }

        const ctx = this.template.querySelector('canvas.chart').getContext('2d');
        
        const { labels, data, backgroundColors } = this.processChartData(this.chartData);

        this.chart = new window.Chart(ctx, {
            type: 'doughnut', // or 'pie', 'bar'
            data: {
                labels: labels,
                datasets: [{
                    label: 'Risk Assessments',
                    data: data,
                    backgroundColor: backgroundColors,
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                legend: {
                    position: 'right',
                },
                title: {
                    display: true,
                    text: 'Fraud Risk Distribution (Last ' + this.timeFrameDays + ' Days)'
                },
                animation: {
                    animateScale: true,
                    animateRotate: true
                }
            }
        });
    }

    processChartData(rawData) {
        const labels = [];
        const data = [];
        const backgroundColors = [];

        const colorMap = {
            'CRITICAL': 'rgba(211, 47, 47, 0.8)',
            'HIGH': 'rgba(245, 124, 0, 0.8)',
            'MEDIUM': 'rgba(253, 216, 53, 0.8)',
            'LOW': 'rgba(67, 160, 71, 0.8)',
            'MINIMAL': 'rgba(27, 94, 32, 0.8)'
        };

        rawData.forEach(item => {
            const riskLevel = item.Risk_Level__c;
            labels.push(riskLevel);
            data.push(item.riskCount);
            backgroundColors.push(colorMap[riskLevel] || 'rgba(158, 158, 158, 0.8)');
        });

        return { labels, data, backgroundColors };
    }
    
    // Dynamically calculate start date for the wire service
    get resolvedStartDate() {
        const today = new Date();
        today.setDate(today.getDate() - this.timeFrameDays);
        return today.toISOString().slice(0, 10);
    }
    
    get isChartEmpty() {
        return !this.isLoading && (!this.chartData || this.chartData.length === 0);
    }

    get errorText() {
        return this.error ? 'An unexpected error occurred: ' + this.error.body.message : '';
    }
}
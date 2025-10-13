



import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import generateAnalyticsDashboard from '@salesforce/apex/DocumentAnalyticsEngine.generateAnalyticsDashboard';
import { loadScript } from 'lightning/platformResourceLoader';
import ChartJS from '@salesforce/resourceUrl/ChartJS';

export default class AnalyticsDashboard extends LightningElement {
    // Data properties
    @track dashboardData = {};
    @track isLoading = true;
    @track error = null;
    @track chartJSInitialized = false;

    // Chart instances
    chartInstances = {};

    // Wire analytics data
    wiredAnalyticsResult;

    @wire(generateAnalyticsDashboard)
    wiredAnalytics(result) {
        this.wiredAnalyticsResult = result;
        if (result.data) {
            this.processDashboardData(result.data);
            this.isLoading = false;
            this.error = null;

            // Initialize charts after data is loaded
            if (this.chartJSInitialized) {
                this.initializeCharts();
            }
        } else if (result.error) {
            this.error = result.error;
            this.isLoading = false;
            this.showToast(
                'Error',
                'Failed to load analytics: ' + result.error.body?.message,
                'error'
            );
        }
    }

    // Load Chart.js library
    renderedCallback() {
        if (this.chartJSInitialized) {
            return;
        }
        loadScript(this, ChartJS)
            .then(() => {
                this.chartJSInitialized = true;
                if (this.dashboardData && Object.keys(this.dashboardData).length > 0) {
                    this.initializeCharts();
                }
            })
            .catch(error => {
                this.showToast(
                    'Error',
                    'Failed to load Chart.js: ' + error.message,
                    'error'
                );
            });
    }

    // Process dashboard data
    processDashboardData(data) {
        this.dashboardData = { ...data };

        // Process insights for display
        if (this.dashboardData.insights) {
            this.dashboardData.insights = this.dashboardData.insights.map(insight => ({
                ...insight,
                cssClass: this.getInsightCssClass(insight.severity),
                severityVariant: this.getSeverityVariant(insight.severity),
                confidenceStyle: `width: ${insight.confidence}%`
            }));
        }
    }

    // Computed properties
    get complianceRateClass() {
        if (!this.dashboardData.complianceMetrics) return 'metric-change';
        const rate = this.dashboardData.complianceMetrics.passRate;
        if (rate >= 95) return 'metric-change positive';
        if (rate >= 85) return 'metric-change neutral';
        return 'metric-change negative';
    }

    get complianceRateText() {
        if (!this.dashboardData.complianceMetrics) return '';
        const rate = this.dashboardData.complianceMetrics.passRate;
        if (rate >= 95) return 'Excellent';
        if (rate >= 85) return 'Good';
        return 'Needs Attention';
    }

    get performanceClass() {
        if (!this.dashboardData.performanceMetrics) return 'metric-change';
        const time = this.dashboardData.performanceMetrics.averageProcessingTime;
        if (time <= 2) return 'metric-change positive';
        if (time <= 4) return 'metric-change neutral';
        return 'metric-change negative';
    }

    get performanceText() {
        if (!this.dashboardData.performanceMetrics) return '';
        const time = this.dashboardData.performanceMetrics.averageProcessingTime;
        if (time <= 2) return 'Excellent';
        if (time <= 4) return 'Good';
        return 'Slow';
    }

    get hasDocumentStatusData() {
        return (
            this.dashboardData.documentMetrics?.statusBreakdown &&
            Object.keys(this.dashboardData.documentMetrics.statusBreakdown).length > 0
        );
    }

    get hasComplianceTrendData() {
        return (
            this.dashboardData.complianceMetrics?.violationTrends &&
            this.dashboardData.complianceMetrics.violationTrends.length > 0
        );
    }

    get hasInsights() {
        return this.dashboardData.insights && this.dashboardData.insights.length > 0;
    }

    get hasActionBreakdown() {
        return (
            this.dashboardData.userActivityMetrics?.actionBreakdown &&
            Object.keys(this.dashboardData.userActivityMetrics.actionBreakdown).length > 0
        );
    }

    get hasActivityTrend() {
        return (
            this.dashboardData.userActivityMetrics?.dailyActivity &&
            this.dashboardData.userActivityMetrics.dailyActivity.length > 0
        );
    }

    get hasOperationMetrics() {
        return (
            this.dashboardData.performanceMetrics?.operationMetrics &&
            Object.keys(this.dashboardData.performanceMetrics.operationMetrics).length > 0
        );
    }

    get actionBreakdownList() {
        if (!this.hasActionBreakdown) return [];
        return Object.keys(this.dashboardData.userActivityMetrics.actionBreakdown).map(
            key => ({
                name: key,
                label: this.formatActionLabel(key),
                count: this.dashboardData.userActivityMetrics.actionBreakdown[key]
            })
        );
    }

    get recentActivity() {
        if (!this.hasActivityTrend) return [];
        return this.dashboardData.userActivityMetrics.dailyActivity.slice(0, 5); // Last 5 days
    }

    get operationMetricsList() {
        if (!this.hasOperationMetrics) return [];
        return Object.keys(this.dashboardData.performanceMetrics.operationMetrics).map(
            key => {
                const value = this.dashboardData.performanceMetrics.operationMetrics[key];
                return {
                    name: key,
                    label: this.formatOperationLabel(key),
                    value: Math.round(value * 100) / 100,
                    statusClass: this.getPerformanceStatusClass(key, value),
                    statusText: this.getPerformanceStatusText(key, value)
                };
            }
        );
    }

    // Chart initialization
    initializeCharts() {
        this.initializeDocumentStatusChart();
        this.initializeComplianceTrendChart();
    }

    initializeDocumentStatusChart() {
        if (!this.hasDocumentStatusData) return;
        const canvas = this.template.querySelector('[data-id="documentStatusChart"]');
        if (!canvas) return;

        const ctx = canvas.getContext('2d');

        // Destroy existing chart
        if (this.chartInstances.statusChart) {
            this.chartInstances.statusChart.destroy();
        }

        const statusData = this.dashboardData.documentMetrics.statusBreakdown;
        const labels = Object.keys(statusData);
        const data = Object.values(statusData);

        this.chartInstances.statusChart = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: labels,
                datasets: [
                    {
                        data: data,
                        backgroundColor: [
                            '#1B96FF',
                            '#06A59A',
                            '#FFB75D',
                            '#FE5F55',
                            '#C23934'
                        ],
                        borderWidth: 2,
                        borderColor: '#FFFFFF'
                    }
                ]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: { position: 'bottom' }
                },
                animation: { animateScale: true }
            }
        });
    }

    initializeComplianceTrendChart() {
        if (!this.hasComplianceTrendData) return;
        const canvas = this.template.querySelector('[data-id="complianceTrendChart"]');
        if (!canvas) return;

        const ctx = canvas.getContext('2d');

        // Destroy existing chart
        if (this.chartInstances.trendChart) {
            this.chartInstances.trendChart.destroy();
        }

        const trendData = this.dashboardData.complianceMetrics.violationTrends;
        const labels = trendData.map(trend => trend.date);
        const data = trendData.map(trend => trend.count);

        this.chartInstances.trendChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: labels,
                datasets: [
                    {
                        label: 'Compliance Checks',
                        data: data,
                        borderColor: '#1B96FF',
                        backgroundColor: 'rgba(27, 150, 255, 0.1)',
                        borderWidth: 2,
                        fill: true,
                        tension: 0.4
                    }
                ]
            },
            options: {
                responsive: true,
                scales: { y: { beginAtZero: true } },
                plugins: { legend: { display: false } }
            }
        });
    }

    // Event handlers
    async handleRefresh() {
        this.isLoading = true;
        try {
            await refreshApex(this.wiredAnalyticsResult);
            this.showToast('Success', 'Analytics refreshed successfully', 'success');
        } catch (error) {
            this.showToast('Error', 'Failed to refresh analytics', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleExport() {
        // Implement export functionality
        this.showToast('Info', 'Export functionality to be implemented', 'info');
    }

    handleAdvancedAnalytics() {
        // Navigate to advanced analytics page
        this.showToast('Info', 'Advanced analytics page to be implemented', 'info');
    }

    // Utility methods
    getInsightCssClass(severity) {
        const baseClass = 'insight-item slds-box slds-m-bottom_small';
        switch (severity) {
            case 'CRITICAL':
                return `${baseClass} insight-critical`;
            case 'HIGH':
                return `${baseClass} insight-high`;
            case 'MEDIUM':
                return `${baseClass} insight-medium`;
            case 'LOW':
                return `${baseClass} insight-low`;
            default:
                return `${baseClass} insight-info`;
        }
    }

    getSeverityVariant(severity) {
        switch (severity) {
            case 'CRITICAL':
                return 'error';
            case 'HIGH':
                return 'warning';
            case 'MEDIUM':
                return 'inverse';
            case 'LOW':
                return 'success';
            default:
                return 'neutral';
        }
    }

    formatActionLabel(actionKey) {
        return actionKey
            .replace(/_/g, ' ')
            .replace(/\b\w/g, l => l.toUpperCase());
    }

    formatOperationLabel(operationKey) {
        return operationKey
            .replace(/_/g, ' ')
            .replace(/\b\w/g, l => l.toUpperCase());
    }

    getPerformanceStatusClass(operation, value) {
        const thresholds = {
            DOCUMENT_GENERATION: 5000,
            COMPLIANCE_CHECK: 3000,
            SIGNATURE_REQUEST: 2000,
            PDF_GENERATION: 10000,
            TEMPLATE_PROCESSING: 1000
        };
        const threshold = thresholds[operation];
        if (!threshold) return 'benchmark-status neutral';
        if (value <= threshold * 0.5) return 'benchmark-status excellent';
        if (value <= threshold * 0.75) return 'benchmark-status good';
        if (value <= threshold) return 'benchmark-status acceptable';
        return 'benchmark-status poor';
    }

    getPerformanceStatusText(operation, value) {
        const thresholds = {
            DOCUMENT_GENERATION: 5000,
            COMPLIANCE_CHECK: 3000,
            SIGNATURE_REQUEST: 2000,
            PDF_GENERATION: 10000,
            TEMPLATE_PROCESSING: 1000
        };
        const threshold = thresholds[operation];
        if (!threshold) return 'N/A';
        if (value <= threshold * 0.5) return 'Excellent';
        if (value <= threshold * 0.75) return 'Good';
        if (value <= threshold) return 'Acceptable';
        return 'Poor';
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

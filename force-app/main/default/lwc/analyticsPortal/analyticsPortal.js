// Developer_build_step_by_step_impl_e_sign v8 .................................................

import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getComprehensiveAnalytics from '@salesforce/apex/AdvancedAnalyticsEngine.getComprehensiveAnalytics';
import exportAnalyticsReport from '@salesforce/apex/AdvancedAnalyticsEngine.exportAnalyticsReport';

export default class AnalyticsPortal extends LightningElement {
    @track selectedDateRange = '30_days';
    @track selectedRegion = 'All';
    @track analyticsData = {};
    @track isLoading = true;
    @track showExportModal = false;
    @track selectedExportFormat = 'PDF';
    @track selectedReportSections = [];
    
    // Chart references
    completionTrendChart;
    hourlyActivityChart;
    deviceUsageChart;
    signatureMethodChart;
    
    // Real-time data
    @track realtimeActivities = [];
    @track intervalId;
    
    // Filter options
    dateRangeOptions = [
        { label: 'Last 7 days', value: '7_days' },
        { label: 'Last 30 days', value: '30_days' },
        { label: 'Last 90 days', value: '90_days' },
        { label: 'Last 6 months', value: '6_months' },
        { label: 'Last year', value: '1_year' }
    ];
    
    regionOptions = [
        { label: 'All Regions', value: 'All' },
        { label: 'North America', value: 'North America' },
        { label: 'Europe', value: 'Europe' },
        { label: 'Asia Pacific', value: 'Asia Pacific' },
        { label: 'Latin America', value: 'Latin America' }
    ];
    
    exportFormatOptions = [
        { label: 'PDF Report', value: 'PDF' },
        { label: 'Excel Spreadsheet', value: 'XLSX' },
        { label: 'CSV Data', value: 'CSV' },
        { label: 'JSON Data', value: 'JSON' }
    ];
    
    reportSectionOptions = [
        { label: 'Completion Rate Analysis', value: 'completion_rates' },
        { label: 'User Behavior Patterns', value: 'user_behavior' },
        { label: 'Performance Metrics', value: 'performance' },
        { label: 'Security Analytics', value: 'security' },
        { label: 'Predictive Insights', value: 'predictions' },
        { label: 'Document Analytics', value: 'documents' }
    ];
    
    @wire(getComprehensiveAnalytics, { 
        dateRange: '$selectedDateRange', 
        region: '$selectedRegion' 
    })
    wiredAnalytics({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.analyticsData = data;
            this.processAnalyticsData(data);
            this.renderCharts();
        } else if (error) {
            this.showToast('Error', 'Failed to load analytics data', 'error');
            console.error('Analytics error:', error);
        }
    }
    
    connectedCallback() {
        // Start real-time updates
        this.startRealtimeUpdates();
        
        // Initialize default report sections
        this.selectedReportSections = [
            'completion_rates',
            'user_behavior',
            'performance',
            'security'
        ];
    }
    
    disconnectedCallback() {
        // Clean up real-time updates
        if (this.intervalId) {
            clearInterval(this.intervalId);
        }
    }
    
    processAnalyticsData(data) {
        // Process completion rate data
        if (data.completionRates) {
            this.completionRate = data.completionRates.completionRate?.toFixed(1) || '0.0';
            this.averageCompletionTime = data.completionRates.averageCompletionTime?.toFixed(1) || '0.0';
            this.totalSignatures = data.completionRates.totalRequests || 0;
            
            // Calculate trends
            this.calculateTrends(data.completionRates.trendData);
        }
        
        // Process security data
        if (data.securityMetrics) {
            this.processSecurityMetrics(data.securityMetrics);
        }
        
        // Process predictive insights
        if (data.predictiveInsights) {
            this.processPredictiveInsights(data.predictiveInsights);
        }
    }
    
    calculateTrends(trendData) {
        if (!trendData || trendData.length < 2) {
            this.completionTrend = '0.0';
            this.timeTrend = '0.0';
            return;
        }
        
        const recent = trendData[trendData.length - 1];
        const previous = trendData[trendData.length - 2];
        
        // Completion rate trend
        const completionDiff = recent.completionRate - previous.completionRate;
        this.completionTrend = Math.abs(completionDiff).toFixed(1);
        this.completionTrendClass = completionDiff >= 0 ? 'positive' : 'negative';
        this.completionTrendIcon = completionDiff >= 0 ? 'utility:trending' : 'utility:down';
        
        // Time trend (negative is good for completion time)
        const timeDiff = recent.avgCompletionTime - previous.avgCompletionTime;
        this.timeTrend = Math.abs(timeDiff).toFixed(1);
        this.timeTrendClass = timeDiff <= 0 ? 'positive' : 'negative';
        this.timeTrendIcon = timeDiff <= 0 ? 'utility:down' : 'utility:trending';
    }
    
    processSecurityMetrics(securityData) {
        this.highRiskCount = 0;
        this.blockedAttempts = 0;
        this.cleanSignatures = 95; // Default
        
        if (securityData.fraudRiskDistribution) {
            this.highRiskCount = (securityData.fraudRiskDistribution.HIGH || 0) + 
                               (securityData.fraudRiskDistribution.CRITICAL || 0);
        }
        
        if (securityData.securityIncidents) {
            this.blockedAttempts = Object.values(securityData.securityIncidents)
                .reduce((sum, count) => sum + count, 0);
        }
        
        // Calculate fraud detection rate
        const totalAssessments = Object.values(securityData.fraudRiskDistribution || {})
            .reduce((sum, count) => sum + count, 0);
        const fraudDetected = this.highRiskCount;
        this.fraudDetectionRate = totalAssessments > 0 ? 
            ((fraudDetected / totalAssessments) * 100).toFixed(1) : '0.0';
    }
    
    processPredictiveInsights(predictiveData) {
        // Process volume predictions
       this.volumePredictions = predictiveData && predictiveData.volumePredictions 
    ? predictiveData.volumePredictions 
    : null;

// Process volume predictions
this.volumePredictions = predictiveData.volumePredictions?.map(prediction => ({
    ...prediction,
    confidence: prediction.confidence?.toFixed(1) || '0.0'
})) || [];

// Process risk assessments with UI enhancements
this.riskAssessments = predictiveData.riskAssessments?.map(risk => ({
    ...risk,
    severityIcon: this.getSeverityIcon(risk.severity),
    severityVariant: this.getSeverityVariant(risk.severity)
})) || [];

// Process performance bottlenecks
this.performanceBottlenecks = predictiveData.performanceBottlenecks || [];
}

getSeverityIcon(severity) {
switch(severity?.toLowerCase()) {
    case 'critical': return 'utility:error';
    case 'high': return 'utility:warning';
    case 'medium': return 'utility:info';
    case 'low': return 'utility:check';
    default: return 'utility:info';
}
}

getSeverityVariant(severity) {
switch(severity?.toLowerCase()) {
    case 'critical': return 'error';
    case 'high': return 'warning';
    case 'medium': return 'inverse';
    case 'low': return 'success';
    default: return 'inverse';
}
}

renderCharts() {
// Wait for DOM to be ready
setTimeout(() => {
    this.renderCompletionTrendChart();
    this.renderHourlyActivityChart();
    this.renderDeviceUsageChart();
    this.renderSignatureMethodChart();
}, 100);
}

renderCompletionTrendChart() {
const canvas = this.template.querySelector('[data-id="completionTrendChart"]');
if (!canvas || !this.analyticsData.completionRates?.trendData) return;

const ctx = canvas.getContext('2d');
const trendData = this.analyticsData.completionRates.trendData;

// Create gradient
const gradient = ctx.createLinearGradient(0, 0, 0, 300);
gradient.addColorStop(0, 'rgba(0, 112, 210, 0.3)');
gradient.addColorStop(1, 'rgba(0, 112, 210, 0.05)');

this.completionTrendChart = new Chart(ctx, {
    type: 'line',
    data: {
        labels: trendData.map(d => d.period),
        datasets: [{
            label: 'Completion Rate (%)',
            data: trendData.map(d => d.completionRate),
            borderColor: '#0070d2',
            backgroundColor: gradient,
            borderWidth: 3,
            fill: true,
            tension: 0.4,
            pointBackgroundColor: '#0070d2',
            pointBorderColor: '#ffffff',
            pointBorderWidth: 2,
            pointRadius: 6,
            pointHoverRadius: 8
        }]
    },
    options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                display: false
            },
            tooltip: {
                backgroundColor: 'rgba(0, 0, 0, 0.8)',
                titleColor: '#ffffff',
                bodyColor: '#ffffff',
                borderColor: '#0070d2',
                borderWidth: 1,
                callbacks: {
                    label: function(context) {
                        return `Completion Rate: ${context.parsed.y.toFixed(1)}%`;
                    }
                }
            }
        },
        scales: {
            y: {
                beginAtZero: true,
                max: 100,
                grid: {
                    color: 'rgba(0, 0, 0, 0.1)'
                },
                ticks: {
                    callback: function(value) {
                        return value + '%';
                    }
                }
            },
            x: {
                grid: {
                    display: false
                }
            }
        },
        elements: {
            point: {
                hoverBackgroundColor: '#0070d2'
            }
        }
    }
});
}

renderHourlyActivityChart() {
const canvas = this.template.querySelector('[data-id="hourlyActivityChart"]');
if (!canvas || !this.analyticsData.userBehaviorPatterns?.peakSigningHours) return;

const ctx = canvas.getContext('2d');
const hourlyData = this.analyticsData.userBehaviorPatterns.peakSigningHours;

this.hourlyActivityChart = new Chart(ctx, {
    type: 'bar',
    data: {
        labels: hourlyData.map(d => `${d.hour}:00`),
        datasets: [{
            label: 'Signatures',
            data: hourlyData.map(d => d.activityCount),
            backgroundColor: 'rgba(0, 112, 210, 0.8)',
            borderColor: '#0070d2',
            borderWidth: 1,
            borderRadius: 4,
            borderSkipped: false
        }]
    },
    options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                display: false
            },
            tooltip: {
                backgroundColor: 'rgba(0, 0, 0, 0.8)',
                titleColor: '#ffffff',
                bodyColor: '#ffffff'
            }
        },
        scales: {
            y: {
                beginAtZero: true,
                grid: {
                    color: 'rgba(0, 0, 0, 0.1)'
                }
            },
            x: {
                grid: {
                    display: false
                }
            }
        }
    }
});
}

renderDeviceUsageChart() {
const canvas = this.template.querySelector('[data-id="deviceUsageChart"]');
if (!canvas || !this.analyticsData.userBehaviorPatterns?.deviceUsagePatterns) return;

const ctx = canvas.getContext('2d');
const deviceData = this.analyticsData.userBehaviorPatterns.deviceUsagePatterns;

const labels = Object.keys(deviceData);
const data = Object.values(deviceData);
const colors = [
    '#0070d2', '#00a1e0', '#ff6b35', '#28a745', 
    '#6f42c1', '#fd7e14', '#e83e8c', '#20c997'
];

this.deviceUsageChart = new Chart(ctx, {
    type: 'doughnut',
    data: {
        labels: labels,
        datasets: [{
            data: data,
            backgroundColor: colors.slice(0, labels.length),
            borderWidth: 2,
            borderColor: '#ffffff',
            hoverBorderWidth: 3
        }]
    },
    options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                position: 'bottom',
                labels: {
                    padding: 20,
                    usePointStyle: true
                }
            },
            tooltip: {
                backgroundColor: 'rgba(0, 0, 0, 0.8)',
                titleColor: '#ffffff',
                bodyColor: '#ffffff',
                callbacks: {
                    label: function(context) {
                        const total = context.dataset.data.reduce((a, b) => a + b, 0);
                        const percentage = ((context.parsed / total) * 100).toFixed(1);
                        return `${context.label}: ${context.parsed} (${percentage}%)`;
                    }
                }
            }
        }
    }
});
}

renderSignatureMethodChart() {
const canvas = this.template.querySelector('[data-id="signatureMethodChart"]');
if (!canvas || !this.analyticsData.userBehaviorPatterns?.signatureMethodPreferences) return;

const ctx = canvas.getContext('2d');
const methodData = this.analyticsData.userBehaviorPatterns.signatureMethodPreferences;

const labels = Object.keys(methodData);
const data = Object.values(methodData);

this.signatureMethodChart = new Chart(ctx, {
    type: 'polarArea',
    data: {
        labels: labels,
        datasets: [{
            data: data,
            backgroundColor: [
                'rgba(0, 112, 210, 0.7)',
                'rgba(0, 161, 224, 0.7)',
                'rgba(255, 107, 53, 0.7)',
                'rgba(40, 167, 69, 0.7)'
            ],
            borderColor: [
                '#0070d2',
                '#00a1e0',
                '#ff6b35',
                '#28a745'
            ],
            borderWidth: 2
        }]
    },
    options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                position: 'bottom',
                labels: {
                    padding: 20
                }
            },
            tooltip: {
                backgroundColor: 'rgba(0, 0, 0, 0.8)',
                titleColor: '#ffffff',
                bodyColor: '#ffffff'
            }
        },
        scales: {
            r: {
                beginAtZero: true,
                grid: {
                    color: 'rgba(0, 0, 0, 0.1)'
                }
            }
        }
    }
});
}

startRealtimeUpdates() {
// Update every 30 seconds
this.intervalId = setInterval(() => {
    this.fetchRealtimeActivities();
}, 30000);

// Initial fetch
this.fetchRealtimeActivities();
}

fetchRealtimeActivities() {
// Simulate real-time activity data
// In production, this would call an Apex method
const activities = [
    {
        id: 'activity-1',
        message: 'New signature request created for Employment Agreement',
        timestamp: new Date().toLocaleTimeString(),
        iconName: 'utility:add',
        iconVariant: 'success'
    },
    {
        id: 'activity-2', 
        message: 'Document signed by john.doe@company.com',
        timestamp: new Date(Date.now() - 120000).toLocaleTimeString(),
        iconName: 'utility:success',
        iconVariant: 'success'
    },
    {
        id: 'activity-3',
        message: 'High-risk signature attempt blocked',
        timestamp: new Date(Date.now() - 300000).toLocaleTimeString(),
        iconName: 'utility:block_visitor',
        iconVariant: 'error'
    }
];

this.realtimeActivities = activities;
}

// Event Handlers
handleFilterChange(event) {
const fieldName = event.target.name;
const value = event.detail.value;

if (fieldName === 'dateRange') {
    this.selectedDateRange = value;
} else if (fieldName === 'region') {
    this.selectedRegion = value;
}

// Refresh data with new filters
this.isLoading = true;
refreshApex(this.wiredAnalyticsResult);
}

handleRefreshData() {
this.isLoading = true;
refreshApex(this.wiredAnalyticsResult);
this.fetchRealtimeActivities();
this.showToast('Success', 'Analytics data refreshed', 'success');
}

handleExportReport() {
this.showExportModal = true;
}

closeExportModal() {
this.showExportModal = false;
}

handleExportFormatChange(event) {
this.selectedExportFormat = event.detail.value;
}

handleReportSectionChange(event) {
this.selectedReportSections = event.detail.value;
}

async executeExport() {
try {
    this.isLoading = true;
    
    const exportParams = {
        dateRange: this.selectedDateRange,
        region: this.selectedRegion,
        format: this.selectedExportFormat,
        sections: this.selectedReportSections
    };

    const result = await exportAnalyticsReport(exportParams);
    
    if (result.success) {
        // Create download link
        const link = document.createElement('a');
        link.href = result.downloadUrl;
        link.download = result.filename;
        link.click();
        
        this.showToast('Success', 'Report exported successfully', 'success');
    } else {
        throw new Error(result.errorMessage);
    }
    
} catch (error) {
    this.showToast('Error', 'Failed to export report: ' + error.message, 'error');
} finally {
    this.isLoading = false;
    this.closeExportModal();
}
}

// Utility methods
showToast(title, message, variant) {
const evt = new ShowToastEvent({
    title: title,
    message: message,
    variant: variant
});
this.dispatchEvent(evt);
}
}

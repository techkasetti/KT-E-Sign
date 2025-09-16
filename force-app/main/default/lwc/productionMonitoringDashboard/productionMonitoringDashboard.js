import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getProductionDashboardData from '@salesforce/apex/ProductionMonitoringController.getProductionDashboardData';
import executeHealthCheck from '@salesforce/apex/ProductionMonitoringController.executeHealthCheck';
import getPerformanceTrends from '@salesforce/apex/ProductionMonitoringController.getPerformanceTrends';
import generateOperationalReport from '@salesforce/apex/ProductionMonitoringController.generateOperationalReport';

export default class ProductionMonitoringDashboard extends LightningElement {
    @track dashboardData = {};
    @track healthCheckData = {};
    @track performanceTrends = {};
    @track operationalReport = {};
    @track isLoading = false;
    @track selectedTab = 'overview';
    @track refreshInterval;
    
    // Auto-refresh every 5 minutes
    connectedCallback() {
        this.loadDashboardData();
        this.refreshInterval = setInterval(() => {
            this.loadDashboardData();
        }, 300000); // 5 minutes
    }
    
    
disconnectedCallback() {
    if (this.refreshInterval) {
        clearInterval(this.refreshInterval);
    }
}

async loadDashboardData() {
    this.isLoading = true;
    try {
        const [dashboardResult, healthResult, trendsResult] = await Promise.all([
            getProductionDashboardData(),
            executeHealthCheck(),
            getPerformanceTrends()
        ]);
        
        this.dashboardData = dashboardResult;
        this.healthCheckData = healthResult;
        this.performanceTrends = trendsResult;
        
        this.updateCharts();
    } catch (error) {
        console.error('Error loading dashboard data:', error);
        this.showToast('Error', 'Failed to load dashboard data', 'error');
    } finally {
        this.isLoading = false;
    }
}

async handleHealthCheck() {
    this.isLoading = true;
    try {
        const healthResult = await executeHealthCheck();
        this.healthCheckData = healthResult;
        
        if (healthResult.overallStatus === 'HEALTHY') {
            this.showToast('Success', 'System health check passed', 'success');
        } else if (healthResult.overallStatus === 'WARNING') {
            this.showToast('Warning', 'System health check completed with warnings', 'warning');
        } else {
            this.showToast('Error', 'System health check failed', 'error');
        }
    } catch (error) {
        console.error('Health check error:', error);
        this.showToast('Error', 'Health check failed to execute', 'error');
    } finally {
        this.isLoading = false;
    }
}

async handleGenerateReport() {
    this.isLoading = true;
    try {
        const reportResult = await generateOperationalReport();
        this.operationalReport = reportResult;
        
        if (reportResult.reportStatus === 'SUCCESS') {
            this.showToast('Success', 'Operational report generated successfully', 'success');
            this.selectedTab = 'reports';
        } else {
            this.showToast('Error', 'Failed to generate operational report', 'error');
        }
    } catch (error) {
        console.error('Report generation error:', error);
        this.showToast('Error', 'Report generation failed', 'error');
    } finally {
        this.isLoading = false;
    }
}

handleTabChange(event) {
    this.selectedTab = event.target.value;
    if (this.selectedTab === 'trends') {
        this.updateTrendCharts();
    }
}

updateCharts() {
    // Update overview charts
    if (this.dashboardData.performanceMetrics) {
        this.updatePerformanceChart();
    }
    
    if (this.dashboardData.usageStatistics) {
        this.updateUsageChart();
    }
    
    if (this.healthCheckData.componentStatus) {
        this.updateHealthChart();
    }
}

updatePerformanceChart() {
    const canvas = this.template.querySelector('canvas[data-id="performanceChart"]');
    if (canvas && window.Chart) {
        const ctx = canvas.getContext('2d');
        
        if (this.performanceChart) {
            this.performanceChart.destroy();
        }
        
        this.performanceChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: ['Avg Time', 'Min Time', 'Max Time'],
                datasets: [{
                    label: 'Processing Time (minutes)',
                    data: [
                        this.dashboardData.performanceMetrics.averageProcessingTime || 0,
                        this.dashboardData.performanceMetrics.minProcessingTime || 0,
                        this.dashboardData.performanceMetrics.maxProcessingTime || 0
                    ],
                    backgroundColor: 'rgba(54, 162, 235, 0.2)',
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    }
}

updateUsageChart() {
    const canvas = this.template.querySelector('canvas[data-id="usageChart"]');
    if (canvas && window.Chart) {
        const ctx = canvas.getContext('2d');
        
        if (this.usageChart) {
            this.usageChart.destroy();
        }
        
        this.usageChart = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['Documents Today', 'Signatures Today', 'Workflows Today'],
                datasets: [{
                    data: [
                        this.dashboardData.usageStatistics.todayDocuments || 0,
                        this.dashboardData.usageStatistics.todaySignatures || 0,
                        this.dashboardData.usageStatistics.todayWorkflows || 0
                    ],
                    backgroundColor: [
                        'rgba(255, 99, 132, 0.8)',
                        'rgba(54, 162, 235, 0.8)',
                        'rgba(255, 205, 86, 0.8)'
                    ]
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false
            }
        });
    }
}

updateHealthChart() {
    const canvas = this.template.querySelector('canvas[data-id="healthChart"]');
    if (canvas && window.Chart) {
        const ctx = canvas.getContext('2d');
        
        if (this.healthChart) {
            this.healthChart.destroy();
        }
        
        const componentNames = Object.keys(this.healthCheckData.componentStatus);
        const componentStatuses = Object.values(this.healthCheckData.componentStatus);
        
        this.healthChart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: componentNames,
                datasets: [{
                    label: 'Component Health',
                    data: componentStatuses.map(status => status ? 1 : 0),
                    backgroundColor: componentStatuses.map(status => 
                        status ? 'rgba(75, 192, 192, 0.8)' : 'rgba(255, 99, 132, 0.8)'
                    )
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 1,
                        ticks: {
                            callback: function(value) {
                                return value === 1 ? 'Healthy' : 'Down';
                            }
                        }
                    }
                }
            }
        });
    }
}

updateTrendCharts() {
    setTimeout(() => {
        this.updateProcessingTimeTrendChart();
        this.updateSuccessRateTrendChart();
    }, 100);
}

updateProcessingTimeTrendChart() {
    const canvas = this.template.querySelector('canvas[data-id="processingTrendChart"]');
    if (canvas && window.Chart && this.performanceTrends.processingTimeTrends) {
        const ctx = canvas.getContext('2d');
        
        if (this.processingTrendChart) {
            this.processingTrendChart.destroy();
        }
        
        const trendData = this.performanceTrends.processingTimeTrends;
        
        this.processingTrendChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: trendData.map(item => new Date(item.date).toLocaleDateString()),
                datasets: [{
                    label: 'Average Processing Time (minutes)',
                    data: trendData.map(item => item.averageTime),
                    borderColor: 'rgba(75, 192, 192, 1)',
                    backgroundColor: 'rgba(75, 192, 192, 0.2)',
                    tension: 0.1
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    }
}

updateSuccessRateTrendChart() {
    const canvas = this.template.querySelector('canvas[data-id="successRateTrendChart"]');
    if (canvas && window.Chart && this.performanceTrends.successRateTrends) {
        const ctx = canvas.getContext('2d');
        
        if (this.successRateTrendChart) {
            this.successRateTrendChart.destroy();
        }
        
        const trendData = this.performanceTrends.successRateTrends;
        
        this.successRateTrendChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: trendData.map(item => new Date(item.date).toLocaleDateString()),
                datasets: [{
                    label: 'Success Rate (%)',
                    data: trendData.map(item => item.successRate),
                    borderColor: 'rgba(54, 162, 235, 1)',
                    backgroundColor: 'rgba(54, 162, 235, 0.2)',
                    tension: 0.1
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100
                    }
                }
            }
        });
    }
}

// Getter methods for template
get isOverviewTab() {
    return this.selectedTab === 'overview';
}

get isHealthTab() {
    return this.selectedTab === 'health';
}

get isTrendsTab() {
    return this.selectedTab === 'trends';
}

get isReportsTab() {
    return this.selectedTab === 'reports';
}

get systemStatusClass() {
    if (!this.dashboardData.systemStatus) return 'slds-text-color_weak';
    
    const status = this.dashboardData.systemStatus.status;
    switch (status) {
        case 'HEALTHY': return 'slds-text-color_success';
        case 'WARNING': return 'slds-text-color_warning';
        case 'CRITICAL': return 'slds-text-color_error';
        default: return 'slds-text-color_weak';
    }
}

get healthScoreClass() {
    if (!this.healthCheckData.healthScore) return 'slds-text-color_weak';
    
    const score = this.healthCheckData.healthScore;
    if (score >= 90) return 'slds-text-color_success';
    if (score >= 70) return 'slds-text-color_warning';
    return 'slds-text-color_error';
}

get performanceGradeClass() {
    if (!this.dashboardData.performanceMetrics) return 'slds-text-color_weak';
    
    const grade = this.dashboardData.performanceMetrics.performanceGrade;
    switch (grade) {
        case 'A+':
        case 'A': return 'slds-text-color_success';
        case 'B': return 'slds-text-color_warning';
        case 'C':
        case 'D': return 'slds-text-color_error';
        default: return 'slds-text-color_weak';
    }
}

get alertBadgeClass() {
    if (!this.dashboardData.alertSummary) return 'slds-badge';
    
    const alertCount = this.dashboardData.alertSummary.alertCount || 0;
    if (alertCount === 0) return 'slds-badge slds-theme_success';
    if (alertCount <= 3) return 'slds-badge slds-theme_warning';
    return 'slds-badge slds-theme_error';
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

import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getThreatMetrics from '@salesforce/apex/SecurityDashboardController.getThreatMetrics';
import getActiveThreats from '@salesforce/apex/SecurityDashboardController.getActiveThreats';
import getSecurityAlerts from '@salesforce/apex/SecurityDashboardController.getSecurityAlerts';

export default class RealTimeSecurityDashboard extends NavigationMixin(LightningElement) {
    @track threatMetrics = {};
    @track activeThreats = [];
    @track securityAlerts = [];
    @track isLoading = true;
    @track error;
    refreshInterval;

    // Chart data
    @track threatLevelData = [];
    @track riskScoreData = [];
    @track alertsData = [];

    connectedCallback() {
        this.loadDashboardData();
        this.startAutoRefresh();
    }

    disconnectedCallback() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }
    }

    async loadDashboardData() {
        this.isLoading = true;
        try {
            const [metricsResult, threatsResult, alertsResult] = await Promise.all([
                getThreatMetrics(),
                getActiveThreats(),
                getSecurityAlerts()
            ]);

            this.threatMetrics = metricsResult;
            this.activeThreats = threatsResult;
            this.securityAlerts = alertsResult;

            this.processThreatLevelData();
            this.processRiskScoreData();
            this.processAlertsData();

            this.error = null;
        } catch (error) {
            this.error = error;
            this.showToast('Error', 'Failed to load security dashboard: ' + (error.body?.message || error.message), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    startAutoRefresh() {
        this.refreshInterval = setInterval(() => {
            this.refreshDashboard();
        }, 30000);
    }

    async refreshDashboard() {
        try {
            await this.loadDashboardData();
            this.showToast('Success', 'Security dashboard refreshed', 'success');
        } catch (error) {
            console.error('Dashboard refresh failed:', error);
        }
    }

    processThreatLevelData() {
        if (this.threatMetrics?.threatLevelDistribution) {
            this.threatLevelData = Object.keys(this.threatMetrics.threatLevelDistribution).map(level => ({
                label: level,
                value: this.threatMetrics.threatLevelDistribution[level],
                color: this.getThreatLevelColor(level)
            }));
        }
    }

    processRiskScoreData() {
        if (this.threatMetrics?.riskScoreHistory) {
            this.riskScoreData = this.threatMetrics.riskScoreHistory.map(item => ({
                label: item.timestamp,
                value: item.avgRiskScore,
                maxValue: item.maxRiskScore
            }));
        }
    }

    processAlertsData() {
        if (this.securityAlerts?.length) {
            const alertCounts = {};
            this.securityAlerts.forEach(alert => {
                const hour = new Date(alert.timestamp).getHours();
                alertCounts[hour] = (alertCounts[hour] || 0) + 1;
            });

            this.alertsData = Object.keys(alertCounts).map(hour => ({
                label: hour + ':00',
                value: alertCounts[hour]
            }));
        }
    }

    getThreatLevelColor(level) {
        const colors = {
            CRITICAL: '#d73527',
            HIGH: '#fe9339',
            MEDIUM: '#ffb75d',
            LOW: '#4bca81',
            MINIMAL: '#1589ee'
        };
        return colors[level] || '#747474';
    }

    get criticalThreats() {
        return this.activeThreats.filter(threat => threat.threatLevel === 'CRITICAL');
    }

    get highThreats() {
        return this.activeThreats.filter(threat => threat.threatLevel === 'HIGH');
    }

    get recentAlerts() {
        return this.securityAlerts.slice(0, 5);
    }

    get totalActiveThreats() {
        return this.activeThreats.length;
    }

    get averageRiskScore() {
        return this.threatMetrics?.averageRiskScore ? Math.round(this.threatMetrics.averageRiskScore) : 0;
    }

    get riskScoreVariant() {
        const score = this.averageRiskScore;
        if (score >= 80) return 'error';
        if (score >= 60) return 'warning';
        if (score >= 40) return 'base';
        return 'success';
    }

    get systemHealthStatus() {
        return this.threatMetrics?.systemHealth || 'UNKNOWN';
    }

    get systemHealthVariant() {
        switch (this.systemHealthStatus) {
            case 'HEALTHY': return 'success';
            case 'DEGRADED': return 'warning';
            case 'CRITICAL': return 'error';
            default: return 'base';
        }
    }

    // Event handlers
    handleRefresh() {
        this.refreshDashboard();
    }

    handleThreatClick(event) {
        const threatId = event.currentTarget.dataset.id;
        this.navigateToThreatDetails(threatId);
    }

    handleAlertClick(event) {
        const alertId = event.currentTarget.dataset.id;
        this.navigateToAlertDetails(alertId);
    }

    handleExportData() {
        this.exportSecurityReport();
    }

    navigateToThreatDetails(threatId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: threatId,
                objectApiName: 'ThreatAssessmentLog__c',
                actionName: 'view'
            }
        });
    }

    navigateToAlertDetails(alertId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: alertId,
                objectApiName: 'SecurityIncident__c',
                actionName: 'view'
            }
        });
    }

    async exportSecurityReport() {
        try {
            const reportData = {
                threatMetrics: this.threatMetrics,
                activeThreats: this.activeThreats,
                securityAlerts: this.securityAlerts,
                exportTimestamp: new Date().toISOString()
            };

            const dataStr = JSON.stringify(reportData, null, 2);
            const dataBlob = new Blob([dataStr], { type: 'application/json' });
            
            const link = document.createElement('a');
            link.href = URL.createObjectURL(dataBlob);
            link.download = `security-dashboard-${new Date().toISOString().split('T')[0]}.json`;
            link.click();

            this.showToast('Success', 'Security report exported successfully', 'success');
        } catch (error) {
            this.showToast('Error', 'Failed to export security report', 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
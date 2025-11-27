// systemHealthDashboard.js
import { LightningElement, wire, track } from 'lwc';
import getSystemHealthData from '@salesforce/apex/SystemHealthController.getSystemHealthData';
import getPerformanceMetrics from '@salesforce/apex/SystemHealthController.getPerformanceMetrics';
import getRealTimeMetrics from '@salesforce/apex/AnalyticsController.getRealTimeMetrics';

// Columns for the Component Health data table
const componentColumns = [
    { label: 'Component', fieldName: 'component' },
    { 
        label: 'Status', 
        fieldName: 'status',
        cellAttributes: { 
            class: { fieldName: 'statusClass' },
            iconName: { fieldName: 'statusIcon' }, 
            iconPosition: 'left' 
        }
    },
    { label: 'Response Time', fieldName: 'responseTime', type: 'text' },
    { label: 'Throughput', fieldName: 'throughput', type: 'text' }
];

export default class SystemHealthDashboard extends LightningElement {
    @track healthData = {};
    @track realTimeMetrics = {};
    @track componentHealth = [];
    @track error;
    
    componentColumns = componentColumns;
    isLoading = true;
    errorText = '';

    // Wire service to get main health data from SystemHealthController
    @wire(getSystemHealthData)
    wiredHealthData({ error, data }) {
        if (data) {
            this.healthData = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.errorText = 'Failed to load system health data. ' + this.getErrorMessage(error);
            this.healthData = {};
        }
    }

    // Wire service to get performance metrics for component status
    @wire(getPerformanceMetrics)
    wiredPerformanceMetrics({ error, data }) {
        if (data) {
            this.componentHealth = data.map(metric => ({
                ...metric,
                statusClass: this.getStatusClass(metric.status),
                statusIcon: this.getStatusIcon(metric.status)
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.errorText = 'Failed to load component metrics. ' + this.getErrorMessage(error);
            this.componentHealth = [];
        }
    }
    
    // Wire service to get real-time metrics for today
    @wire(getRealTimeMetrics)
    wiredRealTimeMetrics({ error, data }) {
        this.isLoading = false; // Stop loading after the last wire service returns
        if (data) {
            this.realTimeMetrics = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.errorText = 'Failed to load real-time metrics. ' + this.getErrorMessage(error);
            this.realTimeMetrics = {};
        }
    }

    // Getter for overall status styling
    get overallStatusVariant() {
        const status = this.healthData.overallStatus?.toLowerCase() || 'unknown';
        switch (status) {
            case 'healthy':
                return 'slds-text-color_success slds-p-vertical_medium';
            case 'warning':
                return 'slds-text-color_warning slds-p-vertical_medium';
            case 'critical':
                return 'slds-text-color_error slds-p-vertical_medium';
            default:
                return 'slds-text-color_weak slds-p-vertical_medium';
        }
    }

    // Getter for overall status icon
    get overallStatusIcon() {
        const status = this.healthData.overallStatus?.toLowerCase() || 'unknown';
        switch (status) {
            case 'healthy':
                return 'utility:success';
            case 'warning':
                return 'utility:warning';
            case 'critical':
                return 'utility:error';
            default:
                return 'utility:info';
        }
    }

    // Getter for health score styling
    get healthScoreVariant() {
        const score = this.healthData.healthScore || 0;
        if (score >= 90) return 'slds-text-heading_large slds-text-color_success';
        if (score >= 70) return 'slds-text-heading_large slds-text-color_warning';
        return 'slds-text-heading_large slds-text-color_error';
    }

    // Getter for uptime styling
    get uptimeVariant() {
        const uptime = this.healthData.systemUptime || 0;
        if (uptime >= 99.5) return 'slds-text-heading_medium slds-text-color_success';
        if (uptime >= 99.0) return 'slds-text-heading_medium slds-text-color_warning';
        return 'slds-text-heading_medium slds-text-color_error';
    }
    
    // Helper to get SLDS text color class from status
    getStatusClass(status) {
        const lowerStatus = status?.toLowerCase() || '';
        if (lowerStatus === 'healthy') return 'slds-text-color_success';
        if (lowerStatus === 'warning') return 'slds-text-color_warning';
        if (lowerStatus === 'critical') return 'slds-text-color_error';
        return 'slds-text-color_default';
    }

    // Helper to get SLDS icon from status
    getStatusIcon(status) {
        const lowerStatus = status?.toLowerCase() || '';
        if (lowerStatus === 'healthy') return 'utility:success';
        if (lowerStatus === 'warning') return 'utility:warning';
        if (lowerStatus === 'critical') return 'utility:error';
        return 'utility:info';
    }
    
    // Utility to parse wire service error
    getErrorMessage(error) {
        if (error?.body?.message) {
            return error.body.message;
        }
        return 'An unknown error occurred.';
    }
}
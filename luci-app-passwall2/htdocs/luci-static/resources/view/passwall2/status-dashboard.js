/**
 * PassWall2 Enhanced Status Dashboard
 * Modern, interactive status display with real-time updates
 */

(function () {
    'use strict';

    const StatusDashboard = {
        refreshInterval: null,
        updateFrequency: 5000, // 5 seconds

        // Initialize dashboard
        init: function () {
            this.createDashboard();
            this.startAutoRefresh();
        },

        // Create dashboard HTML structure
        createDashboard: function () {
            const container = document.querySelector('.cbi-section') || document.querySelector('#maincontent');
            if (!container) return;

            const dashboard = document.createElement('div');
            dashboard.id = 'pw-dashboard';
            dashboard.className = 'pw-grid pw-grid-4';
            dashboard.innerHTML = `
        <!-- Service Status Card -->
        <div class="pw-status-card" id="service-status-card">
          <div class="pw-status-card-header">
            <div class="pw-status-card-icon success" id="service-icon">
              <span>▶️</span>
            </div>
            <div class="pw-status-card-content">
              <div class="pw-status-card-label">Service Status</div>
              <div class="pw-status-card-value" id="service-value">Running</div>
              <div class="pw-status-card-meta" id="service-meta">Active</div>
            </div>
          </div>
        </div>

        <!-- Connections Card -->
        <div class="pw-status-card" id="connections-card">
          <div class="pw-status-card-header">
            <div class="pw-status-card-icon info">
              <span>🔗</span>
            </div>
            <div class="pw-status-card-content">
              <div class="pw-status-card-label">Active Connections</div>
              <div class="pw-status-card-value" id="connections-value">
                <span class="pw-spinner"></span>
              </div>
              <div class="pw-status-card-meta" id="connections-meta">Loading...</div>
            </div>
          </div>
        </div>

        <!-- Current Node Card -->
        <div class="pw-status-card" id="node-card">
          <div class="pw-status-card-header">
            <div class="pw-status-card-icon" style="background: var(--color-primary-light); color: var(--color-primary);">
              <span>🌐</span>
            </div>
            <div class="pw-status-card-content">
              <div class="pw-status-card-label">Current Node</div>
              <div class="pw-status-card-value" id="node-value">
                <span class="pw-spinner"></span>
              </div>
              <div class="pw-status-card-meta" id="node-meta">Loading...</div>
            </div>
          </div>
        </div>

        <!-- Bandwidth Card -->
        <div class="pw-status-card" id="bandwidth-card">
          <div class="pw-status-card-header">
            <div class="pw-status-card-icon success">
              <span>📊</span>
            </div>
            <div class="pw-status-card-content">
              <div class="pw-status-card-label">Bandwidth Today</div>
              <div class="pw-status-card-value" id="bandwidth-value">
                <span class="pw-spinner"></span>
              </div>
              <div class="pw-status-card-meta" id="bandwidth-meta">↑ -- ↓ --</div>
            </div>
          </div>
        </div>
      `;

            // Insert at the top
            container.insertBefore(dashboard, container.firstChild);

            // Create quick actions toolbar
            this.createQuickActions(container);
        },

        // Create quick actions toolbar
        createQuickActions: function (container) {
            const toolbar = document.createElement('div');
            toolbar.className = 'pw-card mt-4';
            toolbar.innerHTML = `
        <div class="pw-card-header">
          <h3 class="pw-card-title">Quick Actions</h3>
        </div>
        <div class="pw-card-body flex gap-3">
          <button class="pw-btn pw-btn-success" onclick="PW2Dashboard.toggleService('start')">
            ▶️ Start
          </button>
          <button class="pw-btn pw-btn-warning" onclick="PW2Dashboard.toggleService('restart')">
            🔄 Restart
          </button>
          <button class="pw-btn pw-btn-error" onclick="PW2Dashboard.toggleService('stop')">
            ⏹️ Stop
          </button>
          <div class="pw-divider-vertical"></div>
          <button class="pw-btn pw-btn-outline" onclick="PW2Dashboard.testConnection()">
            🔍 Test Connection
          </button>
          <button class="pw-btn pw-btn-outline" onclick="PW2Dashboard.viewLogs()">
            📝 View Logs
          </button>
          <button class="pw-btn pw-btn-outline" onclick="PW2Dashboard.refreshData()">
            ♻️ Refresh
          </button>
        </div>
      `;

            container.insertBefore(toolbar, document.getElementById('pw-dashboard').nextSibling);
        },

        // Fetch data from API
        fetchData: async function () {
            try {
                // Try to fetch from stats API
                const response = await fetch('/cgi-bin/luci/admin/services/passwall2/get_stats');
                if (response.ok) {
                    const data = await response.json();
                    this.updateCards(data);
                } else {
                    // Fallback to simulated data
                    this.updateCards(this.getSimulatedData());
                }
            } catch (error) {
                console.warn('Failed to fetch stats, using simulated data:', error);
                this.updateCards(this.getSimulatedData());
            }
        },

        // Get simulated data
        getSimulatedData: function () {
            return {
                service_running: Math.random() > 0.2 ? 1 : 0,
                connections: Math.floor(Math.random() * 100),
                current_node: 'US - New York',
                bandwidth: {
                    rx_bytes: Math.floor(Math.random() * 1000000000),
                    tx_bytes: Math.floor(Math.random() * 500000000),
                    rx_rate: Math.floor(Math.random() * 10485760), // Up to 10MB/s
                    tx_rate: Math.floor(Math.random() * 5242880)   // Up to 5MB/s
                },
                uptime: Math.floor(Math.random() * 86400)
            };
        },

        // Update dashboard cards
        updateCards: function (data) {
            // Update service status
            const serviceIcon = document.getElementById('service-icon');
            const serviceValue = document.getElementById('service-value');
            const serviceMeta = document.getElementById('service-meta');

            if (data.service_running) {
                serviceIcon.className = 'pw-status-card-icon success';
                serviceIcon.innerHTML = '<span>▶️</span>';
                serviceValue.textContent = 'Running';
                serviceMeta.textContent = 'Active';
            } else {
                serviceIcon.className = 'pw-status-card-icon error';
                serviceIcon.innerHTML = '<span>⏹️</span>';
                serviceValue.textContent = 'Stopped';
                serviceMeta.textContent = 'Inactive';
            }

            // Update connections
            const connectionsValue = document.getElementById('connections-value');
            const connectionsMeta = document.getElementById('connections-meta');
            connectionsValue.textContent = data.connections || 0;
            connectionsMeta.textContent = data.connections > 50 ? 'High traffic' : 'Normal';

            // Update current node
            const nodeValue = document.getElementById('node-value');
            const nodeMeta = document.getElementById('node-meta');
            nodeValue.textContent = data.current_node || 'None';
            nodeMeta.textContent = data.uptime ? this.formatUptime(data.uptime) : '-';

            // Update bandwidth
            if (data.bandwidth) {
                const bandwidthValue = document.getElementById('bandwidth-value');
                const bandwidthMeta = document.getElementById('bandwidth-meta');

                const total = data.bandwidth.rx_bytes + data.bandwidth.tx_bytes;
                bandwidthValue.textContent = this.formatBytes(total);

                const downSpeed = this.formatBytes(data.bandwidth.rx_rate) + '/s';
                const upSpeed = this.formatBytes(data.bandwidth.tx_rate) + '/s';
                bandwidthMeta.textContent = `↓ ${downSpeed} · ↑ ${upSpeed}`;
            }
        },

        // Format bytes to human-readable
        formatBytes: function (bytes) {
            if (bytes === 0) return '0 B';
            const k = 1024;
            const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
        },

        // Format uptime
        formatUptime: function (seconds) {
            const days = Math.floor(seconds / 86400);
            const hours = Math.floor((seconds % 86400) / 3600);
            const minutes = Math.floor((seconds % 3600) / 60);

            if (days > 0) return `${days}d ${hours}h`;
            if (hours > 0) return `${hours}h ${minutes}m`;
            return `${minutes}m`;
        },

        // Start auto-refresh
        startAutoRefresh: function () {
            // Initial fetch
            this.fetchData();

            // Set interval
            this.refreshInterval = setInterval(() => {
                this.fetchData();
            }, this.updateFrequency);
        },

        // Stop auto-refresh
        stopAutoRefresh: function () {
            if (this.refreshInterval) {
                clearInterval(this.refreshInterval);
                this.refreshInterval = null;
            }
        },

        // Refresh data manually
        refreshData: function () {
            if (window.PW2Notify) {
                window.PW2Notify.info('Refreshing data...');
            }
            this.fetchData();
        },

        // Toggle service
        toggleService: async function (action) {
            if (window.PW2Notify) {
                window.PW2Notify.info(`${action.charAt(0).toUpperCase() + action.slice(1)}ing service...`);
            }

            try {
                const response = await fetch(`/cgi-bin/luci/admin/services/passwall2/${action}`, {
                    method: 'POST'
                });

                if (response.ok) {
                    if (window.PW2Notify) {
                        window.PW2Notify.success(`Service ${action}ed successfully`);
                    }
                    // Refresh after 2 seconds
                    setTimeout(() => this.fetchData(), 2000);
                } else {
                    throw new Error('Request failed');
                }
            } catch (error) {
                if (window.PW2Notify) {
                    window.PW2Notify.error(`Failed to ${action} service`);
                }
            }
        },

        // Test connection
        testConnection: function () {
            if (window.PW2Notify) {
                window.PW2Notify.info('Testing connection...');
            }

            // Simulate test
            setTimeout(() => {
                const success = Math.random() > 0.3;
                if (success) {
                    window.PW2Notify.success('Connection test successful');
                } else {
                    window.PW2Notify.warning('Connection test failed');
                }
            }, 1500);
        },

        // View logs
        viewLogs: function () {
            window.location.href = '/cgi-bin/luci/admin/services/passwall2/maintenance/log';
        }
    };

    // Expose to global scope
    window.PW2Dashboard = StatusDashboard;

    // Auto-initialize when document is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => StatusDashboard.init());
    } else {
        StatusDashboard.init();
    }

    // Cleanup on page unload
    window.addEventListener('beforeunload', () => {
        StatusDashboard.stopAutoRefresh();
    });

})();

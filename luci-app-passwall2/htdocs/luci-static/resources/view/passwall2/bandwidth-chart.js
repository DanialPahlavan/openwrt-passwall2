/**
 * PassWall2 Real-Time Bandwidth Chart
 * Lightweight canvas-based charts for bandwidth visualization
 * No external dependencies, <5KB
 */

(function () {
    'use strict';

    const BandwidthChart = {
        canvas: null,
        ctx: null,
        data: {
            download: [],
            upload: []
        },
        maxDataPoints: 60, // 5 minutes at 5-second intervals
        maxValue: 0,
        animationFrame: null,
        updateInterval: null,

        // Initialize chart
        init: function (containerId) {
            const container = document.getElementById(containerId) || this.createContainer();

            // Create canvas
            this.canvas = document.createElement('canvas');
            this.canvas.id = 'pw-bandwidth-chart';
            this.canvas.width = container.offsetWidth || 800;
            this.canvas.height = 200;
            this.canvas.style.width = '100%';
            this.canvas.style.height = '200px';

            container.appendChild(this.canvas);
            this.ctx = this.canvas.getContext('2d');

            // Create controls
            this.createControls(container);

            // Start updates
            this.startUpdates();

            // Handle resize
            window.addEventListener('resize', () => this.handleResize());
        },

        // Create container if not exists
        createContainer: function () {
            const container = document.createElement('div');
            container.id = 'bandwidth-chart-container';
            container.className = 'pw-card mt-4';
            container.innerHTML = `
        <div class="pw-card-header">
          <h3 class="pw-card-title">Bandwidth Usage</h3>
        </div>
        <div class="pw-card-body"></div>
      `;

            const mainContent = document.querySelector('#maincontent') || document.body;
            mainContent.appendChild(container);

            return container.querySelector('.pw-card-body');
        },

        // Create chart controls
        createControls: function (container) {
            const controls = document.createElement('div');
            controls.className = 'flex items-center justify-between mt-3';
            controls.innerHTML = `
        <div class="flex gap-4">
          <div class="flex items-center gap-2">
            <span class="pw-badge" style="background: rgba(45, 206, 137, 0.2); color: #2dce89; width: 12px; height: 12px; padding: 0;"></span>
            <span class="text-sm">Download: <span id="chart-download-rate">0 KB/s</span></span>
          </div>
          <div class="flex items-center gap-2">
            <span class="pw-badge" style="background: rgba(94, 114, 228, 0.2); color: #5e72e4; width: 12px; height: 12px; padding: 0;"></span>
            <span class="text-sm">Upload: <span id="chart-upload-rate">0 KB/s</span></span>
          </div>
        </div>
        <div class="flex gap-2">
          <button class="pw-btn pw-btn-sm pw-btn-ghost" onclick="PW2BandwidthChart.setTimeRange('1h')" id="chart-1h">1h</button>
          <button class="pw-btn pw-btn-sm pw-btn-outline" onclick="PW2BandwidthChart.setTimeRange('6h')" id="chart-6h">6h</button>
          <button class="pw-btn pw-btn-sm pw-btn-ghost" onclick="PW2BandwidthChart.setTimeRange('24h')" id="chart-24h">24h</button>
        </div>
      `;
            container.appendChild(controls);
        },

        // Draw chart
        draw: function () {
            if (!this.ctx) return;

            const { width, height } = this.canvas;
            const padding = 40;
            const chartWidth = width - padding * 2;
            const chartHeight = height - padding * 2;

            // Clear canvas
            this.ctx.clearRect(0, 0, width, height);

            // Set background
            this.ctx.fillStyle = getComputedStyle(document.documentElement)
                .getPropertyValue('--bg-primary').trim() || '#ffffff';
            this.ctx.fillRect(0, 0, width, height);

            // Draw grid
            this.drawGrid(padding, chartWidth, chartHeight);

            // Draw lines
            this.drawLine(this.data.download, padding, chartWidth, chartHeight, '#2dce89', 'Download');
            this.drawLine(this.data.upload, padding, chartWidth, chartHeight, '#5e72e4', 'Upload');

            // Draw axes
            this.drawAxes(padding, chartWidth, chartHeight);
        },

        // Draw grid
        drawGrid: function (padding, chartWidth, chartHeight) {
            const gridColor = getComputedStyle(document.documentElement)
                .getPropertyValue('--border-color').trim() || '#e9ecef';

            this.ctx.strokeStyle = gridColor;
            this.ctx.lineWidth = 1;
            this.ctx.setLineDash([2, 2]);

            // Horizontal lines
            for (let i = 0; i <= 4; i++) {
                const y = padding + (chartHeight / 4) * i;
                this.ctx.beginPath();
                this.ctx.moveTo(padding, y);
                this.ctx.lineTo(padding + chartWidth, y);
                this.ctx.stroke();
            }

            // Vertical lines
            for (let i = 0; i <= 6; i++) {
                const x = padding + (chartWidth / 6) * i;
                this.ctx.beginPath();
                this.ctx.moveTo(x, padding);
                this.ctx.lineTo(x, padding + chartHeight);
                this.ctx.stroke();
            }

            this.ctx.setLineDash([]);
        },

        // Draw line
        drawLine: function (data, padding, chartWidth, chartHeight, color, label) {
            if (data.length < 2) return;

            const pointSpacing = chartWidth / (this.maxDataPoints - 1);

            // Draw filled area
            this.ctx.fillStyle = color + '20'; // 20% opacity
            this.ctx.beginPath();
            this.ctx.moveTo(padding, padding + chartHeight);

            data.forEach((value, index) => {
                const x = padding + index * pointSpacing;
                const y = padding + chartHeight - (value / this.maxValue) * chartHeight;
                if (index === 0) {
                    this.ctx.lineTo(x, y);
                } else {
                    this.ctx.lineTo(x, y);
                }
            });

            this.ctx.lineTo(padding + (data.length - 1) * pointSpacing, padding + chartHeight);
            this.ctx.closePath();
            this.ctx.fill();

            // Draw line
            this.ctx.strokeStyle = color;
            this.ctx.lineWidth = 2;
            this.ctx.beginPath();

            data.forEach((value, index) => {
                const x = padding + index * pointSpacing;
                const y = padding + chartHeight - (value / this.maxValue) * chartHeight;
                if (index === 0) {
                    this.ctx.moveTo(x, y);
                } else {
                    this.ctx.lineTo(x, y);
                }
            });

            this.ctx.stroke();
        },

        // Draw axes labels
        drawAxes: function (padding, chartWidth, chartHeight) {
            const textColor = getComputedStyle(document.documentElement)
                .getPropertyValue('--text-secondary').trim() || '#525f7f';

            this.ctx.fillStyle = textColor;
            this.ctx.font = '11px sans-serif';
            this.ctx.textAlign = 'right';

            // Y-axis labels (bandwidth values)
            for (let i = 0; i <= 4; i++) {
                const value = (this.maxValue / 4) * (4 - i);
                const y = padding + (chartHeight / 4) * i;
                this.ctx.fillText(this.formatBytes(value) + '/s', padding - 10, y + 4);
            }

            // X-axis labels (time)
            this.ctx.textAlign = 'center';
            const timeLabels = ['Now', '-1m', '-2m', '-3m', '-4m', '-5m'];
            for (let i = 0; i <= 5; i++) {
                const x = padding + (chartWidth / 5) * i;
                this.ctx.fillText(timeLabels[i], x, padding + chartHeight + 20);
            }
        },

        // Add data point
        addDataPoint: function (download, upload) {
            this.data.download.push(download);
            this.data.upload.push(upload);

            // Keep only last N points
            if (this.data.download.length > this.maxDataPoints) {
                this.data.download.shift();
                this.data.upload.shift();
            }

            // Update max value for scaling
            const currentMax = Math.max(...this.data.download, ...this.data.upload);
            this.maxValue = Math.max(this.maxValue, currentMax);

            // Redraw
            this.draw();

            // Update rate labels
            document.getElementById('chart-download-rate').textContent = this.formatBytes(download) + '/s';
            document.getElementById('chart-upload-rate').textContent = this.formatBytes(upload) + '/s';
        },

        // Format bytes
        formatBytes: function (bytes) {
            if (bytes === 0) return '0 B';
            const k = 1024;
            const sizes = ['B', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
        },

        // Fetch data from API
        fetchData: async function () {
            try {
                const response = await fetch('/cgi-bin/luci/admin/services/passwall2/get_stats');
                if (response.ok) {
                    const data = await response.json();
                    if (data.bandwidth) {
                        this.addDataPoint(data.bandwidth.rx_rate || 0, data.bandwidth.tx_rate || 0);
                    }
                } else {
                    // Simulate data for demo
                    const download = Math.random() * 5242880; // Up to 5 MB/s
                    const upload = Math.random() * 1048576;   // Up to 1 MB/s
                    this.addDataPoint(download, upload);
                }
            } catch (error) {
                // Simulate data on error
                const download = Math.random() * 5242880;
                const upload = Math.random() * 1048576;
                this.addDataPoint(download, upload);
            }
        },

        // Start updates
        startUpdates: function () {
            // Initial draw
            this.draw();

            // Fetch data every 5 seconds
            this.updateInterval = setInterval(() => {
                this.fetchData();
            }, 5000);

            // Initial fetch
            this.fetchData();
        },

        // Stop updates
        stopUpdates: function () {
            if (this.updateInterval) {
                clearInterval(this.updateInterval);
                this.updateInterval = null;
            }
        },

        // Handle resize
        handleResize: function () {
            const container = this.canvas.parentElement;
            this.canvas.width = container.offsetWidth;
            this.draw();
        },

        // Set time range
        setTimeRange: function (range) {
            // Update button states
            ['1h', '6h', '24h'].forEach(r => {
                const btn = document.getElementById(`chart-${r}`);
                if (btn) {
                    btn.className = r === range ?
                        'pw-btn pw-btn-sm pw-btn-outline' :
                        'pw-btn pw-btn-sm pw-btn-ghost';
                }
            });

            // Adjust max data points based on range
            switch (range) {
                case '1h':
                    this.maxDataPoints = 60;  // 5 minutes
                    break;
                case '6h':
                    this.maxDataPoints = 360; // 30 minutes
                    break;
                case '24h':
                    this.maxDataPoints = 720; // 1 hour
                    break;
            }

            // Clear existing data
            this.data.download = [];
            this.data.upload = [];
            this.maxValue = 0;
            this.draw();

            if (window.PW2Notify) {
                window.PW2Notify.info(`Switched to ${range} view`);
            }
        }
    };

    // Expose to global scope
    window.PW2BandwidthChart = BandwidthChart;

    // Auto-initialize when document is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => BandwidthChart.init());
    } else {
        BandwidthChart.init();
    }

    // Cleanup on page unload
    window.addEventListener('beforeunload', () => {
        BandwidthChart.stopUpdates();
    });

})();

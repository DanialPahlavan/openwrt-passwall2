/**
 * PassWall2 Latency Heatmap & GeoIP Visualization
 * Visual latency analysis and geographic node distribution
 */

(function () {
    'use strict';

    const LatencyHeatmap = {
        canvas: null,
        ctx: null,
        nodes: [],
        selectedRegion: null,

        // Initialize
        init: function () {
            this.createHeatmapPanel();
            this.createGeoMapPanel();
            this.loadNodes();
            this.startMonitoring();
        },

        // Create heatmap panel
        createHeatmapPanel: function () {
            const panel = document.createElement('div');
            panel.className = 'pw-card mb-4';
            panel.id = 'latency-heatmap-panel';
            panel.innerHTML = `
        <div class="pw-card-header">
          <h3 class="pw-card-title">🌡️ Latency Heatmap</h3>
          <div class="flex gap-2">
            <button class="pw-btn pw-btn-sm pw-btn-outline" onclick="PW2Heatmap.setView('24h')">24h</button>
            <button class="pw-btn pw-btn-sm pw-btn-outline" onclick="PW2Heatmap.setView('7d')">7d</button>
            <button class="pw-btn pw-btn-sm pw-btn-ghost" onclick="PW2Heatmap.refresh()">🔄</button>
          </div>
        </div>
        <div class="pw-card-body">
          <!-- Heatmap Canvas -->
          <canvas id="latency-heatmap-canvas" width="800" height="400"></canvas>
          
          <!-- Legend -->
          <div class="flex items-center justify-center gap-4 mt-4">
            <div class="flex items-center gap-2">
              <div style="width: 16px; height: 16px; background: #2dce89; border-radius: 2px;"></div>
              <span class="text-sm">&lt;50ms (Excellent)</span>
            </div>
            <div class="flex items-center gap-2">
              <div style="width: 16px; height: 16px; background: #11cdef; border-radius: 2px;"></div>
              <span class="text-sm">50-100ms (Good)</span>
            </div>
            <div class="flex items-center gap-2">
              <div style="width: 16px; height: 16px; background: #fb6340; border-radius: 2px;"></div>
              <span class="text-sm">100-200ms (Fair)</span>
            </div>
            <div class="flex items-center gap-2">
              <div style="width: 16px; height: 16px; background: #f5365c; border-radius: 2px;"></div>
              <span class="text-sm">&gt;200ms (Poor)</span>
            </div>
          </div>
        </div>
      `;

            const container = document.querySelector('.cbi-section') || document.querySelector('#maincontent');
            if (container) {
                container.insertBefore(panel, container.firstChild);
            }

            this.setupCanvas();
        },

        // Setup canvas
        setupCanvas: function () {
            this.canvas = document.getElementById('latency-heatmap-canvas');
            if (!this.canvas) return;

            this.ctx = this.canvas.getContext('2d');

            // Make responsive
            const container = this.canvas.parentElement;
            this.canvas.width = container.offsetWidth;
            this.canvas.style.width = '100%';

            window.addEventListener('resize', () => this.handleResize());
        },

        // Create GeoIP map panel
        createGeoMapPanel: function () {
            const panel = document.createElement('div');
            panel.className = 'pw-card mb-4';
            panel.id = 'geoip-map-panel';
            panel.innerHTML = `
        <div class="pw-card-header">
          <h3 class="pw-card-title">🗺️ Geographic Distribution</h3>
          <div class="flex gap-2">
            <select id="map-filter" class="pw-select" style="width: auto;" onchange="PW2Heatmap.filterByRegion(this.value)">
              <option value="all">All Regions</option>
              <option value="asia">Asia</option>
              <option value="europe">Europe</option>
              <option value="americas">Americas</option>
              <option value="oceania">Oceania</option>
            </select>
          </div>
        </div>
        <div class="pw-card-body">
          <!-- World Map SVG -->
          <div id="world-map-container" style="position: relative; height: 400px; background: var(--bg-secondary); border-radius: var(--radius-lg); overflow: hidden;">
            <canvas id="world-map-canvas" width="800" height="400"></canvas>
            
            <!-- Node pins will be added dynamically -->
            <div id="map-pins"></div>
          </div>

          <!-- Region Stats -->
          <div class="pw-grid pw-grid-4 gap-3 mt-4" id="region-stats">
            <!-- Will be populated -->
          </div>
        </div>
      `;

            const heatmapPanel = document.getElementById('latency-heatmap-panel');
            if (heatmapPanel) {
                heatmapPanel.parentNode.insertBefore(panel, heatmapPanel.nextSibling);
            }

            this.drawWorldMap();
        },

        // Draw world map (simplified)
        drawWorldMap: function () {
            const canvas = document.getElementById('world-map-canvas');
            if (!canvas) return;

            const ctx = canvas.getContext('2d');
            const width = canvas.width;
            const height = canvas.height;

            // Make responsive
            canvas.width = canvas.parentElement.offsetWidth;
            canvas.style.width = '100%';

            // Draw simple continents (very simplified)
            ctx.fillStyle = getComputedStyle(document.documentElement)
                .getPropertyValue('--color-gray-300').trim() || '#dee2e6';

            // Asia (simplified polygon)
            ctx.beginPath();
            ctx.moveTo(width * 0.5, height * 0.2);
            ctx.lineTo(width * 0.8, height * 0.2);
            ctx.lineTo(width * 0.85, height * 0.5);
            ctx.lineTo(width * 0.7, height * 0.6);
            ctx.lineTo(width * 0.5, height * 0.5);
            ctx.closePath();
            ctx.fill();

            // Europe
            ctx.beginPath();
            ctx.moveTo(width * 0.4, height * 0.2);
            ctx.lineTo(width * 0.5, height * 0.2);
            ctx.lineTo(width * 0.5, height * 0.4);
            ctx.lineTo(width * 0.37, height * 0.45);
            ctx.closePath();
            ctx.fill();

            // Americas
            ctx.beginPath();
            ctx.moveTo(width * 0.15, height * 0.2);
            ctx.lineTo(width * 0.25, height * 0.2);
            ctx.lineTo(width * 0.25, height * 0.7);
            ctx.lineTo(width * 0.15, height * 0.7);
            ctx.closePath();
            ctx.fill();

            // Oceania
            ctx.beginPath();
            ctx.arc(width * 0.75, height * 0.7, 30, 0, 2 * Math.PI);
            ctx.fill();

            // Add node pins
            this.updateMapPins();
        },

        // Load nodes data
        loadNodes: function () {
            // Simulate node data (replace with real API call)
            this.nodes = this.generateSimulatedNodes(20);
            this.renderHeatmap();
            this.updateMapPins();
            this.updateRegionStats();
        },

        // Generate simulated nodes
        generateSimulatedNodes: function (count) {
            const regions = ['asia', 'europe', 'americas', 'oceania'];
            const countries = {
                asia: ['Japan', 'Singapore', 'Hong Kong', 'Korea'],
                europe: ['UK', 'Germany', 'France', 'Netherlands'],
                americas: ['USA', 'Canada', 'Brazil'],
                oceania: ['Australia', 'New Zealand']
            };

            const nodes = [];
            for (let i = 0; i < count; i++) {
                const region = regions[Math.floor(Math.random() * regions.length)];
                const countryList = countries[region];
                const country = countryList[Math.floor(Math.random() * countryList.length)];

                nodes.push({
                    id: i,
                    name: `${country}-${i + 1}`,
                    region,
                    country,
                    latency: Math.random() * 250 + 10,
                    x: Math.random() * 0.8 + 0.1, // 10-90% of width
                    y: Math.random() * 0.6 + 0.2, // 20-80% of height
                    history: this.generateLatencyHistory(24)
                });
            }

            return nodes;
        },

        // Generate latency history
        generateLatencyHistory: function (hours) {
            const history = [];
            for (let i = 0; i < hours; i++) {
                history.push({
                    timestamp: Date.now() - (hours - i) * 3600000,
                    latency: Math.random() * 150 + 20
                });
            }
            return history;
        },

        // Render heatmap
        renderHeatmap: function () {
            if (!this.ctx) return;

            const width = this.canvas.width;
            const height = this.canvas.height;
            const padding = 60;

            // Clear canvas
            this.ctx.clearRect(0, 0, width, height);

            // Background
            this.ctx.fillStyle = getComputedStyle(document.documentElement)
                .getPropertyValue('--bg-primary').trim() || '#ffffff';
            this.ctx.fillRect(0, 0, width, height);

            // Draw grid
            this.drawHeatmapGrid(padding, width - padding * 2, height - padding * 2);

            // Draw heatmap cells
            this.drawHeatmapCells(padding, width - padding * 2, height - padding * 2);

            // Draw axes
            this.drawHeatmapAxes(padding, width - padding * 2, height - padding * 2);
        },

        // Draw heatmap grid
        drawHeatmapGrid: function (padding, width, height) {
            const gridColor = getComputedStyle(document.documentElement)
                .getPropertyValue('--border-color').trim() || '#e9ecef';

            this.ctx.strokeStyle = gridColor;
            this.ctx.lineWidth = 1;

            // Horizontal lines
            for (let i = 0; i <= 10; i++) {
                const y = padding + (height / 10) * i;
                this.ctx.beginPath();
                this.ctx.moveTo(padding, y);
                this.ctx.lineTo(padding + width, y);
                this.ctx.stroke();
            }

            // Vertical lines (hours)
            for (let i = 0; i <= 24; i++) {
                const x = padding + (width / 24) * i;
                this.ctx.beginPath();
                this.ctx.moveTo(x, padding);
                this.ctx.lineTo(x, padding + height);
                this.ctx.stroke();
            }
        },

        // Draw heatmap cells
        drawHeatmapCells: function (padding, width, height) {
            const cellWidth = width / 24;
            const cellHeight = height / this.nodes.length;

            this.nodes.forEach((node, nodeIndex) => {
                node.history.slice(-24).forEach((point, hourIndex) => {
                    const x = padding + cellWidth * hourIndex;
                    const y = padding + cellHeight * nodeIndex;

                    // Color based on latency
                    this.ctx.fillStyle = this.getLatencyColor(point.latency);
                    this.ctx.fillRect(x, y, cellWidth - 1, cellHeight - 1);
                });

                // Draw node name
                this.ctx.fillStyle = getComputedStyle(document.documentElement)
                    .getPropertyValue('--text-primary').trim() || '#000000';
                this.ctx.font = '10px sans-serif';
                this.ctx.textAlign = 'right';
                this.ctx.fillText(node.name, padding - 5, y + cellHeight / 2 + 3);
            });
        },

        // Get color for latency value
        getLatencyColor: function (latency) {
            if (latency < 50) return '#2dce89'; // Excellent
            if (latency < 100) return '#11cdef'; // Good
            if (latency < 200) return '#fb6340'; // Fair
            return '#f5365c'; // Poor
        },

        // Draw heatmap axes
        drawHeatmapAxes: function (padding, width, height) {
            const textColor = getComputedStyle(document.documentElement)
                .getPropertyValue('--text-secondary').trim() || '#525f7f';

            this.ctx.fillStyle = textColor;
            this.ctx.font = '11px sans-serif';
            this.ctx.textAlign = 'center';

            // Hour labels
            for (let i = 0; i <= 24; i += 4) {
                const x = padding + (width / 24) * i;
                this.ctx.fillText(`${i}h`, x, padding + height + 20);
            }
        },

        // Update map pins
        updateMapPins: function () {
            const container = document.getElementById('map-pins');
            if (!container) return;

            const mapWidth = container.parentElement.offsetWidth;
            const mapHeight = 400;

            container.innerHTML = this.nodes.map(node => {
                const x = mapWidth * node.x;
                const y = mapHeight * node.y;
                const color = this.getLatencyColor(node.latency);

                return `
          <div class="map-pin" 
               style="position: absolute; left: ${x}px; top: ${y}px; transform: translate(-50%, -100%);"
               title="${node.name}: ${node.latency.toFixed(0)}ms"
               onclick="PW2Heatmap.showNodeDetails(${node.id})">
            <div style="
              width: 12px;
              height: 12px;
              background: ${color};
              border: 2px solid white;
              border-radius: 50%;
              box-shadow: 0 2px 4px rgba(0,0,0,0.2);
              cursor: pointer;
              animation: pin-pulse 2s ease-in-out infinite;
            "></div>
          </div>
        `;
            }).join('');

            // Add pin animation
            if (!document.getElementById('map-pin-styles')) {
                const style = document.createElement('style');
                style.id = 'map-pin-styles';
                style.textContent = `
          @keyframes pin-pulse {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.2); }
          }
          .map-pin:hover div {
            transform: scale(1.4) !important;
            animation: none;
          }
        `;
                document.head.appendChild(style);
            }
        },

        // Update region stats
        updateRegionStats: function () {
            const container = document.getElementById('region-stats');
            if (!container) return;

            const statsByRegion = {};
            this.nodes.forEach(node => {
                if (!statsByRegion[node.region]) {
                    statsByRegion[node.region] = { count: 0, totalLatency: 0 };
                }
                statsByRegion[node.region].count++;
                statsByRegion[node.region].totalLatency += node.latency;
            });

            const regionIcons = {
                asia: '🌏',
                europe: '🌍',
                americas: '🌎',
                oceania: '🏝️'
            };

            container.innerHTML = Object.entries(statsByRegion).map(([region, stats]) => {
                const avgLatency = stats.totalLatency / stats.count;
                const color = this.getLatencyColor(avgLatency);

                return `
          <div class="pw-card-compact text-center">
            <div style="font-size: 2em; margin-bottom: 0.5rem;">${regionIcons[region]}</div>
            <div class="text-sm font-semibold mb-1 capitalize">${region}</div>
            <div class="text-xs text-muted mb-2">${stats.count} nodes</div>
            <div class="font-semibold" style="color: ${color};">
              ${avgLatency.toFixed(0)}ms
            </div>
          </div>
        `;
            }).join('');
        },

        // Show node details
        showNodeDetails: function (nodeId) {
            const node = this.nodes.find(n => n.id === nodeId);
            if (!node) return;

            if (window.PW2Notify) {
                window.PW2Notify.info(`${node.name}: ${node.latency.toFixed(0)}ms (${node.region})`);
            }
        },

        // Filter by region
        filterByRegion: function (region) {
            this.selectedRegion = region === 'all' ? null : region;

            // Update map pins visibility
            const pins = document.querySelectorAll('.map-pin');
            pins.forEach((pin, index) => {
                const node = this.nodes[index];
                pin.style.display = (!this.selectedRegion || node.region === this.selectedRegion) ? 'block' : 'none';
            });

            if (window.PW2Notify) {
                window.PW2Notify.info(`Filtered to: ${region === 'all' ? 'All regions' : region}`);
            }
        },

        // Set view
        setView: function (view) {
            // Update button states
            document.querySelectorAll('#latency-heatmap-panel .pw-btn').forEach(btn => {
                const isActive = btn.textContent.trim() === view;
                btn.className = isActive ?
                    'pw-btn pw-btn-sm pw-btn-outline' :
                    'pw-btn pw-btn-sm pw-btn-ghost';
            });

            // Regenerate history based on view
            const hours = view === '24h' ? 24 : 168; // 7 days
            this.nodes.forEach(node => {
                node.history = this.generateLatencyHistory(hours);
            });

            this.renderHeatmap();

            if (window.PW2Notify) {
                window.PW2Notify.info(`Switched to ${view} view`);
            }
        },

        // Refresh
        refresh: function () {
            this.loadNodes();
            if (window.PW2Notify) {
                window.PW2Notify.success('Refreshed');
            }
        },

        // Start monitoring
        startMonitoring: function () {
            // Update latency every minute
            setInterval(() => {
                this.nodes.forEach(node => {
                    const newLatency = Math.random() * 150 + 20;
                    node.latency = newLatency;
                    node.history.push({
                        timestamp: Date.now(),
                        latency: newLatency
                    });
                    // Keep last 168 hours (7 days)
                    if (node.history.length > 168) {
                        node.history.shift();
                    }
                });

                this.renderHeatmap();
                this.updateMapPins();
                this.updateRegionStats();
            }, 60000); // Every minute
        },

        // Handle resize
        handleResize: function () {
            const container = this.canvas?.parentElement;
            if (container && this.canvas) {
                this.canvas.width = container.offsetWidth;
                this.renderHeatmap();
            }

            // Redraw map
            this.drawWorldMap();
        }
    };

    // Expose to global scope
    window.PW2Heatmap = LatencyHeatmap;

    // Auto-initialize when document is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => LatencyHeatmap.init());
    } else {
        LatencyHeatmap.init();
    }

    // Handle resize
    window.addEventListener('resize', () => LatencyHeatmap.handleResize());

})();

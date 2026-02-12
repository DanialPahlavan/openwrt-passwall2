/**
 * PassWall2 Smart Node Selection & Auto-Failover
 * Intelligent node selection based on multiple criteria
 */

(function () {
    'use strict';

    const SmartSelector = {
        nodes: [],
        currentNode: null,
        selectionStrategy: 'balanced', // balanced, fastest, most-reliable, load-balance
        failoverEnabled: true,
        healthCheckInterval: null,
        failoverHistory: [],

        // Initialize
        init: function () {
            this.createSelectionPanel();
            this.loadNodes();
            this.startHealthMonitoring();
            this.loadSettings();
        },

        // Create selection panel
        createSelectionPanel: function () {
            const panel = document.createElement('div');
            panel.className = 'pw-card mb-4';
            panel.id = 'smart-selector-panel';
            panel.innerHTML = `
        <div class="pw-card-header">
          <h3 class="pw-card-title">🧠 Smart Node Selection</h3>
          <button class="pw-btn pw-btn-sm pw-btn-primary" onclick="PW2SmartSelector.selectBestNode()">
            ✨ Select Best Node
          </button>
        </div>
        <div class="pw-card-body">
          <!-- Strategy Selection -->
          <div class="mb-4">
            <label class="text-sm font-medium mb-2 block">Selection Strategy</label>
            <div class="pw-grid pw-grid-4 gap-2">
              <button class="strategy-btn pw-btn pw-btn-outline active" data-strategy="balanced" onclick="PW2SmartSelector.setStrategy('balanced')">
                ⚖️ Balanced
              </button>
              <button class="strategy-btn pw-btn pw-btn-outline" data-strategy="fastest" onclick="PW2SmartSelector.setStrategy('fastest')">
                ⚡ Fastest
              </button>
              <button class="strategy-btn pw-btn pw-btn-outline" data-strategy="reliable" onclick="PW2SmartSelector.setStrategy('reliable')">
                🛡️ Most Reliable
              </button>
              <button class="strategy-btn pw-btn pw-btn-outline" data-strategy="load-balance" onclick="PW2SmartSelector.setStrategy('load-balance')">
                🔄 Load Balance
              </button>
            </div>
            <p class="text-xs text-muted mt-2" id="strategy-description">
              Balances latency, reliability, and load for optimal performance
            </p>
          </div>

          <!-- Criteria Weights -->
          <div class="mb-4">
            <h4 class="text-sm font-semibold mb-3">Selection Criteria Weights</h4>
            <div class="space-y-3">
              <div>
                <div class="flex justify-between text-sm mb-1">
                  <span>Latency</span>
                  <span id="weight-latency-value">40%</span>
                </div>
                <input type="range" id="weight-latency" class="w-full" min="0" max="100" value="40" 
                       oninput="PW2SmartSelector.updateWeight('latency', this.value)" />
              </div>
              <div>
                <div class="flex justify-between text-sm mb-1">
                  <span>Reliability</span>
                  <span id="weight-reliability-value">30%</span>
                </div>
                <input type="range" id="weight-reliability" class="w-full" min="0" max="100" value="30" 
                       oninput="PW2SmartSelector.updateWeight('reliability', this.value)" />
              </div>
              <div>
                <div class="flex justify-between text-sm mb-1">
                  <span>Load</span>
                  <span id="weight-load-value">20%</span>
                </div>
                <input type="range" id="weight-load" class="w-full" min="0" max="100" value="20" 
                       oninput="PW2SmartSelector.updateWeight('load', this.value)" />
              </div>
              <div>
                <div class="flex justify-between text-sm mb-1">
                  <span>Geographic Preference</span>
                  <span id="weight-geo-value">10%</span>
                </div>
                <input type="range" id="weight-geo" class="w-full" min="0" max="100" value="10" 
                       oninput="PW2SmartSelector.updateWeight('geo', this.value)" />
              </div>
            </div>
          </div>

          <!-- Auto-Failover Settings -->
          <div class="mb-4">
            <div class="flex items-center justify-between mb-3">
              <h4 class="text-sm font-semibold">Auto-Failover</h4>
              <label class="pw-toggle">
                <input type="checkbox" id="failover-enabled" checked onchange="PW2SmartSelector.toggleFailover(this.checked)" />
                <span class="pw-toggle-slider"></span>
              </label>
            </div>
            <div id="failover-settings">
              <div class="space-y-2 text-sm">
                <div class="flex items-center justify-between">
                  <span>Failure Threshold</span>
                  <select id="failure-threshold" class="pw-select" style="width: auto;" onchange="PW2SmartSelector.saveSettings()">
                    <option value="1">1 failure</option>
                    <option value="2">2 failures</option>
                    <option value="3" selected>3 failures</option>
                    <option value="5">5 failures</option>
                  </select>
                </div>
                <div class="flex items-center justify-between">
                  <span>Check Interval</span>
                  <select id="check-interval" class="pw-select" style="width: auto;" onchange="PW2SmartSelector.saveSettings()">
                    <option value="30">30 seconds</option>
                    <option value="60" selected>1 minute</option>
                    <option value="300">5 minutes</option>
                  </select>
                </div>
                <div class="flex items-center gap-2">
                  <input type="checkbox" id="notify-failover" checked onchange="PW2SmartSelector.saveSettings()" />
                  <label for="notify-failover" class="cursor-pointer">Notify on failover</label>
                </div>
              </div>
            </div>
          </div>

          <!-- Current Selection -->
          <div class="pw-divider"></div>
          <div id="current-selection" class="mt-4">
            <!-- Will be populated -->
          </div>

          <!-- Failover History -->
          <div class="mt-4" id="failover-history-section" style="display: none;">
            <h4 class="text-sm font-semibold mb-2">Recent Failovers</h4>
            <div id="failover-history-list">
              <!-- Will be populated -->
            </div>
          </div>
        </div>
      `;

            const container = document.querySelector('.cbi-section') || document.querySelector('#maincontent');
            if (container) {
                container.insertBefore(panel, container.firstChild);
            }

            this.updateCurrentSelection();
        },

        // Load nodes
        loadNodes: function () {
            // Simulate node data (replace with real API)
            this.nodes = this.generateSimulatedNodes(15);
            this.currentNode = this.nodes[0];
        },

        // Generate simulated nodes
        generateSimulatedNodes: function (count) {
            const regions = ['US-West', 'US-East', 'EU-West', 'Asia-East', 'Asia-SE'];
            const nodes = [];

            for (let i = 0; i < count; i++) {
                nodes.push({
                    id: i,
                    name: `${regions[i % regions.length]}-${Math.floor(i / regions.length) + 1}`,
                    region: regions[i % regions.length],
                    latency: Math.random() * 200 + 20,
                    uptime: Math.random() * 100,
                    reliability: Math.random() * 100,
                    load: Math.random() * 100,
                    failureCount: 0,
                    lastCheck: Date.now(),
                    status: 'online'
                });
            }

            return nodes;
        },

        // Set strategy
        setStrategy: function (strategy) {
            this.selectionStrategy = strategy;

            // Update button states
            document.querySelectorAll('.strategy-btn').forEach(btn => {
                btn.classList.toggle('active', btn.dataset.strategy === strategy);
            });

            // Update description
            const descriptions = {
                'balanced': 'Balances latency, reliability, and load for optimal performance',
                'fastest': 'Prioritizes lowest latency nodes for maximum speed',
                'reliable': 'Selects nodes with highest uptime and stability',
                'load-balance': '网Distributes traffic evenly across available nodes'
            };

            document.getElementById('strategy-description').textContent = descriptions[strategy];

            // Update weights based on strategy
            this.applyStrategyPresets(strategy);

            this.saveSettings();

            if (window.PW2Notify) {
                window.PW2Notify.success(`Strategy: ${strategy.replace('-', ' ')}`);
            }
        },

        // Apply strategy presets
        applyStrategyPresets: function (strategy) {
            const presets = {
                'balanced': { latency: 40, reliability: 30, load: 20, geo: 10 },
                'fastest': { latency: 70, reliability: 20, load: 5, geo: 5 },
                'reliable': { latency: 20, reliability: 60, load: 10, geo: 10 },
                'load-balance': { latency: 25, reliability: 25, load: 40, geo: 10 }
            };

            const weights = presets[strategy];
            Object.entries(weights).forEach(([key, value]) => {
                document.getElementById(`weight-${key}`).value = value;
                document.getElementById(`weight-${key}-value`).textContent = `${value}%`;
            });
        },

        // Update weight
        updateWeight: function (type, value) {
            document.getElementById(`weight-${type}-value`).textContent = `${value}%`;
            this.saveSettings();
        },

        // Select best node
        selectBestNode: function () {
            if (window.PW2Notify) {
                window.PW2Notify.info('Analyzing nodes...');
            }

            setTimeout(() => {
                const scores = this.calculateNodeScores();
                const bestNode = scores[0];

                this.currentNode = bestNode.node;
                this.updateCurrentSelection();

                if (window.PW2Notify) {
                    window.PW2Notify.success(`Selected: ${bestNode.node.name} (score: ${bestNode.score.toFixed(1)})`);
                }

                // Show top 5 candidates
                this.showCandidates(scores.slice(0, 5));
            }, 500);
        },

        // Calculate node scores
        calculateNodeScores: function () {
            const weights = {
                latency: parseInt(document.getElementById('weight-latency').value) / 100,
                reliability: parseInt(document.getElementById('weight-reliability').value) / 100,
                load: parseInt(document.getElementById('weight-load').value) / 100,
                geo: parseInt(document.getElementById('weight-geo').value) / 100
            };

            const scores = this.nodes
                .filter(node => node.status === 'online')
                .map(node => {
                    // Normalize values (0-100, higher is better)
                    const latencyScore = Math.max(0, 100 - (node.latency / 3));
                    const reliabilityScore = node.reliability;
                    const loadScore = Math.max(0, 100 - node.load);
                    const geoScore = 50; // Simplified geo preference

                    const score =
                        latencyScore * weights.latency +
                        reliabilityScore * weights.reliability +
                        loadScore * weights.load +
                        geoScore * weights.geo;

                    return { node, score };
                })
                .sort((a, b) => b.score - a.score);

            return scores;
        },

        // Show candidates
        showCandidates: function (candidates) {
            const container = document.getElementById('current-selection');
            if (!container) return;

            container.innerHTML = `
        <div class="pw-card-compact">
          <h4 class="text-sm font-semibold mb-3">Current Selection: ${this.currentNode.name}</h4>
          
          <div class="mb-3">
            <div class="flex justify-between text-sm mb-1">
              <span>Latency</span>
              <span class="font-semibold">${this.currentNode.latency.toFixed(0)}ms</span>
            </div>
            <div class="flex justify-between text-sm mb-1">
              <span>Reliability</span>
              <span class="font-semibold">${this.currentNode.reliability.toFixed(0)}%</span>
            </div>
            <div class="flex justify-between text-sm mb-1">
              <span>Load</span>
              <span class="font-semibold">${this.currentNode.load.toFixed(0)}%</span>
            </div>
          </div>

          <div class="pw-divider"></div>

          <h5 class="text-xs font-semibold text-muted mb-2 mt-3">Top Candidates</h5>
          <div class="space-y-1">
            ${candidates.map((candidate, index) => `
              <div class="flex items-center justify-between py-1 text-sm ${index === 0 ? 'font-semibold' : ''}">
                <span>${index + 1}. ${candidate.node.name}</span>
                <div class="flex items-center gap-2">
                  <span class="text-muted">${candidate.node.latency.toFixed(0)}ms</span>
                  <span class="pw-badge pw-badge-neutral text-xs">${candidate.score.toFixed(1)}</span>
                </div>
              </div>
            `).join('')}
          </div>
        </div>
      `;
        },

        // Update current selection
        updateCurrentSelection: function () {
            if (!this.currentNode) return;

            const container = document.getElementById('current-selection');
            if (!container) return;

            container.innerHTML = `
        <div class="pw-card-compact">
          <div class="flex items-center justify-between mb-3">
            <h4 class="text-sm font-semibold">Current Node</h4>
            <span class="pw-badge pw-badge-success">${this.currentNode.status}</span>
          </div>
          
          <div class="text-center mb-3">
            <div class="text-2xl font-bold">${this.currentNode.name}</div>
            <div class="text-sm text-muted">${this.currentNode.region}</div>
          </div>

          <div class="pw-grid pw-grid-3 gap-2">
            <div class="text-center p-2 bg-secondary rounded">
              <div class="text-xs text-muted">Latency</div>
              <div class="font-semibold">${this.currentNode.latency.toFixed(0)}ms</div>
            </div>
            <div class="text-center p-2 bg-secondary rounded">
              <div class="text-xs text-muted">Reliability</div>
              <div class="font-semibold">${this.currentNode.reliability.toFixed(0)}%</div>
            </div>
            <div class="text-center p-2 bg-secondary rounded">
              <div class="text-xs text-muted">Load</div>
              <div class="font-semibold">${this.currentNode.load.toFixed(0)}%</div>
            </div>
          </div>
        </div>
      `;
        },

        // Toggle failover
        toggleFailover: function (enabled) {
            this.failoverEnabled = enabled;
            document.getElementById('failover-settings').style.display = enabled ? 'block' : 'none';

            if (enabled) {
                this.startHealthMonitoring();
                if (window.PW2Notify) {
                    window.PW2Notify.success('Auto-failover enabled');
                }
            } else {
                this.stopHealthMonitoring();
                if (window.PW2Notify) {
                    window.PW2Notify.info('Auto-failover disabled');
                }
            }

            this.saveSettings();
        },

        // Start health monitoring
        startHealthMonitoring: function () {
            if (this.healthCheckInterval) return;

            const interval = parseInt(document.getElementById('check-interval')?.value || 60);

            this.healthCheckInterval = setInterval(() => {
                this.checkNodesHealth();
            }, interval * 1000);
        },

        // Stop health monitoring
        stopHealthMonitoring: function () {
            if (this.healthCheckInterval) {
                clearInterval(this.healthCheckInterval);
                this.healthCheckInterval = null;
            }
        },

        // Check nodes health
        checkNodesHealth: function () {
            this.nodes.forEach(node => {
                // Simulate health check (replace with real API)
                const isHealthy = Math.random() > 0.05; // 95% success rate

                if (!isHealthy) {
                    node.failureCount++;

                    const threshold = parseInt(document.getElementById('failure-threshold')?.value || 3);
                    if (node.failureCount >= threshold && node.id === this.currentNode.id) {
                        this.performFailover(node);
                    }
                } else {
                    node.failureCount = Math.max(0, node.failureCount - 1);
                }

                node.lastCheck = Date.now();
            });
        },

        // Perform failover
        performFailover: function (failedNode) {
            const scores = this.calculateNodeScores();
            const newNode = scores[0].node;

            if (newNode.id === failedNode.id) {
                // No better alternative
                if (window.PW2Notify) {
                    window.PW2Notify.error('No healthy alternative nodes available');
                }
                return;
            }

            // Record failover
            this.failoverHistory.unshift({
                timestamp: Date.now(),
                from: failedNode.name,
                to: newNode.name,
                reason: `${failedNode.failureCount} consecutive failures`
            });

            // Keep last 10
            if (this.failoverHistory.length > 10) {
                this.failoverHistory.pop();
            }

            this.currentNode = newNode;
            failedNode.status = 'offline';

            this.updateCurrentSelection();
            this.updateFailoverHistory();

            if (document.getElementById('notify-failover')?.checked) {
                if (window.PW2Notify) {
                    window.PW2Notify.warning(`Failover: ${failedNode.name} → ${newNode.name}`);
                }
            }
        },

        // Update failover history
        updateFailoverHistory: function () {
            const section = document.getElementById('failover-history-section');
            const list = document.getElementById('failover-history-list');

            if (!section || !list) return;

            if (this.failoverHistory.length === 0) {
                section.style.display = 'none';
                return;
            }

            section.style.display = 'block';
            list.innerHTML = this.failoverHistory.map(entry => {
                const time = new Date(entry.timestamp).toLocaleTimeString();
                return `
          <div class="flex items-center justify-between py-1 text-sm border-bottom">
            <div>
              <span class="font-mono">${entry.from}</span>
              <span class="text-muted mx-1">→</span>
              <span class="font-mono">${entry.to}</span>
            </div>
            <span class="text-xs text-muted">${time}</span>
          </div>
        `;
            }).join('');
        },

        // Save settings
        saveSettings: function () {
            const settings = {
                strategy: this.selectionStrategy,
                failoverEnabled: this.failoverEnabled,
                weights: {
                    latency: parseInt(document.getElementById('weight-latency').value),
                    reliability: parseInt(document.getElementById('weight-reliability').value),
                    load: parseInt(document.getElementById('weight-load').value),
                    geo: parseInt(document.getElementById('weight-geo').value)
                },
                failureThreshold: parseInt(document.getElementById('failure-threshold')?.value || 3),
                checkInterval: parseInt(document.getElementById('check-interval')?.value || 60),
                notifyFailover: document.getElementById('notify-failover')?.checked
            };

            localStorage.setItem('pw2-smart-selector-settings', JSON.stringify(settings));
        },

        // Load settings
        loadSettings: function () {
            try {
                const settings = JSON.parse(localStorage.getItem('pw2-smart-selector-settings'));
                if (settings) {
                    this.setStrategy(settings.strategy);
                    this.failoverEnabled = settings.failoverEnabled;
                    // Apply other settings...
                }
            } catch (e) {
                console.error('Failed to load settings:', e);
            }
        }
    };

    // Expose to global scope
    window.PW2SmartSelector = SmartSelector;

    // Auto-initialize when document is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => SmartSelector.init());
    } else {
        SmartSelector.init();
    }

    // Cleanup on page unload
    window.addEventListener('beforeunload', () => {
        SmartSelector.stopHealthMonitoring();
    });

})();

/**
 * PassWall2 Network Diagnostics Tools
 * Advanced ping, traceroute, DNS lookup, connection analysis
 */

(function () {
    'use strict';

    const NetworkDiagnostics = {
        activeTests: new Map(),
        testHistory: [],

        // Initialize
        init: function () {
            this.createDiagnosticsPanel();
            this.attachEventListeners();
        },

        // Create diagnostics panel
        createDiagnosticsPanel: function () {
            const panel = document.createElement('div');
            panel.className = 'pw-card mb-4';
            panel.id = 'network-diagnostics-panel';
            panel.innerHTML = `
        <div class="pw-card-header">
          <h3 class="pw-card-title">🔍 Network Diagnostics</h3>
        </div>
        <div class="pw-card-body">
          <!-- Tool Selection -->
          <div class="flex gap-2 mb-4">
            <button class="pw-btn pw-btn-outline diagnostic-tool-btn active" data-tool="ping" onclick="PW2Diagnostics.selectTool('ping')">
              📡 Ping
            </button>
            <button class="pw-btn pw-btn-outline diagnostic-tool-btn" data-tool="traceroute" onclick="PW2Diagnostics.selectTool('traceroute')">
              🗺️ Traceroute
            </button>
            <button class="pw-btn pw-btn-outline diagnostic-tool-btn" data-tool="dns" onclick="PW2Diagnostics.selectTool('dns')">
              🌐 DNS Lookup
            </button>
            <button class="pw-btn pw-btn-outline diagnostic-tool-btn" data-tool="port" onclick="PW2Diagnostics.selectTool('port')">
              🔌 Port Scan
            </button>
            <button class="pw-btn pw-btn-outline diagnostic-tool-btn" data-tool="speed" onclick="PW2Diagnostics.selectTool('speed')">
              ⚡ Speed Test
            </button>
          </div>

          <!-- Ping Tool -->
          <div id="tool-ping" class="diagnostic-tool">
            <div class="mb-4">
              <label class="text-sm font-medium mb-2 block">Target Host</label>
              <div class="flex gap-2">
                <input type="text" id="ping-target" class="pw-input flex-1" placeholder="google.com or 8.8.8.8" value="8.8.8.8" />
                <input type="number" id="ping-count" class="pw-input" style="width: 100px;" placeholder="Count" value="4" min="1" max="100" />
                <button class="pw-btn pw-btn-primary" onclick="PW2Diagnostics.runPing()">Run Ping</button>
              </div>
            </div>
          </div>

          <!-- Traceroute Tool -->
          <div id="tool-traceroute" class="diagnostic-tool" style="display: none;">
            <div class="mb-4">
              <label class="text-sm font-medium mb-2 block">Target Host</label>
              <div class="flex gap-2">
                <input type="text" id="traceroute-target" class="pw-input flex-1" placeholder="google.com" value="google.com" />
                <input type="number" id="traceroute-max-hops" class="pw-input" style="width: 120px;" placeholder="Max hops" value="30" min="1" max="64" />
                <button class="pw-btn pw-btn-primary" onclick="PW2Diagnostics.runTraceroute()">Run Traceroute</button>
              </div>
            </div>
          </div>

          <!-- DNS Tool -->
          <div id="tool-dns" class="diagnostic-tool" style="display: none;">
            <div class="mb-4">
              <label class="text-sm font-medium mb-2 block">Domain Name</label>
              <div class="flex gap-2">
                <input type="text" id="dns-domain" class="pw-input flex-1" placeholder="example.com" value="google.com" />
                <select id="dns-type" class="pw-select" style="width: 120px;">
                  <option value="A">A (IPv4)</option>
                  <option value="AAAA">AAAA (IPv6)</option>
                  <option value="MX">MX (Mail)</option>
                  <option value="TXT">TXT</option>
                  <option value="NS">NS</option>
                  <option value="CNAME">CNAME</option>
                </select>
                <button class="pw-btn pw-btn-primary" onclick="PW2Diagnostics.runDNS()">Lookup</button>
              </div>
            </div>
          </div>

          <!-- Port Scan Tool -->
          <div id="tool-port" class="diagnostic-tool" style="display: none;">
            <div class="mb-4">
              <label class="text-sm font-medium mb-2 block">Target & Ports</label>
              <div class="flex gap-2">
                <input type="text" id="port-target" class="pw-input flex-1" placeholder="192.168.1.1" />
                <input type="text" id="port-range" class="pw-input" style="width: 150px;" placeholder="80,443,8080" value="80,443" />
                <button class="pw-btn pw-btn-primary" onclick="PW2Diagnostics.runPortScan()">Scan Ports</button>
              </div>
              <p class="text-xs text-muted mt-2">⚠️ Only scan hosts you own or have permission to test</p>
            </div>
          </div>

          <!-- Speed Test Tool -->
          <div id="tool-speed" class="diagnostic-tool" style="display: none;">
            <div class="mb-4">
              <div class="text-center">
                <button class="pw-btn pw-btn-primary pw-btn-lg" onclick="PW2Diagnostics.runSpeedTest()">
                  ⚡ Start Speed Test
                </button>
                <p class="text-sm text-muted mt-2">Test your connection speed (download/upload)</p>
              </div>
            </div>
          </div>

          <!-- Results Area -->
          <div class="pw-divider"></div>
          <div id="diagnostic-results" class="mt-4">
            <div class="pw-empty-state">
              <div class="pw-empty-state-icon">🔍</div>
              <div class="pw-empty-state-description">
                Select a tool and run a diagnostic test
              </div>
            </div>
          </div>
        </div>
      `;

            const container = document.querySelector('.cbi-section') || document.querySelector('#maincontent');
            if (container) {
                container.insertBefore(panel, container.firstChild);
            }
        },

        // Select diagnostic tool
        selectTool: function (tool) {
            // Update button states
            document.querySelectorAll('.diagnostic-tool-btn').forEach(btn => {
                btn.classList.toggle('active', btn.dataset.tool === tool);
            });

            // Show/hide tool panels
            document.querySelectorAll('.diagnostic-tool').forEach(panel => {
                panel.style.display = panel.id === `tool-${tool}` ? 'block' : 'none';
            });
        },

        // Run ping test
        runPing: async function () {
            const target = document.getElementById('ping-target').value.trim();
            const count = parseInt(document.getElementById('ping-count').value) || 4;

            if (!target) {
                this.showError('Please enter a target host');
                return;
            }

            this.showProgress('Running ping test...');

            try {
                // Simulate ping test (replace with real API call)
                const results = await this.simulatePing(target, count);
                this.displayPingResults(results);
            } catch (error) {
                this.showError('Ping test failed: ' + error.message);
            }
        },

        // Simulate ping test
        simulatePing: async function (target, count) {
            return new Promise((resolve) => {
                setTimeout(() => {
                    const packets = [];
                    let totalTime = 0;

                    for (let i = 0; i < count; i++) {
                        const time = Math.random() * 100 + 10; // 10-110ms
                        const ttl = 64;
                        const lost = Math.random() > 0.95; // 5% packet loss

                        packets.push({
                            seq: i + 1,
                            time: lost ? null : time.toFixed(2),
                            ttl,
                            lost
                        });

                        if (!lost) totalTime += time;
                    }

                    const received = packets.filter(p => !p.lost).length;
                    const lossRate = ((count - received) / count * 100).toFixed(1);
                    const avgTime = received > 0 ? (totalTime / received).toFixed(2) : 0;

                    resolve({
                        target,
                        packets,
                        transmitted: count,
                        received,
                        lossRate,
                        avgTime,
                        minTime: Math.min(...packets.filter(p => !p.lost).map(p => parseFloat(p.time))).toFixed(2),
                        maxTime: Math.max(...packets.filter(p => !p.lost).map(p => parseFloat(p.time))).toFixed(2)
                    });
                }, 1500);
            });
        },

        // Display ping results
        displayPingResults: function (results) {
            const resultsDiv = document.getElementById('diagnostic-results');
            resultsDiv.innerHTML = `
        <div class="pw-card-compact">
          <h4 class="font-semibold mb-3">Ping Results: ${results.target}</h4>
          
          <!-- Packet List -->
          <div class="mb-4" style="max-height: 200px; overflow-y: auto;">
            ${results.packets.map(packet => `
              <div class="flex items-center justify-between py-1 text-sm ${packet.lost ? 'text-muted' : ''}">
                <span>Sequence ${packet.seq}</span>
                ${packet.lost ?
                    '<span class="pw-badge pw-badge-error">Lost</span>' :
                    `<span>${packet.time}ms (TTL=${packet.ttl})</span>`
                }
              </div>
            `).join('')}
          </div>

          <!-- Statistics -->
          <div class="pw-grid pw-grid-4 gap-2">
            <div class="text-center p-3 bg-secondary rounded">
              <div class="text-xs text-muted">Transmitted</div>
              <div class="font-semibold">${results.transmitted}</div>
            </div>
            <div class="text-center p-3 bg-secondary rounded">
              <div class="text-xs text-muted">Received</div>
              <div class="font-semibold text-success">${results.received}</div>
            </div>
            <div class="text-center p-3 bg-secondary rounded">
              <div class="text-xs text-muted">Loss Rate</div>
              <div class="font-semibold ${parseFloat(results.lossRate) > 10 ? 'text-error' : ''}">${results.lossRate}%</div>
            </div>
            <div class="text-center p-3 bg-secondary rounded">
              <div class="text-xs text-muted">Avg Time</div>
              <div class="font-semibold">${results.avgTime}ms</div>
            </div>
          </div>

          <div class="mt-3 text-sm text-muted">
            Min: ${results.minTime}ms • Max: ${results.maxTime}ms • Avg: ${results.avgTime}ms
          </div>
        </div>
      `;

            this.addToHistory('ping', results.target, 'success');
        },

        // Run traceroute
        runTraceroute: async function () {
            const target = document.getElementById('traceroute-target').value.trim();
            const maxHops = parseInt(document.getElementById('traceroute-max-hops').value) || 30;

            if (!target) {
                this.showError('Please enter a target host');
                return;
            }

            this.showProgress('Running traceroute...');

            try {
                const results = await this.simulateTraceroute(target, maxHops);
                this.displayTracerouteResults(results);
            } catch (error) {
                this.showError('Traceroute failed: ' + error.message);
            }
        },

        // Simulate traceroute
        simulateTraceroute: async function (target, maxHops) {
            return new Promise((resolve) => {
                setTimeout(() => {
                    const hops = [];
                    const hopCount = Math.min(Math.floor(Math.random() * 15) + 5, maxHops);

                    for (let i = 1; i <= hopCount; i++) {
                        hops.push({
                            hop: i,
                            ip: `${Math.floor(Math.random() * 255)}.${Math.floor(Math.random() * 255)}.${Math.floor(Math.random() * 255)}.${Math.floor(Math.random() * 255)}`,
                            hostname: i === hopCount ? target : `hop${i}.example.net`,
                            time1: (Math.random() * 50 + i * 5).toFixed(2),
                            time2: (Math.random() * 50 + i * 5).toFixed(2),
                            time3: (Math.random() * 50 + i * 5).toFixed(2)
                        });
                    }

                    resolve({ target, hops });
                }, 2000);
            });
        },

        // Display traceroute results
        displayTracerouteResults: function (results) {
            const resultsDiv = document.getElementById('diagnostic-results');
            resultsDiv.innerHTML = `
        <div class="pw-card-compact">
          <h4 class="font-semibold mb-3">Traceroute to ${results.target}</h4>
          
          <div style="max-height: 400px; overflow-y: auto;">
            <table class="w-full text-sm">
              <thead>
                <tr class="border-bottom">
                  <th class="text-left py-2">Hop</th>
                  <th class="text-left py-2">IP Address</th>
                  <th class="text-left py-2">Hostname</th>
                  <th class="text-right py-2">Time (ms)</th>
                </tr>
              </thead>
              <tbody>
                ${results.hops.map(hop => `
                  <tr class="border-bottom">
                    <td class="py-2">${hop.hop}</td>
                    <td class="py-2 font-mono">${hop.ip}</td>
                    <td class="py-2 text-muted">${hop.hostname}</td>
                    <td class="py-2 text-right">${hop.time1} / ${hop.time2} / ${hop.time3}</td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>

          <div class="mt-3 text-sm text-muted">
            Total hops: ${results.hops.length}
          </div>
        </div>
      `;

            this.addToHistory('traceroute', results.target, 'success');
        },

        // Run DNS lookup
        runDNS: async function () {
            const domain = document.getElementById('dns-domain').value.trim();
            const type = document.getElementById('dns-type').value;

            if (!domain) {
                this.showError('Please enter a domain name');
                return;
            }

            this.showProgress('Looking up DNS records...');

            try {
                const results = await this.simulateDNS(domain, type);
                this.displayDNSResults(results);
            } catch (error) {
                this.showError('DNS lookup failed: ' + error.message);
            }
        },

        // Simulate DNS lookup
        simulateDNS: async function (domain, type) {
            return new Promise((resolve) => {
                setTimeout(() => {
                    const records = [];

                    switch (type) {
                        case 'A':
                            records.push({ value: '142.250.185.' + Math.floor(Math.random() * 255), ttl: 300 });
                            break;
                        case 'AAAA':
                            records.push({ value: '2607:f8b0:4004:c07::' + Math.floor(Math.random() * 99), ttl: 300 });
                            break;
                        case 'MX':
                            records.push({ value: 'mail.example.com', priority: 10, ttl: 3600 });
                            records.push({ value: 'mail2.example.com', priority: 20, ttl: 3600 });
                            break;
                        case 'NS':
                            records.push({ value: 'ns1.example.com', ttl: 86400 });
                            records.push({ value: 'ns2.example.com', ttl: 86400 });
                            break;
                        default:
                            records.push({ value: 'Record data here', ttl: 3600 });
                    }

                    resolve({ domain, type, records });
                }, 800);
            });
        },

        // Display DNS results
        displayDNSResults: function (results) {
            const resultsDiv = document.getElementById('diagnostic-results');
            resultsDiv.innerHTML = `
        <div class="pw-card-compact">
          <h4 class="font-semibold mb-3">DNS Lookup: ${results.domain} (${results.type})</h4>
          
          <div class="space-y-2">
            ${results.records.map(record => `
              <div class="p-3 bg-secondary rounded">
                <div class="font-mono text-sm mb-1">${record.value}</div>
                ${record.priority ? `<div class="text-xs text-muted">Priority: ${record.priority}</div>` : ''}
                <div class="text-xs text-muted">TTL: ${record.ttl}s</div>
              </div>
            `).join('')}
          </div>

          <div class="mt-3 text-sm text-muted">
            Found ${results.records.length} record(s)
          </div>
        </div>
      `;

            this.addToHistory('dns', results.domain, 'success');
        },

        // Run port scan
        runPortScan: async function () {
            const target = document.getElementById('port-target').value.trim();
            const portsInput = document.getElementById('port-range').value.trim();

            if (!target || !portsInput) {
                this.showError('Please enter target and ports');
                return;
            }

            const ports = portsInput.split(',').map(p => parseInt(p.trim())).filter(p => !isNaN(p));

            this.showProgress('Scanning ports...');

            try {
                const results = await this.simulatePortScan(target, ports);
                this.displayPortScanResults(results);
            } catch (error) {
                this.showError('Port scan failed: ' + error.message);
            }
        },

        // Simulate port scan
        simulatePortScan: async function (target, ports) {
            return new Promise((resolve) => {
                setTimeout(() => {
                    const results = ports.map(port => ({
                        port,
                        open: Math.random() > 0.7,
                        service: this.getServiceName(port)
                    }));

                    resolve({ target, results });
                }, 1500);
            });
        },

        // Get service name for port
        getServiceName: function (port) {
            const services = {
                21: 'FTP', 22: 'SSH', 23: 'Telnet', 25: 'SMTP',
                53: 'DNS', 80: 'HTTP', 110: 'POP3', 143: 'IMAP',
                443: 'HTTPS', 3306: 'MySQL', 3389: 'RDP', 5432: 'PostgreSQL',
                8080: 'HTTP-Alt', 8443: 'HTTPS-Alt'
            };
            return services[port] || 'Unknown';
        },

        // Display port scan results
        displayPortScanResults: function (results) {
            const resultsDiv = document.getElementById('diagnostic-results');
            const openPorts = results.results.filter(r => r.open);

            resultsDiv.innerHTML = `
        <div class="pw-card-compact">
          <h4 class="font-semibold mb-3">Port Scan: ${results.target}</h4>
          
          <div class="mb-4">
            ${results.results.map(r => `
              <div class="flex items-center justify-between py-2 border-bottom">
                <div class="flex items-center gap-2">
                  <span class="font-mono">${r.port}</span>
                  <span class="text-muted text-sm">${r.service}</span>
                </div>
                <span class="pw-badge ${r.open ? 'pw-badge-success' : 'pw-badge-neutral'}">
                  ${r.open ? 'Open' : 'Closed'}
                </span>
              </div>
            `).join('')}
          </div>

          <div class="text-sm text-muted">
            ${openPorts.length} of ${results.results.length} ports open
          </div>
        </div>
      `;

            this.addToHistory('port-scan', results.target, 'success');
        },

        // Run speed test
        runSpeedTest: async function () {
            this.showProgress('Running speed test...');

            try {
                const results = await this.simulateSpeedTest();
                this.displaySpeedTestResults(results);
            } catch (error) {
                this.showError('Speed test failed: ' + error.message);
            }
        },

        // Simulate speed test
        simulateSpeedTest: async function () {
            return new Promise((resolve) => {
                let progress = 0;
                const interval = setInterval(() => {
                    progress += 10;
                    this.showProgress(`Running speed test... ${progress}%`);

                    if (progress >= 100) {
                        clearInterval(interval);
                        resolve({
                            downloadSpeed: (Math.random() * 100 + 50).toFixed(2), // Mbps
                            uploadSpeed: (Math.random() * 50 + 10).toFixed(2),
                            ping: (Math.random() * 50 + 10).toFixed(0),
                            jitter: (Math.random() * 5).toFixed(1)
                        });
                    }
                }, 200);
            });
        },

        // Display speed test results
        displaySpeedTestResults: function (results) {
            const resultsDiv = document.getElementById('diagnostic-results');
            resultsDiv.innerHTML = `
        <div class="pw-card-compact">
          <h4 class="font-semibold mb-3 text-center">Speed Test Results</h4>
          
          <div class="pw-grid pw-grid-2 gap-4 mb-4">
            <div class="text-center p-4 bg-secondary rounded">
              <div class="text-xs text-muted mb-2">Download</div>
              <div class="text-3xl font-bold text-success">${results.downloadSpeed}</div>
              <div class="text-sm text-muted">Mbps</div>
            </div>
            <div class="text-center p-4 bg-secondary rounded">
              <div class="text-xs text-muted mb-2">Upload</div>
              <div class="text-3xl font-bold text-info">${results.uploadSpeed}</div>
              <div class="text-sm text-muted">Mbps</div>
            </div>
          </div>

          <div class="pw-grid pw-grid-2 gap-4">
            <div class="text-center p-3 bg-secondary rounded">
              <div class="text-xs text-muted">Ping</div>
              <div class="font-semibold">${results.ping} ms</div>
            </div>
            <div class="text-center p-3 bg-secondary rounded">
              <div class="text-xs text-muted">Jitter</div>
              <div class="font-semibold">${results.jitter} ms</div>
            </div>
          </div>
        </div>
      `;

            this.addToHistory('speed-test', 'Speed Test', 'success');
        },

        // Show progress
        showProgress: function (message) {
            const resultsDiv = document.getElementById('diagnostic-results');
            resultsDiv.innerHTML = `
        <div class="text-center py-8">
          <div class="pw-spinner pw-spinner-lg mb-3" style="margin: 0 auto;"></div>
          <div class="text-muted">${message}</div>
        </div>
      `;
        },

        // Show error
        showError: function (message) {
            const resultsDiv = document.getElementById('diagnostic-results');
            resultsDiv.innerHTML = `
        <div class="pw-alert pw-alert-error">
          <div class="pw-alert-content">
            <div class="pw-alert-title">Error</div>
            <div class="pw-alert-description">${message}</div>
          </div>
        </div>
      `;
        },

        // Add to history
        addToHistory: function (tool, target, status) {
            this.testHistory.push({
                tool,
                target,
                status,
                timestamp: new Date().toISOString()
            });

            // Keep last 20
            if (this.testHistory.length > 20) {
                this.testHistory.shift();
            }
        },

        // Attach event listeners
        attachEventListeners: function () {
            // Enter key support for inputs
            ['ping-target', 'traceroute-target', 'dns-domain', 'port-target'].forEach(id => {
                const input = document.getElementById(id);
                if (input) {
                    input.addEventListener('keypress', (e) => {
                        if (e.key === 'Enter') {
                            const tool = id.split('-')[0];
                            this[`run${tool.charAt(0).toUpperCase() + tool.slice(1)}`]();
                        }
                    });
                }
            });
        }
    };

    // Expose to global scope
    window.PW2Diagnostics = NetworkDiagnostics;

    // Auto-initialize when document is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => NetworkDiagnostics.init());
    } else {
        NetworkDiagnostics.init();
    }

})();

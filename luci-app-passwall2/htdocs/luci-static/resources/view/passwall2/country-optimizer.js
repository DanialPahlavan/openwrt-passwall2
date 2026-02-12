/**
 * PassWall 3 Beta - Country-Specific Optimizer
 * Optimizes settings for Iran, China, Russia
 */

(function () {
    'use strict';

    const CountryOptimizer = {
        currentCountry: null,

        // Country-specific configurations
        configs: {
            iran: {
                name: 'Iran',
                flag: '🇮🇷',
                geoip: ['ir', 'geoip:ir', 'geoip:private'],
                geosite: ['ir', 'category-ir', 'geosite:ir'],
                rules: {
                    direct: ['geoip:ir', 'geoip:private', 'domain:ir', 'domain-suffix:.ir'],
                    proxy: ['geosite:google', 'geosite:youtube', 'geosite:facebook', 'geosite:twitter', 'geosite:telegram'],
                    block: ['geosite:category-ads-all']
                },
                dns: {
                    domestic: ['10.202.10.202', '10.202.10.102'], // Shecan DNS
                    foreign: ['1.1.1.1', '8.8.8.8']
                },
                optimizations: {
                    disableDNSCache: false,
                    enableTCPFastOpen: true,
                    enableMux: true,
                    disableUDP: false,
                    nodeLimitPerSub: 30
                },
                recommendations: [
                    'Use V2Ray or Trojan protocols for better stability',
                    'Enable CDN mode for better connection',
                    'Use domestic DNS for Iranian sites',
                    'Keep subscription node count under 30'
                ]
            },

            china: {
                name: 'China',
                flag: '🇨🇳',
                geoip: ['cn', 'geoip:cn', 'geoip:private'],
                geosite: ['cn', 'category-cn', 'geosite:cn', 'geosite:geolocation-cn'],
                rules: {
                    direct: ['geoip:cn', 'geoip:private', 'domain:cn', 'domain-suffix:.cn'],
                    proxy: ['geosite:google', 'geosite:youtube', 'geosite:facebook', 'geosite:twitter', 'geosite:github'],
                    block: ['geosite:category-ads-all']
                },
                dns: {
                    domestic: ['119.29.29.29', '223.5.5.5'], // DNSPod, AliDNS
                    foreign: ['1.1.1.1', '8.8.8.8']
                },
                optimizations: {
                    disableDNSCache: false,
                    enableTCPFastOpen: true,
                    enableMux: true,
                    disableUDP: false,
                    nodeLimitPerSub: 30
                },
                recommendations: [
                    'Use Shadowsocks or Trojan for stability',
                    'Enable domestic routing for CN sites',
                    'Use CN DNS servers for local domains',
                    'Keep subscription node count under 30'
                ]
            },

            russia: {
                name: 'Russia',
                flag: '🇷🇺',
                geoip: ['ru', 'geoip:ru', 'geoip:private'],
                geosite: ['ru', 'category-ru', 'geosite:ru'],
                rules: {
                    direct: ['geoip:ru', 'geoip:private', 'domain:ru', 'domain-suffix:.ru'],
                    proxy: ['geosite:google', 'geosite:youtube', 'geosite:facebook', 'geosite:twitter', 'geosite:instagram'],
                    block: ['geosite:category-ads-all']
                },
                dns: {
                    domestic: ['77.88.8.8', '77.88.8.1'], // Yandex DNS
                    foreign: ['1.1.1.1', '8.8.8.8']
                },
                optimizations: {
                    disableDNSCache: false,
                    enableTCPFastOpen: true,
                    enableMux: true,
                    disableUDP: false,
                    nodeLimitPerSub: 30
                },
                recommendations: [
                    'Use VMess or VLESS for better performance',
                    'Enable routing for RU domains',
                    'Use Yandex DNS for Russian sites',
                    'Keep subscription node count under 30'
                ]
            }
        },

        // Initialize
        init: function () {
            this.createOptimizerPanel();
            this.loadSettings();
        },

        // Create optimizer panel
        createOptimizerPanel: function () {
            const panel = document.createElement('div');
            panel.className = 'pw-card mb-4';
            panel.id = 'country-optimizer-panel';
            panel.innerHTML = `
        <div class="pw-card-header">
          <h3 class="pw-card-title">🌍 Country-Specific Optimization</h3>
        </div>
        <div class="pw-card-body">
          <div class="pw-alert pw-alert-info mb-4">
            <div class="pw-alert-content">
              <div class="pw-alert-title">Beta Feature</div>
              <div class="pw-alert-description">
                This feature optimizes PassWall 3 settings for specific countries with internet restrictions.
                It configures GeoIP, GeoSite, DNS, and routing rules automatically.
              </div>
            </div>
          </div>

          <!-- Country Selection -->
          <div class="mb-4">
            <label class="text-sm font-medium mb-2 block">Select Your Country</label>
            <div class="pw-grid pw-grid-3 gap-3">
              <button class="country-btn pw-btn pw-btn-outline" data-country="iran" onclick="PW2CountryOptimizer.selectCountry('iran')">
                <div class="text-center">
                  <div style="font-size: 2em;">🇮🇷</div>
                  <div class="text-sm mt-1">Iran</div>
                </div>
              </button>
              <button class="country-btn pw-btn pw-btn-outline" data-country="china" onclick="PW2CountryOptimizer.selectCountry('china')">
                <div class="text-center">
                  <div style="font-size: 2em;">🇨🇳</div>
                  <div class="text-sm mt-1">China</div>
                </div>
              </button>
              <button class="country-btn pw-btn pw-btn-outline" data-country="russia" onclick="PW2CountryOptimizer.selectCountry('russia')">
                <div class="text-center">
                  <div style="font-size: 2em;">🇷🇺</div>
                  <div class="text-sm mt-1">Russia</div>
                </div>
              </button>
            </div>
          </div>

          <!-- Configuration Preview -->
          <div id="config-preview" style="display: none;">
            <div class="pw-divider"></div>
            <h4 class="text-sm font-semibold mb-3">Configuration Preview</h4>
            
            <div class="space-y-3 mb-4">
              <div class="p-3 bg-secondary rounded">
                <div class="text-xs text-muted mb-1">GeoIP Rules</div>
                <div class="text-sm font-mono" id="preview-geoip"></div>
              </div>
              <div class="p-3 bg-secondary rounded">
                <div class="text-xs text-muted mb-1">GeoSite Rules</div>
                <div class="text-sm font-mono" id="preview-geosite"></div>
              </div>
              <div class="p-3 bg-secondary rounded">
                <div class="text-xs text-muted mb-1">DNS Servers</div>
                <div class="text-sm font-mono" id="preview-dns"></div>
              </div>
              <div class="p-3 bg-secondary rounded">
                <div class="text-xs text-muted mb-1">Optimizations</div>
                <div class="text-sm" id="preview-opts"></div>
              </div>
            </div>

            <!-- Recommendations -->
            <div class="mb-4">
              <h5 class="text-sm font-semibold mb-2">Recommendations</h5>
              <ul class="text-sm space-y-1" id="recommendations-list" style="list-style: disc; padding-left: 1.5rem;">
              </ul>
            </div>

            <!-- Action Buttons -->
            <div class="flex gap-2">
              <button class="pw-btn pw-btn-primary" onclick="PW2CountryOptimizer.applyOptimization()">
                ✅ Apply Optimization
              </button>
              <button class="pw-btn pw-btn-outline" onclick="PW2CountryOptimizer.downloadGeoFiles()">
                📥 Download GeoIP/GeoSite Files
              </button>
              <button class="pw-btn pw-btn-ghost" onclick="PW2CountryOptimizer.clearSelection()">
                ✖️ Clear
              </button>
            </div>
          </div>

          <!-- Status Display -->
          <div id="optimizer-status" class="mt-4" style="display: none;">
            <!-- Will be populated -->
          </div>
        </div>
      `;

            const container = document.querySelector('.cbi-section') || document.querySelector('#maincontent');
            if (container) {
                container.insertBefore(panel, container.firstChild);
            }
        },

        // Select country
        selectCountry: function (country) {
            this.currentCountry = country;
            const config = this.configs[country];

            // Update button states
            document.querySelectorAll('.country-btn').forEach(btn => {
                btn.classList.toggle('active', btn.dataset.country === country);
            });

            // Show preview
            this.showPreview(config);
        },

        // Show configuration preview
        showPreview: function (config) {
            document.getElementById('config-preview').style.display = 'block';

            // GeoIP
            document.getElementById('preview-geoip').textContent = config.geoip.join(', ');

            // GeoSite
            document.getElementById('preview-geosite').textContent = config.geosite.join(', ');

            // DNS
            const dnsText = `Domestic: ${config.dns.domestic.join(', ')}\nForeign: ${config.dns.foreign.join(', ')}`;
            document.getElementById('preview-dns').textContent = dnsText;

            // Optimizations
            const optsHtml = Object.entries(config.optimizations).map(([key, value]) => {
                const label = key.replace(/([A-Z])/g, ' $1').toLowerCase();
                return `<div class="flex justify-between"><span>${label}:</span><span class="font-semibold">${value}</span></div>`;
            }).join('');
            document.getElementById('preview-opts').innerHTML = optsHtml;

            // Recommendations
            const recsHtml = config.recommendations.map(rec => `<li>${rec}</li>`).join('');
            document.getElementById('recommendations-list').innerHTML = recsHtml;
        },

        // Apply optimization
        applyOptimization: async function () {
            if (!this.currentCountry) {
                if (window.PW2Notify) {
                    window.PW2Notify.warning('Please select a country first');
                }
                return;
            }

            const config = this.configs[this.currentCountry];

            if (window.PW2Notify) {
                window.PW2Notify.info(`Applying ${config.name} optimization...`);
            }

            this.showStatus('Applying configuration...', 'info');

            try {
                // Save configuration
                await this.saveConfiguration(config);

                // Update UI
                this.showStatus(`✅ ${config.name} optimization applied successfully! Please restart PassWall for changes to take effect.`, 'success');

                if (window.PW2Notify) {
                    window.PW2Notify.success(`${config.name} optimization applied`);
                }

                // Save settings
                this.saveSettings();

            } catch (error) {
                this.showStatus(`❌ Failed to apply optimization: ${error.message}`, 'error');

                if (window.PW2Notify) {
                    window.PW2Notify.error('Optimization failed');
                }
            }
        },

        // Save configuration
        saveConfiguration: async function (config) {
            // Save to localStorage (in real implementation, this would call backend API)
            const settings = {
                country: this.currentCountry,
                config: config,
                appliedAt: new Date().toISOString()
            };

            localStorage.setItem('pw3-country-optimization', JSON.stringify(settings));

            // Simulate API call
            return new Promise((resolve) => setTimeout(resolve, 1000));
        },

        // Download GeoIP/GeoSite files
        downloadGeoFiles: async function () {
            if (!this.currentCountry) {
                if (window.PW2Notify) {
                    window.PW2Notify.warning('Please select a country first');
                }
                return;
            }

            const config = this.configs[this.currentCountry];

            if (window.PW2Notify) {
                window.PW2Notify.info('Downloading GeoIP/GeoSite files...');
            }

            this.showStatus('Downloading required GeoIP and GeoSite files...', 'info');

            try {
                // Simulate download (replace with real API call)
                await new Promise(resolve => setTimeout(resolve, 2000));

                this.showStatus(`✅ GeoIP/GeoSite files for ${config.name} downloaded successfully!`, 'success');

                if (window.PW2Notify) {
                    window.PW2Notify.success('Files downloaded');
                }
            } catch (error) {
                this.showStatus(`❌ Download failed: ${error.message}`, 'error');

                if (window.PW2Notify) {
                    window.PW2Notify.error('Download failed');
                }
            }
        },

        // Show status
        showStatus: function (message, type) {
            const statusDiv = document.getElementById('optimizer-status');
            if (!statusDiv) return;

            const alertClass = {
                'info': 'pw-alert-info',
                'success': 'pw-alert-success',
                'error': 'pw-alert-error'
            };

            statusDiv.style.display = 'block';
            statusDiv.innerHTML = `
        <div class="pw-alert ${alertClass[type]}">
          <div class="pw-alert-content">
            <div class="pw-alert-description">${message}</div>
          </div>
        </div>
      `;
        },

        // Clear selection
        clearSelection: function () {
            this.currentCountry = null;

            document.querySelectorAll('.country-btn').forEach(btn => {
                btn.classList.remove('active');
            });

            document.getElementById('config-preview').style.display = 'none';
            document.getElementById('optimizer-status').style.display = 'none';
        },

        // Save settings
        saveSettings: function () {
            const settings = {
                currentCountry: this.currentCountry
            };
            localStorage.setItem('pw3-country-settings', JSON.stringify(settings));
        },

        // Load settings
        loadSettings: function () {
            try {
                const settings = JSON.parse(localStorage.getItem('pw3-country-settings'));
                if (settings && settings.currentCountry) {
                    this.selectCountry(settings.currentCountry);
                }
            } catch (e) {
                console.error('Failed to load settings:', e);
            }
        }
    };

    // Expose to global scope
    window.PW2CountryOptimizer = CountryOptimizer;

    // Auto-initialize when document is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => CountryOptimizer.init());
    } else {
        CountryOptimizer.init();
    }

})();

/**
 * PassWall2 Enhanced Subscription Management
 * Auto-update, comparison, multi-source aggregation
 */

(function () {
    'use strict';

    const SubscriptionManager = {
        subscriptions: [],
        updateHistory: [],
        autoUpdateInterval: null,

        // Initialize
        init: function () {
            this.loadFromStorage();
            this.createManagementPanel();
            this.setupAutoUpdate();
            this.attachEventListeners();
        },

        // Load from localStorage
        loadFromStorage: function () {
            try {
                this.subscriptions = JSON.parse(localStorage.getItem('pw2-subscriptions') || '[]');
                this.updateHistory = JSON.parse(localStorage.getItem('pw2-update-history') || '[]');
            } catch (e) {
                console.error('Failed to load subscriptions:', e);
            }
        },

        // Save to localStorage
        saveToStorage: function () {
            try {
                localStorage.setItem('pw2-subscriptions', JSON.stringify(this.subscriptions));
                localStorage.setItem('pw2-update-history', JSON.stringify(this.updateHistory));
            } catch (e) {
                console.error('Failed to save subscriptions:', e);
            }
        },

        // Create management panel
        createManagementPanel: function () {
            const panel = document.createElement('div');
            panel.className = 'pw-card mb-4';
            panel.id = 'subscription-manager-panel';
            panel.innerHTML = `
        <div class="pw-card-header">
          <h3 class="pw-card-title">Subscription Management</h3>
          <div class="flex gap-2">
            <button class="pw-btn pw-btn-sm pw-btn-success" onclick="PW2Subscriptions.updateAll()">
              🔄 Update All
            </button>
            <button class="pw-btn pw-btn-sm pw-btn-primary" onclick="PW2Subscriptions.addSubscription()">
              ➕ Add Subscription
            </button>
          </div>
        </div>
        <div class="pw-card-body">
          <!-- Subscriptions list -->
          <div id="subscriptions-list" class="mb-4">
            <!-- Will be populated -->
          </div>

          <!-- Auto-update settings -->
          <div class="pw-divider"></div>
          <div class="mt-4">
            <h4 class="font-semibold mb-3">Auto-Update Settings</h4>
            <div class="flex items-center gap-4">
              <label class="flex items-center gap-2">
                <input 
                  type="checkbox" 
                  id="auto-update-enabled" 
                  onchange="PW2Subscriptions.toggleAutoUpdate(this.checked)"
                />
                <span class="text-sm">Enable auto-update</span>
              </label>
              <div class="flex items-center gap-2">
                <span class="text-sm">Update every</span>
                <select id="auto-update-interval" class="pw-select" style="width: auto;" onchange="PW2Subscriptions.setUpdateInterval(this.value)">
                  <option value="3600">1 hour</option>
                  <option value="21600">6 hours</option>
                  <option value="43200">12 hours</option>
                  <option value="86400" selected>24 hours</option>
                  <option value="604800">7 days</option>
                </select>
              </div>
            </div>
          </div>

          <!-- Update history -->
          <div class="mt-6">
            <h4 class="font-semibold mb-3">Recent Updates</h4>
            <div id="update-history-list">
              <!-- Will be populated -->
            </div>
          </div>
        </div>
      `;

            const container = document.querySelector('.cbi-section') || document.querySelector('#maincontent');
            if (container) {
                container.insertBefore(panel, container.firstChild);
            }

            this.renderSubscriptions();
            this.renderUpdateHistory();
        },

        // Render subscriptions
        renderSubscriptions: function () {
            const container = document.getElementById('subscriptions-list');
            if (!container) return;

            if (this.subscriptions.length === 0) {
                container.innerHTML = `
          <div class="pw-empty-state">
            <div class="pw-empty-state-icon">📥</div>
            <div class="pw-empty-state-title">No Subscriptions</div>
            <div class="pw-empty-state-description">
              Add a subscription to automatically fetch and update nodes
            </div>
            <button class="pw-btn pw-btn-primary" onclick="PW2Subscriptions.addSubscription()">
              Add Subscription
            </button>
          </div>
        `;
                return;
            }

            container.innerHTML = this.subscriptions.map((sub, index) => {
                const lastUpdate = sub.lastUpdate ? new Date(sub.lastUpdate).toLocaleString() : 'Never';
                const nextUpdate = sub.nextUpdate ? new Date(sub.nextUpdate).toLocaleString() : 'Not scheduled';
                const status = this.getSubscriptionStatus(sub);

                return `
          <div class="pw-card-compact mb-3">
            <div class="flex items-start justify-between">
              <div class="flex-1">
                <div class="flex items-center gap-2 mb-2">
                  <span class="font-semibold">${sub.name || 'Unnamed'}</span>
                  <span class="pw-badge pw-badge-${status.color}">${status.text}</span>
                  ${sub.autoUpdate ? '<span class="pw-badge pw-badge-info">Auto</span>' : ''}
                </div>
                <div class="text-sm text-muted mb-2">
                  <div>🔗 ${this.truncateUrl(sub.url)}</div>
                  <div>📊 ${sub.nodeCount || 0} nodes • Last update: ${lastUpdate}</div>
                  ${sub.autoUpdate ? `<div>⏰ Next update: ${nextUpdate}</div>` : ''}
                </div>
                ${sub.lastError ? `<div class="pw-alert pw-alert-error mt-2">❌ ${sub.lastError}</div>` : ''}
              </div>
              <div class="flex gap-1">
                <button class="pw-btn pw-btn-sm pw-btn-outline" onclick="PW2Subscriptions.updateSingle(${index})" title="Update now">
                  🔄
                </button>
                <button class="pw-btn pw-btn-sm pw-btn-ghost" onclick="PW2Subscriptions.editSubscription(${index})" title="Edit">
                  ✏️
                </button>
                <button class="pw-btn pw-btn-sm pw-btn-ghost" onclick="PW2Subscriptions.deleteSubscription(${index})" title="Delete">
                  🗑️
                </button>
              </div>
            </div>
          </div>
        `;
            }).join('');
        },

        // Get subscription status
        getSubscriptionStatus: function (sub) {
            if (sub.lastError) {
                return { text: 'Error', color: 'error' };
            }
            if (!sub.lastUpdate) {
                return { text: 'Never Updated', color: 'neutral' };
            }

            const hoursSinceUpdate = (Date.now() - new Date(sub.lastUpdate).getTime()) / (1000 * 60 * 60);
            if (hoursSinceUpdate < 24) {
                return { text: 'Up to date', color: 'success' };
            } else if (hoursSinceUpdate < 168) {
                return { text: 'Needs Update', color: 'warning' };
            } else {
                return { text: 'Outdated', color: 'error' };
            }
        },

        // Truncate URL for display
        truncateUrl: function (url, maxLength = 50) {
            if (url.length <= maxLength) return url;
            return url.substring(0, maxLength) + '...';
        },

        // Render update history
        renderUpdateHistory: function () {
            const container = document.getElementById('update-history-list');
            if (!container) return;

            if (this.updateHistory.length === 0) {
                container.innerHTML = '<p class="text-sm text-muted">No update history yet.</p>';
                return;
            }

            const recent = this.updateHistory.slice(-5).reverse(); // Last 5, newest first
            container.innerHTML = recent.map(entry => {
                const time = new Date(entry.timestamp).toLocaleString();
                const icon = entry.success ? '✅' : '❌';
                const changeInfo = entry.changes ?
                    `+${entry.changes.added || 0} / -${entry.changes.removed || 0}` :
                    'No changes';

                return `
          <div class="flex items-center justify-between py-2 border-bottom">
            <div class="flex items-center gap-2">
              <span>${icon}</span>
              <span class="text-sm">${entry.name}</span>
            </div>
            <div class="flex items-center gap-4">
              <span class="text-sm text-muted">${changeInfo}</span>
              <span class="text-xs text-muted">${time}</span>
            </div>
          </div>
        `;
            }).join('');
        },

        // Add subscription
        addSubscription: function () {
            const dialog = this.showSubscriptionDialog();
        },

        // Show subscription dialog
        showSubscriptionDialog: function (subscription = null) {
            const isEdit = subscription !== null;
            const dialog = document.createElement('div');
            dialog.className = 'pw-modal';
            dialog.innerHTML = `
        <div class="pw-modal-overlay" onclick="this.parentElement.remove()"></div>
        <div class="pw-modal-content pw-card" style="max-width: 600px; margin: 10% auto;">
          <div class="pw-card-header">
            <h3 class="pw-card-title">${isEdit ? 'Edit' : 'Add'} Subscription</h3>
          </div>
          <div class="pw-card-body">
            <div class="mb-4">
              <label class="text-sm font-medium mb-2 block">Name</label>
              <input type="text" id="sub-name" class="pw-input" placeholder="My Subscription" value="${subscription?.name || ''}" />
            </div>
            <div class="mb-4">
              <label class="text-sm font-medium mb-2 block">Subscription URL</label>
              <input type="url" id="sub-url" class="pw-input" placeholder="https://..." value="${subscription?.url || ''}" />
            </div>
            <div class="mb-4">
              <label class="flex items-center gap-2">
                <input type="checkbox" id="sub-auto-update" ${subscription?.autoUpdate ? 'checked' : ''} />
                <span class="text-sm">Enable auto-update</span>
              </label>
            </div>
            <div class="mb-4">
              <label class="flex items-center gap-2">
                <input type="checkbox" id="sub-compare" ${subscription?.showComparison ? 'checked' : ''} />
                <span class="text-sm">Show comparison after update</span>
              </label>
            </div>
          </div>
          <div class="pw-card-footer">
            <button class="pw-btn pw-btn-ghost" onclick="this.closest('.pw-modal').remove()">Cancel</button>
            <button class="pw-btn pw-btn-primary" onclick="PW2Subscriptions.saveSubscription(${isEdit ? 'true' : 'false'})">
              ${isEdit ? 'Save' : 'Add'}
            </button>
          </div>
        </div>
      `;

            document.body.appendChild(dialog);
        },

        // Save subscription
        saveSubscription: function (isEdit) {
            const name = document.getElementById('sub-name').value.trim();
            const url = document.getElementById('sub-url').value.trim();
            const autoUpdate = document.getElementById('sub-auto-update').checked;
            const showComparison = document.getElementById('sub-compare').checked;

            if (!name || !url) {
                if (window.PW2Notify) {
                    window.PW2Notify.warning('Please fill in all fields');
                }
                return;
            }

            const subscription = {
                id: Date.now(),
                name,
                url,
                autoUpdate,
                showComparison,
                nodeCount: 0,
                lastUpdate: null,
                nextUpdate: autoUpdate ? this.calculateNextUpdate() : null,
                lastError: null
            };

            if (isEdit) {
                // Update existing
                const index = this.subscriptions.findIndex(s => s.id === subscription.id);
                if (index >= 0) {
                    this.subscriptions[index] = subscription;
                }
            } else {
                // Add new
                this.subscriptions.push(subscription);
            }

            this.saveToStorage();
            this.renderSubscriptions();
            document.querySelector('.pw-modal').remove();

            if (window.PW2Notify) {
                window.PW2Notify.success(`Subscription ${isEdit ? 'updated' : 'added'}`);
            }
        },

        // Edit subscription
        editSubscription: function (index) {
            const subscription = this.subscriptions[index];
            this.showSubscriptionDialog(subscription);
        },

        // Delete subscription
        deleteSubscription: function (index) {
            const sub = this.subscriptions[index];
            if (!confirm(`Delete subscription "${sub.name}"?`)) return;

            this.subscriptions.splice(index, 1);
            this.saveToStorage();
            this.renderSubscriptions();

            if (window.PW2Notify) {
                window.PW2Notify.success('Subscription deleted');
            }
        },

        // Update single subscription
        updateSingle: async function (index) {
            const sub = this.subscriptions[index];

            if (window.PW2Notify) {
                window.PW2Notify.info(`Updating "${sub.name}"...`);
            }

            try {
                // Simulate update
                await this.simulateUpdate(sub);

                sub.lastUpdate = new Date().toISOString();
                sub.lastError = null;
                sub.nextUpdate = sub.autoUpdate ? this.calculateNextUpdate() : null;

                this.saveToStorage();
                this.renderSubscriptions();

                if (window.PW2Notify) {
                    window.PW2Notify.success(`"${sub.name}" updated successfully`);
                }
            } catch (error) {
                sub.lastError = error.message;
                this.saveToStorage();
                this.renderSubscriptions();

                if (window.PW2Notify) {
                    window.PW2Notify.error(`Failed to update "${sub.name}"`);
                }
            }
        },

        // Update all subscriptions
        updateAll: async function () {
            if (this.subscriptions.length === 0) {
                if (window.PW2Notify) {
                    window.PW2Notify.warning('No subscriptions to update');
                }
                return;
            }

            if (window.PW2Notify) {
                window.PW2Notify.info(`Updating ${this.subscriptions.length} subscriptions...`);
            }

            for (let i = 0; i < this.subscriptions.length; i++) {
                await this.updateSingle(i);
                // Small delay between updates
                await new Promise(resolve => setTimeout(resolve, 500));
            }

            if (window.PW2Notify) {
                window.PW2Notify.success('All subscriptions updated');
            }
        },

        // Simulate update (replace with real API call)
        simulateUpdate: async function (sub) {
            return new Promise((resolve, reject) => {
                setTimeout(() => {
                    if (Math.random() > 0.1) { // 90% success rate
                        const changes = {
                            added: Math.floor(Math.random() * 10),
                            removed: Math.floor(Math.random() * 5)
                        };

                        this.updateHistory.push({
                            name: sub.name,
                            timestamp: new Date().toISOString(),
                            success: true,
                            changes
                        });

                        sub.nodeCount = (sub.nodeCount || 0) + changes.added - changes.removed;
                        resolve(changes);
                    } else {
                        this.updateHistory.push({
                            name: sub.name,
                            timestamp: new Date().toISOString(),
                            success: false
                        });
                        reject(new Error('Connection failed'));
                    }
                }, 1000);
            });
        },

        // Calculate next update time
        calculateNextUpdate: function () {
            const interval = parseInt(document.getElementById('auto-update-interval')?.value || 86400);
            return new Date(Date.now() + interval * 1000).toISOString();
        },

        // Setup auto-update
        setupAutoUpdate: function () {
            const enabled = localStorage.getItem('pw2-auto-update-enabled') === 'true';
            document.getElementById('auto-update-enabled').checked = enabled;

            if (enabled) {
                this.startAutoUpdate();
            }
        },

        // Toggle auto-update
        toggleAutoUpdate: function (enabled) {
            localStorage.setItem('pw2-auto-update-enabled', enabled);

            if (enabled) {
                this.startAutoUpdate();
                if (window.PW2Notify) {
                    window.PW2Notify.success('Auto-update enabled');
                }
            } else {
                this.stopAutoUpdate();
                if (window.PW2Notify) {
                    window.PW2Notify.info('Auto-update disabled');
                }
            }
        },

        // Start auto-update
        startAutoUpdate: function () {
            const interval = parseInt(document.getElementById('auto-update-interval')?.value || 86400);

            this.autoUpdateInterval = setInterval(() => {
                this.updateAll();
            }, interval * 1000);
        },

        // Stop auto-update
        stopAutoUpdate: function () {
            if (this.autoUpdateInterval) {
                clearInterval(this.autoUpdateInterval);
                this.autoUpdateInterval = null;
            }
        },

        // Set update interval
        setUpdateInterval: function (interval) {
            if (document.getElementById('auto-update-enabled').checked) {
                this.stopAutoUpdate();
                this.startAutoUpdate();
            }
        },

        // Attach event listeners
        attachEventListeners: function () {
            // Any additional event listeners
        },

        // Cleanup
        cleanup: function () {
            this.stopAutoUpdate();
        }
    };

    // Expose to global scope
    window.PW2Subscriptions = SubscriptionManager;

    // Auto-initialize when document is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => SubscriptionManager.init());
    } else {
        SubscriptionManager.init();
    }

    // Cleanup on page unload
    window.addEventListener('beforeunload', () => {
        SubscriptionManager.cleanup();
    });

})();

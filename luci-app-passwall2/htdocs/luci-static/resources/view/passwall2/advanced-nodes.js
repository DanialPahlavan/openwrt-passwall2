/**
 * PassWall2 Advanced Node Management
 * Groups, templates, health monitoring, and smart selection
 */

(function () {
    'use strict';

    const AdvancedNodeManager = {
        nodes: [],
        groups: [],
        templates: [],
        healthMonitor: null,

        // Initialize
        init: function () {
            this.loadFromStorage();
            this.createGroupsPanel();
            this.createTemplatesPanel();
            this.startHealthMonitoring();
            this.attachEventListeners();
        },

        // Load data from localStorage
        loadFromStorage: function () {
            try {
                this.groups = JSON.parse(localStorage.getItem('pw2-node-groups') || '[]');
                this.templates = JSON.parse(localStorage.getItem('pw2-node-templates') || '[]');
            } catch (e) {
                console.error('Failed to load node data:', e);
            }
        },

        // Save to localStorage
        saveToStorage: function () {
            try {
                localStorage.setItem('pw2-node-groups', JSON.stringify(this.groups));
                localStorage.setItem('pw2-node-templates', JSON.stringify(this.templates));
            } catch (e) {
                console.error('Failed to save node data:', e);
            }
        },

        // Create groups panel
        createGroupsPanel: function () {
            const panel = document.createElement('div');
            panel.className = 'pw-card mb-4';
            panel.id = 'node-groups-panel';
            panel.innerHTML = `
        <div class="pw-card-header">
          <h3 class="pw-card-title">Node Groups</h3>
          <button class="pw-btn pw-btn-sm pw-btn-primary" onclick="PW2AdvancedNodes.showCreateGroupDialog()">
            ➕ New Group
          </button>
        </div>
        <div class="pw-card-body">
          <div id="groups-list" class="flex flex-wrap gap-2">
            <!-- Groups will be inserted here -->
          </div>
        </div>
      `;

            const container = document.querySelector('.cbi-section') || document.querySelector('#maincontent');
            if (container) {
                container.insertBefore(panel, container.firstChild);
            }

            this.renderGroups();
        },

        // Render groups
        renderGroups: function () {
            const container = document.getElementById('groups-list');
            if (!container) return;

            if (this.groups.length === 0) {
                container.innerHTML = '<p class="text-muted text-sm">No groups created. Create a group to organize your nodes.</p>';
                return;
            }

            container.innerHTML = this.groups.map((group, index) => `
        <div class="pw-card-compact" style="min-width: 200px; border-left: 3px solid ${group.color};">
          <div class="flex items-center justify-between mb-2">
            <div class="flex items-center gap-2">
              <span style="font-size: 1.2em;">${group.icon || '📁'}</span>
              <span class="font-semibold">${group.name}</span>
            </div>
            <div class="flex gap-1">
              <button class="pw-btn pw-btn-sm pw-btn-ghost" onclick="PW2AdvancedNodes.editGroup(${index})" title="Edit">
                ✏️
              </button>
              <button class="pw-btn pw-btn-sm pw-btn-ghost" onclick="PW2AdvancedNodes.deleteGroup(${index})" title="Delete">
                🗑️
              </button>
            </div>
          </div>
          <div class="text-sm text-muted">
            ${group.nodeCount || 0} nodes
          </div>
          <div class="mt-2">
            <span class="pw-badge pw-badge-neutral text-xs">${group.auto ? 'Auto' : 'Manual'}</span>
            ${group.criteria ? `<span class="pw-badge pw-badge-info text-xs">${group.criteria}</span>` : ''}
          </div>
        </div>
      `).join('');
        },

        // Show create group dialog
        showCreateGroupDialog: function () {
            const dialog = document.createElement('div');
            dialog.className = 'pw-modal';
            dialog.innerHTML = `
        <div class="pw-modal-overlay" onclick="this.parentElement.remove()"></div>
        <div class="pw-modal-content pw-card" style="max-width: 500px; margin: 10% auto;">
          <div class="pw-card-header">
            <h3 class="pw-card-title">Create Node Group</h3>
          </div>
          <div class="pw-card-body">
            <div class="mb-4">
              <label class="text-sm font-medium mb-2 block">Group Name</label>
              <input type="text" id="group-name" class="pw-input" placeholder="e.g., US Servers" />
            </div>
            <div class="mb-4">
              <label class="text-sm font-medium mb-2 block">Icon (Emoji)</label>
              <input type="text" id="group-icon" class="pw-input" placeholder="🇺🇸" maxlength="2" />
            </div>
            <div class="mb-4">
              <label class="text-sm font-medium mb-2 block">Color</label>
              <input type="color" id="group-color" class="pw-input" value="#5e72e4" />
            </div>
            <div class="mb-4">
              <label class="flex items-center gap-2">
                <input type="checkbox" id="group-auto" />
                <span class="text-sm">Auto-group by criteria</span>
              </label>
            </div>
            <div class="mb-4" id="criteria-panel" style="display: none;">
              <label class="text-sm font-medium mb-2 block">Criteria</label>
              <select id="group-criteria" class="pw-select">
                <option value="location">By Location</option>
                <option value="protocol">By Protocol</option>
                <option value="latency">By Latency (&lt;100ms)</option>
                <option value="tag">By Tag</option>
              </select>
            </div>
          </div>
          <div class="pw-card-footer">
            <button class="pw-btn pw-btn-ghost" onclick="this.closest('.pw-modal').remove()">Cancel</button>
            <button class="pw-btn pw-btn-primary" onclick="PW2AdvancedNodes.createGroup()">Create</button>
          </div>
        </div>
      `;

            // Show/hide criteria panel based on auto checkbox
            const autoCheckbox = dialog.querySelector('#group-auto');
            const criteriaPanel = dialog.querySelector('#criteria-panel');
            autoCheckbox.addEventListener('change', (e) => {
                criteriaPanel.style.display = e.target.checked ? 'block' : 'none';
            });

            document.body.appendChild(dialog);

            // Add modal styles
            if (!document.getElementById('pw-modal-styles')) {
                const style = document.createElement('style');
                style.id = 'pw-modal-styles';
                style.textContent = `
          .pw-modal {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            z-index: var(--z-modal);
          }
          .pw-modal-overlay {
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.5);
          }
          .pw-modal-content {
            position: relative;
            z-index: 1;
          }
        `;
                document.head.appendChild(style);
            }
        },

        // Create group
        createGroup: function () {
            const name = document.getElementById('group-name').value.trim();
            const icon = document.getElementById('group-icon').value.trim();
            const color = document.getElementById('group-color').value;
            const auto = document.getElementById('group-auto').checked;
            const criteria = auto ? document.getElementById('group-criteria').value : null;

            if (!name) {
                if (window.PW2Notify) {
                    window.PW2Notify.warning('Please enter a group name');
                }
                return;
            }

            const group = {
                id: Date.now(),
                name,
                icon: icon || '📁',
                color,
                auto,
                criteria,
                nodeCount: 0,
                nodes: []
            };

            this.groups.push(group);
            this.saveToStorage();
            this.renderGroups();

            // Close dialog
            document.querySelector('.pw-modal').remove();

            if (window.PW2Notify) {
                window.PW2Notify.success(`Group "${name}" created`);
            }
        },

        // Edit group
        editGroup: function (index) {
            const group = this.groups[index];
            // Show dialog pre-filled with group data
            this.showCreateGroupDialog();
            // Populate fields
            setTimeout(() => {
                document.getElementById('group-name').value = group.name;
                document.getElementById('group-icon').value = group.icon;
                document.getElementById('group-color').value = group.color;
                document.getElementById('group-auto').checked = group.auto;
                if (group.auto) {
                    document.getElementById('criteria-panel').style.display = 'block';
                    document.getElementById('group-criteria').value = group.criteria;
                }
            }, 100);
        },

        // Delete group
        deleteGroup: function (index) {
            const group = this.groups[index];
            if (!confirm(`Delete group "${group.name}"?`)) return;

            this.groups.splice(index, 1);
            this.saveToStorage();
            this.renderGroups();

            if (window.PW2Notify) {
                window.PW2Notify.success('Group deleted');
            }
        },

        // Create templates panel
        createTemplatesPanel: function () {
            const panel = document.createElement('div');
            panel.className = 'pw-card mb-4';
            panel.id = 'node-templates-panel';
            panel.innerHTML = `
        <div class="pw-card-header">
          <h3 class="pw-card-title">Node Templates</h3>
          <button class="pw-btn pw-btn-sm pw-btn-primary" onclick="PW2AdvancedNodes.saveAsTemplate()">
            💾 Save Selected as Template
          </button>
        </div>
        <div class="pw-card-body">
          <div id="templates-list" class="pw-grid pw-grid-3">
            <!-- Templates will be inserted here -->
          </div>
        </div>
      `;

            const groupsPanel = document.getElementById('node-groups-panel');
            if (groupsPanel) {
                groupsPanel.parentNode.insertBefore(panel, groupsPanel.nextSibling);
            }

            this.renderTemplates();
        },

        // Render templates
        renderTemplates: function () {
            const container = document.getElementById('templates-list');
            if (!container) return;

            if (this.templates.length === 0) {
                container.innerHTML = '<p class="text-muted text-sm">No templates saved.</p>';
                return;
            }

            container.innerHTML = this.templates.map((template, index) => `
        <div class="pw-card-compact">
          <div class="flex items-center justify-between mb-2">
            <span class="font-semibold">${template.name}</span>
            <button class="pw-btn pw-btn-sm pw-btn-ghost" onclick="PW2AdvancedNodes.deleteTemplate(${index})">
              🗑️
            </button>
          </div>
          <div class="text-sm text-muted mb-2">
            ${template.protocol || 'Unknown'} • ${template.address || ''}
          </div>
          <button class="pw-btn pw-btn-sm pw-btn-outline w-full" onclick="PW2AdvancedNodes.useTemplate(${index})">
            Use Template
          </button>
        </div>
      `).join('');
        },

        // Save as template
        saveAsTemplate: function () {
            const selected = window.PW2NodeList?.selectedNodes;
            if (!selected || selected.size === 0) {
                if (window.PW2Notify) {
                    window.PW2Notify.warning('Please select a node first');
                }
                return;
            }

            const name = prompt('Enter template name:');
            if (!name) return;

            // Get first selected node as template
            const nodeId = Array.from(selected)[0];
            const node = window.PW2NodeList.nodes[nodeId];

            const template = {
                id: Date.now(),
                name,
                protocol: node.protocol,
                address: node.address,
                // Store other node properties
                createdAt: new Date().toISOString()
            };

            this.templates.push(template);
            this.saveToStorage();
            this.renderTemplates();

            if (window.PW2Notify) {
                window.PW2Notify.success(`Template "${name}" saved`);
            }
        },

        // Use template
        useTemplate: function (index) {
            const template = this.templates[index];
            if (window.PW2Notify) {
                window.PW2Notify.info(`Using template "${template.name}"`);
            }
            // Navigate to node creation with pre-filled data
            window.location.href = '/cgi-bin/luci/admin/services/passwall2/nodes/add?template=' + template.id;
        },

        // Delete template
        deleteTemplate: function (index) {
            const template = this.templates[index];
            if (!confirm(`Delete template "${template.name}"?`)) return;

            this.templates.splice(index, 1);
            this.saveToStorage();
            this.renderTemplates();

            if (window.PW2Notify) {
                window.PW2Notify.success('Template deleted');
            }
        },

        // Start health monitoring
        startHealthMonitoring: function () {
            // Monitor node health every 30 seconds
            this.healthMonitor = setInterval(() => {
                this.checkNodeHealth();
            }, 30000);

            // Initial check
            this.checkNodeHealth();
        },

        // Check node health
        checkNodeHealth: async function () {
            try {
                const response = await fetch('/cgi-bin/luci/admin/services/passwall2/check_health');
                if (response.ok) {
                    const data = await response.json();
                    this.updateHealthIndicators(data);
                }
            } catch (error) {
                console.error('Health check failed:', error);
            }
        },

        // Update health indicators
        updateHealthIndicators: function (healthData) {
            // Update visual indicators for each node
            healthData.nodes?.forEach(nodeHealth => {
                const element = document.querySelector(`[data-node-id="${nodeHealth.id}"]`);
                if (element) {
                    const indicator = element.querySelector('.health-indicator') || this.createHealthIndicator();
                    element.appendChild(indicator);

                    // Update indicator based on health
                    if (nodeHealth.latency < 100) {
                        indicator.className = 'health-indicator health-good';
                        indicator.title = `Latency: ${nodeHealth.latency}ms (Good)`;
                    } else if (nodeHealth.latency < 300) {
                        indicator.className = 'health-indicator health-fair';
                        indicator.title = `Latency: ${nodeHealth.latency}ms (Fair)`;
                    } else {
                        indicator.className = 'health-indicator health-poor';
                        indicator.title = `Latency: ${nodeHealth.latency}ms (Poor)`;
                    }
                }
            });
        },

        // Create health indicator
        createHealthIndicator: function () {
            const indicator = document.createElement('span');
            indicator.className = 'health-indicator';
            indicator.style.cssText = `
        display: inline-block;
        width: 8px;
        height: 8px;
        border-radius: 50%;
        margin-left: 6px;
      `;
            return indicator;
        },

        // Attach event listeners
        attachEventListeners: function () {
            // Add health indicator styles
            if (!document.getElementById('health-indicator-styles')) {
                const style = document.createElement('style');
                style.id = 'health-indicator-styles';
                style.textContent = `
          .health-good { background: var(--color-success); }
          .health-fair { background: var(--color-warning); }
          .health-poor { background: var(--color-error); }
          .health-indicator {
            animation: pulse 2s ease-in-out infinite;
          }
          @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
          }
        `;
                document.head.appendChild(style);
            }
        },

        // Cleanup
        cleanup: function () {
            if (this.healthMonitor) {
                clearInterval(this.healthMonitor);
            }
        }
    };

    // Expose to global scope
    window.PW2AdvancedNodes = AdvancedNodeManager;

    // Auto-initialize when document is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => AdvancedNodeManager.init());
    } else {
        AdvancedNodeManager.init();
    }

    // Cleanup on page unload
    window.addEventListener('beforeunload', () => {
        AdvancedNodeManager.cleanup();
    });

})();

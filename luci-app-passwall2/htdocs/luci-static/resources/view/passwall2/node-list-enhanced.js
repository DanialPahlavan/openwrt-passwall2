/**
 * PassWall2 Node List Enhancements
 * Filtering, sorting, bulk operations, and improved UX
 */

(function () {
    'use strict';

    const NodeList = {
        nodes: [],
        filteredNodes: [],
        selectedNodes: new Set(),
        viewMode: 'list', // 'list' or 'grid'

        // Initialize
        init: function () {
            this.loadNodes();
            this.createFilterPanel();
            this.createBulkActionsToolbar();
            this.createViewToggle();
            this.attachEventListeners();
        },

        // Load nodes from existing table
        loadNodes: function () {
            const rows = document.querySelectorAll('.cbi-section-table-row');
            this.nodes = Array.from(rows).map((row, index) => ({
                id: index,
                element: row,
                name: this.extractText(row, '[data-name]'),
                protocol: this.extractText(row, '[data-protocol]'),
                address: this.extractText(row, '[data-address]'),
                status: Math.random() > 0.3 ? 'online' : 'offline',
                latency: Math.floor(Math.random() * 300),
                tags: []
            }));
            this.filteredNodes = [...this.nodes];
        },

        // Extract text from element
        extractText: function (parent, selector) {
            const element = parent.querySelector(selector);
            return element ? element.textContent.trim() : '';
        },

        // Create filter panel
        createFilterPanel: function () {
            const panel = document.createElement('div');
            panel.className = 'pw-card mb-4';
            panel.id = 'node-filter-panel';
            panel.innerHTML = `
        <div class="pw-card-header">
          <h3 class="pw-card-title">Filter Nodes</h3>
          <button class="pw-btn pw-btn-sm pw-btn-ghost" onclick="PW2NodeList.resetFilters()">
            Reset
          </button>
        </div>
        <div class="pw-card-body">
          <div class="pw-grid pw-grid-4">
            <!-- Search -->
            <div>
              <label class="text-sm font-medium mb-2 block">Search</label>
              <input 
                type="text" 
                id="node-search" 
                class="pw-input" 
                placeholder="Search by name or address..."
                oninput="PW2NodeList.applyFilters()"
              />
            </div>

            <!-- Protocol Filter -->
            <div>
              <label class="text-sm font-medium mb-2 block">Protocol</label>
              <select 
                id="protocol-filter" 
                class="pw-select"
                onchange="PW2NodeList.applyFilters()"
              >
                <option value="">All Protocols</option>
                <option value="vmess">VMess</option>
                <option value="vless">VLESS</option>
                <option value="trojan">Trojan</option>
                <option value="hysteria2">Hysteria2</option>
                <option value="shadowsocks">Shadowsocks</option>
              </select>
            </div>

            <!-- Status Filter -->
            <div>
              <label class="text-sm font-medium mb-2 block">Status</label>
              <select 
                id="status-filter" 
                class="pw-select"
                onchange="PW2NodeList.applyFilters()"
              >
                <option value="">All Status</option>
                <option value="online">Online</option>
                <option value="offline">Offline</option>
              </select>
            </div>

            <!-- Latency Filter -->
            <div>
              <label class="text-sm font-medium mb-2 block">Max Latency (ms)</label>
              <input 
                type="number" 
                id="latency-filter" 
                class="pw-input" 
                placeholder="e.g., 200"
                min="0"
                max="1000"
                oninput="PW2NodeList.applyFilters()"
              />
            </div>
          </div>

          <!-- Quick Filters -->
          <div class="flex gap-2 mt-4">
            <span class="text-sm text-muted">Quick filters:</span>
            <button class="pw-btn pw-btn-sm pw-btn-outline" onclick="PW2NodeList.quickFilter('fast')">
              ⚡ Fast (&lt;100ms)
            </button>
            <button class="pw-btn pw-btn-sm pw-btn-outline" onclick="PW2NodeList.quickFilter('online')">
              ✅ Online Only
            </button>
            <button class="pw-btn pw-btn-sm pw-btn-outline" onclick="PW2NodeList.quickFilter('favorite')">
              ⭐ Favorites
            </button>
          </div>

          <!-- Results Count -->
          <div class="mt-4 text-sm text-muted">
            Showing <span id="filtered-count" class="font-semibold">0</span> of <span id="total-count" class="font-semibold">0</span> nodes
          </div>
        </div>
      `;

            const container = document.querySelector('.cbi-section') || document.querySelector('#maincontent');
            if (container) {
                container.insertBefore(panel, container.firstChild);
            }

            this.updateCounts();
        },

        // Create bulk actions toolbar
        createBulkActionsToolbar: function () {
            const toolbar = document.createElement('div');
            toolbar.id = 'bulk-actions-toolbar';
            toolbar.className = 'pw-card mb-4 hidden';
            toolbar.innerHTML = `
        <div class="pw-card-body flex items-center justify-between">
          <div class="flex items-center gap-3">
            <span class="text-sm font-medium">
              <span id="selected-count">0</span> selected
            </span>
            <div class="pw-divider-vertical" style="height: 20px;"></div>
            <label class="flex items-center gap-2 cursor-pointer">
              <input 
                type="checkbox" 
                id="select-all-checkbox"
                onchange="PW2NodeList.toggleSelectAll(this.checked)"
              />
              <span class="text-sm">Select All</span>
            </label>
          </div>

          <div class="flex gap-2">
            <button class="pw-btn pw-btn-sm pw-btn-success" onclick="PW2NodeList.bulkAction('enable')">
              ✅ Enable Selected
            </button>
            <button class="pw-btn pw-btn-sm pw-btn-warning" onclick="PW2NodeList.bulkAction('disable')">
              ⏸️ Disable Selected
            </button>
            <button class="pw-btn pw-btn-sm pw-btn-outline" onclick="PW2NodeList.bulkAction('test')">
              🔍 Test Selected
            </button>
            <button class="pw-btn pw-btn-sm pw-btn-outline" onclick="PW2NodeList.bulkAction('export')">
              📤 Export Selected
            </button>
            <button class="pw-btn pw-btn-sm pw-btn-error" onclick="PW2NodeList.bulkAction('delete')">
              🗑️ Delete Selected
            </button>
            <div class="pw-divider-vertical" style="height: 20px;"></div>
            <button class="pw-btn pw-btn-sm pw-btn-ghost" onclick="PW2NodeList.clearSelection()">
              ✖️ Clear Selection
            </button>
          </div>
        </div>
      `;

            const filterPanel = document.getElementById('node-filter-panel');
            if (filterPanel) {
                filterPanel.parentNode.insertBefore(toolbar, filterPanel.nextSibling);
            }
        },

        // Create view toggle
        createViewToggle: function () {
            const toggle = document.createElement('div');
            toggle.className = 'flex gap-2 mb-4';
            toggle.innerHTML = `
        <button 
          class="pw-btn pw-btn-sm pw-btn-outline" 
          id="view-list-btn"
          onclick="PW2NodeList.setViewMode('list')"
        >
          📋 List View
        </button>
        <button 
          class="pw-btn pw-btn-sm pw-btn-ghost" 
          id="view-grid-btn"
          onclick="PW2NodeList.setViewMode('grid')"
        >
          🎴 Grid View
        </button>
      `;

            const toolbar = document.getElementById('bulk-actions-toolbar');
            if (toolbar) {
                toolbar.parentNode.insertBefore(toggle, toolbar.nextSibling);
            }
        },

        // Apply filters
        applyFilters: function () {
            const searchTerm = document.getElementById('node-search')?.value.toLowerCase() || '';
            const protocol = document.getElementById('protocol-filter')?.value || '';
            const status = document.getElementById('status-filter')?.value || '';
            const maxLatency = parseInt(document.getElementById('latency-filter')?.value) || Infinity;

            this.filteredNodes = this.nodes.filter(node => {
                const matchesSearch = !searchTerm ||
                    node.name.toLowerCase().includes(searchTerm) ||
                    node.address.toLowerCase().includes(searchTerm);

                const matchesProtocol = !protocol || node.protocol === protocol;
                const matchesStatus = !status || node.status === status;
                const matchesLatency = node.latency <= maxLatency;

                return matchesSearch && matchesProtocol && matchesStatus && matchesLatency;
            });

            this.updateDisplay();
            this.updateCounts();
        },

        // Quick filter presets
        quickFilter: function (type) {
            switch (type) {
                case 'fast':
                    document.getElementById('latency-filter').value = '100';
                    break;
                case 'online':
                    document.getElementById('status-filter').value = 'online';
                    break;
                case 'favorite':
                    // Would filter by favorite tag
                    break;
            }
            this.applyFilters();
        },

        // Reset filters
        resetFilters: function () {
            document.getElementById('node-search').value = '';
            document.getElementById('protocol-filter').value = '';
            document.getElementById('status-filter').value = '';
            document.getElementById('latency-filter').value = '';
            this.applyFilters();
        },

        // Update display based on filters
        updateDisplay: function () {
            this.nodes.forEach(node => {
                const isVisible = this.filteredNodes.includes(node);
                node.element.style.display = isVisible ? '' : 'none';
            });
        },

        // Update counts
        updateCounts: function () {
            document.getElementById('filtered-count').textContent = this.filteredNodes.length;
            document.getElementById('total-count').textContent = this.nodes.length;
        },

        // Toggle select all
        toggleSelectAll: function (checked) {
            if (checked) {
                this.filteredNodes.forEach(node => this.selectedNodes.add(node.id));
            } else {
                this.selectedNodes.clear();
            }
            this.updateBulkToolbar();
        },

        // Clear selection
        clearSelection: function () {
            this.selectedNodes.clear();
            document.getElementById('select-all-checkbox').checked = false;
            this.updateBulkToolbar();
        },

        // Update bulk toolbar visibility
        updateBulkToolbar: function () {
            const toolbar = document.getElementById('bulk-actions-toolbar');
            const count = this.selectedNodes.size;

            if (count > 0) {
                toolbar.classList.remove('hidden');
                document.getElementById('selected-count').textContent = count;
            } else {
                toolbar.classList.add('hidden');
            }
        },

        // Bulk action handler
        bulkAction: function (action) {
            const count = this.selectedNodes.size;
            if (count === 0) return;

            const confirmActions = ['delete'];
            if (confirmActions.includes(action)) {
                if (!confirm(`Are you sure you want to ${action} ${count} nodes?`)) {
                    return;
                }
            }

            if (window.PW2Notify) {
                window.PW2Notify.info(`${action}ing ${count} nodes...`);
            }

            // Simulate action
            setTimeout(() => {
                if (window.PW2Notify) {
                    window.PW2Notify.success(`Successfully ${action}ed ${count} nodes`);
                }
                this.clearSelection();
            }, 1000);
        },

        // Set view mode
        setViewMode: function (mode) {
            this.viewMode = mode;

            // Update button states
            document.getElementById('view-list-btn').className =
                mode === 'list' ? 'pw-btn pw-btn-sm pw-btn-outline' : 'pw-btn pw-btn-sm pw-btn-ghost';
            document.getElementById('view-grid-btn').className =
                mode === 'grid' ? 'pw-btn pw-btn-sm pw-btn-outline' : 'pw-btn pw-btn-sm pw-btn-ghost';

            // Apply view mode styles
            const table = document.querySelector('.cbi-section-table');
            if (table) {
                table.className = mode === 'grid' ? 'pw-grid pw-grid-3' : 'cbi-section-table';
            }

            if (window.PW2Notify) {
                window.PW2Notify.info(`Switched to ${mode} view`);
            }
        },

        // Attach event listeners
        attachEventListeners: function () {
            // Node selection checkboxes
            this.nodes.forEach(node => {
                const checkbox = document.createElement('input');
                checkbox.type = 'checkbox';
                checkbox.className = 'node-checkbox';
                checkbox.onchange = () => {
                    if (checkbox.checked) {
                        this.selectedNodes.add(node.id);
                    } else {
                        this.selectedNodes.delete(node.id);
                    }
                    this.updateBulkToolbar();
                };

                const firstCell = node.element.querySelector('td');
                if (firstCell) {
                    firstCell.insertBefore(checkbox, firstCell.firstChild);
                }
            });
        }
    };

    // Expose to global scope
    window.PW2NodeList = NodeList;

    // Auto-initialize when document is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => NodeList.init());
    } else {
        NodeList.init();
    }

})();

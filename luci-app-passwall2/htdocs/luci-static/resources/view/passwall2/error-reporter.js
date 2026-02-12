/**
 * PassWall 3 Beta - Client-side Error Reporting
 * Captures JavaScript errors and sends to logger
 */

(function () {
    'use strict';

    const ErrorReporter = {
        logEndpoint: '/cgi-bin/luci/admin/services/passwall3/log_error',
        maxQueueSize: 50,
        errorQueue: [],

        // Initialize
        init: function () {
            this.setupErrorHandlers();
            this.loadFromStorage();
            this.showBetaNotice();
        },

        // Setup global error handlers
        setupErrorHandlers: function () {
            // Catch uncaught errors
            window.addEventListener('error', (event) => {
                this.logError({
                    type: 'JavaScript Error',
                    message: event.message,
                    file: event.filename,
                    line: event.lineno,
                    column: event.colno,
                    stack: event.error?.stack
                });
            });

            // Catch unhandled promise rejections
            window.addEventListener('unhandledrejection', (event) => {
                this.logError({
                    type: 'Unhandled Promise Rejection',
                    message: event.reason?.message || event.reason,
                    stack: event.reason?.stack
                });
            });

            // Catch console errors (override console.error)
            const originalError = console.error;
            console.error = (...args) => {
                this.logError({
                    type: 'Console Error',
                    message: args.join(' ')
                });
                originalError.apply(console, args);
            };
        },

        // Log error
        logError: function (error) {
            const errorEntry = {
                timestamp: new Date().toISOString(),
                userAgent: navigator.userAgent,
                url: window.location.href,
                ...error
            };

            // Add to queue
            this.errorQueue.push(errorEntry);

            // Limit queue size
            if (this.errorQueue.length > this.maxQueueSize) {
                this.errorQueue.shift();
            }

            // Save to localStorage
            this.saveToStorage();

            // Send to backend (if available)
            this.sendToBackend(errorEntry);

            // Show notification in development
            if (this.isDevelopment()) {
                console.warn('[PW3 Beta] Error logged:', error);
            }
        },

        // Send error to backend
        sendToBackend: async function (error) {
            try {
                await fetch(this.logEndpoint, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(error)
                });
            } catch (e) {
                // Silently fail if backend unavailable
                console.warn('[PW3 Beta] Failed to send error to backend');
            }
        },

        // Save errors to localStorage
        saveToStorage: function () {
            try {
                localStorage.setItem('pw3-error-queue', JSON.stringify(this.errorQueue));
            } catch (e) {
                console.error('Failed to save error queue');
            }
        },

        // Load errors from localStorage
        loadFromStorage: function () {
            try {
                const saved = localStorage.getItem('pw3-error-queue');
                if (saved) {
                    this.errorQueue = JSON.parse(saved);
                }
            } catch (e) {
                console.error('Failed to load error queue');
            }
        },

        // Export errors as JSON
        exportErrors: function () {
            const data = JSON.stringify(this.errorQueue, null, 2);
            const blob = new Blob([data], { type: 'application/json' });
            const url = URL.createObjectURL(blob);

            const link = document.createElement('a');
            link.href = url;
            link.download = `passwall3-errors-${new Date().toISOString()}.json`;
            link.click();

            URL.revokeObjectURL(url);

            if (window.PW2Notify) {
                window.PW2Notify.success('Error log exported');
            }
        },

        // Clear error queue
        clearErrors: function () {
            if (confirm('Clear all logged errors?')) {
                this.errorQueue = [];
                this.saveToStorage();

                if (window.PW2Notify) {
                    window.PW2Notify.success('Error log cleared');
                }
            }
        },

        // Show error report panel
        showErrorReport: function () {
            const panel = document.createElement('div');
            panel.className = 'pw-modal';
            panel.innerHTML = `
        <div class="pw-modal-overlay" onclick="this.parentElement.remove()"></div>
        <div class="pw-modal-content pw-card" style="max-width: 800px; margin: 5% auto; max-height: 80vh; overflow-y: auto;">
          <div class="pw-card-header">
            <h3 class="pw-card-title">🐛 PassWall 3 Beta - Error Report</h3>
          </div>
          <div class="pw-card-body">
            <div class="pw-alert pw-alert-info mb-4">
              <div class="pw-alert-content">
                <div class="pw-alert-description">
                  PassWall 3 is in beta. Errors are automatically logged for debugging.
                  You can export or share these logs with developers.
                </div>
              </div>
            </div>

            <div class="mb-4">
              <div class="flex items-center justify-between mb-2">
                <span class="font-semibold">Logged Errors: ${this.errorQueue.length}</span>
                <div class="flex gap-2">
                  <button class="pw-btn pw-btn-sm pw-btn-primary" onclick="PW3ErrorReporter.exportErrors()">
                    📥 Export
                  </button>
                  <button class="pw-btn pw-btn-sm pw-btn-ghost" onclick="PW3ErrorReporter.clearErrors()">
                    🗑️ Clear
                  </button>
                </div>
              </div>
            </div>

            <div class="space-y-2" style="max-height: 400px; overflow-y: auto;">
              ${this.errorQueue.slice().reverse().map((error, index) => `
                <div class="p-3 bg-secondary rounded">
                  <div class="flex items-start justify-between mb-2">
                    <span class="text-sm font-semibold">${error.type}</span>
                    <span class="text-xs text-muted">${new Date(error.timestamp).toLocaleString()}</span>
                  </div>
                  <div class="text-sm mb-1">${error.message || 'No message'}</div>
                  ${error.file ? `<div class="text-xs text-muted">File: ${error.file}:${error.line}:${error.column}</div>` : ''}
                  ${error.stack ? `
                    <details class="mt-2">
                      <summary class="text-xs cursor-pointer">Stack Trace</summary>
                      <pre class="text-xs mt-1 p-2 bg-primary rounded overflow-x-auto">${error.stack}</pre>
                    </details>
                  ` : ''}
                </div>
              `).join('')}
            </div>

            ${this.errorQueue.length === 0 ? `
              <div class="text-center py-8 text-muted">
                No errors logged yet
              </div>
            ` : ''}
          </div>
          <div class="pw-card-footer">
            <button class="pw-btn pw-btn-ghost" onclick="this.closest('.pw-modal').remove()">Close</button>
          </div>
        </div>
      `;

            document.body.appendChild(panel);
        },

        // Show beta notice
        showBetaNotice: function () {
            // Check if already shown
            if (localStorage.getItem('pw3-beta-notice-shown')) {
                return;
            }

            setTimeout(() => {
                if (window.PW2Notify) {
                    window.PW2Notify.info('🚀 Welcome to PassWall 3 Beta! Errors are automatically logged for debugging.');
                }

                localStorage.setItem('pw3-beta-notice-shown', 'true');
            }, 2000);
        },

        // Check if in development
        isDevelopment: function () {
            return localStorage.getItem('pw3-debug-mode') === 'true';
        },

        // Toggle debug mode
        toggleDebugMode: function () {
            const current = this.isDevelopment();
            localStorage.setItem('pw3-debug-mode', (!current).toString());

            if (window.PW2Notify) {
                window.PW2Notify.info(`Debug mode: ${!current ? 'enabled' : 'disabled'}`);
            }
        }
    };

    // Expose to global scope
    window.PW3ErrorReporter = ErrorReporter;

    // Auto-initialize
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => ErrorReporter.init());
    } else {
        ErrorReporter.init();
    }

    // Add error report button to footer (if exists)
    window.addEventListener('load', () => {
        const footer = document.querySelector('.luci-footer') || document.querySelector('footer');
        if (footer) {
            const button = document.createElement('button');
            button.className = 'pw-btn pw-btn-sm pw-btn-ghost';
            button.style.cssText = 'position: fixed; bottom: 20px; right: 20px; z-index: 1000; opacity: 0.7;';
            button.textContent = '🐛 Beta Report';
            button.onclick = () => ErrorReporter.showErrorReport();
            button.title = 'View PassWall 3 Beta error log';
            document.body.appendChild(button);
        }
    });

})();

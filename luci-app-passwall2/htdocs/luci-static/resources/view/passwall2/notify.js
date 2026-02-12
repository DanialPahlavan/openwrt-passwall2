// PassWall2 Toast Notification System
// Lightweight vanilla JS implementation - ~5KB minified
// No dependencies, memory-efficient design

(function () {
    'use strict';

    // Notification container
    let container = null;
    const MAX_TOASTS = 3;
    const AUTO_DISMISS_TIME = 3000;

    // Initialize container on first use
    function initContainer() {
        if (container) return;

        container = document.createElement('div');
        container.id = 'pw2-toast-container';
        container.className = 'pw2-toast-container';
        document.body.appendChild(container);
    }

    // Create toast element
    function createToast(message, type, duration) {
        const toast = document.createElement('div');
        toast.className = `pw2-toast pw2-toast-${type}`;

        // Icon based on type
        const icons = {
            success: '✓',
            error: '✕',
            warning: '⚠',
            info: 'ℹ'
        };

        const icon = document.createElement('span');
        icon.className = 'pw2-toast-icon';
        icon.textContent = icons[type] || icons.info;

        const text = document.createElement('span');
        text.className = 'pw2-toast-text';
        text.textContent = message;

        toast.appendChild(icon);
        toast.appendChild(text);

        return toast;
    }

    // Show notification
    function showNotification(message, type, duration) {
        type = type || 'info';
        duration = duration || AUTO_DISMISS_TIME;

        initContainer();

        // Remove oldest toast if limit reached
        if (container.children.length >= MAX_TOASTS) {
            container.removeChild(container.firstChild);
        }

        const toast = createToast(message, type, duration);
        container.appendChild(toast);

        // Trigger animation
        setTimeout(() => toast.classList.add('pw2-toast-show'), 10);

        // Auto dismiss
        if (duration > 0) {
            setTimeout(() => dismissToast(toast), duration);
        }

        return toast;
    }

    // Dismiss toast
    function dismissToast(toast) {
        if (!toast || !toast.parentNode) return;

        toast.classList.remove('pw2-toast-show');
        toast.classList.add('pw2-toast-hide');

        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 300);
    }

    // Public API
    window.PW2Notify = {
        success: (msg, duration) => showNotification(msg, 'success', duration),
        error: (msg, duration) => showNotification(msg, 'error', duration),
        warning: (msg, duration) => showNotification(msg, 'warning', duration),
        info: (msg, duration) => showNotification(msg, 'info', duration),
        dismiss: dismissToast
    };

    // Helper for AJAX responses
    window.PW2Notify.handleResponse = function (response) {
        if (response.success) {
            this.success(response.message || 'Operation successful');
        } else {
            this.error(response.message || 'Operation failed');
        }
    };

})();

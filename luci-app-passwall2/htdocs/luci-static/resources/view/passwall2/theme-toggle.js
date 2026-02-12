/**
 * PassWall2 Dark Mode Toggle
 * Lightweight theme switcher with persistence
 */

(function () {
    'use strict';

    // Theme constants
    const THEME_KEY = 'pw2-theme';
    const THEME_AUTO = 'auto';
    const THEME_LIGHT = 'light';
    const THEME_DARK = 'dark';

    // Theme manager
    const ThemeManager = {
        // Get current theme from localStorage
        getCurrentTheme: function () {
            return localStorage.getItem(THEME_KEY) || THEME_AUTO;
        },

        // Set theme
        setTheme: function (theme) {
            localStorage.setItem(THEME_KEY, theme);
            this.applyTheme(theme);
        },

        // Apply theme to document
        applyTheme: function (theme) {
            const root = document.documentElement;

            // Remove existing theme classes
            root.classList.remove('light-mode', 'dark-mode');

            if (theme === THEME_LIGHT) {
                root.classList.add('light-mode');
            } else if (theme === THEME_DARK) {
                root.classList.add('dark-mode');
            }
            // For 'auto', let CSS prefers-color-scheme handle it

            // Dispatch event for other components
            window.dispatchEvent(new CustomEvent('themechange', { detail: { theme } }));
        },

        // Toggle between light/dark/auto
        cycleTheme: function () {
            const current = this.getCurrentTheme();
            let next;

            switch (current) {
                case THEME_AUTO:
                    next = THEME_LIGHT;
                    break;
                case THEME_LIGHT:
                    next = THEME_DARK;
                    break;
                case THEME_DARK:
                    next = THEME_AUTO;
                    break;
                default:
                    next = THEME_AUTO;
            }

            this.setTheme(next);
            return next;
        },

        // Get system preference
        getSystemPreference: function () {
            return window.matchMedia('(prefers-color-scheme: dark)').matches ? THEME_DARK : THEME_LIGHT;
        },

        // Initialize theme on page load
        init: function () {
            this.applyTheme(this.getCurrentTheme());

            // Listen for system theme changes
            window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
                if (this.getCurrentTheme() === THEME_AUTO) {
                    this.applyTheme(THEME_AUTO);
                }
            });
        }
    };

    // Create toggle button
    function createToggleButton() {
        const button = document.createElement('button');
        button.id = 'pw-theme-toggle';
        button.className = 'pw-btn pw-btn-ghost pw-btn-icon';
        button.title = 'Toggle theme';
        button.setAttribute('aria-label', 'Toggle theme');

        updateButtonIcon(button);

        button.addEventListener('click', function () {
            ThemeManager.cycleTheme();
            updateButtonIcon(button);
        });

        return button;
    }

    // Update button icon based on current theme
    function updateButtonIcon(button) {
        const theme = ThemeManager.getCurrentTheme();
        let icon;

        switch (theme) {
            case THEME_AUTO:
                icon = '🌓'; // Half moon (auto)
                button.title = 'Theme: Auto (click for Light)';
                break;
            case THEME_LIGHT:
                icon = '☀️'; // Sun
                button.title = 'Theme: Light (click for Dark)';
                break;
            case THEME_DARK:
                icon = '🌙'; // Moon
                button.title = 'Theme: Dark (click for Auto)';
                break;
        }

        button.innerHTML = icon;
    }

    // Add toggle button to page
    function addToggleButton() {
        // Wait for DOM to be ready
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', addToggleButton);
            return;
        }

        // Try to find header or create a container
        let container = document.querySelector('.luci-brand') ||
            document.querySelector('header') ||
            document.querySelector('.header');

        if (!container) {
            // Create floating button if no header found
            const floatingBtn = createToggleButton();
            floatingBtn.style.cssText = `
        position: fixed;
        top: 1rem;
        right: 1rem;
        z-index: 9999;
        background: var(--bg-primary);
        border: 1px solid var(--border-color);
        box-shadow: var(--shadow-md);
      `;
            document.body.appendChild(floatingBtn);
        } else {
            const toggleBtn = createToggleButton();
            container.appendChild(toggleBtn);
        }
    }

    // Expose to global scope
    window.PW2Theme = ThemeManager;

    // Initialize immediately
    ThemeManager.init();

    // Add toggle button when DOM is ready
    addToggleButton();

    // Add CSS for toggle button positioning
    const style = document.createElement('style');
    style.textContent = `
    #pw-theme-toggle {
      margin-left: auto;
      font-size: 1.25rem;
      transition: transform var(--transition-fast);
    }
    
    #pw-theme-toggle:hover {
      transform: rotate(20deg) scale(1.1);
    }
    
    #pw-theme-toggle:active {
      transform: rotate(20deg) scale(0.95);
    }

    /* Smooth theme transitions */
    body,
    .pw-card,
    .pw-btn,
    .pw-input,
    .pw-select {
      transition: background-color var(--transition-base), 
                  color var(--transition-base),
                  border-color var(--transition-base);
    }
  `;
    document.head.appendChild(style);

})();

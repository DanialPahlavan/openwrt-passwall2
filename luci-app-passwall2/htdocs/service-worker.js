/**
 * PassWall2 Service Worker
 * PWA support with offline caching and background sync
 */

const CACHE_NAME = 'passwall2-v1.0';
const RUNTIME_CACHE = 'passwall2-runtime';

// Assets to cache immediately
const PRECACHE_ASSETS = [
    '/cgi-bin/luci/admin/services/passwall2',
    '/luci-static/resources/view/passwall2/design-system.css',
    '/luci-static/resources/view/passwall2/components.css',
    '/luci-static/resources/view/passwall2/notify.css',
    '/luci-static/resources/view/passwall2/tooltips.css',
    '/luci-static/resources/view/passwall2/notify.js',
    '/luci-static/resources/view/passwall2/theme-toggle.js',
    '/luci-static/resources/view/passwall2/status-dashboard.js',
    '/luci-static/resources/view/passwall2/node-list-enhanced.js',
    '/luci-static/resources/view/passwall2/bandwidth-chart.js',
    '/manifest.json'
];

// Install event - cache assets
self.addEventListener('install', (event) => {
    console.log('[SW] Installing service worker...');

    event.waitUntil(
        caches.open(CACHE_NAME)
            .then((cache) => {
                console.log('[SW] Precaching assets');
                return cache.addAll(PRECACHE_ASSETS);
            })
            .then(() => self.skipWaiting())
    );
});

// Activate event - clean old caches
self.addEventListener('activate', (event) => {
    console.log('[SW] Activating service worker...');

    event.waitUntil(
        caches.keys()
            .then((cacheNames) => {
                return Promise.all(
                    cacheNames.map((cacheName) => {
                        if (cacheName !== CACHE_NAME && cacheName !== RUNTIME_CACHE) {
                            console.log('[SW] Deleting old cache:', cacheName);
                            return caches.delete(cacheName);
                        }
                    })
                );
            })
            .then(() => self.clients.claim())
    );
});

// Fetch event - serve from cache, fallback to network
self.addEventListener('fetch', (event) => {
    const { request } = event;
    const url = new URL(request.url);

    // Skip non-GET requests
    if (request.method !== 'GET') {
        return;
    }

    // Skip external requests
    if (url.origin !== location.origin) {
        return;
    }

    // API requests - network first, cache fallback
    if (url.pathname.includes('/cgi-bin/luci/')) {
        event.respondWith(
            fetch(request)
                .then((response) => {
                    // Clone response and cache it
                    const responseClone = response.clone();
                    caches.open(RUNTIME_CACHE).then((cache) => {
                        cache.put(request, responseClone);
                    });
                    return response;
                })
                .catch(() => {
                    // Fallback to cache
                    return caches.match(request);
                })
        );
        return;
    }

    // Static assets - cache first, network fallback
    event.respondWith(
        caches.match(request)
            .then((cachedResponse) => {
                if (cachedResponse) {
                    return cachedResponse;
                }

                return fetch(request).then((response) => {
                    // Don't cache if not successful
                    if (!response || response.status !== 200 || response.type === 'error') {
                        return response;
                    }

                    // Clone and cache
                    const responseClone = response.clone();
                    caches.open(RUNTIME_CACHE).then((cache) => {
                        cache.put(request, responseClone);
                    });

                    return response;
                });
            })
            .catch(() => {
                // Return offline page for navigation requests
                if (request.mode === 'navigate') {
                    return caches.match('/offline.html');
                }
            })
    );
});

// Background sync for offline actions
self.addEventListener('sync', (event) => {
    console.log('[SW] Background sync:', event.tag);

    if (event.tag === 'sync-nodes') {
        event.waitUntil(syncNodes());
    }

    if (event.tag === 'sync-stats') {
        event.waitUntil(syncStats());
    }
});

// Push notification support
self.addEventListener('push', (event) => {
    console.log('[SW] Push notification received');

    const options = {
        body: event.data ? event.data.text() : 'PassWall 2 notification',
        icon: '/luci-static/resources/view/passwall2/icons/icon-192.png',
        badge: '/luci-static/resources/view/passwall2/icons/badge-72.png',
        vibrate: [200, 100, 200],
        data: {
            dateOfArrival: Date.now(),
            primaryKey: 1
        },
        actions: [
            {
                action: 'view',
                title: 'View',
                icon: '/luci-static/resources/view/passwall2/icons/view-icon.png'
            },
            {
                action: 'close',
                title: 'Close',
                icon: '/luci-static/resources/view/passwall2/icons/close-icon.png'
            }
        ]
    };

    event.waitUntil(
        self.registration.showNotification('PassWall 2', options)
    );
});

// Notification click handler
self.addEventListener('notificationclick', (event) => {
    console.log('[SW] Notification clicked:', event.action);

    event.notification.close();

    if (event.action === 'view') {
        event.waitUntil(
            clients.openWindow('/cgi-bin/luci/admin/services/passwall2')
        );
    }
});

// Helper: Sync nodes
async function syncNodes() {
    try {
        // Get pending node changes from IndexedDB
        // Send to server
        // Clear pending changes
        console.log('[SW] Syncing nodes...');
        return Promise.resolve();
    } catch (error) {
        console.error('[SW] Node sync failed:', error);
        return Promise.reject(error);
    }
}

// Helper: Sync stats
async function syncStats() {
    try {
        const response = await fetch('/cgi-bin/luci/admin/services/passwall2/get_stats');
        if (response.ok) {
            const data = await response.json();
            // Store in cache for offline access
            const cache = await caches.open(RUNTIME_CACHE);
            await cache.put('/api/stats', new Response(JSON.stringify(data)));
        }
        return Promise.resolve();
    } catch (error) {
        console.error('[SW] Stats sync failed:', error);
        return Promise.reject(error);
    }
}

// Message handler
self.addEventListener('message', (event) => {
    console.log('[SW] Message received:', event.data);

    if (event.data && event.data.type === 'SKIP_WAITING') {
        self.skipWaiting();
    }

    if (event.data && event.data.type === 'CLEAR_CACHE') {
        event.waitUntil(
            caches.keys().then((cacheNames) => {
                return Promise.all(
                    cacheNames.map((cacheName) => caches.delete(cacheName))
                );
            })
        );
    }
});

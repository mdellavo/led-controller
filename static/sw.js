// Pass-through service worker — no caching.
// Exists solely to satisfy Chrome's PWA installability requirement.
// All fetches go to the network so live LED state is never stale.

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (e) => e.waitUntil(self.clients.claim()));
self.addEventListener('fetch', (e) => e.respondWith(fetch(e.request)));

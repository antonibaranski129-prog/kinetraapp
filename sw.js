const V='plyotic-v48',SHELL=['./','index.html','manifest.webmanifest','icon-192.png','icon-512.png','icon-maskable-512.png','apple-touch-icon.png','config.js'];
self.addEventListener('install',e=>{e.waitUntil(caches.open(V).then(c=>c.addAll(SHELL)).then(()=>self.skipWaiting()))});
self.addEventListener('activate',e=>{e.waitUntil(caches.keys().then(k=>Promise.all(k.filter(x=>x!==V).map(x=>caches.delete(x)))).then(()=>self.clients.claim()))});
self.addEventListener('fetch',e=>{const r=e.request;if(r.method!=='GET')return;const u=new URL(r.url);
 if(u.origin===location.origin){e.respondWith(caches.match(r).then(h=>{const f=fetch(r).then(n=>{if(n.ok)caches.open(V).then(c=>c.put(r,n.clone()));return n}).catch(()=>h||caches.match('index.html'));return h||f}));return}
 if(/fonts\.(googleapis|gstatic)\.com$/.test(u.host)){e.respondWith(caches.open(V).then(c=>c.match(r).then(h=>{const f=fetch(r).then(n=>{c.put(r,n.clone());return n}).catch(()=>h);return h||f})))}});

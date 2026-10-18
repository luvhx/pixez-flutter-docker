#!/usr/bin/env node
/**
 * Local test server that mimics deploy/nginx.conf:
 * serves build/web and proxies the Pixiv endpoints with the required
 * Host / Referer headers.
 */
const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '../build/web');
const PORT = Number(process.env.PORT || 8099);

const PROXIES = [
  ['/pixiv-api', 'app-api.pixiv.net', 'https://www.pixiv.net/'],
  ['/pixiv-oauth', 'oauth.secure.pixiv.net', 'https://www.pixiv.net/'],
  ['/pixiv-accounts', 'accounts.pixiv.net', 'https://www.pixiv.net/'],
  ['/pixiv-web', 'www.pixiv.net', 'https://www.pixiv.net/'],
  ['/pximg', 'i.pximg.net', 'https://www.pixiv.net/'],
  ['/spximg', 's.pximg.net', 'https://www.pixiv.net/'],
  ['/pixivision', 'www.pixivision.net', 'https://www.pixivision.net/'],
  ['/saucenao', 'saucenao.com', 'https://saucenao.com/'],
];

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.map': 'application/json',
};

function proxy(req, res, prefix, host, referer) {
  const targetPath = req.url.slice(prefix.length) || '/';
  const headers = {
    ...req.headers,
    host,
    referer,
    origin: '',
    'user-agent': 'PixivAndroidApp/5.0.166 (Android 10.0; Pixel C)',
  };
  // Same mapping as deploy/nginx.conf: the web app sends the Pixiv token in
  // X-Pixiv-Authorization so that HTTP Basic Auth can own Authorization.
  if (headers['x-pixiv-authorization']) {
    headers.authorization = headers['x-pixiv-authorization'];
  } else {
    delete headers.authorization;
  }
  delete headers['x-pixiv-authorization'];
  delete headers.connection;
  delete headers['content-length'];
  delete headers['accept-encoding'];

  const upstream = https.request(
    {
      host,
      path: targetPath,
      method: req.method,
      headers,
      servername: host,
      timeout: 60000,
    },
    (up) => {
      res.writeHead(up.statusCode || 502, up.headers);
      up.pipe(res);
    }
  );
  upstream.on('error', (e) => {
    res.writeHead(502, { 'content-type': 'text/plain' });
    res.end('proxy error: ' + e.message);
  });
  upstream.on('timeout', () => upstream.destroy(new Error('timeout')));
  req.pipe(upstream);
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://localhost');
  const match = PROXIES.find(([prefix]) => url.pathname.startsWith(prefix + '/'));
  if (match) {
    proxy(req, res, match[0], match[1], match[2]);
    return;
  }
  if (url.pathname === '/healthz') {
    res.writeHead(200, { 'content-type': 'text/plain' });
    res.end('ok\n');
    return;
  }

  let filePath = path.join(ROOT, decodeURIComponent(url.pathname));
  if (!filePath.startsWith(ROOT)) {
    res.writeHead(403);
    res.end();
    return;
  }
  if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
    filePath = path.join(ROOT, 'index.html');
  }
  const ext = path.extname(filePath).toLowerCase();
  const cache =
    ext === '.html' || filePath.endsWith('flutter_service_worker.js')
      ? 'no-store'
      : 'public, max-age=3600';
  fs.createReadStream(filePath)
    .on('error', () => {
      res.writeHead(404);
      res.end('not found');
    })
    .pipe(
      res.writeHead(200, {
        'content-type': MIME[ext] || 'application/octet-stream',
        'cache-control': cache,
      })
    );
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`PixEz test server: http://127.0.0.1:${PORT}/`);
  console.log(`Serving ${ROOT}`);
});

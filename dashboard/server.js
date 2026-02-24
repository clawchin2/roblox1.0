const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// === CONFIG ===
const PORT = 8420;
const TOKEN = crypto.randomBytes(16).toString('hex');

const MIME = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
};

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  
  // Token auth via query param: ?token=xxx
  if (url.searchParams.get('token') !== TOKEN) {
    res.writeHead(401, { 'Content-Type': 'text/html' });
    res.end('<h1>401 — Unauthorized</h1><p>Add ?token=YOUR_TOKEN to the URL</p>');
    return;
  }

  let filePath = url.pathname === '/' ? '/index.html' : url.pathname;
  filePath = path.join(__dirname, filePath);

  // Prevent directory traversal
  if (!filePath.startsWith(__dirname)) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404, { 'Content-Type': 'text/html' });
      res.end('<h1>404</h1>');
      return;
    }
    const ext = path.extname(filePath);
    res.writeHead(200, { 'Content-Type': MIME[ext] || 'text/plain' });
    res.end(data);
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`\n🎮 Chin2.0 Dashboard running!`);
  console.log(`   Local:  http://localhost:${PORT}/?token=${TOKEN}`);
  console.log(`   Public: http://187.77.220.28:${PORT}/?token=${TOKEN}\n`);
});

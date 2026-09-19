// Minimal static file server for `build/web` — used only to visually
// verify a production Flutter web build in the Browser pane, sidestepping
// the DDC/dwds debug-mode module loader (see dev notes: it can hang in a
// headless browser without the Dart Debug Chrome extension).
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');

const root = path.join(__dirname, '..', 'build', 'web');
const port = process.env.PORT ? Number(process.env.PORT) : 8766;

const mime = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.css': 'text/css',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff2': 'font/woff2',
};

http
  .createServer((req, res) => {
    let filePath = path.join(root, decodeURIComponent(req.url.split('?')[0]));
    if (req.url === '/' || !fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
      filePath = path.join(root, 'index.html');
    }
    const ext = path.extname(filePath);
    fs.readFile(filePath, (err, data) => {
      if (err) {
        res.writeHead(404);
        res.end('Not found');
        return;
      }
      res.writeHead(200, { 'Content-Type': mime[ext] || 'application/octet-stream' });
      res.end(data);
    });
  })
  .listen(port, () => {
    console.log(`Serving build/web on http://localhost:${port}`);
  });

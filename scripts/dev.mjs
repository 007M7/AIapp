#!/usr/bin/env node
/**
 * 本地开发服务器 —— 用来在浏览器里点原型(不需要任何依赖)。
 * 用法:node scripts/dev.mjs [端口]    (或 npm run dev)
 * 默认 5173;启动后打开 http://127.0.0.1:5173/
 */
import { createServer } from "node:http";
import { readFile, stat } from "node:fs/promises";
import { join, extname, resolve, dirname, normalize } from "node:path";
import { fileURLToPath } from "node:url";
import { createPilotProxy, loadPilotConnection } from './device-pilot-proxy.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const PORT = Number(process.argv[2] || process.env.PORT || 5173);
const pilotConnection = await loadPilotConnection(process.env.DEVICE_PILOT_CONNECTION_FILE);
const pilotProxy = createPilotProxy(pilotConnection, {port: PORT});
const TYPES = {
  ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8", ".json": "application/json; charset=utf-8",
  ".css": "text/css; charset=utf-8", ".png": "image/png", ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg", ".svg": "image/svg+xml", ".md": "text/markdown; charset=utf-8",
};

createServer(async (req, res) => {
  try {
    if (await pilotProxy(req, res)) return;
    let p = decodeURIComponent(new URL(req.url, "http://x").pathname);
    if (p === "/") p = "/prototype/index.html";
    const file = normalize(join(ROOT, p));
    if (file !== ROOT && !file.startsWith(ROOT + (process.platform === 'win32' ? '\\' : '/'))) { res.writeHead(403).end("forbidden"); return; }
    const st = await stat(file);
    if (st.isDirectory()) { res.writeHead(302, { Location: p + "/index.html" }).end(); return; }
    res.writeHead(200, { "Content-Type": TYPES[extname(file)] || "application/octet-stream", "Cache-Control": "no-store" });
    res.end(await readFile(file));
  } catch {
    res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" }).end("404 —— 路径不存在");
  }
}).listen(PORT, "127.0.0.1", () => {
  console.log(`\n本地预览已启动:\n  http://127.0.0.1:${PORT}/                ← 交互原型(index.html)\n  http://127.0.0.1:${PORT}/prototype/overview.html   ← 8 屏总览\n  http://127.0.0.1:${PORT}/prototype/pages/hand_today.html  ← 单页\n\nCtrl+C 退出\n`);
});

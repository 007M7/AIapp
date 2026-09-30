#!/usr/bin/env node
/**
 * 本地出图 —— 把 prototype/pages/*.html 用无头浏览器截成 PNG(2 倍分辨率)。
 * 用法:node scripts/shots.mjs    (或 npm run shots)
 *
 * 为什么是脚本而不是 CI:截图依赖本机浏览器与字体,不适合放在云端跑。
 * 找不到浏览器时会**明确说明并跳过**,不静默失败。
 * 可用环境变量 CHROME_PATH 指定浏览器可执行文件。
 */
import { existsSync, readdirSync } from "node:fs";
import { join, resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const PAGES = join(ROOT, "prototype/pages");

const CANDIDATES = [
  process.env.CHROME_PATH,
  "C:/Program Files/Google/Chrome/Application/chrome.exe",
  "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  "/usr/bin/google-chrome", "/usr/bin/chromium", "/usr/bin/chromium-browser",
].filter(Boolean);
const chrome = CANDIDATES.find((p) => existsSync(p));

if (!chrome) {
  console.error("未找到浏览器。请设置 CHROME_PATH 指向 Chrome/Edge 可执行文件后重试。\n已尝试:\n  " + CANDIDATES.join("\n  "));
  process.exit(2);
}

const pages = readdirSync(PAGES).filter((f) => f.endsWith(".html"));
console.log(`浏览器:${chrome}\n准备渲染 ${pages.length} 个页面(390×900 @2×)…`);
let failed = 0;
for (const f of pages) {
  const out = join(ROOT, "prototype", f.replace(/\.html$/, ".png"));
  const r = spawnSync(chrome, [
    "--headless=new", "--disable-gpu", "--hide-scrollbars",
    "--force-device-scale-factor=2", "--window-size=390,900",
    "--virtual-time-budget=3000", `--screenshot=${out}`,
    `file://${join(PAGES, f)}`,
  ], { stdio: "ignore" });
  if (r.status !== 0 || !existsSync(out)) { console.error(`  ✘ ${f}`); failed++; }
  else process.stdout.write(".");
}
console.log(`\n完成:${pages.length - failed} 成功 / ${failed} 失败`);
process.exit(failed ? 1 : 0);

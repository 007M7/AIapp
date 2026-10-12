#!/usr/bin/env node
/**
 * 本地 CI —— 不需要 GitHub Actions,全部在本机跑。
 * 用法:node scripts/check.mjs    (或 npm run check)
 *
 * 退出码:0 = 全部通过;1 = 有失败项(推送前必须修)。
 * 设计原则:每条检查都必须**真的能失败**,不写永远通过的占位检查。
 */
import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join, resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const results = [];
const ok = (name, detail = "") => results.push({ name, ok: true, detail });
const warn = (name, detail = "") => results.push({ name, ok: true, level: "warn", detail });
const bad = (name, detail = "") => results.push({ name, ok: false, detail });

/* ---------- 0. 结构检查 ---------- */
const REQUIRED = [
  "README.md",
  "CONTRIBUTING.md",
  "package.json",
  "miniprogram/app.json",
  "miniprogram/project.config.json",
  "prototype/index.html",
  "prototype/pages",
  "prototype/src/build-app.mjs",
  "prototype/src/core.mjs",
  "docs/19-miniprogram-ia-prd.md",
  "docs/CONTENT.md",
  "ios/project.yml",
  ".github/workflows/ios-unsigned.yml",
  "ios/AIFigure/Info.plist",
  "ios/README.md",
];
{
  const missing = REQUIRED.filter((p) => !existsSync(join(ROOT, p)));
  missing.length ? bad("结构:必需路径存在", `缺失 ${missing.join(", ")}`) : ok("结构:必需路径存在", `${REQUIRED.length} 项`);
}

/* ---------- 1. 小程序单元测试(node --test)---------- */
{
  // 用 glob 而不是目录:Windows 上 `node --test <目录>/` 会报 MODULE_NOT_FOUND(实际踩过)。
  // 只匹配 *.test.js,避免把 test/mock_device.js 这种辅助文件当测试跑。
  const t = spawnSync(process.execPath, ["--test", "miniprogram/test/*.test.js"], { cwd: ROOT, encoding: "utf8", shell: false });
  const out = (t.stdout || "") + (t.stderr || "");
  const grab = (k) => { const m = new RegExp(`(?:^|\\n)(?:# |ℹ )${k} (\\d+)`).exec(out); return m?.[1]; };
  const pass = grab("pass"), fail = grab("fail");
  if (t.status === 0) ok("小程序:单元测试", `pass ${pass ?? "?"}`);
  else bad("小程序:单元测试", `fail ${fail ?? "?"} / 退出码 ${t.status}\n${out.split("\n").slice(-14).join("\n")}`);
}

/* ---------- 2. 小程序:每个 JS 语法可解析 ---------- */
{
  const files = [];
  (function walk(d) {
    for (const e of readdirSync(d, { withFileTypes: true })) {
      const p = join(d, e.name);
      if (e.isDirectory()) walk(p);
      else if (e.name.endsWith(".js")) files.push(p);
    }
  })(join(ROOT, "miniprogram"));
  const badFiles = files.filter((f) => spawnSync(process.execPath, ["--check", f], { encoding: "utf8" }).status !== 0);
  badFiles.length ? bad("小程序:JS 语法", badFiles.map((f) => f.replace(ROOT, "")).join(", ")) : ok("小程序:JS 语法", `${files.length} 个文件`);
}

/* ---------- 3. 小程序:appid(上线门禁,未上线前只警告)---------- */
{
  const cfg = JSON.parse(readFileSync(join(ROOT, "miniprogram/project.config.json"), "utf8"));
  const id = String(cfg.appid ?? "");
  id === "touristappid" || id === ""
    ? warn("小程序:appid 已替换", `当前为占位符「${id || "空"}」—— 正式注册后必须替换(见 docs/19 §5.4);这是**上线门禁**,未上线前不阻断提交`)
    : ok("小程序:appid 已替换", id);
}

/* ---------- 4. 原型:页面与路由一致性 ---------- */
const pagesDir = join(ROOT, "prototype/pages");
const pageFiles = existsSync(pagesDir) ? readdirSync(pagesDir).filter((f) => f.endsWith(".html")) : [];
const indexHtml = readFileSync(join(ROOT, "prototype/index.html"), "utf8");
// 先剥掉 <script>(里面的选择器字面量也会命中 data-page="…",实际踩过),再取唯一 id
const indexHtmlNoScript = indexHtml.replace(/<script[\s\S]*?<\/script>/g, "");
const templateIds = [...new Set([...indexHtmlNoScript.matchAll(/data-page="([^"]+)"/g)].map((m) => m[1]))];
{
  const n = pageFiles.length;
  n >= 30 ? ok("原型:页面数", `${n} 个独立页`) : bad("原型:页面数", `只有 ${n} 个,期望 ≥30`);
  const mismatch = n !== templateIds.length;
  mismatch
    ? bad("原型:独立页与路由模板一一对应", `pages=${n} / templates=${templateIds.length}`)
    : ok("原型:独立页与路由模板一一对应", `${n} ↔ ${templateIds.length}`);
}

/* ---------- 5. 原型:站内链接不悬空 ---------- */
{
  const ids = new Set(templateIds);
  const broken = [];
  for (const f of pageFiles) {
    const html = readFileSync(join(pagesDir, f), "utf8");
    for (const m of html.matchAll(/href="#\/([^"]*)"/g)) {
      const target = m[1] || "hand/today";
      if (!ids.has(target)) broken.push(`${f} → #/${target}`);
    }
  }
  broken.length ? bad("原型:站内链接", broken.slice(0, 8).join("; ")) : ok("原型:站内链接", "无悬空");
}

/* ---------- 6. 文案:禁用词扫描(规范见 docs/CONTENT.md §2)---------- */
const BANNED = [
  "智能对话", "AI 陪伴", "情感陪伴", "永久在线", "永久可用", "角色永不消失",
  "别离开我", "只有我懂你", "比真人", "流畅对话", "实时通话",
  "好感度", "亲密度", "进度条", "成长值",
];
const WHITELIST = ["陪伴计数"]; // 承诺文本里的功能名(docs/17 §3.4),不是主话术
{
  const hits = [];
  const scanOne = (path, text) => {
    let t = text;
    for (const w of WHITELIST) t = t.split(w).join("　"); // 白名单先抠掉
    for (const w of BANNED) if (t.includes(w)) hits.push(`${path} → 「${w}」`);
  };
  for (const f of pageFiles) scanOne(`pages/${f}`, readFileSync(join(pagesDir, f), "utf8"));
  scanOne("index.html", indexHtml);
  for (const f of iosSwiftFiles()) scanOne(`ios/${f.replace(ROOT, "")}`, readFileSync(f, "utf8"));
  hits.length ? bad("文案:禁用词", hits.slice(0, 8).join("; ")) : ok("文案:禁用词", `扫描 ${BANNED.length} 个词,0 命中`);
}

// 收集 ios/ 下全部 .swift(selftest 与源码一并扫)
function iosSwiftFiles() {
  const out = [];
  const iosDir = join(ROOT, "ios");
  if (!existsSync(iosDir)) return out;
  (function walk(d) {
    for (const e of readdirSync(d, { withFileTypes: true })) {
      const p = join(d, e.name);
      if (e.isDirectory()) walk(p);
      else if (e.name.endsWith(".swift")) out.push(p);
    }
  })(iosDir);
  return out;
}

/* ---------- 7. 安全:密钥 / 生产信息扫描 ---------- */
const SECRET_PATTERNS = [
  [/sk-[A-Za-z0-9]{16,}/, "疑似 API key(sk-)"],
  [/gho_[A-Za-z0-9]{20,}/, "疑似 GitHub token(gho_)"],
  [/BEGIN [A-Z ]*PRIVATE KEY/, "私钥材料"],
  [/172\.245\.\d+\.\d+/, "真实生产 IP"],
  [/(DASHSCOPE|DEEPSEEK|OPENAI)_API_KEY\s*=\s*["'][^"']+["']/, "环境变量里写了真实 key"],
];
{
  const hits = [];
  (function walk(d) {
    for (const e of readdirSync(d, { withFileTypes: true })) {
      if ([".git", "node_modules", ".venv"].includes(e.name)) continue;
      if (d === join(ROOT, "admin") && e.name === "data") continue;
      const p = join(d, e.name);
      if (e.isDirectory()) walk(p);
      else if (/\.(js|json|wxml|wxss|html|md|mjs|conf|example|service|txt|swift|plist|pbxproj)$/.test(e.name)) {
        const t = readFileSync(p, "utf8");
        for (const [re, label] of SECRET_PATTERNS) if (re.test(t)) hits.push(`${p.replace(ROOT, "")} → ${label}`);
      }
    }
  })(ROOT);
  hits.length ? bad("安全:密钥/生产信息", hits.slice(0, 8).join("; ")) : ok("安全:密钥/生产信息", `${SECRET_PATTERNS.length} 类模式,0 命中`);
}

/* ---------- 8. 原型:截图非空 ---------- */
{
  const pngs = readdirSync(join(ROOT, "prototype")).filter((f) => f.endsWith(".png"));
  const empty = pngs.filter((f) => statSync(join(ROOT, "prototype", f)).size < 1024);
  !pngs.length ? bad("原型:截图", "一张都没有") :
   empty.length ? bad("原型:截图", `空文件:${empty.join(", ")}`) :
   ok("原型:截图", `${pngs.length} 张,均非空`);
}

/* ---------- 9. 文档快照与主仓一致性(仅当本机同时存在主仓时)---------- */
{
  const MAIN = resolve(ROOT, "../AI_figure");
  const PAIRS = [
    ["docs/09-issue-list.md", "docs/product/09-issue-list.md"],
    ["docs/18-firmware-key-semantics-req.md", "docs/product/18-firmware-key-semantics-req.md"],
    ["docs/21-mobile-product-baseline.md", "docs/product/21-mobile-product-baseline.md"],
    ["docs/22-wechat-miniprogram-prd.md", "docs/product/22-wechat-miniprogram-prd.md"],
    ["docs/23-android-ios-app-prd.md", "docs/product/23-android-ios-app-prd.md"],
    ["docs/app-frontend-content-plan.md", "docs/product/app-frontend-content-plan.md"],
    ["docs/app-todo.md", "docs/product/app-todo.md"],
    ["docs/app-first-character-content.md", "docs/product/app-first-character-content.md"],
    ["docs/app-play-reference.md", "docs/product/app-play-reference.md"],
    ["docs/app-play-design-v0.1.md", "docs/product/app-play-design-v0.1.md"],
    ["docs/app-foundation-research-execution.md", "docs/product/app-foundation-research-execution.md"],
    ["docs/admin-management-prd.md", "docs/product/admin-management-prd.md"],
    ["docs/14-miniprogram-server-design.md", "docs/product/14-miniprogram-server-design.md"],
    ["docs/19-miniprogram-ia-prd.md", "docs/product/19-miniprogram-ia-prd.md"],
    ["docs/20-asset-and-art-inventory.md", "docs/product/20-asset-and-art-inventory.md"],
    ["docs/CONTENT.md", "docs/product/mockups/app/CONTENT.md"],
    ["docs/PROMPTS.md", "docs/product/mockups/PROMPTS.md"],
    ["docs/PROMPTS-ASSETS.md", "docs/product/mockups/PROMPTS-ASSETS.md"],
    ["docs/PROMPTS-v2-maid.md", "docs/product/mockups/PROMPTS-v2-maid.md"],
  ];
  if (!existsSync(MAIN)) {
    warn("文档快照:与主仓一致", "未发现主仓 ../AI_figure,已跳过(只克隆本仓时正常)");
  } else {
    const norm = (p) => readFileSync(p, "utf8").replace(/\r\n/g, "\n").trim();
    const drift = [];
    for (const [mine, theirs] of PAIRS) {
      const a = join(ROOT, mine), b = join(MAIN, theirs);
      if (!existsSync(a) || !existsSync(b) || norm(a) !== norm(b)) drift.push(mine);
    }
    drift.length
      ? bad("文档快照:与主仓一致", `已漂移:${drift.join(", ")} —— 从主仓重新复制,或确认是否该改主仓(见 docs/SNAPSHOT.md)`)
      : ok("文档快照:与主仓一致", `${PAIRS.length} 份`);
  }
}

/* ---------- 10. iOS:工程与源码一致性(XcodeGen 单源,同 jev 范式)---------- */
{
  const swifts = iosSwiftFiles();
  const yml = readFileSync(join(ROOT, "ios/project.yml"), "utf8");
  const plist = readFileSync(join(ROOT, "ios/AIFigure/Info.plist"), "utf8");
  const wf = readFileSync(join(ROOT, ".github/workflows/ios-unsigned.yml"), "utf8");
  const problems = [];

  if (!/^name: AIFigure/m.test(yml)) problems.push("project.yml 缺 name: AIFigure");
  if (!/iOS:\s*"16\.0"/.test(yml)) problems.push("project.yml 缺 deploymentTarget iOS 16.0");
  if (!/NSBluetoothAlwaysUsageDescription/.test(plist)) problems.push("Info.plist 缺蓝牙权限文案");
  for (const [needle, label] of [
    ["macos-15", "稳定镜像(不用 xcode-27 preview,排队坑见 jev)"],
    ["xcodegen", "XcodeGen 生成"],
    ["CODE_SIGNING_ALLOWED=NO", "未签名编译"],
    ["AIFigure-unsigned", "ipa 命名"],
  ]) {
    if (!wf.includes(needle)) problems.push(`workflow 缺 ${label}(${needle})`);
  }
  if (swifts.length < 25) problems.push(`swift 源文件只有 ${swifts.length} 个,疑似目录被清空`);

  problems.length
    ? bad("iOS:工程与源码一致性", problems.join("; "))
    : ok("iOS:工程与源码一致性", `${swifts.length} 个 Swift 文件;project.yml/workflow/Info.plist 关键项齐`);
}

/* ---------- 输出 ---------- */
const pad = (s, n) => s + " ".repeat(Math.max(0, n - [...s].reduce((a, c) => a + (c.charCodeAt(0) > 255 ? 2 : 1), 0)));
console.log("\nAIapp 本地 CI —— node scripts/check.mjs\n" + "─".repeat(64));
for (const r of results) console.log(`${r.ok ? (r.level === "warn" ? "  ⚠" : "  ✔") : "  ✘"} ${pad(r.name, 40)} ${r.detail}`);
const failed = results.filter((r) => !r.ok);
const warned = results.filter((r) => r.ok && r.level === "warn");
console.log("─".repeat(64));
console.log(failed.length
  ? `结果:${results.length - failed.length} 通过 / ${failed.length} 失败${warned.length ? ` / ${warned.length} 警告` : ""} —— 不要推送\n`
  : `结果:全部 ${results.length} 项通过${warned.length ? `(${warned.length} 项警告,见上)` : ""}\n`);
process.exit(failed.length ? 1 : 0);

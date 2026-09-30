#!/usr/bin/env node
/**
 * 安装本地 Git 钩子 —— 让检查在提交/推送时自动跑(**这就是本地 CI 的触发点**)。
 * 用法:node scripts/install-hooks.mjs    (或 npm run install-hooks)
 */
import { spawnSync } from "node:child_process";
import { chmodSync, existsSync } from "node:fs";
import { join, resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const HOOKS = join(ROOT, ".githooks");

for (const f of ["pre-commit", "pre-push"]) {
  const p = join(HOOKS, f);
  if (existsSync(p)) { try { chmodSync(p, 0o755); } catch {} }
}

const r = spawnSync("git", ["config", "core.hooksPath", ".githooks"], { cwd: ROOT, encoding: "utf8" });
if (r.status !== 0) { console.error("设置 core.hooksPath 失败:", r.stderr); process.exit(1); }

const cur = spawnSync("git", ["config", "core.hooksPath"], { cwd: ROOT, encoding: "utf8" }).stdout.trim();
console.log(`已启用本地钩子:core.hooksPath = ${cur}\n  pre-commit → node scripts/check.mjs       (提交前,快)\n  pre-push   → node scripts/check.mjs + 重跑生成器(推送前,全)\n\n如需临时跳过:git commit --no-verify`);

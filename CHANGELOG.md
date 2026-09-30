# 变更记录(AIapp)

本仓记录手机端(小程序 + 原型 + 素材)的变更。格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)。
主仓(设备固件 / 云端服务 / 产品文档)的变更见 `AI_figure`。

## [Unreleased]

### 待办(下一轮)

- 原型**文案深度优化**:4 个 Tab 的空态文案、角色语气库(建议 20~30 句角色口吻样例,供人格卡复用)—— 见 `docs/CONTENT.md` §5
- **替换角色立绘**:当前是矢量站位稿,正式立绘按 `docs/PROMPTS-ASSETS.md` 的母版链产出后置换
- 补齐素材:表情差分、空态插画、动效(D1~D5)、社区 banner、分享卡模板(清单见 `docs/20` §3~§5)
- 小程序 **真机验收 BLE 配网**(自列 5 个未知点,iPhone 长写是最大未知);替换 `touristappid`
- 服务端接口对接(账号/设备绑定/记忆,依赖主仓 M0、`Q-22`/`Q-61`)

## 2026-09-30 —— 建仓

### Added

- **仓库建立**:从主仓 `AI_figure` 抽出手机端内容独立成仓(私有),以"小程序是额外的内容"为原则拆分:
  - `miniprogram/` —— 从主仓 `mini_program` 分支导出(19 个文件:BLS 配网 `bles/pb/prov` + X25519/AES-CTR 加密实现 + 22 个单元测试)
  - `prototype/` —— 33 页可点开的高保真原型 + 8 屏总览 + 26 张 2 倍截图 + 生成器(`src/core.mjs`、`src/build-app.mjs`)
  - `docs/` —— 主仓文档快照:PRD(19)、素材清单(20)、内容规范(CONTENT)、服务端总纲(14)、角色出图提示词(3 份)、`SNAPSHOT.md`
- **本地 CI(不使用 GitHub Actions)**:
  - `scripts/check.mjs` —— 11 项检查(结构 / 22 个单测 / JS 语法 / appid 门禁 / 页面数与路由一致性 / 站内链接 / 禁用词 / 密钥与生产信息 / 截图非空 / 文档快照一致性)
  - `scripts/dev.mjs` —— 零依赖本地预览服务器(含路径穿越防护)
  - `scripts/shots.mjs` —— 本机浏览器批量出图(找不到浏览器时明确跳过)
  - `scripts/install-hooks.mjs` + `.githooks/{pre-commit,pre-push}` —— 让检查在提交/推送时自动触发
- 仓库设施:`README.md`、`CONTRIBUTING.md`、`CHANGELOG.md`、`package.json`(零依赖)、`.editorconfig`、`.gitignore`

### Fixed

- **生成器路径解耦**:`build-app.mjs` 原先把输出目录写死为主仓路径(`D:/APP1/AI_figure/...`),改为相对脚本自身定位,使本仓可独立 `npm run build`。
- **`package.json` 不加 `"type": "module"`**:加上会把 `miniprogram/` 的 CommonJS 代码判成 ESM,导致 22 个单元测试全挂 —— 已在建仓当天实测踩到并写入注释防复犯。
- **单测调用方式**:`node --test <目录>/` 在 Windows 报 `MODULE_NOT_FOUND`,改为 glob `miniprogram/test/*.test.js`。
- **路由模板计数**:`index.html` 的内联脚本里含 `data-page="…"` 字面量,会导致"页面数 ≠ 模板数"的假报错;检查改为**先剥掉 `<script>` 再取唯一 id**。

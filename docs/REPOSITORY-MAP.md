# 仓库分类地图

2026-10-11。保留现有路径，避免破坏工程、模型 URL 与原型路由，通过入口区分内容。

## 运行代码

| 目录 | 分工 | 验证 |
|---|---|---|
| `ios/AIFigure/App/`、`Features/`、`Content/` | 原生入口、页面、状态、内容模型 | macOS 编译、安装、业务验收 |
| `ios/AIFigure/Device/`、`Audio/`、`Server/` | BLE Security 1、播放、HTTP 客户端 | 协议自测、真机及真实后端 |
| `miniprogram/` | 单页 BLE 配网与 CommonJS 协议 | 22 个单测、微信工具和真机 |
| `server/` | WebSocket、ASR/LLM/TTS 编排 | Python 语法、回声、厂商及设备联调 |
| 安卓 | 工程未建立 | 同期 MVP 是目标，尚无实现 |

设备语音服务没有 App 所需的账号、claim、设备归属及资产 HTTP API。后端设计稿与运行代码分开判断。

## 原型、产物与素材

| 路径 | 分类与管理 |
|---|---|
| `prototype/src/` | 设计工具源码，改后 `npm run build` |
| `prototype/index.html`、`overview.html`、`pages/*.html` | 生成的设计原型，已标记 Linguist generated |
| `prototype/*.png` | 评审截图；视觉改动后重新出图与验看 |
| `prototype/first-screen-ab/` | 手写首屏体验实验；尚未完整同步远端 |
| `assets/` | 本机角色图片、参考图、衍生素材；区分参考与正式交付 |
| `models/` | 本机 Blender、网格、纹理、模型导出及评审网页；未全部入 Git |
| `D:/APP1/3D素材/` | 仓外原始资源，不能当作克隆后自动存在的依赖 |

模型进入运行端前需选定版本，登记来源、尺寸预算、纹理、动画与验收；生产原稿、试验版本、运行资源分开管理。此次未移动或删除素材。

## 非代码资料

- `docs/21～23`、`14`、`19`、`CONTENT`、`app-*.md`：主仓产品定义的同步快照。
- `firmware-evaluation-request.md`、`app-device-interaction-baseline.md`：固件需求和联合联调基线。
- `docs/upstream/AGENT.md`、`SERVER.md`：固定版本上游协议与服务参考；具体部署地址已脱敏，相对路径按上游目录解释。
- 本文件、`IMPLEMENTATION-STATUS.md`：本仓工作分类和实现事实。
- `ios/docs/`：本机 iOS 专项方案和验证记录，随对应源码另行交付。
- 研究正本：AI_figure/docs/research/app-foundation/；原始数据在 D:/APP1/_research/，未整体纳入本仓。

## 构建与治理

`ios/project.yml`、`ios/tools/`、`.github/workflows/ios-unsigned.yml` 是原生构建工具；`scripts/`、`.githooks/` 是本地工具；`server/deploy/` 是部署模板。`ios/build/`、`ios/dist/`、虚拟环境、缓存、真实凭证是本机产物，不入库。

云端同步依照 `server/UPSTREAM.json` 比对差异后合并，不覆盖本仓后续业务开发。当前本机与远端状态见 [实现状态](IMPLEMENTATION-STATUS.md)。

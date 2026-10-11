# AIapp · AI 手办 App 与设备云端

私有仓 `007M7/AIapp`。2026-10-11 纳入设备语音云端源码；当前处于原生客户端骨架、网页体验原型与设备服务分别推进的阶段。

[分类地图](docs/REPOSITORY-MAP.md) · [实际实现状态](docs/IMPLEMENTATION-STATUS.md) · [产品文档](docs/README.md) · [云端服务](server/README.md)

## 按内容找入口

| 目录 | 内容与实际用途 |
|---|---|
| `ios/` | SwiftUI 原生 App、BLE、API 客户端、构建脚本；业务与真机验收待完成 |
| `miniprogram/` | 微信小程序单页 BLE 配网与协议测试 |
| `server/` | Python 设备语音服务、厂商适配、部署模板；App HTTP 业务接口尚缺 |
| `prototype/src/` | 共用网页原型生成器，设计源文件 |
| `prototype/pages/`、`index.html`、`overview.html` | 33 页原型及生成产物，设计评审用 |
| `prototype/first-screen-ab/` | 本机首屏 A/B、3D 展示实验；尚未完整同步 GitHub |
| `assets/`、`models/` | 本机角色图片、3D 工程、多轮模型评审；大型素材尚未统一入库 |
| `docs/` | PRD 快照、产品方案、设备需求、本仓状态及来源 |
| `scripts/`、`.githooks/`、`.github/` | 检查、预览、截图、构建及提交工具 |

安卓与 iPhone 同期 MVP 是产品目标；安卓尚无工程。设备固件、硬件及机械 CAD 仍在 AI_figure。

## 运行与验证

网页预览与小程序本地工具需 Node ≥ 20，无 npm 依赖：

```powershell
npm run dev
npm run check
npm run verify
npm run install-hooks
```

预览地址为 `http://127.0.0.1:5173/`。`verify` 会重新生成共用原型，生成器与产物需要一起提交。小程序使用 CommonJS，不加 `type:module`。

iOS 需 macOS/Xcode，见 [iOS 说明](ios/README.md)。Python 服务需独立虚拟环境及 `requirements.txt`，见 [服务启动说明](server/README.md)。Node 检查不能替代原生编译、云端启动或真机联调。

## HTML 为什么最多

同步前 GitHub 语言接口统计：HTML 473,313 字节（约 64.1%）、Swift 137,733、JavaScript 124,712、Shell 2,713。33 页原型重复内嵌样式与页面结构，形成大量 HTML；语言比例不代表 App 完成度。

已用 `.gitattributes` 将生成的 35 个 HTML 标记为 `linguist-generated`，设计生成器仍统计；未整体排除手写 A/B 和模型查看器。GitHub 统计更新可能延迟，此标记仅分类产物，不增加产品能力。规则见 [GitHub Linguist](https://github.com/github-linguist/linguist/blob/main/docs/overrides.md)。

## 同步边界

产品定义仍以 AI_figure 的 `docs/product/` 为正本，见 [SNAPSHOT](docs/SNAPSHOT.md)。服务来源、逐文件哈希及本仓差异见 [UPSTREAM.json](server/UPSTREAM.json)。真实凭证、运行环境、构建包不入库。

本次提交云端、文档与分类信息。此前未提交的 iOS／网页修改与大体积素材保留本机工作区，未混入此次同步。旧 IPA 不能证明当前新源已编译、安装或发布。

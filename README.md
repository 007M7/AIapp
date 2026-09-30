# AIapp · AI 手办手机端

> **AI 手办**(桌面语音玩偶)的**手机端工作仓库**:微信小程序 + 可点开的交互原型 + 素材与出图提示词。
> **🔒 私有仓库**。上游主仓:`AI_figure`(设备固件 + 云端服务 + 产品定义文档)。本仓是**"额外的内容"独立成仓**——手机端的代码与原型在这里迭代,产品定义仍以主仓为准(见 [`docs/SNAPSHOT.md`](docs/SNAPSHOT.md))。

---

## 快速开始(零依赖,只用 Node ≥ 20)

```bash
npm run check          # 本地 CI:跑全部检查(结构/测试/链接/禁用词/密钥/快照)
npm run dev            # 起本地预览服务器 → 浏览器打开 http://127.0.0.1:5173/
npm run verify         # 重跑生成器 + 全检查(推送前的完整闸门)
npm run install-hooks  # 装 Git 钩子:让上面两条在 commit / push 时自动跑
```

**没有 `npm install`**:本仓**零依赖**,不引任何构建工具链,所有脚本用 `node` 直接跑。

---

## CI 是"本地构建运行",不使用 GitHub Actions

这是本仓的明确选择:原型出图依赖本机浏览器与字体、微信小程序本身也无法在云端构建,所以**把检查放在本机、由 Git 钩子触发**。

| 触发点 | 跑什么 | 文件 |
|---|---|---|
| `git commit` | `node scripts/check.mjs`(全部检查) | [`.githooks/pre-commit`](.githooks/pre-commit) |
| `git push` | 重跑原型生成器 → 全检查 → 校验产物已提交 | [`.githooks/pre-push`](.githooks/pre-push) |
| 手动 | `npm run check` / `npm run verify` / `npm run shots`(本地出图) | [`scripts/`](scripts/) |

**检查项(每条都能真的失败)**:

| # | 检查 | 判据 |
|---|---|---|
| 1 | 结构:必需路径存在 | 缺一即失败 |
| 2 | 小程序:单元测试 | `node --test`(22 个用例,含 RFC/FIPS/NIST 标准向量)全过 |
| 3 | 小程序:JS 语法 | `node --check` 逐个文件 |
| 4 | 小程序:appid 已替换 | 占位符 `touristappid` → **警告**(上线门禁,未上线前不阻断) |
| 5 | 原型:页面数 ≥ 30 | 当前 33 |
| 6 | 原型:独立页 ↔ 路由模板一一对应 | 数量必须相等 |
| 7 | 原型:站内链接不悬空 | 每个 `#/xxx` 都要有对应页面 |
| 8 | 文案:禁用词 | 15 个禁用词 0 命中(白名单「陪伴计数」除外) |
| 9 | 安全:密钥 / 生产信息 | API key、私钥、真实生产 IP、写死 key → 命中即失败 |
| 10 | 原型:截图非空 | 每张 PNG ≥ 1KB |
| 11 | 文档快照与主仓一致 | **仅当本机存在 `../AI_figure` 时**;只克隆本仓则跳过 |

---

## 目录结构

```
miniprogram/        微信小程序(BLE 配网,Security 1 + X25519 + AES-CTR)
  lib/ utils/ pages/ test/        19 个文件;测试用 node --test(22 用例)
prototype/          可点开的交互原型(本仓正本)
  index.html        交互版(Tab 与卡片可跳转)
  pages/            33 个独立页面(评审单位)
  overview.html     8 屏并排总览
  src/              生成器:core.mjs(令牌/图标/角色矢量图)+ build-app.mjs(页面内容)
  *.png             26 张 2 倍分辨率截图
ios/                iPhone App(Xcode/SwiftUI 工程源码;构建与自签见 ios/README.md)
docs/               文档(**快照**,正本在主仓;见 SNAPSHOT.md)
scripts/            本地 CI 与工具(check / dev / shots / install-hooks)
.githooks/          本地钩子(pre-commit / pre-push)
```

---

## 当前状态(如实标注)

| 项 | 状态 |
|---|---|
| 交互原型 | ✅ **可点开、33 页互通**;**文案为初版,待深度优化**(规范见 [`docs/CONTENT.md`](docs/CONTENT.md)) |
| 小程序运行时 | ⚠️ **只有 BLE 配网**一个功能;**未真机验收**(自列 5 个未知点,iPhone 长写是最大未知) |
| appid | ⚠️ 仍是 `touristappid` 占位符 —— 本地 CI 会警告,**上线前必须替换** |
| 角色立绘 | ⚠️ **矢量站位稿**(依三视图参考图重绘),待美术置换正式立绘 |
| 素材 | ⚠️ 表情差分 / 空态插画 / 动效 / 社区 banner / 分享卡模板**尚未做**(清单见 `docs/20`) |
| 支付 / 订阅 / 账号 | ⬜ 未开始(等主体与 `Q-20`,见主仓 `docs/project/`) |

**这不是**可提审的小程序、不是可交付的产品:没有账号体系、没有服务端接口对接、没有支付、没有真机验收。

---

## 待确认 / 待指定

1. **小程序主体与 appid**:企业还是个体工商户?类目资质与生成式 AI 备案是否要求(主仓 `Q-32/33/34`)——**责任人:待指定**
2. **上传方式**:是否走 CI 机器人上传,还是人工用微信开发者工具 ——**责任人:待指定**
3. **快照同步责任**:`docs/` 快照由谁在主仓更新后同步过来(建议纳入主仓 PR 检查)——**责任人:待指定**
4. **截图是否长期入库**(当前 4.3MB):保留、迁出、还是走 LFS ——**责任人:待指定**

---

## 纪律(改东西之前先看)

- **内容**:禁用词与写作纪律见 [`docs/CONTENT.md`](docs/CONTENT.md) §2;文案改动会被本地 CI 扫描。
- **美术**:六条美术红线(禁数值化、成人向不做幼态、承诺文本不改写、不画 AI 卖点、分享脱敏、双色调)见 `docs/20` §9。
- **代码**:`miniprogram/` 是 **CommonJS**(`require`),**不要给 `package.json` 加 `"type": "module"`**;脚本一律用 `.mjs`。
- **协议**:BLE 配网协议端点 UUID 与固件一一对应,**改一边必须改另一边**(见 `miniprogram/README.md`)。
- **产品定义**:定位、人群、数字口径、PRD、素材清单一律在**主仓**改,本仓只保留快照。

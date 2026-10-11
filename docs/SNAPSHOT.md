# 文档快照说明(重要)

本仓 `docs/` 下的文件**都是从主仓 `AI_figure` 复制来的快照**,不是正本。

| 本仓快照 | 正本位置(主仓) | 复制的时点 |
|---|---|---|
| `docs/09-issue-list.md` | `AI_figure/docs/product/09-issue-list.md` | 2026-10-03 |
| `docs/18-firmware-key-semantics-req.md` | `AI_figure/docs/product/18-firmware-key-semantics-req.md` | 2026-10-03 |
| `docs/21-mobile-product-baseline.md` | `AI_figure/docs/product/21-mobile-product-baseline.md` | 2026-10-03 |
| `docs/22-wechat-miniprogram-prd.md` | `AI_figure/docs/product/22-wechat-miniprogram-prd.md` | 2026-10-03 |
| `docs/23-android-ios-app-prd.md` | `AI_figure/docs/product/23-android-ios-app-prd.md` | 2026-10-03 |
| `docs/14-miniprogram-server-design.md` | `AI_figure/docs/product/14-*.md` | 2026-09-30 |
| `docs/19-miniprogram-ia-prd.md` | `AI_figure/docs/product/19-*.md` | 2026-09-30 |
| `docs/20-asset-and-art-inventory.md` | `AI_figure/docs/product/20-*.md` | 2026-09-30 |
| `docs/CONTENT.md` | `AI_figure/docs/product/mockups/app/CONTENT.md` | 2026-09-30 |
| `docs/PROMPTS*.md`(3 份) | `AI_figure/docs/product/mockups/PROMPTS*.md` | 2026-09-30 |

## 为什么这样安排

- **产品定义是跨端的**(设备 / 服务端 / 小程序共用同一套定位、人群研究、数字口径与承诺文本),把它拆到两个仓库会产生两份"事实",迟早打架。所以**产品文档正本留在主仓**,本仓只放开发时要随手翻的那几份。
- 本仓的**代码与原型是正本**(`miniprogram/`、`prototype/`)——这部分是"额外的内容",独立成仓。

## 漂移防护

`scripts/check.mjs` 里有一条**条件检查**:如果本机同时存在主仓(`../AI_figure`),它会逐份比对上面的快照与正本,**不一致就报错**(修法:把正本重新复制过来,或确认是否该改的是主仓)。只克隆本仓时该检查自动跳过。

## 冲突时以谁为准

| 内容 | 以谁为准 |
|---|---|
| 小程序代码、原型、素材产物 | **本仓** |
| 产品定位 / 人群研究 / 数字口径 / 承诺文本 / PRD / 素材清单 | **主仓 `AI_figure/docs/product/`** |
| 设备侧规格(引脚、状态机、协议) | 主仓 `AGENT.md` |
| 服务端规格与表结构、API | 主仓 `SERVER.md` 与 `docs/product/14-*.md`(14 在本仓也有快照) |

## 2026-10-03 同步记录

14／19 已同步端侧整理说明；新增 21～23 快照并纳入 check 比对。本目录 README 和 REPOSITORY-MAP 为本仓工作说明，不是产品正本快照。

## 2026-10-06 同步记录

app-todo.md、app-frontend-content-plan.md、app-foundation-research-execution.md 已同步主仓研究完成状态；新增 app-first-screen-ab-v0.1.md 首屏收敛稿快照。两版原型与用户测试未完成。研究报告正本仍在 AI_figure/docs/research/，原始来源快照仍在仓库外，未复制进 App 仓。

## 2026-10-11 设备基线同步

18/21/22/23 与 app-todo 已更新并同步；新增 app-device-interaction-baseline.md 的正本在 AI_figure/docs/product/，本仓副本字节一致。当前 check 尚未自动纳入新增文件，需手动比对。仅文档更新，没有实现设备控制或修改已冻结发布范围。

2026-10-11：新增 firmware-evaluation-request.md，正本位于 AI_figure/docs/product/；同内容副本已逐字节比对，尚未加入自动快照列表。

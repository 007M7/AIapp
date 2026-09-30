# 文档快照说明(重要)

本仓 `docs/` 下的文件**都是从主仓 `AI_figure` 复制来的快照**,不是正本。

| 本仓快照 | 正本位置(主仓) | 复制的时点 |
|---|---|---|
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

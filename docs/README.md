# 产品与工程文档入口

2026-10-11；先读 [实际实现状态](IMPLEMENTATION-STATUS.md) 和 [分类地图](REPOSITORY-MAP.md)。

## 产品需求快照

| 文档 | 内容 |
|---|---|
| [21 · 共用基线](21-mobile-product-baseline.md) | 产品对象、两端边界与实现差距 |
| [22 · 小程序 PRD](22-wechat-miniprogram-prd.md) | 范围、流程、异常与验收 |
| [23 · 安卓／苹果 PRD](23-android-ios-app-prd.md) | 原生 App 要求与分端状态 |
| [19 · 页面规格](19-miniprogram-ia-prd.md) | 页树与开箱流程 |
| [14 · 后端设计](14-miniprogram-server-design.md) | 数据、接口与分期；不等于后端已实现 |
| [09 · 决策登记](09-issue-list.md) | 产品决策与待确认问题 |

正本位于 AI_figure/docs/product/，先修改正本再同步。规则见 [SNAPSHOT](SNAPSHOT.md)。

## 内容与玩法

- [前端内容规划](app-frontend-content-plan.md)、[分批待办](app-todo.md)。
- [角色基础内容](app-first-character-content.md)、[玩法讨论](app-play-design-v0.1.md)、[玩法参考](app-play-reference.md)。
- [研究执行书](app-foundation-research-execution.md)、[首屏 A/B 收敛](app-first-screen-ab-v0.1.md)。研究正本与原始数据仍在主仓及 _research；A/B 尚未完成真实用户验证。
- [文案规范](CONTENT.md)、[素材清单](20-asset-and-art-inventory.md)、[提示词](PROMPTS.md)、[素材提示词](PROMPTS-ASSETS.md)。需求、提示词与正式素材分别判断。

## 设备与云端

- [固件需求](firmware-evaluation-request.md)：先本地固件需求和验收，再云端联合契约。
- [设备交互基线](app-device-interaction-baseline.md)、[设备需求快照](18-firmware-key-semantics-req.md)。
- [设备云端源码说明](../server/README.md)、[来源和哈希](../server/UPSTREAM.json)。
- [上游服务说明](upstream/SERVER.md)、[上游协议说明](upstream/AGENT.md)：固定版本脱敏参考。

## 运行端与设计工具

- [iOS 工程](../ios/README.md)、[微信配网工程](../miniprogram/README.md)、[网页原型](../prototype/README.md)。
- 本机另有 ios/docs/、prototype/first-screen-ab/、assets/、models/；此次云端同步未混入这些历史未提交迭代，完整克隆不保证包含本地全部素材。
- 安卓尚无工程；原生编译和真机验收分别记录，网页预览不替代 App。

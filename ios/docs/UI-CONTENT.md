# iPhone UI 与内容实现规格

> 2026-10-03 · 本轮可实现的局部改进规格。范围承接 23 与 D-13，不新增后端接口、不改承诺原文、不冒充业务成功。

## 1. 视觉与共用状态

保留现有深蓝／米白视觉令牌、五域 Tab 与圆角卡片，不另做一套设计体系。本轮先完善状态与内容，再由实机截图校验布局。禁数值亲密度、红点诱导与挽留话术；AI 身份说明保持可见。

远程列表统一区分：未配置、加载中、空列表、成功、失败。未配置有设置入口，失败有重试；取消不当错误，失败不显示“还没有角色”。旧数据不能在账号或服务器切换后当作当前账号内容；请求完成时检查身份版本及请求代次。

| 页面 | 本轮行为／文案 | 后端仍未解决的部分 |
|---|---|---|
| 今天 | 实际设备状态与请求状态分开；未配置／加载失败时不判断设备离线；记录加载失败可重试 | 真实设备列表和回合记录 |
| 记忆 | 列表加载／失败／空态分开，成功写操作后重读服务端事实 | 真实记忆服务、保留及删除契约 |
| 我的角色 | 加载／失败／空态分开；设置及重试入口 | 角色与资产实际入册 |
| 社区 | 官方包与动态分别加载，单侧失败不抹掉另一侧结果；无固定周更日期承诺 | 官方内容、发布节奏与试听 |
| 商店 | 免费区保持首屏；列表失败可重试；兑换清楚提示尚未开通 | 权益、兑换与支付 Q-20／Q-87 |
| 我的／设置 | 正常内容与开发接入说明区分；token 隐藏输入；本地通知明确是测试，无未来自动提醒承诺 | 正式登录、注销与删除 |
| 开箱 | 保存步骤和名字草稿；可跳过进入五域；示例首卡、契约阅读和流程完成不宣称真实入册／签署／认主 | 命名保存、官方首包、角色级签署及首回合 |

## 2. 开箱六步

1. 装备须知：说明用途与免费／付费边界，保留原承诺文本。
2. 绑定：入口与手输 SN 能力一致，扫码没有实现时不写已支持；“稍后绑定”不授予虚拟资产。
3. 名字：本地草稿保存，显示尚需角色服务确认，不能承诺设备已叫出名字。
4. 第一张卡：明确为预览；继续不冒充装包成功，不将示例连载或权益视作已交付。
5. 契约：原文保持，当前仅阅读确认；不写入正式角色签署状态。
6. 完成：表达“开箱介绍已看完”，入口可进入五域；分享为文字预览，不称图片已生成或认主已成功。

暂时退出不标记流程完成；完成介绍才保存 done 标记。下次继续时恢复步骤，历史越界步号自动裁剪。草稿只存在本机，不属于服务端角色事实。

## 3. 内容待补与交付单位

共用文案修改回主仓 CONTENT／23，角色与承诺按 17。iOS 专属错误／重试／权限恢复文案由工程规格承接。角色口吻库、首个官方包实际内容、正式图标与立绘、分享卡模板、协议和隐私政策正文仍待完善，不把引用标题作为可打开的协议。

验收单位为页面＋状态＋用户结果；需要实测窄屏、大字、深色、VoiceOver、减少动态效果、弱网和权限拒绝。当前固定字号与浅色令牌的可访问性限制仍待后续专门改进，不宣称已适配。

## 4. 当前页面承接清单

以下为源码中的页面容器清单，用于逐页安排截图与场景验收；不是页面已验收记录。共用组件不计入。

| 页面容器 | 源码 | 验收状态 |
|---|---|---|
| ArchiveHomeView | [AIFigure/Features/Archive/ArchiveHomeView.swift](../AIFigure/Features/Archive/ArchiveHomeView.swift) | 新源编译／页面与状态截图待验收 |
| AssetsLedgerView | [AIFigure/Features/Archive/ArchiveHomeView.swift](../AIFigure/Features/Archive/ArchiveHomeView.swift) | 新源编译／页面与状态截图待验收 |
| CertificateView | [AIFigure/Features/Archive/CertificateView.swift](../AIFigure/Features/Archive/CertificateView.swift) | 新源编译／页面与状态截图待验收 |
| CharacterDetailView | [AIFigure/Features/Archive/CharacterDetailView.swift](../AIFigure/Features/Archive/CharacterDetailView.swift) | 新源编译／页面与状态截图待验收 |
| MemoryPanelView | [AIFigure/Features/Archive/MemoryViews.swift](../AIFigure/Features/Archive/MemoryViews.swift) | 新源编译／页面与状态截图待验收 |
| MemoryEditView | [AIFigure/Features/Archive/MemoryViews.swift](../AIFigure/Features/Archive/MemoryViews.swift) | 新源编译／页面与状态截图待验收 |
| ChatView | [AIFigure/Features/Chat/ChatView.swift](../AIFigure/Features/Chat/ChatView.swift) | 新源编译／页面与状态截图待验收 |
| CommunityView | [AIFigure/Features/Community/CommunityView.swift](../AIFigure/Features/Community/CommunityView.swift) | 新源编译／页面与状态截图待验收 |
| PackDetailView | [AIFigure/Features/Community/CommunityView.swift](../AIFigure/Features/Community/CommunityView.swift) | 新源编译／页面与状态截图待验收 |
| BindView | [AIFigure/Features/Hand/BindView.swift](../AIFigure/Features/Hand/BindView.swift) | 新源编译／页面与状态截图待验收 |
| DeviceManualView | [AIFigure/Features/Hand/DevicePages.swift](../AIFigure/Features/Hand/DevicePages.swift) | 新源编译／页面与状态截图待验收 |
| DeviceSettingsView | [AIFigure/Features/Hand/DevicePages.swift](../AIFigure/Features/Hand/DevicePages.swift) | 新源编译／页面与状态截图待验收 |
| HandTodayView | [AIFigure/Features/Hand/HandTodayView.swift](../AIFigure/Features/Hand/HandTodayView.swift) | 新源编译／页面与状态截图待验收 |
| TurnListView | [AIFigure/Features/Hand/HandTodayView.swift](../AIFigure/Features/Hand/HandTodayView.swift) | 新源编译／页面与状态截图待验收 |
| ProvisionView | [AIFigure/Features/Hand/ProvisionView.swift](../AIFigure/Features/Hand/ProvisionView.swift) | 新源编译／页面与状态截图待验收 |
| MeView | [AIFigure/Features/Me/MeView.swift](../AIFigure/Features/Me/MeView.swift) | 新源编译／页面与状态截图待验收 |
| PromiseView | [AIFigure/Features/Me/MeView.swift](../AIFigure/Features/Me/MeView.swift) | 新源编译／页面与状态截图待验收 |
| ExitView | [AIFigure/Features/Me/MeView.swift](../AIFigure/Features/Me/MeView.swift) | 新源编译／页面与状态截图待验收 |
| SettingsView | [AIFigure/Features/Me/SettingsView.swift](../AIFigure/Features/Me/SettingsView.swift) | 新源编译／页面与状态截图待验收 |
| OnboardingFlow | [AIFigure/Features/Onboarding/OnboardingFlow.swift](../AIFigure/Features/Onboarding/OnboardingFlow.swift) | 新源编译／页面与状态截图待验收 |
| StoreView | [AIFigure/Features/Store/StoreView.swift](../AIFigure/Features/Store/StoreView.swift) | 新源编译／页面与状态截图待验收 |
| FreeZoneView | [AIFigure/Features/Store/StoreView.swift](../AIFigure/Features/Store/StoreView.swift) | 新源编译／页面与状态截图待验收 |
| RedeemView | [AIFigure/Features/Store/StoreView.swift](../AIFigure/Features/Store/StoreView.swift) | 新源编译／页面与状态截图待验收 |

## 2026-10-03 界面文案清理

页面仅保留标题、内容、操作和必要状态。已移除研发阶段、文档引用、实现解释及重复宣传；详细规则留在文档中。未开放操作仍保留简短状态，正式契约与服务承诺未改写。浏览器原型同步清理，原生 SwiftUI 尚未重新编译验证。

## 2026-10-03 用户标注后的界面调整

本轮按用户的 10 条浏览器标注执行：移除页面顶部 AI 说明条、“我的”页重复身份说明和登录状态标签；首页形象区域删除呼吸球及说明，保留空白供正式形象设计；首页相处记录集中到档案，删除档案首页资产汇总卡。

第 4 个 Tab 展示名称暂改为“发现”，保留 store/* 路由及既有 Pack API，避免把命名修改扩大成接口迁移。页面改为角色、故事内容入口，移除演示价格、虚构冬装商品、订阅及兑换占位入口。“我的”围绕已有角色、档案、设备与设置入口组织，未接入业务不占据主菜单。

社区设计稿采用动态信息流、故事入口、角色入口；原生界面优先展示服务端官方动态，仅使用已有 posts/packs 数据，不添加虚假用户、点赞数或发布接口。浏览器的故事摘录及卡片仍是设计样稿；UGC、话题、发布、互动及内容运营需在社区专项设计中确定，本轮未宣称实现。

这些调整是当前 UI 迭代口径；“发现”正式命名、社区完整方案和资源清单仍待后续设计。iOS 修改仅完成源码与静态检查，尚未重新编译或真机验收。

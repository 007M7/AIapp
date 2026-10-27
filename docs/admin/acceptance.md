# 后台交付与验收记录

2026-10-12 · 本机 Windows，Python3.12.14、Node24.16.0、Edge headless。范围为独立管理服务，云部署和真实 App／设备接入未验收。

补充：GitHub [Linux CI 38215926903](https://github.com/007M7/AIapp/actions/runs/38215926903) 对ecf9d43成功执行19个测试及前端构建。这仍不包含生产数据库／缓存／队列或CD，完整差距见 [生产架构审查](production-architecture-review.md)。

## 需求追踪

| 需求 | 已验证判据 | 证据 |
|---|---|---|
| ADM-01 素材 | 上传真实小鲸图、类型／大小／哈希、版本可重读 | Domain 上传／输入测试；浏览器 upload 与图片 naturalWidth |
| ADM-02 版本 | 每次保存新版本、固定依赖、并发保存一胜一冲突 | Domain concurrent／immutable／dependency 测试 |
| ADM-03 审核 | 逐层独立批准、拒绝后新版本、自审／未审依赖被拒绝 | Domain review 测试＋浏览器 4 层审批 |
| ADM-04 发布 | 自动闭包4个版本、环境指针 CAS、修改草稿不污染发布 | Domain release 测试＋浏览器 publish |
| ADM-05 执行 | 消费同发布图／文、记录刷新保留、冷却与幂等 | Domain execute；浏览器 reply／reload |
| ADM-06 恢复 | 取消无写、回退旧版、下架后不能新执行 | Domain rollback／withdraw；浏览器取消／回退／空环境 |
| ADM-07 权限 | 服务端角色限制、会话撤销、最后管理员保护、真实／预览隔离 | Domain user 测试，HTTP auth／CSRF／Origin／Host／限流，浏览器只读 |
| ADM-08 记录 | 成功／拒绝有审计；触发器禁改；备份新目录恢复；未来 schema 拒绝 | Domain audit／backup／schema；浏览器操作表 |

19 个后端领域／HTTP 集成测试通过；30 项浏览器检查通过，无未捕获异常。Vue TypeScript＋Vite 生产构建通过；生成 JS 约95KB（gzip约35KB），CSS约11KB。根 npm run check 12项通过、22个小程序单测通过，既有 touristappid 警告保留；主仓 PRD 镜像纳入19份一致性检查。npm 安装时报告0已知漏洞，不等于完整安全审计。

浏览器证据：[browser-report.json](../../admin/verification/browser-report.json)；桌面发布／消费／工作台和390px窄屏截图在 admin/verification/screenshots/（本机评审产物，不入库），已实际查看消费页及窄屏图。浏览器数据库独立于供用户操作的 admin/data/ 主库。

## 成熟度和边界

已做到本地可运行、可验证：SQLite真实保存、服务器权限、不可变发布、预览消费和回退。设备语音server未改，原有iOS／网页／模型工作区修改保留。样例通过显式seed写入，标明本地引导，不当用户或设备事实。

尚未验证：Linux／Nginx实际部署、真实管理员组织规则、SSO/MFA、恶意素材扫描、外部告警、规模与生产并发、App runtime接口和真实设备回执。日常时点／游戏Hook字段可编辑与预览，自动调度未实现；不宣称实体说话成功。生产门禁见 [operations](operations.md)。

## 复核修正

技术选择由临时标准库HTTP方案改为与现有服务一致的aiohttp，前端采用独立Vue工具链；补齐Windows备份连接显式关闭、schema版本门禁、权限变更会话撤销和关键操作前后指针记录。测试发现的临时目录权限及脚本步骤问题已改用工作区独立数据和明确页面选择，未绕过仓库测试或发布钩子。

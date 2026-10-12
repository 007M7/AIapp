# AIapp 后台管理

Python＋aiohttp / Vue 3＋TypeScript＋Vite / SQLite WAL。设计和状态：[PRD](../docs/admin-management-prd.md)、[架构评估](../docs/admin/ADR-001-stack-and-deployment.md)、[数据与接口](../docs/admin/architecture-and-contracts.md)、[页面设计](../docs/admin/page-design.md)。

## 安装和本地运行

```powershell
python -m venv admin/.venv
admin/.venv/Scripts/python -m pip install -r admin/requirements-lock.txt
npm --prefix admin/frontend ci
npm --prefix admin/frontend run build
admin/.venv/Scripts/python admin/server.py --local-preview
```

访问 http://127.0.0.1:8787/admin/ 。本地模式可选编辑／审核／发布／运行身份；业务数据保存在 admin/data/，不是浏览器本地存储。默认空库；可选引导样例由 `seed.py` 明确导入，按需使用。已有本机素材不自动覆盖。

需要前端热更新时：后台启动增加 `--dev-origin http://127.0.0.1:5175`，另开 `npm --prefix admin/frontend run dev`，访问5175/admin/。该开发源仅local-preview允许，正式模式拒绝；默认8787构建预览不需要此参数。引导样例用 `python admin/seed.py --image admin/examples/xiaojing-front.png`，来源与哈希在 examples/source.json。

Linux 替换 Python 路径为 admin/.venv/bin/python。前端构建要求 Node >=22.12（实际验证 Node24）；服务运行 Python3.12，Node 不必在运行机器常驻。真实管理员在关闭 preview 的同一数据目录执行 `python admin/server.py --create-admin`，交互输入密码，随后不带 local-preview 启动。预览身份不可在真实模式登录。

## 核心操作

编辑上传素材→提交→审核员批准→编辑角色→提交／批准→内容→提交／批准→事件→提交／批准→发布负责人选事件发布（自动携带依赖）→运行人员消费预览→查执行／审计→发布负责人回退或下架。

每次编辑另存新版本；发布环境用不可变完整清单。下架、回退、权限变更需原因。预览执行生成真实本地记录，但不发送设备；定时／Hook 是内容配置，未启用自动调度。真实设备与 App 账号／资产接口尚未接入。

## 验证、数据与部署

`admin/.venv/Scripts/python -m unittest discover -s admin/tests -v`；`npm --prefix admin/frontend run build`；浏览器验证见 `verification/`。

`python admin/server.py --backup <备份文件>` 使用 SQLite 在线 backup；同时保存 data/blobs/。恢复先停服务，再从备份恢复 DB＋素材，启动后执行完整性及发布清单校验。schema v1 不自动降级。Linux Nginx／systemd 模板和发布门禁在 deploy/ 与 docs/admin/operations.md。

本轮交付为独立本地管理工程和可运行主链；没有发布到生产、接入真实设备、接管用户私人记忆或配置厂商密钥。

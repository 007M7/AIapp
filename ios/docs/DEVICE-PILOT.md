# iPhone设备试用版 · 2026-10-27

本轮用户要求先做iPhone，沿用jev已使用的Sideloadly签名流程；随后明确先在内置浏览器审阅，暂缓手机连接和安装。

## 内容

- Debug配置启用DEVICE_PILOT：角色首页、设备状态、详情、独立连接配置与扫码、短鸣识别及回执、现有BLE配网入口。
- 角色使用已有小鲸正视图原文件；本轮未将大体积3D模型打入包中。
- 地址保存在UserDefaults；独立局域网凭据保存在本机Keychain，不复用平台账号token或设备密钥。
- HTTP仅在Debug配置开放，客户端限定明确的私网地址；Release仍为原工程配置。
- 录音、等待、播放若没有主板可信确认，不虚构精确状态；网关忙碌仅显示“互动进行中”。电量未知。

## 当前验证

| 项目 | 结果 |
|---|---|
| 本地仓库检查 | 12项通过，含原有28项小程序测试；不是Swift编译结果 |
| HTTP／SQLite执行域测试 | 8项通过，含忙碌／服务模式用例 |
| 原生Swift客户端测试 | 已加入macOS构建，尚待执行 |
| IPA与模拟器截图 | 2026-10-27 00:12的GitHub任务40356790818被账户账单／额度限制阻止，未进入编译；没有生成新IPA |
| 内置浏览器 | prototype/iphone-device-pilot/是可点击的界面审阅稿，数据为示例，不执行主板控制 |
| 签名安装 | 使用D:/jev/Sideloadly/sideloadly.exe；按用户要求待审阅后再执行，尚未安装 |

已推送分支feature/iphone-device-pilot。不能用PR #1在10月12日通过的Management checks作为本次iPhone编译证据。

本机语音服务8766与独立设备网关8795已监听；只读请求鉴权通过。2026-10-27本轮核验时主板未在线，网关如实返回device_online=false、can_identify=false。尚未验证iPhone跨设备访问和主板真实短鸣回执。

浏览器已核验手动连接示例、识别等待与完成反馈、互动期间禁用操作及配网导航。预览不保存真实连接凭据，也不控制主板。

## 构建

GitHub Actions手动触发ios-unsigned.yml，configuration=Debug。构建入口：BUILD_CONFIGURATION=Debug bash ios/tools/build-ipa.sh。

构建资源恢复后：移植与客户端自测→真SwiftUI编译→未签名IPA→模拟器home/connect/device截图。已有preview-simulator.sh负责截图。通过之后，再用现有Sideloadly签名并单独验证iPhone局域网权限、扫码、BLE与真实回执。

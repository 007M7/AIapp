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
| IPA与模拟器截图 | 旧任务40356790818被账户限制阻止；本轮额度已恢复。40445251965发现自测终止函数返回类型错误，已修复；40445384815已成功完成自测、iphoneos编译、未签名IPA、模拟器三页截图和产物上传 |
| 内置浏览器 | prototype/iphone-device-pilot/已改为真实设备联调，移除示例状态选择。2秒轮询状态、真实短鸣识别及回执；浏览器不提供BLE配网 |
| 签名安装 | 使用D:/jev/Sideloadly/sideloadly.exe；按用户要求待审阅后再执行，尚未安装 |

已推送分支feature/iphone-device-pilot。不能用PR #1在10月12日通过的Management checks作为本次iPhone编译证据。

本机语音服务8766与独立设备网关8795已监听。2026-10-27本轮主板按键唤醒后上线：主板192.168.137.159→电脑热点192.168.137.1:8766；电脑上游WLAN为Goldman（192.168.0.101），以太网192.168.0.100。主板服务返回device_online=true、telemetry_fresh=true、service_ready=true、can_identify=true，固件0.5.10-selftest-adc。浏览器发送一次识别指令，实际得到completed回执；声音效果仍以用户耳听为准。未验证iPhone跨设备访问。

浏览器已核验真实状态、识别等待与完成反馈。代理安全测试5项通过，验证同源／Host／路径边界、幂等键转发、错误和超时不重发。连接凭据仅在Node服务中读取，不下发页面、不写入前端存储；页面只保存操作编号与未确认标记。网关沿用SQLite执行记录。电池采样仍待核验，电量和充电状态保持未知。

## 本机浏览器联调启动

### 新增：屏幕麦克风→主板回答

2026-10-27用户确认按住屏幕录音、松开发送，主板播放回答。浏览器AudioWorklet与原生AVAudioRecorder均已加入；最多30秒，页面隐藏／取消时丢弃未提交录音。原生含麦克风权限声明及私有临时WAV清理。状态接口新增can_mobile_voice，操作kind=voice区分回答播放与短鸣回执。

当前实板仍是0.5.10，虚拟语音按钮因能力不足禁用并显示待升级。0.5.11固件与11项服务测试、8项代理／PCM测试已通过，但USB烧录通道未枚举，未刷入，也未验证真人录音→主板回答。不能把已通过的短鸣回执当作该语音功能已完成。

给Node预览进程设置DEVICE_PILOT_CONNECTION_FILE为本机私有connection.json的绝对路径，再运行node scripts/dev.mjs。默认仅监听127.0.0.1:5173；配置文件不得放在仓库静态目录或提交Git。未配置时代理返回503，不降级为示例成功。

浏览器仅允许GET /__device/status、GET /__device/operations/{id}、POST /__device/identify。写操作要求本机同源Origin、固定自定义请求头、JSON空对象和UUID幂等键；由本机固定代理转发至已配置私网设备网关，不开放任意目标代理。POST结果不明时保留未确认并禁止自动重发；状态刷新与后台恢复只执行GET。需结束联调时停止本地预览进程；语音服务独立运行。

## 构建

GitHub Actions手动触发ios-unsigned.yml，configuration=Debug。构建入口：BUILD_CONFIGURATION=Debug bash ios/tools/build-ipa.sh。

本轮上述构建链路已通过。按用户先审阅的要求，Sideloadly签名和安装暂缓；iPhone局域网权限、扫码、BLE及真实回执需后续真机单独验证。

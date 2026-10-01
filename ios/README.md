# iOS App(iPhone)· MVP1 源码工程

> 2026-09-29 初版。**依据**:PRD `19` v1.2(三端同构 IA,§3.1 App 列)、`14` §5.4(API 面)、
> `18` v1.2(设备侧冻结)、`17` §3.4(承诺文本)、`20`(素材与美术红线)、AIapp prototype(33 页文案)。
> **性质**:MVP1 源码工程,「自授签名(自签)」交付路径 —— 配合已在跑通的自签工具(下文「签名」节)。

## 1. 范围(诚实版)

| 项 | 本期 | 原因 |
|---|---|---|
| 五域 IA(手办/档案/社区/商店/我的) | ✅ 同构移植,Tab 命名与小程序逐字一致 | PRD §3.1 |
| 承诺页 / 契约卡 / 免费区 / 两动作说明 | ✅ 文案与原型逐字一致 | PRD 验收 #6、`17` §3.4 |
| BLE 配网(protocomm Security 1) | ✅ 与小程序 `utils/` 同源移植(X25519 + AES-CTR,无 PoP) | `19` §5.2 |
| 文字回合(#24 text-turn,收文本+音频,播放可打断) | ✅ | `14` §5.4 #24 |
| 登录 | ⚠️ 开发期手动填 token | App 登录方式(微信 SDK/手机号)待定 → 09 **Q-88** |
| 远程推送 | ❌ 本期只有**本地通知** | 自签/免费证书无 APNs;系统推送列 App 通道二期 |
| 桌面小组件 | ❌ | App Groups 需付费开发者账号 |
| 蓝牙 OTA 通道 | ❌ | 设备侧 MVP1 冻结(`18`),固件不接受 OTA |
| 支付/订阅 | ❌ 只读 + 兑换码位 | `14` §5.4 刻意缺席支付端点(Q-20 主体) |
| App 直连网关 WS(实时语音) | ❌ | 网关在 PSK 域内,App 无凭据;且无 App 语音端点 → 09 **Q-87** |

**端差异仅三处**(PRD §3.3):登录 / 支付 / 推送 —— 本工程对三处都做了诚实裁剪,未造假接口。

## 2. 目录

```
ios/
  project.yml                  XcodeGen 工程定义(单一来源;不提交 .xcodeproj,同 jev 范式)
  AIFigure/
    App/        入口、根 TabView、设计令牌(与 prototype core.mjs 的 T 一一对应)
    Content/    数据模型 + 静态文案库(承诺/契约/免费区/空态,禁用词已过 CI)
    Server/     /api/v1 客户端(端点注释 = 14 §5.4 行号)+ 接入配置
    Device/     BLE 配网:MiniPB / AesCtr / X25519 / ProtocommBLE / ProvisionSession / Provisioner
    Audio/      回复音频播放(裸 PCM16LE/16k 自动补 WAV 头)
    Features/   Hand(今天/绑定/配网/说明/设置)· Chat · Archive · Community · Store · Me · Onboarding
    Resources/  Info.plist + Assets.xcassets(AccentColor 已设;AppIcon 空位待美术)
  tools/
    build-ipa.sh    Mac 侧一键出包(自动 xcodegen generate)
    selftest.swift  移植层自测(NIST AES-256-CTR 向量 + pb/AES/X25519 与 JS 实现对拍)
.github/workflows/ios-unsigned.yml   云构建:macOS runner 出未签名 IPA(手动触发)
```

## 3. 构建(与 jev 项目同一条已跑通链路)

**路线 A(默认,没有 Mac 也行):GitHub Actions 云构建**

1. 仓库推到 GitHub 后,仓库页 → **Actions** → 左侧「iOS 未签名 IPA」→ **Run workflow**
   (`note` 随便填,会进 artifact 名);
2. 跑完在 Artifacts 下载 `AIFigure-unsigned-<note>`,里面是 `AIFigure-unsigned.ipa`;
3. 走 §4 的 Sideloadly 签名安装。

> 用稳定 `macos-15` 镜像(本工程只需 iOS 16 SDK)。**不要**学 jev 换 `xcode-27`
> preview 镜像——那个镜像经常抢不到机器,~11 秒 completed/failure、steps 为空 =
> 没排上队,重试即可,不是构建错误(jev 实测教训,写在它的 workflow 注释里)。

**路线 B(有 Mac 时)**:

```bash
brew install xcodegen        # 首次
bash ios/tools/build-ipa.sh  # 自动 xcodegen generate → 编译 → ios/dist/AIFigure-unsigned.ipa
```

想直接在 Xcode 里 Cmd+R:项目级 `CODE_SIGNING_ALLOWED=NO` 是为出未签名包设的,
本地调试时在 Xcode 里把该设置改回 YES 并选你的 Team(免费 Apple ID 即可)。

移植层自测(不依赖真机,先跑它再上真机):

```bash
swift ios/tools/selftest.swift \
      ios/AIFigure/Device/MiniPB.swift \
      ios/AIFigure/Device/AesCtr.swift \
      ios/AIFigure/Device/X25519.swift
```

## 4. 构建与签名(Sideloadly 路线)

**分工要分清**:Sideloadly(Windows,开源)只负责**签名 + 侧载**现成 ipa,**不能编译 SwiftUI**;
编译必须在一台 Mac 上(`build-ipa.sh` 一条命令)。两步:

### 4.1 Mac 侧:出未签名 ipa(一次性)

```bash
bash ios/tools/build-ipa.sh     # 产物:ios/dist/AIFigure-unsigned.ipa
```

### 4.2 Windows 侧:Sideloadly 签名安装

1. 前置驱动:**本机已确认装好**(iTunes + Apple Mobile Device Support,2026-09-29 核对);
   若换机器遇到"设备不识别",装 Apple 官网版 iTunes(**不要** Microsoft Store 版);
2. Sideloadly 本体:**本机已有便携版** `D:\jev\Sideloadly\sideloadly.exe`
   (jev 项目 2026-09-22 签 JevAssistant 用的就是它,免安装);
3. 手机连 USB → Sideloadly 拖入 `AIFigure-unsigned.ipa` → 填 Apple ID → Start;
4. **免费 Apple ID 注意**:Sideloadly 会自动改 Bundle ID 加后缀(保持默认即可,工程里的
   `com.aiapp.figure` 是占位);同一证书**最多 3 个 App**、**7 天过期**(过期重签一次);
5. 首次安装后在手机上:设置 → 通用 → VPN与设备管理 → 信任你的开发者证书。

> 没有任何 Mac 可用时的替代:GitHub Actions 的 macOS runner 能跑同一条 xcodebuild
> (一次性手动触发,不做 CI 检查)——是否启用见 `09` D-13 备注,等你拍板。

## 5. 协议映射(与设备/服务端共用的一套)

| 层 | 小程序 | iOS 本工程 | 契约 |
|---|---|---|---|
| protobuf | `utils/pb.js` | `Device/MiniPB.swift` | varint=0 不上线;嵌套消息总上线 |
| AES-256-CTR | `lib/aes_ctr.js` | `Device/AesCtr.swift` | 单密钥流,跨调用偏移保留 |
| X25519 | `lib/x25519.js` | `Device/X25519.swift`(CryptoKit) | 共享密钥即 AES 密钥,无 KDF |
| 配网会话 | `utils/prov.js` | `Device/ProvisionSession.swift` | Sec1 字段号/密钥流消耗顺序逐字对齐 |
| BLE 传输 | `utils/ble.js` | `Device/ProtocommBLE.swift` | 服务 `10624C9A-…`;端点 FF4F–FF53 |
| 业务 API | — | `Server/APIClient.swift` | `14` §5.4,注释带行号 |

移植正确性:`tools/selftest.swift` 的向量由 JS 真实现生成(NIST 官方向量 + 随机对拍 + RFC 7748),不是"看起来对"。

## 6. 已知缺口(全部已登记,不静默)

- **Q-87**:App 侧 API 缺口 —— text-turn 响应字段口径(audio_url/base64 为约定草案)、
  兑换码端点、账号注销端点、App 实时语音通道(api. 域落地后评估);
- **Q-88**:App 登录方式(微信 SDK / 手机号)未定,当前手动 token;
- AppIcon 为空位(工程可编过,仅警告);角色立绘占位,等美术(`20` 清单);
- 本工程在 Windows 上编写,**未经 Xcode 真机编译**;首编如报小错按提示修即可,
  移植层正确性由 selftest 兜底(见 §3);
- 真机验收清单(蓝牙扫到/握手成功/配网成功/文字回合出声/打断生效/承诺页文案比对)待真机后回填 `09`。

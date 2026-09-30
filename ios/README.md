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
  AIFigure.xcodeproj/          Xcode 工程(objectVersion 56,Xcode 14–16 兼容)
  AIFigure/
    App/        入口、根 TabView、设计令牌(与 prototype core.mjs 的 T 一一对应)
    Content/    数据模型 + 静态文案库(承诺/契约/免费区/空态,禁用词已过 CI)
    Server/     /api/v1 客户端(端点注释 = 14 §5.4 行号)+ 接入配置
    Device/     BLE 配网:MiniPB / AesCtr / X25519 / ProtocommBLE / ProvisionSession / Provisioner
    Audio/      回复音频播放(裸 PCM16LE/16k 自动补 WAV 头)
    Features/   Hand(今天/绑定/配网/说明/设置)· Chat · Archive · Community · Store · Me · Onboarding
    Resources/  Info.plist + Assets.xcassets(AccentColor 已设;AppIcon 空位待美术)
  tools/
    selftest.swift  移植层自测(NIST AES-256-CTR 向量 + pb/AES/X25519 与 JS 实现对拍)
```

## 3. 构建(Mac 上)

1. `open ios/AIFigure.xcodeproj`;
2. Signing & Capabilities:选你的 **Team**(免费 Apple ID 即可),Bundle ID 需要时改成你证书里登记的那个(默认占位 `com.aiapp.figure`);
3. 选真机,Cmd+R。

命令行等价:

```bash
xcodebuild -project ios/AIFigure.xcodeproj -scheme AIFigure \
  -destination 'generic/platform=iOS' -allowProvisioningUpdates build
```

移植层自测(不依赖真机,先跑它再上真机):

```bash
swift ios/tools/selftest.swift \
      ios/AIFigure/Device/MiniPB.swift \
      ios/AIFigure/Device/AesCtr.swift \
      ios/AIFigure/Device/X25519.swift
```

## 4. 签名与安装(自签)

两条路,选一:

- **路 A:Xcode 免费个人团队**。免费 Apple ID 的描述文件 **7 天过期**,过期重跑一次 Cmd+R;
- **路 B:自签工具(已跑通的 jev 链路)**。本机(Mac)出**未签名包**,交给签名工具:

```bash
# 1) 出 .app(不签名)
xcodebuild -project ios/AIFigure.xcodeproj -scheme AIFigure \
  -configuration Release -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO build
# 产物在 DerivedData 的 Build/Products/Release-iphoneos/AIFigure.app

# 2) 打成未签名 ipa
mkdir -p Payload && cp -R <上面的路径>/AIFigure.app Payload/
zip -r AIFigure-unsigned.ipa Payload && rm -rf Payload
```

然后把 `AIFigure-unsigned.ipa` 交给你的自签工具(证书 P12 + 描述文件),签完侧载。
若工具要求 App ID 匹配,把工程里 `PRODUCT_BUNDLE_IDENTIFIER` 改成证书登记值再 build。
若你的 api 域名用的是**自签证书**(非 CA 签发),在 Info.plist 加 `NSAppTransportSecurity` 的
域名例外;CA 签发(含 Let's Encrypt)不用动。

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

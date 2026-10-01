import Foundation

// 静态文案库 —— 与 AIapp prototype(初版 app demo)逐字一致,来源:
//   承诺/契约/免费区 → `17` §3.4 / `17` §3.1(原型 PromiseView、certificate 页已过内容纪律)
//   设备两动作 → `18` v1.2(包装卡、开箱第一句、本页三处一致)
//   装备须知/开箱仪式 → `19` §6.1
// 文案纪律:禁用词表(docs/CONTENT.md §2)本地 CI 会扫到本目录,新增文案先过那 15 个词。

enum Copy {
    /// 文案条目:标题 + 正文。
    /// 用结构体而不是元组 —— Swift 不支持指向元组元素的 KeyPath(`\.title` 编不过),
    /// ForEach 依赖 KeyPath,所以这里必须是名义类型。(2026-10-01 首编修复)
    struct Item: Identifiable {
        var id: String { title }
        let title: String
        let body: String
    }

    // 合规:首页常驻 AI 身份标识(PRD §8)
    static let aiBadge = "本产品为人工智能合成语音,互动对象不是真人"

    // 承诺页(me/promise)—— 与原型逐字一致,一字未改
    static let promisePageTitle = "我们承诺什么,不承诺什么"
    static let promisePageIntro = "这一页的内容,和包装里的卡片逐字一致。"
    static let promiseSectionTitle = "可承诺的三件事"
    static let promises: [Item] = [
        Item(title: "按住才听", body: "不按住,麦克风不工作。"),
        Item(title: "它记得你,而且记忆永久免费", body: "记忆可查、可改、可删;不进任何付费口径。"),
        Item(title: "就算有一天服务停了,它还是一尊手办", body: "造型、收藏、离线底稿、陪伴计数、底座刻痕都留在你手里。不承诺停服后仍会说话。"),
    ]
    static let stopServiceTitle = "停服后失效的东西"
    static let stopServiceItems = "对话 · 主动开口 · 内容更新 · 社区 · 订阅权益"
    static let stopServiceNotes = [
        "我们会在停服前 12 个月通知,并把你的档案交付给你;",
        "在那之前,订阅只卖「更多」,不卖「别失去」。",
    ]

    // 契约卡(certificate / onboarding 签署)—— 四条逐字
    static let contractTitle = "契约卡 · 我们永不做的四件事"
    static let contractItems = [
        "· 永不静默改变它的性格",
        "· 永不擅自删除你的记忆",
        "· 停服前 12 个月通知,并交付档案",
        "· 记忆永久免费,不进任何付费口径",
    ]
    static let contractSignNote = "每一次签署都留档;条款只会加,不会偷偷改。"

    // 商店 · 永久免费区(store/free;首屏横幅共用标题)
    static let freeZoneTitle = "永久免费区"
    static let freeZoneBanner = "对话、记忆、按键互动、离线底稿 —— 不花钱也不缺"
    static let freeZoneIntro = "这些不会因为你没有付费而少一点"
    static let freeZoneItems = [
        "对话(按对话时长计量,按时间回血)",
        "它记得你(长期记忆)",
        "按键互动(两个动作)",
        "离线底稿(断网也在)",
    ]
    static let paidIsMoreTitle = "付费只买「更多」"
    static let paidIsMoreBody = "更多角色包 · 更多外观 · 更多连载 · 更多信物。"
    static let storeFooterNote = "标注「永久免费」的东西,不会因为你没有付费而少一点。付费只买「更多」——更多角色、更多外观、更多连载、更多信物。"

    // 设备两动作(device/manual)—— 三处一致:包装卡 / 开箱第一句 / 本页
    static let manualTitle = "它的两个动作"
    static let manualIntro = "包装卡、开箱第一句、本页,说的是同一件事"
    static let deviceActions: [Item] = [
        Item(title: "按住说话", body: "按住头顶那颗按键,松开,它就开口。"),
        Item(title: "播放中按键打断", body: "它在说的时候,按一下,它就停。"),
    ]
    static let manualFooter = "没有更多手势了;其余一切都在手机 App 里完成。"

    // 绑定(device/bind)
    static let bindTitle = "绑定手办"
    static let bindIntro = "两种都可以;不强制,先领一只「虚拟手办」看看也行"
    static let bindOptions: [Item] = [
        Item(title: "扫码绑定", body: "底座二维码一扫即连"),
        Item(title: "手动输入 SN", body: "底座或说明书上的序列号"),
    ]
    static let bindFooter = "不想现在绑定也可以跳过;开箱仪式里的每一步都能断点续做。"

    // BLE 配网(device/provision)
    static let provisionIntro = "把手机上的 WiFi 发给手办,大约 30 秒"
    static let provisionPrivacy = "密码只进手办,不进云端;写入只走蓝牙加密通道(Security 1)。"

    // 开箱仪式(onboarding)—— `19` §6.1 六步,每步可跳过、断点续做
    static let onboardingIntroTitle = "装备须知"
    static let onboardingHeadline = "它到了之后,你会怎么用"
    static let onboardingIntroItems = [
        "永久免费,不用花钱也能用",
        "需要付费的,只是「更多」",
        "互动对象是人工智能,不是真人",
    ]
    static let onboardingSkippable = "每一步都可以跳过;断点续做。"
    static let onboardingAdoptTitle = "给它起个名字"
    static let onboardingAdoptIntro = "它把第一次叫出这个名字,当成你们的开始"
    static let onboardingCardTitle = "第一张角色卡"
    static let onboardingCardIntro = "它免费进你的收藏柜,永远属于你"
    static let onboardingSignTitle = "把它说过的话,按一下手印"
    static let onboardingSignIntro = "这四件事,它永远不做"
    static let onboardingDoneHeadline = "好了,它认识你了"
    static let onboardingFirstWords = "「从今天起,我记着你。」"

    // 档案与记忆
    static let memoryIntro = "可查 · 可改 · 可删 · 记忆永久免费"
    static let memoryDeleteNote = "你删掉的会立刻消失;系统淡忘的会进「已淡忘」档案,你可以把它捡回来。"
    static let memoryEditNote = "删除会立刻消失,不可找回;置顶会永远不被淡忘。"
    static let sealIntro = "说一次,它就永不再提"
    static let sealNote = "封存的内容不会被它提起,也不会用来回应你;你随时可以解封。"

    // 资产账(archive/assets)—— 只增不减
    static let assetsIntro = "只增不减 · 每一件都有来处"
    static let assetsNote = "每件东西什么时候来的,都记在这里;任何一件都不会自己消失,也不会被我们收回。"

    // 分享脱敏(PRD §8:分享卡默认脱敏,发言变「你」)
    static let shareIntro = "把它喜欢的样子,分享给更多人"
    static let shareNote = "分享出去的是图片;好友打开的是网页 \"/s/:token\",里面只有公开信息,没有你说过的话。"

    // 退出与删除(me/exit;合规:一键退出,文案禁「别离开」类)
    static let exitTitle = "退出与删除"
    static let exitIntro = "你想走的每一步,都应该是安静的"
    static let exitNote = "我们不会用「再想想」拦住你,也不会在你删完之后把数据留在你拿不到的地方。"

    // 通知与隐私(me/settings)
    static let privacyItems: [Item] = [
        Item(title: "新内容提醒", body: "每周一次 · 不推广告"),
        Item(title: "授权管理", body: "相机 / 蓝牙 / 麦克风"),
        Item(title: "原声与录音的使用", body: "默认不用于训练"),
    ]

    // 兑换码(store/redeem)
    static let redeemIntro = "实体卡上的码,这里换成线上权益;二维码在包装与说明书里都能找到。"

    // 空态(未配服务器 / 无数据时,真实空态,不放示例数据)
    static let emptyCharactersTitle = "领养第一只手办"
    static let emptyCharactersNote = "它会以一个新角色开始"
    static let emptyMemoriesTitle = "还没有记忆"
    static let emptyMemoriesNote = "第一次对话之后,这里就会有它记得的事"
    static let emptyStoreTitle = "货架还没上架"
    static let emptyStoreNote = "服务端商店接口(14 §5.4 #11)就绪后,这里会出现角色、外观、语音、事件、实物五架"
    static let emptyCommunityTitle = "官方周更准备中"
    static let emptyCommunityNote = "社区 M1 开闸;本期仅官方内容,不需要你做任何事"

    // 设备设置(device/settings)
    static let deviceSettingsNote = "本页没有音量、灯效等硬件控制项 —— 设备侧在 MVP1 冻结(`18` v1.2)。"
    static let nightQuietLabel = "夜间静默(22:00–08:00)"
    static let nightQuietNote = "服务端策略,在服务器侧生效"

    // 聊天页(ChatView)
    static let chatSendHint = "说点什么…"
    static let chatDeviceHint = "按一下设备按键,可以让它在手办上接这句(需固件 G1)"
}

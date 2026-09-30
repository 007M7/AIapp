# app · MVP1 初版 app demo(可点开的高保真原型)

> 生成于 2026-09-30。**依据**:`19-miniprogram-ia-prd.md` v1.2(页面树/流程/验收)、`20-asset-and-art-inventory.md`(素材与美术红线)、`17` §3.4(承诺文本)、`18` v1.2(设备侧冻结)、角色设计依三视图参考图重绘。
> **性质**:**初版 demo**——结构与交互是完整的,文案内容是初版(需按后续优化迭代)。**不是小程序代码工程**,是给设计/开发对齐用的可交互原型。

## 怎么用

| 文件 | 说明 |
|---|---|
| **`index.html`** | **交互版**:双击用浏览器打开,点 Tab 与卡片可在 33 个页面间跳转(hash 路由) |
| `CONTENT.md` | **内容规范 + 文案优化记录**:四条内容纪律 · 禁用词表 · 推荐句库 · 逐页改动 · 待优化项 —— 已移到 [`../docs/CONTENT.md`](../docs/CONTENT.md)(本仓的文档统一放 `docs/`) |
| `pages/*.html` | 33 个**独立页面**,可直接打开单页(也是截图与评审的单位) |
| `overview.html` | 8 屏并排总览(内嵌 iframe) |
| `*.png` | 26 张关键页面的 2 倍分辨率截图(390×900 @2x) |
| `src/core.mjs` | 设计令牌 / 图标 / **角色矢量图** / 机壳 / 页面外壳 |
| `src/build-app.mjs` | 33 个页面的内容定义 + 生成逻辑(`npm run build` 重出) |

## 覆盖范围(33 页,对齐 PRD §4.2 页面树)

| 域 | 页面 |
|---|---|
| **手办**(Tab1) | `hand/today` |
| **档案**(Tab2) | `archive/index` 收藏册 · `character` 角色详情 · `memory` 记忆面板 · `memory-edit` 编辑 · `seal` 封存 · `assets` 资产账 · `timeline` 年历 · `certificate` 出生证与契约 · `share-card` 分享卡 |
| **社区**(Tab3) | `community/index` · `featured` 精选 · `detail` 角色包详情 |
| **商店**(Tab4) | `store/index` · `detail` 商品详情 · `free` 永久免费区 · `redeem` 兑换码 · `orders` 订单(P1) |
| **我的**(Tab5) | `me/index` · `promise` 服务连续性承诺 · `exit` 退出与删除 · `settings` 通知与隐私 · `help`(P1) |
| **设备** | `device/bind` 绑定 · `provision` BLE 配网(五态) · `manual` 按键说明 · `settings` 设备设置 |
| **开箱仪式** | `onboarding/intro` 装备须知 → `bind` 绑定 → `adopt` 认主 → `first-card` 第一张角色卡 → `sign` 契约签署 → `done` 完成页 |

## 角色:深蓝女仆鲸娘(依参考图重绘的**矢量站位稿**)

按三视图参考图重画:深海蓝渐变长发 · **头顶卷曲天线** · **鲸鳍耳** · 白蕾丝女仆头饰 + 浅蓝蝴蝶结 · 白围裙 + **鲸鱼刺绣** · 深蓝长裙 + 金蝴蝶结 · **身后鲸尾** · 白蕾丝短袜 + 深蓝玛丽珍鞋。
**⚠️ 这是占位稿,不是正式立绘**——用途是让版面/配色/信息层级可评估;正式立绘按 `PROMPTS-ASSETS.md` 的母版链产出后再置换(置换成 PNG 即可,版面尺寸已预留)。

**一处必须在造型定稿前解决的冲突**:产品要求"**按住头顶那颗按键**"说话,而参考图的天线正在头顶正中。三选一已写在 `PROMPTS-v2-maid.md` §7:**① 把天线做成按键本身(推荐)· ② 天线柔性可让位 · ③ 天线移到侧后方**。

## 本稿遵守的约束(逐条自检)

- ✅ **无进度条 / 无红点 / 无好感度数值**(`14` 红线#3)——"进度感"只由文字与印记承担
- ✅ **首页常驻 AI 身份标识**("本产品为人工智能合成语音,互动对象不是真人")
- ✅ **商店首屏必现"永久免费区"横幅**;商品详情明示免费/付费边界
- ✅ **承诺页与契约卡文本逐字对齐 `17` §3.4**(含"停服后失效清单")
- ✅ **设备交互只出现两个动作**(按住说话 / 播放中按键打断),与 `18` v1.2 冻结一致;无音量等硬件控制项
- ✅ **无挽留式设计**;`me/exit` 文案无"别离开我"类
- ✅ 分享素材默认脱敏(分享卡只含资产事实,不含记忆)

## 重新生成

```bash
cd docs/product/mockups/src/app && node build-app.mjs
# 截图(可选):对 pages/*.html 逐个跑
CHROME="/c/Program Files/Google/Chrome/Application/chrome.exe"
for f in hand_today archive_index archive_character archive_certificate archive_share-card \
         store_index store_detail store_free me_promise onboarding_done; do
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 \
    --window-size=390,900 --virtual-time-budget=3000 \
    --screenshot="$PWD/pages/../$f.png" "file://$PWD/pages/$f.html"
done
```

改色板改 `core.mjs` 的 `T`;改角色改 `core.mjs` 的 `maidGirl()`;改页面内容改 `build-app.mjs`。

## 已知不足(下一轮)

1. **文案已过一轮优化(2026-09-30)**:按 `12/13/15/16/17` 重写了 6 个页面的文案,禁用词扫描 0 命中(唯一一处"陪伴"是承诺文本里的功能名"陪伴计数",来自 `17` §3.4,属既有术语)。**仍需再优化**:4 个 Tab 的空态文案、角色语气库(建议 20~30 句角色口吻样例,供人格卡复用)。详见 `CONTENT.md` §5。
2. **角色是矢量占位**:待正式立绘;表情差分、空态插画、动效(D1~D5)、社区 banner 与分享卡模板尚未做(见 `20` §3~§5)。
3. **P1 页面从简**:`timeline` / `orders` / `help` / `gallery` / `activity` 只留占位。
4. **BLE 配网五态是静态展示**:真实五态需与 `miniprogram/` 现有实现对接。
5. **本目录未 git commit**(仅落在磁盘上)。

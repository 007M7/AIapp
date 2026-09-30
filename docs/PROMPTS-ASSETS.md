# 角色资产图出图提示词(母版链,可持续复用)

> **本文件解决一件事**:让后续所有出图**不漂**。
> 做法:先产出一套**母版资产**(三视图 / 表情差分 / 细节特写 / 色彩标定 / 比例图 / 服装分解),之后每一次新图都以母版为**引用源**(MJ `--cref`、SD 的 IP-Adapter / reference-only),而不是重新描述角色。
> 关联:`PROMPTS.md`(单图用途变体)、`20-asset-and-art-inventory.md`(§9 六条美术红线)、`14` §2(角色包 = core 魂 / skin 身体)。
> **本机无文生图能力**,以下提示词用于外部工具(Midjourney / SD·ComfyUI / 即梦 / 万相)。

---

## 0. 资产清单(先看这张表:要产出什么、给谁用)

| 编号 | 资产名 | 用途 | 谁消费 | 画幅 | 优先级 |
|---|---|---|---|---|---|
| **A0** | **冻结锚定段**(不是图,是文本) | 所有出图的固定开头;**任何一次都不许改一个字** | 出图流程 | — | **P0** |
| **A1** | **三视图 turnaround**(正/侧/背) | 后续所有图的**引用源**;同时给**手办本体造型**当参考 | 出图 + 设计侧 | 3:2 | **P0** |
| A2 | **表情差分 8 格** | 小程序空态、分享卡、社区 banner | 小程序 | 3:2 | **P0** |
| A3 | 细节特写(发饰 / 呆毛 / 领结 / 伴游鲸) | 卡面局部、周边物料、手办开模细节 | 出图 + 设计侧 | 1:1 | P1 |
| A4 | 色彩与材质标定卡 | 交接给美术的色值/材质基准 | 设计侧 | 1:1 | **P0** |
| A5 | 比例/身高设定图 | 手办本体的头身比与体块 | 设计侧 | 2:3 | P1 |
| A6 | 服装分解图 | 娃衣/换装线(配件复购) | 设计侧 + 内容 | 3:2 | P1 |
| A7 | 手办化质感参考(可选) | 给设计侧看"立绘 → 实物"的材质方向 | 设计侧 | 1:1 | P2 |

---

## 1. A0 冻结锚定段(每次出图的第 0 段,逐字复制,不改标点)

**中文**

> 原创角色「小鲸」:安静的 18 岁少女,来自深海。冷白肤色;及腰长发,发色自深海的深蓝(#2B4CC9)渐变到近浅海的淡蓝(#9FD3FF),**发根深、发梢浅**;两侧各别一枚**鲸鱼尾鳍造型的发饰**;头顶一缕**鲸鱼喷水造型的呆毛**(水滴状,淡青 #8FD8F5);青绿色虹膜(#7FD4E8),眼睛大而圆但不过度夸张;细眉、微微一笑。穿白色上衣,宽大的深海蓝水手领(#2B4CC9),领口正中一枚**青绿色菱形领结**。气质:安静、慢热、话不多。画风:日系平涂 / 赛璐璐上色,线条干净,双色阴影,成人向插画;不要写实、不要 3D、不要儿童向。

**English**

> Original character "Xiaojing" — a quiet 18-year-old human girl from the deep sea. Cool pale skin; waist-length hair with deep-sea-to-shallow blue gradient (roots #2B4CC9 → tips #9FD3FF); a pair of whale-tail-fin hair ornaments on both sides; a single whale-spout ahoge on top, droplet-shaped, pale cyan #8FD8F5; cyan-teal irises (#7FD4E8), eyes large and round but not exaggerated; soft brows, faint smile. White top with a wide deep-blue sailor collar (#2B4CC9) and a cyan diamond necktie knot. Temperament: calm, slow to warm, few words. Style: Japanese cel-shaded flat anime illustration, clean lineart, two-tone shading, adult-oriented; NOT photorealistic, NOT 3D, NOT childlike.

**色值基准**(与 `mockups/src/build-mockups.mjs` 的 `T` 对象同源;改色板要两边一起改)

| 用途 | 色值 |
|---|---|
| 发色·发根 | `#2B4CC9` |
| 发色·中段 | `#5B86FF` |
| 发色·发梢 | `#9FD3FF` |
| 辅色(呆毛/领结/气泡) | `#7FD4E8` · 呆毛亮部 `#8FD8F5` |
| 描边 | `#17202E`(不透明度约 90%) |
| 纸感底 / 卡底 | `#FBF8F1` / `#EDF3FF` |

---

## 2. A1 三视图(核心资产,先出这一张)

**追加在 A0 之后的段落(中)**

> **角色设定三视图**:左侧**正面全身**、中间**侧面全身**、右侧**背面全身**,三个角度**等高等大、并排站立、朝向一致、姿态中性自然(A-pose,双手自然下垂)**;
> **纯白背景,无阴影投射在地面,无场景、无道具**;
> **不要任何文字、不要标注线、不要色卡、不要边框、不要分格线**;
> **全身完整入画,头顶与脚底各留约 8% 空白**;线条清晰、色块干净,便于他人照着画。

**English**

> **Character model sheet, three views**: full-body **front**, **side**, and **back**, side by side, **same height and scale, identical neutral A-pose, consistent facing**; **plain white background, no cast shadow, no scenery, no props**; **no text, no labels, no color swatches, no border, no panel dividers**; **full body in frame with ~8% margin above head and below feet**; clean lineart and flat colors, readable enough for another artist to copy.

**参数**:`--ar 3:2`(**MJ 建议 `--niji 6`;或用 SD + "character sheet / turnaround" 类 LoRA —— 三视图一致性 SD 更稳**)。出图 **8~12 张挑一张**,定稿后**记下 seed 与文件名**(填进 §6 台账)。

**⚠️ 三个已知失败与修法**

| 失败现象 | 修法 |
|---|---|
| 三个角度**不是同一个人**(发饰数量、领结形状不一致) | 追加:"三视图为同一角色的不同角度,发型、发饰、领结、瞳色完全一致" |
| 图里出现**乱码文字/标注线/色块** | 负向词加重 `text, labels, annotations, color palette, arrows, dividers, border`;AI 出不了可用文字,**标注一律后期在 Figma 里加** |
| 画成**儿童/幼儿体型** | 追加"成年人比例,身高约 6 头身",并在负向词保留 `child, toddler, loli` |

> **一条工程提醒(重要)**:产品要求**按键在头顶**(按住说话),所以**实体手办的头顶必须留出按键行程**——立绘上的"喷水呆毛"在实物上要么做成**贴伏/可让位**,要么**移到侧后方**。这一条请在 A5 比例图里明确标出。

---

## 3. A2 表情差分(8 格)

> 在 A0 之后追加:**同一角色的表情差分表,八格等大,每格为头部特写到肩**,依次为:① 安静平常 ② 微微高兴 ③ 认真倾听 ④ 困惑(**不要夸张**)⑤ 犯困(眼睛半闭、轻轻打哈欠)⑥ 被夸到不好意思(轻微脸红、移开视线)⑦ 有点小情绪(嘴微抿)⑧ 闭上眼睛的安心表情。**纯白背景、无文字、无边框、人物比例与头部大小完全一致。**
> **Expression sheet, eight equal cells, head-and-shoulders each**: calm / softly happy / listening intently / mildly puzzled / sleepy / shyly flustered / slightly sulky / eyes closed content. Plain white background, no text, no border, identical head size across cells. `--ar 3:2`

**注意**:⑧ 张里**不要出现哭泣、惊恐、愤怒**——与产品气质不合,且陪伴类内容有合规敏感度。

---

## 4. A3 细节特写 / A4 色彩标定 / A5 比例图 / A6 服装分解

**A3 细节特写**(`--ar 1:1`)
> 四个局部特写并排:① 鲸鱼尾鳍发饰(正视 + 侧视)② 头顶喷水呆毛(含水滴形高光)③ 水手领与青绿菱形领结(正面俯视)④ 伴游小鲸(深蓝剪影,非拟人)。纯白背景,无文字,无标注线。

**A4 色彩与材质标定卡**(`--ar 1:1`)
> 角色头像居中,四周环绕**从她身上提取的色块**:发根 / 发中 / 发梢 / 瞳色 / 领结 / 描边 / 底色,每块为方形纯色。色块不含文字。
> ⚠️ 色块**数量与顺序固定为 7 块**(见 §1 色值表),出图后由人工把色值文字标上 —— **不要让模型写数字**。

**A5 比例/身高设定图**(`--ar 2:3`)
> 角色全身正面立姿,右侧标注等比刻度(1 头身到 6 头身),左侧一条垂直线贯穿全身;**头顶按键位用一个小圆点示意**(表达"这一处留给按键")。素色背景、无多余文字。
> **本图是给手办本体造型的输入**:请在交付时同时说明两种比例 —— **约 3 头身(大头身,便于把主板与按键放进头部)** 与 **约 6 头身(收藏手办常态)**,由设计侧定。

**A6 服装分解**(`--ar 3:2`)
> 同一角色的上衣拆解图:白色上衣、深海蓝水手领、青绿菱形领结、袖口与下摆细节,分件平铺;纯白背景,无文字。
> **用途**:娃衣/换装线是配件复购的主体(`13`:配件占用户支出 33%),服装分解是后续换装 SKU 的结构基础。

---

## 5. 复用协议(把母版变成"可反复利用"的关键)

### 5.1 出完 A1 之后,所有新图都走引用,不再重新描述角色

**Midjourney**

```
[新场景描述] --cref <A1定稿图URL> --cw 80 --niji 6 --style raw --s 150 --ar <按用途>
```
`--cw 80` 保留大部分角色特征但允许服装/姿态变化;要**严格锁脸锁服装**用 `--cw 100`。
可另加 `--sref <A4色标卡>` 锁色调。

**SD / ComfyUI**:IP-Adapter(角色图)+ reference-only ControlNet;先出 A1 存成固定参考图,**同一 seed + 同一 LoRA 组合**;换场景只改 prompt 的场景段落。

### 5.2 通用出图模板(槽位固定,只填场景)

```
【A0 冻结锚定段(逐字不动)】
+ 姿态:______(例:半身偏侧、略微回头)
+ 构图:______(例:人物居中 / 人物偏右下)
+ 场景:______(例:极简深海渐变 / 深海光柱与极淡气泡 / 纯色)
+ 光线:______(例:柔光、整体偏亮便于叠字)
+ 留白:______(例:上方 10%、左侧 45% 留空)
+ 画幅:______
【负向词:统一用 §7 那份】
```

### 5.3 六个已填好的常用组合(直接抄)

| 用途 | 姿态 / 构图 / 场景 / 留白 | 画幅 |
|---|---|---|
| 收藏册卡位 | 半身居中、微俯视 / 极简深海渐变 / 上方 10% 下方 12% | 1:1 → 裁 1:1.1 |
| 详情页 hero | 半身偏侧回头、发梢轻飘、右下伴游鲸 / 深海光柱 + 极淡气泡 / 上方留白 | 3:2 |
| 头像 | 头肩正面平视 / 纯色 #EDF3FF | 1:1 |
| 分享卡底图 | 人物偏右下、占幅 45% / 左侧与上方大片干净留白 | 3:4 |
| 社区 banner | 半身、留出右侧 60% 给标题 / 抽象深海色块 | 16:9 |
| 聊天表情贴纸 | 头肩、夸张一点点但不失气质 / 透明底或纯色底 | 1:1 |

### 5.4 纪律(这三条决定资产能不能复用)

1. **A0 是冻结文本**:任何一次出图都不许改一个字、不许"顺手润色"。角色漂移几乎都源于此。
2. **每次出图都记台账**(§6):seed、参考图版本、提示词版本。否则一个月后没人知道哪张是母版。
3. **母版变更要升版本**:若确实要改角色(例如发饰从一枚改两枚),**A1 重出并升 v2`,旧图作废**——不要新旧混用。

---

## 6. 资产台账(建议直接拷成表格维护)

| 编号 | 版本 | 文件名 | seed | 引用源 | 定稿日期 | 备注 |
|---|---|---|---|---|---|---|
| A1 | v1 | `char-A1-turnaround-v1.png` | 待填 | —(母版) | | 后续所有图的 cref 源 |
| A2 | v1 | `char-A2-expressions-v1.png` | | A1 | | |
| A4 | v1 | `char-A4-palette-v1.png` | | A1 | | 色值后期标注 |
| … | | | | | | |

---

## 7. 统一负向词(全资产通用)

> **英文**:text, watermark, signature, logo, brand mark, labels, annotations, arrows, color swatches, panel dividers, border, extra hands, extra fingers, deformed hands, bad anatomy, photorealistic, 3D render, plastic look, child, toddler, loli, petite childlike proportions, oversaturated, noisy, cluttered background, extra characters, weapons, revealing outfit, sexualized, crying, glasses, screens, phone, anthropomorphic whale, furry, fish head
>
> **中文**:文字, 水印, 签名, logo, 品牌标识, 标注线, 色卡, 分格线, 边框, 多手, 多指, 手部畸形, 五官错位, 写实, 3D 渲染, 塑料感, 儿童, 幼儿, 幼态, 过曝, 噪点, 杂乱背景, 多余人物, 武器, 暴露服装, 性暗示, 哭泣, 眼镜, 屏幕, 手机, 鲸鱼拟人, 兽人, 鱼头

---

## 8. 三条别踩的坑

1. **不要指望 AI 在图上写字**。所有标注、色值、刻度**一律后期加**(Figma/PS);模型生成的中文标注必然是乱码,而带乱码的"设定稿"没法交接给美术。
2. **三视图用于"看方向",不能直接当工程图**。手办开模需要美术按结构重绘(尤其是发饰的固定方式、水手领的厚度、头顶按键的让位)。给设计侧交付时要写清这一点。
3. **商标**:角色保持"深海母题"的自研原创设定,**不要把任何公司的鲸鱼 LOGO 画进去**;对外物料前按既有结论解决授权(最省事的路是自研原创,不绑定品牌)。

---

## 9. 建议的执行顺序

```
A0 冻结文本(5 分钟,一旦定下就别改)
  → A1 三视图(多抽 8~12 张,定稿 + 记 seed)   ← 关键一步,后面全靠它
    → A4 色彩标定(锁色)
      → A2 表情差分 / A3 细节特写 / A5 比例图 / A6 服装分解
        → 之后所有业务图一律"引用 A1 出图"(§5.1)
```

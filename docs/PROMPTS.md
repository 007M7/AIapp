# 角色卡出图提示词(DeepSeek 鲸鱼娘 · 「小鲸」)

> 用途:本机无文生图能力,以下提示词用于**外部出图工具**(Midjourney / SD·ComfyUI / 即梦 / 万相 / GPT-image 等)。
> 目标:产出可直接嵌入 `mockups/` 那批高保真稿的**角色卡图片**——配色、构图位、留白都按现有版面预留。
> 关联:`20-asset-and-art-inventory.md`(B9/B10/C1~C4 与 §9 六条美术红线)、`03-character.png` 的 hero 区、`02-archive.png` 的卡位。
> **母版资产(三视图 / 表情差分 / 色彩标定 / 比例图 / 服装分解)见 [`PROMPTS-ASSETS.md`](PROMPTS-ASSETS.md)。建议顺序:先出母版并冻结,再用本文件出各业务图。**

---

## 0. 先说三条最容易翻车的点

1. **不要把「鲸鱼娘」直译成 `whale girl`**。英文模型会理解成**拟人鲸鱼**(长出鲸鱼头/鳍/尾巴的兽人),中文模型也可能画成鲸鱼拟人。必须写成 **"human girl with whale motifs / whale-tail hair ornaments"**(人类少女 + 鲸鱼母题配饰)。
2. **别让模型复刻 DeepSeek 的官方鲸鱼 LOGO**。「深海鲸鱼」是母题意象,**商标图形不是**——复刻它会同时踩建模人的商标权,并让图变成"品牌物料"。
3. **必须显式排除儿童向**。默认二次元模型会把人画小(脸圆、眼巨大、身高矮),而本产品的红线是"成人向、不做未成年人向"(`15` §6.6)。负向词里一定要压 `child / toddler / loli / 儿童 / 幼儿`。

---

## 1. 角色锚定段(每次出图都必须带上,保证同一角色)

**中文**

> 原创角色「小鲸」:一名安静的 18 岁少女,来自深海。冷白肤色;**及腰长发,发色自深海的深蓝(#2B4CC9)渐变到近浅海的淡蓝(#9FD3FF),发根深、发梢浅**;两侧各别一枚**鲸鱼尾鳍造型的发饰**;头顶一缕**鲸鱼喷水造型的呆毛**(水滴状,淡青 #8FD8F5);青绿色虹膜(#7FD4E8),眼睛大而圆但**不过度夸张**;细眉、微微一笑。穿白色上衣,**宽大的深海蓝水手领**(#2B4CC9),领口正中一枚**青绿色菱形领结**。气质:安静、慢热、话不多。
> 画风:**日系平涂 / 赛璐璐上色,线条干净,双色阴影,成人向插画**;不要写实、不要 3D、不要儿童向。

**English**

> Original character "Xiaojing" — a quiet 18-year-old human girl from the deep sea. Cool pale skin; **waist-length hair with a deep-sea-to-shallow gradient (roots #2B4CC9 → tips #9FD3FF)**; a pair of **whale-tail-fin hair ornaments** on both sides; a single **whale-spout ahoge** on top, droplet-shaped, pale cyan #8FD8F5; **cyan-teal irises (#7FD4E8)**, eyes large and round but **not exaggerated**; soft brows, faint smile. Wearing a white top with a **wide deep-blue sailor collar (#2B4CC9)** and a **cyan diamond necktie knot**. Temperament: calm, slow to warm, few words.
> Style: **Japanese cel-shaded flat anime illustration, clean lineart, two-tone shading, adult-oriented**; NOT photorealistic, NOT 3D, NOT childlike.

---

## 2. 四个用途变体(分别对应现有版面)

### ① 角色卡主图 —— 用于 `02-archive` 收藏册卡位(1:1,按 1:1.1 裁)

在锚定段后追加:

> **半身构图,人物居中,略微俯视镜头;背景为极简的深海蓝浅渐变(左上 #EDF3FF → 右下 #C7DBFF),无场景、无道具、无文字**;人物上方留出约 10% 空白(呆毛不被切),下方留出约 12%(肩部自然收进卡底)。

> Half-body, centered, slight high-angle; **minimal deep-sea blue gradient background (#EDF3FF → #C7DBFF), no scenery, no props, no text**; ~10% headroom above so the ahoge is not cropped, ~12% room below.

**尺寸**:1024×1024 出图 → 裁 1:1.1(约 1024×1126)。**MJ**:`--ar 1:1`

---

### ② 角色详情 hero —— 用于 `03-character` 顶部大图(3:2)

> **半身偏侧、略微回头,发梢有轻微飘动;右下角一只小小的伴游鲸(深蓝色小鲸剪影,不要拟人、不要大)**;背景是**深海光柱与极淡气泡**,整体亮度偏亮,便于上方叠加文字;无文字、无边框。

> Half-body turned slightly, glancing back, hair tips with a light drift; **a small companion whale in the lower right** (deep-blue silhouette, non-anthropomorphic, small); background: **deep-sea light shafts and very faint bubbles**, bright overall; no text, no frame.

**尺寸**:1536×1024。**MJ**:`--ar 3:2`

---

### ③ 头像 —— 用于作者署名 / 列表 / 消息位(1:1)

> **头部特写到肩,正面,平视;背景纯色(#EDF3FF)**;表情温和、眼神安静;不要配饰超载(只保留两侧鲸尾发饰 + 喷水呆毛)。

**尺寸**:1024×1024。**MJ**:`--ar 1:1`

---

### ④ 分享卡背景 —— 用于 `share-card` / `/s/:token`(3:4,大片留白可压字)

> **人物偏右下方,占画面约 45%;左侧与上方留出大面积干净的深海渐变留白(用于叠加文字)**;不要居中、不要满构图、不要复杂背景。

**尺寸**:1152×1536。**MJ**:`--ar 3:4`

---

## 3. 负向提示词(必带)

**中文**

> 文字, 水印, 签名, logo, 品牌标识, 多手, 多指, 断肢, 手部畸形, 五官错位, 写实照片, 3D 渲染, 塑料感, 儿童, 幼儿, 幼态, 矮小身材, 过曝, 噪点, 杂乱背景, 多余人物, 武器, 暴露服装, 性暗示, 哭泣, 眼镜, 屏幕, 手机, 电子设备, 鲸鱼拟人, 兽人, 鱼头

**English**

> text, watermark, signature, logo, brand mark, extra hands, extra fingers, missing limbs, deformed hands, bad anatomy, misplaced facial features, photorealistic, 3D render, plastic look, child, toddler, loli, petite childlike proportions, oversaturated, noisy, cluttered background, extra characters, weapons, revealing outfit, sexualized, crying, glasses, screens, phone, gadgets, anthropomorphic whale, furry, fish head

---

## 4. 参数建议

| 工具 | 建议 |
|---|---|
| **Midjourney** | 用 **`--niji 6`**(日系二次元更准);`--ar` 按上表;`--style raw` 降低"过度美化";`--s 120~180`(别太高,否则脸会更幼) |
| **SD / ComfyUI** | 采样 `DPM++ 2M Karras`;步数 28~32;CFG 5~7;原生 1024;可挂二次元 negative embedding;`Hires fix` 1.5× 提升发丝边缘 |
| **即梦 / 万相** | 风格选「动漫 / 二次元」,写实度调低;开启"人物主体"控制;比例按上表选 |
| **单张一致性** | 固定同一 seed;**MJ 用 `--cref <已定稿角色图> --cw 80`**;SD 用 IP-Adapter 或 reference-only ——**先出一张"角色三视图设定稿",之后所有图都以它为参考** |

> **一条实用做法**:先按锚定段 + 变体①出 **6~8 张**,挑一张定稿;**再用它做字符参考**去出②③④。比每张都重新抽要省得多,也能保证四张图是"同一个它"。

---

## 5. 验收标准(出图后自检,过了再放进版面)

1. **三要素必须同时可辨**:鲸鱼尾鳍发饰 · 喷水呆毛 · 水手领 + 青绿菱形领结。缺任何一个就重出。
2. **渐变方向正确**:发根深蓝 → 发梢浅蓝(反了就是另一个人)。
3. **背景干净**:纯色或极简渐变,能直接叠在版面卡底 `#EDF3FF` 上;**不得有文字/水印/边框**。
4. **裁切安全**:1:1 裁成 1:1.1 后,脸不被切、头顶留 ≥8%、肩部自然收边。
5. **气质成年**:脸型不过圆、眼睛不过大、无儿童向元素、无性暗示。
6. **无商标图形**:不出现任何公司 LOGO 或品牌标识(包含但不限于 DeepSeek 官方鲸鱼标)。

---

## 6. 法律提醒(与本线既有结论一致)

「DeepSeek 鲸鱼娘」引用了第三方品牌。按本线既有结论(`12` §4/§8、`16` 号"联名仅作预选"):
- **内部 demo 使用无碍**;
- **一旦进入对外物料或量产 SKU,须先解决商标 / 形象授权**——包括"鲸鱼娘"这个称呼本身与角色视觉的关联方式;
- 最省事的做法是**把角色发展方向定为"自研原创角色 + 深海母题"**(不绑定任何品牌),这也正是 `13` 号研究给出的结论:**IP 授权费不可承受,自研原创角色是成本上唯一可行路线**。

---

## 附:一句话快用版(赶时间时直接复制)

> 日系赛璐璐平涂,成人向插画。一名安静的 18 岁少女半身像,来自深海:及腰长发自深蓝 #2B4CC9 渐变至淡蓝 #9FD3FF(发根深发梢浅),两侧别鲸鱼尾鳍造型发饰,头顶一缕鲸鱼喷水造型的水滴形呆毛,青绿色虹膜,眼睛大而圆但不过度夸张,微微一笑;白色上衣配宽大深海蓝水手领与青绿菱形领结。背景为极简深海浅蓝渐变,无场景无道具无文字,人物居中,上方留白 10%。**不要儿童向,不要 3D,不要写实,不要鲸鱼拟人。**

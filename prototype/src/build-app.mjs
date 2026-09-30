// 初版 app demo 生成器:把 PRD 页面树做成可点开的高保真原型
// 用法:node prototype/src/build-app.mjs   → 输出到 prototype/(本文件的上两级)
import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { T, FONT, HAND, icon, maidGirl, statusbar, aiBadge, tabbar, subHeader, cap, pill, css } from "./core.mjs";

const OUT = resolve(dirname(fileURLToPath(import.meta.url)), ".."); // prototype/
mkdirSync(OUT + "/pages", { recursive: true });

const breath = () => `<div style="width:96px;height:96px;margin:0 auto;border-radius:50%;background:radial-gradient(circle,rgba(62,99,176,.22) 0%,rgba(62,99,176,.1) 50%,transparent 72%);border:1px solid #D3E0F4;display:flex;align-items:center;justify-content:center"><div style="width:32px;height:32px;border-radius:50%;background:radial-gradient(circle at 35% 32%,#BFD4F2,#3E63B0 72%);box-shadow:0 0 22px rgba(62,99,176,.5)"></div></div>`;
const divider = () => `<div class="rule" style="margin:12px 0"></div>`;
const li = (l, r = "") => `<div class="row" style="padding:12px 0;border-bottom:1px solid ${T.line}"><span style="font-size:13.5px">${l}</span><span class="tiny">${r}</span></div>`;
const avatar = (size = 56) => `<div class="avatar" style="width:${size}px;height:${size}px;flex:none">${maidGirl("avatar")}</div>`;
const hero = (vb = "54 52 212 236", h = 250) => `<div class="square" style="height:${h}px">${maidGirl(vb)}</div>`;

/* ================= 5 个 Tab 页 ================= */
const handToday = `
<div class="row" style="margin:2px 0 12px">
  <div><h1>今天</h1><p class="sub" style="margin:0">小鲸 · 在桌上的第 47 天</p></div>
  ${pill(`${icon("月亮", 15, 1.5)}夜间静默`, true)}
</div>
<div class="card" style="padding:22px 16px;text-align:center">
  ${breath()}
  <div style="font-size:15.5px;font-weight:600;margin-top:16px">它在桌上</div>
  <div class="tiny" style="margin-top:7px;line-height:1.7">按住头顶那颗按键,它就听你说;松手,它才开口<br>上次说话 · 今天 08:12</div>
</div>
<div class="card" style="margin-top:12px">
  <div class="row">${cap("今天的小物")}<span class="tiny">第 3 件 · 可收进收藏柜</span></div>
  <div style="font-size:17px;font-weight:600;margin:9px 0 7px">一枚被浪磨圆的贝壳</div>
  <div class="tiny" style="line-height:1.7">昨天你们聊到海边,它替你捡回来了。</div>
  <div style="margin-top:12px;font-size:13.5px;line-height:1.9;color:${T.ink2}">「下次,带你听这个声音。」<span class="tiny" style="margin-left:6px">—— 小鲸</span></div>
  <div class="row" style="margin-top:13px">${pill(`${icon("星星", 14, 1.5)}收进收藏柜`, true)}<a class="tiny" href="#/archive/assets">收藏柜 ›</a></div>
</div>
<div class="card" style="margin-top:12px">
  <div class="row">${cap("今天的连载")}<span class="tiny">第 6 章 · 海里的灯塔</span></div>
  <div class="tiny" style="margin-top:9px;line-height:1.7">它念一段,大约一分钟;听过的都留在「档案」里。</div>
  <div class="row" style="margin-top:13px">${pill(`${icon("试听", 14, 1.5)}继续听`, true)}<a class="tiny" href="#/community/index">这周的更新 ›</a></div>
</div>
<div class="card" style="margin-top:12px">
  <h2 style="margin-bottom:6px">最近的相处</h2>
  ${li("今天 08:12", "说了 4 分钟")}
  ${li("昨天 21:40", "它先开口,念了连载第 6 章")}
  ${li("9 月 27 日", "你告诉它出差的事")}
  <div class="tiny" style="margin-top:12px;text-align:center"><a href="#/archive/memory">全部记录在「档案」里 ›</a></div>
</div>`;

const archiveIndex = `
<div class="row" style="margin:2px 0 4px"><h1>我的角色</h1>${pill(`${icon("分享", 15, 1.5)}分享收藏柜`)}</div>
<p class="sub">3 位角色 · 2 件外观 · 5 件纪念物 · 1 枚编号 —— 这一格一格上的东西,只增不减</p>
<div class="grid2">
  <a class="card" style="padding:10px" href="#/archive/character">
    <div class="square" style="aspect-ratio:1/1.06">${maidGirl("bust")}</div>
    <div style="font-size:14.5px;font-weight:600;margin:10px 0 3px">小鲸</div>
    <div class="tiny">NO.0001 · 第 47 天</div>
  </a>
  <a class="card" style="padding:10px;background:${T.surface2};border-style:dashed;border-color:#D8D4CC">
    <div style="aspect-ratio:1/1.06;display:flex;align-items:center;justify-content:center;text-align:center;color:${T.muted}">
      <div><div style="font-size:30px;line-height:1;font-weight:200">＋</div><div class="tiny" style="margin-top:10px;line-height:1.6">领养第一只手办<br>它会以一个新角色开始</div></div>
    </div>
  </a>
</div>
<div class="card" style="margin-top:12px">
  <div class="row"><span style="font-size:13.5px;font-weight:600">资产账</span><a class="tiny" href="#/archive/assets">全部 ›</a></div>
  ${divider()}
  ${li("角色 3 · 外观 2 · 纪念物 5 · 编号 1", "")}
  <div class="tiny" style="margin-top:10px;line-height:1.7">每件东西什么时候来的,都记在这里;任何一件都不会自己消失,也不会被我们收回。</div>
</div>`;

const communityIndex = `
<div class="row" style="margin:2px 0 4px"><h1>社区</h1><span class="tiny">官方周更</span></div>
<p class="sub">这里是角色包与故事的聚集地</p>
<div class="card" style="padding:0;overflow:hidden">
  <div style="height:150px;background:linear-gradient(135deg,#22335E,#3E63B0 60%,#7EC4E8)"></div>
  <div style="padding:14px 16px">
    <div style="font-size:16px;font-weight:700">这周更新:第 6 章 · 海里的灯塔</div>
    <div class="tiny" style="margin-top:6px;line-height:1.6">深海书简 · 每周三更新 · 装载后它会在对话里接着讲</div>
  </div>
</div>
<div class="row" style="margin:14px 0 8px"><h2 style="margin:0">精选角色包</h2><a class="tiny" href="#/community/featured">全部 ›</a></div>
<div class="grid2">
  <a class="card" style="padding:10px" href="#/community/detail">
    <div class="square" style="aspect-ratio:1/0.9">${maidGirl("bust")}</div>
    <div style="font-size:14px;font-weight:600;margin:9px 0 3px">小鲸 · 深海书简</div>
    <div class="tiny">官方 · 连载角色</div>
  </a>
  <a class="card" style="padding:10px;background:${T.surface2};border-style:dashed;border-color:#D8D4CC">
    <div style="aspect-ratio:1/0.9;display:flex;align-items:center;justify-content:center;text-align:center;color:${T.muted}"><div><div style="font-size:24px;font-weight:200">＋</div><div class="tiny" style="margin-top:8px">更多官方精选<br>陆续上架</div></div></div>
  </a>
</div>`;

const storeIndex = `
<div class="row" style="margin:2px 0 12px"><h1>商店</h1>${pill(`${icon("兑换", 15, 1.5)}兑换码`)}</div>
<a style="display:block;border-radius:14px;padding:14px 16px;background:linear-gradient(120deg,#EAF0FA,#D6E4F8);border:1px solid #C9DAF2" href="#/store/free">
  <div class="row">
    <div><div style="font-size:15px;font-weight:700;color:#22335E">永久免费区</div><div class="tiny" style="color:#42558F;margin-top:5px;line-height:1.6">对话、记忆、按键互动、离线底稿 —— 不花钱也不缺</div></div>
    <span class="pill on" style="background:#fff;border-color:#C9DAF2">看看 ›</span>
  </div>
</a>
<div class="rowc" style="margin-top:14px;flex-wrap:wrap;gap:8px">
  ${pill("角色", true)}${pill("外观")}${pill("语音")}${pill("事件")}${pill("实物")}
</div>
<div class="grid2" style="margin-top:14px">
  <a class="card" style="padding:10px" href="#/store/detail">
    <div class="square" style="aspect-ratio:1/0.9">${maidGirl("bust")}</div>
    <div style="font-size:14px;font-weight:600;margin:10px 0 4px">深海书简</div>
    <div class="tiny">角色包 · 附 6 章连载</div>
    <div class="row" style="margin-top:9px"><span style="font-size:13.5px;font-weight:600">¥ 29</span><span class="tiny">可兑换</span></div>
  </a>
  <a class="card" style="padding:10px" href="#/store/detail">
    <div style="aspect-ratio:1/0.9;border-radius:12px;background:linear-gradient(160deg,#F3F1EA,#E7E2D6);display:flex;align-items:center;justify-content:center;color:#9A9384"><span class="tiny">外观预览</span></div>
    <div style="font-size:14px;font-weight:600;margin:10px 0 4px">冬装 · 围巾</div>
    <div class="tiny">外观 · 换装不影响记忆</div>
    <div class="row" style="margin-top:9px"><span style="font-size:13.5px;font-weight:600">¥ 19</span><span class="tiny">可兑换</span></div>
  </a>
</div>
<div class="card" style="margin-top:12px">
  ${cap("实物 · 信物")}
  <div class="tiny" style="margin-top:10px;line-height:1.85">每季把最值得留的那几件事,做成编号限量的实体卡,寄到你手上。<br>订阅期内拿到的信物永久属于你,停订也不收回。</div>
  <div class="row" style="margin-top:13px">${pill("看看往季信物", true)}<span class="tiny">每季一次</span></div>
</div>
<div class="card" style="margin-top:12px"><div class="tiny" style="line-height:1.8">标注「永久免费」的东西,不会因为你没有付费而少一点。<br>付费只买「更多」——更多角色、更多外观、更多连载、更多信物。</div></div>`;

const meIndex = `
<div class="row" style="margin:2px 0 14px"><h1>我的</h1><span class="tiny">登录状态</span></div>
<div class="card">
  <div class="rowc">
    ${avatar(58)}
    <div style="flex:1">
      <div style="font-size:16px;font-weight:600">你</div>
      <div class="tiny" style="margin-top:4px">已绑定 1 只手办 · 微信登录</div>
    </div>
  </div>
</div>
<div class="card" style="margin-top:12px">
  ${li(`${icon("礼物", 16, 1.5)} 订阅与兑换`, "")}
  ${li(`${icon("星星", 16, 1.5)} 服务连续性承诺`, "")}
  ${li(`${icon("设置", 16, 1.5)} 通知与隐私`, "")}
  ${li(`${icon("帮助", 16, 1.5)} 帮助与反馈`, "")}
</div>
<div class="card" style="margin-top:12px">
  <a href="#/me/exit" style="display:flex;align-items:center;justify-content:space-between"><span style="font-size:13.5px;color:#A1463F">退出与删除</span><span class="tiny">›</span></a>
</div>
<div class="tiny" style="margin-top:18px;text-align:center;line-height:1.7">《用户协议》《隐私政策》<br>互动对象为人工智能,不是真人</div>`;

/* ================= Archive 分包 ================= */
const archiveCharacter = `
${hero("54 52 212 236", 252)}
<div class="card" style="margin-top:12px">
  <div class="row">
    <div>
      <div style="font-size:19px;font-weight:700">小鲸</div>
      <div class="tiny" style="margin-top:4px">深海来的 · 角色包 v1.2 · 编号 NO.0001</div>
    </div>
    ${pill("相处 47 天", true)}
  </div>
</div>
<div class="card" style="margin-top:12px">
  ${cap("角色圣经")}
  <div class="rowc" style="margin-top:10px;flex-wrap:wrap;gap:8px">
    ${pill("性格:慢热,话不多")}${pill("口癖:喜欢说「大概吧」")}${pill("关系线:同住人")}
  </div>
  <div class="tiny" style="margin-top:11px;line-height:1.7">圣经是公开可查的;任何改动都会提前公示,旧版本可以回滚。</div>
</div>
<div class="card" style="margin-top:12px">
  ${cap("音色")}
  <div class="row" style="margin-top:10px">
    <div><div style="font-size:14.5px;font-weight:600">鲸声 · 清亮</div><div class="tiny" style="margin-top:3px">已录制的基础音色永不更换</div></div>
    ${pill(`${icon("试听", 15, 1.5)}试听`, true)}
  </div>
</div>
<div class="card" style="margin-top:12px">
  ${cap("它正在讲的故事")}
  <div class="row" style="margin-top:10px">
    <div><div style="font-size:14.5px;font-weight:600">第 6 章 · 海里的灯塔</div><div class="tiny" style="margin-top:3px">每周三更新 · 已更新 6 周</div></div>
    ${pill(`${icon("试听", 15, 1.5)}继续听`, true)}
  </div>
</div>
<div class="card" style="margin-top:12px">
  ${cap("它记得的相处事实")}
  <div style="margin-top:10px;font-size:13.5px;line-height:2">· 你习惯在深夜说话<br>· 不吃香菜<br>· 你说过想读完《海边的卡夫卡》</div>
  <div class="tiny" style="margin-top:10px;text-align:right"><a href="#/archive/memory">去「记忆」里查看全部 ›</a></div>
</div>`;

const memoryRows = (rows) => rows.map(([ic, t, tag]) => `
<div class="row" style="padding:13px 0;border-bottom:1px solid ${T.line};gap:10px">
  <div style="display:flex;gap:10px;align-items:flex-start;flex:1">
    <span style="color:${T.navy2};margin-top:1px;flex:none">${icon(ic, 18, 1.6)}</span>
    <div><div style="font-size:14.5px;font-weight:600">${t}</div><div class="tiny" style="margin-top:5px">${tag}</div></div>
  </div>
</div>`).join("");

const archiveMemory = `
<div class="row" style="margin:0 0 4px"><h1 style="font-size:20px;margin:0">它记得的事</h1><span class="tiny">共 18 条</span></div>
<p class="sub">可查 · 可改 · 可删 · 记忆永久免费</p>
<div class="card">
  <div class="row" style="padding:0 0 13px;border-bottom:1px solid ${T.line};gap:10px">
    <div style="display:flex;gap:10px;align-items:flex-start;flex:1">
      <span style="color:${T.navy2};margin-top:1px;flex:none">${icon("编辑", 18, 1.6)}</span>
      <div><div style="font-size:14.5px;font-weight:600">你说过想读完《海边的卡夫卡》</div><div class="tiny" style="margin-top:5px">事实 · 9 月 12 日记住 · 你说过 3 次</div></div>
    </div>
    <a class="tiny" href="#/archive/memory-edit">编辑 ›</a>
  </div>
  <div class="rowc" style="gap:8px;margin-top:12px">
    ${pill(`${icon("封存", 14, 1.5)}封存`)}${pill(`${icon("删除", 14, 1.5)}删除`)}
  </div>
  <div class="tiny" style="margin-top:10px;line-height:1.7">你删掉的会立刻消失;系统淡忘的会进「已淡忘」档案,你可以把它捡回来。</div>
</div>
<div class="card" style="margin-top:12px">
  ${memoryRows([
    ["封存", "你说过一次就不想再提的那件事", "已封存 · 它不会主动提起"],
    ["年历", "8 月 13 日 · 第一次说话", "里程碑 · 它把这天当成生日"],
    ["鲸", "你喜欢在深夜说话", "偏好 · 待你确认 · 还没告诉它"],
  ])}
</div>`;

const archiveMemoryEdit = `
<h1 style="font-size:20px;margin:2px 0 12px">编辑这条记忆</h1>
<div class="card">
  ${cap("它记下来的话")}
  <div style="font-size:14.5px;line-height:1.9;margin-top:10px;background:${T.surface2};border-radius:10px;padding:12px">你说过想读完《海边的卡夫卡》</div>
  ${cap("你能做什么")}
  <div class="tiny" style="margin-top:10px;line-height:1.9">改这句话(写得更准) · 设为置顶 · 隐藏 · 删除</div>
  ${divider()}
  ${pill(`${icon("编辑", 15, 1.5)}保存`, true)}
  ${pill(`${icon("删除", 15, 1.5)}删除`)}
  <div class="tiny" style="margin-top:12px;line-height:1.8">删除会立刻消失,不可找回;置顶会永远不被淡忘。</div>
</div>`;

const archiveSeal = `
<h1 style="font-size:20px;margin:2px 0 12px">封存管理</h1>
<p class="sub">说一次,它就永不再提</p>
<div class="card">
  ${memoryRows([
    ["封存", "那件事,你说过一次", "封存于 9 月 18 日 · 永不再提"],
    ["封存", "工作上的那个人", "封存于 8 月 30 日"],
  ])}
  <div class="tiny" style="margin-top:12px;line-height:1.8">封存的内容不会被它提起,也不会用来回应你;你随时可以解封。</div>
</div>`;

const archiveAssets = `
<h1 style="font-size:20px;margin:2px 0 12px">资产账</h1>
<p class="sub">只增不减 · 每一件都有来处</p>
<div class="card">
  ${li("角色 · 小鲸", "2026-08-13 领养")}
  ${li("外观 · 冬装围巾", "2026-09-02")}
  ${li("纪念物 · 一枚贝壳", "今天的小物,第 3 件")}
  ${li("编号 · NO.0001", "与底座金属铭牌一致")}
  ${li("契约 · 四件事 v1", "2026-08-13 签署")}
  ${li("信物 · 第一件还没寄出", "每季一件 · 编号限量")}
</div>`;

const archiveTimeline = `
<h1 style="font-size:20px;margin:2px 0 12px">年历</h1>
<p class="sub">记录第一次,也记住普通的日子</p>
<div class="card">
  ${li("8 月 13 日 · 第一次说话", "它的生日")}
  ${li("9 月 12 日 · 第一次深夜长谈", "21:40 开始")}
  ${li("9 月 27 日 · 你第一次出差", "它送了你去机场")}
</div>
<div class="tiny" style="margin-top:12px;text-align:center;color:${T.muted}">[P1] 更多月份与纪念日标记,二期补齐</div>`;

const archiveCertificate = `
<div style="background:${T.paper};border:1px solid #E2DCCF;border-radius:14px;padding:18px 16px;position:relative">
  <div style="position:absolute;inset:7px;border:1px solid #E8E2D5;border-radius:9px;pointer-events:none"></div>
  <div style="text-align:center">
    <div style="font-size:11px;letter-spacing:5px;color:#9A8F79">角 色 出 生 证</div>
    <div style="display:flex;justify-content:center;margin:12px 0 6px;color:#B9AE95">${icon("鲸", 30, 1.2)}</div>
    <div class="rule" style="background:#E4DECF;margin:10px 0"></div>
    <div style="font-size:26px;font-family:${HAND};color:#2B2A26;letter-spacing:2px">小&nbsp;鲸</div>
    <div class="tiny" style="margin-top:8px;color:#8A8271">名字由你写下,随时可以改;每次更改都会留下记录</div>
    <div class="row" style="margin-top:16px;font-size:11px;color:#8A8271"><span>编号 NO.0001</span><span>角色包 v1.2</span><span>2026-08-13</span></div>
    <div class="rule" style="background:#E4DECF;margin:11px 0"></div>
    <div style="font-size:10.5px;color:#9A8F79;letter-spacing:.4px">底座刻有同一编号与日期 · 硬件序列号 SN-2087</div>
  </div>
</div>
<div class="card" style="margin-top:12px">
  ${cap("契约卡 · 我们永不做的四件事")}
  <div style="margin-top:11px;font-size:13.5px;line-height:2.05">
    · 永不静默改变它的性格<br>
    · 永不擅自删除你的记忆<br>
    · 停服前 12 个月通知,并交付档案<br>
    · 记忆永久免费,不进任何付费口径
  </div>
  <div class="rule" style="margin:14px 0"></div>
  <div class="row"><div class="tiny">签署于 2026-08-13 · 版本 v1</div>${pill(`${icon("编辑", 15, 1.5)}签署`, true)}</div>
</div>
<div class="card" style="margin-top:12px">
  ${cap("签署记录")}
  <div style="margin-top:11px">
    ${li("首次签署 · 契约 v1", "2026-08-13")}
    ${li("角色包升级 v1.2 · 确认条款未变", "2026-09-20")}
  </div>
  <div class="tiny" style="margin-top:11px;line-height:1.7">每一次签署都留档;条款只会加,不会偷偷改。</div>
</div>
<div class="card" style="margin-top:12px"><div class="tiny" style="line-height:1.8">这张出生证与契约卡,包装里也各有一张实物;上面的编号与底座金属铭牌一致。</div></div>`;

const archiveShareCard = `
<h1 style="font-size:20px;margin:2px 0 12px">分享卡</h1>
<p class="sub">把它喜欢的样子,分享给更多人</p>
<div class="grid2" style="margin-bottom:12px">
  <div class="card" style="padding:10px">
    <div class="square" style="aspect-ratio:1/1.1">${maidGirl("bust")}</div>
    <div style="font-size:13px;font-weight:600;margin:9px 0 3px">收藏柜公开卡</div>
    <div class="tiny">只含资产事实,不含记忆</div>
  </div>
  <div class="card" style="padding:10px">
    <div class="square" style="aspect-ratio:1/1.1">${maidGirl("full")}</div>
    <div style="font-size:13px;font-weight:600;margin:9px 0 3px">开箱第一句话卡</div>
    <div class="tiny">认主那一刻</div>
  </div>
</div>
<div class="btn pri" style="background:${T.navy}">${icon("分享", 16, 1.6)}生成分享卡</div>
<div class="tiny" style="margin-top:12px;line-height:1.8;text-align:center">分享出去的是图片;好友打开的是网页 “/s/:token”,里面只有公开信息,没有你说过的话。</div>`;

/* ================= Community 分包 ================= */
const communityFeatured = `
<h1 style="font-size:20px;margin:2px 0 12px">精选角色包</h1>
<p class="sub">官方精选 · 每周更新</p>
<div class="card">
  ${li("小鲸 · 深海书简(官方)", "连载 6 章 · 免费")}
  ${li("栗子 · 失眠图书馆(官方)", "睡前短读 · 免费")}
  ${li("川 · 周末咖啡师(官方)", "周末限定 · 免费")}
</div>
<div class="tiny" style="margin-top:12px;text-align:center;color:${T.muted}">UGC 开闸延后到主体与审核就绪(「14」§4.6);本期仅官方内容。</div>`;

const communityDetail = `
<div class="card" style="padding:0;overflow:hidden">
  <div style="height:170px;background:linear-gradient(135deg,#22335E,#3E63B0 60%,#7EC4E8);position:relative;display:flex;align-items:flex-end;padding:14px">
    <div style="color:#fff"><div style="font-size:17px;font-weight:700">小鲸 · 深海书简</div><div style="font-size:11px;opacity:.85;margin-top:4px">官方 · 连载角色 · 6 章</div></div>
  </div>
  <div style="padding:14px 16px">
    <div class="row"><span class="tiny">作者:官方</span>${pill(`${icon("试听", 14, 1.5)}试听角色`, true)}</div>
    <div class="tiny" style="margin-top:12px;line-height:1.8">一只从深海来的鲸娘。话不多,但会把你们说过的事都记下来。装载它,它就以一个新角色开始在你桌上生活。</div>
    <div class="btn pri" style="background:${T.navy};margin-top:14px">免费装载到我的角色</div>
  </div>
</div>`;

/* ================= Store 分包 ================= */
const storeDetail = `
<div class="card" style="padding:0;overflow:hidden">
  <div style="height:200px;background:linear-gradient(165deg,#EAF0FA,#D2E0F5)">${maidGirl("bust")}</div>
  <div style="padding:14px 16px">
    <div class="row"><div><div style="font-size:18px;font-weight:700">深海书简</div><div class="tiny" style="margin-top:4px">角色包 · 含连载 6 章</div></div><div style="font-size:18px;font-weight:700">¥ 29</div></div>
    <div class="rowc" style="margin-top:12px;gap:8px">${pill("永久免费基础角色不受影响")}</div>
    <div class="tiny" style="margin-top:12px;line-height:1.8">买下的是「更多」,不是「解锁」。免费的对话、记忆、按键互动、离线底稿都在。</div>
    <div class="rowc" style="margin-top:14px;gap:10px">
      <div class="btn pri" style="background:${T.navy};flex:1">立即购买</div>
      <div class="btn ghost" style="flex:1">用兑换码</div>
    </div>
    <div class="tiny" style="margin-top:10px;text-align:center">iOS 显示「内容转赠 / 兑换码」路径(平台虚拟支付规则)</div>
  </div>
</div>`;

const storeFree = `
<h1 style="font-size:20px;margin:2px 0 12px">永久免费区</h1>
<p class="sub">这些不会因为你没有付费而少一点</p>
<div class="card">
  ${li("对话(按对话时长计量,按时间回血)", "")}
  ${li("它记得你(长期记忆)", "")}
  ${li("按键互动(两个动作)", "")}
  ${li("离线底稿(断网也在)", "")}
</div>
<div class="card" style="margin-top:12px">
  <h2 style="margin:0 0 8px">付费只买「更多」</h2>
  <div class="tiny" style="line-height:1.9">更多角色包 · 更多外观 · 更多连载 · 更多信物。</div>
</div>`;

const storeRedeem = `
<h1 style="font-size:20px;margin:2px 0 12px">兑换码</h1>
<div class="card">
  <div style="background:${T.surface2};border:1px dashed ${T.line};border-radius:12px;padding:14px;text-align:center;font-size:18px;letter-spacing:3px;color:${T.ink2}">A&nbsp;B&nbsp;C&nbsp;D&nbsp;-&nbsp;E&nbsp;F&nbsp;G&nbsp;H</div>
  <div class="btn pri" style="background:${T.navy};margin-top:14px">兑换</div>
  <div class="tiny" style="margin-top:12px;line-height:1.8;text-align:center">实体卡上的码,这里换成线上权益;二维码在包装与说明书里都能找到。</div>
</div>`;

const storeOrders = `
<h1 style="font-size:20px;margin:2px 0 12px">订单与权益</h1>
<div class="tiny" style="text-align:center;color:${T.muted};margin-top:60px">[P1] 支付 V2 前为只读;当前还没有订单。</div>`;

/* ================= Device 分包 ================= */
const deviceBind = `
<h1 style="font-size:20px;margin:2px 0 6px">绑定手办</h1>
<p class="sub">两种都可以;不强制,先领一只"虚拟手办"看看也行</p>
<div class="card">
  <div class="row" style="padding:12px 0;border-bottom:1px solid ${T.line}">
    <div class="rowc">${icon("扫码", 20, 1.5)}<div><div style="font-size:14.5px;font-weight:600">扫码绑定</div><div class="tiny" style="margin-top:3px">底座二维码一扫即连</div></div></div>
    <span class="tiny">›</span>
  </div>
  <div class="row" style="padding:12px 0">
    <div class="rowc">${icon("编辑", 20, 1.5)}<div><div style="font-size:14.5px;font-weight:600">手动输入 SN</div><div class="tiny" style="margin-top:3px">底座或说明书上的序列号</div></div></div>
    <span class="tiny">›</span>
  </div>
</div>
<div class="btn ghost" style="margin-top:14px">先领一只「虚拟手办」看看</div>
<div class="tiny" style="margin-top:12px;line-height:1.8;text-align:center">不想现在绑定也可以跳过;开箱仪式里的每一步都能断点续做。</div>`;

const deviceProvision = `
<h1 style="font-size:20px;margin:2px 0 12px">BLE 配网</h1>
<p class="sub">把手机上的 WiFi 发给手办,大约 30 秒</p>
<div class="card">
  <div class="row" style="padding:10px 0;border-bottom:1px solid ${T.line}"><span class="tiny">1</span><span style="flex:1;margin-left:10px;font-size:13.5px">搜索设备</span><span class="tiny">已完成</span></div>
  <div class="row" style="padding:10px 0;border-bottom:1px solid ${T.line}"><span class="tiny">2</span><span style="flex:1;margin-left:10px;font-size:13.5px">连接手办(蓝牙)</span><span class="tiny">已完成</span></div>
  <div class="row" style="padding:10px 0"><span class="tiny">3</span><span style="flex:1;margin-left:10px;font-size:13.5px">写入 WiFi 名称与密码</span><span class="tiny" style="color:${T.navy2};font-weight:600">进行中</span></div>
</div>
<div class="card" style="margin-top:12px">
  <div class="tiny" style="line-height:1.8">密码只进手办,不进云端;写入只走蓝牙加密通道(Security 1)。</div>
</div>`;

const deviceManual = `
<h1 style="font-size:20px;margin:2px 0 12px">它的两个动作</h1>
<p class="sub">包装卡、开箱第一句、本页,说的是同一件事</p>
<div class="card" style="text-align:center">
  <div style="font-size:15px;font-weight:600;margin-bottom:8px">按住说话</div>
  <div style="height:120px;display:flex;align-items:center;justify-content:center;background:${T.surface2};border-radius:12px;color:${T.navy2}">${icon("语音", 34, 1.4)}</div>
  <div class="tiny" style="margin-top:10px;line-height:1.7">按住头顶那颗按键,松开,它就开口。</div>
</div>
<div class="card" style="margin-top:12px;text-align:center">
  <div style="font-size:15px;font-weight:600;margin-bottom:8px">播放中按键打断</div>
  <div style="height:120px;display:flex;align-items:center;justify-content:center;background:${T.surface2};border-radius:12px;color:${T.navy2}">${icon("手办", 34, 1.4)}</div>
  <div class="tiny" style="margin-top:10px;line-height:1.7">它在说的时候,按一下,它就停。</div>
</div>
<div class="tiny" style="margin-top:12px;line-height:1.8;text-align:center">没有更多手势了;其余一切都在手机小程序里完成。</div>`;

const deviceSettings = `
<h1 style="font-size:20px;margin:2px 0 12px">设备设置</h1>
<div class="card">
  ${li(`${icon("月亮", 16, 1.5)} 夜间静默(22:00–08:00)`, "")}
  ${li("解绑这台手办", "重新进入绑定流程")}
</div>
<div class="tiny" style="margin-top:12px;line-height:1.8">本页没有音量、灯效等硬件控制项——设备侧在 MVP1 冻结;需要时改由固件侧做。</div>`;

/* ================= Me 分包 ================= */
const mePromise = `
<h1 style="font-size:21px;margin:2px 0 6px">我们承诺什么,不承诺什么</h1>
<p class="sub">这一页的内容,和包装里的卡片逐字一致。</p>
<div class="card">
  ${cap("可承诺的三件事")}
  <div style="margin-top:12px">
    <div style="font-size:15px;font-weight:700">按住才听</div>
    <div class="tiny" style="margin-top:5px;line-height:1.7">不按住,麦克风不工作。</div>
  </div>
  <div class="rule" style="margin:13px 0"></div>
  <div>
    <div style="font-size:15px;font-weight:700">它记得你,而且记忆永久免费</div>
    <div class="tiny" style="margin-top:5px;line-height:1.7">记忆可查、可改、可删;不进任何付费口径。</div>
  </div>
  <div class="rule" style="margin:13px 0"></div>
  <div>
    <div style="font-size:15px;font-weight:700">就算有一天服务停了,它还是一尊手办</div>
    <div class="tiny" style="margin-top:5px;line-height:1.7">造型、收藏、离线底稿、陪伴计数、底座刻痕都留在你手里。不承诺停服后仍会说话。</div>
  </div>
</div>
<div class="card" style="margin-top:12px;background:#F1EFE9;border-color:#E3DFD5">
  ${cap("停服后失效的东西")}
  <div style="margin-top:11px;font-size:13.5px;line-height:2;color:#4A505E">对话 · 主动开口 · 内容更新 · 社区 · 订阅权益</div>
  <div class="tiny" style="margin-top:12px;line-height:1.8">我们会在停服前 12 个月通知,并把你的档案交付给你;<br>在那之前,订阅只卖「更多」,不卖「别失去」。</div>
</div>
<div class="card" style="margin-top:12px"><div class="row"><span class="tiny">服务连续性与数据导出</span><span class="tiny">${icon("帮助", 15, 1.4)}</span></div></div>`;

const meExit = `
<h1 style="font-size:20px;margin:2px 0 12px">退出与删除</h1>
<p class="sub">你想走的每一步,都应该是安静的</p>
<div class="card">
  ${li("退出登录", "不影响你在其它设备上的使用")}
  ${li("删除这台手办与角色", "会同时清除它在服务器上的记忆与档案")}
</div>
<div class="card" style="margin-top:12px">
  <div class="tiny" style="line-height:1.8">我们不会用「再想想」拦住你,也不会在你删完之后把数据留在你拿不到的地方。</div>
</div>`;

const meSettings = `
<h1 style="font-size:20px;margin:2px 0 12px">通知与隐私</h1>
<div class="card">
  ${li("新内容提醒", "每周一次 · 不推广告")}
  ${li("授权管理", "相机 / 蓝牙 / 麦克风")}
  ${li("原声与录音的使用", "默认不用于训练")}
</div>`;

const meHelp = `<div class="tiny" style="text-align:center;color:${T.muted};margin-top:80px">[P1] 帮助与反馈,二期补齐。</div>`;

/* ================= 开箱仪式(6 步) ================= */
const obIntro = `
<div style="height:140px;display:flex;flex-direction:column;justify-content:center">
  <div class="tiny" style="letter-spacing:2px;color:${T.muted}">装备须知</div>
  <h1 style="font-size:24px;margin-top:10px;line-height:1.4">它到了之后,<br>你会怎么用</h1>
</div>
<div class="card">
  ${li("永久免费,不用花钱也能用", "")}
  ${li("需要付费的,只是「更多」", "")}
  ${li("互动对象是人工智能,不是真人", "")}
</div>
<div class="btn pri" style="background:${T.navy};margin-top:16px">开始</div>
<div class="tiny" style="margin-top:10px;text-align:center">每一步都可以跳过;断点续做。</div>`;

const obBind = `
<h1 style="font-size:21px;margin:2px 0 10px">先把你的手办连上</h1>
<p class="sub">连不上也没关系,可以跳过这一步先去认主</p>
${deviceBind}
<div class="btn ghost" style="margin-top:16px">跳过,先去认主</div>`;

const obAdopt = `
<h1 style="font-size:21px;margin:2px 0 10px">给它起个名字</h1>
<p class="sub">它把第一次叫出这个名字,当成你们的开始</p>
<div class="card" style="text-align:center">
  ${avatar(92)}
  <div style="margin-top:14px;font-size:13px;color:${T.muted}">现在,它还没有名字</div>
  <div style="margin-top:14px;background:${T.surface2};border-radius:12px;padding:12px;font-size:16px">小鲸</div>
</div>
<div class="btn pri" style="background:${T.navy};margin-top:16px">就这个</div>
<div class="tiny" style="margin-top:10px;text-align:center">按下去,它会用这个名字叫你。</div>`;

const obFirstCard = `
<h1 style="font-size:21px;margin:2px 0 10px">第一张角色卡</h1>
<p class="sub">它免费进你的收藏柜,永远属于你</p>
<div class="card" style="padding:10px">
  <div class="square" style="aspect-ratio:1/0.9">${maidGirl("bust")}</div>
  <div class="row" style="margin-top:12px">
    <div><div style="font-size:16px;font-weight:700">小鲸 · 深海书简</div><div class="tiny" style="margin-top:3px">角色包 · 含连载 6 章</div></div>
    <div style="font-size:16px;font-weight:700;color:#3E8F5B">免费</div>
  </div>
</div>
<div class="btn pri" style="background:${T.navy};margin-top:16px">放进收藏柜</div>`;

const obSign = `
<h1 style="font-size:21px;margin:2px 0 10px">把它说过的话,按一下手印</h1>
<p class="sub">这四件事,它永远不做</p>
<div class="card">
  ${cap("契约卡 · 我们永不做的四件事")}
  <div style="margin-top:12px;font-size:14px;line-height:2.1">
    · 永不静默改变它的性格<br>
    · 永不擅自删除你的记忆<br>
    · 停服前 12 个月通知,并交付档案<br>
    · 记忆永久免费,不进任何付费口径
  </div>
</div>
<div class="btn pri" style="background:${T.navy};margin-top:16px">签署</div>
<div class="tiny" style="margin-top:10px;text-align:center">签署在小程序里完成;包装里也有一张实物契约卡。</div>`;

const obDone = `
<div style="height:120px;display:flex;flex-direction:column;justify-content:center">
  <h1 style="font-size:24px;line-height:1.4">好了,<br>它认识你了</h1>
</div>
<div class="card" style="text-align:center">
  ${cap("开箱第一句话卡")}
  <div class="square" style="margin:14px 0 10px;aspect-ratio:1/1.1">${maidGirl("bust")}</div>
  <div style="font-size:15px;font-weight:600">「从今天起,我记着你。」</div>
  <div class="tiny" style="margin-top:8px">—— 小鲸 · NO.0001 · 2026-09-29</div>
</div>
<div class="btn ghost" style="margin-top:16px">${icon("分享", 16, 1.6)}分享这张卡</div>`;

/* ================= 页面注册表 ================= */
const PAGES = [
  ["hand/today", "手办 · 今天", "手办", true, handToday, true],
  ["archive/index", "档案 · 收藏册", "档案", true, archiveIndex, true],
  ["archive/character", "档案 · 角色详情", null, true, archiveCharacter, true],
  ["archive/memory", "档案 · 记忆面板", null, true, archiveMemory, true],
  ["archive/memory-edit", "档案 · 编辑记忆", null, false, archiveMemoryEdit, false],
  ["archive/seal", "档案 · 封存管理", null, false, archiveSeal, false],
  ["archive/assets", "档案 · 资产账", null, false, archiveAssets, false],
  ["archive/timeline", "档案 · 年历", null, false, archiveTimeline, false],
  ["archive/certificate", "档案 · 出生证与契约", null, true, archiveCertificate, true],
  ["archive/share-card", "档案 · 分享卡", null, false, archiveShareCard, true],
  ["community/index", "社区", "社区", true, communityIndex, true],
  ["community/featured", "社区 · 精选角色包", null, false, communityFeatured, false],
  ["community/detail", "社区 · 角色包详情", null, false, communityDetail, true],
  ["store/index", "商店", "商店", true, storeIndex, true],
  ["store/detail", "商店 · 商品详情", null, true, storeDetail, true],
  ["store/free", "商店 · 永久免费区", null, false, storeFree, true],
  ["store/redeem", "商店 · 兑换码", null, false, storeRedeem, false],
  ["store/orders", "商店 · 订单权益", null, false, storeOrders, false],
  ["device/bind", "设备 · 绑定", null, false, deviceBind, true],
  ["device/provision", "设备 · BLE 配网", null, false, deviceProvision, true],
  ["device/manual", "设备 · 按键说明", null, false, deviceManual, true],
  ["device/settings", "设备 · 设置", null, false, deviceSettings, false],
  ["me/index", "我的", "我的", true, meIndex, true],
  ["me/promise", "我的 · 服务连续性承诺", null, false, mePromise, true],
  ["me/exit", "我的 · 退出与删除", null, false, meExit, true],
  ["me/settings", "我的 · 通知与隐私", null, false, meSettings, false],
  ["me/help", "我的 · 帮助", null, false, meHelp, false],
  ["onboarding/intro", "开箱 · 装备须知", null, false, obIntro, true],
  ["onboarding/bind", "开箱 · 绑定", null, false, obBind, false],
  ["onboarding/adopt", "开箱 · 认主", null, false, obAdopt, true],
  ["onboarding/first-card", "开箱 · 第一张角色卡", null, false, obFirstCard, true],
  ["onboarding/sign", "开箱 · 契约签署", null, false, obSign, true],
  ["onboarding/done", "开箱 · 完成", null, false, obDone, true],
];

/* ---------------- 独立页 HTML(截图用) ---------------- */
const fullShell = ({ title, badge, tab, header, body }) => `<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><title>${title}</title><style>${css()}</style></head><body class="standalone"><div class="phone">${statusbar}${header !== null ? header : ""}${badge ? aiBadge : ""}<main class="content">${body}</main>${tab ? tabbar(tab) : ""}</div></body></html>`;

for (const [id, title, tab, badge, body, shot] of PAGES) {
  const header = tab ? null : subHeader(title);
  writeFileSync(`${OUT}/pages/${id.replace(/\//g, "_")}.html`, fullShell({ title, badge, tab, header, body }));
}

/* ---------------- 交互版 index.html(模板 + 路由) ---------------- */
const templates = PAGES.map(([id, title, tab, badge, body]) => {
  const header = tab ? null : subHeader(title);
  return `<template data-page="${id}">${header !== null ? header : ""}${badge ? aiBadge : ""}<main class="content">${body}</main>${tab ? tabbar(tab) : ""}</template>`;
}).join("\n");

const indexHtml = `<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><title>AI 手办 · MVP1 交互 demo</title><style>${css()}
.phone .wrap { display: block; }
</style></head><body>
<div class="phone frame">${statusbar}<div id="app"></div></div>
${templates}
<script>
const app = document.getElementById('app');
function go(){
  const id = (location.hash || '').replace(/^#\\/?/, '') || 'hand/today';
  const t = document.querySelector('template[data-page="' + id + '"]') || document.querySelector('template[data-page="hand/today"]');
  app.replaceChildren(t.content.cloneNode(true));
  window.scrollTo(0,0);
}
window.addEventListener('hashchange', go);
if (!location.hash) location.hash = '#/hand/today'; else go();
</script>
</body></html>`;
writeFileSync(`${OUT}/index.html`, indexHtml);

/* ---------------- 总览页(iframe) ---------------- */
const showcase = [
  "hand/today", "archive/index", "archive/character", "archive/certificate", "archive/memory",
  "store/index", "me/promise", "onboarding/done",
];
const overviewHtml = `<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><title>demo 总览</title><style>
body{margin:0;padding:30px 26px 40px;background:#EDEBE6;font-family:${FONT};color:#1B2440}
h1{font-size:20px;margin:0 0 4px}p{font-size:12px;color:#6B7488;margin:0 0 22px;line-height:1.7}
.row{display:flex;gap:20px;align-items:flex-start;flex-wrap:nowrap}
figure{margin:0;background:#fff;border-radius:20px;padding:9px;box-shadow:0 10px 28px rgba(27,36,64,.1)}
iframe{border:0;display:block;width:390px;height:844px;border-radius:14px;background:#F3F1EC}
figcaption{font-size:11px;color:#6B7488;text-align:center;padding:8px 0 3px}
</style></head><body>
<h1>AI 手办 · 小程序 MVP1 初版 demo</h1>
<p>依据 19 号 PRD v1.2 与 20 号素材清单;角色立绘为依参考图重绘的矢量站位稿(待美术置换)。内容文案为初版,待深度优化。本稿遵守:无进度条/无红点/无好感度数值;首页常驻 AI 身份标识;商店首屏必现永久免费区。</p>
<div class="row">
${showcase.map((id) => `<figure><iframe src="pages/${id.replace(/\//g, "_")}.html" scrolling="no"></iframe><figcaption>${id}</figcaption></figure>`).join("\n")}
</div></body></html>`;
writeFileSync(`${OUT}/overview.html`, overviewHtml);

console.log(`已生成 ${PAGES.length} 个独立页 + index.html + overview.html → ${OUT}`);

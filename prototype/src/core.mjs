// 核心:设计令牌 / 图标 / 角色矢量图(深蓝女仆鲸娘,依参考图)/ 机壳 / 页面外壳
// 被 build-app.mjs 引用。不直接运行。

export const T = {
  bg: "#F3F1EC",
  surface: "#FFFFFF",
  surface2: "#FAF8F4",
  paper: "#FBF8F1",
  ink: "#1B2440",
  ink2: "#45507B",
  muted: "#8B93AC",
  line: "#E4E2D9",
  navy: "#26325F",
  navy2: "#3E63B0",
  blue: "#7EC4E8",
  ice: "#A8D8F0",
  gold: "#C9A227",
  accent: "#3E63B0",
  accentSoft: "#EAF0FA",
};

export const FONT = `"Microsoft YaHei UI","Microsoft YaHei","PingFang SC",system-ui,-apple-system,"Segoe UI",sans-serif`;
export const HAND = `"KaiTi","STKaiti","楷体",serif`;

/* ---------------- 图标(24×24 线性) ---------------- */
const P = {
  手办: `<path d="M12 3.4c2 0 3.4 1.5 3.4 3.4 0 1.6-.9 2.6-1.6 3.2h3.4c1 0 1.8.8 1.8 1.8v1.6H6.6v-1.6c0-1 .8-1.8 1.8-1.8h3.4c-.7-.6-1.6-1.6-1.6-3.2 0-1.9 1.4-3.4 3.4-3.4Z"/><path d="M5.4 15.6h13.2v3.2c0 .6-.5 1.1-1.1 1.1H6.5c-.6 0-1.1-.5-1.1-1.1v-3.2Z"/><path d="M3.8 20.4h16.4"/>`,
  档案: `<path d="M4 7.2c0-.9.7-1.6 1.6-1.6h3.1l1.5 1.9h7.2c.9 0 1.6.7 1.6 1.6v8.5c0 .9-.7 1.6-1.6 1.6H5.6c-.9 0-1.6-.7-1.6-1.6V7.2Z"/><path d="M4 11.2h16"/>`,
  社区: `<circle cx="9.4" cy="9.6" r="3"/><path d="M4.4 18.6c0-2.5 2.2-4.2 5-4.2s5 1.7 5 4.2"/><path d="M16 7.4c1.6.3 2.7 1.6 2.7 3.2 0 2-.9 3-2.2 3.6"/><path d="M17.2 14.7c1.9.4 3.2 1.7 3.2 3.9"/>`,
  商店: `<path d="M5.6 8.4h12.8l1.1 10.2c.1.9-.6 1.7-1.6 1.7H6.1c-1 0-1.7-.8-1.6-1.7L5.6 8.4Z"/><path d="M9.1 10.2V7.6a2.9 2.9 0 0 1 5.8 0v2.6"/>`,
  我的: `<circle cx="12" cy="8.6" r="3.4"/><path d="M5.6 19.4c0-3 2.9-5 6.4-5s6.4 2 6.4 5"/>`,
  返回: `<path d="M14.4 5.4 7.8 12l6.6 6.6"/><path d="M8.6 12h11"/>`,
  编辑: `<path d="M15.6 5.6l2.8 2.8-8.6 8.6-3.6.8.8-3.6 8.6-8.6Z"/><path d="M4.6 20.2h14.8"/>`,
  封存: `<rect x="5.4" y="10.4" width="13.2" height="9.2" rx="1.6"/><path d="M8.4 10.4V8.2a3.6 3.6 0 0 1 7.2 0v2.2"/>`,
  删除: `<path d="M5.4 7.4h13.2"/><path d="M9.4 7.4V5.8c0-.7.5-1.2 1.2-1.2h2.8c.7 0 1.2.5 1.2 1.2v1.6"/><path d="M7.2 7.4l.8 11.4c0 .8.7 1.4 1.5 1.4h5c.8 0 1.5-.6 1.5-1.4l.8-11.4"/>`,
  分享: `<circle cx="7" cy="12" r="2.4"/><circle cx="17" cy="6.6" r="2.4"/><circle cx="17" cy="17.4" r="2.4"/><path d="M9.2 10.8l5.6-3M9.2 13.2l5.6 3"/>`,
  兑换: `<path d="M4.6 9.2h14.8v3.2c-.9 0-1.6.7-1.6 1.6s.7 1.6 1.6 1.6v3.2H4.6v-3.2c.9 0 1.6-.7 1.6-1.6s-.7-1.6-1.6-1.6V9.2Z"/><path d="M12 9.2v10"/>`,
  试听: `<path d="M4.6 13.4v-1.6a7.4 7.4 0 0 1 14.8 0v1.6"/><path d="M4.6 13.4h2.2c.6 0 1 .4 1 1v3.2c0 .6-.4 1-1 1H5.6c-.6 0-1-.4-1-1v-4.2Z"/><path d="M19.4 13.4h-2.2c-.6 0-1 .4-1 1v3.2c0 .6.4 1 1 1h1.2c.6 0 1-.4 1-1v-4.2Z"/>`,
  年历: `<rect x="4.4" y="6.2" width="15.2" height="13.4" rx="1.8"/><path d="M4.4 10.4h15.2M8.6 4.6v3.2M15.4 4.6v3.2"/><path d="M8.4 14.2h2.2M13.4 14.2h2.2"/>`,
  设置: `<circle cx="12" cy="12" r="2.6"/><path d="M12 3.8v2.2M12 18v2.2M4.9 12H2.7M21.3 12h-2.2M6.9 6.9 5.3 5.3M18.7 18.7l-1.6-1.6M17.1 6.9l1.6-1.6M5.3 18.7l1.6-1.6"/>`,
  帮助: `<circle cx="12" cy="12" r="8"/><path d="M9.7 9.6c.2-1.3 1.2-2.1 2.5-2.1 1.4 0 2.4.9 2.4 2.1 0 1-.5 1.5-1.4 2.1-.8.5-1.1.8-1.1 1.6"/><circle cx="12.1" cy="16.6" r="0.9" fill="currentColor" stroke="none"/>`,
  退出: `<path d="M13.4 5.4H6.8c-.9 0-1.6.7-1.6 1.6v10c0 .9.7 1.6 1.6 1.6h6.6"/><path d="M11.6 12h8.6"/><path d="M17.4 9.2 20.2 12l-2.8 2.8"/>`,
  扫码: `<rect x="4.4" y="4.4" width="6.4" height="6.4" rx="1"/><rect x="13.2" y="4.4" width="6.4" height="6.4" rx="1"/><rect x="4.4" y="13.2" width="6.4" height="6.4" rx="1"/><path d="M13.2 13.2h3v3h-3zM19.6 13.2v3.2M16.2 19.6h3.4M19.6 16.4v3.2"/>`,
  蓝牙: `<path d="M7 7.8 17 16.2l-5 2.6V4.6l5 2.6L7 15.8"/>`,
  月亮: `<path d="M19.6 14.2A8.4 8.4 0 1 1 9.8 4.4a6.6 6.6 0 0 0 9.8 9.8Z"/>`,
  礼物: `<rect x="4.4" y="9.2" width="15.2" height="4.4" rx="1"/><path d="M5.6 13.6v6.4c0 .8.6 1.4 1.4 1.4h10c.8 0 1.4-.6 1.4-1.4v-6.4"/><path d="M12 9.2v12.2"/><path d="M12 9.2c-2.6 0-4.6-1.4-4.6-3s1.6-2.4 3-1.6c1 .6 1.6 2 1.6 4.6 0-2.6.6-4 1.6-4.6 1.4-.8 3 0 3 1.6s-2 3-4.6 3Z"/>`,
  爱心: `<path d="M12 19.4C7 15.8 4.6 13 4.6 9.9 4.6 7.4 6.5 5.6 8.8 5.6c1.4 0 2.5.6 3.2 1.6.7-1 1.8-1.6 3.2-1.6 2.3 0 4.2 1.8 4.2 4.3 0 3.1-2.4 5.9-7.4 9.5Z"/>`,
  星星: `<path d="M12 4.4l2.3 4.7 5.1.7-3.7 3.6.9 5.1-4.6-2.4-4.6 2.4.9-5.1L4.6 9.8l5.1-.7Z"/>`,
  照片: `<rect x="4" y="5.4" width="16" height="13.2" rx="1.6"/><circle cx="9" cy="10.4" r="1.6"/><path d="M4 16.8l4-4 3 3 4-4.4 5 5"/>`,
  语音: `<rect x="10" y="4.2" width="4" height="9" rx="2"/><path d="M6.4 11.4a5.6 5.6 0 0 0 11.2 0"/><path d="M12 17v3.2M8.8 20.2h6.4"/>`,
  更多: `<circle cx="6" cy="12" r="1.4" fill="currentColor" stroke="none"/><circle cx="12" cy="12" r="1.4" fill="currentColor" stroke="none"/><circle cx="18" cy="12" r="1.4" fill="currentColor" stroke="none"/>`,
  鲸: `<ellipse cx="12.4" cy="13" rx="7.2" ry="4.4" fill="currentColor" stroke="none"/><path d="M18.6 11.8c2-.8 3.6-2.8 4.2-4.8 1 3 .4 6.2-1.4 8.2 1 1.2 2.6 1.8 4 2.2-2.6 1.4-5.4 1-7.6-.8" fill="currentColor" stroke="none"/><circle cx="8.2" cy="11.4" r="0.9" fill="#fff" stroke="none"/>`,
};
export const icon = (name, size = 22, sw = 1.6) =>
  `<svg class="ico" viewBox="0 0 24 24" width="${size}" height="${size}" fill="none" stroke="currentColor" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round">${P[name] || ""}</svg>`;

/* ---------------- 角色:深蓝女仆鲸娘(依参考图,占位稿,待美术置换) ----------------
   mode: 'full'(全身)/ 'bust'(半身,裁上半身)/ 'avatar'(头像,裁头) */
export function maidGirl(mode = "full", id = "m") {
  const vb = mode === "full" ? "0 0 320 560" : mode === "bust" ? "20 4 280 302" : "60 2 200 192";
  const g = `
  <defs>
    <linearGradient id="${id}-hair" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#2A3663"/><stop offset="0.55" stop-color="#4E6FB6"/><stop offset="1" stop-color="#9CD2EF"/>
    </linearGradient>
    <linearGradient id="${id}-iris" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#BFE8F6"/><stop offset="0.55" stop-color="#4E7EC0"/><stop offset="1" stop-color="#22335E"/>
    </linearGradient>
    <linearGradient id="${id}-tail" x1="0" y1="0" x2="1" y2="0.4">
      <stop offset="0" stop-color="#2A3663"/><stop offset="1" stop-color="#7FB9DC"/>
    </linearGradient>
  </defs>

  <!-- 鲸鱼尾(身后,向右扫:尾鳍明显探出裙外) -->
  <path d="M214 380c40-16 72-46 92-88-4 42-12 82-30 118-14 26-32 40-52 44-11 2-19-7-17-18 2-22 3-40 7-56Z" fill="url(#${id}-tail)"/>
  <path d="M256 452c10 4 19 11 26 20-12 7-28 7-40-2-9-7-11-17-7-26 5-9 14-9 21 8Z" fill="url(#${id}-tail)" opacity="0.92"/>

  <!-- 后发(到腰的长卷发) -->
  <path d="M160 64c-52 0-76 36-74 84 1 30-4 66-18 108-6 18-4 30 8 40 10 8 22 6 28-4 4-8 4-18 0-28-2 24 6 44 22 52 16 8 36 4 48-4 8-6 12-16 12-26-6-40-10-80-8-118 1-28-6-60-18-104Z" fill="url(#${id}-hair)"/>
  <path d="M160 64c52 0 76 36 74 84-1 30 4 66 18 108 6 18 4 30-8 40-10 8-22 6-28-4-4-8-4-18 0-28 2 24-6 44-22 52-16 8-36 4-48-4-8-6-12-16-12-26 6-40 10-80 8-118-1-28 6-60 18-104Z" fill="url(#${id}-hair)"/>

  <!-- 鲸鳍耳(两侧,向外后) -->
  <path d="M106 120c-16-7-32-2-40 13 10 1 22 5 31 13 5-5 9-14 9-26Z" fill="#2A3663"/>
  <path d="M104 124c-12-4-24 0-30 10" stroke="#7FB9DC" stroke-width="2.6" fill="none" stroke-linecap="round"/>
  <path d="M214 120c16-7 32-2 40 13-10 1-22 5-31 13-5-5-9-14-9-26Z" fill="#2A3663"/>
  <path d="M216 124c12-4 24 0 30 10" stroke="#7FB9DC" stroke-width="2.6" fill="none" stroke-linecap="round"/>

  <!-- 女仆头饰 -->
  <path d="M94 92c4-20 30-32 66-32s62 12 66 32c-8-8-20-10-20-10-6-6-16-8-20-8s-14 2-20 8c0 0-12 2-20 10Z" fill="#F7F9FC"/>
  <path d="M94 92c6-6 12-8 18-8M226 92c-6-6-12-8-18-8M112 82c4-4 10-6 16-7M208 82c-4-4-10-6-16-7M132 76c4-3 8-4 12-4M188 76c-4-3-8-4-12-4" stroke="#D9DEE8" stroke-width="2" fill="none"/>
  <path d="M94 92c-4 8-2 16 2 22 6-6 8-14 6-22ZM226 92c4 8 2 16-2 22-6-6-8-14-6-22Z" fill="#F7F9FC"/>
  <!-- 头饰侧蝴蝶结 -->
  <g transform="translate(226,104)"><path d="M0 0l14-7c4 3 4 9 0 12L0 6c-4 3-4 7 0 10l14-7c4-3 4-9 0-12L0 0Z" fill="#7EC4E8"/><circle cx="0" cy="3" r="3" fill="#4E7EC0"/></g>

  <!-- 头顶卷天线(鲸鱼喷水) -->
  <path d="M160 74c-2-26-14-46-34-52-16-5-28 4-26 18 2 11 12 16 22 13" fill="none" stroke="#2A3663" stroke-width="11" stroke-linecap="round"/>
  <path d="M160 74c-2-26-14-46-34-52-16-5-28 4-26 18 2 11 12 16 22 13" fill="none" stroke="#5B7FC4" stroke-width="5" stroke-linecap="round" opacity="0.55"/>

  <!-- 颈 -->
  <rect x="150" y="160" width="20" height="26" rx="9" fill="#F0CBB4"/>
  <!-- 肩袖与臂 -->
  <path d="M114 178c-18 6-28 20-32 42-3 16 0 34 6 52l16-4c-4-16-4-32-2-46 2-12 6-22 12-30Z" fill="#2A3663"/>
  <path d="M206 178c18 6 28 20 32 42 3 16 0 34-6 52l-16-4c4-16 4-32 2-46-2-12-6-22-12-30Z" fill="#2A3663"/>
  <path d="M84 262c2 8 4 12 8 16 5 4 10 4 14 0l-4-16-16 4Z" fill="#F0CBB4"/>
  <path d="M236 262c-2 8-4 12-8 16-5 4-10 4-14 0l4-16 16 4Z" fill="#F0CBB4"/>
  <path d="M84 258c-2 4 0 10 4 12 4-4 8-8 10-12l-12-4Z" fill="#F7F9FC"/>
  <path d="M236 258c2 4 0 10-4 12-4-4-8-8-10-12l12-4Z" fill="#F7F9FC"/>

  <!-- 脸 -->
  <path d="M160 78c-32 0-48 24-48 54 0 30 20 50 48 50s48-20 48-50c0-30-16-54-48-54Z" fill="#FBE4D6"/>
  <!-- 刘海 -->
  <path d="M160 74c-34 0-52 24-50 50 8-18 20-24 30-34 6 14 20 18 30 18 12 0 22-6 26-12-2-14-16-22-36-22Z" fill="url(#${id}-hair)"/>
  <path d="M112 104c-2 6-3 12-3 18 2 8 6 10 10 12-1-6-2-12-1-18M208 104c2 6 3 12 3 18-2 8-6 10-10 12 1-6 2-12 1-18" fill="url(#${id}-hair)"/>

  <!-- 眼 -->
  <ellipse cx="138" cy="130" rx="11" ry="13" fill="#FFFFFF"/>
  <ellipse cx="138" cy="131" rx="8" ry="10.5" fill="url(#${id}-iris)"/>
  <circle cx="141" cy="126" r="2.8" fill="#FFFFFF"/>
  <ellipse cx="182" cy="130" rx="11" ry="13" fill="#FFFFFF"/>
  <ellipse cx="182" cy="131" rx="8" ry="10.5" fill="url(#${id}-iris)"/>
  <circle cx="185" cy="126" r="2.8" fill="#FFFFFF"/>
  <path d="M128 116c4-3 9-4 13-3M177 113c4-1 9 0 13 3" stroke="#22335E" stroke-width="2.6" fill="none" stroke-linecap="round"/>
  <path d="M130 112c3-2 8-2 11 0M179 112c3-2 8-2 11 0" stroke="#5B7FA8" stroke-width="1.6" fill="none" stroke-linecap="round"/>
  <ellipse cx="128" cy="148" rx="7" ry="4" fill="#F2A6A0" opacity="0.55"/>
  <ellipse cx="192" cy="148" rx="7" ry="4" fill="#F2A6A0" opacity="0.55"/>
  <path d="M154 152c2 4 10 4 12 0" stroke="#B4645C" stroke-width="2.4" fill="none" stroke-linecap="round"/>

  <!-- 胸衣:白领 + 深蓝领结 + 金扣 -->
  <path d="M160 168c-26 0-42 14-46 34 14 8 30 10 46 10s32-2 46-10c-4-20-20-34-46-34Z" fill="#F7F9FC"/>
  <path d="M160 172c-24 0-38 12-42 28 14 8 28 10 42 10s28-2 42-10c-4-16-18-28-42-28Z" fill="#2A3663"/>
  <path d="M146 180h-12c-3 0-4 4-2 6l12 8c3 1 6 0 7-3l-6-11ZM174 180h12c3 0 4 4 2 6l-12 8c-3 1-6 0-7-3l6-11Z" fill="#22335E"/>
  <circle cx="160" cy="186" r="3.2" fill="#C9A227"/>
  <circle cx="155" cy="196" r="2" fill="#C9A227"/><circle cx="165" cy="196" r="2" fill="#C9A227"/>
  <circle cx="155" cy="204" r="2" fill="#C9A227"/><circle cx="165" cy="204" r="2" fill="#C9A227"/>

  <!-- 裙:深蓝长裙 + 白围裙 + 鲸刺绣 + 金蝴蝶结 + 白蕾丝下摆 -->
  <path d="M112 206c-4 26-12 90-18 150-4 40-8 76-6 100 4 24 30 36 72 36s68-12 72-36c2-24-2-60-6-100-6-60-14-124-18-150-16-8-32-10-48-10s-32 2-48 10Z" fill="#2A3663"/>
  <!-- 裙底刺绣(金线) -->
  <path d="M96 452c6-2 12 0 16 4-4 4-12 5-16 2Z" stroke="#C9A227" stroke-width="1.6" fill="none"/>
  <path d="M224 452c-6-2-12 0-16 4 4 4 12 5 16 2Z" stroke="#C9A227" stroke-width="1.6" fill="none"/>
  <path d="M110 470c8 6 18 8 30 8M210 470c-8 6-18 8-30 8" stroke="#C9A227" stroke-width="1.4" fill="none" opacity="0.8"/>
  <!-- 白围裙(比裙窄,两侧露出深蓝裙) -->
  <path d="M134 212c-3 20-6 70-7 120-1 44-1 78 4 100 4 12 14 16 29 16s25-4 29-16c5-22 5-56 4-100-1-50-4-100-7-120-9-5-17-7-26-7s-17 2-26 7Z" fill="#F7F9FC"/>
  <path d="M116 412c-4 2-6 8-2 12 4-4 8-4 10 0 2-6 6-8 10-6 2 2 2 6 0 8-8 8-22 8-28-2-2-4 0-8 4-8" fill="#EDF0F6" opacity="0"/>
  <path d="M120 420c6 6 20 8 40 8s34-2 40-8" stroke="#D9DEE8" stroke-width="3" fill="none" stroke-linecap="round"/>
  <!-- 围裙鲸鱼刺绣 -->
  <g transform="translate(160,330)"><ellipse cx="0" cy="4" rx="16" ry="9" fill="#2A3663"/><path d="M14 1c4-1 7-3 8-6 2 4 1 8-2 10 2 1 4 2 6 3-4 1-8 1-11-1Z" fill="#2A3663"/><circle cx="-7" cy="2" r="1.4" fill="#F7F9FC"/><path d="M-2 -6c1-3 3-5 6-6-1 3-1 6 1 8" fill="#4E7EC0"/></g>

  <!-- 白蕾丝下摆 -->
  <path d="M86 452c2 18 12 30 34 34-8 8-22 8-30-2-6-8-8-16-8-28ZM234 452c-2 18-12 30-34 34 8 8 22 8 30-2 6-8 8-16 8-28Z" fill="#F7F9FC"/>
  <path d="M90 456c14 8 44 12 70 12s56-4 70-12" stroke="#F7F9FC" stroke-width="14" fill="none" stroke-linecap="round"/>
  <path d="M96 458c8 5 22 8 30 9M224 458c-8 5-22 8-30 9" stroke="#D9DEE8" stroke-width="2" fill="none"/>

  <!-- 袜与鞋 -->
  <rect x="132" y="492" width="18" height="26" rx="6" fill="#F0CBB4"/>
  <rect x="170" y="492" width="18" height="26" rx="6" fill="#F0CBB4"/>
  <path d="M130 516c-4 2-6 6-6 10 0 8 6 14 14 14 7 0 13-4 13-10v-14h-21Z" fill="#F7F9FC"/>
  <path d="M190 516c4 2 6 6 6 10 0 8-6 14-14 14-7 0-13-4-13-10v-14h21Z" fill="#F7F9FC"/>
  <path d="M126 522c2-2 4-3 6-3M132 522v14M194 522c-2-2-4-3-6-3M188 522v14" stroke="#D9DEE8" stroke-width="1.6"/>
  <path d="M122 538c0 6 8 10 16 10s16-4 16-10v-8H122v8Z" fill="#2A3663"/>
  <path d="M182 538c0 6 8 10 16 10s16-4 16-10v-8h-16v8Z" fill="#2A3663"/>
  <path d="M124 536h30M184 536h30" stroke="#22335E" stroke-width="3"/>
  <path d="M138 540h4M194 540h4" stroke="#C9A227" stroke-width="2" stroke-linecap="round"/>
  `;
  return `<svg viewBox="${vb}" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="角色立绘:深蓝女仆鲸娘">${g}</svg>`;
}

/* ---------------- 机壳与通用组件 ---------------- */
export const statusbar = `<div class="statusbar"><span>9:41</span><span class="sb-right"><i class="sig"></i><i class="wifi"></i><i class="bat"></i></span></div>`;
export const aiBadge = `<div class="aibadge">${icon("鲸", 15, 1.4)}<span>本产品为人工智能合成语音,互动对象不是真人</span></div>`;

export function tabbar(active) {
  const items = [["手办", "hand/today", "手办"], ["档案", "archive/index", "档案"], ["社区", "community/index", "社区"], ["商店", "store/index", "商店"], ["我的", "me/index", "我的"]];
  return `<nav class="tabbar">${items
    .map(([label, route, ic]) => {
      const on = label === active;
      return `<a class="tab ${on ? "on" : ""}" href="#/${route}">${icon(ic, 23, on ? 1.8 : 1.5)}<span>${label}</span></a>`;
    })
    .join("")}</nav>`;
}

export function subHeader(title, extra = "") {
  return `<div class="subheader"><a href="#/" class="back">${icon("返回", 19, 1.6)}</a><span class="shtitle">${title}</span><span class="shright">${extra}</span></div>`;
}

export const cap = (t) => `<div class="cap">${t}</div>`;
export const card = (inner, style = "") => `<div class="card" style="${style}">${inner}</div>`;
export const pill = (inner, on = false) => `<span class="pill${on ? " on" : ""}">${inner}</span>`;

export function css() {
  return `
*{box-sizing:border-box;-webkit-font-smoothing:antialiased;margin:0;padding:0}
html,body{font-family:${FONT};color:${T.ink}}
body{background:#EAE8E2;padding:0;display:flex;flex-direction:column;align-items:center;gap:0}
a{text-decoration:none;color:inherit}
.phone{width:390px;min-height:844px;background:${T.bg};display:flex;flex-direction:column;position:relative;border-radius:0;overflow-x:hidden}
.phone.frame{border-radius:26px;overflow:hidden;box-shadow:0 12px 40px rgba(27,36,64,.12);margin:22px auto}
/* 独立页:不居中、不留白,保证截图与设计稿尺寸一致(390×900) */
body.standalone{display:block;background:${T.bg}}
body.standalone .phone{margin:0;border-radius:0;box-shadow:none}
.statusbar{height:44px;display:flex;align-items:center;justify-content:space-between;padding:0 22px 0 26px;font-size:13px;font-weight:600;flex:none}
.sb-right{display:flex;gap:5px;align-items:center}
.sb-right i{display:block;background:${T.ink};border-radius:2px}
.sig{width:15px;height:9px;clip-path:polygon(0 100%,20% 100%,20% 60%,0 60%,0 100%,30% 100%,30% 40%,50% 40%,50% 100%,60% 100%,60% 20%,80% 20%,80% 100%,100% 100%,100% 0,0 0)}
.wifi{width:13px;height:10px;clip-path:polygon(50% 100%,0 35%,15% 22%,50% 62%,85% 22%,100% 35%)}
.bat{width:20px;height:10px;border-radius:2.5px}
.aibadge{display:flex;gap:6px;align-items:center;margin:0 16px 10px;padding:7px 10px;border-radius:9px;background:#EDF0F7;color:#5A6480;font-size:11px;line-height:1.3;flex:none}
.aibadge .ico{flex:none}
.content{flex:1;padding:0 16px 26px}
.tabbar{height:62px;display:flex;background:rgba(255,255,255,.94);border-top:1px solid ${T.line};position:sticky;bottom:0}
.tab{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:3px;color:${T.muted};font-size:10.5px}
.tab.on{color:${T.navy2};font-weight:600}
.subheader{height:52px;display:flex;align-items:center;justify-content:space-between;padding:0 2px 0 4px;flex:none}
.shtitle{font-size:12px;color:${T.muted}}
.shright{font-size:12px;color:${T.muted};min-width:26px;text-align:right}
.back{display:flex;align-items:center;color:${T.ink}}
h1{font-size:22px;margin:2px 0 4px;letter-spacing:.2px}
h2{font-size:15px;margin:0 0 10px;font-weight:600}
.sub{font-size:12px;color:${T.muted};margin:0 0 14px;line-height:1.5}
.card{background:${T.surface};border-radius:16px;padding:16px;border:1px solid ${T.line}}
.card + .card{margin-top:12px}
.hairline{height:1px;background:${T.line};margin:14px 0}
.row{display:flex;align-items:center;justify-content:space-between;gap:10px}
.rowc{display:flex;align-items:center;gap:10px}
.pill{display:inline-flex;align-items:center;gap:6px;padding:7px 12px;border-radius:999px;background:${T.surface};border:1px solid ${T.line};font-size:12.5px;color:${T.ink2}}
.pill.on{background:${T.accentSoft};border-color:#CBD8F0;color:${T.navy2};font-weight:600}
.cap{font-size:11px;color:${T.muted};letter-spacing:1.6px;text-transform:uppercase}
.tiny{font-size:11px;color:${T.muted};line-height:1.5}
.rule{height:1px;background:${T.line}}
.ico{display:block}
.grid2{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px}
.grid2 > *{min-width:0}
.avatar{border-radius:50%;overflow:hidden;background:linear-gradient(160deg,#EAF0FA,#C9DCF0)}
.square{border-radius:12px;overflow:hidden;background:linear-gradient(160deg,#EAF0FA,#D2E0F5)}
.square svg,.avatar svg{display:block}
.btn{display:flex;align-items:center;justify-content:center;gap:8px;height:48px;border-radius:14px;font-size:14px;font-weight:600}
.btn.pri{background:${T.navy};color:#fff}
.btn.ghost{background:#fff;border:1px solid ${T.line};color:${T.ink2}}
.list{display:flex;flex-direction:column}
.list .li{display:flex;align-items:center;justify-content:space-between;padding:13px 0;border-bottom:1px solid ${T.line}}
.list .li:last-child{border-bottom:0}
`;
}

/* ---------------- 页面外壳 ---------------- */
export function shell({ title, badge = true, tab = null, header = null, body, frame = true }) {
  return `<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><title>${title}</title><style>${css()}</style></head>
<body><div class="phone ${frame ? "frame" : ""}">
${statusbar}
${header !== null ? header : ""}
${badge ? aiBadge : ""}
<main class="content">${body}</main>
${tab ? tabbar(tab) : ""}
</div></body></html>`;
}

'use strict';
const screen = document.querySelector('#screen');
const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
let snapshot = null, operation = null, error = '', posting = false, fetching = false, uncertain = false;
let operationId = sessionStorage.getItem('pilot.operation') || null;
uncertain = sessionStorage.getItem('pilot.uncertain') === 'true';
let lastPaint = '', timer;
const waiting = () => posting || ['accepted','sent','running'].includes(operation?.status);
const fresh = () => !error && snapshot?.device_online && snapshot?.telemetry_fresh;
const canIdentify = () => fresh() && snapshot?.can_identify && snapshot?.service_ready !== false && !waiting() && !uncertain;
function stateTitle() {
  if (error) return '等待状态更新';
  if (!snapshot) return '正在连接';
  if (!snapshot.device_online) return '未连接';
  if (snapshot.service_ready === false) return '暂时无法互动';
  if (snapshot.busy) return '互动进行中';
  if (!snapshot.telemetry_fresh) return '等待状态更新';
  return {IDLE:'可互动',REC:'正在听',WAIT:'处理中',PLAY:'正在回应',ERR:'暂时无法互动'}[snapshot.telemetry?.state] || '等待状态更新';
}
const operationLabel = () => posting ? '正在发送识别指令' : ({accepted:'服务器已受理',sent:'已发送，等待手办回执',running:'手办正在执行',completed:'手办已执行，请核对短鸣',rejected:'手办未执行',failed:'手办执行失败',unknown:'结果未确认，不会自动重发'}[operation?.status] || (uncertain ? '结果未确认，请查看手办；不会自动重发' : ''));
const nav = title => `<div class="navhead"><button class="back" data-route="home">‹ 返回</button><h2>${title}</h2></div>`;
const row = (label,value) => `<div class="row"><span>${esc(label)}</span><span>${esc(value)}</span></div>`;
const action = (label,route) => `<button class="row-button" data-route="${route}">${label}<span>›</span></button>`;
const time = value => value ? new Date(value * 1000).toLocaleTimeString('zh-CN', {hour12:false}) : '暂无记录';
function home() {
  return `<div class="page"><div class="head"><div><h1>小鲸</h1><p>日常搭子</p></div><button class="icon" data-route="connect" aria-label="连接设置">⌁</button></div><button class="state-row" data-route="device"><span class="live-dot ${fresh()?'online':''}"></span><span>${esc(stateTitle())}</span><small>›</small></button><div class="hero"><img src="/ios/AIFigure/Resources/Assets.xcassets/XiaojingFront.imageset/front.png" alt="小鲸正面形象"></div><button class="primary" id="identify" ${canIdentify()?'':'disabled'}>${waiting()?'等待手办回应':'识别手办'}</button><p class="hint">按住手办按键说话，松开后听回应</p>${operationLabel()?`<div class="result" role="status">${esc(operationLabel())}</div>`:''}${error?`<p class="message">${esc(error)}</p>`:snapshot&&!snapshot.device_online?'<p class="message">按一下手办按键，等待连接</p>':''}</div>`;
}
function device() {
  const telemetry = snapshot?.telemetry;
  const power = fresh() && telemetry ? (telemetry.usb_present?'已接电源':'未检测到外接电源') : '供电状态未知';
  return `<div class="list-page">${nav('我的手办')}<div class="list-body"><p class="section-label">当前状态</p><div class="group">${row('手办',stateTitle())}${row('供电',power)}${row('电量','暂不可用')}${row('最后状态更新',time(snapshot?.telemetry_at))}${row('状态有效',fresh()?'是':'否')}${operationLabel()?row('执行结果',operationLabel()):''}<button class="row-button" id="refresh">刷新状态</button></div><p class="section-label">连接</p><div class="group">${action('连接设置','connect')}${action('Wi-Fi配网','wifi')}</div><p class="section-label">诊断信息</p><div class="group">${row('设备',snapshot?.device_id || '未知')}${row('固件',snapshot?.firmware || '未知')}${row('信号',fresh()&&telemetry?`${telemetry.rssi} dBm`:'未知')}${row('电压采样（待核验）',fresh()&&telemetry?`${telemetry.battery_mv} mV`:'未知')}</div><p class="footnote">电压采样仍待核验，暂不换算剩余电量或充电状态。</p></div></div>`;
}
function connect() {
  return `<div class="list-page">${nav('连接设置')}<div class="list-body"><p class="section-label">本机连接</p><div class="group">${row('设备服务',error?'暂时不可用':snapshot?'已接入':'正在连接')}${row('主板',snapshot?.device_online?'在线':'离线')}${row('连接方式','电脑局域网网关')}<button class="row-button" id="refresh">重新检查连接</button></div><p class="footnote">浏览器通过本机服务访问主板。连接凭据保留在电脑服务中，无需在页面输入。</p><div class="group">${action('我的手办','device')}${action('Wi-Fi配网','wifi')}</div></div></div>`;
}
function wifi() {
  return `<div class="list-page">${nav('Wi-Fi配网')}<div class="list-body"><p class="section-label">当前连接</p><div class="group">${row('主板',snapshot?.device_online?'已联网':'未连接')}${row('设备服务',snapshot?.service_ready?'可用':'等待连接')}</div><p class="footnote">此浏览器实例支持状态查看与短鸣识别。更换主板Wi-Fi需在iPhone原生App中，通过蓝牙完成配网。</p></div></div>`;
}
function render(force = false) {
  const route = location.hash.slice(1) || 'home';
  const html = ({home,device,connect,wifi}[route] || home)();
  document.querySelector('#live-note').textContent = `真实设备联调 · ${stateTitle()}`;
  if (!force && html === lastPaint) return;
  const scrollTop = screen.scrollTop, active = document.activeElement?.id;
  lastPaint = html; screen.innerHTML = html; screen.scrollTop = force?0:scrollTop;
  if (active) document.getElementById(active)?.focus({preventScroll:true});
  document.querySelectorAll('aside button').forEach(b => b.classList.toggle('chosen',b.dataset.route === route));
  document.querySelectorAll('[data-route]').forEach(b => b.onclick = () => {location.hash=b.dataset.route});
  document.querySelector('#identify')?.addEventListener('click',identify);
  document.querySelector('#refresh')?.addEventListener('click',refresh);
}
async function request(path, options = {}) {
  const response = await fetch(`/__device/${path}`,{...options,headers:{'X-Device-Pilot':'1',...options.headers},cache:'no-store',signal:AbortSignal.timeout(10000)});
  const body = await response.json();
  if (!response.ok) { const failure = new Error(body.error?.message || '设备服务暂不可用'); failure.status=response.status; throw failure; }
  return body.data;
}
async function refresh() {
  if (fetching || posting) return;
  fetching = true;
  try {
    snapshot = await request('status'); error='';
    // A status from before POST must never enable another write or replace its result.
    if (!posting) {
      const id = operationId || snapshot.pending_operation_id;
      if (id) {
        operationId = id; sessionStorage.setItem('pilot.operation',id);
        operation = await request(`operations/${id}`);
        uncertain = operation.status === 'unknown';
        sessionStorage.setItem('pilot.uncertain',String(uncertain));
      }
    }
  } catch (failure) { error = failure.message || '暂时连不上电脑设备服务'; }
  finally { fetching=false; render(); }
}
async function identify() {
  if (!canIdentify()) return;
  posting=true; operation=null; operationId=null; error='';
  sessionStorage.removeItem('pilot.operation');
  // Survives a tab reload during POST; only a confirmed receipt clears uncertainty.
  uncertain=true; sessionStorage.setItem('pilot.uncertain','true'); render();
  try {
    operation = await request('identify',{method:'POST',headers:{'Content-Type':'application/json','Idempotency-Key':crypto.randomUUID()},body:'{}'});
    operationId=operation.id; sessionStorage.setItem('pilot.operation',operation.id);
    uncertain=operation.status === 'unknown';
    sessionStorage.setItem('pilot.uncertain',String(uncertain));
  } catch (failure) {
    // Confirmed 4xx rejection has no execution; network / 5xx outcome stays uncertain.
    uncertain=!(failure.status>=400 && failure.status<500);
    sessionStorage.setItem('pilot.uncertain',String(uncertain));
    error=uncertain?'结果未确认，请查看手办；不会自动重发':failure.message;
  } finally { posting=false; render(); await refresh(); }
}
function schedule() { clearInterval(timer); if (!document.hidden) {refresh(); timer=setInterval(refresh,2000);} }
document.querySelector('#refresh-device').onclick=refresh;
window.addEventListener('hashchange',()=>render(true));
document.addEventListener('visibilitychange',schedule);
render(); schedule();

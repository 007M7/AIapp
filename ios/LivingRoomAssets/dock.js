const dock=document.querySelector('.dock');
const motion=matchMedia('(prefers-reduced-motion: reduce)');
dock.addEventListener('click',event=>{
  const button=event.target.closest('.dock-item');
  if(!button||!dock.contains(button))return;
  if(button.classList.contains('dock-mic'))return;
  dock.querySelectorAll('.dock-item').forEach(item=>item.classList.toggle('is-selected',item===button));
  dock.querySelectorAll('.dock-splash').forEach(item=>item.remove());
  const effect=document.createElement('span');effect.className='dock-splash';effect.setAttribute('aria-hidden','true');
  const avatar=document.createElement('span');avatar.className='splash-avatar';avatar.style.backgroundImage=`url('assets/dock-avatar-${1+Math.floor(Math.random()*4)}.png')`;effect.append(avatar);
  for(let i=0;i<7;i++){const drop=document.createElement('span');drop.className='splash-drop';drop.style.setProperty('--i',i);effect.append(drop)}
  button.append(effect);
  if(motion.matches){setTimeout(()=>effect.remove(),250)}else{effect.addEventListener('animationend',event=>{if(event.target===avatar)effect.remove()})}
});

const settingsPage=document.createElement('section');settingsPage.className='pilot-settings';settingsPage.hidden=true;settingsPage.innerHTML='<div class="pilot-settings-top"><button class="pilot-settings-back" aria-label="返回客厅">‹</button><strong>设置</strong><span></span></div><button class="pilot-connect"><span>手办连接</span><span class="live-device-state">未连接</span><span>›</span></button>';document.querySelector('.stage').append(settingsPage);
dock.querySelector('[aria-label="设置"]').addEventListener('click',()=>{setTimeout(()=>{settingsPage.hidden=false},500)});
settingsPage.querySelector('.pilot-settings-back').addEventListener('click',()=>{settingsPage.hidden=true});
settingsPage.querySelector('.pilot-connect').addEventListener('click',()=>{if(window.nativePilot)window.webkit?.messageHandlers?.pilot?.postMessage({type:'settings'});else settingsPage.querySelector('.live-device-state').textContent='请在 App 中连接'});
const talk=dock.querySelector('.dock-mic');let pressing=false;
talk.addEventListener('pointerdown',e=>{e.preventDefault();pressing=true;talk.setPointerCapture(e.pointerId);talk.classList.add('is-holding');if(window.nativePilot)window.webkit?.messageHandlers?.pilot?.postMessage({type:'voice-start'})});
function stopTalk(cancel){if(!pressing)return;pressing=false;talk.classList.remove('is-holding');if(window.nativePilot)window.webkit?.messageHandlers?.pilot?.postMessage({type:cancel?'voice-cancel':'voice-end'})}
talk.addEventListener('pointerup',()=>stopTalk(false));talk.addEventListener('pointercancel',()=>stopTalk(true));

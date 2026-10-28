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

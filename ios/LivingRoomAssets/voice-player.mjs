export function createVoicePlayer({engine,makeUtterance,onState=()=>{},onError=()=>{}}){
 let active=null,state='idle',generation=0;
 function show(next){state=next;onState(active,state)}
 function stop(){generation++;if(state==='paused')engine.resume();engine.cancel();active=null;show('idle')}
 function toggle(item,text){
   if(active===item&&state==='playing'){engine.pause();show('paused');return}
   if(active===item&&state==='paused'){engine.resume();show('playing');return}
   generation++;const current=generation;if(state==='paused')engine.resume();engine.cancel();active=item;const utterance=makeUtterance(text);
   utterance.onend=()=>{if(current===generation){active=null;show('idle')}};
   utterance.onerror=()=>{if(current===generation){active=null;show('idle');onError()}};
   show('playing');engine.speak(utterance);
 }
 return {toggle,stop};
}

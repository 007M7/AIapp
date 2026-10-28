import {DiaryStore,MemoStore,PersonalDiaryStore,localDay,monthCells} from './diary.mjs';

const LONG_EXAMPLE={title:'写给今天的你',body:'今天早上，窗帘边透进来一小块光。我原本打算再眯一会儿，可那块光慢慢爬到地毯上，刚好落在鲸鱼图案的尾巴旁边，看起来像它悄悄游到了岸上。\n\n我坐起来看了好一会儿，想着要不要把地毯整理一下。最后当然整理了，只是中途发现垫子下面藏着一颗糖，于是稍微停下来检查了一下它的味道。嗯，这是必要的质量检查，和贪吃完全没有关系。\n\n下午的云走得很慢。一开始是一团圆圆的，像一只睡着的小鱼；后来风吹过来，它伸出一条长长的尾巴，又变成了一艘船。我试着猜它会去哪里，猜了好几个地方，最后决定让它自己选。反正它也不会乖乖听我的。\n\n房间里安安静静的，我把想说的话写进本子。其实今天没有发生什么惊天动地的大事，只有光、云，还有那颗不小心被发现的糖。可是把它们记下来之后，突然觉得这样的一天也有自己的样子。\n\n如果你看到这里，记得抬头看看窗外。要是没什么特别的也没关系，普通的风景也值得看一眼。至于我？我会继续坐在这里，认真考虑明天的零食应该放在哪里。'};

export function initDiary(){
  const panel=document.querySelector('#diary-panel'),trigger=document.querySelector('#wall-diary'),close=document.querySelector('#diary-close'),content=document.querySelector('#diary-content');
  let storage;try{storage=window.localStorage}catch{storage={getItem(){throw Error('unavailable')},setItem(){throw Error('unavailable')}}}
  const store=new DiaryStore(storage),memos=new MemoStore(storage),personal=new PersonalDiaryStore(storage);let today=store.ensureToday(),month=today.slice(0,7),view='closed',tapTimer=null;
  function refreshBadge(){const unread=store.unread(today);trigger.classList.toggle('has-new',unread);trigger.setAttribute('aria-label',unread?'小鲸的日记，有新日记':'小鲸的日记');trigger.title=unread?'小鲸的日记 · 有新日记':'小鲸的日记'}
  function checkDay(){const day=localDay();if(day!==today){today=store.ensureToday();refreshBadge()}}
  function showEntry(item,day){
    view='entry';panel.dataset.view='entry';content.replaceChildren();
    const nav=document.createElement('button');nav.className='diary-back';nav.textContent='‹ 日历';nav.addEventListener('click',calendar);
    const date=document.createElement('div');date.className='diary-date';date.textContent=day.replaceAll('-',' / ');
    const title=document.createElement('h3');title.textContent=item.title;
    const body=document.createElement('p');body.className='diary-body diary-scroll';body.textContent=item.body;body.tabIndex=0;body.setAttribute('aria-label','日记正文');
    content.append(nav,date,title,body);
  }
  function entry(day){const item=store.read(day),mine=personal.get(day),oldMemo=memos.get(day);month=day.slice(0,7);refreshBadge();const parts=[];if(item)parts.push(item.body);if(mine)parts.push('我的日记\n'+mine);if(oldMemo)parts.push([oldMemo.title,oldMemo.text].filter(Boolean).join('\n'));showEntry({title:item?.title||'这一天',body:parts.join('\n\n')||'这一天还没有日记。'},day)}
  function moveMonth(delta){const [y,m]=month.split('-').map(Number),d=new Date(y,m-1+delta,1);month=`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}`;calendar()}
  function editDiary(day){
    view='edit';panel.dataset.view='memo';content.replaceChildren();
    const nav=document.createElement('button');nav.className='diary-back';nav.textContent='‹ 日历';nav.addEventListener('click',calendar);
    const date=document.createElement('div');date.className='diary-date';date.textContent=day.replaceAll('-',' / ');
    const title=document.createElement('h3');title.textContent='我的日记';
    const input=document.createElement('textarea');input.className='memo-input';input.setAttribute('aria-label','日记内容');input.placeholder='写下这一天的事…';input.maxLength=5000;input.value=personal.get(day);
    const status=document.createElement('div');status.className='memo-status';status.setAttribute('role','status');
    const save=document.createElement('button');save.className='memo-save';save.textContent='保存';save.addEventListener('click',()=>{if(personal.save(day,input.value))calendar();else status.textContent='保存失败，请检查浏览器存储后重试。'});
    content.append(nav,date,title,input,status,save);
  }
  function memo(day){
    view='memo';panel.dataset.view='memo';content.replaceChildren();
    const nav=document.createElement('button');nav.className='diary-back';nav.textContent='‹ 日历';nav.addEventListener('click',calendar);
    const date=document.createElement('div');date.className='diary-date';date.textContent=day.replaceAll('-',' / ');
    const title=document.createElement('input');title.type='text';title.className='memo-title';title.setAttribute('aria-label','事项名称');title.placeholder='填写事项，例如：生日';title.maxLength=100;
    const input=document.createElement('textarea');input.className='memo-input';input.setAttribute('aria-label','事项内容');input.placeholder='写下这一天的事…';input.maxLength=2000;
    const existing=memos.get(day);if(existing){title.value=existing.title;input.value=existing.text}
    const save=document.createElement('button');save.className='memo-save';save.textContent='保存';
    const status=document.createElement('div');status.className='memo-status';status.setAttribute('role','status');
    save.addEventListener('click',()=>{if(memos.save(day,title.value,input.value)){calendar()}else{status.textContent='保存失败，请检查浏览器存储后重试。'}});
    content.append(nav,date,title,input,status,save);
  }
  function calendar(){
    clearTimeout(tapTimer);tapTimer=null;view='calendar';panel.dataset.view='calendar';content.replaceChildren();
    const bar=document.createElement('div');bar.className='calendar-bar';const prev=document.createElement('button'),next=document.createElement('button'),heading=document.createElement('strong');prev.textContent='‹';prev.setAttribute('aria-label','上个月');next.textContent='›';next.setAttribute('aria-label','下个月');heading.textContent=month.replace('-',' 年 ')+' 月';prev.addEventListener('click',()=>moveMonth(-1));next.addEventListener('click',()=>moveMonth(1));bar.append(prev,heading,next);
    const grid=document.createElement('div');grid.className='calendar-grid';for(const w of ['一','二','三','四','五','六','日']){const x=document.createElement('span');x.className='calendar-weekday';x.textContent=w;grid.append(x)}
    const [y,m]=month.split('-').map(Number);let pendingDay='';
    for(const day of monthCells(y,m)){
      if(!day){grid.append(document.createElement('span'));continue}
      const b=document.createElement('button'),record=store.get(day),saved=memos.get(day),mine=personal.get(day);b.className='calendar-day';b.textContent=String(Number(day.slice(-2)));
      b.setAttribute('aria-label',`${day}${record||mine?' 有日记':''}${saved?' 有备忘':''}`);if(record||mine)b.classList.add('has-entry');if(saved)b.classList.add('has-memo');if(day===today)b.classList.add('today');if(store.unread(day))b.classList.add('unread');
      b.addEventListener('click',()=>{checkDay();if(day>today){clearTimeout(tapTimer);tapTimer=null;memo(day);return}if(tapTimer&&pendingDay===day){clearTimeout(tapTimer);tapTimer=null;editDiary(day);return}clearTimeout(tapTimer);pendingDay=day;tapTimer=setTimeout(()=>{tapTimer=null;if(view==='calendar'&&!panel.hidden)entry(day)},450)});grid.append(b)
    }
    content.append(bar,grid);const demo=document.createElement('button');demo.className='diary-demo';demo.textContent='查看长文示例';demo.addEventListener('click',()=>showEntry(LONG_EXAMPLE,today));content.append(demo)
  }
  function closePanel(){clearTimeout(tapTimer);tapTimer=null;panel.hidden=true;view='closed';trigger.focus()}
  trigger.addEventListener('click',()=>{checkDay();panel.hidden=false;month=today.slice(0,7);if(store.unread(today))entry(today);else calendar();close.focus()});close.addEventListener('click',closePanel);panel.addEventListener('click',e=>{if(e.target===panel)closePanel()});panel.addEventListener('keydown',e=>{if(e.key==='Escape'){e.preventDefault();closePanel()}else if(e.key==='Tab'){const focusable=[...panel.querySelectorAll('button:not(:disabled), textarea, select, input')];if(!focusable.length)return;const i=focusable.indexOf(document.activeElement);if(e.shiftKey&&i<=0){e.preventDefault();focusable.at(-1).focus()}else if(!e.shiftKey&&i===focusable.length-1){e.preventDefault();focusable[0].focus()}}});document.addEventListener('visibilitychange',()=>{if(!document.hidden){checkDay();if(view==='calendar')calendar()}});setInterval(checkDay,60000);refreshBadge();
}

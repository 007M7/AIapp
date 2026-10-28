const STORAGE_KEY='xiaojing.diary.demo.v1';
const STORIES=[
  {title:'窗边的休息时间',body:'今天在窗边坐了一会儿。光落在地毯上，暖洋洋的，连尾巴都不想动了。\n\n……才不是偷懒，我是在认真观察天气。'},
  {title:'零食去哪儿了',body:'本来想把零食留到下午，结果打开盒子时只剩下几块。\n\n我决定先替它们检查一下味道。就一块，真的。'},
  {title:'一小片云',body:'窗外有一片云，慢吞吞地飘过去，形状像一条胖胖的鱼。\n\n我盯了它好久。要是它也想摸鱼，那我们还挺合得来的。'},
  {title:'地毯上的发现',body:'发现鲸鱼地毯上的图案，越看越像它在朝我喷水。\n\n我试着跟它打了个招呼。它没回答……嗯，大概是太害羞了。'},
  {title:'今天的安排',body:'今天的计划是先休息一下，再想想要做什么。\n\n别急，休息也是计划的一部分。我已经安排得很认真了。'},
  {title:'安静的一天',body:'外面安安静静，房间里也很舒服。我找了个喜欢的位置坐下，慢慢度过了今天。\n\n偶尔这样也不错嘛。'},
  {title:'一份小心愿',body:'如果明天也有好天气，就继续坐在这里看窗外。\n\n如果下雨？那就听雨声。反正我早就想好了。'},
];
export function localDay(date=new Date()){return `${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,'0')}-${String(date.getDate()).padStart(2,'0')}`}
function isDay(day){if(!/^\d{4}-\d{2}-\d{2}$/.test(day))return false;const [y,m,d]=day.split('-').map(Number),v=new Date(y,m-1,d);return v.getFullYear()===y&&v.getMonth()===m-1&&v.getDate()===d}
export function monthCells(year,month){const first=new Date(year,month-1,1),n=new Date(year,month,0).getDate(),offset=(first.getDay()+6)%7;return [...Array(offset).fill(null),...Array.from({length:n},(_,i)=>`${year}-${String(month).padStart(2,'0')}-${String(i+1).padStart(2,'0')}`)]}
export class DiaryStore{
  constructor(storage){this.storage=storage;this.entries={};this.volatile=false;try{const data=JSON.parse(storage.getItem(STORAGE_KEY)||'null');if(data?.version===1&&data.entries&&typeof data.entries==='object'){for(const [day,entry] of Object.entries(data.entries)){if(isDay(day)&&typeof entry?.title==='string'&&typeof entry?.body==='string')this.entries[day]={title:entry.title,body:entry.body,read:entry.read===true}}}}catch{this.volatile=true}}
  save(){try{this.storage.setItem(STORAGE_KEY,JSON.stringify({version:1,entries:this.entries}));this.volatile=false}catch{this.volatile=true}}
  ensureToday(date=new Date()){const day=localDay(date);if(!this.entries[day]){const index=(date.getFullYear()*372+(date.getMonth()+1)*31+date.getDate())%STORIES.length;this.entries[day]={...STORIES[index],read:false};this.save()}return day}
  unread(day){return !!this.entries[day]&&!this.entries[day].read}
  read(day){if(!this.entries[day])return null;this.entries[day].read=true;this.save();return this.entries[day]}
  get(day){return this.entries[day]||null}
}

const MEMO_KEY='xiaojing.memo.demo.v1';
export class MemoStore{
  constructor(storage){this.storage=storage;this.entries={};try{const data=JSON.parse(storage.getItem(MEMO_KEY)||'null');if(data?.version===1&&data.entries&&typeof data.entries==='object'){for(const [day,item] of Object.entries(data.entries)){if(isDay(day)&&typeof item?.text==='string')this.entries[day]={text:item.text,title:typeof item.title==='string'?item.title:'',...(typeof item.kind==='string'?{kind:item.kind}:{})}}}}catch{}}
  get(day){return this.entries[day]||null}
  save(day,title,text){if(!isDay(day)||typeof title!=='string'||typeof text!=='string')return false;const next={...this.entries};if(title.trim()||text.trim())next[day]={...next[day],title:title.trim(),text:text.trim()};else delete next[day];try{this.storage.setItem(MEMO_KEY,JSON.stringify({version:1,entries:next}));this.entries=next;return true}catch{return false}}
}

const PERSONAL_DIARY_KEY='xiaojing.personal-diary.demo.v1';
export class PersonalDiaryStore {
  constructor(storage){this.storage=storage;this.entries={};try{const data=JSON.parse(storage.getItem(PERSONAL_DIARY_KEY)||'null');if(data?.version===1&&data.entries&&typeof data.entries==='object'){for(const [day,text] of Object.entries(data.entries))if(isDay(day)&&typeof text==='string')this.entries[day]=text}}catch{}}
  get(day){return this.entries[day]||''}
  save(day,text){if(!isDay(day)||typeof text!=='string')return false;const next={...this.entries};if(text.trim())next[day]=text.trim();else delete next[day];try{this.storage.setItem(PERSONAL_DIARY_KEY,JSON.stringify({version:1,entries:next}));this.entries=next;return true}catch{return false}}
}

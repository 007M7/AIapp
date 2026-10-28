// Visual simulation only: no location or weather-service access.
export const WEATHER = Object.freeze({
  clear: {cloud: .16, rain: 0, snow: 0, fog: 0, wind: .18, dim: 0},
  cloudy: {cloud: .7, rain: 0, snow: 0, fog: .06, wind: .25, dim: .18},
  drizzle: {cloud: .8, rain: .35, snow: 0, fog: .12, wind: .18, dim: .24},
  rain: {cloud: .9, rain: .68, snow: 0, fog: .12, wind: .42, dim: .35},
  heavy: {cloud: 1, rain: 1, snow: 0, fog: .18, wind: .7, dim: .48},
  storm: {cloud: 1, rain: .95, snow: 0, fog: .16, wind: .85, dim: .55},
  snow: {cloud: .8, rain: 0, snow: .75, fog: .15, wind: .22, dim: .24},
  fog: {cloud: .52, rain: 0, snow: 0, fog: .7, wind: .06, dim: .22},
  wind: {cloud: .48, rain: 0, snow: 0, fog: .04, wind: 1, dim: .09},
});
const clamp=(v,a=0,b=1)=>Math.max(a,Math.min(b,v));
const lerp=(a,b,t)=>a+(b-a)*t;
const fract=v=>v-Math.floor(v);
const hash=i=>fract(Math.sin(i*127.1+1.37)*43758.5453);
const rgba=(r,g,b,a=1)=>`rgba(${Math.round(r)},${Math.round(g)},${Math.round(b)},${a})`;
const smooth=(a,b,x)=>{const t=clamp((x-a)/(b-a));return t*t*(3-2*t)};
export function daylight(minute){const m=((minute%1440)+1440)%1440;return smooth(300,420,m)*(1-smooth(1050,1170,m))}
export function sunVisibility(weather){return weather==='clear'||weather==='wind'?1:0}
export function weatherLabel(name){return ({clear:'晴',cloudy:'阴',drizzle:'小雨',rain:'中雨',heavy:'大雨',storm:'雷雨',snow:'雪',fog:'雾',wind:'大风'})[name]??'晴'}
const palette=[[0,[18,28,58],[56,70,100]],[300,[35,48,77],[105,101,122]],[390,[133,135,168],[238,175,144]],[510,[90,155,210],[213,228,227]],[720,[76,153,215],[205,228,239]],[1020,[97,148,194],[238,204,172]],[1110,[157,112,143],[243,163,124]],[1200,[50,62,102],[130,101,126]],[1440,[18,28,58],[56,70,100]]];
function skyColor(minute){const m=((minute%1440)+1440)%1440;let i=0;while(i<palette.length-2&&m>=palette[i+1][0])i++;const a=palette[i],b=palette[i+1],t=(m-a[0])/(b[0]-a[0]);return [1,2].map(k=>a[k].map((v,j)=>lerp(v,b[k][j],t)))}
function softCloud(ctx,x,y,rx,ry,color,alpha){ctx.save();ctx.translate(x,y);ctx.scale(rx,ry);const g=ctx.createRadialGradient(0,0,.05,0,0,1);g.addColorStop(0,rgba(...color,alpha));g.addColorStop(.55,rgba(...color,alpha*.52));g.addColorStop(1,rgba(...color,0));ctx.fillStyle=g;ctx.fillRect(-1,-1,2,2);ctx.restore()}
export class WeatherRenderer {
  constructor(canvas){this.canvas=canvas;this.ctx=canvas.getContext('2d');this.coast=new Image();this.coast.src='assets/coast-day.png';this.current={...WEATHER.clear};this.last=0;this.clouds=Array.from({length:22},(_,i)=>({x:hash(i+13)*1.5-.25,y:.06+hash(i+44)*.40,w:.12+hash(i+92)*.20,h:.018+hash(i+17)*.035,depth:i%3}));this.drops=Array.from({length:190},(_,i)=>({x:hash(i+200),y:hash(i+600),depth:i%3,phase:hash(i+900),speed:.55+hash(i+1300)}));this.stars=Array.from({length:65},(_,i)=>({x:hash(i+1600),y:hash(i+1800)*.6,r:.6+hash(i+2100)*1.4,p:hash(i+2500)}));this.reduced=matchMedia('(prefers-reduced-motion: reduce)');}
  resize(){const r=this.canvas.getBoundingClientRect(),d=Math.min(devicePixelRatio||1,2);this.canvas.width=Math.max(1,Math.round(r.width*d));this.canvas.height=Math.max(1,Math.round(r.height*d));}
  draw(now,state){const c=this.ctx,w=this.canvas.width,h=this.canvas.height;if(!w||!h)return;const spec=WEATHER[state.weather]??WEATHER.clear,dt=this.last?Math.min((now-this.last)/1000,.1):.016;this.last=now;const k=1-Math.exp(-dt*1.7);for(const name of ['cloud','rain','snow','fog','wind','dim'])this.current[name]=lerp(this.current[name],spec[name],k);const cur=this.current,m=Number(state.minute)||0,day=daylight(m),[top,bottom]=skyColor(m),t=this.reduced.matches?0:now/1000;
    c.clearRect(0,0,w,h);const sky=c.createLinearGradient(0,0,0,h);sky.addColorStop(0,rgba(...top));sky.addColorStop(.61,rgba(...bottom));sky.addColorStop(.63,rgba(126,170,188));sky.addColorStop(1,rgba(71,125,154));c.fillStyle=sky;c.fillRect(0,0,w,h);
    // Landscape carries only the horizon/sea. Its sky is intentionally excluded.
    if(this.coast.complete&&this.coast.naturalWidth){c.save();c.globalAlpha=.45+day*.35;const ih=this.coast.naturalHeight,iw=this.coast.naturalWidth;c.drawImage(this.coast,0,ih*.69,iw,ih*.31,0,h*.61,w,h*.39);c.restore();c.fillStyle=rgba(10,23,44,clamp((1-day)*.68+cur.dim*.2));c.fillRect(0,h*.61,w,h*.39)}
    c.fillStyle=rgba(60,70,85,cur.dim*.56);c.fillRect(0,0,w,h);
    const phase=clamp((m-360)/720),isDay=m>=360&&m<=1080;let sx=(.08+.69*phase)*w,sy=(.61-Math.sin(phase*Math.PI)*.48)*h;if(!isDay){sx=.27*w;sy=.17*h}
    if(sunVisibility(state.weather)&&cur.cloud<.55){const opacity=(1-cur.cloud)*.9;const g=c.createRadialGradient(sx,sy,0,sx,sy,w*.17);g.addColorStop(0,rgba(255,242,214,opacity));g.addColorStop(.22,rgba(255,225,180,opacity*.45));g.addColorStop(1,rgba(255,225,180,0));c.fillStyle=g;c.fillRect(sx-w*.2,sy-w*.2,w*.4,w*.4);c.fillStyle=rgba(255,247,226,opacity);c.beginPath();c.arc(sx,sy,w*(isDay?.023:.016),0,Math.PI*2);c.fill()}
    if(sunVisibility(state.weather)&&day<.2&&cur.cloud<.5){for(const s of this.stars){const a=(1-day*5)*(1-cur.cloud)*(.45+.3*Math.sin(t*1.4+s.p*9));c.fillStyle=rgba(235,244,255,clamp(a));c.beginPath();c.arc(s.x*w,s.y*h,s.r*(w/450),0,7);c.fill()}}
    const night=1-day,cloudColor=[lerp(244,114,night),lerp(247,130,night),lerp(250,158,night)];for(const q of this.clouds){const speed=(.003+cur.wind*.006)*(q.depth+1),x=fract(q.x+t*speed+1.5)*1.5-.25,y=q.y+Math.sin(t*.1+q.x*9)*.003;for(let j=0;j<3;j++)softCloud(c,(x+(j-1)*q.w*.45)*w,(y-(j===1?q.h*.2:0))*h,q.w*w*(j===1?.8:.65),q.h*h*(j===1?1.2:.8),cloudColor,(.1+cur.cloud*.22)*(1-q.depth*.12))}
    if(cur.fog>.01){for(let i=0;i<3;i++){const y=(.37+i*.12+Math.sin(t*.08+i)*.014)*h;const g=c.createLinearGradient(0,y-h*.06,0,y+h*.06);g.addColorStop(0,rgba(218,226,231,0));g.addColorStop(.5,rgba(218,226,231,cur.fog*.24));g.addColorStop(1,rgba(218,226,231,0));c.fillStyle=g;c.fillRect(0,y-h*.06,w,h*.12)}}
    if(cur.rain>.01){c.lineCap='round';for(const d of this.drops){if(d.phase>cur.rain)continue;const depth=d.depth+1,speed=.18+depth*.16,y=fract(d.y+t*speed*d.speed)*h,x=fract(d.x-t*cur.wind*.04*depth-y/h*.04*cur.wind)*w,len=(.01+depth*.009)*h;c.lineWidth=Math.max(.6,w*(.0011+depth*.0006));c.strokeStyle=rgba(217,232,244,.18+depth*.10);c.beginPath();c.moveTo(x,y);c.lineTo(x-cur.wind*len*.25,y+len);c.stroke()}}
    if(cur.snow>.01){for(const d of this.drops){if(d.phase>cur.snow)continue;const depth=d.depth+1,y=fract(d.y+t*(.018+depth*.018)*d.speed)*h,x=fract(d.x+Math.sin(t*.7+d.phase*30)*.015+t*cur.wind*.005)*w;c.fillStyle=rgba(247,251,255,.5+depth*.12);c.beginPath();c.arc(x,y,(.0015+depth*.0013)*w,0,Math.PI*2);c.fill()}}
    // Rain on the glass: sparse slowly sliding droplets; still behind the window frame.
    if(cur.rain>.1){for(let i=0;i<17;i++){const x=hash(i+4000)*w,y=fract(hash(i+5000)+t*(.008+hash(i+6000)*.02))*h;c.strokeStyle=rgba(230,244,255,cur.rain*.22);c.lineWidth=Math.max(1,w*.003);c.beginPath();c.moveTo(x,y-h*.022);c.quadraticCurveTo(x-w*.003,y-h*.008,x,y);c.stroke();c.fillStyle=rgba(245,250,255,cur.rain*.38);c.beginPath();c.ellipse(x,y,w*.003,h*.002,0,0,7);c.fill()}}
    if(state.weather==='storm'&&!this.reduced.matches){const pulse=fract(t/11.4);if(pulse<.018){c.fillStyle=rgba(225,235,255,(1-pulse/.018)*.3);c.fillRect(0,0,w,h)}}
  }
}

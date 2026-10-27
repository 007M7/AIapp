export function pcm16(samples, rate) {
  if (!(rate>=16000) || samples.length/rate>30.1) throw new Error('录音格式或时长错误');
  const count=Math.floor(samples.length*16000/rate), bytes=new ArrayBuffer(count*2), view=new DataView(bytes);
  for(let i=0;i<count;i++) {
    const begin=Math.floor(i*rate/16000), end=Math.max(begin+1,Math.floor((i+1)*rate/16000));
    let sum=0; for(let j=begin;j<end;j++) sum+=samples[j];
    const value=Math.max(-1,Math.min(1,sum/(end-begin)));
    view.setInt16(i*2,Math.round(value*(value<0?32768:32767)),true);
  }
  return bytes;
}

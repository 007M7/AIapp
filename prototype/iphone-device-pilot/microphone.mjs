import {pcm16} from './pcm.mjs';
export class HoldMicrophone {
  constructor(onState,onAudio,onError) {Object.assign(this,{onState,onAudio,onError,holding:false,active:false,preparing:false});}
  async start() {
    if(this.holding||this.active||this.preparing)return;
    this.holding=true;this.preparing=true;this.onState('准备麦克风');
    try {
      const stream=await navigator.mediaDevices.getUserMedia({audio:{channelCount:1,echoCancellation:true,noiseSuppression:true,autoGainControl:true},video:false});
      if(!this.holding){stream.getTracks().forEach(t=>t.stop());return;}
      this.stream=stream;this.context=new AudioContext();await this.context.resume();
      const code=`class PCMRecorder extends AudioWorkletProcessor {process(inputs){const a=inputs[0]?.[0];if(a)this.port.postMessage(a.slice());return true}}registerProcessor('pcm-recorder',PCMRecorder);`;
      const url=URL.createObjectURL(new Blob([code],{type:'text/javascript'}));
      try {await this.context.audioWorklet.addModule(url);} finally {URL.revokeObjectURL(url);}
      if(!this.holding){this.cleanup();return;}
      this.parts=[];this.samples=0;this.active=true;
      this.source=this.context.createMediaStreamSource(stream);this.node=new AudioWorkletNode(this.context,'pcm-recorder');
      this.node.port.onmessage=e=>{
        if(!this.active)return;
        const remaining=Math.floor(this.context.sampleRate*30)-this.samples;
        if(remaining>0){const part=e.data.subarray(0,remaining);this.parts.push(part);this.samples+=part.length;}
        if(this.samples>=this.context.sampleRate*30)this.stop(false);
      };
      this.source.connect(this.node);this.node.connect(this.context.destination); // Worklet output is silent.
      this.stream.getAudioTracks().forEach(t=>t.onended=()=>this.stop(true));
      this.onState('正在听');
    } catch(error) {
      this.holding=false;this.cleanup();
      this.onError(error.name==='NotAllowedError'?'请允许麦克风访问后再按住说话':error.name==='NotFoundError'?'未找到麦克风':'麦克风暂不可用，请重试');
    } finally {this.preparing=false;if(!this.active)this.onState('');}
  }
  stop(cancel=false) {
    this.holding=false;
    if(!this.active){if(!this.preparing)this.onState('');return;}
    this.active=false;
    const rate=this.context.sampleRate, samples=new Float32Array(this.samples);let offset=0;
    for(const part of this.parts){samples.set(part,offset);offset+=part.length;}
    this.cleanup();this.onState('');
    if(cancel){this.onError('录音已取消');return;}
    if(samples.length<rate*.5){this.onError('录音太短，请按住说完再松开');return;}
    this.onAudio(pcm16(samples,rate));
  }
  cleanup(){this.active=false;this.node?.disconnect();this.source?.disconnect();this.stream?.getTracks().forEach(t=>{t.onended=null;t.stop();});this.context?.close().catch(()=>{});this.parts=[];this.samples=0;}
}

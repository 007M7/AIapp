import test from 'node:test';
import assert from 'node:assert/strict';
import {pcm16} from '../prototype/iphone-device-pilot/pcm.mjs';
test('48kHz mono audio becomes exact 16kHz little-endian clipped PCM',()=>{
  const source=new Float32Array(48000); source.fill(2,0,3); source.fill(-2,3,6);
  const data=pcm16(source,48000), view=new DataView(data);
  assert.equal(data.byteLength,32000);assert.equal(view.getInt16(0,true),32767);assert.equal(view.getInt16(2,true),-32768);
});
test('16kHz samples retain duration and 44.1kHz conversion remains bounded',()=>{
  assert.equal(pcm16(new Float32Array(16000),16000).byteLength,32000);
  assert.equal(pcm16(new Float32Array(44100),44100).byteLength,32000);
  assert.throws(()=>pcm16(new Float32Array(960000),32000/2));
});

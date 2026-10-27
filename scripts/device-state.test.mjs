import test from 'node:test';
import assert from 'node:assert/strict';
import {deviceStateTitle,operationTitle} from '../prototype/iphone-device-pilot/device-state.mjs';
const state=state=>({device_online:true,telemetry_fresh:true,service_ready:true,busy:true,telemetry:{state}});
test('real WAIT and PLAY remain distinct while server is busy',()=>{
  assert.equal(deviceStateTitle(state('WAIT')),'处理中');
  assert.equal(deviceStateTitle(state('PLAY')),'正在回应');
  assert.equal(deviceStateTitle({...state('IDLE'),busy:false}),'可互动');
  assert.equal(deviceStateTitle(state('IDLE')),'互动进行中');
});
test('upload, record, stale and offline never imply actual playback',()=>{
  assert.equal(deviceStateTitle(state('IDLE'),{posting:true}),'正在发送');
  assert.equal(deviceStateTitle(state('IDLE'),{micState:'正在听'}),'正在听');
  assert.equal(deviceStateTitle({...state('PLAY'),telemetry_fresh:false,busy:false}),'等待状态更新');
  assert.equal(deviceStateTitle({...state('PLAY'),device_online:false}),'未连接');
});
test('voice admission is preparation until actual PLAY and completion is explicit',()=>{
  const operation={kind:'voice',status:'running'};
  assert.equal(operationTitle(operation,{snapshot:state('WAIT')}),'正在准备回答');
  assert.equal(operationTitle(operation,{snapshot:state('PLAY')}),'手办正在回应');
  assert.equal(operationTitle({...operation,status:'completed'},{snapshot:state('PLAY')}),'回答已播放完毕');
});

import test from 'node:test';
import assert from 'node:assert/strict';
import {createServer,request} from 'node:http';
import {createPilotProxy,loadPilotConnection} from './device-pilot-proxy.mjs';
import {mkdtemp,writeFile,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';

const credential = 'test_'.repeat(9);
async function fixture(t, fetchImpl) {
  let handler;
  const server=createServer((req,res)=>handler(req,res));
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  const port=server.address().port, origin=`http://127.0.0.1:${port}`;
  handler=createPilotProxy({server:'http://192.168.137.1:8795',credential},{port,fetchImpl});
  t.after(()=>new Promise(resolve=>{server.close(resolve);server.closeAllConnections();}));
  return {origin,headers:{'X-Device-Pilot':'1'}};
}
test('same-origin status forwarding retains private credentials server-side',async t=>{
  const f=await fixture(t,async(url,options)=>{
    assert.equal(url,'http://192.168.137.1:8795/lab/v1/status');
    assert.equal(options.headers.Authorization,`Bearer ${credential}`);
    assert.equal(options.redirect,'error');
    return Response.json({data:{device_online:false}});
  });
  const response=await fetch(f.origin+'/__device/status',{headers:f.headers});
  assert.equal(response.status,200); assert.equal(response.headers.get('cache-control'),'no-store');
  assert.deepEqual(await response.json(),{data:{device_online:false}});
});
test('cross-site, forged host and unapproved methods never reach gateway',async t=>{
  const f=await fixture(t,()=>{throw new Error('must not be called');});
  for(const headers of [{},{...f.headers,Origin:'https://untrusted.example'}]) {
    assert.equal((await fetch(f.origin+'/__device/status',{headers})).status,403);
  }
  const forged = await new Promise((resolve,reject)=>{
    const req=request(f.origin+'/__device/status',{headers:{...f.headers,Host:'attacker.example'}},res=>{res.resume();resolve(res.statusCode);});
    req.on('error',reject);req.end();
  });
  assert.equal(forged,403);
  assert.equal((await fetch(f.origin+'/__device/reset',{method:'POST',headers:f.headers})).status,404);
});
test('identify preserves UUID and rejection; malformed body never reaches gateway',async t=>{
  let calls=0;
  const f=await fixture(t,async(url,options)=>{
    calls++; assert.equal(url,'http://192.168.137.1:8795/lab/v1/identify');
    assert.equal(options.headers['Idempotency-Key'],'12345678-1234-1234-1234-123456789abc');
    assert.equal(options.body,'{}');
    return Response.json({error:{code:'device_offline',message:'设备未连接'}},{status:409});
  });
  const headers={...f.headers,Origin:f.origin,'Content-Type':'application/json','Idempotency-Key':'12345678-1234-1234-1234-123456789abc'};
  assert.equal((await fetch(f.origin+'/__device/identify',{method:'POST',headers,body:'{}'})).status,409);
  assert.equal((await fetch(f.origin+'/__device/identify',{method:'POST',headers,body:'{"target":"other"}'})).status,400);
  assert.equal(calls,1);
});
test('unreachable gateway produces uncertain result without automatic retry',async t=>{
  let calls=0;
  const f=await fixture(t,async()=>{calls++;throw new Error('private diagnostic detail');});
  const response=await fetch(f.origin+'/__device/identify',{method:'POST',headers:{...f.headers,Origin:f.origin,'Content-Type':'application/json','Idempotency-Key':'12345678-1234-1234-1234-123456789abc'},body:'{}'});
  assert.equal(response.status,502); assert.match((await response.json()).error.message,/不会自动重发/); assert.equal(calls,1);
});
test('only explicit private HTTP configuration is accepted',async t=>{
  const folder=await mkdtemp(join(tmpdir(),'pilot-proxy-')); t.after(()=>rm(folder,{recursive:true,force:true}));
  const path=join(folder,'connection.json');
  for(const server of ['http://public.example','http://0.0.0.0','http://192.168.137.1/private','http://user@192.168.137.1']) {
    await writeFile(path,JSON.stringify({type:'aifigure.device.v1',server,credential}));
    await assert.rejects(()=>loadPilotConnection(path));
  }
  await writeFile(path,JSON.stringify({type:'aifigure.device.v1',server:'http://192.168.137.1:8795',credential}));
  assert.equal((await loadPilotConnection(path)).credential,credential);
});

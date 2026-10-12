"""aiohttp boundary; sqlite/password work is offloaded from the event loop."""
import argparse
import asyncio
import getpass
import hashlib
import json
import logging
import re
import time
from pathlib import Path
from aiohttp import web
try:
    from .service import Store,Fault,require,uid,ROLES,now
except ImportError:
    from service import Store,Fault,require,uid,ROLES,now

ROOT=Path(__file__).resolve().parent
LOG=logging.getLogger('management')
REQUEST_ID=web.RequestKey('management_request_id',str)
USER=web.RequestKey('management_user',dict)
def response(data): return web.json_response({'ok':True,'data':data},dumps=lambda v:json.dumps(v,ensure_ascii=False))
def build_app(store,allowed_hosts,secure=False,allowed_origins=None):
    allowed_origins=set(allowed_origins or ())
    require(not allowed_origins or store.preview,'开发 Origin 仅能用于本地预览')
    limits={}
    @web.middleware
    async def security(request,handler):
        request_id=uid();actor=None;started=time.perf_counter()
        try:
            require(request.host in allowed_hosts,'Host 不在允许列表','BAD_HOST',403)
            if request.method not in {'GET','HEAD'}:
                require(request.content_type=='application/json','请求需使用 JSON','CONTENT_TYPE',415)
                origin=request.headers.get('Origin')
                if origin: require(origin==f"{'https' if secure else 'http'}://{request.host}" or origin in allowed_origins,'跨站请求被拒绝','ORIGIN',403)
            request[REQUEST_ID]=request_id
            response_value=await handler(request)
        except Fault as error:
            actor=request.get(USER,{}).get('id')
            await asyncio.to_thread(store.denied,actor,request.path,error.code,request_id)
            response_value=web.json_response({'ok':False,'error':{'code':error.code,'message':error.message},'request_id':request_id},status=error.status)
        except web.HTTPRequestEntityTooLarge:
            response_value=web.json_response({'ok':False,'error':{'code':'TOO_LARGE','message':'上传文件过大'},'request_id':request_id},status=413)
        except (ValueError,TypeError,KeyError):
            await asyncio.to_thread(store.denied,actor,request.path,'INVALID',request_id)
            response_value=web.json_response({'ok':False,'error':{'code':'INVALID','message':'请求字段或格式无效'},'request_id':request_id},status=422)
        except web.HTTPException as error:
            response_value=web.Response(status=error.status,headers=error.headers,text=error.text)
        except Exception:
            LOG.exception('management failure request_id=%s',request_id)
            response_value=web.json_response({'ok':False,'error':{'code':'INTERNAL','message':'操作失败，请重试并记录请求编号'},'request_id':request_id},status=500)
        response_value.headers.update({'X-Content-Type-Options':'nosniff','Referrer-Policy':'same-origin','X-Frame-Options':'DENY','Cache-Control':'no-store','X-Request-ID':request_id,'Content-Security-Policy':"default-src 'self'; img-src 'self' data:; style-src 'self'; script-src 'self'; connect-src 'self'; object-src 'none'; frame-ancestors 'none'; base-uri 'none'"})
        LOG.info('request id=%s method=%s path=%s status=%s ms=%.1f',request_id,request.method,request.path,response_value.status,(time.perf_counter()-started)*1000)
        return response_value
    app=web.Application(middlewares=[security],client_max_size=48*1024*1024)
    async def authenticate(request,csrf=False):
        user=await asyncio.to_thread(store.user,request.cookies.get('management_session',''))
        request[USER]=user
        if csrf:
            import hmac
            require(hmac.compare_digest(request.headers.get('X-Admin-CSRF',''),user['csrf']),'会话校验失败，请刷新后重试','CSRF',403)
        return user
    async def health(request):
        with store.connection() as c: c.execute('SELECT 1').fetchone()
        return response({'status':'ok','schema':1,'scope':'management'})
    async def config(request): return response({'preview':store.preview,'roles':sorted(ROLES)})
    async def login(request):
        body=await request.json();require(isinstance(body,dict),'登录请求无效')
        preview=request.path.endswith('preview-login')
        if not preview:
            cutoff=time.monotonic()-60;ip=request.remote or 'unknown'
            attempts=[x for x in limits.get(ip,[]) if x>cutoff]
            require(len(attempts)<6,'登录尝试过多，请一分钟后再试','RATE_LIMIT',429)
            attempts.append(time.monotonic());limits[ip]=attempts
            if len(limits)>1000: limits.clear()
        token,user=await asyncio.to_thread(store.login,body,preview,request[REQUEST_ID])
        result=response(user);result.set_cookie('management_session',token,httponly=True,samesite='Strict',secure=secure,max_age=8*3600,path='/')
        return result
    async def logout(request):
        user=await authenticate(request,True)
        def revoke():
            with store.transaction() as c:
                c.execute('DELETE FROM sessions WHERE token_hash=?',(hashlib.sha256(request.cookies['management_session'].encode()).hexdigest(),))
                store.audit(c,user['id'],'logout',user['id'],'success',{},request[REQUEST_ID])
        await asyncio.to_thread(revoke)
        result=response({'logged_out':True});result.del_cookie('management_session',path='/');return result
    async def state(request):
        user=await authenticate(request)
        cursor=int(request.query.get('audit_after','0'));require(cursor>=0,'分页游标无效')
        return response(await asyncio.to_thread(store.state,user,cursor))
    async def action(request):
        user=await authenticate(request,True)
        body=await request.json()
        return response(await asyncio.to_thread(store.write,user,request.match_info['action'],body,request.headers.get('Idempotency-Key'),request[REQUEST_ID]))
    async def runtime(request):
        await authenticate(request)
        return response(await asyncio.to_thread(store.runtime,request.query.get('channel','preview')))
    async def blob(request):
        await authenticate(request)
        digest=request.match_info['digest'];require(re.fullmatch('[a-f0-9]{64}',digest),'素材标识无效')
        with store.connection() as c: row=c.execute('SELECT * FROM blobs WHERE digest=?',(digest,)).fetchone()
        require(row and (store.blob_dir/digest).is_file(),'素材不存在','NOT_FOUND',404)
        result=web.FileResponse(store.blob_dir/digest)
        result.headers['Content-Type']=row['media_type']
        if row['media_type']=='model/gltf-binary': result.headers['Content-Disposition']='attachment; filename="model.glb"'
        return result
    async def frontend(request):
        tail=request.match_info.get('tail','')
        dist=ROOT/'frontend/dist'
        file=(dist/tail).resolve() if tail else dist/'index.html'
        require(file.is_relative_to(dist.resolve()),'路径无效','FORBIDDEN',403)
        if not file.is_file() and '.' not in tail: file=dist/'index.html'
        require(file.is_file(),'前端尚未构建，请运行 npm --prefix admin/frontend run build','NOT_FOUND',404)
        return web.FileResponse(file)
    app.router.add_get('/health',health)
    app.router.add_get('/api/admin/config',config)
    app.router.add_post('/api/admin/login',login)
    app.router.add_post('/api/admin/preview-login',login)
    app.router.add_post('/api/admin/logout',logout)
    app.router.add_get('/api/admin/state',state)
    app.router.add_get('/api/admin/blobs/{digest}',blob)
    app.router.add_post('/api/admin/{action}',action)
    app.router.add_get('/api/runtime/release',runtime)
    app.router.add_get('/admin/{tail:.*}',frontend)
    async def home(request): raise web.HTTPFound('/admin/')
    app.router.add_get('/',home)
    return app

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--port',type=int,default=8787)
    parser.add_argument('--data',default=str(ROOT/'data'))
    parser.add_argument('--local-preview',action='store_true')
    parser.add_argument('--allowed-host',action='append',default=[])
    parser.add_argument('--dev-origin',action='append',default=[])
    parser.add_argument('--secure-cookie',action='store_true')
    parser.add_argument('--create-admin',action='store_true')
    parser.add_argument('--backup')
    args=parser.parse_args()
    store=Store(args.data,args.local_preview)
    if args.create_admin:
        store.bootstrap(input('管理员用户名: '),getpass.getpass('密码（至少12字符）: '));print('管理员已创建');return
    if args.backup:
        store.backup(args.backup);print('数据库备份已完成；请同时备份素材目录');return
    require(not args.local_preview or not args.allowed_host,'预览模式只允许 loopback Host')
    from urllib.parse import urlsplit
    for origin in args.dev_origin:
        parsed=urlsplit(origin)
        require(args.local_preview and parsed.scheme=='http' and parsed.hostname in {'127.0.0.1','localhost'} and not parsed.username and not parsed.password and not parsed.path and not parsed.query and not parsed.fragment,'开发Origin需为本机HTTP源，且仅限local-preview')
    hosts=set(args.allowed_host)|{f'127.0.0.1:{args.port}',f'localhost:{args.port}'}
    logging.basicConfig(level=logging.INFO,format='%(asctime)s %(levelname)s %(message)s')
    print(f'Management: http://127.0.0.1:{args.port}/admin/ | preview={args.local_preview}',flush=True)
    web.run_app(build_app(store,hosts,args.secure_cookie,args.dev_origin),host='127.0.0.1',port=args.port,access_log=None)
if __name__=='__main__': main()

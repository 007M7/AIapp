"""Local management domain. No writes to device voice service or real user data."""
import base64
import hashlib
import hmac
import json
import secrets
import sqlite3
from contextlib import contextmanager,closing
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROLES = {'admin','editor','reviewer','publisher','operator','viewer'}
PERMISSIONS = {
    'admin': {'read','write','review','publish','execute','users'},
    'editor': {'read','write'}, 'reviewer': {'read','review'},
    'publisher': {'read','publish'}, 'operator': {'read','execute'}, 'viewer': {'read'},
}
KINDS = {'asset','character','content','event'}
def now(): return datetime.now(timezone.utc).isoformat(timespec='milliseconds')
def uid(): return secrets.token_hex(16)
def dump(value): return json.dumps(value,ensure_ascii=False,separators=(',',':'),sort_keys=True)
def password_hash(password):
    salt=secrets.token_hex(16)
    digest=hashlib.pbkdf2_hmac('sha256',password.encode(),salt.encode(),240000).hex()
    return f'{salt}:{digest}'
def password_ok(password,encoded):
    salt,expected=encoded.split(':')
    actual=hashlib.pbkdf2_hmac('sha256',password.encode(),salt.encode(),240000).hex()
    return hmac.compare_digest(actual,expected)
class Fault(Exception):
    def __init__(self,status,code,message):
        self.status,self.code,self.message=status,code,message
        super().__init__(message)
def require(condition,message,code='INVALID',status=422):
    if not condition: raise Fault(status,code,message)
def string(value,label,maximum=100,minimum=1):
    require(isinstance(value,str) and minimum<=len(value.strip())<=maximum,f'{label}需为 {minimum}～{maximum} 字符')
    return value.strip()
def integer(value,label,low,high):
    require(type(value) is int and low<=value<=high,f'{label}需为 {low}～{high} 的整数')
    return value

class Store:
    def __init__(self,directory,preview=False):
        self.directory=Path(directory).resolve()
        self.directory.mkdir(parents=True,exist_ok=True)
        self.blob_dir=self.directory/'blobs'; self.blob_dir.mkdir(exist_ok=True)
        self.db=self.directory/'management.sqlite3'; self.preview=preview
        with self.connection() as c:
            if c.execute("SELECT 1 FROM sqlite_master WHERE type='table' AND name='schema_version'").fetchone():
                version=c.execute('SELECT max(version) FROM schema_version').fetchone()[0]
                require(version in (None,1),'数据库版本高于当前程序，请使用匹配版本','SCHEMA_INCOMPATIBLE',503)
            c.execute('PRAGMA journal_mode=WAL')
            c.executescript(Path(__file__).with_name('schema.sql').read_text(encoding='utf-8'))
            c.execute('INSERT OR IGNORE INTO schema_version VALUES(1,?)',(now(),))
            c.executemany('INSERT OR IGNORE INTO channels(name) VALUES(?)',[('preview',),('staging',)])
        if preview:
            with self.transaction() as c:
                for role in sorted(ROLES):
                    c.execute('INSERT OR IGNORE INTO admins VALUES(?,?,?,?,?,?,?)',(f'preview-{role}',f'preview-{role}',password_hash(uid()),role,1,1,now()))
    @contextmanager
    def connection(self):
        c=sqlite3.connect(self.db,timeout=15,isolation_level=None)
        c.row_factory=sqlite3.Row;c.execute('PRAGMA foreign_keys=ON');c.execute('PRAGMA busy_timeout=15000')
        try: yield c
        finally: c.close()
    @contextmanager
    def transaction(self):
        with self.connection() as c:
            c.execute('BEGIN IMMEDIATE')
            try: yield c; c.commit()
            except BaseException: c.rollback(); raise
    def audit(self,c,actor,action,target,outcome,details,request_id):
        c.execute('INSERT INTO audit(request_id,actor,action,target,outcome,details,created_at) VALUES(?,?,?,?,?,?,?)',(request_id,actor,action,target,outcome,dump(details),now()))
    def denied(self,actor,action,code,request_id):
        with self.transaction() as c: self.audit(c,actor,action,None,'failed',{'code':code},request_id)
    def user(self,token):
        with self.connection() as c:
            row=c.execute('SELECT a.id,a.username,a.role,a.preview_only,s.csrf FROM sessions s JOIN admins a ON a.id=s.admin_id WHERE s.token_hash=? AND s.expires_at>? AND a.enabled=1',(hashlib.sha256(token.encode()).hexdigest(),now())).fetchone()
        require(row and (self.preview or not row['preview_only']),'请登录后台','UNAUTHENTICATED',401)
        return dict(row)
    def login(self,body,preview,request_id):
        with self.transaction() as c:
            if preview:
                require(self.preview,'预览身份入口未启用','FORBIDDEN',403)
                require(body.get('role') in ROLES,'角色不存在')
                row=c.execute('SELECT * FROM admins WHERE id=? AND enabled=1',(f"preview-{body['role']}",)).fetchone()
            else:
                name=string(body.get('username'),'用户名',60)
                password=string(body.get('password'),'密码',200)
                row=c.execute('SELECT * FROM admins WHERE username=? AND preview_only=0 AND enabled=1',(name,)).fetchone()
                # Same expensive hash path for unknown users.
                encoded=row['password_hash'] if row else '00000000000000000000000000000000:'+'0'*64
                require(password_ok(password,encoded) and row,'用户名或密码不正确','LOGIN_FAILED',401)
            require(row,'管理员不可用','LOGIN_FAILED',401)
            token=secrets.token_urlsafe(32);csrf=secrets.token_urlsafe(32)
            c.execute('DELETE FROM sessions WHERE expires_at<=?',(now(),))
            c.execute('INSERT INTO sessions VALUES(?,?,?,?)',(hashlib.sha256(token.encode()).hexdigest(),row['id'],csrf,(datetime.now(timezone.utc)+timedelta(hours=8)).isoformat()))
            self.audit(c,row['id'],'login',row['id'],'success',{'preview':preview},request_id)
            return token,{'id':row['id'],'username':row['username'],'role':row['role'],'csrf':csrf,'preview':bool(row['preview_only'])}
    def bootstrap(self,name,password):
        name=string(name,'用户名',60);password=string(password,'密码',200,12)
        with self.transaction() as c:
            require(not c.execute('SELECT 1 FROM admins WHERE preview_only=0').fetchone(),'真实管理员已存在，请用管理页面添加')
            user_id=uid()
            c.execute('INSERT INTO admins VALUES(?,?,?,?,?,?,?)',(user_id,name,password_hash(password),'admin',1,0,now()))
            self.audit(c,user_id,'bootstrap',user_id,'success',{},uid())
    def permission(self,user,permission):
        require(permission in PERMISSIONS[user['role']],'当前管理员无此操作权限','FORBIDDEN',403)
    def revision(self,c,revision_id):
        row=c.execute('SELECT r.*,o.kind,o.name FROM revisions r JOIN objects o ON o.id=r.object_id WHERE r.id=?',(revision_id,)).fetchone()
        require(row,'版本不存在','NOT_FOUND',404)
        return dict(row)
    def payload(self,c,kind,p):
        require(isinstance(p,dict),'内容格式应为对象')
        refs=[]
        def ref(field,target):
            value=string(p.get(field),field,64)
            r=self.revision(c,value);require(r['kind']==target,f'{field}引用类型不匹配')
            refs.append(value);return value
        if kind=='character':
            result={'persona':string(p.get('persona'),'角色设定',3000),'voice':string(p.get('voice'),'音色标识',100),'asset_revision':ref('asset_revision','asset')}
        elif kind=='content':
            result={'text':string(p.get('text'),'内容正文',6000),'character_revision':ref('character_revision','character')}
        elif kind=='event':
            trigger=p.get('trigger');require(trigger in {'manual','daily_time','game_hook'},'触发方式无效')
            result={'content_revision':ref('content_revision','content'),'trigger':trigger,'target':'app_preview','cooldown_seconds':integer(p.get('cooldown_seconds',0),'冷却秒数',0,86400),'ttl_seconds':integer(p.get('ttl_seconds',3600),'有效期秒数',1,86400)}
            require(p.get('target','app_preview')=='app_preview','实体设备执行链路未接入','CAPABILITY_UNAVAILABLE',409)
            if trigger=='daily_time':
                result['local_time']=string(p.get('local_time'),'时点',5)
                import re
                require(re.fullmatch(r'(?:[01]\d|2[0-3]):[0-5]\d',result['local_time']),'时点格式为 HH:MM')
                result['timezone']='Asia/Shanghai'
            if trigger=='game_hook': result['hook']=string(p.get('hook'),'hook 标识',80)
        else: raise Fault(422,'INVALID','素材通过上传入口创建')
        require(set(p)<=set(result),'包含未声明的字段')
        return result,refs
    def write(self,user,action,body,key,request_id):
        require(isinstance(body,dict),'请求格式无效')
        fields={
            'save':{'kind','name','payload','object_id','expected_head'},
            'upload':{'name','filename','data','object_id','expected_head'},
            'submit':{'revision_id'},'review':{'revision_id','decision','reason'},
            'publish':{'name','reason','revision_ids','channel','expected_release_id'},
            'rollback':{'reason','release_id','channel','expected_release_id'},
            'withdraw':{'reason','channel','expected_release_id'},
            'execute':{'channel','release_id','revision_id'},
            'create_user':{'username','password','role'},'set_user':{'id','role','enabled','reason'},
        }
        require(action in fields and set(body)<=fields[action],'请求含未声明字段或未知操作')
        key=string(key,'幂等键',100,8)
        fingerprint=hashlib.sha256(dump({'action':action,'body':body}).encode()).hexdigest()
        required={'save':'write','upload':'write','submit':'write','review':'review','publish':'publish','rollback':'publish','withdraw':'publish','execute':'execute','create_user':'users','set_user':'users'}
        require(action in required,'未知操作')
        self.permission(user,required[action])
        with self.transaction() as c:
            current=c.execute('SELECT role,enabled FROM admins WHERE id=?',(user['id'],)).fetchone()
            require(current and current['enabled'],'管理员已停用','UNAUTHENTICATED',401)
            user=dict(user,role=current['role'])
            self.permission(user,required[action])
            previous=c.execute('SELECT * FROM idempotency WHERE actor=? AND key=?',(user['id'],key)).fetchone()
            if previous:
                require(previous['fingerprint']==fingerprint,'幂等键已用于其他请求','IDEMPOTENCY_CONFLICT',409)
                return json.loads(previous['response'])
            if 'reason' in body: string(body['reason'],'操作说明',500)
            result=getattr(self,'op_'+action)(c,user,body)
            target=result.get('id') or result.get('release_id')
            self.audit(c,user['id'],action,target,'success',{'reason':body.get('reason','')[:500],'revision_id':result.get('revision_id'),'state':result.get('state'),'channel':body.get('channel'),'before_release_id':body.get('expected_release_id'),'after_release_id':result.get('release_id'),'role':result.get('role'),'enabled':result.get('enabled')},request_id)
            c.execute('INSERT INTO idempotency VALUES(?,?,?,?,?)',(user['id'],key,fingerprint,dump(result),now()))
            return result
    def new_revision(self,c,user,kind,name,payload,refs,object_id=None,expected=0):
        if object_id:
            obj=c.execute('SELECT * FROM objects WHERE id=?',(object_id,)).fetchone()
            require(obj and obj['kind']==kind,'对象不存在','NOT_FOUND',404)
            require(obj['head']==expected,'草稿已被更新，请刷新后再保存','VERSION_CONFLICT',409)
            number=obj['head']+1
        else:
            object_id=uid();number=1
            c.execute('INSERT INTO objects VALUES(?,?,?,?,?)',(object_id,kind,name,0,now()))
        revision_id=uid()
        c.execute('INSERT INTO revisions(id,object_id,number,payload,state,created_by,created_at) VALUES(?,?,?,?,?,?,?)',(revision_id,object_id,number,dump(payload),'draft',user['id'],now()))
        c.executemany('INSERT INTO revision_refs VALUES(?,?)',[(revision_id,target) for target in refs])
        c.execute('UPDATE objects SET name=?,head=? WHERE id=?',(name,number,object_id))
        return {'id':object_id,'revision_id':revision_id,'number':number,'state':'draft'}
    def op_save(self,c,user,b):
        kind=b.get('kind');require(kind in KINDS-{'asset'},'类型无效')
        name=string(b.get('name'),'名称',100)
        p,refs=self.payload(c,kind,b.get('payload'))
        if b.get('object_id'): integer(b.get('expected_head'),'预期版本',1,1000000)
        return self.new_revision(c,user,kind,name,p,refs,b.get('object_id'),b.get('expected_head',0))
    def op_upload(self,c,user,b):
        name=string(b.get('name'),'素材名称',100);filename=string(b.get('filename'),'文件名',200)
        require(isinstance(b.get('data'),str) and len(b['data'])<=48*1024*1024,'文件超过 32MB')
        try: data=base64.b64decode(b['data'],validate=True)
        except (ValueError,TypeError): raise Fault(422,'INVALID','上传数据无效')
        require(0<len(data)<=32*1024*1024,'文件大小需在 1B～32MB')
        if data.startswith(b'\x89PNG\r\n\x1a\n') and filename.lower().endswith('.png'): media='image/png'
        elif data.startswith(b'\xff\xd8\xff') and filename.lower().endswith(('.jpg','.jpeg')): media='image/jpeg'
        elif data.startswith(b'glTF') and filename.lower().endswith('.glb'):
            import struct
            require(len(data)>=12 and struct.unpack('<II',data[4:12])==(2,len(data)),'GLB 版本或长度无效')
            media='model/gltf-binary'
        else: raise Fault(422,'INVALID','仅支持 PNG、JPEG、GLB，请核对文件内容')
        digest=hashlib.sha256(data).hexdigest();dest=self.blob_dir/digest
        if not dest.exists():
            temp=self.blob_dir/(digest+'.'+uid()+'.tmp');temp.write_bytes(data);temp.replace(dest)
        c.execute('INSERT OR IGNORE INTO blobs VALUES(?,?,?,?)',(digest,media,len(data),Path(filename).name))
        if b.get('object_id'): integer(b.get('expected_head'),'预期版本',1,1000000)
        return self.new_revision(c,user,'asset',name,{'digest':digest,'media_type':media,'size':len(data),'filename':Path(filename).name},[],b.get('object_id'),b.get('expected_head',0))
    def op_submit(self,c,user,b):
        r=self.revision(c,b.get('revision_id'))
        require(r['state']=='draft','只有草稿可以提交审核','STATE_CONFLICT',409)
        c.execute("UPDATE revisions SET state='in_review' WHERE id=?",(r['id'],))
        return {'id':r['object_id'],'revision_id':r['id'],'state':'in_review'}
    def op_review(self,c,user,b):
        r=self.revision(c,b.get('revision_id'))
        require(r['state']=='in_review','此版本不在审核中','STATE_CONFLICT',409)
        require(r['created_by']!=user['id'],'不能审核自己创建的版本','SELF_REVIEW',403)
        decision=b.get('decision');require(decision in {'approved','rejected'},'审核结果无效')
        note=string(b.get('reason'),'审核意见',500)
        if decision=='approved':
            for row in c.execute('SELECT target_revision_id FROM revision_refs WHERE revision_id=?',(r['id'],)):
                require(self.revision(c,row[0])['state']=='approved','引用版本尚未审核通过','DEPENDENCY_NOT_APPROVED',409)
        c.execute('UPDATE revisions SET state=?,reviewed_by=?,review_note=?,reviewed_at=? WHERE id=?',(decision,user['id'],note,now(),r['id']))
        return {'id':r['object_id'],'revision_id':r['id'],'state':decision}
    def closure(self,c,ids):
        found={};pending=list(ids)
        while pending:
            rid=pending.pop()
            if rid in found: continue
            r=self.revision(c,rid)
            require(r['state']=='approved','发布清单包含未审核版本','DEPENDENCY_NOT_APPROVED',409)
            found[rid]=r
            pending += [row[0] for row in c.execute('SELECT target_revision_id FROM revision_refs WHERE revision_id=?',(rid,))]
        selected={}
        for r in found.values():
            require(r['object_id'] not in selected or selected[r['object_id']]==r['id'],'同一发布不能包含同一对象的多个版本','DEPENDENCY_CONFLICT',409)
            selected[r['object_id']]=r['id']
        return list(found.values())
    def channel(self,c,b):
        require(b.get('channel') in {'preview','staging'},'仅支持预览／测试环境')
        ch=c.execute('SELECT * FROM channels WHERE name=?',(b['channel'],)).fetchone()
        require('expected_release_id' in b and ch['release_id']==b['expected_release_id'],'环境发布指针已变更，请刷新','VERSION_CONFLICT',409)
        return dict(ch)
    def move_channel(self,c,user,ch,target,action):
        c.execute('UPDATE channels SET release_id=? WHERE name=?',(target,ch['name']))
        c.execute('INSERT INTO channel_history(channel,release_id,previous_release_id,action,actor,created_at) VALUES(?,?,?,?,?,?)',(ch['name'],target,ch['release_id'],action,user['id'],now()))
    def op_publish(self,c,user,b):
        name=string(b.get('name'),'发布名称',100);string(b.get('reason'),'发布说明',500)
        require(isinstance(b.get('revision_ids'),list) and 1<=len(b['revision_ids'])<=100 and all(isinstance(x,str) for x in b['revision_ids']),'需选择 1～100 个版本')
        ch=self.channel(c,b);revisions=self.closure(c,b['revision_ids'])
        rid=uid();manifest=[{'revision_id':r['id'],'object_id':r['object_id'],'kind':r['kind'],'name':r['name'],'number':r['number'],'payload':json.loads(r['payload'])} for r in sorted(revisions,key=lambda r:r['id'])]
        c.execute('INSERT INTO releases VALUES(?,?,?,?,?)',(rid,name,dump(manifest),user['id'],now()))
        self.move_channel(c,user,ch,rid,'publish')
        return {'id':rid,'release_id':rid,'count':len(manifest),'channel':ch['name']}
    def op_rollback(self,c,user,b):
        string(b.get('reason'),'回退说明',500);ch=self.channel(c,b);rid=b.get('release_id')
        require(c.execute('SELECT 1 FROM channel_history WHERE channel=? AND release_id=?',(ch['name'],rid)).fetchone(),'只能回退到该环境发布过的版本')
        require(rid!=ch['release_id'],'该版本已在当前环境','STATE_CONFLICT',409)
        self.move_channel(c,user,ch,rid,'rollback');return {'release_id':rid,'channel':ch['name']}
    def op_withdraw(self,c,user,b):
        string(b.get('reason'),'下架说明',500);ch=self.channel(c,b)
        require(ch['release_id'],'环境已下架','STATE_CONFLICT',409)
        self.move_channel(c,user,ch,None,'withdraw');return {'id':ch['release_id'],'release_id':None,'channel':ch['name']}
    def op_execute(self,c,user,b):
        require(b.get('channel') in {'preview','staging'},'环境无效')
        ch=c.execute('SELECT * FROM channels WHERE name=?',(b['channel'],)).fetchone()
        require(ch['release_id'] and ch['release_id']==b.get('release_id'),'发布版本已变化或下架','VERSION_CONFLICT',409)
        release=c.execute('SELECT * FROM releases WHERE id=?',(ch['release_id'],)).fetchone()
        entries={x['revision_id']:x for x in json.loads(release['manifest'])}
        event=entries.get(b.get('revision_id'));require(event and event['kind']=='event','事件未在当前发布中')
        payload=event['payload'];require(payload['target']=='app_preview','设备执行不可用','CAPABILITY_UNAVAILABLE',409)
        previous=c.execute('SELECT created_at FROM executions WHERE actor=? AND revision_id=? ORDER BY created_at DESC LIMIT 1',(user['id'],event['revision_id'])).fetchone()
        if previous:
            elapsed=(datetime.now(timezone.utc)-datetime.fromisoformat(previous[0])).total_seconds()
            require(elapsed>=payload['cooldown_seconds'],'事件仍在冷却中','COOLDOWN',409)
        content=entries[payload['content_revision']];character=entries[content['payload']['character_revision']]
        asset=entries[character['payload']['asset_revision']]
        result={'scope':'local-admin-preview','text':content['payload']['text'],'character':character['name'],'asset_digest':asset['payload']['digest'],'device_played':False,'trigger':payload['trigger']}
        eid=uid();c.execute('INSERT INTO executions VALUES(?,?,?,?,?,?,?)',(eid,ch['release_id'],event['revision_id'],user['id'],'preview_completed',dump(result),now()))
        return {'id':eid,'status':'preview_completed','result':result}
    def op_create_user(self,c,user,b):
        name=string(b.get('username'),'用户名',60);password=string(b.get('password'),'密码',200,12)
        require(b.get('role') in ROLES,'角色不存在')
        require(not c.execute('SELECT 1 FROM admins WHERE username=?',(name,)).fetchone(),'用户名已存在','CONFLICT',409)
        aid=uid();c.execute('INSERT INTO admins VALUES(?,?,?,?,?,?,?)',(aid,name,password_hash(password),b['role'],1,0,now()))
        return {'id':aid,'username':name,'role':b['role']}
    def op_set_user(self,c,user,b):
        string(b.get('reason'),'变更说明',500);target=c.execute('SELECT * FROM admins WHERE id=?',(b.get('id'),)).fetchone()
        require(target and not target['preview_only'],'真实管理员不存在','NOT_FOUND',404)
        require(target['id']!=user['id'],'不能在此修改自身权限','FORBIDDEN',403)
        require(b.get('role') in ROLES and type(b.get('enabled')) is bool,'角色或启停状态无效')
        if target['role']=='admin' and target['enabled'] and (b['role']!='admin' or not b['enabled']):
            require(c.execute("SELECT count(*) FROM admins WHERE role='admin' AND enabled=1 AND preview_only=0").fetchone()[0]>1,'不能禁用最后一个真实管理员','LAST_ADMIN',409)
        c.execute('UPDATE admins SET role=?,enabled=? WHERE id=?',(b['role'],int(b['enabled']),target['id']))
        c.execute('DELETE FROM sessions WHERE admin_id=?',(target['id'],))
        return {'id':target['id'],'role':b['role'],'enabled':b['enabled']}
    def state(self,user,after=0):
        self.permission(user,'read')
        with self.connection() as c:
            objects=[dict(x) for x in c.execute('SELECT * FROM objects ORDER BY created_at DESC LIMIT 300')]
            revisions=[]
            for row in c.execute('SELECT r.*,o.kind,o.name,a.username creator FROM revisions r JOIN objects o ON o.id=r.object_id JOIN admins a ON a.id=r.created_by ORDER BY r.created_at DESC LIMIT 1000'):
                r=dict(row);r['payload']=json.loads(r['payload']);revisions.append(r)
            releases=[dict(x) for x in c.execute('SELECT * FROM releases ORDER BY created_at DESC LIMIT 100')]
            for release in releases: release['manifest']=json.loads(release['manifest'])
            audit=[dict(x) for x in c.execute('SELECT au.*,a.username FROM audit au LEFT JOIN admins a ON a.id=au.actor WHERE au.id>? ORDER BY au.id ASC LIMIT 100',(after,))]
            for x in audit: x['details']=json.loads(x['details'])
            executions=[dict(x) for x in c.execute('SELECT * FROM executions ORDER BY created_at DESC LIMIT 100')]
            for x in executions: x['result']=json.loads(x['result'])
            users=[dict(x) for x in c.execute('SELECT id,username,role,enabled,preview_only FROM admins ORDER BY username')] if 'users' in PERMISSIONS[user['role']] else []
            return {'user':user,'preview':self.preview,'permissions':sorted(PERMISSIONS[user['role']]),'objects':objects,'revisions':revisions,'releases':releases,'channels':[dict(x) for x in c.execute('SELECT * FROM channels')],'history':[dict(x) for x in c.execute('SELECT * FROM channel_history ORDER BY id DESC LIMIT 100')],'executions':executions,'audit':audit,'audit_next':audit[-1]['id'] if audit else after,'users':users}
    def runtime(self,channel):
        require(channel in {'preview','staging'},'环境无效')
        with self.connection() as c:
            row=c.execute('SELECT r.* FROM releases r JOIN channels c ON c.release_id=r.id WHERE c.name=?',(channel,)).fetchone()
            return {'channel':channel,'release':None if not row else {'id':row['id'],'name':row['name'],'manifest':json.loads(row['manifest'])},'scope':'local-management-preview'}
    def backup(self,path):
        dest=Path(path).resolve()
        require(dest!=self.db,'备份目标不可覆盖当前数据库')
        dest.parent.mkdir(parents=True,exist_ok=True)
        with self.connection() as c,closing(sqlite3.connect(dest)) as target: c.backup(target)

import base64
import concurrent.futures
import json
import sqlite3
import tempfile
import shutil
import unittest
from contextlib import closing
from pathlib import Path
from admin.service import Store,Fault,uid

# Valid transparent PNG; fixtures are explicit, never production user data.
PNG=base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==')
class DomainTests(unittest.TestCase):
    def setUp(self):
        test_root=Path(__file__).resolve().parents[1]/'data/tests';test_root.mkdir(parents=True,exist_ok=True)
        self.temp=tempfile.TemporaryDirectory(dir=test_root);self.store=Store(self.temp.name,True)
        self.users={role:self.store.login({'role':role},True,uid())[1] for role in ['admin','editor','reviewer','publisher','operator','viewer']}
    def tearDown(self):
        assert Path(self.temp.name).resolve().parent==Path(__file__).resolve().parents[1]/'data/tests'
        self.temp.cleanup()
    def call(self,action,body,role='editor',key=None): return self.store.write(self.users[role],action,body,key or uid(),uid())
    def expect_fault(self,code,action,body,role='editor',key=None):
        with self.assertRaises(Fault) as ctx: self.call(action,body,role,key)
        self.assertEqual(ctx.exception.code,code)
    def asset(self,name='图像',approve=True):
        result=self.call('upload',{'name':name,'filename':'image.png','data':base64.b64encode(PNG).decode()})
        if approve: self.approve(result)
        return result
    def approve(self,result):
        self.call('submit',{'revision_id':result['revision_id']})
        self.call('review',{'revision_id':result['revision_id'],'decision':'approved','reason':'已核对'},'reviewer')
    def chain(self,cooldown=0):
        asset=self.asset()
        char=self.call('save',{'kind':'character','name':'小鲸','payload':{'persona':'日常搭子','voice':'Cherry','asset_revision':asset['revision_id']}});self.approve(char)
        content=self.call('save',{'kind':'content','name':'问候','payload':{'text':'看到你啦。','character_revision':char['revision_id']}});self.approve(content)
        event=self.call('save',{'kind':'event','name':'招手','payload':{'content_revision':content['revision_id'],'trigger':'manual','target':'app_preview','cooldown_seconds':cooldown,'ttl_seconds':3600}});self.approve(event)
        return asset,char,content,event
    def publish(self,event,expected=None): return self.call('publish',{'name':'发布','reason':'验证','revision_ids':[event['revision_id']],'channel':'preview','expected_release_id':expected},'publisher')
    def test_complete_chain_snapshot_and_restart(self):
        chain=self.chain();release=self.publish(chain[-1]);self.assertEqual(release['count'],4)
        result=self.call('execute',{'channel':'preview','release_id':release['id'],'revision_id':chain[-1]['revision_id']},'operator')
        self.assertEqual(result['status'],'preview_completed');self.assertFalse(result['result']['device_played'])
        restarted=Store(self.temp.name)
        self.assertEqual(restarted.runtime('preview')['release']['id'],release['id'])
        with restarted.connection() as c:self.assertGreater(c.execute('SELECT count(*) FROM audit').fetchone()[0],15)
    def test_unapproved_dependency_and_self_review(self):
        asset=self.asset(approve=False)
        char=self.call('save',{'kind':'character','name':'鲸','payload':{'persona':'搭子','voice':'Cherry','asset_revision':asset['revision_id']}})
        self.call('submit',{'revision_id':char['revision_id']})
        self.expect_fault('DEPENDENCY_NOT_APPROVED','review',{'revision_id':char['revision_id'],'decision':'approved','reason':'审核'},'reviewer')
        asset2=self.call('upload',{'name':'自审','filename':'x.png','data':base64.b64encode(PNG).decode()},'admin');self.call('submit',{'revision_id':asset2['revision_id']},'admin')
        self.expect_fault('SELF_REVIEW','review',{'revision_id':asset2['revision_id'],'decision':'approved','reason':'自审'},'admin')
    def test_role_boundaries(self):
        self.expect_fault('FORBIDDEN','upload',{'name':'图','filename':'x.png','data':base64.b64encode(PNG).decode()},'viewer')
        a=self.asset();self.expect_fault('FORBIDDEN','publish',{'name':'发布','reason':'检查','revision_ids':[a['revision_id']],'channel':'preview','expected_release_id':None})
        self.expect_fault('FORBIDDEN','create_user',{'username':'test','password':'test-password-123','role':'viewer'},'operator')
    def test_idempotency_and_conflict(self):
        key=uid();body={'name':'图','filename':'x.png','data':base64.b64encode(PNG).decode()}
        first=self.call('upload',body,key=key);self.assertEqual(first,self.call('upload',body,key=key))
        self.expect_fault('IDEMPOTENCY_CONFLICT','upload',dict(body,name='另一份'),key=key)
        with self.store.connection() as c:self.assertEqual(c.execute('SELECT count(*) FROM objects').fetchone()[0],1)
    def test_concurrent_save_one_winner(self):
        asset=self.asset();body={'kind':'character','name':'鲸','payload':{'persona':'搭子','voice':'Cherry','asset_revision':asset['revision_id']}}
        char=self.call('save',body);edit=dict(body,object_id=char['id'],expected_head=1)
        def save(_):
            try: return self.call('save',edit)['number']
            except Fault as e: return e.code
        with concurrent.futures.ThreadPoolExecutor(2) as pool: results=list(pool.map(save,range(2)))
        self.assertCountEqual(results,[2,'VERSION_CONFLICT'])
    def test_release_cas_and_immutable_drafts(self):
        a,ch,content,event=self.chain();release=self.publish(event)
        self.expect_fault('VERSION_CONFLICT','publish',{'name':'另一个','reason':'并发','revision_ids':[event['revision_id']],'channel':'preview','expected_release_id':None},'publisher')
        self.call('save',{'kind':'content','name':'问候更新','object_id':content['id'],'expected_head':1,'payload':{'text':'改变了','character_revision':ch['revision_id']}})
        manifest=self.store.runtime('preview')['release']['manifest']
        self.assertEqual(next(r['payload']['text'] for r in manifest if r['kind']=='content'),'看到你啦。')
        with self.store.connection() as c:
            with self.assertRaises(sqlite3.IntegrityError):c.execute("UPDATE revisions SET payload='{}' WHERE id=?",(content['revision_id'],))
            with self.assertRaises(sqlite3.IntegrityError):c.execute("UPDATE audit SET outcome='changed'")
            with self.assertRaises(sqlite3.IntegrityError):c.execute('DELETE FROM releases WHERE id=?',(release['id'],))
    def test_reject_and_resubmit(self):
        a=self.asset(approve=False);self.call('submit',{'revision_id':a['revision_id']})
        self.call('review',{'revision_id':a['revision_id'],'decision':'rejected','reason':'比例需修正'},'reviewer')
        self.expect_fault('STATE_CONFLICT','submit',{'revision_id':a['revision_id']})
        new=self.call('upload',{'name':'图修订','filename':'x.png','data':base64.b64encode(PNG).decode(),'object_id':a['id'],'expected_head':1});self.approve(new)
    def test_rollback_withdraw_and_cooldown(self):
        *_,event=self.chain(cooldown=60);one=self.publish(event);two=self.publish(event,one['id'])
        result=self.call('rollback',{'channel':'preview','release_id':one['id'],'expected_release_id':two['id'],'reason':'回到旧版'},'publisher')
        self.assertEqual(result['release_id'],one['id'])
        command={'channel':'preview','release_id':one['id'],'revision_id':event['revision_id']}
        self.call('execute',command,'operator');self.expect_fault('COOLDOWN','execute',command,'operator')
        self.call('withdraw',{'channel':'preview','expected_release_id':one['id'],'reason':'下架'},'publisher')
        self.expect_fault('VERSION_CONFLICT','execute',command,'operator')
        self.assertIsNone(self.store.runtime('preview')['release'])
    def test_conflicting_dependency_versions(self):
        asset=self.asset();updated=self.call('upload',{'name':'图更新','filename':'x.png','data':base64.b64encode(PNG).decode(),'object_id':asset['id'],'expected_head':1});self.approve(updated)
        self.expect_fault('DEPENDENCY_CONFLICT','publish',{'name':'冲突','reason':'冲突','revision_ids':[asset['revision_id'],updated['revision_id']],'channel':'preview','expected_release_id':None},'publisher')
    def test_invalid_upload_payload_and_capability(self):
        self.expect_fault('INVALID','upload',{'name':'恶意','filename':'x.svg','data':base64.b64encode(b'<script>').decode()})
        self.expect_fault('INVALID','upload',{'name':'无效','filename':'x.png','data':'notbase64'})
        a,ch,content,_=self.chain()
        self.expect_fault('CAPABILITY_UNAVAILABLE','save',{'kind':'event','name':'设备','payload':{'content_revision':content['revision_id'],'trigger':'manual','target':'device','cooldown_seconds':0,'ttl_seconds':10}})
        self.expect_fault('INVALID','save',{'kind':'content','name':'未知','payload':{'text':'内容','character_revision':ch['revision_id'],'unknown':1}})
    def test_user_disable_revoke_and_last_admin(self):
        self.store.bootstrap('owner','a-long-password-123')
        token,owner=self.store.login({'username':'owner','password':'a-long-password-123'},False,uid())
        created=self.call('create_user',{'username':'staff','password':'staff-password-123','role':'viewer'},'admin')
        staff_token,_=self.store.login({'username':'staff','password':'staff-password-123'},False,uid())
        self.call('set_user',{'id':created['id'],'role':'editor','enabled':False,'reason':'停用'},'admin')
        with self.assertRaises(Fault):self.store.user(staff_token)
        self.expect_fault('LAST_ADMIN','set_user',{'id':owner['id'],'role':'viewer','enabled':False,'reason':'停用最后管理员'},'admin')
        self.assertNotIn('password',json.dumps(self.store.state(self.users['admin'])['audit']))
        with self.assertRaises(Fault):Store(self.temp.name).user(self.store.login({'role':'editor'},True,uid())[0])
    def test_backup_restore_and_audit_cursor(self):
        chain=self.chain();release=self.publish(chain[-1]);backup=Path(self.temp.name)/'backup.sqlite3';self.store.backup(backup)
        with closing(sqlite3.connect(backup)) as c:self.assertEqual(c.execute('PRAGMA integrity_check').fetchone()[0],'ok');self.assertEqual(c.execute('SELECT release_id FROM channels WHERE name="preview"').fetchone()[0],release['id'])
        restored_dir=Path(self.temp.name)/'restored';restored_dir.mkdir()
        shutil.copy2(backup,restored_dir/'management.sqlite3');shutil.copytree(self.store.blob_dir,restored_dir/'blobs')
        restored=Store(restored_dir)
        self.assertEqual(restored.runtime('preview')['release']['id'],release['id'])
        self.assertEqual(len(list(restored.blob_dir.iterdir())),1)
        first=self.store.state(self.users['viewer']);next_page=self.store.state(self.users['viewer'],first['audit_next']);self.assertEqual(next_page['audit'],[])
    def test_future_schema_does_not_downgrade(self):
        with self.store.connection() as c:c.execute("INSERT INTO schema_version VALUES(2,'future')")
        with self.assertRaises(Fault) as error: Store(self.temp.name)
        self.assertEqual(error.exception.code,'SCHEMA_INCOMPATIBLE')
if __name__=='__main__':unittest.main()

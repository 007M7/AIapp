import asyncio
import tempfile
import unittest
from pathlib import Path
from aiohttp import CookieJar
from aiohttp.test_utils import TestClient,TestServer
from admin.server import build_app
from admin.service import Store

class HttpTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        test_root=Path(__file__).resolve().parents[1]/'data/tests';test_root.mkdir(parents=True,exist_ok=True)
        self.temp=tempfile.TemporaryDirectory(dir=test_root);self.store=await asyncio.to_thread(Store,self.temp.name,True);self.hosts=set()
        self.client=TestClient(TestServer(build_app(self.store,self.hosts)),cookie_jar=CookieJar(unsafe=True))
        await self.client.start_server();self.hosts.add(str(self.client.make_url('/').host)+':'+str(self.client.make_url('/').port))
    async def asyncTearDown(self):
        await self.client.close()
        assert Path(self.temp.name).resolve().parent==Path(__file__).resolve().parents[1]/'data/tests'
        self.temp.cleanup()
    async def login(self,role='editor'):
        res=await self.client.post('/api/admin/preview-login',json={'role':role});data=await res.json();self.assertEqual(res.status,200)
        cookie=res.cookies['management_session'];self.assertTrue(cookie['httponly']);self.assertEqual(cookie['samesite'],'Strict')
        return data['data']
    async def test_auth_csrf_origin_host_and_logout(self):
        res=await self.client.get('/api/admin/state');self.assertEqual(res.status,401)
        user=await self.login();headers={'X-Admin-CSRF':user['csrf'],'Idempotency-Key':'test-request-one'}
        res=await self.client.post('/api/admin/save',json={});self.assertEqual(res.status,403)
        res=await self.client.post('/api/admin/save',json={},headers=dict(headers,Origin='https://evil.example'));self.assertEqual(res.status,403)
        res=await self.client.get('/health',headers={'Host':'evil.example'});self.assertEqual(res.status,403)
        res=await self.client.post('/api/admin/logout',json={},headers=headers);self.assertEqual(res.status,200)
        res=await self.client.get('/api/admin/state');self.assertEqual(res.status,401)
    async def test_role_and_invalid_body(self):
        user=await self.login('viewer');headers={'X-Admin-CSRF':user['csrf'],'Idempotency-Key':'test-request-one'}
        res=await self.client.post('/api/admin/submit',json={'revision_id':'not-present'},headers=headers);self.assertEqual(res.status,403)
        res=await self.client.post('/api/admin/save',data='raw',headers=headers);self.assertEqual(res.status,415)
        res=await self.client.get('/api/admin/state?audit_after=-1');self.assertEqual(res.status,422)
    async def test_real_login_and_preview_disabled(self):
        self.store.bootstrap('owner','a-long-password-123')
        res=await self.client.post('/api/admin/login',json={'username':'owner','password':'wrong'});self.assertEqual(res.status,401)
        res=await self.client.post('/api/admin/login',json={'username':'owner','password':'a-long-password-123'});self.assertEqual(res.status,200)
        self.store.preview=False
        res=await self.client.post('/api/admin/preview-login',json={'role':'admin'});self.assertEqual(res.status,403)
    async def test_static_assets_and_security_headers(self):
        res=await self.client.get('/admin/');self.assertEqual(res.status,200)
        text=await res.text();self.assertIn('角色工坊',text)
        self.assertIn("frame-ancestors 'none'",res.headers['Content-Security-Policy'])
        await self.login();res=await self.client.get('/api/admin/blobs/not-a-digest');self.assertEqual(res.status,422)
        res=await self.client.get('/admin/../../service.py');self.assertNotEqual(res.status,200)
    async def test_login_rate_limit(self):
        for _ in range(6):await self.client.post('/api/admin/login',json={'username':'unknown','password':'wrong'})
        res=await self.client.post('/api/admin/login',json={'username':'unknown','password':'wrong'});self.assertEqual(res.status,429)
    async def test_dev_origin_is_preview_only(self):
        self.store.preview=False
        with self.assertRaises(Exception):build_app(self.store,self.hosts,allowed_origins={'http://127.0.0.1:5175'})
if __name__=='__main__':unittest.main()

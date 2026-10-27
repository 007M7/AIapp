import { readFile } from 'node:fs/promises';
import { isIP } from 'node:net';

// Optional loopback-only browser bridge. The LAN credential never enters HTML/JS.
export async function loadPilotConnection(file) {
  if (!file) return null;
  const value = JSON.parse(await readFile(file, 'utf8'));
  const url = new URL(value.server);
  const octets = url.hostname.split('.').map(Number);
  const privateIP = isIP(url.hostname) === 4 && (octets[0] === 127 || octets[0] === 10 ||
    (octets[0] === 192 && octets[1] === 168) || (octets[0] === 172 && octets[1] >= 16 && octets[1] <= 31));
  if (value.type !== 'aifigure.device.v1' || url.protocol !== 'http:' || !privateIP ||
      url.username || url.password || url.search || url.hash || url.pathname !== '/' ||
      !/^[A-Za-z0-9_-]{32,256}$/.test(value.credential)) throw new Error('Invalid private device connection configuration');
  return { server: url.origin, credential: value.credential };
}

export function createPilotProxy(connection, { port, fetchImpl = fetch } = {}) {
  const expectedHost = `127.0.0.1:${port}`;
  return async function handle(req, res) {
    const path = new URL(req.url, 'http://localhost').pathname;
    if (!path.startsWith('/__device/')) return false;
    const reply = (status, body) => {
      res.writeHead(status, {'Content-Type':'application/json; charset=utf-8', 'Cache-Control':'no-store',
        'X-Content-Type-Options':'nosniff'}).end(JSON.stringify(body));
    };
    const fail = (status, code, message) => reply(status, {error:{code,message}});
    if (req.headers.host !== expectedHost || req.headers['x-device-pilot'] !== '1' ||
        (req.headers.origin && req.headers.origin !== `http://${expectedHost}`) ||
        (req.headers['sec-fetch-site'] && !['same-origin','none'].includes(req.headers['sec-fetch-site']))) {
      fail(403, 'local_boundary', '仅允许本机同源页面访问'); return true;
    }
    if (!connection) { fail(503, 'bridge_not_configured', '本机尚未启用设备连接'); return true; }
    const read = req.method === 'GET' && (path === '/__device/status' || /^\/__device\/operations\/[0-9a-f]{32}$/.test(path));
    const voice = path === '/__device/voice';
    const write = req.method === 'POST' && (path === '/__device/identify' || voice);
    if (req.url.includes('?') || (!read && !write)) { fail(404, 'route_forbidden', '不支持此设备操作'); return true; }
    const headers = {Authorization: `Bearer ${connection.credential}`};
    if (write) {
      if (req.headers.origin !== `http://${expectedHost}` || req.headers['content-type'] !== (voice?'application/octet-stream':'application/json') ||
          !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(req.headers['idempotency-key'] || '')) {
        fail(400, 'invalid_request', '操作编号或请求格式错误'); return true;
      }
      let chunks = [], size = 0;
      for await (const chunk of req) {
        size += chunk.length; chunks.push(chunk);
        if (size > (voice?960000:1024)) { fail(413,'too_large','录音请勿超过30秒'); return true; }
      }
      const body = Buffer.concat(chunks);
      if (voice ? (size<16000 || size%2) : body.toString('utf8').trim() !== '{}') { fail(400,'invalid_body','录音需为0.5至30秒单声道PCM16LE'); return true; }
      req.pilotBody = voice ? body : '{}';
      headers['Content-Type'] = voice?'application/octet-stream':'application/json'; headers['Idempotency-Key'] = req.headers['idempotency-key'];
    }
    try {
      const upstream = await fetchImpl(`${connection.server}/lab/v1/${path.slice('/__device/'.length)}`, {
        method: req.method, headers, ...(write ? {body:req.pilotBody} : {}), redirect:'error', signal:AbortSignal.timeout(8000)
      });
      const text = await upstream.text();
      if (text.length > 65536) throw new Error('Oversized upstream response');
      const data = JSON.parse(text);
      // Never relay upstream headers (cookies, credentials or redirect targets).
      reply(upstream.status, data);
    } catch { fail(502,'gateway_unavailable', write ? '结果未确认，请查看手办；不会自动重发' : '暂时连不上电脑设备服务'); }
    return true;
  };
}

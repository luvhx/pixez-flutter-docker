import http from 'node:http';
import https from 'node:https';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

/**
 * PixEz session backend.
 *
 * Holds one Pixiv account (refresh/access token) server side, exposes a small
 * session API and proxies app-api.pixiv.net with the stored Bearer token.
 * The Flutter web client never sees the Pixiv token.
 */

const PORT = Number(process.env.PORT || 8080);
const STATE_FILE = process.env.PIXEZ_STATE_FILE || '/data/state.json';
const SETUP_TOKEN = process.env.PIXEZ_SETUP_TOKEN || '';
const COOKIE_NAME = 'pixez_session';
const TOKEN_URL = 'https://oauth.secure.pixiv.net/auth/token';
const API_HOST = 'app-api.pixiv.net';
const CLIENT_ID = 'MOBrBDS8blbauoSck0ZfDbtuzpyT';
const CLIENT_SECRET = 'lsACyCD94FhDUtGTXi3QzcFE2uU1hqtDaKeqrdwj';
const UA = 'PixivAndroidApp/5.0.166 (Android 10.0; Pixel C)';

const LOGIN_HTML = fs.readFileSync(new URL('./login.html', import.meta.url), 'utf8');

let state = loadState();
let refreshing = null;

function loadState() {
  try {
    return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
  } catch {
    return {};
  }
}

function saveState() {
  fs.mkdirSync(path.dirname(STATE_FILE), { recursive: true });
  const tmp = `${STATE_FILE}.tmp`;
  fs.writeFileSync(tmp, JSON.stringify(state, null, 2));
  fs.renameSync(tmp, STATE_FILE);
}

if (!state.sessionSecret) {
  state.sessionSecret = crypto.randomBytes(32).toString('hex');
  saveState();
}

function sessionValue() {
  return crypto
    .createHmac('sha256', state.sessionSecret)
    .update('pixez-web-session')
    .digest('hex');
}

function safeEqual(a, b) {
  const ba = Buffer.from(String(a));
  const bb = Buffer.from(String(b));
  return ba.length === bb.length && crypto.timingSafeEqual(ba, bb);
}

function parseCookies(req) {
  const out = {};
  for (const part of (req.headers.cookie || '').split(';')) {
    const idx = part.indexOf('=');
    if (idx > 0) out[part.slice(0, idx).trim()] = part.slice(idx + 1).trim();
  }
  return out;
}

function isAuthenticated(req) {
  const value = parseCookies(req)[COOKIE_NAME];
  return !!value && safeEqual(value, sessionValue()) && !!state.refreshToken;
}

function cookieHeader(req, maxAge) {
  const secure =
    req.headers['x-forwarded-proto'] === 'https' || req.headers['x-forwarded-ssl'] === 'on';
  return `${COOKIE_NAME}=${sessionValue()}; Path=/; HttpOnly; SameSite=Lax; Max-Age=${maxAge}${
    secure ? '; Secure' : ''
  }`;
}

function publicUser() {
  const u = state.user;
  if (!u) return null;
  return {
    id: String(u.id ?? ''),
    name: u.name ?? '',
    account: u.account ?? '',
    mailAddress: u.mail_address ?? '',
    isPremium: !!u.is_premium,
    xRestrict: u.x_restrict ?? 0,
    isMailAuthorized: !!u.is_mail_authorized,
    profileImageUrl:
      u.profile_image_urls?.px_170x170 || u.profile_image_urls?.px_170x170 || '',
  };
}

async function refreshAccessToken() {
  if (!state.refreshToken) throw new Error('no refresh token configured');
  const res = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: {
      'content-type': 'application/x-www-form-urlencoded',
      'user-agent': UA,
    },
    body: new URLSearchParams({
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      grant_type: 'refresh_token',
      refresh_token: state.refreshToken,
      include_policy: 'true',
    }),
  });
  const json = await res.json().catch(() => ({}));
  if (!json.access_token) {
    const message =
      json?.errors?.system?.message || json?.error || `HTTP ${res.status}`;
    throw new Error(message);
  }
  state.accessToken = json.access_token;
  state.refreshToken = json.refresh_token || state.refreshToken;
  state.expiresAt = Date.now() + (json.expires_in || 3600) * 1000;
  if (json.response?.user) state.user = mergeUser(state.user, json.response.user);
  saveState();
  return state.accessToken;
}

function mergeUser(previous, user) {
  return { ...(previous || {}), ...user };
}

async function ensureAccessToken() {
  if (state.accessToken && state.expiresAt && state.expiresAt - 60_000 > Date.now()) {
    return state.accessToken;
  }
  if (!refreshing) {
    refreshing = refreshAccessToken().finally(() => {
      refreshing = null;
    });
  }
  return refreshing;
}

function readBody(req, limit = 64 * 1024) {
  return new Promise((resolve, reject) => {
    let size = 0;
    const chunks = [];
    req.on('data', (chunk) => {
      size += chunk.length;
      if (size > limit) {
        reject(new Error('body too large'));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
    req.on('error', reject);
  });
}

function redirect(res, location) {
  res.writeHead(303, { location });
  res.end();
}

function json(res, status, body) {
  res.writeHead(status, { 'content-type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(body));
}

async function handleLogin(req, res) {
  if (!SETUP_TOKEN) {
    return redirect(res, '/login?error=Server%20is%20missing%20PIXEZ_SETUP_TOKEN');
  }
  const body = new URLSearchParams(await readBody(req));
  const setup = body.get('setup_token') || '';
  const refreshToken = (body.get('refresh_token') || '').trim();

  if (!safeEqual(setup, SETUP_TOKEN)) {
    return redirect(res, '/login?error=Invalid%20setup%20token');
  }
  if (!refreshToken) {
    return redirect(res, '/login?error=Refresh%20token%20is%20required');
  }

  const previous = {
    refreshToken: state.refreshToken,
    accessToken: state.accessToken,
    expiresAt: state.expiresAt,
    user: state.user,
  };
  state.refreshToken = refreshToken;
  state.accessToken = null;
  state.expiresAt = 0;
  try {
    await refreshAccessToken();
  } catch (e) {
    // Keep the previously configured account when a new token is rejected.
    Object.assign(state, previous);
    saveState();
    return redirect(res, `/login?error=${encodeURIComponent(e.message)}`);
  }
  saveState();
  res.setHeader('set-cookie', cookieHeader(req, 30 * 24 * 3600));
  return redirect(res, '/');
}

async function handleApi(req, res, url) {
  if (url.pathname === '/api/session') {
    return json(res, 200, {
      configured: !!state.refreshToken,
      authenticated: isAuthenticated(req),
      user: isAuthenticated(req) ? publicUser() : null,
    });
  }
  if (url.pathname === '/api/logout') {
    res.setHeader('set-cookie', cookieHeader(req, 0));
    return redirect(res, '/login');
  }
  if (url.pathname === '/api/login') {
    return handleLogin(req, res);
  }
  return json(res, 404, { error: 'not found' });
}

function proxyPixiv(req, res, url) {
  const targetPath = url.pathname.replace(/^\/pixiv-api/, '') + url.search;
  const headers = {
    host: API_HOST,
    referer: 'https://www.pixiv.net/',
    'user-agent': UA,
    authorization: `Bearer ${state.accessToken}`,
    'accept-language': req.headers['accept-language'] || 'zh-CN',
    'accept-encoding': req.headers['accept-encoding'] || 'identity',
  };
  if (req.headers['content-type']) headers['content-type'] = req.headers['content-type'];
  if (req.headers['content-length']) headers['content-length'] = req.headers['content-length'];

  const upstream = https.request(
    { host: API_HOST, path: targetPath, method: req.method, headers },
    (up) => {
      const outHeaders = { ...up.headers };
      delete outHeaders['set-cookie'];
      delete outHeaders.connection;
      delete outHeaders['transfer-encoding'];
      res.writeHead(up.statusCode || 502, outHeaders);
      up.pipe(res);
    },
  );
  upstream.on('error', (e) => json(res, 502, { error: e.message }));
  req.pipe(upstream);
}

async function handlePixiv(req, res, url) {
  if (!isAuthenticated(req)) {
    return json(res, 401, { error: 'not_authenticated' });
  }
  try {
    await ensureAccessToken();
  } catch (e) {
    return json(res, 401, { error: 'pixiv_auth_failed', message: e.message });
  }
  return proxyPixiv(req, res, url);
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://localhost');
  try {
    if (url.pathname === '/login' && req.method === 'GET') {
      res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
      return res.end(LOGIN_HTML);
    }
    if (url.pathname.startsWith('/api/')) {
      return await handleApi(req, res, url);
    }
    if (url.pathname.startsWith('/pixiv-api/')) {
      return await handlePixiv(req, res, url);
    }
    if (url.pathname === '/healthz') {
      res.writeHead(200, { 'content-type': 'text/plain' });
      return res.end('ok\n');
    }
    json(res, 404, { error: 'not found' });
  } catch (e) {
    console.error(e);
    if (!res.headersSent) json(res, 500, { error: e.message });
    else res.end();
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`pixez-api listening on ${PORT}, state: ${STATE_FILE}`);
});

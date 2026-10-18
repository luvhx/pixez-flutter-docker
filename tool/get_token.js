#!/usr/bin/env node
/**
 * Pixiv refresh-token helper for PixEz Web.
 *
 * The browser cannot intercept the `pixiv://account/login?code=...` redirect
 * that the native apps rely on, so a refresh token has to be obtained once with
 * a real browser automation context.
 *
 * Usage:
 *   npm --prefix tool install
 *   npx --prefix tool playwright install chromium
 *   node tool/get_token.js
 *
 * A Chromium window opens.  Sign in to Pixiv; the script captures the OAuth
 * code, exchanges it for tokens and prints the refresh token.  Paste that token
 * into the PixEz web login screen.
 *
 * Options:
 *   --headless             run without a window (needs PIXIV_EMAIL/PIXIV_PASSWORD)
 *   --email <mail>         pre-fill the e-mail field
 *   --password <pass>      pre-fill the password field
 *   --timeout <seconds>    how long to wait for the login (default 180)
 *   --json                 print the whole token response as JSON
 */

const crypto = require('crypto');
const path = require('path');

const CLIENT_ID = 'MOBrBDS8blbauoSck0ZfDbtuzpyT';
const CLIENT_SECRET = 'lsACyCD94FhDUtGTXi3QzcFE2uU1hqtDaKeqrdwj';
const TOKEN_URL = 'https://oauth.secure.pixiv.net/auth/token';
const REDIRECT_URI =
  'https://app-api.pixiv.net/web/v1/users/auth/pixiv/callback';
const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36';

function arg(name, fallback) {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx === -1) return fallback;
  const value = process.argv[idx + 1];
  return value && !value.startsWith('--') ? value : true;
}

function base64url(buffer) {
  return buffer.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

async function exchange(code, codeVerifier) {
  const body = new URLSearchParams({
    client_id: CLIENT_ID,
    client_secret: CLIENT_SECRET,
    code,
    code_verifier: codeVerifier,
    grant_type: 'authorization_code',
    redirect_uri: REDIRECT_URI,
    include_policy: 'true',
  });
  const res = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: {
      'content-type': 'application/x-www-form-urlencoded',
      'user-agent': 'PixivAndroidApp/5.0.234 (Android 11; Pixel 5)',
    },
    body,
  });
  const json = await res.json().catch(() => ({}));
  return { status: res.status, json };
}

async function main() {
  const { chromium } = require('playwright');

  const headless = !!arg('headless', false);
  const email = arg('email', process.env.PIXIV_EMAIL || '');
  const password = arg('password', process.env.PIXIV_PASSWORD || '');
  const timeout = Number(arg('timeout', 180)) * 1000;
  const jsonOut = !!arg('json', false);

  const codeVerifier = base64url(crypto.randomBytes(48));
  const codeChallenge = base64url(
    crypto.createHash('sha256').update(codeVerifier).digest()
  );

  const loginUrl =
    'https://app-api.pixiv.net/web/v1/login?' +
    `code_challenge=${codeChallenge}&code_challenge_method=S256&client=pixiv-android`;

  const browser = await chromium.launch({
    headless,
    args: ['--disable-blink-features=AutomationControlled'],
  });
  const context = await browser.newContext({
    userAgent: UA,
    viewport: { width: 1280, height: 800 },
    locale: 'ja-JP',
  });
  const page = await context.newPage();

  // A browser cannot navigate to pixiv://, but CDP still reports the request.
  const cdp = await context.newCDPSession(page);
  await cdp.send('Network.enable');

  let code = null;
  const deadline = Date.now() + timeout;

  const codePromise = new Promise((resolve) => {
    cdp.on('Network.requestWillBeSent', (event) => {
      const url = event?.request?.url || '';
      if (url.startsWith('pixiv://account/login')) {
        const match = /code=([\w-]+)/.exec(url);
        if (match) {
          code = match[1];
          resolve(code);
        }
      }
    });
  });

  console.log('Opening Pixiv login page. Sign in to continue...');
  await page.goto(loginUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });

  const fill = async (selector, text) => {
    try {
      const el = await page.waitForSelector(selector, { timeout: 4000 });
      if (el && (await el.isVisible())) {
        await el.fill(text);
        return true;
      }
    } catch (_) {}
    return false;
  };

  if (email) {
    await fill("input[autocomplete^='username']", email);
    await fill("input[type='email']", email);
  }
  if (password) {
    await fill("input[autocomplete^='current-password']", password);
    await fill("input[type='password']", password);
    if (await page.locator("button:has-text('ログイン')").count()) {
      await page.locator("button:has-text('ログイン')").first().click().catch(() => {});
    }
  }

  const timer = setTimeout(() => {
    if (!code) {
      console.error(
        `\nTimed out after ${timeout / 1000}s waiting for the pixiv:// redirect.`
      );
      console.error('If Pixiv showed a captcha or "unusual traffic" page, complete it');
      console.error('in the browser window, or try again from a residential network.');
      page.close().catch(() => {});
    }
  }, timeout);

  await codePromise;
  clearTimeout(timer);

  console.log('Captured authorization code, exchanging for tokens...');
  const { status, json } = await exchange(code, codeVerifier);
  await browser.close();

  if (!json || !json.refresh_token) {
    console.error(`Token exchange failed (HTTP ${status}):`);
    console.error(JSON.stringify(json, null, 2));
    process.exit(1);
  }

  if (jsonOut) {
    console.log(JSON.stringify(json, null, 2));
    return;
  }

  console.log('\n──────────────────────────────────────────────');
  console.log('Refresh token (paste it into PixEz Web):');
  console.log('\n  ' + json.refresh_token + '\n');
  console.log(`Account: ${json.response?.user?.name || 'unknown'}`);
  console.log('──────────────────────────────────────────────');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

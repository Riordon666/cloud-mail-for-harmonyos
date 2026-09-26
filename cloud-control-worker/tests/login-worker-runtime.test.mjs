import assert from 'node:assert/strict'
import { randomUUID } from 'node:crypto'
import { readFileSync, readdirSync } from 'node:fs'
import test from 'node:test'
import { fileURLToPath } from 'node:url'
import { build } from 'esbuild'
import * as miniflare from 'miniflare'

// These are synthetic credentials and reserved .test hosts, never production data.
const ANCHOR = 'https://anchor.runtime.test/api'
const CONTROL = 'https://control.runtime.test'
const CODE = 'runtime-only-one-use-code'
const SESSION = 'runtime-only-anchor-session'
const EMAIL = 'admin@anchor.runtime.test'
const IDENTITY = {
  huaweiUserId: 'runtime-verified-union-000001',
  unionId: 'runtime-verified-union-000001',
  openId: 'runtime-verified-open-000001',
  nickName: 'Runtime fixture',
  avatarUrl: ''
}
const FLOWS = [
  { path: '/api/platform/auth/huawei-anchor', upstream: '/oauth/huawei/platform-login',
    method: 'POST', body: { authorizationCode: CODE } },
  { path: '/api/platform/auth/anchor', upstream: '/huawei/identity',
    method: 'GET', body: { instanceToken: SESSION } }
]

// The installed Miniflare 5 alpha exposes convertV4MiniflareOptions. Its Node
// getD1Database proxy can hang; execute fixture SQL inside the actual workerd D1
// binding instead. This wrapper exists only in this in-memory test bundle: all
// application paths call the real, unmodified central Worker.
const bundle = await build({
  stdin: {
    contents: `import worker from './src/index.ts';
      export default { async fetch(request, env, ctx) {
        if (new URL(request.url).pathname === '/__runtime_fixture_sql') {
          const body = await request.json();
          if (body.migrations) {
            for (const sql of body.migrations) await env.DB.exec(sql);
            return Response.json({ applied: body.migrations.length });
          }
          return Response.json(await env.DB.prepare(body.query).all());
        }
        return worker.fetch(request, env, ctx);
      }};`,
    sourcefile: 'login-runtime-fixture.mjs',
    resolveDir: fileURLToPath(new URL('..', import.meta.url))
  },
  bundle: true,
  format: 'esm',
  platform: 'browser',
  target: 'es2022',
  write: false
})

const migrationDirectory = new URL('../migrations/', import.meta.url)
const migrations = readdirSync(migrationDirectory).filter(name => name.endsWith('.sql')).sort()
  .map(name => readFileSync(new URL(name, migrationDirectory), 'utf8')
    // D1 exec treats newlines as statement separators; preserve multiline SQL.
    .replace(/^\s*--.*$/gm, '').replace(/\r?\n/g, ' '))

function upstreamJson(data, status = 200) {
  return new miniflare.Response(JSON.stringify(data), {
    status, headers: { 'Content-Type': 'application/json' }
  })
}

async function fixture(t, respond) {
  const calls = []
  const options = {
    name: 'central-login-runtime-test',
    modules: true,
    script: bundle.outputFiles[0].text,
    compatibilityDate: '2026-08-20',
    cf: false,
    unsafeRegisterWorker: false,
    d1Databases: { DB: randomUUID() },
    bindings: {
      PLATFORM_JWT_SECRET: 'runtime-only-platform-jwt-secret-not-a-real-credential',
      ANCHOR_INSTANCE_API_BASE_URL: ANCHOR,
      SUPER_ADMIN_HUAWEI_IDS: `anchor:${EMAIL}`,
      ALLOWED_ORIGINS: ''
    },
    // This intercepts workerd's real outbound transport, not Node global fetch.
    // No request is forwarded to the network, even for an unexpected location.
    outboundService: async request => {
      const call = { url: request.url, method: request.method,
        authorization: request.headers.get('Authorization'), body: await request.text() }
      calls.push(call)
      return respond(call)
    }
  }
  const runtimeOptions = typeof miniflare.convertV4MiniflareOptions === 'function'
    ? { ...miniflare.convertV4MiniflareOptions(options), telemetry: { enabled: false } }
    : options
  const mf = new miniflare.Miniflare(runtimeOptions)
  t.after(() => mf.dispose())
  const query = async query => {
    const response = await mf.dispatchFetch(`${CONTROL}/__runtime_fixture_sql`, {
      method: 'POST', body: JSON.stringify({ query })
    })
    assert.equal(response.status, 200)
    return (await response.json()).results
  }
  const setup = await mf.dispatchFetch(`${CONTROL}/__runtime_fixture_sql`, {
    method: 'POST', body: JSON.stringify({ migrations })
  })
  assert.equal(setup.status, 200)
  assert.equal((await setup.json()).applied, migrations.length)
  const schema = await query("SELECT name FROM sqlite_master WHERE type IN ('table','index')")
  for (const name of ['platform_user', 'mail_instance', 'instance_binding', 'platform_audit_log',
    'legacy_anchor_binding', 'ux_instance_single_active_owner']) {
    assert.ok(schema.some(row => row.name === name), `Migration schema includes ${name}`)
  }
  return {
    calls, query,
    async call(flow, token = '') {
      return mf.dispatchFetch(CONTROL + flow.path, {
        method: flow.body ? 'POST' : 'GET',
        headers: { 'Content-Type': 'application/json', Authorization: token },
        body: flow.body ? JSON.stringify(flow.body) : undefined
      })
    }
  }
}

function assertIdentityCall(call, flow) {
  assert.equal(call.url, ANCHOR + flow.upstream)
  assert.equal(call.method, flow.method)
  if (flow.method === 'POST') {
    assert.deepEqual(JSON.parse(call.body), { authorizationCode: CODE })
    assert.equal(call.authorization, null)
  } else {
    assert.equal(call.authorization, SESSION)
    assert.equal(call.body, '')
  }
}

for (const flow of FLOWS) {
  test(`workerd ${flow.path} reaches upstream and returns business 401, not generic 500`, async t => {
    const f = await fixture(t, () => upstreamJson({ code: 401, message: 'Synthetic expired credential' }, 401))
    const response = await f.call(flow)
    assert.equal(response.status, 401)
    assert.equal(response.headers.get('Cache-Control'), 'no-store')
    assert.equal((await response.json()).code, 401)
    assert.equal(f.calls.length, 1)
    assertIdentityCall(f.calls[0], flow)
    assert.deepEqual(await f.query('SELECT COUNT(*) AS n FROM platform_user'), [{ n: 0 }])
  })

  test(`workerd ${flow.path} rejects redirects without forwarding credentials`, async t => {
    let redirectStatus = 302
    let location = 'https://attacker.runtime.test/credential-sink'
    const f = await fixture(t, () => new miniflare.Response('redirect body must not be trusted', {
      status: redirectStatus, headers: { Location: location }
    }))
    for (const status of [302, 307, 308]) {
      for (const destination of ['https://attacker.runtime.test/credential-sink',
        `${ANCHOR}/same-origin-credential-sink`]) {
        redirectStatus = status
        location = destination
        f.calls.length = 0
        const response = await f.call(flow)
        assert.equal(response.status, 502, `${status} ${destination}`)
        assert.equal(response.headers.get('Location'), null)
        const body = await response.json()
        assert.equal(body.code, 502)
        assert.match(body.message, /重定向/)
        assert.equal(JSON.stringify(body).includes(CODE), false)
        assert.equal(JSON.stringify(body).includes(SESSION), false)
        // The transport reconstructs Request.redirect; asserting request.redirect
        // here would not test the Worker's setting. Exactly one outbound request
        // proves real workerd did not follow either same- or cross-origin Location.
        assert.equal(f.calls.length, 1, `${status} must not follow ${destination}`)
        assertIdentityCall(f.calls[0], flow)
      }
    }
    assert.deepEqual(await f.query('SELECT COUNT(*) AS n FROM platform_user'), [{ n: 0 }])
  })
}

test('workerd UNBOUND Huawei login creates a member and usable platform session in local D1', async t => {
  const f = await fixture(t, call => {
    assert.equal(call.url, ANCHOR + FLOWS[0].upstream)
    return upstreamJson({ code: 200, data: { identity: IDENTITY, status: 'UNBOUND',
      bindToken: 'runtime-only-bind-proof' } })
  })
  const response = await f.call(FLOWS[0])
  assert.equal(response.status, 200)
  const data = (await response.json()).data
  assert.equal(data.user.huaweiUserId, IDENTITY.huaweiUserId)
  assert.equal(data.user.platformRole, 'MEMBER')
  assert.deepEqual(data.anchor, { status: 'UNBOUND', token: '', email: '', bindToken: 'runtime-only-bind-proof' })
  assert.equal(typeof data.token, 'string')
  assert.ok(data.token.length > 20)
  const bindings = await f.call({ path: '/api/platform/me/bindings' }, data.token)
  assert.equal(bindings.status, 200)
  assert.deepEqual((await bindings.json()).data, { bindingCount: 0, bindings: [] })
  assert.equal(f.calls.length, 1)
  assertIdentityCall(f.calls[0], FLOWS[0])
  assert.deepEqual(await f.query('SELECT huawei_user_id, platform_role FROM platform_user'),
    [{ huawei_user_id: IDENTITY.huaweiUserId, platform_role: 'MEMBER' }])
})

test('workerd BOUND and anchor-session logins verify one identity and preserve its D1 binding', async t => {
  const f = await fixture(t, call => {
    if (call.url === ANCHOR + FLOWS[0].upstream) {
      return upstreamJson({ code: 200, data: { identity: IDENTITY, status: 'BOUND', token: SESSION, email: EMAIL } })
    }
    if (call.url === ANCHOR + FLOWS[1].upstream) {
      return upstreamJson({ code: 200, data: { identity: IDENTITY, primaryEmail: EMAIL } })
    }
    assert.equal(call.url, `${ANCHOR}/my/loginUserInfo`)
    assert.equal(call.authorization, SESSION)
    return upstreamJson({ code: 200, data: { userId: 17, email: EMAIL, role: { name: 'admin' }, permKeys: ['*'] } })
  })
  for (const flow of FLOWS) {
    const before = f.calls.length
    const response = await f.call(flow)
    assert.equal(response.status, 200)
    const data = (await response.json()).data
    assert.equal(data.user.huaweiUserId, IDENTITY.huaweiUserId)
    assert.equal(data.user.platformRole, 'SUPER_ADMIN')
    assert.ok(data.token.length > 20)
    assert.equal(f.calls.length - before, 2)
    assertIdentityCall(f.calls[before], flow)
    const bindings = await f.call({ path: '/api/platform/me/bindings' }, data.token)
    assert.equal(bindings.status, 200)
    const own = (await bindings.json()).data
    assert.equal(own.bindingCount, 1)
    assert.equal(own.bindings[0].instanceId, 'riordon-cloud-mail')
    assert.equal(own.bindings[0].localEmail, EMAIL)
  }
  assert.deepEqual(await f.query('SELECT COUNT(*) AS n FROM platform_user'), [{ n: 1 }])
  assert.deepEqual(await f.query('SELECT local_user_key, local_email FROM instance_binding'),
    [{ local_user_key: '17', local_email: EMAIL }])
})

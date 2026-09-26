import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { DatabaseSync } from 'node:sqlite'
import test from 'node:test'
import worker from '../src/index.ts'

const ANCHOR = 'riordon-cloud-mail'
const IDENTITY = {
  huaweiUserId: 'verified-union-identifier-000001',
  unionId: 'verified-union-identifier-000001',
  openId: 'verified-open-identifier-000001',
  nickName: 'Huawei User',
  avatarUrl: 'https://profile.test/avatar.png'
}
const MASKED = IDENTITY.huaweiUserId.slice(0, 6) + '…' + IDENTITY.huaweiUserId.slice(-6)

class Statement {
  constructor(statement) { this.statement = statement; this.values = [] }
  bind(...values) { this.values = values; return this }
  first() { return this.statement.get(...this.values) ?? null }
  all() { return { results: this.statement.all(...this.values) } }
  run() { const result = this.statement.run(...this.values); return { success: true, meta: result } }
}

function fixture() {
  const sql = new DatabaseSync(':memory:')
  sql.exec(readFileSync(new URL('../migrations/0001_platform_identity.sql', import.meta.url), 'utf8'))
  sql.exec(readFileSync(new URL('../migrations/0003_legacy_anchor_import_and_owner_guard.sql', import.meta.url), 'utf8'))
  sql.exec("INSERT INTO platform_user(platform_user_id,huawei_user_id,open_id) VALUES(1,'catalog-owner','owner-open')")
  sql.exec("INSERT INTO mail_instance(instance_id,display_name,api_base_url,origin_host,created_by) VALUES " +
    "('riordon-cloud-mail','Anchor','https://anchor.test/api','anchor.test',1)," +
    "('external','External','https://external.test/api','external.test',1)," +
    "('disabled','Disabled','https://disabled.test/api','disabled.test',1)")
  sql.exec("UPDATE mail_instance SET status='DISABLED' WHERE instance_id='disabled'")
  const env = {
    DB: {
      prepare(query) { return new Statement(sql.prepare(query)) },
      async batch(statements) {
        sql.exec('BEGIN')
        try { const results = statements.map((statement) => statement.run()); sql.exec('COMMIT'); return results }
        catch (error) { sql.exec('ROLLBACK'); throw error }
      }
    },
    PLATFORM_JWT_SECRET: 'test-only-platform-secret-not-a-real-credential',
    ANCHOR_INSTANCE_API_BASE_URL: 'https://anchor.test/api',
    SUPER_ADMIN_HUAWEI_IDS: 'anchor:admin@anchor.test',
    ALLOWED_ORIGINS: ''
  }
  return { sql, env }
}

async function call(f, path, body = undefined, token = '') {
  return worker.fetch(new Request('https://control.test' + path, {
    method: body === undefined ? 'GET' : 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: token },
    body: body === undefined ? undefined : JSON.stringify(body)
  }), f.env)
}

function insertLegacy(f, id = MASKED, status = 'ACTIVE') {
  f.sql.prepare('INSERT INTO platform_user(platform_user_id,huawei_user_id,open_id,status,platform_role) ' +
    "VALUES(2,?,?,?,'SUPER_ADMIN')").run(id, id, status)
  f.sql.prepare('INSERT INTO instance_binding(platform_user_id,instance_id,local_user_key,local_email) ' +
    'VALUES(2,?,?,?)').run(ANCHOR, '17', 'admin@anchor.test')
  f.sql.prepare('INSERT INTO instance_binding(platform_user_id,instance_id,local_user_key,local_email) ' +
    'VALUES(2,?,?,?)').run('external', '22', 'member@external.test')
}

function useAnchor(t, state = 'UNBOUND', options = {}) {
  const calls = []
  t.mock.method(globalThis, 'fetch', async (input, init = {}) => {
    const url = String(input)
    calls.push({ url, init })
    if (url === 'https://anchor.test/api/oauth/huawei/platform-login') {
      assert.equal(init.redirect, 'manual')
      assert.deepEqual(JSON.parse(init.body), { authorizationCode: 'one-use-code' })
      return Response.json({ code: 200, data: {
        identity: options.identity || IDENTITY,
        status: state,
        token: state === 'BOUND' ? 'anchor-session' : undefined,
        email: state === 'BOUND' ? 'admin@anchor.test' : undefined,
        bindToken: state === 'UNBOUND' ? 'short-lived-anchor-bind-proof' : undefined
      } })
    }
    if (url === 'https://anchor.test/api/huawei/identity') {
      assert.equal(init.headers.Authorization, 'anchor-session')
      assert.equal(init.redirect, 'manual')
      return Response.json({ code: 200, data: { identity: options.identity || IDENTITY,
        primaryEmail: 'admin@anchor.test' } })
    }
    if (url === 'https://anchor.test/api/my/loginUserInfo') {
      assert.equal(init.headers.Authorization, 'anchor-session')
      return Response.json({ code: 200, data: { userId: 17,
        email: options.sessionEmail || 'admin@anchor.test', role: { name: 'admin' }, permKeys: ['*'] } })
    }
    if (url === 'https://external.test/api/my/loginUserInfo') {
      assert.equal(init.headers.Authorization, 'external-session')
      return Response.json({ code: 200, data: { userId: 22,
        email: 'member@external.test', role: { name: 'user' }, permKeys: [] } })
    }
    throw new Error('Unexpected request destination: ' + url)
  })
  return calls
}

test('anonymous directory exposes only active instance metadata, never user or binding data', async () => {
  const f = fixture()
  try {
    insertLegacy(f)
    const response = await call(f, '/api/platform/public/instances')
    assert.equal(response.status, 200)
    const rows = (await response.json()).data
    assert.deepEqual(rows.map((row) => row.instance_id).sort(), ['external', ANCHOR].sort())
    for (const row of rows) {
      assert.deepEqual(Object.keys(row).sort(), ['instance_id','display_name','api_base_url','origin_host','status'].sort())
    }
    assert.equal((await call(f, '/api/platform/instances')).status, 401)
    assert.equal((await call(f, '/api/platform/me/bindings')).status, 401)
  } finally { f.sql.close() }
})

test('new Huawei user can bind external instance and log in again without any anchor mailbox', async (t) => {
  const f = fixture()
  const calls = useAnchor(t)
  try {
    const first = await call(f, '/api/platform/auth/huawei-anchor', { authorizationCode: 'one-use-code',
      identity: { huaweiUserId: 'forged-admin' }, apiBaseUrl: 'https://attacker.test' })
    assert.equal(first.status, 200)
    assert.equal(first.headers.get('Cache-Control'), 'no-store')
    const firstData = (await first.json()).data
    assert.equal(firstData.user.huaweiUserId, IDENTITY.huaweiUserId)
    assert.equal(firstData.user.platformRole, 'MEMBER')
    assert.deepEqual(firstData.anchor, { status: 'UNBOUND', token: '', email: '', bindToken: 'short-lived-anchor-bind-proof' })
    assert.equal(f.sql.prepare('SELECT COUNT(*) AS n FROM instance_binding').get().n, 0)
    const binding = await call(f, '/api/platform/instances/external/verify-binding',
      { instanceToken: 'external-session' }, firstData.token)
    assert.equal(binding.status, 200)
    assert.equal((await binding.json()).data.localEmail, 'member@external.test')
    const second = await call(f, '/api/platform/auth/huawei-anchor', { authorizationCode: 'one-use-code' })
    const secondData = (await second.json()).data
    const bindings = (await (await call(f, '/api/platform/me/bindings', undefined, secondData.token)).json()).data
    assert.equal(bindings.bindingCount, 1)
    assert.equal(bindings.bindings[0].instanceId, 'external')
    assert.equal(f.sql.prepare('SELECT COUNT(*) AS n FROM platform_user').get().n, 2)
    assert.equal(calls.some((entry) => entry.url.endsWith('/register')), false)
    assert.equal(calls.some((entry) => entry.url.endsWith('/huawei/me')), false)
  } finally { f.sql.close() }
})

test('legacy anchor user is upgraded in place with all external bindings and configured super-admin role', async (t) => {
  const f = fixture()
  useAnchor(t, 'BOUND')
  try {
    insertLegacy(f)
    const result = await call(f, '/api/platform/auth/huawei-anchor', { authorizationCode: 'one-use-code' })
    assert.equal(result.status, 200)
    const data = (await result.json()).data
    assert.equal(data.user.platformRole, 'SUPER_ADMIN')
    assert.equal(f.sql.prepare('SELECT huawei_user_id FROM platform_user WHERE platform_user_id=2').get().huawei_user_id,
      IDENTITY.huaweiUserId)
    assert.equal(f.sql.prepare('SELECT COUNT(*) AS n FROM instance_binding WHERE platform_user_id=2').get().n, 2)
    const originalEndpoint = await call(f, '/api/platform/auth/huawei', { authorizationCode: 'one-use-code' })
    assert.equal((await originalEndpoint.json()).data.user.platformRole, 'SUPER_ADMIN')
    assert.equal(f.sql.prepare('SELECT COUNT(*) AS n FROM platform_user').get().n, 2)
  } finally { f.sql.close() }
})

test('existing anchor-session login uses full server-verified identity and preserves user id', async (t) => {
  const f = fixture()
  const calls = useAnchor(t, 'BOUND')
  try {
    insertLegacy(f, 'anchor:admin@anchor.test')
    const result = await call(f, '/api/platform/auth/anchor', { instanceToken: 'anchor-session' })
    assert.equal(result.status, 200)
    assert.equal((await result.json()).data.user.huaweiUserId, IDENTITY.huaweiUserId)
    assert.equal(calls[0].url, 'https://anchor.test/api/huawei/identity')
    assert.equal(f.sql.prepare('SELECT COUNT(*) AS n FROM platform_user').get().n, 2)
  } finally { f.sql.close() }
})

test('disabled legacy identity cannot be revived by migration or issued a usable session', async (t) => {
  const f = fixture()
  useAnchor(t, 'BOUND')
  try {
    insertLegacy(f, MASKED, 'DISABLED')
    const result = await call(f, '/api/platform/auth/huawei-anchor', { authorizationCode: 'one-use-code' })
    assert.equal(result.status, 401)
    assert.equal(f.sql.prepare('SELECT huawei_user_id FROM platform_user WHERE platform_user_id=2').get().huawei_user_id, MASKED)
    assert.equal(f.sql.prepare('SELECT COUNT(*) AS n FROM platform_user').get().n, 2)
  } finally { f.sql.close() }
})

test('disabled canonical identity remains disabled even without an anchor mailbox', async (t) => {
  const f = fixture()
  useAnchor(t)
  try {
    f.sql.prepare("INSERT INTO platform_user(huawei_user_id,open_id,status) VALUES(?,?,'DISABLED')")
      .run(IDENTITY.huaweiUserId, IDENTITY.openId)
    assert.equal((await call(f, '/api/platform/auth/huawei-anchor', { authorizationCode: 'one-use-code' })).status, 401)
    assert.equal(f.sql.prepare('SELECT COUNT(*) AS n FROM instance_binding').get().n, 0)
  } finally { f.sql.close() }
})

test('canonical identity collision aborts migration atomically without merging accounts', async (t) => {
  const f = fixture()
  useAnchor(t, 'BOUND')
  try {
    insertLegacy(f)
    f.sql.prepare('INSERT INTO platform_user(huawei_user_id,open_id) VALUES(?,?)').run(IDENTITY.huaweiUserId, IDENTITY.openId)
    assert.equal((await call(f, '/api/platform/auth/huawei-anchor', { authorizationCode: 'one-use-code' })).status, 409)
    assert.equal(f.sql.prepare('SELECT huawei_user_id FROM platform_user WHERE platform_user_id=2').get().huawei_user_id, MASKED)
    assert.equal(f.sql.prepare('SELECT COUNT(*) AS n FROM instance_binding WHERE platform_user_id=2').get().n, 2)
  } finally { f.sql.close() }
})

test('a matching masked id alone cannot adopt someone else legacy bindings', async (t) => {
  const f = fixture()
  useAnchor(t)
  try {
    insertLegacy(f)
    const result = await call(f, '/api/platform/auth/huawei-anchor', { authorizationCode: 'one-use-code' })
    assert.equal(result.status, 200)
    const token = (await result.json()).data.token
    const own = await call(f, '/api/platform/me/bindings', undefined, token)
    assert.equal((await own.json()).data.bindingCount, 0)
    assert.equal(f.sql.prepare('SELECT huawei_user_id FROM platform_user WHERE platform_user_id=2').get().huawei_user_id, MASKED)
    const conflict = await call(f, '/api/platform/instances/external/verify-binding', { instanceToken: 'external-session' }, token)
    assert.equal(conflict.status, 409)
  } finally { f.sql.close() }
})

test('anchor session email mismatch cannot migrate or create platform identities', async (t) => {
  const f = fixture()
  useAnchor(t, 'BOUND', { sessionEmail: 'someone-else@anchor.test' })
  try {
    insertLegacy(f)
    assert.equal((await call(f, '/api/platform/auth/huawei-anchor', { authorizationCode: 'one-use-code' })).status, 401)
    assert.equal(f.sql.prepare('SELECT COUNT(*) AS n FROM platform_user').get().n, 2)
    assert.equal(f.sql.prepare('SELECT huawei_user_id FROM platform_user WHERE platform_user_id=2').get().huawei_user_id, MASKED)
  } finally { f.sql.close() }
})

test('masked or inconsistent upstream identity is rejected before changing data', async (t) => {
  const f = fixture()
  useAnchor(t, 'BOUND', { identity: { ...IDENTITY, huaweiUserId: MASKED } })
  try {
    assert.equal((await call(f, '/api/platform/auth/huawei-anchor', { authorizationCode: 'one-use-code' })).status, 502)
    assert.equal(f.sql.prepare('SELECT COUNT(*) AS n FROM platform_user').get().n, 1)
  } finally { f.sql.close() }
})

test('non-JSON anchor failure returns actionable error without creating platform user', async (t) => {
  const f = fixture()
  t.mock.method(globalThis, 'fetch', async () => new Response('<html>not found</html>', { status: 404 }))
  try {
    const response = await call(f, '/api/platform/auth/huawei-anchor', { authorizationCode: 'one-use-code' })
    assert.equal(response.status, 502)
    assert.match((await response.json()).message, /更新服务/)
    assert.equal(f.sql.prepare('SELECT COUNT(*) AS n FROM platform_user').get().n, 1)
  } finally { f.sql.close() }
})

test('invalid authorization code is refused without contacting anchor', async (t) => {
  const f = fixture()
  t.mock.method(globalThis, 'fetch', async () => { throw new Error('must not be called') })
  try {
    assert.equal((await call(f, '/api/platform/auth/huawei-anchor', { authorizationCode: '' })).status, 400)
    assert.equal((await call(f, '/api/platform/auth/huawei-anchor', { authorizationCode: 'x'.repeat(8193) })).status, 400)
  } finally { f.sql.close() }
})

for (const status of [301, 302, 303, 307, 308]) {
  for (const flow of ['huawei-anchor', 'anchor']) {
    test(`${flow} rejects HTTP ${status} without following redirects or persisting identities`, async (t) => {
      const f = fixture()
      const requests: string[] = []
      t.mock.method(globalThis, 'fetch', async (input, init) => {
        requests.push(String(input))
        assert.equal(init?.redirect, 'manual')
        assert.equal(requests.length, 1, 'credentials must not be forwarded to the redirect destination')
        return Response.json({ code: 200, data: {
          identity: IDENTITY, status: 'UNBOUND', bindToken: 'redirect-body-must-not-be-trusted'
        } }, { status, headers: { Location: 'https://untrusted-redirect.test/collect' } })
      })
      try {
        const body = flow === 'huawei-anchor' ? { authorizationCode: 'one-use-code' } :
          { instanceToken: 'anchor-session' }
        const response = await call(f, '/api/platform/auth/' + flow, body)
        assert.equal(response.status, 502)
        assert.match((await response.json()).message, /重定向/)
        assert.equal(requests.length, 1)
        assert.equal(f.sql.prepare('SELECT COUNT(*) AS n FROM platform_user').get().n, 1)
        assert.equal(f.sql.prepare('SELECT COUNT(*) AS n FROM instance_binding').get().n, 0)
      } finally { f.sql.close() }
    })
  }
}

for (const status of [401, 403, 503]) {
  test('anchor failure ' + status + ' is actionable and does not forward private upstream diagnostics', async (t) => {
    const f = fixture()
    t.mock.method(globalThis, 'fetch', async () => Response.json({ code: status, data: null,
      message: 'private upstream diagnostic that must not be exposed' }))
    try {
      const response = await call(f, '/api/platform/auth/huawei-anchor', { authorizationCode: 'one-use-code' })
      assert.equal(response.status, status)
      assert.doesNotMatch((await response.json()).message, /private upstream/)
      assert.equal(f.sql.prepare('SELECT COUNT(*) AS n FROM platform_user').get().n, 1)
    } finally { f.sql.close() }
  })
}

test('oversized streamed anchor response is bounded before parsing or identity persistence', async (t) => {
  const f = fixture()
  t.mock.method(globalThis, 'fetch', async () => new Response('x'.repeat(65537)))
  try {
    const response = await call(f, '/api/platform/auth/huawei-anchor', { authorizationCode: 'one-use-code' })
    assert.equal(response.status, 502)
    assert.equal(f.sql.prepare('SELECT COUNT(*) AS n FROM platform_user').get().n, 1)
  } finally { f.sql.close() }
})

test('UNBOUND revokes stale anchor authority and link while preserving external bindings', async (t) => {
  const f = fixture()
  useAnchor(t, 'BOUND')
  try {
    insertLegacy(f, IDENTITY.huaweiUserId)
    const bound = await call(f, '/api/platform/auth/huawei-anchor', { authorizationCode: 'one-use-code' })
    const oldToken = (await bound.json()).data.token
    f.sql.prepare('INSERT INTO legacy_anchor_binding(source_instance_id,source_account_id,primary_email,import_marker) ' +
      "VALUES(?,17,'admin@anchor.test','old-import')").run(ANCHOR)
    t.mock.method(globalThis, 'fetch', async () => Response.json({ code: 200, data: {
      identity: IDENTITY, status: 'UNBOUND', bindToken: 'new-bind-proof'
    } }))
    const unbound = await call(f, '/api/platform/auth/huawei-anchor', { authorizationCode: 'new-code' })
    assert.equal(unbound.status, 200)
    const data = (await unbound.json()).data
    assert.equal(data.anchor.status, 'UNBOUND')
    assert.equal(data.user.platformRole, 'MEMBER')
    assert.equal(f.sql.prepare('SELECT COUNT(*) AS n FROM instance_binding WHERE platform_user_id=2 AND instance_id=?')
      .get(ANCHOR).n, 0)
    assert.equal(f.sql.prepare("SELECT COUNT(*) AS n FROM instance_binding WHERE platform_user_id=2 AND instance_id='external'")
      .get().n, 1)
    assert.equal(f.sql.prepare('SELECT COUNT(*) AS n FROM legacy_anchor_binding').get().n, 0)
    for (const token of [oldToken, data.token]) {
      assert.equal((await call(f, '/api/platform/admin/bindings', undefined, token)).status, 403)
    }
  } finally { f.sql.close() }
})

async function deleteOwnBinding(f, instanceId, token = '', email = instanceId === ANCHOR ? 'admin@anchor.test' :
  instanceId === 'disabled' ? 'old@disabled.test' : 'member@external.test', expected = undefined) {
  const snapshot = expected || f.sql.prepare('SELECT binding_id, verified_time FROM instance_binding ' +
    'WHERE platform_user_id=2 AND instance_id=? AND lower(local_email)=?').get(instanceId, email.toLowerCase()) ||
    { binding_id: 9999, verified_time: '2000-01-01T00:00:00.000Z' }
  return worker.fetch(new Request('https://control.test/api/platform/bindings/' + encodeURIComponent(instanceId) +
    '?email=' + encodeURIComponent(email) + '&bindingId=' + snapshot.binding_id +
    '&verifiedTime=' + encodeURIComponent(snapshot.verified_time), {
    method: 'DELETE', headers: { Authorization: token, 'Content-Type': 'application/json' },
    body: JSON.stringify({ platformUserId: 1 })
  }), f.env)
}

test('own binding deletion is authenticated, isolated and idempotent, including disabled instances', async (t) => {
  const f = fixture()
  useAnchor(t, 'BOUND')
  try {
    insertLegacy(f, IDENTITY.huaweiUserId)
    f.sql.prepare('INSERT INTO instance_binding(platform_user_id,instance_id,local_user_key,local_email) ' +
      "VALUES(1,'external','other-user','other@external.test')").run()
    f.sql.prepare('INSERT INTO instance_binding(platform_user_id,instance_id,local_user_key,local_email) ' +
      "VALUES(2,'disabled','old-user','old@disabled.test')").run()
    const token = (await (await call(f, '/api/platform/auth/huawei-anchor', { authorizationCode: 'one-use-code' })).json()).data.token
    assert.equal((await deleteOwnBinding(f, 'external')).status, 401)
    assert.equal((await deleteOwnBinding(f, 'external', token, '')).status, 400)
    assert.equal((await deleteOwnBinding(f, ANCHOR, token, 'old-admin@anchor.test')).status, 200)
    assert.equal((await call(f, '/api/platform/admin/bindings', undefined, token)).status, 200)
    assert.equal(f.sql.prepare('SELECT COUNT(*) AS n FROM instance_binding WHERE platform_user_id=2 AND instance_id=?')
      .get(ANCHOR).n, 1)
    for (const instance of ['external', 'external', 'disabled', 'nonexistent']) {
      const response = await deleteOwnBinding(f, instance, token)
      assert.equal(response.status, 200)
      assert.deepEqual((await response.json()).data, { instanceId: instance, platformRole: 'SUPER_ADMIN' })
    }
    assert.equal(f.sql.prepare("SELECT COUNT(*) AS n FROM instance_binding WHERE platform_user_id=1 AND instance_id='external'")
      .get().n, 1)
    assert.equal(f.sql.prepare('SELECT COUNT(*) AS n FROM instance_binding WHERE platform_user_id=2').get().n, 1)
    assert.equal((await call(f, '/api/platform/admin/bindings', undefined, token)).status, 200)
    const removed = await deleteOwnBinding(f, ANCHOR, token)
    assert.equal(removed.status, 200)
    assert.equal((await removed.json()).data.platformRole, 'MEMBER')
    assert.equal((await (await deleteOwnBinding(f, ANCHOR, token)).json()).data.platformRole, 'MEMBER')
    assert.equal((await call(f, '/api/platform/admin/bindings', undefined, token)).status, 403)
  } finally { f.sql.close() }
})

test('explicit Huawei ID authority survives UNBOUND and removal of the anchor link', async (t) => {
  const f = fixture()
  f.env.SUPER_ADMIN_HUAWEI_IDS = IDENTITY.huaweiUserId
  useAnchor(t)
  try {
    insertLegacy(f, IDENTITY.huaweiUserId)
    const login = await call(f, '/api/platform/auth/huawei-anchor', { authorizationCode: 'one-use-code' })
    const data = (await login.json()).data
    assert.equal(data.user.platformRole, 'SUPER_ADMIN')
    const removed = await deleteOwnBinding(f, ANCHOR, data.token)
    assert.equal(removed.status, 200)
    assert.equal((await removed.json()).data.platformRole, 'SUPER_ADMIN')
    assert.equal((await call(f, '/api/platform/admin/bindings', undefined, data.token)).status, 200)
    assert.equal(f.sql.prepare('SELECT COUNT(*) AS n FROM instance_binding WHERE platform_user_id=2 AND instance_id=?')
      .get(ANCHOR).n, 0)
  } finally { f.sql.close() }
})

test('a queued cleanup cannot remove or downgrade a reverified same-email anchor binding', async (t) => {
  const f = fixture()
  useAnchor(t, 'BOUND')
  try {
    insertLegacy(f, IDENTITY.huaweiUserId)
    const data = (await (await call(f, '/api/platform/auth/huawei-anchor', { authorizationCode: 'one-use-code' })).json()).data
    const before = f.sql.prepare('SELECT binding_id, verified_time FROM instance_binding ' +
      'WHERE platform_user_id=2 AND instance_id=?').get(ANCHOR)
    // Set a future timestamp to force the monotonic fallback, including multiple
    // re-verifications in the same wall-clock millisecond.
    f.sql.prepare('UPDATE instance_binding SET verified_time=? WHERE binding_id=?')
      .run('2099-01-01T00:00:00.000Z', before.binding_id)
    const stale = { binding_id: before.binding_id, verified_time: '2099-01-01T00:00:00.000Z' }
    assert.equal((await call(f, '/api/platform/instances/' + ANCHOR + '/verify-binding',
      { instanceToken: 'anchor-session' }, data.token)).status, 200)
    const fresh = f.sql.prepare('SELECT binding_id, verified_time FROM instance_binding WHERE binding_id=?').get(before.binding_id)
    assert.equal(fresh.binding_id, stale.binding_id)
    assert.equal(fresh.verified_time, '2099-01-01T00:00:00.001Z')
    const staleRemoval = await deleteOwnBinding(f, ANCHOR, data.token, 'admin@anchor.test', stale)
    assert.equal(staleRemoval.status, 200)
    assert.equal((await staleRemoval.json()).data.platformRole, 'SUPER_ADMIN')
    assert.equal(f.sql.prepare('SELECT COUNT(*) AS n FROM instance_binding WHERE binding_id=?').get(before.binding_id).n, 1)
    assert.equal((await call(f, '/api/platform/admin/bindings', undefined, data.token)).status, 200)
    const freshRemoval = await deleteOwnBinding(f, ANCHOR, data.token, 'admin@anchor.test', fresh)
    assert.equal(freshRemoval.status, 200)
    assert.equal((await freshRemoval.json()).data.platformRole, 'MEMBER')
    assert.equal((await call(f, '/api/platform/admin/bindings', undefined, data.token)).status, 403)
  } finally { f.sql.close() }
})

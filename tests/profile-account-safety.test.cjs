const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const test = require('node:test')
const ts = require(process.env.TYPESCRIPT_PATH || 'D:/DevEco Studio/tools/hvigor/hvigor/node_modules/typescript')

const root = path.resolve(__dirname, '../mail/src/main/ets')
class ApiException extends Error { constructor(code, message) { super(message); this.code = code } }
function load(relative, mocks) {
  const code = ts.transpileModule(fs.readFileSync(path.join(root, relative), 'utf8'), {
    compilerOptions: { target: ts.ScriptTarget.ES2021, module: ts.ModuleKind.CommonJS }
  }).outputText
  const module = { exports: {} }
  new Function('module', 'exports', 'require', code)(module, module.exports, name => {
    assert.ok(name in mocks, 'Missing mock ' + name)
    return mocks[name]
  })
  return module.exports
}
function deferred() {
  let resolve
  const promise = new Promise(value => { resolve = value })
  return { promise, resolve }
}
function harness(options = {}) {
  const state = { identity: 'huawei-one', activeId: 'external', cleanupFails: false,
    persistenceFails: false, bindings: [{ instanceId: 'external', localEmail: 'owner@external.example',
      bindingId: 11, verifiedTime: '2026-09-26T01:02:03.004Z' }], ...options.state }
  const instances = new Map(['external', 'anchor'].map(id => [id, { instanceId: id,
    displayName: id + ' service', apiBaseUrl: 'https://' + id + '.example/api', localEmail: 'owner@' + id + '.example' }]))
  const tokens = new Map([['external', 'synthetic-external-token'], ['anchor', 'synthetic-anchor-token']])
  const persisted = options.persisted || new Map()
  const calls = [], unlinks = [], cleared = []
  const store = {
    getSync: (key, fallback) => persisted.get(key) || fallback,
    putSync: (key, value) => { if (state.persistenceFails) throw new Error('synthetic disk error'); persisted.set(key, value) },
    flushSync: () => { if (state.persistenceFails) throw new Error('synthetic disk error') }
  }
  const platform = { getHuaweiUserId: () => state.identity }
  const service = {
    loadMyBindings: async () => options.listBindings ? options.listBindings() : state.bindings,
    unlinkMyBinding: async (...args) => {
      unlinks.push(args)
      if (state.cleanupFails) throw new ApiException(401, 'synthetic platform authorization error')
      if (options.unlink) await options.unlink(...args)
    }
  }
  const { AccountBindingCleanup } = load('common/AccountBindingCleanup.ets', {
    '@kit.ArkData': { preferences: { getPreferencesSync: () => store } },
    './HttpClient': { ApiException }, './InstanceService': { InstanceService: service },
    './PlatformSessionService': { PlatformSessionService: platform }
  })
  if (!options.skipInitialize) AccountBindingCleanup.initialize({})
  const { ProfileApi } = load('api/ProfileApi.ets', {
    '../common/ExternalHttpClient': { ExternalHttpClient: {
      put: async (...args) => { calls.push(['PUT', ...args]); if (options.put) return options.put(...args) },
      delete: async (...args) => { calls.push(['DELETE', ...args]); if (options.delete) return options.delete(...args) }
    } },
    '../common/HttpClient': { ApiException }, '../common/InstanceService': { InstanceService: service },
    '../common/InstanceRegistry': { InstanceRegistry: {
      getActiveInstance: () => instances.get(state.activeId), getDefaultInstanceId: () => 'anchor'
    } },
    '../common/SessionService': { SessionService: {
      getInstanceToken: id => tokens.get(id) || '',
      clearMailboxSession: id => { cleared.push(id); tokens.delete(id); if (state.activeId === id) {
        state.activeId = [...tokens.keys()][0] || 'anchor'
      } }
    } },
    '../common/PlatformSessionService': { PlatformSessionService: platform },
    '../common/AccountBindingCleanup': { AccountBindingCleanup }, '../common/InstanceModels': {}
  })
  return { state, instances, tokens, calls, unlinks, cleared, persisted, ProfileApi, AccountBindingCleanup }
}

test('password change uses the captured current external service and its token, never the anchor', async () => {
  const h = harness()
  const target = h.ProfileApi.captureTarget()
  await h.ProfileApi.resetPassword('new-test-password', target)
  assert.deepEqual(h.calls, [['PUT', 'https://external.example/api', '/my/resetPassword',
    JSON.stringify({ password: 'new-test-password' }), 'synthetic-external-token']])
  assert.equal(target.email, 'owner@external.example')
  assert.deepEqual(h.cleared, [])
})

for (const change of ['activeId', 'token', 'identity', 'apiBaseUrl', 'email']) {
  test('stale confirmation is rejected before any remote mutation after ' + change, async () => {
    const h = harness(), target = h.ProfileApi.captureTarget()
    if (change === 'activeId') h.state.activeId = 'anchor'
    if (change === 'token') h.tokens.set('external', 'renewed-token')
    if (change === 'identity') h.state.identity = 'huawei-two'
    if (change === 'apiBaseUrl') h.instances.get('external').apiBaseUrl = 'https://changed.example/api'
    if (change === 'email') h.instances.get('external').localEmail = 'new@external.example'
    await assert.rejects(h.ProfileApi.resetPassword('new-test-password', target), error => error.code === 409)
    await assert.rejects(h.ProfileApi.deleteAccount(target), error => error.code === 409)
    assert.deepEqual(h.calls, [])
  })
}

test('external delete captures binding version, deletes only current mailbox and preserves other sessions', async () => {
  const h = harness()
  const result = await h.ProfileApi.deleteAccount(h.ProfileApi.captureTarget())
  assert.equal(result, true)
  assert.deepEqual(h.calls, [['DELETE', 'https://external.example/api', '/my/delete', 'synthetic-external-token']])
  assert.deepEqual(h.cleared, ['external'])
  assert.equal(h.tokens.get('anchor'), 'synthetic-anchor-token')
  assert.equal(h.state.activeId, 'anchor')
  assert.equal(h.state.identity, 'huawei-one')
  assert.deepEqual(h.unlinks, [['external', 'huawei-one', 'owner@external.example', 11, '2026-09-26T01:02:03.004Z']])
})

test('primary-service deletion retains /huawei/me semantics without removing an external session', async () => {
  const h = harness({ state: { activeId: 'anchor', bindings: [{ instanceId: 'anchor', localEmail: 'owner@anchor.example',
    bindingId: 12, verifiedTime: 'anchor-version' }] } })
  await h.ProfileApi.deleteAccount(h.ProfileApi.captureTarget())
  assert.equal(h.calls[0][2], '/huawei/me')
  assert.deepEqual(h.cleared, ['anchor'])
  assert.equal(h.tokens.get('external'), 'synthetic-external-token')
})

test('last mailbox deletion keeps platform identity for onboarding another mailbox', async () => {
  const h = harness()
  h.tokens.delete('anchor')
  await h.ProfileApi.deleteAccount(h.ProfileApi.captureTarget())
  assert.equal(h.tokens.size, 0)
  assert.equal(h.state.identity, 'huawei-one')
})

test('missing binding snapshot blocks destructive deletion', async () => {
  const h = harness({ state: { bindings: [] } })
  await assert.rejects(h.ProfileApi.deleteAccount(h.ProfileApi.captureTarget()), error => error.code === 409)
  assert.deepEqual(h.calls, [])
  assert.deepEqual(h.cleared, [])
})

test('platform preflight failure blocks destructive deletion', async () => {
  const h = harness({ listBindings: async () => { throw new ApiException(401, 'reauthorization required') } })
  await assert.rejects(h.ProfileApi.deleteAccount(h.ProfileApi.captureTarget()), error => error.code === 401)
  assert.deepEqual(h.calls, [])
})

test('switching identity during binding preflight cancels destructive deletion', async () => {
  const gate = deferred(), h = harness({ listBindings: () => gate.promise })
  const pending = h.ProfileApi.deleteAccount(h.ProfileApi.captureTarget())
  h.state.identity = 'huawei-two'
  gate.resolve(h.state.bindings)
  await assert.rejects(pending, error => error.code === 409)
  assert.deepEqual(h.calls, [])
})

test('mailbox deletion failure neither clears local sessions nor queues link removal', async () => {
  const h = harness({ delete: async () => { throw new ApiException(403, 'not permitted') } })
  await assert.rejects(h.ProfileApi.deleteAccount(h.ProfileApi.captureTarget()), error => error.code === 403)
  assert.deepEqual(h.cleared, [])
  assert.deepEqual(h.unlinks, [])
  assert.equal(h.AccountBindingCleanup.pendingCount(), 0)
})

test('cleanup failure persists exact match snapshot, retries after restart without repeating mailbox delete', async () => {
  const h = harness({ state: { cleanupFails: true } })
  assert.equal(await h.ProfileApi.deleteAccount(h.ProfileApi.captureTarget()), false)
  assert.deepEqual(h.cleared, ['external'])
  const entries = JSON.parse(h.persisted.get('pending'))
  assert.deepEqual(entries, [{ huaweiUserId: 'huawei-one', instanceId: 'external', email: 'owner@external.example',
    bindingId: 11, verifiedTime: '2026-09-26T01:02:03.004Z' }])
  assert.equal(h.persisted.get('pending').includes('token'), false)
  const restarted = harness({ persisted: h.persisted })
  assert.equal(await restarted.AccountBindingCleanup.retry(), true)
  assert.deepEqual(restarted.calls, [])
  assert.deepEqual(restarted.unlinks, h.unlinks)
  assert.equal(restarted.AccountBindingCleanup.pendingCount(), 0)
})

test('disk failure after successful delete keeps in-memory cleanup and still removes only the deleted session', async () => {
  const h = harness({ state: { cleanupFails: true }, delete: async () => { h.state.persistenceFails = true } })
  assert.equal(await h.ProfileApi.deleteAccount(h.ProfileApi.captureTarget()), false)
  assert.deepEqual(h.cleared, ['external'])
  assert.equal(h.AccountBindingCleanup.pendingCount(), 1)
  assert.equal(h.tokens.get('anchor'), 'synthetic-anchor-token')
})

test('known disk failure blocks irreversible deletion before remote mutation', async () => {
  const h = harness({ state: { persistenceFails: true } })
  await assert.rejects(h.ProfileApi.deleteAccount(h.ProfileApi.captureTarget()))
  assert.deepEqual(h.calls, [])
  assert.deepEqual(h.cleared, [])
})

test('uninitialized durable queue blocks deletion before any remote request', async () => {
  const h = harness({ skipInitialize: true })
  await assert.rejects(h.ProfileApi.deleteAccount(h.ProfileApi.captureTarget()))
  assert.deepEqual(h.calls, [])
})

test('late remote success cannot clear a replacement identity or unlink its bindings', async () => {
  const gate = deferred(), h = harness({ delete: () => gate.promise })
  const pending = h.ProfileApi.deleteAccount(h.ProfileApi.captureTarget())
  await Promise.resolve()
  h.state.identity = 'huawei-two'
  h.tokens.set('external', 'replacement-account-token')
  gate.resolve()
  assert.equal(await pending, false)
  assert.deepEqual(h.cleared, [])
  assert.deepEqual(h.unlinks, [])
  assert.equal(h.tokens.get('external'), 'replacement-account-token')
  assert.equal(h.AccountBindingCleanup.pendingCount(), 0, 'old identity work is hidden from the new identity')
  h.state.identity = 'huawei-one'
  assert.equal(h.AccountBindingCleanup.pendingCount(), 1)
})

test('cleanup only processes its owning identity and leaves other identities pending', async () => {
  const h = harness()
  h.AccountBindingCleanup.enqueue('huawei-one', 'external', 'old@example.com', 1, 'version-one')
  h.AccountBindingCleanup.enqueue('huawei-two', 'external', 'other@example.com', 2, 'version-two')
  await h.AccountBindingCleanup.retry()
  assert.deepEqual(h.unlinks, [['external', 'huawei-one', 'old@example.com', 1, 'version-one']])
  h.state.identity = 'huawei-two'
  assert.equal(h.AccountBindingCleanup.pendingCount(), 1)
})

test('canceling a stale queue item on rebind preserves other pending identities', async () => {
  const h = harness()
  h.AccountBindingCleanup.enqueue('huawei-one', 'external', 'old@example.com', 1, 'version-one')
  h.AccountBindingCleanup.enqueue('huawei-two', 'external', 'other@example.com', 2, 'version-two')
  h.AccountBindingCleanup.cancel('huawei-one', 'external')
  await h.AccountBindingCleanup.retry()
  assert.deepEqual(h.unlinks, [])
  assert.equal(JSON.parse(h.persisted.get('pending')).length, 1)
})

test('UI captures host context before deletion can unmount the last-mailbox component', () => {
  for (const relative of ['components/AccountCenterSheetHost.ets', 'pages/SettingsPage.ets']) {
    const source = fs.readFileSync(path.join(root, relative), 'utf8')
    const method = source.slice(source.indexOf('  private async deleteAccount()'), source.indexOf('  private openProfileDialog('))
    assert.ok(method.indexOf('const context:') < method.indexOf('await ProfileApi.deleteAccount(target)'))
    assert.equal(method.includes('this.onLogout()'), false)
    assert.match(source, /profile_delete_target_confirm', this\.profileTarget\.displayName, this\.profileTarget\.email/)
  }
})

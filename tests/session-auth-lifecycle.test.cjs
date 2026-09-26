const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const test = require('node:test')
const ts = require(process.env.TYPESCRIPT_PATH ||
  'D:/DevEco Studio/tools/hvigor/hvigor/node_modules/typescript')

const anchorBase = 'https://anchor.example/api'
const externalBase = 'https://external.example/api'
const controlBase = 'https://control.example'
const user = { huaweiUserId: 'huawei-owner', nickName: 'Owner', avatarUrl: '', platformRole: 'MEMBER' }
const bootstrap = (overrides = {}) => ({ token: 'platform-current', user,
  anchor: { status: 'UNBOUND', bindToken: 'temporary-proof' }, ...overrides })
const reply = (data = null, status = 200) => ({ responseCode: status,
  header: { 'content-type': 'application/json' }, result: JSON.stringify({ code: status, data, message: '' }) })
const deferred = () => {
  let resolve
  const promise = new Promise(complete => { resolve = complete })
  return { promise, resolve }
}

// Production services, registry, API clients and request scoping; only OS and network are mocked.
function harness(options = {}) {
  const preferencesByName = new Map()
  const tokens = new Map()
  let platformToken = ''
  const calls = []
  const events = []
  let state = new Map()
  const preferences = { getPreferencesSync: (_context, { name }) => {
    if (!preferencesByName.has(name)) preferencesByName.set(name, new Map())
    const content = preferencesByName.get(name)
    return { getSync: (key, fallback) => content.has(key) ? content.get(key) : fallback,
      putSync: (key, value) => content.set(key, value), deleteSync: key => content.delete(key),
      clearSync: () => content.clear(), flushSync: () => {} }
  } }
  const secure = { getInstanceToken: id => tokens.get(id) || '',
    saveInstanceToken: (id, token) => tokens.set(id, token), removeInstanceToken: id => tokens.delete(id),
    getPlatformToken: () => platformToken, savePlatformToken: token => { platformToken = token },
    removePlatformToken: () => { platformToken = '' } }
  const defaultRequest = call => {
    if (call.url === controlBase + '/api/platform/auth/huawei-anchor') return reply(bootstrap())
    if (call.url.endsWith('/my/loginUserInfo')) return reply({
      email: call.url.startsWith(anchorBase) ? 'owner@anchor.example' : 'owner@external.example',
      role: { name: 'user' }, account: { accountId: 7 }, permKeys: [] })
    if (call.url.endsWith('/verify-binding')) return reply({ instanceRole: 'MEMBER' })
    if (call.url.endsWith('/login')) return reply({ token: 'external-mailbox-token' })
    if (call.url === controlBase + '/api/platform/auth/anchor') return reply(bootstrap({ token: 'platform-renewed' }))
    if (call.url.endsWith('/me/bindings')) return reply({ bindings: [] })
    if (call.url.endsWith('/logout')) return reply({})
    if (call.url.includes('/api/platform/bindings/')) return reply({
      instanceId: decodeURIComponent(new URL(call.url).pathname.split('/').pop()), platformRole: 'MEMBER' })
    throw Error('Unexpected request: ' + call.url)
  }
  function boot() {
    state = new Map()
    const app = { get: key => state.get(key), set: (key, value) => state.set(key, value),
      setOrCreate: (key, value) => state.set(key, value) }
    const imports = {
      '@kit.ArkData': { preferences },
      '@kit.NetworkKit': { http: { RequestMethod: { GET: 'GET', POST: 'POST', PUT: 'PUT', DELETE: 'DELETE' },
        HttpDataType: { STRING: 'STRING' }, createHttp: () => ({ request: async (url, request) => {
          const call = { url, method: request.method, token: request.header.Authorization || '',
            body: request.extraData ? JSON.parse(request.extraData) : null }
          calls.push(call)
          return options.request ? options.request(call, defaultRequest) : defaultRequest(call)
        }, destroy: () => {} }) } },
      './Constants': { default: { API_URL: anchorBase, CONTROL_API_URL: controlBase, MAIL_DOMAIN: '@anchor.example' } },
      './SecureTokenStore': { SecureTokenStore: secure },
      './DraftService': { DraftService: { flushActiveEditor: () => events.push('flush-draft') } },
      './MailDetailCache': { MailDetailCache: { clear: () => events.push('clear-cache') } },
      './MailStatsStore': { MailStatsStore: { reset: () => events.push('reset-stats'), setOwner: () => {} } },
      './AccountBindingCleanup': { AccountBindingCleanup: { cancel: () => {} } }
    }
    imports['../common/Constants'] = imports['./Constants']
    function load(area, name) {
      const source = fs.readFileSync(path.resolve(__dirname, '../mail/src/main/ets', area, name + '.ets'), 'utf8')
      const output = ts.transpileModule(source, {
        compilerOptions: { target: ts.ScriptTarget.ES2021, module: ts.ModuleKind.CommonJS }
      }).outputText
      const module = { exports: {} }
      new Function('require', 'module', 'exports', 'AppStorage', output)(specifier => {
        assert.ok(Object.hasOwn(imports, specifier), 'Missing mock: ' + specifier)
        return imports[specifier]
      }, module, module.exports, app)
      imports['./' + name] = module.exports
      imports['../' + area + '/' + name] = module.exports
      return module.exports
    }
    const models = load('common', 'InstanceModels')
    const { InstanceRegistry } = load('common', 'InstanceRegistry')
    const { SessionService } = load('common', 'SessionService')
    const { PlatformSessionService } = load('common', 'PlatformSessionService')
    load('common', 'RequestScope')
    load('common', 'HttpClient')
    load('common', 'ExternalHttpClient')
    const { AuthApi } = load('api', 'AuthApi')
    load('api', 'PlatformApi')
    const { LoginInstanceService } = load('common', 'LoginInstanceService')
    const { InstanceService } = load('common', 'InstanceService')
    const { AuthService } = load('common', 'AuthService')
    AuthService.initialize({})
    return { models, registry: InstanceRegistry, session: SessionService, platform: PlatformSessionService,
      login: LoginInstanceService, instances: InstanceService, auth: AuthService, authApi: AuthApi }
  }
  const h = { ...boot(), calls, events, tokens, preferencesByName, get state() { return state },
    restart: () => Object.assign(h, boot()) }
  h.saveMailbox = (id = 'external', token = 'external-mailbox-token') => {
    const isAnchor = id === h.registry.getDefaultInstanceId()
    h.session.saveInstanceSession(new h.models.MailInstance(id, id, isAnchor ? anchorBase : externalBase,
      isAnchor ? 'anchor.example' : 'external.example',
      isAnchor ? 'owner@anchor.example' : 'owner@external.example', 'user', 'member', 7), token)
  }
  h.signInExternal = () => {
    h.platform.save(bootstrap())
    h.saveMailbox()
    assert.equal(h.session.switchInstance('external'), true)
  }
  return h
}

test('rejecting an empty-token instance switch changes no storage, editor, cache or active mailbox', () => {
  const h = harness(); h.signInExternal()
  const state = [...h.state], registry = JSON.stringify(h.registry.getInstances()), events = [...h.events]
  const preferences = JSON.stringify([...h.preferencesByName].map(([name, values]) => [name, [...values]]))
  assert.equal(h.session.switchInstance(h.registry.getDefaultInstanceId()), false)
  assert.equal(h.session.getActiveInstanceId(), 'external')
  assert.deepEqual([...h.state], state)
  assert.equal(JSON.stringify(h.registry.getInstances()), registry)
  assert.deepEqual(h.events, events)
  assert.equal(JSON.stringify([...h.preferencesByName].map(([name, values]) => [name, [...values]])), preferences)
})

test('logout revokes the original external origin with its token after local state returns to anchor', async () => {
  const h = harness(); h.signInExternal(); h.auth.logout()
  await new Promise(resolve => setImmediate(resolve))
  assert.equal(h.session.getToken(), '')
  assert.equal(h.session.getActiveInstanceId(), h.registry.getDefaultInstanceId())
  assert.deepEqual(h.calls, [{ url: externalBase + '/logout', method: 'DELETE',
    token: 'external-mailbox-token', body: null }])
})

test('a late rejected logout response cannot clear a new mailbox login', async () => {
  const gate = deferred()
  const h = harness({ request: (call, fallback) => call.url.endsWith('/logout') ? gate.promise : fallback(call) })
  h.signInExternal(); h.auth.logout(); h.saveMailbox('new-session', 'new-token'); h.session.switchInstance('new-session')
  gate.resolve(reply(null, 401)); await new Promise(resolve => setImmediate(resolve))
  assert.equal(h.session.getToken(), 'new-token')
  assert.equal(h.session.getActiveInstanceId(), 'new-session')
})

test('cold restart during third-party onboarding never activates the prefetched anchor token', async () => {
  const h = harness({ request: (call, fallback) => call.url.endsWith('/auth/huawei-anchor') ? reply(bootstrap({
    anchor: { status: 'BOUND', token: 'prefetched-anchor', email: 'owner@anchor.example' }
  })) : fallback(call) })
  h.login.rememberInstance('external')
  await h.login.loginHuawei('fixture-code')
  assert.equal(h.session.getToken(), '')
  assert.equal(h.session.getInstanceToken(h.registry.getDefaultInstanceId()), 'prefetched-anchor')
  h.restart()
  assert.equal(h.session.getToken(), '')
  assert.equal(h.login.getPreferredInstanceId(), 'external')
  assert.equal(h.session.getInstanceToken(h.registry.getDefaultInstanceId()), 'prefetched-anchor')
})

test('a completed activation survives restart and marker-free legacy sessions remain compatible', () => {
  const h = harness(); h.signInExternal(); h.restart()
  assert.equal(h.session.getToken(), 'external-mailbox-token')
  h.preferencesByName.get('cloud_mail_auth').delete('activeSessionCommitted')
  h.restart()
  assert.equal(h.session.getToken(), 'external-mailbox-token')
  assert.equal(h.session.getActiveInstanceId(), 'external')
})

test('external-only platform expiry retains identity and mailbox and persists a reauthorization entry', async () => {
  const h = harness({ request: (call, fallback) => call.url.endsWith('/me/bindings') ? reply(null, 401) : fallback(call) })
  h.signInExternal()
  await assert.rejects(h.instances.loadMyBindings(), error => error.code === 401)
  assert.equal(h.platform.getToken(), '')
  assert.equal(h.platform.getHuaweiUserId(), user.huaweiUserId)
  assert.equal(h.state.get('platformReauthRequired'), true)
  assert.equal(h.session.getToken(), 'external-mailbox-token')
  h.restart()
  assert.equal(h.state.get('platformReauthRequired'), true)
  assert.equal(h.platform.getHuaweiUserId(), user.huaweiUserId)
  assert.equal(h.session.getToken(), 'external-mailbox-token')
})

test('same-owner Huawei reauthorization preserves every mailbox and clears expiry status', async () => {
  const h = harness({ request: (call, fallback) => call.url.endsWith('/auth/huawei-anchor') ?
    reply(bootstrap({ token: 'platform-renewed' })) : fallback(call) })
  h.signInExternal(); h.saveMailbox('second', 'second-token'); h.platform.requireReauthorization()
  const registry = JSON.stringify(h.registry.getInstances()), tokens = [...h.tokens]
  await h.login.reauthorizeHuawei('fixture-code')
  assert.equal(h.platform.getToken(), 'platform-renewed')
  assert.equal(h.state.get('platformReauthRequired'), false)
  assert.equal(h.session.getToken(), 'external-mailbox-token')
  assert.equal(h.session.getActiveInstanceId(), 'external')
  assert.deepEqual([...h.tokens], tokens)
  assert.equal(JSON.stringify(h.registry.getInstances()), registry)
})

test('different Huawei identity cannot adopt or replace existing mailbox sessions', async () => {
  const h = harness({ request: (call, fallback) => call.url.endsWith('/auth/huawei-anchor') ?
    reply(bootstrap({ token: 'different-platform', user: { ...user, huaweiUserId: 'another-owner' } })) : fallback(call) })
  h.signInExternal(); h.platform.requireReauthorization()
  await assert.rejects(h.login.reauthorizeHuawei('fixture-code'), error => error.code === 409)
  assert.equal(h.platform.getToken(), '')
  assert.equal(h.platform.getHuaweiUserId(), user.huaweiUserId)
  assert.equal(h.state.get('platformReauthRequired'), true)
  assert.equal(h.session.getToken(), 'external-mailbox-token')
})

test('logout while reauthorization is in flight prevents late platform resurrection', async () => {
  const gate = deferred()
  const h = harness({ request: (call, fallback) => call.url.endsWith('/auth/huawei-anchor') ? gate.promise : fallback(call) })
  h.signInExternal(); h.platform.requireReauthorization()
  const pending = h.login.reauthorizeHuawei('fixture-code')
  h.auth.logout(); gate.resolve(reply(bootstrap({ token: 'late-platform' })))
  await assert.rejects(pending, error => error.code === 409)
  assert.equal(h.platform.getToken(), '')
  assert.equal(h.session.getToken(), '')
})

test('deleting an active external mailbox keeps another signed-in instance and survives restart', () => {
  const h = harness(); h.signInExternal(); h.saveMailbox('second', 'second-token')
  assert.equal(h.session.clearMailboxSession('external'), true)
  assert.equal(h.session.getToken(), 'second-token')
  assert.equal(h.registry.find('external'), null)
  assert.equal(h.platform.getHuaweiUserId(), user.huaweiUserId)
  h.restart()
  assert.equal(h.session.getToken(), 'second-token')
})

test('deleting the final mailbox returns to signed-out state without resurrecting on restart', () => {
  const h = harness(); h.signInExternal()
  assert.equal(h.session.clearMailboxSession('external'), false)
  h.restart()
  assert.equal(h.session.getToken(), '')
})

test('binding cleanup encodes the deleted mailbox and rejects a different owner before sending', async () => {
  const h = harness(); h.signInExternal()
  await h.instances.unlinkMyBinding('external/id', user.huaweiUserId, 'owner+old@external.example', 42, '2026-09-26 12:00:00')
  assert.equal(h.calls[0].url, controlBase + '/api/platform/bindings/external%2Fid?email=owner%2Bold%40external.example' +
    '&bindingId=42&verifiedTime=2026-09-26%2012%3A00%3A00')
  assert.equal(h.calls[0].token, 'platform-current')
  await assert.rejects(h.instances.unlinkMyBinding('external/id', 'another-owner', 'owner@external.example', 42, 'fixture-time'),
    error => error.code === 409)
  assert.equal(h.calls.length, 1)
})

test('UNBOUND reauthorization discards a stale inactive anchor without switching the external mailbox', async () => {
  const h = harness(); h.signInExternal(); h.saveMailbox(h.registry.getDefaultInstanceId(), 'stale-anchor')
  h.platform.requireReauthorization()
  await h.login.reauthorizeHuawei('fixture-code')
  assert.equal(h.session.getInstanceToken(h.registry.getDefaultInstanceId()), '')
  assert.equal(h.registry.find(h.registry.getDefaultInstanceId()).localEmail, '')
  assert.equal(h.session.getActiveInstanceId(), 'external')
  assert.equal(h.session.getToken(), 'external-mailbox-token')
  h.restart()
  assert.equal(h.session.getActiveInstanceId(), 'external')
  assert.equal(h.session.getToken(), 'external-mailbox-token')
})

test('UNBOUND reauthorization of the active anchor retains and chooses another saved mailbox', async () => {
  const h = harness(); h.signInExternal(); h.saveMailbox(h.registry.getDefaultInstanceId(), 'stale-anchor')
  h.session.switchInstance(h.registry.getDefaultInstanceId()); h.platform.requireReauthorization()
  await h.login.reauthorizeHuawei('fixture-code')
  assert.equal(h.session.getInstanceToken(h.registry.getDefaultInstanceId()), '')
  assert.equal(h.session.getActiveInstanceId(), 'external')
  assert.equal(h.session.getToken(), 'external-mailbox-token')
})

test('UNBOUND reauthorization also clears anchor metadata when its secure token is already missing', async () => {
  const h = harness(); h.signInExternal(); h.saveMailbox(h.registry.getDefaultInstanceId(), 'stale-anchor')
  h.tokens.delete(h.registry.getDefaultInstanceId()); h.platform.requireReauthorization()
  await h.login.reauthorizeHuawei('fixture-code')
  assert.equal(h.registry.find(h.registry.getDefaultInstanceId()).localEmail, '')
  assert.equal(h.session.getToken(), 'external-mailbox-token')
})

for (const activeAnchor of [false, true]) {
  test('BOUND reauthorization refreshes the anchor credential without forcing activation: activeAnchor=' + activeAnchor, async () => {
    const h = harness({ request: (call, fallback) => call.url.endsWith('/auth/huawei-anchor') ? reply(bootstrap({
      token: 'renewed-platform', anchor: { status: 'BOUND', token: 'renewed-anchor', email: 'owner@anchor.example' }
    })) : fallback(call) })
    h.signInExternal(); h.saveMailbox(h.registry.getDefaultInstanceId(), 'stale-anchor')
    if (activeAnchor) h.session.switchInstance(h.registry.getDefaultInstanceId())
    h.platform.requireReauthorization()
    await h.login.reauthorizeHuawei('fixture-code')
    assert.equal(h.session.getInstanceToken(h.registry.getDefaultInstanceId()), 'renewed-anchor')
    assert.equal(h.session.getInstanceToken('external'), 'external-mailbox-token')
    assert.equal(h.session.getActiveInstanceId(), activeAnchor ? h.registry.getDefaultInstanceId() : 'external')
    assert.equal(h.session.getToken(), activeAnchor ? 'renewed-anchor' : 'external-mailbox-token')
    h.restart()
    assert.equal(h.session.getToken(), activeAnchor ? 'renewed-anchor' : 'external-mailbox-token')
  })
}

test('a mismatched BOUND anchor profile cannot update the platform or any cached mailbox', async () => {
  const h = harness({ request: (call, fallback) => call.url.endsWith('/auth/huawei-anchor') ? reply(bootstrap({
    token: 'renewed-platform', anchor: { status: 'BOUND', token: 'renewed-anchor', email: 'wrong@anchor.example' }
  })) : fallback(call) })
  h.signInExternal(); h.saveMailbox(h.registry.getDefaultInstanceId(), 'previous-anchor'); h.platform.requireReauthorization()
  const tokens = [...h.tokens]
  await assert.rejects(h.login.reauthorizeHuawei('fixture-code'), error => error.code === -1)
  assert.deepEqual([...h.tokens], tokens)
  assert.equal(h.platform.getToken(), '')
  assert.equal(h.state.get('platformReauthRequired'), true)
})

for (const payload of [null, {}, bootstrap({ token: '' }), bootstrap({ anchor: { status: 'INVALID' } })]) {
  test('malformed reauthorization leaves existing credentials unchanged: ' + JSON.stringify(payload), async () => {
    const h = harness({ request: (call, fallback) => call.url.endsWith('/auth/huawei-anchor') ? reply(payload) : fallback(call) })
    h.signInExternal(); h.platform.requireReauthorization()
    await assert.rejects(h.login.reauthorizeHuawei('fixture-code'), error => error.code === -1)
    assert.equal(h.platform.getToken(), '')
    assert.equal(h.platform.getHuaweiUserId(), user.huaweiUserId)
    assert.equal(h.session.getToken(), 'external-mailbox-token')
  })
}

for (const phase of ['bootstrap', 'anchor-profile']) {
  test('reauthorization rejects switching away and back even with identical final mailbox/token: ' + phase, async () => {
    const gate = deferred(), entered = deferred()
    const h = harness({ request: (call, fallback) => {
      if (call.url.endsWith('/auth/huawei-anchor')) {
        if (phase === 'bootstrap') { entered.resolve(); return gate.promise }
        return reply(bootstrap({ anchor: { status: 'BOUND', token: 'new-anchor', email: 'owner@anchor.example' } }))
      }
      if (call.url === anchorBase + '/my/loginUserInfo') { entered.resolve(); return gate.promise }
      return fallback(call)
    } })
    h.signInExternal(); h.saveMailbox('second', 'second-token'); h.platform.requireReauthorization()
    const pending = h.login.reauthorizeHuawei('fixture-code')
    await entered.promise
    h.session.switchInstance('second'); h.session.switchInstance('external')
    gate.resolve(phase === 'bootstrap' ? reply(bootstrap({ token: 'late-platform' })) : reply({ email: 'owner@anchor.example' }))
    await assert.rejects(pending, error => error.code === 409)
    assert.equal(h.platform.getToken(), '')
    assert.equal(h.session.getToken(), 'external-mailbox-token')
  })
}

test('anchor renewal refuses a different canonical Huawei identity', async () => {
  const h = harness({ request: (call, fallback) => call.url.endsWith('/auth/anchor') ? reply(bootstrap({
    token: 'wrong-owner-token', user: { ...user, huaweiUserId: 'wrong-owner' }
  })) : fallback(call) })
  h.signInExternal(); h.saveMailbox(h.registry.getDefaultInstanceId(), 'anchor-token')
  assert.equal(await h.instances.ensurePlatformSession(true), false)
  assert.equal(h.platform.getToken(), '')
  assert.equal(h.platform.getHuaweiUserId(), user.huaweiUserId)
  assert.equal(h.state.get('platformReauthRequired'), true)
  assert.equal(h.session.getToken(), 'external-mailbox-token')
})

test('anchor renewal cannot save after switching away and back', async () => {
  const gate = deferred(), entered = deferred()
  const h = harness({ request: (call, fallback) => {
    if (call.url.endsWith('/auth/anchor')) { entered.resolve(); return gate.promise }
    return fallback(call)
  } })
  h.signInExternal(); h.saveMailbox('second', 'second-token'); h.saveMailbox(h.registry.getDefaultInstanceId(), 'anchor-token')
  const pending = h.instances.ensurePlatformSession(true)
  await entered.promise
  h.session.switchInstance('second'); h.session.switchInstance('external')
  gate.resolve(reply(bootstrap({ token: 'late-platform' })))
  assert.equal(await pending, false)
  assert.equal(h.platform.getToken(), '')
  assert.equal(h.session.getToken(), 'external-mailbox-token')
})

test('missing legacy Huawei owner requires full login rather than inferring it from a cached anchor', async () => {
  const h = harness(); h.signInExternal(); h.saveMailbox(h.registry.getDefaultInstanceId(), 'unproven-anchor')
  h.platform.clear()
  await assert.rejects(h.instances.loadMyBindings(), error => error.code === 401 && /退出当前邮箱后重新登录/.test(error.message))
  await assert.rejects(h.login.reauthorizeHuawei('fixture-code'),
    error => error.code === 401 && /退出当前邮箱后重新登录/.test(error.message))
  assert.equal(h.state.get('platformReauthRequired'), true)
  assert.equal(h.calls.length, 0)
  assert.equal(h.session.getToken(), 'external-mailbox-token')
})

for (const status of [200, 401]) {
  test('a platform response cannot return data or retry under a different Huawei identity: HTTP ' + status, async () => {
    const gate = deferred(), entered = deferred()
    const h = harness({ request: (call, fallback) => {
      if (call.url.endsWith('/me/bindings')) { entered.resolve(); return gate.promise }
      return fallback(call)
    } })
    h.signInExternal()
    const pending = h.instances.loadMyBindings()
    await entered.promise
    h.platform.save(bootstrap({ token: 'other-owner-token', user: { ...user, huaweiUserId: 'other-owner' } }))
    gate.resolve(reply({ bindings: [] }, status))
    await assert.rejects(pending, error => error.code === 409)
    assert.equal(h.calls.length, 1)
    assert.equal(h.platform.getToken(), 'other-owner-token')
  })
}

test('a platform 401 after switching away and back never clears or refreshes the current platform token', async () => {
  const gate = deferred(), entered = deferred()
  const h = harness({ request: (call, fallback) => {
    if (call.url.endsWith('/me/bindings')) { entered.resolve(); return gate.promise }
    return fallback(call)
  } })
  h.signInExternal(); h.saveMailbox('second', 'second-token')
  const pending = h.instances.loadMyBindings()
  await entered.promise
  h.session.switchInstance('second'); h.session.switchInstance('external')
  gate.resolve(reply(null, 401))
  await assert.rejects(pending, error => error.code === 409)
  assert.equal(h.calls.length, 1)
  assert.equal(h.platform.getToken(), 'platform-current')
})

test('same-owner automatic anchor renewal retries the expired operation successfully', async () => {
  const h = harness({ request: (call, fallback) => call.url.endsWith('/me/bindings') && call.token === 'platform-current' ?
    reply(null, 401) : fallback(call) })
  h.signInExternal(); h.saveMailbox(h.registry.getDefaultInstanceId(), 'anchor-token')
  assert.deepEqual(await h.instances.loadMyBindings(), [])
  assert.equal(h.platform.getToken(), 'platform-renewed')
  assert.equal(h.calls.length, 3)
  assert.equal(h.calls[2].token, 'platform-renewed')
})

test('binding cleanup synchronizes the authoritative role and persists demotion', async () => {
  const h = harness(); h.signInExternal()
  h.platform.save(bootstrap({ user: { ...user, platformRole: 'SUPER_ADMIN' } }))
  await h.instances.unlinkMyBinding('external', user.huaweiUserId, 'owner@external.example', 42, 'fixture-time')
  assert.equal(h.platform.getRole(), 'MEMBER')
  h.restart()
  assert.equal(h.platform.getRole(), 'MEMBER')
})

test('late cleanup response cannot overwrite a newer owner role', async () => {
  const gate = deferred(), entered = deferred()
  const h = harness({ request: (call, fallback) => {
    if (call.url.includes('/api/platform/bindings/')) { entered.resolve(); return gate.promise }
    return fallback(call)
  } })
  h.signInExternal()
  const pending = h.instances.unlinkMyBinding('external', user.huaweiUserId, 'owner@external.example', 42, 'fixture-time')
  await entered.promise
  h.platform.save(bootstrap({ token: 'new-owner-token', user: { ...user, huaweiUserId: 'new-owner', platformRole: 'SUPER_ADMIN' } }))
  gate.resolve(reply({ instanceId: 'external', platformRole: 'MEMBER' }))
  await assert.rejects(pending, error => error.code === 409)
  assert.equal(h.platform.getRole(), 'SUPER_ADMIN')
})

for (const snapshot of [[0, 'time'], [1.5, 'time'], [NaN, 'time'], [42, '']]) {
  test('cleanup rejects an incomplete binding version before any network request: ' + JSON.stringify(snapshot), async () => {
    const h = harness(); h.signInExternal()
    await assert.rejects(h.instances.unlinkMyBinding('external', user.huaweiUserId, 'owner@external.example', ...snapshot),
      error => error.code === 400)
    assert.equal(h.calls.length, 0)
  })
}

test('instance password verification cannot be rebound to a changed Huawei owner', async () => {
  const gate = deferred(), entered = deferred()
  const h = harness({ request: (call, fallback) => {
    if (call.url.endsWith('/login')) { entered.resolve(); return gate.promise }
    return fallback(call)
  } })
  h.signInExternal()
  const target = new h.models.PlatformInstance({ instance_id: 'third', display_name: 'Third',
    api_base_url: externalBase, origin_host: 'external.example', status: 'ACTIVE' })
  const pending = h.instances.bindInstance(target, 'owner@external.example', 'fixture-password')
  await entered.promise
  h.platform.save(bootstrap({ token: 'new-owner-token', user: { ...user, huaweiUserId: 'new-owner' } }))
  gate.resolve(reply({ token: 'new-mailbox-token' }))
  const result = await pending
  assert.equal(result.success, false)
  assert.equal(h.registry.find('third'), null)
  assert.equal(h.calls.length, 1)
})

test('refreshSession guards the final API continuation before writing mailbox credentials', async () => {
  const h = harness(); h.signInExternal(); h.saveMailbox('second', 'second-token')
  const getCurrentUser = h.authApi.getCurrentUser.bind(h.authApi)
  h.authApi.getCurrentUser = async () => {
    const result = await getCurrentUser()
    h.session.switchInstance('second')
    return result
  }
  assert.equal((await h.auth.refreshSession()).success, false)
  assert.equal(h.session.getActiveInstanceId(), 'second')
  assert.equal(h.session.getToken(), 'second-token')
  assert.equal(h.session.getInstanceToken('second'), 'second-token')
})

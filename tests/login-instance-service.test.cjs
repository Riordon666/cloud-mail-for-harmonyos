const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const test = require('node:test')
const ts = require(process.env.TYPESCRIPT_PATH ||
  'D:/DevEco Studio/tools/hvigor/hvigor/node_modules/typescript')
const sourceRoot = path.resolve(__dirname, '../mail/src/main/ets/common')

// Execute production services/models, mocking only the network, OS storage and mailbox session boundary.
function loadSource(name, imports = {}, storage = {}, clock = Date) {
  const source = fs.readFileSync(path.join(sourceRoot, name + '.ets'), 'utf8')
  const compiled = ts.transpileModule(source, {
    compilerOptions: { target: ts.ScriptTarget.ES2021, module: ts.ModuleKind.CommonJS }
  }).outputText
  const module = { exports: {} }
  new Function('require', 'module', 'exports', 'AppStorage', 'Date', compiled)(specifier => {
    assert.ok(Object.hasOwn(imports, specifier), 'Unexpected import: ' + specifier)
    return imports[specifier]
  }, module, module.exports, storage, clock)
  return module.exports
}

const models = loadSource('InstanceModels')
const anchorBase = 'https://anchor.example/api'
const otherBase = 'https://other.example/api'
const controlBase = 'https://control.example'

class ApiException extends Error {
  constructor(code, message, retryable = false) {
    super(message)
    this.code = code
    this.retryable = retryable
  }
}

function instance(overrides = {}) {
  return new models.PlatformInstance({
    instance_id: 'other', display_name: 'Other service', api_base_url: otherBase,
    origin_host: 'other.example', status: 'ACTIVE', ...overrides
  })
}

function bootstrap(overrides = {}) {
  return {
    token: 'platform-token-a',
    user: { huaweiUserId: 'huawei-a', nickName: 'Person A', avatarUrl: '', platformRole: 'MEMBER' },
    anchor: { status: 'UNBOUND', bindToken: 'short-lived-anchor-proof' }, ...overrides
  }
}

function identity(overrides = {}) {
  return {
    anchorStatus: 'UNBOUND', anchorToken: '', anchorEmail: '',
    anchorBindToken: 'short-lived-anchor-proof', ...overrides
  }
}

function deferred() {
  let resolve
  let reject
  const promise = new Promise((ok, fail) => { resolve = ok; reject = fail })
  return { promise, resolve, reject }
}

function apiError(code) {
  return error => {
    assert.equal(error.code, code)
    return true
  }
}

function runtime(options = {}) {
  const calls = []
  const writes = []
  const values = new Map()
  const registry = new Map()
  const tokens = new Map()
  const clock = { now: 1700000000000 }
  values.set('activeInstanceId', 'anchor')
  values.set('authToken', '')
  values.set('sessionRevision', 0)
  const preferencesByName = new Map()
  const storage = {
    get: key => values.get(key),
    set: (key, value) => values.set(key, value),
    setOrCreate: (key, value) => values.set(key, value)
  }
  const preferences = {
    getPreferencesSync: (_context, { name }) => {
      if (!preferencesByName.has(name)) preferencesByName.set(name, new Map())
      const content = preferencesByName.get(name)
      return {
        getSync: (key, fallback) => content.has(key) ? content.get(key) : fallback,
        putSync: (key, value) => { content.set(key, value); writes.push({ name, key, value }) },
        flushSync: () => {},
        clearSync: () => content.clear()
      }
    }
  }
  let securePlatformToken = ''
  const platform = loadSource('PlatformSessionService', {
    '@kit.ArkData': { preferences },
    './InstanceModels': models,
    './SecureTokenStore': { SecureTokenStore: {
      getPlatformToken: () => securePlatformToken,
      savePlatformToken: token => { securePlatformToken = token },
      removePlatformToken: () => { securePlatformToken = '' }
    } }
  }, storage).PlatformSessionService
  platform.initialize({})
  if (options.platform !== false) platform.save(bootstrap())
  writes.length = 0
  const saved = []
  const switched = []
  const verified = []
  const promoted = []
  let clearCount = 0
  const external = {
    get: async (base, route, token = '') => {
      const call = { method: 'GET', base, route, token }
      calls.push(call)
      if (options.request) return options.request(call)
      if (route === '/my/loginUserInfo') return { data: {
        email: 'member@other.example', role: { name: 'member' }, account: { accountId: 42 }, permKeys: []
      } }
      throw new Error('Unexpected GET: ' + route)
    },
    post: async (base, route, body, token = '') => {
      const call = { method: 'POST', base, route, body: JSON.parse(body), token }
      calls.push(call)
      if (options.request) return options.request(call)
      if (route === '/login' || route === '/oauth/huawei/bind-existing' || route === '/oauth/huawei/register') {
        return { data: { token: 'mailbox-token' } }
      }
      if (route === '/api/platform/auth/huawei-anchor') return { data: bootstrap() }
      throw new Error('Unexpected POST: ' + route)
    }
  }
  const service = loadSource('LoginInstanceService', {
    '@kit.ArkData': { preferences },
    './HttpClient': { ApiException },
    './ExternalHttpClient': { ExternalHttpClient: external },
    '../api/PlatformApi': { PlatformApi: {
      verifyBinding: async (token, instanceId, mailboxToken) => {
        verified.push({ token, instanceId, mailboxToken })
        if (options.verify) return options.verify()
        return { instanceRole: 'MEMBER' }
      },
      loginThroughAnchor: async token => {
        promoted.push(token)
        if (options.promote) return options.promote()
        return bootstrap({ token: 'renewed-platform-token' })
      },
      instances: async token => {
        if (options.instances) return options.instances(token)
        return [instance()]
      }
    } },
    './Constants': { default: { API_URL: anchorBase, CONTROL_API_URL: controlBase } },
    './InstanceRegistry': { InstanceRegistry: {
      getDefaultInstanceId: () => 'anchor',
      find: id => registry.get(id) || null
    } },
    './InstanceModels': models,
    './PlatformSessionService': { PlatformSessionService: platform },
    './SessionService': { SessionService: {
      clearAllSessions: () => {
        clearCount++; saved.length = 0; registry.clear(); tokens.clear()
        values.set('activeInstanceId', 'anchor')
        values.set('authToken', '')
        values.set('sessionRevision', values.get('sessionRevision') + 1)
      },
      saveInstanceSession: (local, token) => {
        saved.push({ local, token }); registry.set(local.instanceId, local); tokens.set(local.instanceId, token)
      },
      getActiveInstanceId: () => values.get('activeInstanceId'),
      getApiBaseUrl: () => values.get('activeApiBaseUrl') ||
        registry.get(values.get('activeInstanceId'))?.apiBaseUrl || anchorBase,
      getToken: () => values.get('authToken'),
      getInstanceToken: id => tokens.get(id) || '',
      switchInstance: id => {
        if (options.switchResult === false || !registry.has(id) || !tokens.get(id)) return false
        switched.push(id)
        values.set('activeInstanceId', id)
        values.set('authToken', tokens.get(id))
        values.set('sessionRevision', values.get('sessionRevision') + 1)
        return true
      }
    } }
  }, storage, { now: () => clock.now }).LoginInstanceService
  service.initialize({})
  return { service, platform, calls, saved, switched, verified, promoted, writes, values, registry, tokens, clock,
    get clearCount() { return clearCount }, get securePlatformToken() { return securePlatformToken } }
}

function boundRuntime(options = {}) {
  return runtime({ ...options, request: options.request || (call => {
    if (call.route === '/api/platform/auth/huawei-anchor') return { data: bootstrap({
      anchor: { status: 'BOUND', token: 'existing-anchor-token', email: 'Owner@anchor.example' },
      user: { huaweiUserId: 'huawei-a', nickName: 'Person A', avatarUrl: '', platformRole: 'SUPER_ADMIN' }
    }) }
    if (call.route === '/login') return { data: { token: 'external-mailbox-token' } }
    if (call.route === '/my/loginUserInfo') return { data: {
      email: call.base === anchorBase ? 'owner@anchor.example' : 'member@other.example',
      role: { name: call.base === anchorBase ? 'admin' : 'member' }, account: { accountId: 1 }, permKeys: []
    } }
    throw new Error('Unexpected request: ' + call.route)
  }) })
}

test('fresh BOUND bootstrap activates in two HTTP requests with no duplicate profile, binding or promotion', async () => {
  const h = boundRuntime({ platform: false })
  h.service.rememberInstance('other')
  const result = await h.service.loginHuawei('one-time-huawei-code')
  const writesBeforeActivation = h.writes.length
  await h.service.activateAnchor(result, h.service.defaultInstance())
  assert.deepEqual(h.calls.map(call => [call.method, call.base, call.route]), [
    ['POST', controlBase, '/api/platform/auth/huawei-anchor'],
    ['GET', anchorBase, '/my/loginUserInfo']
  ])
  assert.deepEqual(h.verified, [])
  assert.deepEqual(h.promoted, [])
  assert.equal(h.saved.length, 1, 'activation reuses the already verified mailbox session')
  assert.equal(h.platform.getRole(), 'SUPER_ADMIN', 'keep the authoritative bootstrap platform role')
  assert.equal(h.registry.get('anchor').localRole, 'admin')
  assert.equal(h.registry.get('anchor').instanceRole, 'MEMBER', 'never infer central owner status from local admin')
  assert.deepEqual(h.switched, ['anchor'])
  assert.equal(h.values.get('authToken'), 'existing-anchor-token')
  assert.equal(h.service.getPreferredInstanceId(), 'anchor')
  assert.deepEqual(h.writes.slice(writesBeforeActivation), [
    { name: 'cloud_mail_login', key: 'instanceId', value: 'anchor' }
  ], 'temporary activation proof is never persisted')
})

test('bootstrap activation proof is one-use even if the same result object is submitted twice', async () => {
  const h = boundRuntime()
  const result = await h.service.loginHuawei('one-time-code')
  await h.service.activateAnchor(result, h.service.defaultInstance())
  await assert.rejects(h.service.activateAnchor(result, h.service.defaultInstance()), apiError(409))
  assert.equal(h.calls.length, 2)
  assert.deepEqual(h.switched, ['anchor'])
})

for (const elapsed of [60000, 60001, -1]) {
  test('expired or clock-reversed proof uses full verification only in unchanged scope: ' + elapsed, async () => {
    const h = boundRuntime()
    const result = await h.service.loginHuawei('one-time-code')
    h.clock.now += elapsed
    await h.service.activateAnchor(result, h.service.defaultInstance())
    assert.equal(h.calls.length + h.verified.length + h.promoted.length, 5)
    assert.equal(h.calls.filter(call => call.route === '/my/loginUserInfo').length, 2)
    assert.deepEqual(h.verified, [{ token: 'platform-token-a', instanceId: 'anchor', mailboxToken: 'existing-anchor-token' }])
    assert.deepEqual(h.promoted, ['existing-anchor-token'])
    assert.deepEqual(h.switched, ['anchor'])
  })
}

test('proof remains usable immediately before expiry', async () => {
  const h = boundRuntime()
  const result = await h.service.loginHuawei('one-time-code')
  h.clock.now += 59999
  await h.service.activateAnchor(result, h.service.defaultInstance())
  assert.equal(h.calls.length, 2)
  assert.deepEqual(h.verified, [])
})

for (const [label, mutate] of [
  ['cancel', h => h.service.cancelPending()],
  ['session revision', h => h.values.set('sessionRevision', h.values.get('sessionRevision') + 1)],
  ['Huawei identity', h => h.values.set('platformHuaweiUserId', 'huawei-b')],
  ['platform token', h => h.values.set('platformToken', 'different-platform-token')],
  ['expired platform token', h => h.platform.invalidateToken()],
  ['platform revision', h => h.values.set('platformRevision', h.values.get('platformRevision') + 1)],
  ['active instance', h => h.values.set('activeInstanceId', 'other')],
  ['active base URL', h => h.values.set('activeApiBaseUrl', otherBase)],
  ['active token', h => h.values.set('authToken', 'different-mailbox-token')],
  ['stored anchor token', h => h.tokens.set('anchor', 'replaced-anchor-token')],
  ['removed anchor token', h => h.tokens.delete('anchor')],
  ['removed anchor metadata', h => h.registry.delete('anchor')],
  ['anchor metadata base URL', h => { h.registry.get('anchor').apiBaseUrl = otherBase }],
  ['anchor metadata email', h => { h.registry.get('anchor').localEmail = 'different@anchor.example' }],
  ['anchor metadata role', h => { h.registry.get('anchor').localRole = 'member' }],
  ['anchor metadata account', h => { h.registry.get('anchor').accountId = 99 }],
  ['result token', (_h, result) => { result.anchorToken = 'forged-token' }],
  ['result email', (_h, result) => { result.anchorEmail = 'different@anchor.example' }],
  ['result status', (_h, result) => { result.anchorStatus = 'UNBOUND' }],
  ['result bind proof', (_h, result) => { result.anchorBindToken = 'forged-proof' }]
]) {
  for (const expired of [false, true]) {
    test('changed ' + label + ' rejects ' + (expired ? 'expired' : 'fresh') + ' proof without slow fallback', async () => {
      const h = boundRuntime()
      h.service.rememberInstance('other')
      const result = await h.service.loginHuawei('one-time-code')
      if (expired) h.clock.now += 60000
      mutate(h, result)
      await assert.rejects(h.service.activateAnchor(result, h.service.defaultInstance()), apiError(409))
      assert.equal(h.calls.length, 2)
      assert.deepEqual(h.verified, [])
      assert.deepEqual(h.promoted, [])
      assert.deepEqual(h.switched, [])
      assert.equal(h.service.getPreferredInstanceId(), 'other')
    })
  }
}

test('a cloned bootstrap result cannot acquire its original object activation proof', async () => {
  const h = boundRuntime()
  const result = await h.service.loginHuawei('one-time-code')
  await h.service.activateAnchor({ ...result }, h.service.defaultInstance())
  assert.equal(h.calls.length + h.verified.length + h.promoted.length, 5)
  assert.deepEqual(h.promoted, ['existing-anchor-token'])
  assert.deepEqual(h.switched, ['anchor'])
})

test('cancel then a new bootstrap cannot make the older result eligible for either activation path', async () => {
  const h = boundRuntime()
  const oldResult = await h.service.loginHuawei('first-code')
  h.service.cancelPending()
  const newResult = await h.service.loginHuawei('second-code')
  await assert.rejects(h.service.activateAnchor(oldResult, h.service.defaultInstance()), apiError(409))
  assert.equal(h.calls.length, 4)
  assert.deepEqual(h.switched, [])
  await h.service.activateAnchor(newResult, h.service.defaultInstance())
  assert.equal(h.calls.length, 4)
  assert.deepEqual(h.switched, ['anchor'])
})

test('failed session switch rejects login success and does not overwrite the selection', async () => {
  const h = boundRuntime({ switchResult: false })
  h.service.rememberInstance('other')
  const result = await h.service.loginHuawei('one-time-code')
  await assert.rejects(h.service.activateAnchor(result, h.service.defaultInstance()), apiError(409))
  assert.deepEqual(h.switched, [])
  assert.equal(h.service.getPreferredInstanceId(), 'other')
  assert.equal(h.calls.length, 2)
})

test('BOUND bootstrap does not bypass third-party login or its server binding check', async () => {
  const h = boundRuntime()
  const result = await h.service.loginHuawei('one-time-code')
  await h.service.bind(instance(), result, 'member@other.example', 'private-password')
  assert.deepEqual(h.calls.slice(2).map(call => [call.method, call.base, call.route]), [
    ['POST', otherBase, '/login'], ['GET', otherBase, '/my/loginUserInfo']
  ])
  assert.deepEqual(h.verified, [{ token: 'platform-token-a', instanceId: 'other', mailboxToken: 'external-mailbox-token' }])
  assert.deepEqual(h.promoted, [])
  assert.deepEqual(h.switched, ['other'])
  await assert.rejects(h.service.activateAnchor(result, h.service.defaultInstance()), apiError(409))
  assert.equal(h.calls.length, 4)
  assert.equal(h.values.get('authToken'), 'external-mailbox-token')
})

for (const change of ['cancel', 'identity', 'session']) {
  for (const stage of ['profile', 'verification', 'promotion']) {
    test('expired proof slow path rejects late ' + stage + ' after ' + change, async () => {
      const gate = deferred()
      const entered = deferred()
      let profiles = 0
      const profile = { data: { email: 'owner@anchor.example' } }
      const payload = bootstrap({
        anchor: { status: 'BOUND', token: 'existing-anchor-token', email: 'owner@anchor.example' }
      })
      const h = boundRuntime({
        request: call => {
          if (call.method === 'POST') return { data: payload }
          profiles++
          if (profiles === 2 && stage === 'profile') { entered.resolve(); return gate.promise }
          return profile
        },
        verify: () => {
          if (stage === 'verification') { entered.resolve(); return gate.promise }
          return { instanceRole: 'MEMBER' }
        },
        promote: () => {
          if (stage === 'promotion') { entered.resolve(); return gate.promise }
          return bootstrap()
        }
      })
      const result = await h.service.loginHuawei('one-time-code')
      h.clock.now += 60000
      const pending = h.service.activateAnchor(result, h.service.defaultInstance())
      await entered.promise
      if (change === 'cancel') h.service.cancelPending()
      else if (change === 'identity') h.values.set('platformHuaweiUserId', 'huawei-b')
      else h.values.set('sessionRevision', h.values.get('sessionRevision') + 1)
      gate.resolve(stage === 'profile' ? profile : stage === 'verification' ? { instanceRole: 'MEMBER' } : bootstrap())
      await assert.rejects(pending, apiError(409))
      assert.equal(h.saved.length, 1, 'only the initial bootstrap session was saved')
      assert.deepEqual(h.switched, [])
      assert.equal(h.platform.getToken(), 'platform-token-a')
    })
  }
}

test('failed slow-path session switch also rejects success after an expired proof', async () => {
  const h = boundRuntime({ switchResult: false })
  h.service.rememberInstance('other')
  const result = await h.service.loginHuawei('one-time-code')
  h.clock.now += 60000
  await assert.rejects(h.service.activateAnchor(result, h.service.defaultInstance()), apiError(409))
  assert.deepEqual(h.switched, [])
  assert.equal(h.service.getPreferredInstanceId(), 'other')
})

test('a new unbound Huawei identity establishes platform identity without creating or activating an anchor mailbox', async () => {
  const h = runtime({ platform: false })
  const result = await h.service.loginHuawei('one-time-huawei-code')
  assert.equal(result.anchorStatus, 'UNBOUND')
  assert.equal(result.anchorBindToken, 'short-lived-anchor-proof')
  assert.deepEqual(h.calls, [{ method: 'POST', base: controlBase,
    route: '/api/platform/auth/huawei-anchor', body: { authorizationCode: 'one-time-huawei-code' }, token: '' }])
  assert.equal(h.platform.getToken(), 'platform-token-a')
  assert.equal(h.clearCount, 1)
  assert.deepEqual(h.saved, [])
  assert.deepEqual(h.switched, [])
  assert.deepEqual(h.verified, [])
})

test('bound Huawei login retains a verified anchor token without forcing activation of that service', async () => {
  const h = runtime({ platform: false, request: call => call.method === 'POST' ? { data: bootstrap({
    anchor: { status: 'BOUND', token: 'existing-anchor-token', email: 'Owner@anchor.example' }
  }) } : { data: { email: 'owner@anchor.example', role: { name: 'admin' },
    account: { accountId: 1 }, permKeys: ['*'] } } })
  h.service.rememberInstance('other')
  const result = await h.service.loginHuawei('one-time-huawei-code')
  assert.equal(result.anchorStatus, 'BOUND')
  assert.deepEqual(h.calls[1], { method: 'GET', base: anchorBase, route: '/my/loginUserInfo',
    token: 'existing-anchor-token' })
  assert.equal(h.saved.length, 1)
  assert.equal(h.saved[0].local.instanceId, 'anchor')
  assert.equal(h.saved[0].local.localEmail, 'owner@anchor.example')
  assert.equal(h.saved[0].local.localRole, 'admin')
  assert.equal(h.saved[0].token, 'existing-anchor-token')
  assert.deepEqual(h.switched, [])
  assert.equal(h.service.getPreferredInstanceId(), 'other')
})

test('bound Huawei bootstrap with mismatched anchor email cannot replace any current identity', async () => {
  const h = runtime({ request: call => call.method === 'POST' ? { data: bootstrap({
    token: 'new-platform-token',
    anchor: { status: 'BOUND', token: 'existing-anchor-token', email: 'owner@anchor.example' }
  }) } : { data: { email: 'other@anchor.example' } } })
  await assert.rejects(h.service.loginHuawei('one-time-code'), apiError(-1))
  assert.equal(h.clearCount, 0)
  assert.equal(h.platform.getToken(), 'platform-token-a')
  assert.deepEqual(h.saved, [])
  assert.deepEqual(h.switched, [])
})

test('cancel during bound anchor profile verification leaves the current mailbox and platform session intact', async () => {
  const gate = deferred()
  const entered = deferred()
  const h = runtime({ request: call => {
    if (call.method === 'POST') return { data: bootstrap({
      anchor: { status: 'BOUND', token: 'existing-anchor-token', email: 'owner@anchor.example' }
    }) }
    entered.resolve()
    return gate.promise
  } })
  const pending = h.service.loginHuawei('one-time-code')
  await entered.promise
  h.service.cancelPending()
  gate.resolve({ data: { email: 'owner@anchor.example' } })
  await assert.rejects(pending, apiError(409))
  assert.equal(h.clearCount, 0)
  assert.equal(h.platform.getToken(), 'platform-token-a')
  assert.deepEqual(h.saved, [])
})

test('third-party binding sends the password only to the selected service and activates only after verification', async () => {
  const gate = deferred()
  const h = runtime({ verify: () => gate.promise })
  const pending = h.service.bind(instance(), identity(), '  member@other.example  ', 'private-mailbox-password')
  await new Promise(resolve => setImmediate(resolve))
  assert.deepEqual(h.saved, [])
  assert.deepEqual(h.switched, [])
  assert.deepEqual(h.calls, [
    { method: 'POST', base: otherBase, route: '/login',
      body: { email: 'member@other.example', password: 'private-mailbox-password' }, token: '' },
    { method: 'GET', base: otherBase, route: '/my/loginUserInfo', token: 'mailbox-token' }
  ])
  assert.deepEqual(h.verified, [{ token: 'platform-token-a', instanceId: 'other', mailboxToken: 'mailbox-token' }])
  gate.resolve({ instanceRole: 'MEMBER' })
  await pending
  assert.equal(h.saved[0].local.instanceId, 'other')
  assert.equal(h.saved[0].local.localEmail, 'member@other.example')
  assert.deepEqual(h.switched, ['other'])
  assert.deepEqual(h.promoted, [])
  assert.equal(h.calls.some(call => call.base === anchorBase), false)
})

test('binding rejection leaves the mailbox session and selected-instance preference untouched', async () => {
  const h = runtime({ verify: () => { throw new ApiException(409, 'already bound') } })
  await assert.rejects(h.service.bind(instance(), identity(), 'member@other.example', 'password'), apiError(409))
  assert.deepEqual(h.saved, [])
  assert.deepEqual(h.switched, [])
  assert.deepEqual(h.writes, [])
})

test('wrong selected-instance password is not retried on the anchor service', async () => {
  const h = runtime({ request: () => { throw new ApiException(401, 'wrong password') } })
  await assert.rejects(h.service.bind(instance(), identity(), 'member@other.example', 'wrong-password'), apiError(401))
  assert.equal(h.calls.length, 1)
  assert.equal(h.calls[0].base, otherBase)
  assert.deepEqual(h.verified, [])
  assert.deepEqual(h.saved, [])
  assert.deepEqual(h.switched, [])
})

for (const data of [null, {}, { token: '' }, { token: 123 }]) {
  test('missing mailbox token stops before profile or binding requests: ' + JSON.stringify(data), async () => {
    const h = runtime({ request: () => ({ data }) })
    await assert.rejects(h.service.bind(instance(), identity(), 'member@other.example', 'password'), apiError(-1))
    assert.equal(h.calls.length, 1)
    assert.deepEqual(h.verified, [])
    assert.deepEqual(h.saved, [])
  })
}

for (const change of ['cancel', 'identity']) {
  for (const stage of ['password', 'profile', 'verification']) {
    test('late ' + stage + ' response after ' + change + ' cannot save or activate a mailbox', async () => {
      const gate = deferred()
      const entered = deferred()
      const h = runtime({
        request: async call => {
          if ((stage === 'password' && call.route === '/login') ||
            (stage === 'profile' && call.route === '/my/loginUserInfo')) {
            entered.resolve()
            return gate.promise
          }
          return call.route === '/login' ? { data: { token: 'mailbox-token' } } :
            { data: { email: 'member@other.example' } }
        },
        verify: () => {
          entered.resolve()
          return stage === 'verification' ? gate.promise : { instanceRole: 'MEMBER' }
        }
      })
      const pending = h.service.bind(instance(), identity(), 'member@other.example', 'password')
      await entered.promise
      if (change === 'cancel') h.service.cancelPending()
      else h.platform.save(bootstrap({ token: 'platform-token-b', user: {
        huaweiUserId: 'huawei-b', nickName: 'Person B', avatarUrl: '', platformRole: 'MEMBER'
      } }))
      gate.resolve(stage === 'password' ? { data: { token: 'late-mailbox-token' } } :
        stage === 'profile' ? { data: { email: 'member@other.example' } } : { instanceRole: 'MEMBER' })
      await assert.rejects(pending, apiError(409))
      assert.deepEqual(h.saved, [])
      assert.deepEqual(h.switched, [])
      assert.equal(h.writes.some(write => write.name === 'cloud_mail_login'), false)
      if (stage === 'password') assert.equal(h.calls.length, 1)
      if (stage !== 'verification') assert.equal(h.verified.length, 0)
    })
  }
}

test('cancelled Huawei authorization cannot replace the current platform identity or clear mailbox sessions', async () => {
  const gate = deferred()
  const h = runtime({ request: () => gate.promise })
  const pending = h.service.loginHuawei('one-time-code')
  h.service.cancelPending()
  gate.resolve({ data: bootstrap({ token: 'late-token' }) })
  await assert.rejects(pending, apiError(409))
  assert.equal(h.clearCount, 0)
  assert.equal(h.platform.getToken(), 'platform-token-a')
})

test('a newer Huawei authorization wins when previous authorization arrives last', async () => {
  const first = deferred()
  const second = deferred()
  const h = runtime({ request: call => call.body.authorizationCode === 'first' ? first.promise : second.promise })
  const oldRequest = h.service.loginHuawei('first')
  const newRequest = h.service.loginHuawei('second')
  second.resolve({ data: bootstrap({ token: 'newest-token' }) })
  await newRequest
  first.resolve({ data: bootstrap({ token: 'stale-token' }) })
  await assert.rejects(oldRequest, apiError(409))
  assert.equal(h.platform.getToken(), 'newest-token')
  assert.equal(h.clearCount, 1)
})

for (const email of ['member+purpose@external.example', 'UPPER@different.test']) {
  test('a complete mailbox outside the anchor domain is accepted: ' + email, async () => {
    const h = runtime()
    await h.service.bind(instance(), identity(), email, 'password')
    assert.equal(h.calls[0].body.email, email)
    assert.equal(h.calls[0].base, otherBase)
    assert.equal(h.saved.length, 1)
  })
}

for (const email of ['member', 'member@', '@other.example', 'member @other.example', 'member@other']) {
  test('incomplete mailbox is rejected before requests: ' + email, async () => {
    const h = runtime()
    await assert.rejects(h.service.bind(instance(), identity(), email, 'password'), apiError(400))
    assert.deepEqual(h.calls, [])
    assert.deepEqual(h.saved, [])
  })
}

test('selected service registration configuration uses only that service and has no anchor domain fallback', async () => {
  const h = runtime({ request: () => ({ data: { domainList: ['@other.example', '@other.example', 'invalid'],
    register: 0, regKey: 1, registerVerify: 2, regVerifyOpen: true, minEmailPrefix: 3 } }) })
  const config = await h.service.registrationConfig(instance())
  assert.deepEqual(config.domains, ['@other.example'])
  assert.equal(config.enabled, true)
  assert.equal(config.codeRequired, false)
  assert.equal(config.verificationRequired, true)
  assert.equal(config.minPrefix, 3)
  assert.deepEqual(h.calls, [{ method: 'GET', base: otherBase, route: '/setting/websiteConfig', token: '' }])
  assert.deepEqual(h.saved, [])
})

for (const domainList of [undefined, [], ['not-a-domain', '@', '@bad domain.example']]) {
  test('missing or invalid domains remain empty, never riordon.xyz: ' + JSON.stringify(domainList), async () => {
    const h = runtime({ request: () => ({ data: { domainList, register: 1 } }) })
    const config = await h.service.registrationConfig(instance())
    assert.deepEqual(config.domains, [])
    assert.equal(config.enabled, false)
  })
}

test('anchor existing-account binding retains its Huawei proof route and server-based role promotion', async () => {
  const h = runtime()
  const anchor = h.service.defaultInstance()
  await h.service.bind(anchor, identity(), 'owner@anchor.example', 'private-password')
  assert.equal(h.calls[0].base, anchorBase)
  assert.equal(h.calls[0].route, '/oauth/huawei/bind-existing')
  assert.deepEqual(h.calls[0].body, { email: 'owner@anchor.example', password: 'private-password',
    bindToken: 'short-lived-anchor-proof' })
  assert.deepEqual(h.promoted, ['mailbox-token'])
  assert.equal(h.platform.getToken(), 'renewed-platform-token')
  assert.deepEqual(h.switched, ['anchor'])
})

test('anchor registration retains its route and third-party registration never calls it', async () => {
  const h = runtime()
  await h.service.registerAnchor(h.service.defaultInstance(), identity(), 'new@anchor.example', ' invite-code ')
  assert.equal(h.calls[0].route, '/oauth/huawei/register')
  assert.equal(h.calls[0].body.code, 'invite-code')
  assert.deepEqual(h.switched, ['anchor'])
  const thirdParty = runtime()
  await assert.rejects(thirdParty.service.registerAnchor(instance(), identity(), 'new@other.example', ''), apiError(400))
  assert.deepEqual(thirdParty.calls, [])
})

test('manually constructed bound anchor identity still verifies the token without registration or password binding', async () => {
  const h = runtime()
  await h.service.activateAnchor(identity({ anchorStatus: 'BOUND', anchorToken: 'existing-anchor-token',
    anchorEmail: 'owner@anchor.example', anchorBindToken: '' }), h.service.defaultInstance())
  assert.equal(h.calls[0].method, 'GET')
  assert.equal(h.calls[0].base, anchorBase)
  assert.equal(h.calls[0].token, 'existing-anchor-token')
  assert.deepEqual(h.switched, ['anchor'])
  assert.equal(h.verified.length, 1)
  assert.equal(h.promoted.length, 1)
  assert.equal(h.calls.some(call => call.route.includes('register') || call.route.includes('bind-existing')), false)
})

test('passwords and temporary Huawei proofs never reach preferences or saved mailbox session metadata', async () => {
  const h = runtime({ platform: false })
  const result = await h.service.loginHuawei('secret-authorization-code')
  await h.service.bind(instance(), result, 'member@other.example', 'secret-password')
  const persisted = JSON.stringify({ writes: h.writes, saved: h.saved, state: [...h.values] })
  for (const secret of ['secret-authorization-code', 'secret-password', 'short-lived-anchor-proof']) {
    assert.equal(persisted.includes(secret), false, 'Must not persist ' + secret)
  }
  assert.equal(h.securePlatformToken, 'platform-token-a')
  assert.deepEqual(h.writes.filter(write => write.name === 'cloud_mail_login'), [
    { name: 'cloud_mail_login', key: 'instanceId', value: 'other' }
  ])
})

test('public instance directory requires no login and does not mutate active mailbox sessions', async () => {
  const h = runtime({ platform: false, request: () => ({ data: [{ instance_id: 'other', display_name: 'Other',
    api_base_url: otherBase, origin_host: 'other.example', status: 'ACTIVE' }] }) })
  const instances = await h.service.listInstances()
  assert.equal(instances[0].instanceId, 'other')
  assert.deepEqual(h.calls, [{ method: 'GET', base: controlBase, route: '/api/platform/public/instances', token: '' }])
  assert.deepEqual(h.saved, [])
  assert.deepEqual(h.switched, [])
})

for (const data of [null, {}, 'unrecognized response']) {
  test('malformed public directory does not silently substitute the anchor instance: ' + JSON.stringify(data), async () => {
    const h = runtime({ request: () => ({ data }) })
    await assert.rejects(h.service.listInstances(), apiError(-1))
    assert.deepEqual(h.saved, [])
  })
}

test('public directory network errors propagate instead of hiding other services behind anchor-only fallback', async () => {
  const failure = new ApiException(503, 'unavailable', true)
  const h = runtime({ request: () => { throw failure } })
  await assert.rejects(h.service.listInstances(), error => error === failure)
  assert.deepEqual(h.saved, [])
})

test('a null directory entry returns a controlled API error instead of a constructor TypeError', async () => {
  const h = runtime({ request: () => ({ data: [null] }) })
  await assert.rejects(h.service.listInstances(), error => {
    assert.ok(error instanceof ApiException)
    assert.equal(error.code, -1)
    assert.equal(error.retryable, false)
    return true
  })
  assert.deepEqual(h.saved, [])
  assert.deepEqual(h.switched, [])
})

test('mailbox binding without authenticated Huawei identity sends no password request', async () => {
  const h = runtime({ platform: false })
  await assert.rejects(h.service.bind(instance(), identity(), 'member@other.example', 'password'), apiError(401))
  assert.deepEqual(h.calls, [])
})

for (const overrides of [{ status: 'DISABLED' }, { api_base_url: 'http://other.example/api' }, { instance_id: '' }]) {
  test('unavailable or insecure instance is rejected without sending credentials: ' + JSON.stringify(overrides), async () => {
    const h = runtime()
    await assert.rejects(h.service.bind(instance(overrides), identity(), 'member@other.example', 'password'), apiError(400))
    assert.deepEqual(h.calls, [])
    assert.deepEqual(h.saved, [])
  })
}

for (const payload of [null, {}, bootstrap({ token: '' }), bootstrap({ anchor: { status: 'UNBOUND' } })]) {
  test('invalid Huawei bootstrap cannot clear or replace existing sessions: ' + JSON.stringify(payload), async () => {
    const h = runtime({ request: () => ({ data: payload }) })
    await assert.rejects(h.service.loginHuawei('one-time-code'), apiError(-1))
    assert.equal(h.clearCount, 0)
    assert.equal(h.platform.getToken(), 'platform-token-a')
    assert.deepEqual(h.saved, [])
  })
}

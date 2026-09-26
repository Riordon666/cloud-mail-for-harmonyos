const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const test = require('node:test')
const ts = require(process.env.TYPESCRIPT_PATH ||
  'D:/DevEco Studio/tools/hvigor/hvigor/node_modules/typescript')

function runtime() {
  const values = new Map([['sessionRevision', 1]])
  const state = { identity: 'person-a', requests: [], renewals: [] }
  class ApiException extends Error {
    constructor(code, message) { super(message); this.code = code }
  }
  const imports = {
    '@kit.AccountKit': { authentication: {
      HuaweiIDProvider: class { createAuthorizationWithHuaweiIDRequest() { return {} } },
      AuthenticationController: class {
        executeRequest(request, callback) { state.requests.push({ request, callback }) }
      }
    } },
    '@kit.ArkTS': { util: { generateRandomUUID: () => 'unique-state' } },
    './HttpClient': { ApiException },
    './LoginInstanceService': { LoginInstanceService: {
      reauthorizeHuawei: async code => { state.renewals.push(code) }
    } },
    './PlatformSessionService': { PlatformSessionService: { getHuaweiUserId: () => state.identity } }
  }
  const source = fs.readFileSync(path.join(__dirname,
    '../mail/src/main/ets/common/PlatformReauthorization.ets'), 'utf8')
  const compiled = ts.transpileModule(source, {
    compilerOptions: { target: ts.ScriptTarget.ES2021, module: ts.ModuleKind.CommonJS }
  }).outputText
  const module = { exports: {} }
  new Function('require', 'module', 'exports', 'AppStorage', compiled)(specifier => {
    assert.ok(Object.hasOwn(imports, specifier), specifier)
    return imports[specifier]
  }, module, module.exports, { get: key => values.get(key) })
  return { service: module.exports.default, state, values }
}

test('renewal uses native authorization once and only forwards a validated code', async () => {
  const { service, state } = runtime()
  const first = service.reauthorize({})
  const second = service.reauthorize({})
  assert.equal(state.requests.length, 1)
  const { request, callback } = state.requests[0]
  assert.deepEqual(request.scopes, ['openid', 'profile'])
  assert.deepEqual(request.permissions, ['serviceauthcode'])
  assert.equal(request.forceAuthorization, true)
  callback(null, { state: request.state, data: { authorizationCode: 'native-code' } })
  await Promise.all([first, second])
  assert.deepEqual(state.renewals, ['native-code'])
})

for (const response of [
  { state: 'other-state', data: { authorizationCode: 'never-forward' } },
  { data: { authorizationCode: 'never-forward' } },
  { state: 'unique-state', data: {} },
  null
]) {
  test('malformed native response does not renew: ' + JSON.stringify(response), async () => {
    const { service, state } = runtime()
    const pending = service.reauthorize({})
    state.requests[0].callback(null, response)
    await assert.rejects(pending, { code: 401 })
    assert.deepEqual(state.renewals, [])
  })
}

test('cancellation keeps identity and permits a later retry', async () => {
  const { service, state } = runtime()
  const pending = service.reauthorize({})
  state.requests[0].callback({ code: 1001502012 }, null)
  await assert.rejects(pending, { code: 1001502012 })
  assert.equal(state.identity, 'person-a')
  assert.deepEqual(state.renewals, [])
  const retry = service.reauthorize({})
  state.requests[1].callback(null, { state: 'unique-state', data: { authorizationCode: 'retry-code' } })
  await retry
  assert.deepEqual(state.renewals, ['retry-code'])
})

test('logout or mailbox switch while native authorization is open cannot renew a new session', async () => {
  for (const change of ['identity', 'revision']) {
    const { service, state, values } = runtime()
    const pending = service.reauthorize({})
    if (change === 'identity') state.identity = 'person-b'
    else values.set('sessionRevision', 2)
    state.requests[0].callback(null, { state: 'unique-state', data: { authorizationCode: 'stale-code' } })
    await assert.rejects(pending, { code: 409 })
    assert.deepEqual(state.renewals, [])
  }
})

test('no stored identity means no native request or mutation', async () => {
  const { service, state } = runtime()
  state.identity = ''
  await assert.rejects(service.reauthorize({}), { code: 401 })
  assert.deepEqual(state.requests, [])
  assert.deepEqual(state.renewals, [])
})

const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const test = require('node:test')
const ts = require(process.env.TYPESCRIPT_PATH ||
  'D:/DevEco Studio/tools/hvigor/hvigor/node_modules/typescript')
const day = 24 * 60 * 60 * 1000
const start = 1780000000000

function runtime(content = new Map(), fail = false) {
  const writes = []
  const source = fs.readFileSync(path.join(__dirname,
    '../mail/src/main/ets/common/HuaweiProfileAuthorization.ets'), 'utf8')
  const compiled = ts.transpileModule(source, {
    compilerOptions: { target: ts.ScriptTarget.ES2021, module: ts.ModuleKind.CommonJS }
  }).outputText
  const module = { exports: {} }
  new Function('require', 'module', 'exports', 'console', compiled)(specifier => {
    assert.equal(specifier, '@kit.ArkData')
    return { preferences: { getPreferencesSync: (_context, options) => {
      assert.equal(options.name, 'cloud_mail_profile_authorization')
      if (fail) throw new Error('storage unavailable')
      return {
        getSync: (key, fallback) => content.has(key) ? content.get(key) : fallback,
        putSync: (key, value) => { content.set(key, value); writes.push({ key, value }) },
        flushSync: () => {}
      }
    } } }
  }, module, module.exports, { warn: () => {} })
  const service = module.exports.default
  service.initialize({})
  return { service, content, writes }
}

test('new/changed/missing native identity always requests profile authorization', t => {
  t.mock.method(Date, 'now', () => start)
  const { service } = runtime()
  assert.equal(service.needsAuthorization('person-a'), true)
  service.remember('person-a', 'person-a', 'Name', 'https://avatar.test/a')
  assert.equal(service.needsAuthorization('person-a'), false)
  assert.equal(service.needsAuthorization('person-b'), true)
  assert.equal(service.needsAuthorization(''), true)
})

test('only matching server-verified identity with complete profile can record the hint', t => {
  t.mock.method(Date, 'now', () => start)
  for (const args of [
    ['', 'person-a', 'Name', 'https://avatar.test/a'],
    ['person-b', 'person-a', 'Name', 'https://avatar.test/a'],
    ['person-a', 'person-a', '', 'https://avatar.test/a'],
    ['person-a', 'person-a', 'Name', '']
  ]) {
    const { service, writes } = runtime()
    service.remember(...args)
    assert.equal(service.needsAuthorization('person-a'), true)
    assert.deepEqual(writes, [])
  }
})

test('hint survives restart but contains no authorization code, token or password', t => {
  t.mock.method(Date, 'now', () => start)
  const { service, content, writes } = runtime()
  service.remember('person-a', 'person-a', 'Name', 'https://avatar.test/a')
  assert.deepEqual(writes, [{ key: 'identity', value: 'person-a' }, { key: 'authorizedAt', value: start }])
  assert.equal(runtime(content).service.needsAuthorization('person-a'), false)
})

test('hint expires after 24 hours and checking it does not extend its age', t => {
  let now = start
  t.mock.method(Date, 'now', () => now)
  const { service, content } = runtime()
  service.remember('person-a', 'person-a', 'Name', 'https://avatar.test/a')
  now += day - 1
  assert.equal(service.needsAuthorization('person-a'), false)
  assert.equal(content.get('authorizedAt'), start)
  now++
  assert.equal(service.needsAuthorization('person-a'), true)
})

test('clock rollback and malformed dates fail closed to a fresh profile request', t => {
  t.mock.method(Date, 'now', () => start)
  for (const savedAt of [start + 1, NaN, Infinity, 'invalid', String(start), 0, -1]) {
    const { service } = runtime(new Map([['identity', 'person-a'], ['authorizedAt', savedAt]]))
    assert.equal(service.needsAuthorization('person-a'), true)
  }
})

test('storage failure preserves the normal profile authorization flow', () => {
  const { service } = runtime(new Map(), true)
  assert.equal(service.needsAuthorization('person-a'), true)
})

test('login page only records profile consent after server login and current-operation guard', () => {
  const source = fs.readFileSync(path.join(__dirname, '../mail/src/main/ets/pages/AuthPage.ets'), 'utf8')
  const login = source.slice(source.indexOf('private async loginWithHuawei('),
    source.indexOf('private loginWithHuaweiProfile('))
  assert.match(login, /await LoginInstanceService\.loginHuawei[\s\S]*isAuthenticationCurrent\(operation\)[\s\S]*HuaweiProfileAuthorization\.remember/)
  assert.match(login, /profileIdentity: string = ''/)
  const profile = source.slice(source.indexOf('private loginWithHuaweiProfile('),
    source.indexOf('private showHuaweiAccountSwitchGuide('))
  assert.match(profile, /nativeCredential\.authorizationCode/)
  assert.match(profile, /needsAuthorization\(nativeIdentity\)[\s\S]*loginWithHuawei\(fallbackAuthorizationCode, target, operation\)/)
  assert.match(profile, /profileIdentity === nativeIdentity \? profileIdentity : ''/)
  assert.match(profile, /response\.state !== request\.state/)
})

function pageRuntime(cached = false) {
  const source = fs.readFileSync(path.join(__dirname, '../mail/src/main/ets/pages/AuthPage.ets'), 'utf8')
  const method = source.slice(source.indexOf('private loginWithHuaweiProfile('),
    source.indexOf('private showHuaweiAccountSwitchGuide('))
  const compiled = ts.transpileModule('class Page { ' + method + ' }; return Page;', {
    compilerOptions: { target: ts.ScriptTarget.ES2021, module: ts.ModuleKind.CommonJS }
  }).outputText
  const requests = []
  const calls = []
  const toasts = []
  const Page = new Function('authentication', 'util', 'HuaweiProfileAuthorization', 'hilog', '$r', compiled)({
    HuaweiIDProvider: class { createAuthorizationWithHuaweiIDRequest() { return {} } },
    AuthenticationController: class {
      executeRequest(request, callback) { requests.push({ request, callback }) }
    }
  }, { generateRandomUUID: () => 'state-only-for-test' }, { needsAuthorization: () => !cached },
  { info: () => {}, error: () => {} }, id => id)
  const page = new Page()
  Object.assign(page, {
    pageActive: true, isSubmitting: false, directoryReady: true, directoryLoading: false,
    authenticationSequence: 0, selectedInstance: { instanceId: 'anchor' },
    getUIContext: () => ({ getHostContext: () => ({}) }),
    isAuthenticationCurrent: operation => page.pageActive && operation === page.authenticationSequence,
    loginWithHuawei: (...args) => calls.push(args),
    showToast: text => toasts.push(text), resourceText: text => text
  })
  const credential = { unionID: 'person-a', openID: 'open-a', authorizationCode: 'fresh-button-code' }
  return { page, credential, requests, calls, toasts }
}

test('fresh consent skips the second SDK request but uses the current button code', () => {
  const { page, credential, requests, calls } = pageRuntime(true)
  page.loginWithHuaweiProfile(credential)
  assert.equal(requests.length, 0)
  assert.equal(calls.length, 1)
  assert.equal(calls[0][0], 'fresh-button-code')
  assert.equal(calls[0].length, 3, 'cache hit must not renew the consent hint')
})

test('new profile authorization forwards a matching identity for later server confirmation', () => {
  const { page, credential, requests, calls } = pageRuntime()
  page.loginWithHuaweiProfile(credential)
  assert.equal(requests.length, 1)
  assert.deepEqual(requests[0].request.scopes, ['openid', 'profile'])
  requests[0].callback(null, { state: requests[0].request.state,
    data: { unionID: 'person-a', authorizationCode: 'fresh-profile-code' } })
  assert.equal(calls.length, 1)
  assert.equal(calls[0][0], 'fresh-profile-code')
  assert.equal(calls[0][3], 'person-a')
})

test('account change between button and profile responses cannot sign in a different account', () => {
  const { page, credential, requests, calls, toasts } = pageRuntime()
  page.loginWithHuaweiProfile(credential)
  requests[0].callback(null, { state: requests[0].request.state,
    data: { unionID: 'person-b', authorizationCode: 'other-person-code' } })
  assert.deepEqual(calls, [])
  assert.equal(page.isSubmitting, false)
  assert.deepEqual(toasts, ['app.string.login_huawei_identity_changed'])
})

test('failed profile authorization may use the original button code but cannot record a consent hint', () => {
  for (const failure of ['cancelled', 'wrong-state', 'missing-state', 'missing-code']) {
    const { page, credential, requests, calls } = pageRuntime()
    page.loginWithHuaweiProfile(credential)
    const response = { state: requests[0].request.state, data: {
      unionID: 'person-a', authorizationCode: 'must-not-forward' } }
    if (failure === 'wrong-state') response.state = 'unrelated-state'
    if (failure === 'missing-state') delete response.state
    if (failure === 'missing-code') delete response.data.authorizationCode
    requests[0].callback(failure === 'cancelled' ? { code: 1001502012 } : null, response)
    assert.equal(calls.length, 1)
    assert.equal(calls[0][0], 'fresh-button-code')
    assert.equal(calls[0].length, 3)
  }
})

test('late profile callbacks after leaving or cancelling never start login', () => {
  for (const change of ['left', 'cancelled']) {
    const { page, credential, requests, calls } = pageRuntime()
    page.loginWithHuaweiProfile(credential)
    if (change === 'left') page.pageActive = false
    else page.authenticationSequence++
    requests[0].callback(null, { state: requests[0].request.state,
      data: { unionID: 'person-a', authorizationCode: 'late-code' } })
    assert.deepEqual(calls, [])
  }
})

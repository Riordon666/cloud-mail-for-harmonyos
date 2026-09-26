const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const test = require('node:test')
const ts = require(process.env.TYPESCRIPT_PATH ||
  'D:/DevEco Studio/tools/hvigor/hvigor/node_modules/typescript')

// Extract and execute production non-UI methods; ArkUI builders need the device compiler.
function extractMethod(source, name) {
  const marker = new RegExp('  private (?:async )?' + name + '\\(')
  const match = marker.exec(source)
  assert.ok(match, 'Missing production method: ' + name)
  const start = match.index
  const opening = source.indexOf('{', start)
  let depth = 1
  let index = opening + 1
  while (depth > 0 && index < source.length) {
    if (source[index] === '{') depth++
    if (source[index] === '}') depth--
    index++
  }
  assert.equal(depth, 0)
  return source.slice(start, index)
}

function binding(overrides = {}) {
  return { primaryEmail: 'owner@anchor.example', nickName: 'Person', avatarUrl: 'https://avatar.example/p.jpg',
    huaweiUserId: 'test-user', userCreateTime: '2026-08-01', receiveCount: 40, sentCount: 8, starCount: 3,
    ...overrides }
}

function deferred() {
  let resolve
  const promise = new Promise(value => { resolve = value })
  return { promise, resolve }
}

function harness(relative, cached = null) {
  const source = fs.readFileSync(path.resolve(__dirname, '../mail/src/main/ets', relative), 'utf8')
  const isHost = relative.includes('AccountCenter')
  const methods = ['canUseAnchorAccountData', 'getRegistrationTime', 'getMailCountText',
    'getUnavailableStatText', 'applyHuaweiIdentity', 'loadHuaweiIdentity', 'applyPlatformIdentity']
  if (isHost) methods.push('notifyIdentityChanged')
  const compiled = ts.transpileModule('class TestSubject {\n' + methods.map(name => extractMethod(source, name)).join('\n') +
    '\n}\nmodule.exports = TestSubject;', {
    compilerOptions: { target: ts.ScriptTarget.ES2021, module: ts.ModuleKind.CommonJS }
  }).outputText
  const state = { activeId: 'anchor', authEmail: 'owner@anchor.example',
    anchorEmail: 'owner@anchor.example', anchorToken: 'test-anchor-token',
    platformIdentity: '', platformNickName: '', platformAvatarUrl: '', cachedOwner: 'owner@anchor.example' }
  const writes = []
  const cacheKeys = []
  const cacheSaves = []
  const requests = []
  const globals = {
    SessionService: { getActiveInstanceId: () => state.activeId },
    InstanceRegistry: { getDefaultInstanceId: () => 'anchor' },
    InstanceService: { getAnchorEmail: () => state.anchorEmail, getAnchorToken: () => state.anchorToken },
    AppStorage: { get: key => state[key] },
    DateTimeUtils: { formatUtcDateTime: (value, fallback) => value || fallback },
    MailStatsStore: { sync: (...values) => writes.push(values), syncMissing: (...values) => writes.push(values) },
    PlatformSessionService: { getNickName: () => state.platformNickName,
      getAvatarUrl: () => state.platformAvatarUrl, getHuaweiUserId: () => state.platformIdentity },
    HuaweiAccountCache: {
      load: (context, owner) => { cacheKeys.push(owner); return owner === state.cachedOwner ? cached : null },
      shouldRefresh: () => true,
      save: (context, owner, data) => cacheSaves.push({ owner, data }),
      markRefreshed: () => {}
    },
    HuaweiAccountApi: { current: () => { const result = deferred(); requests.push(result); return result.promise } },
    $r: () => ({ id: 1 })
  }
  const module = { exports: {} }
  new Function('module', ...Object.keys(globals), compiled)(module, ...Object.values(globals))
  const target = new module.exports()
  Object.assign(target, {
    huaweiNickName: '', huaweiAvatarUrl: '', huaweiPrimaryEmail: '', huaweiUserId: '', userCreateTime: '',
    authEmail: state.authEmail, sessionRevision: 1, identityRequestSequence: 0, identityRequestInFlight: false,
    getUIContext: () => ({ getHostContext: () => ({ resourceManager: { getStringSync: () => '未获取' } }) })
  })
  return { state, target, writes, cacheKeys, cacheSaves, requests }
}

for (const relative of ['components/AccountCenterSheetHost.ets', 'pages/SettingsPage.ets']) {
  test(relative + ': matching anchor identity can initialize account stats and registration time', () => {
    const h = harness(relative)
    h.target.applyHuaweiIdentity(binding())
    assert.deepEqual(h.writes, [[40, 8, 3]])
    assert.equal(h.target.getRegistrationTime(), '2026-08-01')
  })

  test(relative + ': identical email on another instance cannot accept anchor stats', () => {
    const h = harness(relative)
    h.state.activeId = 'external'
    h.target.applyHuaweiIdentity(binding())
    assert.equal(h.target.huaweiNickName, 'Person', 'cross-instance profile remains available')
    assert.equal(h.target.huaweiAvatarUrl, 'https://avatar.example/p.jpg')
    assert.equal(h.target.userCreateTime, '')
    assert.equal(h.target.getRegistrationTime(), '未获取')
    assert.deepEqual(h.writes, [])
  })

  test(relative + ': mismatched or empty primary email cannot initialize stats', () => {
    const h = harness(relative)
    h.target.applyHuaweiIdentity(binding({ primaryEmail: 'other@anchor.example' }))
    h.target.applyHuaweiIdentity(binding({ primaryEmail: '' }))
    assert.deepEqual(h.writes, [])
    assert.equal(h.target.getRegistrationTime(), '未获取')
  })

  test(relative + ': unknown count differs from a verified zero', () => {
    const h = harness(relative)
    assert.equal(h.target.getMailCountText(0, false), '未获取')
    assert.equal(h.target.getMailCountText(0, true), '0')
    assert.equal(h.target.getMailCountText(40, true), '40')
    assert.equal(h.target.getMailCountText(NaN, true), '未获取')
  })

  test(relative + ': cached anchor stats do not leak into the external active account', async () => {
    const h = harness(relative, binding())
    h.state.activeId = 'external'
    h.state.authEmail = 'member@external.example'
    h.target.authEmail = h.state.authEmail
    const pending = h.target.loadHuaweiIdentity(true)
    assert.deepEqual(h.cacheKeys, ['owner@anchor.example'])
    assert.deepEqual(h.writes, [])
    assert.equal(h.target.userCreateTime, '')
    h.requests[0].resolve(binding())
    await pending
    assert.deepEqual(h.writes, [])
    assert.equal(h.cacheSaves[0].owner, 'owner@anchor.example')
  })

  for (const changed of ['sessionRevision', 'anchorEmail', 'anchorToken']) {
    test(relative + ': stale identity response cannot write stats or cache after ' + changed, async () => {
      const h = harness(relative)
      const pending = h.target.loadHuaweiIdentity(true)
      if (changed === 'sessionRevision') h.target.sessionRevision++
      else h.state[changed] = 'changed'
      h.requests[0].resolve(binding())
      await pending
      assert.deepEqual(h.writes, [])
      assert.deepEqual(h.cacheSaves, [])
      assert.equal(h.target.huaweiNickName, '')
    })
  }

  test(relative + ': newer identity response wins over an older concurrent request', async () => {
    const h = harness(relative)
    const first = h.target.loadHuaweiIdentity(true)
    const second = h.target.loadHuaweiIdentity(true)
    h.requests[1].resolve(binding({ receiveCount: 41 }))
    await second
    h.requests[0].resolve(binding({ receiveCount: 39 }))
    await first
    assert.deepEqual(h.writes, [[41, 8, 3]])
    assert.equal(h.cacheSaves.length, 1)
  })

  test(relative + ': external-only first login shows platform identity without requiring anchor access', async () => {
    const h = harness(relative)
    Object.assign(h.state, { activeId: 'external', authEmail: 'owner@external.example', anchorEmail: '',
      anchorToken: '', platformIdentity: 'test-user', platformNickName: 'Platform Name',
      platformAvatarUrl: 'https://avatar.example/platform.jpg' })
    await h.target.loadHuaweiIdentity(true)
    assert.equal(h.target.huaweiNickName, 'Platform Name')
    assert.equal(h.target.huaweiAvatarUrl, 'https://avatar.example/platform.jpg')
    assert.equal(h.requests.length, 0)
    assert.deepEqual(h.cacheKeys, [])
    assert.deepEqual(h.writes, [])
  })

  test(relative + ': current platform nickname/avatar win over matching but older anchor profile', async () => {
    const h = harness(relative, binding())
    Object.assign(h.state, { platformIdentity: 'test-user', platformNickName: 'Fresh Name',
      platformAvatarUrl: 'https://avatar.example/fresh.jpg' })
    const pending = h.target.loadHuaweiIdentity(true)
    assert.equal(h.target.huaweiNickName, 'Fresh Name')
    assert.equal(h.target.huaweiAvatarUrl, 'https://avatar.example/fresh.jpg')
    h.requests[0].resolve(binding())
    await pending
    assert.equal(h.target.huaweiNickName, 'Fresh Name')
    assert.equal(h.target.huaweiAvatarUrl, 'https://avatar.example/fresh.jpg')
  })

  test(relative + ': a different identity cannot inherit the old cache, and a mismatched mailbox response is ignored', async () => {
    const h = harness(relative, binding())
    h.state.platformIdentity = 'new-user'
    const pending = h.target.loadHuaweiIdentity(true)
    assert.deepEqual(h.cacheKeys, ['new-user|owner@anchor.example'])
    assert.equal(h.target.huaweiNickName, '')
    assert.equal(h.target.huaweiAvatarUrl, '')
    assert.deepEqual(h.writes, [])
    h.requests[0].resolve(binding({ primaryEmail: 'other@anchor.example' }))
    await pending
    assert.equal(h.target.huaweiNickName, '')
    assert.equal(h.target.huaweiAvatarUrl, '')
    assert.deepEqual(h.writes, [])
    assert.deepEqual(h.cacheSaves, [])
  })

  test(relative + ': real masked Huawei display IDs do not reject an otherwise authenticated anchor profile', async () => {
    const h = harness(relative)
    h.state.platformIdentity = 'abcdef1234567890uvwxyz'
    const pending = h.target.loadHuaweiIdentity(true)
    h.requests[0].resolve(binding({ huaweiUserId: 'abcdef…uvwxyz' }))
    await pending
    assert.deepEqual(h.writes, [[40, 8, 3]])
    assert.equal(h.target.huaweiUserId, 'abcdef1234567890uvwxyz')
    assert.equal(h.cacheSaves[0].owner, 'abcdef1234567890uvwxyz|owner@anchor.example')
  })

  test(relative + ': changing identity invalidates an outstanding anchor profile response', async () => {
    const h = harness(relative)
    h.state.platformIdentity = 'test-user'
    const pending = h.target.loadHuaweiIdentity(true)
    h.state.platformIdentity = 'replacement-user'
    h.target.applyPlatformIdentity()
    h.requests[0].resolve(binding())
    await pending
    assert.equal(h.target.huaweiUserId, 'replacement-user')
    assert.equal(h.target.huaweiNickName, '')
    assert.equal(h.target.userCreateTime, '')
    assert.deepEqual(h.cacheSaves, [])
    assert.deepEqual(h.writes, [])
  })
}

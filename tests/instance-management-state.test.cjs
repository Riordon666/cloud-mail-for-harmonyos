const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const test = require('node:test')
const ts = require(process.env.TYPESCRIPT_PATH ||
  'D:/DevEco Studio/tools/hvigor/hvigor/node_modules/typescript')

const source = fs.readFileSync(path.join(__dirname,
  '../mail/src/main/ets/pages/InstanceManagementPage.ets'), 'utf8')

function method(name) {
  const match = new RegExp('  private (?:async )?' + name + '\\(').exec(source)
  assert.ok(match, name)
  let end = source.indexOf('{', match.index) + 1
  let depth = 1
  while (depth && end < source.length) {
    if (source[end] === '{') depth++
    if (source[end] === '}') depth--
    end++
  }
  assert.equal(depth, 0)
  return source.slice(match.index, end)
}

function harness() {
  const state = { tokens: new Map([['external', 'external-token']]),
    switches: [], directory: [], reauthorizations: 0, local: [], toasts: [] }
  const names = ['hasMailboxSession', 'isCurrentInstance', 'isUnavailable', 'getInstanceStatus',
    'findPlatformInstance', 'getInstanceRoleLabel', 'switchTo', 'openBindSheet', 'loadLocalInstances',
    'refreshInstances', 'reauthorizePlatform']
  const compiled = ts.transpileModule('class Subject {\n' + names.map(method).join('\n') +
    '\n}\nmodule.exports = Subject', {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2021 }
  }).outputText
  const globals = {
    SessionService: { getInstanceToken: id => state.tokens.get(id) || '' },
    InstanceService: {
      switchInstance: id => {
        state.switches.push(id)
        return !!state.tokens.get(id)
      },
      getLocalInstances: () => state.local,
      loadPlatformInstances: async () => state.directory
    },
    PlatformReauthorization: { reauthorize: async () => { state.reauthorizations++ } },
    $r: name => name
  }
  const module = { exports: {} }
  new Function('module', ...Object.keys(globals), compiled)(module, ...Object.values(globals))
  const page = new module.exports()
  Object.assign(page, { activeInstanceId: 'external', platformDirectoryLoaded: false,
    platformInstances: [], pageActive: true, refreshSequence: 0, loading: false, reauthorizing: false,
    showBindSheet: false, showToast: message => state.toasts.push(message),
    getUIContext: () => ({ getHostContext: () => ({}) }) })
  return { state, page }
}

test('a saved anchor without credentials is not shown as signed in or current', () => {
  const { page } = harness()
  page.activeInstanceId = 'anchor'
  assert.equal(page.isCurrentInstance({ instanceId: 'anchor' }), false)
  assert.equal(page.getInstanceStatus({ instanceId: 'anchor' }), 'app.string.instance_needs_login')
  assert.ok(source.includes('this.SectionHeader($r(\'app.string.instance_saved_services\')'))
  assert.ok(!source.includes("this.SectionHeader('已登录服务'"))
})

test('current mailbox requires both matching instance and credentials', () => {
  const { page } = harness()
  assert.equal(page.isCurrentInstance({ instanceId: 'external' }), true)
  assert.equal(page.isCurrentInstance({ instanceId: 'anchor' }), false)
  assert.equal(page.getInstanceStatus({ instanceId: 'external', instanceRole: 'MEMBER' }), '成员')
})

test('authenticated directory role replaces the conservative fast-login role for the same mailbox', () => {
  const { page } = harness()
  const item = { instanceId: 'external', localEmail: 'owner@external.example', instanceRole: 'MEMBER' }
  page.platformDirectoryLoaded = true
  page.platformInstances = [{ ...item, status: 'ACTIVE', bindingStatus: 'ACTIVE', instanceRole: 'INSTANCE_OWNER' }]
  assert.equal(page.getInstanceStatus(item), '实例所有者')
  page.platformInstances[0].instanceRole = 'INSTANCE_ADMIN'
  assert.equal(page.getInstanceStatus(item), '实例管理员')
  page.platformInstances[0].instanceRole = 'MEMBER'
  assert.equal(page.getInstanceStatus({ ...item, instanceRole: 'INSTANCE_OWNER' }), '成员')
})

test('unloaded directory or mismatched binding cannot grant a role from another account', () => {
  const { page } = harness()
  const item = { instanceId: 'external', localEmail: 'member@external.example',
    localRole: 'admin', instanceRole: 'MEMBER' }
  const service = { ...item, status: 'ACTIVE', bindingStatus: 'ACTIVE', instanceRole: 'INSTANCE_OWNER' }
  page.platformInstances = [service]
  assert.equal(page.getInstanceStatus(item), '成员')
  page.platformDirectoryLoaded = true
  for (const patch of [
    { localEmail: 'other@external.example' },
    { localEmail: '' },
    { bindingStatus: 'DISABLED' },
    { bindingStatus: '' },
    { instanceRole: 'SUPER_ADMIN' },
    { instanceRole: '' }
  ]) {
    page.platformInstances = [{ ...service, ...patch }]
    assert.equal(page.getInstanceStatus(item), '成员', JSON.stringify(patch))
  }
  page.platformInstances = [{ ...service, localEmail: '' }]
  assert.equal(page.getInstanceStatus({ ...item, localEmail: '' }), '成员')
})

test('unknown directory role keeps a known local role but never overrides missing sessions', () => {
  const { state, page } = harness()
  const item = { instanceId: 'external', localEmail: 'admin@external.example', instanceRole: 'INSTANCE_ADMIN' }
  page.platformDirectoryLoaded = true
  page.platformInstances = [{ ...item, status: 'ACTIVE', bindingStatus: 'ACTIVE', instanceRole: 'UNKNOWN_ROLE' }]
  assert.equal(page.getInstanceStatus(item), '实例管理员')
  page.platformInstances[0].instanceRole = 'INSTANCE_OWNER'
  state.tokens.delete('external')
  assert.equal(page.getInstanceStatus(item), 'app.string.instance_needs_login')
  state.tokens.set('external', 'external-token')
  page.platformInstances[0].status = 'DISABLED'
  assert.equal(page.getInstanceStatus(item), 'app.string.instance_unavailable')
})

test('offline directory cannot mark saved services as deleted', async () => {
  const { state, page } = harness()
  state.directory = Promise.reject(new Error('offline'))
  page.platformDirectoryLoaded = true
  await page.refreshInstances()
  assert.equal(page.platformDirectoryLoaded, false)
  assert.equal(page.isUnavailable({ instanceId: 'external' }), false)
  assert.equal(page.loading, false)
})

test('confirmed missing or disabled service cannot switch or open binding form', async () => {
  const { state, page } = harness()
  state.directory = [{ instanceId: 'disabled', status: 'DISABLED' }]
  await page.refreshInstances()
  for (const instanceId of ['missing', 'disabled']) {
    const item = { instanceId }
    assert.equal(page.isUnavailable(item), true)
    assert.equal(page.getInstanceStatus(item), 'app.string.instance_unavailable')
    page.switchTo(item)
  }
  assert.deepEqual(state.switches, [])
  assert.equal(page.showBindSheet, false)
})

test('saved service needing login opens only its own binding form without changing current mailbox', () => {
  const { state, page } = harness()
  page.platformInstances = [{ instanceId: 'anchor', localEmail: 'person@anchor.example', status: 'ACTIVE' }]
  page.platformDirectoryLoaded = true
  page.bindPassword = 'old-form-value'
  page.switchTo({ instanceId: 'anchor' })
  assert.equal(page.activeInstanceId, 'external')
  assert.equal(page.selectedInstance.instanceId, 'anchor')
  assert.equal(page.bindEmail, 'person@anchor.example')
  assert.equal(page.bindPassword, '')
  assert.equal(page.showBindSheet, true)
  assert.deepEqual(state.switches, ['anchor'])
})

test('directory completion after leaving page cannot replace its UI state', async () => {
  const { state, page } = harness()
  let resolve
  state.directory = new Promise(done => { resolve = done })
  const pending = page.refreshInstances()
  page.pageActive = false
  page.refreshSequence++
  resolve([{ instanceId: 'late', status: 'ACTIVE' }])
  await pending
  assert.deepEqual(page.platformInstances, [])
  assert.equal(page.platformDirectoryLoaded, false)
})

test('native reauthorization has an actionable card and reloads the directory without switching mailboxes', async () => {
  const { state, page } = harness()
  assert.match(source, /if \(this\.platformReauthRequired\)/)
  assert.match(source, /onClick: \(\) => \{ this\.reauthorizePlatform\(\) \}/)
  assert.match(source, /enable: !this\.reauthorizing/)
  state.directory = [{ instanceId: 'external', status: 'ACTIVE' }]
  await page.reauthorizePlatform()
  assert.equal(state.reauthorizations, 1)
  assert.deepEqual(page.platformInstances, state.directory)
  assert.equal(page.activeInstanceId, 'external')
  assert.deepEqual(state.switches, [])
  assert.equal(page.reauthorizing, false)
})

test('repeated taps while native authorization is in flight do not start another authorization', async () => {
  const { state, page } = harness()
  page.reauthorizing = true
  await page.reauthorizePlatform()
  assert.equal(state.reauthorizations, 0)
})

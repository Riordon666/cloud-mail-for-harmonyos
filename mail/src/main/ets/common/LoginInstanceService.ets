import { preferences } from '@kit.ArkData'
import { ApiException, ApiResponse } from './HttpClient'
import { ExternalHttpClient } from './ExternalHttpClient'
import { PlatformApi } from '../api/PlatformApi'
import Constants from './Constants'
import { InstanceRegistry } from './InstanceRegistry'
import { MailInstance, PlatformInstance, PlatformInstancePayload, PlatformLoginPayload } from './InstanceModels'
import { PlatformSessionService } from './PlatformSessionService'
import { SessionService } from './SessionService'

export class LoginIdentityResult {
  anchorStatus: string = ''
  anchorToken: string = ''
  anchorEmail: string = ''
  anchorBindToken: string = ''
}

export class LoginRegistrationConfig {
  domains: string[] = []
  enabled: boolean = false
  codeRequired: boolean = true
  minPrefix: number = 1
  verificationRequired: boolean = true
}

class AnchorLoginPayload {
  status: string = ''
  token: string = ''
  email: string = ''
  bindToken: string = ''
}

class LoginBootstrapPayload extends PlatformLoginPayload {
  anchor: AnchorLoginPayload = new AnchorLoginPayload()
}

// A server-verified bootstrap is usable only by its original, in-memory result object.
// Keep invalidated results recognizable without retaining them after their page is discarded.
class AnchorActivationSnapshot {
  readonly epoch: number
  readonly revision: number
  readonly platformRevision: number
  readonly platformToken: string = PlatformSessionService.getToken()
  readonly huaweiUserId: string = PlatformSessionService.getHuaweiUserId()
  readonly activeInstanceId: string = SessionService.getActiveInstanceId()
  readonly activeBaseUrl: string = SessionService.getApiBaseUrl()
  readonly activeToken: string = SessionService.getToken()
  readonly verifiedAt: number = Date.now()
  readonly anchorToken: string
  readonly anchorEmail: string
  readonly anchorBindToken: string
  readonly local: MailInstance
  consumed: boolean = false

  constructor(epoch: number, revision: number, identity: LoginIdentityResult, local: MailInstance) {
    this.epoch = epoch
    this.revision = revision
    this.platformRevision = AppStorage.get<number>('platformRevision') || 0
    this.anchorToken = identity.anchorToken
    this.anchorEmail = identity.anchorEmail
    this.anchorBindToken = identity.anchorBindToken
    this.local = new MailInstance(local.instanceId, local.displayName, local.apiBaseUrl, local.originHost,
      local.localEmail, local.localRole, local.localRoleName, local.accountId, local.instanceRole)
  }
}

class LoginWebsitePayload {
  domainList: string[] = []
  register: number = 1
  regKey: number = 1
  registerVerify: number = 1
  regVerifyOpen: boolean = false
  minEmailPrefix: number = 1
}

class AuthorizationRequest {
  authorizationCode: string
  constructor(code: string) { this.authorizationCode = code }
}

class MailboxLoginRequest {
  email: string
  password: string
  constructor(email: string, password: string) { this.email = email; this.password = password }
}

class AnchorBindingRequest extends MailboxLoginRequest {
  bindToken: string
  constructor(bindToken: string, email: string, password: string) {
    super(email, password)
    this.bindToken = bindToken
  }
}

class AnchorRegistrationRequest {
  bindToken: string
  email: string
  code: string
  constructor(bindToken: string, email: string, code: string) {
    this.bindToken = bindToken; this.email = email; this.code = code
  }
}

class MailboxTokenPayload { token: string = '' }
class LoginRolePayload { name: string = '' }
class LoginAccountPayload { accountId: number = 0 }
class LoginUserPayload {
  email: string = ''
  role: LoginRolePayload = new LoginRolePayload()
  account: LoginAccountPayload = new LoginAccountPayload()
  permKeys: string[] = []
}

// Onboarding never changes the active instance until both identity and mailbox verification succeed.
// Passwords and the short-lived anchor binding proof are deliberately not persisted.
export class LoginInstanceService {
  private static selectionPreferences: preferences.Preferences | null = null
  private static preferredInstanceId: string = ''
  private static requestEpoch: number = 0
  private static readonly anchorActivations: WeakMap<LoginIdentityResult, AnchorActivationSnapshot> = new WeakMap()
  private static readonly ANCHOR_ACTIVATION_TTL_MS: number = 60000

  static initialize(context: Context): void {
    try {
      LoginInstanceService.selectionPreferences = preferences.getPreferencesSync(context, { name: 'cloud_mail_login' })
      LoginInstanceService.preferredInstanceId =
        LoginInstanceService.selectionPreferences.getSync('instanceId', '') as string
    } catch (err) {
      console.error('initialize login instance selection failed')
    }
  }

  static getPreferredInstanceId(): string {
    return LoginInstanceService.preferredInstanceId === '' ?
      InstanceRegistry.getDefaultInstanceId() : LoginInstanceService.preferredInstanceId
  }

  static rememberInstance(instanceId: string): void {
    LoginInstanceService.preferredInstanceId = instanceId
    try {
      if (LoginInstanceService.selectionPreferences !== null) {
        LoginInstanceService.selectionPreferences.putSync('instanceId', instanceId)
        LoginInstanceService.selectionPreferences.flushSync()
      }
    } catch (err) {
      console.error('save login instance selection failed')
    }
  }

  static cancelPending(): void { LoginInstanceService.requestEpoch++ }

  static defaultInstance(): PlatformInstance {
    const source: PlatformInstancePayload = new PlatformInstancePayload()
    source.instance_id = InstanceRegistry.getDefaultInstanceId()
    source.display_name = '云笺集主服务'
    source.api_base_url = Constants.API_URL
    source.origin_host = 'mail.riordon.xyz'
    source.status = 'ACTIVE'
    return new PlatformInstance(source)
  }

  static isAnchor(instance: PlatformInstance): boolean {
    return instance.instanceId === InstanceRegistry.getDefaultInstanceId() && instance.apiBaseUrl === Constants.API_URL
  }

  static async listInstances(): Promise<PlatformInstance[]> {
    const response: ApiResponse = await ExternalHttpClient.get(
      Constants.CONTROL_API_URL, '/api/platform/public/instances')
    if (response.data === null || !Array.isArray(response.data)) {
      throw new ApiException(-1, '未能获取邮箱服务列表，请重试', true)
    }
    const payloads: PlatformInstancePayload[] = response.data as PlatformInstancePayload[]
    const result: PlatformInstance[] = []
    for (let index = 0; index < payloads.length; index++) {
      if (payloads[index] === null || typeof payloads[index] !== 'object') {
        throw new ApiException(-1, '邮箱服务列表格式无效，请重试', false)
      }
      const instance: PlatformInstance = new PlatformInstance(payloads[index])
      LoginInstanceService.validateInstance(instance)
      result.push(instance)
    }
    return result
  }

  static async authenticatedInstances(): Promise<PlatformInstance[]> {
    return PlatformApi.instances(LoginInstanceService.requirePlatformToken())
  }

  static async loginHuawei(authorizationCode: string): Promise<LoginIdentityResult> {
    const epoch: number = ++LoginInstanceService.requestEpoch
    const revision: number = LoginInstanceService.sessionRevision()
    const response: ApiResponse = await ExternalHttpClient.post(Constants.CONTROL_API_URL,
      '/api/platform/auth/huawei-anchor', JSON.stringify(new AuthorizationRequest(authorizationCode)))
    if (response.data === null) {
      throw new ApiException(-1, '服务器未返回华为账号登录结果', false)
    }
    const payload: LoginBootstrapPayload = response.data as LoginBootstrapPayload
    const identity: LoginIdentityResult = LoginInstanceService.parseIdentity(payload)
    LoginInstanceService.assertCurrent(epoch, '', revision)
    let anchorInstance: MailInstance | null = null
    if (identity.anchorStatus === 'BOUND') {
      const anchorResponse: ApiResponse = await ExternalHttpClient.get(
        Constants.API_URL, '/my/loginUserInfo', identity.anchorToken)
      anchorInstance = LoginInstanceService.mailboxFromResponse(LoginInstanceService.defaultInstance(), anchorResponse)
      if (anchorInstance.localEmail.toLowerCase() !== identity.anchorEmail.toLowerCase()) {
        throw new ApiException(-1, '主服务邮箱身份校验失败，请重新登录', false)
      }
      LoginInstanceService.assertCurrent(epoch, '', revision)
    }
    // A different device Huawei account must not inherit the previous account's mailbox tokens.
    SessionService.clearAllSessions()
    PlatformSessionService.clear()
    PlatformSessionService.save(payload)
    if (anchorInstance !== null) {
      SessionService.saveInstanceSession(anchorInstance, identity.anchorToken)
      // huawei-anchor already verified and persisted the central binding before issuing this platform session.
      // The local profile/email check above is still mandatory; only subsequent duplicate requests are skipped.
      LoginInstanceService.anchorActivations.set(identity, new AnchorActivationSnapshot(
        epoch, LoginInstanceService.sessionRevision(), identity, anchorInstance))
    }
    return identity
  }

  static async registrationConfig(instance: PlatformInstance): Promise<LoginRegistrationConfig> {
    LoginInstanceService.validateInstance(instance)
    const response: ApiResponse = await ExternalHttpClient.get(instance.apiBaseUrl, '/setting/websiteConfig')
    if (response.data === null) {
      throw new ApiException(-1, '无法读取所选服务的注册配置', true)
    }
    const source: LoginWebsitePayload = response.data as LoginWebsitePayload
    const config: LoginRegistrationConfig = new LoginRegistrationConfig()
    config.enabled = source.register === 0
    config.codeRequired = source.regKey === 0
    config.verificationRequired = source.registerVerify === 0 ||
      (source.registerVerify === 2 && source.regVerifyOpen === true)
    config.minPrefix = typeof source.minEmailPrefix === 'number' && source.minEmailPrefix > 0 ?
      source.minEmailPrefix : 1
    if (Array.isArray(source.domainList)) {
      for (let index = 0; index < source.domainList.length; index++) {
        const domain: string = source.domainList[index]
        if (typeof domain === 'string' && /^@[^@\s/]+\.[^@\s/]+$/.test(domain) &&
          config.domains.indexOf(domain) < 0) {
          config.domains.push(domain)
        }
      }
    }
    return config
  }

  static async reauthorizeHuawei(authorizationCode: string): Promise<void> {
    const expectedHuaweiId: string = PlatformSessionService.getHuaweiUserId()
    const mailboxToken: string = SessionService.getToken()
    const instanceId: string = SessionService.getActiveInstanceId()
    const platformToken: string = PlatformSessionService.getToken()
    const revision: number = LoginInstanceService.sessionRevision()
    if (expectedHuaweiId === '') {
      throw new ApiException(401, '华为身份记录缺失，请退出当前邮箱后重新登录', false)
    }
    if (mailboxToken === '') {
      throw new ApiException(401, '当前邮箱身份已失效，请重新登录', false)
    }
    const epoch: number = ++LoginInstanceService.requestEpoch
    const response: ApiResponse = await ExternalHttpClient.post(Constants.CONTROL_API_URL,
      '/api/platform/auth/huawei-anchor', JSON.stringify(new AuthorizationRequest(authorizationCode)))
    LoginInstanceService.assertCurrent(epoch, '', revision)
    if (expectedHuaweiId !== PlatformSessionService.getHuaweiUserId() ||
      mailboxToken !== SessionService.getToken() || instanceId !== SessionService.getActiveInstanceId() ||
      platformToken !== PlatformSessionService.getToken()) {
      throw new ApiException(409, '邮箱或华为身份已变化，请重新操作', false)
    }
    if (response.data === null) {
      throw new ApiException(-1, '服务器未返回华为账号登录结果', false)
    }
    const payload: LoginBootstrapPayload = response.data as LoginBootstrapPayload
    const identity: LoginIdentityResult = LoginInstanceService.parseIdentity(payload)
    if (payload.user.huaweiUserId !== expectedHuaweiId) {
      throw new ApiException(409, '华为账号与当前邮箱身份不一致，请切回原华为账号后重试', false)
    }
    let anchorInstance: MailInstance | null = null
    if (identity.anchorStatus === 'BOUND') {
      const response: ApiResponse = await ExternalHttpClient.get(
        Constants.API_URL, '/my/loginUserInfo', identity.anchorToken)
      anchorInstance = LoginInstanceService.mailboxFromResponse(LoginInstanceService.defaultInstance(), response)
      if (anchorInstance.localEmail.toLowerCase() !== identity.anchorEmail.toLowerCase()) {
        throw new ApiException(-1, '主服务邮箱身份校验失败，请重新授权', false)
      }
      LoginInstanceService.assertCurrent(epoch, '', revision)
      if (expectedHuaweiId !== PlatformSessionService.getHuaweiUserId() ||
        platformToken !== PlatformSessionService.getToken()) {
        throw new ApiException(409, '华为身份已变化，请重新操作', false)
      }
    }
    PlatformSessionService.save(payload)
    if (anchorInstance !== null) {
      SessionService.saveInstanceSession(anchorInstance, identity.anchorToken)
      if (instanceId === InstanceRegistry.getDefaultInstanceId()) {
        SessionService.saveSession(identity.anchorToken, anchorInstance.localEmail,
          anchorInstance.localRole, anchorInstance.localRoleName, anchorInstance.accountId)
      }
    } else {
      const anchor: MailInstance | null = InstanceRegistry.find(InstanceRegistry.getDefaultInstanceId())
      if (anchor !== null && (anchor.localEmail !== '' || SessionService.getInstanceToken(anchor.instanceId) !== '')) {
        // UNBOUND is authoritative: discard only the invalid anchor, never the current external mailbox.
        SessionService.clearMailboxSession(anchor.instanceId)
      }
    }
  }

  static async activateAnchor(identity: LoginIdentityResult, instance: PlatformInstance): Promise<void> {
    LoginInstanceService.validateInstance(instance)
    const snapshot: AnchorActivationSnapshot | undefined = LoginInstanceService.anchorActivations.get(identity)
    if (snapshot !== undefined && LoginInstanceService.activateVerifiedAnchor(identity, instance, snapshot)) {
      return
    }
    if (!LoginInstanceService.isAnchor(instance) || identity.anchorStatus !== 'BOUND') {
      throw new ApiException(400, '请先绑定所选邮箱服务', false)
    }
    await LoginInstanceService.verifyAndActivate(instance, identity.anchorToken, LoginInstanceService.requestEpoch,
      LoginInstanceService.requirePlatformToken(), LoginInstanceService.sessionRevision())
  }

  private static activateVerifiedAnchor(identity: LoginIdentityResult, instance: PlatformInstance,
    snapshot: AnchorActivationSnapshot): boolean {
    LoginInstanceService.assertCurrent(snapshot.epoch, snapshot.platformToken, snapshot.revision)
    const local: MailInstance | null = InstanceRegistry.find(snapshot.local.instanceId)
    if (snapshot.consumed || snapshot.huaweiUserId !== PlatformSessionService.getHuaweiUserId() ||
      snapshot.platformRevision !== (AppStorage.get<number>('platformRevision') || 0) ||
      snapshot.activeInstanceId !== SessionService.getActiveInstanceId() ||
      snapshot.activeBaseUrl !== SessionService.getApiBaseUrl() || snapshot.activeToken !== SessionService.getToken() ||
      !LoginInstanceService.isAnchor(instance) || identity.anchorStatus !== 'BOUND' ||
      identity.anchorToken !== snapshot.anchorToken || identity.anchorEmail !== snapshot.anchorEmail ||
      identity.anchorBindToken !== snapshot.anchorBindToken ||
      SessionService.getInstanceToken(snapshot.local.instanceId) !== snapshot.anchorToken || local === null ||
      local.apiBaseUrl !== snapshot.local.apiBaseUrl || local.originHost !== snapshot.local.originHost ||
      local.localEmail !== snapshot.local.localEmail || local.localRole !== snapshot.local.localRole ||
      local.localRoleName !== snapshot.local.localRoleName || local.accountId !== snapshot.local.accountId ||
      local.instanceRole !== snapshot.local.instanceRole) {
      throw new ApiException(409, '登录身份或邮箱会话已变化，请重新登录', false)
    }
    // Consume before either activation or fallback. Cancelled/stale results must never enter the slow path.
    snapshot.consumed = true
    const elapsed: number = Date.now() - snapshot.verifiedAt
    if (elapsed < 0 || elapsed >= LoginInstanceService.ANCHOR_ACTIVATION_TTL_MS) { return false }
    if (!SessionService.switchInstance(snapshot.local.instanceId)) {
      throw new ApiException(409, '邮箱会话未能激活，请重新登录', false)
    }
    LoginInstanceService.rememberInstance(snapshot.local.instanceId)
    return true
  }

  static async bind(instance: PlatformInstance, identity: LoginIdentityResult,
    email: string, password: string): Promise<void> {
    LoginInstanceService.validateInstance(instance)
    LoginInstanceService.validateEmail(email)
    if (password === '') { throw new ApiException(400, '请输入所选服务的邮箱密码', false) }
    const epoch: number = LoginInstanceService.requestEpoch
    const platformToken: string = LoginInstanceService.requirePlatformToken()
    const revision: number = LoginInstanceService.sessionRevision()
    let response: ApiResponse
    if (LoginInstanceService.isAnchor(instance)) {
      LoginInstanceService.requireAnchorProof(identity)
      response = await ExternalHttpClient.post(Constants.API_URL, '/oauth/huawei/bind-existing',
        JSON.stringify(new AnchorBindingRequest(identity.anchorBindToken, email.trim(), password)))
    } else {
      response = await ExternalHttpClient.post(instance.apiBaseUrl, '/login',
        JSON.stringify(new MailboxLoginRequest(email.trim(), password)))
    }
    const token: string = LoginInstanceService.parseMailboxToken(response)
    await LoginInstanceService.verifyAndActivate(instance, token, epoch, platformToken, revision)
  }

  static async registerAnchor(instance: PlatformInstance, identity: LoginIdentityResult,
    email: string, code: string): Promise<void> {
    if (!LoginInstanceService.isAnchor(instance)) {
      throw new ApiException(400, '请前往所选服务的网站注册，再返回绑定', false)
    }
    LoginInstanceService.validateEmail(email)
    LoginInstanceService.requireAnchorProof(identity)
    const epoch: number = LoginInstanceService.requestEpoch
    const platformToken: string = LoginInstanceService.requirePlatformToken()
    const revision: number = LoginInstanceService.sessionRevision()
    const response: ApiResponse = await ExternalHttpClient.post(Constants.API_URL, '/oauth/huawei/register',
      JSON.stringify(new AnchorRegistrationRequest(identity.anchorBindToken, email.trim(), code.trim())))
    await LoginInstanceService.verifyAndActivate(instance, LoginInstanceService.parseMailboxToken(response),
      epoch, platformToken, revision)
  }

  private static async verifyAndActivate(instance: PlatformInstance, token: string, epoch: number,
    platformToken: string, revision: number): Promise<void> {
    LoginInstanceService.assertCurrent(epoch, platformToken, revision)
    const expectedHuaweiId: string = PlatformSessionService.getHuaweiUserId()
    const response: ApiResponse = await ExternalHttpClient.get(instance.apiBaseUrl, '/my/loginUserInfo', token)
    const local: MailInstance = LoginInstanceService.mailboxFromResponse(instance, response)
    LoginInstanceService.assertCurrent(epoch, platformToken, revision, expectedHuaweiId)
    const binding = await PlatformApi.verifyBinding(platformToken, instance.instanceId, token)
    LoginInstanceService.assertCurrent(epoch, platformToken, revision, expectedHuaweiId)
    let renewedPlatform: PlatformLoginPayload | null = null
    if (LoginInstanceService.isAnchor(instance)) {
      // Promote only from a server-verified anchor account, never from a client email or role.
      renewedPlatform = await PlatformApi.loginThroughAnchor(token)
      LoginInstanceService.assertCurrent(epoch, platformToken, revision, expectedHuaweiId)
      if (renewedPlatform.user.huaweiUserId !== expectedHuaweiId) {
        throw new ApiException(409, '主服务与当前华为身份不一致，请重新登录', false)
      }
    }
    local.instanceRole = binding.instanceRole
    if (renewedPlatform !== null) { PlatformSessionService.save(renewedPlatform) }
    SessionService.saveInstanceSession(local, token)
    if (!SessionService.switchInstance(instance.instanceId)) {
      throw new ApiException(409, '邮箱会话未能激活，请重新登录', false)
    }
    LoginInstanceService.rememberInstance(instance.instanceId)
  }

  private static parseMailboxToken(response: ApiResponse): string {
    if (response.data !== null) {
      const payload: MailboxTokenPayload = response.data as MailboxTokenPayload
      if (typeof payload.token === 'string' && payload.token !== '') { return payload.token }
    }
    throw new ApiException(-1, '所选服务未返回登录令牌', false)
  }

  private static parseIdentity(payload: LoginBootstrapPayload): LoginIdentityResult {
    if (typeof payload.token !== 'string' || payload.token === '' || !payload.user ||
      typeof payload.user.huaweiUserId !== 'string' || payload.user.huaweiUserId === '' || !payload.anchor) {
      throw new ApiException(-1, '平台登录结果无效，请重试', false)
    }
    const identity: LoginIdentityResult = new LoginIdentityResult()
    identity.anchorStatus = payload.anchor.status
    identity.anchorToken = typeof payload.anchor.token === 'string' ? payload.anchor.token : ''
    identity.anchorEmail = typeof payload.anchor.email === 'string' ? payload.anchor.email : ''
    identity.anchorBindToken = typeof payload.anchor.bindToken === 'string' ? payload.anchor.bindToken : ''
    if ((identity.anchorStatus !== 'BOUND' && identity.anchorStatus !== 'UNBOUND') ||
      (identity.anchorStatus === 'BOUND' && (identity.anchorToken === '' || identity.anchorEmail === '')) ||
      (identity.anchorStatus === 'UNBOUND' && identity.anchorBindToken === '')) {
      throw new ApiException(-1, '华为身份验证结果无效，请重新登录', false)
    }
    return identity
  }

  private static mailboxFromResponse(instance: PlatformInstance, response: ApiResponse): MailInstance {
    if (response.data === null) { throw new ApiException(-1, '所选服务未返回邮箱信息', false) }
    const user: LoginUserPayload = response.data as LoginUserPayload
    if (typeof user.email !== 'string' || user.email === '') {
      throw new ApiException(-1, '所选服务未返回有效的邮箱信息', false)
    }
    const roleName: string = user.role && typeof user.role.name === 'string' && user.role.name !== '' ?
      user.role.name : '普通用户'
    const isAdmin: boolean = roleName === 'admin' || (Array.isArray(user.permKeys) && user.permKeys.indexOf('*') >= 0)
    const accountId: number = user.account && typeof user.account.accountId === 'number' ? user.account.accountId : 0
    return new MailInstance(instance.instanceId, instance.displayName, instance.apiBaseUrl,
      instance.originHost, user.email, isAdmin ? 'admin' : 'user', roleName, accountId)
  }

  private static requirePlatformToken(): string {
    const token: string = PlatformSessionService.getToken()
    if (token === '') { throw new ApiException(401, '请先登录华为账号，再绑定邮箱服务', false) }
    return token
  }

  private static requireAnchorProof(identity: LoginIdentityResult): void {
    if (identity.anchorStatus !== 'UNBOUND' || identity.anchorBindToken === '') {
      throw new ApiException(401, '绑定凭据已失效，请重新登录华为账号', false)
    }
  }

  private static sessionRevision(): number {
    const revision: number | undefined = AppStorage.get('sessionRevision') as number | undefined
    return revision === undefined ? 0 : revision
  }

  private static assertCurrent(epoch: number, platformToken: string = '', revision: number = -1,
    huaweiUserId: string = ''): void {
    if (epoch !== LoginInstanceService.requestEpoch ||
      (platformToken !== '' && platformToken !== PlatformSessionService.getToken()) ||
      (huaweiUserId !== '' && huaweiUserId !== PlatformSessionService.getHuaweiUserId()) ||
      (revision >= 0 && revision !== LoginInstanceService.sessionRevision())) {
      throw new ApiException(409, '登录状态已变化，请重新操作', false)
    }
  }

  private static validateInstance(instance: PlatformInstance): void {
    if (instance.instanceId === '' || instance.status !== 'ACTIVE' ||
      !instance.apiBaseUrl.startsWith('https://') || instance.originHost === '') {
      throw new ApiException(400, '所选邮箱服务不可用，请重新选择', false)
    }
  }

  private static validateEmail(email: string): void {
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email.trim())) {
      throw new ApiException(400, '请输入完整的主邮箱地址', false)
    }
  }
}

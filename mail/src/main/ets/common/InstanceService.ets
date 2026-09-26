import { PlatformApi } from '../api/PlatformApi'
import { AuthUserInfo } from '../api/AuthApi'
import { ApiException, ApiResponse } from './HttpClient'
import { ExternalHttpClient } from './ExternalHttpClient'
import { InstanceRegistry } from './InstanceRegistry'
import {
  MailInstance,
  PlatformAdminBindingPage,
  PlatformBinding,
  PlatformBindingPayload,
  PlatformImportResult,
  PlatformInstance,
  PlatformLoginPayload
} from './InstanceModels'
import { PlatformSessionService } from './PlatformSessionService'
import { SessionService } from './SessionService'
import Constants from './Constants'

class InstanceLoginRequest {
  email: string
  password: string

  constructor(email: string, password: string) {
    this.email = email
    this.password = password
  }
}

class InstanceLoginPayload {
  token: string = ''
}

class BindingRemovalPayload {
  instanceId: string = ''
  platformRole: string = ''
}

class InstanceRemoteAccount {
  accountId: number = 0
}

class InstanceRemoteRole {
  name: string = ''
}

class InstanceRemoteUser {
  email: string = ''
  account: InstanceRemoteAccount = new InstanceRemoteAccount()
  role: InstanceRemoteRole = new InstanceRemoteRole()
  permKeys: string[] = []
}

export class InstanceBindResult {
  success: boolean
  message: string
  instance: MailInstance | null

  constructor(success: boolean, message: string, instance: MailInstance | null = null) {
    this.success = success
    this.message = message
    this.instance = instance
  }
}

export class InstanceService {
  static initialize(context: Context): void {
    PlatformSessionService.initialize(context)
  }

  static async ensurePlatformSession(forceRefresh: boolean = false): Promise<boolean> {
    const expectedHuaweiId: string = PlatformSessionService.getHuaweiUserId()
    if (expectedHuaweiId === '' && SessionService.getToken() !== '' &&
      SessionService.getActiveInstanceId() !== InstanceRegistry.getDefaultInstanceId()) {
      // Old broken sessions lost their owner record. Do not infer their identity from another mailbox.
      PlatformSessionService.requireReauthorization()
      return false
    }
    if (!forceRefresh && expectedHuaweiId !== '' && PlatformSessionService.getToken() !== '') {
      return true
    }
    if (forceRefresh) {
      PlatformSessionService.invalidateToken()
    }
    const expectedPlatformToken: string = PlatformSessionService.getToken()
    const revision: number = InstanceService.sessionRevision()
    const defaultToken: string = SessionService.getInstanceToken(InstanceRegistry.getDefaultInstanceId())
    if (defaultToken === '') {
      if (SessionService.getToken() !== '') {
        PlatformSessionService.requireReauthorization()
      }
      return false
    }
    try {
      const payload: PlatformLoginPayload = await PlatformApi.loginThroughAnchor(defaultToken)
      if (expectedHuaweiId !== PlatformSessionService.getHuaweiUserId() ||
        expectedPlatformToken !== PlatformSessionService.getToken() ||
        revision !== InstanceService.sessionRevision() ||
        defaultToken !== SessionService.getInstanceToken(InstanceRegistry.getDefaultInstanceId())) {
        return false
      }
      if (!payload.user || typeof payload.user.huaweiUserId !== 'string' || payload.user.huaweiUserId === '' ||
        (expectedHuaweiId !== '' && payload.user.huaweiUserId !== expectedHuaweiId)) {
        throw new ApiException(409, '主服务与当前华为身份不一致，请重新授权', false)
      }
      PlatformSessionService.save(payload)
      return true
    } catch (err) {
      if (expectedHuaweiId === PlatformSessionService.getHuaweiUserId() &&
        expectedPlatformToken === PlatformSessionService.getToken() && revision === InstanceService.sessionRevision() &&
        defaultToken === SessionService.getInstanceToken(InstanceRegistry.getDefaultInstanceId()) &&
        SessionService.getToken() !== '') {
        PlatformSessionService.requireReauthorization()
      }
      console.error('platform anchor login failed')
      return false
    }
  }

  static async loadPlatformInstances(): Promise<PlatformInstance[]> {
    const instances: PlatformInstance[] = await InstanceService.withPlatformSession(
      (token: string): Promise<PlatformInstance[]> => {
      return PlatformApi.instances(token)
    })
    SessionService.synchronizeInstanceMetadata(instances)
    return instances
  }

  static async loadMyBindings(): Promise<PlatformBinding[]> {
    return InstanceService.withPlatformSession((token: string): Promise<PlatformBinding[]> => {
      return PlatformApi.myBindings(token)
    })
  }

  static async unlinkMyBinding(instanceId: string, expectedHuaweiUserId: string,
    expectedEmail: string, bindingId: number, verifiedTime: string): Promise<void> {
    if (instanceId === '' || expectedHuaweiUserId === '' || expectedEmail === '' ||
      !Number.isSafeInteger(bindingId) || bindingId <= 0 || verifiedTime === '') {
      throw new ApiException(400, '邮箱绑定标识无效', false)
    }
    let responseToken: string = ''
    const response: ApiResponse = await InstanceService.withPlatformSession((token: string): Promise<ApiResponse> => {
      if (PlatformSessionService.getHuaweiUserId() !== expectedHuaweiUserId) {
        throw new ApiException(409, '华为账号已变化，已取消绑定清理', false)
      }
      responseToken = token
      return ExternalHttpClient.delete(Constants.CONTROL_API_URL,
        '/api/platform/bindings/' + encodeURIComponent(instanceId) + '?email=' + encodeURIComponent(expectedEmail) +
        '&bindingId=' + bindingId.toString() + '&verifiedTime=' + encodeURIComponent(verifiedTime), token)
    })
    if (expectedHuaweiUserId !== PlatformSessionService.getHuaweiUserId()) {
      throw new ApiException(409, '华为账号已变化，已取消绑定清理', false)
    }
    if (response.data !== null && responseToken === PlatformSessionService.getToken()) {
      const result: BindingRemovalPayload = response.data as BindingRemovalPayload
      if (result.instanceId === instanceId) {
        PlatformSessionService.updateRole(result.platformRole)
      }
    }
  }

  static async loadAdminBindings(keyword: string, page: number, size: number):
    Promise<PlatformAdminBindingPage> {
    return InstanceService.withPlatformSession((token: string): Promise<PlatformAdminBindingPage> => {
      return PlatformApi.adminBindings(token, keyword, page, size)
    })
  }

  static async createPlatformInstance(apiBaseUrl: string, displayName: string): Promise<void> {
    await InstanceService.withPlatformSession((token: string): Promise<Object> => {
      return PlatformApi.createInstance(token, apiBaseUrl, displayName)
    })
  }

  static async renamePlatformInstance(instanceId: string, displayName: string): Promise<void> {
    const normalizedName: string = displayName.trim()
    if (instanceId === '' || normalizedName === '') {
      throw new ApiException(400, '请输入有效的邮箱服务名称', false)
    }
    await InstanceService.withPlatformSession((token: string): Promise<void> => {
      return PlatformApi.renameInstance(token, instanceId, normalizedName)
    })
    SessionService.updateInstanceMetadata(instanceId, normalizedName)
  }

  static async deletePlatformInstance(instanceId: string): Promise<void> {
    if (instanceId === '') {
      throw new ApiException(400, '邮箱服务标识无效', false)
    }
    await InstanceService.withPlatformSession((token: string): Promise<void> => {
      return PlatformApi.deleteInstance(token, instanceId)
    })
    SessionService.removeInstanceSession(instanceId)
  }

  static async importAnchorHuaweiAccounts(): Promise<PlatformImportResult> {
    const anchorToken: string = SessionService.getInstanceToken(InstanceRegistry.getDefaultInstanceId())
    if (anchorToken === '') {
      throw new ApiException(401, '主服务登录已失效，请重新登录华为账号', false)
    }
    return InstanceService.withPlatformSession((token: string): Promise<PlatformImportResult> => {
      return PlatformApi.importAnchorHuaweiAccounts(token, anchorToken)
    })
  }

  static async bindInstance(instance: PlatformInstance, email: string, password: string): Promise<InstanceBindResult> {
    if (email.trim() === '' || password === '') {
      return new InstanceBindResult(false, '请输入该实例的完整邮箱和密码')
    }
    const expectedHuaweiId: string = PlatformSessionService.getHuaweiUserId()
    const revision: number = InstanceService.sessionRevision()
    try {
      if (expectedHuaweiId === '') {
        throw new ApiException(401, '华为身份记录缺失，请退出当前邮箱后重新登录', false)
      }
      const loginRequest: InstanceLoginRequest = new InstanceLoginRequest(email.trim(), password)
      const loginResponse: ApiResponse = await ExternalHttpClient.post(
        instance.apiBaseUrl, '/login', JSON.stringify(loginRequest))
      InstanceService.assertPlatformOwner(expectedHuaweiId, revision)
      if (loginResponse.data === null) {
        return new InstanceBindResult(false, '实例未返回登录令牌')
      }
      const loginPayload: InstanceLoginPayload = loginResponse.data as InstanceLoginPayload
      if (loginPayload.token === '') {
        return new InstanceBindResult(false, '实例未返回登录令牌')
      }
      const user: AuthUserInfo = await InstanceService.loadInstanceUser(instance.apiBaseUrl, loginPayload.token)
      InstanceService.assertPlatformOwner(expectedHuaweiId, revision)
      const binding: PlatformBindingPayload = await InstanceService.withPlatformSession(
        (token: string): Promise<PlatformBindingPayload> => {
          return PlatformApi.verifyBinding(token, instance.instanceId, loginPayload.token)
        })
      InstanceService.assertPlatformOwner(expectedHuaweiId, revision)
      const localInstance: MailInstance = new MailInstance(
        instance.instanceId,
        instance.displayName,
        instance.apiBaseUrl,
        instance.originHost,
        user.email,
        user.role,
        user.roleName,
        user.accountId,
        binding.instanceRole
      )
      SessionService.saveInstanceSession(localInstance, loginPayload.token)
      return new InstanceBindResult(true, '', localInstance)
    } catch (err) {
      if (err instanceof ApiException) {
        return new InstanceBindResult(false, err.message)
      }
      return new InstanceBindResult(false, '实例绑定失败，请稍后重试')
    }
  }

  static getLocalInstances(): MailInstance[] {
    return InstanceRegistry.getInstances()
  }

  static switchInstance(instanceId: string): boolean {
    return SessionService.switchInstance(instanceId)
  }

  static removeInstance(instanceId: string): boolean {
    return SessionService.removeInstanceSession(instanceId)
  }

  static getAnchorEmail(): string {
    const instance: MailInstance | null = InstanceRegistry.find(InstanceRegistry.getDefaultInstanceId())
    return instance === null ? '' : instance.localEmail
  }

  static getAnchorApiBaseUrl(): string {
    const instance: MailInstance | null = InstanceRegistry.find(InstanceRegistry.getDefaultInstanceId())
    return instance === null ? '' : instance.apiBaseUrl
  }

  static getAnchorToken(): string {
    return SessionService.getInstanceToken(InstanceRegistry.getDefaultInstanceId())
  }

  private static async loadInstanceUser(apiBaseUrl: string, token: string): Promise<AuthUserInfo> {
    const response: ApiResponse = await ExternalHttpClient.get(apiBaseUrl, '/my/loginUserInfo', token)
    if (response.data === null) {
      throw new ApiException(-1, '实例未返回用户信息', false)
    }
    const payload: InstanceRemoteUser = response.data as InstanceRemoteUser
    const email: string = payload.email === undefined ? '' : payload.email
    if (email === '') {
      throw new ApiException(-1, '实例未返回用户邮箱', false)
    }
    const roleName: string = payload.role === undefined || payload.role.name === undefined || payload.role.name === '' ?
      '普通用户' : payload.role.name
    const permKeys: string[] = payload.permKeys === undefined ? [] : payload.permKeys
    const accountId: number = payload.account === undefined || payload.account.accountId === undefined ?
      0 : payload.account.accountId
    const isAdmin: boolean = InstanceService.isAdministrator(roleName, permKeys)
    return new AuthUserInfo(email, isAdmin ? 'admin' : 'user', roleName, accountId)
  }

  private static isAdministrator(roleName: string, permKeys: string[]): boolean {
    if (roleName === 'admin') {
      return true
    }
    for (let index = 0; index < permKeys.length; index++) {
      if (permKeys[index] === '*') {
        return true
      }
    }
    return false
  }

  private static async withPlatformSession<T>(operation: (token: string) => Promise<T>): Promise<T> {
    const initialHuaweiId: string = PlatformSessionService.getHuaweiUserId()
    const revision: number = InstanceService.sessionRevision()
    const ready: boolean = await InstanceService.ensurePlatformSession()
    if (revision !== InstanceService.sessionRevision() ||
      (initialHuaweiId !== '' && initialHuaweiId !== PlatformSessionService.getHuaweiUserId())) {
      throw new ApiException(409, '邮箱或华为身份已变化，请重新操作', false)
    }
    if (!ready) {
      throw new ApiException(401, PlatformSessionService.getHuaweiUserId() === '' ?
        '华为身份记录缺失，请退出当前邮箱后重新登录' : '平台身份尚未建立，请重新授权华为账号', false)
    }
    const expectedHuaweiId: string = PlatformSessionService.getHuaweiUserId()
    const requestToken: string = PlatformSessionService.getToken()
    try {
      const result: T = await operation(requestToken)
      InstanceService.assertPlatformOwner(expectedHuaweiId, revision)
      return result
    } catch (err) {
      InstanceService.assertPlatformOwner(expectedHuaweiId, revision)
      if (!(err instanceof ApiException)) {
        throw new ApiException(-1, '平台服务请求失败，请稍后重试', true)
      }
      if (err.code !== 401) {
        throw err
      }
    }
    if (requestToken !== PlatformSessionService.getToken() && PlatformSessionService.getToken() !== '') {
      const result: T = await operation(PlatformSessionService.getToken())
      InstanceService.assertPlatformOwner(expectedHuaweiId, revision)
      return result
    }
    const renewed: boolean = await InstanceService.ensurePlatformSession(true)
    InstanceService.assertPlatformOwner(expectedHuaweiId, revision)
    if (!renewed) {
      throw new ApiException(401, '平台登录已过期，请重新登录华为账号', false)
    }
    const result: T = await operation(PlatformSessionService.getToken())
    InstanceService.assertPlatformOwner(expectedHuaweiId, revision)
    return result
  }

  private static sessionRevision(): number {
    const revision: number | undefined = AppStorage.get('sessionRevision') as number | undefined
    return revision === undefined ? 0 : revision
  }

  private static assertPlatformOwner(huaweiUserId: string, revision: number): void {
    if (huaweiUserId !== PlatformSessionService.getHuaweiUserId() || revision !== InstanceService.sessionRevision()) {
      throw new ApiException(409, '邮箱或华为身份已变化，请重新操作', false)
    }
  }
}

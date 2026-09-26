import { AuthApi, AuthUserInfo } from '../api/AuthApi'
import { ApiException } from './HttpClient'
import { HuaweiLoginResult, HuaweiSessionResult } from '../api/AuthApi'
import { SessionService } from './SessionService'
import Constants from './Constants'
import { InstanceService } from './InstanceService'
import { PlatformSessionService } from './PlatformSessionService'
import { LoginInstanceService } from './LoginInstanceService'

export class AuthResult {
  success: boolean
  message: string

  constructor(success: boolean, message: string) {
    this.success = success
    this.message = message
  }
}

export class HuaweiAuthResult {
  success: boolean
  message: string
  bound: boolean
  bindToken: string

  constructor(success: boolean, message: string, bound: boolean, bindToken: string) {
    this.success = success
    this.message = message
    this.bound = bound
    this.bindToken = bindToken
  }
}

export class AuthService {
  static initialize(context: Context): void {
    SessionService.initialize(context)
    InstanceService.initialize(context)
    LoginInstanceService.initialize(context)
  }

  static async login(email: string, password: string): Promise<AuthResult> {
    if (!AuthService.isSupportedEmail(email)) {
      return new AuthResult(false, '仅支持 ' + Constants.MAIL_DOMAIN + ' 邮箱')
    }
    try {
      const token: string = await AuthApi.login(email, password)
      SessionService.saveSession(token, email, 'user', '普通用户', 0)
      const user: AuthUserInfo = await AuthApi.getCurrentUser()
      SessionService.saveSession(token, user.email, user.role, user.roleName, user.accountId)
      return new AuthResult(true, '')
    } catch (err) {
      if (err instanceof ApiException && err.code === 401) {
        SessionService.clearSession()
      }
      return new AuthResult(false, AuthService.getErrorMessage(err))
    }
  }

  static async register(email: string, password: string, registerCode: string): Promise<AuthResult> {
    if (!AuthService.isSupportedEmail(email)) {
      return new AuthResult(false, '仅支持 ' + Constants.MAIL_DOMAIN + ' 邮箱')
    }
    try {
      await AuthApi.register(email, password, registerCode)
      return new AuthResult(true, '')
    } catch (err) {
      return new AuthResult(false, AuthService.getErrorMessage(err))
    }
  }

  static async loginWithHuawei(authorizationCode: string): Promise<HuaweiAuthResult> {
    try {
      const result: HuaweiLoginResult = await AuthApi.loginWithHuawei(authorizationCode)
      if (!result.bound) {
        return new HuaweiAuthResult(true, '', false, result.bindToken)
      }
      await AuthService.saveHuaweiSession(result.token, result.email)
      return new HuaweiAuthResult(true, '', true, '')
    } catch (err) {
      return new HuaweiAuthResult(false, AuthService.getErrorMessage(err), false, '')
    }
  }

  static async bindHuaweiAccount(bindToken: string, email: string, password: string): Promise<AuthResult> {
    if (!AuthService.isSupportedEmail(email)) {
      return new AuthResult(false, '仅支持 ' + Constants.MAIL_DOMAIN + ' 邮箱')
    }
    try {
      const result: HuaweiSessionResult = await AuthApi.bindHuaweiAccount(bindToken, email, password)
      await AuthService.saveHuaweiSession(result.token, result.email)
      return new AuthResult(true, '')
    } catch (err) {
      return new AuthResult(false, AuthService.getErrorMessage(err))
    }
  }

  static async registerWithHuawei(bindToken: string, email: string, registerCode: string): Promise<AuthResult> {
    if (!AuthService.isSupportedEmail(email)) {
      return new AuthResult(false, '仅支持 ' + Constants.MAIL_DOMAIN + ' 邮箱')
    }
    try {
      const result: HuaweiSessionResult = await AuthApi.registerWithHuawei(bindToken, email, registerCode)
      await AuthService.saveHuaweiSession(result.token, result.email)
      return new AuthResult(true, '')
    } catch (err) {
      return new AuthResult(false, AuthService.getErrorMessage(err))
    }
  }

  static logout(): void {
    const token: string = SessionService.getToken()
    const apiBaseUrl: string = SessionService.getApiBaseUrl()
    LoginInstanceService.cancelPending()
    SessionService.clearAllSessions()
    PlatformSessionService.clear()
    if (token !== '') {
      AuthService.revokeServerSession(apiBaseUrl, token)
    }
  }

  static async refreshSession(): Promise<AuthResult> {
    const token: string = SessionService.getToken()
    const instanceId: string = SessionService.getActiveInstanceId()
    const revision: number = (AppStorage.get('sessionRevision') as number | undefined) ?? 0
    if (token === '') {
      return new AuthResult(false, '未登录')
    }
    try {
      const user: AuthUserInfo = await AuthApi.getCurrentUser()
      if (instanceId !== SessionService.getActiveInstanceId() || token !== SessionService.getToken() ||
        revision !== ((AppStorage.get('sessionRevision') as number | undefined) ?? 0)) {
        return new AuthResult(false, '邮箱或登录账号已切换，已取消原请求')
      }
      SessionService.saveSession(token, user.email, user.role, user.roleName, user.accountId)
      await InstanceService.ensurePlatformSession()
      return new AuthResult(true, '')
    } catch (err) {
      if (err instanceof ApiException && err.code === 401) {
        if (instanceId === SessionService.getActiveInstanceId() && token === SessionService.getToken() &&
          revision === ((AppStorage.get('sessionRevision') as number | undefined) ?? 0)) {
          SessionService.clearSession()
        }
        return new AuthResult(false, '登录已过期，请重新登录')
      }
      return new AuthResult(true, '')
    }
  }

  private static async revokeServerSession(apiBaseUrl: string, token: string): Promise<void> {
    try {
      await AuthApi.logout(apiBaseUrl, token)
    } catch (err) {
      console.error('logout request failed')
    }
  }

  private static async saveHuaweiSession(token: string, email: string): Promise<void> {
    SessionService.saveSession(token, email, 'user', '普通用户', 0)
    const user: AuthUserInfo = await AuthApi.getCurrentUser()
    SessionService.saveSession(token, user.email, user.role, user.roleName, user.accountId)
    await InstanceService.ensurePlatformSession()
  }

  private static getErrorMessage(err: Object): string {
    if (err instanceof ApiException) {
      return err.message
    }
    return '请求失败，请稍后重试'
  }

  private static isSupportedEmail(email: string): boolean {
    const domainIndex: number = email.lastIndexOf(Constants.MAIL_DOMAIN)
    return domainIndex > 0 && domainIndex === email.length - Constants.MAIL_DOMAIN.length
  }
}

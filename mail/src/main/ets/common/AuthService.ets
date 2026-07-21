import { AuthApi, AuthUserInfo } from '../api/AuthApi'
import { ApiException } from './HttpClient'
import { SessionService } from './SessionService'
import Constants from './Constants'

export class AuthResult {
  success: boolean
  message: string

  constructor(success: boolean, message: string) {
    this.success = success
    this.message = message
  }
}

export class AuthService {
  static initialize(context: Context): void {
    SessionService.initialize(context)
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

  static logout(): void {
    const token: string = SessionService.getToken()
    SessionService.clearSession()
    if (token !== '') {
      AuthService.revokeServerSession(token)
    }
  }

  static async refreshSession(): Promise<AuthResult> {
    const token: string = SessionService.getToken()
    if (token === '') {
      return new AuthResult(false, '未登录')
    }
    try {
      const user: AuthUserInfo = await AuthApi.getCurrentUser()
      SessionService.saveSession(token, user.email, user.role, user.roleName, user.accountId)
      return new AuthResult(true, '')
    } catch (err) {
      if (err instanceof ApiException && err.code === 401) {
        SessionService.clearSession()
        return new AuthResult(false, '登录已过期，请重新登录')
      }
      return new AuthResult(true, '')
    }
  }

  private static async revokeServerSession(token: string): Promise<void> {
    try {
      await AuthApi.logout(token)
    } catch (err) {
      console.error('logout request failed')
    }
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

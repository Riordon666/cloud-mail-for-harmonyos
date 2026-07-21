import { preferences } from '@kit.ArkData'

export class SessionService {
  private static sessionPreferences: preferences.Preferences | null = null

  static initialize(context: Context): void {
    let token: string = ''
    let email: string = ''
    let role: string = 'user'
    let roleName: string = '普通用户'
    let accountId: number = 0
    try {
      SessionService.sessionPreferences = preferences.getPreferencesSync(context, { name: 'cloud_mail_auth' })
      token = SessionService.sessionPreferences.getSync('token', '') as string
      email = SessionService.sessionPreferences.getSync('email', '') as string
      role = SessionService.sessionPreferences.getSync('role', 'user') as string
      roleName = SessionService.sessionPreferences.getSync('roleName', '普通用户') as string
      accountId = SessionService.sessionPreferences.getSync('accountId', 0) as number
    } catch (err) {
      console.error('initialize session preferences failed')
    }
    AppStorage.setOrCreate('authToken', token)
    AppStorage.setOrCreate('authEmail', email)
    AppStorage.setOrCreate('authRole', role)
    AppStorage.setOrCreate('authRoleName', roleName)
    AppStorage.setOrCreate('currentAccountId', accountId)
    AppStorage.setOrCreate('sessionRevision', 0)
  }

  static saveSession(token: string, email: string, role: string, roleName: string, accountId: number): void {
    AppStorage.set('authToken', token)
    AppStorage.set('authEmail', email)
    AppStorage.set('authRole', role)
    AppStorage.set('authRoleName', roleName)
    AppStorage.set('currentAccountId', accountId)
    SessionService.notifySessionChanged()
    if (SessionService.sessionPreferences === null) {
      return
    }
    try {
      SessionService.sessionPreferences.putSync('token', token)
      SessionService.sessionPreferences.putSync('email', email)
      SessionService.sessionPreferences.putSync('role', role)
      SessionService.sessionPreferences.putSync('roleName', roleName)
      SessionService.sessionPreferences.putSync('accountId', accountId)
      SessionService.sessionPreferences.flushSync()
    } catch (err) {
      console.error('save session preferences failed')
    }
  }

  static clearSession(): void {
    AppStorage.set('authToken', '')
    AppStorage.set('authEmail', '')
    AppStorage.set('authRole', 'user')
    AppStorage.set('authRoleName', '普通用户')
    AppStorage.set('currentAccountId', 0)
    SessionService.notifySessionChanged()
    if (SessionService.sessionPreferences === null) {
      return
    }
    try {
      SessionService.sessionPreferences.deleteSync('token')
      SessionService.sessionPreferences.deleteSync('email')
      SessionService.sessionPreferences.deleteSync('role')
      SessionService.sessionPreferences.deleteSync('roleName')
      SessionService.sessionPreferences.deleteSync('accountId')
      SessionService.sessionPreferences.flushSync()
    } catch (err) {
      console.error('clear session preferences failed')
    }
  }

  static getToken(): string {
    const token: string | undefined = AppStorage.get('authToken') as string | undefined
    return token === undefined ? '' : token
  }

  private static notifySessionChanged(): void {
    const revision: number | undefined = AppStorage.get('sessionRevision') as number | undefined
    AppStorage.set('sessionRevision', revision === undefined ? 1 : revision + 1)
  }
}

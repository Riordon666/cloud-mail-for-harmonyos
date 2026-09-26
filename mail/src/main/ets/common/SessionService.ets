import { preferences } from '@kit.ArkData'

import Constants from './Constants'
import { InstanceRegistry } from './InstanceRegistry'
import { MailInstance, PlatformInstance } from './InstanceModels'
import { MailStatsStore } from './MailStatsStore'
import { SecureTokenStore } from './SecureTokenStore'
import { DraftService } from './DraftService'
import { MailDetailCache } from './MailDetailCache'

export class SessionService {
  private static sessionPreferences: preferences.Preferences | null = null

  static initialize(context: Context): void {
    InstanceRegistry.initialize(context)
    let token: string = ''
    let email: string = ''
    let role: string = 'user'
    let roleName: string = '普通用户'
    let accountId: number = 0
    try {
      SessionService.sessionPreferences = preferences.getPreferencesSync(context, { name: 'cloud_mail_auth' })
      const activeInstance: MailInstance = InstanceRegistry.getActiveInstance()
      const legacyToken: string = SessionService.sessionPreferences.getSync('token', '') as string
      token = SecureTokenStore.getInstanceToken(activeInstance.instanceId)
      if (token === '' && legacyToken !== '') {
        token = legacyToken
        SecureTokenStore.saveInstanceToken(activeInstance.instanceId, legacyToken)
        SessionService.sessionPreferences.deleteSync('token')
        SessionService.sessionPreferences.flushSync()
      }
      // Older releases have no marker. A prefetched onboarding token is not an activated mailbox.
      const committed: boolean = SessionService.sessionPreferences.getSync('activeSessionCommitted', true) as boolean
      if (!committed) {
        token = ''
      }
      email = activeInstance.localEmail
      role = activeInstance.localRole
      roleName = activeInstance.localRoleName
      accountId = activeInstance.accountId
      if (email === '') {
        email = SessionService.sessionPreferences.getSync('email', '') as string
        role = SessionService.sessionPreferences.getSync('role', 'user') as string
        roleName = SessionService.sessionPreferences.getSync('roleName', '普通用户') as string
        accountId = SessionService.sessionPreferences.getSync('accountId', 0) as number
        if (email !== '') {
          InstanceRegistry.updateSession(activeInstance.instanceId, email, role, roleName, accountId)
        }
      }
    } catch (err) {
      console.error('initialize session preferences failed')
    }
    AppStorage.setOrCreate('authToken', token)
    AppStorage.setOrCreate('authEmail', email)
    AppStorage.setOrCreate('authRole', role)
    AppStorage.setOrCreate('authRoleName', roleName)
    AppStorage.setOrCreate('currentAccountId', accountId)
    AppStorage.setOrCreate('sessionRevision', 0)
    AppStorage.setOrCreate('instanceRevision', 0)
    SessionService.applyActiveInstanceStorage()
  }

  static saveSession(token: string, email: string, role: string, roleName: string, accountId: number): void {
    DraftService.flushActiveEditor()
    MailStatsStore.setOwner(email)
    AppStorage.set('authToken', token)
    AppStorage.set('authEmail', email)
    AppStorage.set('authRole', role)
    AppStorage.set('authRoleName', roleName)
    AppStorage.set('currentAccountId', accountId)
    const activeInstanceId: string = InstanceRegistry.getActiveInstanceId()
    SecureTokenStore.saveInstanceToken(activeInstanceId, token)
    InstanceRegistry.updateSession(activeInstanceId, email, role, roleName, accountId)
    SessionService.applyActiveInstanceStorage()
    SessionService.notifySessionChanged()
    if (SessionService.sessionPreferences === null) {
      return
    }
    try {
      SessionService.sessionPreferences.putSync('email', email)
      SessionService.sessionPreferences.putSync('role', role)
      SessionService.sessionPreferences.putSync('roleName', roleName)
      SessionService.sessionPreferences.putSync('accountId', accountId)
      SessionService.sessionPreferences.putSync('activeSessionCommitted', token !== '')
      SessionService.sessionPreferences.flushSync()
    } catch (err) {
      console.error('save session preferences failed')
    }
  }

  static clearSession(): void {
    SessionService.preserveDraftBeforeSignOut()
    MailDetailCache.clear()
    MailStatsStore.reset()
    AppStorage.set('authToken', '')
    AppStorage.set('authEmail', '')
    AppStorage.set('authRole', 'user')
    AppStorage.set('authRoleName', '普通用户')
    AppStorage.set('currentAccountId', 0)
    const activeInstanceId: string = InstanceRegistry.getActiveInstanceId()
    SecureTokenStore.removeInstanceToken(activeInstanceId)
    InstanceRegistry.updateSession(activeInstanceId, '', 'user', '普通用户', 0)
    SessionService.notifySessionChanged()
    if (SessionService.sessionPreferences === null) {
      return
    }
    try {
      SessionService.sessionPreferences.deleteSync('email')
      SessionService.sessionPreferences.deleteSync('role')
      SessionService.sessionPreferences.deleteSync('roleName')
      SessionService.sessionPreferences.deleteSync('accountId')
      SessionService.sessionPreferences.putSync('activeSessionCommitted', false)
      SessionService.sessionPreferences.flushSync()
    } catch (err) {
      console.error('clear session preferences failed')
    }
  }

  static clearAllSessions(): void {
    SessionService.preserveDraftBeforeSignOut()
    MailDetailCache.clear()
    const instances: MailInstance[] = InstanceRegistry.getInstances()
    for (let index = 0; index < instances.length; index++) {
      SecureTokenStore.removeInstanceToken(instances[index].instanceId)
      if (instances[index].instanceId === InstanceRegistry.getDefaultInstanceId()) {
        InstanceRegistry.updateSession(instances[index].instanceId, '', 'user', '普通用户', 0, 'MEMBER')
      } else {
        InstanceRegistry.remove(instances[index].instanceId)
      }
    }
    InstanceRegistry.setActiveInstance(InstanceRegistry.getDefaultInstanceId())
    MailStatsStore.reset()
    AppStorage.set('authToken', '')
    AppStorage.set('authEmail', '')
    AppStorage.set('authRole', 'user')
    AppStorage.set('authRoleName', '普通用户')
    AppStorage.set('currentAccountId', 0)
    SessionService.applyActiveInstanceStorage()
    SessionService.notifySessionChanged()
    SessionService.notifyInstanceChanged()
    if (SessionService.sessionPreferences === null) {
      return
    }
    try {
      SessionService.sessionPreferences.clearSync()
      SessionService.sessionPreferences.putSync('activeSessionCommitted', false)
      SessionService.sessionPreferences.flushSync()
    } catch (err) {
      console.error('clear all session preferences failed')
    }
  }

  static getToken(): string {
    const token: string | undefined = AppStorage.get('authToken') as string | undefined
    return token === undefined ? '' : token
  }

  static getApiBaseUrl(): string {
    const instance: MailInstance = InstanceRegistry.getActiveInstance()
    return instance.apiBaseUrl === '' ? Constants.API_URL : instance.apiBaseUrl
  }

  static getActiveInstanceId(): string {
    return InstanceRegistry.getActiveInstanceId()
  }

  static getActiveMailDomain(): string {
    const instance: MailInstance = InstanceRegistry.getActiveInstance()
    const email: string = instance.localEmail
    const separator: number = email.lastIndexOf('@')
    if (separator > 0 && separator < email.length - 1) {
      return email.substring(separator)
    }
    return Constants.MAIL_DOMAIN
  }

  static switchInstance(instanceId: string): boolean {
    const instance: MailInstance | null = InstanceRegistry.find(instanceId)
    const token: string = SecureTokenStore.getInstanceToken(instanceId)
    if (instance === null || token === '') {
      return false
    }
    // A rejected switch must leave the current mailbox, editor and cache untouched.
    DraftService.flushActiveEditor()
    if (!InstanceRegistry.setActiveInstance(instanceId)) {
      return false
    }
    MailDetailCache.clear()
    AppStorage.set('authToken', token)
    AppStorage.set('authEmail', instance.localEmail)
    AppStorage.set('authRole', instance.localRole)
    AppStorage.set('authRoleName', instance.localRoleName)
    AppStorage.set('currentAccountId', instance.accountId)
    MailStatsStore.setOwner(instance.localEmail)
    SessionService.persistActivation(true)
    SessionService.applyActiveInstanceStorage()
    SessionService.notifySessionChanged()
    SessionService.notifyInstanceChanged()
    return true
  }

  static saveInstanceSession(instance: MailInstance, token: string): void {
    InstanceRegistry.save(instance)
    SecureTokenStore.saveInstanceToken(instance.instanceId, token)
  }

  // Server-side account deletion affects one mailbox, not the other signed-in services.
  static clearMailboxSession(instanceId: string): boolean {
    const wasActive: boolean = InstanceRegistry.getActiveInstanceId() === instanceId
    if (wasActive) {
      SessionService.clearSession()
    } else {
      SecureTokenStore.removeInstanceToken(instanceId)
    }
    InstanceRegistry.updateSession(instanceId, '', 'user', '普通用户', 0, 'MEMBER')
    if (instanceId !== InstanceRegistry.getDefaultInstanceId()) {
      InstanceRegistry.remove(instanceId)
    }
    if (wasActive) {
      const instances: MailInstance[] = InstanceRegistry.getInstances()
      for (let index = 0; index < instances.length; index++) {
        if (SecureTokenStore.getInstanceToken(instances[index].instanceId) !== '' &&
          SessionService.switchInstance(instances[index].instanceId)) {
          return true
        }
      }
      InstanceRegistry.setActiveInstance(InstanceRegistry.getDefaultInstanceId())
      SessionService.applyActiveSession()
    } else {
      SessionService.applyActiveInstanceStorage()
      SessionService.notifyInstanceChanged()
    }
    return SessionService.getToken() !== ''
  }

  static removeInstanceSession(instanceId: string): boolean {
    if (instanceId === InstanceRegistry.getDefaultInstanceId()) {
      return false
    }
    const wasActive: boolean = InstanceRegistry.getActiveInstanceId() === instanceId
    if (wasActive) {
      DraftService.flushActiveEditor()
      MailDetailCache.clear()
    }
    SecureTokenStore.removeInstanceToken(instanceId)
    const removed: boolean = InstanceRegistry.remove(instanceId)
    if (removed) {
      if (wasActive) {
        SessionService.applyActiveSession()
      } else {
        SessionService.applyActiveInstanceStorage()
        SessionService.notifyInstanceChanged()
      }
    }
    return removed
  }

  static synchronizeInstanceMetadata(instances: PlatformInstance[]): void {
    let changed: boolean = false
    for (let index = 0; index < instances.length; index++) {
      if (InstanceRegistry.updateMetadata(
        instances[index].instanceId,
        instances[index].displayName,
        instances[index].apiBaseUrl,
        instances[index].originHost)) {
        changed = true
      }
    }
    if (changed) {
      SessionService.applyActiveInstanceStorage()
      SessionService.notifyInstanceChanged()
    }
  }

  static updateInstanceMetadata(instanceId: string, displayName: string): void {
    if (!InstanceRegistry.updateMetadata(instanceId, displayName)) {
      return
    }
    SessionService.applyActiveInstanceStorage()
    SessionService.notifyInstanceChanged()
  }

  static getInstanceToken(instanceId: string): string {
    return SecureTokenStore.getInstanceToken(instanceId)
  }

  private static notifySessionChanged(): void {
    const revision: number | undefined = AppStorage.get('sessionRevision') as number | undefined
    AppStorage.set('sessionRevision', revision === undefined ? 1 : revision + 1)
  }

  private static preserveDraftBeforeSignOut(): void {
    try {
      DraftService.flushActiveEditor()
    } catch (err) {
      // The editor reports the failed save. An expired/revoked session must still be cleared.
      console.error('could not flush draft before signing out')
    }
  }

  private static applyActiveSession(): void {
    const instance: MailInstance = InstanceRegistry.getActiveInstance()
    const token: string = SecureTokenStore.getInstanceToken(instance.instanceId)
    AppStorage.set('authToken', token)
    AppStorage.set('authEmail', instance.localEmail)
    AppStorage.set('authRole', instance.localRole)
    AppStorage.set('authRoleName', instance.localRoleName)
    AppStorage.set('currentAccountId', instance.accountId)
    MailStatsStore.setOwner(instance.localEmail)
    SessionService.persistActivation(token !== '')
    SessionService.applyActiveInstanceStorage()
    SessionService.notifySessionChanged()
    SessionService.notifyInstanceChanged()
  }

  private static persistActivation(committed: boolean): void {
    if (SessionService.sessionPreferences === null) {
      return
    }
    try {
      SessionService.sessionPreferences.putSync('activeSessionCommitted', committed)
      SessionService.sessionPreferences.flushSync()
    } catch (err) {
      console.error('save mailbox activation state failed')
    }
  }

  private static notifyInstanceChanged(): void {
    const revision: number | undefined = AppStorage.get('instanceRevision') as number | undefined
    AppStorage.set('instanceRevision', revision === undefined ? 1 : revision + 1)
  }

  private static applyActiveInstanceStorage(): void {
    const instance: MailInstance = InstanceRegistry.getActiveInstance()
    AppStorage.setOrCreate('activeInstanceId', instance.instanceId)
    AppStorage.setOrCreate('activeInstanceName', instance.displayName)
    AppStorage.setOrCreate('activeInstanceApiBaseUrl', instance.apiBaseUrl)
    AppStorage.set('activeInstanceId', instance.instanceId)
    AppStorage.set('activeInstanceName', instance.displayName)
    AppStorage.set('activeInstanceApiBaseUrl', instance.apiBaseUrl)
  }
}

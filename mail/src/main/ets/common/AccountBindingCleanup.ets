import { preferences } from '@kit.ArkData'
import { ApiException } from './HttpClient'
import { InstanceService } from './InstanceService'
import { PlatformSessionService } from './PlatformSessionService'

class PendingBindingCleanup {
  huaweiUserId: string = ''
  instanceId: string = ''
  email: string = ''
  bindingId: number = 0
  verifiedTime: string = ''

  constructor(huaweiUserId: string = '', instanceId: string = '', email: string = '',
    bindingId: number = 0, verifiedTime: string = '') {
    this.huaweiUserId = huaweiUserId
    this.instanceId = instanceId
    this.email = email
    this.bindingId = bindingId
    this.verifiedTime = verifiedTime
  }
}

// Only identity and binding-match metadata are persisted. No credentials are retained.
export class AccountBindingCleanup {
  private static store: preferences.Preferences | null = null
  private static pending: PendingBindingCleanup[] = []
  private static syncing: boolean = false

  static initialize(context: Context): void {
    if (AccountBindingCleanup.store !== null) { return }
    try {
      AccountBindingCleanup.store = preferences.getPreferencesSync(context, { name: 'cloud_mail_binding_cleanup' })
      const source: string = AccountBindingCleanup.store.getSync('pending', '[]') as string
      const entries: PendingBindingCleanup[] = JSON.parse(source) as PendingBindingCleanup[]
      if (Array.isArray(entries)) {
        AccountBindingCleanup.pending = entries.filter((entry: PendingBindingCleanup): boolean =>
          entry !== null && typeof entry.huaweiUserId === 'string' && entry.huaweiUserId !== '' &&
          typeof entry.instanceId === 'string' && entry.instanceId !== '' &&
          typeof entry.email === 'string' && entry.email !== '' &&
          typeof entry.bindingId === 'number' && entry.bindingId > 0 &&
          typeof entry.verifiedTime === 'string' && entry.verifiedTime !== '')
      }
    } catch (err) {
      AccountBindingCleanup.store = null
      console.error('initialize binding cleanup failed')
    }
  }

  static requireReady(): void {
    if (AccountBindingCleanup.store === null) {
      throw new ApiException(-1, '暂时无法保存账户删除后的同步进度，请重试', false)
    }
    try {
      // Fail before the irreversible mailbox request if storage is already unavailable.
      AccountBindingCleanup.store.putSync('pending', JSON.stringify(AccountBindingCleanup.pending))
      AccountBindingCleanup.store.flushSync()
    } catch (err) {
      throw new ApiException(-1, '暂时无法保存账户删除后的同步进度，请重试', false)
    }
  }

  static enqueue(huaweiUserId: string, instanceId: string, email: string,
    bindingId: number, verifiedTime: string): void {
    if (huaweiUserId === '' || instanceId === '' || email === '' || bindingId <= 0 || verifiedTime === '') { return }
    const exists: boolean = AccountBindingCleanup.pending.some((entry: PendingBindingCleanup): boolean =>
      entry.huaweiUserId === huaweiUserId && entry.instanceId === instanceId &&
      entry.bindingId === bindingId && entry.verifiedTime === verifiedTime)
    if (!exists) {
      AccountBindingCleanup.pending.push(new PendingBindingCleanup(huaweiUserId, instanceId, email,
        bindingId, verifiedTime))
    }
    AccountBindingCleanup.persist()
  }

  static cancel(huaweiUserId: string, instanceId: string): void {
    AccountBindingCleanup.pending = AccountBindingCleanup.pending.filter((entry: PendingBindingCleanup): boolean =>
      entry.huaweiUserId !== huaweiUserId || entry.instanceId !== instanceId)
    AccountBindingCleanup.persist()
  }

  static pendingCount(): number {
    const identity: string = PlatformSessionService.getHuaweiUserId()
    return AccountBindingCleanup.pending.filter((entry: PendingBindingCleanup): boolean =>
      entry.huaweiUserId === identity).length
  }

  static async retry(): Promise<boolean> {
    const identity: string = PlatformSessionService.getHuaweiUserId()
    if (identity === '' || AccountBindingCleanup.syncing) { return AccountBindingCleanup.pendingCount() === 0 }
    AccountBindingCleanup.syncing = true
    try {
      const entries: PendingBindingCleanup[] = AccountBindingCleanup.pending.slice()
      for (let index = 0; index < entries.length; index++) {
        const entry: PendingBindingCleanup = entries[index]
        if (entry.huaweiUserId !== identity) { continue }
        if (PlatformSessionService.getHuaweiUserId() !== identity) { return false }
        await InstanceService.unlinkMyBinding(entry.instanceId, identity, entry.email, entry.bindingId, entry.verifiedTime)
        if (PlatformSessionService.getHuaweiUserId() !== identity) { return false }
        AccountBindingCleanup.pending = AccountBindingCleanup.pending.filter((candidate: PendingBindingCleanup): boolean =>
          candidate.huaweiUserId !== identity || candidate.instanceId !== entry.instanceId ||
          candidate.bindingId !== entry.bindingId || candidate.verifiedTime !== entry.verifiedTime)
        AccountBindingCleanup.persist()
      }
      return AccountBindingCleanup.pendingCount() === 0
    } catch (err) {
      return false
    } finally {
      AccountBindingCleanup.syncing = false
    }
  }

  private static persist(): void {
    try {
      if (AccountBindingCleanup.store !== null) {
        AccountBindingCleanup.store.putSync('pending', JSON.stringify(AccountBindingCleanup.pending))
        AccountBindingCleanup.store.flushSync()
      }
    } catch (err) {
      // Keep the in-memory retry item even if persistence temporarily fails.
      console.error('persist binding cleanup failed')
    }
  }
}

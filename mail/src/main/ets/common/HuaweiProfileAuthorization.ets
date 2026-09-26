import { preferences } from '@kit.ArkData'

// A profile-authorization hint, never a login credential or proof of identity.
// Every login still exchanges a fresh native authorization code on the server.
export default class HuaweiProfileAuthorization {
  private static readonly MAX_AGE_MS: number = 24 * 60 * 60 * 1000
  private static store: preferences.Preferences | null = null
  private static identity: string = ''
  private static authorizedAt: number = 0

  static initialize(context: Context): void {
    HuaweiProfileAuthorization.store = null
    HuaweiProfileAuthorization.identity = ''
    HuaweiProfileAuthorization.authorizedAt = 0
    try {
      const store: preferences.Preferences = preferences.getPreferencesSync(context,
        { name: 'cloud_mail_profile_authorization' })
      HuaweiProfileAuthorization.store = store
      HuaweiProfileAuthorization.identity = store.getSync('identity', '') as string
      HuaweiProfileAuthorization.authorizedAt = store.getSync('authorizedAt', 0) as number
    } catch (error) {
      // Storage failure only means requesting profile authorization again.
      console.warn('Profile authorization hint unavailable')
    }
  }

  static needsAuthorization(nativeIdentity: string): boolean {
    const age: number = Date.now() - HuaweiProfileAuthorization.authorizedAt
    return nativeIdentity === '' || nativeIdentity !== HuaweiProfileAuthorization.identity ||
      !Number.isFinite(age) || !Number.isFinite(HuaweiProfileAuthorization.authorizedAt) ||
      HuaweiProfileAuthorization.authorizedAt <= 0 ||
      age < 0 || age >= HuaweiProfileAuthorization.MAX_AGE_MS
  }

  // Call only after a successful profile SDK response AND successful server login.
  static remember(profileIdentity: string, verifiedIdentity: string, nickName: string, avatarUrl: string): void {
    if (profileIdentity === '' || profileIdentity !== verifiedIdentity || nickName === '' || avatarUrl === '') {
      return
    }
    HuaweiProfileAuthorization.identity = verifiedIdentity
    HuaweiProfileAuthorization.authorizedAt = Date.now()
    if (HuaweiProfileAuthorization.store === null) {
      return
    }
    try {
      HuaweiProfileAuthorization.store.putSync('identity', verifiedIdentity)
      HuaweiProfileAuthorization.store.putSync('authorizedAt', HuaweiProfileAuthorization.authorizedAt)
      HuaweiProfileAuthorization.store.flushSync()
    } catch (error) {
      console.warn('Profile authorization hint could not be saved')
    }
  }
}

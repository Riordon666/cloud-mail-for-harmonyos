import { hilog } from '@kit.PerformanceAnalysisKit'
import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit'
import { preferences } from '@kit.ArkData'

const DOMAIN = 0x0000
const PREF_NAME = 'cloud_mail_prefs'

export default class MailBackupAbility extends BackupExtensionAbility {
  async onBackup(): Promise<void> {
    hilog.info(DOMAIN, 'MailBackup', 'onBackup start')
    try {
      const context = this.context
      const prefs = await preferences.getPreferences(context, PREF_NAME)
      await prefs.flush()
      hilog.info(DOMAIN, 'MailBackup', 'onBackup ok - preferences flushed')
    } catch (err) {
      hilog.error(DOMAIN, 'MailBackup', 'onBackup failed: %{public}s', JSON.stringify(err))
    }
  }

  async onRestore(bundleVersion: BundleVersion): Promise<void> {
    hilog.info(DOMAIN, 'MailBackup', 'onRestore start, version: %{public}s', JSON.stringify(bundleVersion))
    try {
      const context = this.context
      const prefs = await preferences.getPreferences(context, PREF_NAME)
      await prefs.flush()
      hilog.info(DOMAIN, 'MailBackup', 'onRestore ok')
    } catch (err) {
      hilog.error(DOMAIN, 'MailBackup', 'onRestore failed: %{public}s', JSON.stringify(err))
    }
  }
}
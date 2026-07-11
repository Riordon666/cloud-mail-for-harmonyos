import { pushService } from '@kit.PushKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'PushService'

export class PushService {
  static async initPush(): Promise<void> {
    try {
      await pushService.init()
      hilog.info(DOMAIN, TAG, 'Push service initialized')
      await PushService.getToken()
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Push init failed: %{public}s', JSON.stringify(err))
    }
  }

  static async getToken(): Promise<string> {
    try {
      const token: string = await pushService.getToken()
      hilog.info(DOMAIN, TAG, 'Push token: %{public}s', token)
      return token
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Get push token failed: %{public}s', JSON.stringify(err))
      return ''
    }
  }

  static async deleteToken(): Promise<void> {
    try {
      await pushService.deleteToken()
      hilog.info(DOMAIN, TAG, 'Push token deleted')
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Delete push token failed: %{public}s', JSON.stringify(err))
    }
  }

  static async turnOnPush(): Promise<void> {
    try {
      await pushService.turnOnPush()
      hilog.info(DOMAIN, TAG, 'Push turned on')
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Turn on push failed: %{public}s', JSON.stringify(err))
    }
  }

  static async turnOffPush(): Promise<void> {
    try {
      await pushService.turnOffPush()
      hilog.info(DOMAIN, TAG, 'Push turned off')
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Turn off push failed: %{public}s', JSON.stringify(err))
    }
  }
}
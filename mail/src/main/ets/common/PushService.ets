import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'PushService'

export class PushService {
  static async initPush(): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, 'Push service initialized')
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Push init failed')
    }
  }
}
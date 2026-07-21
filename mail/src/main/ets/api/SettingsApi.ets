import { ApiException, ApiResponse, HttpClient } from '../common/HttpClient'

class WebsiteConfigPayload {
  register: number = 1
  title: string = 'Cloud Mail'
  regKey: number = 1
  registerVerify: number = 1
  regVerifyOpen: boolean = false
  minEmailPrefix: number = 1
  r2Domain: string | null = null
}

export class WebsiteConfig {
  title: string
  registrationEnabled: boolean
  registrationCodeRequired: boolean
  registrationVerificationRequired: boolean
  minEmailPrefix: number
  r2Domain: string

  constructor(title: string, registrationEnabled: boolean, registrationCodeRequired: boolean,
    registrationVerificationRequired: boolean, minEmailPrefix: number, r2Domain: string) {
    this.title = title
    this.registrationEnabled = registrationEnabled
    this.registrationCodeRequired = registrationCodeRequired
    this.registrationVerificationRequired = registrationVerificationRequired
    this.minEmailPrefix = minEmailPrefix
    this.r2Domain = r2Domain
  }
}

export class SettingsApi {
  static async getWebsiteConfig(): Promise<WebsiteConfig> {
    const response: ApiResponse = await HttpClient.get('/setting/websiteConfig', false)
    if (response.data === null) {
      throw new ApiException(-1, '服务器未返回网站配置', false)
    }
    const payload: WebsiteConfigPayload = response.data as WebsiteConfigPayload
    return new WebsiteConfig(payload.title, payload.register === 0, payload.regKey === 0,
      payload.registerVerify === 0 || (payload.registerVerify === 2 && payload.regVerifyOpen), payload.minEmailPrefix,
      payload.r2Domain === null ? '' : payload.r2Domain)
  }
}

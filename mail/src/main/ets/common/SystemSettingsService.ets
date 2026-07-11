import { ApiException, ApiResponse, HttpClient } from './HttpClient'

class SystemSettingPayload {
  title: string = 'Cloud Mail'
  register: number = 0
  addEmail: number = 0
  manyEmail: number = 0
}

class SystemSettingRequest {
  title: string
  register: number
  addEmail: number
  manyEmail: number

  constructor(title: string, registrationEnabled: boolean, addEmailEnabled: boolean, manyEmailEnabled: boolean) {
    this.title = title
    this.register = registrationEnabled ? 0 : 1
    this.addEmail = addEmailEnabled ? 0 : 1
    this.manyEmail = manyEmailEnabled ? 0 : 1
  }
}

export class SystemSettings {
  siteTitle: string
  registrationEnabled: boolean
  addEmailEnabled: boolean
  manyEmailEnabled: boolean

  constructor(siteTitle: string, registrationEnabled: boolean, addEmailEnabled: boolean, manyEmailEnabled: boolean) {
    this.siteTitle = siteTitle
    this.registrationEnabled = registrationEnabled
    this.addEmailEnabled = addEmailEnabled
    this.manyEmailEnabled = manyEmailEnabled
  }
}

export class SystemSettingsService {
  private static settings: SystemSettings = new SystemSettings('Cloud Mail', true, true, true)

  static initialize(context: Context): void {
    SystemSettingsService.publishSettings()
  }

  static async getSettings(): Promise<SystemSettings> {
    const response: ApiResponse = await HttpClient.get('/setting/query')
    if (response.data === null) {
      throw new ApiException(-1, '服务器未返回系统设置', false)
    }
    const payload: SystemSettingPayload = response.data as SystemSettingPayload
    SystemSettingsService.settings = new SystemSettings(payload.title, payload.register === 0, payload.addEmail === 0,
      payload.manyEmail === 0)
    SystemSettingsService.publishSettings()
    return new SystemSettings(SystemSettingsService.settings.siteTitle, SystemSettingsService.settings.registrationEnabled,
      SystemSettingsService.settings.addEmailEnabled, SystemSettingsService.settings.manyEmailEnabled)
  }

  static async save(settings: SystemSettings): Promise<void> {
    const request: SystemSettingRequest = new SystemSettingRequest(settings.siteTitle, settings.registrationEnabled,
      settings.addEmailEnabled, settings.manyEmailEnabled)
    await HttpClient.put('/setting/set', JSON.stringify(request))
    SystemSettingsService.settings = new SystemSettings(settings.siteTitle, settings.registrationEnabled,
      settings.addEmailEnabled, settings.manyEmailEnabled)
    SystemSettingsService.publishSettings()
  }

  private static publishSettings(): void {
    AppStorage.setOrCreate('siteTitle', SystemSettingsService.settings.siteTitle)
    AppStorage.setOrCreate('registrationEnabled', SystemSettingsService.settings.registrationEnabled)
    AppStorage.setOrCreate('addEmailEnabled', SystemSettingsService.settings.addEmailEnabled)
    AppStorage.setOrCreate('manyEmailEnabled', SystemSettingsService.settings.manyEmailEnabled)
    AppStorage.set('siteTitle', SystemSettingsService.settings.siteTitle)
    AppStorage.set('registrationEnabled', SystemSettingsService.settings.registrationEnabled)
    AppStorage.set('addEmailEnabled', SystemSettingsService.settings.addEmailEnabled)
    AppStorage.set('manyEmailEnabled', SystemSettingsService.settings.manyEmailEnabled)
  }
}

import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'
import { preferences } from '@kit.ArkData'
import { AuthService } from '../common/AuthService'
import { SystemSettingsService } from '../common/SystemSettingsService'
import { AdminService } from '../common/AdminService'
import { DraftService } from '../common/DraftService'

const PREF_NAME: string = 'cloud_mail_settings'

let appContext: Context | null = null

export function setAppContext(ctx: Context): void {
  appContext = ctx
}

export default class MailAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    setAppContext(this.context)
    this.applySavedColorMode()
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    AuthService.initialize(this.context)
    SystemSettingsService.initialize(this.context)
    DraftService.initialize(this.context)
    AdminService.initialize()
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        console.error('loadContent failed: ' + JSON.stringify(err))
      }
    })
  }

  private async applySavedColorMode(): Promise<void> {
    try {
      const dataPref = await preferences.getPreferences(this.context, PREF_NAME)
      const mode = dataPref.getSync('colorMode', -1) as number
      if (mode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT ||
        mode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
        this.context.getApplicationContext().setColorMode(mode)
      } else {
        this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
      }
      AppStorage.setOrCreate('currentColorMode', mode)
    } catch (err) {
      try {
        this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
      } catch (e) {
        console.error('setColorMode failed')
      }
      AppStorage.setOrCreate('currentColorMode', ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
    }
  }

  onWindowStageDestroy(): void {}
  onForeground(): void {}
  onBackground(): void {}
  onDestroy(): void {}
}

export async function setAppColorMode(mode: number): Promise<void> {
  if (appContext === null) {
    return
  }
  try {
    const dataPref = await preferences.getPreferences(appContext, PREF_NAME)
    await dataPref.put('colorMode', mode)
    await dataPref.flush()
    appContext.getApplicationContext().setColorMode(mode)
    AppStorage.set('currentColorMode', mode)
  } catch (err) {
    console.error('setAppColorMode failed: ' + JSON.stringify(err))
  }
}
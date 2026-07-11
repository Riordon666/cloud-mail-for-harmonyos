import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'
import { AuthService } from '../common/AuthService'
import { SystemSettingsService } from '../common/SystemSettingsService'
import { AdminService } from '../common/AdminService'
import { DraftService } from '../common/DraftService'

export default class MailAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
    } catch (err) {
      console.error('setColorMode failed: ' + JSON.stringify(err))
    }
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

  onWindowStageDestroy(): void {}
  onForeground(): void {}
  onBackground(): void {}
  onDestroy(): void {}
}

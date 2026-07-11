import { PromptAction } from '@kit.ArkUI'
import { HdsNavDestination, HdsNavDestinationTitleMode } from '@kit.UIDesignKit'
import Constants from '../common/Constants'
import { ApiException } from '../common/HttpClient'
import { SystemSettings, SystemSettingsService } from '../common/SystemSettingsService'
import { EmptyState } from '../components/EmptyState'

@Component
export struct SystemSettingsPage {
  @StorageLink('authRole') authRole: string = 'user'
  @State siteTitle: string = ''
  @State registrationEnabled: boolean = true
  @State addEmailEnabled: boolean = true
  @State manyEmailEnabled: boolean = true
  @State isSaving: boolean = false
  private toast: PromptAction = this.getUIContext().getPromptAction()

  aboutToAppear(): void {
    this.loadSettings()
  }

  build() {
    HdsNavDestination() {
      if (this.authRole !== 'admin') {
        EmptyState({ icon: $r('sys.symbol.person'), message: '仅管理员可访问系统设置' })
      } else {
        Stack({ alignContent: Alignment.TopStart }) {
          Scroll() {
          Column({ space: Constants.GAP_MEDIUM }) {
            Text('系统设置')
              .fontSize(Constants.FONT_SIZE_TITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .width('100%')

            Text('保存到服务端，并立即应用于登录与副邮箱注册流程。')
              .fontSize(Constants.FONT_SIZE_COMMON)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')

            Column({ space: Constants.GAP_MEDIUM }) {
              Text('网站标题')
                .fontSize(Constants.FONT_SIZE_SUBTITLE)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
              TextInput({ placeholder: 'Cloud Mail', text: this.siteTitle })
                .height(48)
                .fontColor($r('app.color.text_primary'))
                .placeholderColor($r('app.color.text_tertiary'))
                .backgroundColor($r('app.color.background'))
                .border({ width: 0.5, color: $r('app.color.divider') })
                .borderRadius(Constants.RADIUS_SMALL)
                .padding({ left: Constants.PADDING_INNER, right: Constants.PADDING_INNER })
                .onChange((value: string) => { this.siteTitle = value })

              Row() {
                Column() {
                  Text('开放注册')
                    .fontSize(Constants.FONT_SIZE_SUBTITLE)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))
                  Text('关闭后，登录页不再显示注册入口。')
                    .fontSize(Constants.FONT_SIZE_SMALL)
                    .fontColor($r('app.color.text_secondary'))
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                Toggle({ type: ToggleType.Switch, isOn: this.registrationEnabled })
                  .selectedColor($r('app.color.primary'))
                  .onChange((enabled: boolean) => { this.registrationEnabled = enabled })
              }
              .width('100%')

              Row() {
                Column() {
                  Text('允许注册副邮箱')
                    .fontSize(Constants.FONT_SIZE_SUBTITLE)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))
                  Text('关闭后，用户无法添加副邮箱地址。')
                    .fontSize(Constants.FONT_SIZE_SMALL)
                    .fontColor($r('app.color.text_secondary'))
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                Toggle({ type: ToggleType.Switch, isOn: this.addEmailEnabled })
                  .selectedColor($r('app.color.primary'))
                  .onChange((enabled: boolean) => { this.addEmailEnabled = enabled })
              }
              .width('100%')

              Row() {
                Column() {
                  Text('允许多个副邮箱')
                    .fontSize(Constants.FONT_SIZE_SUBTITLE)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))
                  Text('关闭后，每个主邮箱仅允许一个副邮箱。')
                    .fontSize(Constants.FONT_SIZE_SMALL)
                    .fontColor($r('app.color.text_secondary'))
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                Toggle({ type: ToggleType.Switch, isOn: this.manyEmailEnabled })
                  .selectedColor($r('app.color.primary'))
                  .onChange((enabled: boolean) => { this.manyEmailEnabled = enabled })
              }
              .width('100%')

              Button(this.isSaving ? '保存中...' : '保存设置', { type: ButtonType.Capsule, stateEffect: true })
                .width('100%')
                .height(48)
                .fontSize(Constants.FONT_SIZE_SUBTITLE)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('sys.color.icon_on_primary'))
                .backgroundColor($r('app.color.primary'))
                .margin({ top: 8 })
                .enabled(!this.isSaving)
                .onClick(() => { this.saveSettings() })
            }
            .width('100%')
            .padding(Constants.PADDING_EDGE)
            .backgroundColor($r('app.color.card'))
            .borderRadius(Constants.RADIUS_CARD)
            .shadow(Constants.SHADOW_CARD)

            Blank().height(24)
          }
          .width('100%')
          .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 16, bottom: 24 })
          }
          .width('100%')
          .height('100%')
          .align(Alignment.TopStart)
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .height('100%')
      }
    }
    .titleBar({ content: { title: { mainTitle: '系统设置' } }, enableComponentSafeArea: true })
    .hideBackButton(false)
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  private async loadSettings(): Promise<void> {
    try {
      const settings: SystemSettings = await SystemSettingsService.getSettings()
      this.siteTitle = settings.siteTitle
      this.registrationEnabled = settings.registrationEnabled
      this.addEmailEnabled = settings.addEmailEnabled
      this.manyEmailEnabled = settings.manyEmailEnabled
    } catch (err) {
      if (err instanceof ApiException) {
        this.showToast(err.message)
      } else {
        this.showToast('加载系统设置失败')
      }
    }
  }

  private async saveSettings(): Promise<void> {
    const title: string = this.siteTitle.trim()
    if (title === '') {
      this.showToast('网站标题不能为空')
      return
    }
    this.isSaving = true
    try {
      await SystemSettingsService.save(new SystemSettings(title, this.registrationEnabled, this.addEmailEnabled, this.manyEmailEnabled))
      this.showToast('系统设置已保存')
    } catch (err) {
      if (err instanceof ApiException) {
        this.showToast(err.message)
      } else {
        this.showToast('保存系统设置失败')
      }
    } finally {
      this.isSaving = false
    }
  }

  private showToast(message: string): void {
    try {
      this.toast.openToast({ message: message, duration: 1500 })
    } catch (err) {
      console.error('openToast failed')
    }
  }
}
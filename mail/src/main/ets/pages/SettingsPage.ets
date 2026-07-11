import { PromptAction } from '@kit.ArkUI'
import Constants from '../common/Constants'
import { AvatarBar } from '../components/AvatarBar'

@Component
export struct SettingsPage {
  @StorageLink('authEmail') authEmail: string = ''
  @StorageLink('authRole') authRole: string = 'user'
  @State showLogoutConfirm: boolean = false
  private toast: PromptAction = this.getUIContext().getPromptAction()
  onLogout?: () => void
  onManageAccounts?: () => void
  onSystemSettings?: () => void
  onManageUsers?: () => void
  onManageGlobalMails?: () => void
  onManageRoles?: () => void
  onOpenAnalytics?: () => void
  onManageRegistrationCodes?: () => void

  build() {
    Stack() {
      Column() {
        Text('个人设置')
          .fontSize(Constants.FONT_SIZE_HERO)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 16, bottom: 16 })
          .width('100%')

        Column() {
          AvatarBar({ name: this.authEmail === '' ? 'admin@riordon.xyz' : this.authEmail, avatarSize: 72, fontSize: 32 })
            .margin({ bottom: 16 })
          Text(this.authEmail === '' ? 'admin@riordon.xyz' : this.authEmail)
            .fontSize(Constants.FONT_SIZE_TITLE)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text(this.authRole === 'admin' ? '管理员' : '普通用户')
            .fontSize(Constants.FONT_SIZE_SMALL)
            .fontColor($r('app.color.tag_text'))
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .borderRadius(Constants.RADIUS_SMALL)
            .backgroundColor(this.authRole === 'admin' ? $r('app.color.primary_light') : $r('app.color.info'))
            .margin({ top: 8 })
        }
        .width('100%')
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 16, bottom: 28 })
        .alignItems(HorizontalAlign.Center)

        List() {
          ListItem() { this.MenuItem('账号管理', '', () => { this.openAccountManagement() }) }
          ListItem() { this.MenuItem('外观设置', '跟随系统', () => { this.showToast('主题切换将在 F13 阶段开放') }) }
          ListItem() { this.MenuItem('通知设置', '', () => { this.showToast('通知设置将在后续阶段开放') }) }
          ListItem() { this.MenuItem('隐私政策', '', () => { this.showToast('隐私政策页面将在后续阶段开放') }) }
          ListItem() { this.MenuItem('关于', 'v1.0.0', () => { this.showToast('Cloud Mail for HarmonyOS') }) }

          if (this.authRole === 'admin') {
            ListItem() {
              Text('管理员功能')
                .fontSize(Constants.FONT_SIZE_SMALL)
                .fontColor($r('app.color.text_tertiary'))
                .fontWeight(FontWeight.Medium)
                .padding({ left: Constants.PADDING_EDGE, top: 16, bottom: 6 })
                .width('100%')
            }

            ListItem() { this.MenuItem('系统设置', '', () => { this.openSystemSettings() }) }
            ListItem() { this.MenuItem('用户管理', '', () => { this.openUserManagement() }) }
            ListItem() { this.MenuItem('全部邮件', '', () => { this.openGlobalMailManagement() }) }
            ListItem() { this.MenuItem('角色权限', '', () => { this.openRoleManagement() }) }
            ListItem() { this.MenuItem('数据分析', '', () => { this.openAnalytics() }) }
            ListItem() { this.MenuItem('注册码管理', '', () => { this.openRegistrationCodeManagement() }) }
          }

          ListItem() {
            Row() {
              Text('退出登录')
                .fontSize(Constants.FONT_SIZE_SUBTITLE)
                .fontColor($r('app.color.danger'))
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ top: 28, bottom: 8 })
            .onClick(() => { this.showLogoutConfirm = true })
          }
          ListItem() {
            Column().height(Constants.PADDING_TAB_CONTENT_BOTTOM)
          }
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.card'))
        .borderRadius({ topLeft: 20, topRight: 20 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background'))

      if (this.showLogoutConfirm) {
        this.LogoutConfirmDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private LogoutConfirmDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.overlay'))

      Column({ space: Constants.GAP_MEDIUM }) {
        Text('确认退出登录')
          .fontSize(Constants.FONT_SIZE_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        Text('退出后需要重新输入邮箱账号和密码才能进入邮箱。')
          .fontSize(Constants.FONT_SIZE_COMMON)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
        Row() {
          Button('取消', { type: ButtonType.Normal, stateEffect: true })
            .layoutWeight(1)
            .height(44)
            .fontColor($r('app.color.text_primary'))
            .backgroundColor($r('app.color.background'))
            .onClick(() => { this.showLogoutConfirm = false })
          Button('退出登录', { type: ButtonType.Normal, stateEffect: true })
            .layoutWeight(1)
            .height(44)
            .fontColor($r('sys.color.icon_on_primary'))
            .backgroundColor($r('app.color.danger'))
            .margin({ left: Constants.GAP_MEDIUM })
            .onClick(() => { this.confirmLogout() })
        }
        .width('100%')
      }
      .width('100%')
      .margin({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
      .padding(20)
      .backgroundColor($r('app.color.card'))
      .borderRadius(Constants.RADIUS_CARD)
      .shadow(Constants.SHADOW_CARD)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  MenuItem(title: string, value: string, onItemClick?: () => void) {
    Row() {
      Text(title)
        .fontSize(Constants.FONT_SIZE_SUBTITLE)
        .fontColor($r('app.color.text_primary'))
      Blank()
      if (value !== '') {
        Text(value)
          .fontSize(Constants.FONT_SIZE_COMMON)
          .fontColor($r('app.color.text_tertiary'))
          .margin({ right: 8 })
      }
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(Constants.SIZE_ICON_SMALL)
        .fontColor([$r('app.color.text_tertiary')])
    }
    .width('100%')
    .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 16, bottom: 16 })
    .onClick(() => {
      if (onItemClick) {
        onItemClick()
      }
    })
  }

  private openAccountManagement(): void {
    if (this.onManageAccounts) {
      this.onManageAccounts()
    }
  }

  private openSystemSettings(): void {
    if (this.onSystemSettings) {
      this.onSystemSettings()
    }
  }

  private openUserManagement(): void {
    if (this.onManageUsers) {
      this.onManageUsers()
    }
  }

  private openGlobalMailManagement(): void {
    if (this.onManageGlobalMails) {
      this.onManageGlobalMails()
    }
  }

  private openRoleManagement(): void {
    if (this.onManageRoles) {
      this.onManageRoles()
    }
  }

  private openAnalytics(): void {
    if (this.onOpenAnalytics) {
      this.onOpenAnalytics()
    }
  }

  private openRegistrationCodeManagement(): void {
    if (this.onManageRegistrationCodes) {
      this.onManageRegistrationCodes()
    }
  }

  private confirmLogout(): void {
    this.showLogoutConfirm = false
    if (this.onLogout) {
      this.onLogout()
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

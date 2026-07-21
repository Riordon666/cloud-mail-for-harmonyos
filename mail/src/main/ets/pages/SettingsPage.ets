import { PromptAction } from '@kit.ArkUI'
import { bundleManager, common, ConfigurationConstant } from '@kit.AbilityKit'
import { HdsListItemCard, IconSize, PrefixIcon, SuffixTextAndArrow } from '@kit.UIDesignKit'
import Constants from '../common/Constants'
import { AvatarBar } from '../components/AvatarBar'
import { setAppColorMode } from '../mailability/MailAbility'

@Component
export struct SettingsPage {
  @StorageLink('authEmail') authEmail: string = ''
  @StorageLink('authRole') authRole: string = 'user'
  @StorageLink('authRoleName') authRoleName: string = '普通用户'
  @StorageLink('currentColorMode') currentColorMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
  @State showLogoutConfirm: boolean = false
  @State showThemeDialog: boolean = false
  private toast: PromptAction = this.getUIContext().getPromptAction()
  onLogout?: () => void
  onManageAccounts?: () => void
  onSystemSettings?: () => void
  onManageUsers?: () => void
  onManageGlobalMails?: () => void
  onManageRoles?: () => void
  onOpenAnalytics?: () => void
  onManageRegistrationCodes?: () => void

  aboutToAppear(): void {
    if (this.currentColorMode === undefined || this.currentColorMode === null) {
      this.currentColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
    }
  }

  build() {
    Stack() {
      Scroll() {
        Column({ space: Constants.GAP_MEDIUM }) {
          Text('个人设置')
            .fontSize(Constants.FONT_SIZE_HERO)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .width('100%')

          Row({ space: Constants.GAP_MEDIUM }) {
            AvatarBar({
              name: this.authEmail === '' ? 'admin@riordon.xyz' : this.authEmail,
              avatarSize: 64,
              fontSize: 28
            })
            Column({ space: 6 }) {
              Text(this.authEmail === '' ? 'admin@riordon.xyz' : this.authEmail)
                .fontSize(Constants.FONT_SIZE_SUBTITLE)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Row({ space: Constants.GAP_SMALL }) {
                Text(this.getRoleLabel())
                  .fontSize(Constants.FONT_SIZE_SMALL)
                  .fontColor($r('app.color.tag_text'))
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .borderRadius(Constants.RADIUS_SMALL)
                  .backgroundColor(this.authRole === 'admin' ? $r('app.color.primary_light') : $r('app.color.info'))
                Text(this.getThemeLabel())
                  .fontSize(Constants.FONT_SIZE_SMALL)
                  .fontColor($r('app.color.text_secondary'))
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(Constants.PADDING_EDGE)
          .borderRadius(Constants.RADIUS_CARD)
          .backgroundBlurStyle(BlurStyle.BACKGROUND_ULTRA_THICK,
            { adaptiveColor: AdaptiveColor.DEFAULT })
          .border({ width: 1, color: $r('app.color.divider') })

          this.SectionTitle('账户与偏好')
          Column() {
            this.SettingsRow('账号管理', '主邮箱与副邮箱', '', $r('sys.symbol.person'), () => { this.openAccountManagement() })
            Divider().color($r('app.color.divider')).margin({ left: 56, right: 16 })
            this.ThemeSettingsRow()
          }
          .width('100%')
          .borderRadius(Constants.RADIUS_CARD)
          .backgroundBlurStyle(BlurStyle.BACKGROUND_ULTRA_THICK,
            { adaptiveColor: AdaptiveColor.DEFAULT })
          .border({ width: 1, color: $r('app.color.divider') })

          this.SectionTitle('隐私与支持')
          Column() {
            this.SettingsRow('隐私政策', '了解数据使用方式', '', $r('sys.symbol.lock_shield'), () => { this.openPrivacyPolicy() })
            Divider().color($r('app.color.divider')).margin({ left: 56, right: 16 })
            this.SettingsRow('关于', '云笺集 · HarmonyOS 原生邮件客户端', this.getAppVersionLabel(), $r('sys.symbol.questionmark_circle'), () => { this.showToast('云笺集') })
          }
          .width('100%')
          .borderRadius(Constants.RADIUS_CARD)
          .backgroundBlurStyle(BlurStyle.BACKGROUND_ULTRA_THICK,
            { adaptiveColor: AdaptiveColor.DEFAULT })
          .border({ width: 1, color: $r('app.color.divider') })

          if (this.authRole === 'admin') {
            this.SectionTitle('管理员专区')
            Column() {
              this.SettingsRow('系统设置', '网站与注册策略', '', $r('sys.symbol.gearshape'), () => { this.openSystemSettings() })
              Divider().color($r('app.color.divider')).margin({ left: 56, right: 16 })
              this.SettingsRow('用户管理', '用户状态与角色', '', $r('sys.symbol.person'), () => { this.openUserManagement() })
              Divider().color($r('app.color.divider')).margin({ left: 56, right: 16 })
              this.SettingsRow('全部邮件', '全局邮件管理', '', $r('sys.symbol.envelope'), () => { this.openGlobalMailManagement() })
              Divider().color($r('app.color.divider')).margin({ left: 56, right: 16 })
              this.SettingsRow('角色权限', '角色与权限树', '', $r('sys.symbol.person_fill'), () => { this.openRoleManagement() })
              Divider().color($r('app.color.divider')).margin({ left: 56, right: 16 })
              this.SettingsRow('数据分析', '平台数据概览', '', $r('sys.symbol.doc'), () => { this.openAnalytics() })
              Divider().color($r('app.color.divider')).margin({ left: 56, right: 16 })
              this.SettingsRow('注册码管理', '生成与使用记录', '', $r('sys.symbol.star_fill'), () => { this.openRegistrationCodeManagement() })
            }
            .width('100%')
            .borderRadius(Constants.RADIUS_CARD)
            .backgroundBlurStyle(BlurStyle.BACKGROUND_ULTRA_THICK,
              { adaptiveColor: AdaptiveColor.DEFAULT })
            .border({ width: 1, color: $r('app.color.divider') })
          }

          Button('退出登录', { type: ButtonType.Capsule, stateEffect: true })
            .width('100%')
            .height(48)
            .fontSize(Constants.FONT_SIZE_SUBTITLE)
            .fontColor($r('app.color.danger'))
            .backgroundColor($r('app.color.card'))
            .margin({ top: Constants.GAP_SMALL })
            .onClick(() => { this.showLogoutConfirm = true })

          Blank().height(Constants.PADDING_TAB_CONTENT_BOTTOM)
        }
        .width('100%')
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 16, bottom: 16 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .backgroundColor($r('app.color.background'))

      if (this.showLogoutConfirm) {
        this.LogoutConfirmDialog()
      }

      if (this.showThemeDialog) {
        this.ThemeSelectDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private SectionTitle(title: string) {
    Text(title)
      .fontSize(Constants.FONT_SIZE_SMALL)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.text_tertiary'))
      .width('100%')
      .padding({ left: 4, top: 4 })
  }

  @Builder
  private SettingsRow(title: string, description: string, value: string, icon: Resource, onItemClick: () => void) {
    Row() {
      SymbolGlyph(icon)
        .fontSize(Constants.SIZE_ICON_MEDIUM)
        .fontColor([$r('app.color.text_primary')])
        .width(32)
        .margin({ right: 12 })

      Column({ space: 3 }) {
        Text(title)
          .fontSize(Constants.FONT_SIZE_SUBTITLE)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(description)
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (value !== '') {
        Text(value)
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
          .margin({ right: 6 })
      }
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(Constants.SIZE_ICON_SMALL)
        .fontColor([$r('app.color.text_tertiary')])
    }
    .width('100%')
    .height(68)
    .padding({ left: 16, right: 16 })
    .onClick(onItemClick)
  }

  @Builder
  private ThemeSettingsRow() {
    Row() {
      SymbolGlyph($r('sys.symbol.paintbrush'))
        .fontSize(Constants.SIZE_ICON_MEDIUM)
        .fontColor([$r('app.color.text_primary')])
        .width(32)
        .margin({ right: 12 })

      Column({ space: 3 }) {
        Text('外观与主题')
          .fontSize(Constants.FONT_SIZE_SUBTITLE)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
        Text('主题与显示模式')
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text(this.getThemeLabel())
        .fontSize(Constants.FONT_SIZE_SMALL)
        .fontColor($r('app.color.text_secondary'))
        .margin({ right: 6 })
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(Constants.SIZE_ICON_SMALL)
        .fontColor([$r('app.color.text_tertiary')])
    }
    .width('100%')
    .height(68)
    .padding({ left: 16, right: 16 })
    .onClick(() => { this.showThemeDialog = true })
  }

  @Builder
  private SettingsCard(title: string, description: string, value: string, icon: ResourceStr, onItemClick: () => void) {
    HdsListItemCard({
      prefixItem: new PrefixIcon({
        iconSize: IconSize.SYSTEM_ICON,
        iconValue: { symbol: icon }
      }),
      textItem: {
        primaryText: { text: title },
        secondaryText: { text: description }
      },
      suffixItem: new SuffixTextAndArrow({ text: value }),
      cardHeight: 72,
      cardBackgroundColor: $r('app.color.card'),
      cardBorderRadius: Constants.RADIUS_CARD,
      onClick: onItemClick
    })
  }

  @Builder
  private ThemeSelectDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.overlay'))
        .onClick(() => { this.showThemeDialog = false })

      Column({ space: 0 }) {
        Text('外观设置')
          .fontSize(Constants.FONT_SIZE_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
          .padding({ left: 20, right: 20, top: 20, bottom: 16 })

        this.ThemeOption('跟随系统', ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
        this.ThemeOption('浅色模式', ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)
        this.ThemeOption('深色模式', ConfigurationConstant.ColorMode.COLOR_MODE_DARK)

        Button('取消', { type: ButtonType.Normal, stateEffect: true })
          .width('100%')
          .height(44)
          .fontColor($r('app.color.text_secondary'))
          .backgroundColor($r('app.color.card'))
          .margin({ top: 12, left: 20, right: 20, bottom: 20 })
          .onClick(() => { this.showThemeDialog = false })
      }
      .width('100%')
      .margin({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
      .backgroundColor($r('app.color.card'))
      .borderRadius(Constants.RADIUS_CARD)
      .shadow(Constants.SHADOW_CARD)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ThemeOption(label: string, mode: number) {
    Row() {
      Text(label)
        .fontSize(Constants.FONT_SIZE_SUBTITLE)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      if (this.currentColorMode === mode) {
        SymbolGlyph($r('sys.symbol.checkmark'))
          .fontSize(Constants.SIZE_ICON_SMALL)
          .fontColor([$r('app.color.primary')])
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 16, bottom: 16 })
    .onClick(() => { this.selectTheme(mode) })
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

  private getThemeLabel(): string {
    if (this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT) {
      return '浅色模式'
    }
    if (this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
      return '深色模式'
    }
    return '跟随系统'
  }

  private getRoleLabel(): string {
    const roleName: string = this.authRoleName.trim()
    if (roleName === 'admin') {
      return '管理员'
    }
    return roleName === '' ? '普通用户' : roleName
  }

  private getAppVersionLabel(): string {
    try {
      const info: bundleManager.BundleInfo = bundleManager.getBundleInfoForSelfSync(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT)
      return 'v' + info.versionName
    } catch (err) {
      console.error('get app version failed')
      return 'v1.0.2'
    }
  }

  private selectTheme(mode: number): void {
    this.showThemeDialog = false
    this.currentColorMode = mode
    setAppColorMode(mode)
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

  private async openPrivacyPolicy(): Promise<void> {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
    try {
      await context.openLink(Constants.PRIVACY_POLICY_URL)
    } catch (err) {
      console.error('open privacy policy failed')
      this.showToast('暂时无法打开隐私政策')
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

import { PromptAction } from '@kit.ArkUI'
import { SettingsApi, WebsiteConfig } from '../api/SettingsApi'
import Constants from '../common/Constants'
import { AuthResult, AuthService } from '../common/AuthService'

@Component
export struct AuthPage {
  @State isRegisterMode: boolean = false
  @State email: string = ''
  @State password: string = ''
  @State confirmPassword: string = ''
  @State registerCode: string = ''
  @State registrationCodeRequired: boolean = true
  @State registrationVerificationRequired: boolean = false
  @State minEmailPrefix: number = 1
  @State isSubmitting: boolean = false
  @StorageLink('siteTitle') siteTitle: string = 'Cloud Mail'
  @StorageLink('registrationEnabled') registrationEnabled: boolean = true
  private toast: PromptAction = this.getUIContext().getPromptAction()
  onAuthenticated?: () => void

  aboutToAppear(): void {
    this.refreshWebsiteConfig()
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [[$r('app.color.auth_gradient_start'), 0.0], [$r('app.color.auth_gradient_end'), 1.0]]
        })

      Scroll() {
        Column() {
          this.BrandHeader()
          this.AuthForm()
          Blank().height(32)
        }
        .width('100%')
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 56, bottom: 24 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  private BrandHeader() {
    Column() {
      Stack() {
        Circle()
          .width(72)
          .height(72)
          .foregroundColor($r('app.color.primary'))
        SymbolGlyph($r('sys.symbol.envelope_fill'))
          .fontSize(34)
          .fontColor([$r('sys.color.icon_on_primary')])
      }
      .width(72)
      .height(72)
      .margin({ bottom: 20 })

      Text(this.siteTitle)
        .fontSize(Constants.FONT_SIZE_HERO)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Text(this.isRegisterMode ? '创建你的邮箱账户' : '登录以查看你的邮件')
        .fontSize(Constants.FONT_SIZE_SUBTITLE)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 8 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .margin({ bottom: 32 })
  }

  @Builder
  private AuthForm() {
    Column({ space: Constants.GAP_MEDIUM }) {
      Text(this.isRegisterMode ? '注册' : '登录')
        .fontSize(Constants.FONT_SIZE_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      Row() {
        TextInput({ placeholder: '邮箱账号', text: this.email })
          .layoutWeight(1)
          .height(48)
          .fontSize(Constants.FONT_SIZE_COMMON)
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.text_tertiary'))
          .backgroundColor($r('app.color.background'))
          .border({ width: 0.5, color: $r('app.color.divider') })
          .borderRadius(Constants.RADIUS_SMALL)
          .padding({ left: Constants.PADDING_INNER, right: Constants.PADDING_INNER })
          .onChange((value: string) => { this.email = value })
        Text(Constants.MAIL_DOMAIN)
          .fontSize(Constants.FONT_SIZE_COMMON)
          .fontColor($r('app.color.text_secondary'))
          .padding({ left: 8, right: 8 })
      }
      .width('100%')
      .height(48)

      TextInput({ placeholder: '密码', text: this.password })
        .type(InputType.Password)
        .showPasswordIcon(true)
        .height(48)
        .fontSize(Constants.FONT_SIZE_COMMON)
        .fontColor($r('app.color.text_primary'))
        .placeholderColor($r('app.color.text_tertiary'))
        .backgroundColor($r('app.color.background'))
        .border({ width: 0.5, color: $r('app.color.divider') })
        .borderRadius(Constants.RADIUS_SMALL)
        .padding({ left: Constants.PADDING_INNER, right: Constants.PADDING_INNER })
        .onChange((value: string) => { this.password = value })

      if (this.isRegisterMode) {
        TextInput({ placeholder: '确认密码', text: this.confirmPassword })
          .type(InputType.Password)
          .showPasswordIcon(true)
          .height(48)
          .fontSize(Constants.FONT_SIZE_COMMON)
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.text_tertiary'))
          .backgroundColor($r('app.color.background'))
          .border({ width: 0.5, color: $r('app.color.divider') })
          .borderRadius(Constants.RADIUS_SMALL)
          .padding({ left: Constants.PADDING_INNER, right: Constants.PADDING_INNER })
          .onChange((value: string) => { this.confirmPassword = value })

        if (this.registrationCodeRequired) {
          TextInput({ placeholder: '注册码', text: this.registerCode })
            .height(48)
            .fontSize(Constants.FONT_SIZE_COMMON)
            .fontColor($r('app.color.text_primary'))
            .placeholderColor($r('app.color.text_tertiary'))
            .backgroundColor($r('app.color.background'))
            .border({ width: 0.5, color: $r('app.color.divider') })
            .borderRadius(Constants.RADIUS_SMALL)
            .padding({ left: Constants.PADDING_INNER, right: Constants.PADDING_INNER })
            .onChange((value: string) => { this.registerCode = value })
        }
      }

      Button(this.isRegisterMode ? '注册' : '登录', { type: ButtonType.Capsule, stateEffect: true })
        .width('100%')
        .height(48)
        .fontSize(Constants.FONT_SIZE_SUBTITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.icon_on_primary'))
        .backgroundColor($r('app.color.primary'))
        .margin({ top: 8 })
        .enabled(!this.isSubmitting)
        .onClick(() => { this.submit() })

      if (!this.isRegisterMode) {
        Text('使用你的 ' + Constants.MAIL_DOMAIN + ' 邮箱账号登录')
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_tertiary'))
          .width('100%')
          .textAlign(TextAlign.Center)
      }

      if (this.isRegisterMode || this.registrationEnabled) {
        Row() {
          Text(this.isRegisterMode ? '已有账号？' : '没有账号？')
            .fontSize(Constants.FONT_SIZE_COMMON)
            .fontColor($r('app.color.text_secondary'))
          Text(this.isRegisterMode ? '去登录' : '去注册')
            .fontSize(Constants.FONT_SIZE_COMMON)
            .fontColor($r('app.color.text_link'))
            .fontWeight(FontWeight.Medium)
            .margin({ left: 4 })
            .onClick(() => { this.switchMode() })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 4 })
      }
    }
    .width('100%')
    .padding(Constants.PADDING_EDGE)
    .backgroundColor($r('app.color.card'))
    .borderRadius(Constants.RADIUS_CARD)
    .shadow(Constants.SHADOW_CARD)
  }

  private submit(): void {
    if (this.isRegisterMode) {
      this.submitRegister()
      return
    }
    this.submitLogin()
  }

  private submitLogin(): void {
    this.loginRemote()
  }

  private async loginRemote(): Promise<void> {
    if (!this.validateEmail()) {
      return
    }
    if (this.password.trim() === '') {
      this.showToast('请输入密码')
      return
    }
    this.isSubmitting = true
    const result: AuthResult = await AuthService.login(this.getFullEmail(), this.password)
    this.isSubmitting = false
    if (!result.success) {
      this.showToast(result.message)
      return
    }
    if (this.onAuthenticated) {
      this.onAuthenticated()
    }
  }

  private submitRegister(): void {
    this.registerRemote()
  }

  private async registerRemote(): Promise<void> {
    if (!this.registrationEnabled) {
      this.showToast('当前未开放注册')
      return
    }
    if (!this.validateEmail()) {
      return
    }
    if (this.email.trim().length < this.minEmailPrefix) {
      this.showToast('邮箱账号至少需要 ' + this.minEmailPrefix.toString() + ' 位')
      return
    }
    if (this.password.length < 6) {
      this.showToast('密码至少需要 6 位')
      return
    }
    if (this.password !== this.confirmPassword) {
      this.showToast('两次输入的密码不一致')
      return
    }
    if (this.registrationCodeRequired && this.registerCode.trim() === '') {
      this.showToast('请输入注册码')
      return
    }
    if (this.registrationVerificationRequired) {
      this.showToast('当前注册需要人机验证，请先在网页端完成注册')
      return
    }
    this.isSubmitting = true
    const result: AuthResult = await AuthService.register(this.getFullEmail(), this.password, this.registerCode.trim())
    this.isSubmitting = false
    if (!result.success) {
      this.showToast(result.message)
      return
    }
    this.password = ''
    this.confirmPassword = ''
    this.registerCode = ''
    this.isRegisterMode = false
    this.showToast('注册成功，请登录')
  }

  private validateEmail(): boolean {
    const value: string = this.email.trim()
    if (value === '' || value.indexOf('@') >= 0 || value.indexOf(' ') >= 0) {
      this.showToast('请输入正确的邮箱账号')
      return false
    }
    return true
  }

  private getFullEmail(): string {
    return this.email.trim() + Constants.MAIL_DOMAIN
  }

  private switchMode(): void {
    this.isRegisterMode = !this.isRegisterMode
    this.password = ''
    this.confirmPassword = ''
    this.registerCode = ''
  }

  private async refreshWebsiteConfig(): Promise<void> {
    try {
      const config: WebsiteConfig = await SettingsApi.getWebsiteConfig()
      AppStorage.set('siteTitle', config.title)
      AppStorage.set('registrationEnabled', config.registrationEnabled)
      this.registrationCodeRequired = config.registrationCodeRequired
      this.registrationVerificationRequired = config.registrationVerificationRequired
      this.minEmailPrefix = config.minEmailPrefix
      if (!config.registrationEnabled && this.isRegisterMode) {
        this.switchMode()
      }
    } catch (err) {
      console.error('load website config failed')
    }
  }

  private showToast(message: string): void {
    try {
      this.toast.openToast({ message: message, duration: 2000 })
    } catch (err) {
      console.error('openToast failed')
    }
  }
}

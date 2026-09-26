import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit'
import { common } from '@kit.AbilityKit'
import { authentication } from '@kit.AccountKit'
import { util } from '@kit.ArkTS'
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit'
import { PromptAction } from '@kit.ArkUI'
import { hilog } from '@kit.PerformanceAnalysisKit'
import Constants from '../common/Constants'
import { ApiException } from '../common/HttpClient'
import { PlatformInstance } from '../common/InstanceModels'
import { LoginIdentityResult, LoginInstanceService, LoginRegistrationConfig } from '../common/LoginInstanceService'
import { LoginInstancePicker } from '../components/LoginInstancePicker'
import HuaweiProfileAuthorization from '../common/HuaweiProfileAuthorization'
import { PlatformSessionService } from '../common/PlatformSessionService'

enum LoginStage {
  HUAWEI_LOGIN,
  CHOOSE_ACTION,
  BIND_EXISTING,
  REGISTER_NEW
}

enum HuaweiLoginErrorCode {
  LOGIN_OUT = 1001502001,
  NETWORK_ERROR = 1001502005,
  INTERNAL_ERROR = 1001502009,
  USER_CANCEL = 1001502012,
  SYSTEM_SERVICE = 12300001,
  REQUEST_REFUSE = 1001500002,
  AGREEMENT_NOT_ACCEPTED = 1005300001,
  INVALID_CLIENT_OR_PROFILE = 1001502003
}

@Component
export struct AuthPage {
  @State stage: LoginStage = LoginStage.HUAWEI_LOGIN
  @State agreementAccepted: boolean = false
  @State email: string = ''
  @State password: string = ''
  @State registerCode: string = ''
  @State selectedInstance: PlatformInstance = LoginInstanceService.defaultInstance()
  @State instances: PlatformInstance[] = []
  @State directoryLoading: boolean = false
  @State directoryReady: boolean = false
  @State directoryError: string = ''
  @State showInstancePicker: boolean = false
  @State registrationLoading: boolean = false
  @State registrationError: string = ''
  @State registrationDomains: string[] = []
  @State selectedDomain: number = 0
  @State registrationVerificationRequired: boolean = false
  @State registrationEnabled: boolean = false
  @State registrationCodeRequired: boolean = true
  @State minEmailPrefix: number = 1
  @State isSubmitting: boolean = false
  private identity: LoginIdentityResult | null = null
  private pageActive: boolean = false
  private authenticationSequence: number = 0
  private directorySequence: number = 0
  private registrationSequence: number = 0
  private toast: PromptAction = this.getUIContext().getPromptAction()
  private huaweiAccountSubscriber: commonEventManager.CommonEventSubscriber | null = null
  private isAccountEventSubscriptionActive: boolean = false
  onAuthenticated?: () => void

  private huaweiLoginController: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .setAgreementStatus(loginComponentManager.AgreementStatus.NOT_ACCEPTED)
      .onClickLoginWithHuaweiIDButton((error: BusinessError,
        response: loginComponentManager.HuaweiIDCredential) => {
        if (error) {
          this.handleHuaweiLoginError(error)
          return
        }
        if (response && response.authorizationCode) {
          this.loginWithHuaweiProfile(response)
        }
      })

  aboutToAppear(): void {
    this.pageActive = true
    HuaweiProfileAuthorization.initialize(this.getUIContext().getHostContext() as common.UIAbilityContext)
    this.isAccountEventSubscriptionActive = true
    this.subscribeHuaweiAccountEvents()
    this.refreshInstanceDirectory(true)
  }

  aboutToDisappear(): void {
    this.pageActive = false
    this.authenticationSequence++
    this.directorySequence++
    this.registrationSequence++
    LoginInstanceService.cancelPending()
    this.isAccountEventSubscriptionActive = false
    this.unsubscribeHuaweiAccountEvents()
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

      if (this.stage === LoginStage.HUAWEI_LOGIN) {
        this.HuaweiLoginPage()
      } else {
        Scroll() {
          Column() {
            this.BrandHeader()
            this.InstanceSelector()
            if (this.stage === LoginStage.CHOOSE_ACTION) {
              this.ActionChoiceCard()
            } else if (this.stage === LoginStage.BIND_EXISTING) {
              this.BindExistingCard()
            } else {
              this.RegisterCard()
            }
            Blank().height(32)
          }
          .width('100%')
          .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 56, bottom: 24 })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .blur(this.showInstancePicker ? 12 : 0)
      }

      if (this.isSubmitting) {
        Stack() {
          Column({ space: 12 }) {
            LoadingProgress()
              .width(32)
              .height(32)
              .color($r('app.color.primary'))
            Text($r('app.string.login_instance_submitting'))
              .fontSize(Constants.FONT_SIZE_COMMON)
              .fontColor($r('app.color.text_primary'))
          }
          .padding(24)
          .backgroundColor($r('app.color.card'))
          .borderRadius(Constants.RADIUS_CARD)
          .shadow(Constants.SHADOW_FLOAT)
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.overlay'))
      }

      Row()
        .width(1)
        .height(1)
        .bindSheet($$this.showInstancePicker, this.InstancePickerSheet(), {
          height: '72%',
          dragBar: false,
          showClose: false,
          blurStyle: BlurStyle.COMPONENT_THICK,
          maskColor: 0x1A000000,
          enableOutsideInteractive: false,
          onWillDismiss: (action: DismissSheetAction) => {
            this.showInstancePicker = false
            action.dismiss()
          }
        })
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  private InstanceSelector() {
    Column({ space: 8 }) {
      Button({ type: ButtonType.Normal, stateEffect: true }) {
        Row({ space: 12 }) {
          SymbolGlyph($r('sys.symbol.externaldrive'))
            .fontSize(24)
            .fontColor([$r('app.color.primary')])
          Column({ space: 4 }) {
            Text($r('app.string.login_selected_instance'))
              .fontSize(Constants.FONT_SIZE_SMALL)
              .fontColor($r('app.color.text_secondary'))
            Text(this.selectedInstance.displayName)
              .fontSize(Constants.FONT_SIZE_COMMON)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.selectedInstance.originHost)
              .fontSize(Constants.FONT_SIZE_SMALL)
              .fontColor($r('app.color.text_secondary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text($r('app.string.login_switch_instance'))
            .fontSize(Constants.FONT_SIZE_COMMON)
            .fontColor($r('app.color.text_link'))
          SymbolGlyph($r('sys.symbol.chevron_down'))
            .fontSize(14)
            .fontColor([$r('app.color.text_secondary')])
        }
        .width('100%')
        .padding(Constants.PADDING_INNER)
      }
      .width('100%')
      .backgroundColor($r('app.color.card'))
      .borderRadius(Constants.RADIUS_CARD)
      .border({ width: 0.5, color: $r('app.color.divider') })
      .enabled(!this.isSubmitting)
      .onClick(() => { this.showInstancePicker = true })

      if (this.directoryLoading) {
        Text($r('app.string.login_instances_loading'))
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
      } else if (this.directoryError !== '') {
        Text(this.directoryError)
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
        Button($r('app.string.login_instances_retry'), { type: ButtonType.Normal })
          .fontColor($r('app.color.text_link'))
          .backgroundColor(Color.Transparent)
          .onClick(() => { this.refreshInstanceDirectory() })
      }
    }
    .width('100%')
    .margin({ bottom: 20 })
  }

  @Builder
  private InstancePickerSheet() {
    LoginInstancePicker({
      instances: this.instances,
      selectedId: this.selectedInstance.instanceId,
      loading: this.directoryLoading,
      errorMessage: this.directoryError,
      onSelect: (instance: PlatformInstance) => { this.selectInstance(instance) },
      onRetry: () => { this.refreshInstanceDirectory() },
      onClose: () => { this.showInstancePicker = false }
    })
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

      Text('云笺集')
        .fontSize(Constants.FONT_SIZE_HERO)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Text(this.getStageDescription())
        .fontSize(Constants.FONT_SIZE_SUBTITLE)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 8 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .margin({ bottom: 32 })
  }

  @Builder
  private HuaweiLoginPage() {
    Column() {
      Blank()

      Stack() {
        Circle()
          .width(64)
          .height(64)
          .foregroundColor($r('app.color.primary'))
        SymbolGlyph($r('sys.symbol.envelope_fill'))
          .fontSize(30)
          .fontColor([$r('sys.color.icon_on_primary')])
      }
      .width(64)
      .height(64)

      Text('云笺集')
        .fontSize(Constants.FONT_SIZE_HERO)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ top: 18 })

      Text($r('app.string.login_multi_instance_description'))
        .fontSize(Constants.FONT_SIZE_COMMON)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 8 })

      Blank()

      this.InstanceSelector()

      LoginWithHuaweiIDButton({
        params: {
          style: loginComponentManager.Style.BUTTON_RED,
          extraStyle: {
            buttonStyle: new loginComponentManager.ButtonStyle().loadingStyle({ show: true })
          },
          borderRadius: 24,
          loginType: loginComponentManager.LoginType.ID,
          supportDarkMode: true
        },
        controller: this.huaweiLoginController
      })
        .width('100%')
        .height(48)
        .enabled(this.directoryReady && !this.directoryLoading && !this.isSubmitting)

      Button('切换华为账号', { type: ButtonType.Capsule, stateEffect: true })
        .width('100%')
        .height(48)
        .fontSize(Constants.FONT_SIZE_COMMON)
        .fontColor($r('app.color.text_link'))
        .backgroundColor($r('app.color.card'))
        .border({ width: 1, color: $r('app.color.divider') })
        .margin({ top: 12 })
        .enabled(!this.isSubmitting)
        .onClick(() => {
          this.showHuaweiAccountSwitchGuide()
        })

      Row() {
        Checkbox({ name: 'loginAgreement', group: 'loginAgreementGroup' })
          .select(this.agreementAccepted)
          .onChange((accepted: boolean) => {
            this.agreementAccepted = accepted
            this.huaweiLoginController.setAgreementStatus(accepted ?
            loginComponentManager.AgreementStatus.ACCEPTED :
            loginComponentManager.AgreementStatus.NOT_ACCEPTED)
          })
        Text('我已阅读并同意')
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
          .margin({ left: 8 })
        Text('《隐私政策》')
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_link'))
          .onClick(() => { this.openPrivacyPolicy() })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .margin({ top: 18, bottom: 12 })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 40, bottom: 28 })
    .blur(this.showInstancePicker ? 12 : 0)
  }

  @Builder
  private ActionChoiceCard() {
    Column({ space: Constants.GAP_MEDIUM }) {
      Text('设置你的主邮箱')
        .fontSize(Constants.FONT_SIZE_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      Button('已经有主邮箱了？点我绑定', { type: ButtonType.Capsule, stateEffect: true })
        .width('100%')
        .height(48)
        .fontSize(Constants.FONT_SIZE_SUBTITLE)
        .fontColor($r('sys.color.icon_on_primary'))
        .backgroundColor($r('app.color.primary'))
        .onClick(() => {
          this.email = this.selectedInstance.localEmail
          this.stage = LoginStage.BIND_EXISTING
        })

      Button('还没有主邮箱，点我注册', { type: ButtonType.Capsule, stateEffect: true })
        .width('100%')
        .height(48)
        .fontSize(Constants.FONT_SIZE_SUBTITLE)
        .fontColor($r('app.color.text_primary'))
        .backgroundColor($r('app.color.background'))
        .border({ width: 1, color: $r('app.color.divider') })
        .enabled(this.canRegister())
        .onClick(() => { this.stage = LoginStage.REGISTER_NEW })

      Button('切换华为账号', { type: ButtonType.Normal, stateEffect: true })
        .fontSize(Constants.FONT_SIZE_COMMON)
        .fontColor($r('app.color.text_link'))
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.resetHuaweiLoginForAccountSwitch()
          this.showHuaweiAccountSwitchGuide()
        })

      if (this.registrationLoading) {
        Text($r('app.string.login_registration_loading'))
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
      } else if (this.registrationError !== '') {
        Text(this.registrationError)
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
        Button($r('app.string.login_registration_retry'), { type: ButtonType.Normal })
          .fontColor($r('app.color.text_link'))
          .backgroundColor(Color.Transparent)
          .onClick(() => { this.refreshRegistrationConfig(this.selectedInstance) })
      } else if (!this.registrationEnabled && LoginInstanceService.isAnchor(this.selectedInstance)) {
        Text('当前站点未开放新邮箱注册，你仍可以绑定已有主邮箱。')
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_tertiary'))
          .width('100%')
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .padding(Constants.PADDING_EDGE)
    .backgroundColor($r('app.color.card'))
    .borderRadius(Constants.RADIUS_CARD)
    .shadow(Constants.SHADOW_CARD)
  }

  @Builder
  private BindExistingCard() {
    Column({ space: Constants.GAP_MEDIUM }) {
      Text('绑定已有主邮箱')
        .fontSize(Constants.FONT_SIZE_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      this.EmailInput()

      Text($r('app.string.login_instance_password_notice'))
        .fontSize(Constants.FONT_SIZE_SMALL)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')

      TextInput({ placeholder: '原邮箱密码（仅用于本次验证）', text: this.password })
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

      this.PrimaryActionButton('确认绑定', () => { this.bindExisting() })
      this.BackButton()
    }
    .width('100%')
    .padding(Constants.PADDING_EDGE)
    .backgroundColor($r('app.color.card'))
    .borderRadius(Constants.RADIUS_CARD)
    .shadow(Constants.SHADOW_CARD)
  }

  @Builder
  private RegisterCard() {
    Column({ space: Constants.GAP_MEDIUM }) {
      Text('注册新的主邮箱')
        .fontSize(Constants.FONT_SIZE_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      if (this.requiresWebRegistration()) {
        Text($r('app.string.login_instance_web_registration'))
          .fontSize(Constants.FONT_SIZE_COMMON)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
        this.PrimaryActionButton($r('app.string.login_instance_open_registration'), () => {
          this.openSelectedInstanceWebsite()
        })
        Button($r('app.string.login_instance_registration_done'), { type: ButtonType.Capsule, stateEffect: true })
          .width('100%')
          .height(48)
          .fontColor($r('app.color.text_link'))
          .backgroundColor($r('app.color.background'))
          .onClick(() => {
            this.email = ''
            this.password = ''
            this.stage = LoginStage.BIND_EXISTING
          })
      } else {
        this.EmailInput()

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

        Text('该邮箱将与当前华为账号绑定，应用内不再设置单独登录密码。')
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')

        this.PrimaryActionButton('注册并绑定', () => { this.registerNewMailbox() })
      }
      this.BackButton()
    }
    .width('100%')
    .padding(Constants.PADDING_EDGE)
    .backgroundColor($r('app.color.card'))
    .borderRadius(Constants.RADIUS_CARD)
    .shadow(Constants.SHADOW_CARD)
  }

  @Builder
  private EmailInput() {
    Column({ space: 8 }) {
      TextInput({
        placeholder: this.usesRegistrationDomain() ? $r('app.string.login_email_prefix') :
          $r('app.string.login_full_email'),
        text: this.email
      })
        .width('100%')
        .height(48)
        .type(this.usesRegistrationDomain() ? InputType.Normal : InputType.Email)
        .fontSize(Constants.FONT_SIZE_COMMON)
        .fontColor($r('app.color.text_primary'))
        .placeholderColor($r('app.color.text_tertiary'))
        .backgroundColor($r('app.color.background'))
        .border({ width: 0.5, color: $r('app.color.divider') })
        .borderRadius(Constants.RADIUS_SMALL)
        .padding({ left: Constants.PADDING_INNER, right: Constants.PADDING_INNER })
        .onChange((value: string) => { this.email = value })
      if (this.usesRegistrationDomain()) {
        Row({ space: 8 }) {
          Text($r('app.string.login_email_domain'))
            .fontSize(Constants.FONT_SIZE_SMALL)
            .fontColor($r('app.color.text_secondary'))
          Select(this.getDomainOptions())
            .selected(this.selectedDomain)
            .value('@' + this.registrationDomains[this.selectedDomain])
            .font({ size: Constants.FONT_SIZE_COMMON })
            .fontColor($r('app.color.text_primary'))
            .backgroundColor($r('app.color.background'))
            .layoutWeight(1)
            .onSelect((index: number) => {
              this.selectedDomain = index
            })
        }
        .width('100%')
      }
    }
    .width('100%')
  }

  @Builder
  private PrimaryActionButton(label: ResourceStr, action: () => void) {
    Button(label, { type: ButtonType.Capsule, stateEffect: true })
      .width('100%')
      .height(48)
      .fontSize(Constants.FONT_SIZE_SUBTITLE)
      .fontColor($r('sys.color.icon_on_primary'))
      .backgroundColor($r('app.color.primary'))
      .enabled(!this.isSubmitting && this.directoryReady && !this.directoryLoading)
      .onClick(action)
  }

  @Builder
  private BackButton() {
    Button('返回选择', { type: ButtonType.Normal, stateEffect: true })
      .fontSize(Constants.FONT_SIZE_COMMON)
      .fontColor($r('app.color.text_link'))
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.password = ''
        this.registerCode = ''
        this.stage = LoginStage.CHOOSE_ACTION
      })
  }

  private async loginWithHuawei(authorizationCode: string, target: PlatformInstance,
    operation: number, profileIdentity: string = ''): Promise<void> {
    if (!this.isAuthenticationCurrent(operation)) {
      return
    }
    try {
      const startedAt: number = Date.now()
      const identity: LoginIdentityResult = await LoginInstanceService.loginHuawei(authorizationCode)
      if (!this.isAuthenticationCurrent(operation)) {
        return
      }
      HuaweiProfileAuthorization.remember(profileIdentity, PlatformSessionService.getHuaweiUserId(),
        PlatformSessionService.getNickName(), PlatformSessionService.getAvatarUrl())
      hilog.info(0x0000, 'CloudMailLogin', 'Identity and mailbox verification completed in %{public}d ms',
        Date.now() - startedAt)
      this.identity = identity
      if (LoginInstanceService.isAnchor(target) && identity.anchorStatus === 'BOUND') {
        await LoginInstanceService.activateAnchor(identity, target)
        if (this.isAuthenticationCurrent(operation)) {
          this.finishAuthentication()
        }
        return
      }
      this.stage = LoginStage.CHOOSE_ACTION
      await this.refreshInstanceDirectory()
    } catch (error) {
      if (this.isAuthenticationCurrent(operation)) {
        this.showRequestError(error, $r('app.string.login_instance_login_failed'))
      }
    } finally {
      if (this.isAuthenticationCurrent(operation)) {
        this.isSubmitting = false
      }
    }
  }

  private loginWithHuaweiProfile(nativeCredential: loginComponentManager.HuaweiIDCredential): void {
    if (!this.pageActive || this.isSubmitting || !this.directoryReady || this.directoryLoading) {
      return
    }
    this.isSubmitting = true
    const target: PlatformInstance = this.selectedInstance
    const operation: number = ++this.authenticationSequence
    const fallbackAuthorizationCode: string = nativeCredential.authorizationCode
    const nativeIdentity: string = nativeCredential.unionID || nativeCredential.openID || ''
    if (!HuaweiProfileAuthorization.needsAuthorization(nativeIdentity)) {
      // Reuse only the recent consent hint, never an old authorization code.
      this.loginWithHuawei(fallbackAuthorizationCode, target, operation)
      return
    }
    const profileStartedAt: number = Date.now()
    try {
      const request: authentication.AuthorizationWithHuaweiIDRequest =
        new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest()
      request.scopes = ['openid', 'profile']
      request.permissions = ['serviceauthcode']
      request.forceAuthorization = true
      request.state = util.generateRandomUUID()
      const controller: authentication.AuthenticationController =
        new authentication.AuthenticationController(this.getUIContext().getHostContext())
      controller.executeRequest(request, (error: BusinessError<Record<string, Object>>,
        data: authentication.AuthenticationResponse) => {
        if (!this.isAuthenticationCurrent(operation)) {
          return
        }
        hilog.info(0x0000, 'CloudMailLogin', 'Profile authorization completed in %{public}d ms',
          Date.now() - profileStartedAt)
        if (error) {
          this.loginWithHuawei(fallbackAuthorizationCode, target, operation)
          return
        }
        const response: authentication.AuthorizationWithHuaweiIDResponse =
          data as authentication.AuthorizationWithHuaweiIDResponse
        if (!response || response.state !== request.state) {
          hilog.error(0x0000, 'CloudMailAuth', 'Huawei profile authorization state mismatch')
          this.loginWithHuawei(fallbackAuthorizationCode, target, operation)
          return
        }
        const credential: authentication.AuthorizationWithHuaweiIDCredential | undefined = response.data
        if (credential && credential.authorizationCode) {
          const profileIdentity: string = credential.unionID || credential.openID || ''
          if (nativeIdentity !== '' && profileIdentity !== '' && profileIdentity !== nativeIdentity) {
            this.isSubmitting = false
            this.showToast(this.resourceText($r('app.string.login_huawei_identity_changed')))
            return
          }
          this.loginWithHuawei(credential.authorizationCode, target, operation,
            profileIdentity === nativeIdentity ? profileIdentity : '')
          return
        }
        this.loginWithHuawei(fallbackAuthorizationCode, target, operation)
      })
    } catch (error) {
      this.loginWithHuawei(fallbackAuthorizationCode, target, operation)
    }
  }

  private showHuaweiAccountSwitchGuide(): void {
    this.toast.showDialog({
      title: '切换华为账号',
      message: '云笺集使用设备当前登录的华为账号。\n\n请前往“设置 > 华为账号中心”，退出当前账号并登录另一个账号；返回云笺集后，再点击“华为账号登录”。',
      buttons: [{
        text: '我知道了',
        color: $r('app.color.primary'),
        primary: true
      }]
    }).catch((error: BusinessError) => {
      hilog.error(0x0000, 'CloudMailAuth',
        `Show Huawei account switch guide failed, code=${error.code}, message=${error.message}`)
    })
  }

  private resetHuaweiLoginForAccountSwitch(): void {
    LoginInstanceService.cancelPending()
    this.authenticationSequence++
    this.directorySequence++
    this.identity = null
    this.isSubmitting = false
    this.directoryLoading = false
    this.directoryReady = false
    this.instances = []
    this.selectedInstance = LoginInstanceService.defaultInstance()
    this.email = ''
    this.password = ''
    this.registerCode = ''
    this.stage = LoginStage.HUAWEI_LOGIN
    this.refreshInstanceDirectory(true)
  }

  private subscribeHuaweiAccountEvents(): void {
    const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: [
        commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN,
        commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOUT
      ]
    }
    commonEventManager.createSubscriber(subscribeInfo)
      .then((subscriber: commonEventManager.CommonEventSubscriber) => {
        if (!this.isAccountEventSubscriptionActive) {
          return
        }
        this.huaweiAccountSubscriber = subscriber
        commonEventManager.subscribe(subscriber,
          (error: BusinessError, data: commonEventManager.CommonEventData) => {
            if (!this.isAccountEventSubscriptionActive || !this.pageActive) {
              return
            }
            if (error) {
              hilog.error(0x0000, 'CloudMailAuth',
                `Subscribe Huawei account event failed, code=${error.code}, message=${error.message}`)
              return
            }
            this.resetHuaweiLoginForAccountSwitch()
            if (data.event === commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN) {
              this.showToast('检测到华为账号已登录，请重新登录云笺集')
              return
            }
            if (data.event === commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOUT) {
              this.showToast('检测到华为账号已退出，请在系统设置中登录其他账号')
            }
          })
      })
      .catch((error: BusinessError) => {
        hilog.error(0x0000, 'CloudMailAuth',
          `Create Huawei account subscriber failed, code=${error.code}, message=${error.message}`)
      })
  }

  private unsubscribeHuaweiAccountEvents(): void {
    const subscriber: commonEventManager.CommonEventSubscriber | null = this.huaweiAccountSubscriber
    if (subscriber === null) {
      return
    }
    this.huaweiAccountSubscriber = null
    commonEventManager.unsubscribe(subscriber, (error: BusinessError) => {
      if (error) {
        hilog.error(0x0000, 'CloudMailAuth',
          `Unsubscribe Huawei account event failed, code=${error.code}, message=${error.message}`)
      }
    })
  }

  private async bindExisting(): Promise<void> {
    if (this.isSubmitting || this.identity === null || !this.directoryReady) {
      return
    }
    if (!this.validateEmail()) {
      return
    }
    if (this.password === '') {
      this.showToast('请输入原邮箱密码')
      return
    }
    const target: PlatformInstance = this.selectedInstance
    const identity: LoginIdentityResult = this.identity
    const email: string = this.getFullEmail()
    const password: string = this.password
    const operation: number = ++this.authenticationSequence
    this.isSubmitting = true
    try {
      await LoginInstanceService.bind(target, identity, email, password)
      if (this.isAuthenticationCurrent(operation)) {
        this.finishAuthentication()
      }
    } catch (error) {
      if (this.isAuthenticationCurrent(operation)) {
        this.showRequestError(error, $r('app.string.login_instance_bind_failed'))
      }
    } finally {
      if (this.isAuthenticationCurrent(operation)) {
        this.password = ''
        this.isSubmitting = false
      }
    }
  }

  private async registerNewMailbox(): Promise<void> {
    if (this.isSubmitting || this.identity === null || !this.directoryReady) {
      return
    }
    if (this.requiresWebRegistration() || !this.canRegister()) {
      this.showToast('当前未开放注册')
      return
    }
    if (!this.validateEmail()) {
      return
    }
    if (this.getFullEmail().split('@')[0].length < this.minEmailPrefix) {
      this.showToast('邮箱账号至少需要 ' + this.minEmailPrefix.toString() + ' 位')
      return
    }
    if (this.registrationCodeRequired && this.registerCode.trim() === '') {
      this.showToast('请输入注册码')
      return
    }
    const target: PlatformInstance = this.selectedInstance
    const identity: LoginIdentityResult = this.identity
    const email: string = this.getFullEmail()
    const code: string = this.registerCode.trim()
    const operation: number = ++this.authenticationSequence
    this.isSubmitting = true
    try {
      await LoginInstanceService.registerAnchor(target, identity, email, code)
      if (this.isAuthenticationCurrent(operation)) {
        this.finishAuthentication()
      }
    } catch (error) {
      if (this.isAuthenticationCurrent(operation)) {
        this.showRequestError(error, $r('app.string.login_instance_register_failed'))
      }
    } finally {
      if (this.isAuthenticationCurrent(operation)) {
        this.isSubmitting = false
      }
    }
  }

  private finishAuthentication(): void {
    this.password = ''
    this.registerCode = ''
    this.identity = null
    if (this.onAuthenticated) {
      this.onAuthenticated()
    }
  }

  private validateEmail(): boolean {
    const value: string = this.email.trim()
    if (this.usesRegistrationDomain() && (value.indexOf('@') >= 0 || value === '')) {
      this.showToast(this.resourceText($r('app.string.login_email_prefix_invalid')))
      return false
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.getFullEmail())) {
      this.showToast(this.resourceText($r('app.string.login_email_invalid')))
      return false
    }
    return true
  }

  private getFullEmail(): string {
    if (this.usesRegistrationDomain()) {
      return this.email.trim() + '@' + this.registrationDomains[this.selectedDomain]
    }
    return this.email.trim()
  }

  private getStageDescription(): string {
    if (this.stage === LoginStage.HUAWEI_LOGIN) {
      return '使用华为账号安全登录'
    }
    if (this.stage === LoginStage.CHOOSE_ACTION) {
      return this.resourceText($r('app.string.login_multi_instance_description'))
    }
    if (this.stage === LoginStage.BIND_EXISTING) {
      return '验证并绑定你的主邮箱'
    }
    return '创建并绑定新的主邮箱'
  }

  private handleHuaweiLoginError(error: BusinessError): void {
    hilog.error(0x0000, 'CloudMailAuth',
      `Huawei login failed, code=${error.code}, message=${error.message}`)
    if (error.code === HuaweiLoginErrorCode.USER_CANCEL ||
      error.code === HuaweiLoginErrorCode.REQUEST_REFUSE) {
      return
    }
    if (error.code === HuaweiLoginErrorCode.AGREEMENT_NOT_ACCEPTED) {
      this.showToast('请先阅读并同意隐私政策')
      return
    }
    if (error.code === HuaweiLoginErrorCode.NETWORK_ERROR) {
      this.showToast('网络连接失败，请检查网络后重试')
      return
    }
    if (error.code === HuaweiLoginErrorCode.LOGIN_OUT) {
      this.showToast('请先在设备上登录华为账号')
      return
    }
    if (error.code === HuaweiLoginErrorCode.INVALID_CLIENT_OR_PROFILE) {
      this.showToast('华为账号配置校验失败，请更新应用后重试')
      return
    }
    if (error.code === HuaweiLoginErrorCode.SYSTEM_SERVICE ||
      error.code === HuaweiLoginErrorCode.INTERNAL_ERROR) {
      this.showToast('华为账号服务暂时不可用，请稍后重试')
      return
    }
    this.showToast('华为账号登录失败，请重试')
  }

  private async refreshInstanceDirectory(usePreference: boolean = false): Promise<void> {
    const sequence: number = ++this.directorySequence
    this.directoryLoading = true
    this.directoryError = ''
    try {
      const instances: PlatformInstance[] = this.identity === null ?
        await LoginInstanceService.listInstances() : await LoginInstanceService.authenticatedInstances()
      if (!this.pageActive || sequence !== this.directorySequence) {
        return
      }
      if (instances.length === 0) {
        throw new ApiException(503, this.resourceText($r('app.string.login_instances_empty')), true)
      }
      this.instances = instances
      const preferredId: string = usePreference ? LoginInstanceService.getPreferredInstanceId() :
        this.selectedInstance.instanceId
      const chosen: PlatformInstance | undefined = instances.find((item: PlatformInstance) =>
        item.instanceId === preferredId)
      if (!usePreference && chosen === undefined) {
        this.directoryReady = false
        this.directoryError = this.resourceText($r('app.string.login_instance_unavailable'))
        this.showInstancePicker = true
        return
      }
      this.selectedInstance = chosen === undefined ? instances[0] : chosen
      LoginInstanceService.rememberInstance(this.selectedInstance.instanceId)
      this.directoryReady = true
      if (this.identity !== null && this.selectedInstance.localEmail !== '') {
        this.email = this.selectedInstance.localEmail
        this.stage = LoginStage.BIND_EXISTING
      }
      this.refreshRegistrationConfig(this.selectedInstance)
    } catch (error) {
      if (this.pageActive && sequence === this.directorySequence) {
        this.directoryReady = false
        this.directoryError = error instanceof ApiException ? error.message :
          this.resourceText($r('app.string.login_instances_failed'))
      }
    } finally {
      if (this.pageActive && sequence === this.directorySequence) {
        this.directoryLoading = false
      }
    }
  }

  private async selectInstance(instance: PlatformInstance): Promise<void> {
    if (this.isSubmitting || this.directoryLoading) {
      return
    }
    this.selectedInstance = instance
    this.directoryReady = true
    this.directoryError = ''
    this.showInstancePicker = false
    this.email = ''
    this.password = ''
    this.registerCode = ''
    LoginInstanceService.rememberInstance(instance.instanceId)
    this.refreshRegistrationConfig(instance)
    const identity: LoginIdentityResult | null = this.identity
    if (identity === null) {
      return
    }
    if (LoginInstanceService.isAnchor(instance) && identity.anchorStatus === 'BOUND') {
      const operation: number = ++this.authenticationSequence
      this.isSubmitting = true
      try {
        await LoginInstanceService.activateAnchor(identity, instance)
        if (this.isAuthenticationCurrent(operation)) {
          this.finishAuthentication()
        }
      } catch (error) {
        if (this.isAuthenticationCurrent(operation)) {
          this.showRequestError(error, $r('app.string.login_instance_login_failed'))
          this.stage = LoginStage.CHOOSE_ACTION
        }
      } finally {
        if (this.isAuthenticationCurrent(operation)) {
          this.isSubmitting = false
        }
      }
      return
    }
    this.email = instance.localEmail
    this.stage = this.email === '' ? LoginStage.CHOOSE_ACTION : LoginStage.BIND_EXISTING
  }

  private async refreshRegistrationConfig(instance: PlatformInstance): Promise<void> {
    const sequence: number = ++this.registrationSequence
    this.registrationLoading = true
    this.registrationError = ''
    this.registrationEnabled = false
    this.registrationDomains = []
    this.selectedDomain = 0
    this.registrationVerificationRequired = false
    try {
      const config: LoginRegistrationConfig = await LoginInstanceService.registrationConfig(instance)
      if (!this.pageActive || sequence !== this.registrationSequence ||
        instance.instanceId !== this.selectedInstance.instanceId) {
        return
      }
      this.registrationEnabled = config.enabled
      this.registrationCodeRequired = config.codeRequired
      this.minEmailPrefix = config.minPrefix
      this.registrationDomains = config.domains.map((domain: string): string =>
        domain.charAt(0) === '@' ? domain.substring(1) : domain)
      this.registrationVerificationRequired = config.verificationRequired
    } catch (error) {
      if (this.pageActive && sequence === this.registrationSequence) {
        this.registrationError = this.resourceText($r('app.string.login_registration_failed'))
      }
    } finally {
      if (this.pageActive && sequence === this.registrationSequence) {
        this.registrationLoading = false
      }
    }
  }

  private canRegister(): boolean {
    if (!LoginInstanceService.isAnchor(this.selectedInstance)) {
      return this.directoryReady
    }
    return this.registrationEnabled && !this.registrationLoading && this.registrationError === ''
  }

  private requiresWebRegistration(): boolean {
    return !LoginInstanceService.isAnchor(this.selectedInstance) || this.registrationVerificationRequired
  }

  private usesRegistrationDomain(): boolean {
    return this.stage === LoginStage.REGISTER_NEW && !this.requiresWebRegistration() &&
      this.registrationDomains.length > 0
  }

  private getDomainOptions(): SelectOption[] {
    return this.registrationDomains.map((domain: string): SelectOption => ({ value: '@' + domain }))
  }

  private async openSelectedInstanceWebsite(): Promise<void> {
    if (this.isSubmitting) {
      return
    }
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
    const instance: PlatformInstance = this.selectedInstance
    try {
      await context.openLink('https://' + instance.originHost)
    } catch (error) {
      this.showToast(this.resourceText($r('app.string.login_instance_open_failed')))
    }
  }

  private isAuthenticationCurrent(operation: number): boolean {
    return this.pageActive && operation === this.authenticationSequence
  }

  private showRequestError(error: Object, fallback: Resource): void {
    this.showToast(error instanceof ApiException ? error.message : this.resourceText(fallback))
  }

  private resourceText(resource: Resource): string {
    return this.getUIContext().getHostContext()!.resourceManager.getStringSync(resource.id)
  }

  private async openPrivacyPolicy(): Promise<void> {
    const context: common.UIAbilityContext =
      this.getUIContext().getHostContext() as common.UIAbilityContext
    try {
      await context.openLink(Constants.PRIVACY_POLICY_URL)
    } catch (err) {
      this.showToast('暂时无法打开隐私政策')
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

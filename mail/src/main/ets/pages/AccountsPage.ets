import { PromptAction } from '@kit.ArkUI'
import { ApiException } from '../common/HttpClient'
import { HdsNavDestination, HdsNavDestinationTitleMode } from '@kit.UIDesignKit'
import Constants from '../common/Constants'
import { AccountResult, AccountService, ManagedAccount } from '../common/AccountService'
import { AccountCard } from '../components/AccountCard'
import { EmptyState } from '../components/EmptyState'

@Component
export struct AccountsPage {
  private scroller: Scroller = new Scroller()
  @StorageLink('authEmail') authEmail: string = ''
  @StorageLink('accountRevision') @Watch('onAccountRevision') accountRevision: number = 0
  @State accountList: ManagedAccount[] = []
  @State showRegisterDialog: boolean = false
  @State secondaryEmail: string = ''
  @State deleteAccountId: number = 0
  @State deleteAccountEmail: string = ''
  private toast: PromptAction = this.getUIContext().getPromptAction()

  aboutToAppear(): void {
    this.refreshAccounts()
  }

  private onAccountRevision(): void {
    this.refreshAccounts()
  }

  build() {
    HdsNavDestination() {
      Stack() {
        Column() {
          Row() {
            Column() {
              Text('主邮箱与副邮箱')
                .fontSize(Constants.FONT_SIZE_TITLE)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
              Text('副邮箱固定使用 ' + Constants.MAIL_DOMAIN + '，由主邮箱统一收发与管理。')
                .fontSize(Constants.FONT_SIZE_COMMON)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 4 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Button({ type: ButtonType.Circle, stateEffect: true }) {
              SymbolGlyph($r('sys.symbol.plus'))
                .fontSize(Constants.SIZE_ICON_MEDIUM)
                .fontColor([$r('sys.color.icon_on_primary')])
            }
            .width(44)
            .height(44)
            .backgroundColor($r('app.color.primary'))
            .onClick(() => { this.showRegisterDialog = true })
          }
          .width('100%')
          .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 16, bottom: 12 })

          if (this.accountList.length === 0) {
            EmptyState({ icon: $r('sys.symbol.envelope'), message: '暂无邮箱账号' })
          } else {
            List({ scroller: this.scroller }) {
              ForEach(this.accountList, (item: ManagedAccount) => {
                ListItem() {
                  AccountCard({
                    email: item.email,
                    unread: item.unread,
                    total: item.total,
                    isPrimary: item.isPrimary,
                    onDeleteClick: () => { this.openDeleteDialog(item) }
                  })
                }
              }, (item: ManagedAccount): string => item.id.toString())
            }
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.background'))

        if (this.showRegisterDialog) {
          this.RegisterSecondaryEmailDialog()
        }
        if (this.deleteAccountId !== 0) {
          this.DeleteConfirmDialog()
        }
      }
      .width('100%')
      .height('100%')
    }
    .titleBar({ content: { title: { mainTitle: '账号管理' } }, enableComponentSafeArea: true })
    .hideBackButton(false)
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  private RegisterSecondaryEmailDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.overlay'))

      Column({ space: Constants.GAP_MEDIUM }) {
        Text('注册副邮箱')
          .fontSize(Constants.FONT_SIZE_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        Text('副邮箱注册后会自动附属于主邮箱，不需要单独设置密码。')
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
        Row() {
          TextInput({ placeholder: '副邮箱账号', text: this.secondaryEmail })
            .layoutWeight(1)
            .height(48)
            .fontColor($r('app.color.text_primary'))
            .placeholderColor($r('app.color.text_tertiary'))
            .backgroundColor($r('app.color.background'))
            .border({ width: 0.5, color: $r('app.color.divider') })
            .borderRadius(Constants.RADIUS_SMALL)
            .padding({ left: Constants.PADDING_INNER, right: Constants.PADDING_INNER })
            .onChange((value: string) => { this.secondaryEmail = value })
          Text(Constants.MAIL_DOMAIN)
            .fontSize(Constants.FONT_SIZE_COMMON)
            .fontColor($r('app.color.text_secondary'))
            .padding({ left: 8, right: 8 })
        }
        .width('100%')
        .height(48)
        Row() {
          Button('取消', { type: ButtonType.Normal, stateEffect: true })
            .layoutWeight(1)
            .height(44)
            .fontColor($r('app.color.text_primary'))
            .backgroundColor($r('app.color.background'))
            .onClick(() => { this.closeRegisterDialog() })
          Button('注册', { type: ButtonType.Normal, stateEffect: true })
            .layoutWeight(1)
            .height(44)
            .fontColor($r('sys.color.icon_on_primary'))
            .backgroundColor($r('app.color.primary'))
            .margin({ left: Constants.GAP_MEDIUM })
            .onClick(() => { this.registerSecondaryEmail() })
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
  private DeleteConfirmDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.overlay'))

      Column({ space: Constants.GAP_MEDIUM }) {
        Text('删除副邮箱')
          .fontSize(Constants.FONT_SIZE_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        Text('确定删除 ' + this.deleteAccountEmail + ' 吗？删除后不可恢复。')
          .fontSize(Constants.FONT_SIZE_COMMON)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
        Row() {
          Button('取消', { type: ButtonType.Normal, stateEffect: true })
            .layoutWeight(1)
            .height(44)
            .fontColor($r('app.color.text_primary'))
            .backgroundColor($r('app.color.background'))
            .onClick(() => { this.closeDeleteDialog() })
          Button('删除', { type: ButtonType.Normal, stateEffect: true })
            .layoutWeight(1)
            .height(44)
            .fontColor($r('sys.color.icon_on_primary'))
            .backgroundColor($r('app.color.danger'))
            .margin({ left: Constants.GAP_MEDIUM })
            .onClick(() => { this.deleteSecondaryEmail() })
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

  private async refreshAccounts(): Promise<void> {
    try {
      this.accountList = await AccountService.getAccounts(this.authEmail)
    } catch (err) {
      if (err instanceof ApiException) {
        this.showToast(err.message)
      } else {
        this.showToast('加载邮箱账号失败')
      }
    }
  }

  private openDeleteDialog(account: ManagedAccount): void {
    this.deleteAccountId = account.id
    this.deleteAccountEmail = account.email
  }

  private closeDeleteDialog(): void {
    this.deleteAccountId = 0
    this.deleteAccountEmail = ''
  }

  private async deleteSecondaryEmail(): Promise<void> {
    const result: AccountResult = await AccountService.deleteSecondaryEmail(this.deleteAccountId)
    if (!result.success) {
      this.showToast(result.message)
      return
    }
    this.closeDeleteDialog()
    await this.refreshAccounts()
    this.showToast('副邮箱已删除')
  }

  private async registerSecondaryEmail(): Promise<void> {
    if (!this.isValidEmail(this.secondaryEmail)) {
      this.showToast('请输入正确的副邮箱账号')
      return
    }
    const result: AccountResult = await AccountService.registerSecondaryEmail(this.getFullSecondaryEmail())
    if (!result.success) {
      this.showToast(result.message)
      return
    }
    this.closeRegisterDialog()
    await this.refreshAccounts()
    this.showToast('副邮箱注册成功')
  }

  private closeRegisterDialog(): void {
    this.showRegisterDialog = false
    this.secondaryEmail = ''
  }

  private isValidEmail(email: string): boolean {
    const value: string = email.trim()
    return value !== '' && value.indexOf('@') < 0 && value.indexOf(' ') < 0
  }

  private getFullSecondaryEmail(): string {
    return this.secondaryEmail.trim() + Constants.MAIL_DOMAIN
  }

  private showToast(message: string): void {
    try {
      this.toast.openToast({ message: message, duration: 1500 })
    } catch (err) {
      console.error('openToast failed')
    }
  }
}

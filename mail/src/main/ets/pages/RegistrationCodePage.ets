import { PromptAction } from '@kit.ArkUI'
import { HdsNavDestination, HdsNavDestinationTitleMode } from '@kit.UIDesignKit'
import Constants from '../common/Constants'
import { AdminResult, AdminRole, AdminService, RegistrationCode } from '../common/AdminService'
import { EmptyState } from '../components/EmptyState'

@Component
export struct RegistrationCodePage {
  @StorageLink('authRole') authRole: string = 'user'
  @StorageLink('registrationCodeRevision') @Watch('onCodeRevision') codeRevision: number = 0
  @StorageLink('adminRoleRevision') @Watch('onRoleRevision') roleRevision: number = 0
  @State codeList: RegistrationCode[] = []
  @State roleList: AdminRole[] = []
  @State showGenerateDialog: boolean = false
  @State generateCount: string = '1'
  @State selectedRoleId: string = 'user'
  @State deleteCodeId: number = 0
  @State deleteCodeValue: string = ''
  private toast: PromptAction = this.getUIContext().getPromptAction()

  aboutToAppear(): void {
    AdminService.initialize()
    this.refreshData()
  }

  private onCodeRevision(): void {
    this.refreshData()
  }

  private onRoleRevision(): void {
    this.refreshData()
  }

  build() {
    HdsNavDestination() {
      if (this.authRole !== 'admin') {
        EmptyState({ icon: $r('sys.symbol.doc'), message: '仅管理员可访问注册码管理' })
      } else {
        Stack({ alignContent: Alignment.TopStart }) {
          Scroll() {
            Column({ space: Constants.GAP_MEDIUM }) {
              Row() {
                Column() {
                  Text('注册码管理')
                    .fontSize(Constants.FONT_SIZE_TITLE)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.text_primary'))
                  Text('批量生成与分配新用户角色，已使用记录会保留在列表中。')
                    .fontSize(Constants.FONT_SIZE_COMMON)
                    .fontColor($r('app.color.text_secondary'))
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                Button('批量生成', { type: ButtonType.Capsule, stateEffect: true })
                  .height(40)
                  .fontSize(Constants.FONT_SIZE_SMALL)
                  .fontColor($r('sys.color.icon_on_primary'))
                  .backgroundColor($r('app.color.primary'))
                  .onClick(() => { this.openGenerateDialog() })
              }
              .width('100%')

              if (this.codeList.length === 0) {
                EmptyState({ icon: $r('sys.symbol.doc'), message: '暂无注册码', iconSize: 40 })
                  .height(220)
              } else {
                Column({ space: Constants.GAP_SMALL }) {
                  ForEach(this.codeList, (item: RegistrationCode) => {
                    this.CodeCard(item)
                  }, (item: RegistrationCode): string => item.id.toString())
                }
                .width('100%')
              }
              Blank().height(24)
            }
            .width('100%')
            .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 16, bottom: 24 })
          }
          .width('100%')
          .height('100%')
          .align(Alignment.TopStart)
          .scrollBar(BarState.Off)
          if (this.showGenerateDialog) {
            this.GenerateCodeDialog()
          }
          if (this.deleteCodeId !== 0) {
            this.DeleteCodeDialog()
          }
        }
        .width('100%')
        .height('100%')
      }
    }
    .titleBar({ content: { title: { mainTitle: '注册码管理' } }, enableComponentSafeArea: true })
    .hideBackButton(false)
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  private CodeCard(item: RegistrationCode) {
    Column({ space: Constants.GAP_SMALL }) {
      Row() {
        Text(item.code)
          .fontSize(Constants.FONT_SIZE_SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text(item.used ? '已使用' : '未使用')
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor(item.used ? $r('app.color.text_tertiary') : $r('app.color.primary'))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(Constants.RADIUS_FULL)
          .backgroundColor($r('app.color.background'))
      }
      .width('100%')
      Text('注册角色：' + this.getRoleName(item.roleId) + ' · 创建于 ' + item.createdAt)
        .fontSize(Constants.FONT_SIZE_SMALL)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
      if (item.used) {
        Text('使用者：' + item.usedBy)
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
      }
      Button('删除', { type: ButtonType.Normal, stateEffect: true })
        .height(30)
        .fontSize(Constants.FONT_SIZE_SMALL)
        .fontColor($r('app.color.danger'))
        .backgroundColor($r('app.color.background'))
        .onClick(() => { this.openDeleteDialog(item) })
    }
    .width('100%')
    .padding(Constants.PADDING_CARD)
    .backgroundColor($r('app.color.card'))
    .borderRadius(Constants.RADIUS_CARD)
    .shadow(Constants.SHADOW_CARD)
  }

  @Builder
  private GenerateCodeDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.overlay'))
      Column({ space: Constants.GAP_MEDIUM }) {
        Text('批量生成注册码')
          .fontSize(Constants.FONT_SIZE_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        Text('每次可生成 1 到 20 个注册码。')
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
        TextInput({ placeholder: '数量', text: this.generateCount })
          .type(InputType.Number)
          .height(46)
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.text_tertiary'))
          .backgroundColor($r('app.color.background'))
          .border({ width: 0.5, color: $r('app.color.divider') })
          .borderRadius(Constants.RADIUS_SMALL)
          .padding({ left: Constants.PADDING_INNER, right: Constants.PADDING_INNER })
          .onChange((value: string) => { this.generateCount = value })
        Text('注册后角色')
          .fontSize(Constants.FONT_SIZE_SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.roleList, (role: AdminRole) => {
            Button(role.name, { type: ButtonType.Normal, stateEffect: true })
              .height(34)
              .fontSize(Constants.FONT_SIZE_SMALL)
              .fontColor(this.selectedRoleId === role.id ? $r('sys.color.icon_on_primary') : $r('app.color.text_secondary'))
              .backgroundColor(this.selectedRoleId === role.id ? $r('app.color.primary') : $r('app.color.background'))
              .margin({ right: 8, bottom: 8 })
              .onClick(() => { this.selectedRoleId = role.id })
          }, (role: AdminRole): string => role.id)
        }
        .width('100%')
        Row() {
          Button('取消', { type: ButtonType.Normal, stateEffect: true })
            .layoutWeight(1)
            .height(44)
            .fontColor($r('app.color.text_primary'))
            .backgroundColor($r('app.color.background'))
            .onClick(() => { this.closeGenerateDialog() })
          Button('生成', { type: ButtonType.Normal, stateEffect: true })
            .layoutWeight(1)
            .height(44)
            .fontColor($r('sys.color.icon_on_primary'))
            .backgroundColor($r('app.color.primary'))
            .margin({ left: Constants.GAP_MEDIUM })
            .onClick(() => { this.generateCodes() })
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
  private DeleteCodeDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.overlay'))
      Column({ space: Constants.GAP_MEDIUM }) {
        Text('删除注册码')
          .fontSize(Constants.FONT_SIZE_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        Text('确定删除 ' + this.deleteCodeValue + ' 吗？')
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
            .onClick(() => { this.deleteCode() })
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

  private async refreshData(): Promise<void> {
    try {
      this.codeList = await AdminService.getRegistrationCodes()
      this.roleList = await AdminService.getRoles()
    } catch (err) {
      this.showToast('加载注册码数据失败')
    }
  }

  private openGenerateDialog(): void {
    this.generateCount = '1'
    this.selectedRoleId = this.getDefaultRoleId()
    this.showGenerateDialog = true
  }

  private closeGenerateDialog(): void {
    this.showGenerateDialog = false
  }

  private async generateCodes(): Promise<void> {
    const count: number = Number(this.generateCount)
    if (count !== Math.floor(count)) {
      this.showToast('请输入正确的生成数量')
      return
    }
    const result: AdminResult = await AdminService.generateRegistrationCodes(count, this.selectedRoleId)
    if (!result.success) {
      this.showToast(result.message)
      return
    }
    this.closeGenerateDialog()
    await this.refreshData()
    this.showToast('注册码已生成')
  }

  private openDeleteDialog(code: RegistrationCode): void {
    this.deleteCodeId = code.id
    this.deleteCodeValue = code.code
  }

  private closeDeleteDialog(): void {
    this.deleteCodeId = 0
    this.deleteCodeValue = ''
  }

  private async deleteCode(): Promise<void> {
    const result: AdminResult = await AdminService.deleteRegistrationCode(this.deleteCodeId)
    if (!result.success) {
      this.showToast(result.message)
      return
    }
    this.closeDeleteDialog()
    await this.refreshData()
    this.showToast('注册码已删除')
  }

  private getRoleName(roleId: string): string {
    for (let i = 0; i < this.roleList.length; i++) {
      if (this.roleList[i].id === roleId) {
        return this.roleList[i].name
      }
    }
    return '未知角色'
  }

  private getDefaultRoleId(): string {
    for (let i = 0; i < this.roleList.length; i++) {
      if (this.roleList[i].isDefault) {
        return this.roleList[i].id
      }
    }
    return 'user'
  }

  private showToast(message: string): void {
    try {
      this.toast.openToast({ message: message, duration: 1500 })
    } catch (err) {
      console.error('openToast failed')
    }
  }
}

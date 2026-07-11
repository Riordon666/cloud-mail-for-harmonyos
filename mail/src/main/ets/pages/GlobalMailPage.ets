import { PromptAction } from '@kit.ArkUI'
import { HdsNavDestination, HdsNavDestinationTitleMode } from '@kit.UIDesignKit'
import Constants from '../common/Constants'
import { AdminResult, AdminService, GlobalMail } from '../common/AdminService'
import { EmptyState } from '../components/EmptyState'

@Component
export struct GlobalMailPage {
  @StorageLink('authRole') authRole: string = 'user'
  @StorageLink('adminMailRevision') @Watch('onMailRevision') mailRevision: number = 0
  @State mailList: GlobalMail[] = []
  @State senderKeyword: string = ''
  @State recipientKeyword: string = ''
  @State subjectKeyword: string = ''
  @State timeFilter: string = '全部'
  @State selectedMailIds: number[] = []
  @State deleteMailIds: number[] = []
  private toast: PromptAction = this.getUIContext().getPromptAction()

  aboutToAppear(): void {
    AdminService.initialize()
    this.refreshMails()
  }

  private onMailRevision(): void {
    this.refreshMails()
  }

  build() {
    HdsNavDestination() {
      if (this.authRole !== 'admin') {
        EmptyState({ icon: $r('sys.symbol.envelope'), message: '仅管理员可访问全部邮件' })
      } else {
        Stack() {
          Scroll() {
            Column({ space: Constants.GAP_MEDIUM }) {
              Text('全部邮件')
                .fontSize(Constants.FONT_SIZE_TITLE)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
              Text('按发件人、收件人、主题和时间筛选；删除操作会立即从管理列表移除。')
                .fontSize(Constants.FONT_SIZE_COMMON)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')

              Column({ space: Constants.GAP_SMALL }) {
                TextInput({ placeholder: '发件人', text: this.senderKeyword })
                  .height(44)
                  .fontColor($r('app.color.text_primary'))
                  .placeholderColor($r('app.color.text_tertiary'))
                  .backgroundColor($r('app.color.card'))
                  .border({ width: 0.5, color: $r('app.color.divider') })
                  .borderRadius(Constants.RADIUS_SMALL)
                  .padding({ left: Constants.PADDING_INNER, right: Constants.PADDING_INNER })
                  .onChange((value: string) => { this.senderKeyword = value })
                TextInput({ placeholder: '收件人', text: this.recipientKeyword })
                  .height(44)
                  .fontColor($r('app.color.text_primary'))
                  .placeholderColor($r('app.color.text_tertiary'))
                  .backgroundColor($r('app.color.card'))
                  .border({ width: 0.5, color: $r('app.color.divider') })
                  .borderRadius(Constants.RADIUS_SMALL)
                  .padding({ left: Constants.PADDING_INNER, right: Constants.PADDING_INNER })
                  .onChange((value: string) => { this.recipientKeyword = value })
                TextInput({ placeholder: '主题', text: this.subjectKeyword })
                  .height(44)
                  .fontColor($r('app.color.text_primary'))
                  .placeholderColor($r('app.color.text_tertiary'))
                  .backgroundColor($r('app.color.card'))
                  .border({ width: 0.5, color: $r('app.color.divider') })
                  .borderRadius(Constants.RADIUS_SMALL)
                  .padding({ left: Constants.PADDING_INNER, right: Constants.PADDING_INNER })
                  .onChange((value: string) => { this.subjectKeyword = value })
              }
              .width('100%')

              Row({ space: Constants.GAP_SMALL }) {
                this.TimeFilterButton('全部')
                this.TimeFilterButton('今天')
                this.TimeFilterButton('本周')
              }
              .width('100%')

              Row() {
                Toggle({ type: ToggleType.Checkbox, isOn: this.isAllFilteredSelected() })
                  .selectedColor($r('app.color.primary'))
                  .onChange((selected: boolean) => { this.toggleAllFiltered(selected) })
                Text('全选当前结果（已选 ' + this.selectedMailIds.length.toString() + ' 封）')
                  .fontSize(Constants.FONT_SIZE_SMALL)
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ left: 8 })
                Blank()
                Button('批量删除', { type: ButtonType.Normal, stateEffect: true })
                  .height(34)
                  .enabled(this.selectedMailIds.length > 0)
                  .fontSize(Constants.FONT_SIZE_SMALL)
                  .fontColor($r('app.color.danger'))
                  .backgroundColor($r('app.color.card'))
                  .onClick(() => { this.openBatchDeleteDialog() })
              }
              .width('100%')

              if (this.getFilteredMails().length === 0) {
                EmptyState({ icon: $r('sys.symbol.envelope'), message: '没有匹配的邮件', iconSize: 40 })
                  .height(220)
              } else {
                Column({ space: Constants.GAP_SMALL }) {
                  ForEach(this.getFilteredMails(), (item: GlobalMail) => {
                    this.MailCard(item)
                  }, (item: GlobalMail): string => item.id.toString())
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
          .scrollBar(BarState.Off)

          if (this.deleteMailIds.length > 0) {
            this.DeleteMailDialog()
          }
        }
        .width('100%')
        .height('100%')
      }
    }
    .titleBar({ content: { title: { mainTitle: '全部邮件' } }, enableComponentSafeArea: true })
    .hideBackButton(false)
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  private TimeFilterButton(label: string) {
    Button(label, { type: ButtonType.Normal, stateEffect: true })
      .height(32)
      .fontSize(Constants.FONT_SIZE_SMALL)
      .fontColor(this.timeFilter === label ? $r('sys.color.icon_on_primary') : $r('app.color.text_secondary'))
      .backgroundColor(this.timeFilter === label ? $r('app.color.primary') : $r('app.color.card'))
      .borderRadius(Constants.RADIUS_FULL)
      .padding({ left: 12, right: 12 })
      .onClick(() => { this.timeFilter = label })
  }

  @Builder
  private MailCard(item: GlobalMail) {
    Row() {
      Toggle({ type: ToggleType.Checkbox, isOn: this.isMailSelected(item.id) })
        .selectedColor($r('app.color.primary'))
        .onChange((selected: boolean) => { this.toggleMail(item.id, selected) })
        .margin({ right: 10 })
      Column() {
        Row() {
          Text(item.subject)
            .fontSize(Constants.FONT_SIZE_SUBTITLE)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(item.time)
            .fontSize(Constants.FONT_SIZE_SMALL)
            .fontColor($r('app.color.text_tertiary'))
            .margin({ left: 8 })
        }
        .width('100%')
        Text('发：' + item.sender)
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 5 })
        Text('收：' + item.recipient)
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 3 })
        Button('删除', { type: ButtonType.Normal, stateEffect: true })
          .height(30)
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.danger'))
          .backgroundColor($r('app.color.background'))
          .margin({ top: 8 })
          .onClick(() => { this.openSingleDeleteDialog(item.id) })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(Constants.PADDING_CARD)
    .backgroundColor($r('app.color.card'))
    .borderRadius(Constants.RADIUS_CARD)
    .shadow(Constants.SHADOW_CARD)
  }

  @Builder
  private DeleteMailDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.overlay'))
      Column({ space: Constants.GAP_MEDIUM }) {
        Text('删除邮件')
          .fontSize(Constants.FONT_SIZE_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        Text('确定删除选中的 ' + this.deleteMailIds.length.toString() + ' 封邮件吗？此操作会立即生效。')
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
            .onClick(() => { this.deleteMails() })
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

  private async refreshMails(): Promise<void> {
    try {
      this.mailList = await AdminService.getMails()
      this.removeMissingSelections()
    } catch (err) {
      this.showToast('加载邮件数据失败')
    }
  }

  private getFilteredMails(): GlobalMail[] {
    const result: GlobalMail[] = []
    const sender: string = this.senderKeyword.trim().toLowerCase()
    const recipient: string = this.recipientKeyword.trim().toLowerCase()
    const subject: string = this.subjectKeyword.trim().toLowerCase()
    for (let i = 0; i < this.mailList.length; i++) {
      const mail: GlobalMail = this.mailList[i]
      if (mail.deleted) {
        continue
      }
      if (sender !== '' && mail.sender.toLowerCase().indexOf(sender) < 0) {
        continue
      }
      if (recipient !== '' && mail.recipient.toLowerCase().indexOf(recipient) < 0) {
        continue
      }
      if (subject !== '' && mail.subject.toLowerCase().indexOf(subject) < 0) {
        continue
      }
      if (this.timeFilter === '今天' && mail.time.indexOf('今天') !== 0) {
        continue
      }
      if (this.timeFilter === '本周' && mail.time.indexOf('周') < 0 && mail.time.indexOf('今天') < 0 && mail.time.indexOf('昨天') < 0) {
        continue
      }
      result.push(mail)
    }
    return result
  }

  private isMailSelected(mailId: number): boolean {
    for (let i = 0; i < this.selectedMailIds.length; i++) {
      if (this.selectedMailIds[i] === mailId) {
        return true
      }
    }
    return false
  }

  private isAllFilteredSelected(): boolean {
    const filtered: GlobalMail[] = this.getFilteredMails()
    if (filtered.length === 0) {
      return false
    }
    for (let i = 0; i < filtered.length; i++) {
      if (!this.isMailSelected(filtered[i].id)) {
        return false
      }
    }
    return true
  }

  private toggleMail(mailId: number, selected: boolean): void {
    const result: number[] = []
    let exists: boolean = false
    for (let i = 0; i < this.selectedMailIds.length; i++) {
      const selectedId: number = this.selectedMailIds[i]
      if (selectedId === mailId) {
        exists = true
        if (selected) {
          result.push(selectedId)
        }
      } else {
        result.push(selectedId)
      }
    }
    if (selected && !exists) {
      result.push(mailId)
    }
    this.selectedMailIds = result
  }

  private toggleAllFiltered(selected: boolean): void {
    const filtered: GlobalMail[] = this.getFilteredMails()
    if (selected) {
      const next: number[] = []
      for (let i = 0; i < this.selectedMailIds.length; i++) {
        next.push(this.selectedMailIds[i])
      }
      for (let i = 0; i < filtered.length; i++) {
        if (!this.isMailSelected(filtered[i].id)) {
          next.push(filtered[i].id)
        }
      }
      this.selectedMailIds = next
      return
    }
    const next: number[] = []
    for (let i = 0; i < this.selectedMailIds.length; i++) {
      let stillSelected: boolean = true
      for (let j = 0; j < filtered.length; j++) {
        if (this.selectedMailIds[i] === filtered[j].id) {
          stillSelected = false
          break
        }
      }
      if (stillSelected) {
        next.push(this.selectedMailIds[i])
      }
    }
    this.selectedMailIds = next
  }

  private openSingleDeleteDialog(mailId: number): void {
    this.deleteMailIds = [mailId]
  }

  private openBatchDeleteDialog(): void {
    const ids: number[] = []
    for (let i = 0; i < this.selectedMailIds.length; i++) {
      ids.push(this.selectedMailIds[i])
    }
    this.deleteMailIds = ids
  }

  private closeDeleteDialog(): void {
    this.deleteMailIds = []
  }

  private async deleteMails(): Promise<void> {
    const result: AdminResult = await AdminService.deleteMails(this.deleteMailIds)
    if (!result.success) {
      this.showToast(result.message)
      return
    }
    this.closeDeleteDialog()
    await this.refreshMails()
    this.showToast('邮件已删除')
  }

  private removeMissingSelections(): void {
    const next: number[] = []
    for (let i = 0; i < this.selectedMailIds.length; i++) {
      for (let j = 0; j < this.mailList.length; j++) {
        if (this.selectedMailIds[i] === this.mailList[j].id && !this.mailList[j].deleted) {
          next.push(this.selectedMailIds[i])
          break
        }
      }
    }
    this.selectedMailIds = next
  }

  private showToast(message: string): void {
    try {
      this.toast.openToast({ message: message, duration: 1500 })
    } catch (err) {
      console.error('openToast failed')
    }
  }
}

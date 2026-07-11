import Constants from '../common/Constants'
import { ApiException } from '../common/HttpClient'
import { MailDetailParams, MailItem } from '../common/MailModels'
import { MailService } from '../common/MailService'
import { PromptAction } from '@kit.ArkUI'
import { EmailCard } from '../components/EmailCard'

@Component
export struct InboxPage {
  private scroller: Scroller = new Scroller()
  private searchController: SearchController = new SearchController()
  @State searchText: string = ''
  @State isSearchFocused: boolean = false
  @State emailList: MailItem[] = []
  @State isLoading: boolean = false
  @State refreshKey: number = 0
  private pathStack: NavPathStack = AppStorage.get('appPathStack') as NavPathStack
  private toast: PromptAction = this.getUIContext().getPromptAction()

  aboutToAppear(): void {
    this.loadEmails()
  }

  private async loadEmails(): Promise<void> {
    this.isLoading = true
    try {
      this.emailList = await MailService.loadInbox()
    } catch (err) {
      this.showRequestError(err)
    } finally {
      this.isLoading = false
    }
  }

  private getFiltered(): MailItem[] {
    if (this.searchText.trim() === '') {
      return this.emailList
    }
    return this.emailList.filter((item: MailItem) =>
      item.name.toLowerCase().includes(this.searchText.toLowerCase()) ||
      item.subject.toLowerCase().includes(this.searchText.toLowerCase())
    )
  }

  private async markAsRead(id: number): Promise<void> {
    try {
      await MailService.markRead(id)
      this.replaceUnread(id, false)
    } catch (err) {
      this.showRequestError(err)
    }
  }

  private async toggleStar(id: number, starred: boolean): Promise<void> {
    const nextStarred: boolean = !starred
    try {
      await MailService.setStar(id, nextStarred)
      this.replaceStarred(id, nextStarred)
      this.showToast(nextStarred ? '已加入星标' : '已取消星标')
    } catch (err) {
      this.showRequestError(err)
    }
  }

  private async deleteEmail(id: number): Promise<void> {
    try {
      await MailService.delete(id)
      const result: MailItem[] = []
      for (let index = 0; index < this.emailList.length; index++) {
        if (this.emailList[index].id !== id) {
          result.push(this.emailList[index])
        }
      }
      this.emailList = result
      this.showToast('邮件已删除')
    } catch (err) {
      this.showRequestError(err)
    }
  }

  private openDetail(item: MailItem, index: number): void {
    if (item.unread) {
      this.markAsRead(item.id)
    }
    const filtered: MailItem[] = this.getFiltered()
    const params: MailDetailParams = new MailDetailParams(item, filtered, index)
    this.pathStack.pushPathByName('DetailPage', params)
  }

  private replaceUnread(id: number, unread: boolean): void {
    const result: MailItem[] = []
    for (let index = 0; index < this.emailList.length; index++) {
      const source: MailItem = this.emailList[index]
      const next: MailItem = source.copy()
      if (next.id === id) {
        next.unread = unread
      }
      result.push(next)
    }
    this.emailList = result
    this.refreshKey++
  }

  private replaceStarred(id: number, starred: boolean): void {
    const result: MailItem[] = []
    for (let index = 0; index < this.emailList.length; index++) {
      const source: MailItem = this.emailList[index]
      const next: MailItem = source.copy()
      if (next.id === id) {
        next.starred = starred
      }
      result.push(next)
    }
    this.emailList = result
    this.refreshKey++
  }

  private showRequestError(err: Error): void {
    if (err instanceof ApiException) {
      this.showToast(err.message)
      return
    }
    this.showToast('请求失败，请稍后重试')
  }

  private showToast(message: string): void {
    try {
      this.toast.openToast({ message: message, duration: 1500 })
    } catch (err) {
      console.error('openToast failed')
    }
  }

  build() {
    Column() {
      Text('收件箱')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 16, bottom: 8 })
        .width('100%')

      Search({ value: this.searchText, placeholder: '搜索邮件', controller: this.searchController })
        .searchIcon({ src: $r('sys.media.ohos_ic_public_search_filled'), size: 20 })
        .cancelButton({
          style: CancelButtonStyle.INPUT,
          icon: { size: 18, color: $r('app.color.text_tertiary'), src: '' }
        })
        .placeholderColor($r('app.color.text_tertiary'))
        .fontColor($r('app.color.text_primary'))
        .backgroundColor($r('app.color.card'))
        .border({
          width: this.isSearchFocused ? 1 : 0.5,
          color: this.isSearchFocused ? $r('app.color.primary') : $r('app.color.divider')
        })
        .borderRadius(Constants.RADIUS_BUTTON)
        .shadow(Constants.SHADOW_CARD)
        .height(48)
        .margin({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, bottom: 8 })
        .animation({ duration: Constants.DURATION_NORMAL, curve: Curve.EaseOut })
        .onChange((value: string) => { this.searchText = value })
        .onFocus(() => { this.isSearchFocused = true })
        .onBlur(() => { this.isSearchFocused = false })

      if (this.isLoading) {
        Column() {
          Text('正在加载邮件…')
            .fontSize(Constants.FONT_SIZE_SUBTITLE)
            .fontColor($r('app.color.text_tertiary'))
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.getFiltered().length === 0) {
        Column() {
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontSize(48)
            .fontColor([$r('app.color.text_tertiary')])
          Text(this.searchText !== '' ? '未找到相关邮件' : '暂无邮件')
            .fontSize(Constants.FONT_SIZE_SUBTITLE)
            .fontColor($r('app.color.text_tertiary'))
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ scroller: this.scroller }) {
          ForEach(this.getFiltered(), (item: MailItem, index: number) => {
            ListItem() {
              EmailCard({
                name: item.name,
                subject: item.subject,
                time: item.time,
                unread: item.unread,
                onCardClick: () => { this.openDetail(item, index) }
              })
            }
            .swipeAction({
              end: {
                builder: () => { this.SwipeActions(item.id, item.unread, item.starred) },
                actionAreaDistance: 180
              },
              edgeEffect: SwipeEdgeEffect.Spring
            })
          }, (item: MailItem): string => item.id.toString() + '_' + item.unread.toString() + '_' + item.starred.toString() + '_' + this.refreshKey.toString())
          ListItem() {
            Column().height(Constants.PADDING_TAB_CONTENT_BOTTOM)
          }
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
  }

  @Builder SwipeActions(id: number, unread: boolean, starred: boolean) {
    Row() {
      if (unread) {
        Button() {
          Column() {
            SymbolGlyph($r('sys.symbol.checkmark'))
              .fontSize(20)
              .fontColor([Color.White])
            Text('已读')
              .fontSize(12)
              .fontColor(Color.White)
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        .width(60)
        .height('100%')
        .backgroundColor($r('app.color.success'))
        .onClick(() => { this.markAsRead(id) })
      }

      Button() {
        Column() {
          SymbolGlyph(starred ? $r('sys.symbol.star_slash') : $r('sys.symbol.star'))
            .fontSize(20)
            .fontColor([Color.White])
          Text(starred ? '取消标' : '星标')
            .fontSize(12)
            .fontColor(Color.White)
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width(60)
      .height('100%')
      .backgroundColor(starred ? $r('app.color.text_tertiary') : $r('app.color.warning'))
      .onClick(() => { this.toggleStar(id, starred) })

      Button() {
        Column() {
          SymbolGlyph($r('sys.symbol.trash'))
            .fontSize(20)
            .fontColor([Color.White])
          Text('删除')
            .fontSize(12)
            .fontColor(Color.White)
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width(60)
      .height('100%')
      .backgroundColor($r('app.color.danger'))
      .onClick(() => { this.deleteEmail(id) })
    }
    .height('100%')
  }
}

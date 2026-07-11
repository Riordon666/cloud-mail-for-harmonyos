import Constants from '../common/Constants'
import { ApiException } from '../common/HttpClient'
import { MailDetailParams, MailItem } from '../common/MailModels'
import { MailService } from '../common/MailService'
import { PromptAction } from '@kit.ArkUI'
import { EmailCard } from '../components/EmailCard'
import { EmptyState } from '../components/EmptyState'

@Component
export struct StarredPage {
  private scroller: Scroller = new Scroller()
  private pathStack: NavPathStack = AppStorage.get('appPathStack') as NavPathStack
  private toast: PromptAction = this.getUIContext().getPromptAction()
  @State starList: MailItem[] = []
  @State isLoading: boolean = false

  aboutToAppear(): void {
    this.loadStarredEmails()
  }

  private async loadStarredEmails(): Promise<void> {
    this.isLoading = true
    try {
      this.starList = await MailService.loadStarred()
    } catch (err) {
      this.showRequestError(err)
    } finally {
      this.isLoading = false
    }
  }

  private openDetail(item: MailItem, index: number): void {
    const params: MailDetailParams = new MailDetailParams(item, this.starList, index)
    this.pathStack.pushPathByName('DetailPage', params)
  }

  private async cancelStar(id: number): Promise<void> {
    try {
      await MailService.setStar(id, false)
      const result: MailItem[] = []
      for (let index = 0; index < this.starList.length; index++) {
        if (this.starList[index].id !== id) {
          result.push(this.starList[index])
        }
      }
      this.starList = result
      this.showToast('已取消星标')
    } catch (err) {
      this.showRequestError(err)
    }
  }

  private showRequestError(err: Error): void {
    const message: string = err instanceof ApiException ? err.message : '请求失败，请稍后重试'
    this.showToast(message)
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
      Text('星标邮件')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 16, bottom: 8 })
        .width('100%')

      if (this.isLoading) {
        EmptyState({ icon: $r('sys.symbol.star'), message: '正在加载邮件…' })
      } else if (this.starList.length === 0) {
        EmptyState({ icon: $r('sys.symbol.star'), message: '暂无星标邮件' })
      } else {
        List({ scroller: this.scroller }) {
          ForEach(this.starList, (item: MailItem, index: number) => {
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
                builder: () => { this.StarSwipeAction(item.id) },
                actionAreaDistance: 80
              },
              edgeEffect: SwipeEdgeEffect.Spring
            })
          }, (item: MailItem): string => item.id.toString())
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

  @Builder StarSwipeAction(id: number) {
    Row() {
      Button() {
        Column() {
          SymbolGlyph($r('sys.symbol.star_slash'))
            .fontSize(20)
            .fontColor([Color.White])
          Text('取消星标')
            .fontSize(12)
            .fontColor(Color.White)
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width(80)
      .height('100%')
      .backgroundColor($r('app.color.warning'))
      .onClick(() => { this.cancelStar(id) })
    }
    .height('100%')
  }
}

import Constants from '../common/Constants'
import { ApiException } from '../common/HttpClient'
import { MailDetailParams, MailItem } from '../common/MailModels'
import { MailService } from '../common/MailService'
import { MailListDataSource } from '../common/MailListDataSource'
import { PromptAction } from '@kit.ArkUI'
import { EmailCard } from '../components/EmailCard'
import { EmptyState } from '../components/EmptyState'

@Component
export struct StarredPage {
  private scroller: Scroller = new Scroller()
  private dataSource: MailListDataSource = new MailListDataSource()
  private pathStack: NavPathStack = AppStorage.get('appPathStack') as NavPathStack
  private toast: PromptAction = this.getUIContext().getPromptAction()
  @StorageLink('mailRevision') @Watch('onMailRevision') mailRevision: number = 0
  @State starList: MailItem[] = []
  @State isLoading: boolean = false

  aboutToAppear(): void {
    this.loadStarredEmails()
  }

  private onMailRevision(): void {
    this.loadStarredEmails(false)
  }

  private async loadStarredEmails(showLoading: boolean = true): Promise<void> {
    if (showLoading) {
      this.isLoading = true
    }
    try {
      this.starList = await MailService.loadStarred()
      this.dataSource.setData(this.starList)
    } catch (err) {
      this.showRequestError(err)
    } finally {
      if (showLoading) {
        this.isLoading = false
      }
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
      this.dataSource.removeItem(id)
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
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.isLoading) {
        Column() {
          EmptyState({ icon: $r('sys.symbol.star'), message: '正在加载邮件…' })
        }
        .width('100%')
        .height('100%')
        .padding({ top: 56 })
      } else if (this.starList.length === 0) {
        Column() {
          EmptyState({ icon: $r('sys.symbol.star'), message: '暂无星标邮件' })
        }
        .width('100%')
        .height('100%')
        .padding({ top: 56 })
      } else {
        List({ scroller: this.scroller }) {
          ListItem() {
            Column().height(56)
          }
          LazyForEach(this.dataSource, (item: MailItem, index: number) => {
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
        .height('100%')
        .scrollBar(BarState.Off)
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
      }

      Stack({ alignContent: Alignment.BottomStart }) {
        Row()
          .width('100%')
          .height('100%')
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

        Text('星标邮件')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 16, bottom: 8 })
          .width('100%')
      }
      .width('100%')
      .height(56)
        .zIndex(1)
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

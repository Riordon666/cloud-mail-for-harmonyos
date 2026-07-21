import Constants from '../common/Constants'
import { ApiException } from '../common/HttpClient'
import { MailDetailParams, MailItem } from '../common/MailModels'
import { MailService } from '../common/MailService'
import { MailListDataSource } from '../common/MailListDataSource'
import { PromptAction } from '@kit.ArkUI'
import { EmailCard } from '../components/EmailCard'
import { EmptyState } from '../components/EmptyState'

@Component
export struct SentPage {
  private scroller: Scroller = new Scroller()
  private dataSource: MailListDataSource = new MailListDataSource()
  private pathStack: NavPathStack = AppStorage.get('appPathStack') as NavPathStack
  private toast: PromptAction = this.getUIContext().getPromptAction()
  @State sentList: MailItem[] = []
  @State isLoading: boolean = false
  @State isHeaderBlurred: boolean = false

  aboutToAppear(): void {
    this.loadSentEmails()
  }

  private async loadSentEmails(): Promise<void> {
    this.isLoading = true
    try {
      this.sentList = await MailService.loadSent()
      this.dataSource.setData(this.sentList)
    } catch (err) {
      this.showRequestError(err)
    } finally {
      this.isLoading = false
    }
  }

  private openDetail(item: MailItem, index: number): void {
    const params: MailDetailParams = new MailDetailParams(item, this.sentList, index)
    this.pathStack.pushPathByName('DetailPage', params)
  }

  private showRequestError(err: Error): void {
    const message: string = err instanceof ApiException ? err.message : '请求失败，请稍后重试'
    try {
      this.toast.openToast({ message: message, duration: 1500 })
    } catch (toastErr) {
      console.error('openToast failed')
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.isLoading) {
        Column() {
          EmptyState({ icon: $r('sys.symbol.paperplane'), message: '正在加载邮件…' })
        }
        .width('100%')
        .height('100%')
        .padding({ top: 56 })
      } else if (this.sentList.length === 0) {
        Column() {
          EmptyState({ icon: $r('sys.symbol.paperplane'), message: '暂无已发送邮件' })
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
                unread: false,
                status: '已发送',
                onCardClick: () => { this.openDetail(item, index) }
              })
            }
          }, (item: MailItem): string => item.id.toString())
          ListItem() {
            Column().height(Constants.PADDING_TAB_CONTENT_BOTTOM)
          }
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
        .onDidScroll(() => {
          this.isHeaderBlurred = this.scroller.currentOffset().yOffset > 0
        })
        .onReachStart(() => { this.isHeaderBlurred = false })
      }

      Stack({ alignContent: Alignment.BottomStart }) {
        if (this.isHeaderBlurred) {
          Row()
            .width('100%')
            .height('100%')
            .backgroundEffect({
              radius: 30,
              saturation: 1.0,
              brightness: 1.0,
              color: $r('app.color.glass_surface')
            })
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
        } else {
          Row()
            .width('100%')
            .height('100%')
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
        }

        Text('已发送')
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
}

import Constants from '../common/Constants'
import { MOCK_EMAILS, EmailMock, getStarredIds, toggleEmailStar } from '../common/MockData'
import { promptAction } from '@kit.ArkUI'
import { EmailCard } from '../components/EmailCard'

class DetailParams {
  emailData: EmailMock
  emailList: EmailMock[]
  currentIndex: number
  constructor(emailData: EmailMock, emailList: EmailMock[], currentIndex: number) {
    this.emailData = emailData
    this.emailList = emailList
    this.currentIndex = currentIndex
  }
}

@Component
export struct StarredPage {
  private scroller: Scroller = new Scroller()
  @StorageLink('starredIds') @Watch('onStarredChange') starredIds: number[] = []
  @State starList: EmailMock[] = []
  private pathStack: NavPathStack = AppStorage.get('appPathStack') as NavPathStack

  aboutToAppear(): void {
    this.buildStarList()
  }

  private onStarredChange(): void {
    this.buildStarList()
  }

  private buildStarList(): void {
    const ids: number[] = getStarredIds()
    const result: EmailMock[] = []
    for (let i = 0; i < ids.length; i++) {
      const found: EmailMock | undefined = MOCK_EMAILS.find((e: EmailMock) => e.id === ids[i])
      if (found !== undefined) { result.push(found) }
    }
    this.starList = result
  }

  private openDetail(item: EmailMock, index: number): void {
    const params: DetailParams = new DetailParams(item, this.starList, index)
    this.pathStack.pushPathByName('DetailPage', params)
  }

  build() {
    Column() {
      Text('星标邮件')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 16, bottom: 8 })
        .width('100%')

      if (this.starList.length === 0) {
        Column() {
          SymbolGlyph($r('sys.symbol.star'))
            .fontSize(48)
            .fontColor([$r('app.color.text_tertiary')])
          Text('暂无星标邮件')
            .fontSize(16)
            .fontColor($r('app.color.text_tertiary'))
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ scroller: this.scroller }) {
          ForEach(this.starList, (item: EmailMock, index: number) => {
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
          }, (item: EmailMock): string => item.id.toString())
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
      .backgroundColor('#FF9500')
      .onClick(() => {
        toggleEmailStar(id)
        promptAction.showToast({ message: '已取消星标', duration: 1500 })
      })
    }
    .height('100%')
  }
}

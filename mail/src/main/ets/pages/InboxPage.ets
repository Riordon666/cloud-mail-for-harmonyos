import Constants from '../common/Constants'
import { MOCK_EMAILS, EmailMock } from '../common/MockData'
import { EmailCard } from '../components/EmailCard'

@Component
export struct InboxPage {
  private scroller: Scroller = new Scroller()
  @State searchText: string = ''
  @State emailList: EmailMock[] = MOCK_EMAILS

  aboutToAppear(): void {
    this.emailList = MOCK_EMAILS
  }

  private getFiltered(): EmailMock[] {
    if (this.searchText.trim() === '') {
      return this.emailList
    }
    return this.emailList.filter((e: EmailMock) =>
      e.name.toLowerCase().includes(this.searchText.toLowerCase()) ||
      e.subject.toLowerCase().includes(this.searchText.toLowerCase())
    )
  }

  private markAsRead(id: number): void {
    const newList: EmailMock[] = []
    for (let i = 0; i < this.emailList.length; i++) {
      const e = this.emailList[i]
      if (e.id === id) {
        newList.push({
          id: e.id, name: e.name, email: e.email,
          subject: e.subject, body: e.body, time: e.time,
          unread: false, cc: e.cc, bcc: e.bcc,
          attList: e.attList, htmlContent: e.htmlContent
        })
      } else {
        newList.push(e)
      }
    }
    this.emailList = newList
  }

  private deleteEmail(id: number): void {
    const newList: EmailMock[] = []
    for (let i = 0; i < this.emailList.length; i++) {
      if (this.emailList[i].id !== id) {
        newList.push(this.emailList[i])
      }
    }
    this.emailList = newList
  }

  build() {
    Column() {
      Row() {
        Search({ placeholder: '搜索邮件', value: this.searchText })
          .placeholderColor($r('app.color.text_tertiary'))
          .fontColor($r('app.color.text_primary'))
          .backgroundColor($r('app.color.card'))
          .borderRadius(Constants.RADIUS_BUTTON)
          .height(48)
          .layoutWeight(1)
          .cancelButton({ style: CancelButtonStyle.INPUT })
          .onChange((value: string) => {
            this.searchText = value
          })
      }
      .width('100%')
      .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 0, bottom: 8 })

      if (this.getFiltered().length === 0) {
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
          ForEach(this.getFiltered(), (item: EmailMock, index: number) => {
            ListItem() {
              EmailCard({
                name: item.name,
                subject: item.subject,
                time: item.time,
                unread: item.unread
              })
            }
            .swipeAction({
              end: {
                builder: () => { this.SwipeActions(item.id, item.unread) },
                actionAreaDistance: 180,
                onStateChange: (state: SwipeActionState) => {
                  if (state === SwipeActionState.ACTIONING) {
                    this.deleteEmail(item.id)
                  }
                }
              },
              edgeEffect: SwipeEdgeEffect.Spring
            })
          }, (item: EmailMock): string => item.id.toString() + '_' + item.unread.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
        .onReachEnd(() => {
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder SwipeActions(id: number, unread: boolean) {
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
        .backgroundColor('#34C759')
        .onClick(() => {
          this.markAsRead(id)
        })
      }

      Button() {
        Column() {
          SymbolGlyph($r('sys.symbol.star'))
            .fontSize(20)
            .fontColor([Color.White])
          Text('星标')
            .fontSize(12)
            .fontColor(Color.White)
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width(60)
      .height('100%')
      .backgroundColor('#FF9500')
      .onClick(() => {
      })

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
      .onClick(() => {
        this.deleteEmail(id)
      })
    }
    .height('100%')
  }
}

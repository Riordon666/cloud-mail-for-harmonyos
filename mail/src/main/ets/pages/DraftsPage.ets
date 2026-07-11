import Constants from '../common/Constants'
import { EmptyState } from '../components/EmptyState'
import { ComposeParams } from './ComposePage'

interface DraftItem {
  id: number
  subject: string
  toEmail: string
  content: string
  time: string
}

@Component
export struct DraftsPage {
  private scroller: Scroller = new Scroller()
  private pathStack: NavPathStack = AppStorage.get('appPathStack') as NavPathStack
  @State draftList: DraftItem[] = [
    { id: 1, subject: '关于下季度 OKR 的草稿', toEmail: 'team@example.com', content: '各位好，以下是下季度的 OKR 草案...', time: '昨天' },
    { id: 2, subject: '请假申请草稿', toEmail: 'hr@example.com', content: '您好，我需要申请...', time: '周一' }
  ]

  private deleteDraft(index: number): void {
    const nextDraftList: DraftItem[] = []
    for (let i = 0; i < this.draftList.length; i++) {
      if (i !== index) {
        nextDraftList.push(this.draftList[i])
      }
    }
    this.draftList = nextDraftList
  }

  private editDraft(item: DraftItem): void {
    const params: ComposeParams = new ComposeParams(item.toEmail, '', '', item.subject, item.content)
    this.pathStack.pushPathByName('ComposePage', params)
  }

  build() {
    Column() {
      Text('草稿箱')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 16, bottom: 8 })
        .width('100%')

      if (this.draftList.length === 0) {
        EmptyState({ icon: $r('sys.symbol.doc'), message: '暂无草稿' })
      } else {
        List({ scroller: this.scroller }) {
          ForEach(this.draftList, (item: DraftItem, index: number) => {
            ListItem() {
              Row() {
                Column() {
                  Row() {
                    Text(item.subject)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('app.color.text_primary'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)
                    Text(item.time)
                      .fontSize(12)
                      .fontColor($r('app.color.text_tertiary'))
                  }
                  .width('100%')

                  Row() {
                    Text('收件人: ' + item.toEmail)
                      .fontSize(13)
                      .fontColor($r('app.color.text_secondary'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)
                  }
                  .width('100%')
                  .margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding({ top: 14, bottom: 14, left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
              .borderRadius(Constants.RADIUS_CARD)
              .backgroundColor($r('app.color.card'))
              .margin({ top: 4, bottom: 4 })
              .onClick(() => { this.editDraft(item) })
            }
            .swipeAction({
              end: {
                builder: () => { this.DeleteDraftAction(index) },
                actionAreaDistance: 80
              },
              edgeEffect: SwipeEdgeEffect.Spring
            })
          }, (item: DraftItem): string => item.id.toString())
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

  @Builder DeleteDraftAction(index: number) {
    Row() {
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
      .width(80)
      .height('100%')
      .backgroundColor($r('app.color.danger'))
      .onClick(() => { this.deleteDraft(index) })
    }
    .height('100%')
  }
}

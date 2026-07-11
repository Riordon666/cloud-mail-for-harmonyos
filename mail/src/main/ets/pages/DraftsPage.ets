import Constants from '../common/Constants'
import { DraftService, MailDraft } from '../common/DraftService'
import { DraftListDataSource } from '../common/DraftListDataSource'
import { EmptyState } from '../components/EmptyState'
import { ComposeParams } from './ComposePage'

@Component
export struct DraftsPage {
  private scroller: Scroller = new Scroller()
  private dataSource: DraftListDataSource = new DraftListDataSource()
  private pathStack: NavPathStack = AppStorage.get('appPathStack') as NavPathStack
  @StorageLink('draftRevision') @Watch('onDraftRevision') draftRevision: number = 0
  @State draftList: MailDraft[] = []

  aboutToAppear(): void {
    this.refreshDrafts()
  }

  private onDraftRevision(): void {
    this.refreshDrafts()
  }

  private refreshDrafts(): void {
    this.draftList = DraftService.getDrafts()
    this.dataSource.setData(this.draftList)
  }

  private deleteDraft(id: number): void {
    DraftService.deleteDraft(id)
    this.dataSource.removeItem(id)
  }

  private editDraft(item: MailDraft): void {
    const params: ComposeParams = new ComposeParams(item.toEmail, item.ccEmail, item.bccEmail, item.subject, item.content,
      '', 0, item.id)
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
          LazyForEach(this.dataSource, (item: MailDraft) => {
            ListItem() {
              Row() {
                Column() {
                  Row() {
                    Text(item.subject === '' ? '无主题' : item.subject)
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

                  Text('收件人: ' + (item.toEmail === '' ? '未填写' : item.toEmail))
                    .fontSize(13)
                    .fontColor($r('app.color.text_secondary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
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
                builder: () => { this.DeleteDraftAction(item.id) },
                actionAreaDistance: 80
              },
              edgeEffect: SwipeEdgeEffect.Spring
            })
          }, (item: MailDraft): string => item.id.toString())
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

  @Builder DeleteDraftAction(id: number) {
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
      .onClick(() => { this.deleteDraft(id) })
    }
    .height('100%')
  }
}
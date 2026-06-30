import Constants from '../common/Constants'
import { MOCK_EMAILS } from '../common/MockData'
import { EmailCard } from '../components/EmailCard'

@Component
export struct InboxPage {
  private scroller: Scroller = new Scroller()

  build() {
    List({ scroller: this.scroller }) {
      ListItem() {
        Row() {
          TextInput({ placeholder: '搜索邮件' })
            .placeholderColor($r('app.color.text_tertiary'))
            .fontColor($r('app.color.text_primary'))
            .backgroundColor($r('app.color.card'))
            .borderRadius(Constants.RADIUS_BUTTON)
            .height(48)
            .layoutWeight(1)
            .padding({ left: 14 })
        }
        .width('100%')
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 8, bottom: 8 })
      }

      ForEach(MOCK_EMAILS, (item, index: number) => {
        ListItem() {
          EmailCard({
            name: item.name,
            subject: item.subject,
            time: item.time,
            unread: item.unread
          })
        }
      }, (item) => item.id.toString())
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor($r('app.color.background'))
  }
}

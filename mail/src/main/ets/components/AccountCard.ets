import Constants from '../common/Constants'
import { AvatarBar } from './AvatarBar'

@Component
export struct AccountCard {
  @Prop email: string = ''
  @Prop unread: number = 0
  @Prop total: number = 0
  @Prop isPrimary: boolean = false
  onCardClick?: () => void

  build() {
    Row() {
      AvatarBar({
        name: this.email,
        avatarSize: 44,
        fontSize: 18,
        bgColor: this.isPrimary ? '#317AF7' : '#D1D1D6'
      })

      Column() {
        Text(this.email)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))

        Text(this.unread + ' 封未读 · ' + this.total + ' 封总计')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 4 })

        if (this.isPrimary) {
          Text('默认账号')
            .fontSize(10)
            .fontColor($r('app.color.primary'))
            .fontWeight(FontWeight.Medium)
            .margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .layoutWeight(1)

      Text('›')
        .fontSize(20)
        .fontColor($r('app.color.text_tertiary'))
    }
    .width('100%')
    .padding({ top: 14, bottom: 14, left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
    .borderRadius(Constants.RADIUS_CARD)
    .backgroundColor($r('app.color.card'))
    .margin({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 4, bottom: 4 })
    .onClick(() => {
      if (this.onCardClick) { this.onCardClick() }
    })
  }
}

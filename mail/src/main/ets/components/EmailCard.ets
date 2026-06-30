import Constants from '../common/Constants'
import { AvatarBar } from './AvatarBar'

@Component
export struct EmailCard {
  @Prop name: string = ''
  @Prop subject: string = ''
  @Prop time: string = ''
  @Prop unread: boolean = false
  onCardClick?: () => void

  build() {
    Row() {
      AvatarBar({ name: this.name, avatarSize: 44, fontSize: 18 })
        .margin({ right: 12 })

      Column() {
        Row() {
          Text(this.name)
            .fontSize(16)
            .fontWeight(this.unread ? FontWeight.Bold : FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
            .animation({ duration: 300, curve: Curve.EaseInOut })
          Text(this.time)
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
        }
        .width('100%')

        Text(this.subject)
          .fontSize(14)
          .fontWeight(this.unread ? FontWeight.Medium : FontWeight.Normal)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
          .width('100%')
          .animation({ duration: 300, curve: Curve.EaseInOut })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.unread) {
        Circle()
          .width(8)
          .height(8)
          .fill($r('app.color.primary'))
          .margin({ left: 8 })
      }
    }
    .width('100%')
    .padding({ top: 14, bottom: 14, left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
    .borderRadius(Constants.RADIUS_CARD)
    .backgroundColor($r('app.color.card'))
    .margin({ top: 4, bottom: 4 })
    .onClick(() => {
      if (this.onCardClick) { this.onCardClick() }
    })
  }
}

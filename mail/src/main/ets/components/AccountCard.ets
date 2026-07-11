import Constants from '../common/Constants'
import { AvatarBar } from './AvatarBar'

@Component
export struct AccountCard {
  @Prop email: string = ''
  @Prop unread: number = 0
  @Prop total: number = 0
  @Prop isPrimary: boolean = false
  onDeleteClick?: () => void

  build() {
    Column() {
      Row() {
        AvatarBar({
          name: this.email,
          avatarSize: 44,
          fontSize: 18
        })

        Column() {
          Text(this.email)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.total < 0 ? '邮件统计由服务端加载' : this.unread + ' 封未读 · ' + this.total + ' 封总计')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 4 })

          Text(this.isPrimary ? '主邮箱' : '副邮箱')
            .fontSize(10)
            .fontColor($r('app.color.tag_text'))
            .backgroundColor(this.isPrimary ? $r('app.color.primary') : $r('app.color.info'))
            .borderRadius(Constants.RADIUS_SMALL)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
        .layoutWeight(1)
      }
      .width('100%')

      Divider()
        .strokeWidth(0.5)
        .color($r('app.color.divider'))
        .margin({ top: 12, bottom: 10 })

      Row() {
        Text(this.isPrimary ? '主邮箱用于登录，并统一管理所有副邮箱。' : '副邮箱自动归属主邮箱，不能独立登录。')
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
          .layoutWeight(1)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (!this.isPrimary) {
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            SymbolGlyph($r('sys.symbol.trash'))
              .fontSize(Constants.SIZE_ICON_SMALL)
              .fontColor([$r('app.color.danger')])
          }
          .width(32)
          .height(32)
          .backgroundColor($r('app.color.background'))
          .margin({ left: 8 })
          .onClick(() => {
            if (this.onDeleteClick) {
              this.onDeleteClick()
            }
          })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ top: 14, bottom: 14, left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
    .borderRadius(Constants.RADIUS_CARD)
    .backgroundColor($r('app.color.card'))
    .margin({ top: 4, bottom: 4 })
  }
}

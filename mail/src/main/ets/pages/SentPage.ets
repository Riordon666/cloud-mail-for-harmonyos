import Constants from '../common/Constants'

@Component
export struct SentPage {
  build() {
    Column() {
      Text('已发送')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 16, bottom: 16 })
        .width('100%')

      Column() {
        SymbolGlyph($r('sys.symbol.paperplane'))
          .fontSize(48)
          .fontColor([$r('app.color.text_tertiary')])
        Text('暂无已发送邮件')
          .fontSize(16)
          .fontColor($r('app.color.text_tertiary'))
          .margin({ top: 12 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }
}
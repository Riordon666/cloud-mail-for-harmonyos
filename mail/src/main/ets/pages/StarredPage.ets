import Constants from '../common/Constants'

@Component
export struct StarredPage {
  build() {
    Column() {
      Text('星标邮件')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 16, bottom: 16 })
        .width('100%')

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
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }
}
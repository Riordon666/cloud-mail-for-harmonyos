import Constants from '../common/Constants'

@Component
export struct NotFoundPage {
  build() {
    Column() {
      SymbolGlyph($r('sys.symbol.questionmark_circle'))
        .fontSize(64)
        .fontColor([$r('app.color.text_tertiary')])
      Text('404')
        .fontSize(48)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 16 })
      Text('页面不存在')
        .fontSize(Constants.FONT_SIZE_SUBTITLE)
        .fontColor($r('app.color.text_tertiary'))
        .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.background'))
  }
}
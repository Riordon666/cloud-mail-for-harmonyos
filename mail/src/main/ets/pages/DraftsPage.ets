import Constants from '../common/Constants'

@Component
export struct DraftsPage {
  build() {
    Column() {
      Text('草稿箱')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .padding({ left: Constants.PADDING_EDGE, top: 16, bottom: 16 })
        .width('100%')

      Column() {
        SymbolGlyph($r('sys.symbol.doc'))
          .fontSize(48)
          .fontColor([$r('app.color.text_tertiary')])
        Text('暂无草稿')
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
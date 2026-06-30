import Constants from '../common/Constants'

@Component
export struct EmptyState {
  @Prop icon: ResourceStr = $r('sys.symbol.tray')
  @Prop message: string = '暂无数据'
  @Prop iconSize: number = 48

  build() {
    Column() {
      SymbolGlyph(this.icon)
        .fontSize(this.iconSize)
        .fontColor([$r('app.color.text_tertiary')])
      Text(this.message)
        .fontSize(Constants.FONT_SIZE_SUBTITLE)
        .fontColor($r('app.color.text_tertiary'))
        .margin({ top: 12 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}
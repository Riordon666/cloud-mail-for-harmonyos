import Constants from '../common/Constants'

@Component
export struct LoadingView {
  @Prop message: string = '加载中...'

  build() {
    Column() {
      LoadingProgress()
        .width(36)
        .height(36)
        .color($r('app.color.primary'))
      Text(this.message)
        .fontSize(Constants.FONT_SIZE_SMALL)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 12 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}
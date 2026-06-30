import Constants from '../common/Constants'

@Component
export struct SectionHeader {
  @Prop title: string = ''

  build() {
    Text(this.title)
      .fontSize(Constants.FONT_SIZE_SMALL)
      .fontColor($r('app.color.text_tertiary'))
      .fontWeight(FontWeight.Medium)
      .padding({ left: Constants.PADDING_EDGE, top: 20, bottom: 6 })
      .width('100%')
  }
}
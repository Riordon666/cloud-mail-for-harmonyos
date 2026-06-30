import Constants from '../common/Constants'

@Component
export struct ComposePage {
  @State toEmail: string = ''
  @State subject: string = ''
  @State content: string = ''

  build() {
    Column() {
      Row() {
        SymbolGlyph('sys.symbol.chevron_left')
          .fontSize(24)
          .fontColor($r('app.color.text_primary'))
          .onClick(() => { /* TODO: 返回上一页 */ })
        Text('写邮件')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .margin({ left: 8 })
        Blank()
        Row() {
          Text('发送')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .borderRadius(18)
        .backgroundColor($r('app.color.primary'))
      }
      .width('100%')
      .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 12, bottom: 8 })

      Divider().strokeWidth(0.5).color($r('app.color.divider'))

      Row() {
        Text('收件人')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_secondary'))
          .width(56)
        TextInput({ placeholder: '输入邮箱地址', text: this.toEmail })
          .placeholderColor($r('app.color.text_tertiary'))
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .height(44)
          .onChange((v: string) => { this.toEmail = v })
      }
      .width('100%')
      .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 12 })

      Divider().strokeWidth(0.5).color($r('app.color.divider'))
        .margin({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })

      Row() {
        Text('主题')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_secondary'))
          .width(56)
        TextInput({ placeholder: '邮件主题', text: this.subject })
          .placeholderColor($r('app.color.text_tertiary'))
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .height(44)
          .onChange((v: string) => { this.subject = v })
      }
      .width('100%')
      .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })

      Divider().strokeWidth(0.5).color($r('app.color.divider'))
        .margin({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })

      TextArea({ placeholder: '写点什么...', text: this.content })
        .placeholderColor($r('app.color.text_tertiary'))
        .fontColor($r('app.color.text_primary'))
        .backgroundColor(Color.Transparent)
        .padding(Constants.PADDING_EDGE)
        .layoutWeight(1)
        .onChange((v: string) => { this.content = v })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }
}

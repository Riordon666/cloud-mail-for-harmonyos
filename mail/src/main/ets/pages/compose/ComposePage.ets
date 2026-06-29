import { AppTheme } from '../../theme/AppTheme'

@Entry
@Component
struct ComposePage {
  @State toEmail: string = ''
  @State subject: string = ''
  @State content: string = ''
  @StorageProp('currentColorMode') colorMode: number = 1

  build() {
    Column() {
      Row() {
        Text('写邮件')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)

        Blank()

        SymbolGlyph(('sys.symbol.paperclip'))
          .fontSize(22)
          .fontColor(this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT)
          .margin({ right: 16 })

        Row() {
          SymbolGlyph(('sys.symbol.paperplane_fill'))
            .fontSize(16)
            .fontColor(Color.White)

          Text('发送')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .margin({ left: 4 })
        }
        .padding({ left: 14, right: 14, top: 8, bottom: 8 })
        .borderRadius(20)
        .backgroundColor(AppTheme.PRIMARY)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })
      .backgroundColor(this.isDark() ? AppTheme.CARD_BLUR_DARK : AppTheme.CARD_BLUR)
      .backdropBlur(20)

      Row() {
        Text('收件人')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT)
          .width(56)

        TextInput({ placeholder: '输入邮箱地址', text: this.toEmail })
          .placeholderColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
          .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .height(44)
          .onChange((value: string) => { this.toEmail = value })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12 })

      Divider()
        .strokeWidth(0.5)
        .color(this.isDark() ? AppTheme.DIVIDER_DARK : AppTheme.DIVIDER_LIGHT)
        .margin({ left: 16, right: 16 })

      Row() {
        Text('主题')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT)
          .width(56)

        TextInput({ placeholder: '邮件主题', text: this.subject })
          .placeholderColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
          .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .height(44)
          .onChange((value: string) => { this.subject = value })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      Divider()
        .strokeWidth(0.5)
        .color(this.isDark() ? AppTheme.DIVIDER_DARK : AppTheme.DIVIDER_LIGHT)
        .margin({ left: 16, right: 16 })

      TextArea({ placeholder: '写点什么...', text: this.content })
        .placeholderColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
        .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
        .backgroundColor(Color.Transparent)
        .padding(16)
        .layoutWeight(1)
        .onChange((value: string) => { this.content = value })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDark() ? AppTheme.BG_DARK : AppTheme.BG_LIGHT)
  }

  private isDark(): boolean {
    return this.colorMode === 1
  }
}

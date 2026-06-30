import Constants from '../common/Constants'

@Component
export struct SearchBar {
  @Prop placeholder: string = '搜索'
  @Link searchText: string
  @State isActive: boolean = false

  build() {
    Row() {
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(18)
        .fontColor([$r('app.color.text_tertiary')])
        .margin({ left: 12 })

      TextInput({ placeholder: this.placeholder, text: this.searchText })
        .placeholderColor($r('app.color.text_tertiary'))
        .fontColor($r('app.color.text_primary'))
        .backgroundColor(Color.Transparent)
        .borderRadius(0)
        .height(48)
        .layoutWeight(1)
        .padding({ left: 8 })
        .onChange((value: string) => {
          this.searchText = value
        })
        .onFocus(() => {
          this.isActive = true
        })

      if (this.searchText !== '') {
        SymbolGlyph($r('sys.symbol.xmark_circle_fill'))
          .fontSize(18)
          .fontColor([$r('app.color.text_tertiary')])
          .margin({ right: 12 })
          .onClick(() => {
            this.searchText = ''
          })
      }
    }
    .width('100%')
    .height(48)
    .backgroundColor($r('app.color.card'))
    .borderRadius(Constants.RADIUS_BUTTON)
    .padding({ left: 0, right: 0 })
  }
}
@Component
export struct SplashPage {
  @State iconScale: number = 0.6
  @State iconOpacity: number = 0
  @State pageOpacity: number = 1
  private hideTimerId: number = -1
  onSplashFinished: () => void = () => {}

  aboutToAppear(): void {
    // 图标淡入 + 放大
    setTimeout(() => {
      this.iconOpacity = 1
      this.iconScale = 1
    }, 80)
    // 停留约 1.2s 后整页淡出
    this.hideTimerId = setTimeout(() => {
      this.pageOpacity = 0
    }, 1300)
  }

  aboutToDisappear(): void {
    if (this.hideTimerId !== -1) {
      clearTimeout(this.hideTimerId)
    }
  }

  build() {
    Stack() {
      Column({ space: 18 }) {
        SymbolGlyph($r("sys.symbol.envelope_fill"))
          .fontColor([$r("sys.color.font_on_primary")])
          .fontSize(200)
          .scale({ x: this.iconScale, y: this.iconScale })
          .opacity(this.iconOpacity)
          .animation({
            duration: 600,
            curve: Curve.EaseOut,
            iterations: 1,
            playMode: PlayMode.Normal
          })

        Text("Cloud Mail")
          .fontSize(26)
          .fontColor($r("sys.color.font_on_primary"))
          .fontWeight(FontWeight.Bold)
          .opacity(this.iconOpacity)
          .animation({
            duration: 600,
            curve: Curve.EaseOut,
            iterations: 1,
            playMode: PlayMode.Normal
          })
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .width("100%")
      .height("100%")
    }
    .width("100%")
    .height("100%")
    .backgroundColor($r("app.color.start_window_background"))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .opacity(this.pageOpacity)
    .animation({
      duration: 450,
      curve: Curve.EaseInOut,
      iterations: 1,
      playMode: PlayMode.Normal,
      onFinish: () => {
        if (this.pageOpacity === 0) {
          this.onSplashFinished()
        }
      }
    })
  }
}

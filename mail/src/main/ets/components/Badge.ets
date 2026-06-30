@Component
export struct BadgeDot {
  @Prop count: number = 0
  @Prop showDot: boolean = false

  build() {
    if (this.showDot) {
      Circle()
        .width(8)
        .height(8)
        .fill($r('app.color.primary'))
    } else if (this.count > 0) {
      Text(this.count > 99 ? '99+' : this.count.toString())
        .fontSize(10)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.primary'))
        .borderRadius(9)
        .padding({ left: 5, right: 5, top: 1, bottom: 1 })
        .constraintSize({ minWidth: 18 })
        .textAlign(TextAlign.Center)
    }
  }
}
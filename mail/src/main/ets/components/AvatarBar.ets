@Component
export struct AvatarBar {
  @Prop name: string = ''
  @Prop avatarSize: number = 44
  @Prop fontSize: number = 18
  @Prop bgColor: string = ''

  private readonly PALETTE: string[] = ['#FF6B6B', '#FFD93D', '#6BCB77', '#4D96FF', '#9B59B6', '#1ABC9C']

  private hashColor(n: string): string {
    let h: number = 0
    for (let i: number = 0; i < n.length; i++) {
      h = n.charCodeAt(i) + ((h << 5) - h)
    }
    return this.PALETTE[Math.abs(h) % this.PALETTE.length]
  }

  build() {
    Stack() {
      Circle()
        .width(this.avatarSize)
        .height(this.avatarSize)
        .fill(this.bgColor || this.hashColor(this.name))
      Text(this.name.charAt(0).toUpperCase())
        .fontSize(this.fontSize)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
    }
  }
}

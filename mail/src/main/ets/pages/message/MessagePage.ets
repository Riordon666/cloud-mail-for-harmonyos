import { AppTheme } from '../../theme/AppTheme'

@Entry
@Component
struct MessagePage {
  @StorageProp('currentColorMode') colorMode: number = 1

  build() {
    Column() {
      Row() {
        SymbolGlyph(('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)

        Blank()

        SymbolGlyph(('sys.symbol.archivebox'))
          .fontSize(22)
          .fontColor(this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT)
          .margin({ right: 16 })

        SymbolGlyph(('sys.symbol.trash'))
          .fontSize(22)
          .fontColor(this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT)
          .margin({ right: 16 })

        SymbolGlyph(('sys.symbol.flag'))
          .fontSize(22)
          .fontColor(this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT)
          .margin({ right: 8 })
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 8, bottom: 4 })
      .backgroundColor(this.isDark() ? AppTheme.CARD_BLUR_DARK : AppTheme.CARD_BLUR)
      .backdropBlur(20)

      Scroll() {
        Column() {
          Text('Q4 设计稿评审通知')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
            .width('100%')
            .padding({ left: 16, right: 16, top: 20 })
            .textAlign(TextAlign.Start)

          Row() {
            Stack() {
              Circle()
                .width(40)
                .height(40)
                .fill('#FF6B6B')
              Text('A')
                .fontSize(17)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.White)
            }

            Column() {
              Row() {
                Text('Alice Zhang')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
              }
              Text('alice@example.com')
                .fontSize(13)
                .fontColor(this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT)
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 10 })
            .layoutWeight(1)

            Column() {
              Text('09:15')
                .fontSize(13)
                .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)

              SymbolGlyph(('sys.symbol.star_fill'))
                .fontSize(18)
                .fontColor('#FFD93D')
                .margin({ top: 6 })
            }
            .alignItems(HorizontalAlign.End)
          }
          .width('100%')
          .padding(16)
          .borderRadius(AppTheme.RADIUS_MD)
          .backgroundColor(this.isDark() ? AppTheme.CARD_DARK : AppTheme.CARD_LIGHT)
          .margin({ left: 16, right: 16, top: 16 })

          Text('收件人: admin@riordon.xyz')
            .fontSize(12)
            .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
            .width('100%')
            .padding({ left: 16, right: 16, top: 8 })

          Divider()
            .strokeWidth(0.5)
            .color(this.isDark() ? AppTheme.DIVIDER_DARK : AppTheme.DIVIDER_LIGHT)
            .margin({ left: 16, right: 16, top: 16 })

          Text(this.mockContent)
            .fontSize(15)
            .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
            .lineHeight(24)
            .width('100%')
            .padding(16)
            .textAlign(TextAlign.Start)

          this.AttachmentCard('设计稿-v3.fig', '2.4 MB')
          this.AttachmentCard('评审意见.pdf', '856 KB')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)

      Row() {
        SymbolGlyph(('sys.symbol.arrowshape.turn.up.left_fill'))
          .fontSize(22)
          .fontColor(this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT)
          .layoutWeight(1)

        SymbolGlyph(('sys.symbol.arrowshape.turn.up.forward'))
          .fontSize(22)
          .fontColor(this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT)
          .layoutWeight(1)

        SymbolGlyph(('sys.symbol.paperplane'))
          .fontSize(22)
          .fontColor(this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT)
          .layoutWeight(1)

        SymbolGlyph(('sys.symbol.ellipsis'))
          .fontSize(22)
          .fontColor(this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ top: 10, bottom: 18 })
      .backgroundColor(this.isDark() ? AppTheme.CARD_BLUR_DARK : AppTheme.CARD_BLUR)
      .backdropBlur(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDark() ? AppTheme.BG_DARK : AppTheme.BG_LIGHT)
  }

  @Builder
  AttachmentCard(filename: string, size: string) {
    Row() {
      SymbolGlyph(('sys.symbol.doc'))
        .fontSize(28)
        .fontColor(AppTheme.PRIMARY)

      Column() {
        Text(filename)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)

        Text(size)
          .fontSize(12)
          .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10 })
      .layoutWeight(1)

      SymbolGlyph(('sys.symbol.arrow.down.to.line'))
        .fontSize(18)
        .fontColor(this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT)
    }
    .width('100%')
    .padding(14)
    .borderRadius(AppTheme.RADIUS_SM)
    .backgroundColor(this.isDark() ? '#252525' : '#F5F5F7')
    .margin({ left: 16, right: 16, bottom: 8 })
  }

  private isDark(): boolean {
    return this.colorMode === 1
  }

  private mockContent: string =
    'hi，各位同学：\n\n本周五（6月30日）下午3点在会议室A进行Q4设计稿评审，\n请提前准备好相关材料。\n\n本次评审范围：\n- 首页改版方案\n- 个人中心页面\n- 设置页面更新\n\n请大家准时参加，如有疑问请联系我。\n\n谢谢！\nAlice'
}

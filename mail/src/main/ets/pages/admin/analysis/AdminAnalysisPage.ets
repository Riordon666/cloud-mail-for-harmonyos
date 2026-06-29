import { AppTheme } from '../../../theme/AppTheme'

@Entry
@Component
struct AdminAnalysisPage {
  @StorageProp('currentColorMode') colorMode: number = 1

  build() {
    Column() {
      Row() {
        SymbolGlyph(('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
        Text('数据分析')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
          .margin({ left: 8 })
        Blank()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(this.isDark() ? AppTheme.CARD_BLUR_DARK : AppTheme.CARD_BLUR)
      .backdropBlur(20)

      Scroll() {
        Column() {
          Row() {
            this.StatCard('总用户', '60', AppTheme.PRIMARY)
            this.StatCard('今日收信', '24', '#6BCB77')
            this.StatCard('今日发信', '8', '#FFD93D')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16 })
          .justifyContent(FlexAlign.SpaceBetween)

          Column() {
            Text('邮件增长趋势')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
              .width('100%')
              .padding({ left: 16, top: 16 })

            Row({ space: 8 }) {
              ForEach(this.mockChartData, (item: ChartData) => {
                Column() {
                  Column()
                    .width(28)
                    .height(item.value * 3)
                    .borderRadius(6)
                    .linearGradient({
                      angle: 180,
                      colors: [[AppTheme.PRIMARY, 0.0], [AppTheme.PRIMARY_LIGHT, 1.0]]
                    })
                  Text(item.label)
                    .fontSize(11)
                    .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
                    .margin({ top: 6 })
                }
                .justifyContent(FlexAlign.End)
                .height(160)
              })
            }
            .width('100%')
            .height(180)
            .padding({ left: 16, right: 16, bottom: 20 })
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Bottom)
          }
          .width('100%')
          .borderRadius(AppTheme.RADIUS_MD)
          .backgroundColor(this.isDark() ? AppTheme.CARD_DARK : AppTheme.CARD_LIGHT)
          .margin({ left: 16, right: 16, top: 16 })

          Row() {
            this.DomainCard('riordon.xyz', 45)
            this.DomainCard('其他', 15)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16 })
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDark() ? AppTheme.BG_DARK : AppTheme.BG_LIGHT)
  }

  @Builder
  StatCard(label: string, value: string, color: string) {
    Column() {
      Text(value)
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)

      Text(label)
        .fontSize(13)
        .fontColor(this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT)
        .margin({ top: 4 })
    }
    .width('30%')
    .padding({ top: 20, bottom: 20 })
    .borderRadius(AppTheme.RADIUS_MD)
    .backgroundColor(this.isDark() ? AppTheme.CARD_DARK : AppTheme.CARD_LIGHT)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  DomainCard(domain: string, count: number) {
    Column() {
      Text(domain)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)

      Text(count + ' 个用户')
        .fontSize(13)
        .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
        .margin({ top: 6 })
    }
    .width('46%')
    .padding({ top: 20, bottom: 20 })
    .borderRadius(AppTheme.RADIUS_MD)
    .backgroundColor(this.isDark() ? AppTheme.CARD_DARK : AppTheme.CARD_LIGHT)
    .alignItems(HorizontalAlign.Center)
  }

  private isDark(): boolean {
    return this.colorMode === 1
  }

  @State mockChartData: ChartData[] = [
    { label: '周一', value: 12 },
    { label: '周二', value: 18 },
    { label: '周三', value: 24 },
    { label: '周四', value: 20 },
    { label: '周五', value: 28 },
    { label: '周六', value: 8 },
    { label: '周日', value: 5 }
  ]
}

interface ChartData {
  label: string
  value: number
}

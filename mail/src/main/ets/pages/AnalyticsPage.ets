import { HdsNavDestination, HdsNavDestinationTitleMode } from '@kit.UIDesignKit'
import Constants from '../common/Constants'
import { AdminAnalytics, AdminService, AdminStats, TrendItem } from '../common/AdminService'
import { EmptyState } from '../components/EmptyState'

@Component
export struct AnalyticsPage {
  @StorageLink('authRole') authRole: string = 'user'
  @StorageLink('adminUserRevision') @Watch('onDataChanged') userRevision: number = 0
  @StorageLink('adminMailRevision') @Watch('onDataChanged') mailRevision: number = 0
  @State stats: AdminStats = new AdminStats(0, 0, 0, '0 B')
  @State trendItems: TrendItem[] = []

  aboutToAppear(): void {
    AdminService.initialize()
    this.refreshData()
  }

  private onDataChanged(): void {
    this.refreshData()
  }

  build() {
    HdsNavDestination() {
      if (this.authRole !== 'admin') {
        EmptyState({ icon: $r('sys.symbol.externaldrive'), message: '仅管理员可访问数据分析' })
      } else {
        Scroll() {
          Column({ space: Constants.GAP_MEDIUM }) {
            Text('数据分析')
              .fontSize(Constants.FONT_SIZE_TITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
            Text('统计数据来自邮件服务端，并按当前时区汇总。')
              .fontSize(Constants.FONT_SIZE_COMMON)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')

            Row({ space: Constants.GAP_SMALL }) {
              this.StatCard('总用户数', this.stats.totalUsers.toString(), $r('sys.symbol.person'))
              this.StatCard('总邮件数', this.stats.totalEmails.toString(), $r('sys.symbol.envelope'))
            }
            .width('100%')
            Row({ space: Constants.GAP_SMALL }) {
              this.StatCard('今日发送', this.stats.activeToday.toString(), $r('sys.symbol.paperplane'))
              this.StatCard('存储占用', this.stats.storageUsed, $r('sys.symbol.externaldrive'))
            }
            .width('100%')

            Column({ space: Constants.GAP_SMALL }) {
              Text('近 7 天趋势')
                .fontSize(Constants.FONT_SIZE_SUBTITLE)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
              Row() {
                Text('日期')
                  .layoutWeight(1)
                  .fontSize(Constants.FONT_SIZE_SMALL)
                  .fontColor($r('app.color.text_tertiary'))
                Text('用户')
                  .width(72)
                  .fontSize(Constants.FONT_SIZE_SMALL)
                  .fontColor($r('app.color.text_tertiary'))
                  .textAlign(TextAlign.End)
                Text('邮件')
                  .width(72)
                  .fontSize(Constants.FONT_SIZE_SMALL)
                  .fontColor($r('app.color.text_tertiary'))
                  .textAlign(TextAlign.End)
              }
              .width('100%')
              .padding({ bottom: 6 })
              ForEach(this.trendItems, (item: TrendItem) => {
                this.TrendRow(item)
              }, (item: TrendItem): string => item.date)
            }
            .width('100%')
            .padding(Constants.PADDING_CARD)
            .backgroundColor($r('app.color.card'))
            .borderRadius(Constants.RADIUS_CARD)
            .shadow(Constants.SHADOW_CARD)
            Blank().height(24)
          }
          .width('100%')
          .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 16, bottom: 24 })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
      }
    }
    .titleBar({ content: { title: { mainTitle: '数据分析' } }, enableComponentSafeArea: true })
    .hideBackButton(false)
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  private StatCard(title: string, value: string, icon: Resource) {
    Column() {
      Row() {
        Text(title)
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
          .layoutWeight(1)
        SymbolGlyph(icon)
          .fontSize(Constants.SIZE_ICON_SMALL)
          .fontColor([$r('app.color.primary')])
      }
      .width('100%')
      Text(value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .margin({ top: 12 })
    }
    .layoutWeight(1)
    .padding(Constants.PADDING_CARD)
    .backgroundColor($r('app.color.card'))
    .borderRadius(Constants.RADIUS_CARD)
    .shadow(Constants.SHADOW_CARD)
  }

  @Builder
  private TrendRow(item: TrendItem) {
    Row() {
      Text(item.date)
        .layoutWeight(1)
        .fontSize(Constants.FONT_SIZE_COMMON)
        .fontColor($r('app.color.text_primary'))
      Text(item.users.toString())
        .width(72)
        .fontSize(Constants.FONT_SIZE_COMMON)
        .fontColor($r('app.color.primary'))
        .textAlign(TextAlign.End)
      Text(item.emails.toString())
        .width(72)
        .fontSize(Constants.FONT_SIZE_COMMON)
        .fontColor($r('app.color.text_primary'))
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })
  }

  private async refreshData(): Promise<void> {
    try {
      const analytics: AdminAnalytics = await AdminService.getAnalytics()
      this.stats = analytics.stats
      this.trendItems = analytics.trend
    } catch (err) {
      console.error('load analytics failed')
    }
  }
}

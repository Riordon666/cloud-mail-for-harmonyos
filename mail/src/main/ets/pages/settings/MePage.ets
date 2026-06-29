import { AppTheme } from '../../theme/AppTheme'

@Entry
@Component
struct MePage {
  @StorageProp('currentColorMode') colorMode: number = 1
  @State isAdmin: boolean = true

  build() {
    Column() {
      this.ProfileCard()

      List() {
        ListItemGroup({ header: this.SectionHeader('通用') }) {
          ListItem() { this.MenuItem('外观设置', ('sys.symbol.paintbrush'), '跟随系统') }
          ListItem() { this.MenuItem('通知设置', ('sys.symbol.bell'), '') }
          ListItem() { this.MenuItem('隐私政策', ('sys.symbol.hand_raised'), '') }
          ListItem() { this.MenuItem('关于', ('sys.symbol.info_circle'), 'v1.0.0') }
        }

        if (this.isAdmin) {
          ListItemGroup({ header: this.SectionHeader('管理') }) {
            ListItem() { this.MenuItem('用户管理', ('sys.symbol.person_2'), '') }
            ListItem() { this.MenuItem('全部邮件', ('sys.symbol.tray'), '') }
            ListItem() { this.MenuItem('角色权限', ('sys.symbol.shield'), '') }
            ListItem() { this.MenuItem('数据分析', ('sys.symbol.chart_bar'), '') }
            ListItem() { this.MenuItem('注册码管理', ('sys.symbol.ticket'), '') }
          }
        }

        ListItemGroup({ header: this.SectionHeader('') }) {
          ListItem() {
            Row() {
              Text('退出登录')
                .fontSize(16)
                .fontColor('#FF4757')
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ top: 14, bottom: 14 })
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .sticky(StickyStyle.Header)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDark() ? AppTheme.BG_DARK : AppTheme.BG_LIGHT)
  }

  @Builder
  ProfileCard() {
    Column() {
      Stack() {
        Circle()
          .width(72)
          .height(72)
          .fill('#317AF7')
        Text('A')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .margin({ bottom: 16 })

      Text('admin@riordon.xyz')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)

      Row() {
        Text('专业版')
          .fontSize(12)
          .fontColor(Color.White)
      }
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .borderRadius(10)
      .backgroundColor(AppTheme.PRIMARY_LIGHT)
      .margin({ top: 8 })
    }
    .width('100%')
    .padding({ top: 40, bottom: 28 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  SectionHeader(title: string) {
    Text(title)
      .fontSize(13)
      .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
      .fontWeight(FontWeight.Medium)
      .padding({ left: 16, top: 20, bottom: 6 })
      .width('100%')
      .backgroundColor(this.isDark() ? AppTheme.BG_DARK : AppTheme.BG_LIGHT)
  }

  @Builder
  MenuItem(title: string, icon: Resource, value: string) {
    Row() {
      SymbolGlyph(icon)
        .fontSize(22)
        .fontColor(this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT)

      Text(title)
        .fontSize(16)
        .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
        .margin({ left: 12 })
        .layoutWeight(1)

      if (value) {
        Text(value)
          .fontSize(14)
          .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
      }

      SymbolGlyph(('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
        .margin({ left: 4 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(this.isDark() ? AppTheme.CARD_DARK : AppTheme.CARD_LIGHT)
  }

  private isDark(): boolean {
    return this.colorMode === 1
  }
}

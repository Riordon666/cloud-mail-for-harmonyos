import { AppTheme } from '../theme/AppTheme'
import { InboxPage } from './inbox/InboxPage'
import { StarredPage } from './starred/StarredPage'
import { ComposePage } from './compose/ComposePage'
import { AccountsPage } from './accounts/AccountsPage'
import { MePage } from './settings/MePage'

/**
 * Index — 主入口页面
 * 底部 TabBar 导航
 */
@Entry
@Component
struct Index {
  @State currentTab: number = 0
  @StorageProp('currentColorMode') colorMode: number = 1

  private readonly tabTitles: string[] = ['收件箱', '星标', '写邮件', '账号', '我']
  private readonly tabIcons: Resource[] = [
    ('sys.symbol.folder'),
    ('sys.symbol.star'),
    ('sys.symbol.square_and_pencil'),
    ('sys.symbol.at'),
    ('sys.symbol.person_crop_circle')
  ]
  private readonly tabIconsSelected: Resource[] = [
    ('sys.symbol.folder_fill'),
    ('sys.symbol.star_fill'),
    ('sys.symbol.square_and_pencil'),
    ('sys.symbol.at'),
    ('sys.symbol.person_crop_circle_fill')
  ]

  build() {
    Navigation() {
      Tabs({ index: this.currentTab }) {
        TabContent() {
          InboxPage()
        }.tabBar(this.TabBuilder(0))

        TabContent() {
          StarredPage()
        }.tabBar(this.TabBuilder(1))

        TabContent() {
          ComposePage()
        }.tabBar(this.TabBuilder(2))

        TabContent() {
          AccountsPage()
        }.tabBar(this.TabBuilder(3))

        TabContent() {
          MePage()
        }.tabBar(this.TabBuilder(4))
      }
      .barHeight(56)
      .barPosition(BarPosition.End)
      .barBackgroundColor(this.isDark() ? '#0D0D0DCC' : '#FFFFFFCC')
      .barBackBlurStyle(BlurStyle.BACKGROUND_REGULAR)
      .onChange((index: number) => {
        this.currentTab = index
      })
      .width('100%')
      .height('100%')
    }
    .hideBackButton(true)
    .mode(NavigationMode.Stack)
    .backgroundColor(this.isDark() ? AppTheme.BG_DARK : AppTheme.BG_LIGHT)
  }

  @Builder
  TabBuilder(index: number) {
    Column() {
      SymbolGlyph(this.currentTab === index ? this.tabIconsSelected[index] : this.tabIcons[index])
        .fontSize(24)
        .fontColor(this.currentTab === index ?
        (this.isDark() ? AppTheme.PRIMARY_LIGHT : AppTheme.PRIMARY) :
        (this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT))
      Text(this.tabTitles[index])
        .fontSize(10)
        .fontWeight(500)
        .fontColor(this.currentTab === index ?
        (this.isDark() ? AppTheme.PRIMARY_LIGHT : AppTheme.PRIMARY) :
        (this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT))
        .margin({ top: 2 })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
  }

  private isDark(): boolean {
    return this.colorMode === 1
  }
}

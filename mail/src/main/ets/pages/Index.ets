import { hdsMaterial, HdsNavigation, HdsTabs, HdsTabsController, ScrollEffectType } from '@kit.UIDesignKit'
import Constants from '../common/Constants'
import { InboxPage } from './InboxPage'
import { SentPage } from './SentPage'
import { DraftsPage } from './DraftsPage'
import { StarredPage } from './StarredPage'
import { SettingsPage } from './SettingsPage'

@Entry
@Component
struct Index {
  @State currentTab: number = 0
  private tabController: HdsTabsController = new HdsTabsController()

  aboutToAppear(): void {
    try {
      this.tabController.preloadItems([0, 1, 2, 3, 4])
    } catch (err) {
      console.error('preloadItems failed')
    }
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // ===== 主框架：沉浸光感导航 =====
      HdsNavigation() {
        HdsTabs({ controller: this.tabController, index: this.currentTab }) {
          TabContent() { InboxPage() }
            .tabBar(this.TabBuilder('收件箱', 0, 'sys.symbol.envelope', 'sys.symbol.envelope_fill'))

          TabContent() { SentPage() }
            .tabBar(this.TabBuilder('已发送', 1, 'sys.symbol.paperplane', 'sys.symbol.paperplane_fill'))

          TabContent() { DraftsPage() }
            .tabBar(this.TabBuilder('草稿箱', 2, 'sys.symbol.doc', 'sys.symbol.doc_fill'))

          TabContent() { StarredPage() }
            .tabBar(this.TabBuilder('星标邮件', 3, 'sys.symbol.star', 'sys.symbol.star_fill'))

          TabContent() { SettingsPage() }
            .tabBar(this.TabBuilder('个人设置', 4, 'sys.symbol.person_crop_circle', 'sys.symbol.person_crop_circle_fill'))
        }
        .scrollable(false)
        .barOverlap(true)
        .vertical(false)
        .barPosition(BarPosition.End)
        .barFloatingStyle({
          barBottomMargin: 36,
          adaptToHandedness: true,
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        })
        .onChange((index: number) => { this.currentTab = index })
        .width('100%')
        .height('100%')
      }
      .mode(NavigationMode.Stack)
      .titleBar({
        style: {
          scrollEffectOpts: {
            enableScrollEffect: true,
            scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR
          },
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        }
      })
      .hideBackButton(true)
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
      .backgroundColor($r('app.color.background'))

      // ===== 悬浮写邮件球（核心操作栏 · 智感握姿自适应） =====
      Column() {
        SymbolGlyph('sys.symbol.square_and_pencil')
          .fontSize(24)
          .fontColor([Color.White])
      }
      .width(56)
      .height(56)
      .borderRadius(28)
      .backgroundColor($r('app.color.primary'))
      .shadow({
        radius: 16,
        color: '#317AF740',
        offsetX: 0,
        offsetY: 6
      })
      .margin({ right: 20, bottom: 104 })
      .onClick(() => {
        // TODO: 后续接入 Navigation 路由
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder TabBuilder(text: string, index: number, icon: string, iconFill: string) {
    Column() {
      SymbolGlyph(this.currentTab === index ? iconFill : icon)
        .fontSize(22)
        .fontColor([this.currentTab === index
          ? $r('app.color.primary')
          : $r('app.color.text_tertiary')])
      Text(text)
        .fontSize(Constants.FONT_SIZE_BAR)
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentTab === index
          ? $r('app.color.primary')
          : $r('app.color.text_tertiary'))
        .margin({ top: 2 })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
  }
}

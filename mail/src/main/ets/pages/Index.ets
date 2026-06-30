import { hdsMaterial, HdsNavigation, HdsTabs, HdsTabsController, ScrollEffectType, HdsNavigationTitleMode } from '@kit.UIDesignKit'
import { SymbolGlyphModifier } from '@kit.ArkUI'
import { motion } from '@kit.MultimodalAwarenessKit'

import { InboxPage } from './InboxPage'
import { SentPage } from './SentPage'
import { DraftsPage } from './DraftsPage'
import { StarredPage } from './StarredPage'
import { SettingsPage } from './SettingsPage'

@Entry
@Component
struct Index {
  @State currentTab: number = 0
  @State isLeftHand: boolean = false
  private tabController: HdsTabsController = new HdsTabsController()

  aboutToAppear(): void {
    try {
      this.tabController.preloadItems([0, 1, 2, 3, 4])
      motion.on('holdingHandChanged', (status: motion.HoldingHandStatus) => {
        animateTo({ duration: 400, curve: Curve.EaseInOut }, () => {
          this.isLeftHand = status === motion.HoldingHandStatus.LEFT_HAND_HELD
        })
      })
    } catch (err) {
      console.error('init failed')
    }
  }

  build() {
    Stack({ alignContent: this.isLeftHand ? Alignment.BottomStart : Alignment.BottomEnd }) {
      HdsNavigation() {
        HdsTabs({ controller: this.tabController, index: this.currentTab }) {
          TabContent() { InboxPage() }
            .tabBar(new BottomTabBarStyle({
              normal: new SymbolGlyphModifier($r('sys.symbol.envelope'))
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([$r('sys.color.font_secondary')]),
              selected: new SymbolGlyphModifier($r('sys.symbol.envelope_fill'))
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([$r('app.color.primary')])
            }, '收件箱'))

          TabContent() { SentPage() }
            .tabBar(new BottomTabBarStyle({
              normal: new SymbolGlyphModifier($r('sys.symbol.paperplane'))
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([$r('sys.color.font_secondary')]),
              selected: new SymbolGlyphModifier($r('sys.symbol.paperplane_fill'))
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([$r('app.color.primary')])
            }, '已发送'))

          TabContent() { DraftsPage() }
            .tabBar(new BottomTabBarStyle({
              normal: new SymbolGlyphModifier($r('sys.symbol.doc'))
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([$r('sys.color.font_secondary')]),
              selected: new SymbolGlyphModifier($r('sys.symbol.doc'))
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([$r('app.color.primary')])
            }, '草稿箱'))

          TabContent() { StarredPage() }
            .tabBar(new BottomTabBarStyle({
              normal: new SymbolGlyphModifier($r('sys.symbol.star'))
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([$r('sys.color.font_secondary')]),
              selected: new SymbolGlyphModifier($r('sys.symbol.star_fill'))
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([$r('app.color.primary')])
            }, '星标邮件'))

          TabContent() { SettingsPage() }
            .tabBar(new BottomTabBarStyle({
              normal: new SymbolGlyphModifier($r('sys.symbol.person'))
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([$r('sys.color.font_secondary')]),
              selected: new SymbolGlyphModifier($r('sys.symbol.person_fill'))
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([$r('app.color.primary')])
            }, '个人设置'))
        }
        .scrollable(false)
        .barOverlap(true)
        .vertical(false)
        .barPosition(BarPosition.End)
        .barFloatingStyle({
          barBottomMargin: $r('sys.float.padding_level8'),
          adaptToHandedness: true,
          lightColor: $r('app.color.primary'),
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.IMMERSIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        })
        .onChange((index: number) => { this.currentTab = index })
        .width('100%')
        .height('100%')
      }
      .titleBar({
        avoidLayoutSafeArea: false,
        enableComponentSafeArea: false,
        style: {
          scrollEffectOpts: {
            enableScrollEffect: true,
            scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR
          },
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.IMMERSIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        }
      })
      .hideBackButton(true)
      .titleMode(HdsNavigationTitleMode.MINI)
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])

      Row() {
        SymbolGlyph($r('sys.symbol.square_and_pencil_fill'))
          .fontColor([$r('sys.color.icon_on_primary')])
          .fontSize($r('sys.float.Title_M'))
      }
      .backgroundColor($r('sys.color.background_emphasize'))
      .borderRadius('50%')
      .clip(true)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .width(56)
      .aspectRatio(1)
      .margin(this.isLeftHand ? { left: 16, bottom: 52 } : { right: 16, bottom: 52 })
      .onClick(() => {
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }
}
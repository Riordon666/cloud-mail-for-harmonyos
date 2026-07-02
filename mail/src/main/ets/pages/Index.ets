import { hdsMaterial, HdsTabs, HdsTabsController } from "@kit.UIDesignKit"
import { HdsNavigation, HdsNavigationAttribute } from "@kit.UIDesignKit"
import { SymbolGlyphModifier } from "@kit.ArkUI"
import { motion } from "@kit.MultimodalAwarenessKit"

import { InboxPage } from "./InboxPage"
import { SentPage } from "./SentPage"
import { DraftsPage } from "./DraftsPage"
import { StarredPage } from "./StarredPage"
import { SettingsPage } from "./SettingsPage"
import { DetailPageContent } from "./DetailPage"
import { ComposePageContent } from "./ComposePage"
import { EmailMock } from "../common/MockData"

class DetailParams {
  emailData: EmailMock
  emailList: EmailMock[]
  currentIndex: number

  constructor(emailData: EmailMock, emailList: EmailMock[], currentIndex: number) {
    this.emailData = emailData
    this.emailList = emailList
    this.currentIndex = currentIndex
  }
}

@Entry
@Component
struct Index {
  @State currentTab: number = 0
  @State isLeftHand: boolean = false
  private tabController: HdsTabsController = new HdsTabsController()
  private pathStack: NavPathStack = new NavPathStack()

  aboutToAppear(): void {
    AppStorage.setOrCreate("appPathStack", this.pathStack)
    try {
      this.tabController.preloadItems([0, 1, 2, 3, 4])
      motion.on("holdingHandChanged", (status: motion.HoldingHandStatus) => {
        animateTo({ duration: 400, curve: Curve.EaseInOut }, () => {
          this.isLeftHand = status === motion.HoldingHandStatus.LEFT_HAND_HELD
        })
      })
    } catch (err) {
      console.error("init failed")
    }
  }

  build() {
    HdsNavigation(this.pathStack) {
      Stack({ alignContent: this.isLeftHand ? Alignment.BottomStart : Alignment.BottomEnd }) {
        HdsTabs({ controller: this.tabController, index: this.currentTab }) {
          TabContent() { InboxPage() }
            .tabBar(new BottomTabBarStyle({
              normal: new SymbolGlyphModifier($r("sys.symbol.envelope"))
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([$r("sys.color.font_secondary")]),
              selected: new SymbolGlyphModifier($r("sys.symbol.envelope_fill"))
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([$r("app.color.primary")])
            }, "收件箱"))

          TabContent() { SentPage() }
            .tabBar(new BottomTabBarStyle({
              normal: new SymbolGlyphModifier($r("sys.symbol.paperplane"))
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([$r("sys.color.font_secondary")]),
              selected: new SymbolGlyphModifier($r("sys.symbol.paperplane_fill"))
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([$r("app.color.primary")])
            }, "已发送"))

          TabContent() { DraftsPage() }
            .tabBar(new BottomTabBarStyle({
              normal: new SymbolGlyphModifier($r("sys.symbol.doc"))
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([$r("sys.color.font_secondary")]),
              selected: new SymbolGlyphModifier($r("sys.symbol.doc"))
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([$r("app.color.primary")])
            }, "草稿箱"))

          TabContent() { StarredPage() }
            .tabBar(new BottomTabBarStyle({
              normal: new SymbolGlyphModifier($r("sys.symbol.star"))
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([$r("sys.color.font_secondary")]),
              selected: new SymbolGlyphModifier($r("sys.symbol.star_fill"))
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([$r("app.color.primary")])
            }, "星标邮件"))

          TabContent() { SettingsPage() }
            .tabBar(new BottomTabBarStyle({
              normal: new SymbolGlyphModifier($r("sys.symbol.person"))
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([$r("sys.color.font_secondary")]),
              selected: new SymbolGlyphModifier($r("sys.symbol.person_fill"))
                .renderingStrategy(SymbolRenderingStrategy.SINGLE)
                .fontColor([$r("app.color.primary")])
            }, "个人设置"))
        }
        .scrollable(false)
        .barOverlap(true)
        .vertical(false)
        .barPosition(BarPosition.End)
        .barFloatingStyle({
          barBottomMargin: -8,
          adaptToHandedness: true,
          lightColor: $r("app.color.primary"),
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.IMMERSIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        })
        .onChange((index: number) => { this.currentTab = index })
        .width("100%")
        .height("100%")

        Row() {
          SymbolGlyph($r("sys.symbol.square_and_pencil_fill"))
            .fontColor([$r("sys.color.icon_on_primary")])
            .fontSize($r("sys.float.Title_M"))
        }
        .backgroundColor($r("sys.color.background_emphasize"))
        .borderRadius("50%")
        .clip(true)
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .width(56)
        .aspectRatio(1)
        .margin(this.isLeftHand ? { left: 16, bottom: 55 } : { right: 16, bottom: 55 })
        .onClick(() => {
          this.pathStack.pushPathByName("ComposePage", undefined)
        })
      }
      .width("100%")
      .height("100%")
      .backgroundColor($r("app.color.background"))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    }
    .navDestination(this.navDestinationBuilder)
    .hideTitleBar(true)
    .hideToolBar(true)
    .width("100%")
    .height("100%")
    .backgroundColor($r("app.color.background"))
  }

  @Builder
  navDestinationBuilder(name: string, param: Object) {
    if (name === "DetailPage") {
      DetailPageContent({ emailData: param as DetailParams })
    } else if (name === "ComposePage") {
      ComposePageContent()
    }
  }
}

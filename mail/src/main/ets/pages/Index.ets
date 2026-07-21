import { hdsMaterial, HdsTabs, HdsTabsController } from "@kit.UIDesignKit"
import { HdsNavigation } from "@kit.UIDesignKit"
import { SymbolGlyphModifier } from "@kit.ArkUI"

import { InboxPage } from "./InboxPage"
import { SentPage } from "./SentPage"
import { DraftsPage } from "./DraftsPage"
import { StarredPage } from "./StarredPage"
import { SettingsPage } from "./SettingsPage"
import { DetailPageContent } from "./DetailPage"
import { ComposePageContent, ComposeParams } from "./ComposePage"
import { MailDetailParams } from '../common/MailModels'
import { AuthService } from "../common/AuthService"
import { AuthPage } from "./AuthPage"
import { AccountsPage } from "./AccountsPage"
import { SystemSettingsPage } from "./SystemSettingsPage"
import { UserManagementPage } from "./UserManagementPage"
import { GlobalMailPage } from "./GlobalMailPage"
import { RoleManagementPage } from "./RoleManagementPage"
import { AnalyticsPage } from "./AnalyticsPage"
import { RegistrationCodePage } from "./RegistrationCodePage"
import { NotFoundPage } from "./NotFoundPage"
import { SplashPage } from "./SplashPage"
import Constants from "../common/Constants"

@Entry
@Component
struct Index {
  @State currentTab: number = 0
  @StorageLink('authToken') authToken: string = ''
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'
  @State showSplash: boolean = true
  private tabController: HdsTabsController = new HdsTabsController()
  private pathStack: NavPathStack = new NavPathStack()
  private isHomePrepared: boolean = false

  aboutToAppear(): void {
    AppStorage.setOrCreate("appPathStack", this.pathStack)
    if (this.authToken !== '') {
      this.restoreSession()
    }
  }

  private async restoreSession(): Promise<void> {
    const result = await AuthService.refreshSession()
    if (result.success && this.authToken !== '') {
      this.prepareHome()
    }
  }

  private prepareHome(): void {
    if (this.isHomePrepared) {
      return
    }
    this.isHomePrepared = true
    try {
      this.tabController.preloadItems([0, 1, 2, 3, 4])
    } catch (err) {
      console.error("init failed")
    }
  }

  build() {
    Stack() {
    if (this.authToken === '') {
      AuthPage({
        onAuthenticated: () => {
          this.currentTab = 0
          this.prepareHome()
        }
      })
    } else {
      HdsNavigation(this.pathStack) {
      Stack({ alignContent: Alignment.BottomEnd }) {
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

          TabContent() {
            SettingsPage({
              onLogout: () => { this.logout() },
              onManageAccounts: () => { this.pathStack.pushPathByName('AccountsPage', undefined) },
              onSystemSettings: () => { this.pathStack.pushPathByName('SystemSettingsPage', undefined) },
              onManageUsers: () => { this.pathStack.pushPathByName('UserManagementPage', undefined) },
              onManageGlobalMails: () => { this.pathStack.pushPathByName('GlobalMailPage', undefined) },
              onManageRoles: () => { this.pathStack.pushPathByName('RoleManagementPage', undefined) },
              onOpenAnalytics: () => { this.pathStack.pushPathByName('AnalyticsPage', undefined) },
              onManageRegistrationCodes: () => { this.pathStack.pushPathByName('RegistrationCodePage', undefined) }
            })
          }
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
        .margin({ right: 16, bottom: 55 })
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

    // 应用内闪屏覆盖层：蓝底 + 半屏大图标，淡出后移除
    if (this.showSplash) {
      SplashPage({
        onSplashFinished: () => {
          this.showSplash = false
        }
      })
    }
    }
    .width("100%")
    .height("100%")
    .backgroundColor($r("app.color.background"))
  }

  private logout(): void {
    AuthService.logout()
    this.currentTab = 0
  }

  @Builder
  navDestinationBuilder(name: string, param: Object) {
    if (name === "DetailPage") {
      DetailPageContent({ emailData: param as MailDetailParams })
    } else if (name === "ComposePage") {
      if (param instanceof ComposeParams) {
        ComposePageContent({ composeParams: param })
      } else {
        ComposePageContent()
      }
    } else if (name === 'AccountsPage') {
      AccountsPage()
    } else if (name === 'SystemSettingsPage') {
      SystemSettingsPage()
    } else if (name === 'UserManagementPage') {
      UserManagementPage()
    } else if (name === 'GlobalMailPage') {
      GlobalMailPage()
    } else if (name === 'RoleManagementPage') {
      RoleManagementPage()
    } else if (name === 'AnalyticsPage') {
      AnalyticsPage()
    } else if (name === 'RegistrationCodePage') {
      RegistrationCodePage()
    } else {
      NotFoundPage()
    }
  }
}

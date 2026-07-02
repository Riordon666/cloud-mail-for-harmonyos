import Constants from "../common/Constants"
import { EmailMock } from "../common/MockData"
import { SymbolGlyphModifier } from "@kit.ArkUI"
import { HdsNavDestination, HdsNavDestinationAttribute, ScrollEffectType, hdsMaterial, HdsNavDestinationTitleMode } from "@kit.UIDesignKit"

class DetailParams {
  emailData: EmailMock
  constructor(emailData: EmailMock) { this.emailData = emailData }
}

@Component
export struct DetailPageContent {
  private scroller: Scroller = new Scroller()
  @Prop emailData: DetailParams = new DetailParams({
    id: 0, name: "", email: "", subject: "", body: "", time: "",
    unread: false, cc: [], bcc: [], attList: [], htmlContent: ""
  })
  private pathStack: NavPathStack | null = null
  @State email: EmailMock = {
    id: 0, name: "", email: "", subject: "", body: "", time: "",
    unread: false, cc: [], bcc: [], attList: [], htmlContent: ""
  }
  @State showDetail: boolean = false
  @State showCcBcc: boolean = false
  @State isStarred: boolean = false

  aboutToAppear(): void {
    this.pathStack = AppStorage.get("appPathStack") as NavPathStack
    if (this.emailData?.emailData !== undefined) { this.email = this.emailData.emailData }
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Scroll(this.scroller) {
        Column() {
          Blank().height(6)

          Text(this.email.subject)
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor($r("app.color.text_primary"))
            .width("100%").padding({ top: 2, bottom: 8, left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })

          if (!this.showDetail) {
            Row() {
              Text(this.email.name).fontSize(14).fontColor("#34C759").maxLines(1)
              Blank()
              Text("详情").fontSize(14).fontColor($r("app.color.primary")).onClick(() => { this.showDetail = true })
            }
            .width("100%").padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 2, bottom: 8 })
          } else {
            Column() {
              Row() {
                Text("发件人：").fontSize(14).fontColor($r("app.color.text_secondary"))
                Text(this.email.name).fontSize(14).fontColor($r("app.color.text_primary"))
                Blank()
                Text("隐藏").fontSize(14).fontColor($r("app.color.primary")).onClick(() => { this.showDetail = false })
              }
              .width("100%").padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, bottom: 2 })

              Row() {
                Blank().width(56)
                Text(this.email.email).fontSize(13).fontColor($r("app.color.text_secondary"))
              }
              .width("100%").padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })

              Row() {
                Text("收件人：").fontSize(14).fontColor($r("app.color.text_secondary"))
                Text("admin").fontSize(14).fontColor($r("app.color.text_primary"))
              }
              .width("100%").padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE }).margin({ top: 6 })

              Row() {
                Blank().width(56)
                Text("admin@riordon.xyz").fontSize(13).fontColor($r("app.color.text_secondary"))
              }
              .width("100%").padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE }).margin({ top: 2 })

              Row() {
                Text("    时间：2025年6月29日 10:32").fontSize(14).fontColor($r("app.color.text_secondary"))
              }
              .width("100%").padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE }).margin({ top: 6 })
            }
            .width("100%").padding({ top: 2, bottom: 8 })
          }

          Divider().strokeWidth(0.5).color($r("app.color.divider"))

          Text(this.email.body).fontSize(15).fontColor($r("app.color.text_primary")).lineHeight(24)
            .width("100%").padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 12, bottom: 12 })

          ForEach(this.email.attList, (att: string) => {
            Row() {
              SymbolGlyph($r("sys.symbol.doc")).fontSize(24).fontColor([$r("app.color.primary")])
              Column() {
                Text(att).fontSize(14).fontColor($r("app.color.text_primary"))
                Text("点击下载").fontSize(11).fontColor($r("app.color.primary")).margin({ top: 2 })
              }.margin({ left: 12 }).layoutWeight(1).alignItems(HorizontalAlign.Start)
              SymbolGlyph($r("sys.symbol.arrow_down_to_line")).fontSize(20).fontColor([$r("app.color.primary")])
            }
            .width("100%").padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 14, bottom: 14 })
            .backgroundColor($r("app.color.card")).borderRadius(10).margin({ top: 4, bottom: 4 })
          })

          Blank().layoutWeight(1)
        }
        .width("100%")
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
      }
      .width("100%").height("100%").scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)

        Row() {
          Column() {
            SymbolGlyph($r("sys.symbol.arrowshape_turn_up_left")).fontSize(24).fontColor([$r("app.color.text_primary")])
            Text("回复").fontSize(11).fontColor($r("app.color.text_secondary")).margin({ top: 4 })
          }.layoutWeight(1).alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center).onClick(() => {})

          Column() {
            SymbolGlyph($r("sys.symbol.arrowshape_turn_up_right")).fontSize(24).fontColor([$r("app.color.text_primary")])
            Text("转发").fontSize(11).fontColor($r("app.color.text_secondary")).margin({ top: 4 })
          }.layoutWeight(1).alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center).onClick(() => {})

          Column() {
            SymbolGlyph($r("sys.symbol.star")).fontSize(24).fontColor([$r("app.color.text_primary")])
            Text("星标").fontSize(11).fontColor($r("app.color.text_secondary")).margin({ top: 4 })
          }.layoutWeight(1).alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center).onClick(() => { this.isStarred = !this.isStarred })

          Column() {
            SymbolGlyph($r("sys.symbol.trash")).fontSize(24).fontColor([$r("app.color.text_primary")])
            Text("删除").fontSize(11).fontColor($r("app.color.text_secondary")).margin({ top: 4 })
          }.layoutWeight(1).alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center).onClick(() => { this.deleteEmail() })
        }
        .width("100%").padding({ top: 12, bottom: 16 })
        .borderRadius(24)
        .margin({ left: 16, right: 16, bottom: 16 })
        .backgroundColor("#CCFFFFFF")
      }
      .width("100%").height("100%")
    }
    .titleBar({
      content: {
        title: { mainTitle: "" },
        menu: {
          maxCount: 2,
          value: [
            { content: { label: "上一封", icon: $r("sys.symbol.chevron_up"), isEnabled: true, action: () => { this.prevEmail() } } },
            { content: { label: "下一封", icon: $r("sys.symbol.chevron_down"), isEnabled: true, action: () => { this.nextEmail() } } }
          ]
        }
      },
      enableComponentSafeArea: true,
      style: {
        scrollEffectOpts: { enableScrollEffect: true, scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR },
        originalStyle: {
          contentStyle: {
            titleStyle: { mainTitleColor: $r("app.color.text_primary"), subTitleColor: $r("app.color.text_secondary") },
            menuStyle: { iconColor: $r("app.color.text_primary") },
            backIconStyle: { iconColor: $r("app.color.text_primary") }
          }
        },
        scrollEffectStyle: {
          contentStyle: {
            titleStyle: { mainTitleColor: $r("app.color.text_primary"), subTitleColor: $r("app.color.text_secondary") },
            menuStyle: { iconColor: $r("app.color.text_primary") },
            backIconStyle: { iconColor: $r("app.color.text_primary") }
          }
        },
        systemMaterialEffect: { materialType: hdsMaterial.MaterialType.IMMERSIVE, materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE }
      }
    })
    .hideBackButton(false)
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .bindToScrollable([this.scroller])
    .onBackPressed(() => { if (this.pathStack !== null) { this.pathStack.pop() } return true })
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .systemBarStyle({ statusBarContentColor: "#000000" }, { statusBarContentColor: "#000000" })
    .width("100%").height("100%").backgroundColor($r("app.color.background"))
  }

  private prevEmail(): void {}
  private nextEmail(): void {}
  private deleteEmail(): void {}
}
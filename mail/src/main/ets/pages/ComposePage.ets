import Constants from "../common/Constants"
import { HdsNavDestination, HdsNavDestinationAttribute, HdsNavDestinationTitleMode, ScrollEffectType, hdsMaterial } from "@kit.UIDesignKit"

export class ComposeParams {
  toEmail: string
  ccEmail: string
  bccEmail: string
  subject: string
  content: string

  constructor(toEmail: string = '', ccEmail: string = '', bccEmail: string = '', subject: string = '', content: string = '') {
    this.toEmail = toEmail
    this.ccEmail = ccEmail
    this.bccEmail = bccEmail
    this.subject = subject
    this.content = content
  }
}

@Component
export struct ComposePageContent {
  private scroller: Scroller = new Scroller()
  @Prop composeParams: ComposeParams = new ComposeParams()
  @State toEmail: string = ""
  @State ccEmail: string = ""
  @State bccEmail: string = ""
  @State subject: string = ""
  @State content: string = ""
  @State sending: boolean = false

  aboutToAppear(): void {
    this.toEmail = this.composeParams.toEmail
    this.ccEmail = this.composeParams.ccEmail
    this.bccEmail = this.composeParams.bccEmail
    this.subject = this.composeParams.subject
    this.content = this.composeParams.content
  }

  build() {
    HdsNavDestination() {
      Scroll(this.scroller) {
        Column() {
          Row() {
            Text("收件人").fontSize(14).fontWeight(FontWeight.Medium).fontColor($r("app.color.text_secondary")).width(56)
            TextInput({ placeholder: "输入邮箱地址", text: this.toEmail })
              .placeholderColor($r("app.color.text_tertiary")).fontColor($r("app.color.text_primary"))
              .backgroundColor(Color.Transparent).layoutWeight(1).height(44)
              .onChange((v: string) => { this.toEmail = v })
          }
          .width("100%").padding({ top: 12, bottom: 12 })

          Divider().strokeWidth(0.5).color($r("app.color.divider"))

          Row() {
            Text("抄送").fontSize(14).fontWeight(FontWeight.Medium).fontColor($r("app.color.text_tertiary")).width(56)
            TextInput({ placeholder: "抄送邮箱（可选）", text: this.ccEmail })
              .placeholderColor($r("app.color.text_tertiary")).fontColor($r("app.color.text_primary"))
              .backgroundColor(Color.Transparent).layoutWeight(1).height(44)
              .onChange((v: string) => { this.ccEmail = v })
          }
          .width("100%").padding({ top: 12, bottom: 12 })

          Divider().strokeWidth(0.5).color($r("app.color.divider"))

          Row() {
            Text("密送").fontSize(14).fontWeight(FontWeight.Medium).fontColor($r("app.color.text_tertiary")).width(56)
            TextInput({ placeholder: "密送邮箱（可选）", text: this.bccEmail })
              .placeholderColor($r("app.color.text_tertiary")).fontColor($r("app.color.text_primary"))
              .backgroundColor(Color.Transparent).layoutWeight(1).height(44)
              .onChange((v: string) => { this.bccEmail = v })
          }
          .width("100%").padding({ top: 12, bottom: 12 })

          Divider().strokeWidth(0.5).color($r("app.color.divider"))

          Row() {
            Text("主题").fontSize(14).fontWeight(FontWeight.Medium).fontColor($r("app.color.text_secondary")).width(56)
            TextInput({ placeholder: "邮件主题", text: this.subject })
              .placeholderColor($r("app.color.text_tertiary")).fontColor($r("app.color.text_primary"))
              .backgroundColor(Color.Transparent).layoutWeight(1).height(44)
              .onChange((v: string) => { this.subject = v })
          }
          .width("100%").padding({ top: 12, bottom: 12 })

          Divider().strokeWidth(0.5).color($r("app.color.divider"))

          TextArea({ placeholder: "写点什么...", text: this.content })
            .placeholderColor($r("app.color.text_tertiary")).fontColor($r("app.color.text_primary"))
            .backgroundColor(Color.Transparent).padding(Constants.PADDING_EDGE).height(300)
            .onChange((v: string) => { this.content = v })

          Row() {
            SymbolGlyph($r("sys.symbol.paperplane_fill"))
              .fontSize(20).fontColor([$r("sys.color.icon_on_primary")])
            Text("发送").fontSize(13).fontColor($r("sys.color.icon_on_primary")).margin({ left: 4 })
          }
          .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 10, bottom: 10 })
          .backgroundColor($r("app.color.primary")).borderRadius(22)
          .onClick(() => { this.sendEmail() })
          .justifyContent(FlexAlign.Center).width("100%")
          .padding({ top: 12, bottom: 16 })

          Blank().height(20)
        }
        .width("100%")
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
        .alignItems(HorizontalAlign.Start)
      }
      .width("100%").height("100%")
      .scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
    }
    .titleBar({
      content: { title: { mainTitle: "写邮件" } },
      enableComponentSafeArea: true,
      style: {
        scrollEffectOpts: { enableScrollEffect: true, scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR },
        originalStyle: {
          contentStyle: {
            titleStyle: { mainTitleColor: $r("app.color.text_primary") },
            backIconStyle: { iconColor: $r("app.color.text_primary") }
          }
        },
        scrollEffectStyle: {
          contentStyle: {
            titleStyle: { mainTitleColor: $r("app.color.text_primary") },
            backIconStyle: { iconColor: $r("app.color.text_primary") }
          }
        },
        systemMaterialEffect: { materialType: hdsMaterial.MaterialType.IMMERSIVE, materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE }
      }
    })
    .hideBackButton(false)
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .bindToScrollable([this.scroller])
    .onBackPressed(() => {
      const stack: NavPathStack | null = AppStorage.get("appPathStack") as NavPathStack
      if (stack !== null) { stack.pop() }
      return true
    })
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .systemBarStyle({ statusBarContentColor: "#000000" }, { statusBarContentColor: "#000000" })
    .width("100%").height("100%")
    .backgroundColor($r("app.color.background"))
  }

  private sendEmail(): void {
    if (this.toEmail.trim() === "" || this.sending) { return }
    this.sending = true
    setTimeout(() => {
      this.sending = false
      this.toEmail = ""; this.ccEmail = ""; this.bccEmail = ""; this.subject = ""; this.content = ""
      const stack: NavPathStack | null = AppStorage.get("appPathStack") as NavPathStack
      if (stack !== null) { stack.pop() }
    }, 1000)
  }
}

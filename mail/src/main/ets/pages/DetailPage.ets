import Constants from "../common/Constants"
import { ApiException } from '../common/HttpClient'
import { MailDetailParams, MailItem } from '../common/MailModels'
import { MailService } from '../common/MailService'
import { ComposeParams } from './ComposePage'
import { DividerModifier, LengthMetrics, PromptAction, SymbolGlyphModifier, ToolBar, ToolBarModifier, ToolBarOptions } from "@kit.ArkUI"
import { http } from '@kit.NetworkKit'
import { fileIo, picker } from '@kit.CoreFileKit'
import { HdsNavDestination, HdsNavDestinationAttribute, ScrollEffectType, hdsMaterial, HdsNavDestinationTitleMode } from "@kit.UIDesignKit"

@Component
export struct DetailPageContent {
  private scroller: Scroller = new Scroller()
  @Prop emailData: MailDetailParams = new MailDetailParams(new MailItem(), [], 0)
  private pathStack: NavPathStack | null = null
  @State email: MailItem = new MailItem()
  @State emailList: MailItem[] = []
  @State currentIndex: number = 0
  @State showDetail: boolean = false
  @State showCcBcc: boolean = false
  @State isStarred: boolean = false
  private toast: PromptAction = this.getUIContext().getPromptAction()
  @State toolbarList: ToolBarOptions = new ToolBarOptions()
  private toolBarModifier: ToolBarModifier = new ToolBarModifier()
    .height(LengthMetrics.vp(64))
    .backgroundColor($r("app.color.card"))
    .stateEffect(true)
  private dividerModifier: DividerModifier = new DividerModifier().height(0)

  aboutToAppear(): void {
    this.pathStack = AppStorage.get("appPathStack") as NavPathStack
    if (this.emailData.emailData !== undefined) {
      this.email = this.emailData.emailData
      this.emailList = this.emailData.emailList.slice()
      this.currentIndex = this.emailData.currentIndex
      this.isStarred = this.email.starred
    }
    this.refreshToolbar()
  }

  private refreshToolbar(): void {
    this.toolbarList.splice(0, this.toolbarList.length)
    this.toolbarList.push({
      content: "回复",
      action: () => { this.replyEmail() },
      toolBarSymbolOptions: {
        normal: new SymbolGlyphModifier($r("sys.symbol.arrowshape_turn_up_left"))
          .fontColor([$r("app.color.text_primary")])
      }
    })
    this.toolbarList.push({
      content: "转发",
      action: () => { this.forwardEmail() },
      toolBarSymbolOptions: {
        normal: new SymbolGlyphModifier($r("sys.symbol.arrowshape_turn_up_right"))
          .fontColor([$r("app.color.text_primary")])
      }
    })
    this.toolbarList.push({
      content: this.isStarred ? "已星标" : "星标",
      action: () => { this.toggleStar() },
      toolBarSymbolOptions: {
        normal: new SymbolGlyphModifier(this.isStarred ? $r("sys.symbol.star_fill") : $r("sys.symbol.star"))
          .fontColor(this.isStarred ? [$r("app.color.primary")] : [$r("app.color.text_primary")])
      }
    })
    this.toolbarList.push({
      content: "删除",
      action: () => { this.deleteEmail() },
      toolBarSymbolOptions: {
        normal: new SymbolGlyphModifier($r("sys.symbol.trash"))
          .fontColor([$r("app.color.danger")])
      }
    })
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
              Text(this.email.name).fontSize(14).fontColor($r('app.color.success')).maxLines(1)
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
                Text(this.email.toEmail === '' ? '当前账户' : this.email.toEmail).fontSize(14).fontColor($r("app.color.text_primary"))
              }
              .width("100%").padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE }).margin({ top: 6 })

              Row() {
                Blank().width(56)
                Text(this.email.toEmail === '' ? this.email.email : this.email.toEmail).fontSize(13).fontColor($r("app.color.text_secondary"))
              }
              .width("100%").padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE }).margin({ top: 2 })

              Row() {
                Text('    时间：' + this.email.time).fontSize(14).fontColor($r("app.color.text_secondary"))
              }
              .width("100%").padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE }).margin({ top: 6 })
            }
            .width("100%").padding({ top: 2, bottom: 8 })
          }

          Divider().strokeWidth(0.5).color($r("app.color.divider"))

          Text(this.email.body).fontSize(15).fontColor($r("app.color.text_primary")).lineHeight(24)
            .width("100%").padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 12, bottom: 12 })

          ForEach(this.email.attList, (att: string, index: number) => {
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
            .onClick(() => { this.downloadAttachment(index, att) })
          })

          Blank().height(88)
          Blank().layoutWeight(1)
        }
        .width("100%")
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
      }
      .width("100%").height("100%").scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)

        Column() {
          ToolBar({
            toolBarList: this.toolbarList,
            toolBarModifier: this.toolBarModifier,
            dividerModifier: this.dividerModifier
          })
        }
        .width("100%")
        .borderRadius(24)
        .clip(true)
        .margin({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, bottom: 16 })
        .shadow(Constants.SHADOW_CARD)
      }
      .width("100%").height("100%")
    }
    .titleBar({
      content: {
        title: { mainTitle: "" },
        menu: {
          maxCount: 2,
          value: [
            { content: { label: "上一封", icon: $r("sys.symbol.chevron_up"), isEnabled: this.currentIndex > 0, action: () => { this.prevEmail() } } },
            { content: { label: "下一封", icon: $r("sys.symbol.chevron_down"), isEnabled: this.currentIndex < this.emailList.length - 1, action: () => { this.nextEmail() } } }
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

  private prevEmail(): void {
    if (this.currentIndex > 0) {
      this.currentIndex--
      this.email = this.emailList[this.currentIndex]
      this.showDetail = false
      this.isStarred = this.email.starred
      this.refreshToolbar()
      this.scroller.scrollTo({ xOffset: 0, yOffset: 0 })
    }
  }

  private nextEmail(): void {
    if (this.currentIndex < this.emailList.length - 1) {
      this.currentIndex++
      this.email = this.emailList[this.currentIndex]
      this.showDetail = false
      this.isStarred = this.email.starred
      this.refreshToolbar()
      this.scroller.scrollTo({ xOffset: 0, yOffset: 0 })
    }
  }

  private async deleteEmail(): Promise<void> {
    try {
      await MailService.delete(this.email.id)
      this.emailList.splice(this.currentIndex, 1)
      if (this.emailList.length === 0) {
        if (this.pathStack !== null) { this.pathStack.pop() }
        return
      }
      if (this.currentIndex >= this.emailList.length) {
        this.currentIndex = this.emailList.length - 1
      }
      this.email = this.emailList[this.currentIndex]
      this.showDetail = false
      this.isStarred = this.email.starred
      this.refreshToolbar()
      this.showToast('邮件已删除')
    } catch (err) {
      this.showRequestError(err)
    }
  }

  private replyEmail(): void {
    if (this.pathStack === null) {
      return
    }
    const prefix: string = this.email.subject.indexOf('Re:') === 0 ? '' : 'Re: '
    const params: ComposeParams = new ComposeParams(this.email.email, '', '', prefix + this.email.subject, '', 'reply', this.email.id)
    this.pathStack.pushPathByName('ComposePage', params)
  }

  private forwardEmail(): void {
    if (this.pathStack === null) {
      return
    }
    const prefix: string = this.email.subject.indexOf('Fwd:') === 0 ? '' : 'Fwd: '
    const params: ComposeParams = new ComposeParams('', '', '', prefix + this.email.subject, this.email.body, 'forward', this.email.id)
    this.pathStack.pushPathByName('ComposePage', params)
  }

  private showToast(message: string): void {
    try {
      this.toast.openToast({ message: message, duration: 2000 })
    } catch (err) {
      console.error('openToast failed')
    }
  }

  private async toggleStar(): Promise<void> {
    const nextStarred: boolean = !this.isStarred
    try {
      await MailService.setStar(this.email.id, nextStarred)
      const nextEmail: MailItem = this.email.copy()
      nextEmail.starred = nextStarred
      this.email = nextEmail
      this.isStarred = nextStarred
      this.refreshToolbar()
      this.showToast(nextStarred ? '已加入星标' : '已取消星标')
    } catch (err) {
      this.showRequestError(err)
    }
  }

  private showRequestError(err: Error): void {
    if (err instanceof ApiException) {
      this.showToast(err.message)
      return
    }
    this.showToast('请求失败，请稍后重试')
  }

  private async downloadAttachment(index: number, filename: string): Promise<void> {
    if (index >= this.email.attachmentKeys.length || this.email.attachmentKeys[index] === '') {
      this.showToast('附件地址无效')
      return
    }
    const request: http.HttpRequest = http.createHttp()
    try {
      const response: http.HttpResponse = await request.request(this.getAttachmentUrl(this.email.attachmentKeys[index]), {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        usingCache: false,
        connectTimeout: 10000,
        readTimeout: 30000
      })
      if (response.responseCode < 200 || response.responseCode >= 300) {
        this.showToast('下载附件失败')
        return
      }
      const content: ArrayBuffer = response.result as ArrayBuffer
      const context: Context = this.getUIContext().getHostContext() as Context
      const options: picker.DocumentSaveOptions = new picker.DocumentSaveOptions()
      options.newFileNames = [filename]
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context)
      const destinations: string[] = await documentPicker.save(options)
      if (destinations.length === 0) {
        return
      }
      const file: fileIo.File = fileIo.openSync(destinations[0], fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC)
      try {
        fileIo.writeSync(file.fd, content)
      } finally {
        fileIo.closeSync(file)
      }
      this.showToast('附件已保存')
    } catch (err) {
      this.showToast('下载附件失败，请重试')
    } finally {
      request.destroy()
    }
  }

  private getAttachmentUrl(key: string): string {
    const apiIndex: number = Constants.API_URL.lastIndexOf('/api')
    const host: string = apiIndex > 0 ? Constants.API_URL.substring(0, apiIndex) : Constants.API_URL
    return host + '/oss/' + key
  }
}

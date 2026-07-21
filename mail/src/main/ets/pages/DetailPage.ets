import Constants from "../common/Constants"
import { ApiException } from '../common/HttpClient'
import { MailDetailParams, MailItem } from '../common/MailModels'
import { MailService } from '../common/MailService'
import { SettingsApi, WebsiteConfig } from '../api/SettingsApi'
import { ComposeParams } from './ComposePage'
import { LengthMetrics, PromptAction } from "@kit.ArkUI"
import { http } from '@kit.NetworkKit'
import { fileIo, picker } from '@kit.CoreFileKit'
import { webview } from '@kit.ArkWeb'
import { ActionBarButton, ActionBarStyle, BlurStrategy, HdsActionBar, HdsNavDestination, HdsNavDestinationAttribute, ScrollEffectType, hdsMaterial, HdsNavDestinationTitleMode } from "@kit.UIDesignKit"

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
  @State mediaBaseUrl: string = ''
  private toast: PromptAction = this.getUIContext().getPromptAction()
  private webController: webview.WebviewController = new webview.WebviewController()
  private isWebAttached: boolean = false

  private replyAction: ActionBarButton = new ActionBarButton({
    baseIcon: $r('sys.symbol.arrowshape_turn_up_left'),
    onClick: () => { this.replyEmail() },
    accessibilityText: '回复',
    hoverTips: '回复',
    id: 'detail-reply'
  })
  private forwardAction: ActionBarButton = new ActionBarButton({
    baseIcon: $r('sys.symbol.arrowshape_turn_up_right'),
    onClick: () => { this.forwardEmail() },
    accessibilityText: '转发',
    hoverTips: '转发',
    id: 'detail-forward'
  })
  private starAction: ActionBarButton = new ActionBarButton({
    baseIcon: $r('sys.symbol.star'),
    altIcon: $r('sys.symbol.star_fill'),
    onClick: () => { this.toggleStar() },
    accessibilityText: '星标',
    hoverTips: '星标',
    id: 'detail-star'
  })
  private deleteAction: ActionBarButton = new ActionBarButton({
    baseIcon: $r('sys.symbol.trash'),
    onClick: () => { this.deleteEmail() },
    accessibilityText: '删除',
    hoverTips: '删除',
    id: 'detail-delete'
  })
  private startActions: ActionBarButton[] = [this.replyAction, this.forwardAction]
  private endActions: ActionBarButton[] = [this.deleteAction]

  aboutToAppear(): void {
    this.pathStack = AppStorage.get("appPathStack") as NavPathStack
    this.mediaBaseUrl = this.getAttachmentBaseUrl()
    if (this.emailData.emailData !== undefined) {
      this.email = this.emailData.emailData
      this.emailList = this.emailData.emailList.slice()
      this.currentIndex = this.emailData.currentIndex
      this.isStarred = this.email.starred
    }
    this.refreshMediaBaseUrl()
  }

  private async refreshMediaBaseUrl(): Promise<void> {
    try {
      const config: WebsiteConfig = await SettingsApi.getWebsiteConfig()
      this.mediaBaseUrl = this.normalizeMediaBaseUrl(config.r2Domain)
    } catch (err) {
      this.mediaBaseUrl = this.getAttachmentBaseUrl()
    }
    this.loadMailContent()
  }

  private loadMailContent(): void {
    if (!this.isWebAttached) {
      return
    }
    try {
      this.webController.loadData(this.buildMailDocument(), 'text/html', 'UTF-8', ' ', ' ')
    } catch (err) {
      console.error('load mail html failed')
    }
  }

  private buildMailDocument(): string {
    const head: string = '<!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1.0" ' +
      'charset="utf-8"><style>html,body{height:auto!important;min-height:1px!important;margin:0;padding:0;' +
      'background:transparent;color:CanvasText;color-scheme:light dark;overflow-wrap:anywhere;}' +
      'img,video{display:block;max-width:100%!important;height:auto!important;}table{max-width:100%!important;}' +
      'pre{white-space:pre-wrap;overflow-wrap:anywhere;}</style></head><body>'
    const tail: string = '</body></html>'
    if (this.isHtmlMail()) {
      return head + this.normalizeMailContent(this.email.htmlContent) + tail
    }
    return head + '<pre>' + this.escapeHtml(this.email.body) + '</pre>' + tail
  }

  private normalizeMailContent(content: string): string {
    const imageBaseUrl: string = this.mediaBaseUrl === '' ? this.getAttachmentBaseUrl() : this.mediaBaseUrl
    return content.replaceAll('{{domain}}/', imageBaseUrl).replaceAll('{{domain}}', imageBaseUrl)
  }

  private normalizeMediaBaseUrl(domain: string): string {
    let result: string = domain.trim()
    if (result === '') {
      return this.getAttachmentBaseUrl()
    }
    if (result.indexOf('http://') !== 0 && result.indexOf('https://') !== 0) {
      result = 'https://' + result
    }
    if (result.lastIndexOf('/') !== result.length - 1) {
      result += '/'
    }
    return result
  }

  private isHtmlMail(): boolean {
    const content: string = this.email.htmlContent.trim().toLowerCase()
    return content.indexOf('<html') >= 0 || content.indexOf('<body') >= 0 || content.indexOf('<div') >= 0 ||
      content.indexOf('<p') >= 0 || content.indexOf('<img') >= 0 || content.indexOf('<table') >= 0 ||
      content.indexOf('<br') >= 0 || content.indexOf('<style') >= 0 || content.indexOf('<!doctype') >= 0
  }

  private escapeHtml(value: string): string {
    return value.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;')
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

          Web({ src: 'about:blank', controller: this.webController, renderMode: RenderMode.SYNC_RENDER })
            .width('100%')
            .layoutMode(WebLayoutMode.FIT_CONTENT)
            .overScrollMode(OverScrollMode.NEVER)
            .javaScriptAccess(false)
            .imageAccess(true)
            .onlineImageAccess(true)
            .mixedMode(MixedMode.All)
            .backgroundColor(Color.Transparent)
            .onControllerAttached(() => {
              this.isWebAttached = true
              this.loadMailContent()
            })

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

        Row() {
          HdsActionBar({
            startButtons: this.startActions,
            primaryButton: this.starAction,
            endButtons: this.endActions,
            actionBarStyle: new ActionBarStyle({
              height: LengthMetrics.vp(64),
              backgroundBlurStyle: BlurStyle.COMPONENT_THICK,
              isPrimaryIconChanged: this.isStarred,
              margin: LengthMetrics.vp(0)
            }),
            isExpand: true,
            blurStrategy: BlurStrategy.ADAPTIVE
          })
        }
        .width("100%")
        .justifyContent(FlexAlign.Center)
        .margin({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, bottom: 16 })
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
      this.loadMailContent()
      this.scroller.scrollTo({ xOffset: 0, yOffset: 0 })
    }
  }

  private nextEmail(): void {
    if (this.currentIndex < this.emailList.length - 1) {
      this.currentIndex++
      this.email = this.emailList[this.currentIndex]
      this.showDetail = false
      this.isStarred = this.email.starred
      this.loadMailContent()
      this.scroller.scrollTo({ xOffset: 0, yOffset: 0 })
    }
  }

  private async deleteEmail(): Promise<void> {
    try {
      await MailService.delete(this.email.id)
      const remaining: MailItem[] = []
      for (let index = 0; index < this.emailList.length; index++) {
        if (this.emailList[index].id !== this.email.id) {
          remaining.push(this.emailList[index])
        }
      }
      this.emailList = remaining
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
      this.loadMailContent()
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
      const updatedList: MailItem[] = []
      for (let index = 0; index < this.emailList.length; index++) {
        if (this.emailList[index].id === nextEmail.id) {
          updatedList.push(nextEmail)
        } else {
          updatedList.push(this.emailList[index])
        }
      }
      this.emailList = updatedList
      this.isStarred = nextStarred
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
    return this.getAttachmentBaseUrl() + key
  }

  private getAttachmentBaseUrl(): string {
    return Constants.API_URL + '/oss/'
  }
}

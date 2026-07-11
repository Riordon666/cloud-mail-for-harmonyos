import Constants from "../common/Constants"
import { ApiException } from '../common/HttpClient'
import { DraftService } from '../common/DraftService'
import { MailAttachment } from '../common/MailModels'
import { MailService } from '../common/MailService'
import { PromptAction } from '@kit.ArkUI'
import { util } from '@kit.ArkTS'
import { fileIo, picker } from '@kit.CoreFileKit'
import { HdsNavDestination, HdsNavDestinationAttribute, HdsNavDestinationTitleMode, ScrollEffectType, hdsMaterial } from "@kit.UIDesignKit"

export class ComposeParams {
  toEmail: string
  ccEmail: string
  bccEmail: string
  subject: string
  content: string
  sendType: string
  emailId: number
  draftId: number

  constructor(toEmail: string = '', ccEmail: string = '', bccEmail: string = '', subject: string = '', content: string = '',
    sendType: string = '', emailId: number = 0, draftId: number = 0) {
    this.toEmail = toEmail
    this.ccEmail = ccEmail
    this.bccEmail = bccEmail
    this.subject = subject
    this.content = content
    this.sendType = sendType
    this.emailId = emailId
    this.draftId = draftId
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
  @State attachments: MailAttachment[] = []
  @State sending: boolean = false
  private draftId: number = 0
  private toast: PromptAction = this.getUIContext().getPromptAction()

  aboutToAppear(): void {
    this.toEmail = this.composeParams.toEmail
    this.ccEmail = this.composeParams.ccEmail
    this.bccEmail = this.composeParams.bccEmail
    this.subject = this.composeParams.subject
    this.content = this.composeParams.content
    this.draftId = this.composeParams.draftId
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
            Button('添加附件', { type: ButtonType.Normal, stateEffect: true })
              .height(36)
              .fontSize(Constants.FONT_SIZE_SMALL)
              .fontColor($r('app.color.primary'))
              .backgroundColor($r('app.color.primary_light'))
              .onClick(() => { this.chooseAttachments() })
            Text(this.attachments.length === 0 ? '最多 10 个附件' : '已添加 ' + this.attachments.length.toString() + ' 个附件')
              .fontSize(Constants.FONT_SIZE_SMALL)
              .fontColor($r('app.color.text_secondary'))
              .margin({ left: Constants.GAP_SMALL })
          }
          .width('100%')
          .padding({ top: 8, bottom: 4 })

          ForEach(this.attachments, (item: MailAttachment, index: number) => {
            Row() {
              SymbolGlyph($r('sys.symbol.doc'))
                .fontSize(Constants.SIZE_ICON_SMALL)
                .fontColor([$r('app.color.primary')])
              Text(item.filename)
                .fontSize(Constants.FONT_SIZE_SMALL)
                .fontColor($r('app.color.text_primary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
                .margin({ left: Constants.GAP_SMALL })
              Button({ type: ButtonType.Circle, stateEffect: true }) {
                SymbolGlyph($r('sys.symbol.xmark'))
                  .fontSize(Constants.SIZE_ICON_SMALL)
                  .fontColor([$r('app.color.text_secondary')])
              }
              .width(28)
              .height(28)
              .backgroundColor(Color.Transparent)
              .onClick(() => { this.removeAttachment(index) })
            }
            .width('100%')
            .padding({ top: 6, bottom: 6, left: Constants.PADDING_INNER, right: Constants.PADDING_INNER })
            .backgroundColor($r('app.color.card'))
            .borderRadius(Constants.RADIUS_SMALL)
            .margin({ top: 2, bottom: 2 })
          }, (item: MailAttachment): string => item.filename)

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
      this.saveDraftIfNeeded()
      const stack: NavPathStack | null = AppStorage.get("appPathStack") as NavPathStack
      if (stack !== null) { stack.pop() }
      return true
    })
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .systemBarStyle({ statusBarContentColor: "#000000" }, { statusBarContentColor: "#000000" })
    .width("100%").height("100%")
    .backgroundColor($r("app.color.background"))
  }

  private async sendEmail(): Promise<void> {
    if (this.sending) {
      return
    }
    if (this.toEmail.trim() === '') {
      this.showToast('请输入收件人邮箱')
      return
    }
    if (this.subject.trim() === '') {
      this.showToast('请输入邮件主题')
      return
    }
    if (this.content.trim() === '') {
      this.showToast('请输入邮件正文')
      return
    }
    this.sending = true
    try {
      await MailService.send(this.toEmail, this.ccEmail, this.bccEmail, this.subject, this.content,
        this.composeParams.sendType, this.composeParams.emailId, this.attachments)
      this.sending = false
      this.showToast('邮件已发送')
      this.toEmail = ''
      this.ccEmail = ''
      this.bccEmail = ''
      this.subject = ''
      this.content = ''
      this.attachments = []
      if (this.draftId !== 0) {
        DraftService.deleteDraft(this.draftId)
        this.draftId = 0
      }
      const stack: NavPathStack | null = AppStorage.get("appPathStack") as NavPathStack
      if (stack !== null) { stack.pop() }
    } catch (err) {
      this.sending = false
      if (err instanceof ApiException) {
        this.showToast(err.message)
      } else {
        this.showToast('发送失败，请稍后重试')
      }
    }
  }

  private showToast(message: string): void {
    try {
      this.toast.openToast({ message: message, duration: 1800 })
    } catch (err) {
      console.error('openToast failed')
    }
  }

  private saveDraftIfNeeded(): void {
    if (this.sending) {
      return
    }
    this.draftId = DraftService.saveDraft(this.draftId, this.toEmail, this.ccEmail, this.bccEmail, this.subject, this.content)
  }

  private async chooseAttachments(): Promise<void> {
    if (this.attachments.length >= 10) {
      this.showToast('最多添加 10 个附件')
      return
    }
    try {
      const context: Context = this.getUIContext().getHostContext() as Context
      const options: picker.DocumentSelectOptions = new picker.DocumentSelectOptions()
      options.maxSelectNumber = 10 - this.attachments.length
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context)
      const uris: string[] = await documentPicker.select(options)
      const next: MailAttachment[] = this.attachments.slice()
      for (let index = 0; index < uris.length; index++) {
        next.push(this.readAttachment(uris[index]))
      }
      this.attachments = next
    } catch (err) {
      this.showToast('读取附件失败，请确认文件访问权限')
    }
  }

  private readAttachment(uri: string): MailAttachment {
    let file: fileIo.File | null = null
    try {
      file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY)
      const stat: fileIo.Stat = fileIo.statSync(file.fd)
      if (stat.size > 10 * 1024 * 1024) {
        throw new ApiException(-1, '单个附件不能超过 10 MB', false)
      }
      const buffer: ArrayBuffer = new ArrayBuffer(stat.size)
      const length: number = fileIo.readSync(file.fd, buffer)
      const bytes: Uint8Array = new Uint8Array(buffer, 0, length)
      const content: string = new util.Base64Helper().encodeToStringSync(bytes, util.Type.BASIC)
      const filename: string = this.getAttachmentName(uri)
      return new MailAttachment(filename, content, 'application/octet-stream')
    } catch (err) {
      if (err instanceof ApiException) {
        throw err
      }
      throw new ApiException(-1, '读取附件失败', false)
    } finally {
      if (file !== null) {
        try {
          fileIo.closeSync(file)
        } catch (err) {
          console.error('close attachment failed')
        }
      }
    }
  }

  private removeAttachment(index: number): void {
    const next: MailAttachment[] = []
    for (let itemIndex = 0; itemIndex < this.attachments.length; itemIndex++) {
      if (itemIndex !== index) {
        next.push(this.attachments[itemIndex])
      }
    }
    this.attachments = next
  }

  private getAttachmentName(uri: string): string {
    const slashIndex: number = uri.lastIndexOf('/')
    const filename: string = slashIndex < 0 ? uri : uri.substring(slashIndex + 1)
    return decodeURIComponent(filename)
  }
}

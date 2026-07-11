export class MailItem {
  id: number = 0
  name: string = ''
  email: string = ''
  subject: string = ''
  body: string = ''
  time: string = ''
  unread: boolean = false
  cc: string[] = []
  bcc: string[] = []
  attList: string[] = []
  attachmentKeys: string[] = []
  htmlContent: string = ''
  toEmail: string = ''
  accountId: number = 0
  type: number = 0
  starred: boolean = false

  copy(): MailItem {
    const item: MailItem = new MailItem()
    item.id = this.id
    item.name = this.name
    item.email = this.email
    item.subject = this.subject
    item.body = this.body
    item.time = this.time
    item.unread = this.unread
    item.cc = this.cc.slice()
    item.bcc = this.bcc.slice()
    item.attList = this.attList.slice()
    item.attachmentKeys = this.attachmentKeys.slice()
    item.htmlContent = this.htmlContent
    item.toEmail = this.toEmail
    item.accountId = this.accountId
    item.type = this.type
    item.starred = this.starred
    return item
  }
}

export class MailAttachment {
  filename: string
  content: string
  type: string

  constructor(filename: string, content: string, type: string) {
    this.filename = filename
    this.content = content
    this.type = type
  }
}

export class MailDetailParams {
  emailData: MailItem
  emailList: MailItem[]
  currentIndex: number

  constructor(emailData: MailItem, emailList: MailItem[], currentIndex: number) {
    this.emailData = emailData
    this.emailList = emailList
    this.currentIndex = currentIndex
  }
}

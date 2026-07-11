import { ApiException, ApiResponse } from './HttpClient'
import { EmailApi } from '../api/EmailApi'
import { MailAttachment, MailItem } from './MailModels'

class RemoteAttachment {
  filename: string = ''
  key: string = ''
}

class RemoteEmail {
  emailId: number = 0
  sendEmail: string = ''
  name: string = ''
  accountId: number = 0
  subject: string = ''
  text: string = ''
  content: string = ''
  cc: string = '[]'
  bcc: string = '[]'
  toEmail: string = ''
  toName: string = ''
  type: number = 0
  unread: number = 0
  createTime: string = ''
  isStar: number = 0
  attList: RemoteAttachment[] = []
}

class RemoteMailList {
  list: RemoteEmail[] = []
}

class SendMailRequest {
  accountId: number
  name: string
  sendType: string
  emailId: number
  receiveEmail: string[]
  text: string
  content: string
  subject: string
  attachments: MailAttachment[]

  constructor(accountId: number, receiveEmail: string[], subject: string, content: string, sendType: string, emailId: number,
    attachments: MailAttachment[]) {
    this.accountId = accountId
    this.name = ''
    this.sendType = sendType
    this.emailId = emailId
    this.receiveEmail = receiveEmail
    this.text = content
    this.content = content
    this.subject = subject
    this.attachments = attachments
  }
}

export class MailService {
  static async loadInbox(): Promise<MailItem[]> {
    const response: ApiResponse = await EmailApi.list(MailService.getCurrentAccountId(), 0, 0, 0, 50, 0)
    return MailService.toItems(response)
  }

  static async loadSent(): Promise<MailItem[]> {
    const response: ApiResponse = await EmailApi.list(MailService.getCurrentAccountId(), 0, 0, 0, 50, 1)
    return MailService.toItems(response)
  }

  static async loadStarred(): Promise<MailItem[]> {
    const response: ApiResponse = await EmailApi.listStarred(0, 50)
    return MailService.toItems(response)
  }

  static async markRead(emailId: number): Promise<void> {
    await EmailApi.markRead([emailId])
  }

  static async setStar(emailId: number, starred: boolean): Promise<void> {
    if (starred) {
      await EmailApi.addStar(emailId)
    } else {
      await EmailApi.cancelStar(emailId)
    }
  }

  static async delete(emailId: number): Promise<void> {
    await EmailApi.delete(emailId.toString())
  }

  static async send(toEmail: string, ccEmail: string, bccEmail: string, subject: string, content: string,
    sendType: string, emailId: number, attachments: MailAttachment[]): Promise<void> {
    if (ccEmail.trim() !== '' || bccEmail.trim() !== '') {
      throw new ApiException(-1, '当前邮件服务暂不支持抄送和密送', false)
    }
    const recipients: string[] = MailService.splitRecipients(toEmail)
    if (recipients.length === 0) {
      throw new ApiException(-1, '请输入有效的收件人邮箱', false)
    }
    const request: SendMailRequest = new SendMailRequest(MailService.getCurrentAccountId(), recipients, subject, content,
      sendType, emailId, attachments)
    await EmailApi.send(JSON.stringify(request))
  }

  private static getCurrentAccountId(): number {
    const accountId: number | undefined = AppStorage.get('currentAccountId') as number | undefined
    return accountId === undefined ? 0 : accountId
  }

  private static toItems(response: ApiResponse): MailItem[] {
    if (response.data === null) {
      return []
    }
    const remoteData: RemoteMailList = response.data as RemoteMailList
    const result: MailItem[] = []
    for (let index = 0; index < remoteData.list.length; index++) {
      result.push(MailService.toItem(remoteData.list[index]))
    }
    return result
  }

  private static toItem(remote: RemoteEmail): MailItem {
    const item: MailItem = new MailItem()
    item.id = remote.emailId
    item.accountId = remote.accountId
    item.type = remote.type
    item.subject = remote.subject
    item.body = remote.text === '' ? remote.content : remote.text
    item.htmlContent = remote.content
    item.time = MailService.formatTime(remote.createTime)
    item.unread = remote.unread === 0
    item.starred = remote.isStar === 1
    item.cc = MailService.toAddressList(remote.cc)
    item.bcc = MailService.toAddressList(remote.bcc)
    item.toEmail = remote.toEmail
    if (remote.type === 1) {
      item.name = remote.toName === '' ? remote.toEmail : remote.toName
      item.email = remote.toEmail
    } else {
      item.name = remote.name === '' ? remote.sendEmail : remote.name
      item.email = remote.sendEmail
    }
    for (let index = 0; index < remote.attList.length; index++) {
      const filename: string = remote.attList[index].filename
      if (filename !== '') {
        item.attList.push(filename)
        item.attachmentKeys.push(remote.attList[index].key)
      }
    }
    return item
  }

  private static toAddressList(rawValue: string): string[] {
    if (rawValue === '') {
      return []
    }
    try {
      const values: string[] = JSON.parse(rawValue) as string[]
      const result: string[] = []
      for (let index = 0; index < values.length; index++) {
        if (values[index] !== '') {
          result.push(values[index])
        }
      }
      return result
    } catch (err) {
      return []
    }
  }

  private static splitRecipients(rawValue: string): string[] {
    const values: string[] = rawValue.replace('，', ',').replace(';', ',').split(',')
    const result: string[] = []
    for (let index = 0; index < values.length; index++) {
      const email: string = values[index].trim()
      if (email !== '' && email.indexOf('@') > 0 && email.indexOf('.') > 1) {
        result.push(email)
      }
    }
    return result
  }

  private static formatTime(value: string): string {
    if (value.length <= 16) {
      return value
    }
    return value.substring(0, 16).replace('T', ' ')
  }
}

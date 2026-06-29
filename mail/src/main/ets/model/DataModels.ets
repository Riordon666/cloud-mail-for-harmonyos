import { AppTheme } from './AppTheme'

/**
 * 邮件类型数据模型
 */
export class EmailItem {
  emailId: number = 0
  accountId: number = 0
  userId: number = 0
  sendEmail: string = ''
  name: string = ''
  toEmail: string = ''
  toName: string = ''
  subject: string = ''
  content: string = ''
  text: string = ''
  code: string = ''
  cc: string = '[]'
  bcc: string = '[]'
  recipient: string = ''
  type: number = 0
  status: number = 0
  unread: number = 0
  createTime: string = ''
  isDel: number = 0
  isStar: number = 0
  attList: AttachmentItem[] = []
}

export class AttachmentItem {
  attId: number = 0
  key: string = ''
  filename: string = ''
  mimeType: string = ''
  size: number = 0
  contentId: string = ''
}

export class AccountItem {
  accountId: number = 0
  email: string = ''
  name: string = ''
  userId: number = 0
  allReceive: number = 0
  latestEmailTime: string = ''
  sort: number = 0
}

export class UserInfo {
  userId: number = 0
  email: string = ''
  name: string = ''
  account: AccountItem | null = null
  role: RoleItem | null = null
  permKeys: string[] = []
  type: number = 0
  sendCount: number = 0
}

export class RoleItem {
  roleId: number = 0
  name: string = ''
  sendType: string = ''
  sendCount: number = 0
  banEmail: string = ''
  availDomain: string = ''
}

export class SettingItem {
  title: string = ''
  register: number = 0
  receive: number = 0
  send: number = 0
  background: string = ''
  backgroundOpacity: number = 1
  forwardStatus: number = 0
  forwardEmail: string = ''
  tgBotStatus: number = 0
  tgChatId: string = ''
  ruleType: number = 0
  ruleEmail: string = ''
  customDomain: string = ''
}

export class UserListItem {
  userId: number = 0
  email: string = ''
  type: number = 0
  status: number = 0
  createTime: string = ''
  username: string = ''
  avatar: string = ''
  sendCount: number = 0
}

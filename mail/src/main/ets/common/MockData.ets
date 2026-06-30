export interface EmailMock {
  id: number
  name: string
  subject: string
  time: string
  unread: boolean
}

export interface AccountMock {
  email: string
  unread: number
  total: number
  isPrimary: boolean
}

export const MOCK_EMAILS: EmailMock[] = [
  { id: 1, name: 'GitHub', subject: '[Action] Build failed on main', time: '10:32', unread: true },
  { id: 2, name: 'Alice Zhang', subject: 'Q4 设计稿评审通知', time: '09:15', unread: true },
  { id: 3, name: 'Apple', subject: 'Your receipt from Apple', time: '昨天', unread: false },
  { id: 4, name: 'Cloudflare', subject: 'Weekly Analytics Report', time: '昨天', unread: false },
  { id: 5, name: 'Bob Smith', subject: 'Re: 项目进展', time: '周一', unread: false },
  { id: 6, name: 'Notion', subject: '文档有更新', time: '周日', unread: false }
]

export const MOCK_ACCOUNTS: AccountMock[] = [
  { email: 'admin@riordon.xyz', unread: 3, total: 128, isPrimary: true },
  { email: 'work@riordon.xyz', unread: 0, total: 45, isPrimary: false },
  { email: 'hello@riordon.xyz', unread: 12, total: 67, isPrimary: false }
]

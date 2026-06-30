// ===== 邮箱 =====
export interface EmailMock {
  id: number
  name: string
  email: string
  subject: string
  body: string
  time: string
  unread: boolean
  cc: string[]
  bcc: string[]
  attList: string[]
  htmlContent: string
}

// ===== 账户 =====
export interface AccountMock {
  email: string
  unread: number
  total: number
  isPrimary: boolean
}

// ===== 用户 =====
export interface UserMock {
  id: string
  name: string
  email: string
  role: 'admin' | 'user'
  avatar: string
}

// ===== 设置 =====
export interface SettingsMock {
  siteTitle: string
  allowRegister: boolean
  defaultQuota: number
  maxAlias: number
}

// ===== 管理员角色 =====
export interface RoleMock {
  id: string
  name: string
  permissions: string[]
}

// ===== 注册码 =====
export interface InviteCodeMock {
  code: string
  used: boolean
  usedBy: string
  createdAt: string
}

// ===== 邮件 Mock 数据 =====
export const MOCK_EMAILS: EmailMock[] = [
  {
    id: 1, name: 'GitHub', email: 'noreply@github.com',
    subject: '[Action] Build failed on main',
    body: 'The workflow "CI" failed on branch main. Please check the logs for details.',
    time: '10:32', unread: true, cc: [], bcc: [], attList: [],
    htmlContent: '<p>The workflow <b>CI</b> failed on branch main.</p>'
  },
  {
    id: 2, name: 'Alice Zhang', email: 'alice@example.com',
    subject: 'Q4 设计稿评审通知',
    body: '各位好，Q4 设计稿评审定于本周五下午 3 点，请在会议前查看附件中的设计稿。',
    time: '09:15', unread: true, cc: ['bob@example.com'], bcc: [], attList: ['design_v3.fig'],
    htmlContent: '<p>各位好，Q4 设计稿评审定于本周五下午 3 点。</p>'
  },
  {
    id: 3, name: 'Apple', email: 'no_reply@email.apple.com',
    subject: 'Your receipt from Apple',
    body: 'Thank you for your purchase. Here is your receipt.',
    time: '昨天', unread: false, cc: [], bcc: [], attList: ['receipt.pdf'],
    htmlContent: '<p>Thank you for your purchase.</p>'
  },
  {
    id: 4, name: 'Cloudflare', email: 'noreply@cloudflare.com',
    subject: 'Weekly Analytics Report',
    body: 'Your weekly analytics report is now available.',
    time: '昨天', unread: false, cc: [], bcc: [], attList: [],
    htmlContent: '<p>Your weekly analytics report is now available.</p>'
  },
  {
    id: 5, name: 'Bob Smith', email: 'bob@example.com',
    subject: 'Re: 项目进展',
    body: '进展顺利，第一阶段预计下周可以交付。第二阶段需要额外资源。',
    time: '周一', unread: false, cc: ['alice@example.com'], bcc: [], attList: [],
    htmlContent: '<p>进展顺利，第一阶段预计下周可以交付。</p>'
  },
  {
    id: 6, name: 'Notion', email: 'notifications@notion.so',
    subject: '文档有更新',
    body: '有人在 "产品需求" 文档中 @了你，请查看最新评论。',
    time: '周日', unread: false, cc: [], bcc: [], attList: [],
    htmlContent: '<p>有人在 "产品需求" 文档中 @了你。</p>'
  }
]

// ===== 账户 Mock 数据 =====
export const MOCK_ACCOUNTS: AccountMock[] = [
  { email: 'admin@riordon.xyz', unread: 3, total: 128, isPrimary: true },
  { email: 'work@riordon.xyz', unread: 0, total: 45, isPrimary: false },
  { email: 'hello@riordon.xyz', unread: 12, total: 67, isPrimary: false }
]

// ===== 用户 Mock 数据 =====
export const MOCK_USER: UserMock = {
  id: '1',
  name: 'Admin',
  email: 'admin@riordon.xyz',
  role: 'admin',
  avatar: ''
}

export const MOCK_USERS: UserMock[] = [
  MOCK_USER,
  { id: '2', name: '张三', email: 'zhangsan@riordon.xyz', role: 'user', avatar: '' },
  { id: '3', name: '李四', email: 'lisi@riordon.xyz', role: 'user', avatar: '' }
]

// ===== 设置 Mock 数据 =====
export const MOCK_SETTINGS: SettingsMock = {
  siteTitle: 'Cloud Mail',
  allowRegister: true,
  defaultQuota: 500,
  maxAlias: 5
}

// ===== 管理员 Mock 数据 =====
export const MOCK_ROLES: RoleMock[] = [
  { id: '1', name: '超级管理员', permissions: ['all'] },
  { id: '2', name: '邮件管理员', permissions: ['mail:read', 'mail:delete'] },
  { id: '3', name: '只读用户', permissions: ['mail:read'] }
]

export interface StatsMock {
  totalUsers: number
  totalEmails: number
  totalStorage: string
  activeToday: number
}

export const MOCK_STATS: StatsMock = {
  totalUsers: 128,
  totalEmails: 4567,
  totalStorage: '2.3 GB',
  activeToday: 34
}

// ===== 注册码 Mock 数据 =====
export const MOCK_INVITE_CODES: InviteCodeMock[] = [
  { code: 'CLOUD-2024-001', used: true, usedBy: 'zhangsan@riordon.xyz', createdAt: '2024-01-15' },
  { code: 'CLOUD-2024-002', used: false, usedBy: '', createdAt: '2024-06-01' },
  { code: 'CLOUD-2024-003', used: false, usedBy: '', createdAt: '2024-06-01' }
]
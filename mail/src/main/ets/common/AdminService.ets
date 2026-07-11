import { ApiException, ApiResponse } from './HttpClient'
import { AdminApi } from '../api/AdminApi'

export class AdminUser {
  id: number
  email: string
  roleId: string
  status: string
  deleted: boolean
  sendCount: number

  constructor(id: number, email: string, roleId: string, status: string, deleted: boolean, sendCount: number) {
    this.id = id
    this.email = email
    this.roleId = roleId
    this.status = status
    this.deleted = deleted
    this.sendCount = sendCount
  }
}

export class AdminRole {
  id: string
  name: string
  permissions: string[]
  isDefault: boolean

  constructor(id: string, name: string, permissions: string[], isDefault: boolean) {
    this.id = id
    this.name = name
    this.permissions = permissions
    this.isDefault = isDefault
  }
}

export class AdminPermission {
  id: string
  name: string

  constructor(id: string, name: string) {
    this.id = id
    this.name = name
  }
}

export class GlobalMail {
  id: number
  sender: string
  recipient: string
  subject: string
  time: string
  deleted: boolean

  constructor(id: number, sender: string, recipient: string, subject: string, time: string, deleted: boolean) {
    this.id = id
    this.sender = sender
    this.recipient = recipient
    this.subject = subject
    this.time = time
    this.deleted = deleted
  }
}

export class RegistrationCode {
  id: number
  code: string
  roleId: string
  used: boolean
  usedBy: string
  createdAt: string

  constructor(id: number, code: string, roleId: string, used: boolean, usedBy: string, createdAt: string) {
    this.id = id
    this.code = code
    this.roleId = roleId
    this.used = used
    this.usedBy = usedBy
    this.createdAt = createdAt
  }
}

export class TrendItem {
  date: string
  users: number
  emails: number

  constructor(date: string, users: number, emails: number) {
    this.date = date
    this.users = users
    this.emails = emails
  }
}

export class AdminStats {
  totalUsers: number
  totalEmails: number
  activeToday: number
  storageUsed: string

  constructor(totalUsers: number, totalEmails: number, activeToday: number, storageUsed: string) {
    this.totalUsers = totalUsers
    this.totalEmails = totalEmails
    this.activeToday = activeToday
    this.storageUsed = storageUsed
  }
}

export class AdminAnalytics {
  stats: AdminStats
  trend: TrendItem[]

  constructor(stats: AdminStats, trend: TrendItem[]) {
    this.stats = stats
    this.trend = trend
  }
}

export class AdminResult {
  success: boolean
  message: string

  constructor(success: boolean, message: string) {
    this.success = success
    this.message = message
  }
}

class RemoteUser {
  userId: number = 0
  email: string = ''
  type: number = 0
  status: number = 0
  isDel: number = 0
  sendCount: number = 0
}

class RemoteUserList {
  list: RemoteUser[] = []
}

class RemoteRole {
  roleId: number = 0
  name: string = ''
  permIds: number[] = []
  isDefault: number = 0
}

class RemoteMail {
  emailId: number = 0
  sendEmail: string = ''
  toEmail: string = ''
  subject: string = ''
  createTime: string = ''
  isDel: number = 0
}

class RemoteMailList {
  list: RemoteMail[] = []
}

class RemoteRegistrationCode {
  regKeyId: number = 0
  code: string = ''
  roleId: number = 0
  count: number = 0
  createTime: string = ''
}

class RemotePermission {
  permId: number = 0
  name: string = ''
  type: number = 0
  children: RemotePermission[] = []
}

class RemoteCount {
  date: string = ''
  total: number = 0
}

class RemoteNumberCount {
  normalUserTotal: number = 0
  normalReceiveTotal: number = 0
  normalSendTotal: number = 0
}

class RemoteEmailDayCount {
  receiveDayCount: RemoteCount[] = []
  sendDayCount: RemoteCount[] = []
}

class RemoteAnalyticsPayload {
  numberCount: RemoteNumberCount = new RemoteNumberCount()
  userDayCount: RemoteCount[] = []
  emailDayCount: RemoteEmailDayCount = new RemoteEmailDayCount()
  daySendTotal: number = 0
}

export class AdminService {
  static initialize(): void {
    AppStorage.setOrCreate('adminUserRevision', 0)
    AppStorage.setOrCreate('adminRoleRevision', 0)
    AppStorage.setOrCreate('adminMailRevision', 0)
    AppStorage.setOrCreate('registrationCodeRevision', 0)
  }

  static async getUsers(): Promise<AdminUser[]> {
    const response: ApiResponse = await AdminApi.users('', -1, 0, 1, 50)
    if (response.data === null) {
      return []
    }
    const payload: RemoteUserList = response.data as RemoteUserList
    const result: AdminUser[] = []
    for (let index = 0; index < payload.list.length; index++) {
      const user: RemoteUser = payload.list[index]
      result.push(new AdminUser(user.userId, user.email, user.type.toString(), user.status === 0 ? '正常' : '禁用',
        user.isDel === 1, user.sendCount))
    }
    return result
  }

  static async getRoles(): Promise<AdminRole[]> {
    const response: ApiResponse = await AdminApi.roles()
    if (response.data === null) {
      return []
    }
    const source: RemoteRole[] = response.data as RemoteRole[]
    const result: AdminRole[] = []
    for (let index = 0; index < source.length; index++) {
      const role: RemoteRole = source[index]
      const permissions: string[] = []
      for (let permissionIndex = 0; permissionIndex < role.permIds.length; permissionIndex++) {
        permissions.push(role.permIds[permissionIndex].toString())
      }
      result.push(new AdminRole(role.roleId.toString(), role.name, permissions, role.isDefault === 1))
    }
    return result
  }

  static async getPermissions(): Promise<AdminPermission[]> {
    const response: ApiResponse = await AdminApi.roleTree()
    if (response.data === null) {
      return []
    }
    const source: RemotePermission[] = response.data as RemotePermission[]
    const result: AdminPermission[] = []
    for (let index = 0; index < source.length; index++) {
      AdminService.collectPermissions(source[index], result)
    }
    return result
  }

  static async getMails(): Promise<GlobalMail[]> {
    const response: ApiResponse = await AdminApi.allEmails('', '', '', 0, 50)
    if (response.data === null) {
      return []
    }
    const payload: RemoteMailList = response.data as RemoteMailList
    const result: GlobalMail[] = []
    for (let index = 0; index < payload.list.length; index++) {
      const email: RemoteMail = payload.list[index]
      result.push(new GlobalMail(email.emailId, email.sendEmail, email.toEmail, email.subject, email.createTime, email.isDel === 1))
    }
    return result
  }

  static async getRegistrationCodes(): Promise<RegistrationCode[]> {
    const response: ApiResponse = await AdminApi.registrationCodes(1, 50)
    if (response.data === null) {
      return []
    }
    const source: RemoteRegistrationCode[] = response.data as RemoteRegistrationCode[]
    const result: RegistrationCode[] = []
    for (let index = 0; index < source.length; index++) {
      const code: RemoteRegistrationCode = source[index]
      result.push(new RegistrationCode(code.regKeyId, code.code, code.roleId.toString(), code.count === 0, '', code.createTime))
    }
    return result
  }

  static async getAnalytics(): Promise<AdminAnalytics> {
    const response: ApiResponse = await AdminApi.analytics('Asia/Shanghai')
    if (response.data === null) {
      return new AdminAnalytics(new AdminStats(0, 0, 0, '服务端未提供'), [])
    }
    const payload: RemoteAnalyticsPayload = response.data as RemoteAnalyticsPayload
    const totalEmails: number = payload.numberCount.normalReceiveTotal + payload.numberCount.normalSendTotal
    const stats: AdminStats = new AdminStats(payload.numberCount.normalUserTotal, totalEmails, payload.daySendTotal, '服务端未提供')
    const trend: TrendItem[] = []
    for (let index = 0; index < payload.userDayCount.length; index++) {
      const users: RemoteCount = payload.userDayCount[index]
      let emails: number = 0
      for (let receiveIndex = 0; receiveIndex < payload.emailDayCount.receiveDayCount.length; receiveIndex++) {
        const receive: RemoteCount = payload.emailDayCount.receiveDayCount[receiveIndex]
        if (receive.date === users.date) {
          emails += receive.total
        }
      }
      for (let sendIndex = 0; sendIndex < payload.emailDayCount.sendDayCount.length; sendIndex++) {
        const send: RemoteCount = payload.emailDayCount.sendDayCount[sendIndex]
        if (send.date === users.date) {
          emails += send.total
        }
      }
      trend.push(new TrendItem(users.date, users.total, emails))
    }
    return new AdminAnalytics(stats, trend)
  }

  static async createUser(email: string, password: string, roleId: string): Promise<AdminResult> {
    try {
      await AdminApi.createUser(email, password, Number(roleId))
      AdminService.notify('adminUserRevision')
      return new AdminResult(true, '')
    } catch (err) {
      return new AdminResult(false, AdminService.toErrorMessage(err))
    }
  }

  static async updateUser(id: number, password: string, roleId: string, status: string): Promise<AdminResult> {
    try {
      if (password !== '') {
        await AdminApi.setUserPassword(id, password)
      }
      await AdminApi.setUserRole(id, Number(roleId))
      await AdminApi.setUserStatus(id, status === '正常' ? 0 : 1)
      AdminService.notify('adminUserRevision')
      return new AdminResult(true, '')
    } catch (err) {
      return new AdminResult(false, AdminService.toErrorMessage(err))
    }
  }

  static async deleteUser(id: number): Promise<AdminResult> {
    try {
      await AdminApi.deleteUsers(id.toString())
      AdminService.notify('adminUserRevision')
      return new AdminResult(true, '')
    } catch (err) {
      return new AdminResult(false, AdminService.toErrorMessage(err))
    }
  }

  static async restoreUser(id: number): Promise<AdminResult> {
    try {
      await AdminApi.restoreUser(id, 1)
      AdminService.notify('adminUserRevision')
      return new AdminResult(true, '')
    } catch (err) {
      return new AdminResult(false, AdminService.toErrorMessage(err))
    }
  }

  static async resetSendCount(id: number): Promise<AdminResult> {
    try {
      await AdminApi.resetUserSendCount(id)
      AdminService.notify('adminUserRevision')
      return new AdminResult(true, '')
    } catch (err) {
      return new AdminResult(false, AdminService.toErrorMessage(err))
    }
  }

  static async createRole(name: string, permissions: string[]): Promise<AdminResult> {
    try {
      await AdminApi.createRole(name, AdminService.toNumbers(permissions))
      AdminService.notify('adminRoleRevision')
      return new AdminResult(true, '')
    } catch (err) {
      return new AdminResult(false, AdminService.toErrorMessage(err))
    }
  }

  static async updateRole(id: string, name: string, permissions: string[]): Promise<AdminResult> {
    try {
      await AdminApi.updateRole(Number(id), name, AdminService.toNumbers(permissions))
      AdminService.notify('adminRoleRevision')
      return new AdminResult(true, '')
    } catch (err) {
      return new AdminResult(false, AdminService.toErrorMessage(err))
    }
  }

  static async setDefaultRole(id: string): Promise<AdminResult> {
    try {
      await AdminApi.setDefaultRole(Number(id))
      AdminService.notify('adminRoleRevision')
      return new AdminResult(true, '')
    } catch (err) {
      return new AdminResult(false, AdminService.toErrorMessage(err))
    }
  }

  static async deleteRole(id: string): Promise<AdminResult> {
    try {
      await AdminApi.deleteRole(Number(id))
      AdminService.notify('adminRoleRevision')
      return new AdminResult(true, '')
    } catch (err) {
      return new AdminResult(false, AdminService.toErrorMessage(err))
    }
  }

  static async deleteMails(ids: number[]): Promise<AdminResult> {
    if (ids.length === 0) {
      return new AdminResult(false, '请先选择邮件')
    }
    try {
      const values: string[] = []
      for (let index = 0; index < ids.length; index++) {
        values.push(ids[index].toString())
      }
      await AdminApi.deleteAllEmails(values.join(','))
      AdminService.notify('adminMailRevision')
      return new AdminResult(true, '')
    } catch (err) {
      return new AdminResult(false, AdminService.toErrorMessage(err))
    }
  }

  static async generateRegistrationCodes(count: number, roleId: string): Promise<AdminResult> {
    if (count <= 0) {
      return new AdminResult(false, '请输入正确的生成数量')
    }
    const code: string = 'HM-' + new Date().getTime().toString()
    try {
      await AdminApi.createRegistrationCode(code, Number(roleId), count, '2099-12-31 23:59:59')
      AdminService.notify('registrationCodeRevision')
      return new AdminResult(true, '')
    } catch (err) {
      return new AdminResult(false, AdminService.toErrorMessage(err))
    }
  }

  static async deleteRegistrationCode(id: number): Promise<AdminResult> {
    try {
      await AdminApi.deleteRegistrationCode(id)
      AdminService.notify('registrationCodeRevision')
      return new AdminResult(true, '')
    } catch (err) {
      return new AdminResult(false, AdminService.toErrorMessage(err))
    }
  }

  private static collectPermissions(source: RemotePermission, result: AdminPermission[]): void {
    if (source.type === 2) {
      result.push(new AdminPermission(source.permId.toString(), source.name))
    }
    for (let index = 0; index < source.children.length; index++) {
      AdminService.collectPermissions(source.children[index], result)
    }
  }

  private static toNumbers(values: string[]): number[] {
    const result: number[] = []
    for (let index = 0; index < values.length; index++) {
      result.push(Number(values[index]))
    }
    return result
  }

  private static notify(key: string): void {
    const revision: number | undefined = AppStorage.get(key) as number | undefined
    AppStorage.set(key, revision === undefined ? 1 : revision + 1)
  }

  private static toErrorMessage(err: Error): string {
    if (err instanceof ApiException) {
      return err.message
    }
    return '请求失败，请稍后重试'
  }
}

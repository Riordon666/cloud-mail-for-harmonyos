import { ApiResponse, HttpClient, QueryParameter } from '../common/HttpClient'

class UserPasswordRequest {
  userId: number
  password: string

  constructor(userId: number, password: string) {
    this.userId = userId
    this.password = password
  }
}

class UserStatusRequest {
  userId: number
  status: number

  constructor(userId: number, status: number) {
    this.userId = userId
    this.status = status
  }
}

class UserRoleRequest {
  userId: number
  type: number

  constructor(userId: number, type: number) {
    this.userId = userId
    this.type = type
  }
}

class RoleIdRequest {
  roleId: number

  constructor(roleId: number) {
    this.roleId = roleId
  }
}

class UserCreateRequest {
  email: string
  password: string
  type: number

  constructor(email: string, password: string, type: number) {
    this.email = email
    this.password = password
    this.type = type
  }
}

class RoleRequest {
  roleId: number = 0
  name: string
  permIds: number[]
  banEmail: string[]
  availDomain: string[]
  description: string
  sendType: string
  sendCount: number
  accountCount: number
  sort: number

  constructor(name: string, permIds: number[]) {
    this.name = name
    this.permIds = permIds
    this.banEmail = []
    this.availDomain = []
    this.description = ''
    this.sendType = 'count'
    this.sendCount = 0
    this.accountCount = 0
    this.sort = 0
  }
}

class RegistrationCodeRequest {
  code: string
  roleId: number
  count: number
  expireTime: string

  constructor(code: string, roleId: number, count: number, expireTime: string) {
    this.code = code
    this.roleId = roleId
    this.count = count
    this.expireTime = expireTime
  }
}

export class AdminApi {
  static async users(email: string, status: number, isDeleted: number, page: number, size: number): Promise<ApiResponse> {
    const path: string = HttpClient.appendQuery('/user/list', [
      new QueryParameter('email', email),
      new QueryParameter('status', status.toString()),
      new QueryParameter('isDel', isDeleted.toString()),
      new QueryParameter('num', page.toString()),
      new QueryParameter('size', size.toString())
    ])
    return HttpClient.get(path)
  }

  static async allEmails(recipient: string, sender: string, subject: string, emailId: number, size: number): Promise<ApiResponse> {
    const path: string = HttpClient.appendQuery('/allEmail/list', [
      new QueryParameter('toEmail', recipient),
      new QueryParameter('sendEmail', sender),
      new QueryParameter('subject', subject),
      new QueryParameter('emailId', emailId.toString()),
      new QueryParameter('timeSort', '0'),
      new QueryParameter('type', ''),
      new QueryParameter('size', size.toString())
    ])
    return HttpClient.get(path)
  }

  static async roles(): Promise<ApiResponse> {
    return HttpClient.get('/role/list')
  }

  static async roleTree(): Promise<ApiResponse> {
    return HttpClient.get('/role/tree')
  }

  static async registrationCodes(page: number, size: number): Promise<ApiResponse> {
    const path: string = HttpClient.appendQuery('/regKey/list', [
      new QueryParameter('num', page.toString()),
      new QueryParameter('size', size.toString())
    ])
    return HttpClient.get(path)
  }

  static async analytics(timeZone: string): Promise<ApiResponse> {
    const path: string = HttpClient.appendQuery('/analysis/echarts', [new QueryParameter('timeZone', timeZone)])
    return HttpClient.get(path)
  }

  static async createUser(email: string, password: string, type: number): Promise<ApiResponse> {
    return HttpClient.post('/user/add', JSON.stringify(new UserCreateRequest(email, password, type)))
  }

  static async setUserPassword(userId: number, password: string): Promise<ApiResponse> {
    return HttpClient.put('/user/setPwd', JSON.stringify(new UserPasswordRequest(userId, password)))
  }

  static async setUserStatus(userId: number, status: number): Promise<ApiResponse> {
    return HttpClient.put('/user/setStatus', JSON.stringify(new UserStatusRequest(userId, status)))
  }

  static async setUserRole(userId: number, type: number): Promise<ApiResponse> {
    return HttpClient.put('/user/setType', JSON.stringify(new UserRoleRequest(userId, type)))
  }

  static async deleteUsers(userIds: string): Promise<ApiResponse> {
    const path: string = HttpClient.appendQuery('/user/delete', [new QueryParameter('userIds', userIds)])
    return HttpClient.delete(path)
  }

  static async restoreUser(userId: number, type: number): Promise<ApiResponse> {
    return HttpClient.put('/user/restore', JSON.stringify(new UserRoleRequest(userId, type)))
  }

  static async resetUserSendCount(userId: number): Promise<ApiResponse> {
    return HttpClient.put('/user/resetSendCount', JSON.stringify(new UserStatusRequest(userId, 0)))
  }

  static async deleteAllEmails(emailIds: string): Promise<ApiResponse> {
    const path: string = HttpClient.appendQuery('/allEmail/delete', [new QueryParameter('emailIds', emailIds)])
    return HttpClient.delete(path)
  }

  static async createRole(name: string, permIds: number[]): Promise<ApiResponse> {
    return HttpClient.post('/role/add', JSON.stringify(new RoleRequest(name, permIds)))
  }

  static async updateRole(roleId: number, name: string, permIds: number[]): Promise<ApiResponse> {
    const request: RoleRequest = new RoleRequest(name, permIds)
    request.roleId = roleId
    return HttpClient.put('/role/set', JSON.stringify(request))
  }

  static async setDefaultRole(roleId: number): Promise<ApiResponse> {
    const path: string = HttpClient.appendQuery('/role/setDefault', [new QueryParameter('roleId', roleId.toString())])
    return HttpClient.put(path, JSON.stringify(new RoleIdRequest(roleId)))
  }

  static async deleteRole(roleId: number): Promise<ApiResponse> {
    const path: string = HttpClient.appendQuery('/role/delete', [new QueryParameter('roleId', roleId.toString())])
    return HttpClient.delete(path)
  }

  static async createRegistrationCode(code: string, roleId: number, count: number, expireTime: string): Promise<ApiResponse> {
    return HttpClient.post('/regKey/add', JSON.stringify(new RegistrationCodeRequest(code, roleId, count, expireTime)))
  }

  static async deleteRegistrationCode(registrationCodeId: number): Promise<ApiResponse> {
    const path: string = HttpClient.appendQuery('/regKey/delete', [new QueryParameter('regKeyIds', registrationCodeId.toString())])
    return HttpClient.delete(path)
  }
}

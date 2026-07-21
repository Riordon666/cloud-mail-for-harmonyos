import { ApiException, ApiResponse, HttpClient } from '../common/HttpClient'

class LoginRequest {
  email: string
  password: string

  constructor(email: string, password: string) {
    this.email = email
    this.password = password
  }
}

class RegisterRequest {
  email: string
  password: string
  token: string
  code: string

  constructor(email: string, password: string, token: string, code: string) {
    this.email = email
    this.password = password
    this.token = token
    this.code = code
  }
}

class LoginPayload {
  token: string = ''
}

class RemoteAccountPayload {
  accountId: number = 0
}

class RemoteRolePayload {
  name: string = ''
}

class RemoteUserPayload {
  email: string = ''
  account: RemoteAccountPayload = new RemoteAccountPayload()
  role: RemoteRolePayload = new RemoteRolePayload()
  permKeys: string[] = []
}

export class AuthUserInfo {
  email: string
  role: string
  roleName: string
  accountId: number

  constructor(email: string, role: string, roleName: string, accountId: number) {
    this.email = email
    this.role = role
    this.roleName = roleName
    this.accountId = accountId
  }
}

export class AuthApi {
  static async login(email: string, password: string): Promise<string> {
    const request: LoginRequest = new LoginRequest(email, password)
    const response: ApiResponse = await HttpClient.post('/login', JSON.stringify(request), false)
    if (response.data === null) {
      throw new ApiException(-1, '服务器未返回登录令牌', false)
    }
    const payload: LoginPayload = response.data as LoginPayload
    if (payload.token === '') {
      throw new ApiException(-1, '服务器未返回登录令牌', false)
    }
    return payload.token
  }

  static async register(email: string, password: string, registerCode: string): Promise<void> {
    const request: RegisterRequest = new RegisterRequest(email, password, '', registerCode)
    await HttpClient.post('/register', JSON.stringify(request), false)
  }

  static async getCurrentUser(): Promise<AuthUserInfo> {
    const response: ApiResponse = await HttpClient.get('/my/loginUserInfo')
    if (response.data === null) {
      throw new ApiException(-1, '服务器未返回用户信息', false)
    }
    const payload: RemoteUserPayload = response.data as RemoteUserPayload
    const role: string = AuthApi.isAdministrator(payload) ? 'admin' : 'user'
    const roleName: string = payload.role.name === '' ? '普通用户' : payload.role.name
    return new AuthUserInfo(payload.email, role, roleName, payload.account.accountId)
  }

  static async logout(token: string): Promise<void> {
    await HttpClient.delete('/logout', true, token)
  }

  private static isAdministrator(payload: RemoteUserPayload): boolean {
    if (payload.role.name === 'admin') {
      return true
    }
    for (let i = 0; i < payload.permKeys.length; i++) {
      if (payload.permKeys[i] === '*') {
        return true
      }
    }
    return false
  }
}

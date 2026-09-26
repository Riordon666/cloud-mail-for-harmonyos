import { ApiException, ApiResponse, HttpClient } from '../common/HttpClient'

import { ExternalHttpClient } from '../common/ExternalHttpClient'

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

class HuaweiLoginRequest {
  authorizationCode: string

  constructor(authorizationCode: string) {
    this.authorizationCode = authorizationCode
  }
}

class HuaweiBindRequest {
  bindToken: string
  email: string
  password: string

  constructor(bindToken: string, email: string, password: string) {
    this.bindToken = bindToken
    this.email = email
    this.password = password
  }
}

class HuaweiRegisterRequest {
  bindToken: string
  email: string
  code: string

  constructor(bindToken: string, email: string, code: string) {
    this.bindToken = bindToken
    this.email = email
    this.code = code
  }
}

class HuaweiLoginPayload {
  status: string = ''
  token: string = ''
  bindToken: string = ''
  email: string = ''
}

class HuaweiSessionPayload {
  token: string = ''
  email: string = ''
}

export class HuaweiLoginResult {
  bound: boolean
  token: string
  bindToken: string
  email: string

  constructor(bound: boolean, token: string, bindToken: string, email: string) {
    this.bound = bound
    this.token = token
    this.bindToken = bindToken
    this.email = email
  }
}

export class HuaweiSessionResult {
  token: string
  email: string

  constructor(token: string, email: string) {
    this.token = token
    this.email = email
  }
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
  static async loginWithHuawei(authorizationCode: string): Promise<HuaweiLoginResult> {
    const request: HuaweiLoginRequest = new HuaweiLoginRequest(authorizationCode)
    const response: ApiResponse = await HttpClient.post('/oauth/huawei/login', JSON.stringify(request), false)
    if (response.data === null) {
      throw new ApiException(-1, '服务器未返回华为账号登录结果', false)
    }
    const payload: HuaweiLoginPayload = response.data as HuaweiLoginPayload
    if (payload.status === 'BOUND' && payload.token !== '') {
      return new HuaweiLoginResult(true, payload.token, '', payload.email)
    }
    if (payload.status === 'UNBOUND' && payload.bindToken !== '') {
      return new HuaweiLoginResult(false, '', payload.bindToken, '')
    }
    throw new ApiException(-1, '华为账号登录结果无效', false)
  }

  static async bindHuaweiAccount(bindToken: string, email: string, password: string): Promise<HuaweiSessionResult> {
    const request: HuaweiBindRequest = new HuaweiBindRequest(bindToken, email, password)
    const response: ApiResponse =
      await HttpClient.post('/oauth/huawei/bind-existing', JSON.stringify(request), false)
    return AuthApi.parseHuaweiSession(response)
  }

  static async registerWithHuawei(bindToken: string, email: string, registerCode: string):
    Promise<HuaweiSessionResult> {
    const request: HuaweiRegisterRequest = new HuaweiRegisterRequest(bindToken, email, registerCode)
    const response: ApiResponse = await HttpClient.post('/oauth/huawei/register', JSON.stringify(request), false)
    return AuthApi.parseHuaweiSession(response)
  }

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

  static async logout(apiBaseUrl: string, token: string): Promise<void> {
    // Both values belong to the session captured before local sign-out.
    await ExternalHttpClient.delete(apiBaseUrl, '/logout', token)
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

  private static parseHuaweiSession(response: ApiResponse): HuaweiSessionResult {
    if (response.data === null) {
      throw new ApiException(-1, '服务器未返回登录令牌', false)
    }
    const payload: HuaweiSessionPayload = response.data as HuaweiSessionPayload
    if (payload.token === '' || payload.email === '') {
      throw new ApiException(-1, '服务器返回的登录信息无效', false)
    }
    return new HuaweiSessionResult(payload.token, payload.email)
  }
}

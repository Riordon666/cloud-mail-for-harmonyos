import { http } from '@kit.NetworkKit'
import Constants from './Constants'
import { SessionService } from './SessionService'

export class ApiResponse {
  code: number = -1
  message: string = ''
  data: Object | null = null
}

export class ApiException extends Error {
  code: number
  message: string
  retryable: boolean

  constructor(code: number, message: string, retryable: boolean) {
    super(message)
    this.code = code
    this.message = message
    this.retryable = retryable
  }
}

export class QueryParameter {
  key: string
  value: string

  constructor(key: string, value: string) {
    this.key = key
    this.value = value
  }
}

export class HttpClient {
  static async get(path: string, requiresAuthorization: boolean = true): Promise<ApiResponse> {
    return HttpClient.request(path, http.RequestMethod.GET, '', requiresAuthorization, '')
  }

  static async post(path: string, body: string, requiresAuthorization: boolean = true): Promise<ApiResponse> {
    return HttpClient.request(path, http.RequestMethod.POST, body, requiresAuthorization, '')
  }

  static async put(path: string, body: string, requiresAuthorization: boolean = true): Promise<ApiResponse> {
    return HttpClient.request(path, http.RequestMethod.PUT, body, requiresAuthorization, '')
  }

  static async delete(path: string, requiresAuthorization: boolean = true, tokenOverride: string = ''): Promise<ApiResponse> {
    return HttpClient.request(path, http.RequestMethod.DELETE, '', requiresAuthorization, tokenOverride)
  }

  static appendQuery(path: string, parameters: QueryParameter[]): string {
    if (parameters.length === 0) {
      return path
    }
    let result: string = path + '?'
    for (let i = 0; i < parameters.length; i++) {
      if (i > 0) {
        result += '&'
      }
      result += encodeURIComponent(parameters[i].key) + '=' + encodeURIComponent(parameters[i].value)
    }
    return result
  }

  private static async request(path: string, method: http.RequestMethod, body: string, requiresAuthorization: boolean,
    tokenOverride: string): Promise<ApiResponse> {
    let lastError: ApiException = new ApiException(-1, '网络连接失败，请检查网络后重试', true)
    const retryTimes: number = method === http.RequestMethod.GET ? 2 : 1
    for (let attempt = 0; attempt < retryTimes; attempt++) {
      try {
        return await HttpClient.requestOnce(path, method, body, requiresAuthorization, tokenOverride)
      } catch (err) {
        if (err instanceof ApiException) {
          lastError = err
          if (!err.retryable) {
            throw err
          }
        } else {
          lastError = new ApiException(-1, '网络连接失败，请检查网络后重试', true)
        }
      }
    }
    throw lastError
  }

  private static async requestOnce(path: string, method: http.RequestMethod, body: string, requiresAuthorization: boolean,
    tokenOverride: string): Promise<ApiResponse> {
    const request: http.HttpRequest = http.createHttp()
    const token: string = tokenOverride === '' ? SessionService.getToken() : tokenOverride
    const url: string = HttpClient.createUrl(path)
    try {
      let response: http.HttpResponse
      if (requiresAuthorization && token !== '') {
        response = await request.request(url, {
          method: method,
          extraData: body,
          expectDataType: http.HttpDataType.STRING,
          usingCache: false,
          connectTimeout: 10000,
          readTimeout: 20000,
          header: { 'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': token }
        })
      } else {
        response = await request.request(url, {
          method: method,
          extraData: body,
          expectDataType: http.HttpDataType.STRING,
          usingCache: false,
          connectTimeout: 10000,
          readTimeout: 20000,
          header: { 'Accept': 'application/json', 'Content-Type': 'application/json' }
        })
      }
      if (response.responseCode < 200 || response.responseCode >= 300) {
        if (response.responseCode === 401) {
          SessionService.clearSession()
        }
        throw new ApiException(response.responseCode, '服务器请求失败，请稍后重试', response.responseCode >= 500)
      }
      const content: string = response.result as string
      const apiResponse: ApiResponse = JSON.parse(content) as ApiResponse
      if (apiResponse.code === 401) {
        SessionService.clearSession()
        throw new ApiException(401, apiResponse.message === '' ? '登录已过期，请重新登录' : apiResponse.message, false)
      }
      if (apiResponse.code !== 200) {
        throw new ApiException(apiResponse.code, apiResponse.message === '' ? '请求失败，请稍后重试' : apiResponse.message,
          apiResponse.code >= 500)
      }
      return apiResponse
    } catch (err) {
      if (err instanceof ApiException) {
        throw err
      }
      console.error('http request failed')
      throw new ApiException(-1, '网络连接失败，请检查网络后重试', true)
    } finally {
      request.destroy()
    }
  }

  private static createUrl(path: string): string {
    if (path.indexOf('http://') === 0 || path.indexOf('https://') === 0) {
      return path
    }
    if (path.indexOf('/') === 0) {
      return Constants.API_URL + path
    }
    return Constants.API_URL + '/' + path
  }
}

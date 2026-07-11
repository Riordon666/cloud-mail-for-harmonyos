import { ApiResponse, HttpClient, QueryParameter } from '../common/HttpClient'

class AddAccountRequest {
  email: string
  token: string

  constructor(email: string, token: string) {
    this.email = email
    this.token = token
  }
}

class AccountNameRequest {
  accountId: number
  name: string

  constructor(accountId: number, name: string) {
    this.accountId = accountId
    this.name = name
  }
}

class AccountIdRequest {
  accountId: number

  constructor(accountId: number) {
    this.accountId = accountId
  }
}

export class AccountApi {
  static async list(accountId: number, size: number, lastSort: number): Promise<ApiResponse> {
    const path: string = HttpClient.appendQuery('/account/list', [
      new QueryParameter('accountId', accountId.toString()),
      new QueryParameter('size', size.toString()),
      new QueryParameter('lastSort', lastSort.toString())
    ])
    return HttpClient.get(path)
  }

  static async add(email: string, token: string): Promise<ApiResponse> {
    const request: AddAccountRequest = new AddAccountRequest(email, token)
    return HttpClient.post('/account/add', JSON.stringify(request))
  }

  static async delete(accountId: number): Promise<ApiResponse> {
    const path: string = HttpClient.appendQuery('/account/delete', [new QueryParameter('accountId', accountId.toString())])
    return HttpClient.delete(path)
  }

  static async setName(accountId: number, name: string): Promise<ApiResponse> {
    const request: AccountNameRequest = new AccountNameRequest(accountId, name)
    return HttpClient.put('/account/setName', JSON.stringify(request))
  }

  static async setAllReceive(accountId: number): Promise<ApiResponse> {
    const request: AccountIdRequest = new AccountIdRequest(accountId)
    return HttpClient.put('/account/setAllReceive', JSON.stringify(request))
  }

  static async setAsTop(accountId: number): Promise<ApiResponse> {
    const request: AccountIdRequest = new AccountIdRequest(accountId)
    return HttpClient.put('/account/setAsTop', JSON.stringify(request))
  }
}

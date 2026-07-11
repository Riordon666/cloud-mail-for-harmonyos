import { ApiResponse, HttpClient, QueryParameter } from '../common/HttpClient'

class EmailIdsRequest {
  emailIds: number[]

  constructor(emailIds: number[]) {
    this.emailIds = emailIds
  }
}

class EmailIdRequest {
  emailId: number

  constructor(emailId: number) {
    this.emailId = emailId
  }
}

export class EmailApi {
  static async list(accountId: number, allReceive: number, emailId: number, timeSort: number, size: number,
    type: number): Promise<ApiResponse> {
    const path: string = HttpClient.appendQuery('/email/list', [
      new QueryParameter('accountId', accountId.toString()),
      new QueryParameter('allReceive', allReceive.toString()),
      new QueryParameter('emailId', emailId.toString()),
      new QueryParameter('timeSort', timeSort.toString()),
      new QueryParameter('size', size.toString()),
      new QueryParameter('type', type.toString())
    ])
    return HttpClient.get(path)
  }

  static async latest(emailId: number, accountId: number, allReceive: number): Promise<ApiResponse> {
    const path: string = HttpClient.appendQuery('/email/latest', [
      new QueryParameter('emailId', emailId.toString()),
      new QueryParameter('accountId', accountId.toString()),
      new QueryParameter('allReceive', allReceive.toString())
    ])
    return HttpClient.get(path)
  }

  static async delete(emailIds: string): Promise<ApiResponse> {
    const path: string = HttpClient.appendQuery('/email/delete', [new QueryParameter('emailIds', emailIds)])
    return HttpClient.delete(path)
  }

  static async markRead(emailIds: number[]): Promise<ApiResponse> {
    const request: EmailIdsRequest = new EmailIdsRequest(emailIds)
    return HttpClient.put('/email/read', JSON.stringify(request))
  }

  static async addStar(emailId: number): Promise<ApiResponse> {
    const request: EmailIdRequest = new EmailIdRequest(emailId)
    return HttpClient.post('/star/add', JSON.stringify(request))
  }

  static async cancelStar(emailId: number): Promise<ApiResponse> {
    const path: string = HttpClient.appendQuery('/star/cancel', [new QueryParameter('emailId', emailId.toString())])
    return HttpClient.delete(path)
  }

  static async listStarred(emailId: number, size: number): Promise<ApiResponse> {
    const path: string = HttpClient.appendQuery('/star/list', [
      new QueryParameter('emailId', emailId.toString()),
      new QueryParameter('size', size.toString())
    ])
    return HttpClient.get(path)
  }

  static async send(jsonForm: string): Promise<ApiResponse> {
    return HttpClient.post('/email/send', jsonForm)
  }
}

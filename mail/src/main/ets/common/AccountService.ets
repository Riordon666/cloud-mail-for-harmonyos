import { ApiException, ApiResponse } from './HttpClient'
import { AccountApi } from '../api/AccountApi'

export class ManagedAccount {
  id: number
  email: string
  unread: number
  total: number
  isPrimary: boolean

  constructor(id: number, email: string, unread: number, total: number, isPrimary: boolean) {
    this.id = id
    this.email = email
    this.unread = unread
    this.total = total
    this.isPrimary = isPrimary
  }
}

export class AccountResult {
  success: boolean
  message: string

  constructor(success: boolean, message: string) {
    this.success = success
    this.message = message
  }
}

class RemoteAccount {
  accountId: number = 0
  email: string = ''
}

export class AccountService {
  static async getAccounts(primaryEmail: string): Promise<ManagedAccount[]> {
    const response: ApiResponse = await AccountApi.list(0, 30, 999999999)
    if (response.data === null) {
      return []
    }
    const remoteAccounts: RemoteAccount[] = response.data as RemoteAccount[]
    const result: ManagedAccount[] = []
    for (let index = 0; index < remoteAccounts.length; index++) {
      const account: RemoteAccount = remoteAccounts[index]
      result.push(new ManagedAccount(account.accountId, account.email, 0, -1, account.email === primaryEmail))
    }
    return result
  }

  static async registerSecondaryEmail(email: string): Promise<AccountResult> {
    try {
      await AccountApi.add(email, '')
      AccountService.notifyChange()
      return new AccountResult(true, '')
    } catch (err) {
      return new AccountResult(false, AccountService.toErrorMessage(err))
    }
  }

  static async deleteSecondaryEmail(id: number): Promise<AccountResult> {
    try {
      await AccountApi.delete(id)
      AccountService.notifyChange()
      return new AccountResult(true, '')
    } catch (err) {
      return new AccountResult(false, AccountService.toErrorMessage(err))
    }
  }

  private static notifyChange(): void {
    const revision: number | undefined = AppStorage.get('accountRevision') as number | undefined
    AppStorage.set('accountRevision', revision === undefined ? 1 : revision + 1)
  }

  private static toErrorMessage(err: Error): string {
    if (err instanceof ApiException) {
      return err.message
    }
    return '请求失败，请稍后重试'
  }
}

import { common } from '@kit.AbilityKit'
import { authentication } from '@kit.AccountKit'
import { util } from '@kit.ArkTS'
import { BusinessError } from '@kit.BasicServicesKit'
import { ApiException } from './HttpClient'
import { LoginInstanceService } from './LoginInstanceService'
import { PlatformSessionService } from './PlatformSessionService'

// Renew the platform identity without replacing the mailbox the user is reading.
export default class PlatformReauthorization {
  private static inFlight: Promise<void> | null = null

  static reauthorize(context: common.UIAbilityContext): Promise<void> {
    if (PlatformReauthorization.inFlight !== null) {
      return PlatformReauthorization.inFlight
    }
    const operation: Promise<void> = PlatformReauthorization.perform(context)
    PlatformReauthorization.inFlight = operation
    return operation.finally(() => {
      if (PlatformReauthorization.inFlight === operation) {
        PlatformReauthorization.inFlight = null
      }
    })
  }

  private static async perform(context: common.UIAbilityContext): Promise<void> {
    const identity: string = PlatformSessionService.getHuaweiUserId()
    const revision: number = AppStorage.get<number>('sessionRevision') ?? 0
    if (identity === '') {
      throw new ApiException(401, '华为身份记录缺失，请退出当前邮箱后重新登录', false)
    }
    const code: string = await PlatformReauthorization.requestAuthorizationCode(context)
    if (identity !== PlatformSessionService.getHuaweiUserId() ||
      revision !== (AppStorage.get<number>('sessionRevision') ?? 0)) {
      throw new ApiException(409, '当前邮箱或账号已变化，请重新授权', false)
    }
    await LoginInstanceService.reauthorizeHuawei(code)
  }

  private static requestAuthorizationCode(context: common.UIAbilityContext): Promise<string> {
    return new Promise<string>((resolve, reject) => {
      const request: authentication.AuthorizationWithHuaweiIDRequest =
        new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest()
      request.scopes = ['openid', 'profile']
      request.permissions = ['serviceauthcode']
      request.forceAuthorization = true
      request.state = util.generateRandomUUID()
      const controller: authentication.AuthenticationController =
        new authentication.AuthenticationController(context)
      controller.executeRequest(request, (error: BusinessError<Record<string, Object>>,
        data: authentication.AuthenticationResponse) => {
        if (error) {
          const message: string = error.code === 1001502012 ? '已取消授权，当前邮箱保持登录' :
            '华为账号授权失败，请检查网络后重试'
          reject(new ApiException(error.code, message, false))
          return
        }
        const response: authentication.AuthorizationWithHuaweiIDResponse =
          data as authentication.AuthorizationWithHuaweiIDResponse
        if (!response || response.state !== request.state) {
          reject(new ApiException(401, '华为账号授权校验失败，请重试', false))
          return
        }
        const credential: authentication.AuthorizationWithHuaweiIDCredential | undefined = response.data
        if (!credential || !credential.authorizationCode) {
          reject(new ApiException(401, '未获取到华为账号授权，请重试', false))
          return
        }
        resolve(credential.authorizationCode)
      })
    })
  }
}

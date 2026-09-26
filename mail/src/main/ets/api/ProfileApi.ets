import { ExternalHttpClient } from '../common/ExternalHttpClient'
import { ApiException } from '../common/HttpClient'
import { InstanceService } from '../common/InstanceService'
import { InstanceRegistry } from '../common/InstanceRegistry'
import { SessionService } from '../common/SessionService'
import { PlatformSessionService } from '../common/PlatformSessionService'
import { AccountBindingCleanup } from '../common/AccountBindingCleanup'
import { PlatformBinding } from '../common/InstanceModels'

export class ProfileTarget {
  instanceId: string = ''
  displayName: string = ''
  apiBaseUrl: string = ''
  email: string = ''
  token: string = ''
  huaweiUserId: string = ''
}

class ResetPasswordRequest {
  password: string

  constructor(password: string) {
    this.password = password
  }
}

export class ProfileApi {
  static captureTarget(): ProfileTarget {
    const instance = InstanceRegistry.getActiveInstance()
    const target: ProfileTarget = new ProfileTarget()
    target.instanceId = instance.instanceId
    target.displayName = instance.displayName
    target.apiBaseUrl = instance.apiBaseUrl
    target.email = instance.localEmail
    target.token = SessionService.getInstanceToken(instance.instanceId)
    target.huaweiUserId = PlatformSessionService.getHuaweiUserId()
    ProfileApi.requireCurrentTarget(target)
    return target
  }

  static async resetPassword(password: string, target: ProfileTarget): Promise<void> {
    ProfileApi.requireCurrentTarget(target)
    await ExternalHttpClient.put(
      target.apiBaseUrl, '/my/resetPassword', JSON.stringify(new ResetPasswordRequest(password)), target.token)
  }

  // true means both mailbox deletion and platform-link cleanup completed.
  // A failed cleanup is retained for retry; the irreversible mailbox request is never repeated.
  static async deleteAccount(target: ProfileTarget): Promise<boolean> {
    ProfileApi.requireCurrentTarget(target)
    AccountBindingCleanup.requireReady()
    const bindings: PlatformBinding[] = await InstanceService.loadMyBindings()
    ProfileApi.requireCurrentTarget(target)
    let binding: PlatformBinding | null = null
    for (let index = 0; index < bindings.length; index++) {
      if (bindings[index].instanceId === target.instanceId &&
        bindings[index].localEmail.toLowerCase() === target.email.toLowerCase()) {
        binding = bindings[index]
        break
      }
    }
    if (binding === null || binding.bindingId <= 0 || binding.verifiedTime === '') {
      throw new ApiException(409, '未能确认当前邮箱绑定，请刷新账号中心或重新验证华为身份后重试', false)
    }
    const path: string = target.instanceId === InstanceRegistry.getDefaultInstanceId() ? '/huawei/me' : '/my/delete'
    await ExternalHttpClient.delete(target.apiBaseUrl, path, target.token)
    AccountBindingCleanup.enqueue(target.huaweiUserId, target.instanceId, target.email,
      binding.bindingId, binding.verifiedTime)
    if (PlatformSessionService.getHuaweiUserId() === target.huaweiUserId &&
      SessionService.getInstanceToken(target.instanceId) === target.token) {
      SessionService.clearMailboxSession(target.instanceId)
    }
    if (PlatformSessionService.getHuaweiUserId() !== target.huaweiUserId) { return false }
    return AccountBindingCleanup.retry()
  }

  private static requireCurrentTarget(target: ProfileTarget): void {
    if (target.instanceId === '' || target.token === '' || target.email === '' || target.apiBaseUrl === '' ||
      target.huaweiUserId === '') {
      throw new ApiException(401, '当前邮箱尚未登录，请先登录所选服务', false)
    }
    const current = InstanceRegistry.getActiveInstance()
    if (current.instanceId !== target.instanceId || current.apiBaseUrl !== target.apiBaseUrl ||
      current.localEmail !== target.email || SessionService.getInstanceToken(target.instanceId) !== target.token ||
      PlatformSessionService.getHuaweiUserId() !== target.huaweiUserId) {
      throw new ApiException(409, '当前邮箱已变化，请重新打开账号设置确认操作对象', false)
    }
  }
}

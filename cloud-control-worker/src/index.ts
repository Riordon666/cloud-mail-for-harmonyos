interface Env {
  DB: D1Database
  PLATFORM_JWT_SECRET: string
  ANCHOR_INSTANCE_API_BASE_URL: string
  SUPER_ADMIN_HUAWEI_IDS: string
  ALLOWED_ORIGINS: string
}

interface HuaweiIdentity {
  huaweiUserId: string
  unionId: string
  openId: string
  nickName: string
  avatarUrl: string
}

interface PlatformUserRow {
  platform_user_id: number
  huawei_user_id: string
  nick_name: string | null
  avatar_url: string | null
  platform_role: string
  status: string
}

interface PlatformTokenPayload {
  sub: number
  huaweiUserId: string
  role: string
  iat: number
  exp: number
}

interface MailInstanceRow {
  instance_id: string
  display_name: string
  api_base_url: string
  origin_host: string
  status: string
}

interface BindingCountRow {
  count_value: number
}

interface ExistingBindingRoleRow {
  instance_role: string
}

interface PlatformBindingRow {
  binding_id: number
  platform_user_id: number
  instance_id: string
  display_name: string
  api_base_url: string
  origin_host: string
  local_email: string
  local_role_name: string
  instance_role: string
  verified_time: string
}

interface PlatformAdminBindingRow {
  platform_user_id: number
  huawei_user_id: string
  nick_name: string | null
  avatar_url: string | null
  platform_role: string
  create_time: string
  binding_id: number | null
  instance_id: string | null
  display_name: string | null
  api_base_url: string | null
  origin_host: string | null
  local_email: string | null
  local_role_name: string | null
  instance_role: string | null
  verified_time: string | null
  instance_status: string | null
}

interface PlatformBindingView {
  bindingId: number
  instanceId: string
  displayName: string
  apiBaseUrl: string
  originHost: string
  localEmail: string
  localRoleName: string
  instanceRole: string
  verifiedTime: string
}

interface BindingRemovalSnapshot {
  email: string
  bindingId: number
  verifiedTime: string
}

interface PlatformAdminUserView {
  platformUserId: number
  huaweiUserId: string
  nickName: string
  avatarUrl: string
  platformRole: string
  createTime: string
  bindingCount: number
  bindings: PlatformBindingView[]
}

interface InstanceUserPayload {
  userId?: number | string
  email?: string
  role?: { name?: string }
  permKeys?: string[]
}

interface CloudMailEnvelope {
  code?: number
  message?: string
  data?: InstanceUserPayload
}

interface AnchorHuaweiPayload {
  huaweiUserId?: string
  nickName?: string
  avatarUrl?: string
  primaryEmail?: string
}

interface AnchorHuaweiEnvelope {
  code?: number
  data?: AnchorHuaweiPayload
}

interface AnchorLoginState {
  status: 'BOUND' | 'UNBOUND'
  token: string
  email: string
  bindToken: string
}

interface AnchorAdminBindingItem {
  huaweiAccountId?: number
  huaweiUserId?: string
  nickName?: string
  avatarUrl?: string
  primaryEmail?: string
  profileUpdateTime?: string
  createTime?: string
}

interface AnchorAdminBindingPage {
  list?: AnchorAdminBindingItem[]
  total?: number
  page?: number
  size?: number
}

interface AnchorAdminBindingEnvelope {
  code?: number
  message?: string
  data?: AnchorAdminBindingPage
}

interface BindingOwnerRow {
  platform_user_id: number
}

interface AnchorAuthorityBindingRow {
  local_email: string
}

interface JsonObject {
  [key: string]: unknown
}

const PLATFORM_TOKEN_TTL_SECONDS = 7 * 24 * 60 * 60
const ANCHOR_INSTANCE_ID = 'riordon-cloud-mail'

class HttpError extends Error {
  status: number
  code: number

  constructor(status: number, code: number, message: string) {
    super(message)
    this.status = status
    this.code = code
  }
}

function jsonResponse(request: Request, env: Env, data: unknown, status = 200, code = 200,
  message = ''): Response {
  const headers = new Headers({ 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store' })
  applyCorsHeaders(request, env, headers)
  return new Response(JSON.stringify({ code, message, data }), { status, headers })
}

function emptyResponse(request: Request, env: Env): Response {
  const headers = new Headers()
  applyCorsHeaders(request, env, headers)
  return new Response(null, { status: 204, headers })
}

function applyCorsHeaders(request: Request, env: Env, headers: Headers): void {
  const origin = request.headers.get('Origin') || ''
  if (origin !== '' && isAllowedOrigin(origin, env.ALLOWED_ORIGINS)) {
    headers.set('Access-Control-Allow-Origin', origin)
    headers.set('Vary', 'Origin')
    headers.set('Access-Control-Allow-Headers', 'Authorization, Content-Type')
    headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
  }
}

function isAllowedOrigin(origin: string, configured: string): boolean {
  const allowed = configured.split(',').map((value) => value.trim()).filter((value) => value !== '')
  return allowed.includes(origin)
}

async function parseBody(request: Request): Promise<JsonObject> {
  try {
    return await request.json() as JsonObject
  } catch {
    throw new HttpError(400, 400, '请求内容不是有效的 JSON')
  }
}

function textValue(value: unknown): string {
  return typeof value === 'string' ? value.trim() : ''
}

export function normalizeInstanceDisplayName(value: unknown, fallback = ''): string {
  const displayName = textValue(value) || fallback.trim()
  if (displayName === '') {
    throw new HttpError(400, 400, '服务名称不能为空')
  }
  if (displayName.length > 60) {
    throw new HttpError(400, 400, '服务名称不能超过 60 个字符')
  }
  return displayName
}

export function isProtectedInstance(instanceId: string): boolean {
  return instanceId === ANCHOR_INSTANCE_ID
}

function positiveInteger(value: string | null, fallback: number, maximum: number): number {
  const parsed = Number(value)
  if (!Number.isInteger(parsed) || parsed < 1) {
    return fallback
  }
  return Math.min(parsed, maximum)
}

function base64UrlEncode(value: Uint8Array): string {
  let binary = ''
  for (let index = 0; index < value.length; index++) {
    binary += String.fromCharCode(value[index])
  }
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '')
}

function base64UrlDecode(value: string): Uint8Array {
  const normalized = value.replace(/-/g, '+').replace(/_/g, '/')
  const padding = normalized.length % 4 === 0 ? '' : '='.repeat(4 - normalized.length % 4)
  const binary = atob(normalized + padding)
  const bytes = new Uint8Array(binary.length)
  for (let index = 0; index < binary.length; index++) {
    bytes[index] = binary.charCodeAt(index)
  }
  return bytes
}

async function importJwtKey(secret: string): Promise<CryptoKey> {
  return crypto.subtle.importKey('raw', new TextEncoder().encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false,
    ['sign', 'verify'])
}

async function issuePlatformToken(user: PlatformUserRow, secret: string): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  const header = base64UrlEncode(new TextEncoder().encode(JSON.stringify({ alg: 'HS256', typ: 'JWT' })))
  const payload: PlatformTokenPayload = {
    sub: user.platform_user_id,
    huaweiUserId: user.huawei_user_id,
    role: user.platform_role,
    iat: now,
    exp: now + PLATFORM_TOKEN_TTL_SECONDS
  }
  const body = base64UrlEncode(new TextEncoder().encode(JSON.stringify(payload)))
  const signingInput = header + '.' + body
  const key = await importJwtKey(secret)
  const signature = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(signingInput))
  return signingInput + '.' + base64UrlEncode(new Uint8Array(signature))
}

async function verifyPlatformToken(token: string, secret: string): Promise<PlatformTokenPayload> {
  const parts = token.split('.')
  if (parts.length !== 3) {
    throw new HttpError(401, 401, '平台登录已失效，请重新登录')
  }
  const signingInput = parts[0] + '.' + parts[1]
  const key = await importJwtKey(secret)
  const signatureBytes = base64UrlDecode(parts[2])
  const valid = await crypto.subtle.verify('HMAC', key, signatureBytes.buffer as ArrayBuffer,
    new TextEncoder().encode(signingInput))
  if (!valid) {
    throw new HttpError(401, 401, '平台登录已失效，请重新登录')
  }
  const payloadText = new TextDecoder().decode(base64UrlDecode(parts[1]))
  const payload = JSON.parse(payloadText) as PlatformTokenPayload
  if (payload.exp <= Math.floor(Date.now() / 1000)) {
    throw new HttpError(401, 401, '平台登录已过期，请重新登录')
  }
  return payload
}

function bearerToken(request: Request): string {
  const authorization = request.headers.get('Authorization') || ''
  if (authorization.startsWith('Bearer ')) {
    return authorization.substring(7).trim()
  }
  return authorization.trim()
}

async function requireUser(request: Request, env: Env): Promise<PlatformUserRow> {
  const token = bearerToken(request)
  if (token === '') {
    throw new HttpError(401, 401, '请先使用华为账号登录')
  }
  const payload = await verifyPlatformToken(token, env.PLATFORM_JWT_SECRET)
  const user = await env.DB.prepare(
    'SELECT platform_user_id, huawei_user_id, nick_name, avatar_url, platform_role, status ' +
    'FROM platform_user WHERE platform_user_id = ? LIMIT 1'
  ).bind(payload.sub).first<PlatformUserRow>()
  if (user === null || user.status !== 'ACTIVE') {
    throw new HttpError(401, 401, '平台账号不可用')
  }
  return user
}

function requireSuperAdmin(user: PlatformUserRow): void {
  if (user.platform_role !== 'SUPER_ADMIN') {
    throw new HttpError(403, 403, '仅平台超级管理员可执行此操作')
  }
}

function isSuperAdminIdentity(huaweiUserId: string, configured: string, alias = ''): boolean {
  return configured.split(',').map((value) => value.trim()).filter((value) => value !== '')
    .some((value) => value === huaweiUserId || (alias !== '' && value.toLowerCase() === alias.toLowerCase()))
}

async function upsertPlatformUser(identity: HuaweiIdentity, env: Env, superAdminAlias = ''): Promise<PlatformUserRow> {
  const existing = await env.DB.prepare(
    'SELECT platform_user_id, huawei_user_id, nick_name, avatar_url, platform_role, status ' +
    'FROM platform_user WHERE huawei_user_id = ? LIMIT 1'
  ).bind(identity.huaweiUserId).first<PlatformUserRow>()
  if (existing !== null && existing.status !== 'ACTIVE') {
    throw new HttpError(401, 401, '平台账号不可用')
  }
  // Only this login's server-verified anchor mailbox can grant email-based
  // authority. A stored link is historical evidence, not proof it still exists.
  const platformRole = isSuperAdminIdentity(identity.huaweiUserId, env.SUPER_ADMIN_HUAWEI_IDS, superAdminAlias) ?
    'SUPER_ADMIN' : 'MEMBER'
  const statements = [env.DB.prepare(
    'INSERT INTO platform_user (huawei_user_id, union_id, open_id, nick_name, avatar_url, platform_role) ' +
    'VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT(huawei_user_id) DO UPDATE SET ' +
    'union_id = excluded.union_id, open_id = excluded.open_id, ' +
    'nick_name = COALESCE(excluded.nick_name, platform_user.nick_name), ' +
    'avatar_url = COALESCE(excluded.avatar_url, platform_user.avatar_url), ' +
    'platform_role = excluded.platform_role, update_time = CURRENT_TIMESTAMP ' +
    'WHERE platform_user.status = \'ACTIVE\''
  ).bind(identity.huaweiUserId, identity.unionId === '' ? null : identity.unionId, identity.openId,
    identity.nickName === '' ? null : identity.nickName, identity.avatarUrl === '' ? null : identity.avatarUrl,
    platformRole)]
  if (superAdminAlias === '' && existing !== null) {
    statements.push(...removeOwnBindingStatements(env, existing, ANCHOR_INSTANCE_ID))
  }
  await env.DB.batch(statements)
  const user = await env.DB.prepare(
    'SELECT platform_user_id, huawei_user_id, nick_name, avatar_url, platform_role, status ' +
    'FROM platform_user WHERE huawei_user_id = ? LIMIT 1'
  ).bind(identity.huaweiUserId).first<PlatformUserRow>()
  if (user === null) {
    throw new HttpError(500, 500, '平台账号保存失败')
  }
  if (user.status !== 'ACTIVE') {
    throw new HttpError(401, 401, '平台账号不可用')
  }
  return user
}

function jsonObject(value: unknown): JsonObject {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(502, 502, '主服务返回的身份信息无效')
  }
  return value as JsonObject
}

function verifiedHuaweiIdentity(value: unknown): HuaweiIdentity {
  const source = jsonObject(value)
  const identity: HuaweiIdentity = {
    huaweiUserId: textValue(source.huaweiUserId),
    unionId: textValue(source.unionId),
    openId: textValue(source.openId),
    nickName: textValue(source.nickName),
    avatarUrl: textValue(source.avatarUrl)
  }
  if (identity.openId === '' || identity.huaweiUserId === '' || identity.huaweiUserId.includes('…') ||
    identity.huaweiUserId !== (identity.unionId || identity.openId)) {
    throw new HttpError(502, 502, '主服务未返回完整的华为账号身份')
  }
  return identity
}

async function readAnchorIdentityResponse(response: Response): Promise<JsonObject> {
  // Workerd does not implement redirect: 'error'. Fetch manually and reject
  // redirects before reading identity data, without forwarding any credentials.
  if (response.status >= 300 && response.status < 400) {
    await response.body?.cancel()
    throw new HttpError(502, 502, '主服务身份接口发生重定向，请联系管理员检查服务地址')
  }
  // Identity envelopes are small. Bound both declared and streamed response sizes.
  const maximumBytes = 65536
  if (Number(response.headers.get('Content-Length') || '0') > maximumBytes || response.body === null) {
    await response.body?.cancel()
    throw new HttpError(502, 502, '主服务身份响应无效')
  }
  const reader = response.body.getReader()
  const decoder = new TextDecoder()
  let body = ''
  let bytes = 0
  try {
    while (true) {
      const part = await reader.read()
      if (part.done) break
      bytes += part.value.byteLength
      if (bytes > maximumBytes) {
        await reader.cancel()
        throw new HttpError(502, 502, '主服务身份响应过大')
      }
      body += decoder.decode(part.value, { stream: true })
    }
    body += decoder.decode()
  } finally {
    reader.releaseLock()
  }
  let envelope: JsonObject
  try {
    envelope = jsonObject(JSON.parse(body))
  } catch {
    throw new HttpError(502, 502, '主服务尚不支持平台华为登录，请联系管理员更新服务')
  }
  if (!response.ok || envelope.code !== 200) {
    const reportedStatus = Number(envelope.code)
    if (reportedStatus === 401 || response.status === 401) {
      throw new HttpError(401, 401, '华为账号授权已失效，请重新登录')
    }
    if (reportedStatus === 403 || response.status === 403) {
      throw new HttpError(403, 403, '当前华为账号对应的主服务账号不可用')
    }
    if (reportedStatus === 503 || response.status === 503) {
      throw new HttpError(503, 503, '主服务尚未配置好华为登录，请联系管理员')
    }
    throw new HttpError(502, 502, '主服务身份校验失败，请稍后重试')
  }
  return jsonObject(envelope.data)
}

async function resolveAnchorPlatformUser(identity: HuaweiIdentity, primaryEmail: string,
  env: Env): Promise<PlatformUserRow> {
  const verifiedEmail = primaryEmail.toLowerCase()
  if (verifiedEmail !== '') {
    // Historical clients stored a masked ID. A verified anchor mailbox binding,
    // not a collision-prone masked ID alone, is required to upgrade that row.
    const legacyRows = await env.DB.prepare(
      'SELECT p.platform_user_id, p.huawei_user_id, p.nick_name, p.avatar_url, p.platform_role, p.status ' +
      'FROM platform_user p INNER JOIN instance_binding b ON b.platform_user_id = p.platform_user_id ' +
      'WHERE b.instance_id = ? AND lower(b.local_email) = ? LIMIT 2'
    ).bind(ANCHOR_INSTANCE_ID, verifiedEmail).all<PlatformUserRow>()
    if (legacyRows.results.length > 1) {
      throw new HttpError(409, 409, '主邮箱存在冲突的绑定，请联系管理员')
    }
    const legacy = legacyRows.results[0]
    if (legacy !== undefined) {
      if (legacy.status !== 'ACTIVE') {
        throw new HttpError(401, 401, '平台账号不可用')
      }
      if (legacy.huawei_user_id !== identity.huaweiUserId) {
        const maskedId = identity.huaweiUserId.length <= 12 ? identity.huaweiUserId :
          identity.huaweiUserId.slice(0, 6) + '…' + identity.huaweiUserId.slice(-6)
        if (legacy.huawei_user_id !== maskedId && legacy.huawei_user_id !== 'anchor:' + verifiedEmail) {
          throw new HttpError(409, 409, '主邮箱已绑定其他华为身份，请联系管理员')
        }
        const role = isSuperAdminIdentity(identity.huaweiUserId, env.SUPER_ADMIN_HUAWEI_IDS,
          'anchor:' + verifiedEmail) ? 'SUPER_ADMIN' : 'MEMBER'
        try {
          // One atomic UPDATE preserves the platform user ID and every FK/binding;
          // a canonical-ID collision aborts without merging unrelated accounts.
          await env.DB.prepare(
            'UPDATE platform_user SET huawei_user_id = ?, union_id = ?, open_id = ?, ' +
            'nick_name = COALESCE(NULLIF(?, \'\'), nick_name), ' +
            'avatar_url = COALESCE(NULLIF(?, \'\'), avatar_url), platform_role = ?, ' +
            'update_time = CURRENT_TIMESTAMP WHERE platform_user_id = ? AND huawei_user_id = ? ' +
            'AND status = \'ACTIVE\''
          ).bind(identity.huaweiUserId, identity.unionId || null, identity.openId, identity.nickName,
            identity.avatarUrl, role, legacy.platform_user_id, legacy.huawei_user_id).run()
        } catch {
          throw new HttpError(409, 409, '华为身份存在重复的绑定，请联系管理员')
        }
      }
    }
  }
  return upsertPlatformUser(identity, env, verifiedEmail === '' ? '' : 'anchor:' + verifiedEmail)
}

function normalizeApiBaseUrl(value: string): URL {
  let url: URL
  try {
    url = new URL(value)
  } catch {
    throw new HttpError(400, 400, '请输入有效的 HTTPS 服务地址')
  }
  if (url.protocol !== 'https:' || url.username !== '' || url.password !== '' || url.port !== '') {
    throw new HttpError(400, 400, '服务地址必须使用标准 HTTPS 地址')
  }
  const host = url.hostname.toLowerCase()
  if (host === 'localhost' || host.endsWith('.localhost') || host === '0.0.0.0' || host === '127.0.0.1' ||
    host === '::1' || /^10\./.test(host) || /^192\.168\./.test(host) || /^169\.254\./.test(host) ||
    /^172\.(1[6-9]|2\d|3[0-1])\./.test(host)) {
    throw new HttpError(400, 400, '服务地址不能指向本机或内网')
  }
  url.hash = ''
  url.search = ''
  let pathname = url.pathname.replace(/\/{2,}/g, '/').replace(/\/+$/, '')
  if (!pathname.endsWith('/api')) {
    pathname += '/api'
  }
  url.pathname = pathname
  return url
}

async function probeInstance(apiBaseUrl: string): Promise<string> {
  const response = await fetch(apiBaseUrl + '/setting/websiteConfig', {
    headers: { 'Accept': 'application/json' },
    signal: AbortSignal.timeout(10000)
  })
  if (!response.ok) {
    throw new HttpError(400, 400, '无法连接该邮箱服务')
  }
  const payload = await response.json() as { code?: number, data?: { title?: string } }
  if (payload.code !== 200 || payload.data === undefined) {
    throw new HttpError(400, 400, '该地址不是兼容的 Cloud Mail 服务')
  }
  return textValue(payload.data.title)
}

function roleIsAdmin(payload: InstanceUserPayload): boolean {
  if (textValue(payload.role?.name).toLowerCase() === 'admin') {
    return true
  }
  const keys = Array.isArray(payload.permKeys) ? payload.permKeys : []
  return keys.includes('*')
}

export function isAnchorImportAuthority(platformRole: string, localUser: InstanceUserPayload,
  expectedEmail: string): boolean {
  return platformRole === 'SUPER_ADMIN' && roleIsAdmin(localUser) &&
    textValue(localUser.email).toLowerCase() === expectedEmail.toLowerCase()
}

async function verifyInstanceUser(instance: MailInstanceRow, instanceToken: string): Promise<InstanceUserPayload> {
  if (instanceToken === '') {
    throw new HttpError(400, 400, '缺少实例登录令牌')
  }
  const response = await fetch(instance.api_base_url + '/my/loginUserInfo', {
    headers: { 'Accept': 'application/json', 'Authorization': instanceToken },
    signal: AbortSignal.timeout(15000)
  })
  const envelope = await response.json() as CloudMailEnvelope
  if (!response.ok || envelope.code !== 200 || envelope.data === undefined) {
    throw new HttpError(401, 401, '邮箱账号验证失败，请重新登录该实例')
  }
  if (textValue(envelope.data.email) === '') {
    throw new HttpError(502, 502, '实例未返回有效邮箱账号')
  }
  return envelope.data
}

async function determineInstanceRole(env: Env, platformUserId: number, instanceId: string,
  isAdmin: boolean): Promise<string> {
  if (!isAdmin) {
    return 'MEMBER'
  }
  const existingBinding = await env.DB.prepare(
    'SELECT instance_role FROM instance_binding WHERE platform_user_id = ? AND instance_id = ? LIMIT 1'
  ).bind(platformUserId, instanceId).first<ExistingBindingRoleRow>()
  if (existingBinding !== null && existingBinding.instance_role === 'INSTANCE_OWNER') {
    return 'INSTANCE_OWNER'
  }
  const ownerCount = await env.DB.prepare(
    'SELECT COUNT(*) AS count_value FROM instance_binding WHERE instance_id = ? ' +
    'AND instance_role = \'INSTANCE_OWNER\' AND status = \'ACTIVE\''
  ).bind(instanceId).first<BindingCountRow>()
  return ownerCount === null || ownerCount.count_value === 0 ? 'INSTANCE_OWNER' : 'INSTANCE_ADMIN'
}

function bindingUpsert(env: Env, user: PlatformUserRow, instance: MailInstanceRow,
  localUser: InstanceUserPayload, instanceRole: string): D1PreparedStatement {
  const localEmail = textValue(localUser.email)
  const localUserKey = localUser.userId === undefined ? localEmail.toLowerCase() : String(localUser.userId)
  const localRoleName = textValue(localUser.role?.name)
  return env.DB.prepare(
    'INSERT INTO instance_binding (platform_user_id, instance_id, local_user_key, local_email, ' +
    'local_role_name, instance_role, verified_time) VALUES (?, ?, ?, ?, ?, ?, ?) ' +
    'ON CONFLICT(platform_user_id, instance_id) DO UPDATE SET local_user_key = excluded.local_user_key, ' +
    'local_email = excluded.local_email, local_role_name = excluded.local_role_name, ' +
    'instance_role = excluded.instance_role, status = \'ACTIVE\', verified_time = ' +
    'CASE WHEN julianday(excluded.verified_time) > julianday(instance_binding.verified_time) ' +
    'THEN excluded.verified_time ELSE strftime(\'%Y-%m-%dT%H:%M:%fZ\', ' +
    'julianday(instance_binding.verified_time) + 1.0 / 86400000) END, ' +
    'update_time = CURRENT_TIMESTAMP'
  ).bind(user.platform_user_id, instance.instance_id, localUserKey, localEmail, localRoleName, instanceRole,
    new Date().toISOString())
}

function auditInsert(env: Env, userId: number, instanceId: string | null, action: string,
  detail: string): D1PreparedStatement {
  return env.DB.prepare(
    'INSERT INTO platform_audit_log (platform_user_id, instance_id, action, detail) VALUES (?, ?, ?, ?)'
  ).bind(userId, instanceId, action, detail)
}

async function foreignLocalBinding(env: Env, platformUserId: number, instanceId: string,
  localUserKey: string): Promise<BindingOwnerRow | null> {
  return env.DB.prepare(
    'SELECT platform_user_id FROM instance_binding WHERE instance_id = ? AND local_user_key = ? ' +
    'AND platform_user_id <> ? LIMIT 1'
  ).bind(instanceId, localUserKey, platformUserId).first<BindingOwnerRow>()
}

async function activeOwner(env: Env, instanceId: string, platformUserId: number): Promise<BindingOwnerRow | null> {
  return env.DB.prepare(
    'SELECT platform_user_id FROM instance_binding WHERE instance_id = ? AND instance_role = \'INSTANCE_OWNER\' ' +
    'AND status = \'ACTIVE\' AND platform_user_id <> ? LIMIT 1'
  ).bind(instanceId, platformUserId).first<BindingOwnerRow>()
}

async function persistInstanceBinding(env: Env, user: PlatformUserRow, instance: MailInstanceRow,
  localUser: InstanceUserPayload, auditAction: string, auditDetail: string): Promise<string> {
  const localEmail = textValue(localUser.email)
  const localUserKey = localUser.userId === undefined ? localEmail.toLowerCase() : String(localUser.userId)
  let instanceRole = await determineInstanceRole(
    env, user.platform_user_id, instance.instance_id, roleIsAdmin(localUser))

  const runBatch = async (role: string): Promise<void> => {
    await env.DB.batch([
      bindingUpsert(env, user, instance, localUser, role),
      auditInsert(env, user.platform_user_id, instance.instance_id, auditAction, auditDetail)
    ])
  }

  try {
    await runBatch(instanceRole)
  } catch (error) {
    const foreign = await foreignLocalBinding(env, user.platform_user_id, instance.instance_id, localUserKey)
    if (foreign !== null) {
      throw new HttpError(409, 409, '该实例邮箱已经绑定其他华为账号')
    }
    if (instanceRole !== 'INSTANCE_OWNER' ||
      await activeOwner(env, instance.instance_id, user.platform_user_id) === null) {
      throw error
    }
    instanceRole = 'INSTANCE_ADMIN'
    try {
      await runBatch(instanceRole)
    } catch (retryError) {
      const retryForeign = await foreignLocalBinding(env, user.platform_user_id, instance.instance_id, localUserKey)
      if (retryForeign !== null) {
        throw new HttpError(409, 409, '该实例邮箱已经绑定其他华为账号')
      }
      throw retryError
    }
  }
  return instanceRole
}

async function writeAudit(env: Env, userId: number, instanceId: string | null, action: string,
  detail: string): Promise<void> {
  await auditInsert(env, userId, instanceId, action, detail).run()
}

function removeOwnBindingStatements(env: Env, user: PlatformUserRow,
  instanceId: string, expected?: BindingRemovalSnapshot): D1PreparedStatement[] {
  const statements: D1PreparedStatement[] = []
  const condition = 'platform_user_id = ? AND instance_id = ?' +
    (expected === undefined ? '' : ' AND lower(local_email) = ? AND binding_id = ? AND verified_time = ?')
  const values: (number | string)[] = [user.platform_user_id, instanceId]
  if (expected !== undefined) values.push(expected.email, expected.bindingId, expected.verifiedTime)
  if (instanceId === ANCHOR_INSTANCE_ID) {
    // Do not let an imported display-only record resurrect the removed link.
    statements.push(env.DB.prepare(
      'DELETE FROM legacy_anchor_binding WHERE source_instance_id = ? AND lower(primary_email) IN ' +
      '(SELECT lower(local_email) FROM instance_binding WHERE ' + condition + ')'
    ).bind(instanceId, ...values))
    const role = isSuperAdminIdentity(user.huawei_user_id, env.SUPER_ADMIN_HUAWEI_IDS) ? 'SUPER_ADMIN' : 'MEMBER'
    // A delayed cleanup for an old mailbox must not downgrade a newly verified
    // mailbox. An authoritative UNBOUND login (no snapshot) always revokes.
    statements.push(env.DB.prepare(
      'UPDATE platform_user SET platform_role = ?, update_time = CURRENT_TIMESTAMP WHERE platform_user_id = ?' +
      (expected === undefined ? '' : ' AND EXISTS (SELECT 1 FROM instance_binding WHERE ' + condition + ')')
    ).bind(role, user.platform_user_id, ...(expected === undefined ? [] : values)))
  }
  statements.push(env.DB.prepare(
    'DELETE FROM instance_binding WHERE ' + condition
  ).bind(...values))
  return statements
}

async function handleDeleteOwnBinding(request: Request, env: Env, user: PlatformUserRow,
  instanceId: string): Promise<Response> {
  const params = new URL(request.url).searchParams
  const email = textValue(params.get('email')).toLowerCase()
  const bindingIdText = textValue(params.get('bindingId'))
  const bindingId = Number(bindingIdText)
  const verifiedTime = textValue(params.get('verifiedTime'))
  if (email === '' || email.length > 320 || !/^[1-9]\d*$/.test(bindingIdText) ||
    !Number.isSafeInteger(bindingId) || verifiedTime === '' || verifiedTime.length > 64) {
    throw new HttpError(400, 400, '缺少待解除绑定的邮箱与绑定版本信息')
  }
  const snapshot = { email, bindingId, verifiedTime }
  await env.DB.batch([
    ...removeOwnBindingStatements(env, user, instanceId, snapshot),
    auditInsert(env, user.platform_user_id, null, 'INSTANCE_BIND_REMOVE', JSON.stringify({ instanceId, ...snapshot }))
  ])
  const current = await env.DB.prepare(
    'SELECT platform_role FROM platform_user WHERE platform_user_id = ?'
  ).bind(user.platform_user_id).first<{ platform_role: string }>()
  if (current === null) {
    throw new HttpError(401, 401, '平台账号不可用')
  }
  return jsonResponse(request, env, { instanceId, platformRole: current.platform_role })
}

async function handleHuaweiLogin(request: Request, env: Env): Promise<Response> {
  // Keep the original endpoint compatible, with the same canonical identity and
  // legacy migration policy as the new onboarding entry point.
  return handleHuaweiAnchorLogin(request, env)
}

function configuredAnchor(env: Env): MailInstanceRow {
  const anchorBase = normalizeApiBaseUrl(env.ANCHOR_INSTANCE_API_BASE_URL).toString().replace(/\/$/, '')
  return {
    instance_id: ANCHOR_INSTANCE_ID,
    display_name: '云笺集主服务',
    api_base_url: anchorBase,
    origin_host: new URL(anchorBase).hostname,
    status: 'ACTIVE'
  }
}

async function persistAnchorSession(env: Env, user: PlatformUserRow, anchorInstance: MailInstanceRow,
  localUser: InstanceUserPayload): Promise<void> {
  await env.DB.prepare(
    'INSERT INTO mail_instance (instance_id, display_name, api_base_url, origin_host, created_by) ' +
    'VALUES (?, ?, ?, ?, ?) ON CONFLICT(instance_id) DO UPDATE SET api_base_url = excluded.api_base_url, ' +
    'origin_host = excluded.origin_host, status = \'ACTIVE\', update_time = CURRENT_TIMESTAMP'
  ).bind(ANCHOR_INSTANCE_ID, '云笺集主服务', anchorInstance.api_base_url, anchorInstance.origin_host,
    user.platform_user_id).run()
  await persistInstanceBinding(env, user, anchorInstance, localUser, 'ANCHOR_LOGIN', textValue(localUser.email))
}

function platformLoginView(user: PlatformUserRow, token: string): JsonObject {
  return {
    token,
    user: {
      huaweiUserId: user.huawei_user_id,
      nickName: user.nick_name || '',
      avatarUrl: user.avatar_url || '',
      platformRole: user.platform_role
    }
  }
}

async function handleHuaweiAnchorLogin(request: Request, env: Env): Promise<Response> {
  const body = await parseBody(request)
  const authorizationCode = textValue(body.authorizationCode)
  if (authorizationCode === '' || authorizationCode.length > 8192) {
    throw new HttpError(400, 400, '未获取到有效的华为账号授权码')
  }
  const anchorInstance = configuredAnchor(env)
  // The client never chooses the identity broker URL. Credentials go only to the
  // configured anchor; redirects are forbidden so they cannot escape that origin.
  const response = await fetch(anchorInstance.api_base_url + '/oauth/huawei/platform-login', {
    method: 'POST',
    headers: { 'Accept': 'application/json', 'Content-Type': 'application/json' },
    body: JSON.stringify({ authorizationCode }),
    redirect: 'manual',
    signal: AbortSignal.timeout(20000)
  })
  const verified = await readAnchorIdentityResponse(response)
  const identity = verifiedHuaweiIdentity(verified.identity)
  const status = textValue(verified.status)
  if (status !== 'BOUND' && status !== 'UNBOUND') {
    throw new HttpError(502, 502, '主服务返回的绑定状态无效')
  }
  const anchor: AnchorLoginState = {
    status,
    token: status === 'BOUND' ? textValue(verified.token) : '',
    email: status === 'BOUND' ? textValue(verified.email) : '',
    bindToken: status === 'UNBOUND' ? textValue(verified.bindToken) : ''
  }
  if ((status === 'BOUND' && (anchor.token === '' || anchor.email === '')) ||
    (status === 'UNBOUND' && anchor.bindToken === '')) {
    throw new HttpError(502, 502, '主服务返回的登录凭据无效')
  }
  let localUser: InstanceUserPayload | null = null
  if (status === 'BOUND') {
    localUser = await verifyInstanceUser(anchorInstance, anchor.token)
    if (textValue(localUser.email).toLowerCase() !== anchor.email.toLowerCase()) {
      throw new HttpError(401, 401, '主邮箱会话与华为绑定不匹配')
    }
  }
  const user = await resolveAnchorPlatformUser(identity, anchor.email, env)
  if (localUser !== null) {
    await persistAnchorSession(env, user, anchorInstance, localUser)
  }
  const token = await issuePlatformToken(user, env.PLATFORM_JWT_SECRET)
  await writeAudit(env, user.platform_user_id, null, 'HUAWEI_LOGIN', '')
  return jsonResponse(request, env, { ...platformLoginView(user, token), anchor })
}

async function handleAnchorLogin(request: Request, env: Env): Promise<Response> {
  const body = await parseBody(request)
  const instanceToken = textValue(body.instanceToken)
  if (instanceToken === '') {
    throw new HttpError(400, 400, '缺少主实例登录令牌')
  }
  const anchorInstance = configuredAnchor(env)
  const response = await fetch(anchorInstance.api_base_url + '/huawei/identity', {
    headers: { 'Accept': 'application/json', 'Authorization': instanceToken },
    redirect: 'manual',
    signal: AbortSignal.timeout(15000)
  })
  const verified = await readAnchorIdentityResponse(response)
  const identity = verifiedHuaweiIdentity(verified.identity)
  const primaryEmail = textValue(verified.primaryEmail)
  if (primaryEmail === '') {
    throw new HttpError(401, 401, '主实例未返回绑定邮箱')
  }
  const localUser = await verifyInstanceUser(anchorInstance, instanceToken)
  if (textValue(localUser.email).toLowerCase() !== primaryEmail.toLowerCase()) {
    throw new HttpError(401, 401, '主邮箱会话与华为绑定不匹配')
  }
  const user = await resolveAnchorPlatformUser(identity, primaryEmail, env)
  await persistAnchorSession(env, user, anchorInstance, localUser)
  const token = await issuePlatformToken(user, env.PLATFORM_JWT_SECRET)
  return jsonResponse(request, env, platformLoginView(user, token))
}

async function handlePublicInstances(request: Request, env: Env): Promise<Response> {
  const result = await env.DB.prepare(
    'SELECT instance_id, display_name, api_base_url, origin_host, status ' +
    'FROM mail_instance WHERE status = \'ACTIVE\' ORDER BY create_time ASC, instance_id ASC'
  ).all<MailInstanceRow>()
  return jsonResponse(request, env, result.results)
}

async function handleListInstances(request: Request, env: Env, user: PlatformUserRow): Promise<Response> {
  const result = await env.DB.prepare(
    'SELECT i.instance_id, i.display_name, i.api_base_url, i.origin_host, i.status, ' +
    'COALESCE(b.local_email, \'\') AS local_email, COALESCE(b.local_role_name, \'\') AS local_role_name, ' +
    'COALESCE(b.instance_role, \'\') AS instance_role, COALESCE(b.status, \'\') AS binding_status ' +
    'FROM mail_instance i LEFT JOIN instance_binding b ON b.instance_id = i.instance_id ' +
    'AND b.platform_user_id = ? WHERE i.status = \'ACTIVE\' ORDER BY i.create_time ASC'
  ).bind(user.platform_user_id).all<Record<string, string>>()
  return jsonResponse(request, env, result.results)
}

function bindingView(row: PlatformBindingRow): PlatformBindingView {
  return {
    bindingId: row.binding_id,
    instanceId: row.instance_id,
    displayName: row.display_name,
    apiBaseUrl: row.api_base_url,
    originHost: row.origin_host,
    localEmail: row.local_email,
    localRoleName: row.local_role_name,
    instanceRole: row.instance_role,
    verifiedTime: row.verified_time
  }
}

async function handleMyBindings(request: Request, env: Env, user: PlatformUserRow): Promise<Response> {
  const result = await env.DB.prepare(
    'SELECT b.binding_id, b.platform_user_id, b.instance_id, i.display_name, i.api_base_url, i.origin_host, ' +
    'b.local_email, b.local_role_name, b.instance_role, b.verified_time FROM instance_binding b ' +
    'INNER JOIN mail_instance i ON i.instance_id = b.instance_id WHERE b.platform_user_id = ? ' +
    'AND b.status = \'ACTIVE\' AND i.status = \'ACTIVE\' ' +
    'ORDER BY b.verified_time DESC, b.binding_id DESC'
  ).bind(user.platform_user_id).all<PlatformBindingRow>()
  const bindings: PlatformBindingView[] = result.results.map(bindingView)
  return jsonResponse(request, env, { bindingCount: bindings.length, bindings })
}

async function fetchAnchorEnvelope<T>(url: string, instanceToken: string, failureMessage: string): Promise<T> {
  let response: Response
  try {
    response = await fetch(url, {
      headers: { 'Accept': 'application/json', 'Authorization': instanceToken },
      signal: AbortSignal.timeout(15000)
    })
  } catch {
    throw new HttpError(502, 502, failureMessage)
  }
  let payload: T
  try {
    payload = await response.json() as T
  } catch {
    throw new HttpError(502, 502, failureMessage)
  }
  if (!response.ok) {
    throw new HttpError(response.status === 401 || response.status === 403 ? 403 : 502,
      response.status === 401 || response.status === 403 ? 403 : 502, failureMessage)
  }
  return payload
}

async function verifyAnchorImportAuthority(env: Env, user: PlatformUserRow,
  instanceToken: string): Promise<{ anchorBase: string, primaryEmail: string }> {
  const anchorBase = normalizeApiBaseUrl(env.ANCHOR_INSTANCE_API_BASE_URL).toString().replace(/\/$/, '')
  const huaweiEnvelope = await fetchAnchorEnvelope<AnchorHuaweiEnvelope>(
    anchorBase + '/huawei/me', instanceToken, '无法验证主实例华为账号')
  if (huaweiEnvelope.code !== 200 || huaweiEnvelope.data === undefined) {
    throw new HttpError(403, 403, '主实例华为账号验证失败')
  }
  const primaryEmail = textValue(huaweiEnvelope.data.primaryEmail).toLowerCase()
  if (primaryEmail === '') {
    throw new HttpError(403, 403, '主实例未返回绑定邮箱')
  }

  const anchorInstance = await loadInstance(env, ANCHOR_INSTANCE_ID)
  const localUser = await verifyInstanceUser(anchorInstance, instanceToken)
  if (!isAnchorImportAuthority(user.platform_role, localUser, primaryEmail)) {
    throw new HttpError(403, 403, '该主实例账号不是管理员')
  }
  const callerBinding = await env.DB.prepare(
    'SELECT local_email FROM instance_binding WHERE platform_user_id = ? AND instance_id = ? ' +
    'AND status = \'ACTIVE\' AND lower(local_email) = ? LIMIT 1'
  ).bind(user.platform_user_id, ANCHOR_INSTANCE_ID, primaryEmail).first<AnchorAuthorityBindingRow>()
  if (callerBinding === null) {
    throw new HttpError(403, 403, '主实例管理员令牌与当前平台账号不匹配')
  }
  return { anchorBase, primaryEmail }
}

export async function loadLegacyAnchorBindings(anchorBase: string,
  instanceToken: string): Promise<{ list: AnchorAdminBindingItem[], sourceTotal: number }> {
  const pageSize = 100
  const maximumPages = 100
  const byAccountId = new Map<number, AnchorAdminBindingItem>()
  let sourceTotal = 0
  for (let page = 1; page <= maximumPages; page++) {
    const envelope = await fetchAnchorEnvelope<AnchorAdminBindingEnvelope>(
      anchorBase + '/huawei/admin/list?page=' + page + '&size=' + pageSize,
      instanceToken, '无法读取主实例华为账号列表')
    if (envelope.code !== 200 || envelope.data === undefined || !Array.isArray(envelope.data.list)) {
      throw new HttpError(502, 502, '主实例返回的华为账号列表格式无效')
    }
    const pageItems = envelope.data.list
    const reportedTotal = Number(envelope.data.total)
    if (!Number.isFinite(reportedTotal) || reportedTotal < 0) {
      throw new HttpError(502, 502, '主实例返回的华为账号总数无效')
    }
    sourceTotal = Math.floor(reportedTotal)
    for (const item of pageItems) {
      const accountId = Number(item.huaweiAccountId)
      const primaryEmail = textValue(item.primaryEmail)
      if (!Number.isInteger(accountId) || accountId < 1 || primaryEmail === '' || byAccountId.has(accountId)) {
        throw new HttpError(502, 502, '主实例返回的华为账号记录无效')
      }
      byAccountId.set(accountId, item)
    }
    if (pageItems.length === 0 || page * pageSize >= sourceTotal) {
      if (byAccountId.size !== sourceTotal) {
        throw new HttpError(502, 502, '主实例华为账号列表不完整，请稍后重试')
      }
      return { list: Array.from(byAccountId.values()), sourceTotal }
    }
  }
  throw new HttpError(502, 502, '主实例华为账号数量超过单次同步上限')
}

async function handleImportAnchorHuawei(request: Request, env: Env,
  user: PlatformUserRow): Promise<Response> {
  requireSuperAdmin(user)
  const body = await parseBody(request)
  const instanceToken = textValue(body.instanceToken)
  if (instanceToken === '') {
    throw new HttpError(400, 400, '缺少主实例管理员令牌')
  }
  const authority = await verifyAnchorImportAuthority(env, user, instanceToken)
  const source = await loadLegacyAnchorBindings(authority.anchorBase, instanceToken)
  const importMarker = crypto.randomUUID()
  const statements: D1PreparedStatement[] = source.list.map((item) => env.DB.prepare(
    'INSERT INTO legacy_anchor_binding (source_instance_id, source_account_id, masked_huawei_user_id, ' +
    'nick_name, avatar_url, primary_email, profile_update_time, source_create_time, import_marker) ' +
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT(source_instance_id, source_account_id) DO UPDATE SET ' +
    'masked_huawei_user_id = excluded.masked_huawei_user_id, nick_name = excluded.nick_name, ' +
    'avatar_url = excluded.avatar_url, primary_email = excluded.primary_email, ' +
    'profile_update_time = excluded.profile_update_time, source_create_time = excluded.source_create_time, ' +
    'import_marker = excluded.import_marker, update_time = CURRENT_TIMESTAMP'
  ).bind(ANCHOR_INSTANCE_ID, Number(item.huaweiAccountId), textValue(item.huaweiUserId),
    textValue(item.nickName) || null, textValue(item.avatarUrl) || null,
    textValue(item.primaryEmail).toLowerCase(), textValue(item.profileUpdateTime) || null,
    textValue(item.createTime) || null, importMarker))

  // A failed remote read never reaches this point, so an incomplete source response cannot clear prior data.
  // Batches are intentionally bounded to stay below per-invocation D1 statement limits.
  for (let index = 0; index < statements.length; index += 40) {
    await env.DB.batch(statements.slice(index, index + 40))
  }
  await env.DB.batch([
    env.DB.prepare(
      'DELETE FROM legacy_anchor_binding WHERE source_instance_id = ? AND import_marker <> ?'
    ).bind(ANCHOR_INSTANCE_ID, importMarker),
    auditInsert(env, user.platform_user_id, ANCHOR_INSTANCE_ID, 'ANCHOR_LEGACY_IMPORT',
      JSON.stringify({ imported: source.list.length, sourceTotal: source.sourceTotal }))
  ])
  return jsonResponse(request, env, { imported: source.list.length, sourceTotal: source.sourceTotal })
}

async function handleAdminBindings(request: Request, env: Env, user: PlatformUserRow,
  url: URL): Promise<Response> {
  requireSuperAdmin(user)
  const keyword = textValue(url.searchParams.get('keyword'))
  const page = positiveInteger(url.searchParams.get('page'), 1, 1000000)
  const size = positiveInteger(url.searchParams.get('size'), 20, 50)
  const offset = (page - 1) * size
  const pattern = '%' + keyword + '%'
  const commonCte =
    'WITH visible_legacy AS (' +
    'SELECT l.legacy_binding_id, l.source_instance_id, l.masked_huawei_user_id, l.nick_name, l.avatar_url, ' +
    'l.primary_email, COALESCE(NULLIF(l.source_create_time, \'\'), l.create_time) AS source_create_time ' +
    'FROM legacy_anchor_binding l WHERE l.source_instance_id = ? AND NOT EXISTS (' +
    'SELECT 1 FROM instance_binding xb WHERE xb.instance_id = l.source_instance_id ' +
    'AND xb.status = \'ACTIVE\' AND lower(xb.local_email) = lower(l.primary_email))), ' +
    'all_users AS (' +
    'SELECT \'PLATFORM\' AS record_type, p.platform_user_id, p.huawei_user_id, p.nick_name, p.avatar_url, ' +
    'p.platform_role, p.create_time, NULL AS legacy_binding_id, NULL AS source_instance_id, ' +
    'NULL AS legacy_email FROM platform_user p WHERE p.status = \'ACTIVE\' UNION ALL ' +
    'SELECT \'LEGACY\', -l.legacy_binding_id, l.masked_huawei_user_id, l.nick_name, l.avatar_url, ' +
    '\'MEMBER\', l.source_create_time, l.legacy_binding_id, l.source_instance_id, l.primary_email ' +
    'FROM visible_legacy l), ' +
    'filtered_users AS (SELECT au.* FROM all_users au WHERE (? = \'\' ' +
    'OR COALESCE(au.nick_name, \'\') LIKE ? OR au.huawei_user_id LIKE ? OR COALESCE(au.legacy_email, \'\') LIKE ? ' +
    'OR (au.record_type = \'PLATFORM\' AND EXISTS (SELECT 1 FROM instance_binding sb ' +
    'INNER JOIN mail_instance si ON si.instance_id = sb.instance_id ' +
    'WHERE sb.platform_user_id = au.platform_user_id AND sb.status = \'ACTIVE\' AND si.status = \'ACTIVE\' ' +
    'AND (sb.local_email LIKE ? OR si.display_name LIKE ? OR si.origin_host LIKE ?))))) '
  const countRow = await env.DB.prepare(
    commonCte + 'SELECT COUNT(*) AS count_value FROM filtered_users'
  ).bind(ANCHOR_INSTANCE_ID, keyword, pattern, pattern, pattern, pattern, pattern, pattern)
    .first<BindingCountRow>()
  const rows = await env.DB.prepare(
    commonCte +
    ', paged_users AS (SELECT * FROM filtered_users ' +
    'ORDER BY create_time DESC, platform_user_id DESC LIMIT ? OFFSET ?) ' +
    'SELECT * FROM (SELECT pu.platform_user_id, pu.huawei_user_id, pu.nick_name, pu.avatar_url, pu.platform_role, ' +
    'pu.create_time, b.binding_id, b.instance_id, i.display_name, i.api_base_url, i.origin_host, ' +
    'b.local_email, b.local_role_name, b.instance_role, b.verified_time, i.status AS instance_status ' +
    'FROM paged_users pu LEFT JOIN instance_binding b ON b.platform_user_id = pu.platform_user_id ' +
    'AND pu.record_type = \'PLATFORM\' AND b.status = \'ACTIVE\' ' +
    'LEFT JOIN mail_instance i ON i.instance_id = b.instance_id WHERE pu.record_type = \'PLATFORM\' ' +
    'UNION ALL SELECT pu.platform_user_id, pu.huawei_user_id, pu.nick_name, pu.avatar_url, pu.platform_role, ' +
    'pu.create_time, -pu.legacy_binding_id, pu.source_instance_id, ai.display_name, ai.api_base_url, ' +
    'ai.origin_host, pu.legacy_email, \'历史绑定\', \'MEMBER\', pu.create_time, ai.status ' +
    'FROM paged_users pu INNER JOIN mail_instance ai ON ai.instance_id = pu.source_instance_id ' +
    'WHERE pu.record_type = \'LEGACY\') combined_rows ' +
    'ORDER BY combined_rows.create_time DESC, combined_rows.platform_user_id DESC, ' +
    'combined_rows.verified_time DESC, combined_rows.binding_id DESC'
  ).bind(ANCHOR_INSTANCE_ID, keyword, pattern, pattern, pattern, pattern, pattern, pattern, size, offset)
    .all<PlatformAdminBindingRow>()

  const list: PlatformAdminUserView[] = []
  const indexes = new Map<number, number>()
  for (const row of rows.results) {
    let index = indexes.get(row.platform_user_id)
    if (index === undefined) {
      index = list.length
      indexes.set(row.platform_user_id, index)
      list.push({
        platformUserId: row.platform_user_id,
        huaweiUserId: row.huawei_user_id,
        nickName: row.nick_name || '',
        avatarUrl: row.avatar_url || '',
        platformRole: row.platform_role,
        createTime: row.create_time,
        bindingCount: 0,
        bindings: []
      })
    }
    if (row.binding_id !== null && row.instance_id !== null && row.instance_status === 'ACTIVE') {
      list[index].bindings.push({
        bindingId: row.binding_id,
        instanceId: row.instance_id,
        displayName: row.display_name || '',
        apiBaseUrl: row.api_base_url || '',
        originHost: row.origin_host || '',
        localEmail: row.local_email || '',
        localRoleName: row.local_role_name || '',
        instanceRole: row.instance_role || 'MEMBER',
        verifiedTime: row.verified_time || ''
      })
      list[index].bindingCount = list[index].bindings.length
    }
  }
  return jsonResponse(request, env, {
    total: countRow === null ? 0 : countRow.count_value,
    page,
    size,
    list
  })
}

async function handleCreateInstance(request: Request, env: Env, user: PlatformUserRow): Promise<Response> {
  requireSuperAdmin(user)
  const body = await parseBody(request)
  const requestedUrl = textValue(body.apiBaseUrl) || textValue(body.domain)
  const apiUrl = normalizeApiBaseUrl(requestedUrl)
  const probedTitle = await probeInstance(apiUrl.toString().replace(/\/$/, ''))
  const displayName = normalizeInstanceDisplayName(body.displayName, probedTitle || apiUrl.hostname)
  const apiBaseUrl = apiUrl.toString().replace(/\/$/, '')
  const existing = await env.DB.prepare(
    'SELECT instance_id, display_name, api_base_url, origin_host, status FROM mail_instance ' +
    'WHERE origin_host = ? OR api_base_url = ? LIMIT 1'
  ).bind(apiUrl.hostname, apiBaseUrl).first<MailInstanceRow>()
  if (existing !== null) {
    if (existing.status === 'ACTIVE') {
      throw new HttpError(409, 409, '该邮箱服务已经添加')
    }
    await env.DB.batch([
      env.DB.prepare(
        'UPDATE mail_instance SET display_name = ?, api_base_url = ?, origin_host = ?, status = \'ACTIVE\', ' +
        'created_by = ?, update_time = CURRENT_TIMESTAMP WHERE instance_id = ?'
      ).bind(displayName, apiBaseUrl, apiUrl.hostname, user.platform_user_id, existing.instance_id),
      auditInsert(env, user.platform_user_id, existing.instance_id, 'INSTANCE_REACTIVATE', apiUrl.hostname)
    ])
    return jsonResponse(request, env, {
      instanceId: existing.instance_id,
      displayName,
      apiBaseUrl,
      originHost: apiUrl.hostname
    })
  }
  const instanceId = crypto.randomUUID()
  try {
    await env.DB.prepare(
      'INSERT INTO mail_instance (instance_id, display_name, api_base_url, origin_host, created_by) ' +
      'VALUES (?, ?, ?, ?, ?)'
    ).bind(instanceId, displayName, apiBaseUrl, apiUrl.hostname, user.platform_user_id).run()
  } catch {
    throw new HttpError(409, 409, '该邮箱服务已经添加')
  }
  await writeAudit(env, user.platform_user_id, instanceId, 'INSTANCE_CREATE', apiUrl.hostname)
  return jsonResponse(request, env, { instanceId, displayName, apiBaseUrl, originHost: apiUrl.hostname })
}

async function handleUpdateInstance(request: Request, env: Env, user: PlatformUserRow,
  instanceId: string): Promise<Response> {
  requireSuperAdmin(user)
  const instance = await loadInstance(env, instanceId)
  const body = await parseBody(request)
  const displayName = normalizeInstanceDisplayName(body.displayName)
  await env.DB.batch([
    env.DB.prepare(
      'UPDATE mail_instance SET display_name = ?, update_time = CURRENT_TIMESTAMP WHERE instance_id = ? ' +
      'AND status = \'ACTIVE\''
    ).bind(displayName, instanceId),
    auditInsert(env, user.platform_user_id, instanceId, 'INSTANCE_RENAME', JSON.stringify({
      previousDisplayName: instance.display_name,
      displayName
    }))
  ])
  return jsonResponse(request, env, {
    instanceId,
    displayName,
    apiBaseUrl: instance.api_base_url,
    originHost: instance.origin_host
  })
}

async function handleDisableInstance(request: Request, env: Env, user: PlatformUserRow,
  instanceId: string): Promise<Response> {
  requireSuperAdmin(user)
  if (isProtectedInstance(instanceId)) {
    throw new HttpError(409, 409, '主服务不能删除')
  }
  const instance = await loadInstance(env, instanceId)
  await env.DB.batch([
    env.DB.prepare(
      'UPDATE instance_binding SET status = \'DISABLED\', update_time = CURRENT_TIMESTAMP ' +
      'WHERE instance_id = ? AND status = \'ACTIVE\''
    ).bind(instanceId),
    env.DB.prepare(
      'UPDATE mail_instance SET status = \'DISABLED\', update_time = CURRENT_TIMESTAMP ' +
      'WHERE instance_id = ? AND status = \'ACTIVE\''
    ).bind(instanceId),
    auditInsert(env, user.platform_user_id, instanceId, 'INSTANCE_DISABLE', JSON.stringify({
      displayName: instance.display_name,
      originHost: instance.origin_host
    }))
  ])
  return jsonResponse(request, env, { instanceId })
}

async function loadInstance(env: Env, instanceId: string): Promise<MailInstanceRow> {
  const instance = await env.DB.prepare(
    'SELECT instance_id, display_name, api_base_url, origin_host, status FROM mail_instance ' +
    'WHERE instance_id = ? LIMIT 1'
  ).bind(instanceId).first<MailInstanceRow>()
  if (instance === null || instance.status !== 'ACTIVE') {
    throw new HttpError(404, 404, '邮箱实例不存在或已停用')
  }
  return instance
}

async function handleVerifyBinding(request: Request, env: Env, user: PlatformUserRow,
  instanceId: string): Promise<Response> {
  const instance = await loadInstance(env, instanceId)
  const body = await parseBody(request)
  const localUser = await verifyInstanceUser(instance, textValue(body.instanceToken))
  const localEmail = textValue(localUser.email)
  const localRoleName = textValue(localUser.role?.name)
  const instanceRole = await persistInstanceBinding(
    env, user, instance, localUser, 'INSTANCE_BIND_VERIFY', localEmail)
  return jsonResponse(request, env, {
    instanceId,
    displayName: instance.display_name,
    apiBaseUrl: instance.api_base_url,
    localEmail,
    localRoleName,
    instanceRole
  })
}

async function route(request: Request, env: Env): Promise<Response> {
  if (request.method === 'OPTIONS') {
    return emptyResponse(request, env)
  }
  const url = new URL(request.url)
  if (request.method === 'GET' && url.pathname === '/health') {
    return jsonResponse(request, env, { service: 'yunjianji-cloud-control', status: 'ok' })
  }
  if (request.method === 'POST' && url.pathname === '/api/platform/auth/huawei') {
    return handleHuaweiLogin(request, env)
  }
  if (request.method === 'POST' && url.pathname === '/api/platform/auth/huawei-anchor') {
    return handleHuaweiAnchorLogin(request, env)
  }
  if (request.method === 'GET' && url.pathname === '/api/platform/public/instances') {
    return handlePublicInstances(request, env)
  }
  if (request.method === 'POST' && url.pathname === '/api/platform/auth/anchor') {
    return handleAnchorLogin(request, env)
  }
  const user = await requireUser(request, env)
  if (request.method === 'GET' && url.pathname === '/api/platform/instances') {
    return handleListInstances(request, env, user)
  }
  if (request.method === 'GET' && url.pathname === '/api/platform/me/bindings') {
    return handleMyBindings(request, env, user)
  }
  if (request.method === 'GET' && url.pathname === '/api/platform/admin/bindings') {
    return handleAdminBindings(request, env, user, url)
  }
  if (request.method === 'POST' && url.pathname === '/api/platform/admin/import-anchor-huawei') {
    return handleImportAnchorHuawei(request, env, user)
  }
  if (request.method === 'POST' && url.pathname === '/api/platform/admin/instances') {
    return handleCreateInstance(request, env, user)
  }
  const adminInstanceMatch = url.pathname.match(/^\/api\/platform\/admin\/instances\/([^/]+)$/)
  if (adminInstanceMatch !== null) {
    const instanceId = decodeURIComponent(adminInstanceMatch[1])
    if (request.method === 'PUT') {
      return handleUpdateInstance(request, env, user, instanceId)
    }
    if (request.method === 'DELETE') {
      return handleDisableInstance(request, env, user, instanceId)
    }
  }
  const bindingMatch = url.pathname.match(/^\/api\/platform\/instances\/([^/]+)\/verify-binding$/)
  if (request.method === 'POST' && bindingMatch !== null) {
    return handleVerifyBinding(request, env, user, decodeURIComponent(bindingMatch[1]))
  }
  const ownBindingMatch = url.pathname.match(/^\/api\/platform\/bindings\/([^/]+)$/)
  if (request.method === 'DELETE' && ownBindingMatch !== null) {
    return handleDeleteOwnBinding(request, env, user, decodeURIComponent(ownBindingMatch[1]))
  }
  throw new HttpError(404, 404, '接口不存在')
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    try {
      return await route(request, env)
    } catch (error) {
      if (error instanceof HttpError) {
        return jsonResponse(request, env, null, error.status, error.code, error.message)
      }
      console.error('Unhandled platform error', error)
      return jsonResponse(request, env, null, 500, 500, '平台服务暂时不可用')
    }
  }
} satisfies ExportedHandler<Env>

# 云笺集多实例中心服务

该 Worker 只负责华为账号身份、邮箱实例目录、实例绑定关系和作用域角色。邮箱、邮件、密码与实例令牌仍归各 Cloud Mail 实例管理。

## 安全边界

- 邮箱密码由客户端直接发送到目标实例的 `/api/login`，不会发送到本服务。
- 本服务仅短暂使用实例返回的令牌调用该实例 `/api/my/loginUserInfo` 完成身份与管理员权限校验，令牌不会写入 D1。
- D1 仅保存华为身份标识、实例地址、绑定邮箱、已校验角色和审计记录。
- 只有 `SUPER_ADMIN` 能登记实例地址，且仅允许标准 HTTPS 公网域名，避免把服务变成任意请求代理。
- 登录前公开的 `/api/platform/public/instances` 仅返回启用实例的名称、地址与 ID，不包含用户邮箱、绑定信息或角色。
- 华为授权码只发送到配置好的主服务身份桥接接口，不发送给所选第三方邮箱实例；新用户无需在主服务注册邮箱。

## 首次部署

1. 复制 `wrangler.jsonc`，把 `database_id` 替换为新建 D1 的 ID。
2. 安装依赖：`npm install`。
3. 执行远程迁移：`npm run db:migrate:remote`。
4. 执行 `npx wrangler secret put PLATFORM_JWT_SECRET` 写入平台签名 Secret；华为应用凭据继续只保存在主服务，不需要复制到本 Worker。Secret 不写入 `wrangler.jsonc`。
5. 在 `SUPER_ADMIN_HUAWEI_IDS` 配置首位超级管理员的 `anchor:主邮箱地址`，或经可信校验取得的完整华为身份 ID；多个值使用英文逗号分隔。不要使用 `/api/huawei/me` 展示用的脱敏 ID。
6. 执行 `npm run deploy`。

`ANCHOR_INSTANCE_API_BASE_URL` 指向保管华为应用凭据的主服务。平台通过该地址交换和校验一次性授权码，只建立平台身份，不会替新用户创建主服务邮箱。第三方实例仍只需提供兼容的 Cloud Mail 服务，不需要新增华为数据表或接口。

## 登录页实例选择升级

部署顺序：先更新主服务 `mail-worker`（新增 `/api/oauth/huawei/platform-login` 与受登录保护的 `/api/huawei/identity`），再部署本 Worker，最后安装新客户端。本次不新增数据库结构，不需要额外 SQL 迁移；首次部署仍需要应用已有 migrations。不要删除现有数据或修改其他实例的配置。

- `POST /api/platform/auth/huawei-anchor`：请求 `{ authorizationCode }`，返回 `{ token, user, anchor: { status, token, email, bindToken } }`。`anchor.status` 为 `BOUND` 或 `UNBOUND`；未绑定主服务也可使用平台令牌验证并绑定其他实例。
- `POST /api/platform/auth/huawei`：保留为同一安全桥接的兼容入口，不重复消费授权码。
- `POST /api/platform/auth/anchor`：保留旧客户端的主服务会话换取平台会话能力；完整身份由主服务认证后返回，不接受客户端填写的邮箱或华为 ID。
- 老平台用户的脱敏身份只在完整华为身份与已验证主邮箱同时吻合时原地升级，保留原平台用户 ID 和全部实例绑定；重复或冲突身份拒绝自动合并。
- 平台只保存绑定关系，不保存第三方实例密码或会话。退出登录或本地实例会话失效后，访问该第三方实例仍需输入对应密码进行验证。

本地检查：`npm run typecheck`、`npm run test:logic`；主服务另运行 `node --test tests/huawei-platform-login.test.mjs tests/native-mail.test.mjs`。本地测试不代表生产部署或真机验收完成。

`wrangler.jsonc` 是绑定、变量和部署配置的唯一来源；敏感值不得写入该文件或提交到 Git。

## 1.2.2 绑定清理与身份恢复

- 客户端重新获取华为授权时核对完整身份，不替换当前正在使用的第三方邮箱会话；主服务明确返回 `UNBOUND` 后，仅失效的主服务会话与绑定被清除。
- 删除当前邮箱后的中心解绑接口为 `DELETE /api/platform/bindings/:instanceId?email=...&bindingId=...&verifiedTime=...`。三个查询字段均必填，必须来自当前身份已认证获取的绑定记录，按原值 URL 编码。接口只删除完全匹配的旧绑定，防止延迟重试删除后来重新绑定的邮箱。
- 删除响应 `data` 包含 `instanceId` 和数据库当前的 `platformRole`。邮箱派生的管理员角色会随对应绑定清理而更新；显式配置的华为身份超级管理员不受影响。
- 客户端保存不含凭据的待清理记录，可在账号中心重试。第三方邮箱删除与中心解绑不是跨服务原子事务；删除失败不会预先解绑。远端成功与本地记录落盘之间遭遇进程崩溃，仍可能需要重新验证并处理残留绑定。
- 本轮修复仍需更新主服务 `mail-worker` 和本 Worker，无新增 SQL 迁移。部署顺序同上；源代码修改、本地测试及安装包构建不代表线上部署完成。

完整本地回归：本目录执行 `npm run typecheck`、`npm run test:logic` 和 `npm run test:runtime`；主服务执行 `node --test tests/huawei-platform-login.test.mjs tests/huawei-account-lifecycle.test.mjs tests/native-mail.test.mjs`。

`test:runtime` 在本地 Miniflare/workerd 中运行真实 Worker，使用隔离 D1 与模拟上游，不访问生产账号。登录身份请求必须使用 `redirect: 'manual'` 并显式拒绝 3xx；Workers 运行时不支持 `redirect: 'error'`，仅使用 Node fetch mock 无法检出此类兼容性错误。

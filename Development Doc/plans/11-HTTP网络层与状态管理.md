# F11 - HTTP 网络层 + 状态管理

> **前置条件**：前面所有页面 UI 完成
> **目标**：网络层封装 + 全局状态

## 任务清单

### 任务 1：HTTP 客户端
- [ ] HttpClient 封装（使用 @kit.NetworkKit 的 http 模块）
- [ ] 请求拦截（自动附带 Authorization Bearer Token）
- [ ] 响应拦截（401 跳转登录、网络异常提示）
- [ ] 错误统一处理（重试逻辑、用户提示）
- [ ] 基础 URL 配置：`https://riordon.xyz/api`
- [ ] 注意：ArkTS 不支持 axios，需用原生 http.createHttp()

### 任务 2：API 模块
- [ ] `api/EmailApi.ets` — 邮件相关接口
- [ ] `api/AuthApi.ets` — 登录/注册/Token
- [ ] `api/AccountApi.ets` — 账号管理
- [ ] `api/AdminApi.ets` — 管理后台

### 任务 3：状态管理
- [ ] Token 持久化（Preferences）
- [ ] 用户信息全局状态
- [ ] 当前账号状态

## 验收标准
- ✅ HTTP 请求正常发起和接收
- ✅ Token 自动附加和过期处理
- ✅ API 模块结构清晰
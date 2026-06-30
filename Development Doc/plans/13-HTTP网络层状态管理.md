# 13 — HTTP 网络层 + 状态管理

> **前置条件**：01-12 全部完成（页面 UI 画完）
> **对标原项目**：`axios/` + `request/` + `store/`

## 任务清单

### 任务 1：HttpClient 封装
- [ ] `api/HttpClient.ets` — 单例 HTTP 客户端
- [ ] 自动拼接 baseURL（Constants.API_URL）
- [ ] 自动附加 Authorization header（从 AppStorage 取 Token）
- [ ] 统一响应解析（JSON → ApiResponse<T>）
- [ ] 401 拦截 → 清除 Token → 跳转登录
- [ ] 超时设置（30 秒）
- [ ] 请求重试（指数退避，最多 3 次）

### 任务 2：API 模块编写（对标原项目 15 个 request 文件）
- [ ] `api/AuthApi.ets` — login / register / logout
- [ ] `api/EmailApi.ets` — list / send / delete / read / latest / attList
- [ ] `api/AccountApi.ets` — list / add / delete / setName / setAllReceive / setAsTop
- [ ] `api/UserApi.ets` — list / add / delete / setPwd / setStatus / setType / resetSendCount
- [ ] `api/AdminApi.ets` — allEmail(list/delete/batchDelete), analysis(echarts)
- [ ] `api/RoleApi.ets` — add / list / delete / tree / set / setDefault
- [ ] `api/RegKeyApi.ets` — add / list / delete / clear / history
- [ ] `api/MyApi.ets` — userInfo / delete / update
- [ ] `api/StarApi.ets` — star / unstar / list
- [ ] `api/SettingApi.ets` — get / set / websiteConfig / setBackground
- [ ] `api/PublicApi.ets` — genToken / emailList / addUser

### 任务 3：全局状态管理
- [ ] `store/UserStore.ets` — 用户信息、Token（AppStorage 实现）
- [ ] `store/ThemeStore.ets` — 主题切换（深色/浅色/跟随系统）
- [ ] `store/AccountStore.ets` — 当前选中账号
- [ ] `store/AppState.ets` — 全局应用状态（网络状态、未读数）

### 任务 4：类型定义
- [ ] `common/Types.ets` — 所有接口类型定义
- [ ] 对标原项目 entity 结构：Email, Account, User, Role, Perm, Setting, RegKey, Attachment, Star
- [ ] API 响应类型：ApiResponse<T>, PageData<T>

### 任务 5：工具函数
- [ ] `common/Utils.ets` — 日期格式化、邮箱校验、文件大小格式化
- [ ] `common/StorageUtils.ets` — Preferences 读写封装

## 验收标准
- ✅ HttpClient 单例可用
- ✅ 所有 API 模块编译通过
- ✅ 全局状态读写正常
- ✅ 类型定义完整

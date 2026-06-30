# 14 — 接入真实 API

> **前置条件**：13 完成（网络层就绪）
> **目标**：所有页面从 Mock 数据切换到真实 API 数据

## 任务清单

### 任务 1：登录/注册接入
- [ ] 登录按钮 → AuthApi.login(email, password)
- [ ] 注册按钮 → AuthApi.register(email, password, regCode?)
- [ ] 成功后存储 Token + 跳转主页
- [ ] 失败显示错误消息
- [ ] Token 过期自动跳转登录

### 任务 2：收件箱接入
- [ ] 页面加载 → EmailApi.fetchList(accountId, type, size, emailId)
- [ ] 下拉刷新 → EmailApi.latest(emailId)
- [ ] 上拉加载 → EmailApi.fetchList（分页游标）
- [ ] 搜索 → EmailApi.fetchList（带搜索参数）
- [ ] 删除 → EmailApi.deleteEmails(ids)

### 任务 3：邮件详情接入
- [ ] 进入详情 → EmailApi.fetchList（取单条邮件详情）
- [ ] 附件列表 → EmailApi.attList(emailId)
- [ ] 标记已读 → EmailApi.markRead(emailIds)
- [ ] 删除 → EmailApi.deleteEmails([emailId])

### 任务 4：写邮件接入
- [ ] 发送 → EmailApi.send(composeData)
- [ ] 附件上传 → 先上传文件到 OSS，获取 key → 附带在 send body
- [ ] 发送成功 → 跳回收件箱 + 刷新列表
- [ ] 发送失败 → 显示错误信息

### 任务 5：账号管理接入
- [ ] 列表 → AccountApi.fetchList()
- [ ] 添加 → AccountApi.addEmail(email, name)
- [ ] 删除 → AccountApi.deleteAccount(accountId)
- [ ] 设置别名 → AccountApi.setName(accountId, name)
- [ ] 全部接收 → AccountApi.setAllReceive(accountId, flag)
- [ ] 置顶 → AccountApi.setAsTop(accountId)

### 任务 6：管理后台接入
- [ ] 用户管理 → UserApi.list / add / delete / setPwd / setStatus / setType
- [ ] 全局邮件 → AdminApi.allEmailList / delete / batchDelete
- [ ] 角色权限 → RoleApi.list / add / delete / set
- [ ] 数据分析 → AdminApi.analysis / echarts
- [ ] 注册码 → RegKeyApi.list / add / delete

### 任务 7：设置接入
- [ ] 外观 → SettingApi.get / set
- [ ] 背景图 → SettingApi.setBackground
- [ ] 网站配置 → SettingApi.websiteConfig

### 任务 8：数据持久化增强
- [ ] 邮件列表缓存到 RelationalStore（离线可用）
- [ ] Token 持久化（Preferences）
- [ ] 用户设置持久化（Preferences）
- [ ] 草稿持久化（Preferences）

## 验收标准
- ✅ 所有页面使用真实 API 数据
- ✅ 登录态正常维护
- ✅ 分页加载正确
- ✅ 错误处理完善（网络断开、401、500）
- ✅ 离线缓存兜底

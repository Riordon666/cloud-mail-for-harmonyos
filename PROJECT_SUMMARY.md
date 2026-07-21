# Cloud Mail for HarmonyOS · 项目总结

> 最后更新：2026-07-11 | 编译状态：BUILD SUCCESSFUL | API 23 / SDK 6.1.0

## 项目概况

| 项 | 值 |
|---|-----|
| 名称 | Cloud Mail |
| 类型 | 鸿蒙原生邮件客户端 (ArkUI + ArkTS) |
| 后端 | Cloudflare Workers · `mail.riordon.xyz` |
| 本地路径 | `D:\cloud_mail_for_harmonyos` |
| 远程仓库 | `https://github.com/Riordon666/cloud-mail-for-harmonyos` |
| 分支 | `main` |

## 代码结构

```
mail/src/main/ets/
├── api/                    # API 调用层 (5 个)
│   ├── AccountApi.ets      # 副邮箱 CRUD
│   ├── AdminApi.ets        # 管理员接口
│   ├── AuthApi.ets         # 登录/注册/会话
│   ├── EmailApi.ets        # 邮件收发/星标/删除/已读
│   └── SettingsApi.ets     # 系统设置/个人设置
├── common/                 # 基础设施 (12 个)
│   ├── Constants.ets       # 全局常量(API URL/边距/圆角/字号/断点)
│   ├── HttpClient.ets      # HTTP 网络层 (封装 @kit.NetworkKit)
│   ├── MailModels.ets      # 数据模型 (MailItem/MailAttachment 等)
│   ├── SessionService.ets  # 会话管理 (authToken 持久化)
│   ├── AuthService.ets     # 认证服务 (登录/注册/刷新/登出)
│   ├── MailService.ets     # 邮件服务 (收件箱/已发送/星标/草稿/已读)
│   ├── DraftService.ets    # 本地草稿 (preferences 持久化)
│   ├── AccountService.ets  # 副邮箱管理
│   ├── AdminService.ets    # 管理后台服务
│   ├── SystemSettingsService.ets  # 系统设置服务
│   ├── MailListDataSource.ets     # LazyForEach 邮件列表数据源
│   ├── DraftListDataSource.ets    # LazyForEach 草稿列表数据源
│   └── PushService.ets     # 推送服务基础封装
├── components/             # 公用组件 (8 个)
│   ├── EmailCard.ets       # 邮件卡片
│   ├── AccountCard.ets     # 账号卡片
│   ├── AvatarBar.ets       # 头像组件
│   ├── Badge.ets           # 未读角标
│   ├── EmptyState.ets      # 空态占位
│   ├── LoadingView.ets     # 加载状态
│   ├── SearchBar.ets       # 搜索栏
│   └── SectionHeader.ets   # 分组标题
├── pages/                  # 页面 (16 个)
│   ├── Index.ets           # 入口 · HdsNavigation + HdsTabs 5个Tab
│   ├── AuthPage.ets        # 登录/注册页
│   ├── InboxPage.ets       # 收件箱 (LazyForEach)
│   ├── SentPage.ets        # 已发送 (LazyForEach)
│   ├── DraftsPage.ets      # 草稿箱 (LazyForEach)
│   ├── StarredPage.ets     # 星标邮件 (LazyForEach)
│   ├── DetailPage.ets      # 邮件详情(附件下载/上下翻页)
│   ├── ComposePage.ets     # 写邮件(附件上传/草稿保存)
│   ├── SettingsPage.ets    # 个人设置(头像/昵称/链接/外观/管理入口)
│   ├── AccountsPage.ets    # 副邮箱管理
│   ├── SystemSettingsPage.ets     # 系统配置
│   ├── UserManagementPage.ets     # 用户管理(管理员)
│   ├── GlobalMailPage.ets         # 全局邮件(管理员)
│   ├── RoleManagementPage.ets     # 角色权限管理(管理员)
│   ├── AnalyticsPage.ets          # 数据分析(管理员)
│   ├── RegistrationCodePage.ets   # 注册码管理(管理员)
│   └── NotFoundPage.ets   # 404 兜底
├── mailability/
│   └── MailAbility.ets     # UIAbility 入口 · 颜色模式/推送/服务初始化
└── mailbackupability/
    └── MailBackupAbility.ets  # 备份恢复扩展
```

## 关键技术决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 导航框架 | HdsTabs (非 HdsNavigation 为主容器) | 无标题栏沉浸式 |
| 路由 | NavPathStack + navDestination builder | 声明式路由，Index.ets 统一管理 |
| 网络层 | 自封装 HttpClient (基于 @kit.NetworkKit) | 不用 axios，统一 token/错误处理 |
| 状态管理 | @State/@StorageLink/@StorageProp + AppStorage | ArkTS 原生方案 |
| 持久化 | @kit.ArkData preferences | 鸿蒙推荐 KV 存储 |
| 列表性能 | LazyForEach + IDataSource | 虚拟滚动，60fps |
| 深色模式 | $r() 资源引用 + preferences 持久化 | 主题切换无闪烁 |
| 图标 | SymbolGlyph (系统符号) + $r() 引用 | 统一设计语言 |

## 开发规范 (AI 必须遵守)

1. **所有 .ets 文件必须 UTF-8 with BOM**
2. **API 23 限制**：禁用模板字符串(反引号)、`any`/`unknown` 类型、`getContext()`、`uiMaterial`/`systemMaterial`
3. **颜色用 $r() 引用**，不要硬编码色值
4. **边距统一用 Constants.PADDING_EDGE**
5. **分页提交**：每个逻辑块单独 commit，commit message 格式 `type(scope): 中文描述 — 英文关键词`
6. **不要提交 `Development Doc/` 目录下的文档**
7. **不要未经用户要求就 commit 或 push**

## 构建命令

```powershell
& "D:\DevEco Studio\tools\node\node.exe" `
  "D:\DevEco Studio\tools\hvigor\bin\hvigorw.js" `
  --mode module `
  -p module=mail@default `
  -p product=default `
  -p requiredDeviceType=phone `
  assembleHap `
  --analyze=normal --parallel --incremental --daemon
```

## 当前状态

- **F01-F14 全部完成**，BUILD SUCCESSFUL
- 只有中文，未做国际化
- 已完成：登录注册、收件箱/已发送/星标/草稿箱、邮件详情/写邮件、个人设置、账号管理、管理后台(5页)、主题切换、LazyForEach 性能优化、平板断点适配、404 页面、备份恢复、推送基础封装
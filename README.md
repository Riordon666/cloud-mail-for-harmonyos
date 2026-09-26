<div align="center">
<img src="https://readme-typing-svg.vercel.app/?lines=%E2%9C%A8Riordon666%E2%9C%A8;%E2%9C%89%EF%B8%8FCloud%20Mail%20for%20HarmonyOS%E2%9C%89%EF%B8%8F;%E2%9A%A1Made%20with%20ArkTS%E2%9A%A1;%F0%9F%92%ABThanks%20for%20maillab%F0%9F%92%AB;&font=Fira%20Code&center=true&width=540&height=50&duration=4000&pause=1000&color=00D9FF&vCenter=true&size=28">


<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=6,11,20&height=200&section=header&text=Cloud%20Mail%20for%20HarmonyOS&fontSize=50&fontAlignY=35&animation=twinkling&fontColor=fff" />

<h1 align="center">✉️Cloud Mail for HarmonyOS <sup><small>v1.2.2</small></sup></h1>

**鸿蒙原生邮件客户端** · 基于 ArkUI + ArkTS 从零构建

为 HarmonyOS 打造的沉浸式邮件体验，采用 HDS 设计语言，深度适配深色模式与平板断点布局。

![Platform](https://img.shields.io/badge/Platform-HarmonyOS-0A0A0A?logo=harmonyos&logoColor=white)
![API](https://img.shields.io/badge/API-23+-317AF7)
![SDK](https://img.shields.io/badge/SDK-6.1.0+-5B9AF9)
![License](https://img.shields.io/badge/License-MIT-6BCB77)
![Status](https://img.shields.io/badge/状态-持续开发优化中-yellow)

[功能特性](#-功能特性) · [技术架构](#-技术架构) · [功能全景](#-功能全景) · [快速开始](#-快速开始)

</div>

<div align="center">

<img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif" width="100%" height="3px" />

</div>

## 📖 项目简介

**Cloud Mail for HarmonyOS（云笺集）** 是面向 **[Cloud Mail](https://github.com/maillab/cloud-mail)** 邮件服务的 **HarmonyOS 原生客户端**，支持接入多个兼容实例、华为账号登录与邮箱绑定。

这不是简单的网页套壳，而是基于 **ArkUI 声明式 UI** 与 **ArkTS** 语言、采用华为 **HDS（HarmonyOS Design System）** 组件库从零重写的原生客户端——沉浸式全屏体验、HdsTabs 底部导航、LazyForEach 虚拟滚动、断点式平板适配，一个都不少。

- 🔗 **主服务**：Cloudflare Workers · [Riordon's Cloud Mail](https://mail.riordon.xyz)
- 🎯 **目标**：提供原生邮件收发、账号管理和实例切换体验，并非网页版所有功能的完整移植。
- 🆕 **当前版本**：1.2.2（versionCode `1020002`），新增登录页切换实例，完善账号与绑定生命周期，并优化登录响应速度。详见 [1.2.2 更新日志](release-assets/RELEASE_NOTES-1.2.2.md)。

<div align="center">

<img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif" width="100%" height="3px" />

</div>

## ✨ 功能特性

### 📨 邮件核心
- **收件箱 / 已发送 / 星标 / 草稿箱** 四大分类，邮件列表采用 LazyForEach 按需构建
- **统一收件箱**：集中查看当前账号主邮箱与副邮箱收到的邮件
- **邮件详情**：附件下载、上一封/下一封翻页、星标、删除、底部悬浮工具栏
- **写邮件**：收件人、附件上传、本地草稿自动保存，草稿及附件按实例与账号隔离
- **验证码**：支持服务端返回的验证码展示与一键复制；是否识别取决于实例能力及配置

当前不支持发送抄送/密送；包含这类字段的旧草稿会提示处理，不会静默丢弃收件人后发送。

### 👤 用户体系
- **华为账号登录**：展示授权头像与昵称，支持绑定不同实例的主邮箱
- **登录前选实例**：新用户可以先选择邮箱服务，再绑定已有邮箱或注册，不再必须先注册主服务邮箱
- **邮箱服务切换**：按实例保存会话；切换未登录实例时先验证，不提前退出当前邮箱
- **账号中心**：查看已绑定主邮箱、注册时间、收发与星标邮件统计，进入账号管理与账号设置
- **账号管理**：主邮箱、副邮箱及用途子地址；账号设置支持修改密码与删除当前实例账户
- **会话安全**：使用 AssetStoreKit 保存令牌，重新授权时校验身份，处理退出、过期与删除后的绑定清理

### 🛡️ 分级管理
- **实例管理员**：仅管理自己拥有权限的实例，包括用户、邮件、角色、数据分析、注册码与系统设置
- **平台超级管理员**：登记、重命名或删除实例，集中查看华为账号跨实例的邮箱绑定
- 管理入口随当前权限显示，服务端仍独立校验权限；平台权限不等于其他实例的管理员权限

### 🎨 设计与体验
- **沉浸式全屏**：`expandSafeArea` 内容延伸至状态栏，无分隔线
- **HDS 设计语言**：HdsTabs + HdsNavigation + SymbolGlyph 系统符号
- **外观与主题**：跟随系统 / 浅色 / 深色三档直接切换，资源适配并保存偏好
- **半模态页面**：账号中心、关于与更新日志，统一标题栏光感与模糊效果
- **平板适配**：断点系统（sm/md/lg），内容区最大宽度约束
- **系统启动窗口**：`startWindowIcon` + `startWindowBackground` 无缝启动体验
- **通知说明**：华为 Push Kit 通知尚未接入，不提供后台实时推送

<div align="center">

<img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif" width="100%" height="3px" />

</div>

## 🏗️ 技术架构

| 维度 | 选型 | 说明 |
|------|------|------|
| **UI 框架** | ArkUI + HDS | 原生导航、沉浸光感标题栏与半模态页面 |
| **路由** | NavPathStack + navDestination | 声明式路由，Index 统一管理 |
| **网络层** | 自封装 HttpClient | 基于 `@kit.NetworkKit`，统一 token/错误处理 |
| **状态管理** | @State / @StorageLink + AppStorage | ArkTS 原生方案 |
| **偏好与元数据** | preferences（`@kit.ArkData`） | 主题、实例目录及非敏感状态 |
| **令牌存储** | AssetStoreKit | 按实例保存会话令牌，独立保存平台令牌 |
| **草稿存储** | 应用私有文件目录 | 草稿与附件按实例、邮箱隔离 |
| **列表性能** | LazyForEach + IDataSource | 按需构建邮件列表项 |
| **图标** | SymbolGlyph（系统符号） | 统一设计语言，自适应主题 |
| **多实例中心** | Cloudflare Workers + D1 | 华为身份、实例目录、绑定关系与作用域角色 |

### 多实例与后端边界

邮箱内容、密码校验与邮箱会话归各 Cloud Mail 实例管理；本仓库的 `cloud-control-worker` 负责平台身份和绑定目录，不集中存储第三方邮箱密码或实例令牌。第三方实例的密码由客户端直接交给目标实例验证，退出登录或本地会话失效后可能需要重新输入。

接入地址由平台超级管理员登记，普通用户选择已启用的兼容实例。新增实例不需要部署华为账号表，但必须提供兼容的 Cloud Mail API；验证码、用途子地址等功能也取决于对应实例能力。主服务保管华为应用凭据并提供身份桥接，不能只部署手机客户端就获得完整华为登录能力。

1.2.2 的登录页实例选择与绑定清理需要配套更新主服务和中心 Worker。部署顺序、接口与安全边界见 [中心服务说明](cloud-control-worker/README.md)；网页版主服务代码不在本仓库中。

### 代码分层

```
mail/src/main/ets/
├── api/                 # API 接口层
│   ├── AuthApi          #   登录/注册/会话
│   ├── EmailApi         #   邮件收发/星标/删除
│   ├── AccountApi       #   副邮箱 CRUD
│   ├── AdminApi         #   管理后台接口
│   ├── PlatformApi      #   多实例中心接口
│   ├── ProfileApi       #   账号信息、统计与账户操作
│   └── SettingsApi      #   系统/个人设置
├── common/              # 基础设施与业务服务
│   ├── HttpClient       #   HTTP 网络层
│   ├── *Service         #   各业务服务（Auth/Mail/Draft/...）
│   ├── LoginInstanceService # 登录实例选择、验证与激活
│   ├── SecureTokenStore #   安全令牌存储
│   ├── MailModels       #   数据模型
│   └── *DataSource      #   LazyForEach 数据源
├── components/          # 公用组件、账号中心与登录实例选择器
├── pages/               # 页面
│   ├── Index            #   入口 · 5 Tab 导航
│   ├── AuthPage         #   登录/注册
│   ├── Inbox/Sent/...   #   邮件各页
│   └── *Management      #   管理后台
├── mailability/         # UIAbility 入口
└── mailbackupability/   # 备份恢复扩展
```

<div align="center">

<img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif" width="100%" height="3px" />

</div>

## 🖼️ 功能全景


<!-- 截图区域：取消下方注释并放入对应图片即可
<p align="center">
  <img src="screenshots/inbox.png" width="270" alt="收件箱"/>
  <img src="screenshots/detail.png" width="270" alt="邮件详情"/>
  <img src="screenshots/compose.png" width="270" alt="写邮件"/>
</p>
-->

| 模块 | 功能 |
|------|------|
| 📥 收件箱 | 搜索、未读角标、左滑标记已读/星标/删除、LazyForEach 虚拟滚动 |
| 📤 已发送 | 发送记录浏览、LazyForEach 虚拟滚动 |
| ⭐ 星标 | 星标邮件集中查看、取消星标、LazyForEach 虚拟滚动 |
| 📝 草稿箱 | 本地草稿保存、继续编辑、左滑删除、LazyForEach 虚拟滚动 |
| 📄 邮件详情 | 附件下载、上一封/下一封翻页、星标、删除、底部悬浮工具栏 |
| ✏️ 写邮件 | 收件人、附件上传、草稿自动保存与附件恢复 |
| 🔐 登录注册 | 华为账号授权、登录前选择实例、邮箱绑定与注册、会话恢复 |
| ⚙️ 个人设置 | 华为头像与昵称、账号中心、关于与更新日志、外观主题 |
| 👥 账号管理 | 主邮箱与副邮箱管理、用途子地址、修改密码与删除账户 |
| 🌐 邮箱服务 | 多实例绑定与切换、独立会话、超级管理员管理实例 |
| 🛡️ 管理后台 | 实例内用户/邮件/角色/分析/注册码/系统设置；平台华为绑定查询 |
| 🎨 主题切换 | 深色/浅色/跟随系统三档，持久化偏好 |
| 📱 平板适配 | BreakpointSystem 断点布局（sm/md/lg）、内容区最大宽度约束 |
| 🔢 验证码 | 邮件验证码展示与一键复制（需实例支持） |
| 🚫 404 兜底 | NotFoundPage 未知路由兜底 |

<div align="center">

<img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif" width="100%" height="3px" />

</div>

## 🚀 快速开始

### 环境要求

- **DevEco Studio**（支持下列 SDK 的版本）
- **HarmonyOS SDK** `6.1.0`（API `23`）
- 手机模拟器或真机

### 运行

1. 使用 **DevEco Studio** 打开项目根目录
2. 确认已安装 HarmonyOS SDK `6.1.0`（API `23`）
3. 选择 `mail` 模块和 `default` Product
4. 配置自己的调试签名及授权设备，连接设备后点击 ▶️ 运行

本机证书、私钥、签名口令和 `.dev.vars` 不应提交到 Git；克隆仓库后需要自行配置签名。华为登录还要求应用标识、签名与服务端华为账号配置匹配。

### 命令行构建

```powershell
$env:JAVA_HOME = "D:\DevEco Studio\jbr"
$env:DEVECO_SDK_HOME = "D:\DevEco Studio\sdk"

& "D:\DevEco Studio\tools\node\node.exe" `
  "D:\DevEco Studio\tools\hvigor\bin\hvigorw.js" `
  --mode module `
  -p module=mail@default `
  -p product=default `
  assembleHap `
  --no-daemon
```

按实际安装目录调整以上路径。发布 APP 使用 `publish` Product，并先配置自己的发布签名：

```powershell
& "D:\DevEco Studio\tools\node\node.exe" `
  "D:\DevEco Studio\tools\hvigor\bin\hvigorw.js" `
  --mode project -p product=publish assembleApp --no-daemon
```

HAP 输出在 `mail/build/<product>/outputs/default/`，APP 输出在 `build/outputs/<product>/`。签名成功后再使用对应的 `*-signed.hap` / `*-signed.app`。

### 本地回归测试

测试使用 Node.js 24，并通过 TypeScript 转译业务逻辑；不替代 Hvigor 编译或真机 UI 验收。

```powershell
npm --prefix cloud-control-worker install
$env:TYPESCRIPT_PATH = (Resolve-Path cloud-control-worker/node_modules/typescript).Path
$env:ARKTS_TEST_TYPESCRIPT = $env:TYPESCRIPT_PATH
$releaseTestFiles = Get-ChildItem tests -Filter '*.test.cjs' | ForEach-Object FullName
node --test $releaseTestFiles
npm --prefix cloud-control-worker run typecheck
npm --prefix cloud-control-worker run test:logic
npm --prefix cloud-control-worker run test:runtime
```

中心服务的运行时测试使用本地 Miniflare/workerd、隔离 D1 与模拟上游，不操作生产数据库。

### 📲 安装与发布包

安装包以 [Releases](https://github.com/Riordon666/cloud-mail-for-harmonyos/releases) 中实际发布的附件和说明为准。`APP` 用于应用市场提交；`HAP` 能否直接侧载取决于签名类型、授权设备与系统校验，发布签名 HAP 不保证可直接调试安装。

开发调试请使用匹配设备的调试签名 HAP。同签名覆盖安装通常可保留数据；不要为解决签名不匹配而直接卸载，以免丢失本地草稿与登录状态。构建产物与本机签名材料不会随源代码提交。


<div align="center">

<img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif" width="100%" height="3px" />

</div>

## 📄 License

MIT License · 本项目仅供学习交流

<div align="center">

<img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif" width="100%" height="3px" />

</div>

<div align="center">

**如果这个项目对你有帮助，欢迎 ⭐ Star**

Made with ArkTS for HarmonyOS

</div>

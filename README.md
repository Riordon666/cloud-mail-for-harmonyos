<div align="center">
<img src="https://readme-typing-svg.vercel.app/?lines=%E2%9C%A8Riordon666%E2%9C%A8;%E2%9C%89%EF%B8%8FCloud%20Mail%20for%20HarmonyOS%E2%9C%89%EF%B8%8F;%E2%9A%A1Made%20with%20ArkTS%E2%9A%A1;%F0%9F%92%ABThanks%20for%20maillab%F0%9F%92%AB;&font=Fira%20Code&center=true&width=540&height=50&duration=4000&pause=1000&color=00D9FF&vCenter=true&size=28">


<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=6,11,20&height=200&section=header&text=Cloud%20Mail%20for%20HarmonyOS&fontSize=50&fontAlignY=35&animation=twinkling&fontColor=fff" />

<h1 align="center">✉️Cloud Mail for HarmonyOS <sup><small>v0.1</small></sup></h1>

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

**Cloud Mail for HarmonyOS** 是一款将 **[Cloud Mail](https://github.com/maillab/cloud-mail)**（原 Vue 3 + Cloudflare Workers 邮件服务）完整移植为 **HarmonyOS 原生应用** 的邮件客户端。

这不是简单的网页套壳，而是基于 **ArkUI 声明式 UI** 与 **ArkTS** 语言、采用华为 **HDS（HarmonyOS Design System）** 组件库从零重写的原生客户端——沉浸式全屏体验、HdsTabs 底部导航、LazyForEach 虚拟滚动、断点式平板适配，一个都不少。

- 🔗 **后端**：Cloudflare Workers · [Riordon's Cloud Mail](https://mail.riordon.xyz) 
- 🎯 **目标**：完整的邮件收发、用户体系、管理后台，原生级流畅、正在持续开发优化中~

<div align="center">

<img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif" width="100%" height="3px" />

</div>

## ✨ 功能特性

### 📨 邮件核心
- **收件箱 / 已发送 / 星标 / 草稿箱** 四大分类，LazyForEach 虚拟滚动保证 60fps
- **邮件详情**：附件下载、上一封/下一封翻页、星标、删除、底部悬浮工具栏
- **写邮件**：收件人/抄送/密送、附件上传、本地草稿自动保存（preferences 持久化）

### 👤 用户体系
- 登录 / 注册 / 会话刷新，authToken 持久化
- 副邮箱管理（增删改）
- 个人设置：头像、昵称、链接、外观主题

### 🛡️ 管理后台（5 页）
- 用户管理 · 全局邮件 · 角色权限管理 · 数据分析 · 注册码管理

### 🎨 设计与体验
- **沉浸式全屏**：`expandSafeArea` 内容延伸至状态栏，无分隔线
- **HDS 设计语言**：HdsTabs + HdsNavigation + SymbolGlyph 系统符号
- **深色模式**：`$r()` 资源引用，主题切换无闪烁，preferences 记忆偏好
- **平板适配**：断点系统（sm/md/lg），内容区最大宽度约束
- **系统启动窗口**：`startWindowIcon` + `startWindowBackground` 无缝启动体验
- **Push Kit 推送**：基础封装就绪，需 AppGallery Connect 配置后启用

<div align="center">

<img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif" width="100%" height="3px" />

</div>

## 🏗️ 技术架构

| 维度 | 选型 | 说明 |
|------|------|------|
| **UI 框架** | ArkUI + HdsTabs | 沉浸式无标题栏底部导航 |
| **路由** | NavPathStack + navDestination | 声明式路由，Index 统一管理 |
| **网络层** | 自封装 HttpClient | 基于 `@kit.NetworkKit`，统一 token/错误处理 |
| **状态管理** | @State / @StorageLink + AppStorage | ArkTS 原生方案 |
| **持久化** | preferences（`@kit.ArkData`） | KV 存储，会话/草稿/主题 |
| **列表性能** | LazyForEach + IDataSource | 虚拟滚动，大数据量不卡顿 |
| **图标** | SymbolGlyph（系统符号） | 统一设计语言，自适应主题 |
| **推送** | Push Kit | 新邮件实时通知 |

### 代码分层

```
mail/src/main/ets/
├── api/                 # API 接口层（5 个）
│   ├── AuthApi          #   登录/注册/会话
│   ├── EmailApi         #   邮件收发/星标/删除
│   ├── AccountApi       #   副邮箱 CRUD
│   ├── AdminApi         #   管理后台接口
│   └── SettingsApi      #   系统/个人设置
├── common/              # 基础设施（12 个）
│   ├── HttpClient       #   HTTP 网络层
│   ├── *Service         #   各业务服务（Auth/Mail/Draft/...）
│   ├── MailModels       #   数据模型
│   ├── *DataSource      #   LazyForEach 数据源
│   └── PushService      #   Push Kit 推送
├── components/          # 公用组件（8 个）
├── pages/               # 页面（16 个）
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
| ✏️ 写邮件 | 收件人/抄送/密送、附件上传、草稿自动保存 |
| 🔐 登录注册 | 会话持久化、authToken 自动刷新 |
| ⚙️ 个人设置 | 头像上传、昵称、链接管理、外观主题（浅/深/跟随系统） |
| 👥 账号管理 | 副邮箱增删查 |
| 🛡️ 管理后台 | 用户管理/全局邮件/角色权限/数据分析/注册码（5 页） |
| 🎨 主题切换 | 深色/浅色/跟随系统、preferences 持久化、$r() 无缝切换 |
| 📱 平板适配 | BreakpointSystem 断点布局（sm/md/lg）、内容区最大宽度约束 |
| 📡 Push Kit | 推送基础封装就绪（需 AppGallery Connect 配置后启用） |
| 🔄 备份恢复 | MailBackupAbility 扩展，preferences 数据持久化 |
| 🚫 404 兜底 | NotFoundPage 未知路由兜底 |

<div align="center">

<img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4500-a447-11eb-908a-139a6edaec5c.gif" width="100%" height="3px" />

</div>

## 🚀 快速开始

### 环境要求

- **DevEco Studio**（最新稳定版）
- **HarmonyOS SDK** `6.1.0`（API `23`）
- 手机模拟器或真机

### 运行

1. 使用 **DevEco Studio** 打开项目根目录
2. 确认已安装 HarmonyOS SDK `6.1.0`（API `23`）
3. 选择 `mail` 模块和 `default` Product
4. 连接设备后点击 ▶️ 运行

### 命令行构建

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

### 📲 安装体验（无需开发环境）

没有 DevEco Studio？可以直接下载 [Releases](https://github.com/Riordon666/cloud-mail-for-harmonyos/releases) 中的 `.hap` 安装包，使用下面的工具侧载到手机即可体验。

#### 安装工具

**小白调试助手**（Auto-Installer）—— 免费、跨平台的鸿蒙应用安装调试工具，**本仓库安装包均推荐使用此工具安装。**

- 🔗 **下载链接**：[likuai2010/auto-installer Releases](https://github.com/likuai2010/auto-installer/releases/latest)
- 📄 **教程文档**：[点击下载 PDF 教程](https://github.com/Zitann/HarmonyOS-Haps/raw/refs/heads/main/assets/guide.pdf)
- 🎬 **视频教程**：[B 站观看](https://www.bilibili.com/video/BV1hkZ7YnEMd/)


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

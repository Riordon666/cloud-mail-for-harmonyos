<div align="center">

# ✉️ Cloud Mail for HarmonyOS

**鸿蒙原生邮件客户端** · 基于 ArkUI + ArkTS 从零构建

为 HarmonyOS 打造的沉浸式邮件体验，采用 HDS 设计语言，深度适配深色模式与平板断点布局。

![Platform](https://img.shields.io/badge/Platform-HarmonyOS-0A0A0A?logo=harmonyos&logoColor=white)
![API](https://img.shields.io/badge/API-23-317AF7)
![SDK](https://img.shields.io/badge/SDK-6.1.0-5B9AF9)
![License](https://img.shields.io/badge/License-MIT-6BCB77)
![Status](https://img.shields.io/badge/状态-开发中-yellow)

[功能特性](#-功能特性) · [技术架构](#-技术架构) · [功能全景](#-功能全景) · [快速开始](#-快速开始)

</div>

---

## 📖 项目简介

**Cloud Mail** 是一款将 Cloud Mail（原 Vue 3 + Cloudflare Workers 邮件服务）完整移植为 **HarmonyOS 原生应用** 的邮件客户端。

这不是简单的网页套壳，而是基于 **ArkUI 声明式 UI** 与 **ArkTS** 语言、采用华为 **HDS（HarmonyOS Design System）** 组件库从零重写的原生客户端——沉浸式全屏体验、HdsTabs 底部导航、LazyForEach 虚拟滚动、断点式平板适配，一个都不少。

- 🔗 **后端**：Cloudflare Workers · `https://mail.riordon.xyz`
- 🎯 **目标**：完整的邮件收发、用户体系、管理后台，原生级流畅、正在开发优化中~

---

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
- **蓝色全屏启动闪屏**：系统启动窗口 + 应用内闪屏无缝衔接
- **Push Kit 推送**：新邮件实时推送

---

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
├── common/              # 基础设施（13 个）
│   ├── HttpClient       #   HTTP 网络层
│   ├── *Service         #   各业务服务（Auth/Mail/Draft/...）
│   ├── MailModels       #   数据模型
│   ├── *DataSource      #   LazyForEach 数据源
│   └── PushService      #   Push Kit 推送
├── components/          # 公用组件（8 个）
├── pages/               # 页面（17 个）
│   ├── Index            #   入口 · 5 Tab 导航
│   ├── AuthPage         #   登录/注册
│   ├── Inbox/Sent/...   #   邮件各页
│   └── *Management      #   管理后台
├── mailability/         # UIAbility 入口
└── mailbackupability/   # 备份恢复扩展
```

---

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
| 📥 收件箱 | 搜索、未读角标、左滑标记已读/删除、下拉刷新 |
| 📤 已发送 | 发送记录浏览 |
| ⭐ 星标 | 星标邮件集中查看 |
| 📝 草稿箱 | 本地草稿保存、继续编辑、左滑删除 |
| 📄 邮件详情 | 附件下载、上下翻页、星标、删除 |
| ✏️ 写邮件 | 收件人/抄送/密送、附件上传、草稿自动保存 |
| 🔐 登录注册 | 会话持久化、自动刷新 |
| ⚙️ 个人设置 | 头像、昵称、外观主题 |
| 👥 账号管理 | 副邮箱增删改 |
| 🛡️ 管理后台 | 用户/全局邮件/角色/数据分析/注册码 |

---

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

---

## 📐 开发规范

- `.ets` 文件统一 **UTF-8 with BOM** 编码
- 颜色通过 **`$r()`** 资源引用，维护浅色与深色双主题
- 页面水平边距统一使用 **`Constants.PADDING_EDGE`**（16vp）
- **API 23 限制**：禁用模板字符串、`any`/`unknown`、`getContext()`、`uiMaterial`
- 提交信息格式：`type(scope): 中文描述 — 英文关键词`

---

## 📄 License

MIT License · 本项目仅供学习交流

---

<div align="center">

**如果这个项目对你有帮助，欢迎 ⭐ Star**

Made with ArkTS for HarmonyOS

</div>

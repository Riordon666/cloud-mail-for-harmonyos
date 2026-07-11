# Cloud Mail for HarmonyOS

> Cloud Mail for HarmonyOS 是将 Cloud Mail 移植为 HarmonyOS 原生应用的 ArkUI/ArkTS 邮件客户端，当前以 Mock 数据完成核心邮件工作流的 UI 骨架。

## 项目简介

本项目基于 ArkUI 与 ArkTS 重构原 Cloud Mail 的邮件客户端体验，使用 HDS 组件实现沉浸式底部导航、邮件列表、详情、写邮件及常用邮箱页面。当前阶段优先完成页面与交互骨架，网络请求、真实登录和远端数据同步将在后续阶段接入。

## 当前功能

- 收件箱：搜索、未读状态、左滑标记已读与删除。
- 邮件详情：发件人与附件信息、上一封/下一封、星标、删除，以及底部操作工具栏。
- 写邮件：收件人、抄送、密送、主题和正文编辑。
- 邮件分类：星标邮件、已发送邮件、草稿箱；草稿可继续编辑并支持左滑删除。
- 设计体验：HDS 底部导航、深色主题资源、空状态组件和右下角写邮件入口。

## 技术栈

- HarmonyOS SDK `6.1.0`，兼容 API `23`
- ArkUI + ArkTS
- `@kit.UIDesignKit`（HDS 组件）
- `@kit.ArkUI`

## 项目结构

```text
mail/
  src/main/ets/
    common/       # 常量与 Mock 数据
    components/   # 可复用 UI 组件
    pages/        # 邮件页面与导航入口
    mailability/  # UIAbility 入口
  src/main/resources/ # 颜色、字符串与图标资源
Development Doc/      # 本地开发计划与阶段记录（不上传远程）
```

## 开始使用

1. 使用 DevEco Studio 打开项目根目录。
2. 确认已安装 HarmonyOS SDK `6.1.0`（API `23`）及手机或模拟器运行环境。
3. 选择 `mail` 模块和 `default` Product 后运行应用。

如已配置 DevEco Studio 的命令行工具，也可以在项目根目录构建：

```powershell
hvigorw assembleHap --mode module -p module=mail@default -p product=default -p requiredDeviceType=phone
```

## 开发状态

| 阶段 | 状态 | 内容 |
|------|------|------|
| F01 | ✅ | UI 框架与沉浸式底部导航 |
| F02 | ✅ | 收件箱搜索、列表与左滑操作 |
| F03 | ✅ | 邮件详情与写邮件 |
| F04 | ✅ | 星标邮件、发件箱与草稿箱 |
| F05+ | ⏳ | 登录注册、账号管理、网络层与真实 API 接入 |

## 开发约定

- `.ets` 文件使用 UTF-8 with BOM 编码。
- 颜色通过 `$r()` 资源引用，并维护浅色与深色主题。
- 页面水平边距统一使用 `Constants.PADDING_EDGE`。
- `Development Doc/` 仅作本地开发记录，已由 `.gitignore` 排除，不会上传到远程仓库。

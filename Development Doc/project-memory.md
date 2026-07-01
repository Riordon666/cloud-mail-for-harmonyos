# Cloud Mail for HarmonyOS · 项目记忆

> 最后更新：2026-07-01

## 项目概况

| 项目 | 说明 |
|------|------|
| 名称 | Cloud Mail for HarmonyOS |
| 类型 | 鸿蒙原生邮件客户端 |
| 技术栈 | ArkUI + ArkTS + HdsTabs |
| API 版本 | 23 (兼容 SDK 26) |
| 远程仓库 | https://github.com/Riordon666/cloud-mail-for-harmonyos |
| 本地路径 | D:/cloud_mail_for_harmonyos |
| 后端 | Cloudflare Workers (riordon.xyz) |

## 开发进度

| 阶段 | 状态 | 完成日期 | 文档 |
|------|------|----------|------|
| F01 - UI框架与沉浸光感 | ✅ 完成 | 2026-06-30 | finished/F01-UI框架与沉浸光感.md |
| F02 - 收件箱完善 | ✅ 完成 | 2026-06-30 | finished/F02-收件箱完善.md |
| 03 - 邮件详情与写邮件 | ⬜ 待开始 | - | plans/03-邮件详情与写邮件.md |
| 04 - 星标发件箱草稿箱 | ⬜ 待开始 | - | plans/04-星标发件箱草稿箱.md |
| 05 - 登录注册 | ⬜ 待开始 | - | plans/05-登录注册.md |
| 06 - 账号管理 | ⬜ 待开始 | - | plans/06-账号管理.md |
| 07 - 个人设置 | ⬜ 待开始 | - | plans/07-个人设置.md |
| 08 - 用户管理 | ⬜ 待开始 | - | plans/08-用户管理.md |
| 09 - 全局邮件与角色权限 | ⬜ 待开始 | - | plans/09-全局邮件与角色权限.md |
| 10 - 数据分析与注册码 | ⬜ 待开始 | - | plans/10-数据分析与注册码.md |
| 11 - HTTP网络层与状态管理 | ⬜ 待开始 | - | plans/11-HTTP网络层与状态管理.md |
| 12 - 全页面接入API | ⬜ 待开始 | - | plans/12-全页面接入API.md |
| 13 - 主题切换与国际化 | ⬜ 待开始 | - | plans/13-主题切换与国际化.md |
| 14 - 最终打磨 | ⬜ 待开始 | - | plans/14-最终打磨.md |

## 关键技术决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 导航框架 | HdsTabs (非 HdsNavigation) | 无标题栏页面，避免标题栏遮挡触摸区域 |
| 全屏沉浸 | expandSafeArea(TOP) | 内容延伸到状态栏下，无分隔线 |
| Tab 图标 | BottomTabBarStyle + SymbolGlyphModifier | 全局可用，无需额外 import |
| 搜索组件 | Search (官方) | 自带搜索图标和清除按钮 |
| ForEach key | id + unread | key 变化触发重建，确保已读状态刷新 |
| 编码 | UTF-8 with BOM | 鸿蒙 .ets 文件必须 UTF-8 BOM |
| API 前缀 | () 资源引用 | 适配深色模式自动切换 |

## 设计 Token

| Token | 值 | 用途 |
|------|-----|------|
| 主色 | #317AF7 | 按钮、选中态、强调 |
| 背景 | #F1F3F5 | 页面背景 |
| 卡片 | #FFFFFF | 卡片/列表项背景 |
| 水平边距 | 16vp | Constants.PADDING_EDGE |
| 圆角 | 15vp | 卡片圆角 |
| 悬浮球大小 | 56×56 | FAB 写信按钮 |

## 开发规范

- 所有 .ets 文件必须 UTF-8 with BOM
- 使用 () 引用资源颜色，不要硬编码
- 边距统一使用 Constants.PADDING_EDGE
- 不要用 HdsNavigation 作为容器（除非需要标题栏）
- API 23 限制：无模板字符串(反引号)、无 uiMaterial、无 systemMaterial (FAB)

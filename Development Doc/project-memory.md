# Cloud Mail for HarmonyOS · 项目记忆

> 最后更新：2026-07-02 16:45

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
| 03 - 邮件详情与写邮件 | ✅ 完成 | - | plans/03-邮件详情与写邮件.md |
| 04 - 星标发件箱草稿箱 | 🟡 进行中 | - | plans/04-星标发件箱草稿箱.md |
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
| API 前缀 | $r() 资源引用 | 适配深色模式自动切换 |

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
- 使用 $r() 引用资源颜色，不要硬编码
- 边距统一使用 Constants.PADDING_EDGE
- 不要用 HdsNavigation 作为容器（除非需要标题栏）
- API 23 限制：无模板字符串(反引号)、无 uiMaterial、无 systemMaterial (FAB)

## 排坑记录 (2026-07-02)

### 坑1：HdsNavDestination 内容垂直居中
- **现象**：Scroll 内部 Column 的内容垂直居中，即使设了 alignItems(Start) + justifyContent(Start) 也没用
- **根因**：titleMode(HdsNavDestinationTitleMode.MINI) + bindToScrollable 组合导致。当内容不足以填满 Scroll 剩余空间时，系统会自动把内容推到垂直中心，以便标题栏折叠动画有合理起点
- **验证**：把内容精简到 3 行 Text 依然居中；注释掉 bindToScrollable 依然居中；注释掉 titleMode 依然居中（说明这两个属性只要 HdsNavDestination 被用作 NavDestination 子页面就会触发此行为）
- **解决方案**：在 Scroll 内部 Column 的最后一个子元素放 Blank().layoutWeight(1)，让 Blank 吃掉所有剩余空间，把实际内容推到顶部
- **注意**：不要用 Blank().height(固定值)，必须用 layoutWeight(1) 来动态填充
- **对比**：ComposePage 不居中是因为内容多（收件人/抄送/密送/主题/正文/发送按钮）天然填满了 Scroll

### 坑2：底部悬浮工具栏
- **现状**：用 Stack({ alignContent: Alignment.Bottom }) 包裹 Scroll + 底部 Row，Row 设 backgroundColor("#CCFFFFFF") 半透明
- **尝试过的方案**：
  - ImmersiveMaterial + .systemMaterial() → SDK 26 才支持，API 23 编译报错
  - backgroundBlurStyle(BlurStyle.COMPONENT_THICK) → 可以用但效果一般
  - shadow + borderRadius → 可以加但不能连写太多属性，容易导致内容布局异常
- **建议**：悬浮工具栏先用 Stack + 半透明背景做，后续升级 SDK 26 后再改用 ImmersiveMaterial

### 坑3：PowerShell Set-Content 会导致 UTF-8 中文乱码
- **原因**：PowerShell 的 Set-Content 默认用系统编码（不是 UTF-8），会把中文全变成乱码
- **解决方案**：用 [System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false)) 写入文件
- **$false 参数含义**：不带 BOM 的 UTF-8 编码（鸿蒙 .ets 文件需要 BOM，后续再确认）

### 坑4：git show 恢复文件时会混入 stderr
- 不要用 `git show HASH:path 2>&1 | Out-File` 恢复文件，会混入 git 的 stderr 输出
- 用 `git checkout HASH -- path` 但在工作区文件不在 commit 中时会失败
- 最可靠的方式：手动重写文件，用 WriteAllText 写入
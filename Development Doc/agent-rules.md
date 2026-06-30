# Agent 开发规则

> 本文件定义了 Agent（Claude Code）参与 Cloud Mail 鸿蒙移植项目的开发工作流。

## 目录结构

```
Development Doc/
├── agent-rules.md        ← 本文件（Agent 开发规则）
├── 00-总开发计划.md        ← 总览 + 依赖关系
├── plans/                ← 开发计划文档
│   ├── 01-项目结构重构.md
│   ├── 02-完善设计系统.md
│   └── ...
├── finished/             ← 已完成步骤总结
│   ├── F01-项目结构重构.md
│   └── ...
└── 开发者文档/            ← 技术参考
```

## 文件命名规则

| 前缀 | 位置 | 含义 |
|------|------|------|
| `01-` `02-` ... | `plans/` | 开发计划文档 |
| `F01-` `F02-` ... | `finished/` | 已完成步骤的总结文档 |
| 无前缀 | 根目录 | 参考/规则/索引文档 |

## 开发工作流

```
用户给出下一步指令
    ↓
Agent 阅读 plans/XX-xxx.md 计划文档
    ↓
Agent 按计划逐步实施开发
    ↓
完成后，Agent 编写 finished/FXX-xxx.md 总结文档
    ↓
Agent 告知用户本步骤完成的内容
    ↓
用户审核 → 确认后进入下一步
```

## 每次开发的强制要求

1. **开始前**：阅读 `plans/XX-步骤名.md` 计划文档
2. **开发中**：严格按照计划文档的任务清单执行
3. **完成后**：编写 `finished/FXX-步骤名.md`，包含：
   - 本步骤完成了什么
   - 新建/修改了哪些文件
   - 遇到的问题和解决方案
   - 下一步建议
4. **提交代码**：每个步骤完成后做一次 git commit

## 代码规范

### 目录结构约定
```
mail/src/main/ets/
├── common/          # 常量、类型定义、工具函数
├── api/             # HTTP 请求封装（对标原项目 request/）
├── store/           # 全局状态管理（对标原项目 store/）
├── components/      # 可复用 UI 组件
├── pages/           # 页面组件（每个页面一个文件/目录）
├── mailability/     # MailAbility 入口
└── mailbackupability/  # 备份扩展
```

### 命名约定
- **文件名**：PascalCase（`LoginPage.ets`, `EmailCard.ets`）
- **组件名**：PascalCase（`struct InboxView`）
- **方法名**：camelCase（`fetchEmails()`）
- **常量**：UPPER_SNAKE_CASE（`API_URL`）
- **状态变量**：camelCase（`@State currentTab: number`）

### 必须遵守
- ✅ 所有组件放在独立文件中（不在一个文件堆砌多个 `@Component`）
- ✅ 使用 `@Builder` 提取可复用 UI 片段
- ✅ Mock 数据统一放在 `common/MockData.ets`
- ✅ 颜色使用 `$r('app.color.xxx')` 资源引用，不硬编码
- ✅ 尺寸使用 `Constants.ets` 的 Token，不硬编码数字
- ❌ 不要在组件内直接调用 HTTP（应通过 api/ 层）
- ❌ 不要在 ListItem 的 `@Builder` 中使用重量级组件

### 提交信息格式
```
step(XX): 步骤简述

- 完成内容1
- 完成内容2
```

## 当前状态

- **已完成的步骤**：01-项目结构重构（见 `finished/F01-项目结构重构.md`）
- **下一步**：02-完善设计系统（见 `plans/02-完善设计系统.md`）
- **保留内容**：
  - HdsNavigation + HdsTabs 沉浸光感导航栏（5 个 Tab 底部悬浮）
  - 悬浮写邮件球（FAB，智感握姿自适应）
  - Constants.ets 设计 Token
  - 浅色/深色资源色板
  - MailAbility.ets 入口
  - MailBackupAbility.ets 备份模板

# Agent 开发规则

> 本文件定义了 Agent（Claude Code）参与 Cloud Mail 鸿蒙移植项目的开发工作流。

## 目录结构

```
Development Doc/
├── project-memory.md      ← 🔑 所有 Agent 必读第一份文档
├── agent-rules.md         ← 本文件（Agent 开发规则）
├── 00-总开发计划.md        ← 总览 + 依赖关系
├── plans/                ← 开发计划文档
│   ├── 01-项目结构重构.md
│   └── ...
├── finished/             ← 已完成步骤总结
│   └── F01-xxx.md
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
Agent 启动
    ↓
① 先读 project-memory.md（了解项目全貌 + 当前状态）
    ↓
② 读 plans/XX-xxx.md 计划文档
    ↓
③ 按计划逐步实施开发
    ↓
④ 写 finished/FXX-xxx.md 完成总结
    ↓
⑤ 更新 project-memory.md（进度 + 下一步 + 设计决策）
    ↓
⑥ git commit & push
    ↓
⑦ 告知用户完成内容
```

## 每次开发的强制要求

1. **开始前**：必读 `project-memory.md`，然后读 `plans/XX-步骤名.md`
2. **开发中**：严格按照计划文档的任务清单执行
3. **完成后**：
   - 编写 `finished/FXX-步骤名.md`
   - **更新 `project-memory.md`**（进度表格 + 最后更新日期 + 下一步行动 + 新设计决策）
4. **提交代码**：每个步骤完成后做一次 git commit

## 强制纪律

- ❌ **禁止未经允许 push 代码**：必须等用户明确说"push"或"推送"后才能执行 `git push`
- ❌ **禁止未经允许删除文件**：删除任何文件前必须征得用户同意
- ❌ **禁止频繁 commit**：每个 Step 完成后做一次 commit，不要每改一个文件就提交

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

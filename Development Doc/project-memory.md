# Project Memory

> **给新 Agent / 新开发者的第一份文档。每次开发完成后更新。**
> 最后更新：2026-06-30（Step 01 完成后）

---

## 一、这是什么项目

将 [Cloud Mail](https://github.com/maillab/cloud-mail)（Vue 3 + Cloudflare Workers 全栈邮件系统）移植为 **HarmonyOS NEXT 原生邮件客户端**（ArkUI + ArkTS）。

- **原项目后端**：`https://riordon.xyz/api`（已部署运行，Hono + D1 + KV + R2 + Resend）
- **原项目前端**：`cloud-mail/mail-vue/`（Vue 3 + Element Plus + Pinia + Vue Router，仅作参考）
- **HarmonyOS 项目**：`mail/`（ArkUI + ArkTS，API 26，目标 phone + tablet）

---

## 二、当前代码结构

```
mail/src/main/ets/
├── common/
│   ├── Constants.ets          # 设计 Token（颜色/字号/间距/圆角）
│   └── MockData.ets           # 所有 mock 数据（邮件、账号）
├── components/
│   ├── AvatarBar.ets          # 头像（Circle + 首字母 + 哈希取色）
│   ├── EmailCard.ets          # 邮件卡片（展示型，@Prop 接收）
│   └── AccountCard.ets        # 账号卡片
├── pages/
│   ├── Index.ets              # 入口：HdsNavigation + 5 Tab + 悬浮写邮件球
│   ├── InboxPage.ets          # 收件箱（搜索 + 邮件列表）
│   ├── SentPage.ets           # 已发送（空状态）
│   ├── DraftsPage.ets         # 草稿箱（空状态）
│   ├── StarredPage.ets        # 星标邮件（空状态）
│   ├── SettingsPage.ets       # 个人设置（头像 + 菜单）
│   └── ComposePage.ets        # 写邮件（收件人/主题/正文 + 返回）
├── mailability/
│   └── MailAbility.ets        # 主 Ability 入口
└── mailbackupability/
    └── MailBackupAbility.ets  # 备份扩展（模板）
```

---

## 三、导航结构

```
5 个 Tab（HdsNavigation + HdsTabs，底部悬浮）：
  收件箱 | 已发送 | 草稿箱 | 星标邮件 | 个人设置
  
悬浮球（FAB）：
  写邮件（56vp 圆形，主色+阴影，Stack BottomEnd 对齐，智感握姿自适应）
```

**Tab 图标**（SymbolGlyph 系统图标）：
| Tab | 默认图标 | 选中图标 (fill) |
|-----|---------|----------------|
| 收件箱 | `envelope` | `envelope_fill` |
| 已发送 | `paperplane` | `paperplane_fill` |
| 草稿箱 | `doc` | `doc_fill` |
| 星标邮件 | `star` | `star_fill` |
| 个人设置 | `person_crop_circle` | `person_crop_circle_fill` |
| 悬浮球 | `square_and_pencil` | — |

---

## 四、开发进度

| 步骤 | 状态 | 完成日期 | 总结文档 |
|------|------|---------|---------|
| 01-项目结构重构 | ✅ 完成 | 2026-06-30 | `finished/F01-项目结构重构.md` |
| 02-完善设计系统 | ⏳ 下一步 | — | — |
| 03~16 | ⏳ 待开始 | — | — |

**详细计划**：见 `plans/` 目录

---

## 五、关键设计决策

1. **导航框架**：使用 `@kit.UIDesignKit` 的 HdsNavigation + HdsTabs（不要改用原生 Navigation/Tabs）
2. **沉浸光感**：ScrollEffectType.IMMERSIVE_GRADIENT_BLUR + MaterialType.ADAPTIVE
3. **写邮件入口**：悬浮球（FAB），不是 Tab 页（对标 HDS 核心操作栏模式）
4. **组件通信**：展示型组件用 `@Prop`（单向），页面级状态用 `@State`
5. **颜色**：必须用 `$r('app.color.xxx')` 资源引用，禁止硬编码色值
6. **尺寸**：必须用 `Constants.ets` 的 Token
7. **Mock 数据**：全部放在 `common/MockData.ets`，通过接口定义类型
8. **设计风格**：严格跟随 HDS 官方设计规范，不用花哨的 AI 生成样式

---

## 六、不能改的东西

- ❌ HdsNavigation + HdsTabs 框架
- ❌ `barFloatingStyle` 的沉浸光感配置
- ❌ 悬浮写邮件球的位置和样式
- ❌ `MailAbility.ets` 和 `MailBackupAbility.ets`
- ❌ `.gitignore`

---

## 七、Git 规范

- **提交格式**：`step(XX): 简述\n\n- 完成项1\n- 完成项2`
- **分支**：直接推 main（暂无 PR 流程）
- **远程**：`https://github.com/Riordon666/cloud-mail-for-harmonyos`

---

## 八、开发文档索引

| 文档 | 位置 |
|------|------|
| Agent 规则 | `agent-rules.md` |
| 总开发计划 | `00-总开发计划.md` |
| 计划文档 | `plans/01-xxx.md` ~ `plans/16-xxx.md` |
| 完成总结 | `finished/F01-xxx.md` ~ |
| 技术参考：项目总览 | `开发者文档/01-项目总览.md` |
| 技术参考：ArkTS 语法 | `开发者文档/02-ArkTS语言速查.md` |
| 技术参考：ArkUI 组件 | `开发者文档/03-ArkUI组件大全.md` |
| 技术参考：状态管理 | `开发者文档/04-状态管理.md` |
| 技术参考：导航路由 | `开发者文档/05-导航与路由.md` |
| 技术参考：数据持久化 | `开发者文档/06-数据持久化.md` |
| 技术参考：文件管理 | `开发者文档/07-文件管理.md` |
| 技术参考：网络请求 | `开发者文档/08-网络请求.md` |
| 技术参考：程序框架 | `开发者文档/09-程序框架.md` |
| 技术参考：设计系统 | `开发者文档/10-设计系统.md` |

---

## 九、下一步行动

**Step 02 — 完善设计系统**（详见 `plans/02-完善设计系统.md`）：
1. 补全 Constants.ets（缺失 Token）
2. 补全浅色/深色色板（补充 warning, info 等语义色）
3. 丰富 MockData.ets
4. 封装通用组件（EmptyState, LoadingView, SectionHeader）
5. Tab 图标改为 SymbolGlyph → ✅ 已在 Step 01 完成

---

> **Agent 注意**：每完成一个 Step 或做任何重大改动后，必须更新此文件：
> 1. 更新"开发进度"表格
> 2. 更新"最后更新"日期
> 3. 更新"下一步行动"
> 4. 如有新设计决策，补入"关键设计决策"

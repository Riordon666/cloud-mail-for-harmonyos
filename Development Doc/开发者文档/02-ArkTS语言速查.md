# 02 — ArkTS 语言速查

> ArkTS = TypeScript 超集 + ArkUI 专用装饰器 + 严格模式

## 基础类型（与 TS 一致）

```typescript
// 基本类型
let name: string = 'admin@riordon.xyz'
let count: number = 0
let isLoading: boolean = false
let data: string[] = ['a', 'b', 'c']        // 数组
let tuple: [string, number] = ['admin', 1]   // 元组
let anything: Object = {}                    // Object 类型

// 联合类型
let status: 'loading' | 'done' | 'error' = 'loading'

// 接口定义
interface EmailData {
  emailId: number
  subject: string
  content: string
  unread: boolean
  attList?: Attachment[]     // 可选属性
}

// 枚举（推荐用常量对象替代数字枚举）
const EmailType = {
  RECEIVE: 0,
  SEND: 1
} as const
```

## 核心装饰器

| 装饰器 | 用途 | 对标原项目 |
|--------|------|-----------|
| `@Entry` | 标记页面入口组件 | 页面组件 |
| `@Component` | 标记可复用组件 | Vue 组件 |
| `@State` | 组件内响应式状态 | `ref()` / `reactive()` |
| `@Prop` | 父→子单向传递 | `props` |
| `@Link` | 父↔子双向绑定 | `v-model` |
| `@Provide` | 祖先提供数据 | `provide()` |
| `@Consume` | 后代消费数据 | `inject()` |
| `@StorageLink` | 双向绑定 AppStorage | Pinia + persist |
| `@StorageProp` | 单向绑定 AppStorage | Pinia (只读) |
| `@Observed` | 标记可观察类 | — |
| `@ObjectLink` | 观察对象属性变化 | `storeToRefs()` |
| `@Builder` | 声明可复用 UI 函数 | `<template>` 片段 |
| `@BuilderParam` | 传递 UI 构建器为参数 | slot |
| `@Watch` | 监听状态变化回调 | `watch()` |
| `@Extend` | 扩展组件属性 | CSS class |

## 装饰器使用示例

```typescript
// @State — 组件本地状态
@State currentTab: number = 0
@State toEmail: string = ''
@State emails: EmailData[] = []

// @StorageProp — 全局状态（如深色模式）
@StorageProp('colorMode') colorMode: number = 0

// @Builder — 可复用 UI
@Builder TabBarItem(text: string, index: number) {
  Column() {
    Text(text).fontSize(11)
  }
}

// @Watch — 监听变化
@State @Watch('onEmailChange') email: string = ''
onEmailChange() { /* email 变化时触发 */ }
```

## 条件与循环渲染

```typescript
// if/else（对标 v-if）
if (this.unread) {
  Circle().width(8).height(8).fill(Color.Blue)
}

// 三元表达式（对标 :class）
.fontColor(this.isActive ? Color.Blue : Color.Gray)

// ForEach（对标 v-for）
ForEach(this.emails, (item: EmailData, index: number) => {
  ListItem() { this.EmailCard(item) }
}, (item: EmailData) => item.emailId.toString())  // key 生成器（必填）

// LazyForEach（对标虚拟滚动，长列表必用）
LazyForEach(this.dataSource, (item: EmailData) => {
  ListItem() { this.EmailCard(item) }
}, (item: EmailData) => item.emailId.toString())
```

## 资源引用

```typescript
// 颜色资源
.fontColor($r('app.color.text_primary'))

// 字符串资源
Text($r('app.string.module_desc'))

// 图片资源
Image($r('app.media.logo'))

// 原始颜色值
.backgroundColor('#FF6B6B')
.fontColor(Color.White)
```

## 常用 API 导入

```typescript
import { window } from '@kit.ArkUI'            // 窗口管理
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit'  // Ability
import { hilog } from '@kit.PerformanceAnalysisKit'  // 日志
import { hdsMaterial, HdsNavigation, HdsTabs } from '@kit.UIDesignKit'  // 设计套件
```

## 关键限制

- ❌ 不支持 `any` / `unknown`（严格模式强制类型）
- ❌ 不支持 `Function` 类型（必须用具体函数签名）
- ❌ 装饰器不能用于 `export default class`
- ❌ `Date.now()` / `Math.random()` 在某些上下文中不可用

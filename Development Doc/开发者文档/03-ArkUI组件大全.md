# 03 — ArkUI 组件大全

> 声明式 UI：`Component(params) { ... child components ... }.attr1().attr2()`

## 布局组件

### Column（垂直布局）
```typescript
Column({ space: 12 }) {         // space: 子元素间距
  Text('标题')
  Text('内容')
}
.width('100%')
.height('100%')
.padding({ left: 16, right: 16, top: 8, bottom: 8 })
.backgroundColor($r('app.color.background'))
.alignItems(HorizontalAlign.Start)   // 水平对齐: Start/Center/End
.justifyContent(FlexAlign.Center)    // 垂直对齐: Start/Center/End/SpaceBetween
```

### Row（水平布局）
```typescript
Row() {
  Text('左侧').layoutWeight(1)
  Text('右侧')
}
.width('100%')
.padding(16)
.justifyContent(FlexAlign.SpaceBetween)
.alignItems(VerticalAlign.Center)
```

### Stack（层叠布局）
```typescript
Stack() {
  Circle().width(44).height(44).fill('#317AF7')   // 底层
  Text('A').fontSize(18).fontColor(Color.White)    // 上层
}
.alignContent(Alignment.Center)  // 子元素对齐方式
```

### Flex（弹性布局，功能 > Row/Column）
```typescript
Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) { ... }
```

### Blank（空白占位）
```typescript
Row() {
  Text('左')
  Blank()    // 把后面的元素推到最右
  Text('右')
}
```

### Divider（分割线）
```typescript
Divider().strokeWidth(0.5).color($r('app.color.divider'))
```

---

## 文本组件

### Text
```typescript
Text('邮件标题')
  .fontSize(16)
  .fontWeight(FontWeight.Bold)       // Bold / Medium / Normal / Regular
  .fontColor($r('app.color.text_primary'))
  .maxLines(1)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
  .textAlign(TextAlign.Start)        // Start / Center / End
  .lineHeight(24)
  .letterSpacing(0.5)
  .decoration({ type: TextDecorationType.Underline })
```

### TextInput（单行输入）
```typescript
TextInput({ placeholder: '搜索邮件', text: this.keyword })
  .type(InputType.Email)              // Normal / Password / Email / Number
  .placeholderColor('#C7C7CC')
  .fontColor('#1A1A1A')
  .backgroundColor(Color.Transparent)
  .layoutWeight(1)
  .height(44)
  .borderRadius(18)
  .onChange((value: string) => { this.keyword = value })
  .onSubmit(() => { /* 回车搜索 */ })
```

### TextArea（多行输入——邮件正文）
```typescript
TextArea({ placeholder: '写邮件正文...', text: this.content })
  .placeholderColor($r('app.color.text_tertiary'))
  .fontColor($r('app.color.text_primary'))
  .backgroundColor(Color.Transparent)
  .layoutWeight(1)    // 填满剩余空间
  .onChange((v: string) => { this.content = v })
```

### SymbolGlyph（系统 SF Symbols 图标）
```typescript
SymbolGlyph('sys.symbol.envelope_fill')
  .fontSize(24)
  .fontColor([Color.Blue])

// 邮件相关图标:
// sys.symbol.envelope / .envelope_fill       → 邮件
// sys.symbol.star / .star_fill                → 星标
// sys.symbol.paperplane / .paperplane_fill    → 发送
// sys.symbol.paperclip                        → 附件
// sys.symbol.trash                            → 删除
// sys.symbol.person_crop_circle               → 头像
// sys.symbol.chevron_left / .chevron_right    → 返回/前进
// sys.symbol.arrowshape.turn.up.left_fill     → 回复
// sys.symbol.arrowshape.turn.up.forward       → 转发
// sys.symbol.bell                             → 通知
// sys.symbol.paintbrush                       → 外观
// sys.symbol.lock                             → 隐私/安全
// sys.symbol.chart_bar                        → 数据分析
// sys.symbol.ticket                           → 注册码
```

---

## 列表组件

### List + ListItem
```typescript
List({ scroller: this.scroller }) {
  ForEach(this.emails, (item: EmailData) => {
    ListItem() {
      this.EmailCard(item)       // 自定义 @Builder
    }
    .margin({ left: 16, right: 16, top: 4, bottom: 4 })
    .swipeAction({                // 左滑操作
      end: {
        builder: () => { this.SwipeDelete(item) },
        onAction: () => { this.deleteEmail(item) }
      }
    })
  })
}
.width('100%')
.layoutWeight(1)
.scrollBar(BarState.Off)          // Off / Auto / On
.edgeEffect(EdgeEffect.Spring)    // 滚动到边界弹性效果
.divider({ strokeWidth: 0.5, color: '#E5E5EA' })
```

### ListItemGroup（分组列表，适合设置页）
```typescript
List() {
  ListItemGroup({ header: this.SectionHeader('通用') }) {
    ListItem() { this.MenuItem('外观设置', '跟随系统') }
    ListItem() { this.MenuItem('通知设置', '') }
  }
  ListItemGroup({ header: this.SectionHeader('管理') }) {
    ListItem() { this.MenuItem('用户管理', '') }
  }
}
.sticky(StickyStyle.Header)  // 吸顶分组标题
```

### Scroll（通用滚动，适合邮件详情）
```typescript
Scroll() {
  Column() {
    Text('邮件标题').fontSize(22)
    Text('发件人：Alice <alice@example.com>')
    Text('正文内容...').margin({ top: 16 })
  }
  .width('100%')
}
.width('100%')
.layoutWeight(1)
.scrollBar(BarState.Auto)
```

---

## 按钮与选择

### Button
```typescript
Button('登录')
  .width('100%')
  .height(50)
  .fontSize(16)
  .fontWeight(FontWeight.Medium)
  .fontColor(Color.White)
  .backgroundColor($r('app.color.primary'))
  .borderRadius(18)
  .loading(this.isLoading)    // 显示加载圈
  .onClick(() => { this.login() })

// 文字按钮
Button('发送', { type: ButtonType.Capsule })
  .fontColor(Color.White)
  .backgroundColor($r('app.color.primary'))
```

### Toggle（开关）
```typescript
Toggle({ type: ToggleType.Switch, isOn: this.notifyEnabled })
  .onChange((isOn: boolean) => { this.notifyEnabled = isOn })
```

---

## 图形组件

### Circle（圆形——头像、未读标记）
```typescript
// 头像
Circle().width(44).height(44).fill('#317AF7')

// 未读蓝点
Circle().width(8).height(8).fill($r('app.color.primary'))
```

### Image（图片——附件预览、头像照片）
```typescript
Image($r('app.media.logo'))
  .width(80).height(80)
  .borderRadius(40)
  .objectFit(ImageFit.Cover)

// 网络图片
Image('https://example.com/avatar.jpg')
  .width(44).height(44).borderRadius(22)
```

---

## 弹窗组件

### AlertDialog（确认对话框）
```typescript
AlertDialog.show({
  title: '删除邮件',
  message: '确定删除这封邮件吗？',
  primaryButton: { value: '取消', action: () => {} },
  secondaryButton: { value: '删除', fontColor: '#FF4757', action: () => { this.doDelete() } }
})
```

### CustomDialog（自定义弹窗）
```typescript
@CustomDialog
struct ComposeDialog {
  controller: CustomDialogController
  build() {
    Column() { /* 自定义内容 */ }
  }
}
// 使用：new CustomDialogController({ builder: ComposeDialog() })
```

### bindPopup（点击弹出菜单）
```typescript
Text('更多')
  .bindPopup(this.showPopup, {
    builder: () => { Column() { /* 菜单项 */ } },
    placement: Placement.Bottom
  })
```

---

## 其他常用组件

| 组件 | 用途 | 示例 |
|------|------|------|
| `Progress` | 进度条 | `Progress({ value: 60, total: 100 })` |
| `LoadingProgress` | 加载圈 | `LoadingProgress().width(40).height(40)` |
| `Badge` | 角标（未读数） | `Badge({ count: 3, value: '' })` |
| `TextClock` | 时间显示 | `TextClock().format('yyyy-MM-dd')` |
| `Search` | 搜索框 | `Search({ placeholder: '搜索' })` |
| `Rating` | 评分/星标 | `Rating({ rating: 5 })` |
| `Swiper` | 轮播/滑动切换 | `Swiper() { ... }` |
| `Refresh` | 下拉刷新 | `.refresh({ refreshing: $$this.isRefresh })` |

---

## 属性速查表

| 通用属性 | 含义 | 值示例 |
|----------|------|--------|
| `.width()` / `.height()` | 尺寸 | `'100%'`, `44`, `'auto'` |
| `.margin()` | 外边距 | `{ top: 8, bottom: 8 }` |
| `.padding()` | 内边距 | `{ left: 16, right: 16 }` |
| `.borderRadius()` | 圆角 | `18`, `{ topLeft: 12 }` |
| `.backgroundColor()` | 背景色 | `$r('app.color.card')` |
| `.border()` | 边框 | `{ width: 1, color: '#ccc' }` |
| `.shadow()` | 阴影 | `{ radius: 8, color: '#00000010' }` |
| `.opacity()` | 透明度 | `0.8` |
| `.layoutWeight()` | 弹性比例 | `1` (填满剩余空间) |
| `.backdropBlur()` | 背景模糊 | `20` (毛玻璃效果) |
| `.onClick()` | 点击事件 | `() => { ... }` |
| `.hitTestBehavior()` | 触摸测试 | `HitTestMode.Block` |
| `.visibility()` | 可见性 | `Visibility.Visible / Hidden / None` |
| `.zIndex()` | 层级 | `10` |

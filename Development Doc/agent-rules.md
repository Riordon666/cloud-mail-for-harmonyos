# Agent Rules

## 核心原则

1. **写代码前先读文档和现有代码** — 每次修改前必须：
   - 查看 D:\HarmonyOS-Developer-docs-main 中相关的官方文档
   - 参考项目中已有的类似实现（如 Index.ets 的做法）
   - 考虑清楚 API 版本兼容性（API 23 / SDK 6.1.0）

2. **每一步做之前搜索官方文档** — 不要凭记忆写代码
   - 每一个组件、每一个属性都要确认在 API 23 中可用
   - 不确定的 API 必须先查文档
   - 每步做完不要急着写 F0X 文档，等用户验收通过后再写

3. **边距规范**
   - 所有页面统一 top: 0（配合 expandSafeArea(TOP) 全屏沉浸）
   - 水平边距统一 Constants.PADDING_EDGE（16vp）
   - DetailPage/ComposePage 等子页面也要遵守

4. **编码规范**
   - 所有 .ets 文件必须 UTF-8 with BOM
   - 用 $r() 引用资源颜色，不要硬编码
   - 用 router.pushUrl / router.back() 做页面跳转
   - 不用 getContext()（已废弃），用 router API

5. **API 23 限制**
   - 无 uiMaterial.ImmersiveMaterial
   - 无 systemMaterial（FAB 上不能用）
   - 无 Web 组件 new WebviewController()（直接 new 不行）
   - 无模板字符串（反引号）
   - animateTo 已废弃但仍可用

6. **编译前检查**
   - PowerShell 命令不能用 &&，用 ;
   - Python 字符串中 $ 符号用 chr(36) 避免被 PowerShell 吃掉
   - SymbolGlyph fontColor 要数组形式 [$r('xxx')]
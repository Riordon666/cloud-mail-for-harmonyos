/**
 * 主题配置 — 鸿蒙原生风格 + 沉浸光感
 */
export class AppTheme {
  // 主色调
  static readonly PRIMARY: string = '#317AF7'
  static readonly PRIMARY_LIGHT: string = '#5B9AF9'
  static readonly PRIMARY_DARK: string = '#1A5CD4'

  // 背景色
  static readonly BG_LIGHT: string = '#F1F3F5'
  static readonly BG_DARK: string = '#0D0D0D'

  // 卡片色 (含毛玻璃)
  static readonly CARD_LIGHT: string = '#FFFFFF'
  static readonly CARD_DARK: string = '#1A1A1A'
  static readonly CARD_BLUR: string = 'rgba(255,255,255,0.72)'
  static readonly CARD_BLUR_DARK: string = 'rgba(26,26,26,0.75)'

  // 文字色
  static readonly TEXT_PRIMARY_LIGHT: string = '#1A1A1A'
  static readonly TEXT_PRIMARY_DARK: string = '#E8E8E8'
  static readonly TEXT_SECONDARY_LIGHT: string = '#8E8E93'
  static readonly TEXT_SECONDARY_DARK: string = '#8E8E93'
  static readonly TEXT_TERTIARY_LIGHT: string = '#C7C7CC'
  static readonly TEXT_TERTIARY_DARK: string = '#5C5C5C'

  // 分割线
  static readonly DIVIDER_LIGHT: string = '#E5E5EA'
  static readonly DIVIDER_DARK: string = '#2C2C2E'

  // 圆角
  static readonly RADIUS_SM: number = 8
  static readonly RADIUS_MD: number = 14
  static readonly RADIUS_LG: number = 20
  static readonly RADIUS_XL: number = 28

  // 间距
  static readonly SPACE_XS: number = 4
  static readonly SPACE_SM: number = 8
  static readonly SPACE_MD: number = 16
  static readonly SPACE_LG: number = 24
  static readonly SPACE_XL: number = 32
}

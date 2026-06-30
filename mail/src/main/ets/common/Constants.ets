export default class Constants {
  static readonly API_URL: string = "https://riordon.xyz/api"

  // ===== 圆角 =====
  static readonly RADIUS_CARD: number = 15
  static readonly RADIUS_BUTTON: number = 18
  static readonly RADIUS_FULL: number = 50
  static readonly RADIUS_SMALL: number = 8

  // ===== 字号 =====
  static readonly FONT_SIZE_HERO: number = 28
  static readonly FONT_SIZE_TITLE: number = 20
  static readonly FONT_SIZE_SUBTITLE: number = 16
  static readonly FONT_SIZE_COMMON: number = 14
  static readonly FONT_SIZE_SMALL: number = 12
  static readonly FONT_SIZE_BAR: number = 11
  static readonly FONT_SIZE_CAPTION: number = 10

  // ===== 字重 =====
  static readonly FONT_WEIGHT_BOLD: number = 700

  // ===== 间距 =====
  static readonly PADDING_EDGE: number = 16
  static readonly PADDING_INNER: number = 10
  static readonly PADDING_CARD: number = 12
  static readonly GAP_SMALL: number = 8
  static readonly GAP_MEDIUM: number = 12

  // ===== 阴影 =====
  static readonly SHADOW_CARD: ShadowOptions = {
    radius: 8,
    color: '#00000010',
    offsetX: 0,
    offsetY: 2
  }
  static readonly SHADOW_FLOAT: ShadowOptions = {
    radius: 16,
    color: '#317AF740',
    offsetX: 0,
    offsetY: 6
  }

  // ===== 动画 =====
  static readonly DURATION_FAST: number = 150
  static readonly DURATION_NORMAL: number = 300

  // ===== 图标尺寸 =====
  static readonly SIZE_ICON_SMALL: number = 20
  static readonly SIZE_ICON_MEDIUM: number = 24
  static readonly SIZE_ICON_LARGE: number = 32

  // ===== 头像尺寸 =====
  static readonly SIZE_AVATAR: number = 44
  static readonly SIZE_AVATAR_LARGE: number = 72
}
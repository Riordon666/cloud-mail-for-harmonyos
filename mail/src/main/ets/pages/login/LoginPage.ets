import { AppTheme } from '../../theme/AppTheme'

@Entry
@Component
struct LoginPage {
  @State email: string = ''
  @State password: string = ''
  @State isRegister: boolean = false
  @State loading: boolean = false
  @StorageProp('currentColorMode') colorMode: number = 1

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: this.isDark() ?
          [[AppTheme.BG_DARK, 0.0], ['#1A1A3E', 0.5], ['#0D1B2A', 1.0]] :
          [[AppTheme.BG_LIGHT, 0.0], ['#E8F0FE', 0.5], ['#FCE4EC', 1.0]]
        })

      Column()
        .width(200)
        .height(200)
        .borderRadius(100)
        .position({ x: '20%', y: '15%' })
        .backgroundColor(this.isDark() ? '#317AF720' : '#317AF712')
        .blur(60)

      Column()
        .width(150)
        .height(150)
        .borderRadius(75)
        .position({ x: '55%', y: '60%' })
        .backgroundColor(this.isDark() ? '#5B9AF915' : '#FF6B6B08')
        .blur(50)

      Column({ space: 0 }) {
        SymbolGlyph(('sys.symbol.envelope_fill'))
          .fontSize(48)
          .fontColor(AppTheme.PRIMARY)
          .margin({ bottom: 12 })

        Text('Cloud Mail')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)

        Text(this.isRegister ? '创建新账号' : '登录以继续')
          .fontSize(15)
          .fontColor(this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT)
          .margin({ top: 4, bottom: 36 })

        Row() {
          SymbolGlyph(('sys.symbol.envelope'))
            .fontSize(20)
            .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
            .margin({ right: 10 })

          TextInput({ placeholder: '邮箱地址', text: this.email })
            .placeholderColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
            .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
            .backgroundColor(Color.Transparent)
            .type(InputType.Email)
            .layoutWeight(1)
            .height(44)
            .onChange((value: string) => { this.email = value })
        }
        .width('100%')
        .padding({ left: 14, right: 14 })
        .borderRadius(AppTheme.RADIUS_SM)
        .backgroundColor(this.isDark() ? '#252525' : '#F2F2F7')
        .margin({ bottom: 12 })

        Row() {
          SymbolGlyph(('sys.symbol.lock'))
            .fontSize(20)
            .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
            .margin({ right: 10 })

          TextInput({ placeholder: '密码', text: this.password })
            .placeholderColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
            .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
            .backgroundColor(Color.Transparent)
            .type(InputType.Password)
            .layoutWeight(1)
            .height(44)
            .onChange((value: string) => { this.password = value })
        }
        .width('100%')
        .padding({ left: 14, right: 14 })
        .borderRadius(AppTheme.RADIUS_SM)
        .backgroundColor(this.isDark() ? '#252525' : '#F2F2F7')
        .margin({ bottom: 24 })

        Button(this.isRegister ? '注册' : '登录')
          .width('100%')
          .height(50)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor(AppTheme.PRIMARY)
          .borderRadius(AppTheme.RADIUS_MD)
          .loading(this.loading)
          .margin({ bottom: 16 })

        Row() {
          Text(this.isRegister ? '已有账号？' : '没有账号？')
            .fontSize(14)
            .fontColor(this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT)

          Text(this.isRegister ? '去登录' : '立即注册')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppTheme.PRIMARY)
            .margin({ left: 4 })
            .onClick(() => { this.isRegister = !this.isRegister })
        }
      }
      .width('88%')
      .padding({ top: 40, bottom: 40, left: 28, right: 28 })
      .borderRadius(AppTheme.RADIUS_XL)
      .backgroundColor(this.isDark() ? AppTheme.CARD_BLUR_DARK : AppTheme.CARD_BLUR)
      .backdropBlur(40)
      .shadow({
        radius: 20,
        color: this.isDark() ? '#00000040' : '#00000010',
        offsetX: 0,
        offsetY: 8
      })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }

  private isDark(): boolean {
    return this.colorMode === 1
  }
}

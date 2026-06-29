import { AppTheme } from '../../theme/AppTheme'

@Entry
@Component
struct AccountsPage {
  @StorageProp('currentColorMode') colorMode: number = 1

  build() {
    Column() {
      Row() {
        Text('我的邮箱')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)

        Blank()

        Row() {
          SymbolGlyph(('sys.symbol.plus'))
            .fontSize(18)
            .fontColor(Color.White)
          Text('新建')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .margin({ left: 4 })
        }
        .padding({ left: 12, right: 14, top: 6, bottom: 6 })
        .borderRadius(18)
        .backgroundColor(AppTheme.PRIMARY)
      }
      .width('100%')
      .padding({ left: 16, top: 16, bottom: 12, right: 16 })

      List() {
        ForEach(this.mockAccounts, (item: AccountMock, index: number) => {
          ListItem() {
            this.AccountCard(item)
          }
          .margin({ left: 16, right: 16, top: 4, bottom: 4 })
        })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDark() ? AppTheme.BG_DARK : AppTheme.BG_LIGHT)
  }

  @Builder
  AccountCard(item: AccountMock) {
    Row() {
      Stack() {
        Circle()
          .width(44)
          .height(44)
          .fill(item.isPrimary ? '#317AF7' : (this.isDark() ? '#2C2C2E' : '#E8E8ED'))
        Text(item.email.charAt(0).toUpperCase())
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(item.isPrimary ? Color.White : (this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT))
      }

      Column() {
        Text(item.email)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)

        Text(item.unread + ' 封未读 · ' + item.total + ' 封总计')
          .fontSize(13)
          .fontColor(this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT)
          .margin({ top: 4 })

        if (item.isPrimary) {
          Text('默认账号')
            .fontSize(11)
            .fontColor(AppTheme.PRIMARY)
            .fontWeight(FontWeight.Medium)
            .margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .layoutWeight(1)

      SymbolGlyph(('sys.symbol.chevron_right'))
        .fontSize(18)
        .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppTheme.RADIUS_MD)
    .backgroundColor(this.isDark() ? AppTheme.CARD_DARK : AppTheme.CARD_LIGHT)
    .shadow({
      radius: 4,
      color: this.isDark() ? '#FFFFFF05' : '#00000008',
      offsetX: 0,
      offsetY: 1
    })
  }

  private isDark(): boolean {
    return this.colorMode === 1
  }

  @State mockAccounts: AccountMock[] = [
    { email: 'admin@riordon.xyz', unread: 3, total: 128, isPrimary: true },
    { email: 'work@riordon.xyz', unread: 0, total: 45, isPrimary: false },
    { email: 'hello@riordon.xyz', unread: 12, total: 67, isPrimary: false }
  ]
}

interface AccountMock {
  email: string
  unread: number
  total: number
  isPrimary: boolean
}

import { AppTheme } from '../../../theme/AppTheme'

@Entry
@Component
struct AdminUsersPage {
  @StorageProp('currentColorMode') colorMode: number = 1

  build() {
    Column() {
      Row() {
        SymbolGlyph(('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
        Text('用户管理')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
          .margin({ left: 8 })
        Blank()
        SymbolGlyph(('sys.symbol.plus'))
          .fontSize(22)
          .fontColor(this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(this.isDark() ? AppTheme.CARD_BLUR_DARK : AppTheme.CARD_BLUR)
      .backdropBlur(20)

      List() {
        ForEach(this.mockUsers, (item: UserMock, index: number) => {
          ListItem() {
            Row() {
              Stack() {
                Circle()
                  .width(40)
                  .height(40)
                  .fill('#317AF7')
                Text(item.email.charAt(0).toUpperCase())
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Color.White)
              }

              Column() {
                Text(item.email)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)

                Text('创建时间: ' + item.createTime + ' · 角色: ' + item.role)
                  .fontSize(12)
                  .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
                  .margin({ top: 3 })
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 10 })
              .layoutWeight(1)

              Text(item.status)
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .fontColor(item.status === '正常' ? '#6BCB77' : '#FF6B6B')
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .borderRadius(8)
                .backgroundColor(item.status === '正常' ? '#6BCB7715' : '#FF6B6B15')
            }
            .width('100%')
            .padding(14)
            .borderRadius(AppTheme.RADIUS_MD)
            .backgroundColor(this.isDark() ? AppTheme.CARD_DARK : AppTheme.CARD_LIGHT)
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

  private isDark(): boolean {
    return this.colorMode === 1
  }

  @State mockUsers: UserMock[] = [
    { email: 'admin@riordon.xyz', createTime: '2025-01-15', role: '管理员', status: '正常' },
    { email: 'user1@riordon.xyz', createTime: '2025-06-10', role: '标准用户', status: '正常' },
    { email: 'user2@riordon.xyz', createTime: '2025-06-20', role: '标准用户', status: '封禁' }
  ]
}

interface UserMock {
  email: string
  createTime: string
  role: string
  status: string
}

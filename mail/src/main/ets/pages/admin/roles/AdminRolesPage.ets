import { AppTheme } from '../../../theme/AppTheme'

@Entry
@Component
struct AdminRolesPage {
  @StorageProp('currentColorMode') colorMode: number = 1

  build() {
    Column() {
      Row() {
        SymbolGlyph(('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
        Text('角色权限')
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
        ForEach(this.mockRoles, (item: RoleMock, index: number) => {
          ListItem() {
            Row() {
              Stack() {
                Circle()
                  .width(40)
                  .height(40)
                  .fill(item.isDefault ? AppTheme.PRIMARY : (this.isDark() ? '#2C2C2E' : '#E8E8ED'))
                SymbolGlyph(('sys.symbol.shield'))
                  .fontSize(20)
                  .fontColor(item.isDefault ? Color.White : (this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT))
              }

              Column() {
                Row() {
                  Text(item.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)

                  if (item.isDefault) {
                    Text('默认')
                      .fontSize(10)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(AppTheme.PRIMARY)
                      .margin({ left: 6 })
                  }
                }

                Text(item.userCount + ' 个用户 · 发送: ' + item.sendType + (item.sendCount === -1 ? '不限' : (item.sendCount + '封')))
                  .fontSize(12)
                  .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
                  .margin({ top: 3 })
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 10 })
              .layoutWeight(1)

              SymbolGlyph(('sys.symbol.chevron_right'))
                .fontSize(16)
                .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
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

  @State mockRoles: RoleMock[] = [
    { name: '免费用户', userCount: 45, sendType: '每日', sendCount: 50, isDefault: true },
    { name: '标准用户', userCount: 12, sendType: '每日', sendCount: 500, isDefault: false },
    { name: '专业用户', userCount: 3, sendType: '每日', sendCount: 2000, isDefault: false }
  ]
}

interface RoleMock {
  name: string
  userCount: number
  sendType: string
  sendCount: number
  isDefault: boolean
}

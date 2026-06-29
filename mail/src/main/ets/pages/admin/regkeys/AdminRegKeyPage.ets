import { AppTheme } from '../../../theme/AppTheme'

@Entry
@Component
struct AdminRegKeyPage {
  @StorageProp('currentColorMode') colorMode: number = 1

  build() {
    Column() {
      Row() {
        SymbolGlyph(('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
        Text('注册码管理')
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
        ForEach(this.mockKeys, (item: KeyMock, index: number) => {
          ListItem() {
            Row() {
              Column() {
                Row() {
                  Text(item.key)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)

                  Text(item.isUsed ? '使用' : '未使用')
                    .fontSize(10)
                    .fontColor(item.isUsed ? '#FF6B6B' : '#6BCB77')
                    .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                    .borderRadius(4)
                    .backgroundColor(item.isUsed ? '#FF6B6B15' : '#6BCB7715')
                    .margin({ left: 8 })
                }

                Text('有效期: ' + item.expire + ' · 次数: ' + item.useCount + '/' + item.maxUse)
                  .fontSize(12)
                  .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              SymbolGlyph(('sys.symbol.trash'))
                .fontSize(18)
                .fontColor('#FF6B6B')
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

  @State mockKeys: KeyMock[] = [
    { key: 'INVITE-2024-A1B2', isUsed: true, expire: '2026-12-31', useCount: 1, maxUse: 1 },
    { key: 'INVITE-2024-C3D4', isUsed: false, expire: '2026-12-31', useCount: 0, maxUse: 5 },
    { key: 'INVITE-2024-E5F6', isUsed: true, expire: '2026-06-30', useCount: 3, maxUse: 3 }
  ]
}

interface KeyMock {
  key: string
  isUsed: boolean
  expire: string
  useCount: number
  maxUse: number
}

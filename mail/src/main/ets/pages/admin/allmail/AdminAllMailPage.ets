import { AppTheme } from '../../../theme/AppTheme'

@Entry
@Component
struct AdminAllMailPage {
  @StorageProp('currentColorMode') colorMode: number = 1

  build() {
    Column() {
      Row() {
        SymbolGlyph(('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
        Text('全部邮件')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
          .margin({ left: 8 })
        Blank()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(this.isDark() ? AppTheme.CARD_BLUR_DARK : AppTheme.CARD_BLUR)
      .backdropBlur(20)

      List() {
        ForEach(this.mockMails, (item: AdminMailMock, index: number) => {
          ListItem() {
            Row() {
              Column() {
                Text(item.subject)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
                  .maxLines(1)

                Row() {
                  Text(item.from)
                    .fontSize(12)
                    .fontColor(AppTheme.PRIMARY)
                  Text(' → ')
                    .fontSize(11)
                    .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
                  Text(item.to)
                    .fontSize(12)
                    .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
                  Text(' · ')
                    .fontSize(11)
                    .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
                  Text(item.time)
                    .fontSize(12)
                    .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
                }
                .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
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

  @State mockMails: AdminMailMock[] = [
    { from: 'alice@outlook.com', to: 'admin@riordon.xyz', subject: 'Q4 设计稿评审通知', time: '09:15' },
    { from: 'github@notify.com', to: 'work@riordon.xyz', subject: '[Action] Build failed', time: '10:32' },
    { from: 'user1@riordon.xyz', to: 'hello@gmail.com', subject: '关于项目合作', time: '昨天' }
  ]
}

interface AdminMailMock {
  from: string
  to: string
  subject: string
  time: string
}

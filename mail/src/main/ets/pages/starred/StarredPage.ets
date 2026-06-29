import { AppTheme } from '../../theme/AppTheme'

@Entry
@Component
struct StarredPage {
  @StorageProp('currentColorMode') colorMode: number = 1

  build() {
    Column() {
      Row() {
        Text('星标邮件')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
      }
      .width('100%')
      .padding({ left: 16, top: 16, bottom: 12 })

      if (this.mockStarred.length === 0) {
        Column() {
          SymbolGlyph(('sys.symbol.star_fill'))
            .fontSize(48)
            .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)

          Text('暂无星标邮件')
            .fontSize(16)
            .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
            .margin({ top: 12 })

          Text('标记为星标的邮件会出现在这里')
            .fontSize(13)
            .fontColor(this.isDark() ? '#5C5C5C' : '#C7C7CC')
            .margin({ top: 4 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.mockStarred, (item: StarredMock, index: number) => {
            ListItem() {
              this.StarredCard(item)
            }
            .margin({ left: 16, right: 16, top: 4, bottom: 4 })
          })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDark() ? AppTheme.BG_DARK : AppTheme.BG_LIGHT)
  }

  @Builder
  StarredCard(item: StarredMock) {
    Row() {
      Column() {
        Text(item.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
          .maxLines(1)

        Text(item.subject)
          .fontSize(14)
          .fontColor(this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT)
          .maxLines(1)
          .margin({ top: 4 })

        Text(item.time)
          .fontSize(12)
          .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      SymbolGlyph(('sys.symbol.star_fill'))
        .fontSize(20)
        .fontColor('#FFD93D')
    }
    .width('100%')
    .padding(16)
    .borderRadius(AppTheme.RADIUS_MD)
    .backgroundColor(this.isDark() ? AppTheme.CARD_DARK : AppTheme.CARD_LIGHT)
  }

  private isDark(): boolean {
    return this.colorMode === 1
  }

  @State mockStarred: StarredMock[] = [
    { name: 'GitHub', subject: '[Action] Build failed on main branch', time: '10:32' }
  ]
}

interface StarredMock {
  name: string
  subject: string
  time: string
}

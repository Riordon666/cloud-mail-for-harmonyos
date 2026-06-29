import { AppTheme } from '../../theme/AppTheme'

/**
 * InboxPage — 收件箱列表页面
 */
@Entry
@Component
struct InboxPage {
  @State searchText: string = ''
  @StorageProp('currentColorMode') colorMode: number = 1

  build() {
    Column() {
      this.SearchHeader()

      List() {
        ForEach(this.mockEmails, (item: EmailMock, index: number) => {
          ListItem() {
            this.EmailCard(item)
          }
          .margin({ left: 16, right: 16, top: 4, bottom: 4 })
        })
      }
      .width('100%')
      .layoutWeight(1)
      .divider({ strokeWidth: 0 })
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDark() ? AppTheme.BG_DARK : AppTheme.BG_LIGHT)
  }

  @Builder
  SearchHeader() {
    Row() {
      TextInput({ placeholder: '搜索邮件', text: this.searchText })
        .placeholderColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
        .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
        .backgroundColor(Color.Transparent)
        .border({ width: 0 })
        .height(36)
        .layoutWeight(1)
        .onChange((value: string) => { this.searchText = value })

      Blank().width(8)

      SymbolGlyph(('sys.symbol.line_3_horizontal_decrease'))
        .fontSize(22)
        .fontColor(this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT)
    }
    .width('100%')
    .height(52)
    .borderRadius(AppTheme.RADIUS_LG)
    .padding({ left: 12, right: 12 })
    .backgroundColor(this.isDark() ? AppTheme.CARD_BLUR_DARK : AppTheme.CARD_BLUR)
    .backdropBlur(20)
    .shadow({
      radius: 8,
      color: this.isDark() ? '#FFFFFF05' : '#00000010',
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder
  EmailCard(item: EmailMock) {
    Row() {
      Stack() {
        Circle()
          .width(44)
          .height(44)
          .fill(this.getAvatarColor(item.name))
        Text(item.name.charAt(0).toUpperCase())
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
      }
      .margin({ right: 12 })

      Column() {
        Row() {
          Text(item.name)
            .fontSize(16)
            .fontWeight(item.unread ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          Text(item.time)
            .fontSize(12)
            .fontColor(this.isDark() ? AppTheme.TEXT_TERTIARY_DARK : AppTheme.TEXT_TERTIARY_LIGHT)
            .fontWeight(item.unread ? FontWeight.Medium : FontWeight.Normal)
        }
        .width('100%')

        Text(item.subject)
          .fontSize(15)
          .fontWeight(item.unread ? FontWeight.Medium : FontWeight.Normal)
          .fontColor(this.isDark() ? AppTheme.TEXT_PRIMARY_DARK : AppTheme.TEXT_PRIMARY_LIGHT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
          .width('100%')

        Text(item.preview)
          .fontSize(13)
          .fontColor(this.isDark() ? AppTheme.TEXT_SECONDARY_DARK : AppTheme.TEXT_SECONDARY_LIGHT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 3 })
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (item.unread) {
        Circle()
          .width(8)
          .height(8)
          .fill(AppTheme.PRIMARY)
          .margin({ left: 8 })
      }
    }
    .width('100%')
    .padding({ top: 14, bottom: 14, left: 16, right: 16 })
    .borderRadius(AppTheme.RADIUS_MD)
    .backgroundColor(this.isDark() ? AppTheme.CARD_DARK : AppTheme.CARD_LIGHT)
    .shadow({
      radius: 4,
      color: this.isDark() ? '#FFFFFF05' : '#00000008',
      offsetX: 0,
      offsetY: 1
    })
  }

  private getAvatarColor(name: string): string {
    const colors: string[] = ['#FF6B6B', '#FFD93D', '#6BCB77', '#4D96FF', '#9B59B6', '#1ABC9C']
    let hash = 0
    for (let i = 0; i < name.length; i++) {
      hash = name.charCodeAt(i) + ((hash << 5) - hash)
    }
    return colors[Math.abs(hash) % colors.length]
  }

  private isDark(): boolean {
    return this.colorMode === 1
  }

  @State mockEmails: EmailMock[] = [
    { name: 'GitHub', subject: '[Action] Build failed on main branch', preview: 'The workflow run #4528 has failed...', time: '10:32', unread: true },
    { name: 'Alice Zhang', subject: 'Q4 设计稿评审通知', preview: 'hi，本周五下午3点会议室A进行设计评审...', time: '09:15', unread: true },
    { name: 'Apple', subject: 'Your receipt from Apple', preview: 'Here is your receipt for the purchase...', time: '昨天', unread: false },
    { name: 'Cloudflare', subject: 'Weekly Analytics Report', preview: 'Your weekly analytics report is now available...', time: '昨天', unread: false },
    { name: 'Bob Smith', subject: 'Re: 关于项目进度的讨论', preview: 'Thanks for the update. I have reviewed the changes...', time: '周一', unread: false },
    { name: 'Verification', subject: 'Login verification code', preview: 'Your verification code is 847291...', time: '周日', unread: false }
  ]
}

interface EmailMock {
  name: string
  subject: string
  preview: string
  time: string
  unread: boolean
}

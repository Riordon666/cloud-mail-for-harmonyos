import Constants from '../common/Constants'
import { MOCK_EMAILS, EmailMock } from '../common/MockData'
import { EmailCard } from '../components/EmailCard'

class DetailParams {
  emailData: EmailMock
  emailList: EmailMock[]
  currentIndex: number
  constructor(emailData: EmailMock, emailList: EmailMock[], currentIndex: number) {
    this.emailData = emailData
    this.emailList = emailList
    this.currentIndex = currentIndex
  }
}

@Component
export struct SentPage {
  private scroller: Scroller = new Scroller()
  private pathStack: NavPathStack = AppStorage.get('appPathStack') as NavPathStack
  private sentList: EmailMock[] = [
    {
      id: 100, name: 'Re: 项目进展', email: 'admin@riordon.xyz',
      subject: 'Re: 项目进展',
      body: '好的，第一阶段的交付物已经准备好了，请查收附件。第二阶段需要额外的人力资源，我已经提交了申请。',
      time: '昨天', unread: false, cc: [], bcc: [], attList: [], htmlContent: ''
    },
    {
      id: 101, name: 'Re: Q4 设计稿', email: 'admin@riordon.xyz',
      subject: 'Re: Q4 设计稿评审通知',
      body: '收到，我会在周五之前反馈修改意见。',
      time: '周一', unread: false, cc: [], bcc: [], attList: [], htmlContent: ''
    },
    {
      id: 102, name: 'Re: 周报', email: 'admin@riordon.xyz',
      subject: 'Re: 本周工作总结',
      body: '本周完成了邮件模块的前端重构，下周开始后端API对接。',
      time: '周日', unread: false, cc: [], bcc: [], attList: [], htmlContent: ''
    }
  ]

  private openDetail(item: EmailMock, index: number): void {
    const params: DetailParams = new DetailParams(item, this.sentList, index)
    this.pathStack.pushPathByName('DetailPage', params)
  }

  build() {
    Column() {
      Text('已发送')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 16, bottom: 8 })
        .width('100%')

      if (this.sentList.length === 0) {
        Column() {
          SymbolGlyph($r('sys.symbol.paperplane'))
            .fontSize(48)
            .fontColor([$r('app.color.text_tertiary')])
          Text('暂无已发送邮件')
            .fontSize(16)
            .fontColor($r('app.color.text_tertiary'))
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ scroller: this.scroller }) {
          ForEach(this.sentList, (item: EmailMock, index: number) => {
            ListItem() {
              EmailCard({
                name: item.name,
                subject: item.subject,
                time: item.time,
                unread: item.unread,
                onCardClick: () => { this.openDetail(item, index) }
              })
            }
          }, (item: EmailMock): string => item.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }
}

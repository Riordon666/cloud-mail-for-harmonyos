import Constants from '../common/Constants'
import { EmailMock } from '../common/MockData'
import { EmailCard } from '../components/EmailCard'
import { EmptyState } from '../components/EmptyState'

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

interface SentEmailItem {
  emailData: EmailMock
  status: string
}

@Component
export struct SentPage {
  private scroller: Scroller = new Scroller()
  private pathStack: NavPathStack = AppStorage.get('appPathStack') as NavPathStack
  private sentList: SentEmailItem[] = [
    {
      emailData: {
        id: 100, name: 'Re: 项目进展', email: 'admin@riordon.xyz',
        subject: 'Re: 项目进展',
        body: '好的，第一阶段的交付物已经准备好了，请查收附件。第二阶段需要额外的人力资源，我已经提交了申请。',
        time: '昨天', unread: false, cc: [], bcc: [], attList: [], htmlContent: ''
      },
      status: '已发送'
    },
    {
      emailData: {
        id: 101, name: 'Re: Q4 设计稿', email: 'admin@riordon.xyz',
        subject: 'Re: Q4 设计稿评审通知',
        body: '收到，我会在周五之前反馈修改意见。',
        time: '周一', unread: false, cc: [], bcc: [], attList: [], htmlContent: ''
      },
      status: '已发送'
    },
    {
      emailData: {
        id: 102, name: 'Re: 周报', email: 'admin@riordon.xyz',
        subject: 'Re: 本周工作总结',
        body: '本周完成了邮件模块的前端重构，下周开始后端API对接。',
        time: '周日', unread: false, cc: [], bcc: [], attList: [], htmlContent: ''
      },
      status: '已发送'
    }
  ]

  private getSentEmails(): EmailMock[] {
    const emails: EmailMock[] = []
    for (let i = 0; i < this.sentList.length; i++) {
      emails.push(this.sentList[i].emailData)
    }
    return emails
  }

  private openDetail(item: SentEmailItem, index: number): void {
    const params: DetailParams = new DetailParams(item.emailData, this.getSentEmails(), index)
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
        EmptyState({ icon: $r('sys.symbol.paperplane'), message: '暂无已发送邮件' })
      } else {
        List({ scroller: this.scroller }) {
          ForEach(this.sentList, (item: SentEmailItem, index: number) => {
            ListItem() {
              EmailCard({
                name: item.emailData.name,
                subject: item.emailData.subject,
                time: item.emailData.time,
                unread: item.emailData.unread,
                status: item.status,
                onCardClick: () => { this.openDetail(item, index) }
              })
            }
          }, (item: SentEmailItem): string => item.emailData.id.toString())
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

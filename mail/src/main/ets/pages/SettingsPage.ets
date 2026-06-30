import Constants from '../common/Constants'
import { AvatarBar } from '../components/AvatarBar'

@Component
export struct SettingsPage {
  build() {
    Column() {
      Column() {
        AvatarBar({ name: 'admin@riordon.xyz', size: 72, fontSize: 32, bgColor: '#317AF7' })
          .margin({ bottom: 16 })
        Text('admin@riordon.xyz')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text('专业版')
          .fontSize(12)
          .fontColor(Color.White)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(10)
          .backgroundColor($r('app.color.primary_light'))
          .margin({ top: 8 })
      }
      .width('100%')
      .padding({ top: 40, bottom: 28 })
      .alignItems(HorizontalAlign.Center)

      List() {
        ListItem() { this.MenuItem('外观设置', '跟随系统') }
        ListItem() { this.MenuItem('通知设置', '') }
        ListItem() { this.MenuItem('隐私政策', '') }
        ListItem() { this.MenuItem('关于', 'v1.0.0') }

        ListItem() {
          Text('管理员功能')
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
            .fontWeight(FontWeight.Medium)
            .padding({ left: Constants.PADDING_EDGE, top: 20, bottom: 6 })
            .width('100%')
        }

        ListItem() { this.MenuItem('用户管理', '') }
        ListItem() { this.MenuItem('全部邮件', '') }
        ListItem() { this.MenuItem('角色权限', '') }
        ListItem() { this.MenuItem('数据分析', '') }
        ListItem() { this.MenuItem('注册码管理', '') }

        ListItem() {
          Row() {
            Text('退出登录')
              .fontSize(16)
              .fontColor($r('app.color.danger'))
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 14, bottom: 14 })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder MenuItem(title: string, value: string) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      if (value !== '') {
        Text(value)
          .fontSize(14)
          .fontColor($r('app.color.text_tertiary'))
      }
      Text('›')
        .fontSize(18)
        .fontColor($r('app.color.text_tertiary'))
        .margin({ left: 4 })
    }
    .width('100%')
    .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 14, bottom: 14 })
    .backgroundColor($r('app.color.card'))
  }
}

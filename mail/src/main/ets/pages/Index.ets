import { hdsMaterial, HdsNavigation, HdsTabs, HdsTabsController, ScrollEffectType } from '@kit.UIDesignKit'
import Constants from '../common/Constants'

@Entry
@Component
struct Index {
  @State currentTab: number = 0
  private tabController: HdsTabsController = new HdsTabsController()

  aboutToAppear(): void {
    try {
      this.tabController.preloadItems([0, 1, 2, 3, 4])
    } catch (err) {
      console.error('preloadItems failed')
    }
  }

  build() {
    HdsNavigation() {
      HdsTabs({ controller: this.tabController, index: this.currentTab }) {
        TabContent() { InboxView() }
        .tabBar(this.TabBarItem('收件箱', 0))

        TabContent() { StarredView() }
        .tabBar(this.TabBarItem('星标', 1))

        TabContent() { ComposeView() }
        .tabBar(this.TabBarItem('写邮件', 2))

        TabContent() { AccountsView() }
        .tabBar(this.TabBarItem('账号', 3))

        TabContent() { MeView() }
        .tabBar(this.TabBarItem('我', 4))
      }
      .scrollable(false)
      .barOverlap(true)
      .vertical(false)
      .barPosition(BarPosition.End)
      .barFloatingStyle({
        barBottomMargin: 36,
        adaptToHandedness: true,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        }
      })
      .onChange((index: number) => { this.currentTab = index })
      .width('100%')
      .height('100%')
    }
    .mode(NavigationMode.Stack)
    .titleBar({
      style: {
        scrollEffectOpts: {
          enableScrollEffect: true,
          scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR
        },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        }
      }
    })
    .hideBackButton(true)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .backgroundColor($r('app.color.background'))
  }

  @Builder TabBarItem(text: string, index: number) {
    Column() {
      Text(text)
        .fontSize(Constants.FONT_SIZE_BAR)
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentTab === index ? $r('app.color.primary') : $r('app.color.text_tertiary'))
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
  }
}

// ========== 收件箱 ==========
@Component
struct InboxView {
  private scroller: Scroller = new Scroller()
  build() {
    List({ scroller: this.scroller }) {
      ListItem() {
        Row() {
          TextInput({ placeholder: '搜索邮件' })
            .placeholderColor($r('app.color.text_tertiary'))
            .fontColor($r('app.color.text_primary'))
            .backgroundColor($r('app.color.card'))
            .borderRadius(Constants.RADIUS_BUTTON)
            .height(48)
            .layoutWeight(1)
            .padding({ left: 14 })
        }
        .width('100%')
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 8, bottom: 8 })
      }
      ListItem() { this.EmailCard('GitHub', '[Action] Build failed on main', '10:32', true) }
      ListItem() { this.EmailCard('Alice Zhang', 'Q4 设计稿评审通知', '09:15', true) }
      ListItem() { this.EmailCard('Apple', 'Your receipt from Apple', '昨天', false) }
      ListItem() { this.EmailCard('Cloudflare', 'Weekly Analytics Report', '昨天', false) }
      ListItem() { this.EmailCard('Bob Smith', 'Re: 项目进展', '周一', false) }
      ListItem() { this.EmailCard('Notion', '文档有更新', '周日', false) }
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor($r('app.color.background'))
  }

  @Builder EmailCard(name: string, subject: string, time: string, unread: boolean) {
    Row() {
      Stack() {
        Circle().width(44).height(44).fill(this.getAvatarColor(name))
        Text(name.charAt(0).toUpperCase()).fontSize(18).fontWeight(FontWeight.Medium).fontColor(Color.White)
      }.margin({ right: 12 })
      Column() {
        Row() {
          Text(name).fontSize(16).fontWeight(unread ? FontWeight.Bold : FontWeight.Medium)
            .fontColor($r('app.color.text_primary')).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
          Text(time).fontSize(12).fontColor($r('app.color.text_tertiary'))
        }.width('100%')
        Text(subject).fontSize(14).fontWeight(unread ? FontWeight.Medium : FontWeight.Normal)
          .fontColor($r('app.color.text_secondary')).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 4 }).width('100%')
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      if (unread) { Circle().width(8).height(8).fill($r('app.color.primary')).margin({ left: 8 }) }
    }
    .width('100%').padding({ top: 14, bottom: 14, left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
    .borderRadius(Constants.RADIUS_CARD).backgroundColor($r('app.color.card'))
    .margin({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 4, bottom: 4 })
  }
  private getAvatarColor(name: string): string {
    const c = ['#FF6B6B', '#FFD93D', '#6BCB77', '#4D96FF', '#9B59B6', '#1ABC9C']
    let h = 0; for (let i = 0; i < name.length; i++) { h = name.charCodeAt(i) + ((h << 5) - h) }
    return c[Math.abs(h) % c.length]
  }
}

// ========== 星标 ==========
@Component
struct StarredView {
  build() {
    Column() {
      Text('星标邮件').fontSize(28).fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary')).padding({ left: Constants.PADDING_EDGE, top: 16, bottom: 16 }).width('100%')
      Column() {
        Text('⭐').fontSize(48)
        Text('暂无星标邮件').fontSize(16).fontColor($r('app.color.text_tertiary')).margin({ top: 12 })
      }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
    }.width('100%').height('100%').backgroundColor($r('app.color.background'))
  }
}

// ========== 写邮件 ==========
@Component
struct ComposeView {
  @State toEmail: string = ''
  @State subject: string = ''
  @State content: string = ''
  build() {
    Column() {
      Row() {
        Text('写邮件').fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        Blank()
        Row() { Text('发送').fontSize(14).fontWeight(FontWeight.Medium).fontColor(Color.White) }
        .padding({ left: 16, right: 16, top: 8, bottom: 8 }).borderRadius(18).backgroundColor($r('app.color.primary'))
      }.width('100%').padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 12, bottom: 8 })
      Divider().strokeWidth(0.5).color($r('app.color.divider'))
      Row() {
        Text('收件人').fontSize(14).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_secondary')).width(56)
        TextInput({ placeholder: '输入邮箱地址', text: this.toEmail }).placeholderColor($r('app.color.text_tertiary'))
          .fontColor($r('app.color.text_primary')).backgroundColor(Color.Transparent).layoutWeight(1).height(44)
          .onChange((v: string) => { this.toEmail = v })
      }.width('100%').padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 12 })
      Divider().strokeWidth(0.5).color($r('app.color.divider')).margin({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
      Row() {
        Text('主题').fontSize(14).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_secondary')).width(56)
        TextInput({ placeholder: '邮件主题', text: this.subject }).placeholderColor($r('app.color.text_tertiary'))
          .fontColor($r('app.color.text_primary')).backgroundColor(Color.Transparent).layoutWeight(1).height(44)
          .onChange((v: string) => { this.subject = v })
      }.width('100%').padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
      Divider().strokeWidth(0.5).color($r('app.color.divider')).margin({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
      TextArea({ placeholder: '写点什么...', text: this.content }).placeholderColor($r('app.color.text_tertiary'))
        .fontColor($r('app.color.text_primary')).backgroundColor(Color.Transparent).padding(Constants.PADDING_EDGE).layoutWeight(1)
        .onChange((v: string) => { this.content = v })
    }.width('100%').height('100%').backgroundColor($r('app.color.background'))
  }
}

// ========== 账号管理 ==========
@Component
struct AccountsView {
  build() {
    Column() {
      Row() {
        Text('我的邮箱').fontSize(28).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        Blank()
        Row() { Text('新建').fontSize(14).fontWeight(FontWeight.Medium).fontColor(Color.White) }
        .padding({ left: 12, right: 14, top: 6, bottom: 6 }).borderRadius(18).backgroundColor($r('app.color.primary'))
      }.width('100%').padding({ left: Constants.PADDING_EDGE, top: 16, bottom: 12, right: Constants.PADDING_EDGE })
      List() {
        ListItem() { this.AccountCard('admin@riordon.xyz', 3, 128, true) }
        ListItem() { this.AccountCard('work@riordon.xyz', 0, 45, false) }
        ListItem() { this.AccountCard('hello@riordon.xyz', 12, 67, false) }
      }.width('100%').layoutWeight(1).scrollBar(BarState.Off)
    }.width('100%').height('100%').backgroundColor($r('app.color.background'))
  }
  @Builder AccountCard(email: string, unread: number, total: number, isPrimary: boolean) {
    Row() {
      Stack() {
        Circle().width(44).height(44).fill(isPrimary ? '#317AF7' : '#D1D1D6')
        Text(email.charAt(0).toUpperCase()).fontSize(18).fontWeight(FontWeight.Medium).fontColor(Color.White)
      }
      Column() {
        Text(email).fontSize(16).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
        Text(unread + ' 封未读 · ' + total + ' 封总计').fontSize(12).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
        if (isPrimary) { Text('默认账号').fontSize(10).fontColor($r('app.color.primary')).fontWeight(FontWeight.Medium).margin({ top: 2 }) }
      }.alignItems(HorizontalAlign.Start).margin({ left: 12 }).layoutWeight(1)
      Text('›').fontSize(20).fontColor($r('app.color.text_tertiary'))
    }
    .width('100%').padding({ top: 14, bottom: 14, left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
    .borderRadius(Constants.RADIUS_CARD).backgroundColor($r('app.color.card'))
    .margin({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 4, bottom: 4 })
  }
}

// ========== 我的 ==========
@Component
struct MeView {
  build() {
    Column() {
      Column() {
        Stack() {
          Circle().width(72).height(72).fill('#317AF7')
          Text('A').fontSize(32).fontWeight(FontWeight.Bold).fontColor(Color.White)
        }.margin({ bottom: 16 })
        Text('admin@riordon.xyz').fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        Text('专业版').fontSize(12).fontColor(Color.White).padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(10).backgroundColor($r('app.color.primary_light')).margin({ top: 8 })
      }.width('100%').padding({ top: 40, bottom: 28 }).alignItems(HorizontalAlign.Center)
      List() {
        ListItem() { this.MenuItem('外观设置', '跟随系统') }
        ListItem() { this.MenuItem('通知设置', '') }
        ListItem() { this.MenuItem('隐私政策', '') }
        ListItem() { this.MenuItem('关于', 'v1.0.0') }
        ListItem() {
          Text('管理员功能').fontSize(12).fontColor($r('app.color.text_tertiary')).fontWeight(FontWeight.Medium)
            .padding({ left: Constants.PADDING_EDGE, top: 20, bottom: 6 }).width('100%')
        }
        ListItem() { this.MenuItem('用户管理', '') }
        ListItem() { this.MenuItem('全部邮件', '') }
        ListItem() { this.MenuItem('角色权限', '') }
        ListItem() { this.MenuItem('数据分析', '') }
        ListItem() { this.MenuItem('注册码管理', '') }
        ListItem() {
          Row() { Text('退出登录').fontSize(16).fontColor($r('app.color.danger')).fontWeight(FontWeight.Medium) }
            .width('100%').justifyContent(FlexAlign.Center).padding({ top: 14, bottom: 14 })
        }
      }.width('100%').layoutWeight(1).scrollBar(BarState.Off)
    }.width('100%').height('100%').backgroundColor($r('app.color.background'))
  }
  @Builder MenuItem(title: string, value: string) {
    Row() {
      Text(title).fontSize(16).fontColor($r('app.color.text_primary')).layoutWeight(1)
      if (value != '') { Text(value).fontSize(14).fontColor($r('app.color.text_tertiary')) }
      Text('›').fontSize(18).fontColor($r('app.color.text_tertiary')).margin({ left: 4 })
    }.width('100%').padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 14, bottom: 14 })
    .backgroundColor($r('app.color.card'))
  }
}
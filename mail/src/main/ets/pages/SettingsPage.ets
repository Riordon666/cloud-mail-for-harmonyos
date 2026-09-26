import { PromptAction } from '@kit.ArkUI'
import { bundleManager, common, ConfigurationConstant } from '@kit.AbilityKit'
import { CapsuleSegmentButtonV2, LengthMetrics, SegmentButtonV2Items } from '@kit.ArkUI'
import { pasteboard } from '@kit.BasicServicesKit'
import {
  HdsListItemCard,
  HdsNavDestination,
  HdsNavDestinationTitleMode,
  IconSize,
  IconStyleMode,
  PrefixIcon,
  ScrollEffectType,
  SuffixTextAndArrow,
  hdsMaterial
} from '@kit.UIDesignKit'
import Constants from '../common/Constants'
import { HuaweiAccountApi, HuaweiAccountBinding } from '../api/HuaweiAccountApi'
import { ProfileApi, ProfileTarget } from '../api/ProfileApi'
import { DateTimeUtils } from '../common/DateTimeUtils'
import { HuaweiAccountCache } from '../common/HuaweiAccountCache'
import { MailStatsStore } from '../common/MailStatsStore'
import { InstanceService } from '../common/InstanceService'
import { InstanceRegistry } from '../common/InstanceRegistry'
import { SessionService } from '../common/SessionService'
import { PlatformSessionService } from '../common/PlatformSessionService'
import { AccountBindingCleanup } from '../common/AccountBindingCleanup'
import { setAppColorMode } from '../mailability/MailAbility'

class ChangeLogItem {
  version: string
  date: string
  changes: string[]

  constructor(version: string, date: string, changes: string[]) {
    this.version = version
    this.date = date
    this.changes = changes
  }
}

@Component
export struct SettingsPage {
  scroller: Scroller = new Scroller()
  private aboutScroller: Scroller = new Scroller()
  private changeLogScroller: Scroller = new Scroller()
  private fallbackAccountScroller: Scroller = new Scroller()
  private fallbackSettingsScroller: Scroller = new Scroller()
  @Prop topContentInset: number = Constants.TITLE_BAR_HEIGHT_MINI
  @StorageLink('authEmail') authEmail: string = ''
  @StorageLink('authRole') authRole: string = 'user'
  @StorageLink('platformRole') platformRole: string = 'MEMBER'
  @StorageLink('authRoleName') authRoleName: string = '普通用户'
  @StorageLink('sessionRevision') @Watch('onSessionRevisionChanged') sessionRevision: number = 0
  @StorageLink('platformRevision') @Watch('onPlatformRevisionChanged') platformRevision: number = 0
  @StorageLink('activeInstanceName') activeInstanceName: string = ''
  @State profileTarget: ProfileTarget = new ProfileTarget()
  @StorageLink('currentColorMode') currentColorMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
  @State showLogoutConfirm: boolean = false
  @State showAboutSheet: boolean = false
  @State showAccountCenterSheet: boolean = false
  @State showPersonalSettingsSheet: boolean = false
  @State showPasswordDialog: boolean = false
  @State showDeleteAccountDialog: boolean = false
  @State profileSubmitting: boolean = false
  @State newPassword: string = ''
  @State confirmPassword: string = ''
  @State showChangeLogCover: boolean = false
  @State expandedChangeLogs: string[] = []
  @State huaweiNickName: string = ''
  @State huaweiAvatarUrl: string = ''
  @State huaweiPrimaryEmail: string = ''
  @State huaweiUserId: string = ''
  @State userCreateTime: string = ''
  @StorageLink('mailReceiveCount') receiveMailCount: number = 0
  @StorageLink('mailSentCount') sentMailCount: number = 0
  @StorageLink('mailStarCount') starMailCount: number = 0
  @StorageLink('mailReceiveCountReady') receiveMailCountReady: boolean = false
  @StorageLink('mailSentCountReady') sentMailCountReady: boolean = false
  @StorageLink('mailStarCountReady') starMailCountReady: boolean = false
  @State huaweiIdentityLoaded: boolean = false
  private identityRequestSequence: number = 0
  private readonly themeItems: SegmentButtonV2Items = new SegmentButtonV2Items([
    { text: $r('app.string.settings_theme_system') },
    { text: $r('app.string.settings_theme_light') },
    { text: $r('app.string.settings_theme_dark') }
  ])
  private readonly repositoryUrl: string = 'https://github.com/Riordon666/cloud-mail-for-harmonyos'
  private readonly telegramGroupUrl: string = 'https://t.me/CloudMailforHarmonyOSGroup'
  private readonly changeLogs: ChangeLogItem[] = [
    new ChangeLogItem('1.2.2', '2026.09.26', [
      '新增登录页切换实例的功能',
      '修复了切换未登录实例时导致当前邮箱退出的问题',
      '修复了退出第三方实例时注销请求发送到错误服务的问题',
      '修复了绑定流程中断后重启应用可能进入错误实例的问题',
      '修复了第三方实例用户华为账号授权过期后无法恢复的问题',
      '修复了账号设置未跟随当前实例、修改密码和删除账户目标不一致的问题',
      '修复了仅绑定第三方实例时个人设置不显示华为头像和昵称的问题',
      '修复了删除邮箱账户后残留华为绑定、影响后续登录的问题',
      '优化登录响应速度，减少已绑定主邮箱的重复验证和同账号重复资料授权'
    ]),
    new ChangeLogItem('1.2.1', '2026.09.12', [
      '优化邮件列表加载，支持兼容服务的摘要读取与按需正文缓存',
      '支持继续加载历史邮件，并完善邮件全文搜索',
      '新增邮件验证码卡片与一键复制',
      '新增用途子地址管理，支持为不同用途创建和复制收件地址',
      '完善草稿自动保存、附件恢复与发送前检查',
      '加强多邮箱实例的会话、邮件与附件隔离',
      '优化账号中心统计刷新与草稿卡片点击体验'
    ]),
    new ChangeLogItem('1.2.0', '2026.08.27', [
      '新增多邮箱服务实例接入与切换',
      '支持一个华为账号绑定多个实例主邮箱',
      '新增平台管理员多邮箱绑定数量与详情查询',
      '账号中心集中展示当前华为账号绑定的全部主邮箱',
      '优化第三方邮箱服务账号验证与地址兼容性',
      '优化邮箱服务入口尺寸与个人设置卡片样式'
    ]),
    new ChangeLogItem('1.1.1', '2026.07.29', [
      '新增华为账号中心，集中展示账号资料、邮箱统计与注册时间',
      '新增账号管理、账号设置和退出登录快捷入口',
      '在邮箱主页标题栏加入华为账号头像入口',
      '优化华为账号资料缓存与主邮箱显示',
      '软件内时间显示时区从服务器 UTC+0 调整为北京时间 UTC+8',
      '完善账号中心半模态背景模糊、布局间距和交互体验',
      '外观与主题改为跟随系统、浅色、深色三段式快捷切换',
      '账号中心邮件统计随收件、发送和星标操作实时刷新'
    ]),
    new ChangeLogItem('1.1.0', '2026.07.26', [
      '新增华为账号一键登录与主邮箱绑定',
      '新增管理员华为账号绑定查询与搜索',
      '个人设置展示华为账号头像、昵称、主邮箱和身份组',
      '完善登录安全与账号资料同步',
      '新增关于页面、官方社群入口与版本更新日志'
    ]),
    new ChangeLogItem('1.0.3', '2026.07.25', [
      '使用官方标题栏结构实现沉浸光感',
      '修复搜索邮件功能',
      '优化状态栏、标题栏和内容区间距'
    ]),
    new ChangeLogItem('1.0.2', '2026.07.21', [
      '新增收件箱下拉刷新',
      '修复星标状态实时刷新、取消星标和删除邮件',
      '完善个人设置身份组和主题显示'
    ]),
    new ChangeLogItem('1.0.1', '2026.07.21', [
      '更新云笺集应用名称与图标',
      '修复图文邮件显示',
      '优化邮件详情页悬浮工具栏'
    ]),
    new ChangeLogItem('1.0.0', '2026.07.11', [
      '首个公开测试版本',
      '支持收件箱、已发送、草稿箱和星标邮件',
      '支持邮件收发、账号管理与管理员功能'
    ])
  ]
  private toast: PromptAction = this.getUIContext().getPromptAction()
  onLogout?: () => void
  onManageAccounts?: () => void
  onSystemSettings?: () => void
  onManageUsers?: () => void
  onManageGlobalMails?: () => void
  onManageRoles?: () => void
  onOpenAnalytics?: () => void
  onManageRegistrationCodes?: () => void
  onManageHuaweiAccounts?: () => void
  onOpenAccountCenter?: () => void

  aboutToAppear(): void {
    AccountBindingCleanup.initialize(this.getUIContext().getHostContext() as common.UIAbilityContext)
    if (this.currentColorMode === undefined || this.currentColorMode === null) {
      this.currentColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
    }
    this.loadHuaweiIdentity()
  }

  aboutToDisappear(): void {
    this.identityRequestSequence++
  }

  private onSessionRevisionChanged(): void {
    this.showPasswordDialog = false
    this.showDeleteAccountDialog = false
    this.userCreateTime = ''
    this.loadHuaweiIdentity(true)
  }

  private onPlatformRevisionChanged(): void {
    this.loadHuaweiIdentity(true)
  }

  build() {
    Stack() {
      Scroll(this.scroller) {
        Column({ space: Constants.GAP_MEDIUM }) {
          Blank().height(this.topContentInset)

          Row({ space: Constants.GAP_MEDIUM }) {
            if (this.huaweiAvatarUrl !== '') {
              Image(this.huaweiAvatarUrl)
                .width(64)
                .height(64)
                .borderRadius(Constants.RADIUS_FULL)
                .objectFit(ImageFit.Cover)
            } else {
              Stack() {
                Circle()
                  .width(64)
                  .height(64)
                  .foregroundColor($r('app.color.primary_light'))
                Text(this.getHuaweiAvatarText())
                  .fontSize(28)
                  .fontColor($r('app.color.primary'))
              }
              .width(64)
              .height(64)
            }
            Column({ space: 6 }) {
              Text(this.getHuaweiDisplayName())
                .fontSize(Constants.FONT_SIZE_SUBTITLE)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(this.getHuaweiBindingText())
                .fontSize(Constants.FONT_SIZE_SMALL)
                .fontColor($r('app.color.text_secondary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Row({ space: Constants.GAP_SMALL }) {
                Text('身份组 · ' + this.getRoleLabel())
                  .fontSize(Constants.FONT_SIZE_SMALL)
                  .fontColor($r('app.color.tag_text'))
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .borderRadius(Constants.RADIUS_SMALL)
                  .backgroundColor(this.authRole === 'admin' ? $r('app.color.primary_light') : $r('app.color.info'))
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(Constants.PADDING_EDGE)
          .borderRadius(Constants.RADIUS_CARD)
          .backgroundColor($r('app.color.card'))
          .border({ width: 1, color: $r('app.color.divider') })
          .onClick(() => {
            if (this.onOpenAccountCenter) {
              this.onOpenAccountCenter()
            } else {
              this.showToast($r('app.string.account_center_unavailable'))
            }
          })

          this.SectionTitle('账户与偏好')
          Column() {
            this.SettingsCard('账号管理', '主邮箱与副邮箱', '', $r('sys.symbol.person'), () => { this.openAccountManagement() })
            Divider().color($r('app.color.divider')).margin({ left: 56, right: 16 })
            this.ThemeSettingsRow()
          }
          .width('100%')
          .borderRadius(Constants.RADIUS_CARD)
          .backgroundColor($r('app.color.card'))
          .border({ width: 1, color: $r('app.color.divider') })

          this.SectionTitle('隐私与支持')
          Column() {
            this.SettingsCard('隐私政策', '了解数据使用方式', '', $r('sys.symbol.lock_shield'), () => { this.openPrivacyPolicy() })
            Divider().color($r('app.color.divider')).margin({ left: 56, right: 16 })
            this.SettingsCard('关于', '云笺集 · HarmonyOS 原生邮件客户端', this.getAppVersionLabel(),
              $r('sys.symbol.questionmark_circle'), () => {
                this.showAboutSheet = true
              })
          }
          .width('100%')
          .borderRadius(Constants.RADIUS_CARD)
          .backgroundColor($r('app.color.card'))
          .border({ width: 1, color: $r('app.color.divider') })

          if (this.shouldShowAdminSection()) {
            this.SectionTitle('管理员专区')
            Column() {
              if (this.canManageCurrentInstance()) {
                this.SettingsRow('系统设置', '网站与注册策略', '', $r('sys.symbol.gearshape'), () => { this.openSystemSettings() })
                Divider().color($r('app.color.divider')).margin({ left: 56, right: 16 })
                this.SettingsRow('用户管理', '用户状态与角色', '', $r('sys.symbol.person'), () => { this.openUserManagement() })
                Divider().color($r('app.color.divider')).margin({ left: 56, right: 16 })
                this.SettingsRow('全部邮件', '全局邮件管理', '', $r('sys.symbol.envelope'), () => { this.openGlobalMailManagement() })
                Divider().color($r('app.color.divider')).margin({ left: 56, right: 16 })
                this.SettingsRow('角色权限', '角色与权限树', '', $r('sys.symbol.person_fill'), () => { this.openRoleManagement() })
                Divider().color($r('app.color.divider')).margin({ left: 56, right: 16 })
                this.SettingsRow('数据分析', '当前实例数据概览', '', $r('sys.symbol.doc'), () => { this.openAnalytics() })
                Divider().color($r('app.color.divider')).margin({ left: 56, right: 16 })
                this.SettingsRow('注册码管理', '生成与使用记录', '', $r('sys.symbol.star_fill'), () => { this.openRegistrationCodeManagement() })
              }
              if (this.canManageCurrentInstance() && this.canManageHuaweiBindings()) {
                Divider().color($r('app.color.divider')).margin({ left: 56, right: 16 })
              }
              if (this.canManageHuaweiBindings()) {
                this.SettingsRow('华为账号绑定', '查看华为账号与主邮箱关系', '', $r('sys.symbol.person_2'), () => {
                  this.openHuaweiAccountManagement()
                })
              }
            }
            .width('100%')
            .borderRadius(Constants.RADIUS_CARD)
            .backgroundColor($r('app.color.card'))
            .border({ width: 1, color: $r('app.color.divider') })
          }

          Button('退出登录', {
            type: ButtonType.Capsule,
            stateEffect: true,
            buttonStyle: ButtonStyleMode.EMPHASIZED,
            controlSize: ControlSize.NORMAL,
            role: ButtonRole.ERROR
          })
            .width('100%')
            .margin({ top: Constants.GAP_SMALL })
            .onClick(() => { this.showLogoutConfirm = true })

          Blank().height(Constants.PADDING_TAB_CONTENT_BOTTOM)
        }
        .width('100%')
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 4, bottom: 16 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .backgroundColor($r('app.color.background'))

      if (this.showLogoutConfirm) {
        this.LogoutConfirmDialog()
      }

    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
    .bindSheet($$this.showAboutSheet, this.AboutSheet(), {
      height: '84%',
      dragBar: false,
      showClose: false,
      blurStyle: BlurStyle.COMPONENT_THICK,
      maskColor: 0x1A000000,
      onDisappear: () => { this.showAboutSheet = false },
      enableOutsideInteractive: false
    })
  }

  @Builder
  private SectionTitle(title: string) {
    Text(title)
      .fontSize(Constants.FONT_SIZE_SMALL)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.text_tertiary'))
      .width('100%')
      .padding({ left: 4, top: 4 })
  }

  @Builder
  private SettingsRow(title: string, description: string, value: string, icon: Resource, onItemClick: () => void) {
    Row() {
      SymbolGlyph(icon)
        .fontSize(Constants.SIZE_ICON_MEDIUM)
        .fontColor([$r('app.color.text_primary')])
        .width(32)
        .margin({ right: 12 })

      Column({ space: 3 }) {
        Text(title)
          .fontSize(Constants.FONT_SIZE_SUBTITLE)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(description)
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (value !== '') {
        Text(value)
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
          .margin({ right: 6 })
      }
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(Constants.SIZE_ICON_SMALL)
        .fontColor([$r('app.color.text_tertiary')])
    }
    .width('100%')
    .height(68)
    .padding({ left: 16, right: 16 })
    .onClick(onItemClick)
  }

  @Builder
  private ThemeSettingsRow() {
    Column({ space: Constants.GAP_SMALL }) {
      Row() {
        SymbolGlyph($r('sys.symbol.paintbrush'))
          .fontSize(Constants.SIZE_ICON_MEDIUM)
          .fontColor([$r('app.color.text_primary')])
          .width(32)
          .margin({ right: 12 })

        Column({ space: 3 }) {
          Text('外观与主题')
            .fontSize(Constants.FONT_SIZE_SUBTITLE)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
          Text('主题与显示模式')
            .fontSize(Constants.FONT_SIZE_SMALL)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      CapsuleSegmentButtonV2({
        items: this.themeItems,
        selectedIndex: this.getThemeSelectedIndex(),
        onItemClicked: (index: number): void => {
          this.selectThemeByIndex(index)
        },
        itemFontSize: LengthMetrics.fp(12),
        itemSelectedFontSize: LengthMetrics.fp(12),
        itemMinHeight: LengthMetrics.vp(32),
        itemPadding: {
          top: LengthMetrics.vp(0),
          bottom: LengthMetrics.vp(0),
          start: LengthMetrics.vp(5),
          end: LengthMetrics.vp(5)
        },
        buttonMinHeight: LengthMetrics.vp(36),
        buttonPadding: LengthMetrics.vp(2)
      })
        .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }

  @Builder
  private SettingsCard(title: string, description: string, value: string, icon: ResourceStr, onItemClick: () => void) {
    Column() {
      HdsListItemCard({
        prefixItem: new PrefixIcon({
          iconSize: IconSize.SYSTEM_ICON,
          iconValue: { symbol: icon }
        }),
        textItem: {
          primaryText: { text: title },
          secondaryText: { text: description }
        },
        suffixItem: new SuffixTextAndArrow({ text: value }),
        cardHeight: 72,
        cardBackgroundColor: $r('app.color.card'),
        cardBorderRadius: Constants.RADIUS_CARD,
        onClick: onItemClick
      })
    }
    .width('100%')
    .padding({ top: Constants.GAP_SMALL, bottom: Constants.GAP_SMALL })
  }

  @Builder
  private AccountCenterSheet() {
    HdsNavDestination() {
      Column() {
        Scroll(this.fallbackAccountScroller) {
          Column({ space: Constants.GAP_MEDIUM }) {
            Column({ space: 6 }) {
              if (this.huaweiAvatarUrl !== '') {
                Image(this.huaweiAvatarUrl)
                  .width(88)
                  .height(88)
                  .borderRadius(Constants.RADIUS_FULL)
                  .objectFit(ImageFit.Cover)
                  .shadow(Constants.SHADOW_CARD)
              } else {
                Stack() {
                  Circle()
                    .width(88)
                    .height(88)
                    .foregroundColor($r('app.color.primary_light'))
                  Text(this.getHuaweiAvatarText())
                    .fontSize(34)
                    .fontColor($r('app.color.primary'))
                }
                .width(88)
                .height(88)
              }
              Text(this.getHuaweiDisplayName())
                .fontSize(Constants.FONT_SIZE_TITLE)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(this.getPrimaryEmail())
                .fontSize(Constants.FONT_SIZE_COMMON)
                .fontColor($r('app.color.text_secondary'))
                .maxLines(2)
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding({ bottom: 8 })

            Grid() {
              GridItem() {
                this.AccountStatCard('注册时间', this.getRegistrationTime(), $r('sys.symbol.clock'))
              }
              GridItem() {
                this.AccountStatCard('收到邮件', this.getMailCountText(this.receiveMailCount, this.receiveMailCountReady), $r('sys.symbol.envelope'))
              }
              GridItem() {
                this.AccountStatCard('发送邮件', this.getMailCountText(this.sentMailCount, this.sentMailCountReady), $r('sys.symbol.paperplane'))
              }
              GridItem() {
                this.AccountStatCard('星标邮件', this.getMailCountText(this.starMailCount, this.starMailCountReady), $r('sys.symbol.star'))
              }
            }
            .columnsTemplate('1fr 1fr')
            .columnsGap(Constants.GAP_MEDIUM)
            .rowsGap(Constants.GAP_MEDIUM)
            .width('100%')

            Column() {
              this.AccountCenterActionRow('账号管理', '主邮箱与副邮箱', $r('sys.symbol.person_2'), () => {
                this.showAccountCenterSheet = false
                this.openAccountManagement()
              })
              Divider().color($r('app.color.divider')).margin({ left: 56, right: 16 })
              this.AccountCenterActionRow('账号设置', '修改密码与删除账户', $r('sys.symbol.gearshape'), () => {
                this.showPersonalSettingsSheet = true
              })
            }
            .width('100%')
            .backgroundColor($r('app.color.card'))
            .borderRadius(Constants.RADIUS_CARD)
            .border({ width: 1, color: $r('app.color.divider') })

            Button('退出登录', { type: ButtonType.Capsule, stateEffect: true })
              .width('100%')
              .height(48)
              .fontSize(Constants.FONT_SIZE_SUBTITLE)
              .fontColor($r('sys.color.icon_on_primary'))
              .backgroundColor($r('app.color.danger'))
              .onClick(() => {
                this.showAccountCenterSheet = false
                this.showLogoutConfirm = true
              })

            Blank().height(24)
          }
          .width('100%')
          .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, bottom: 24 })
        }
        .width('100%')
        .height('100%')
        .clip(false)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background'))
    }
    .titleBar({
      content: {
        title: { mainTitle: '账号中心' },
        menu: {
          maxCount: 1,
          value: [{
            content: {
              label: '关闭',
              icon: $r('sys.symbol.xmark'),
              type: IconStyleMode.SMALL,
              isEnabled: true,
              action: () => { this.showAccountCenterSheet = false }
            }
          }]
        }
      },
      enableComponentSafeArea: true,
      style: {
        scrollEffectOpts: {
          enableScrollEffect: true,
          scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
          blurEffectiveStartOffset: LengthMetrics.vp(0),
          blurEffectiveEndOffset: LengthMetrics.vp(20)
        },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        },
        originalStyle: {
          backgroundStyle: { maskExtraHeight: 0 },
          contentStyle: {
            titleStyle: { mainTitleColor: $r('app.color.text_primary') },
            menuStyle: { iconColor: $r('app.color.text_primary') },
            backIconStyle: { iconColor: $r('app.color.text_primary') }
          }
        },
        scrollEffectStyle: {
          backgroundStyle: { maskExtraHeight: 0 },
          contentStyle: {
            titleStyle: { mainTitleColor: $r('app.color.text_primary') },
            menuStyle: { iconColor: $r('app.color.text_primary') },
            backIconStyle: { iconColor: $r('app.color.text_primary') }
          }
        }
      }
    })
    .hideBackButton(true)
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .bindToScrollable([this.fallbackAccountScroller])
    .onBackPressed(() => {
      this.showAccountCenterSheet = false
      return true
    })
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
    .bindSheet($$this.showPersonalSettingsSheet, this.PersonalSettingsSheet(), {
      height: '84%',
      dragBar: false,
      showClose: false,
      blurStyle: BlurStyle.COMPONENT_THICK,
      maskColor: 0x1A000000,
      onDisappear: () => { this.showPersonalSettingsSheet = false },
      enableOutsideInteractive: false
    })
  }

  @Builder
  private AccountStatCard(title: string, value: string, icon: Resource) {
    Column({ space: Constants.GAP_SMALL }) {
      Row({ space: 6 }) {
        SymbolGlyph(icon)
          .fontSize(Constants.SIZE_ICON_SMALL)
          .fontColor([$r('app.color.primary')])
        Text(title)
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)

      Text(value)
        .fontSize(Constants.FONT_SIZE_COMMON)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .maxLines(2)
        .textAlign(TextAlign.Center)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(82)
    .padding(Constants.PADDING_CARD)
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.card'))
    .borderRadius(Constants.RADIUS_CARD)
    .border({ width: 1, color: $r('app.color.divider') })
  }

  @Builder
  private AccountCenterActionRow(title: ResourceStr, description: ResourceStr, icon: Resource, action: () => void) {
    Row() {
      SymbolGlyph(icon)
        .fontSize(Constants.SIZE_ICON_MEDIUM)
        .fontColor([$r('app.color.text_primary')])
        .width(32)
        .margin({ right: 12 })
      Column({ space: 3 }) {
        Text(title)
          .fontSize(Constants.FONT_SIZE_SUBTITLE)
          .fontColor($r('app.color.text_primary'))
        Text(description)
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(Constants.SIZE_ICON_SMALL)
        .fontColor([$r('app.color.text_tertiary')])
    }
    .width('100%')
    .height(68)
    .padding({ left: 16, right: 16 })
    .onClick(action)
  }

  @Builder
  private PersonalSettingsSheet() {
    Stack() {
      HdsNavDestination() {
        Scroll(this.fallbackSettingsScroller) {
          Column({ space: Constants.GAP_MEDIUM }) {
            this.SectionTitle('账号信息')
            Column() {
              this.ProfileInfoRow('华为账号', this.getHuaweiDisplayName())
              Divider().color($r('app.color.divider')).margin({ left: 16, right: 16 })
              this.ProfileInfoRow($r('app.string.profile_current_service'), this.activeInstanceName)
              Divider().color($r('app.color.divider')).margin({ left: 16, right: 16 })
              this.ProfileInfoRow($r('app.string.profile_current_mailbox'), this.getPrimaryEmailValue())
            }
            .width('100%')
            .backgroundColor($r('app.color.card'))
            .borderRadius(Constants.RADIUS_CARD)
            .border({ width: 1, color: $r('app.color.divider') })

            this.SectionTitle('安全设置')
            Column() {
              this.AccountCenterActionRow('修改密码', $r('app.string.profile_password_scope'), $r('sys.symbol.lock'), () => {
                this.openProfileDialog(false)
              })
            }
            .width('100%')
            .backgroundColor($r('app.color.card'))
            .borderRadius(Constants.RADIUS_CARD)
            .border({ width: 1, color: $r('app.color.divider') })

            this.SectionTitle('危险操作')
            Column({ space: Constants.GAP_MEDIUM }) {
              Column({ space: 6 }) {
                Text('删除账户')
                  .fontSize(Constants.FONT_SIZE_SUBTITLE)
                  .fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.danger'))
                Text($r('app.string.profile_delete_scope'))
                  .fontSize(Constants.FONT_SIZE_SMALL)
                  .fontColor($r('app.color.text_secondary'))
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              Button('删除账户', { type: ButtonType.Capsule, stateEffect: true })
                .width('100%')
                .height(44)
                .fontColor($r('sys.color.icon_on_primary'))
                .backgroundColor($r('app.color.danger'))
                .onClick(() => { this.openProfileDialog(true) })
            }
            .width('100%')
            .padding(Constants.PADDING_EDGE)
            .backgroundColor($r('app.color.card'))
            .borderRadius(Constants.RADIUS_CARD)
            .border({ width: 1, color: $r('app.color.divider') })

            Blank().height(24)
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)
          .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 8, bottom: 24 })
        }
        .width('100%')
        .height('100%')
        .clip(false)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      .titleBar({
        content: {
          title: { mainTitle: '账号设置' },
          menu: {
            maxCount: 1,
            value: [{
              content: {
                label: '关闭',
                icon: $r('sys.symbol.xmark'),
                type: IconStyleMode.SMALL,
                isEnabled: true,
                action: () => { this.showPersonalSettingsSheet = false }
              }
            }]
          }
        },
        enableComponentSafeArea: true,
        style: {
          scrollEffectOpts: {
            enableScrollEffect: true,
            scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
            blurEffectiveStartOffset: LengthMetrics.vp(0),
            blurEffectiveEndOffset: LengthMetrics.vp(20)
          },
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          },
          originalStyle: {
            backgroundStyle: { maskExtraHeight: 0 },
            contentStyle: {
              titleStyle: { mainTitleColor: $r('app.color.text_primary') },
              menuStyle: { iconColor: $r('app.color.text_primary') },
              backIconStyle: { iconColor: $r('app.color.text_primary') }
            }
          },
          scrollEffectStyle: {
            backgroundStyle: { maskExtraHeight: 0 },
            contentStyle: {
              titleStyle: { mainTitleColor: $r('app.color.text_primary') },
              menuStyle: { iconColor: $r('app.color.text_primary') },
              backIconStyle: { iconColor: $r('app.color.text_primary') }
            }
          }
        }
      })
      .hideBackButton(true)
      .titleMode(HdsNavDestinationTitleMode.MODAL)
      .bindToScrollable([this.fallbackSettingsScroller])
      .onBackPressed(() => {
        this.showPersonalSettingsSheet = false
        return true
      })
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background'))

      if (this.showPasswordDialog) {
        this.ChangePasswordDialog()
      }
      if (this.showDeleteAccountDialog) {
        this.DeleteAccountDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private ProfileInfoRow(label: ResourceStr, value: string) {
    Row({ space: Constants.GAP_MEDIUM }) {
      Text(label)
        .fontSize(Constants.FONT_SIZE_COMMON)
        .fontColor($r('app.color.text_secondary'))
        .width(72)
      Text(value)
        .fontSize(Constants.FONT_SIZE_COMMON)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }

  @Builder
  private ChangePasswordDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.overlay'))
      Column({ space: Constants.GAP_MEDIUM }) {
        Text('修改密码')
          .fontSize(Constants.FONT_SIZE_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        Text(this.profileTarget.displayName + ' · ' + this.profileTarget.email)
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .wordBreak(WordBreak.BREAK_ALL)
        TextInput({ text: this.newPassword, placeholder: '输入新密码（至少6位）' })
          .type(InputType.Password)
          .height(48)
          .backgroundColor($r('app.color.background'))
          .borderRadius(Constants.RADIUS_SMALL)
          .onChange((value: string) => { this.newPassword = value })
        TextInput({ text: this.confirmPassword, placeholder: '再次输入新密码' })
          .type(InputType.Password)
          .height(48)
          .backgroundColor($r('app.color.background'))
          .borderRadius(Constants.RADIUS_SMALL)
          .onChange((value: string) => { this.confirmPassword = value })
        Row() {
          Button('取消', { type: ButtonType.Normal, stateEffect: true })
            .layoutWeight(1)
            .height(44)
            .enabled(!this.profileSubmitting)
            .fontColor($r('app.color.text_primary'))
            .backgroundColor($r('app.color.background'))
            .onClick(() => { this.showPasswordDialog = false })
          Button(this.profileSubmitting ? '保存中' : '保存', { type: ButtonType.Normal, stateEffect: true })
            .layoutWeight(1)
            .height(44)
            .enabled(!this.profileSubmitting)
            .fontColor($r('sys.color.icon_on_primary'))
            .backgroundColor($r('app.color.primary'))
            .margin({ left: Constants.GAP_MEDIUM })
            .onClick(() => { this.changePassword() })
        }
      }
      .width('100%')
      .margin({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
      .padding(20)
      .backgroundColor($r('app.color.card'))
      .borderRadius(Constants.RADIUS_CARD)
      .shadow(Constants.SHADOW_CARD)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private DeleteAccountDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.overlay'))
      Column({ space: Constants.GAP_MEDIUM }) {
        Text('确认删除账户')
          .fontSize(Constants.FONT_SIZE_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        Text($r('app.string.profile_delete_target_confirm', this.profileTarget.displayName, this.profileTarget.email))
          .fontSize(Constants.FONT_SIZE_COMMON)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
        Row() {
          Button('取消', { type: ButtonType.Normal, stateEffect: true })
            .layoutWeight(1)
            .height(44)
            .enabled(!this.profileSubmitting)
            .fontColor($r('app.color.text_primary'))
            .backgroundColor($r('app.color.background'))
            .onClick(() => { this.showDeleteAccountDialog = false })
          Button(this.profileSubmitting ? '删除中' : '永久删除', { type: ButtonType.Normal, stateEffect: true })
            .layoutWeight(1)
            .height(44)
            .enabled(!this.profileSubmitting)
            .fontColor($r('sys.color.icon_on_primary'))
            .backgroundColor($r('app.color.danger'))
            .margin({ left: Constants.GAP_MEDIUM })
            .onClick(() => { this.deleteAccount() })
        }
      }
      .width('100%')
      .margin({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
      .padding(20)
      .backgroundColor($r('app.color.card'))
      .borderRadius(Constants.RADIUS_CARD)
      .shadow(Constants.SHADOW_CARD)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private AboutSheet() {
    HdsNavDestination() {
      Scroll(this.aboutScroller) {
        Column({ space: Constants.GAP_MEDIUM }) {
          Column({ space: Constants.GAP_SMALL }) {
            Image($r('app.media.startIcon'))
              .width(96)
              .height(96)
              .borderRadius(24)
              .objectFit(ImageFit.Cover)
              .shadow(Constants.SHADOW_CARD)

            Text('云笺集')
              .fontSize(Constants.FONT_SIZE_TITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))

            Text('版本 ' + this.getAppVersionName())
              .fontSize(Constants.FONT_SIZE_COMMON)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .height(196)
          .justifyContent(FlexAlign.Center)

        Column() {
          this.AboutActionRow('联系我', '2717831140@qq.com', '点击复制', () => {
            this.copyText('2717831140@qq.com', '联系邮箱')
          })
          Divider().color($r('app.color.divider')).margin({ left: 16, right: 16 })
          this.AboutActionRow('QQ交流群', '1075732184', '点击复制', () => {
            this.copyText('1075732184', 'QQ群号')
          })
          Divider().color($r('app.color.divider')).margin({ left: 16, right: 16 })
          this.AboutActionRow('官方TG交流群', 't.me/CloudMailforHarmonyOSGroup', '点击加入', () => {
            this.openTelegramGroup()
          })
          Divider().color($r('app.color.divider')).margin({ left: 16, right: 16 })
          this.AboutActionRow('开源仓库', 'Riordon666/cloud-mail-for-harmonyos', '', () => {
            this.openRepository()
          })
          Divider().color($r('app.color.divider')).margin({ left: 16, right: 16 })
          Row() {
            Text('更新日志')
              .fontSize(Constants.FONT_SIZE_SUBTITLE)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
            Text('查看全部版本')
              .fontSize(Constants.FONT_SIZE_SMALL)
              .fontColor($r('app.color.text_secondary'))
              .margin({ right: 8 })
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(Constants.SIZE_ICON_SMALL)
              .fontColor([$r('app.color.text_tertiary')])
          }
          .width('100%')
          .height(64)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            this.showChangeLogCover = true
          })
          .bindSheet($$this.showChangeLogCover, this.ChangeLogSheet(), {
            height: '84%',
            dragBar: false,
            showClose: false,
            blurStyle: BlurStyle.COMPONENT_THICK,
            maskColor: 0x1A000000,
            onDisappear: () => { this.showChangeLogCover = false },
            enableOutsideInteractive: false
          })
        }
        .width('100%')
        .backgroundColor($r('app.color.card'))
        .borderRadius(Constants.RADIUS_CARD)
        .border({ width: 1, color: $r('app.color.divider') })

        Text('云笺集 · HarmonyOS 原生邮件客户端')
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_tertiary'))
          .margin({ top: 4, bottom: 24 })
        }
        .width('100%')
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, bottom: 24 })
      }
      .width('100%')
      .height('100%')
      .clip(false)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .backgroundColor($r('app.color.background'))
    }
    .titleBar({
      content: {
        title: { mainTitle: '关于' },
        menu: {
          maxCount: 1,
          value: [{
            content: {
              label: '关闭',
              icon: $r('sys.symbol.xmark'),
              type: IconStyleMode.SMALL,
              isEnabled: true,
              action: () => {
                this.showAboutSheet = false
              }
            }
          }]
        }
      },
      enableComponentSafeArea: true,
      style: {
        scrollEffectOpts: {
          enableScrollEffect: true,
          scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
          blurEffectiveStartOffset: LengthMetrics.vp(0),
          blurEffectiveEndOffset: LengthMetrics.vp(20)
        },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        },
        originalStyle: {
          backgroundStyle: { maskExtraHeight: 0 },
          contentStyle: {
            titleStyle: { mainTitleColor: $r('app.color.text_primary') },
            menuStyle: { iconColor: $r('app.color.text_primary') },
            backIconStyle: { iconColor: $r('app.color.text_primary') }
          }
        },
        scrollEffectStyle: {
          backgroundStyle: { maskExtraHeight: 0 },
          contentStyle: {
            titleStyle: { mainTitleColor: $r('app.color.text_primary') },
            menuStyle: { iconColor: $r('app.color.text_primary') },
            backIconStyle: { iconColor: $r('app.color.text_primary') }
          }
        }
      }
    })
    .hideBackButton(true)
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .bindToScrollable([this.aboutScroller])
    .onBackPressed(() => {
      this.showAboutSheet = false
      return true
    })
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  private AboutActionRow(title: string, value: string, hint: string, onItemClick: () => void) {
    Row() {
      Column({ space: 3 }) {
        Text(title)
          .fontSize(Constants.FONT_SIZE_SUBTITLE)
          .fontColor($r('app.color.text_primary'))
        Text(value)
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (hint !== '') {
        Text(hint)
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.primary'))
          .margin({ right: 8 })
      }
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(Constants.SIZE_ICON_SMALL)
        .fontColor([$r('app.color.text_tertiary')])
    }
    .width('100%')
    .height(72)
    .padding({ left: 16, right: 16 })
    .onClick(onItemClick)
  }

  @Builder
  private ChangeLogSheet() {
    HdsNavDestination() {
      List({ scroller: this.changeLogScroller, space: Constants.GAP_MEDIUM }) {
        ListItem() {
          Column({ space: Constants.GAP_MEDIUM }) {
            Image($r('app.media.startIcon'))
              .width(96)
              .height(96)
              .borderRadius(24)
              .objectFit(ImageFit.Cover)
              .shadow(Constants.SHADOW_CARD)

            Text('当前版本：' + this.getAppVersionName() + ' (' + this.getAppVersionCode().toString() + ')')
              .fontSize(Constants.FONT_SIZE_SUBTITLE)
              .fontColor($r('app.color.text_primary'))
          }
          .width('100%')
          .height(196)
          .justifyContent(FlexAlign.Center)
        }

        ForEach(this.changeLogs, (item: ChangeLogItem) => {
          ListItem() {
            this.ChangeLogCard(item)
          }
          .width('100%')
        }, (item: ChangeLogItem): string => item.version)

        ListItem() {
          Row().height(32)
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
      .alignListItem(ListItemAlign.Center)
      .cachedCount(4, true)
      .clip(false)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .backgroundColor($r('app.color.background'))
    }
    .titleBar({
      content: {
        title: { mainTitle: '更新日志' },
        menu: {
          maxCount: 1,
          value: [{
            content: {
              label: '关闭',
              icon: $r('sys.symbol.xmark'),
              type: IconStyleMode.SMALL,
              isEnabled: true,
              action: () => {
                this.showChangeLogCover = false
              }
            }
          }]
        }
      },
      enableComponentSafeArea: true,
      style: {
        scrollEffectOpts: {
          enableScrollEffect: true,
          scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
          blurEffectiveStartOffset: LengthMetrics.vp(0),
          blurEffectiveEndOffset: LengthMetrics.vp(20)
        },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        },
        originalStyle: {
          backgroundStyle: { maskExtraHeight: 0 },
          contentStyle: {
            titleStyle: { mainTitleColor: $r('app.color.text_primary') },
            menuStyle: { iconColor: $r('app.color.text_primary') },
            backIconStyle: { iconColor: $r('app.color.text_primary') }
          }
        },
        scrollEffectStyle: {
          backgroundStyle: { maskExtraHeight: 0 },
          contentStyle: {
            titleStyle: { mainTitleColor: $r('app.color.text_primary') },
            menuStyle: { iconColor: $r('app.color.text_primary') },
            backIconStyle: { iconColor: $r('app.color.text_primary') }
          }
        }
      }
    })
    .hideBackButton(true)
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .bindToScrollable([this.changeLogScroller])
    .onBackPressed(() => {
      this.showChangeLogCover = false
      return true
    })
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  private ChangeLogCard(item: ChangeLogItem) {
    Column() {
      Row() {
        Text(item.version + '  ' + item.date)
          .fontSize(Constants.FONT_SIZE_SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        SymbolGlyph(this.isChangeLogExpanded(item.version) ?
          $r('sys.symbol.chevron_down') : $r('sys.symbol.chevron_right'))
          .fontSize(Constants.SIZE_ICON_SMALL)
          .fontColor([$r('app.color.text_primary')])
      }
      .width('100%')
      .height(64)
      .padding({ left: 16, right: 16 })
      .onClick(() => {
        this.toggleChangeLog(item.version)
      })

      if (this.isChangeLogExpanded(item.version)) {
        Divider()
          .color($r('app.color.divider'))
          .margin({ left: 16, right: 16 })
        Column({ space: 8 }) {
          ForEach(item.changes, (change: string) => {
            Row({ space: 8 }) {
              Circle()
                .width(5)
                .height(5)
                .foregroundColor($r('app.color.primary'))
                .margin({ top: 5 })
              Text(change)
                .fontSize(Constants.FONT_SIZE_COMMON)
                .fontColor($r('app.color.text_secondary'))
                .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
          })
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 14, bottom: 18 })
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .backgroundColor($r('app.color.card'))
    .borderRadius(Constants.RADIUS_CARD)
    .border({ width: 1, color: $r('app.color.divider') })
  }

  private isChangeLogExpanded(version: string): boolean {
    return this.expandedChangeLogs.includes(version)
  }

  private toggleChangeLog(version: string): void {
    if (this.isChangeLogExpanded(version)) {
      this.expandedChangeLogs = this.expandedChangeLogs.filter((item: string): boolean => item !== version)
      return
    }
    this.expandedChangeLogs = [...this.expandedChangeLogs, version]
  }

  @Builder
  private LogoutConfirmDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.overlay'))

      Column({ space: Constants.GAP_MEDIUM }) {
        Text('确认退出登录')
          .fontSize(Constants.FONT_SIZE_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        Text('退出后需要重新使用华为账号登录才能进入邮箱。')
          .fontSize(Constants.FONT_SIZE_COMMON)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
        Row() {
          Button('取消', { type: ButtonType.Normal, stateEffect: true })
            .layoutWeight(1)
            .height(44)
            .fontColor($r('app.color.text_primary'))
            .backgroundColor($r('app.color.background'))
            .onClick(() => { this.showLogoutConfirm = false })
          Button('退出登录', { type: ButtonType.Normal, stateEffect: true })
            .layoutWeight(1)
            .height(44)
            .fontColor($r('sys.color.icon_on_primary'))
            .backgroundColor($r('app.color.danger'))
            .margin({ left: Constants.GAP_MEDIUM })
            .onClick(() => { this.confirmLogout() })
        }
        .width('100%')
      }
      .width('100%')
      .margin({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
      .padding(20)
      .backgroundColor($r('app.color.card'))
      .borderRadius(Constants.RADIUS_CARD)
      .shadow(Constants.SHADOW_CARD)
    }
    .width('100%')
    .height('100%')
  }

  private getThemeSelectedIndex(): number {
    if (this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT) {
      return 1
    }
    if (this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
      return 2
    }
    return 0
  }

  private selectThemeByIndex(index: number): void {
    if (index === 1) {
      this.selectTheme(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)
      return
    }
    if (index === 2) {
      this.selectTheme(ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
      return
    }
    this.selectTheme(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
  }

  private getRoleLabel(): string {
    const roleName: string = this.authRoleName.trim()
    if (roleName === 'admin') {
      return '管理员'
    }
    return roleName === '' ? '普通用户' : roleName
  }

  private getAppVersionLabel(): string {
    return 'v' + this.getAppVersionName()
  }

  private getAppVersionName(): string {
    try {
      const info: bundleManager.BundleInfo = bundleManager.getBundleInfoForSelfSync(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT)
      return info.versionName
    } catch (err) {
      console.error('get app version failed')
      return '1.2.2'
    }
  }

  private getAppVersionCode(): number {
    try {
      const info: bundleManager.BundleInfo = bundleManager.getBundleInfoForSelfSync(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT)
      return info.versionCode
    } catch (err) {
      console.error('get app version code failed')
      return 1020002
    }
  }

  private selectTheme(mode: number): void {
    this.currentColorMode = mode
    setAppColorMode(mode)
  }

  private openAccountManagement(): void {
    if (this.onManageAccounts) {
      this.onManageAccounts()
    }
  }

  private canManageCurrentInstance(): boolean {
    return this.authRole === 'admin'
  }

  private canManageHuaweiBindings(): boolean {
    return this.platformRole === 'SUPER_ADMIN'
  }

  private shouldShowAdminSection(): boolean {
    return this.canManageCurrentInstance() || this.canManageHuaweiBindings()
  }

  private openSystemSettings(): void {
    if (!this.canManageCurrentInstance()) {
      this.showToast('当前邮箱服务无管理员权限')
      return
    }
    if (this.onSystemSettings) {
      this.onSystemSettings()
    }
  }

  private openUserManagement(): void {
    if (!this.canManageCurrentInstance()) {
      this.showToast('当前邮箱服务无管理员权限')
      return
    }
    if (this.onManageUsers) {
      this.onManageUsers()
    }
  }

  private openGlobalMailManagement(): void {
    if (!this.canManageCurrentInstance()) {
      this.showToast('当前邮箱服务无管理员权限')
      return
    }
    if (this.onManageGlobalMails) {
      this.onManageGlobalMails()
    }
  }

  private openRoleManagement(): void {
    if (!this.canManageCurrentInstance()) {
      this.showToast('当前邮箱服务无管理员权限')
      return
    }
    if (this.onManageRoles) {
      this.onManageRoles()
    }
  }

  private openAnalytics(): void {
    if (!this.canManageCurrentInstance()) {
      this.showToast('当前邮箱服务无管理员权限')
      return
    }
    if (this.onOpenAnalytics) {
      this.onOpenAnalytics()
    }
  }

  private openRegistrationCodeManagement(): void {
    if (!this.canManageCurrentInstance()) {
      this.showToast('当前邮箱服务无管理员权限')
      return
    }
    if (this.onManageRegistrationCodes) {
      this.onManageRegistrationCodes()
    }
  }

  private openHuaweiAccountManagement(): void {
    if (!this.canManageHuaweiBindings()) {
      this.showToast('仅平台超级管理员可查看华为账号绑定')
      return
    }
    if (this.onManageHuaweiAccounts) {
      this.onManageHuaweiAccounts()
    }
  }

  private async loadHuaweiIdentity(forceRefresh: boolean = false): Promise<void> {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
    const ownerEmail: string = InstanceService.getAnchorEmail()
    const sourceToken: string = InstanceService.getAnchorToken()
    const requestRevision: number = this.sessionRevision
    const requestId: number = ++this.identityRequestSequence
    const identity: string = PlatformSessionService.getHuaweiUserId()
    const cacheOwner: string = identity === '' ? ownerEmail : identity + '|' + ownerEmail
    this.applyPlatformIdentity()
    if (ownerEmail === '' || sourceToken === '') {
      this.huaweiIdentityLoaded = true
      return
    }
    const cachedBinding: HuaweiAccountBinding | null = HuaweiAccountCache.load(context, cacheOwner)
    if (cachedBinding !== null && cachedBinding.primaryEmail === ownerEmail) {
      this.applyHuaweiIdentity(cachedBinding, false)
      if (this.canUseAnchorAccountData(cachedBinding.primaryEmail)) {
        MailStatsStore.syncMissing(cachedBinding.receiveCount, cachedBinding.sentCount, cachedBinding.starCount)
      }
      this.huaweiIdentityLoaded = true
    }
    if (!forceRefresh && !HuaweiAccountCache.shouldRefresh(cacheOwner)) {
      this.huaweiIdentityLoaded = true
      return
    }
    try {
      const binding: HuaweiAccountBinding | null = await HuaweiAccountApi.current()
      if (requestId !== this.identityRequestSequence || requestRevision !== this.sessionRevision ||
        ownerEmail !== InstanceService.getAnchorEmail() || sourceToken !== InstanceService.getAnchorToken() ||
        identity !== PlatformSessionService.getHuaweiUserId()) {
        return
      }
      this.huaweiIdentityLoaded = true
      // /huawei/me exposes a masked display ID, not the full platform identity.
      if (binding === null || binding.primaryEmail !== ownerEmail) {
        return
      }
      this.applyHuaweiIdentity(binding)
      HuaweiAccountCache.save(context, cacheOwner, binding)
      HuaweiAccountCache.markRefreshed(cacheOwner)
    } catch (err) {
      if (requestId === this.identityRequestSequence) {
        this.huaweiIdentityLoaded = true
        console.error('load Huawei identity failed')
      }
    }
  }

  private applyHuaweiIdentity(binding: HuaweiAccountBinding, syncStats: boolean = true): void {
    this.huaweiNickName = PlatformSessionService.getNickName() === '' ?
      binding.nickName : PlatformSessionService.getNickName()
    this.huaweiAvatarUrl = PlatformSessionService.getAvatarUrl() === '' ?
      binding.avatarUrl : PlatformSessionService.getAvatarUrl()
    this.huaweiPrimaryEmail = binding.primaryEmail
    this.huaweiUserId = PlatformSessionService.getHuaweiUserId() === '' ?
      binding.huaweiUserId : PlatformSessionService.getHuaweiUserId()
    this.userCreateTime = this.canUseAnchorAccountData(binding.primaryEmail) ? binding.userCreateTime : ''
    if (syncStats && this.canUseAnchorAccountData(binding.primaryEmail)) {
      MailStatsStore.sync(binding.receiveCount, binding.sentCount, binding.starCount)
    }
  }

  private applyPlatformIdentity(): void {
    const identity: string = PlatformSessionService.getHuaweiUserId()
    if (this.huaweiUserId !== identity) {
      this.huaweiPrimaryEmail = ''
      this.userCreateTime = ''
    }
    this.huaweiUserId = identity
    this.huaweiNickName = PlatformSessionService.getNickName()
    this.huaweiAvatarUrl = PlatformSessionService.getAvatarUrl()
    if (identity !== '') { this.huaweiIdentityLoaded = true }
  }

  private getHuaweiDisplayName(): string {
    if (!this.huaweiIdentityLoaded) {
      return '正在读取华为账号'
    }
    if (this.huaweiNickName !== '') {
      return this.huaweiNickName
    }
    return this.getUIContext().getHostContext()!.resourceManager.getStringSync($r('app.string.account_huawei_user').id)
  }

  private getHuaweiBindingText(): string {
    if (!this.huaweiIdentityLoaded) {
      return '正在读取绑定信息'
    }
    const email: string = this.authEmail
    return email === '' ? '暂未绑定主邮箱' : '主邮箱：' + email
  }

  private getPrimaryEmail(): string {
    const email: string = this.getPrimaryEmailValue()
    return email === '' ? '暂未绑定主邮箱' : '主邮箱：' + email
  }

  private getPrimaryEmailValue(): string {
    return this.authEmail
  }

  private getRegistrationTime(): string {
    const fallback: string = this.getUnavailableStatText()
    return this.canUseAnchorAccountData(this.huaweiPrimaryEmail) ?
      DateTimeUtils.formatUtcDateTime(this.userCreateTime, fallback) : fallback
  }

  private canUseAnchorAccountData(primaryEmail: string): boolean {
    return primaryEmail !== '' && SessionService.getActiveInstanceId() === InstanceRegistry.getDefaultInstanceId() &&
      primaryEmail === ((AppStorage.get('authEmail') as string) || '') &&
      primaryEmail === InstanceService.getAnchorEmail()
  }

  private getMailCountText(value: number, ready: boolean): string {
    return ready && Number.isFinite(value) && value >= 0 ? value.toString() : this.getUnavailableStatText()
  }

  private getUnavailableStatText(): string {
    return this.getUIContext().getHostContext()!.resourceManager.getStringSync($r('app.string.account_stats_unavailable').id)
  }

  private async changePassword(): Promise<void> {
    if (this.profileSubmitting) { return }
    if (this.newPassword.length < 6) {
      this.showToast('新密码至少需要6位')
      return
    }
    if (this.newPassword !== this.confirmPassword) {
      this.showToast('两次输入的密码不一致')
      return
    }
    this.profileSubmitting = true
    try {
      await ProfileApi.resetPassword(this.newPassword, this.profileTarget)
      this.showPasswordDialog = false
      this.newPassword = ''
      this.confirmPassword = ''
      this.showToast('密码修改成功')
    } catch (err) {
      this.showToast(err instanceof Error && err.message !== '' ? err.message : '密码修改失败，请重试')
    } finally {
      this.profileSubmitting = false
    }
  }

  private async deleteAccount(): Promise<void> {
    if (this.profileSubmitting) { return }
    const target: ProfileTarget = this.profileTarget
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
    this.profileSubmitting = true
    try {
      const bindingRemoved: boolean = await ProfileApi.deleteAccount(target)
      this.showDeleteAccountDialog = false
      this.showPersonalSettingsSheet = false
      this.showAccountCenterSheet = false
      if (target.instanceId === InstanceRegistry.getDefaultInstanceId()) {
        HuaweiAccountCache.clear(context, target.huaweiUserId + '|' + target.email)
      }
      this.showToast(bindingRemoved ? $r('app.string.profile_deleted') : $r('app.string.profile_deleted_pending'))
    } catch (err) {
      this.showToast(err instanceof Error && err.message !== '' ? err.message : '删除账户失败，请重试')
    } finally {
      this.profileSubmitting = false
    }
  }

  private openProfileDialog(deleting: boolean): void {
    try {
      this.profileTarget = ProfileApi.captureTarget()
      this.newPassword = ''
      this.confirmPassword = ''
      this.showDeleteAccountDialog = deleting
      this.showPasswordDialog = !deleting
    } catch (err) {
      this.showToast(err instanceof Error ? err.message : $r('app.string.profile_unavailable'))
    }
  }

  private getHuaweiAvatarText(): string {
    const value: string = this.huaweiNickName === '' ? this.authEmail : this.huaweiNickName
    return value === '' ? '华' : value.substring(0, 1).toUpperCase()
  }

  private async openPrivacyPolicy(): Promise<void> {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
    try {
      await context.openLink(Constants.PRIVACY_POLICY_URL)
    } catch (err) {
      console.error('open privacy policy failed')
      this.showToast('暂时无法打开隐私政策')
    }
  }

  private async copyText(value: string, label: string): Promise<void> {
    try {
      const data: pasteboard.PasteData =
        pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, value)
      const systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard()
      await systemPasteboard.setData(data)
      this.showToast(label + '已复制')
    } catch (err) {
      console.error('copy text failed')
      this.showToast('复制失败，请重试')
    }
  }

  private async openRepository(): Promise<void> {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
    try {
      await context.openLink(this.repositoryUrl)
    } catch (err) {
      console.error('open repository failed')
      this.showToast('暂时无法打开开源仓库')
    }
  }

  private async openTelegramGroup(): Promise<void> {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
    try {
      await context.openLink(this.telegramGroupUrl)
    } catch (err) {
      console.error('open Telegram group failed')
      this.showToast('暂时无法打开官方TG交流群')
    }
  }

  private confirmLogout(): void {
    this.showLogoutConfirm = false
    if (this.onLogout) {
      this.onLogout()
    }
  }

  private showToast(message: ResourceStr): void {
    try {
      this.toast.openToast({ message: message, duration: 1500 })
    } catch (err) {
      console.error('openToast failed')
    }
  }
}

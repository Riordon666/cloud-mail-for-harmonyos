import { PromptAction } from '@kit.ArkUI'
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
import { LengthMetrics } from '@kit.ArkUI'

import { common } from '@kit.AbilityKit'
import Constants from '../common/Constants'
import { InstanceRegistry } from '../common/InstanceRegistry'
import { SessionService } from '../common/SessionService'
import PlatformReauthorization from '../common/PlatformReauthorization'
import { InstanceBindResult, InstanceService } from '../common/InstanceService'
import {
  MailInstance,
  PlatformInstance,
  PlatformInstancePayload
} from '../common/InstanceModels'

@Component
export struct InstanceManagementPage {
  onInstanceSwitched?: () => void
  private scroller: Scroller = new Scroller()
  private addSheetScroller: Scroller = new Scroller()
  private bindSheetScroller: Scroller = new Scroller()
  private manageSheetScroller: Scroller = new Scroller()
  private toast: PromptAction = this.getUIContext().getPromptAction()
  private pageActive: boolean = false
  private refreshSequence: number = 0
  @StorageLink('activeInstanceId') activeInstanceId: string = ''
  @StorageLink('platformRole') platformRole: string = 'MEMBER'
  @StorageLink('platformReauthRequired') platformReauthRequired: boolean = false
  @StorageLink('instanceRevision') @Watch('onInstanceRevision') instanceRevision: number = 0
  @State localInstances: MailInstance[] = []
  @State platformInstances: PlatformInstance[] = []
  @State keyword: string = ''
  @State loading: boolean = false
  @State platformDirectoryLoaded: boolean = false
  @State reauthorizing: boolean = false
  @State submitting: boolean = false
  @State showAddSheet: boolean = false
  @State showBindSheet: boolean = false
  @State showManageSheet: boolean = false
  @State editingInstanceId: string = ''
  @State editingInstanceName: string = ''
  @State managingInstance: boolean = false
  @State serviceAddress: string = ''
  @State serviceName: string = ''
  @State bindEmail: string = ''
  @State bindPassword: string = ''
  @State selectedInstance: PlatformInstance = new PlatformInstance(new PlatformInstancePayload())

  aboutToAppear(): void {
    this.pageActive = true
    this.loading = false
    this.reauthorizing = false
    this.refreshInstances()
  }

  aboutToDisappear(): void {
    this.pageActive = false
    this.refreshSequence++
    this.bindPassword = ''
  }

  private onInstanceRevision(): void {
    this.loadLocalInstances()
  }

  build() {
    Stack() {
      HdsNavDestination() {
        List({ scroller: this.scroller, space: Constants.GAP_MEDIUM }) {
          ListItem() {
            Column({ space: Constants.GAP_SMALL }) {
              Text($r('app.string.instance_switch_title'))
                .fontSize(Constants.FONT_SIZE_SUBTITLE)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
              Text($r('app.string.instance_switch_description'))
                .fontSize(Constants.FONT_SIZE_SMALL)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
            }
            .width('100%')
            .padding(Constants.PADDING_CARD)
            .backgroundColor($r('app.color.card'))
            .borderRadius(Constants.RADIUS_CARD)
            .border({ width: 1, color: $r('app.color.divider') })
          }

          ListItem() {
            Search({ value: this.keyword, placeholder: $r('app.string.instance_search_placeholder') })
              .width('100%')
              .height(48)
              .searchIcon({ src: $r('sys.media.ohos_ic_public_search_filled'), size: Constants.SIZE_ICON_SMALL })
              .cancelButton({
                style: CancelButtonStyle.INPUT,
                icon: { size: 18, color: $r('app.color.text_tertiary'), src: '' }
              })
              .fontColor($r('app.color.text_primary'))
              .placeholderColor($r('app.color.text_tertiary'))
              .backgroundColor($r('app.color.card'))
              .borderRadius(Constants.RADIUS_FULL)
              .onChange((value: string) => {
                this.keyword = value
              })
          }

          ListItem() {
            this.SectionHeader($r('app.string.instance_saved_services'), this.getSavedInstanceCount())
          }

          if (this.platformReauthRequired) {
            ListItem() {
              this.ReauthorizationCard()
            }
          }

          ForEach(this.localInstances, (item: MailInstance) => {
            if (this.matchesLocal(item)) {
              ListItem() {
                this.LocalInstanceCard(item)
              }
            }
          }, (item: MailInstance): string => 'local-' + item.instanceId)

          if (this.getAvailableInstanceCount() > 0) {
            ListItem() {
              this.SectionHeader('可绑定服务', this.getAvailableInstanceCount())
            }
          }

          ForEach(this.platformInstances, (item: PlatformInstance) => {
            if (!this.isLocalInstance(item.instanceId) && this.matchesPlatform(item)) {
              ListItem() {
                this.AvailableInstanceCard(item)
              }
            }
          }, (item: PlatformInstance): string => 'remote-' + item.instanceId)

          if (!this.loading && this.getVisibleItemCount() === 0) {
            ListItem() {
              Column({ space: Constants.GAP_MEDIUM }) {
                SymbolGlyph($r('sys.symbol.externaldrive'))
                  .fontSize(40)
                  .fontColor([$r('app.color.text_tertiary')])
                Text(this.keyword === '' ? '暂无可用邮箱服务' : '没有匹配的邮箱服务')
                  .fontSize(Constants.FONT_SIZE_COMMON)
                  .fontColor($r('app.color.text_secondary'))
              }
              .width('100%')
              .height(180)
              .justifyContent(FlexAlign.Center)
            }
          }

          ListItem() {
            Row().height(32)
          }
        }
        .width('100%')
        .height('100%')
        .clip(false)
        .cachedCount(3, true)
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 12 })
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .nestedScroll({
          scrollForward: NestedScrollMode.PARENT_FIRST,
          scrollBackward: NestedScrollMode.SELF_FIRST
        })
      }
      .titleBar({
        content: {
          title: { mainTitle: $r('app.string.instance_page_title') },
          menu: {
            maxCount: this.platformRole === 'SUPER_ADMIN' ? 2 : 0,
            value: this.platformRole === 'SUPER_ADMIN' ? [{
              content: {
                label: $r('app.string.instance_manage_action'),
                icon: $r('sys.symbol.gearshape'),
                type: IconStyleMode.SMALL,
                isEnabled: true,
                action: () => {
                  this.openManageSheet()
                }
              }
            }, {
              content: {
                label: $r('app.string.instance_add_action'),
                icon: $r('sys.symbol.plus'),
                type: IconStyleMode.SMALL,
                isEnabled: true,
                action: () => {
                  this.openAddSheet()
                }
              }
            }] : []
          }
        },
        avoidLayoutSafeArea: true,
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
            backgroundStyle: { maskExtraHeight: 0 }
          },
          scrollEffectStyle: {
            backgroundStyle: { maskExtraHeight: 0 }
          }
        }
      })
      .hideBackButton(false)
      .titleMode(HdsNavDestinationTitleMode.MINI)
      .bindToScrollable([this.scroller])
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background'))

      if (this.loading) {
        LoadingProgress()
          .width(36)
          .height(36)
          .color($r('app.color.primary'))
          .align(Alignment.Center)
      }

      Row()
        .width(1)
        .height(1)
        .bindSheet($$this.showAddSheet, this.AddInstanceSheet(), {
          height: '64%',
          dragBar: false,
          showClose: false,
          blurStyle: BlurStyle.COMPONENT_THICK,
          maskColor: 0x1A000000,
          enableOutsideInteractive: false,
          onDisappear: () => { this.showAddSheet = false }
        })

      Row()
        .width(1)
        .height(1)
        .bindSheet($$this.showBindSheet, this.BindInstanceSheet(), {
          height: '68%',
          dragBar: false,
          showClose: false,
          blurStyle: BlurStyle.COMPONENT_THICK,
          maskColor: 0x1A000000,
          enableOutsideInteractive: false,
          onDisappear: () => { this.showBindSheet = false }
        })

      Row()
        .width(1)
        .height(1)
        .bindSheet($$this.showManageSheet, this.ManageInstancesSheet(), {
          height: '76%',
          dragBar: false,
          showClose: false,
          blurStyle: BlurStyle.COMPONENT_THICK,
          maskColor: 0x1A000000,
          enableOutsideInteractive: false,
          onDisappear: () => {
            this.showManageSheet = false
            this.clearInstanceEditor()
          }
        })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private SectionHeader(title: ResourceStr, count: number) {
    Row() {
      Text(title)
        .fontSize(Constants.FONT_SIZE_COMMON)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_secondary'))
      Blank()
      Text(count.toString())
        .fontSize(Constants.FONT_SIZE_SMALL)
        .fontColor($r('app.color.text_tertiary'))
    }
    .width('100%')
    .padding({ left: 4, right: 4, top: 4 })
  }

  @Builder
  private ReauthorizationCard() {
    Column() {
      HdsListItemCard({
        prefixItem: new PrefixIcon({
          iconSize: IconSize.SYSTEM_ICON,
          iconValue: { symbol: $r('sys.symbol.person') }
        }),
        textItem: {
          primaryText: { text: $r('app.string.platform_reauth_title') },
          secondaryText: { text: $r('app.string.platform_reauth_description') },
          description: { text: this.reauthorizing ? $r('app.string.platform_reauth_busy') :
            $r('app.string.platform_reauth_action') }
        },
        cardBackgroundColor: $r('app.color.card'),
        cardBorderRadius: Constants.RADIUS_CARD,
        hoverBorderRadius: Constants.RADIUS_CARD,
        enable: !this.reauthorizing,
        onClick: () => { this.reauthorizePlatform() }
      })
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }

  @Builder
  private LocalInstanceCard(item: MailInstance) {
    Row({ space: Constants.GAP_MEDIUM }) {
      Stack() {
        Circle()
          .width(48)
          .height(48)
          .foregroundColor(this.isCurrentInstance(item) ?
            $r('app.color.primary') : $r('app.color.background'))
        SymbolGlyph($r('sys.symbol.externaldrive'))
          .fontSize(Constants.SIZE_ICON_MEDIUM)
          .fontColor([this.isCurrentInstance(item) ?
            $r('sys.color.icon_on_primary') : $r('app.color.primary')])
      }
      .width(48)
      .height(48)

      Column({ space: 3 }) {
        Row({ space: 6 }) {
          Text(item.displayName)
            .fontSize(Constants.FONT_SIZE_SUBTITLE)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.isCurrentInstance(item)) {
            Text($r('app.string.instance_current'))
              .fontSize(Constants.FONT_SIZE_CAPTION)
              .fontColor($r('sys.color.icon_on_primary'))
              .padding({ left: 7, right: 7, top: 2, bottom: 2 })
              .backgroundColor($r('app.color.primary'))
              .borderRadius(Constants.RADIUS_FULL)
          }
        }
        .width('100%')
        Text(item.localEmail === '' ? item.originHost : item.localEmail)
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.getInstanceStatus(item))
          .fontSize(Constants.FONT_SIZE_CAPTION)
          .fontColor($r('app.color.text_tertiary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (!this.isCurrentInstance(item)) {
        Button(this.hasMailboxSession(item) ? $r('app.string.instance_switch_action') :
          $r('app.string.instance_sign_in'), {
          type: ButtonType.Capsule,
          stateEffect: true,
          buttonStyle: ButtonStyleMode.NORMAL,
          controlSize: ControlSize.SMALL
        })
          .enabled(!this.isUnavailable(item) && !this.reauthorizing)
          .onClick(() => {
            this.switchTo(item)
          })
      }
    }
    .width('100%')
    .padding(Constants.PADDING_CARD)
    .backgroundColor($r('app.color.card'))
    .borderRadius(Constants.RADIUS_CARD)
    .border({ width: 1, color: $r('app.color.divider') })
  }

  @Builder
  private AvailableInstanceCard(item: PlatformInstance) {
    Row({ space: Constants.GAP_MEDIUM }) {
      Stack() {
        Circle()
          .width(48)
          .height(48)
          .foregroundColor($r('app.color.background'))
        SymbolGlyph($r('sys.symbol.link'))
          .fontSize(Constants.SIZE_ICON_MEDIUM)
          .fontColor([$r('app.color.primary')])
      }
      .width(48)
      .height(48)

      Column({ space: 4 }) {
        Text(item.displayName)
          .fontSize(Constants.FONT_SIZE_SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(item.originHost)
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Button(item.bindingStatus === 'ACTIVE' ? '登录' : '绑定', {
        type: ButtonType.Capsule,
        stateEffect: true,
        buttonStyle: ButtonStyleMode.EMPHASIZED,
        controlSize: ControlSize.SMALL
      })
        .onClick(() => {
          this.openBindSheet(item)
        })
    }
    .width('100%')
    .padding(Constants.PADDING_CARD)
    .backgroundColor($r('app.color.card'))
    .borderRadius(Constants.RADIUS_CARD)
    .border({ width: 1, color: $r('app.color.divider') })
  }

  @Builder
  private ManageInstancesSheet() {
    HdsNavDestination() {
      List({ scroller: this.manageSheetScroller, space: Constants.GAP_SMALL }) {
        ListItem() {
          Text($r('app.string.instance_manage_description'))
            .fontSize(Constants.FONT_SIZE_SMALL)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .padding({ left: 4, right: 4, bottom: 4 })
        }

        ForEach(this.platformInstances, (item: PlatformInstance) => {
          ListItem() {
            this.ManageInstanceCard(item)
          }
        }, (item: PlatformInstance): string => 'manage-' + item.instanceId)

        if (!this.loading && this.platformInstances.length === 0) {
          ListItem() {
            Column({ space: Constants.GAP_MEDIUM }) {
              SymbolGlyph($r('sys.symbol.externaldrive'))
                .fontSize(40)
                .fontColor([$r('app.color.text_tertiary')])
              Text($r('app.string.instance_manage_empty'))
                .fontSize(Constants.FONT_SIZE_COMMON)
                .fontColor($r('app.color.text_secondary'))
            }
            .width('100%')
            .height(180)
            .justifyContent(FlexAlign.Center)
          }
        }

        ListItem() {
          Row().height(24)
        }
      }
      .width('100%')
      .height('100%')
      .clip(false)
      .cachedCount(3, true)
      .padding({
        left: Constants.PADDING_EDGE,
        right: Constants.PADDING_EDGE,
        top: Constants.GAP_MEDIUM,
        bottom: Constants.GAP_MEDIUM
      })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .titleBar({
      content: {
        title: { mainTitle: $r('app.string.instance_manage_title') },
        menu: {
          maxCount: 1,
          value: [{
            content: {
              label: $r('app.string.common_close'),
              icon: $r('sys.symbol.xmark'),
              type: IconStyleMode.SMALL,
              isEnabled: true,
              action: () => {
                this.closeManageSheet()
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
          backgroundStyle: { maskExtraHeight: 0 }
        },
        scrollEffectStyle: {
          backgroundStyle: { maskExtraHeight: 0 }
        }
      }
    })
    .hideBackButton(true)
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .bindToScrollable([this.manageSheetScroller])
    .onBackPressed(() => {
      this.closeManageSheet()
      return true
    })
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  private ManageInstanceCard(item: PlatformInstance) {
    Column({ space: Constants.GAP_SMALL }) {
      Column() {
        HdsListItemCard({
          prefixItem: new PrefixIcon({
            iconSize: IconSize.SYSTEM_ICON,
            iconValue: { symbol: $r('sys.symbol.externaldrive') }
          }),
          textItem: {
            primaryText: { text: item.displayName },
            secondaryText: { text: item.originHost }
          },
          suffixItem: new SuffixTextAndArrow({
            text: this.isAnchorInstance(item) ?
              $r('app.string.instance_main_badge') : $r('app.string.instance_manage_item_action')
          }),
          cardHeight: 76,
          cardBackgroundColor: $r('app.color.card'),
          cardBorderRadius: Constants.RADIUS_CARD,
          hoverBorderRadius: Constants.RADIUS_CARD,
          onClick: () => {
            this.toggleInstanceEditor(item)
          }
        })
      }
      .width('100%')
      .padding({ top: 4, bottom: 4 })

      if (this.editingInstanceId === item.instanceId) {
        this.InstanceEditor(item)
      }
    }
    .width('100%')
  }

  @Builder
  private InstanceEditor(item: PlatformInstance) {
    Column({ space: Constants.GAP_MEDIUM }) {
      Text($r('app.string.instance_name_label'))
        .fontSize(Constants.FONT_SIZE_COMMON)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      TextInput({
        text: this.editingInstanceName,
        placeholder: $r('app.string.instance_name_placeholder')
      })
        .width('100%')
        .height(52)
        .fontColor($r('app.color.text_primary'))
        .placeholderColor($r('app.color.text_tertiary'))
        .backgroundColor($r('app.color.background'))
        .border({ width: 1, color: $r('app.color.divider') })
        .borderRadius(Constants.RADIUS_CARD)
        .onChange((value: string) => {
          this.editingInstanceName = value
        })

      Button(this.managingInstance ? $r('app.string.instance_saving') :
        $r('app.string.instance_save_action'), {
        type: ButtonType.Capsule,
        stateEffect: true,
        buttonStyle: ButtonStyleMode.EMPHASIZED,
        controlSize: ControlSize.NORMAL
      })
        .width('100%')
        .enabled(!this.managingInstance && this.editingInstanceName.trim() !== '')
        .onClick(() => {
          this.renameInstance(item)
        })

      Divider()
        .color($r('app.color.divider'))

      if (this.isAnchorInstance(item)) {
        Text($r('app.string.instance_main_delete_disabled'))
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
      } else {
        Text($r('app.string.instance_delete_description'))
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')

        Button($r('app.string.instance_delete_action'), {
          type: ButtonType.Capsule,
          stateEffect: true,
          buttonStyle: ButtonStyleMode.NORMAL,
          controlSize: ControlSize.NORMAL
        })
          .width('100%')
          .fontColor($r('sys.color.icon_on_primary'))
          .backgroundColor($r('app.color.danger'))
          .enabled(!this.managingInstance)
          .onClick(() => {
            this.confirmDeleteInstance(item)
          })
      }
    }
    .width('100%')
    .padding(Constants.PADDING_CARD)
    .backgroundColor($r('app.color.card'))
    .borderRadius(Constants.RADIUS_CARD)
    .border({ width: 1, color: $r('app.color.divider') })
  }

  @Builder
  private AddInstanceSheet() {
    HdsNavDestination() {
      Scroll(this.addSheetScroller) {
        Column({ space: Constants.GAP_MEDIUM }) {
          Text('只有平台超级管理员可以登记新服务。系统会先验证地址是否为兼容的 Cloud Mail 实例。')
            .fontSize(Constants.FONT_SIZE_SMALL)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')

          TextInput({ placeholder: 'https://mail.example.com', text: this.serviceAddress })
            .width('100%')
            .height(52)
            .fontColor($r('app.color.text_primary'))
            .placeholderColor($r('app.color.text_tertiary'))
            .backgroundColor($r('app.color.card'))
            .border({ width: 1, color: $r('app.color.divider') })
            .borderRadius(Constants.RADIUS_CARD)
            .onChange((value: string) => {
              this.serviceAddress = value
            })

          TextInput({ placeholder: '服务名称（可选）', text: this.serviceName })
            .width('100%')
            .height(52)
            .fontColor($r('app.color.text_primary'))
            .placeholderColor($r('app.color.text_tertiary'))
            .backgroundColor($r('app.color.card'))
            .border({ width: 1, color: $r('app.color.divider') })
            .borderRadius(Constants.RADIUS_CARD)
            .onChange((value: string) => {
              this.serviceName = value
            })

          Button(this.submitting ? '正在验证' : '验证并添加', {
            type: ButtonType.Capsule,
            stateEffect: true,
            buttonStyle: ButtonStyleMode.EMPHASIZED,
            controlSize: ControlSize.NORMAL
          })
            .width('100%')
            .enabled(!this.submitting)
            .onClick(() => {
              this.addInstance()
            })
        }
        .width('100%')
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 16, bottom: 24 })
      }
      .width('100%')
      .height('100%')
      .clip(false)
      .scrollBar(BarState.Off)
    }
    .titleBar({
      content: {
        title: { mainTitle: '添加邮箱服务' },
        menu: {
          maxCount: 1,
          value: [{
            content: {
              label: '关闭',
              icon: $r('sys.symbol.xmark'),
              type: IconStyleMode.SMALL,
              isEnabled: true,
              action: () => {
                this.showAddSheet = false
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
          backgroundStyle: { maskExtraHeight: 0 }
        },
        scrollEffectStyle: {
          backgroundStyle: { maskExtraHeight: 0 }
        }
      }
    })
    .hideBackButton(true)
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .bindToScrollable([this.addSheetScroller])
    .onBackPressed(() => {
      this.showAddSheet = false
      return true
    })
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  private BindInstanceSheet() {
    HdsNavDestination() {
      Scroll(this.bindSheetScroller) {
        Column({ space: Constants.GAP_MEDIUM }) {
          Column({ space: 4 }) {
            Text(this.selectedInstance.displayName)
              .fontSize(Constants.FONT_SIZE_TITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
            Text(this.selectedInstance.originHost)
              .fontSize(Constants.FONT_SIZE_SMALL)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          Text('请输入该服务自己的完整邮箱与密码。密码只会直发该服务，不会保存到云笺集中心。')
            .fontSize(Constants.FONT_SIZE_SMALL)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')

          TextInput({ placeholder: '完整邮箱地址', text: this.bindEmail })
            .width('100%')
            .height(52)
            .type(InputType.Email)
            .fontColor($r('app.color.text_primary'))
            .placeholderColor($r('app.color.text_tertiary'))
            .backgroundColor($r('app.color.card'))
            .border({ width: 1, color: $r('app.color.divider') })
            .borderRadius(Constants.RADIUS_CARD)
            .onChange((value: string) => {
              this.bindEmail = value
            })

          TextInput({ placeholder: '邮箱密码', text: this.bindPassword })
            .width('100%')
            .height(52)
            .type(InputType.Password)
            .showPasswordIcon(true)
            .fontColor($r('app.color.text_primary'))
            .placeholderColor($r('app.color.text_tertiary'))
            .backgroundColor($r('app.color.card'))
            .border({ width: 1, color: $r('app.color.divider') })
            .borderRadius(Constants.RADIUS_CARD)
            .onChange((value: string) => {
              this.bindPassword = value
            })

          Button(this.submitting ? '正在验证' : '验证并绑定', {
            type: ButtonType.Capsule,
            stateEffect: true,
            buttonStyle: ButtonStyleMode.EMPHASIZED,
            controlSize: ControlSize.NORMAL
          })
            .width('100%')
            .enabled(!this.submitting)
            .onClick(() => {
              this.bindSelectedInstance()
            })
        }
        .width('100%')
        .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 16, bottom: 24 })
      }
      .width('100%')
      .height('100%')
      .clip(false)
      .scrollBar(BarState.Off)
    }
    .titleBar({
      content: {
        title: { mainTitle: '绑定邮箱服务' },
        menu: {
          maxCount: 1,
          value: [{
            content: {
              label: '关闭',
              icon: $r('sys.symbol.xmark'),
              type: IconStyleMode.SMALL,
              isEnabled: true,
              action: () => {
                this.showBindSheet = false
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
          backgroundStyle: { maskExtraHeight: 0 }
        },
        scrollEffectStyle: {
          backgroundStyle: { maskExtraHeight: 0 }
        }
      }
    })
    .hideBackButton(true)
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .bindToScrollable([this.bindSheetScroller])
    .onBackPressed(() => {
      this.showBindSheet = false
      return true
    })
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  private openAddSheet(): void {
    if (this.platformRole !== 'SUPER_ADMIN') {
      return
    }
    this.showAddSheet = true
  }

  private openManageSheet(): void {
    if (this.platformRole !== 'SUPER_ADMIN') {
      return
    }
    this.clearInstanceEditor()
    this.showManageSheet = true
  }

  private closeManageSheet(): void {
    this.showManageSheet = false
    this.clearInstanceEditor()
  }

  private toggleInstanceEditor(item: PlatformInstance): void {
    if (this.editingInstanceId === item.instanceId) {
      this.clearInstanceEditor()
      return
    }
    this.editingInstanceId = item.instanceId
    this.editingInstanceName = item.displayName
  }

  private clearInstanceEditor(): void {
    this.editingInstanceId = ''
    this.editingInstanceName = ''
  }

  private isAnchorInstance(item: PlatformInstance): boolean {
    return item.instanceId === InstanceRegistry.getDefaultInstanceId()
  }

  private async renameInstance(item: PlatformInstance): Promise<void> {
    if (this.managingInstance) {
      return
    }
    const displayName: string = this.editingInstanceName.trim()
    if (displayName === '') {
      this.showToast('请输入邮箱服务名称')
      return
    }
    this.managingInstance = true
    try {
      await InstanceService.renamePlatformInstance(item.instanceId, displayName)
      this.clearInstanceEditor()
      this.showToast('邮箱服务名称已更新')
      await this.refreshInstances()
    } catch (err) {
      this.showToast(err instanceof Error && err.message !== '' ? err.message : '修改邮箱服务名称失败')
    }
    this.managingInstance = false
  }

  private confirmDeleteInstance(item: PlatformInstance): void {
    if (this.isAnchorInstance(item)) {
      this.showToast('云笺集主服务不可删除')
      return
    }
    this.getUIContext().showAlertDialog({
      title: $r('app.string.instance_delete_confirm_title'),
      message: $r('app.string.instance_delete_confirm_message'),
      autoCancel: true,
      primaryButton: {
        value: $r('app.string.common_cancel'),
        action: () => {
        }
      },
      secondaryButton: {
        value: $r('app.string.instance_delete_action'),
        fontColor: $r('app.color.danger'),
        action: () => {
          this.deleteInstance(item)
        }
      }
    })
  }

  private async deleteInstance(item: PlatformInstance): Promise<void> {
    if (this.managingInstance || this.isAnchorInstance(item)) {
      return
    }
    const wasActive: boolean = item.instanceId === this.activeInstanceId
    this.managingInstance = true
    try {
      await InstanceService.deletePlatformInstance(item.instanceId)
      this.clearInstanceEditor()
      this.loadLocalInstances()
      this.showToast('邮箱服务已删除')
      if (wasActive && this.onInstanceSwitched) {
        this.onInstanceSwitched()
      }
      await this.refreshInstances()
    } catch (err) {
      this.showToast(err instanceof Error && err.message !== '' ? err.message : '删除邮箱服务失败')
    }
    this.managingInstance = false
  }

  private async refreshInstances(): Promise<void> {
    if (this.loading) {
      return
    }
    this.loading = true
    const sequence: number = ++this.refreshSequence
    this.loadLocalInstances()
    try {
      const instances: PlatformInstance[] = await InstanceService.loadPlatformInstances()
      if (!this.pageActive || sequence !== this.refreshSequence) {
        return
      }
      this.platformInstances = instances
      this.platformDirectoryLoaded = true
      this.loadLocalInstances()
    } catch (err) {
      if (!this.pageActive || sequence !== this.refreshSequence) {
        return
      }
      // A failed directory request is not evidence that a saved service was removed.
      this.platformDirectoryLoaded = false
      this.showToast('暂时无法读取平台实例，已显示本机服务')
    } finally {
      if (this.pageActive && sequence === this.refreshSequence) {
        this.loading = false
      }
    }
  }

  private async reauthorizePlatform(): Promise<void> {
    if (this.reauthorizing) {
      return
    }
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
    this.reauthorizing = true
    try {
      await PlatformReauthorization.reauthorize(context)
      if (this.pageActive) {
        await this.refreshInstances()
      }
    } catch (err) {
      if (this.pageActive) {
        this.showToast(err instanceof Error ? err.message : '华为账号授权失败，请重试')
      }
    } finally {
      if (this.pageActive) {
        this.reauthorizing = false
      }
    }
  }

  private loadLocalInstances(): void {
    this.localInstances = InstanceService.getLocalInstances()
  }

  private openBindSheet(instance: PlatformInstance): void {
    this.selectedInstance = instance
    this.bindEmail = instance.localEmail
    this.bindPassword = ''
    this.showBindSheet = true
  }

  private async addInstance(): Promise<void> {
    if (this.serviceAddress.trim() === '') {
      this.showToast('请输入邮箱服务地址')
      return
    }
    this.submitting = true
    try {
      await InstanceService.createPlatformInstance(this.serviceAddress.trim(), this.serviceName.trim())
      this.serviceAddress = ''
      this.serviceName = ''
      this.showAddSheet = false
      this.showToast('邮箱服务已添加')
      await this.refreshInstances()
    } catch (err) {
      this.showToast(err instanceof Error && err.message !== '' ? err.message : '添加邮箱服务失败')
    }
    this.submitting = false
  }

  private async bindSelectedInstance(): Promise<void> {
    if (this.submitting) {
      return
    }
    this.submitting = true
    const result: InstanceBindResult = await InstanceService.bindInstance(
      this.selectedInstance, this.bindEmail, this.bindPassword)
    this.bindPassword = ''
    if (!result.success || result.instance === null) {
      this.submitting = false
      this.showToast(result.message)
      return
    }
    this.showBindSheet = false
    this.submitting = false
    this.loadLocalInstances()
    this.showToast('邮箱服务绑定成功')
  }

  private switchTo(instance: MailInstance): void {
    if (this.isUnavailable(instance)) {
      return
    }
    const switched: boolean = InstanceService.switchInstance(instance.instanceId)
    if (!switched) {
      this.showToast('该服务需要重新登录')
      const platformInstance: PlatformInstance | null = this.findPlatformInstance(instance.instanceId)
      if (platformInstance !== null) {
        this.openBindSheet(platformInstance)
      }
      return
    }
    this.showToast('已切换至 ' + instance.displayName)
    if (this.onInstanceSwitched) {
      this.onInstanceSwitched()
    }
  }

  private hasMailboxSession(instance: MailInstance): boolean {
    return SessionService.getInstanceToken(instance.instanceId) !== ''
  }

  private isCurrentInstance(instance: MailInstance): boolean {
    return instance.instanceId === this.activeInstanceId && this.hasMailboxSession(instance)
  }

  private isUnavailable(instance: MailInstance): boolean {
    if (!this.platformDirectoryLoaded) {
      return false
    }
    const service: PlatformInstance | null = this.findPlatformInstance(instance.instanceId)
    return service === null || service.status !== 'ACTIVE'
  }

  private getInstanceStatus(instance: MailInstance): ResourceStr {
    if (this.isUnavailable(instance)) {
      return $r('app.string.instance_unavailable')
    }
    if (!this.hasMailboxSession(instance)) {
      return $r('app.string.instance_needs_login')
    }
    if (this.platformDirectoryLoaded) {
      const service: PlatformInstance | null = this.findPlatformInstance(instance.instanceId)
      if (service !== null && service.bindingStatus === 'ACTIVE' && service.localEmail !== '' &&
        service.localEmail === instance.localEmail &&
        (service.instanceRole === 'INSTANCE_OWNER' || service.instanceRole === 'INSTANCE_ADMIN' ||
          service.instanceRole === 'MEMBER')) {
        return this.getInstanceRoleLabel(service.instanceRole)
      }
    }
    return this.getInstanceRoleLabel(instance.instanceRole)
  }

  private findPlatformInstance(instanceId: string): PlatformInstance | null {
    for (let index = 0; index < this.platformInstances.length; index++) {
      if (this.platformInstances[index].instanceId === instanceId) {
        return this.platformInstances[index]
      }
    }
    return null
  }

  private isLocalInstance(instanceId: string): boolean {
    for (let index = 0; index < this.localInstances.length; index++) {
      if (this.localInstances[index].instanceId === instanceId) {
        return true
      }
    }
    return false
  }

  private matchesLocal(instance: MailInstance): boolean {
    const keyword: string = this.keyword.trim().toLowerCase()
    if (keyword === '') {
      return true
    }
    return instance.displayName.toLowerCase().includes(keyword) ||
      instance.originHost.toLowerCase().includes(keyword) ||
      instance.localEmail.toLowerCase().includes(keyword)
  }

  private matchesPlatform(instance: PlatformInstance): boolean {
    const keyword: string = this.keyword.trim().toLowerCase()
    if (keyword === '') {
      return true
    }
    return instance.displayName.toLowerCase().includes(keyword) ||
      instance.originHost.toLowerCase().includes(keyword) ||
      instance.localEmail.toLowerCase().includes(keyword)
  }

  private getAvailableInstanceCount(): number {
    let count: number = 0
    for (let index = 0; index < this.platformInstances.length; index++) {
      if (!this.isLocalInstance(this.platformInstances[index].instanceId) &&
        this.matchesPlatform(this.platformInstances[index])) {
        count++
      }
    }
    return count
  }

  private getSavedInstanceCount(): number {
    let count: number = 0
    for (let index = 0; index < this.localInstances.length; index++) {
      if (this.matchesLocal(this.localInstances[index])) {
        count++
      }
    }
    return count
  }

  private getVisibleItemCount(): number {
    let count: number = 0
    for (let index = 0; index < this.localInstances.length; index++) {
      if (this.matchesLocal(this.localInstances[index])) {
        count++
      }
    }
    return count + this.getAvailableInstanceCount()
  }

  private getInstanceRoleLabel(role: string): string {
    if (role === 'INSTANCE_OWNER') {
      return '实例所有者'
    }
    if (role === 'INSTANCE_ADMIN') {
      return '实例管理员'
    }
    return '成员'
  }

  private showToast(message: string): void {
    try {
      this.toast.openToast({ message: message, duration: 1500 })
    } catch (err) {
      console.error('open instance toast failed')
    }
  }
}

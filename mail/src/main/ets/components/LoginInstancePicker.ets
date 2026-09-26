import { LengthMetrics } from '@kit.ArkUI'
import {
  HdsNavDestination,
  HdsNavDestinationTitleMode,
  IconStyleMode,
  ScrollEffectType,
  hdsMaterial
} from '@kit.UIDesignKit'
import Constants from '../common/Constants'
import { PlatformInstance } from '../common/InstanceModels'

@Component
export struct LoginInstancePicker {
  @Prop instances: PlatformInstance[] = []
  @Prop selectedId: string = ''
  @Prop loading: boolean = false
  @Prop errorMessage: string = ''
  private scroller: Scroller = new Scroller()
  onSelect: (instance: PlatformInstance) => void = () => {}
  onRetry: () => void = () => {}
  onClose: () => void = () => {}

  build() {
    HdsNavDestination() {
      List({ scroller: this.scroller, space: Constants.GAP_MEDIUM }) {
        ListItem() {
          Text($r('app.string.login_instance_picker_description'))
            .fontSize(Constants.FONT_SIZE_COMMON)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
        }
        if (this.loading) {
          ListItem() {
            Row({ space: 12 }) {
              LoadingProgress().width(24).height(24).color($r('app.color.primary'))
              Text($r('app.string.login_instances_loading'))
                .fontSize(Constants.FONT_SIZE_COMMON)
                .fontColor($r('app.color.text_secondary'))
            }
            .width('100%')
            .padding(16)
          }
        }
        if (this.errorMessage !== '') {
          ListItem() {
            Column({ space: 12 }) {
              Text(this.errorMessage)
                .fontSize(Constants.FONT_SIZE_COMMON)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
              Button($r('app.string.login_instances_retry'), { type: ButtonType.Capsule })
                .enabled(!this.loading)
                .fontColor($r('app.color.text_link'))
                .backgroundColor($r('app.color.card'))
                .onClick(() => { this.onRetry() })
            }
            .width('100%')
          }
        }
        ForEach(this.instances, (instance: PlatformInstance) => {
          ListItem() {
            Button({ type: ButtonType.Normal, stateEffect: true }) {
              Row({ space: 12 }) {
                SymbolGlyph($r('sys.symbol.externaldrive'))
                  .fontSize(28)
                  .fontColor([$r('app.color.primary')])
                Column({ space: 6 }) {
                  Text(instance.displayName)
                    .fontSize(Constants.FONT_SIZE_SUBTITLE)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(instance.originHost)
                    .fontSize(Constants.FONT_SIZE_SMALL)
                    .fontColor($r('app.color.text_secondary'))
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  if (instance.localEmail !== '') {
                    Text(instance.localEmail)
                      .fontSize(Constants.FONT_SIZE_SMALL)
                      .fontColor($r('app.color.text_link'))
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                if (instance.instanceId === this.selectedId) {
                  SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
                    .fontSize(22)
                    .fontColor([$r('app.color.primary')])
                }
              }
              .width('100%')
              .padding(Constants.PADDING_EDGE)
            }
            .width('100%')
            .backgroundColor($r('app.color.card'))
            .borderRadius(Constants.RADIUS_CARD)
            .border({ width: 0.5, color: $r('app.color.divider') })
            .enabled(!this.loading)
            .onClick(() => { this.onSelect(instance) })
          }
        }, (instance: PlatformInstance): string => instance.instanceId)
        ListItem() { Row().height(24) }
      }
      .width('100%')
      .height('100%')
      .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 0 })
      .scrollBar(BarState.Off)
      .clip(false)
    }
    .titleBar({
      content: {
        title: { mainTitle: $r('app.string.login_instance_picker_title') },
        menu: {
          maxCount: 1,
          value: [{
            content: {
              label: $r('app.string.common_close'),
              icon: $r('sys.symbol.xmark'),
              type: IconStyleMode.SMALL,
              isEnabled: true,
              action: () => { this.onClose() }
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
        originalStyle: { backgroundStyle: { maskExtraHeight: 0 } },
        scrollEffectStyle: { backgroundStyle: { maskExtraHeight: 0 } }
      }
    })
    .hideBackButton(true)
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .bindToScrollable([this.scroller])
    .onBackPressed(() => {
      this.onClose()
      return true
    })
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }
}

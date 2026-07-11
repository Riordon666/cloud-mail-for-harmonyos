import { PromptAction } from '@kit.ArkUI'
import { HdsNavDestination, HdsNavDestinationTitleMode } from '@kit.UIDesignKit'
import Constants from '../common/Constants'
import { AdminPermission, AdminResult, AdminRole, AdminService } from '../common/AdminService'
import { EmptyState } from '../components/EmptyState'

class PermissionItem {
  key: string
  label: string
  description: string

  constructor(key: string, label: string, description: string) {
    this.key = key
    this.label = label
    this.description = description
  }
}

@Component
export struct RoleManagementPage {
  @StorageLink('authRole') authRole: string = 'user'
  @StorageLink('adminRoleRevision') @Watch('onRoleRevision') roleRevision: number = 0
  @State roleList: AdminRole[] = []
  @State showRoleDialog: boolean = false
  @State isEditing: boolean = false
  @State editingRoleId: string = ''
  @State roleName: string = ''
  @State selectedPermissions: string[] = []
  @State deleteRoleId: string = ''
  @State deleteRoleName: string = ''
  @State permissionItems: PermissionItem[] = []
  private toast: PromptAction = this.getUIContext().getPromptAction()

  aboutToAppear(): void {
    AdminService.initialize()
    this.refreshRoles()
  }

  private onRoleRevision(): void {
    this.refreshRoles()
  }

  build() {
    HdsNavDestination() {
      if (this.authRole !== 'admin') {
        EmptyState({ icon: $r('sys.symbol.person'), message: '仅管理员可访问角色权限' })
      } else {
        Stack({ alignContent: Alignment.TopStart }) {
          Scroll() {
            Column({ space: Constants.GAP_MEDIUM }) {
              Row() {
                Column() {
                  Text('角色权限')
                    .fontSize(Constants.FONT_SIZE_TITLE)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.text_primary'))
                  Text('按角色配置管理能力，默认角色会用于新用户创建。')
                    .fontSize(Constants.FONT_SIZE_COMMON)
                    .fontColor($r('app.color.text_secondary'))
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                Button({ type: ButtonType.Circle, stateEffect: true }) {
                  SymbolGlyph($r('sys.symbol.plus'))
                    .fontSize(Constants.SIZE_ICON_MEDIUM)
                    .fontColor([$r('sys.color.icon_on_primary')])
                }
                .width(44)
                .height(44)
                .backgroundColor($r('app.color.primary'))
                .onClick(() => { this.openCreateDialog() })
              }
              .width('100%')

              if (this.roleList.length === 0) {
                EmptyState({ icon: $r('sys.symbol.person'), message: '暂无角色', iconSize: 40 })
                  .height(220)
              } else {
                Column({ space: Constants.GAP_SMALL }) {
                  ForEach(this.roleList, (role: AdminRole) => {
                    this.RoleCard(role)
                  }, (role: AdminRole): string => role.id)
                }
                .width('100%')
              }
              Blank().height(24)
            }
            .width('100%')
            .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 16, bottom: 24 })
          }
          .width('100%')
          .height('100%')
          .align(Alignment.TopStart)
          .scrollBar(BarState.Off)
          if (this.showRoleDialog) {
            this.RoleDialog()
          }
          if (this.deleteRoleId !== '') {
            this.DeleteRoleDialog()
          }
        }
        .width('100%')
        .height('100%')
      }
    }
    .titleBar({ content: { title: { mainTitle: '角色权限' } }, enableComponentSafeArea: true })
    .hideBackButton(false)
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  private RoleCard(role: AdminRole) {
    Column({ space: Constants.GAP_SMALL }) {
      Row() {
        Text(role.name)
          .fontSize(Constants.FONT_SIZE_SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        if (role.isDefault) {
          Text('默认角色')
            .fontSize(Constants.FONT_SIZE_SMALL)
            .fontColor($r('app.color.primary'))
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(Constants.RADIUS_FULL)
            .backgroundColor($r('app.color.primary_light'))
        }
      }
      .width('100%')
      Text('已授权 ' + role.permissions.length.toString() + ' 项：' + this.getPermissionSummary(role.permissions))
        .fontSize(Constants.FONT_SIZE_SMALL)
        .fontColor($r('app.color.text_secondary'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
      Row({ space: Constants.GAP_SMALL }) {
        Button('编辑', { type: ButtonType.Normal, stateEffect: true })
          .height(32)
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.primary'))
          .backgroundColor($r('app.color.primary_light'))
          .onClick(() => { this.openEditDialog(role) })
        if (!role.isDefault) {
          Button('设为默认', { type: ButtonType.Normal, stateEffect: true })
            .height(32)
            .fontSize(Constants.FONT_SIZE_SMALL)
            .fontColor($r('app.color.text_secondary'))
            .backgroundColor($r('app.color.background'))
            .onClick(() => { this.setDefaultRole(role.id) })
        }
        if (role.id !== 'admin' && !role.isDefault) {
          Button('删除', { type: ButtonType.Normal, stateEffect: true })
            .height(32)
            .fontSize(Constants.FONT_SIZE_SMALL)
            .fontColor($r('app.color.danger'))
            .backgroundColor($r('app.color.background'))
            .onClick(() => { this.openDeleteDialog(role) })
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(Constants.PADDING_CARD)
    .backgroundColor($r('app.color.card'))
    .borderRadius(Constants.RADIUS_CARD)
    .shadow(Constants.SHADOW_CARD)
  }

  @Builder
  private RoleDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.overlay'))
      Scroll() {
        Column({ space: Constants.GAP_MEDIUM }) {
          Text(this.isEditing ? '编辑角色' : '创建角色')
            .fontSize(Constants.FONT_SIZE_TITLE)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
          TextInput({ placeholder: '角色名称', text: this.roleName })
            .height(46)
            .fontColor($r('app.color.text_primary'))
            .placeholderColor($r('app.color.text_tertiary'))
            .backgroundColor($r('app.color.background'))
            .border({ width: 0.5, color: $r('app.color.divider') })
            .borderRadius(Constants.RADIUS_SMALL)
            .padding({ left: Constants.PADDING_INNER, right: Constants.PADDING_INNER })
            .onChange((value: string) => { this.roleName = value })
          Text('权限')
            .fontSize(Constants.FONT_SIZE_SUBTITLE)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
          Column({ space: Constants.GAP_SMALL }) {
            ForEach(this.permissionItems, (item: PermissionItem) => {
              Row() {
                Toggle({ type: ToggleType.Checkbox, isOn: this.hasPermission(item.key) })
                  .selectedColor($r('app.color.primary'))
                  .onChange((selected: boolean) => { this.togglePermission(item.key, selected) })
                Column() {
                  Text(item.label)
                    .fontSize(Constants.FONT_SIZE_COMMON)
                    .fontColor($r('app.color.text_primary'))
                  Text(item.description)
                    .fontSize(Constants.FONT_SIZE_SMALL)
                    .fontColor($r('app.color.text_secondary'))
                    .margin({ top: 2 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                .margin({ left: 10 })
              }
              .width('100%')
              .padding(Constants.PADDING_INNER)
              .backgroundColor($r('app.color.background'))
              .borderRadius(Constants.RADIUS_SMALL)
            }, (item: PermissionItem): string => item.key)
          }
          .width('100%')
          Row() {
            Button('取消', { type: ButtonType.Normal, stateEffect: true })
              .layoutWeight(1)
              .height(44)
              .fontColor($r('app.color.text_primary'))
              .backgroundColor($r('app.color.background'))
              .onClick(() => { this.closeRoleDialog() })
            Button(this.isEditing ? '保存' : '创建', { type: ButtonType.Normal, stateEffect: true })
              .layoutWeight(1)
              .height(44)
              .fontColor($r('sys.color.icon_on_primary'))
              .backgroundColor($r('app.color.primary'))
              .margin({ left: Constants.GAP_MEDIUM })
              .onClick(() => { this.saveRole() })
          }
          .width('100%')
        }
        .width('100%')
        .padding(20)
      }
      .width('100%')
      .margin({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE })
      .backgroundColor($r('app.color.card'))
      .borderRadius(Constants.RADIUS_CARD)
      .shadow(Constants.SHADOW_CARD)
      .constraintSize({ maxHeight: '84%' })
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private DeleteRoleDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.overlay'))
      Column({ space: Constants.GAP_MEDIUM }) {
        Text('删除角色')
          .fontSize(Constants.FONT_SIZE_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        Text('确定删除角色“' + this.deleteRoleName + '”吗？')
          .fontSize(Constants.FONT_SIZE_COMMON)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
        Row() {
          Button('取消', { type: ButtonType.Normal, stateEffect: true })
            .layoutWeight(1)
            .height(44)
            .fontColor($r('app.color.text_primary'))
            .backgroundColor($r('app.color.background'))
            .onClick(() => { this.closeDeleteDialog() })
          Button('删除', { type: ButtonType.Normal, stateEffect: true })
            .layoutWeight(1)
            .height(44)
            .fontColor($r('sys.color.icon_on_primary'))
            .backgroundColor($r('app.color.danger'))
            .margin({ left: Constants.GAP_MEDIUM })
            .onClick(() => { this.deleteRole() })
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

  private async refreshRoles(): Promise<void> {
    try {
      this.roleList = await AdminService.getRoles()
      const permissions: AdminPermission[] = await AdminService.getPermissions()
      const items: PermissionItem[] = []
      for (let index = 0; index < permissions.length; index++) {
        const permission: AdminPermission = permissions[index]
        items.push(new PermissionItem(permission.id, permission.name, '服务端权限'))
      }
      this.permissionItems = items
    } catch (err) {
      this.showToast('加载角色数据失败')
    }
  }

  private openCreateDialog(): void {
    this.isEditing = false
    this.editingRoleId = ''
    this.roleName = ''
    this.selectedPermissions = []
    this.showRoleDialog = true
  }

  private openEditDialog(role: AdminRole): void {
    const permissions: string[] = []
    for (let i = 0; i < role.permissions.length; i++) {
      permissions.push(role.permissions[i])
    }
    this.isEditing = true
    this.editingRoleId = role.id
    this.roleName = role.name
    this.selectedPermissions = permissions
    this.showRoleDialog = true
  }

  private closeRoleDialog(): void {
    this.showRoleDialog = false
    this.roleName = ''
    this.selectedPermissions = []
  }

  private async saveRole(): Promise<void> {
    let result: AdminResult
    if (this.isEditing) {
      result = await AdminService.updateRole(this.editingRoleId, this.roleName.trim(), this.selectedPermissions)
    } else {
      result = await AdminService.createRole(this.roleName.trim(), this.selectedPermissions)
    }
    if (!result.success) {
      this.showToast(result.message)
      return
    }
    this.closeRoleDialog()
    await this.refreshRoles()
    this.showToast(this.isEditing ? '角色已保存' : '角色已创建')
  }

  private async setDefaultRole(roleId: string): Promise<void> {
    const result: AdminResult = await AdminService.setDefaultRole(roleId)
    if (result.success) {
      await this.refreshRoles()
    }
    this.showToast(result.success ? '默认角色已更新' : result.message)
  }

  private openDeleteDialog(role: AdminRole): void {
    this.deleteRoleId = role.id
    this.deleteRoleName = role.name
  }

  private closeDeleteDialog(): void {
    this.deleteRoleId = ''
    this.deleteRoleName = ''
  }

  private async deleteRole(): Promise<void> {
    const result: AdminResult = await AdminService.deleteRole(this.deleteRoleId)
    if (!result.success) {
      this.showToast(result.message)
      return
    }
    this.closeDeleteDialog()
    await this.refreshRoles()
    this.showToast('角色已删除')
  }

  private hasPermission(permission: string): boolean {
    for (let i = 0; i < this.selectedPermissions.length; i++) {
      if (this.selectedPermissions[i] === permission) {
        return true
      }
    }
    return false
  }

  private togglePermission(permission: string, selected: boolean): void {
    const next: string[] = []
    let exists: boolean = false
    for (let i = 0; i < this.selectedPermissions.length; i++) {
      if (this.selectedPermissions[i] === permission) {
        exists = true
        if (selected) {
          next.push(permission)
        }
      } else {
        next.push(this.selectedPermissions[i])
      }
    }
    if (selected && !exists) {
      next.push(permission)
    }
    this.selectedPermissions = next
  }

  private getPermissionSummary(permissions: string[]): string {
    const names: string[] = []
    for (let i = 0; i < permissions.length; i++) {
      for (let j = 0; j < this.permissionItems.length; j++) {
        if (permissions[i] === this.permissionItems[j].key) {
          names.push(this.permissionItems[j].label)
          break
        }
      }
    }
    return names.join('、')
  }

  private showToast(message: string): void {
    try {
      this.toast.openToast({ message: message, duration: 1500 })
    } catch (err) {
      console.error('openToast failed')
    }
  }
}

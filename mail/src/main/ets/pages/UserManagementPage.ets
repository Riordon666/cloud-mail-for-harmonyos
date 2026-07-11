import { PromptAction } from '@kit.ArkUI'
import { HdsNavDestination, HdsNavDestinationTitleMode } from '@kit.UIDesignKit'
import Constants from '../common/Constants'
import { AdminResult, AdminRole, AdminService, AdminUser } from '../common/AdminService'
import { EmptyState } from '../components/EmptyState'

@Component
export struct UserManagementPage {
  @StorageLink('authRole') authRole: string = 'user'
  @StorageLink('adminUserRevision') @Watch('onUserRevision') userRevision: number = 0
  @State userList: AdminUser[] = []
  @State roleList: AdminRole[] = []
  @State keyword: string = ''
  @State statusFilter: string = '全部'
  @State currentPage: number = 1
  @State showUserDialog: boolean = false
  @State isEditing: boolean = false
  @State editingUserId: number = 0
  @State emailPrefix: string = ''
  @State password: string = ''
  @State selectedRoleId: string = 'user'
  @State selectedStatus: string = '正常'
  @State deleteUserId: number = 0
  @State deleteUserEmail: string = ''
  private readonly pageSize: number = 5
  private toast: PromptAction = this.getUIContext().getPromptAction()

  aboutToAppear(): void {
    AdminService.initialize()
    this.refreshData()
  }

  private onUserRevision(): void {
    this.refreshData()
  }

  build() {
    HdsNavDestination() {
      if (this.authRole !== 'admin') {
        EmptyState({ icon: $r('sys.symbol.person'), message: '仅管理员可访问用户管理' })
      } else {
        Stack() {
          Scroll() {
            Column({ space: Constants.GAP_MEDIUM }) {
              Row() {
                Column() {
                  Text('用户管理')
                    .fontSize(Constants.FONT_SIZE_TITLE)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.text_primary'))
                  Text('创建、编辑、禁用或恢复站内邮箱用户。')
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

              TextInput({ placeholder: '搜索邮箱账号', text: this.keyword })
                .height(46)
                .fontColor($r('app.color.text_primary'))
                .placeholderColor($r('app.color.text_tertiary'))
                .backgroundColor($r('app.color.card'))
                .border({ width: 0.5, color: $r('app.color.divider') })
                .borderRadius(Constants.RADIUS_SMALL)
                .padding({ left: Constants.PADDING_INNER, right: Constants.PADDING_INNER })
                .onChange((value: string) => {
                  this.keyword = value
                  this.currentPage = 1
                })

              this.StatusFilters()

              if (this.getFilteredUsers().length === 0) {
                EmptyState({ icon: $r('sys.symbol.person'), message: '没有匹配的用户', iconSize: 40 })
                  .height(220)
              } else {
                Column({ space: Constants.GAP_SMALL }) {
                  ForEach(this.getPagedUsers(), (item: AdminUser) => {
                    this.UserCard(item)
                  }, (item: AdminUser): string => item.id.toString())
                }
                .width('100%')

                this.Pagination()
              }
              Blank().height(24)
            }
            .width('100%')
            .padding({ left: Constants.PADDING_EDGE, right: Constants.PADDING_EDGE, top: 16, bottom: 24 })
          }
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Off)

          if (this.showUserDialog) {
            this.UserDialog()
          }
          if (this.deleteUserId !== 0) {
            this.DeleteUserDialog()
          }
        }
        .width('100%')
        .height('100%')
      }
    }
    .titleBar({ content: { title: { mainTitle: '用户管理' } }, enableComponentSafeArea: true })
    .hideBackButton(false)
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  private StatusFilters() {
    Row({ space: Constants.GAP_SMALL }) {
      this.FilterButton('全部')
      this.FilterButton('正常')
      this.FilterButton('禁用')
      this.FilterButton('已删除')
    }
    .width('100%')
  }

  @Builder
  private FilterButton(label: string) {
    Button(label, { type: ButtonType.Normal, stateEffect: true })
      .height(32)
      .fontSize(Constants.FONT_SIZE_SMALL)
      .fontColor(this.statusFilter === label ? $r('sys.color.icon_on_primary') : $r('app.color.text_secondary'))
      .backgroundColor(this.statusFilter === label ? $r('app.color.primary') : $r('app.color.card'))
      .borderRadius(Constants.RADIUS_FULL)
      .padding({ left: 12, right: 12 })
      .onClick(() => {
        this.statusFilter = label
        this.currentPage = 1
      })
  }

  @Builder
  private UserCard(item: AdminUser) {
    Column({ space: Constants.GAP_SMALL }) {
      Row() {
        Column() {
          Text(item.email)
            .fontSize(Constants.FONT_SIZE_SUBTITLE)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          Text(this.getRoleName(item.roleId) + ' · 已发送 ' + item.sendCount.toString() + ' 封')
            .fontSize(Constants.FONT_SIZE_SMALL)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Text(this.getStatusLabel(item))
          .fontSize(Constants.FONT_SIZE_SMALL)
          .fontColor(this.getStatusColor(item))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(Constants.RADIUS_FULL)
          .backgroundColor($r('app.color.background'))
      }
      .width('100%')

      Row({ space: Constants.GAP_SMALL }) {
        if (item.deleted) {
          Button('恢复', { type: ButtonType.Normal, stateEffect: true })
            .height(32)
            .fontSize(Constants.FONT_SIZE_SMALL)
            .fontColor($r('app.color.primary'))
            .backgroundColor($r('app.color.primary_light'))
            .onClick(() => { this.restoreUser(item.id) })
        } else {
          Button('编辑', { type: ButtonType.Normal, stateEffect: true })
            .height(32)
            .fontSize(Constants.FONT_SIZE_SMALL)
            .fontColor($r('app.color.primary'))
            .backgroundColor($r('app.color.primary_light'))
            .onClick(() => { this.openEditDialog(item) })
          Button('重置计数', { type: ButtonType.Normal, stateEffect: true })
            .height(32)
            .fontSize(Constants.FONT_SIZE_SMALL)
            .fontColor($r('app.color.text_secondary'))
            .backgroundColor($r('app.color.background'))
            .onClick(() => { this.resetSendCount(item.id) })
          if (item.roleId !== 'admin') {
            Button('删除', { type: ButtonType.Normal, stateEffect: true })
              .height(32)
              .fontSize(Constants.FONT_SIZE_SMALL)
              .fontColor($r('app.color.danger'))
              .backgroundColor($r('app.color.background'))
              .onClick(() => { this.openDeleteDialog(item) })
          }
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
  private Pagination() {
    Row() {
      Button('上一页', { type: ButtonType.Normal, stateEffect: true })
        .height(36)
        .enabled(this.currentPage > 1)
        .fontSize(Constants.FONT_SIZE_SMALL)
        .fontColor($r('app.color.primary'))
        .backgroundColor($r('app.color.card'))
        .onClick(() => { this.currentPage -= 1 })
      Blank()
      Text(this.currentPage.toString() + ' / ' + this.getPageCount().toString() + ' 页')
        .fontSize(Constants.FONT_SIZE_SMALL)
        .fontColor($r('app.color.text_secondary'))
      Blank()
      Button('下一页', { type: ButtonType.Normal, stateEffect: true })
        .height(36)
        .enabled(this.currentPage < this.getPageCount())
        .fontSize(Constants.FONT_SIZE_SMALL)
        .fontColor($r('app.color.primary'))
        .backgroundColor($r('app.color.card'))
        .onClick(() => { this.currentPage += 1 })
    }
    .width('100%')
    .margin({ top: 4 })
  }

  @Builder
  private UserDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.overlay'))

      Column({ space: Constants.GAP_MEDIUM }) {
        Text(this.isEditing ? '编辑用户' : '创建用户')
          .fontSize(Constants.FONT_SIZE_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')

        if (!this.isEditing) {
          Text('邮箱固定使用 ' + Constants.MAIL_DOMAIN + ' 后缀。')
            .fontSize(Constants.FONT_SIZE_SMALL)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
          Row() {
            TextInput({ placeholder: '邮箱账号', text: this.emailPrefix })
              .layoutWeight(1)
              .height(46)
              .fontColor($r('app.color.text_primary'))
              .placeholderColor($r('app.color.text_tertiary'))
              .backgroundColor($r('app.color.background'))
              .border({ width: 0.5, color: $r('app.color.divider') })
              .borderRadius(Constants.RADIUS_SMALL)
              .padding({ left: Constants.PADDING_INNER, right: Constants.PADDING_INNER })
              .onChange((value: string) => { this.emailPrefix = value })
            Text(Constants.MAIL_DOMAIN)
              .fontSize(Constants.FONT_SIZE_COMMON)
              .fontColor($r('app.color.text_secondary'))
              .padding({ left: 8, right: 4 })
          }
          .width('100%')
        }

        TextInput({ placeholder: this.isEditing ? '留空则不修改密码' : '设置密码（至少 6 位）', text: this.password })
          .type(InputType.Password)
          .height(46)
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.text_tertiary'))
          .backgroundColor($r('app.color.background'))
          .border({ width: 0.5, color: $r('app.color.divider') })
          .borderRadius(Constants.RADIUS_SMALL)
          .padding({ left: Constants.PADDING_INNER, right: Constants.PADDING_INNER })
          .onChange((value: string) => { this.password = value })

        Text('角色')
          .fontSize(Constants.FONT_SIZE_SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.roleList, (role: AdminRole) => {
            Button(role.name, { type: ButtonType.Normal, stateEffect: true })
              .height(34)
              .fontSize(Constants.FONT_SIZE_SMALL)
              .fontColor(this.selectedRoleId === role.id ? $r('sys.color.icon_on_primary') : $r('app.color.text_secondary'))
              .backgroundColor(this.selectedRoleId === role.id ? $r('app.color.primary') : $r('app.color.background'))
              .margin({ right: 8, bottom: 8 })
              .onClick(() => { this.selectedRoleId = role.id })
          }, (role: AdminRole): string => role.id)
        }
        .width('100%')

        if (this.isEditing) {
          Row() {
            Text('账号状态')
              .fontSize(Constants.FONT_SIZE_SUBTITLE)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.selectedStatus === '正常' })
              .selectedColor($r('app.color.primary'))
              .onChange((enabled: boolean) => { this.selectedStatus = enabled ? '正常' : '禁用' })
          }
          .width('100%')
        }

        Row() {
          Button('取消', { type: ButtonType.Normal, stateEffect: true })
            .layoutWeight(1)
            .height(44)
            .fontColor($r('app.color.text_primary'))
            .backgroundColor($r('app.color.background'))
            .onClick(() => { this.closeUserDialog() })
          Button(this.isEditing ? '保存' : '创建', { type: ButtonType.Normal, stateEffect: true })
            .layoutWeight(1)
            .height(44)
            .fontColor($r('sys.color.icon_on_primary'))
            .backgroundColor($r('app.color.primary'))
            .margin({ left: Constants.GAP_MEDIUM })
            .onClick(() => { this.saveUser() })
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

  @Builder
  private DeleteUserDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.overlay'))
      Column({ space: Constants.GAP_MEDIUM }) {
        Text('删除用户')
          .fontSize(Constants.FONT_SIZE_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        Text('确认删除 ' + this.deleteUserEmail + ' 吗？用户可以在此页面恢复。')
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
            .onClick(() => { this.deleteUser() })
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

  private async refreshData(): Promise<void> {
    try {
      this.userList = await AdminService.getUsers()
      this.roleList = await AdminService.getRoles()
      if (this.currentPage > this.getPageCount()) {
        this.currentPage = this.getPageCount()
      }
    } catch (err) {
      this.showToast('加载用户数据失败')
    }
  }

  private getFilteredUsers(): AdminUser[] {
    const result: AdminUser[] = []
    const normalizedKeyword: string = this.keyword.trim().toLowerCase()
    for (let i = 0; i < this.userList.length; i++) {
      const user: AdminUser = this.userList[i]
      if (normalizedKeyword !== '' && user.email.toLowerCase().indexOf(normalizedKeyword) < 0) {
        continue
      }
      if (this.statusFilter === '已删除' && !user.deleted) {
        continue
      }
      if (this.statusFilter === '正常' && (user.deleted || user.status !== '正常')) {
        continue
      }
      if (this.statusFilter === '禁用' && (user.deleted || user.status !== '禁用')) {
        continue
      }
      result.push(user)
    }
    return result
  }

  private getPagedUsers(): AdminUser[] {
    const filtered: AdminUser[] = this.getFilteredUsers()
    const result: AdminUser[] = []
    const start: number = (this.currentPage - 1) * this.pageSize
    const end: number = Math.min(start + this.pageSize, filtered.length)
    for (let i = start; i < end; i++) {
      result.push(filtered[i])
    }
    return result
  }

  private getPageCount(): number {
    const count: number = Math.ceil(this.getFilteredUsers().length / this.pageSize)
    return count < 1 ? 1 : count
  }

  private getRoleName(roleId: string): string {
    for (let i = 0; i < this.roleList.length; i++) {
      if (this.roleList[i].id === roleId) {
        return this.roleList[i].name
      }
    }
    return '未知角色'
  }

  private getStatusLabel(user: AdminUser): string {
    if (user.deleted) {
      return '已删除'
    }
    return user.status
  }

  private getStatusColor(user: AdminUser): ResourceColor {
    if (user.deleted) {
      return $r('app.color.text_tertiary')
    }
    if (user.status === '禁用') {
      return $r('app.color.danger')
    }
    return $r('app.color.primary')
  }

  private openCreateDialog(): void {
    this.isEditing = false
    this.editingUserId = 0
    this.emailPrefix = ''
    this.password = ''
    this.selectedRoleId = this.getDefaultRoleId()
    this.selectedStatus = '正常'
    this.showUserDialog = true
  }

  private openEditDialog(user: AdminUser): void {
    this.isEditing = true
    this.editingUserId = user.id
    this.password = ''
    this.selectedRoleId = user.roleId
    this.selectedStatus = user.status
    this.showUserDialog = true
  }

  private closeUserDialog(): void {
    this.showUserDialog = false
    this.emailPrefix = ''
    this.password = ''
  }

  private openDeleteDialog(user: AdminUser): void {
    this.deleteUserId = user.id
    this.deleteUserEmail = user.email
  }

  private closeDeleteDialog(): void {
    this.deleteUserId = 0
    this.deleteUserEmail = ''
  }

  private async saveUser(): Promise<void> {
    let result: AdminResult
    if (this.isEditing) {
      result = await AdminService.updateUser(this.editingUserId, this.password, this.selectedRoleId, this.selectedStatus)
    } else {
      if (!this.isValidPrefix(this.emailPrefix)) {
        this.showToast('请输入正确的邮箱账号')
        return
      }
      result = await AdminService.createUser(this.emailPrefix.trim() + Constants.MAIL_DOMAIN, this.password, this.selectedRoleId)
    }
    if (!result.success) {
      this.showToast(result.message)
      return
    }
    this.closeUserDialog()
    await this.refreshData()
    this.showToast(this.isEditing ? '用户已保存' : '用户已创建')
  }

  private async deleteUser(): Promise<void> {
    const result: AdminResult = await AdminService.deleteUser(this.deleteUserId)
    if (!result.success) {
      this.showToast(result.message)
      return
    }
    this.closeDeleteDialog()
    await this.refreshData()
    this.showToast('用户已删除')
  }

  private async restoreUser(userId: number): Promise<void> {
    const result: AdminResult = await AdminService.restoreUser(userId)
    if (result.success) {
      await this.refreshData()
    }
    this.showToast(result.success ? '用户已恢复' : result.message)
  }

  private async resetSendCount(userId: number): Promise<void> {
    const result: AdminResult = await AdminService.resetSendCount(userId)
    if (result.success) {
      await this.refreshData()
    }
    this.showToast(result.success ? '发送计数已重置' : result.message)
  }

  private getDefaultRoleId(): string {
    for (let i = 0; i < this.roleList.length; i++) {
      if (this.roleList[i].isDefault) {
        return this.roleList[i].id
      }
    }
    return 'user'
  }

  private isValidPrefix(value: string): boolean {
    const prefix: string = value.trim()
    return prefix !== '' && prefix.indexOf('@') < 0 && prefix.indexOf(' ') < 0
  }

  private showToast(message: string): void {
    try {
      this.toast.openToast({ message: message, duration: 1500 })
    } catch (err) {
      console.error('openToast failed')
    }
  }
}

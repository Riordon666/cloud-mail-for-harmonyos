import { preferences } from '@kit.ArkData'

export class MailDraft {
  id: number
  toEmail: string
  ccEmail: string
  bccEmail: string
  subject: string
  content: string
  time: string

  constructor(id: number, toEmail: string, ccEmail: string, bccEmail: string, subject: string, content: string, time: string) {
    this.id = id
    this.toEmail = toEmail
    this.ccEmail = ccEmail
    this.bccEmail = bccEmail
    this.subject = subject
    this.content = content
    this.time = time
  }
}

class DraftStorageItem {
  id: number = 0
  toEmail: string = ''
  ccEmail: string = ''
  bccEmail: string = ''
  subject: string = ''
  content: string = ''
  time: string = ''
}

export class DraftService {
  private static draftPreferences: preferences.Preferences | null = null
  private static drafts: MailDraft[] = []
  private static nextId: number = 1

  static initialize(context: Context): void {
    try {
      DraftService.draftPreferences = preferences.getPreferencesSync(context, { name: 'cloud_mail_drafts' })
      const savedDrafts: string = DraftService.draftPreferences.getSync('items', '') as string
      if (savedDrafts !== '') {
        const items: DraftStorageItem[] = JSON.parse(savedDrafts) as DraftStorageItem[]
        const loadedDrafts: MailDraft[] = []
        let maximumId: number = 0
        for (let index = 0; index < items.length; index++) {
          const item: DraftStorageItem = items[index]
          loadedDrafts.push(new MailDraft(item.id, item.toEmail, item.ccEmail, item.bccEmail, item.subject, item.content, item.time))
          if (item.id > maximumId) {
            maximumId = item.id
          }
        }
        DraftService.drafts = loadedDrafts
        DraftService.nextId = maximumId + 1
      }
    } catch (err) {
      DraftService.drafts = []
      DraftService.nextId = 1
      console.error('initialize draft preferences failed')
    }
    AppStorage.setOrCreate('draftRevision', 0)
  }

  static getDrafts(): MailDraft[] {
    const result: MailDraft[] = []
    for (let index = 0; index < DraftService.drafts.length; index++) {
      const draft: MailDraft = DraftService.drafts[index]
      result.push(new MailDraft(draft.id, draft.toEmail, draft.ccEmail, draft.bccEmail, draft.subject, draft.content, draft.time))
    }
    return result
  }

  static saveDraft(id: number, toEmail: string, ccEmail: string, bccEmail: string, subject: string, content: string): number {
    if (toEmail.trim() === '' && ccEmail.trim() === '' && bccEmail.trim() === '' && subject.trim() === '' && content.trim() === '') {
      return 0
    }
    const draftId: number = id === 0 ? DraftService.nextId : id
    if (id === 0) {
      DraftService.nextId += 1
    }
    const nextDraft: MailDraft = new MailDraft(draftId, toEmail, ccEmail, bccEmail, subject, content, '已保存')
    let updated: boolean = false
    for (let index = 0; index < DraftService.drafts.length; index++) {
      if (DraftService.drafts[index].id === draftId) {
        DraftService.drafts[index] = nextDraft
        updated = true
        break
      }
    }
    if (!updated) {
      DraftService.drafts.unshift(nextDraft)
    }
    DraftService.persist()
    return draftId
  }

  static deleteDraft(id: number): void {
    const result: MailDraft[] = []
    for (let index = 0; index < DraftService.drafts.length; index++) {
      if (DraftService.drafts[index].id !== id) {
        result.push(DraftService.drafts[index])
      }
    }
    DraftService.drafts = result
    DraftService.persist()
  }

  private static persist(): void {
    if (DraftService.draftPreferences === null) {
      return
    }
    try {
      DraftService.draftPreferences.putSync('items', JSON.stringify(DraftService.drafts))
      DraftService.draftPreferences.flushSync()
      DraftService.notifyChange()
    } catch (err) {
      console.error('save draft preferences failed')
    }
  }

  private static notifyChange(): void {
    const revision: number | undefined = AppStorage.get('draftRevision') as number | undefined
    AppStorage.set('draftRevision', revision === undefined ? 1 : revision + 1)
  }
}

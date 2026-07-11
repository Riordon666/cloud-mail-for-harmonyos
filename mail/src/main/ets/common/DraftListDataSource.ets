import { MailDraft } from './DraftService'

export class DraftListDataSource implements IDataSource {
  private dataList: MailDraft[] = []
  private listeners: DataChangeListener[] = []

  totalCount(): number {
    return this.dataList.length
  }

  getData(index: number): MailDraft {
    return this.dataList[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    const exists = this.listeners.findIndex((l: DataChangeListener): boolean => l === listener)
    if (exists < 0) {
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.findIndex((l: DataChangeListener): boolean => l === listener)
    if (pos >= 0) {
      this.listeners.splice(pos, 1)
    }
  }

  setData(data: MailDraft[]): void {
    this.dataList = data
    this.notifyDataReload()
  }

  removeItem(id: number): void {
    for (let i = 0; i < this.dataList.length; i++) {
      if (this.dataList[i].id === id) {
        this.dataList.splice(i, 1)
        this.notifyDataDelete(i)
        return
      }
    }
  }

  private notifyDataReload(): void {
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataReloaded()
    }
  }

  private notifyDataDelete(index: number): void {
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataDelete(index)
    }
  }
}
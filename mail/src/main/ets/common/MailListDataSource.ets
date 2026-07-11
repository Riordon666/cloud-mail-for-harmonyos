import { MailItem } from './MailModels'

export class MailListDataSource implements IDataSource {
  private dataList: MailItem[] = []
  private listeners: DataChangeListener[] = []

  totalCount(): number {
    return this.dataList.length
  }

  getData(index: number): MailItem {
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

  setData(data: MailItem[]): void {
    this.dataList = data
    this.notifyDataReload()
  }

  updateItem(id: number, updatedItem: MailItem): void {
    for (let i = 0; i < this.dataList.length; i++) {
      if (this.dataList[i].id === id) {
        this.dataList[i] = updatedItem
        this.notifyDataChange(i)
        return
      }
    }
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

  private notifyDataChange(index: number): void {
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataChange(index)
    }
  }

  private notifyDataDelete(index: number): void {
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataDelete(index)
    }
  }
}
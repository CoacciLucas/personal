import Store from 'electron-store'

interface SettingsSchema {
  apiKey: string
}

const store = new Store<SettingsSchema>({
  defaults: {
    apiKey: ''
  }
})

export class SettingsService {
  getApiKey(): string {
    return store.get('apiKey', '')
  }

  saveApiKey(key: string): void {
    store.set('apiKey', key)
  }

  hasApiKey(): boolean {
    return !!store.get('apiKey', '')
  }
}

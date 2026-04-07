import { contextBridge, ipcRenderer } from 'electron'

export interface API {
  // Chat
  chat: {
    send: (messages: unknown[], hasImage: boolean, selectedModelId?: string) => Promise<string>
    clear: () => void
    onCleared: (callback: () => void) => () => void
    onProgress: (callback: (stage: string) => void) => () => void
  }

  // Settings
  settings: {
    getApiKey: () => Promise<string>
    saveApiKey: (key: string) => Promise<void>
    hasApiKey: () => Promise<boolean>
  }

  // Speech
  speech: {
    start: () => Promise<boolean>
    stop: () => Promise<boolean>
    toggle: () => Promise<boolean>
    onTranscript: (callback: (transcript: { type: string; text: string; isFinal: boolean }) => void) => () => void
  }

  // Screenshot
  screenshot: {
    capture: () => Promise<string>
    onCaptured: (callback: (base64: string) => void) => () => void
  }

  // Models & Assistants
  models: {
    getAll: () => Promise<{ id: string; name: string; supportsVision: boolean }[]>
  }

  assistants: {
    getAll: () => Promise<{ id: string; name: string; prompt: string }[]>
  }

  // Panels
  panel: {
    toggleChat: () => void
    createToolbar: () => void
    showApiKeyDialog: () => void
    onShowApiKeyDialog: (callback: () => void) => () => void
  }

  // Main window
  main: {
    hide: () => void
    showSettings: () => void
  }
}

const api: API = {
  chat: {
    send: (messages, hasImage, selectedModelId) => ipcRenderer.invoke('chat:send', messages, hasImage, selectedModelId),
    clear: () => ipcRenderer.send('chat:clear'),
    onCleared: (callback) => {
      const handler = () => callback()
      ipcRenderer.on('chat:cleared', handler)
      return () => ipcRenderer.removeListener('chat:cleared', handler)
    },
    onProgress: (callback) => {
      const handler = (_event: Electron.IpcRendererEvent, stage: string) => callback(stage)
      ipcRenderer.on('chat:progress', handler)
      return () => ipcRenderer.removeListener('chat:progress', handler)
    }
  },

  settings: {
    getApiKey: () => ipcRenderer.invoke('settings:getApiKey'),
    saveApiKey: (key) => ipcRenderer.invoke('settings:saveApiKey', key),
    hasApiKey: () => ipcRenderer.invoke('settings:hasApiKey')
  },

  speech: {
    start: () => ipcRenderer.invoke('speech:start'),
    stop: () => ipcRenderer.invoke('speech:stop'),
    toggle: () => ipcRenderer.invoke('speech:toggle'),
    onTranscript: (callback) => {
      const handler = (_event: Electron.IpcRendererEvent, transcript: { type: string; text: string; isFinal: boolean }) => callback(transcript)
      ipcRenderer.on('speech:transcript', handler)
      return () => ipcRenderer.removeListener('speech:transcript', handler)
    }
  },

  screenshot: {
    capture: () => ipcRenderer.invoke('screenshot:capture'),
    onCaptured: (callback) => {
      const handler = (_event: Electron.IpcRendererEvent, base64: string) => callback(base64)
      ipcRenderer.on('screenshot:captured', handler)
      return () => ipcRenderer.removeListener('screenshot:captured', handler)
    }
  },

  models: {
    getAll: () => ipcRenderer.invoke('models:getAll')
  },

  assistants: {
    getAll: () => ipcRenderer.invoke('assistants:getAll')
  },

  panel: {
    toggleChat: () => ipcRenderer.send('panel:toggleChat'),
    createToolbar: () => ipcRenderer.send('panel:createToolbar'),
    showApiKeyDialog: () => ipcRenderer.send('panel:showApiKeyDialog'),
    onShowApiKeyDialog: (callback) => {
      const handler = () => callback()
      ipcRenderer.on('panel:showApiKeyDialog', handler)
      return () => ipcRenderer.removeListener('panel:showApiKeyDialog', handler)
    }
  },

  main: {
    hide: () => ipcRenderer.send('main:hide'),
    showSettings: () => ipcRenderer.send('main:showSettings')
  }
}

contextBridge.exposeInMainWorld('api', api)

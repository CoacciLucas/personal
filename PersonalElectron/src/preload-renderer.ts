// Types for the preload bridge - mirrors the API interface
export interface API {
  chat: {
    send: (messages: unknown[], hasImage: boolean, selectedModelId?: string) => Promise<string>
    clear: () => void
    onCleared: (callback: () => void) => () => void
    onProgress: (callback: (stage: string) => void) => () => void
  }
  settings: {
    getApiKey: () => Promise<string>
    saveApiKey: (key: string) => Promise<void>
    hasApiKey: () => Promise<boolean>
  }
  speech: {
    start: () => Promise<boolean>
    stop: () => Promise<boolean>
    toggle: () => Promise<boolean>
    onTranscript: (callback: (transcript: { type: string; text: string; isFinal: boolean }) => void) => () => void
  }
  screenshot: {
    capture: () => Promise<string>
    onCaptured: (callback: (base64: string) => void) => () => void
  }
  models: {
    getAll: () => Promise<{ id: string; name: string; supportsVision: boolean }[]>
  }
  assistants: {
    getAll: () => Promise<{ id: string; name: string; prompt: string }[]>
  }
  panel: {
    toggleChat: () => void
    createToolbar: () => void
    showApiKeyDialog: () => void
    onShowApiKeyDialog: (callback: () => void) => () => void
  }
}

import { app, BrowserWindow, ipcMain } from 'electron'
import { join } from 'path'
import { is } from '@electron-toolkit/utils'
import { GlmService } from '../services/GlmService'
import { SettingsService } from '../services/SettingsService'
import { ModelService } from '../services/ModelService'
import { AssistantService } from '../services/AssistantService'
import { HotkeyService } from '../services/HotkeyService'
import { ScreenshotService } from '../services/ScreenshotService'
import { SpeechService } from '../services/SpeechService'
import {
  createToolbarWindow,
  toggleChatWindow,
  closeAllWindows,
  setOnAllFloatingClosed
} from '../services/PanelManager'

const glmService = new GlmService()
const settingsService = new SettingsService()
const modelService = new ModelService()
const assistantService = new AssistantService()
const hotkeyService = new HotkeyService()
const screenshotService = new ScreenshotService()
const speechService = new SpeechService()

let mainWindow: BrowserWindow | null = null

function createMainWindow(): void {
  mainWindow = new BrowserWindow({
    width: 400,
    height: 600,
    show: false,
    resizable: true,
    webPreferences: {
      preload: join(__dirname, '../preload/index.js'),
      sandbox: false
    }
  })

  mainWindow.on('ready-to-show', () => {
    mainWindow?.setContentProtection(true)
  })

  mainWindow.on('close', (e) => {
    // If floating windows exist, hide instead of closing
    const allWindows = BrowserWindow.getAllWindows()
    if (allWindows.length > 1) {
      e.preventDefault()
      mainWindow?.hide()
    }
  })

  mainWindow.on('closed', () => {
    mainWindow = null
  })

  if (is.dev && process.env['ELECTRON_RENDERER_URL']) {
    mainWindow.loadURL(process.env['ELECTRON_RENDERER_URL'])
  } else {
    mainWindow.loadFile(join(__dirname, '../renderer/index.html'))
  }
}

// --- IPC Handlers ---

// Chat
ipcMain.handle('chat:send', async (_event, messages: unknown[], hasImage: boolean, selectedModelId?: string) => {
  const sender = _event.sender
  glmService.onProgress = (stage: string) => {
    try { sender.send('chat:progress', stage) } catch {}
  }
  try {
    return await glmService.sendMessage(messages as any[], hasImage, selectedModelId)
  } finally {
    glmService.onProgress = null
    glmService.onStreamToken = null
  }
})

ipcMain.on('chat:clear', () => {
  // Broadcast to all windows
  BrowserWindow.getAllWindows().forEach((win) => {
    win.webContents.send('chat:cleared')
  })
})

// Settings
ipcMain.handle('settings:getApiKey', () => settingsService.getApiKey())
ipcMain.handle('settings:saveApiKey', (_event, key: string) => {
  settingsService.saveApiKey(key)
  glmService.setApiKey(key)
  speechService.setApiKey(key)
})
ipcMain.handle('settings:hasApiKey', () => settingsService.hasApiKey())

// Models
ipcMain.handle('models:getAll', () => {
  const models = modelService.getModels()
  glmService.setAvailableModels(models)
  return models
})

// Assistants
ipcMain.handle('assistants:getAll', () => assistantService.getAssistants())

// Screenshot
ipcMain.handle('screenshot:capture', async () => {
  const base64 = await screenshotService.captureScreen()
  // Broadcast to all windows
  BrowserWindow.getAllWindows().forEach((win) => {
    win.webContents.send('screenshot:captured', base64)
  })
  return base64
})

// Speech
ipcMain.handle('speech:start', () => {
  speechService.startListening()
  return true
})

ipcMain.handle('speech:stop', () => {
  speechService.stopListening()
  return false
})

ipcMain.handle('speech:toggle', () => {
  return speechService.toggleListening()
})

// Speech transcript forwarding
speechService.onTranscript((transcript) => {
  BrowserWindow.getAllWindows().forEach((win) => {
    win.webContents.send('speech:transcript', transcript)
  })
})

// Panels
ipcMain.on('panel:toggleChat', () => toggleChatWindow())
ipcMain.on('panel:createToolbar', () => createToolbarWindow())
ipcMain.on('panel:showApiKeyDialog', () => {
  // Show main window with settings view
  if (mainWindow) {
    mainWindow.webContents.executeJavaScript('window.location.hash = "settings"')
    mainWindow.show()
    mainWindow.focus()
  }
})
ipcMain.on('main:hide', () => {
  mainWindow?.hide()
})
ipcMain.on('main:showSettings', () => {
  if (mainWindow) {
    mainWindow.webContents.executeJavaScript('window.location.hash = "settings"')
    mainWindow.show()
    mainWindow.focus()
  }
})

// Hotkeys
hotkeyService.setScreenshotCallback(async () => {
  try {
    const base64 = await screenshotService.captureScreen()
    BrowserWindow.getAllWindows().forEach((win) => {
      win.webContents.send('screenshot:captured', base64)
    })
  } catch (err) {
    console.error('Screenshot failed:', err)
  }
})

hotkeyService.setSpeechToggleCallback(() => {
  speechService.toggleListening()
  const isListening = speechService.getIsListening()
  BrowserWindow.getAllWindows().forEach((win) => {
    win.webContents.send('speech:stateChanged', isListening)
  })
})

// --- App Lifecycle ---

app.whenReady().then(() => {
  // Load saved API key
  const apiKey = settingsService.getApiKey()
  if (apiKey) {
    glmService.setApiKey(apiKey)
    speechService.setApiKey(apiKey)
  }

  // Register global hotkeys
  hotkeyService.register()

  // Create main window (hidden by default)
  createMainWindow()

  // When all floating windows close, show main window as fallback
  setOnAllFloatingClosed(() => {
    if (mainWindow) {
      mainWindow.webContents.executeJavaScript('window.location.hash = "settings"')
      mainWindow.show()
    }
  })

  if (apiKey) {
    // Has API key: create floating toolbar, keep main window hidden
    createToolbarWindow()
  } else {
    // No API key: show main window so user can configure
    mainWindow?.once('ready-to-show', () => {
      mainWindow?.show()
    })
  }
})

app.on('window-all-closed', () => {
  hotkeyService.unregister()
  speechService.destroy()
  if (process.platform !== 'darwin') {
    app.quit()
  }
})

app.on('before-quit', () => {
  closeAllWindows()
})

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createMainWindow()
  }
})

app.on('will-quit', () => {
  hotkeyService.unregister()
})

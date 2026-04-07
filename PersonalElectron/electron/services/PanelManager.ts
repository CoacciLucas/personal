import { BrowserWindow, screen } from 'electron'
import { join } from 'path'
import { is } from '@electron-toolkit/utils'

let toolbarWindow: BrowserWindow | null = null
let chatWindow: BrowserWindow | null = null
let onAllFloatingClosed: (() => void) | null = null

export function setOnAllFloatingClosed(callback: () => void): void {
  onAllFloatingClosed = callback
}

function checkAllFloatingClosed(): void {
  if (!toolbarWindow && !chatWindow && onAllFloatingClosed) {
    onAllFloatingClosed()
  }
}

export function createToolbarWindow(): BrowserWindow {
  if (toolbarWindow) return toolbarWindow

  const primaryDisplay = screen.getPrimaryDisplay()
  const { width: screenWidth, height: screenHeight } = primaryDisplay.workAreaSize

  toolbarWindow = new BrowserWindow({
    width: 52,
    height: 210,
    x: screenWidth - 70,
    y: 100,
    frame: false,
    transparent: true,
    resizable: false,
    alwaysOnTop: true,
    skipTaskbar: true,
    hasShadow: false,
    show: false,
    webPreferences: {
      preload: join(__dirname, '../preload/index.js'),
      sandbox: false
    }
  })

  toolbarWindow.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true })
  toolbarWindow.setContentProtection(true)

  if (is.dev && process.env['ELECTRON_RENDERER_URL']) {
    toolbarWindow.loadURL(process.env['ELECTRON_RENDERER_URL'] + '#toolbar')
  } else {
    toolbarWindow.loadFile(join(__dirname, '../renderer/index.html'), { hash: 'toolbar' })
  }

  toolbarWindow.once('ready-to-show', () => {
    toolbarWindow?.show()
  })

  toolbarWindow.on('closed', () => {
    toolbarWindow = null
    checkAllFloatingClosed()
  })

  return toolbarWindow
}

export function createChatWindow(): BrowserWindow {
  if (chatWindow) {
    chatWindow.show()
    return chatWindow
  }

  const primaryDisplay = screen.getPrimaryDisplay()
  const { width: screenWidth } = primaryDisplay.workAreaSize

  chatWindow = new BrowserWindow({
    width: 420,
    height: 550,
    x: screenWidth - 70 - 420 - 10,
    y: 80,
    title: 'GLM Chat',
    resizable: true,
    alwaysOnTop: true,
    skipTaskbar: true,
    show: false,
    webPreferences: {
      preload: join(__dirname, '../preload/index.js'),
      sandbox: false
    }
  })

  chatWindow.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true })
  chatWindow.setContentProtection(true)

  if (is.dev && process.env['ELECTRON_RENDERER_URL']) {
    chatWindow.loadURL(process.env['ELECTRON_RENDERER_URL'] + '#floating-chat')
  } else {
    chatWindow.loadFile(join(__dirname, '../renderer/index.html'), { hash: 'floating-chat' })
  }

  chatWindow.once('ready-to-show', () => {
    chatWindow?.show()
  })

  chatWindow.on('closed', () => {
    chatWindow = null
    checkAllFloatingClosed()
  })

  return chatWindow
}

export function toggleChatWindow(): void {
  if (chatWindow) {
    if (chatWindow.isVisible()) {
      chatWindow.hide()
    } else {
      chatWindow.show()
    }
  } else {
    createChatWindow()
  }
}

export function closeAllWindows(): void {
  toolbarWindow?.close()
  chatWindow?.close()
  toolbarWindow = null
  chatWindow = null
}

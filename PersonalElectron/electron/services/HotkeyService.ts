import { globalShortcut } from 'electron'

type ScreenshotCallback = () => void
type SpeechToggleCallback = () => void

export class HotkeyService {
  private onScreenshot: ScreenshotCallback | null = null
  private onSpeechToggle: SpeechToggleCallback | null = null

  setScreenshotCallback(cb: ScreenshotCallback): void {
    this.onScreenshot = cb
  }

  setSpeechToggleCallback(cb: SpeechToggleCallback): void {
    this.onSpeechToggle = cb
  }

  register(): boolean {
    const screenshotOk = globalShortcut.register('Ctrl+E', () => {
      this.onScreenshot?.()
    })

    const speechOk = globalShortcut.register('CmdOrCtrl+D', () => {
      this.onSpeechToggle?.()
    })

    return screenshotOk && speechOk
  }

  unregister(): void {
    globalShortcut.unregister('Ctrl+E')
    globalShortcut.unregister('CmdOrCtrl+D')
  }
}

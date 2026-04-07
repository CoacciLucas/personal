import type { SpeechProvider, TranscriptCallback } from './speech/SpeechProvider'
import { MacSpeechProvider } from './speech/MacSpeechProvider'
import { WindowsSpeechProvider } from './speech/WindowsSpeechProvider'
import type { Transcript } from '../../src/types'

export class SpeechService {
  private provider: SpeechProvider
  private isListening = false

  constructor() {
    this.provider = this.createProvider()
  }

  private createProvider(): SpeechProvider {
    switch (process.platform) {
      case 'darwin':
        return new MacSpeechProvider()
      case 'win32':
        return new WindowsSpeechProvider()
      default:
        throw new Error(`Plataforma não suportada para speech: ${process.platform}`)
    }
  }

  setApiKey(key: string): void {
    if (this.provider instanceof WindowsSpeechProvider) {
      this.provider.setApiKey(key)
    }
  }

  startListening(): void {
    if (this.isListening) return
    this.isListening = true
    this.provider.startMicrophone()
    this.provider.startSystemAudio()
  }

  stopListening(): void {
    if (!this.isListening) return
    this.isListening = false
    this.provider.stopMicrophone()
    this.provider.stopSystemAudio()
  }

  toggleListening(): boolean {
    if (this.isListening) {
      this.stopListening()
    } else {
      this.startListening()
    }
    return this.isListening
  }

  getIsListening(): boolean {
    return this.isListening
  }

  onTranscript(callback: TranscriptCallback): void {
    this.provider.onTranscript(callback)
  }

  destroy(): void {
    this.provider.destroy()
  }
}

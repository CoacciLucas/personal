import { spawn, ChildProcess } from 'child_process'
import { resolve, dirname } from 'path'
import { app } from 'electron'
import type { SpeechProvider, TranscriptCallback } from './SpeechProvider'

export class MacSpeechProvider implements SpeechProvider {
  private transcriptCallback: TranscriptCallback | null = null
  private micProcess: ChildProcess | null = null
  private systemAudioProcess: ChildProcess | null = null
  private micRestartCount = 0
  private systemRestartCount = 0
  private maxRestarts = 5

  onTranscript(callback: TranscriptCallback): void {
    this.transcriptCallback = callback
  }

  startMicrophone(): void {
    this.micRestartCount = 0
    this.startMicProcess()
  }

  private startMicProcess(): void {
    if (this.micProcess) return

    const bridgePath = this.getBridgePath('mic-speech-bridge')
    this.micProcess = spawn(bridgePath, ['mic'])

    this.micProcess.stdout?.on('data', (data: Buffer) => {
      const lines = data.toString().split('\n').filter(Boolean)
      for (const line of lines) {
        try {
          const result = JSON.parse(line)
          this.transcriptCallback?.({
            type: 'user',
            text: result.text,
            isFinal: result.isFinal ?? false
          })
        } catch { /* ignore malformed */ }
      }
    })

    this.micProcess.on('exit', () => {
      this.micProcess = null
      if (this.micRestartCount < this.maxRestarts) {
        this.micRestartCount++
        setTimeout(() => this.startMicProcess(), 1000 * this.micRestartCount)
      }
    })
  }

  startSystemAudio(): void {
    this.systemRestartCount = 0
    this.startSystemAudioProcess()
  }

  private startSystemAudioProcess(): void {
    if (this.systemAudioProcess) return

    const bridgePath = this.getBridgePath('system-audio-bridge')
    this.systemAudioProcess = spawn(bridgePath, ['system-audio'])

    this.systemAudioProcess.stdout?.on('data', (data: Buffer) => {
      const lines = data.toString().split('\n').filter(Boolean)
      for (const line of lines) {
        try {
          const result = JSON.parse(line)
          this.transcriptCallback?.({
            type: 'system',
            text: result.text,
            isFinal: result.isFinal ?? false
          })
        } catch { /* ignore malformed */ }
      }
    })

    this.systemAudioProcess.on('exit', () => {
      this.systemAudioProcess = null
      if (this.systemRestartCount < this.maxRestarts) {
        this.systemRestartCount++
        setTimeout(() => this.startSystemAudioProcess(), 1000 * this.systemRestartCount)
      }
    })
  }

  private getBridgePath(name: string): string {
    // In dev: resources/mac/, in production: resources/mac/ inside asar
    const resourcesPath = app.isPackaged
      ? process.resourcesPath
      : resolve(dirname(app.getAppPath()), 'resources', 'mac')
    return resolve(resourcesPath, name)
  }

  stopMicrophone(): void {
    this.micProcess?.kill()
    this.micProcess = null
  }

  stopSystemAudio(): void {
    this.systemAudioProcess?.kill()
    this.systemAudioProcess = null
  }

  destroy(): void {
    this.stopMicrophone()
    this.stopSystemAudio()
    this.transcriptCallback = null
  }
}

import type { SpeechProvider, TranscriptCallback } from './SpeechProvider'

const GLM_SPEECH_URL = 'https://api.z.ai/api/coding/paas/v4/audio/transcriptions'

export class WindowsSpeechProvider implements SpeechProvider {
  private transcriptCallback: TranscriptCallback | null = null
  private apiKey: string = ''
  private micStream: MediaStream | null = null
  private systemStream: MediaStream | null = null
  private isMicRecording = false
  private isSystemRecording = false

  setApiKey(key: string): void {
    this.apiKey = key
  }

  onTranscript(callback: TranscriptCallback): void {
    this.transcriptCallback = callback
  }

  startMicrophone(): void {
    if (this.isMicRecording) return
    this.isMicRecording = true
    this.captureAndTranscribe('user')
  }

  startSystemAudio(): void {
    if (this.isSystemRecording) return
    this.isSystemRecording = true
    this.captureAndTranscribe('system')
  }

  private async captureAndTranscribe(type: 'user' | 'system'): Promise<void> {
    const isRecording = type === 'user' ? () => this.isMicRecording : () => this.isSystemRecording

    while (isRecording()) {
      try {
        const audioBlob = await this.captureAudioChunk(type)
        if (!isRecording()) break

        const text = await this.sendToGlmApi(audioBlob)
        if (text && this.transcriptCallback) {
          this.transcriptCallback({ type, text, isFinal: true })
        }
      } catch {
        // Wait and retry
        await new Promise((r) => setTimeout(r, 1000))
      }
    }
  }

  private async captureAudioChunk(type: 'user' | 'system'): Promise<Blob> {
    // This runs in renderer context via IPC
    // The actual audio capture is handled by the renderer process
    // This method is a placeholder - actual capture happens in renderer
    throw new Error('Audio capture must be initiated from renderer process')
  }

  private async sendToGlmApi(audioBlob: Blob): Promise<string> {
    if (!this.apiKey) return ''

    const formData = new FormData()
    formData.append('file', audioBlob, 'audio.wav')
    formData.append('model', 'glm-4')

    const response = await fetch(GLM_SPEECH_URL, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.apiKey}`
      },
      body: formData
    })

    if (!response.ok) return ''

    const data = await response.json()
    return data?.text ?? ''
  }

  stopMicrophone(): void {
    this.isMicRecording = false
    if (this.micStream) {
      this.micStream.getTracks().forEach((t) => t.stop())
      this.micStream = null
    }
  }

  stopSystemAudio(): void {
    this.isSystemRecording = false
    if (this.systemStream) {
      this.systemStream.getTracks().forEach((t) => t.stop())
      this.systemStream = null
    }
  }

  destroy(): void {
    this.stopMicrophone()
    this.stopSystemAudio()
    this.transcriptCallback = null
  }
}

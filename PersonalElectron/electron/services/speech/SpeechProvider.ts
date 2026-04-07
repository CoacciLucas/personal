import type { Transcript } from '../../../src/types'

export type TranscriptCallback = (transcript: Transcript) => void

export interface SpeechProvider {
  startMicrophone(): void
  stopMicrophone(): void
  startSystemAudio(): void
  stopSystemAudio(): void
  onTranscript(callback: TranscriptCallback): void
  destroy(): void
}

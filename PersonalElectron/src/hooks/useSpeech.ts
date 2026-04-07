import { useEffect } from 'react'
import { useChatStore } from '../stores/chatStore'

const api = () => window.api

export function useSpeech() {
  const store = useChatStore()

  useEffect(() => {
    const unsubscribe = api().speech.onTranscript((transcript) => {
      if (transcript.type === 'user') {
        store.setUserTranscript(transcript.text)
      } else {
        store.setSystemTranscript(transcript.text)
      }
    })

    return unsubscribe
  }, [])

  async function toggleListening() {
    const isListening = await api().speech.toggle()
    store.setListening(isListening)
  }

  async function startListening() {
    const result = await api().speech.start()
    store.setListening(result)
  }

  async function stopListening() {
    const result = await api().speech.stop()
    store.setListening(result)
  }

  return {
    isListening: store.isListening,
    liveUserTranscript: store.liveUserTranscript,
    liveSystemTranscript: store.liveSystemTranscript,
    toggleListening,
    startListening,
    stopListening
  }
}

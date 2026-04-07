import { useEffect } from 'react'
import { useChatStore } from '../stores/chatStore'
import type { ChatMessage } from '../types'

const api = () => window.api

export function useScreenshot() {
  const store = useChatStore()

  useEffect(() => {
    const unsubscribe = api().screenshot.onCaptured(async (base64) => {
      if (store.isLoading) return

      const assistant = store.availableAssistants.find((a) => a.id === store.selectedAssistant)
      const lang = store.selectedLanguage === 'pt' ? 'Portuguese (Brazilian)' : 'English'
      const systemMessage: ChatMessage = {
        role: 'system',
        content: `${assistant?.prompt ?? 'You are a helpful assistant.'}\n\nYou must always respond in ${lang}.`
      }

      const userMessage: ChatMessage = {
        role: 'user',
        content: [
          { type: 'text', text: 'Look at this screenshot carefully. Pay attention to any code, problem descriptions, or content visible. If there is code, analyze THAT specific code — do not generate new code from scratch. Help based on what is actually shown on screen, following your role.' },
          { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${base64}` } }
        ]
      }

      const userItem = {
        id: crypto.randomUUID(),
        role: 'user' as const,
        content: 'Analise essa screenshot e me ajude com base nisso.',
        imageBase64: base64
      }

      store.addMessage(userItem, userMessage)
      store.setLoading(true)

      try {
        const currentState = useChatStore.getState()
        const history = [
          { ...systemMessage },
          ...currentState.conversationHistory
        ]
        const response = await api().chat.send(history, true, currentState.selectedModel)
        store.addAssistantMessage(response)
      } catch (err: any) {
        store.addAssistantMessage(`Erro: ${err.message}`)
      } finally {
        store.setLoading(false)
      }
    })

    return unsubscribe
  }, [store])

  async function capture() {
    await api().screenshot.capture()
  }

  return { capture }
}

export function usePanel() {
  function toggleChat() {
    api().panel.toggleChat()
  }

  function createToolbar() {
    api().panel.createToolbar()
  }

  function showApiKeyDialog() {
    api().panel.showApiKeyDialog()
  }

  return { toggleChat, createToolbar, showApiKeyDialog }
}

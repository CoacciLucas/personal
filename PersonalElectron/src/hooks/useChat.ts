import { useEffect } from 'react'
import { useChatStore } from '../stores/chatStore'
import type { ChatMessage } from '../types'

const api = () => window.api

export function useChat() {
  const store = useChatStore()

  useEffect(() => {
    const unsubscribe = api().chat.onProgress((stage) => {
      store.setLoadingStage(stage)
    })
    return unsubscribe
  }, [store])

  async function loadModels() {
    const models = await api().models.getAll()
    store.setAvailableModels(models)
  }

  async function loadAssistants() {
    const assistants = await api().assistants.getAll()
    store.setAvailableAssistants(assistants)
    const current = useChatStore.getState().selectedAssistant
    if (!assistants.find((a) => a.id === current) && assistants.length > 0) {
      store.selectAssistant(assistants[0].id)
    }
  }

  async function sendMessage(text: string) {
    if (!text.trim() || store.isLoading) return

    const assistant = store.availableAssistants.find((a) => a.id === store.selectedAssistant)
    const lang = store.selectedLanguage === 'pt' ? 'Portuguese (Brazilian)' : 'English'
    const systemMessage: ChatMessage = {
      role: 'system',
      content: `${assistant?.prompt ?? 'You are a helpful assistant.'}\n\nYou must always respond in ${lang}.`
    }

    const userMessage: ChatMessage = { role: 'user', content: text }
    const userItem = {
      id: crypto.randomUUID(),
      role: 'user' as const,
      content: text
    }

    store.addMessage(userItem, userMessage)
    store.setLoading(true)

    try {
      const history = [systemMessage, ...useChatStore.getState().conversationHistory]
      const hasImage = history.some(
        (m) => Array.isArray(m.content) && m.content.some((c: any) => c.type === 'image_url')
      )

      const response = await api().chat.send(history, hasImage, store.selectedModel)
      store.addAssistantMessage(response)
    } catch (err: any) {
      store.addAssistantMessage(`Erro: ${err.message}`)
    } finally {
      store.setLoading(false)
    }
  }

  async function sendScreenshot(base64: string) {
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
      const history = [systemMessage, ...useChatStore.getState().conversationHistory]
      const hasImage = true

      const response = await api().chat.send(history, hasImage, store.selectedModel)
      store.addAssistantMessage(response)
    } catch (err: any) {
      store.addAssistantMessage(`Erro: ${err.message}`)
    } finally {
      store.setLoading(false)
    }
  }

  function clearConversation() {
    store.clearConversation()
    api().chat.clear()
  }

  return {
    ...store,
    loadModels,
    loadAssistants,
    sendMessage,
    sendScreenshot,
    clearConversation
  }
}

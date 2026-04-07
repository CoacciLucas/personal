import { create } from 'zustand'
import type { ChatMessage, ChatMessageItem, GlmModel, Assistant, Transcript } from '../types'

interface ChatState {
  // Messages
  messages: ChatMessageItem[]
  conversationHistory: ChatMessage[]
  isLoading: boolean
  loadingStage: string

  // Models & Assistants
  selectedModel: string
  selectedAssistant: string
  selectedLanguage: string
  availableModels: GlmModel[]
  availableAssistants: Assistant[]

  // Speech
  isListening: boolean
  liveUserTranscript: string
  liveSystemTranscript: string

  // Navigation
  currentView: 'main' | 'settings' | 'chat' | 'floating-chat' | 'toolbar'

  // Dialog
  showApiKeyDialog: boolean

  // Actions
  addMessage: (message: ChatMessageItem, historyEntry: ChatMessage) => void
  addAssistantMessage: (content: string) => void
  setLoading: (loading: boolean) => void
  setLoadingStage: (stage: string) => void
  clearConversation: () => void
  selectModel: (modelId: string) => void
  selectAssistant: (assistantId: string) => void
  selectLanguage: (language: string) => void
  setAvailableModels: (models: GlmModel[]) => void
  setAvailableAssistants: (assistants: Assistant[]) => void
  setListening: (listening: boolean) => void
  setUserTranscript: (text: string) => void
  setSystemTranscript: (text: string) => void
  setView: (view: 'main' | 'settings' | 'chat' | 'floating-chat' | 'toolbar') => void
  setShowApiKeyDialog: (show: boolean) => void
}

export const useChatStore = create<ChatState>((set, get) => ({
  messages: [],
  conversationHistory: [],
  isLoading: false,
  loadingStage: '',
  selectedModel: 'glm-5',
  selectedAssistant: 'general-assistant',
  selectedLanguage: 'pt',
  availableModels: [],
  availableAssistants: [],
  isListening: false,
  liveUserTranscript: '',
  liveSystemTranscript: '',
  currentView: 'main',
  showApiKeyDialog: false,

  addMessage: (message, historyEntry) =>
    set((state) => ({
      messages: [...state.messages, message],
      conversationHistory: [...state.conversationHistory, historyEntry]
    })),

  addAssistantMessage: (content) =>
    set((state) => {
      const message: ChatMessageItem = {
        id: crypto.randomUUID(),
        role: 'assistant',
        content
      }
      const historyEntry: ChatMessage = { role: 'assistant', content }
      return {
        messages: [...state.messages, message],
        conversationHistory: [...state.conversationHistory, historyEntry]
      }
    }),

  setLoading: (isLoading) => set({ isLoading, loadingStage: '' }),
  setLoadingStage: (loadingStage) => set({ loadingStage }),
  clearConversation: () => set({ messages: [], conversationHistory: [] }),
  selectModel: (modelId) => set({ selectedModel: modelId }),
  selectAssistant: (assistantId) => set({ selectedAssistant: assistantId }),
  selectLanguage: (language) => set({ selectedLanguage: language }),
  setAvailableModels: (models) => set({ availableModels: models }),
  setAvailableAssistants: (assistants) => set({ availableAssistants: assistants }),
  setListening: (isListening) => set({ isListening }),
  setUserTranscript: (liveUserTranscript) => set({ liveUserTranscript }),
  setSystemTranscript: (liveSystemTranscript) => set({ liveSystemTranscript }),
  setView: (currentView) => set({ currentView }),
  setShowApiKeyDialog: (showApiKeyDialog) => set({ showApiKeyDialog })
}))

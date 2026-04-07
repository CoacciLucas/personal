export interface ChatMessage {
  role: 'system' | 'user' | 'assistant'
  content: string | MessageContent[]
}

export interface MessageContent {
  type: 'text' | 'image_url'
  text?: string
  image_url?: { url: string }
}

export interface ChatMessageItem {
  id: string
  role: 'user' | 'assistant'
  content: string
  imageBase64?: string
}

export interface GlmModel {
  id: string
  name: string
  supportsVision: boolean
}

export interface Assistant {
  id: string
  name: string
  prompt: string
}

export interface Transcript {
  type: 'user' | 'system'
  text: string
  isFinal: boolean
}

import { net } from 'electron'
import type { ChatMessage, GlmModel } from '../../src/types'

const API_URL = 'https://api.z.ai/api/coding/paas/v4/chat/completions'

export class GlmError extends Error {
  constructor(
    message: string,
    public type: 'no_api_key' | 'invalid_response' | 'api_error'
  ) {
    super(message)
    this.name = 'GlmError'
  }
}

export class GlmService {
  private apiKey: string = ''
  private model: string = 'glm-5'
  private availableModels: GlmModel[] = []
  onProgress: ((stage: string) => void) | null = null

  setApiKey(key: string): void {
    this.apiKey = key
  }

  setModel(model: string): void {
    this.model = model
  }

  setAvailableModels(models: GlmModel[]): void {
    this.availableModels = models
  }

  private getVisionModel(): string {
    // Prefer flash model for faster responses
    const flashModel = this.availableModels.find((m) => m.supportsVision && m.id.includes('flash'))
    if (flashModel) return flashModel.id
    const visionModel = this.availableModels.find((m) => m.supportsVision)
    return visionModel?.id ?? 'glm-4.6v'
  }

  private async callApi(model: string, messages: ChatMessage[]): Promise<string> {
    const response = await net.fetch(API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.apiKey}`
      },
      body: JSON.stringify({ model, messages, max_tokens: 4096 })
    })

    if (!response.ok) {
      const text = await response.text()
      throw new GlmError(`Erro da API: ${response.status} - ${text}`, 'api_error')
    }

    const data = await response.json()
    const content = data?.choices?.[0]?.message?.content

    if (!content) {
      throw new GlmError('Resposta inválida da API', 'invalid_response')
    }

    return content
  }

  async sendMessage(
    messages: ChatMessage[],
    hasImage: boolean = false,
    selectedModelId?: string
  ): Promise<string> {
    if (!this.apiKey) {
      throw new GlmError('API key não configurada', 'no_api_key')
    }

    const modelId = selectedModelId ?? this.model

    if (!hasImage) {
      return this.callApi(modelId, messages)
    }

    this.onProgress?.('Analyzing image...')
    return this.callApi(this.getVisionModel(), messages)
  }
}

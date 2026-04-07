import { readFileSync } from 'fs'
import { resolve } from 'path'
import { app } from 'electron'
import type { GlmModel } from '../../src/types'

export class ModelService {
  getModels(): GlmModel[] {
    const modelsPath = resolve(app.getAppPath(), '..', 'Models.md')

    try {
      const content = readFileSync(modelsPath, 'utf-8')
      return content
        .split('\n')
        .filter((line) => line.trim().startsWith('-'))
        .map((line) => {
          const stripped = line.replace(/^-\s*/, '')
          const parts = stripped.split('|').map((p) => p.trim())
          return {
            id: parts[0] ?? '',
            name: parts[1] ?? parts[0] ?? '',
            supportsVision: parts.length > 2 && parts[2]?.toLowerCase() === 'vision'
          }
        })
        .filter((m) => m.id)
    } catch {
      return [
        { id: 'glm-5', name: 'GLM-5', supportsVision: false },
        { id: 'glm-4-plus', name: 'GLM-4 Plus', supportsVision: false },
        { id: 'glm-4-flash', name: 'GLM-4 Flash', supportsVision: false },
        { id: 'glm-4.6v-flash', name: 'GLM-4.6V Flash', supportsVision: true },
        { id: 'glm-4v', name: 'GLM-4V', supportsVision: true }
      ]
    }
  }
}

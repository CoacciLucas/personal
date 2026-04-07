import { readFileSync, readdirSync, existsSync, mkdirSync, writeFileSync } from 'fs'
import { resolve, basename } from 'path'
import { app } from 'electron'
import type { Assistant } from '../../src/types'

export class AssistantService {
  private assistantsDir: string
  private sourceDir: string

  constructor() {
    this.assistantsDir = resolve(app.getPath('userData'), 'Assistants')
    // In dev: Assistants is at repo root (../Assistants from PersonalElectron)
    // In prod: Assistants bundled in resources
    this.sourceDir = resolve(app.getAppPath(), '..', 'Assistants')
  }

  getAssistants(): Assistant[] {
    this.ensureDirectory()
    this.seedDefaultsIfNeeded()

    try {
      const files = readdirSync(this.assistantsDir).filter((f) => f.endsWith('.md'))

      if (files.length === 0) {
        return [this.defaultAssistant()]
      }

      return files.map((file) => {
        const content = readFileSync(resolve(this.assistantsDir, file), 'utf-8')
        const name = basename(file, '.md')
          .split('-')
          .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
          .join(' ')

        return {
          id: basename(file, '.md'),
          name,
          prompt: content.trim()
        }
      })
    } catch {
      return [this.defaultAssistant()]
    }
  }

  private defaultAssistant(): Assistant {
    return {
      id: 'general',
      name: 'General',
      prompt: 'You are a helpful assistant.'
    }
  }

  private ensureDirectory() {
    if (!existsSync(this.assistantsDir)) {
      mkdirSync(this.assistantsDir, { recursive: true })
    }
  }

  private seedDefaultsIfNeeded() {
    const existingFiles = readdirSync(this.assistantsDir).filter((f) => f.endsWith('.md'))
    if (existingFiles.length > 0) return

    // Try to copy from source Assistants folder
    if (!existsSync(this.sourceDir)) return

    try {
      const sourceFiles = readdirSync(this.sourceDir).filter((f) => f.endsWith('.md'))
      for (const file of sourceFiles) {
        const content = readFileSync(resolve(this.sourceDir, file), 'utf-8')
        writeFileSync(resolve(this.assistantsDir, file), content)
      }
    } catch {
      // If seeding fails, fallback to default
    }
  }
}

import React from 'react'
import type { GlmModel } from '../types'

interface Props {
  models: GlmModel[]
  selected: string
  onChange: (id: string) => void
  label?: string
  bgColor?: string
}

export function ModelSelector({ models, selected, onChange, label = 'Modelo', bgColor = 'bg-purple-600' }: Props) {
  return (
    <select
      value={selected}
      onChange={(e) => onChange(e.target.value)}
      className={`${bgColor} text-white text-xs px-2 py-1 rounded-lg border-none outline-none cursor-pointer`}
    >
      {models.map((model) => (
        <option key={model.id} value={model.id}>
          {model.name} {model.supportsVision ? '👁' : ''}
        </option>
      ))}
    </select>
  )
}

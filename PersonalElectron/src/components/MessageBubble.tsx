import React, { useState } from 'react'
import type { ChatMessageItem } from '../types'
import { MarkdownContent } from './MarkdownContent'

interface Props {
  message: ChatMessageItem
}

export function MessageBubble({ message }: Props) {
  const isUser = message.role === 'user'
  const [copied, setCopied] = useState(false)

  function handleCopy() {
    navigator.clipboard.writeText(message.content)
    setCopied(true)
    setTimeout(() => setCopied(false), 1500)
  }

  return (
    <div className={`group flex ${isUser ? 'justify-end' : 'justify-start'} mb-3`}>
      <div
        className={`relative max-w-[80%] px-4 py-2 rounded-2xl text-sm ${
          isUser ? 'bg-purple-600 text-white' : 'bg-gray-100 text-gray-900'
        }`}
      >
        <button
          onClick={handleCopy}
          className="absolute top-1 right-1 opacity-0 group-hover:opacity-100 transition-opacity text-xs px-1.5 py-0.5 rounded bg-black/20 hover:bg-black/30"
          title="Copiar"
        >
          {copied ? '✓' : '⧉'}
        </button>
        {message.imageBase64 && (
          <img
            src={`data:image/jpeg;base64,${message.imageBase64}`}
            alt="Screenshot"
            className="max-w-[300px] max-h-[200px] rounded-lg mb-2"
          />
        )}
        {isUser ? (
          <p>{message.content}</p>
        ) : (
          <MarkdownContent content={message.content} />
        )}
      </div>
    </div>
  )
}

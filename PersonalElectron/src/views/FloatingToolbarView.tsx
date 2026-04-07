import React, { useEffect } from 'react'
import { useSpeech } from '../hooks/useSpeech'
import { useScreenshot, usePanel } from '../hooks/useHotkeys'
import { useChatStore } from '../stores/chatStore'

export function FloatingToolbarView() {
  const speech = useSpeech()
  const { capture } = useScreenshot()
  const { toggleChat } = usePanel()
  const isListening = useChatStore((s) => s.isListening)

  return (
    <div className="flex flex-col items-center gap-3 py-3 bg-white/80 backdrop-blur-sm rounded-xl shadow-lg border border-gray-200">
      {/* Camera - Screenshot */}
      <button
        onClick={capture}
        className="w-9 h-9 flex items-center justify-center rounded-lg bg-purple-600 hover:bg-purple-700 text-white transition-colors"
        title="Capturar tela (Ctrl+E)"
      >
        📷
      </button>

      {/* Chat - Toggle panel */}
      <button
        onClick={toggleChat}
        className="w-9 h-9 flex items-center justify-center rounded-lg bg-purple-600 hover:bg-purple-700 text-white transition-colors"
        title="Chat"
      >
        💬
      </button>

      {/* Mic - Speech toggle */}
      <button
        onClick={speech.toggleListening}
        className={`w-9 h-9 flex items-center justify-center rounded-lg transition-colors ${
          isListening
            ? 'bg-red-500 hover:bg-red-600 animate-pulse'
            : 'bg-purple-600 hover:bg-purple-700'
        } text-white`}
        title="Reconhecimento de voz (Ctrl+D)"
      >
        🎤
      </button>

      {/* Key - API key */}
      <button
        onClick={() => window.api.main.showSettings()}
        className="w-9 h-9 flex items-center justify-center rounded-lg bg-gray-400 hover:bg-gray-500 text-white transition-colors"
        title="Alterar API Key"
      >
        🔑
      </button>
    </div>
  )
}

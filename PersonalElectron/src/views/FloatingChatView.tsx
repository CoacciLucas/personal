import React, { useState, useRef, useEffect } from 'react'
import { useChat } from '../hooks/useChat'
import { useSpeech } from '../hooks/useSpeech'
import { useScreenshot } from '../hooks/useHotkeys'
import { MessageBubble } from '../components/MessageBubble'
import { ModelSelector } from '../components/ModelSelector'
import { TranscriptBar } from '../components/TranscriptBar'

export function FloatingChatView() {
  const chat = useChat()
  const speech = useSpeech()
  const { capture } = useScreenshot()
  const [input, setInput] = useState('')
  const messagesEndRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    chat.loadModels()
    chat.loadAssistants()
  }, [])

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [chat.messages])

  function handleSend() {
    if (!input.trim()) return
    chat.sendMessage(input)
    setInput('')
  }

  function handleKeyDown(e: React.KeyboardEvent) {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSend()
    }
  }

  return (
    <div className="flex flex-col h-screen bg-white">
      {/* Header */}
      <div className="flex items-center gap-2 px-3 py-2 border-b border-gray-200">
        <select
          value={chat.selectedAssistant}
          onChange={(e) => chat.selectAssistant(e.target.value)}
          className="bg-purple-600 text-white text-xs px-2 py-1 rounded-lg border-none outline-none cursor-pointer"
        >
          {chat.availableAssistants.map((a) => (
            <option key={a.id} value={a.id}>{a.name}</option>
          ))}
        </select>

        <select
          value={chat.selectedLanguage}
          onChange={(e) => chat.selectLanguage(e.target.value)}
          className="bg-green-600 text-white text-xs px-2 py-1 rounded-lg border-none outline-none cursor-pointer"
        >
          <option value="pt">PT</option>
          <option value="en">EN</option>
        </select>

        <ModelSelector
          models={chat.availableModels}
          selected={chat.selectedModel}
          onChange={chat.selectModel}
          bgColor="bg-blue-600"
        />

        <button
          onClick={() => chat.clearConversation()}
          className="ml-auto text-gray-400 hover:text-red-500 text-sm"
          title="Limpar conversa"
        >
          🗑
        </button>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto px-3 py-2">
        {chat.messages.map((msg) => (
          <div key={msg.id} className="max-w-[350px]">
            <MessageBubble message={msg} />
          </div>
        ))}
        {chat.isLoading && (
          <div className="flex justify-start mb-3">
            <div className="bg-gray-100 px-3 py-2 rounded-2xl text-sm text-gray-500">
              {chat.loadingStage || 'Pensando...'}
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Transcript */}
      <TranscriptBar
        userTranscript={chat.liveUserTranscript}
        systemTranscript={chat.liveSystemTranscript}
        isListening={chat.isListening}
      />

      {/* Input / Recording */}
      {chat.isListening ? (
        <div className="flex items-center gap-2 px-3 py-3 border-t border-gray-200 bg-red-50">
          <div className="w-3 h-3 bg-red-500 rounded-full animate-pulse" />
          <span className="text-sm text-red-700 flex-1">Gravando...</span>
          <button
            onClick={speech.toggleListening}
            className="px-3 py-1 bg-red-500 hover:bg-red-600 text-white text-xs rounded-lg"
          >
            Parar
          </button>
        </div>
      ) : (
        <div className="flex gap-2 px-3 py-3 border-t border-gray-200">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Digite sua mensagem..."
            className="flex-1 px-3 py-2 border border-gray-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-purple-500"
            disabled={chat.isLoading}
          />
          <button
            onClick={handleSend}
            disabled={chat.isLoading || !input.trim()}
            className="px-3 py-2 bg-purple-600 hover:bg-purple-700 disabled:bg-gray-300 text-white rounded-xl transition-colors text-sm"
          >
            Enviar
          </button>
        </div>
      )}
    </div>
  )
}

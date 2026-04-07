import React from 'react'

interface Props {
  userTranscript: string
  systemTranscript: string
  isListening: boolean
}

export function TranscriptBar({ userTranscript, systemTranscript, isListening }: Props) {
  if (!isListening && !userTranscript && !systemTranscript) return null

  return (
    <div className="mx-3 mb-2 p-2 rounded-lg bg-gray-50 border border-gray-200 space-y-1">
      <div className="flex items-center gap-2">
        <div className={`w-2 h-2 rounded-full ${isListening ? 'bg-red-500 animate-pulse' : 'bg-gray-400'}`} />
        <span className="text-xs font-medium text-gray-600">Gravando</span>
      </div>

      {userTranscript && (
        <p className="text-xs text-blue-700 bg-blue-50 rounded px-2 py-1">
          <span className="font-medium">Você:</span> {userTranscript}
        </p>
      )}

      {systemTranscript && (
        <p className="text-xs text-red-700 bg-red-50 rounded px-2 py-1">
          <span className="font-medium">Sistema:</span> {systemTranscript}
        </p>
      )}
    </div>
  )
}

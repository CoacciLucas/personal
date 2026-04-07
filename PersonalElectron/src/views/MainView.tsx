import React from 'react'

export function MainView() {
  function handleStart() {
    window.location.hash = 'settings'
  }

  return (
    <div className="flex flex-col items-center justify-center h-screen gap-4 bg-white">
      <h1 className="text-3xl font-bold text-purple-600">GLM Chat</h1>
      <p className="text-base text-gray-500">Chat com a API GLM da Zhipu AI</p>
      <button
        onClick={handleStart}
        className="mt-4 px-8 py-3 bg-purple-600 hover:bg-purple-700 text-white text-lg font-medium rounded-xl transition-colors"
      >
        Iniciar Chat
      </button>
    </div>
  )
}

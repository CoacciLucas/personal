import React, { useState, useEffect } from 'react'

export function SettingsView() {
  const [apiKey, setApiKey] = useState('')
  const [status, setStatus] = useState('')

  useEffect(() => {
    window.api.settings.getApiKey().then(setApiKey)
  }, [])

  async function handleSave() {
    if (!apiKey.trim()) return
    await window.api.settings.saveApiKey(apiKey)
    setStatus('Salvo! Iniciando toolbar...')

    // Create floating toolbar and hide main window
    window.api.panel.createToolbar()
    setTimeout(() => {
      window.api.main.hide()
    }, 500)
  }

  return (
    <div className="flex flex-col items-center justify-center h-screen gap-6 bg-white px-8">
      <h2 className="text-2xl font-bold text-purple-600">Configurar API Key</h2>

      <input
        type="password"
        value={apiKey}
        onChange={(e) => setApiKey(e.target.value)}
        placeholder="Sua API Key da Zhipu AI"
        className="w-full max-w-sm px-4 py-3 border border-gray-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-purple-500"
      />

      {status && <p className="text-sm text-green-600">{status}</p>}

      <button
        onClick={handleSave}
        className="px-6 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-xl transition-colors"
      >
        Salvar e Iniciar
      </button>
    </div>
  )
}

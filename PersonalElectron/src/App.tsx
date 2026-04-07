import React, { useEffect, useState } from 'react'
import { useChatStore } from './stores/chatStore'
import { MainView } from './views/MainView'
import { SettingsView } from './views/SettingsView'
import { ChatView } from './views/ChatView'
import { FloatingChatView } from './views/FloatingChatView'
import { FloatingToolbarView } from './views/FloatingToolbarView'

function getRouteFromHash(): string {
  const hash = window.location.hash.replace('#', '')
  return hash || 'main'
}

export function App() {
  const [route, setRoute] = useState(getRouteFromHash)

  useEffect(() => {
    function handleHashChange() {
      setRoute(getRouteFromHash())
    }
    window.addEventListener('hashchange', handleHashChange)
    return () => window.removeEventListener('hashchange', handleHashChange)
  }, [])

  // Toolbar route - compact view
  if (route === 'toolbar') {
    return <FloatingToolbarView />
  }

  // Floating chat route
  if (route === 'floating-chat') {
    return <FloatingChatView />
  }

  // Main window routes
  switch (route) {
    case 'settings':
      return <SettingsView />
    case 'chat':
      return <ChatView />
    default:
      return <MainView />
  }
}

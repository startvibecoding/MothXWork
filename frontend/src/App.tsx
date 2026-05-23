import { useState, useEffect, useRef } from 'react'
import { 
  CreateSession, 
  SendMessage, 
  Abort,
  GetConfig,
  OpenDirectoryDialog,
  SaveSessionConfig,
  LoadSessionConfig
} from '../wailsjs/go/main/App'
import { EventsOn } from '../wailsjs/runtime/runtime'
import ChatArea from './components/ChatArea'
import InputArea from './components/InputArea'
import Sidebar from './components/Sidebar'
import StatusBar from './components/StatusBar'
import GlobalSettings from './components/GlobalSettings'
import SessionSettings from './components/SessionSettings'
import PermissionDialog from './components/PermissionDialog'

interface Message {
  id: string
  role: 'user' | 'assistant' | 'system'
  content: string
  timestamp: Date
  isStreaming?: boolean
}

interface Session {
  id: string
  name: string
  cwd: string
  isActive: boolean
}

interface Config {
  cwd: string
  provider: string
  model: string
  mode: string
  thinking: string
}

interface PermissionRequest {
  requestId: string
  sessionId: string
  toolCallId: string
  title: string
  kind: string
  input: any
  options: Array<{
    optionId: string
    name: string
    kind: string
  }>
}

function App() {
  const [messages, setMessages] = useState<Message[]>([])
  const [inputValue, setInputValue] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [currentSession, setCurrentSession] = useState<string | null>(null)
  const [sessions, setSessions] = useState<Session[]>([])
  const [isConnected, setIsConnected] = useState(false)
  const [isGlobalSettingsOpen, setIsGlobalSettingsOpen] = useState(false)
  const [permissionRequest, setPermissionRequest] = useState<PermissionRequest | null>(null)
  const [config, setConfig] = useState<Config>({
    cwd: '',
    provider: 'deepseek-openai',
    model: 'deepseek-v4-flash',
    mode: 'agent',
    thinking: 'medium'
  })
  const streamingMessageRef = useRef<string>('')
  const streamingMessageIdRef = useRef<string | null>(null)

  useEffect(() => {
    // Set up event listener before initializing session
    const unsubscribe = setupEventListeners()
    loadConfig()
    loadSessions()
    
    // Cleanup on unmount
    return () => {
      unsubscribe()
    }
  }, [])

  const setupEventListeners = () => {
    // Listen for chat events
    const unsubscribeChat = EventsOn('chat:event', (event: any) => {
      console.log('Received chat event:', event)
      handleChatEvent(event)
    })
    
    // Listen for config updates
    const unsubscribeConfig = EventsOn('config:updated', (newConfig: any) => {
      console.log('Config updated:', newConfig)
      setConfig(newConfig)
      // Reset sessions when config changes
      setSessions([])
      setCurrentSession(null)
      setMessages([])
    })
    
    return () => {
      unsubscribeChat()
      unsubscribeConfig()
    }
  }

  const loadConfig = async () => {
    try {
      const cfg = await GetConfig()
      setConfig(cfg as Config)
    } catch (err) {
      console.error('Failed to load config:', err)
    }
  }

  const loadSessions = async () => {
    try {
      const savedSessions = await LoadSessionConfig()
      if (savedSessions && Array.isArray(savedSessions) && savedSessions.length > 0) {
        setSessions(savedSessions as unknown as Session[])
        // Select the first session
        setCurrentSession(savedSessions[0].id)
        setIsConnected(true)
      }
    } catch (err) {
      console.error('Failed to load sessions:', err)
    }
  }

  const saveSessions = async (newSessions: Session[]) => {
    setSessions(newSessions)
    try {
      await SaveSessionConfig(newSessions as any)
    } catch (err) {
      console.error('Failed to save sessions:', err)
    }
  }

  const handleChatEvent = (event: any) => {
    console.log('Handling chat event:', event.type, event)
    
    switch (event.type) {
      case 'content':
        appendToStreamingMessage(event.content)
        break

      case 'tool_call':
        // Handle tool call event
        const toolTitle = event.data?.title || 'Calling tool...'
        appendToStreamingMessage(`\n🔧 **${toolTitle}**\n`)
        break

      case 'toolCallUpdate':
        if (event.data?.status === 'completed' && event.content) {
          appendToStreamingMessage(`\n✅ **Result:**\n\`\`\`\n${event.content}\n\`\`\`\n`)
        }
        break

      case 'permission_request':
        // Handle permission request
        setPermissionRequest(event.data)
        break

      case 'status':
        // Handle status updates
        break

      case 'done':
        finishStreamingMessage()
        setIsLoading(false)
        break

      case 'error':
        appendToStreamingMessage(`\n❌ **Error:** ${event.error}`)
        finishStreamingMessage()
        setIsLoading(false)
        break

      default:
        console.log('Unknown event type:', event.type)
    }
  }

  const appendToStreamingMessage = (content: string) => {
    if (!streamingMessageIdRef.current) {
      // Create new streaming message
      const id = `streaming-${Date.now()}`
      streamingMessageIdRef.current = id
      streamingMessageRef.current = content
      setMessages(prev => [...prev, {
        id,
        role: 'assistant',
        content,
        timestamp: new Date(),
        isStreaming: true
      }])
    } else {
      // Append to existing streaming message
      streamingMessageRef.current += content
      setMessages(prev => prev.map(msg => 
        msg.id === streamingMessageIdRef.current
          ? { ...msg, content: streamingMessageRef.current }
          : msg
      ))
    }
  }

  const finishStreamingMessage = () => {
    if (streamingMessageIdRef.current) {
      setMessages(prev => prev.map(msg => 
        msg.id === streamingMessageIdRef.current
          ? { ...msg, isStreaming: false }
          : msg
      ))
      streamingMessageIdRef.current = null
      streamingMessageRef.current = ''
    }
  }

  const handleSend = async () => {
    if (!inputValue.trim() || isLoading || !currentSession) return

    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: inputValue,
      timestamp: new Date()
    }

    setMessages(prev => [...prev, userMessage])
    setInputValue('')
    setIsLoading(true)

    try {
      await SendMessage(currentSession, inputValue)
    } catch (err) {
      console.error('Failed to send message:', err)
      const errorMessage: Message = {
        id: (Date.now() + 1).toString(),
        role: 'system',
        content: `Error: ${err}`,
        timestamp: new Date()
      }
      setMessages(prev => [...prev, errorMessage])
      setIsLoading(false)
    }
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSend()
    }
  }

  const handleAbort = async () => {
    if (currentSession) {
      await Abort(currentSession)
    }
    setIsLoading(false)
    finishStreamingMessage()
  }

  const handleNewSession = async () => {
    try {
      // Open directory dialog to select working directory
      const cwd = await OpenDirectoryDialog()
      if (!cwd) return // User cancelled
      
      const sessionId = await CreateSession()
      const newSession: Session = {
        id: sessionId,
        name: `Session ${sessions.length + 1}`,
        cwd: cwd,
        isActive: true
      }
      
      const newSessions = [...sessions, newSession]
      await saveSessions(newSessions)
      
      setCurrentSession(sessionId)
      setMessages([])
      setConfig(prev => ({ ...prev, cwd }))
      setIsConnected(true)
    } catch (err) {
      console.error('Failed to create session:', err)
    }
  }

  const handleSelectSession = (sessionId: string) => {
    setCurrentSession(sessionId)
    setMessages([])
    const session = sessions.find(s => s.id === sessionId)
    if (session) {
      setConfig(prev => ({ ...prev, cwd: session.cwd }))
    }
  }

  const handleRenameSession = async (sessionId: string, newName: string) => {
    const newSessions = sessions.map(s => 
      s.id === sessionId ? { ...s, name: newName } : s
    )
    await saveSessions(newSessions)
  }

  const handleConfigChange = (newConfig: Config) => {
    setConfig(newConfig)
  }

  return (
    <div className="flex h-screen">
      {/* Sidebar */}
      <Sidebar
        sessions={sessions}
        currentSession={currentSession}
        onNewSession={handleNewSession}
        onSelectSession={handleSelectSession}
        onRenameSession={handleRenameSession}
        onOpenSettings={() => setIsGlobalSettingsOpen(true)}
      />

      {/* Main Content */}
      <div className="flex flex-col flex-1">
        {/* Header */}
        <div className="bg-[#1C1C1E] text-white px-6 py-3 border-b border-[#38383A]">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-lg font-semibold text-white">VibeCoding GUI</h1>
            </div>
            <SessionSettings 
              config={config} 
              onConfigChange={handleConfigChange}
            />
          </div>
        </div>

        {/* Chat Area */}
        <ChatArea messages={messages} isLoading={isLoading} />

        {/* Input Area */}
        <InputArea
          value={inputValue}
          onChange={setInputValue}
          onSend={handleSend}
          onKeyDown={handleKeyDown}
          onAbort={handleAbort}
          isLoading={isLoading}
          cwd={config.cwd}
        />

        {/* Status Bar */}
        <StatusBar
          isConnected={isConnected}
          currentSession={currentSession}
          messageCount={messages.length}
        />
      </div>

      {/* Global Settings Modal */}
      <GlobalSettings
        isOpen={isGlobalSettingsOpen}
        onClose={() => setIsGlobalSettingsOpen(false)}
      />
      
      {/* Permission Dialog */}
      <PermissionDialog
        request={permissionRequest}
        onClose={() => setPermissionRequest(null)}
      />
    </div>
  )
}

export default App

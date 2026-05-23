import { useState, useRef, useEffect } from 'react'

interface Session {
  id: string
  name: string
  cwd: string
  isActive: boolean
}

interface SidebarProps {
  sessions: Session[]
  currentSession: string | null
  onNewSession: () => void
  onSelectSession: (sessionId: string) => void
  onDeleteSession: (sessionId: string) => void
  onOpenSettings: () => void
}

export default function Sidebar({ 
  sessions, 
  currentSession, 
  onNewSession, 
  onSelectSession,
  onDeleteSession,
  onOpenSettings
}: SidebarProps) {
  const [contextMenu, setContextMenu] = useState<{ x: number; y: number; sessionId: string } | null>(null)
  const menuRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        setContextMenu(null)
      }
    }
    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  const handleContextMenu = (e: React.MouseEvent, sessionId: string) => {
    e.preventDefault()
    setContextMenu({ x: e.clientX, y: e.clientY, sessionId })
  }

  const handleDelete = (sessionId: string) => {
    onDeleteSession(sessionId)
    setContextMenu(null)
  }

  // Sort sessions: latest first (newest at top)
  const sortedSessions = [...sessions].reverse()

  return (
    <div className="w-64 bg-primary text-text-primary flex flex-col border-r border-separator">
      {/* Logo */}
      <div className="p-4 border-b border-separator">
        <div className="flex items-center space-x-3">
          <img src="/icon.svg" alt="VibeCoding" className="w-8 h-8" />
          <div>
            <h1 className="text-xl font-semibold text-text-primary">VibeCoding</h1>
            <p className="text-xs text-text-secondary mt-1">AI Coding Assistant</p>
          </div>
        </div>
      </div>

      {/* New Session Button */}
      <div className="p-3 border-b border-separator">
        <button 
          className="w-full flex items-center justify-center px-4 py-2.5 bg-accent hover:bg-accent/90 rounded-lg transition-colors font-medium text-white"
          onClick={onNewSession}
        >
          <span className="mr-2">+</span>
          <span>New Session</span>
        </button>
      </div>

      {/* Sessions List */}
      <div className="flex-1 p-3 overflow-y-auto">
        <h3 className="text-xs font-medium text-text-secondary mb-2 uppercase tracking-wider px-2">Sessions</h3>
        <div className="space-y-1">
          {sortedSessions.length === 0 ? (
            <p className="text-text-tertiary text-sm px-2">No sessions yet</p>
          ) : (
            sortedSessions.map(session => (
              <div
                key={session.id}
                className={`group relative flex flex-col items-start px-3 py-2 rounded-lg transition-colors cursor-pointer ${
                  currentSession === session.id
                    ? 'bg-accent text-white'
                    : 'hover:bg-secondary text-text-secondary'
                }`}
                onClick={() => onSelectSession(session.id)}
                onContextMenu={(e) => handleContextMenu(e, session.id)}
              >
                {/* First line: Session ID */}
                <div className={`text-xs font-mono truncate w-full ${
                  currentSession === session.id ? 'text-white/70' : 'text-text-tertiary'
                }`}>
                  {session.id.length > 20 ? session.id.slice(0, 20) + '...' : session.id}
                </div>
                {/* Second line: Session Name */}
                <div className="font-medium text-sm truncate w-full mt-0.5">
                  {session.name}
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Settings */}
      <div className="p-3 border-t border-separator">
        <button 
          className="w-full flex items-center px-3 py-2 rounded-lg hover:bg-secondary text-text-secondary transition-colors"
          onClick={onOpenSettings}
        >
          <span className="mr-2">⚙️</span>
          <span className="text-sm">全局设置</span>
        </button>
      </div>

      {/* Context Menu */}
      {contextMenu && (
        <div 
          ref={menuRef}
          className="fixed bg-secondary border border-elevated rounded-lg shadow-xl py-1 z-50 min-w-[140px]"
          style={{ left: contextMenu.x, top: contextMenu.y }}
        >
          <button
            className="w-full px-4 py-2 text-left text-sm text-accent-red hover:bg-tertiary transition-colors"
            onClick={() => handleDelete(contextMenu.sessionId)}
          >
            删除 Session
          </button>
        </div>
      )}
    </div>
  )
}

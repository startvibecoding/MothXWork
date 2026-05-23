import { useState, useEffect, useRef } from 'react'

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
  onRenameSession: (sessionId: string, newName: string) => void
  onOpenSettings: () => void
}

export default function Sidebar({ 
  sessions, 
  currentSession, 
  onNewSession, 
  onSelectSession,
  onRenameSession,
  onOpenSettings
}: SidebarProps) {
  const [editingId, setEditingId] = useState<string | null>(null)
  const [editName, setEditName] = useState('')
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (editingId && inputRef.current) {
      inputRef.current.focus()
      inputRef.current.select()
    }
  }, [editingId])

  const handleDoubleClick = (session: Session) => {
    setEditingId(session.id)
    setEditName(session.name)
  }

  const handleSave = (sessionId: string) => {
    if (editName.trim()) {
      onRenameSession(sessionId, editName.trim())
    }
    setEditingId(null)
  }

  const handleKeyDown = (e: React.KeyboardEvent, sessionId: string) => {
    if (e.key === 'Enter') {
      handleSave(sessionId)
    } else if (e.key === 'Escape') {
      setEditingId(null)
    }
  }

  return (
    <div className="w-64 bg-[#1C1C1E] text-white flex flex-col border-r border-[#38383A]">
      {/* Logo */}
      <div className="p-4 border-b border-[#38383A]">
        <div className="flex items-center space-x-3">
          <img src="/icon.svg" alt="VibeCoding" className="w-8 h-8" />
          <div>
            <h1 className="text-xl font-semibold text-white">VibeCoding</h1>
            <p className="text-xs text-[#8E8E93] mt-1">AI Coding Assistant</p>
          </div>
        </div>
      </div>

      {/* New Session Button */}
      <div className="p-3 border-b border-[#38383A]">
        <button 
          className="w-full flex items-center justify-center px-4 py-2.5 bg-[#007AFF] hover:bg-[#0071E3] rounded-lg transition-colors font-medium"
          onClick={onNewSession}
        >
          <span className="mr-2">+</span>
          <span>New Session</span>
        </button>
      </div>

      {/* Sessions List */}
      <div className="flex-1 p-3 overflow-y-auto">
        <h3 className="text-xs font-medium text-[#8E8E93] mb-2 uppercase tracking-wider px-2">Sessions</h3>
        <div className="space-y-1">
          {sessions.length === 0 ? (
            <p className="text-[#636366] text-sm px-2">No sessions yet</p>
          ) : (
            sessions.map(session => (
              <div
                key={session.id}
                className={`group relative flex flex-col items-start px-3 py-2 rounded-lg transition-colors cursor-pointer ${
                  currentSession === session.id
                    ? 'bg-[#007AFF] text-white'
                    : 'hover:bg-[#2C2C2E] text-[#8E8E93]'
                }`}
                onClick={() => onSelectSession(session.id)}
                onDoubleClick={() => handleDoubleClick(session)}
              >
                {editingId === session.id ? (
                  <input
                    ref={inputRef}
                    type="text"
                    className="w-full bg-transparent text-white border-b border-white/50 outline-none text-sm font-medium"
                    value={editName}
                    onChange={e => setEditName(e.target.value)}
                    onBlur={() => handleSave(session.id)}
                    onKeyDown={e => handleKeyDown(e, session.id)}
                    onClick={e => e.stopPropagation()}
                  />
                ) : (
                  <div className="font-medium text-sm truncate w-full">{session.name}</div>
                )}
                {session.cwd && (
                  <div className={`text-xs truncate w-full mt-1 ${
                    currentSession === session.id ? 'text-white/70' : 'text-[#636366]'
                  }`}>
                    {session.cwd.split('/').pop() || '/'}
                  </div>
                )}
                {/* Rename hint */}
                <div className={`absolute right-2 top-2 text-xs opacity-0 group-hover:opacity-100 transition-opacity ${
                  currentSession === session.id ? 'text-white/50' : 'text-[#636366]'
                }`}>
                  ✏️
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Settings */}
      <div className="p-3 border-t border-[#38383A]">
        <button 
          className="w-full flex items-center px-3 py-2 rounded-lg hover:bg-[#2C2C2E] text-[#8E8E93] transition-colors"
          onClick={onOpenSettings}
        >
          <span className="mr-2">⚙️</span>
          <span className="text-sm">全局设置</span>
        </button>
      </div>
    </div>
  )
}

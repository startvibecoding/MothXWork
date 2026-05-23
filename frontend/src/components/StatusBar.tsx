interface StatusBarProps {
  isConnected: boolean
  currentSession: string | null
  messageCount: number
}

export default function StatusBar({ isConnected, currentSession, messageCount }: StatusBarProps) {
  return (
    <div className="px-4 py-2 bg-primary border-t border-separator flex items-center justify-between text-sm">
      <div className="flex items-center space-x-4">
        <div className="flex items-center">
          <div className={`w-2 h-2 rounded-full mr-2 ${isConnected ? 'bg-accent-green' : 'bg-accent-red'}`}></div>
          <span className="text-text-secondary">{isConnected ? 'Connected' : 'Disconnected'}</span>
        </div>
        {currentSession && (
          <>
            <span className="text-separator">|</span>
            <span className="text-text-tertiary">Session: {currentSession.substring(0, 8)}...</span>
          </>
        )}
      </div>
      <div className="flex items-center space-x-4">
        <span className="text-text-tertiary">{messageCount} messages</span>
      </div>
    </div>
  )
}

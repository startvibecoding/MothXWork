interface StatusBarProps {
  isConnected: boolean
  currentSession: string | null
  messageCount: number
}

export default function StatusBar({ isConnected, currentSession, messageCount }: StatusBarProps) {
  return (
    <div className="px-4 py-2 bg-[#1C1C1E] border-t border-[#38383A] flex items-center justify-between text-sm">
      <div className="flex items-center space-x-4">
        <div className="flex items-center">
          <div className={`w-2 h-2 rounded-full mr-2 ${isConnected ? 'bg-[#34C759]' : 'bg-[#FF3B30]'}`}></div>
          <span className="text-[#8E8E93]">{isConnected ? 'Connected' : 'Disconnected'}</span>
        </div>
        {currentSession && (
          <>
            <span className="text-[#38383A]">|</span>
            <span className="text-[#636366]">Session: {currentSession.substring(0, 8)}...</span>
          </>
        )}
      </div>
      <div className="flex items-center space-x-4">
        <span className="text-[#636366]">{messageCount} messages</span>
      </div>
    </div>
  )
}

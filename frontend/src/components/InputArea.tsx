interface InputAreaProps {
  value: string
  onChange: (value: string) => void
  onSend: () => void
  onKeyDown: (e: React.KeyboardEvent) => void
  onAbort: () => void
  isLoading: boolean
  cwd?: string
}

export default function InputArea({ value, onChange, onSend, onKeyDown, onAbort, isLoading, cwd }: InputAreaProps) {
  return (
    <div className="bg-[#1C1C1E] border-t border-[#38383A]">
      <div className="p-4">
        <div className="flex space-x-3">
          <textarea
            className="flex-1 bg-[#2C2C2E] text-white rounded-xl px-4 py-3 border border-[#38383A] focus:border-[#007AFF] focus:ring-1 focus:ring-[#007AFF] outline-none resize-none placeholder-[#636366] text-[15px]"
            placeholder="Type your message..."
            value={value}
            onChange={e => onChange(e.target.value)}
            onKeyDown={onKeyDown}
            rows={2}
            disabled={isLoading}
          />
          {isLoading ? (
            <button
              className="px-5 py-3 rounded-xl font-medium transition-colors bg-[#FF3B30] hover:bg-[#FF453A] text-white"
              onClick={onAbort}
            >
              <div className="flex items-center">
                <svg className="h-5 w-5 mr-1.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <rect x="6" y="6" width="12" height="12" rx="2" />
                </svg>
                Stop
              </div>
            </button>
          ) : (
            <button
              className={`px-5 py-3 rounded-xl font-medium transition-colors ${
                !value.trim()
                  ? 'bg-[#3A3A3C] text-[#636366] cursor-not-allowed'
                  : 'bg-[#007AFF] hover:bg-[#0071E3] text-white'
              }`}
              onClick={onSend}
              disabled={!value.trim()}
            >
              <svg className="h-5 w-5" viewBox="0 0 24 24" fill="currentColor">
                <path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z" />
              </svg>
            </button>
          )}
        </div>
      </div>
      
      {/* Working Directory */}
      {cwd && (
        <div className="px-4 pb-2 flex items-center space-x-2 text-xs text-[#636366]">
          <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
          </svg>
          <span className="truncate" title={cwd}>{cwd}</span>
        </div>
      )}
    </div>
  )
}

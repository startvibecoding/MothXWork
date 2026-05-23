import { useState } from 'react'
import { SendPermissionResponse } from '../../wailsjs/go/main/App'

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

interface PermissionDialogProps {
  request: PermissionRequest | null
  onClose: () => void
}

export default function PermissionDialog({ request, onClose }: PermissionDialogProps) {
  const [isProcessing, setIsProcessing] = useState(false)

  if (!request) return null

  const handleResponse = async (optionId: string) => {
    setIsProcessing(true)
    try {
      await SendPermissionResponse(request.requestId, optionId)
      onClose()
    } catch (err) {
      console.error('Failed to send permission response:', err)
    } finally {
      setIsProcessing(false)
    }
  }

  const formatInput = (input: any) => {
    if (!input) return 'No input'
    if (typeof input === 'string') return input
    try {
      return JSON.stringify(input, null, 2)
    } catch {
      return String(input)
    }
  }

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 animate-fade-in">
      <div className="bg-[#2C2C2E] rounded-2xl w-full max-w-lg shadow-2xl animate-slide-up">
        {/* Header */}
        <div className="p-5 border-b border-[#38383A]">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-[#FF9500]/20 rounded-full flex items-center justify-center">
              <span className="text-xl">⚠️</span>
            </div>
            <div>
              <h2 className="text-lg font-semibold text-white">Permission Required</h2>
              <p className="text-sm text-[#8E8E93]">The AI wants to execute a command</p>
            </div>
          </div>
        </div>

        {/* Content */}
        <div className="p-5 space-y-4">
          {/* Command Info */}
          <div>
            <label className="block text-xs font-medium text-[#8E8E93] mb-2 uppercase">Command</label>
            <div className="bg-[#1C1C1E] rounded-lg p-3">
              <div className="font-medium text-white text-sm">{request.title}</div>
            </div>
          </div>

          {/* Input */}
          {request.input && (
            <div>
              <label className="block text-xs font-medium text-[#8E8E93] mb-2 uppercase">Input</label>
              <div className="bg-[#1C1C1E] rounded-lg p-3 max-h-40 overflow-auto">
                <pre className="text-xs text-[#8E8E93] whitespace-pre-wrap break-words">
                  {formatInput(request.input)}
                </pre>
              </div>
            </div>
          )}

          {/* Warning */}
          <div className="bg-[#FF9500]/10 border border-[#FF9500]/20 rounded-lg p-3">
            <div className="flex items-start space-x-2">
              <span className="text-[#FF9500] mt-0.5">⚠️</span>
              <p className="text-sm text-[#FF9500]">
                Be careful when allowing command execution. Only allow commands you trust.
              </p>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="flex justify-end space-x-3 p-5 border-t border-[#38383A]">
          <button
            className={`px-5 py-2.5 rounded-xl font-medium transition-colors ${
              isProcessing
                ? 'bg-[#3A3A3C] text-[#636366] cursor-not-allowed'
                : 'bg-[#FF3B30] hover:bg-[#FF453A] text-white'
            }`}
            onClick={() => handleResponse('reject-once')}
            disabled={isProcessing}
          >
            {isProcessing ? 'Processing...' : 'Reject'}
          </button>
          <button
            className={`px-5 py-2.5 rounded-xl font-medium transition-colors ${
              isProcessing
                ? 'bg-[#3A3A3C] text-[#636366] cursor-not-allowed'
                : 'bg-[#34C759] hover:bg-[#30B350] text-white'
            }`}
            onClick={() => handleResponse('allow-once')}
            disabled={isProcessing}
          >
            {isProcessing ? 'Processing...' : 'Allow'}
          </button>
        </div>
      </div>
    </div>
  )
}

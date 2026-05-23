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
      <div className="bg-secondary rounded-2xl w-full max-w-lg shadow-2xl animate-slide-up">
        {/* Header */}
        <div className="p-5 border-b border-separator">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-accent-orange/20 rounded-full flex items-center justify-center">
              <span className="text-xl">⚠️</span>
            </div>
            <div>
              <h2 className="text-lg font-semibold text-text-primary">Permission Required</h2>
              <p className="text-sm text-text-secondary">The AI wants to execute a command</p>
            </div>
          </div>
        </div>

        {/* Content */}
        <div className="p-5 space-y-4">
          {/* Command Info */}
          <div>
            <label className="block text-xs font-medium text-text-secondary mb-2 uppercase">Command</label>
            <div className="bg-primary rounded-lg p-3">
              <div className="font-medium text-text-primary text-sm">{request.title}</div>
            </div>
          </div>

          {/* Input */}
          {request.input && (
            <div>
              <label className="block text-xs font-medium text-text-secondary mb-2 uppercase">Input</label>
              <div className="bg-primary rounded-lg p-3 max-h-40 overflow-auto">
                <pre className="text-xs text-text-secondary whitespace-pre-wrap break-words">
                  {formatInput(request.input)}
                </pre>
              </div>
            </div>
          )}

          {/* Warning */}
          <div className="bg-accent-orange/10 border border-accent-orange/20 rounded-lg p-3">
            <div className="flex items-start space-x-2">
              <span className="text-accent-orange mt-0.5">⚠️</span>
              <p className="text-sm text-accent-orange">
                Be careful when allowing command execution. Only allow commands you trust.
              </p>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="flex justify-end space-x-3 p-5 border-t border-separator">
          <button
            className={`px-5 py-2.5 rounded-xl font-medium transition-colors ${
              isProcessing
                ? 'bg-tertiary text-text-tertiary cursor-not-allowed'
                : 'bg-accent-red hover:bg-accent-red/90 text-white'
            }`}
            onClick={() => handleResponse('reject-once')}
            disabled={isProcessing}
          >
            {isProcessing ? 'Processing...' : 'Reject'}
          </button>
          <button
            className={`px-5 py-2.5 rounded-xl font-medium transition-colors ${
              isProcessing
                ? 'bg-tertiary text-text-tertiary cursor-not-allowed'
                : 'bg-accent-green hover:bg-accent-green/90 text-white'
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

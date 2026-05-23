import { useEffect, useRef } from 'react'
import ReactMarkdown from 'react-markdown'
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter'
import { vscDarkPlus } from 'react-syntax-highlighter/dist/esm/styles/prism'
import remarkGfm from 'remark-gfm'
import type { Components } from 'react-markdown'

interface Message {
  id: string
  role: 'user' | 'assistant' | 'system'
  content: string
  timestamp: Date
  isStreaming?: boolean
}

interface ChatAreaProps {
  messages: Message[]
  isLoading: boolean
}

const components: Components = {
  code({ node, className, children, ...props }) {
    const match = /language-(\w+)/.exec(className || '')
    const isInline = !match
    
    if (!isInline && match) {
      return (
        <div className="my-3 rounded-lg overflow-hidden border border-[#38383A]">
          <div className="bg-[#2C2C2E] px-4 py-2 text-xs text-[#8E8E93] border-b border-[#38383A]">
            {match[1]}
          </div>
          <SyntaxHighlighter
            style={vscDarkPlus as any}
            language={match[1]}
            PreTag="div"
            wrapLongLines={true}
            customStyle={{
              margin: 0,
              borderRadius: 0,
              border: 'none',
              padding: '16px',
              fontSize: '13px',
              lineHeight: '1.5',
              whiteSpace: 'pre-wrap',
              wordBreak: 'break-word',
              overflowWrap: 'break-word'
            }}
          >
            {String(children).replace(/\n$/, '')}
          </SyntaxHighlighter>
        </div>
      )
    }
    
    return (
      <code className="bg-[#3A3A3C] px-1.5 py-0.5 rounded text-sm font-mono" {...props}>
        {children}
      </code>
    )
  }
}

export default function ChatArea({ messages, isLoading }: ChatAreaProps) {
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const containerRef = useRef<HTMLDivElement>(null)

  // Auto-scroll to bottom when messages change or during streaming
  useEffect(() => {
    const scrollToBottom = () => {
      if (messagesEndRef.current) {
        messagesEndRef.current.scrollIntoView({ behavior: 'smooth' })
      }
    }
    
    // Scroll immediately
    scrollToBottom()
    
    // Also scroll after a short delay to handle streaming content
    const timer = setTimeout(scrollToBottom, 100)
    
    return () => clearTimeout(timer)
  }, [messages])

  // Also scroll when isLoading changes
  useEffect(() => {
    if (isLoading && messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({ behavior: 'smooth' })
    }
  }, [isLoading])

  const renderMessage = (message: Message) => {
    const isUser = message.role === 'user'
    const isSystem = message.role === 'system'

    return (
      <div
        key={message.id}
        className={`flex ${isUser ? 'justify-end' : 'justify-start'} mb-4 animate-fade-in`}
      >
        <div
          className={`max-w-[80%] rounded-2xl px-4 py-3 ${
            isUser
              ? 'bg-[#007AFF] text-white'
              : isSystem
              ? 'bg-[#FF9500]/20 text-[#FF9500] border border-[#FF9500]/30'
              : 'bg-[#2C2C2E] text-white'
          }`}
          style={{ 
            overflowWrap: 'break-word', 
            wordBreak: 'break-word',
            maxWidth: '80%',
            width: 'fit-content'
          }}
        >
          {isUser ? (
            <p className="whitespace-pre-wrap text-[15px] break-words">{message.content}</p>
          ) : (
            <div className="markdown-body">
              <ReactMarkdown
                remarkPlugins={[remarkGfm]}
                components={components}
              >
                {message.content}
              </ReactMarkdown>
            </div>
          )}
          <div className={`text-xs mt-2 ${
            isUser ? 'text-white/60' : 'text-[#636366]'
          }`}>
            {message.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
            {message.isStreaming && (
              <span className="ml-2 inline-block animate-pulse">●</span>
            )}
          </div>
        </div>
      </div>
    )
  }

  return (
    <div ref={containerRef} className="flex-1 overflow-y-auto p-6 bg-[#1C1C1E]">
      {messages.length === 0 ? (
        <div className="flex items-center justify-center h-full">
          <div className="text-center">
            <img src="/logo.svg" alt="VibeCoding" className="w-24 h-24 mx-auto mb-4" />
            <h2 className="text-2xl font-semibold text-white mb-2">VibeCoding GUI</h2>
            <p className="text-[#8E8E93] text-lg">Start a conversation to begin coding with AI</p>
          </div>
        </div>
      ) : (
        <>
          {messages.map(renderMessage)}
          {isLoading && !messages.some(m => m.isStreaming) && (
            <div className="flex justify-start mb-4">
              <div className="bg-[#2C2C2E] rounded-2xl px-4 py-3">
                <div className="flex space-x-2">
                  <div className="w-2 h-2 bg-[#8E8E93] rounded-full animate-bounce" />
                  <div className="w-2 h-2 bg-[#8E8E93] rounded-full animate-bounce" style={{ animationDelay: '0.2s' }} />
                  <div className="w-2 h-2 bg-[#8E8E93] rounded-full animate-bounce" style={{ animationDelay: '0.4s' }} />
                </div>
              </div>
            </div>
          )}
          {/* Scroll anchor */}
          <div ref={messagesEndRef} />
        </>
      )}
    </div>
  )
}

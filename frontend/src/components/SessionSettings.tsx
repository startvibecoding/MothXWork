import { useState, useEffect, useRef } from 'react'
import { GetProviders, GetModels, UpdateConfig } from '../../wailsjs/go/main/App'

interface Config {
  cwd: string
  provider: string
  model: string
  mode: string
  thinking: string
}

interface Provider {
  id: string
  name: string
  api: string
}

interface Model {
  id: string
  name: string
  reasoning?: boolean
  contextWindow?: number
  maxTokens?: number
  temperature?: number
  top_p?: number
  input?: string[]
}

interface SessionSettingsProps {
  config: Config
  onConfigChange: (config: Config) => void
}

function CustomSelect({ 
  value, 
  onChange, 
  options, 
  placeholder 
}: { 
  value: string
  onChange: (value: string) => void
  options: { value: string, label: string }[]
  placeholder?: string
}) {
  const [isOpen, setIsOpen] = useState(false)
  const ref = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (ref.current && !ref.current.contains(event.target as Node)) {
        setIsOpen(false)
      }
    }
    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  const selectedOption = options.find(o => o.value === value)

  return (
    <div className="relative" ref={ref}>
      <button
        type="button"
        className="w-full bg-primary text-text-primary rounded-lg px-3 py-2.5 border border-separator hover:border-elevated focus:border-accent focus:ring-1 focus:ring-accent outline-none text-sm text-left flex items-center justify-between"
        onClick={() => setIsOpen(!isOpen)}
      >
        <span className={selectedOption ? 'text-text-primary' : 'text-text-tertiary'}>
          {selectedOption?.label || placeholder || 'Select...'}
        </span>
        <svg 
          className={`w-4 h-4 text-text-secondary transition-transform ${isOpen ? 'rotate-180' : ''}`} 
          fill="none" 
          stroke="currentColor" 
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {isOpen && (
        <div className="absolute z-50 w-full mt-1 bg-secondary rounded-lg shadow-xl border border-separator max-h-60 overflow-auto">
          {options.map(option => (
            <button
              key={option.value}
              type="button"
              className={`w-full px-3 py-2.5 text-sm text-left hover:bg-tertiary transition-colors ${
                option.value === value 
                  ? 'bg-accent/20 text-accent' 
                  : 'text-text-primary'
              }`}
              onClick={() => {
                onChange(option.value)
                setIsOpen(false)
              }}
            >
              {option.label}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}

export default function SessionSettings({ config, onConfigChange }: SessionSettingsProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [providers, setProviders] = useState<Provider[]>([])
  const [models, setModels] = useState<Model[]>([])
  const [editConfig, setEditConfig] = useState<Config>(config)
  const dropdownRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    loadProviders()
  }, [])

  useEffect(() => {
    if (editConfig.provider) {
      loadModels(editConfig.provider)
    }
  }, [editConfig.provider])

  useEffect(() => {
    setEditConfig(config)
  }, [config])

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false)
      }
    }

    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  const loadProviders = async () => {
    try {
      const p = await GetProviders()
      setProviders(Array.isArray(p) ? (p as unknown as Provider[]) : [])
    } catch (err) {
      console.error('Failed to load providers:', err)
      setProviders([])
    }
  }

  const loadModels = async (providerID: string) => {
    try {
      const m = await GetModels(providerID)
      setModels(Array.isArray(m) ? (m as unknown as Model[]) : [])
    } catch (err) {
      console.error('Failed to load models:', err)
      setModels([])
    }
  }

  const handleApply = async () => {
    try {
      await UpdateConfig(editConfig)
      onConfigChange(editConfig)
      setIsOpen(false)
    } catch (err) {
      console.error('Failed to update config:', err)
    }
  }

  const hasChanges = 
    editConfig.provider !== config.provider ||
    editConfig.model !== config.model ||
    editConfig.mode !== config.mode ||
    editConfig.thinking !== config.thinking

  const modes = [
    { id: 'plan', name: 'Plan', icon: '🗒️', color: 'text-accent-yellow' },
    { id: 'agent', name: 'Agent', icon: '🔧', color: 'text-accent-green' },
    { id: 'yolo', name: 'YOLO', icon: '🚀', color: 'text-accent-red' },
  ]

  const thinkingLevels = [
    { id: 'off', name: 'Off' },
    { id: 'minimal', name: 'Min' },
    { id: 'low', name: 'Low' },
    { id: 'medium', name: 'Med' },
    { id: 'high', name: 'High' },
    { id: 'xhigh', name: 'XHigh' },
  ]

  const currentMode = modes.find(m => m.id === config.mode)

  const providerOptions = providers.map(p => ({
    value: p.id,
    label: `${p.name} (${p.api})`
  }))

  const modelOptions = models.map(m => ({
    value: m.id,
    label: m.contextWindow 
      ? `${m.name} (${m.contextWindow >= 1000000 
        ? `${(m.contextWindow / 1000000).toFixed(0)}M` 
        : `${(m.contextWindow / 1000).toFixed(0)}K`
      })`
      : m.name
  }))

  return (
    <div className="relative" ref={dropdownRef}>
      {/* Trigger Button */}
      <button
        className="flex items-center space-x-2 bg-secondary hover:bg-tertiary px-3 py-1.5 rounded-lg transition-colors"
        onClick={() => setIsOpen(!isOpen)}
      >
        <span className={currentMode?.color}>{currentMode?.icon}</span>
        <span className="text-sm text-text-primary font-medium">{currentMode?.name}</span>
        <span className="text-separator">|</span>
        <span className="text-sm text-text-secondary">{config.provider}</span>
        <span className="text-separator">|</span>
        <span className="text-sm text-text-secondary">{config.model}</span>
        <svg 
          className={`w-4 h-4 text-text-secondary transition-transform ${isOpen ? 'rotate-180' : ''}`} 
          fill="none" 
          stroke="currentColor" 
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {/* Dropdown */}
      {isOpen && (
        <div className="absolute right-0 top-full mt-2 w-80 bg-secondary rounded-xl shadow-2xl border border-separator z-50 animate-slide-up">
          <div className="p-4 space-y-4">
            {/* Mode */}
            <div>
              <label className="block text-xs font-medium text-text-secondary mb-2 uppercase">Mode</label>
              <div className="flex space-x-2">
                {modes.map(mode => (
                  <button
                    key={mode.id}
                    className={`flex-1 flex items-center justify-center p-2.5 rounded-lg transition-colors ${
                      editConfig.mode === mode.id
                        ? 'bg-accent/20 border border-accent/50'
                        : 'bg-primary hover:bg-tertiary border border-transparent'
                    }`}
                    onClick={() => setEditConfig({ ...editConfig, mode: mode.id })}
                  >
                    <span className={`mr-1.5 ${mode.color}`}>{mode.icon}</span>
                    <span className="text-sm text-text-primary font-medium">{mode.name}</span>
                  </button>
                ))}
              </div>
            </div>

            {/* Provider */}
            <div>
              <label className="block text-xs font-medium text-text-secondary mb-2 uppercase">Provider</label>
              <CustomSelect
                value={editConfig.provider}
                onChange={(value) => setEditConfig({ 
                  ...editConfig, 
                  provider: value,
                  model: '' // Reset model
                })}
                options={providerOptions}
                placeholder="Select provider..."
              />
            </div>

            {/* Model */}
            <div>
              <label className="block text-xs font-medium text-text-secondary mb-2 uppercase">Model</label>
              <CustomSelect
                value={editConfig.model}
                onChange={(value) => setEditConfig({ ...editConfig, model: value })}
                options={modelOptions}
                placeholder="Select model..."
              />
            </div>

            {/* Thinking Level */}
            <div>
              <label className="block text-xs font-medium text-text-secondary mb-2 uppercase">Thinking</label>
              <div className="flex flex-wrap gap-2">
                {thinkingLevels.map(t => (
                  <button
                    key={t.id}
                    className={`px-3 py-1.5 rounded-lg text-sm transition-colors ${
                      editConfig.thinking === t.id
                        ? 'bg-accent text-white'
                        : 'bg-primary hover:bg-tertiary text-text-secondary'
                    }`}
                    onClick={() => setEditConfig({ ...editConfig, thinking: t.id })}
                  >
                    {t.name}
                  </button>
                ))}
              </div>
            </div>

            {/* Apply Button */}
            {hasChanges && (
              <button
                className="w-full py-2.5 bg-accent hover:bg-accent/90 rounded-xl text-white text-sm font-medium transition-colors"
                onClick={handleApply}
              >
                Apply & Restart Session
              </button>
            )}
          </div>
        </div>
      )}
    </div>
  )
}

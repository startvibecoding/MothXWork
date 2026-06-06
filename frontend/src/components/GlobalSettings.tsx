import { useState, useEffect } from 'react'
import { GetSettings, SaveSettings, LoadUIConfig, SaveUIConfig } from '../../wailsjs/go/main/App'
import CustomSelect from './CustomSelect'
import AdvancedSettings from './AdvancedSettings'

interface CostConfig {
  input: number
  output: number
  cacheRead?: number
  cacheWrite?: number
}

interface ModelCompat {
  thinkingFormat?: string
  requiresReasoningContentOnAssistant?: boolean
  requiresReasoningContentOnAssistantMessages?: boolean
  forceAdaptiveThinking?: boolean
  supportsDeveloperRole?: boolean
  supportsStore?: boolean
  supportsReasoningEffort?: boolean
  supportsStrictMode?: boolean
  maxTokensField?: string
  supportsCacheControlOnTools?: boolean
  supportsLongCacheRetention?: boolean
  supportsPromptCacheKey?: boolean
  supportsReasoningSummary?: boolean
  sendSessionAffinityHeaders?: boolean
  supportsEagerToolInputStreaming?: boolean
}

interface Model {
  id: string
  name: string
  reasoning?: boolean
  contextWindow?: number
  maxTokens?: number
  temperature?: number
  top_p?: number
  cost?: CostConfig
  input?: string[]
  compat?: ModelCompat
}

interface Provider {
  apiKey: string
  baseUrl: string
  api: string
  models: Model[]
}

interface Settings {
  providers: Record<string, Provider>
  defaultProvider: string
  defaultModel: string
  defaultThinkingLevel: string
  defaultMode: string
}

interface GlobalSettingsProps {
  isOpen: boolean
  onClose: () => void
}

export default function GlobalSettings({ isOpen, onClose }: GlobalSettingsProps) {
  const [settings, setSettings] = useState<Settings | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [editingProvider, setEditingProvider] = useState<string | null>(null)
  const [editingModel, setEditingModel] = useState<{ provider: string, model: Model | null } | null>(null)
  const [showAddProvider, setShowAddProvider] = useState(false)
  const [showAddModel, setShowAddModel] = useState<string | null>(null)
  const [hasChanges, setHasChanges] = useState(false)
  const [showAdvancedSettings, setShowAdvancedSettings] = useState(false)
  const [advancedSettings, setAdvancedSettings] = useState<any>({})
  const [uiTheme, setUiTheme] = useState<string>('dark')

  // Form states
  const [providerForm, setProviderForm] = useState({ id: '', apiKey: '', baseUrl: '', api: 'openai-chat' })
  const [modelForm, setModelForm] = useState({ 
    id: '', 
    name: '', 
    reasoning: false,
    contextWindow: 1000000, 
    maxTokens: 65535,
    temperature: undefined as number | undefined,
    top_p: undefined as number | undefined,
    input: [] as string[]
  })

  useEffect(() => {
    if (isOpen) {
      loadSettings()
    }
  }, [isOpen])

  const loadSettings = async () => {
    setIsLoading(true)
    setError(null)
    try {
      const [s, uiConfig] = await Promise.all([GetSettings(), LoadUIConfig()])
      setSettings(s as unknown as Settings)
      // Set UI theme
      if (uiConfig && uiConfig.theme) {
        setUiTheme(uiConfig.theme as string)
      }
      // Extract advanced settings (exclude theme)
      const advanced: any = {}
      if ((s as any).compaction) advanced.compaction = (s as any).compaction
      if ((s as any).sandbox) advanced.sandbox = (s as any).sandbox
      if ((s as any).contextFiles) advanced.contextFiles = (s as any).contextFiles
      if ((s as any).skillsDir) advanced.skillsDir = (s as any).skillsDir
      if ((s as any).sessionDir) advanced.sessionDir = (s as any).sessionDir
      if ((s as any).shellPath) advanced.shellPath = (s as any).shellPath
      if ((s as any).shellCommandPrefix) advanced.shellCommandPrefix = (s as any).shellCommandPrefix
      if ((s as any).retry) advanced.retry = (s as any).retry
      if ((s as any).approval) advanced.approval = (s as any).approval
      if ((s as any).maxOutputTokens) advanced.maxOutputTokens = (s as any).maxOutputTokens
      if ((s as any).maxContextTokens) advanced.maxContextTokens = (s as any).maxContextTokens
      setAdvancedSettings(advanced)
    } catch (err) {
      console.error('Failed to load settings:', err)
      setError('Failed to load settings: ' + err)
    } finally {
      setIsLoading(false)
    }
  }

  const handleSave = async () => {
    if (!settings) return
    
    try {
      // Save VibeCoding settings (without theme)
      const fullSettings = { ...settings, ...advancedSettings }
      await SaveSettings(fullSettings as any)
      // Save UI theme separately
      await SaveUIConfig({ theme: uiTheme })
      setHasChanges(false)
      onClose()
    } catch (err) {
      console.error('Failed to save settings:', err)
      setError('Failed to save settings: ' + err)
    }
  }

  const handleAdvancedSettingsSave = async (newAdvancedSettings: any) => {
    setAdvancedSettings(newAdvancedSettings)
    // Save immediately
    if (settings) {
      try {
        const fullSettings = { ...settings, ...newAdvancedSettings }
        await SaveSettings(fullSettings as any)
      } catch (err) {
        console.error('Failed to save advanced settings:', err)
      }
    }
  }

  const handleThemeChange = async (theme: string) => {
    setUiTheme(theme)
    setHasChanges(true)
    // Apply theme immediately
    document.documentElement.setAttribute('data-theme', theme)
  }

  // Provider CRUD
  const handleAddProvider = () => {
    if (!settings || !providerForm.id) return
    
    const newSettings = { ...settings }
    newSettings.providers[providerForm.id] = {
      apiKey: providerForm.apiKey,
      baseUrl: providerForm.baseUrl,
      api: providerForm.api,
      models: []
    }
    setSettings(newSettings)
    setHasChanges(true)
    setShowAddProvider(false)
    setProviderForm({ id: '', apiKey: '', baseUrl: '', api: 'openai-chat' })
  }

  const handleEditProvider = (id: string) => {
    if (!settings) return
    const provider = settings.providers[id]
    setProviderForm({ id, apiKey: provider.apiKey, baseUrl: provider.baseUrl, api: provider.api })
    setEditingProvider(id)
  }

  const handleUpdateProvider = () => {
    if (!settings || !editingProvider) return
    
    const newSettings = { ...settings }
    const oldProvider = newSettings.providers[editingProvider]
    newSettings.providers[editingProvider] = {
      ...oldProvider,
      apiKey: providerForm.apiKey,
      baseUrl: providerForm.baseUrl,
      api: providerForm.api
    }
    setSettings(newSettings)
    setHasChanges(true)
    setEditingProvider(null)
  }

  const handleDeleteProvider = (id: string) => {
    if (!settings) return
    if (!confirm(`Delete provider "${id}"?`)) return
    
    const newSettings = { ...settings }
    delete newSettings.providers[id]
    if (newSettings.defaultProvider === id) {
      newSettings.defaultProvider = Object.keys(newSettings.providers)[0] || ''
    }
    setSettings(newSettings)
    setHasChanges(true)
  }

  // Model CRUD
  const handleAddModel = (providerId: string) => {
    if (!settings || !modelForm.id) return
    
    const newSettings = { ...settings }
    newSettings.providers[providerId].models.push({
      id: modelForm.id,
      name: modelForm.name,
      reasoning: modelForm.reasoning,
      contextWindow: modelForm.contextWindow,
      maxTokens: modelForm.maxTokens,
      temperature: modelForm.temperature,
      top_p: modelForm.top_p,
      input: modelForm.input
    })
    setSettings(newSettings)
    setHasChanges(true)
    setShowAddModel(null)
    setModelForm({ id: '', name: '', reasoning: false, contextWindow: 1000000, maxTokens: 65535, temperature: undefined, top_p: undefined, input: [] })
  }

  const handleEditModel = (providerId: string, model: Model) => {
    setModelForm({ 
      id: model.id, 
      name: model.name, 
      reasoning: model.reasoning || false,
      contextWindow: model.contextWindow || 0, 
      maxTokens: model.maxTokens || 0,
      temperature: model.temperature,
      top_p: model.top_p,
      input: model.input || []
    })
    setEditingModel({ provider: providerId, model })
  }

  const handleUpdateModel = () => {
    if (!settings || !editingModel) return
    
    const newSettings = { ...settings }
    const models = newSettings.providers[editingModel.provider].models
    const index = models.findIndex(m => m.id === editingModel.model?.id)
    if (index !== -1) {
      models[index] = { ...models[index], ...modelForm }
    }
    setSettings(newSettings)
    setHasChanges(true)
    setEditingModel(null)
  }

  const handleDeleteModel = (providerId: string, modelId: string) => {
    if (!settings) return
    if (!confirm(`Delete model "${modelId}"?`)) return
    
    const newSettings = { ...settings }
    newSettings.providers[providerId].models = newSettings.providers[providerId].models.filter(m => m.id !== modelId)
    if (newSettings.defaultModel === modelId) {
      newSettings.defaultModel = newSettings.providers[providerId].models[0]?.id || ''
    }
    setSettings(newSettings)
    setHasChanges(true)
  }

  if (!isOpen) return null

  const apiOptions = [
    { value: 'openai-chat', label: 'OpenAI Chat' },
    { value: 'anthropic-messages', label: 'Anthropic Messages' }
  ]

  const modeOptions = [
    { value: 'plan', label: 'Plan' },
    { value: 'agent', label: 'Agent' },
    { value: 'yolo', label: 'YOLO' }
  ]

  const thinkingOptions = [
    { value: 'off', label: 'Off' },
    { value: 'minimal', label: 'Minimal' },
    { value: 'low', label: 'Low' },
    { value: 'medium', label: 'Medium' },
    { value: 'high', label: 'High' },
    { value: 'xhigh', label: 'XHigh' }
  ]

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 animate-fade-in">
      <div className="bg-secondary rounded-2xl w-full max-w-5xl max-h-[90vh] flex flex-col shadow-2xl animate-slide-up">
        {/* Header */}
        <div className="flex items-center justify-between p-5 border-b border-separator">
          <div>
            <h2 className="text-xl font-semibold text-text-primary">全局设置</h2>
            <p className="text-sm text-text-secondary mt-1">~/.vibecoding/settings.json</p>
          </div>
          <div className="flex items-center space-x-3">
            <button
              className="px-4 py-2 bg-tertiary hover:bg-elevated rounded-lg text-text-primary text-sm font-medium transition-colors"
              onClick={() => setShowAdvancedSettings(true)}
            >
              ⚙️ 高级设置
            </button>
            {hasChanges && (
              <button
                className="px-4 py-2 bg-accent hover:bg-accent/90 rounded-lg text-white text-sm font-medium transition-colors"
                onClick={handleSave}
              >
                Save Changes
              </button>
            )}
            <button 
              className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-tertiary text-text-secondary hover:text-text-primary transition-colors"
              onClick={onClose}
            >
              ✕
            </button>
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-5">
          {isLoading ? (
            <div className="flex items-center justify-center h-32">
              <div className="text-text-secondary">Loading settings...</div>
            </div>
          ) : error ? (
            <div className="bg-accent-red/10 border border-accent-red/30 rounded-xl p-4">
              <div className="text-accent-red">{error}</div>
            </div>
          ) : settings ? (
            <div className="space-y-6">
              {/* Add Provider Button */}
              <div className="flex justify-between items-center">
                <h3 className="text-lg font-semibold text-text-primary">Providers</h3>
                <button
                  className="px-4 py-2 bg-accent-green hover:bg-accent-green/90 rounded-lg text-white text-sm font-medium transition-colors"
                  onClick={() => setShowAddProvider(true)}
                >
                  + Add Provider
                </button>
              </div>

              {/* Add Provider Form */}
              {showAddProvider && (
                <div className="bg-primary rounded-xl p-4 border border-accent/30">
                  <h4 className="text-sm font-medium text-text-primary mb-3">Add New Provider</h4>
                  <div className="grid grid-cols-2 gap-3">
                    <input
                      type="text"
                      placeholder="Provider ID"
                      className="bg-secondary text-text-primary rounded-lg px-3 py-2 border border-separator focus:border-accent outline-none text-sm"
                      value={providerForm.id}
                      onChange={e => setProviderForm({ ...providerForm, id: e.target.value })}
                    />
                    <CustomSelect
                      value={providerForm.api}
                      onChange={value => setProviderForm({ ...providerForm, api: value })}
                      options={apiOptions}
                      placeholder="Select API type..."
                    />
                    <input
                      type="text"
                      placeholder="API Key"
                      className="bg-secondary text-text-primary rounded-lg px-3 py-2 border border-separator focus:border-accent outline-none text-sm"
                      value={providerForm.apiKey}
                      onChange={e => setProviderForm({ ...providerForm, apiKey: e.target.value })}
                    />
                    <input
                      type="text"
                      placeholder="Base URL"
                      className="bg-secondary text-text-primary rounded-lg px-3 py-2 border border-separator focus:border-accent outline-none text-sm"
                      value={providerForm.baseUrl}
                      onChange={e => setProviderForm({ ...providerForm, baseUrl: e.target.value })}
                    />
                  </div>
                  <div className="flex justify-end space-x-2 mt-3">
                    <button
                      className="px-3 py-1.5 bg-tertiary hover:bg-elevated rounded-lg text-text-primary text-sm"
                      onClick={() => setShowAddProvider(false)}
                    >
                      Cancel
                    </button>
                    <button
                      className="px-3 py-1.5 bg-accent hover:bg-accent/90 rounded-lg text-white text-sm"
                      onClick={handleAddProvider}
                    >
                      Add
                    </button>
                  </div>
                </div>
              )}

              {/* Providers List */}
              <div className="space-y-4">
                {Object.entries(settings.providers).map(([id, provider]) => (
                  <div key={id} className="bg-primary rounded-xl p-4">
                    {/* Provider Header */}
                    <div className="flex items-center justify-between mb-3">
                      <div className="flex items-center space-x-3">
                        <h4 className="font-medium text-text-primary">{id}</h4>
                        <span className="text-xs bg-tertiary text-text-secondary px-2 py-0.5 rounded">{provider.api}</span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <button
                          className="px-3 py-1.5 bg-tertiary hover:bg-elevated rounded-lg text-text-primary text-xs"
                          onClick={() => handleEditProvider(id)}
                        >
                          Edit
                        </button>
                        <button
                          className="px-3 py-1.5 bg-accent-red/20 hover:bg-accent-red/30 rounded-lg text-accent-red text-xs"
                          onClick={() => handleDeleteProvider(id)}
                        >
                          Delete
                        </button>
                      </div>
                    </div>

                    {/* Edit Provider Form */}
                    {editingProvider === id && (
                      <div className="bg-secondary rounded-lg p-3 mb-3">
                        <div className="grid grid-cols-2 gap-3">
                          <input
                            type="text"
                            placeholder="API Key"
                            className="bg-primary text-text-primary rounded-lg px-3 py-2 border border-separator focus:border-accent outline-none text-sm"
                            value={providerForm.apiKey}
                            onChange={e => setProviderForm({ ...providerForm, apiKey: e.target.value })}
                          />
                          <input
                            type="text"
                            placeholder="Base URL"
                            className="bg-primary text-text-primary rounded-lg px-3 py-2 border border-separator focus:border-accent outline-none text-sm"
                            value={providerForm.baseUrl}
                            onChange={e => setProviderForm({ ...providerForm, baseUrl: e.target.value })}
                          />
                        </div>
                        <div className="flex justify-end space-x-2 mt-3">
                          <button
                            className="px-3 py-1.5 bg-tertiary hover:bg-elevated rounded-lg text-text-primary text-xs"
                            onClick={() => setEditingProvider(null)}
                          >
                            Cancel
                          </button>
                          <button
                            className="px-3 py-1.5 bg-accent hover:bg-accent/90 rounded-lg text-white text-xs"
                            onClick={handleUpdateProvider}
                          >
                            Save
                          </button>
                        </div>
                      </div>
                    )}

                    {/* Provider Info */}
                    <div className="text-sm text-text-secondary mb-3">
                      <span className="text-text-tertiary">Base URL:</span> {provider.baseUrl}
                    </div>

                    {/* Models */}
                    <div>
                      <div className="flex justify-between items-center mb-2">
                        <h5 className="text-xs font-medium text-text-tertiary uppercase">Models</h5>
                        <button
                          className="text-xs text-accent hover:text-accent/90"
                          onClick={() => setShowAddModel(id)}
                        >
                          + Add Model
                        </button>
                      </div>

                      {/* Add Model Form */}
                      {showAddModel === id && (
                        <div className="bg-secondary rounded-lg p-3 mb-2">
                          <div className="grid grid-cols-2 gap-3">
                            <input
                              type="text"
                              placeholder="Model ID"
                              className="bg-primary text-text-primary rounded-lg px-3 py-2 border border-separator focus:border-accent outline-none text-sm"
                              value={modelForm.id}
                              onChange={e => setModelForm({ ...modelForm, id: e.target.value })}
                            />
                            <input
                              type="text"
                              placeholder="Model Name"
                              className="bg-primary text-text-primary rounded-lg px-3 py-2 border border-separator focus:border-accent outline-none text-sm"
                              value={modelForm.name}
                              onChange={e => setModelForm({ ...modelForm, name: e.target.value })}
                            />
                            <div className="flex items-center space-x-2">
                              <input
                                type="checkbox"
                                id="reasoning"
                                checked={modelForm.reasoning}
                                onChange={e => setModelForm({ ...modelForm, reasoning: e.target.checked })}
                                className="rounded"
                              />
                              <label htmlFor="reasoning" className="text-sm text-text-secondary">Reasoning</label>
                            </div>
                            <input
                              type="number"
                              placeholder="Context Window"
                              className="bg-primary text-text-primary rounded-lg px-3 py-2 border border-separator focus:border-accent outline-none text-sm"
                              value={modelForm.contextWindow}
                              onChange={e => setModelForm({ ...modelForm, contextWindow: parseInt(e.target.value) || 0 })}
                            />
                            <input
                              type="number"
                              placeholder="Max Tokens"
                              className="bg-primary text-text-primary rounded-lg px-3 py-2 border border-separator focus:border-accent outline-none text-sm"
                              value={modelForm.maxTokens}
                              onChange={e => setModelForm({ ...modelForm, maxTokens: parseInt(e.target.value) || 0 })}
                            />
                            <input
                              type="number"
                              placeholder="Temperature (optional)"
                              className="bg-primary text-text-primary rounded-lg px-3 py-2 border border-separator focus:border-accent outline-none text-sm"
                              value={modelForm.temperature ?? ''}
                              onChange={e => setModelForm({ ...modelForm, temperature: e.target.value ? parseFloat(e.target.value) : undefined })}
                            />
                            <input
                              type="number"
                              placeholder="Top P (optional)"
                              className="bg-primary text-text-primary rounded-lg px-3 py-2 border border-separator focus:border-accent outline-none text-sm"
                              value={modelForm.top_p ?? ''}
                              onChange={e => setModelForm({ ...modelForm, top_p: e.target.value ? parseFloat(e.target.value) : undefined })}
                            />
                          </div>
                          <div className="mt-3">
                            <label className="text-xs text-text-secondary mb-2 block">Input Types</label>
                            <div className="flex flex-wrap gap-2">
                              {['text', 'image', 'audio', 'video'].map(type => (
                                <label key={type} className="flex items-center space-x-1">
                                  <input
                                    type="checkbox"
                                    checked={modelForm.input.includes(type)}
                                    onChange={e => {
                                      if (e.target.checked) {
                                        setModelForm({ ...modelForm, input: [...modelForm.input, type] })
                                      } else {
                                        setModelForm({ ...modelForm, input: modelForm.input.filter(t => t !== type) })
                                      }
                                    }}
                                    className="rounded"
                                  />
                                  <span className="text-xs text-text-primary">{type}</span>
                                </label>
                              ))}
                            </div>
                          </div>
                          <div className="flex justify-end space-x-2 mt-3">
                            <button
                              className="px-3 py-1.5 bg-tertiary hover:bg-elevated rounded-lg text-text-primary text-xs"
                              onClick={() => setShowAddModel(null)}
                            >
                              Cancel
                            </button>
                            <button
                              className="px-3 py-1.5 bg-accent hover:bg-accent/90 rounded-lg text-white text-xs"
                              onClick={() => handleAddModel(id)}
                            >
                              Add
                            </button>
                          </div>
                        </div>
                      )}

                      <div className="grid grid-cols-2 gap-2">
                        {provider.models.map(model => (
                          <div key={model.id} className="bg-secondary rounded-lg p-3">
                            {/* Edit Model Form */}
                            {editingModel?.provider === id && editingModel.model?.id === model.id ? (
                              <div className="space-y-2">
                                <input
                                  type="text"
                                  placeholder="Model ID"
                                  className="w-full bg-primary text-text-primary rounded px-2 py-1 border border-separator focus:border-accent outline-none text-sm"
                                  value={modelForm.id}
                                  onChange={e => setModelForm({ ...modelForm, id: e.target.value })}
                                />
                                <input
                                  type="text"
                                  placeholder="Model Name"
                                  className="w-full bg-primary text-text-primary rounded px-2 py-1 border border-separator focus:border-accent outline-none text-sm"
                                  value={modelForm.name}
                                  onChange={e => setModelForm({ ...modelForm, name: e.target.value })}
                                />
                                <div className="flex items-center space-x-2">
                                  <input
                                    type="checkbox"
                                    checked={modelForm.reasoning}
                                    onChange={e => setModelForm({ ...modelForm, reasoning: e.target.checked })}
                                    className="rounded"
                                  />
                                  <span className="text-xs text-text-secondary">Reasoning</span>
                                </div>
                                <div className="grid grid-cols-2 gap-2">
                                  <input
                                    type="number"
                                    placeholder="Context Window"
                                    className="w-full bg-primary text-text-primary rounded px-2 py-1 border border-separator focus:border-accent outline-none text-sm"
                                    value={modelForm.contextWindow}
                                    onChange={e => setModelForm({ ...modelForm, contextWindow: parseInt(e.target.value) || 0 })}
                                  />
                                  <input
                                    type="number"
                                    placeholder="Max Tokens"
                                    className="w-full bg-primary text-text-primary rounded px-2 py-1 border border-separator focus:border-accent outline-none text-sm"
                                    value={modelForm.maxTokens}
                                    onChange={e => setModelForm({ ...modelForm, maxTokens: parseInt(e.target.value) || 0 })}
                                  />
                                  <input
                                    type="number"
                                    placeholder="Temperature"
                                    className="w-full bg-primary text-text-primary rounded px-2 py-1 border border-separator focus:border-accent outline-none text-sm"
                                    value={modelForm.temperature ?? ''}
                                    onChange={e => setModelForm({ ...modelForm, temperature: e.target.value ? parseFloat(e.target.value) : undefined })}
                                  />
                                  <input
                                    type="number"
                                    placeholder="Top P"
                                    className="w-full bg-primary text-text-primary rounded px-2 py-1 border border-separator focus:border-accent outline-none text-sm"
                                    value={modelForm.top_p ?? ''}
                                    onChange={e => setModelForm({ ...modelForm, top_p: e.target.value ? parseFloat(e.target.value) : undefined })}
                                  />
                                </div>
                                <div className="flex justify-end space-x-2">
                                  <button
                                    className="px-2 py-1 bg-tertiary rounded text-xs text-text-primary"
                                    onClick={() => setEditingModel(null)}
                                  >
                                    Cancel
                                  </button>
                                  <button
                                    className="px-2 py-1 bg-accent rounded text-xs text-white"
                                    onClick={handleUpdateModel}
                                  >
                                    Save
                                  </button>
                                </div>
                              </div>
                            ) : (
                              <>
                                <div className="flex justify-between items-start">
                                  <div>
                                    <div className="font-medium text-text-primary text-sm">{model.name}</div>
                                    <div className="text-xs text-text-secondary mt-1">
                                      {model.contextWindow ? (
                                        model.contextWindow >= 1000000 
                                          ? `${(model.contextWindow / 1000000).toFixed(0)}M tokens`
                                          : `${(model.contextWindow / 1000).toFixed(0)}K tokens`
                                      ) : 'N/A'}
                                    </div>
                                    <div className="flex flex-wrap gap-1 mt-1">
                                      {model.reasoning && (
                                        <span className="text-xs bg-accent-green/20 text-accent-green px-1 rounded">Reasoning</span>
                                      )}
                                      {model.input?.map(type => (
                                        <span key={type} className="text-xs bg-accent/20 text-accent px-1 rounded">{type}</span>
                                      ))}
                                      {model.temperature != null && (
                                        <span className="text-xs bg-tertiary text-text-secondary px-1 rounded">T:{model.temperature}</span>
                                      )}
                                    </div>
                                  </div>
                                  <div className="flex space-x-1">
                                    <button
                                      className="text-xs text-accent hover:text-accent/90"
                                      onClick={() => handleEditModel(id, model)}
                                    >
                                      Edit
                                    </button>
                                    <button
                                      className="text-xs text-accent-red hover:text-accent-red/90"
                                      onClick={() => handleDeleteModel(id, model.id)}
                                    >
                                      Del
                                    </button>
                                  </div>
                                </div>
                              </>
                            )}
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              {/* Default Settings */}
              <div>
                <h3 className="text-lg font-semibold text-text-primary mb-4">Default Settings</h3>
                <div className="bg-primary rounded-xl p-4 space-y-4">
                  <div className="flex justify-between items-center">
                    <span className="text-text-secondary">Default Provider</span>
                    <CustomSelect
                      value={settings.defaultProvider}
                      onChange={value => {
                        setSettings({ ...settings, defaultProvider: value })
                        setHasChanges(true)
                      }}
                      options={Object.keys(settings.providers).map(id => ({ value: id, label: id }))}
                      placeholder="Select provider..."
                      className="w-48"
                    />
                  </div>
                  <div className="flex justify-between items-center border-t border-separator pt-4">
                    <span className="text-text-secondary">Default Model</span>
                    <CustomSelect
                      value={settings.defaultModel}
                      onChange={value => {
                        setSettings({ ...settings, defaultModel: value })
                        setHasChanges(true)
                      }}
                      options={settings.providers[settings.defaultProvider]?.models.map(m => ({ value: m.id, label: m.name })) || []}
                      placeholder="Select model..."
                      className="w-48"
                    />
                  </div>
                  <div className="flex justify-between items-center border-t border-separator pt-4">
                    <span className="text-text-secondary">Default Mode</span>
                    <CustomSelect
                      value={settings.defaultMode}
                      onChange={value => {
                        setSettings({ ...settings, defaultMode: value })
                        setHasChanges(true)
                      }}
                      options={modeOptions}
                      placeholder="Select mode..."
                      className="w-48"
                    />
                  </div>
                  <div className="flex justify-between items-center border-t border-separator pt-4">
                    <span className="text-text-secondary">Default Thinking Level</span>
                    <CustomSelect
                      value={settings.defaultThinkingLevel}
                      onChange={value => {
                        setSettings({ ...settings, defaultThinkingLevel: value })
                        setHasChanges(true)
                      }}
                      options={thinkingOptions}
                      placeholder="Select thinking level..."
                      className="w-48"
                    />
                  </div>
                  <div className="flex justify-between items-center border-t border-separator pt-4">
                    <div>
                      <span className="text-text-secondary">UI Theme</span>
                      <div className="text-xs text-text-tertiary mt-0.5">存储于 ~/.vibecoding-gui/ui.json</div>
                    </div>
                    <CustomSelect
                      value={uiTheme}
                      onChange={value => handleThemeChange(value)}
                      options={[
                        { value: 'dark', label: '深色' },
                        { value: 'light', label: '浅色' }
                      ]}
                      placeholder="Select theme..."
                      className="w-48"
                    />
                  </div>
                </div>
              </div>
            </div>
          ) : null}
        </div>

        {/* Footer */}
        <div className="flex justify-between items-center p-5 border-t border-separator">
          <div className="text-sm text-text-secondary">
            {hasChanges && <span className="text-accent-orange">⚠️ You have unsaved changes</span>}
          </div>
          <div className="flex space-x-3">
            <button
              className="px-4 py-2.5 bg-tertiary hover:bg-elevated rounded-xl text-text-primary font-medium transition-colors"
              onClick={onClose}
            >
              Close
            </button>
            {hasChanges && (
              <button
                className="px-4 py-2.5 bg-accent hover:bg-accent/90 rounded-xl text-white font-medium transition-colors"
                onClick={handleSave}
              >
                Save Changes
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Advanced Settings Modal */}
      <AdvancedSettings
        isOpen={showAdvancedSettings}
        onClose={() => setShowAdvancedSettings(false)}
        settings={advancedSettings}
        onSave={handleAdvancedSettingsSave}
      />
    </div>
  )
}

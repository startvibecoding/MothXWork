import { useState, useEffect } from 'react'
import { GetSettings } from '../../wailsjs/go/main/App'
import CustomSelect from './CustomSelect'

interface Model {
  id: string
  name: string
  contextWindow: number
  maxTokens: number
  reasoning?: boolean
  input?: string[]
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

  // Form states
  const [providerForm, setProviderForm] = useState({ id: '', apiKey: '', baseUrl: '', api: 'openai-chat' })
  const [modelForm, setModelForm] = useState({ id: '', name: '', contextWindow: 1000000, maxTokens: 65535 })

  useEffect(() => {
    if (isOpen) {
      loadSettings()
    }
  }, [isOpen])

  const loadSettings = async () => {
    setIsLoading(true)
    setError(null)
    try {
      const s = await GetSettings()
      setSettings(s as unknown as Settings)
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
      // Save to file using backend API
      // For now, we'll just close and reload
      setHasChanges(false)
      onClose()
    } catch (err) {
      console.error('Failed to save settings:', err)
      setError('Failed to save settings: ' + err)
    }
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
      contextWindow: modelForm.contextWindow,
      maxTokens: modelForm.maxTokens
    })
    setSettings(newSettings)
    setHasChanges(true)
    setShowAddModel(null)
    setModelForm({ id: '', name: '', contextWindow: 1000000, maxTokens: 65535 })
  }

  const handleEditModel = (providerId: string, model: Model) => {
    setModelForm({ id: model.id, name: model.name, contextWindow: model.contextWindow, maxTokens: model.maxTokens })
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
      <div className="bg-[#2C2C2E] rounded-2xl w-full max-w-5xl max-h-[90vh] flex flex-col shadow-2xl animate-slide-up">
        {/* Header */}
        <div className="flex items-center justify-between p-5 border-b border-[#38383A]">
          <div>
            <h2 className="text-xl font-semibold text-white">全局设置</h2>
            <p className="text-sm text-[#8E8E93] mt-1">~/.vibecoding/settings.json</p>
          </div>
          <div className="flex items-center space-x-3">
            {hasChanges && (
              <button
                className="px-4 py-2 bg-[#007AFF] hover:bg-[#0071E3] rounded-lg text-white text-sm font-medium transition-colors"
                onClick={handleSave}
              >
                Save Changes
              </button>
            )}
            <button 
              className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-[#3A3A3C] text-[#8E8E93] hover:text-white transition-colors"
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
              <div className="text-[#8E8E93]">Loading settings...</div>
            </div>
          ) : error ? (
            <div className="bg-[#FF3B30]/10 border border-[#FF3B30]/30 rounded-xl p-4">
              <div className="text-[#FF3B30]">{error}</div>
            </div>
          ) : settings ? (
            <div className="space-y-6">
              {/* Add Provider Button */}
              <div className="flex justify-between items-center">
                <h3 className="text-lg font-semibold text-white">Providers</h3>
                <button
                  className="px-4 py-2 bg-[#34C759] hover:bg-[#30B350] rounded-lg text-white text-sm font-medium transition-colors"
                  onClick={() => setShowAddProvider(true)}
                >
                  + Add Provider
                </button>
              </div>

              {/* Add Provider Form */}
              {showAddProvider && (
                <div className="bg-[#1C1C1E] rounded-xl p-4 border border-[#007AFF]/30">
                  <h4 className="text-sm font-medium text-white mb-3">Add New Provider</h4>
                  <div className="grid grid-cols-2 gap-3">
                    <input
                      type="text"
                      placeholder="Provider ID"
                      className="bg-[#2C2C2E] text-white rounded-lg px-3 py-2 border border-[#38383A] focus:border-[#007AFF] outline-none text-sm"
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
                      className="bg-[#2C2C2E] text-white rounded-lg px-3 py-2 border border-[#38383A] focus:border-[#007AFF] outline-none text-sm"
                      value={providerForm.apiKey}
                      onChange={e => setProviderForm({ ...providerForm, apiKey: e.target.value })}
                    />
                    <input
                      type="text"
                      placeholder="Base URL"
                      className="bg-[#2C2C2E] text-white rounded-lg px-3 py-2 border border-[#38383A] focus:border-[#007AFF] outline-none text-sm"
                      value={providerForm.baseUrl}
                      onChange={e => setProviderForm({ ...providerForm, baseUrl: e.target.value })}
                    />
                  </div>
                  <div className="flex justify-end space-x-2 mt-3">
                    <button
                      className="px-3 py-1.5 bg-[#3A3A3C] hover:bg-[#48484A] rounded-lg text-white text-sm"
                      onClick={() => setShowAddProvider(false)}
                    >
                      Cancel
                    </button>
                    <button
                      className="px-3 py-1.5 bg-[#007AFF] hover:bg-[#0071E3] rounded-lg text-white text-sm"
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
                  <div key={id} className="bg-[#1C1C1E] rounded-xl p-4">
                    {/* Provider Header */}
                    <div className="flex items-center justify-between mb-3">
                      <div className="flex items-center space-x-3">
                        <h4 className="font-medium text-white">{id}</h4>
                        <span className="text-xs bg-[#3A3A3C] text-[#8E8E93] px-2 py-0.5 rounded">{provider.api}</span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <button
                          className="px-3 py-1.5 bg-[#3A3A3C] hover:bg-[#48484A] rounded-lg text-white text-xs"
                          onClick={() => handleEditProvider(id)}
                        >
                          Edit
                        </button>
                        <button
                          className="px-3 py-1.5 bg-[#FF3B30]/20 hover:bg-[#FF3B30]/30 rounded-lg text-[#FF3B30] text-xs"
                          onClick={() => handleDeleteProvider(id)}
                        >
                          Delete
                        </button>
                      </div>
                    </div>

                    {/* Edit Provider Form */}
                    {editingProvider === id && (
                      <div className="bg-[#2C2C2E] rounded-lg p-3 mb-3">
                        <div className="grid grid-cols-2 gap-3">
                          <input
                            type="text"
                            placeholder="API Key"
                            className="bg-[#1C1C1E] text-white rounded-lg px-3 py-2 border border-[#38383A] focus:border-[#007AFF] outline-none text-sm"
                            value={providerForm.apiKey}
                            onChange={e => setProviderForm({ ...providerForm, apiKey: e.target.value })}
                          />
                          <input
                            type="text"
                            placeholder="Base URL"
                            className="bg-[#1C1C1E] text-white rounded-lg px-3 py-2 border border-[#38383A] focus:border-[#007AFF] outline-none text-sm"
                            value={providerForm.baseUrl}
                            onChange={e => setProviderForm({ ...providerForm, baseUrl: e.target.value })}
                          />
                        </div>
                        <div className="flex justify-end space-x-2 mt-3">
                          <button
                            className="px-3 py-1.5 bg-[#3A3A3C] hover:bg-[#48484A] rounded-lg text-white text-xs"
                            onClick={() => setEditingProvider(null)}
                          >
                            Cancel
                          </button>
                          <button
                            className="px-3 py-1.5 bg-[#007AFF] hover:bg-[#0071E3] rounded-lg text-white text-xs"
                            onClick={handleUpdateProvider}
                          >
                            Save
                          </button>
                        </div>
                      </div>
                    )}

                    {/* Provider Info */}
                    <div className="text-sm text-[#8E8E93] mb-3">
                      <span className="text-[#636366]">Base URL:</span> {provider.baseUrl}
                    </div>

                    {/* Models */}
                    <div>
                      <div className="flex justify-between items-center mb-2">
                        <h5 className="text-xs font-medium text-[#636366] uppercase">Models</h5>
                        <button
                          className="text-xs text-[#007AFF] hover:text-[#0071E3]"
                          onClick={() => setShowAddModel(id)}
                        >
                          + Add Model
                        </button>
                      </div>

                      {/* Add Model Form */}
                      {showAddModel === id && (
                        <div className="bg-[#2C2C2E] rounded-lg p-3 mb-2">
                          <div className="grid grid-cols-2 gap-3">
                            <input
                              type="text"
                              placeholder="Model ID"
                              className="bg-[#1C1C1E] text-white rounded-lg px-3 py-2 border border-[#38383A] focus:border-[#007AFF] outline-none text-sm"
                              value={modelForm.id}
                              onChange={e => setModelForm({ ...modelForm, id: e.target.value })}
                            />
                            <input
                              type="text"
                              placeholder="Model Name"
                              className="bg-[#1C1C1E] text-white rounded-lg px-3 py-2 border border-[#38383A] focus:border-[#007AFF] outline-none text-sm"
                              value={modelForm.name}
                              onChange={e => setModelForm({ ...modelForm, name: e.target.value })}
                            />
                            <input
                              type="number"
                              placeholder="Context Window"
                              className="bg-[#1C1C1E] text-white rounded-lg px-3 py-2 border border-[#38383A] focus:border-[#007AFF] outline-none text-sm"
                              value={modelForm.contextWindow}
                              onChange={e => setModelForm({ ...modelForm, contextWindow: parseInt(e.target.value) || 0 })}
                            />
                            <input
                              type="number"
                              placeholder="Max Tokens"
                              className="bg-[#1C1C1E] text-white rounded-lg px-3 py-2 border border-[#38383A] focus:border-[#007AFF] outline-none text-sm"
                              value={modelForm.maxTokens}
                              onChange={e => setModelForm({ ...modelForm, maxTokens: parseInt(e.target.value) || 0 })}
                            />
                          </div>
                          <div className="flex justify-end space-x-2 mt-3">
                            <button
                              className="px-3 py-1.5 bg-[#3A3A3C] hover:bg-[#48484A] rounded-lg text-white text-xs"
                              onClick={() => setShowAddModel(null)}
                            >
                              Cancel
                            </button>
                            <button
                              className="px-3 py-1.5 bg-[#007AFF] hover:bg-[#0071E3] rounded-lg text-white text-xs"
                              onClick={() => handleAddModel(id)}
                            >
                              Add
                            </button>
                          </div>
                        </div>
                      )}

                      <div className="grid grid-cols-2 gap-2">
                        {provider.models.map(model => (
                          <div key={model.id} className="bg-[#2C2C2E] rounded-lg p-3">
                            {/* Edit Model Form */}
                            {editingModel?.provider === id && editingModel.model?.id === model.id ? (
                              <div className="space-y-2">
                                <input
                                  type="text"
                                  placeholder="Model ID"
                                  className="w-full bg-[#1C1C1E] text-white rounded px-2 py-1 border border-[#38383A] focus:border-[#007AFF] outline-none text-sm"
                                  value={modelForm.id}
                                  onChange={e => setModelForm({ ...modelForm, id: e.target.value })}
                                />
                                <input
                                  type="text"
                                  placeholder="Model Name"
                                  className="w-full bg-[#1C1C1E] text-white rounded px-2 py-1 border border-[#38383A] focus:border-[#007AFF] outline-none text-sm"
                                  value={modelForm.name}
                                  onChange={e => setModelForm({ ...modelForm, name: e.target.value })}
                                />
                                <div className="flex justify-end space-x-2">
                                  <button
                                    className="px-2 py-1 bg-[#3A3A3C] rounded text-xs text-white"
                                    onClick={() => setEditingModel(null)}
                                  >
                                    Cancel
                                  </button>
                                  <button
                                    className="px-2 py-1 bg-[#007AFF] rounded text-xs text-white"
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
                                    <div className="font-medium text-white text-sm">{model.name}</div>
                                    <div className="text-xs text-[#8E8E93] mt-1">
                                      {model.contextWindow >= 1000000 
                                        ? `${(model.contextWindow / 1000000).toFixed(0)}M tokens`
                                        : `${(model.contextWindow / 1000).toFixed(0)}K tokens`
                                      }
                                    </div>
                                  </div>
                                  <div className="flex space-x-1">
                                    <button
                                      className="text-xs text-[#007AFF] hover:text-[#0071E3]"
                                      onClick={() => handleEditModel(id, model)}
                                    >
                                      Edit
                                    </button>
                                    <button
                                      className="text-xs text-[#FF3B30] hover:text-[#FF453A]"
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
                <h3 className="text-lg font-semibold text-white mb-4">Default Settings</h3>
                <div className="bg-[#1C1C1E] rounded-xl p-4 space-y-4">
                  <div className="flex justify-between items-center">
                    <span className="text-[#8E8E93]">Default Provider</span>
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
                  <div className="flex justify-between items-center border-t border-[#38383A] pt-4">
                    <span className="text-[#8E8E93]">Default Model</span>
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
                  <div className="flex justify-between items-center border-t border-[#38383A] pt-4">
                    <span className="text-[#8E8E93]">Default Mode</span>
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
                  <div className="flex justify-between items-center border-t border-[#38383A] pt-4">
                    <span className="text-[#8E8E93]">Default Thinking Level</span>
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
                </div>
              </div>
            </div>
          ) : null}
        </div>

        {/* Footer */}
        <div className="flex justify-between items-center p-5 border-t border-[#38383A]">
          <div className="text-sm text-[#8E8E93]">
            {hasChanges && <span className="text-[#FF9500]">⚠️ You have unsaved changes</span>}
          </div>
          <div className="flex space-x-3">
            <button
              className="px-4 py-2.5 bg-[#3A3A3C] hover:bg-[#48484A] rounded-xl text-white font-medium transition-colors"
              onClick={onClose}
            >
              Close
            </button>
            {hasChanges && (
              <button
                className="px-4 py-2.5 bg-[#007AFF] hover:bg-[#0071E3] rounded-xl text-white font-medium transition-colors"
                onClick={handleSave}
              >
                Save Changes
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

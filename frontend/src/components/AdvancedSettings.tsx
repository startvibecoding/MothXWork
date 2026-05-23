import { useState, useEffect } from 'react'
import CustomSelect from './CustomSelect'

interface CompactionConfig {
  enabled: boolean
  reserveTokens: number
  keepRecentTokens: number
}

interface SandboxConfig {
  enabled: boolean
  level: string
  allowNetwork: boolean
  allowedRead?: string[]
  deniedPaths?: string[]
  passEnv?: string[]
  tmpSize?: string
}

interface ContextFilesConfig {
  enabled: boolean
  extraFiles?: string[]
}

interface RetryConfig {
  enabled: boolean
  maxRetries: number
  baseDelayMs: number
}

interface ApprovalConfig {
  bashWhitelist?: string[]
  bashBlacklist?: string[]
}

export interface AdvancedSettingsData {
  maxOutputTokens?: number
  maxContextTokens?: number
  compaction?: CompactionConfig
  sandbox?: SandboxConfig
  contextFiles?: ContextFilesConfig
  skillsDir?: string
  sessionDir?: string
  shellPath?: string
  shellCommandPrefix?: string
  retry?: RetryConfig
  approval?: ApprovalConfig
}

interface AdvancedSettingsProps {
  isOpen: boolean
  onClose: () => void
  settings: AdvancedSettingsData
  onSave: (settings: AdvancedSettingsData) => void
}

const defaultCompaction: CompactionConfig = {
  enabled: true,
  reserveTokens: 16384,
  keepRecentTokens: 20000
}

const defaultSandbox: SandboxConfig = {
  enabled: false,
  level: 'none',
  allowNetwork: false
}

const defaultContextFiles: ContextFilesConfig = {
  enabled: true,
  extraFiles: []
}

const defaultRetry: RetryConfig = {
  enabled: true,
  maxRetries: 3,
  baseDelayMs: 2000
}

const defaultApproval: ApprovalConfig = {
  bashWhitelist: ['go ', 'make ', 'git ', 'npm ', 'yarn ', 'node ', 'python ', 'pip '],
  bashBlacklist: []
}

export default function AdvancedSettings({ isOpen, onClose, settings, onSave }: AdvancedSettingsProps) {
  const [formData, setFormData] = useState<AdvancedSettingsData>(settings)
  const [hasChanges, setHasChanges] = useState(false)
  const [newExtraFile, setNewExtraFile] = useState('')
  const [newWhitelistItem, setNewWhitelistItem] = useState('')
  const [newBlacklistItem, setNewBlacklistItem] = useState('')
  const [newAllowedPath, setNewAllowedPath] = useState('')
  const [newDeniedPath, setNewDeniedPath] = useState('')
  const [newPassEnv, setNewPassEnv] = useState('')

  useEffect(() => {
    if (isOpen) {
      setFormData({
        ...settings,
        compaction: settings.compaction || defaultCompaction,
        sandbox: settings.sandbox || defaultSandbox,
        contextFiles: settings.contextFiles || defaultContextFiles,
        retry: settings.retry || defaultRetry,
        approval: settings.approval || defaultApproval
      })
      setHasChanges(false)
    }
  }, [isOpen, settings])

  const updateField = (path: string, value: any) => {
    const keys = path.split('.')
    const newData = { ...formData }
    let current: any = newData
    for (let i = 0; i < keys.length - 1; i++) {
      if (!current[keys[i]]) current[keys[i]] = {}
      current = current[keys[i]]
    }
    current[keys[keys.length - 1]] = value
    setFormData(newData)
    setHasChanges(true)
  }

  const handleSave = () => {
    onSave(formData)
    setHasChanges(false)
    onClose()
  }

  const addListItem = (field: string, value: string, setter: (v: string) => void) => {
    if (!value.trim()) return
    const keys = field.split('.')
    const newData = { ...formData }
    let current: any = newData
    for (let i = 0; i < keys.length - 1; i++) {
      if (!current[keys[i]]) current[keys[i]] = {}
      current = current[keys[i]]
    }
    const lastKey = keys[keys.length - 1]
    const arr = current[lastKey] || []
    current[lastKey] = [...arr, value.trim()]
    setFormData(newData)
    setHasChanges(true)
    setter('')
  }

  const removeListItem = (field: string, index: number) => {
    const keys = field.split('.')
    const newData = { ...formData }
    let current: any = newData
    for (let i = 0; i < keys.length - 1; i++) {
      if (!current[keys[i]]) current[keys[i]] = {}
      current = current[keys[i]]
    }
    const lastKey = keys[keys.length - 1]
    const arr = current[lastKey] || []
    current[lastKey] = arr.filter((_: any, i: number) => i !== index)
    setFormData(newData)
    setHasChanges(true)
  }

  if (!isOpen) return null

  const sandboxLevelOptions = [
    { value: 'none', label: 'None' },
    { value: 'standard', label: 'Standard' },
    { value: 'strict', label: 'Strict' }
  ]

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-[60] animate-fade-in">
      <div className="bg-secondary rounded-2xl w-full max-w-4xl max-h-[90vh] flex flex-col shadow-2xl animate-slide-up">
        {/* Header */}
        <div className="flex items-center justify-between p-5 border-b border-separator">
          <div>
            <h2 className="text-xl font-semibold text-text-primary">高级设置</h2>
            <p className="text-sm text-text-secondary mt-1">Advanced Settings</p>
          </div>
          <div className="flex items-center space-x-3">
            {hasChanges && (
              <button
                className="px-4 py-2 bg-accent hover:bg-accent/90 rounded-lg text-white text-sm font-medium transition-colors"
                onClick={handleSave}
              >
                保存
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
        <div className="flex-1 overflow-y-auto p-5 space-y-6">
          {/* Compaction */}
          <div className="bg-primary rounded-xl p-4">
            <h3 className="text-lg font-semibold text-text-primary mb-4">上下文压缩 (Compaction)</h3>
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <div className="text-text-primary">启用压缩</div>
                  <div className="text-xs text-text-secondary">管理长对话的上下文窗口</div>
                </div>
                <button
                  className={`w-12 h-6 rounded-full transition-colors ${
                    formData.compaction?.enabled ? 'bg-accent-green' : 'bg-tertiary'
                  }`}
                  onClick={() => updateField('compaction.enabled', !formData.compaction?.enabled)}
                >
                  <div className={`w-5 h-5 rounded-full bg-white transition-transform ${
                    formData.compaction?.enabled ? 'translate-x-6' : 'translate-x-0.5'
                  }`} />
                </button>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm text-text-secondary">保留 Token 数</label>
                  <input
                    type="number"
                    className="w-full bg-secondary text-text-primary rounded-lg px-3 py-2 border border-separator focus:border-accent outline-none text-sm mt-1"
                    value={formData.compaction?.reserveTokens || 16384}
                    onChange={e => updateField('compaction.reserveTokens', parseInt(e.target.value) || 0)}
                  />
                </div>
                <div>
                  <label className="text-sm text-text-secondary">保留最近消息 Token</label>
                  <input
                    type="number"
                    className="w-full bg-secondary text-text-primary rounded-lg px-3 py-2 border border-separator focus:border-accent outline-none text-sm mt-1"
                    value={formData.compaction?.keepRecentTokens || 20000}
                    onChange={e => updateField('compaction.keepRecentTokens', parseInt(e.target.value) || 0)}
                  />
                </div>
              </div>
            </div>
          </div>

          {/* Sandbox */}
          <div className="bg-primary rounded-xl p-4">
            <h3 className="text-lg font-semibold text-text-primary mb-4">沙箱 (Sandbox)</h3>
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <div className="text-text-primary">启用沙箱</div>
                  <div className="text-xs text-text-secondary">限制 bash 命令的访问权限</div>
                </div>
                <button
                  className={`w-12 h-6 rounded-full transition-colors ${
                    formData.sandbox?.enabled ? 'bg-accent-green' : 'bg-tertiary'
                  }`}
                  onClick={() => updateField('sandbox.enabled', !formData.sandbox?.enabled)}
                >
                  <div className={`w-5 h-5 rounded-full bg-white transition-transform ${
                    formData.sandbox?.enabled ? 'translate-x-6' : 'translate-x-0.5'
                  }`} />
                </button>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm text-text-secondary block mb-1">沙箱级别</label>
                  <CustomSelect
                    value={formData.sandbox?.level || 'none'}
                    onChange={value => updateField('sandbox.level', value)}
                    options={sandboxLevelOptions}
                    placeholder="Select level..."
                  />
                </div>
                <div>
                  <label className="text-sm text-text-secondary">临时目录大小</label>
                  <input
                    type="text"
                    className="w-full bg-secondary text-text-primary rounded-lg px-3 py-2 border border-separator focus:border-accent outline-none text-sm mt-1"
                    value={formData.sandbox?.tmpSize || '100m'}
                    onChange={e => updateField('sandbox.tmpSize', e.target.value)}
                    placeholder="100m"
                  />
                </div>
              </div>
              <div className="flex items-center justify-between">
                <div>
                  <div className="text-text-primary">允许网络访问</div>
                  <div className="text-xs text-text-secondary">沙箱内是否可以访问网络</div>
                </div>
                <button
                  className={`w-12 h-6 rounded-full transition-colors ${
                    formData.sandbox?.allowNetwork ? 'bg-accent-green' : 'bg-tertiary'
                  }`}
                  onClick={() => updateField('sandbox.allowNetwork', !formData.sandbox?.allowNetwork)}
                >
                  <div className={`w-5 h-5 rounded-full bg-white transition-transform ${
                    formData.sandbox?.allowNetwork ? 'translate-x-6' : 'translate-x-0.5'
                  }`} />
                </button>
              </div>

              {/* Allowed Read Paths */}
              <div>
                <label className="text-sm text-text-secondary mb-2 block">允许读取的路径</label>
                <div className="flex flex-wrap gap-2 mb-2">
                  {(formData.sandbox?.allowedRead || []).map((path, index) => (
                    <span key={index} className="bg-secondary text-text-primary text-xs px-2 py-1 rounded flex items-center">
                      {path}
                      <button
                        className="ml-1 text-accent-red hover:text-accent-red/90"
                        onClick={() => removeListItem('sandbox.allowedRead', index)}
                      >
                        ×
                      </button>
                    </span>
                  ))}
                </div>
                <div className="flex gap-2">
                  <input
                    type="text"
                    className="flex-1 bg-secondary text-text-primary rounded-lg px-3 py-1.5 border border-separator focus:border-accent outline-none text-sm"
                    value={newAllowedPath}
                    onChange={e => setNewAllowedPath(e.target.value)}
                    placeholder="/path/to/allow"
                    onKeyDown={e => {
                      if (e.key === 'Enter') {
                        addListItem('sandbox.allowedRead', newAllowedPath, setNewAllowedPath)
                      }
                    }}
                  />
                  <button
                    className="px-3 py-1.5 bg-accent-green hover:bg-accent-green/90 rounded-lg text-white text-sm"
                    onClick={() => addListItem('sandbox.allowedRead', newAllowedPath, setNewAllowedPath)}
                  >
                    添加
                  </button>
                </div>
              </div>

              {/* Denied Paths */}
              <div>
                <label className="text-sm text-text-secondary mb-2 block">拒绝的路径</label>
                <div className="flex flex-wrap gap-2 mb-2">
                  {(formData.sandbox?.deniedPaths || []).map((path, index) => (
                    <span key={index} className="bg-accent-red/20 text-accent-red text-xs px-2 py-1 rounded flex items-center">
                      {path}
                      <button
                        className="ml-1 text-accent-red hover:text-accent-red/90"
                        onClick={() => removeListItem('sandbox.deniedPaths', index)}
                      >
                        ×
                      </button>
                    </span>
                  ))}
                </div>
                <div className="flex gap-2">
                  <input
                    type="text"
                    className="flex-1 bg-secondary text-text-primary rounded-lg px-3 py-1.5 border border-separator focus:border-accent outline-none text-sm"
                    value={newDeniedPath}
                    onChange={e => setNewDeniedPath(e.target.value)}
                    placeholder="/path/to/deny"
                    onKeyDown={e => {
                      if (e.key === 'Enter') {
                        addListItem('sandbox.deniedPaths', newDeniedPath, setNewDeniedPath)
                      }
                    }}
                  />
                  <button
                    className="px-3 py-1.5 bg-accent-red hover:bg-accent-red/90 rounded-lg text-white text-sm"
                    onClick={() => addListItem('sandbox.deniedPaths', newDeniedPath, setNewDeniedPath)}
                  >
                    添加
                  </button>
                </div>
              </div>

              {/* Pass Env */}
              <div>
                <label className="text-sm text-text-secondary mb-2 block">传递的环境变量</label>
                <div className="flex flex-wrap gap-2 mb-2">
                  {(formData.sandbox?.passEnv || []).map((env, index) => (
                    <span key={index} className="bg-secondary text-text-primary text-xs px-2 py-1 rounded flex items-center">
                      {env}
                      <button
                        className="ml-1 text-accent-red hover:text-accent-red/90"
                        onClick={() => removeListItem('sandbox.passEnv', index)}
                      >
                        ×
                      </button>
                    </span>
                  ))}
                </div>
                <div className="flex gap-2">
                  <input
                    type="text"
                    className="flex-1 bg-secondary text-text-primary rounded-lg px-3 py-1.5 border border-separator focus:border-accent outline-none text-sm"
                    value={newPassEnv}
                    onChange={e => setNewPassEnv(e.target.value)}
                    placeholder="ENV_VAR"
                    onKeyDown={e => {
                      if (e.key === 'Enter') {
                        addListItem('sandbox.passEnv', newPassEnv, setNewPassEnv)
                      }
                    }}
                  />
                  <button
                    className="px-3 py-1.5 bg-accent hover:bg-accent/90 rounded-lg text-white text-sm"
                    onClick={() => addListItem('sandbox.passEnv', newPassEnv, setNewPassEnv)}
                  >
                    添加
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Context Files */}
          <div className="bg-primary rounded-xl p-4">
            <h3 className="text-lg font-semibold text-text-primary mb-4">上下文文件 (Context Files)</h3>
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <div className="text-text-primary">自动加载上下文文件</div>
                  <div className="text-xs text-text-secondary">自动搜索并加载 AGENTS.md、CLAUDE.md 等文件</div>
                </div>
                <button
                  className={`w-12 h-6 rounded-full transition-colors ${
                    formData.contextFiles?.enabled ? 'bg-accent-green' : 'bg-tertiary'
                  }`}
                  onClick={() => updateField('contextFiles.enabled', !formData.contextFiles?.enabled)}
                >
                  <div className={`w-5 h-5 rounded-full bg-white transition-transform ${
                    formData.contextFiles?.enabled ? 'translate-x-6' : 'translate-x-0.5'
                  }`} />
                </button>
              </div>
              <div>
                <label className="text-sm text-text-secondary mb-2 block">额外上下文文件</label>
                <div className="flex flex-wrap gap-2 mb-2">
                  {(formData.contextFiles?.extraFiles || []).map((file, index) => (
                    <span key={index} className="bg-secondary text-text-primary text-xs px-2 py-1 rounded flex items-center">
                      {file}
                      <button
                        className="ml-1 text-accent-red hover:text-accent-red/90"
                        onClick={() => removeListItem('contextFiles.extraFiles', index)}
                      >
                        ×
                      </button>
                    </span>
                  ))}
                </div>
                <div className="flex gap-2">
                  <input
                    type="text"
                    className="flex-1 bg-secondary text-text-primary rounded-lg px-3 py-1.5 border border-separator focus:border-accent outline-none text-sm"
                    value={newExtraFile}
                    onChange={e => setNewExtraFile(e.target.value)}
                    placeholder="/path/to/extra-context.md"
                    onKeyDown={e => {
                      if (e.key === 'Enter') {
                        addListItem('contextFiles.extraFiles', newExtraFile, setNewExtraFile)
                      }
                    }}
                  />
                  <button
                    className="px-3 py-1.5 bg-accent-green hover:bg-accent-green/90 rounded-lg text-white text-sm"
                    onClick={() => addListItem('contextFiles.extraFiles', newExtraFile, setNewExtraFile)}
                  >
                    添加
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Retry */}
          <div className="bg-primary rounded-xl p-4">
            <h3 className="text-lg font-semibold text-text-primary mb-4">重试 (Retry)</h3>
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <div className="text-text-primary">启用重试</div>
                  <div className="text-xs text-text-secondary">API 调用失败时自动重试</div>
                </div>
                <button
                  className={`w-12 h-6 rounded-full transition-colors ${
                    formData.retry?.enabled ? 'bg-accent-green' : 'bg-tertiary'
                  }`}
                  onClick={() => updateField('retry.enabled', !formData.retry?.enabled)}
                >
                  <div className={`w-5 h-5 rounded-full bg-white transition-transform ${
                    formData.retry?.enabled ? 'translate-x-6' : 'translate-x-0.5'
                  }`} />
                </button>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm text-text-secondary">最大重试次数</label>
                  <input
                    type="number"
                    className="w-full bg-secondary text-text-primary rounded-lg px-3 py-2 border border-separator focus:border-accent outline-none text-sm mt-1"
                    value={formData.retry?.maxRetries || 3}
                    onChange={e => updateField('retry.maxRetries', parseInt(e.target.value) || 0)}
                  />
                </div>
                <div>
                  <label className="text-sm text-text-secondary">基础延迟 (毫秒)</label>
                  <input
                    type="number"
                    className="w-full bg-secondary text-text-primary rounded-lg px-3 py-2 border border-separator focus:border-accent outline-none text-sm mt-1"
                    value={formData.retry?.baseDelayMs || 2000}
                    onChange={e => updateField('retry.baseDelayMs', parseInt(e.target.value) || 0)}
                  />
                </div>
              </div>
            </div>
          </div>

          {/* Approval */}
          <div className="bg-primary rounded-xl p-4">
            <h3 className="text-lg font-semibold text-text-primary mb-4">审批 (Approval)</h3>
            <div className="space-y-4">
              <div>
                <label className="text-sm text-text-secondary mb-2 block">Bash 白名单 (自动批准的命令)</label>
                <div className="flex flex-wrap gap-2 mb-2">
                  {(formData.approval?.bashWhitelist || []).map((cmd, index) => (
                    <span key={index} className="bg-accent-green/20 text-accent-green text-xs px-2 py-1 rounded flex items-center">
                      {cmd}
                      <button
                        className="ml-1 text-accent-red hover:text-accent-red/90"
                        onClick={() => removeListItem('approval.bashWhitelist', index)}
                      >
                        ×
                      </button>
                    </span>
                  ))}
                </div>
                <div className="flex gap-2">
                  <input
                    type="text"
                    className="flex-1 bg-secondary text-text-primary rounded-lg px-3 py-1.5 border border-separator focus:border-accent outline-none text-sm"
                    value={newWhitelistItem}
                    onChange={e => setNewWhitelistItem(e.target.value)}
                    placeholder="git "
                    onKeyDown={e => {
                      if (e.key === 'Enter') {
                        addListItem('approval.bashWhitelist', newWhitelistItem, setNewWhitelistItem)
                      }
                    }}
                  />
                  <button
                    className="px-3 py-1.5 bg-accent-green hover:bg-accent-green/90 rounded-lg text-white text-sm"
                    onClick={() => addListItem('approval.bashWhitelist', newWhitelistItem, setNewWhitelistItem)}
                  >
                    添加
                  </button>
                </div>
              </div>
              <div>
                <label className="text-sm text-text-secondary mb-2 block">Bash 黑名单 (始终需要审批)</label>
                <div className="flex flex-wrap gap-2 mb-2">
                  {(formData.approval?.bashBlacklist || []).map((cmd, index) => (
                    <span key={index} className="bg-accent-red/20 text-accent-red text-xs px-2 py-1 rounded flex items-center">
                      {cmd}
                      <button
                        className="ml-1 text-accent-red hover:text-accent-red/90"
                        onClick={() => removeListItem('approval.bashBlacklist', index)}
                      >
                        ×
                      </button>
                    </span>
                  ))}
                </div>
                <div className="flex gap-2">
                  <input
                    type="text"
                    className="flex-1 bg-secondary text-text-primary rounded-lg px-3 py-1.5 border border-separator focus:border-accent outline-none text-sm"
                    value={newBlacklistItem}
                    onChange={e => setNewBlacklistItem(e.target.value)}
                    placeholder="rm -rf"
                    onKeyDown={e => {
                      if (e.key === 'Enter') {
                        addListItem('approval.bashBlacklist', newBlacklistItem, setNewBlacklistItem)
                      }
                    }}
                  />
                  <button
                    className="px-3 py-1.5 bg-accent-red hover:bg-accent-red/90 rounded-lg text-white text-sm"
                    onClick={() => addListItem('approval.bashBlacklist', newBlacklistItem, setNewBlacklistItem)}
                  >
                    添加
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Paths and Shell */}
          <div className="bg-primary rounded-xl p-4">
            <h3 className="text-lg font-semibold text-text-primary mb-4">路径与 Shell</h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm text-text-secondary">技能目录</label>
                <input
                  type="text"
                  className="w-full bg-secondary text-text-primary rounded-lg px-3 py-2 border border-separator focus:border-accent outline-none text-sm mt-1"
                  value={formData.skillsDir || ''}
                  onChange={e => updateField('skillsDir', e.target.value)}
                  placeholder="~/.vibecoding/skills"
                />
              </div>
              <div>
                <label className="text-sm text-text-secondary">会话目录</label>
                <input
                  type="text"
                  className="w-full bg-secondary text-text-primary rounded-lg px-3 py-2 border border-separator focus:border-accent outline-none text-sm mt-1"
                  value={formData.sessionDir || ''}
                  onChange={e => updateField('sessionDir', e.target.value)}
                  placeholder="~/.vibecoding/sessions"
                />
              </div>
              <div>
                <label className="text-sm text-text-secondary">Shell 路径</label>
                <input
                  type="text"
                  className="w-full bg-secondary text-text-primary rounded-lg px-3 py-2 border border-separator focus:border-accent outline-none text-sm mt-1"
                  value={formData.shellPath || ''}
                  onChange={e => updateField('shellPath', e.target.value)}
                  placeholder="/bin/bash"
                />
              </div>
              <div>
                <label className="text-sm text-text-secondary">命令前缀</label>
                <input
                  type="text"
                  className="w-full bg-secondary text-text-primary rounded-lg px-3 py-2 border border-separator focus:border-accent outline-none text-sm mt-1"
                  value={formData.shellCommandPrefix || ''}
                  onChange={e => updateField('shellCommandPrefix', e.target.value)}
                  placeholder=""
                />
              </div>
            </div>
          </div>

          {/* Token Limits */}
          <div className="bg-primary rounded-xl p-4">
            <h3 className="text-lg font-semibold text-text-primary mb-4">Token 限制</h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm text-text-secondary">最大输出 Token</label>
                <input
                  type="number"
                  className="w-full bg-secondary text-text-primary rounded-lg px-3 py-2 border border-separator focus:border-accent outline-none text-sm mt-1"
                  value={formData.maxOutputTokens || 384000}
                  onChange={e => updateField('maxOutputTokens', parseInt(e.target.value) || 0)}
                />
              </div>
              <div>
                <label className="text-sm text-text-secondary">最大上下文 Token</label>
                <input
                  type="number"
                  className="w-full bg-secondary text-text-primary rounded-lg px-3 py-2 border border-separator focus:border-accent outline-none text-sm mt-1"
                  value={formData.maxContextTokens || 1000000}
                  onChange={e => updateField('maxContextTokens', parseInt(e.target.value) || 0)}
                />
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="flex justify-between items-center p-5 border-t border-separator">
          <div className="text-sm text-text-secondary">
            {hasChanges && <span className="text-accent-orange">⚠️ 有未保存的更改</span>}
          </div>
          <div className="flex space-x-3">
            <button
              className="px-4 py-2.5 bg-tertiary hover:bg-elevated rounded-xl text-text-primary font-medium transition-colors"
              onClick={onClose}
            >
              取消
            </button>
            {hasChanges && (
              <button
                className="px-4 py-2.5 bg-accent hover:bg-accent/90 rounded-xl text-white font-medium transition-colors"
                onClick={handleSave}
              >
                保存
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

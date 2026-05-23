# 真实的设置功能 - 读取 ~/.vibecoding/settings.json

## 概述

设置功能现在会**读取真实的配置文件** `~/.vibecoding/settings.json`，而不是使用硬编码的选项。

## 功能特性

### 1. 读取真实配置

设置界面会从 `~/.vibecoding/settings.json` 读取：

- **Providers**: 所有配置的 AI 提供商
- **Models**: 每个 Provider 下的可用模型
- **Default Provider**: 默认提供商
- **Default Model**: 默认模型
- **Default Mode**: 默认模式
- **Default Thinking Level**: 默认思考级别

### 2. 配置文件结构

```json
{
  "providers": {
    "xiaomi": {
      "apiKey": "sk-...",
      "baseUrl": "https://api.xiaomimimo.com/anthropic",
      "api": "anthropic-messages",
      "models": [
        {
          "id": "mimo-v2.5-pro",
          "name": "mimo-v2.5-pro",
          "contextWindow": 1000000,
          "maxTokens": 65535
        }
      ]
    },
    "xiaomi2": {
      "apiKey": "tp-...",
      "baseUrl": "https://token-plan-cn.xiaomimimo.com/v1",
      "api": "openai-chat",
      "models": [...]
    },
    "baidu": {
      "apiKey": "bce-v3/...",
      "baseUrl": "https://qianfan.baidubce.com/anthropic/coding",
      "api": "anthropic-messages",
      "models": [...]
    }
  },
  "defaultProvider": "xiaomi",
  "defaultModel": "mimo-v2.5-pro",
  "defaultThinkingLevel": "medium",
  "defaultMode": "agent"
}
```

### 3. 设置界面显示

- **Provider 列表**: 显示所有配置的 Provider，包含 API 类型
- **Model 列表**: 显示选中 Provider 下的所有模型，包含上下文窗口和最大 token 数
- **Mode 选择**: Plan, Agent, YOLO
- **Thinking Level**: Off, Minimal, Low, Medium, High, XHigh

## 使用方法

### 1. 打开设置界面

点击侧边栏底部的 "⚙️ Settings" 按钮。

### 2. 查看配置

设置界面会显示：
- 当前 Provider 和 API 类型
- 所有可用的 Model，包含上下文窗口信息
- 当前 Mode 和 Thinking Level

### 3. 修改配置

1. **选择 Provider**: 点击相应的 Provider 按钮
2. **选择 Model**: 点击相应的 Model 按钮
3. **选择 Mode**: 点击相应的 Mode 按钮
4. **选择 Thinking Level**: 点击相应的 Thinking Level 按钮

### 4. 保存配置

点击 "Save & Restart" 按钮保存配置。

**注意**: 修改配置会重启 AI session，当前对话历史将丢失。

## 技术实现

### 后端

```go
// LoadVibeCodingSettings loads settings from ~/.vibecoding/settings.json
func LoadVibeCodingSettings() (*VibeCodingSettings, error) {
    home, _ := os.UserHomeDir()
    settingsPath := filepath.Join(home, ".vibecoding", "settings.json")
    data, _ := os.ReadFile(settingsPath)
    
    var settings VibeCodingSettings
    json.Unmarshal(data, &settings)
    
    return &settings, nil
}

// GetProviders returns list of available providers
func (s *VibeCodingSettings) GetProviders() []map[string]string {
    providers := make([]map[string]string, 0, len(s.Providers))
    for id, p := range s.Providers {
        providers = append(providers, map[string]string{
            "id":   id,
            "name": id,
            "api":  p.API,
        })
    }
    return providers
}

// GetModels returns list of available models for a provider
func (s *VibeCodingSettings) GetModels(providerID string) []map[string]interface{} {
    p, ok := s.Providers[providerID]
    if !ok {
        return nil
    }
    
    models := make([]map[string]interface{}, 0, len(p.Models))
    for _, m := range p.Models {
        models = append(models, map[string]interface{}{
            "id":            m.ID,
            "name":          m.Name,
            "contextWindow": m.ContextWindow,
            "maxTokens":     m.MaxTokens,
        })
    }
    return models
}
```

### 前端

```typescript
const loadProviders = async () => {
    const p = await GetProviders()
    setProviders(p as unknown as Provider[])
}

const loadModels = async (providerID: string) => {
    const m = await GetModels(providerID)
    setModels(m as unknown as Model[])
}
```

## 注意事项

1. **配置文件必须存在**: 确保 `~/.vibecoding/settings.json` 文件存在
2. **Provider 必须有效**: 确保选择的 Provider 在配置文件中存在
3. **Model 必须有效**: 确保选择的 Model 在 Provider 下存在
4. **配置更新会重启 ACP 客户端**: 保存配置时，当前的 ACP 连接会断开并重新建立
5. **Session 会丢失**: 配置更新会创建新的 session，当前对话历史会丢失

## 调试

查看 stderr 输出获取配置加载信息：

```bash
./build/bin/vibecoding-gui 2>&1 | grep -E "Settings|Provider|Model"
```

## 下一步

1. 添加配置文件编辑功能
2. 添加配置验证
3. 添加配置导入/导出
4. 优化配置更新体验（不丢失对话历史）

# VibeCoding 集成指南

本文档说明如何将 VibeCoding 的核心功能集成到 GUI 客户端中。

## 集成架构

```
┌─────────────────────────────────────────────────────────────┐
│                      GUI Frontend                           │
│  (React + TypeScript + Tailwind CSS)                        │
└─────────────────────┬───────────────────────────────────────┘
                      │ Wails Bindings
┌─────────────────────▼───────────────────────────────────────┐
│                      GUI Backend                            │
│  (Go + Wails)                                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Agent     │  │   Config    │  │   Session   │         │
│  │   Manager   │  │   Manager   │  │   Manager   │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
└─────────┼────────────────┼────────────────┼─────────────────┘
          │                │                │
┌─────────▼────────────────▼────────────────▼─────────────────┐
│                 VibeCoding Core Packages                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  internal/  │  │  internal/  │  │  internal/  │         │
│  │   agent     │  │   config    │  │   session   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

## 步骤 1: 更新 go.mod

```go
module github.com/startvibecoding/prader/vibecoding-gui

go 1.21.0

require (
    github.com/startvibecoding/vibecoding v0.1.17
    github.com/wailsapp/wails/v2 v2.10.1
)
```

然后运行：
```bash
go mod tidy
```

## 步骤 2: 创建 VibeCoding 客户端封装

创建 `internal/vibecoding/client.go`:

```go
package vibecoding

import (
    "context"
    "sync"

    "github.com/startvibecoding/vibecoding/internal/agent"
    "github.com/startvibecoding/vibecoding/internal/config"
    "github.com/startvibecoding/vibecoding/internal/provider"
    "github.com/startvibecoding/vibecoding/internal/session"
)

type Client struct {
    settings *config.Settings
    session  *session.Manager
    mu       sync.RWMutex
}

func NewClient() (*Client, error) {
    // Load settings
    settings, err := config.Load()
    if err != nil {
        return nil, err
    }

    // Initialize session manager
    sessionMgr, err := session.NewManager(settings.SessionDir)
    if err != nil {
        return nil, err
    }

    return &Client{
        settings: settings,
        session:  sessionMgr,
    }, nil
}

func (c *Client) GetSettings() *config.Settings {
    c.mu.RLock()
    defer c.mu.RUnlock()
    return c.settings
}

func (c *Client) GetProviders() []string {
    providers := make([]string, 0, len(c.settings.Providers))
    for name := range c.settings.Providers {
        providers = append(providers, name)
    }
    return providers
}

func (c *Client) GetModels(providerName string) []string {
    p, ok := c.settings.Providers[providerName]
    if !ok {
        return nil
    }
    models := make([]string, 0, len(p.Models))
    for _, m := range p.Models {
        models = append(models, m.ID)
    }
    return models
}

func (c *Client) CreateSession() (string, error) {
    return c.session.Create()
}

func (c *Client) GetSessions() ([]session.Entry, error) {
    return c.session.List()
}
```

## 步骤 3: 创建 Agent 管理器

创建 `internal/vibecoding/agent.go`:

```go
package vibecoding

import (
    "context"
    "fmt"

    "github.com/startvibecoding/vibecoding/internal/agent"
    "github.com/startvibecoding/vibecoding/internal/provider"
)

type AgentManager struct {
    client  *Client
    agents  map[string]*agent.Agent
}

func NewAgentManager(client *Client) *AgentManager {
    return &AgentManager{
        client: client,
        agents: make(map[string]*agent.Agent),
    }
}

func (am *AgentManager) Chat(ctx context.Context, sessionID, message string) (<-chan agent.Event, error) {
    // Get or create agent for session
    a, ok := am.agents[sessionID]
    if !ok {
        // Create new agent
        settings := am.client.GetSettings()
        
        // Get provider
        p, err := provider.Get(settings.DefaultProvider)
        if err != nil {
            return nil, err
        }

        // Get model
        model := p.GetModel(settings.DefaultModel)
        if model == nil {
            return nil, fmt.Errorf("model not found: %s", settings.DefaultModel)
        }

        // Create agent config
        cfg := agent.Config{
            Provider: p,
            Model:    model,
            Mode:     settings.DefaultMode,
            Settings: settings,
            Session:  am.client.session,
        }

        a = agent.New(cfg)
        am.agents[sessionID] = a
    }

    // Send message and get event channel
    return a.Chat(ctx, message)
}
```

## 步骤 4: 更新 App 绑定

更新 `app.go`:

```go
package main

import (
    "context"
    "fmt"

    vibecoding "github.com/startvibecoding/prader/vibecoding-gui/internal/vibecoding"
    "github.com/wailsapp/wails/v2/pkg/runtime"
)

type App struct {
    ctx     context.Context
    client  *vibecoding.Client
    agent   *vibecoding.AgentManager
}

func NewApp() (*App, error) {
    client, err := vibecoding.NewClient()
    if err != nil {
        return nil, err
    }

    return &App{
        client: client,
        agent:  vibecoding.NewAgentManager(client),
    }, nil
}

func (a *App) startup(ctx context.Context) {
    a.ctx = ctx
}

func (a *App) GetSettings() (map[string]interface{}, error) {
    settings := a.client.GetSettings()
    return map[string]interface{}{
        "defaultProvider": settings.DefaultProvider,
        "defaultModel":    settings.DefaultModel,
        "defaultMode":     settings.DefaultMode,
    }, nil
}

func (a *App) GetProviders() ([]string, error) {
    return a.client.GetProviders(), nil
}

func (a *App) GetModels(provider string) ([]string, error) {
    return a.client.GetModels(provider), nil
}

func (a *App) SendMessage(sessionID, message string) error {
    events, err := a.agent.Chat(a.ctx, sessionID, message)
    if err != nil {
        return err
    }

    // Process events in background
    go func() {
        for event := range events {
            // Emit event to frontend
            runtime.EventsEmit(a.ctx, "chat:event", event)
        }
    }()

    return nil
}
```

## 步骤 5: 更新前端事件处理

更新 `App.tsx`:

```typescript
import { EventsOn } from '../wailsjs/runtime/runtime'

useEffect(() => {
    // Listen for chat events
    const unsubscribe = EventsOn('chat:event', (event: any) => {
        switch (event.type) {
            case 'text':
                appendToLastMessage(event.content)
                break
            case 'tool_call':
                showToolCall(event)
                break
            case 'tool_result':
                showToolResult(event)
                break
            case 'error':
                showError(event.message)
                break
            case 'done':
                setIsLoading(false)
                break
        }
    })

    return () => unsubscribe()
}, [])
```

## 步骤 6: 实现流式响应

在 `ChatArea.tsx` 中:

```typescript
const [streamingContent, setStreamingContent] = useState('')

useEffect(() => {
    const unsubscribe = EventsOn('chat:stream', (chunk: string) => {
        setStreamingContent(prev => prev + chunk)
    })

    return () => unsubscribe()
}, [])

// In render:
{streamingContent && (
    <div className="markdown-body">
        <ReactMarkdown>{streamingContent}</ReactMarkdown>
    </div>
)}
```

## 步骤 7: 实现工具调用审批

创建 `ToolApproval.tsx`:

```typescript
interface ToolApprovalProps {
    toolName: string
    args: any
    onApprove: () => void
    onReject: () => void
}

export default function ToolApproval({ toolName, args, onApprove, onReject }: ToolApprovalProps) {
    return (
        <div className="bg-yellow-900/30 border border-yellow-700 rounded-lg p-4 mb-4">
            <h4 className="font-semibold text-yellow-200 mb-2">Tool Call Approval</h4>
            <p className="text-gray-300 mb-2">Tool: <code>{toolName}</code></p>
            <pre className="bg-gray-800 p-3 rounded text-sm overflow-x-auto">
                {JSON.stringify(args, null, 2)}
            </pre>
            <div className="flex space-x-3 mt-4">
                <button
                    className="px-4 py-2 bg-green-600 hover:bg-green-700 rounded"
                    onClick={onApprove}
                >
                    Approve
                </button>
                <button
                    className="px-4 py-2 bg-red-600 hover:bg-red-700 rounded"
                    onClick={onReject}
                >
                    Reject
                </button>
            </div>
        </div>
    )
}
```

## 下一步

1. 运行 `go mod tidy` 解析依赖
2. 测试基础功能
3. 实现流式响应
4. 实现工具调用审批
5. 优化 UI/UX

## 注意事项

1. **并发安全**: 使用 mutex 保护共享状态
2. **错误处理**: 所有错误都应该传递给前端显示
3. **资源清理**: 在 shutdown 时清理资源
4. **配置热重载**: 监听配置文件变化

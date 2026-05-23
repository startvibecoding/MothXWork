# AGENTS.md - VibeCoding GUI

## 项目概述

VibeCoding GUI 是一个基于 Wails 框架的桌面应用程序，为 VibeCoding CLI 提供图形用户界面。它通过 ACP（Agent Communication Protocol）协议与 VibeCoding 后端通信，实现 AI 编程助手的可视化交互。

## 技术栈

### 后端
- **语言**: Go 1.22+
- **框架**: Wails v2.10.1
- **通信协议**: ACP (JSON-RPC over stdin/stdout)

### 前端
- **框架**: React 18 + TypeScript
- **构建工具**: Vite
- **样式**: Tailwind CSS
- **Markdown**: react-markdown + remark-gfm
- **代码高亮**: react-syntax-highlighter

## 项目结构

```
vibecoding-gui/
├── main.go                    # Wails 入口点
├── app.go                     # 应用逻辑，暴露给前端的方法
├── wails.json                 # Wails 配置
├── go.mod                     # Go 模块定义
├── Makefile                   # 构建脚本
├── internal/
│   └── vibecoding/
│       ├── acp_client.go      # ACP 协议客户端实现
│       ├── agent.go           # Agent 管理器
│       └── settings.go        # 配置管理
└── frontend/
    ├── src/
    │   ├── App.tsx            # 主 React 组件
    │   ├── components/        # UI 组件
    │   │   ├── ChatArea.tsx   # 聊天区域
    │   │   ├── InputArea.tsx  # 输入区域
    │   │   ├── Sidebar.tsx    # 侧边栏（会话管理）
    │   │   ├── StatusBar.tsx  # 状态栏
    │   │   ├── GlobalSettings.tsx  # 全局设置
    │   │   └── SessionSettings.tsx # 会话设置
    │   └── index.css          # 全局样式
    ├── package.json
    └── wailsjs/               # Wails 自动生成的绑定
```

## 核心架构

### 1. Go 后端架构

**ACPClient** (`internal/vibecoding/acp_client.go`)
- 管理与 VibeCoding CLI 的 ACP 通信
- 使用 JSON-RPC 2.0 协议通过 stdin/stdout 通信
- 支持异步事件流（session/update 通知）
- 主要方法：`Initialize()`, `NewSession()`, `Prompt()`, `Cancel()`

**AgentManager** (`internal/vibecoding/agent.go`)
- 封装 ACPClient，提供高级 API
- 管理会话生命周期
- 处理聊天事件流
- 主要方法：`CreateSession()`, `Chat()`, `Abort()`

**App** (`app.go`)
- Wails 应用入口，暴露方法给前端
- 处理前端调用和事件发射
- 主要暴露方法：`CreateSession()`, `SendMessage()`, `Abort()`, `GetConfig()`, `UpdateConfig()`

### 2. 前端架构

**App.tsx**
- 主组件，管理全局状态
- 处理 Wails 事件监听
- 协调各子组件

**状态管理**
- 使用 React useState 管理本地状态
- 通过 Wails EventsOn 监听后端事件
- 主要状态：messages, sessions, config, isLoading

**事件流**
- 前端通过 `SendMessage()` 发送消息
- 后端通过 `runtime.EventsEmit()` 发送事件
- 前端通过 `EventsOn('chat:event')` 接收事件
- 事件类型：content, toolCall, toolCallUpdate, done, error

## 开发指南

### 环境要求
- Go 1.21+
- Node.js 18+
- Wails CLI v2.10+

### 开发命令

```bash
# 安装依赖
make setup
# 或
cd frontend && npm install

# 开发模式（热重载）
make dev
# 或
wails dev

# 构建
make build
# 或
wails build

# 运行
make run
# 或
./build/bin/vibecoding-gui
```

### 添加新功能

#### 添加新的 Go 方法暴露给前端

1. 在 `app.go` 中添加方法：
```go
func (a *App) MyNewMethod(param string) (string, error) {
    // 实现逻辑
    return result, nil
}
```

2. 在前端调用：
```typescript
import { MyNewMethod } from '../wailsjs/go/main/App'

const result = await MyNewMethod('param')
```

#### 添加新的前端组件

1. 在 `frontend/src/components/` 创建新组件
2. 在 `App.tsx` 中导入并使用
3. 使用 Tailwind CSS 进行样式设计

#### 修改 ACP 通信

1. 在 `internal/vibecoding/acp_client.go` 中添加新的 RPC 方法
2. 在 `agent.go` 中封装高级 API
3. 在 `app.go` 中暴露给前端

### 调试技巧

1. **Go 后端调试**
   - 使用 `fmt.Fprintf(os.Stderr, ...)` 输出调试信息
   - ACP 原始消息会打印到 stderr（标记为 `[ACP RAW]` 和 `[ACP EVENT]`）

2. **前端调试**
   - 使用 `console.log()` 输出调试信息
   - 检查浏览器开发者工具的控制台
   - Wails 开发模式支持热重载

3. **ACP 通信调试**
   - 检查 stderr 输出的 ACP 消息
   - 验证 JSON-RPC 请求/响应格式

## 配置管理

### 全局配置
配置文件位置：`~/.vibecoding/settings.json`

```json
{
  "providers": {
    "provider-id": {
      "apiKey": "your-api-key",
      "baseUrl": "https://api.example.com",
      "api": "openai",
      "models": [
        {
          "id": "model-id",
          "name": "Model Name",
          "contextWindow": 128000,
          "maxTokens": 4096
        }
      ]
    }
  },
  "defaultProvider": "deepseek-openai",
  "defaultModel": "deepseek-v4-flash",
  "defaultThinkingLevel": "medium",
  "defaultMode": "agent"
}
```

### 会话配置
会话配置在创建会话时传递，包括：
- `cwd`: 工作目录
- `provider`: 提供商 ID
- `model`: 模型 ID
- `mode`: 模式（plan/agent/yolo）
- `thinking`: 思考级别（low/medium/high）

## 常见任务

### 1. 添加新的 LLM 提供商

1. 在 `~/.vibecoding/settings.json` 中添加提供商配置
2. 确保 ACP 客户端支持该提供商的 API 格式
3. 前端会自动从配置中读取可用提供商

### 2. 修改 UI 样式

1. 编辑对应的组件文件（如 `ChatArea.tsx`）
2. 使用 Tailwind CSS 类名
3. 全局样式在 `frontend/src/index.css`

### 3. 添加新的事件类型

1. 在 `acp_client.go` 的 `handleNotification()` 中添加处理
2. 在 `agent.go` 的 `Chat()` 中转发事件
3. 在 `App.tsx` 的 `handleChatEvent()` 中处理

### 4. 修改会话管理

1. 后端：修改 `agent.go` 中的会话管理逻辑
2. 前端：修改 `App.tsx` 中的 sessions 状态管理
3. UI：修改 `Sidebar.tsx` 组件

## 注意事项

1. **线程安全**
   - Go 后端使用 `sync.RWMutex` 保护共享状态
   - 前端事件处理是异步的，注意状态更新时机

2. **错误处理**
   - Go 方法返回 error，前端需要 try-catch 处理
   - ACP 错误会通过事件流传递到前端

3. **资源清理**
   - 组件卸载时需要取消事件监听
   - 应用关闭时需要关闭 ACP 客户端

4. **性能考虑**
   - 事件通道有缓冲区（100），满时会丢弃事件
   - 大量消息时考虑虚拟滚动优化

5. **安全性**
   - API 密钥存储在本地配置文件中
   - ACP 通信通过本地进程 stdin/stdout，无网络暴露

## 构建和发布

### 开发构建
```bash
wails build -dev
```

### 生产构建
```bash
wails build
```

### 交叉编译
```bash
# Windows
wails build -platform windows/amd64

# macOS
wails build -platform darwin/universal

# Linux
wails build -platform linux/amd64
```

## 相关资源

- [Wails 官方文档](https://wails.io/docs)
- [ACP 协议规范](https://github.com/anthropics/agent-communication-protocol)
- [VibeCoding 项目](https://github.com/startvibecoding/prader)

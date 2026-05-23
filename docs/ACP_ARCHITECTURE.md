# VibeCoding GUI - ACP 方案实现

## 架构概述

使用 ACP (Agent Client Protocol) 协议通过 stdin/stdout 与 VibeCoding 通信，避免直接导入 internal 包。

```
┌─────────────────────────────────────────────────────────────┐
│                      GUI Frontend                           │
│  (React + TypeScript + Tailwind CSS)                        │
└─────────────────────┬───────────────────────────────────────┘
                      │ Wails Bindings
┌─────────────────────▼───────────────────────────────────────┐
│                      GUI Backend                            │
│  (Go + Wails)                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              ACP Client                              │   │
│  │  - JSON-RPC over stdin/stdout                        │   │
│  │  - Session management                                │   │
│  │  - Event streaming                                   │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────┬───────────────────────────────────────┘
                      │ stdin/stdout (JSON-RPC)
┌─────────────────────▼───────────────────────────────────────┐
│                 VibeCoding Binary                            │
│  - ACP mode (--acp)                                         │
│  - Agent loop                                               │
│  - Provider integration                                     │
│  - Tool execution                                           │
└─────────────────────────────────────────────────────────────┘
```

## 优势

1. **无依赖污染** - GUI 项目独立，不修改 VibeCoding 代码
2. **版本独立** - 可以独立更新 VibeCoding 和 GUI
3. **语言无关** - 理论上可以用任何语言实现 GUI
4. **进程隔离** - VibeCoding 崩溃不会影响 GUI

## ACP 协议

### 初始化
```json
→ {"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":1,"clientInfo":{"name":"VibeCoding GUI","version":"1.0.0"}}}
← {"jsonrpc":"2.0","id":1,"result":{"protocolVersion":1,"agentCapabilities":{...},"agentInfo":{"name":"VibeCoding","version":"0.1.17"}}}
```

### 创建会话
```json
→ {"jsonrpc":"2.0","id":2,"method":"session/new","params":{"cwd":"/path/to/project"}}
← {"jsonrpc":"2.0","id":2,"result":{"sessionId":"session-123"}}
```

### 发送提示
```json
→ {"jsonrpc":"2.0","id":3,"method":"session/prompt","params":{"sessionId":"session-123","prompt":[{"type":"text","text":"Hello"}]}}
← {"jsonrpc":"2.0","id":3,"result":{"stopReason":"stop"}}
```

### 会话更新（通知）
```json
← {"jsonrpc":"2.0","method":"session/update","params":{"sessionUpdate":"content","content":{"type":"text","text":"Hello, how can I help?"}}}
← {"jsonrpc":"2.0","method":"session/update","params":{"sessionUpdate":"toolCall","toolCallId":"tc-123","title":"bash: ls -la","kind":"bash","status":"running"}}
← {"jsonrpc":"2.0","method":"session/update","params":{"sessionUpdate":"toolResult","toolCallId":"tc-123","rawOutput":{"content":"file1.txt\nfile2.txt"}}}
```

## 项目结构

```
vibecoding-gui/
├── main.go                     # Wails 入口
├── app.go                      # 应用逻辑
├── internal/
│   └── vibecoding/
│       ├── acp_client.go       # ACP 客户端实现
│       └── agent.go            # Agent 管理器
└── frontend/
    └── src/
        ├── App.tsx             # 主组件
        └── components/
            ├── ChatArea.tsx    # 聊天区域
            └── InputArea.tsx   # 输入区域
```

## 使用方法

### 1. 构建 VibeCoding
```bash
cd vibecoding
make build
```

### 2. 构建 GUI
```bash
cd prader/vibecoding-gui
wails build
```

### 3. 运行
```bash
./build/bin/vibecoding-gui
```

## 配置

GUI 会自动查找 VibeCoding 二进制文件：
1. 当前目录的 `vibecoding` 子目录
2. `/usr/local/bin/vibecoding`
3. `~/.local/bin/vibecoding`
4. `~/go/bin/vibecoding`
5. PATH 环境变量

## 下一步

1. 完善事件处理
2. 添加会话管理 UI
3. 添加设置界面
4. 添加文件选择支持
5. 优化错误处理

## 技术细节

### JSON-RPC 请求/响应
- 请求: `{"jsonrpc":"2.0","id":1,"method":"...","params":{...}}`
- 响应: `{"jsonrpc":"2.0","id":1,"result":{...}}` 或 `{"jsonrpc":"2.0","id":1,"error":{"code":-1,"message":"..."}}`
- 通知: `{"jsonrpc":"2.0","method":"...","params":{...}}`

### 事件类型
- `content` - 文本内容更新
- `toolCall` - 工具调用开始
- `toolResult` - 工具调用结果
- `done` - 完成
- `error` - 错误

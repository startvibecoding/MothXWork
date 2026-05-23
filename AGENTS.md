# AGENTS.md - VibeCoding GUI

## 概述

Wails v2 + React + TypeScript 构建的 VibeCoding GUI 客户端，通过 ACP 协议与 VibeCoding 通信。

## 技术栈

- **后端**: Go + Wails v2
- **前端**: React 18 + TypeScript + Tailwind CSS
- **通信**: ACP (JSON-RPC over stdin/stdout)

## 项目结构

```
├── main.go                     # Wails 入口
├── app.go                      # 暴露给前端的方法
├── internal/vibecoding/
│   ├── acp_client.go           # ACP 协议客户端
│   ├── agent.go                # Agent 管理器
│   └── settings.go             # 配置加载
└── frontend/src/
    ├── App.tsx                  # 主组件
    └── components/              # UI 组件
```

## 核心架构

### 后端

- **ACPClient**: 管理与 VibeCoding 的 ACP 通信
- **AgentManager**: 封装 ACPClient，提供高级 API
- **App**: Wails 入口，暴露方法给前端

### 前端

- **App.tsx**: 主组件，管理全局状态
- **EventsOn('chat:event')**: 监听后端事件
- 事件类型: `content`, `tool_call`, `toolCallUpdate`, `permission_request`, `done`, `error`

## 开发命令

```bash
wails dev          # 开发模式
wails build        # 构建
./build/bin/vibecoding-gui  # 运行
```

## 添加新方法

1. 在 `app.go` 添加方法
2. 前端调用: `import { MyMethod } from '../wailsjs/go/main/App'`

## 配置

- 全局配置: `~/.vibecoding/settings.json`
- 会话配置: `~/.vibecoding-gui/sessions.json`

## 调试

- Go: `fmt.Fprintf(os.Stderr, ...)`
- 前端: `console.log()`
- ACP 消息自动打印到 stderr

## 注意事项

- 使用 `sync.RWMutex` 保护共享状态
- 事件通道缓冲区 100，满时丢弃
- 组件卸载时取消事件监听
- API 密钥存储在本地配置文件

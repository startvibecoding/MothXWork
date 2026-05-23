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
├── build/
│   ├── appicon.png             # 应用图标 (VibeCoding logo)
│   └── windows/icon.ico        # Windows 图标
└── frontend/src/
    ├── App.tsx                  # 主组件
    └── components/              # UI 组件
```

## 核心架构

### 后端

- **ACPClient**: 管理与 VibeCoding 的 ACP 通信
- **AgentManager**: 封装 ACPClient，提供高级 API
  - `CreateSession()`: 创建新 session (使用当前目录)
  - `CreateSessionWithCwd(cwd)`: 创建新 session (指定目录)
- **App**: Wails 入口，暴露方法给前端
  - `CreateSession()`: 创建新 session
  - `RestoreSession(cwd)`: 恢复保存的 session (启动时使用)
  - `SaveSessionConfig()`: 保存 session 列表到 `~/.vibecoding-gui/sessions.json`
  - `LoadSessionConfig()`: 从 config 加载 session 列表

### 前端

- **App.tsx**: 主组件，管理全局状态
  - `loadSessions()`: 启动时加载 session 列表，恢复最后一个 session
  - `saveSessions()`: 保存 session 元数据到后端
- **EventsOn('chat:event')**: 监听后端事件
- 事件类型: `content`, `tool_call`, `toolCallUpdate`, `permission_request`, `done`, `error`

## Session 管理

GUI 只管理 session 的元数据（别名、工作目录），聊天记录由 VibeCoding 的 session 自身负责。

### 数据存储

- Session 元数据: `~/.vibecoding-gui/sessions.json`
- 存储内容: session ID、名称（别名）、工作目录、创建时间
- 不存储聊天记录，聊天记录由 VibeCoding 管理

### 启动流程

1. 从 `sessions.json` 加载保存的 session 列表
2. 为最后一个 session 调用 `RestoreSession(cwd)` 创建新的 ACP session
3. 更新 session ID（每次启动会变化）并保存到 config
4. 设置当前 session 和工作目录

### Session 操作

- **创建**: 选择工作目录 → 创建 ACP session → 保存到 config
- **重命名**: 更新 session 名称 → 保存到 config
- **删除**: 从列表移除 → 保存到 config
- **切换**: 设置当前 session 和工作目录

## 开发命令

```bash
wails dev          # 开发模式
wails build        # 构建
./build/bin/vibecoding-gui  # 运行
```

## 添加新方法

1. 在 `app.go` 添加方法
2. 运行 `wails generate module` 生成前端绑定
3. 前端调用: `import { MyMethod } from '../wailsjs/go/main/App'`

## 配置

- 全局配置: `~/.vibecoding/settings.json`
- Session 配置: `~/.vibecoding-gui/sessions.json`

## 调试

- Go: `fmt.Fprintf(os.Stderr, ...)`
- 前端: `console.log()`
- ACP 消息自动打印到 stderr

## 注意事项

- 使用 `sync.RWMutex` 保护共享状态
- 事件通道缓冲区 100，满时丢弃
- 组件卸载时取消事件监听
- API 密钥存储在本地配置文件
- Session ID 每次启动都会变化（ACP session 是临时的）

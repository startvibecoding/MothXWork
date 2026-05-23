# VibeCoding GUI

一个基于 Wails、React 和 TypeScript 构建的 VibeCoding 桌面 GUI 客户端。

[English](./README.md) | 中文

## 功能特性

- 🤖 与 AI 编程助手对话
- 📝 Markdown 渲染与代码语法高亮
- 🔄 流式响应
- ⚙️ 提供商和模型选择
- 🛡️ 模式切换（计划/代理/YOLO）
- 📁 带工作目录的 Session 管理
- 💾 跨应用重启的 Session 持久化
- 🔐 Bash 命令的权限对话框
- 🎨 Apple 风格暗色主题
- 🌍 全局设置与高级配置
- 📂 多 Session 支持与快速切换

## 快速开始

### 环境要求

- Go 1.21+
- Node.js 18+
- Wails CLI v2.10+
- 已安装 VibeCoding

### 安装 Wails CLI

```bash
go install github.com/wailsapp/wails/v2/cmd/wails@latest
```

### 构建与运行

```bash
# 克隆仓库
git clone https://github.com/startvibecoding/vibecoding-gui.git
cd vibecoding-gui

# 安装前端依赖
cd frontend && npm install && cd ..

# 构建
wails build

# 运行
./build/bin/vibecoding-gui
```

### 开发模式

```bash
wails dev
```

开发模式支持热重载，修改代码后自动刷新界面。

## 项目架构

```
vibecoding-gui/
├── main.go                          # Wails 入口文件
├── app.go                           # 应用逻辑，暴露给前端的方法
├── internal/
│   └── vibecoding/
│       ├── acp_client.go            # ACP 协议客户端
│       ├── agent.go                 # Agent 管理器
│       └── settings.go              # 配置加载器
├── build/
│   ├── appicon.png                  # 应用图标 (VibeCoding logo)
│   └── windows/icon.ico             # Windows 图标
└── frontend/
    └── src/
        ├── App.tsx                  # 主组件，管理全局状态
        └── components/
            ├── ChatArea.tsx         # 聊天区域
            ├── InputArea.tsx        # 输入区域
            ├── Sidebar.tsx          # 侧边栏
            ├── StatusBar.tsx        # 状态栏
            ├── SessionSettings.tsx   # Session 设置下拉菜单
            ├── GlobalSettings.tsx    # 全局设置弹窗
            ├── AdvancedSettings.tsx  # 高级设置
            ├── PermissionDialog.tsx  # 权限请求对话框
            └── CustomSelect.tsx      # 自定义选择组件
```

## 通信协议

使用 ACP（Agent Client Protocol）通过 stdin/stdout 的 JSON-RPC 与 VibeCoding 通信。

```
GUI ←→ ACP Client ←→ VibeCoding (acp 模式)
```

### 事件类型

| 事件类型 | 说明 |
|---------|------|
| `content` | 接收 AI 回复内容 |
| `tool_call` | 工具调用请求 |
| `toolCallUpdate` | 工具调用状态更新 |
| `permission_request` | 权限请求（如执行 bash 命令） |
| `done` | 响应完成 |
| `error` | 错误信息 |

## Session 管理

GUI 只管理 Session 的元数据（别名、工作目录），聊天记录由 VibeCoding 的 Session 自身负责。

### 数据存储

- **Session 元数据**: `~/.vibecoding-gui/sessions.json`
- **存储内容**: Session ID、名称（别名）、工作目录、创建时间
- **不存储**: 聊天记录（由 VibeCoding 管理）

### 启动流程

1. 从 `sessions.json` 加载保存的 Session 列表
2. 为最后一个 Session 调用 `RestoreSession(cwd)` 创建新的 ACP Session
3. 更新 Session ID（每次启动会变化）并保存到配置
4. 设置当前 Session 和工作目录

### Session 操作

- **创建**: 选择工作目录 → 创建 ACP Session → 保存到配置
- **重命名**: 更新 Session 名称 → 保存到配置
- **删除**: 从列表移除 → 保存到配置
- **切换**: 设置当前 Session 和工作目录

## 配置

### 全局设置

位置: `~/.vibecoding/settings.json`

包含 AI 提供商、模型选择、API 密钥等全局配置。

### Session 设置

位置: `~/.vibecoding-gui/sessions.json`

包含 Session 列表及元数据信息。

## 开发指南

### 添加新方法

1. 在 `app.go` 中添加 Go 方法
2. 运行 `wails generate module` 生成前端绑定
3. 前端调用: `import { MyMethod } from '../wailsjs/go/main/App'`

### 调试

- **Go 后端**: 使用 `fmt.Fprintf(os.Stderr, ...)` 输出调试信息
- **前端**: 使用 `console.log()` 输出调试信息
- **ACP 消息**: 自动打印到 stderr

### 注意事项

- 使用 `sync.RWMutex` 保护共享状态
- 事件通道缓冲区大小为 100，满时丢弃事件
- 组件卸载时自动取消事件监听
- API 密钥存储在本地配置文件
- Session ID 每次启动都会变化（ACP Session 是临时的）

## 技术栈

| 类别 | 技术 |
|-----|------|
| 后端 | Go + Wails v2 |
| 前端 | React 18 + TypeScript |
| 样式 | Tailwind CSS |
| 通信 | ACP (JSON-RPC over stdin/stdout) |
| 构建 | Wails CLI |

## 文档

详细文档请参阅 [docs/](./docs/) 目录。

## 许可证

MIT

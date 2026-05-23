# VibeCoding GUI

A desktop GUI client for VibeCoding built with Wails, React, and TypeScript.

## Features

- 🤖 Chat with AI coding assistant
- 📝 Markdown rendering with code syntax highlighting
- 🔄 Streaming responses
- ⚙️ Provider and model selection
- 🛡️ Mode switching (Plan/Agent/YOLO)
- 📁 Session management with working directory
- 🔐 Permission dialog for bash commands
- 🎨 Apple-style dark theme

## Quick Start

### Prerequisites

- Go 1.21+
- Node.js 18+
- Wails CLI v2.10+
- VibeCoding installed

### Build & Run

```bash
# Install dependencies
cd frontend && npm install && cd ..

# Build
wails build

# Run
./build/bin/vibecoding-gui
```

### Development

```bash
wails dev
```

## Architecture

```
vibecoding-gui/
├── main.go                     # Wails entry point
├── app.go                      # Application logic
├── internal/
│   └── vibecoding/
│       ├── acp_client.go       # ACP protocol client
│       ├── agent.go            # Agent manager
│       └── settings.go         # Settings loader
└── frontend/
    └── src/
        ├── App.tsx             # Main component
        └── components/
            ├── ChatArea.tsx    # Chat area
            ├── InputArea.tsx   # Input area
            ├── Sidebar.tsx     # Sidebar
            ├── StatusBar.tsx   # Status bar
            ├── SessionSettings.tsx   # Session settings dropdown
            ├── GlobalSettings.tsx    # Global settings modal
            ├── PermissionDialog.tsx  # Permission request dialog
            └── CustomSelect.tsx      # Custom select component
```

## Communication

Uses ACP (Agent Client Protocol) to communicate with VibeCoding via stdin/stdout JSON-RPC.

```
GUI ←→ ACP Client ←→ VibeCoding (acp mode)
```

## Configuration

### Global Settings

Location: `~/.vibecoding/settings.json`

### Session Settings

Location: `~/.vibecoding-gui/sessions.json`

## Documentation

See [docs/](./docs/) for detailed documentation.

## License

MIT

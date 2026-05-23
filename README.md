# VibeCoding GUI

A desktop GUI client for VibeCoding built with Wails, React, and TypeScript.

## Features

- 🤖 Chat with AI coding assistant
- 📝 Markdown rendering with code syntax highlighting
- 🔄 Streaming responses
- ⚙️ Provider and model selection
- 🛡️ Mode switching (Plan/Agent/YOLO)
- 📁 Session management with working directory
- 💾 Session persistence across app restarts
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
├── build/
│   ├── appicon.png             # App icon (VibeCoding logo)
│   └── windows/icon.ico        # Windows icon
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

## Session Management

The GUI manages session metadata (aliases, working directories), while chat history is handled by VibeCoding's sessions themselves.

### Data Storage

- **Session metadata**: `~/.vibecoding-gui/sessions.json`
- **Stores**: Session ID, name (alias), working directory, creation time
- **Does NOT store**: Chat history (managed by VibeCoding)

### Startup Flow

1. Load saved session list from `sessions.json`
2. Restore the last session by creating a new ACP session with the saved working directory
3. Update session ID (changes on each restart) and save to config
4. Set current session and working directory

### Session Operations

- **Create**: Select working directory → Create ACP session → Save to config
- **Rename**: Update session name → Save to config
- **Delete**: Remove from list → Save to config
- **Switch**: Set current session and working directory

## Configuration

### Global Settings

Location: `~/.vibecoding/settings.json`

### Session Settings

Location: `~/.vibecoding-gui/sessions.json`

## Documentation

See [docs/](./docs/) for detailed documentation.

## License

MIT

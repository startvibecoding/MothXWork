# VibeCoding GUI

A desktop GUI client for VibeCoding built with Wails, React, and TypeScript.

## Features

- 🤖 Chat with AI coding assistant
- 📝 Markdown rendering with code syntax highlighting
- 🔄 Streaming responses
- ⚙️ Provider and model selection
- 🛡️ Mode switching (Plan/Agent/YOLO)
- 📁 Session management

## Tech Stack

- **Backend**: Go + Wails v2
- **Frontend**: React + TypeScript + Tailwind CSS
- **Markdown**: react-markdown + remark-gfm
- **Syntax Highlighting**: react-syntax-highlighter

## Development

### Prerequisites

- Go 1.21+
- Node.js 18+
- Wails CLI v2.10+

### Setup

1. Install dependencies:
   ```bash
   cd frontend
   npm install
   ```

2. Run in development mode:
   ```bash
   wails dev
   ```

### Build

```bash
wails build
```

## Project Structure

```
vibecoding-gui/
├── main.go              # Wails entry point
├── app.go               # Application logic
├── wails.json           # Wails configuration
├── go.mod               # Go module
└── frontend/
    ├── src/
    │   ├── App.tsx      # Main React component
    │   ├── components/  # UI components
    │   └── index.css    # Global styles
    ├── package.json
    └── wailsjs/         # Wails bindings
```

## Integration

This client integrates directly with VibeCoding's Go packages:

- `internal/agent` - Core agent loop
- `internal/config` - Configuration management
- `internal/provider` - LLM provider abstraction
- `internal/session` - Session management

## License

MIT

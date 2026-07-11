# Mothx GUI (Flutter)

An elegant, high-performance cross-platform desktop GUI client for Mothx, built with Flutter and Dart. It communicates exclusively with a running `mothx serve` instance over HTTP, SSE, and WebSocket.

## Features

- 🤖 **AI Conversation**: Direct chat interface with support for multiple providers and models.
- 🔄 **Real-Time Streaming**: High-performance stream response rendering.
- 📝 **Markdown rendering**: Full syntax highlighting for code block presentation.
- ⚙️ **Session Management**: Automatically restores session on start; customizable per-session directories and configurations.
- 📡 **Serve Operations**: Session history, usage statistics, cron jobs, and logs from the connected serve instance.
- 🎨 **Adaptive Theme**: Supports both dark and light modes styled with clean Apple-like designs.

## Getting Started

### Prerequisites

- Flutter SDK (3.38.0+)
- A running `mothx serve` instance reachable over HTTP. Configure its URL and optional token in Settings.

### Build and Run

```bash
# Get dependencies
flutter pub get

# Run in development mode (Linux)
make dev

# Build a release binary for Linux
make build

# Run the release binary
make run

# Clean build outputs
make clean
```

### Platform Builds

Run each native build on its target operating system:

```bash
make build          # Linux
make build-windows  # Windows
make build-macos    # macOS
```

Mothx settings are read from and written to `~/.mothx/settings.json`. Legacy
settings in `~/.mothx-gui/settings.json` are read once when the canonical file
does not exist; session and UI metadata remain under `~/.mothx-gui/`.

### Build .deb Package (Ubuntu/Debian)

```bash
make deb
```
This generates a installable `.deb` package in the root directory.

## Architecture

- **lib/main.dart**: Main application entry point and layouts.
- **lib/services/app_state.dart**: Centralized ChangeNotifier-based state manager for Serve sessions, streaming, logs, cron, and stats.
- **lib/services/serve_client.dart**: HTTP, SSE, and WebSocket client for `mothx serve`.
- **lib/services/config_service.dart**: Reads/writes Mothx settings (`~/.mothx/settings.json`) and GUI preferences (`~/.mothx-gui/ui.json`).
- **lib/theme/**: Custom Apple-styled dark/light palette definitions and inheritance.
- **lib/widgets/**: Modular UI components (ChatArea, InputArea, Sidebar, StatusBar, settings panels).

# Mothx GUI (Flutter)

An elegant, high-performance cross-platform desktop GUI client for Mothx, built with Flutter and Dart. It communicates with Mothx via the Agent Client Protocol (ACP) over stdio.

## Features

- 🤖 **AI Conversation**: Direct chat interface with support for multiple providers and models.
- 🔄 **Real-Time Streaming**: High-performance stream response rendering.
- 📝 **Markdown rendering**: Full syntax highlighting for code block presentation.
- ⚙️ **Session Management**: Automatically restores session on start; customizable per-session directories and configurations.
- 🛡️ **Execution Security**: Visual permission dialog for approving or denying commands in real-time.
- 🎨 **Adaptive Theme**: Supports both dark and light modes styled with clean Apple-like designs.

## Getting Started

### Prerequisites

- Flutter SDK (3.38.0+)
- Mothx command-line tool installed (located in your PATH or at `~/go/bin/mothx`)

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

### Build .deb Package (Ubuntu/Debian)

```bash
make deb
```
This generates a installable `.deb` package in the root directory.

## Architecture

- **lib/main.dart**: Main application entry point, layouts, and permission overlays.
- **lib/services/app_state.dart**: Centralized ChangeNotifier-based state manager, handles sessions, configurations, and state.
- **lib/services/acp_client.dart**: Complete JSON-RPC-based Agent Client Protocol (ACP) client communicating with `mothx acp` over stdin/stdout.
- **lib/services/config_service.dart**: Reads/writes configuration for both Mothx (`~/.mothx/settings.json`) and the GUI (`~/.mothx-gui/sessions.json`).
- **lib/theme/**: Custom Apple-styled dark/light palette definitions and inheritance.
- **lib/widgets/**: Modular UI components (ChatArea, InputArea, Sidebar, StatusBar, settings panels).

# ACP Protocol Integration Status

## Last Updated: 2026-07-11

## Overview

GUI communicates exclusively via ACP with the `mothx acp` subprocess.
All local Agent/Provider/Tool logic has been removed from the GUI.

---

## Implemented Methods (Client → Server)

| Method | Status | Dart Client | Go Server |
|---|---|---|---|
| `initialize` | ✅ | `AcpClient.initialize()` | `handleInitialize` |
| `session/new` | ✅ | `AcpClient.newSession()` | `handleNewSession` |
| `session/load` | ✅ | `AcpClient.loadSession()` | `handleLoadSession` |
| `session/prompt` | ✅ | `AcpClient.prompt()` | `handlePrompt` |
| `session/cancel` | ✅ | `AcpClient.cancel()` | `handleCancel` |
| `session/close` | ✅ | `AcpClient.closeSession()` | `handleCloseSession` |
| `session/list` | ✅ | `AcpClient.listSessions()` | `handleListSessions` |

---

## Implemented Notifications (Server → Client)

| sessionUpdate Type | Status | Go Emits | Dart Handles |
|---|---|---|---|
| `agent_message_chunk` | ✅ | `handleAgentEvent` | `_handleSessionUpdate` |
| `agent_thought_chunk` | ✅ | `handleAgentEvent` | `_handleSessionUpdate` |
| `tool_call` | ✅ | `handleAgentEvent` | `_handleSessionUpdate` |
| `tool_call_update` | ✅ | `handleAgentEvent` | `_handleSessionUpdate` |
| `user_message_chunk` | ✅ | `emitMessage` | `_handleSessionUpdate` |
| `status` | ✅ | (via notify) | `_handleSessionUpdate` |
| `usage_update` | ✅ | `emitUsageUpdate` | `_handleSessionUpdate` |

---

## Implemented Requests (Server → Client)

| Method | Status | Go Sends | Dart Handles |
|---|---|---|---|
| `session/request_permission` | ✅ | `requestPermission` | `_handlePermissionRequest` |

---

## Key Architecture

### Data Flow

```
┌─────────────┐     JSON-RPC / stdio     ┌─────────────────┐
│  Flutter GUI │ ◄──────────────────────► │  mothx acp      │
│             │                          │  (Go server)    │
│ AppState    │                          │                 │
│   ├─ AcpClient                         │  sessionRuntime │
│   └─ UI Widgets                        │    ├─ Agent     │
└─────────────┘                          │    ├─ Tools     │
                                         │    └─ MCP       │
                                         └─────────────────┘
```

### Session Lifecycle

1. **Init**: `initialize()` → `session/list()` → load session list from backend
2. **New**: `session/new(cwd)` → returns backend sessionId
3. **Load**: `session/load(sessionId, cwd, limit)` → backend emits history as notifications
4. **Prompt**: `session/prompt(sessionId, text)` → long-running, returns on completion
5. **Cancel**: `session/cancel(sessionId)` → stops active prompt
6. **Close**: `session/close(sessionId)` → cleans up server-side resources

### Usage Tracking

- `usage_update` notifications arrive during streaming (`EventUsage`) and on completion (`EventDone`)
- StatusBar shows: context used/size bar + cumulative cost
- AppState exposes: `contextUsed`, `contextSize`, `currentCost`

---

## Remaining Stubs (Not ACP-related)

These features exist in the UI but are not yet backed by ACP:

| Feature | Status | Notes |
|---|---|---|
| Cron management | 🟡 Stub | UI exists, needs ACP methods |
| Logs viewer | 🟡 Stub | UI exists, needs WebSocket or ACP method |
| Stats page | 🟡 Stub | UI exists, needs ACP method |
| Serve mode | 🟡 Stub | Connection mode exists, serve_client.dart not wired |

---

## Files Changed

| File | Role |
|---|---|
| `lib/services/acp_client.dart` | ACP protocol client (JSON-RPC over stdio) |
| `lib/services/app_state.dart` | State management, ACP event handling |
| `lib/services/config_service.dart` | Config + MothxLocator |
| `lib/widgets/status_bar.dart` | Connection status + usage indicator |
| `lib/models/models.dart` | Data models + CronJobInfo/LogEntry stubs |
| `lib/main.dart` | App entry (no vendor registry) |

### Removed

- `lib/core/agent.dart`
- `lib/core/provider/` (all files)
- `lib/core/tools/` (all files)
- `lib/core/settings.dart`
- `lib/core/session.dart`

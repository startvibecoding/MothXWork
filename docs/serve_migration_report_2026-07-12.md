# Serve Client Migration Report

**Updated:** 2026-07-12

The desktop client now communicates exclusively with `mothx serve`. The local
subprocess client and JSON-RPC transport were removed.

## Runtime Flow

1. The application reads the saved serve URL and optional token.
2. It verifies `/health`, then loads sessions from `/api/sessions`.
3. Chat uses `/v1/chat/completions` with SSE. New sessions are created by the
   server and returned through `x_session_id`.
4. Session history, deletion, statistics, cron jobs, and logs use the Serve
   REST and WebSocket endpoints.

## WebUI Coverage

- Chat: streamed transcript, tool capability toggles, image content parts,
  server-side directory selection, run/capability events, and sub-agent
  transcripts.
- Operations: sessions, statistics breakdowns, cron jobs, live logs, channel
  status, and WeChat login.
- Administration: serve status and features, global Memory, remote settings,
  and complete serve configuration editing.

## Validation

- `flutter analyze`
- `flutter test`
- `flutter build linux --release`

Windows and macOS project shells and CI build jobs are present, but their
native builds still need to run on Windows and macOS runners. Signing and
installer credentials remain release-management work.

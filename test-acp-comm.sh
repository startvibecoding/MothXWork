#!/bin/bash

# 测试 ACP 通信

set -e

cd "$(dirname "$0")"

echo "=== 测试 ACP 通信 ==="
echo ""

# 测试 initialize
echo "1. 测试 initialize..."
INIT_RESULT=$(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":1,"clientInfo":{"name":"test","version":"1.0.0"}}}' | timeout 5 vibecoding acp 2>/dev/null)
echo "结果: $INIT_RESULT"
echo ""

# 测试 session/new
echo "2. 测试 session/new..."
SESSION_RESULT=$(echo '{"jsonrpc":"2.0","id":2,"method":"session/new","params":{"cwd":"/tmp"}}' | timeout 5 vibecoding acp 2>/dev/null)
echo "结果: $SESSION_RESULT"
echo ""

# 提取 sessionId
SESSION_ID=$(echo "$SESSION_RESULT" | grep -o '"sessionId":"[^"]*"' | cut -d'"' -f4)
echo "Session ID: $SESSION_ID"
echo ""

# 测试 session/prompt (需要交互式输入)
echo "3. 测试 session/prompt..."
echo "发送: hello"
echo ""

# 使用 expect 或类似工具进行交互式测试
# 这里只是演示，实际需要更复杂的交互式测试
cat << EOF | timeout 10 vibecoding acp 2>&1 | head -20
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":1,"clientInfo":{"name":"test","version":"1.0.0"}}}
{"jsonrpc":"2.0","id":2,"method":"session/new","params":{"cwd":"/tmp"}}
{"jsonrpc":"2.0","id":3,"method":"session/prompt","params":{"sessionId":"$SESSION_ID","prompt":[{"type":"text","text":"hello"}]}}
EOF

echo ""
echo "=== 测试完成 ==="

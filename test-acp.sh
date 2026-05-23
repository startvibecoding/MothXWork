#!/bin/bash

# 测试 ACP 客户端

set -e

cd "$(dirname "$0")"

echo "=== 测试 VibeCoding GUI (ACP 方案) ==="
echo ""

# 检查 VibeCoding 二进制文件
VIBECODING_BIN=""
if [ -f "../../vibecoding/build/bin/vibecoding" ]; then
    VIBECODING_BIN="../../vibecoding/build/bin/vibecoding"
elif [ -f "/usr/local/bin/vibecoding" ]; then
    VIBECODING_BIN="/usr/local/bin/vibecoding"
elif command -v vibecoding &> /dev/null; then
    VIBECODING_BIN=$(which vibecoding)
fi

if [ -z "$VIBECODING_BIN" ]; then
    echo "❌ VibeCoding 二进制文件未找到"
    echo "请先构建 VibeCoding: cd vibecoding && make build"
    exit 1
fi

echo "✅ 找到 VibeCoding: $VIBECODING_BIN"

# 检查 VibeCoding 是否支持 ACP 模式
echo ""
echo "检查 VibeCoding ACP 支持..."
if $VIBECODING_BIN --help 2>&1 | grep -q "acp"; then
    echo "✅ VibeCoding 支持 ACP 模式 (使用: vibecoding acp)"
else
    echo "⚠️  VibeCoding 可能不支持 ACP 模式"
fi

# 检查 GUI 二进制文件
GUI_BIN="build/bin/vibecoding-gui"
if [ ! -f "$GUI_BIN" ]; then
    echo "❌ GUI 二进制文件不存在"
    echo "请先构建 GUI: wails build"
    exit 1
fi

echo "✅ 找到 GUI: $GUI_BIN"

# 检查文件大小
SIZE=$(du -h "$GUI_BIN" | cut -f1)
echo "📦 GUI 大小: $SIZE"

echo ""
echo "=== 测试完成 ==="
echo ""
echo "要运行 GUI:"
echo "  ./$GUI_BIN"
echo ""
echo "或者:"
echo "  make run"

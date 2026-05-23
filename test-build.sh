#!/bin/bash

# 测试 VibeCoding GUI 构建

set -e

cd "$(dirname "$0")"

echo "=== 测试 VibeCoding GUI 构建 ==="
echo ""

# 检查构建目录
BUILD_DIR="build/bin"
BINARY="$BUILD_DIR/vibecoding-gui"

if [ ! -d "$BUILD_DIR" ]; then
    echo "❌ 构建目录不存在: $BUILD_DIR"
    echo "请先运行: wails build"
    exit 1
fi

if [ ! -f "$BINARY" ]; then
    echo "❌ 二进制文件不存在: $BINARY"
    echo "请先运行: wails build"
    exit 1
fi

echo "✅ 构建目录存在: $BUILD_DIR"
echo "✅ 二进制文件存在: $BINARY"

# 检查文件大小
SIZE=$(du -h "$BINARY" | cut -f1)
echo "📦 二进制文件大小: $SIZE"

# 检查文件权限
if [ -x "$BINARY" ]; then
    echo "✅ 二进制文件可执行"
else
    echo "❌ 二进制文件不可执行"
    exit 1
fi

# 检查依赖
echo ""
echo "检查依赖..."
ldd "$BINARY" 2>/dev/null | head -10 || echo "无法检查依赖 (可能是静态链接)"

echo ""
echo "=== 构建测试完成 ==="
echo ""
echo "要运行应用程序:"
echo "  ./$BINARY"
echo ""
echo "或者:"
echo "  make run"

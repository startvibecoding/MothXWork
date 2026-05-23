#!/bin/bash

# VibeCoding GUI 快速启动脚本

set -e

echo "🚀 VibeCoding GUI 启动脚本"
echo "=========================="
echo ""

# 检查 Go 版本
echo "检查 Go 版本..."
go_version=$(go version | awk '{print $3}' | sed 's/go//')
echo "当前 Go 版本: $go_version"

# 检查 Node.js 版本
echo "检查 Node.js 版本..."
node_version=$(node --version)
echo "当前 Node.js 版本: $node_version"

# 检查 Wails 版本
echo "检查 Wails 版本..."
wails version

echo ""
echo "安装前端依赖..."
cd frontend
npm install
cd ..

echo ""
echo "✅ 依赖安装完成！"
echo ""
echo "启动开发服务器..."
echo "运行命令: wails dev"
echo ""
echo "或者使用 Makefile:"
echo "  make dev    - 启动开发服务器"
echo "  make build  - 构建生产版本"
echo "  make clean  - 清理构建文件"

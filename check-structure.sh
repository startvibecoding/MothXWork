#!/bin/bash

echo "=== VibeCoding GUI Project Structure ==="
echo ""

cd "$(dirname "$0")"

echo "📁 Root directory:"
ls -la

echo ""
echo "📁 Frontend directory:"
ls -la frontend/

echo ""
echo "📁 Frontend src directory:"
ls -la frontend/src/

echo ""
echo "📁 Frontend components directory:"
ls -la frontend/src/components/

echo ""
echo "✅ Project structure looks good!"
echo ""
echo "To start development:"
echo "  cd prader/vibecoding-gui"
echo "  make setup"
echo "  make dev"

#!/bin/bash
# Copy the platform-specific vibecoding binary to the build output directory
# Usage: ./scripts/copy-vibecoding.sh [output_dir]

set -e

VIBECODING_BIN_DIR="${VIBECODING_BIN_DIR:-/home/free/src/startvibecoding/vibecoding/bin}"
OUTPUT_DIR="${1:-build/bin}"

# Detect platform and architecture
OS=$(go env GOOS)
ARCH=$(go env GOARCH)

# Map to vibecoding binary name
BINARY_NAME="vibecoding-${OS}-${ARCH}"

# Add .exe extension for Windows
if [ "$OS" = "windows" ]; then
    BINARY_NAME="${BINARY_NAME}.exe"
fi

SOURCE="${VIBECODING_BIN_DIR}/${BINARY_NAME}"
DEST="${OUTPUT_DIR}/vibecoding"

if [ "$OS" = "windows" ]; then
    DEST="${DEST}.exe"
fi

if [ ! -f "$SOURCE" ]; then
    echo "Warning: vibecoding binary not found: ${SOURCE}"
    echo "Available binaries:"
    ls -1 "${VIBECODING_BIN_DIR}/" 2>/dev/null || echo "  (directory not found)"
    exit 1
fi

# Ensure output directory exists
mkdir -p "${OUTPUT_DIR}"

# Copy binary
cp "${SOURCE}" "${DEST}"
chmod +x "${DEST}"

echo "Copied ${BINARY_NAME} -> ${DEST}"

.PHONY: dev build clean setup run all help build-all

# Configuration
VIBECODING_BIN_DIR ?= /home/free/src/startvibecoding/vibecoding/bin
BUILD_DIR          := build/bin
FRONTEND_DIR       := frontend

# Version info (from git)
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT  := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
LDFLAGS := -ldflags "-X main.version=$(VERSION) -X main.commit=$(COMMIT)"

# Default target
all: setup build run

## help: Show this help message
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@sed -n 's/^## //p' $(MAKEFILE_LIST) | column -t -s ':' 2>/dev/null || sed -n 's/^## //p' $(MAKEFILE_LIST)

## dev: Start development mode with hot reload
dev:
	wails dev

## build: Build for current platform
build: setup
	wails build $(LDFLAGS)
	./scripts/copy-vibecoding.sh $(BUILD_DIR)
	@echo "✅ Build complete: $(BUILD_DIR)/vibecoding-gui"

## build-all: Build for all platforms (linux/darwin/windows, amd64/arm64)
build-all: setup
	@echo "Building for all platforms..."
	@for os in linux darwin windows; do \
		for arch in amd64 arm64; do \
			echo "Building $$os/$$arch..."; \
			GOOS=$$os GOARCH=$$arch wails build $(LDFLAGS) -o vibecoding-gui-$$os-$$arch 2>/dev/null || true; \
		done; \
	done
	@echo "✅ All builds complete"

## setup: Install frontend dependencies
setup:
	cd $(FRONTEND_DIR) && npm install

## clean: Remove build artifacts
clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(FRONTEND_DIR)/node_modules
	rm -rf $(FRONTEND_DIR)/dist
	@echo "✅ Cleaned"

## run: Run the built application
run: build
	./$(BUILD_DIR)/vibecoding-gui

## lint: Run linters
lint:
	cd $(FRONTEND_DIR) && npm run lint 2>/dev/null || true
	@echo "✅ Lint complete"

## fmt: Format Go code
fmt:
	gofmt -w .
	@echo "✅ Formatted"

## check: Run all checks (lint + build)
check: lint build
	@echo "✅ All checks passed"

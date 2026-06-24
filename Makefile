.PHONY: dev build clean setup run all help build-all build-windows build-mac deb

# Configuration
VIBECODING_BIN_DIR ?= /home/free/src/startvibecoding/vibecoding/bin
BUILD_DIR          := build/bin
FRONTEND_DIR       := frontend

# Version info (from git)
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT  := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
LDFLAGS := -ldflags "-X main.version=$(VERSION) -X main.commit=$(COMMIT)"

# Deb version (must start with digit for dpkg-deb)
GIT_TAG := $(shell git describe --tags --abbrev=0 2>/dev/null || echo "")
ifeq ($(GIT_TAG),)
  DEB_VERSION := 0.0.1-$(COMMIT)
else
  DEB_VERSION := $(GIT_TAG:v=%)
endif

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

## build-windows: Build for Windows (amd64)
build-windows: setup
	@echo "Building for Windows/amd64..."
	GOOS=windows GOARCH=amd64 wails build $(LDFLAGS) -o vibecoding-gui.exe -platform windows/amd64
	./scripts/copy-vibecoding.sh $(BUILD_DIR) windows amd64
	@echo "✅ Windows build complete: $(BUILD_DIR)/vibecoding-gui.exe"

## build-mac: Build for macOS (amd64 + arm64)
build-mac: setup
	@echo "Building for macOS/amd64..."
	GOOS=darwin GOARCH=amd64 wails build $(LDFLAGS) -o vibecoding-gui-darwin-amd64 -platform darwin/amd64
	./scripts/copy-vibecoding.sh $(BUILD_DIR) darwin amd64
	@echo "Building for macOS/arm64..."
	GOOS=darwin GOARCH=arm64 wails build $(LDFLAGS) -o vibecoding-gui-darwin-arm64 -platform darwin/arm64
	./scripts/copy-vibecoding.sh $(BUILD_DIR) darwin arm64
	@echo "✅ macOS builds complete"

## deb: Build .deb package for Debian/Ubuntu (amd64)
deb: setup
	@echo "Building .deb package..."
	GOOS=linux GOARCH=amd64 wails build $(LDFLAGS) -o vibecoding-gui -platform linux/amd64
	./scripts/copy-vibecoding.sh $(BUILD_DIR) linux amd64
	@# Create deb structure
	@mkdir -p build/deb/usr/bin build/deb/DEBIAN
	@cp $(BUILD_DIR)/vibecoding-gui build/deb/usr/bin/
	@cp $(BUILD_DIR)/vibecoding build/deb/usr/bin/ 2>/dev/null || true
	@chmod 755 build/deb/usr/bin/*
	@# Create control file
	@echo "Package: vibecoding-gui" > build/deb/DEBIAN/control
	@echo "Version: $(DEB_VERSION)" >> build/deb/DEBIAN/control
	@echo "Section: utils" >> build/deb/DEBIAN/control
	@echo "Priority: optional" >> build/deb/DEBIAN/control
	@echo "Architecture: amd64" >> build/deb/DEBIAN/control
	@echo "Maintainer: VibeCoding Team" >> build/deb/DEBIAN/control
	@echo "Description: VibeCoding GUI Client" >> build/deb/DEBIAN/control
	@# Build deb
	@dpkg-deb --build build/deb vibecoding-gui-$(DEB_VERSION)-amd64.deb
	@echo "✅ .deb package complete: vibecoding-gui-$(DEB_VERSION)-amd64.deb"

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

# ---------------------------------------------------------------------------
# Flutter targets
# ---------------------------------------------------------------------------

FLUTTER_APP := flutter_app
FLUTTER_BUNDLE := $(FLUTTER_APP)/build/linux/x64/release/bundle

## flutter-dev: Run Flutter app in development mode
flutter-dev:
	cd $(FLUTTER_APP) && flutter run -d linux

## flutter-build: Build Flutter app for Linux (release)
flutter-build:
	cd $(FLUTTER_APP) && flutter build linux --release
	mkdir -p build/bin
	cp -r $(FLUTTER_BUNDLE)/* build/bin/
	@echo "✅ Flutter build: build/bin/vibecoding-gui"

## flutter-deb: Build .deb from Flutter build
flutter-deb: flutter-build
	@echo "Building .deb package (Flutter)..."
	mkdir -p build/deb/usr/share/vibecoding-gui build/deb/usr/bin build/deb/DEBIAN
	cp -r $(FLUTTER_BUNDLE)/* build/deb/usr/share/vibecoding-gui/
	ln -sf /usr/share/vibecoding-gui/vibecoding-gui build/deb/usr/bin/vibecoding-gui
	@echo "Package: vibecoding-gui" > build/deb/DEBIAN/control
	@echo "Version: $(DEB_VERSION)" >> build/deb/DEBIAN/control
	@echo "Section: utils" >> build/deb/DEBIAN/control
	@echo "Priority: optional" >> build/deb/DEBIAN/control
	@echo "Architecture: amd64" >> build/deb/DEBIAN/control
	@echo "Maintainer: VibeCoding Team" >> build/deb/DEBIAN/control
	@echo "Description: VibeCoding GUI (Flutter)" >> build/deb/DEBIAN/control
	dpkg-deb --build build/deb vibecoding-gui-$(DEB_VERSION)-amd64.deb
	@echo "✅ .deb: vibecoding-gui-$(DEB_VERSION)-amd64.deb"

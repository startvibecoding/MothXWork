.PHONY: dev build build-windows build-macos clean run help deb all

# Configuration
BUILD_DIR      := build/bin
FLUTTER_BUNDLE := build/linux/x64/release/bundle

# Version info (from git)
COMMIT  := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
LDFLAGS := -ldflags "-X main.commit=$(COMMIT)"

# Deb version (must start with digit for dpkg-deb)
GIT_TAG := $(shell git describe --tags --abbrev=0 2>/dev/null || echo "")
ifeq ($(GIT_TAG),)
  DEB_VERSION := 0.0.1-$(COMMIT)
else
  DEB_VERSION := $(GIT_TAG:v=%)
endif

# Default target
all: build

## help: Show this help message
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@sed -n 's/^## //p' $(MAKEFILE_LIST) | column -t -s ':' 2>/dev/null || sed -n 's/^## //p' $(MAKEFILE_LIST)

## dev: Run Flutter app in development mode
dev:
	flutter run -d linux

## build: Build Flutter app for Linux (release)
build:
	flutter build linux --release
	mkdir -p $(BUILD_DIR)
	cp -r $(FLUTTER_BUNDLE)/* $(BUILD_DIR)/
	@echo "✅ Flutter build completed: $(BUILD_DIR)/mothx-gui"

## build-windows: Build a Windows release bundle (run on Windows)
build-windows:
	flutter build windows --release

## build-macos: Build a macOS release app bundle (run on macOS)
build-macos:
	flutter build macos --release

## run: Run the built application
run: build
	./$(BUILD_DIR)/mothx-gui

## deb: Build .deb package for Debian/Ubuntu (amd64)
deb: build
	@echo "Building .deb package (Flutter)..."
	mkdir -p build/deb/usr/share/mothx-gui build/deb/usr/bin build/deb/DEBIAN
	cp -r $(FLUTTER_BUNDLE)/* build/deb/usr/share/mothx-gui/
	ln -sf /usr/share/mothx-gui/mothx-gui build/deb/usr/bin/mothx-gui
	@echo "Package: mothx-gui" > build/deb/DEBIAN/control
	@echo "Version: $(DEB_VERSION)" >> build/deb/DEBIAN/control
	@echo "Section: utils" >> build/deb/DEBIAN/control
	@echo "Priority: optional" >> build/deb/DEBIAN/control
	@echo "Architecture: amd64" >> build/deb/DEBIAN/control
	@echo "Maintainer: Mothx Team" >> build/deb/DEBIAN/control
	@echo "Description: Mothx GUI (Flutter)" >> build/deb/DEBIAN/control
	dpkg-deb --build build/deb mothx-gui-$(DEB_VERSION)-amd64.deb
	@echo "✅ .deb package completed: mothx-gui-$(DEB_VERSION)-amd64.deb"

## clean: Remove build artifacts
clean:
	flutter clean
	rm -rf build
	rm -f *.deb
	@echo "✅ Cleaned"

.PHONY: dev build clean setup

# Development
dev:
	wails dev

# Build
build: setup
	wails build

# Setup dependencies
setup:
	cd frontend && npm install

# Clean
clean:
	rm -rf build/bin
	rm -rf frontend/node_modules
	rm -rf frontend/dist

# Run
run:
	./build/bin/vibecoding-gui

# All
all: setup build run

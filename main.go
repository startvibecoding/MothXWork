package main

import (
	"embed"
	"log"

	vibecoding "github.com/startvibecoding/prader/vibecoding-gui/internal/vibecoding"
	"github.com/wailsapp/wails/v2"
	"github.com/wailsapp/wails/v2/pkg/options"
	"github.com/wailsapp/wails/v2/pkg/options/assetserver"
)

//go:embed all:frontend/dist
var assets embed.FS

func main() {
	// Load settings from ~/.vibecoding/settings.json
	settings, err := vibecoding.LoadVibeCodingSettings()
	if err != nil {
		log.Printf("Warning: failed to load settings: %v", err)
		// Use default settings
		settings = &vibecoding.VibeCodingSettings{
			DefaultProvider:      "deepseek-openai",
			DefaultModel:         "deepseek-v4-flash",
			DefaultThinkingLevel: "medium",
			DefaultMode:          "agent",
		}
	}
	
	// Create config from settings
	config := &vibecoding.SessionConfig{
		Provider: settings.DefaultProvider,
		Model:    settings.DefaultModel,
		Mode:     settings.DefaultMode,
		Thinking: settings.DefaultThinkingLevel,
	}
	
	// Create an instance of the app structure
	app, err := NewApp(config)
	if err != nil {
		log.Fatal("Failed to create app:", err)
	}
	defer app.agent.Close()

	// Create application with options
	err = wails.Run(&options.App{
		Title:  "VibeCoding GUI",
		Width:  1280,
		Height: 800,
		AssetServer: &assetserver.Options{
			Assets: assets,
		},
		BackgroundColour: &options.RGBA{R: 27, G: 38, B: 54, A: 1},
		OnStartup:        app.startup,
		Bind: []interface{}{
			app,
		},
	})

	if err != nil {
		log.Fatal("Error:", err.Error())
	}
}

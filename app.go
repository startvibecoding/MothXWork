package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	vibecoding "github.com/startvibecoding/prader/vibecoding-gui/internal/vibecoding"
	"github.com/wailsapp/wails/v2/pkg/runtime"
)

// App struct
type App struct {
	ctx      context.Context
	agent    *vibecoding.AgentManager
	settings *vibecoding.VibeCodingSettings
}

// NewApp creates a new App application struct
func NewApp(config *vibecoding.SessionConfig) (*App, error) {
	// Load VibeCoding settings
	settings, err := vibecoding.LoadVibeCodingSettings()
	if err != nil {
		return nil, fmt.Errorf("load settings: %w", err)
	}
	
	// Find VibeCoding binary
	vibecodingPath := findVibeCodingBinary()
	if vibecodingPath == "" {
		return nil, fmt.Errorf("vibecoding binary not found")
	}
	
	agent, err := vibecoding.NewAgentManager(vibecodingPath, config)
	if err != nil {
		return nil, fmt.Errorf("create agent manager: %w", err)
	}
	
	return &App{
		agent:    agent,
		settings: settings,
	}, nil
}

// startup is called when the app starts. The context is saved
// so we can call the runtime methods
func (a *App) startup(ctx context.Context) {
	a.ctx = ctx
}

// Greet returns a greeting for the given name
func (a *App) Greet(name string) string {
	return fmt.Sprintf("Hello %s, It's show time!", name)
}

// GetConfig returns the current configuration
func (a *App) GetConfig() *vibecoding.SessionConfig {
	return a.agent.GetConfig()
}

// GetSettings returns the VibeCoding settings
func (a *App) GetSettings() *vibecoding.VibeCodingSettings {
	return a.settings
}

// GetProviders returns available providers
func (a *App) GetProviders() []map[string]string {
	return a.settings.GetProviders()
}

// GetModels returns available models for a provider
func (a *App) GetModels(providerID string) []map[string]interface{} {
	return a.settings.GetModels(providerID)
}

// UpdateConfig updates the configuration and restarts the ACP client
func (a *App) UpdateConfig(config *vibecoding.SessionConfig) error {
	// Close existing agent
	if a.agent != nil {
		a.agent.Close()
	}
	
	// Create new agent with updated config
	vibecodingPath := findVibeCodingBinary()
	if vibecodingPath == "" {
		return fmt.Errorf("vibecoding binary not found")
	}
	
	agent, err := vibecoding.NewAgentManager(vibecodingPath, config)
	if err != nil {
		return fmt.Errorf("create agent manager: %w", err)
	}
	
	a.agent = agent
	
	// Notify frontend
	runtime.EventsEmit(a.ctx, "config:updated", config)
	
	return nil
}

// CreateSession creates a new session
func (a *App) CreateSession() (string, error) {
	return a.agent.CreateSession()
}

// SendMessage sends a message and streams response
func (a *App) SendMessage(sessionID, message string) error {
	events, err := a.agent.Chat(a.ctx, sessionID, message)
	if err != nil {
		return err
	}
	
	// Process events in background
	go func() {
		for event := range events {
			runtime.EventsEmit(a.ctx, "chat:event", event)
		}
	}()
	
	return nil
}

// Abort aborts the current operation
func (a *App) Abort(sessionID string) error {
	return a.agent.Abort(sessionID)
}

// SendPermissionResponse sends a permission response
func (a *App) SendPermissionResponse(requestID string, optionID string) error {
	return a.agent.SendPermissionResponse(requestID, optionID)
}

// ShowNotification shows a notification
func (a *App) ShowNotification(title, message string) {
	runtime.EventsEmit(a.ctx, "notification", map[string]string{
		"title":   title,
		"message": message,
	})
}

// OpenFileDialog opens a file dialog
func (a *App) OpenFileDialog() (string, error) {
	return runtime.OpenFileDialog(a.ctx, runtime.OpenDialogOptions{
		Title: "Select File",
		Filters: []runtime.FileFilter{
			{
				DisplayName: "All Files",
				Pattern:     "*.*",
			},
		},
	})
}

// OpenDirectoryDialog opens a directory dialog
func (a *App) OpenDirectoryDialog() (string, error) {
	return runtime.OpenDirectoryDialog(a.ctx, runtime.OpenDialogOptions{
		Title: "Select Directory",
	})
}

// SaveSessionConfig saves session configuration
func (a *App) SaveSessionConfig(sessions []map[string]string) error {
	home, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("get home dir: %w", err)
	}
	
	configDir := filepath.Join(home, ".vibecoding-gui")
	if err := os.MkdirAll(configDir, 0755); err != nil {
		return fmt.Errorf("create config dir: %w", err)
	}
	
	configPath := filepath.Join(configDir, "sessions.json")
	data, err := json.MarshalIndent(sessions, "", "  ")
	if err != nil {
		return fmt.Errorf("marshal config: %w", err)
	}
	
	return os.WriteFile(configPath, data, 0644)
}

// LoadSessionConfig loads session configuration
func (a *App) LoadSessionConfig() ([]map[string]string, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return nil, fmt.Errorf("get home dir: %w", err)
	}
	
	configPath := filepath.Join(home, ".vibecoding-gui", "sessions.json")
	data, err := os.ReadFile(configPath)
	if err != nil {
		if os.IsNotExist(err) {
			return []map[string]string{}, nil
		}
		return nil, fmt.Errorf("read config: %w", err)
	}
	
	var sessions []map[string]string
	if err := json.Unmarshal(data, &sessions); err != nil {
		return nil, fmt.Errorf("parse config: %w", err)
	}
	
	return sessions, nil
}

// findVibeCodingBinary finds the VibeCoding binary
func findVibeCodingBinary() string {
	// Check common locations
	locations := []string{
		"vibecoding",
		"/usr/local/bin/vibecoding",
		filepath.Join(os.Getenv("HOME"), ".local/bin/vibecoding"),
		filepath.Join(os.Getenv("HOME"), "go/bin/vibecoding"),
	}
	
	// Check current directory
	cwd, err := os.Getwd()
	if err == nil {
		// Check parent directories
		for dir := cwd; dir != "/"; dir = filepath.Dir(dir) {
			locations = append(locations, filepath.Join(dir, "vibecoding", "build", "bin", "vibecoding"))
			locations = append(locations, filepath.Join(dir, "vibecoding", "vibecoding"))
		}
	}
	
	for _, loc := range locations {
		if _, err := os.Stat(loc); err == nil {
			return loc
		}
	}
	
	// Try PATH
	path, err := exec.LookPath("vibecoding")
	if err == nil {
		return path
	}
	
	return ""
}

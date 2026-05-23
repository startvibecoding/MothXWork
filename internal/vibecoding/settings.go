package vibecoding

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

// VibeCodingSettings represents the ~/.vibecoding/settings.json structure
type VibeCodingSettings struct {
	Providers            map[string]*ProviderConfig `json:"providers"`
	DefaultProvider      string                     `json:"defaultProvider"`
	DefaultModel         string                     `json:"defaultModel"`
	DefaultThinkingLevel string                     `json:"defaultThinkingLevel"`
	DefaultMode          string                     `json:"defaultMode"`
}

// ProviderConfig represents a provider configuration
type ProviderConfig struct {
	APIKey  string        `json:"apiKey"`
	BaseURL string        `json:"baseUrl"`
	API     string        `json:"api"`
	Models  []ModelConfig `json:"models"`
}

// ModelConfig represents a model configuration
type ModelConfig struct {
	ID            string `json:"id"`
	Name          string `json:"name"`
	ContextWindow int    `json:"contextWindow"`
	MaxTokens     int    `json:"maxTokens"`
}

// LoadVibeCodingSettings loads settings from ~/.vibecoding/settings.json
func LoadVibeCodingSettings() (*VibeCodingSettings, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return nil, fmt.Errorf("get home dir: %w", err)
	}
	
	settingsPath := filepath.Join(home, ".vibecoding", "settings.json")
	data, err := os.ReadFile(settingsPath)
	if err != nil {
		if os.IsNotExist(err) {
			// Return default settings if file doesn't exist
			return &VibeCodingSettings{
				DefaultProvider:      "deepseek-openai",
				DefaultModel:         "deepseek-v4-flash",
				DefaultThinkingLevel: "medium",
				DefaultMode:          "agent",
			}, nil
		}
		return nil, fmt.Errorf("read settings: %w", err)
	}
	
	var settings VibeCodingSettings
	if err := json.Unmarshal(data, &settings); err != nil {
		return nil, fmt.Errorf("parse settings: %w", err)
	}
	
	return &settings, nil
}

// GetProviders returns list of available providers
func (s *VibeCodingSettings) GetProviders() []map[string]string {
	providers := make([]map[string]string, 0, len(s.Providers))
	for id, p := range s.Providers {
		providers = append(providers, map[string]string{
			"id":   id,
			"name": id,
			"api":  p.API,
		})
	}
	return providers
}

// GetModels returns list of available models for a provider
func (s *VibeCodingSettings) GetModels(providerID string) []map[string]interface{} {
	p, ok := s.Providers[providerID]
	if !ok {
		return nil
	}
	
	models := make([]map[string]interface{}, 0, len(p.Models))
	for _, m := range p.Models {
		models = append(models, map[string]interface{}{
			"id":            m.ID,
			"name":          m.Name,
			"contextWindow": m.ContextWindow,
			"maxTokens":     m.MaxTokens,
		})
	}
	return models
}

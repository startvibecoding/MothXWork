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
	MaxOutputTokens      int                        `json:"maxOutputTokens,omitempty"`
	MaxContextTokens     int                        `json:"maxContextTokens,omitempty"`
	Compaction           *CompactionConfig          `json:"compaction,omitempty"`
	Sandbox              *SandboxConfig             `json:"sandbox,omitempty"`
	ContextFiles         *ContextFilesConfig        `json:"contextFiles,omitempty"`
	SkillsDir            string                     `json:"skillsDir,omitempty"`
	SessionDir           string                     `json:"sessionDir,omitempty"`
	ShellPath            string                     `json:"shellPath,omitempty"`
	ShellCommandPrefix   string                     `json:"shellCommandPrefix,omitempty"`
	Retry                *RetryConfig               `json:"retry,omitempty"`
	Approval             *ApprovalConfig            `json:"approval,omitempty"`
}

// CompactionConfig represents compaction settings
type CompactionConfig struct {
	Enabled          bool `json:"enabled"`
	ReserveTokens    int  `json:"reserveTokens"`
	KeepRecentTokens int  `json:"keepRecentTokens"`
}

// SandboxConfig represents sandbox settings
type SandboxConfig struct {
	Enabled      bool     `json:"enabled"`
	Level        string   `json:"level"`
	AllowNetwork bool     `json:"allowNetwork"`
	AllowedRead  []string `json:"allowedRead,omitempty"`
	DeniedPaths  []string `json:"deniedPaths,omitempty"`
	PassEnv      []string `json:"passEnv,omitempty"`
	TmpSize      string   `json:"tmpSize,omitempty"`
}

// ContextFilesConfig represents context files settings
type ContextFilesConfig struct {
	Enabled    bool     `json:"enabled"`
	ExtraFiles []string `json:"extraFiles,omitempty"`
}

// RetryConfig represents retry settings
type RetryConfig struct {
	Enabled      bool `json:"enabled"`
	MaxRetries   int  `json:"maxRetries"`
	BaseDelayMs  int  `json:"baseDelayMs"`
}

// ApprovalConfig represents approval settings
type ApprovalConfig struct {
	BashWhitelist []string `json:"bashWhitelist,omitempty"`
	BashBlacklist []string `json:"bashBlacklist,omitempty"`
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
	ID            string       `json:"id"`
	Name          string       `json:"name"`
	Reasoning     bool         `json:"reasoning,omitempty"`
	ContextWindow int          `json:"contextWindow,omitempty"`
	MaxTokens     int          `json:"maxTokens,omitempty"`
	Temperature   *float64     `json:"temperature,omitempty"`
	TopP          *float64     `json:"top_p,omitempty"`
	Cost          *CostConfig  `json:"cost,omitempty"`
	Input         []string     `json:"input,omitempty"`
	Compat        *ModelCompat `json:"compat,omitempty"`
}

// CostConfig represents model cost configuration
type CostConfig struct {
	Input      float64 `json:"input"`
	Output     float64 `json:"output"`
	CacheRead  float64 `json:"cacheRead,omitempty"`
	CacheWrite float64 `json:"cacheWrite,omitempty"`
}

// ModelCompat defines per-model compatibility flags
type ModelCompat struct {
	ThinkingFormat                              string `json:"thinkingFormat,omitempty"`
	RequiresReasoningContentOnAssistant         bool   `json:"requiresReasoningContentOnAssistant,omitempty"`
	RequiresReasoningContentOnAssistantMessages bool   `json:"requiresReasoningContentOnAssistantMessages,omitempty"`
	ForceAdaptiveThinking                       bool   `json:"forceAdaptiveThinking,omitempty"`
	SupportsDeveloperRole                       *bool  `json:"supportsDeveloperRole,omitempty"`
	SupportsStore                               *bool  `json:"supportsStore,omitempty"`
	SupportsReasoningEffort                     *bool  `json:"supportsReasoningEffort,omitempty"`
	SupportsStrictMode                          *bool  `json:"supportsStrictMode,omitempty"`
	MaxTokensField                              string `json:"maxTokensField,omitempty"`
	SupportsCacheControlOnTools                 *bool  `json:"supportsCacheControlOnTools,omitempty"`
	SupportsLongCacheRetention                  *bool  `json:"supportsLongCacheRetention,omitempty"`
	SupportsPromptCacheKey                      *bool  `json:"supportsPromptCacheKey,omitempty"`
	SupportsReasoningSummary                    *bool  `json:"supportsReasoningSummary,omitempty"`
	SendSessionAffinityHeaders                  bool   `json:"sendSessionAffinityHeaders,omitempty"`
	SupportsEagerToolInputStreaming             *bool  `json:"supportsEagerToolInputStreaming,omitempty"`
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

// SaveSettings saves settings to ~/.vibecoding/settings.json
func SaveSettings(settings *VibeCodingSettings) error {
	home, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("get home dir: %w", err)
	}
	
	configDir := filepath.Join(home, ".vibecoding")
	if err := os.MkdirAll(configDir, 0755); err != nil {
		return fmt.Errorf("create config dir: %w", err)
	}
	
	settingsPath := filepath.Join(configDir, "settings.json")
	data, err := json.MarshalIndent(settings, "", "  ")
	if err != nil {
		return fmt.Errorf("marshal settings: %w", err)
	}
	
	return os.WriteFile(settingsPath, data, 0644)
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
		model := map[string]interface{}{
			"id":            m.ID,
			"name":          m.Name,
			"reasoning":     m.Reasoning,
			"contextWindow": m.ContextWindow,
			"maxTokens":     m.MaxTokens,
		}
		if m.Temperature != nil {
			model["temperature"] = *m.Temperature
		}
		if m.TopP != nil {
			model["top_p"] = *m.TopP
		}
		if m.Cost != nil {
			model["cost"] = m.Cost
		}
		if len(m.Input) > 0 {
			model["input"] = m.Input
		}
		if m.Compat != nil {
			model["compat"] = m.Compat
		}
		models = append(models, model)
	}
	return models
}

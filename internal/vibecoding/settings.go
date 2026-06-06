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
	EnablePlanTool       *bool                      `json:"enablePlanTool,omitempty"`
	WebSearch            WebSearchSettings          `json:"webSearch"`
	MaxContextTokens     int                        `json:"maxContextTokens,omitempty"`
	MaxOutputTokens      int                        `json:"maxOutputTokens,omitempty"`
	ContextFiles         *ContextFilesConfig        `json:"contextFiles,omitempty"`
	SkillsDir            string                     `json:"skillsDir,omitempty"`
	Compaction           *CompactionConfig          `json:"compaction,omitempty"`
	Sandbox              *SandboxConfig             `json:"sandbox,omitempty"`
	SessionDir           string                     `json:"sessionDir,omitempty"`
	ShellPath            string                     `json:"shellPath,omitempty"`
	ShellCommandPrefix   string                     `json:"shellCommandPrefix,omitempty"`
	Theme                string                     `json:"theme,omitempty"`
	Retry                *RetryConfig               `json:"retry,omitempty"`
	Approval             *ApprovalConfig            `json:"approval,omitempty"`
}

// WebSearchSettings represents web search configuration
type WebSearchSettings struct {
	Enabled      *bool  `json:"enabled,omitempty"`
	Provider     string `json:"provider,omitempty"`
	ProviderType string `json:"providerType,omitempty"`
	Model        string `json:"model,omitempty"`
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
	BwrapPath    string   `json:"bwrapPath,omitempty"`
	AllowNetwork bool     `json:"allowNetwork"`
	AllowedRead  []string `json:"allowedRead,omitempty"`
	AllowedWrite []string `json:"allowedWrite,omitempty"`
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
	BashWhitelist      []string `json:"bashWhitelist,omitempty"`
	BashBlacklist      []string `json:"bashBlacklist,omitempty"`
	ConfirmBeforeWrite *bool    `json:"confirmBeforeWrite,omitempty"`
}

// ProviderConfig represents a provider configuration
type ProviderConfig struct {
	APIKey         string        `json:"apiKey"`
	BaseURL        string        `json:"baseUrl"`
	HTTPProxy      string        `json:"httpProxy,omitempty"`
	API            string        `json:"api"`
	ThinkingFormat string        `json:"thinkingFormat,omitempty"`
	CacheControl   *bool         `json:"cacheControl,omitempty"`
	Models         []ModelConfig `json:"models"`
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
			return DefaultSettings(), nil
		}
		return nil, fmt.Errorf("read settings: %w", err)
	}
	
	var settings VibeCodingSettings
	if err := json.Unmarshal(data, &settings); err != nil {
		return nil, fmt.Errorf("parse settings: %w", err)
	}
	
	return &settings, nil
}

// DefaultSettings returns the default settings matching vibecoding's defaults
func DefaultSettings() *VibeCodingSettings {
	return &VibeCodingSettings{
		Providers: map[string]*ProviderConfig{
			"anthropic": {
				BaseURL: "https://api.anthropic.com",
				APIKey:  "${ANTHROPIC_API_KEY}",
				API:     "anthropic-messages",
				Models: []ModelConfig{
					{ID: "claude-sonnet-4-20250514", Name: "Claude 4 Sonnet", Reasoning: true, ContextWindow: 200000, MaxTokens: 16384, Cost: &CostConfig{Input: 3.0, Output: 15.0, CacheRead: 0.3, CacheWrite: 3.75}, Input: []string{"text", "image"}},
					{ID: "claude-3-5-sonnet-20241022", Name: "Claude 3.5 Sonnet", ContextWindow: 200000, MaxTokens: 8192, Cost: &CostConfig{Input: 3.0, Output: 15.0, CacheRead: 0.3, CacheWrite: 3.75}, Input: []string{"text", "image"}},
					{ID: "claude-3-5-haiku-20241022", Name: "Claude 3.5 Haiku", ContextWindow: 200000, MaxTokens: 8192, Cost: &CostConfig{Input: 0.8, Output: 4.0, CacheRead: 0.08, CacheWrite: 1.0}, Input: []string{"text", "image"}},
					{ID: "claude-3-opus-20240229", Name: "Claude 3 Opus", ContextWindow: 200000, MaxTokens: 4096, Cost: &CostConfig{Input: 15.0, Output: 75.0, CacheRead: 1.5, CacheWrite: 18.75}, Input: []string{"text", "image"}},
				},
			},
			"deepseek-anthropic": {
				BaseURL: "https://api.deepseek.com/anthropic",
				APIKey:  "${DEEPSEEK_API_KEY}",
				API:     "anthropic-messages",
				Models: []ModelConfig{
					{ID: "deepseek-v4-flash", Name: "DeepSeek-V4-Flash", ContextWindow: 1000000, MaxTokens: 384000, Cost: &CostConfig{Input: 0.5, Output: 2}, Input: []string{"text"}},
					{ID: "deepseek-v4-pro", Name: "DeepSeek-V4-Pro", Reasoning: true, ContextWindow: 1000000, MaxTokens: 384000, Cost: &CostConfig{Input: 1, Output: 4}, Input: []string{"text"}},
				},
			},
			"deepseek-openai": {
				BaseURL: "https://api.deepseek.com",
				APIKey:  "${DEEPSEEK_API_KEY}",
				API:     "openai-chat",
				Models: []ModelConfig{
					{ID: "deepseek-v4-flash", Name: "DeepSeek-V4-Flash", ContextWindow: 1000000, MaxTokens: 384000, Cost: &CostConfig{Input: 0.5, Output: 2}, Input: []string{"text"}},
					{ID: "deepseek-v4-pro", Name: "DeepSeek-V4-Pro", Reasoning: true, ContextWindow: 1000000, MaxTokens: 384000, Cost: &CostConfig{Input: 1, Output: 4}, Input: []string{"text"}},
				},
			},
			"openai": {
				BaseURL: "https://api.openai.com/v1",
				APIKey:  "${OPENAI_API_KEY}",
				API:     "openai-responses",
				Models: []ModelConfig{
					{ID: "gpt-4o", Name: "GPT-4o", ContextWindow: 128000, MaxTokens: 16384, Cost: &CostConfig{Input: 2.5, Output: 10.0, CacheRead: 1.25, CacheWrite: 2.5}, Input: []string{"text", "image"}},
					{ID: "gpt-4o-mini", Name: "GPT-4o Mini", ContextWindow: 128000, MaxTokens: 16384, Cost: &CostConfig{Input: 0.15, Output: 0.6, CacheRead: 0.075, CacheWrite: 0.15}, Input: []string{"text", "image"}},
					{ID: "o1", Name: "o1", Reasoning: true, ContextWindow: 200000, MaxTokens: 100000, Cost: &CostConfig{Input: 15.0, Output: 60.0, CacheRead: 7.5, CacheWrite: 15.0}, Input: []string{"text", "image"}},
					{ID: "o3-mini", Name: "o3-mini", Reasoning: true, ContextWindow: 200000, MaxTokens: 100000, Cost: &CostConfig{Input: 1.1, Output: 4.4, CacheRead: 0.55, CacheWrite: 1.1}, Input: []string{"text", "image"}},
				},
			},
			"google-gemini": {
				BaseURL: "https://generativelanguage.googleapis.com/v1beta/models",
				APIKey:  "${GOOGLE_API_KEY}",
				API:     "google-gemini",
				Models: []ModelConfig{
					{ID: "gemini-2.5-pro", Name: "Gemini 2.5 Pro", Reasoning: true, ContextWindow: 1000000, MaxTokens: 65536, Input: []string{"text", "image"}},
					{ID: "gemini-2.5-flash", Name: "Gemini 2.5 Flash", Reasoning: true, ContextWindow: 1000000, MaxTokens: 65536, Input: []string{"text", "image"}},
				},
			},
			"google-vertex": {
				BaseURL: "https://aiplatform.googleapis.com/v1/projects/YOUR_PROJECT/locations/global/publishers/google/models",
				APIKey:  "${GOOGLE_VERTEX_ACCESS_TOKEN}",
				API:     "google-vertex",
				Models: []ModelConfig{
					{ID: "gemini-2.5-pro", Name: "Gemini 2.5 Pro", Reasoning: true, ContextWindow: 1000000, MaxTokens: 65536, Input: []string{"text", "image"}},
					{ID: "gemini-2.5-flash", Name: "Gemini 2.5 Flash", Reasoning: true, ContextWindow: 1000000, MaxTokens: 65536, Input: []string{"text", "image"}},
				},
			},
			"xiaomi": {
				BaseURL:        "https://api.xiaomimimo.com/v1",
				APIKey:         "${XIAOMI_API_KEY}",
				API:            "openai-chat",
				ThinkingFormat: "xiaomi",
				Models: []ModelConfig{
					{ID: "mimo-v2.5-pro", Name: "MiMo-V2.5-Pro", Reasoning: true, ContextWindow: 1000000, MaxTokens: 128000, Cost: &CostConfig{Input: 0.435, Output: 0.87, CacheRead: 0.0036}, Input: []string{"text"}},
					{ID: "mimo-v2.5", Name: "MiMo-V2.5", Reasoning: true, ContextWindow: 1000000, MaxTokens: 128000, Cost: &CostConfig{Input: 0.14, Output: 0.28, CacheRead: 0.0028}, Input: []string{"text", "image", "audio", "video"}},
					{ID: "mimo-v2-flash", Name: "MiMo-V2-Flash", Reasoning: true, ContextWindow: 256000, MaxTokens: 64000, Cost: &CostConfig{Input: 0.10, Output: 0.30, CacheRead: 0.01}, Input: []string{"text"}},
				},
			},
		},
		DefaultProvider:      "deepseek-openai",
		DefaultModel:         "deepseek-v4-flash",
		DefaultThinkingLevel: "medium",
		DefaultMode:          "agent",
		EnablePlanTool:       boolPtr(true),
		WebSearch:            WebSearchSettings{Enabled: boolPtr(false), Provider: "openai", ProviderType: "responses"},
		MaxOutputTokens:      384000,
		MaxContextTokens:     1000000,
		ContextFiles:         &ContextFilesConfig{Enabled: true},
		SkillsDir:            "~/.vibecoding/skills",
		Compaction:           &CompactionConfig{Enabled: true, ReserveTokens: 16384, KeepRecentTokens: 20000},
		Sandbox:              &SandboxConfig{Enabled: false, Level: "none", TmpSize: "100m"},
		SessionDir:           "~/.vibecoding/sessions",
		Theme:                "dark",
		Retry:                &RetryConfig{Enabled: true, MaxRetries: 3, BaseDelayMs: 2000},
		Approval: &ApprovalConfig{
			BashWhitelist:      []string{"go ", "make ", "git ", "npm ", "yarn ", "node ", "python ", "pip "},
			ConfirmBeforeWrite: boolPtr(true),
		},
	}
}

func boolPtr(v bool) *bool {
	return &v
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

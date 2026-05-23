package vibecoding

import (
	"context"
	"fmt"
	"os"
	"sync"
)

// AgentManager manages ACP connections to VibeCoding
type AgentManager struct {
	client    *ACPClient
	sessions  map[string]bool
	mu        sync.RWMutex
	connected bool
	config    *SessionConfig
}

// ChatEvent represents a chat event for frontend
type ChatEvent struct {
	Type    string      `json:"type"`
	Content string      `json:"content,omitempty"`
	Data    interface{} `json:"data,omitempty"`
	Error   string      `json:"error,omitempty"`
}

// NewAgentManager creates a new agent manager
func NewAgentManager(vibecodingPath string, config *SessionConfig) (*AgentManager, error) {
	am := &AgentManager{
		sessions: make(map[string]bool),
		config:   config,
	}
	
	// Create ACP client
	client, err := NewACPClient(vibecodingPath, config)
	if err != nil {
		return nil, fmt.Errorf("create ACP client: %w", err)
	}
	am.client = client
	
	// Initialize
	result, err := client.Initialize("VibeCoding GUI", "1.0.0")
	if err != nil {
		client.Close()
		return nil, fmt.Errorf("initialize ACP: %w", err)
	}
	
	am.connected = true
	fmt.Printf("Connected to VibeCoding %s (v%s)\n", result.AgentInfo.Title, result.AgentInfo.Version)
	
	return am, nil
}

// CreateSession creates a new session
func (am *AgentManager) CreateSession() (string, error) {
	am.mu.Lock()
	defer am.mu.Unlock()
	
	cwd, err := os.Getwd()
	if err != nil {
		return "", err
	}
	
	sessionID, err := am.client.NewSession(cwd)
	if err != nil {
		return "", err
	}
	
	am.sessions[sessionID] = true
	return sessionID, nil
}

// Chat sends a message and streams response
func (am *AgentManager) Chat(ctx context.Context, sessionID, message string) (<-chan ChatEvent, error) {
	am.mu.RLock()
	_, exists := am.sessions[sessionID]
	am.mu.RUnlock()
	
	if !exists {
		return nil, fmt.Errorf("session not found: %s", sessionID)
	}
	
	events := make(chan ChatEvent, 100)
	
	go func() {
		defer close(events)
		
		// Create a done channel for the ACP event listener
		done := make(chan struct{})
		defer close(done)
		
		// Listen for ACP events
		go func() {
			for {
				select {
				case event, ok := <-am.client.Events():
					if !ok {
						return
					}
					chatEvent := ChatEvent{
						Type:    event.Type,
						Content: event.Content,
						Data:    event.Data,
					}
					
					select {
					case events <- chatEvent:
					case <-done:
						return
					case <-ctx.Done():
						return
					}
				case <-done:
					return
				case <-ctx.Done():
					return
				}
			}
		}()
		
		// Send prompt
		stopReason, err := am.client.Prompt(sessionID, message)
		if err != nil {
			select {
			case events <- ChatEvent{
				Type:  "error",
				Error: err.Error(),
			}:
			case <-ctx.Done():
			}
			return
		}
		
		// Send done event
		select {
		case events <- ChatEvent{
			Type: "done",
			Data: map[string]interface{}{
				"stopReason": stopReason,
			},
		}:
		case <-ctx.Done():
		}
	}()
	
	return events, nil
}

// Abort aborts the current operation
func (am *AgentManager) Abort(sessionID string) error {
	am.mu.RLock()
	_, exists := am.sessions[sessionID]
	am.mu.RUnlock()
	
	if !exists {
		return fmt.Errorf("session not found: %s", sessionID)
	}
	
	return am.client.Cancel(sessionID)
}

// SendPermissionResponse sends a permission response
func (am *AgentManager) SendPermissionResponse(requestID string, optionID string) error {
	return am.client.SendPermissionResponse(requestID, optionID)
}

// GetConfig returns the current configuration
func (am *AgentManager) GetConfig() *SessionConfig {
	return am.config
}

// Close closes the agent manager
func (am *AgentManager) Close() error {
	if am.client != nil {
		return am.client.Close()
	}
	return nil
}

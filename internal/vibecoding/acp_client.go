package vibecoding

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"sync"
	"sync/atomic"
)

// ACPClient communicates with VibeCoding via ACP protocol
type ACPClient struct {
	cmd    *exec.Cmd
	stdin  io.WriteCloser
	stdout *bufio.Reader
	mu     sync.Mutex
	
	nextID   atomic.Int64
	pending  map[int64]chan *rpcResponse
	events   chan ACPEvent
	sessions map[string]bool
	
	ctx    context.Context
	cancel context.CancelFunc
}

// ACPEvent represents an event from ACP
type ACPEvent struct {
	Type      string      `json:"type"`
	SessionID string      `json:"sessionId,omitempty"`
	Content   string      `json:"content,omitempty"`
	Data      interface{} `json:"data,omitempty"`
}

// rpcRequest represents a JSON-RPC request
type rpcRequest struct {
	JSONRPC string      `json:"jsonrpc"`
	ID      int64       `json:"id"`
	Method  string      `json:"method"`
	Params  interface{} `json:"params,omitempty"`
}

// rpcResponse represents a JSON-RPC response
type rpcResponse struct {
	JSONRPC string          `json:"jsonrpc"`
	ID      int64           `json:"id"`
	Result  json.RawMessage `json:"result,omitempty"`
	Error   *rpcError       `json:"error,omitempty"`
}

type rpcError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

// sessionUpdate represents a session update event
type sessionUpdate struct {
	SessionUpdate string      `json:"sessionUpdate"`
	Content       *contentBlock `json:"content,omitempty"`
	ToolCallID    string      `json:"toolCallId,omitempty"`
	Title         string      `json:"title,omitempty"`
	Kind          string      `json:"kind,omitempty"`
	Status        string      `json:"status,omitempty"`
	RawInput      map[string]any `json:"rawInput,omitempty"`
	RawOutput     map[string]any `json:"rawOutput,omitempty"`
}

type contentBlock struct {
	Type     string `json:"type"`
	Text     string `json:"text,omitempty"`
	MimeType string `json:"mimeType,omitempty"`
}

// InitializeResult represents the initialize response
type InitializeResult struct {
	ProtocolVersion   int    `json:"protocolVersion"`
	AgentCapabilities struct {
		LoadSession bool `json:"loadSession"`
		PromptCapabilities struct {
			Image           bool `json:"image"`
			Audio           bool `json:"audio"`
			EmbeddedContext bool `json:"embeddedContext"`
		} `json:"promptCapabilities"`
		SessionCapabilities struct {
			Cancel bool `json:"cancel"`
			Close  bool `json:"close"`
			List   bool `json:"list"`
		} `json:"sessionCapabilities"`
	} `json:"agentCapabilities"`
	AgentInfo struct {
		Name    string `json:"name"`
		Title   string `json:"title"`
		Version string `json:"version"`
	} `json:"agentInfo"`
}

// SessionConfig represents session configuration

type SessionConfig struct {
	Cwd       string `json:"cwd"`
	Provider  string `json:"provider,omitempty"`
	Model     string `json:"model,omitempty"`
	Mode      string `json:"mode,omitempty"`
	Thinking  string `json:"thinking,omitempty"`
}

// NewACPClient creates a new ACP client
func NewACPClient(vibecodingPath string, config *SessionConfig) (*ACPClient, error) {
	ctx, cancel := context.WithCancel(context.Background())
	
	client := &ACPClient{
		pending:  make(map[int64]chan *rpcResponse),
		events:   make(chan ACPEvent, 100),
		sessions: make(map[string]bool),
		ctx:      ctx,
		cancel:   cancel,
	}
	
	// Build command args
	args := []string{"acp"}
	if config != nil {
		if config.Provider != "" {
			args = append(args, "--provider", config.Provider)
		}
		if config.Model != "" {
			args = append(args, "--model", config.Model)
		}
		if config.Mode != "" {
			args = append(args, "--mode", config.Mode)
		}
		if config.Thinking != "" {
			args = append(args, "--thinking", config.Thinking)
		}
	}
	
	// Start VibeCoding in ACP mode
	client.cmd = exec.CommandContext(ctx, vibecodingPath, args...)
	
	var err error
	client.stdin, err = client.cmd.StdinPipe()
	if err != nil {
		cancel()
		return nil, fmt.Errorf("stdin pipe: %w", err)
	}
	
	stdoutPipe, err := client.cmd.StdoutPipe()
	if err != nil {
		cancel()
		return nil, fmt.Errorf("stdout pipe: %w", err)
	}
	client.stdout = bufio.NewReader(stdoutPipe)
	
	// Redirect stderr to os.Stderr for debugging
	client.cmd.Stderr = os.Stderr
	
	if err := client.cmd.Start(); err != nil {
		cancel()
		return nil, fmt.Errorf("start vibecoding: %w", err)
	}
	
	// Start response reader
	go client.readResponses()
	
	return client, nil
}

// Initialize sends initialize request
func (c *ACPClient) Initialize(clientName, clientVersion string) (*InitializeResult, error) {
	result, err := c.call("initialize", map[string]interface{}{
		"protocolVersion": 1,
		"clientInfo": map[string]interface{}{
			"name":    clientName,
			"version": clientVersion,
		},
		"clientCapabilities": map[string]interface{}{
			"session": map[string]bool{
				"cancel": true,
			},
		},
	})
	if err != nil {
		return nil, err
	}
	
	var initResult InitializeResult
	if err := json.Unmarshal(result, &initResult); err != nil {
		return nil, fmt.Errorf("parse initialize result: %w", err)
	}
	
	return &initResult, nil
}

// NewSession creates a new session
func (c *ACPClient) NewSession(cwd string) (string, error) {
	result, err := c.call("session/new", map[string]interface{}{
		"cwd": cwd,
	})
	if err != nil {
		return "", err
	}
	
	var sessionResult struct {
		SessionID string `json:"sessionId"`
	}
	if err := json.Unmarshal(result, &sessionResult); err != nil {
		return "", fmt.Errorf("parse session result: %w", err)
	}
	
	c.mu.Lock()
	c.sessions[sessionResult.SessionID] = true
	c.mu.Unlock()
	
	return sessionResult.SessionID, nil
}

// LoadSession loads an existing session
func (c *ACPClient) LoadSession(sessionID, cwd string) error {
	_, err := c.call("session/load", map[string]interface{}{
		"sessionId": sessionID,
		"cwd":       cwd,
	})
	if err != nil {
		return err
	}
	
	c.mu.Lock()
	c.sessions[sessionID] = true
	c.mu.Unlock()
	
	return nil
}

// Prompt sends a prompt to a session
func (c *ACPClient) Prompt(sessionID, text string) (string, error) {
	result, err := c.call("session/prompt", map[string]interface{}{
		"sessionId": sessionID,
		"prompt": []map[string]interface{}{
			{
				"type": "text",
				"text": text,
			},
		},
	})
	if err != nil {
		return "", err
	}
	
	var promptResult struct {
		StopReason string `json:"stopReason"`
	}
	if err := json.Unmarshal(result, &promptResult); err != nil {
		return "", fmt.Errorf("parse prompt result: %w", err)
	}
	
	return promptResult.StopReason, nil
}

// Cancel cancels a session
func (c *ACPClient) Cancel(sessionID string) error {
	_, err := c.call("session/cancel", map[string]interface{}{
		"sessionId": sessionID,
	})
	return err
}

// Events returns the event channel
func (c *ACPClient) Events() <-chan ACPEvent {
	return c.events
}

// SendPermissionResponse sends a permission response
func (c *ACPClient) SendPermissionResponse(requestID string, optionID string) error {
	// requestID is a string like "acp-1"
	fmt.Fprintf(os.Stderr, "[ACP PERMISSION] sending response: requestID=%s option=%s\n", requestID, optionID)
	
	// Send response as JSON-RPC response
	response := map[string]interface{}{
		"jsonrpc": "2.0",
		"id":      requestID,
		"result": map[string]interface{}{
			"outcome": map[string]interface{}{
				"outcome":  "selected",
				"optionId": optionID,
			},
		},
	}
	
	data, err := json.Marshal(response)
	if err != nil {
		return fmt.Errorf("marshal response: %w", err)
	}
	
	// Send response
	c.mu.Lock()
	defer c.mu.Unlock()
	
	_, err = c.stdin.Write(append(data, '\n'))
	if err != nil {
		return fmt.Errorf("write response: %w", err)
	}
	
	fmt.Fprintf(os.Stderr, "[ACP PERMISSION] sent response successfully\n")
	
	return nil
}

// Close closes the ACP client
func (c *ACPClient) Close() error {
	c.cancel()
	if c.stdin != nil {
		c.stdin.Close()
	}
	if c.cmd != nil && c.cmd.Process != nil {
		return c.cmd.Wait()
	}
	return nil
}

// call sends a JSON-RPC request and waits for response
func (c *ACPClient) call(method string, params interface{}) (json.RawMessage, error) {
	id := c.nextID.Add(1)
	
	req := rpcRequest{
		JSONRPC: "2.0",
		ID:      id,
		Method:  method,
		Params:  params,
	}
	
	// Create response channel
	ch := make(chan *rpcResponse, 1)
	c.mu.Lock()
	c.pending[id] = ch
	c.mu.Unlock()
	
	// Send request
	data, err := json.Marshal(req)
	if err != nil {
		c.mu.Lock()
		delete(c.pending, id)
		c.mu.Unlock()
		return nil, fmt.Errorf("marshal request: %w", err)
	}
	
	c.mu.Lock()
	_, err = c.stdin.Write(append(data, '\n'))
	c.mu.Unlock()
	if err != nil {
		c.mu.Lock()
		delete(c.pending, id)
		c.mu.Unlock()
		return nil, fmt.Errorf("write request: %w", err)
	}
	
	// Wait for response
	select {
	case resp := <-ch:
		if resp.Error != nil {
			return nil, fmt.Errorf("ACP error %d: %s", resp.Error.Code, resp.Error.Message)
		}
		return resp.Result, nil
	case <-c.ctx.Done():
		c.mu.Lock()
		delete(c.pending, id)
		c.mu.Unlock()
		return nil, context.Canceled
	}
}

// readResponses reads responses from stdout
func (c *ACPClient) readResponses() {
	for {
		select {
		case <-c.ctx.Done():
			return
		default:
		}
		
		line, err := c.stdout.ReadBytes('\n')
		if err != nil {
			if err == io.EOF {
				break
			}
			continue
		}
		
		// Debug: print raw line
		fmt.Fprintf(os.Stderr, "[ACP RAW] %s", line)
		
		// Try to parse as response with numeric ID
		var resp rpcResponse
		if err := json.Unmarshal(line, &resp); err == nil && resp.ID > 0 {
			c.mu.Lock()
			ch, ok := c.pending[resp.ID]
			if ok {
				delete(c.pending, resp.ID)
			}
			c.mu.Unlock()
			
			if ok {
				ch <- &resp
			}
			continue
		}
		
		// Try to parse as notification/event (includes request_permission)
		var notification struct {
			JSONRPC string          `json:"jsonrpc"`
			Method  string          `json:"method"`
			ID      json.RawMessage `json:"id"`
			Params  json.RawMessage `json:"params"`
		}
		if err := json.Unmarshal(line, &notification); err == nil && notification.Method != "" {
			// For request_permission, pass the full line; for others, pass params
			if notification.Method == "session/request_permission" {
				c.handleNotification(notification.Method, line)
			} else {
				c.handleNotification(notification.Method, notification.Params)
			}
		}
	}
}

// handleNotification handles a JSON-RPC notification
func (c *ACPClient) handleNotification(method string, params json.RawMessage) {
	// Debug: print notification
	fmt.Fprintf(os.Stderr, "[ACP EVENT] method=%s\n", method)
	
	switch method {
	case "session/update":
		// Parse the nested structure
		var notification struct {
			SessionID string `json:"sessionId"`
			Update    struct {
				SessionUpdate string      `json:"sessionUpdate"`
				Content       *contentBlock `json:"content,omitempty"`
				ToolCallID    string        `json:"toolCallId,omitempty"`
				Title         string        `json:"title,omitempty"`
				Kind          string        `json:"kind,omitempty"`
				Status        string        `json:"status,omitempty"`
				RawInput      map[string]any `json:"rawInput,omitempty"`
				RawOutput     map[string]any `json:"rawOutput,omitempty"`
			} `json:"update"`
		}
		
		if err := json.Unmarshal(params, &notification); err != nil {
			fmt.Fprintf(os.Stderr, "[ACP ERROR] parse notification: %v\n", err)
			return
		}
		
		update := notification.Update
		event := ACPEvent{
			Type:      update.SessionUpdate,
			SessionID: notification.SessionID,
		}
		
		switch update.SessionUpdate {
		case "agent_thought_chunk", "agent_message_chunk":
			// These are content updates
			event.Type = "content"
			if update.Content != nil {
				event.Content = update.Content.Text
				event.Data = map[string]interface{}{
					"type":       update.Content.Type,
					"chunkType":  update.SessionUpdate,
				}
				fmt.Fprintf(os.Stderr, "[ACP DEBUG] content chunk: text=%s\n", update.Content.Text)
			} else {
				fmt.Fprintf(os.Stderr, "[ACP DEBUG] content is nil for %s\n", update.SessionUpdate)
				// Try to extract content from raw JSON
				var rawUpdate struct {
					Content struct {
						Type string `json:"type"`
						Text string `json:"text"`
					} `json:"content"`
				}
				if err := json.Unmarshal(params, &rawUpdate); err == nil {
					event.Content = rawUpdate.Content.Text
					event.Data = map[string]interface{}{
						"type":       rawUpdate.Content.Type,
						"chunkType":  update.SessionUpdate,
					}
					fmt.Fprintf(os.Stderr, "[ACP DEBUG] extracted from raw: text=%s\n", rawUpdate.Content.Text)
				}
			}
		case "content":
			if update.Content != nil {
				event.Content = update.Content.Text
				event.Data = map[string]interface{}{
					"type": update.Content.Type,
				}
			}
		case "tool_call":
			event.Data = map[string]interface{}{
				"id":     update.ToolCallID,
				"title":  update.Title,
				"kind":   update.Kind,
				"status": update.Status,
				"input":  update.RawInput,
			}
		case "tool_call_update":
			event.Type = "toolCallUpdate"
			event.Data = map[string]interface{}{
				"id":     update.ToolCallID,
				"title":  update.Title,
				"status": update.Status,
				"output": update.RawOutput,
			}
			if update.RawOutput != nil {
				fmt.Fprintf(os.Stderr, "[ACP DEBUG] rawOutput type=%T value=%v\n", update.RawOutput["content"], update.RawOutput["content"])
				if content, ok := update.RawOutput["content"].(string); ok {
					event.Content = content
					fmt.Fprintf(os.Stderr, "[ACP DEBUG] extracted content len=%d\n", len(content))
				} else {
					fmt.Fprintf(os.Stderr, "[ACP DEBUG] content is not string type\n")
				}
			}
		case "status":
			event.Data = map[string]interface{}{
				"status": update.Status,
			}
		}
		
		// Debug: print event being sent
		fmt.Fprintf(os.Stderr, "[ACP EVENT SEND] type=%s content_len=%d\n", event.Type, len(event.Content))
		
		select {
		case c.events <- event:
		default:
			// Drop event if channel is full
			fmt.Fprintf(os.Stderr, "[ACP EVENT DROP] channel full\n")
		}
	
	case "session/request_permission":
		// Parse permission request from full JSON
		var request struct {
			ID     string `json:"id"`
			Params struct {
				SessionID string `json:"sessionId"`
				ToolCall  struct {
					ToolCallID string         `json:"toolCallId"`
					Title      string         `json:"title"`
					Kind       string         `json:"kind"`
					Status     string         `json:"status"`
					RawInput   map[string]any `json:"rawInput"`
				} `json:"toolCall"`
				Options []struct {
					OptionID string `json:"optionId"`
					Name     string `json:"name"`
					Kind     string `json:"kind"`
				} `json:"options"`
			} `json:"params"`
		}
		
		if err := json.Unmarshal(params, &request); err != nil {
			fmt.Fprintf(os.Stderr, "[ACP ERROR] parse permission request: %v\n", err)
			return
		}
		
		// Use the ID from the request
		requestID := request.ID
		if requestID == "" {
			fmt.Fprintf(os.Stderr, "[ACP ERROR] empty request ID\n")
			return
		}
		
		fmt.Fprintf(os.Stderr, "[ACP PERMISSION] requestID=%s title=%s\n", requestID, request.Params.ToolCall.Title)
		
		// Send permission request event
		event := ACPEvent{
			Type: "permission_request",
			Data: map[string]interface{}{
				"requestId":  requestID,
				"sessionId":  request.Params.SessionID,
				"toolCallId": request.Params.ToolCall.ToolCallID,
				"title":      request.Params.ToolCall.Title,
				"kind":       request.Params.ToolCall.Kind,
				"input":      request.Params.ToolCall.RawInput,
				"options":    request.Params.Options,
			},
		}
		
		select {
		case c.events <- event:
		default:
			fmt.Fprintf(os.Stderr, "[ACP EVENT DROP] channel full\n")
		}
	}
}

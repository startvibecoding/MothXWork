(workflow "go-to-dart-migration"
  (concurrency 3)

  ;; Phase 1: Deep scan of Go source modules in parallel
  (phase "scan-go"
    (parallel
      (agent "scan-provider"
        :mode "plan"
        :tools '("read" "grep" "find")
        :max-iterations 100
        :prompt (concat
          "Analyze the Go provider system in /home/free/src/vibecoding/internal/provider/.\n"
          "Read these files: provider.go, types.go, vendor.go, registry.go, retry.go, base.go, http_client.go, hosted_tools.go\n"
          "Also read factory/factory.go and one vendor adapter (e.g. vendor_openai.go, vendor_anthropic.go).\n"
          "Produce a structured summary:\n"
          "1. Provider interface methods and ChatParams/StreamEvent types\n"
          "2. Message/ContentBlock/ToolCallBlock/Usage/Cost data models\n"
          "3. VendorAdapter pattern: how vendors register, matchBaseURL, apply defaults\n"
          "4. ProviderRegistry + ResolveProvider 3-level fallback\n"
          "5. Factory.Create flow: settings -> provider+model resolution\n"
          "6. RetryConfig and IsRetryable logic\n"
          "7. CacheControl and ModelCompat flags\n"
          "Return the complete analysis as structured text."))

      (agent "scan-agent"
        :mode "plan"
        :tools '("read" "grep" "find")
        :max-iterations 100
        :prompt (concat
          "Analyze the Go agent loop in /home/free/src/vibecoding/internal/agent/.\n"
          "Read these files: agent.go, eventloop.go, events.go, manager.go, factory.go, provider.go, system_prompt.go\n"
          "Also read /home/free/src/vibecoding/internal/context/compaction.go and context.go and tokenizer.go.\n"
          "Produce a structured summary:\n"
          "1. Agent struct fields and Config/AgentLoopConfig\n"
          "2. The main loop() flow: steering messages -> frozen prompt -> cache markers -> provider.Chat -> stream processing -> tool execution -> compaction check\n"
          "3. Event types (EventType enum) and Event struct fields\n"
          "4. Cache marker algorithm (selectCacheMarkers, applyCacheMarkers) dual-marker rolling buffer\n"
          "5. Context guard: replaceLargestToolResultForContext\n"
          "6. Compaction: ShouldCompact, Compact, FindCutPoint, SerializeConversation\n"
          "7. Token estimation: estimateTextTokens, estimateChatRequestTokens\n"
          "8. AgentManager and AgentFactory patterns\n"
          "9. Approval/Question mechanism\n"
          "10. Session context message (buildSessionContextMessage)\n"
          "Return the complete analysis as structured text."))

      (agent "scan-session"
        :mode "plan"
        :tools '("read" "grep" "find")
        :max-iterations 80
        :prompt (concat
          "Analyze the Go session system in /home/free/src/vibecoding/internal/session/.\n"
          "Read: session.go, entry.go\n"
          "Also read /home/free/src/vibecoding/internal/config/settings.go for the full Settings struct.\n"
          "Produce a structured summary:\n"
          "1. Session Manager: Init, AppendMessage, AppendModelChange, AppendCompaction, GetMessages, GetReplayState\n"
          "2. Entry types: Header, MessageEntry, ModelChangeEntry, CompactionEntry, SessionInfoEntry\n"
          "3. SQLite schema: sessions table, entries table\n"
          "4. Replay state: buildReplayState, applyCompactionEntry\n"
          "5. Settings struct: all fields, ProviderConfig, ModelConfig, ModelCompat, CompactionSettings, SandboxSettings, ApprovalSettings, RetrySettings\n"
          "6. DefaultSettings: all default provider/model definitions\n"
          "Return the complete analysis as structured text."))))

  ;; Phase 2: Scan existing Dart codebase
  (phase "scan-dart"
    (agent "scan-existing-dart"
      :mode "plan"
      :tools '("read" "grep" "find")
      :max-iterations 80
      :prompt (concat
        "Analyze the existing Flutter/Dart codebase in /home/free/src/vibecoding-gui/lib/.\n"
        "Read ALL files: core/agent.dart, core/provider.dart, core/session.dart, core/settings.dart,\n"
        "core/tools/registry.dart, core/tools/file_tools.dart, core/tools/search_tools.dart, core/tools/shell_tool.dart,\n"
        "models/models.dart, services/acp_client.dart, services/app_state.dart, services/config_service.dart\n"
        "Produce a gap analysis:\n"
        "1. What exists vs what Go has\n"
        "2. Missing features in provider.dart (only openai-chat + anthropic-messages, no vendor adapters, no retry, no cache control)\n"
        "3. Missing features in agent.dart (no compaction, no cache markers, no token budgeting, max 15 iterations, only 1 tool call per turn)\n"
        "4. Missing features in session.dart (JSONL vs SQLite, no compaction entries, no replay state)\n"
        "5. Missing features in settings.dart (no ModelCompat, no CompactionSettings, no RetrySettings)\n"
        "6. What tools are implemented vs Go tools\n"
        "Return the complete gap analysis.")))

  ;; Phase 3: Design the Dart migration architecture
  (phase "design"
    (agent "architect"
      :mode "plan"
      :tools '("read")
      :max-iterations 80
      :prompt (concat
        "Based on the Go source analysis and Dart gap analysis below, design the complete Dart migration architecture.\n\n"
        "=== GO PROVIDER ANALYSIS ===\n"
        (result "scan-go.scan-provider")
        "\n\n=== GO AGENT ANALYSIS ===\n"
        (result "scan-go.scan-agent")
        "\n\n=== GO SESSION ANALYSIS ===\n"
        (result "scan-go.scan-session")
        "\n\n=== DART GAP ANALYSIS ===\n"
        (result "scan-dart.scan-existing-dart")
        "\n\nProduce a detailed implementation plan:\n"
        "1. File-by-file migration plan: which Go files map to which Dart files\n"
        "2. New Dart files to create (with full path under lib/core/)\n"
        "3. Data model changes: what to add to models.dart or create new model files\n"
        "4. Provider system: vendor_adapter.dart, provider_registry.dart, provider_factory.dart, retry.dart\n"
        "5. Agent loop: complete rewrite of agent.dart with cache markers, compaction, token budgeting\n"
        "6. Session: migrate to SQLite using sqflite package\n"
        "7. Settings: add CompactionSettings, RetrySettings, ModelCompat\n"
        "8. pubspec.yaml dependency changes needed\n"
        "9. Migration order: which files to create/modify first\n"
        "Return the complete implementation plan.")))

  ;; Phase 4: Implement in parallel batches
  (phase "implement-batch1"
    (parallel
      ;; 4a: Data models
      (agent "impl-models"
        :mode "agent"
        :tools '("read" "write" "edit")
        :max-iterations 150
        :prompt (concat
          "Implement the Dart data models for the Go-to-Dart migration.\n\n"
          "REFERENCE PLAN:\n"
          (result "design.architect")
          "\n\n"
          "Working directory: /home/free/src/vibecoding-gui\n\n"
          "Tasks:\n"
          "1. Read /home/free/src/vibecoding-gui/lib/core/settings.dart\n"
          "2. Add these missing classes/fields to match Go's config/settings.go:\n"
          "   - ModelCompat class (all fields from Go ModelCompat)\n"
          "   - CompactionSettings class (enabled, reserveTokens, keepRecentTokens, tokenizer, idleCompression settings)\n"
          "   - RetrySettings class (enabled, maxRetries, baseDelayMs)\n"
          "   - WebSearchSettings class\n"
          "   - ResponsesConfig class\n"
          "   - CostConfig class\n"
          "   - Update ProviderConfig to include ResponsesConfig, Headers map\n"
          "   - Update Settings to include compaction, retry, webSearch, contextFiles fields\n"
          "   - Update ModelConfig to include CostConfig, ModelCompat\n"
          "3. Read /home/free/src/vibecoding-gui/lib/models/models.dart\n"
          "4. Add these missing models:\n"
          "   - ContentBlock class (type, text, thinking, signature, image, toolCall, cacheControl)\n"
          "   - ToolCallBlock class (id, name, arguments, invalidArguments)\n"
          "   - CacheControl class\n"
          "   - Usage class (input, output, reasoning, cacheRead, cacheWrite, totalTokens, cost, with CalculateCost and CacheInfo)\n"
          "   - Cost class\n"
          "   - ModelPricing class\n"
          "   - ImageContent class\n"
          "   - Update ChatMessage to support contents (List<ContentBlock>) in addition to simple content string\n"
          "5. Ensure all classes have fromJson/toJson factories\n"
          "6. Preserve backward compatibility with existing code that uses these models"))

      ;; 4b: Vendor adapter system
      (agent "impl-vendor"
        :mode "agent"
        :tools '("read" "write" "edit")
        :max-iterations 150
        :prompt (concat
          "Implement the Dart vendor adapter system.\n\n"
          "REFERENCE PLAN:\n"
          (result "design.architect")
          "\n\n"
          "Go source reference: /home/free/src/vibecoding/internal/provider/vendor.go\n"
          "Working directory: /home/free/src/vibecoding-gui\n\n"
          "Tasks:\n"
          "1. Create /home/free/src/vibecoding-gui/lib/core/provider/vendor_adapter.dart:\n"
          "   - VendorAdapter abstract class with name(), matchBaseURL(baseURL), apply(AdapterConfig)\n"
          "   - SimpleVendorAdapter implementation\n"
          "   - VendorRegistry: registerVendorAdapter, getVendorAdapter, listVendorAdapters\n"
          "   - ResolveAdapterConfig function (vendor + baseUrl auto-detect + protocol fallback)\n"
          "   - AdapterConfig class (vendor, api, baseURL, thinkingFormat, cacheControl)\n"
          "2. Create /home/free/src/vibecoding-gui/lib/core/provider/vendor_registry.dart:\n"
          "   - Register all vendors from Go: openai, anthropic, deepseek, google-gemini, google-vertex,\n"
          "     groq, cerebras, xai, moonshotai, nvidia, together, fireworks, huggingface, openrouter,\n"
          "     volcengine, minimax, kimi, bailian, qianfan, cloudflare, xiaomi, zai, etc.\n"
          "   - Each vendor with its domains, defaultAPI, thinkingFormat, cacheControl\n"
          "3. Create /home/free/src/vibecoding-gui/lib/core/provider/retry.dart:\n"
          "   - RetryConfig class\n"
          "   - IsRetryable function (429, 502, 503, 504, network errors)\n"
          "   - RetryDelay calculator (exponential backoff with jitter)\n"
          "   - wrapWithRetry function for Stream<T>"))

      ;; 4c: Provider registry and factory
      (agent "impl-provider-registry"
        :mode "agent"
        :tools '("read" "write" "edit")
        :max-iterations 150
        :prompt (concat
          "Implement the Dart provider registry and factory.\n\n"
          "REFERENCE PLAN:\n"
          (result "design.architect")
          "\n\n"
          "Go source references:\n"
          "  /home/free/src/vibecoding/internal/provider/registry.go\n"
          "  /home/free/src/vibecoding/internal/provider/factory/factory.go\n"
          "Working directory: /home/free/src/vibecoding-gui\n\n"
          "Tasks:\n"
          "1. Create /home/free/src/vibecoding-gui/lib/core/provider/provider_registry.dart:\n"
          "   - ProviderRegistry class with register(name, factory), create(name, cfg), list(), has()\n"
          "   - Global registry instance\n"
          "   - ResolveProvider function with 3-level fallback: vendor explicit -> baseUrl auto-detect -> generic fallback\n"
          "2. Create /home/free/src/vibecoding-gui/lib/core/provider/provider_factory.dart:\n"
          "   - ProviderFactory.create(settings, providerName, modelID) -> (Provider, Model)\n"
          "   - Support openai-chat, openai-responses, anthropic-messages, google-gemini, google-vertex API types\n"
          "   - ConvertModelConfigs: config ModelConfig -> provider Model\n"
          "   - applyModelOverrides\n"
          "   - ConfigureRetry, ConfigureHeaders\n"
          "3. Update /home/free/src/vibecoding-gui/lib/core/provider.dart:\n"
          "   - Split into proper files under lib/core/provider/\n"
          "   - Create provider interface (abstract class Provider with chat, name, models, getModel)\n"
          "   - Create OpenAI provider implementation\n"
          "   - Create Anthropic provider implementation\n"
          "   - Support streaming with proper StreamEvent types (textDelta, thinkDelta, toolCall, usage, done, error)\n"
          "   - Support cache_control markers in messages\n"
          "   - Support thinking/reasoning content blocks\n"
          "   - Support parallel tool calls in a single response"))))

  ;; Phase 5: Implement agent loop and session (depends on batch1)
  (phase "implement-batch2"
    (parallel
      ;; 5a: Agent loop rewrite
      (agent "impl-agent"
        :mode "agent"
        :tools '("read" "write" "edit")
        :max-iterations 200
        :prompt (concat
          "Rewrite the Dart agent loop to match Go's agent.go.\n\n"
          "REFERENCE PLAN:\n"
          (result "design.architect")
          "\n\n"
          "Go source: /home/free/src/vibecoding/internal/agent/agent.go\n"
          "Working directory: /home/free/src/vibecoding-gui\n\n"
          "Tasks:\n"
          "1. Rewrite /home/free/src/vibecoding-gui/lib/core/agent.dart with these features from Go:\n"
          "   - Agent class with Config and AgentLoopConfig\n"
          "   - Frozen system prompt and tool defs (built once at construction, R2.1)\n"
          "   - buildSessionContextMessage (R2.3: dynamic info as separate system-injected message)\n"
          "   - Main loop: steering messages -> frozen prompt -> cache markers -> provider.chat -> stream processing -> tool execution (parallel) -> compaction check\n"
          "   - selectCacheMarkers + applyCacheMarkers (dual-marker rolling buffer, R3.1-R3.3)\n"
          "   - Context guard: replaceLargestToolResultForContext\n"
          "   - Token budgeting: requestTokenBudget, prepareRequestMessages\n"
          "   - ShouldCompact + Compact (context compaction)\n"
          "   - ShouldStopAfterTurn, PrepareNextTurn callbacks\n"
          "   - GetSteeringMessages, GetFollowUpMessages\n"
          "   - Consecutive no-text loop detection with warning\n"
          "   - Context pressure and budget pressure events\n"
          "   - Parallel tool execution (executeToolCallsParallel)\n"
          "   - Approval mechanism (NeedsApproval, RequestApproval)\n"
          "   - Support for multiple tool calls per turn (currently only handles 1)\n"
          "   - Proper event stream with all EventTypes\n"
          "2. Create /home/free/src/vibecoding-gui/lib/core/agent_events.dart:\n"
          "   - EventType enum matching Go's EventType\n"
          "   - AgentEvent class with all fields from Go's Event struct\n"
          "3. Create /home/free/src/vibecoding-gui/lib/core/compaction.dart:\n"
          "   - CompactionSettings, FindCutPoint, SerializeConversation\n"
          "   - Token estimation (GenericTokenEstimator)\n"
          "   - HasCompactableMessages, ShouldCompact\n"
          "   - ContextUsage class"))

      ;; 5b: Session SQLite migration
      (agent "impl-session"
        :mode "agent"
        :tools '("read" "write" "edit")
        :max-iterations 150
        :prompt (concat
          "Rewrite the Dart session manager to use SQLite like Go's session.go.\n\n"
          "REFERENCE PLAN:\n"
          (result "design.architect")
          "\n\n"
          "Go source: /home/free/src/vibecoding/internal/session/session.go, entry.go\n"
          "Working directory: /home/free/src/vibecoding-gui\n\n"
          "Tasks:\n"
          "1. Add sqflite to /home/free/src/vibecoding-gui/pubspec.yaml dependencies\n"
          "2. Rewrite /home/free/src/vibecoding-gui/lib/core/session.dart:\n"
          "   - SessionManager with SQLite backend (sessions table + entries table)\n"
          "   - Init/InitWithID, Open, OpenByID, ContinueRecent\n"
          "   - AppendMessage, AppendModelChange, AppendThinkingLevelChange, AppendCompaction, AppendSessionInfo\n"
          "   - GetMessages, GetReplayState (with compaction support)\n"
          "   - GetLatestCompaction\n"
          "   - ReplayState with applyCompactionEntry\n"
          "   - ListForDir, ListForDirDetailed\n"
          "   - DeleteSession\n"
          "   - Entry types: Header, MessageEntry, ModelChangeEntry, CompactionEntry, SessionInfoEntry\n"
          "   - EntryBase with id, parentId, timestamp\n"
          "   - GenerateID function\n"
          "   - encodePath for directory-based session organization\n"
          "3. Keep backward compatibility with existing JSONL format for migration"))

      ;; 5c: Provider implementations
      (agent "impl-providers"
        :mode "agent"
        :tools '("read" "write" "edit")
        :max-iterations 200
        :prompt (concat
          "Implement the Dart provider implementations (OpenAI + Anthropic).\n\n"
          "REFERENCE PLAN:\n"
          (result "design.architect")
          "\n\n"
          "Go source references:\n"
          "  /home/free/src/vibecoding/internal/provider/openai/provider.go\n"
          "  /home/free/src/vibecoding/internal/provider/anthropic/provider.go\n"
          "Working directory: /home/free/src/vibecoding-gui\n\n"
          "Tasks:\n"
          "1. Create /home/free/src/vibecoding-gui/lib/core/provider/openai_provider.dart:\n"
          "   - OpenAI provider implementing Provider interface\n"
          "   - Support openai-chat API (SSE streaming)\n"
          "   - Support openai-responses API\n"
          "   - Handle tool_calls in streaming (accumulate arguments across deltas)\n"
          "   - Handle reasoning_content for thinking models\n"
          "   - Support cache_control on messages\n"
          "   - Support thinking_format: openai, deepseek, xiaomi\n"
          "   - Retry with exponential backoff\n"
          "2. Create /home/free/src/vibecoding-gui/lib/core/provider/anthropic_provider.dart:\n"
          "   - Anthropic provider implementing Provider interface\n"
          "   - Support anthropic-messages API (SSE streaming with event types)\n"
          "   - Handle content_block_start, content_block_delta, content_block_stop\n"
          "   - Handle tool_use blocks and input_json_delta\n"
          "   - Handle thinking blocks with signature\n"
          "   - Support cache_control (ephemeral breakpoints)\n"
          "   - Retry with exponential backoff\n"
          "3. Create /home/free/src/vibecoding-gui/lib/core/provider/google_provider.dart:\n"
          "   - Google Gemini provider\n"
          "   - Support google-gemini API\n"
          "4. Update existing provider.dart to use the new provider implementations"))))

  ;; Phase 6: Integration and wiring
  (phase "integration"
    (agent "integrate"
      :mode "agent"
      :tools '("read" "write" "edit")
      :max-iterations 200
      :prompt (concat
        "Wire everything together and update existing code.\n\n"
        "REFERENCE PLAN:\n"
        (result "design.architect")
        "\n\n"
        "Working directory: /home/free/src/vibecoding-gui\n\n"
        "Tasks:\n"
        "1. Create /home/free/src/vibecoding-gui/lib/core/provider.dart as barrel export:\n"
        "   - Export all provider/*.dart files\n"
        "   - Keep backward-compatible LLMProviderClient that delegates to new provider system\n"
        "2. Update /home/free/src/vibecoding-gui/lib/services/app_state.dart:\n"
        "   - Use new Agent with full loop capabilities\n"
        "   - Use new SessionManager (SQLite)\n"
        "   - Wire agent events to UI\n"
        "3. Update /home/free/src/vibecoding-gui/lib/services/config_service.dart:\n"
        "   - Load/save settings using new Settings class\n"
        "   - Support all new config fields\n"
        "4. Update /home/free/src/vibecoding-gui/lib/widgets/ files if needed for new event types\n"
        "5. Update /home/free/src/vibecoding-gui/pubspec.yaml with new dependencies (sqflite, etc.)\n"
        "6. Ensure the app compiles with 'flutter analyze'\n"
        "7. Fix any import issues or type mismatches")))

  ;; Phase 7: Final verification
  (phase "verify"
    (agent "verifier"
      :mode "plan"
      :tools '("read" "grep")
      :max-iterations 100
      :prompt (concat
        "Verify the complete migration. Check:\n\n"
        "1. Read all new/modified Dart files in /home/free/src/vibecoding-gui/lib/\n"
        "2. Verify provider system: vendor adapters, registry, factory, retry, cache control\n"
        "3. Verify agent loop: frozen prompt, cache markers, token budgeting, compaction, parallel tools\n"
        "4. Verify session: SQLite backend, replay state, compaction entries\n"
        "5. Verify settings: all Go settings fields have Dart equivalents\n"
        "6. Verify data models: ContentBlock, ToolCallBlock, Usage, Cost all present\n"
        "7. Check for any missing features vs the Go codebase\n"
        "8. Report any issues found with file:line references\n"
        "Return PASS if all good, or list of issues to fix."))))

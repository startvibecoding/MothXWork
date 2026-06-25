import 'dart:async';
import 'dart:convert';
import '../models/models.dart';
import '../services/acp_client.dart';
import 'provider.dart';
import 'session.dart';
import 'settings.dart' as core_settings;
import 'tools/registry.dart';
import 'tools/file_tools.dart';
import 'tools/search_tools.dart';
import 'tools/shell_tool.dart';

class Agent {
  final String sessionId;
  final String cwd;
  final core_settings.ProviderConfig provider;
  final core_settings.ModelConfig model;
  final String mode;
  final String thinkingLevel;
  final int maxTokens;
  final core_settings.ApprovalSettings? approvalSettings;

  final Future<bool> Function(String toolName, Map<String, dynamic> args)? approvalHandler;

  final ToolRegistry registry = ToolRegistry();
  final SessionManager session;
  final List<ChatMessage> messages = [];

  final StreamController<AcpEvent> _eventsController = StreamController<AcpEvent>.broadcast();
  Stream<AcpEvent> get events => _eventsController.stream;

  Agent({
    required this.sessionId,
    required this.cwd,
    required this.provider,
    required this.model,
    required this.mode,
    required this.thinkingLevel,
    required this.maxTokens,
    this.approvalSettings,
    this.approvalHandler,
  }) : session = SessionManager(sessionId: sessionId, cwd: cwd) {
    registry.register(ReadTool());
    registry.register(WriteTool());
    registry.register(EditTool());
    registry.register(LsTool());
    registry.register(FindTool());
    registry.register(GrepTool());
    registry.register(BashTool());
  }

  void loadHistory(List<ChatMessage> history) {
    messages.clear();
    messages.addAll(history);
  }

  String get systemPrompt => '''
You are VibeWork, an elite AI Coding Assistant powered by VibeCoding. You work closely with the developer in their workspace directory.

Your workspace path is: $cwd
Current Mode: $mode
Thinking Level: $thinkingLevel

You have direct access to these native developer tools:
- read: read file contents
- write: create or overwrite files
- edit: perform search-and-replace edits
- ls: list directory contents
- find: find files by name patterns
- grep: search content by regex
- bash: run shell commands natively

CRITICAL GUIDELINES:
1. Always keep file paths accurate and write clean, robust code.
2. In agent and yolo modes, utilize tools to investigate, compile, and run tests independently to solve the task.
3. Be concise and precise.
''';

  bool _needsApproval(String toolName, Map<String, dynamic> args) {
    if ((toolName == 'write' || toolName == 'edit') && mode == 'agent') {
      return approvalSettings?.confirmBeforeWrite ?? false;
    }
    if (toolName == 'bash') {
      if (_isBashBlacklisted(args)) return true;
      if (mode == 'agent') {
        return !_isBashWhitelisted(args);
      }
    }
    return false;
  }

  bool _isBashWhitelisted(Map<String, dynamic> args) {
    final cmd = args['command']?.toString() ?? '';
    final whitelist = approvalSettings?.bashWhitelist ?? [];
    for (var prefix in whitelist) {
      if (cmd.startsWith(prefix)) return true;
    }
    return false;
  }

  bool _isBashBlacklisted(Map<String, dynamic> args) {
    final cmd = args['command']?.toString() ?? '';
    final blacklist = approvalSettings?.bashBlacklist ?? [];
    for (var term in blacklist) {
      if (cmd.contains(term)) return true;
    }
    return false;
  }

  Future<void> run(String userPrompt) async {
    final userMsg = ChatMessage(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: userPrompt,
      timestamp: DateTime.now(),
    );
    messages.add(userMsg);
    await session.appendMessage(userMsg);

    _eventsController.add(AcpEvent(
      type: 'user_content',
      sessionId: sessionId,
      content: userPrompt,
    ));

    int iterations = 0;
    const maxIterations = 15;
    final client = LLMProviderClient(provider: provider, model: model);

    while (iterations < maxIterations) {
      iterations++;
      
      _eventsController.add(AcpEvent(
        type: 'turn_start',
        sessionId: sessionId,
        content: 'Turn $iterations...',
      ));

      final toolsDef = registry.getDefinitions();
      String assistantContent = '';
      
      String? activeToolCallId;
      String? activeToolName;
      String activeToolArgs = '';

      final chatStream = client.chat(messages, toolsDef, systemPrompt);
      
      await for (final event in chatStream) {
        if (event.error != null) {
          _eventsController.add(AcpEvent(
            type: 'error',
            sessionId: sessionId,
            error: event.error,
          ));
          return;
        }

        if (event.textDelta.isNotEmpty) {
          assistantContent += event.textDelta;
          _eventsController.add(AcpEvent(
            type: 'content',
            sessionId: sessionId,
            content: event.textDelta,
          ));
        }

        if (event.thinkDelta.isNotEmpty) {
          _eventsController.add(AcpEvent(
            type: 'content',
            sessionId: sessionId,
            content: event.thinkDelta,
          ));
        }

        if (event.toolCallId != null) {
          activeToolCallId = event.toolCallId;
          activeToolName = event.toolName;
          if (event.toolArgsDelta != null) {
            activeToolArgs += event.toolArgsDelta!;
          }
        }
      }

      if (activeToolCallId != null && activeToolName != null) {
        Map<String, dynamic> parsedArgs = {};
        try {
          if (activeToolArgs.isNotEmpty) {
            parsedArgs = Map<String, dynamic>.from(jsonDecode(activeToolArgs) as Map);
          }
        } catch (_) {}

        // Check if the tool execution requires user permission
        if (_needsApproval(activeToolName, parsedArgs) && approvalHandler != null) {
          _eventsController.add(AcpEvent(
            type: 'status',
            sessionId: sessionId,
            content: 'Waiting for permission to run $activeToolName...',
          ));

          final approved = await approvalHandler!(activeToolName, parsedArgs);
          if (!approved) {
            final toolDeniedResult = 'Permission denied by user.';
            
            final assistMsg = ChatMessage(
              id: 'ast-${DateTime.now().millisecondsSinceEpoch}',
              role: MessageRole.assistant,
              content: '$assistantContent\n🔧 Tried to use tool: $activeToolName (Denied)',
              timestamp: DateTime.now(),
            );
            messages.add(assistMsg);
            await session.appendMessage(assistMsg);

            final resultMsg = ChatMessage(
              id: 'tls-${DateTime.now().millisecondsSinceEpoch}',
              role: MessageRole.assistant,
              content: 'Tool Result ($activeToolName):\n$toolDeniedResult',
              timestamp: DateTime.now(),
            );
            messages.add(resultMsg);
            await session.appendMessage(resultMsg);

            _eventsController.add(AcpEvent(
              type: 'done',
              sessionId: sessionId,
              content: 'completed_denied',
            ));
            break;
          }
        }

        _eventsController.add(AcpEvent(
          type: 'tool_call',
          sessionId: sessionId,
          content: '',
          data: {
            'title': 'Executing tool: $activeToolName',
          },
        ));

        final tool = registry.get(activeToolName);
        String toolResult = '';
        if (tool != null) {
          try {
            toolResult = await tool.execute(cwd, parsedArgs);
          } catch (e) {
            toolResult = 'Tool execution error: $e';
          }
        } else {
          toolResult = 'Error: Tool $activeToolName not found.';
        }

        final assistMsg = ChatMessage(
          id: 'ast-${DateTime.now().millisecondsSinceEpoch}',
          role: MessageRole.assistant,
          content: '$assistantContent\n🔧 Used tool: $activeToolName with args: $parsedArgs',
          timestamp: DateTime.now(),
        );
        messages.add(assistMsg);
        await session.appendMessage(assistMsg);

        _eventsController.add(AcpEvent(
          type: 'toolCallUpdate',
          sessionId: sessionId,
          content: toolResult,
          data: {
            'status': 'completed',
          },
        ));

        final resultMsg = ChatMessage(
          id: 'tls-${DateTime.now().millisecondsSinceEpoch}',
          role: MessageRole.assistant,
          content: 'Tool Result ($activeToolName):\n$toolResult',
          timestamp: DateTime.now(),
        );
        messages.add(resultMsg);
        await session.appendMessage(resultMsg);

        await Future.delayed(const Duration(milliseconds: 100));
      } else {
        final assistMsg = ChatMessage(
          id: 'ast-${DateTime.now().millisecondsSinceEpoch}',
          role: MessageRole.assistant,
          content: assistantContent,
          timestamp: DateTime.now(),
        );
        messages.add(assistMsg);
        await session.appendMessage(assistMsg);

        _eventsController.add(AcpEvent(
          type: 'done',
          sessionId: sessionId,
          content: 'completed',
        ));
        break;
      }
    }
  }
}

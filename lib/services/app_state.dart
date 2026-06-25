import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/agent.dart';
import '../core/session.dart';
import '../core/settings.dart' as core_settings;
import '../models/models.dart';
import 'acp_client.dart';
import 'config_service.dart';

class AppState extends ChangeNotifier {
  final ConfigService config = ConfigService();

  StreamSubscription<AcpEvent>? _eventSub;
  Completer<bool>? _pendingPermissionCompleter;

  Map<String, dynamic> settings = {};
  List<SessionInfo> sessions = [];
  String? currentSessionId;
  final List<ChatMessage> messages = [];
  bool isLoading = false;
  bool isConnected = true;
  String theme = 'dark';
  String? errorBanner;

  SessionRuntimeConfig runtimeConfig = SessionRuntimeConfig();
  PermissionRequest? pendingPermission;

  String? _streamingId;
  MessageRole? _lastChunkRole;
  int _currentHistoryLimit = 30;
  bool hasMoreHistory = true;
  final bool _isBufferMode = false;
  final List<ChatMessage> _bufferedMessages = [];

  Future<void> init() async {
    settings = await config.loadSettings();
    runtimeConfig = SessionRuntimeConfig(
      provider: (settings['defaultProvider'] ?? '').toString(),
      model: (settings['defaultModel'] ?? '').toString(),
      mode: (settings['defaultMode'] ?? 'agent').toString(),
      thinking: (settings['defaultThinkingLevel'] ?? 'medium').toString(),
    );

    final ui = await config.loadUiConfig();
    theme = (ui['theme'] ?? 'dark').toString();

    final saved = await config.loadSessions();
    sessions = saved;
    notifyListeners();

    isConnected = true;

    if (saved.isEmpty) {
      await createSession(Directory.current.path);
    } else {
      final last = saved.last;
      currentSessionId = last.id;
      runtimeConfig = runtimeConfig.copyWith(cwd: last.cwd);
      await _loadLocalMessages(last.id, last.cwd);
    }
    notifyListeners();
  }

  Future<void> _loadLocalMessages(String sessionId, String cwd) async {
    _clearMessages();
    final mgr = SessionManager(sessionId: sessionId, cwd: cwd);
    final list = await mgr.loadMessages(limit: _currentHistoryLimit);
    messages.clear();
    messages.addAll(list);
    notifyListeners();
  }

  void _clearMessages({bool resetLimit = true}) {
    messages.clear();
    _bufferedMessages.clear();
    _streamingId = null;
    _lastChunkRole = null;
    if (resetLimit) {
      _currentHistoryLimit = 30;
      hasMoreHistory = true;
    }
  }

  Future<void> updateRuntimeConfig(SessionRuntimeConfig cfg) async {
    runtimeConfig = cfg.copyWith(cwd: runtimeConfig.cwd);
    if (currentSessionId != null) {
      await _loadLocalMessages(currentSessionId!, runtimeConfig.cwd);
    }
    notifyListeners();
  }

  Future<void> createSession(String cwd) async {
    final id = 'session-${DateTime.now().millisecondsSinceEpoch}';
    final session = SessionInfo(
      id: id,
      name: 'Session $id',
      cwd: cwd,
      createdAt: DateTime.now().toIso8601String(),
    );
    sessions.add(session);
    currentSessionId = id;
    _clearMessages();
    runtimeConfig = runtimeConfig.copyWith(cwd: cwd);
    await config.saveSessions(sessions);
    notifyListeners();
  }

  Future<void> selectSession(String id) async {
    final s = sessions.firstWhere((e) => e.id == id, orElse: () => sessions.first);
    currentSessionId = id;
    runtimeConfig = runtimeConfig.copyWith(cwd: s.cwd);
    await _loadLocalMessages(id, s.cwd);
  }

  Future<void> loadMoreHistory() async {
    final sessionId = currentSessionId;
    if (sessionId == null) return;
    final s = sessions.firstWhere((e) => e.id == sessionId, orElse: () => sessions.first);
    final prevCount = messages.length;
    _currentHistoryLimit += 50;

    await _loadLocalMessages(sessionId, s.cwd);

    if (messages.length <= prevCount) {
      hasMoreHistory = false;
    }
    notifyListeners();
  }

  Future<void> renameSession(String id, String name) async {
    final idx = sessions.indexWhere((s) => s.id == id);
    if (idx != -1) {
      sessions[idx].name = name;
      await config.saveSessions(sessions);
      notifyListeners();
    }
  }

  Future<void> deleteSession(String id) async {
    sessions.removeWhere((s) => s.id == id);
    await config.saveSessions(sessions);
    if (currentSessionId == id) {
      if (sessions.isNotEmpty) {
        await selectSession(sessions.last.id);
      } else {
        currentSessionId = null;
      }
      _clearMessages();
    }
    notifyListeners();
  }

  String sessionName(String? id) {
    if (id == null) return 'No Session';
    final s = sessions.firstWhere((e) => e.id == id,
        orElse: () => SessionInfo(id: id, name: id, cwd: '', createdAt: ''));
    return s.name;
  }

  List<ProviderInfo> get providers => config.providersFrom(settings);
  List<ModelInfo> modelsForProvider(String id) => config.modelsFrom(settings, id);

  Future<void> prompt(String text) async {
    if (text.trim().isEmpty || isLoading || currentSessionId == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final s = sessions.firstWhere((e) => e.id == currentSessionId);
      final pConfigJson = settings['providers'][runtimeConfig.provider];
      if (pConfigJson == null) {
        throw 'Provider ${runtimeConfig.provider} not found in settings.';
      }
      final pConfig = core_settings.ProviderConfig.fromJson(Map<String, dynamic>.from(pConfigJson as Map));
      final mConfig = pConfig.models.firstWhere((m) => m.id == runtimeConfig.model, orElse: () => pConfig.models.first);
      final appSettings = core_settings.Settings.fromJson(settings);

      final agent = Agent(
        sessionId: currentSessionId!,
        cwd: s.cwd,
        provider: pConfig,
        model: mConfig,
        mode: runtimeConfig.mode,
        thinkingLevel: runtimeConfig.thinking,
        maxTokens: 4096,
        approvalSettings: appSettings.approval,
        approvalHandler: (toolName, args) async {
          final completer = Completer<bool>();
          
          pendingPermission = PermissionRequest(
            requestId: 'req-${DateTime.now().millisecondsSinceEpoch}',
            sessionId: currentSessionId!,
            toolCallId: 'toolcall-${DateTime.now().millisecondsSinceEpoch}',
            title: 'Permission request for running: $toolName',
            kind: toolName,
            input: args,
            options: [
              PermissionOption(optionId: 'allow-once', name: 'Allow Once', kind: 'allow'),
              PermissionOption(optionId: 'reject-once', name: 'Deny Once', kind: 'reject'),
            ],
          );
          
          _pendingPermissionCompleter = completer;
          notifyListeners();
          
          final approved = await completer.future;
          pendingPermission = null;
          _pendingPermissionCompleter = null;
          notifyListeners();
          return approved;
        },
      );

      agent.loadHistory(messages);

      await _eventSub?.cancel();
      _eventSub = agent.events.listen(_handleEvent);

      await agent.run(text);
    } catch (e) {
      _appendChunk('\n❌ **Error:** $e', MessageRole.assistant);
      _finishStreaming();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    await prompt(text);
  }

  void abort() {}

  Future<void> respondPermission(String optionId) async {
    final approved = optionId == 'allow-once' || optionId.contains('allow');
    _pendingPermissionCompleter?.complete(approved);
  }

  void dismissPermission() {
    _pendingPermissionCompleter?.complete(false);
    pendingPermission = null;
    notifyListeners();
  }

  void _handleEvent(AcpEvent event) {
    switch (event.type) {
      case 'content':
        _appendChunk(event.content, MessageRole.assistant);
        break;
      case 'user_content':
        _appendChunk(event.content, MessageRole.user);
        break;
      case 'status':
        _appendChunk('\n⚙️ *${event.content}*\n', MessageRole.assistant);
        break;
      case 'tool_call':
        final title = (event.data is Map ? event.data['title'] : null) ?? 'Calling tool...';
        _appendChunk('\n🔧 **$title**\n', MessageRole.assistant);
        break;
      case 'toolCallUpdate':
        final data = event.data;
        if (data is Map && data['status'] == 'completed' && event.content.isNotEmpty) {
          _appendChunk('\n✅ **Result:**\n```\n${event.content}\n```\n', MessageRole.assistant);
        }
        break;
      case 'error':
        _appendChunk('\n❌ **Error:** ${event.error}', MessageRole.assistant);
        _finishStreaming();
        isLoading = false;
        notifyListeners();
        break;
    }
  }

  void _appendChunk(String content, MessageRole role) {
    if (content.isEmpty) return;

    final targetList = _isBufferMode ? _bufferedMessages : messages;

    if (_streamingId == null || _lastChunkRole != role) {
      _finishStreaming();
      final id = 'chunk-${DateTime.now().millisecondsSinceEpoch}-${targetList.length}';
      _streamingId = id;
      _lastChunkRole = role;
      targetList.add(ChatMessage(
        id: id,
        role: role,
        content: content,
        timestamp: DateTime.now(),
        isStreaming: true,
      ));
    } else {
      final msg = targetList.firstWhere((m) => m.id == _streamingId, orElse: () => targetList.last);
      msg.content += content;
    }
    if (!_isBufferMode) {
      notifyListeners();
    }
  }

  void _finishStreaming() {
    if (_streamingId != null) {
      final targetList = _isBufferMode ? _bufferedMessages : messages;
      for (final m in targetList) {
        if (m.id == _streamingId) m.isStreaming = false;
      }
      _streamingId = null;
      _lastChunkRole = null;
    }
  }

  Future<void> saveSettings(Map<String, dynamic> newSettings) async {
    settings = newSettings;
    await config.saveSettings(settings);
    notifyListeners();
  }

  void setTheme(String val) {
    theme = val;
    notifyListeners();
  }
}

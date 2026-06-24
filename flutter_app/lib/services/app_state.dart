import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'acp_client.dart';
import 'config_service.dart';

/// Central application state, equivalent to the React App.tsx state plus the
/// Go AgentManager. Manages the ACP client lifecycle, sessions, messages and
/// configuration.
class AppState extends ChangeNotifier {
  final ConfigService config = ConfigService();

  AcpClient? _client;
  StreamSubscription<AcpEvent>? _eventSub;

  // ---- Public state ----
  Map<String, dynamic> settings = {};
  List<SessionInfo> sessions = [];
  String? currentSessionId;
  final List<ChatMessage> messages = [];
  bool isLoading = false;
  bool isConnected = false;
  String theme = 'dark';
  String? errorBanner;

  SessionRuntimeConfig runtimeConfig = SessionRuntimeConfig();
  PermissionRequest? pendingPermission;

  // Streaming bookkeeping.
  String? _streamingId;

  String? get vibecodingPath => _vibecodingPath;
  String? _vibecodingPath;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------
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

    _vibecodingPath = VibeCodingLocator.find();
    if (_vibecodingPath == null) {
      errorBanner = '未找到 vibecoding 可执行文件';
      notifyListeners();
      return;
    }

    await _startClient();
    await _loadSessions();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // ACP client lifecycle
  // ---------------------------------------------------------------------------
  Future<void> _startClient() async {
    await _eventSub?.cancel();
    await _client?.close();

    final c = AcpClient(_vibecodingPath!, args: {
      'provider': runtimeConfig.provider,
      'model': runtimeConfig.model,
      'mode': runtimeConfig.mode,
      'thinking': runtimeConfig.thinking,
    });
    try {
      await c.start();
      await c.initialize('VibeCoding GUI', '1.0.0');
      _client = c;
      _eventSub = c.events.listen(_handleEvent);
      isConnected = true;
      errorBanner = null;
    } catch (e) {
      isConnected = false;
      errorBanner = '连接 VibeCoding 失败: $e';
    }
  }

  Future<void> updateRuntimeConfig(SessionRuntimeConfig cfg) async {
    runtimeConfig = cfg.copyWith(cwd: runtimeConfig.cwd);
    isConnected = false;
    notifyListeners();
    await _startClient();
    // Config change invalidates existing ACP sessions.
    currentSessionId = null;
    messages.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Sessions
  // ---------------------------------------------------------------------------
  Future<void> _loadSessions() async {
    final saved = await config.loadSessions();
    sessions = saved;
    if (_client == null) return;

    if (saved.isEmpty) {
      // Automatically create a default session in the current working directory
      await createSession(Directory.current.path);
      return;
    }

    // Restore the last session by creating a fresh ACP session with saved cwd.
    final last = saved.last;
    try {
      final newId = await _client!.newSession(last.cwd);
      last.id = newId;
      currentSessionId = newId;
      runtimeConfig = runtimeConfig.copyWith(cwd: last.cwd);
      await config.saveSessions(sessions);
    } catch (e) {
      errorBanner = '恢复会话失败: $e';
    }
  }

  Future<void> createSession(String cwd) async {
    if (_client == null) return;
    try {
      final id = await _client!.newSession(cwd);
      final session = SessionInfo(
        id: id,
        name: id,
        cwd: cwd,
        createdAt: DateTime.now().toIso8601String(),
      );
      sessions.add(session);
      currentSessionId = id;
      messages.clear();
      runtimeConfig = runtimeConfig.copyWith(cwd: cwd);
      isConnected = true;
      await config.saveSessions(sessions);
      notifyListeners();
    } catch (e) {
      errorBanner = '创建会话失败: $e';
      notifyListeners();
    }
  }

  void selectSession(String id) {
    final s = sessions.firstWhere((e) => e.id == id, orElse: () => sessions.first);
    currentSessionId = id;
    messages.clear();
    runtimeConfig = runtimeConfig.copyWith(cwd: s.cwd);
    notifyListeners();
  }

  Future<void> renameSession(String id, String name) async {
    for (final s in sessions) {
      if (s.id == id) s.name = name;
    }
    await config.saveSessions(sessions);
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    sessions.removeWhere((s) => s.id == id);
    await config.saveSessions(sessions);
    if (currentSessionId == id) {
      if (sessions.isNotEmpty) {
        currentSessionId = sessions.last.id;
      } else {
        currentSessionId = null;
        isConnected = false;
      }
      messages.clear();
    }
    notifyListeners();
  }

  String? sessionName(String? id) {
    if (id == null) return null;
    for (final s in sessions) {
      if (s.id == id) return s.name;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Messaging
  // ---------------------------------------------------------------------------
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || isLoading || currentSessionId == null) return;
    final client = _client;
    if (client == null) return;

    messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    ));
    isLoading = true;
    notifyListeners();

    final sessionId = currentSessionId!;
    try {
      final stopReason = await client.prompt(sessionId, text);
      _finishStreaming();
      isLoading = false;
      debugPrint('prompt done: $stopReason');
      notifyListeners();
    } catch (e) {
      _appendStreaming('\n❌ **Error:** $e');
      _finishStreaming();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> abort() async {
    if (currentSessionId != null) {
      await _client?.cancel(currentSessionId!);
    }
    _finishStreaming();
    isLoading = false;
    notifyListeners();
  }

  void _handleEvent(AcpEvent event) {
    switch (event.type) {
      case 'content':
        _appendStreaming(event.content);
        break;
      case 'tool_call':
        final title = (event.data is Map ? event.data['title'] : null) ??
            'Calling tool...';
        _appendStreaming('\n🔧 **$title**\n');
        break;
      case 'toolCallUpdate':
        final data = event.data;
        if (data is Map &&
            data['status'] == 'completed' &&
            event.content.isNotEmpty) {
          _appendStreaming('\n✅ **Result:**\n```\n${event.content}\n```\n');
        }
        break;
      case 'permission_request':
        _setPermission(event.data as Map<String, dynamic>);
        break;
      case 'done':
        _finishStreaming();
        isLoading = false;
        notifyListeners();
        break;
      case 'error':
        _appendStreaming('\n❌ **Error:** ${event.error}');
        _finishStreaming();
        isLoading = false;
        notifyListeners();
        break;
    }
  }

  void _appendStreaming(String content) {
    if (content.isEmpty) return;
    if (_streamingId == null) {
      final id = 'streaming-${DateTime.now().millisecondsSinceEpoch}';
      _streamingId = id;
      messages.add(ChatMessage(
        id: id,
        role: MessageRole.assistant,
        content: content,
        timestamp: DateTime.now(),
        isStreaming: true,
      ));
    } else {
      final msg = messages.firstWhere((m) => m.id == _streamingId,
          orElse: () => messages.last);
      msg.content += content;
    }
    notifyListeners();
  }

  void _finishStreaming() {
    if (_streamingId != null) {
      for (final m in messages) {
        if (m.id == _streamingId) m.isStreaming = false;
      }
      _streamingId = null;
    }
  }

  // ---------------------------------------------------------------------------
  // Permission handling
  // ---------------------------------------------------------------------------
  void _setPermission(Map<String, dynamic> data) {
    final optionsRaw = data['options'] as List<dynamic>? ?? [];
    pendingPermission = PermissionRequest(
      requestId: data['requestId']?.toString() ?? '',
      sessionId: data['sessionId']?.toString() ?? '',
      toolCallId: data['toolCallId']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      kind: data['kind']?.toString() ?? '',
      input: data['input'],
      options: optionsRaw
          .map((o) => PermissionOption.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
    notifyListeners();
  }

  Future<void> respondPermission(String optionId) async {
    final req = pendingPermission;
    if (req == null) return;
    await _client?.sendPermissionResponse(req.requestId, optionId);
    pendingPermission = null;
    notifyListeners();
  }

  void dismissPermission() {
    pendingPermission = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Theme & settings
  // ---------------------------------------------------------------------------
  Future<void> setTheme(String value) async {
    theme = value;
    await config.saveUiConfig({'theme': value});
    notifyListeners();
  }

  Future<void> saveSettings(Map<String, dynamic> newSettings) async {
    settings = newSettings;
    await config.saveSettings(newSettings);
    notifyListeners();
  }

  List<ProviderInfo> get providers => config.providersFrom(settings);
  List<ModelInfo> modelsForProvider(String providerId) =>
      config.modelsFrom(settings, providerId);

  @override
  void dispose() {
    _eventSub?.cancel();
    _client?.close();
    super.dispose();
  }
}

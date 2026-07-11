import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'acp_client.dart';
import 'config_service.dart';

enum ConnectionMode { acp, serve }

class AppState extends ChangeNotifier {
  final ConfigService config = ConfigService();
  AcpClient? _acp;

  StreamSubscription<AcpEvent>? _eventSub;
  Completer<bool>? _pendingPermissionCompleter;

  Map<String, dynamic> settings = {};
  List<SessionInfo> sessions = [];
  String? currentSessionId;
  /// Backend session ID managed by mothx acp.
  String? _backendSessionId;
  final List<ChatMessage> messages = [];
  bool isLoading = false;
  bool isConnected = false;
  ConnectionMode connectionMode = ConnectionMode.acp;
  String? serveUrl;
  String currentPage = 'chat';
  String theme = 'dark';
  String? errorBanner;

  // Usage tracking
  int contextUsed = 0;
  int contextSize = 0;
  double? currentCost;

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

    // Start ACP client.
    final binary = MothxLocator.find();
    if (binary == null) {
      isConnected = false;
      errorBanner = 'mothx binary not found. Please install mothx and ensure it is in your PATH.';
      notifyListeners();
      return;
    }

    try {
      _acp = AcpClient(binary);
      await _acp!.start();
      await _acp!.initialize('mothx-gui', '1.0.0');
      _eventSub = _acp!.events.listen(_handleEvent);
      isConnected = true;
    } catch (e) {
      isConnected = false;
      errorBanner = 'Failed to start mothx acp: $e';
      notifyListeners();
      return;
    }

    // Load sessions from backend via session/list
    await _loadSessionsFromBackend();

    if (sessions.isNotEmpty) {
      final last = sessions.last;
      currentSessionId = last.id;
      runtimeConfig = runtimeConfig.copyWith(cwd: last.cwd);
      await _switchToSession(last.id, last.cwd);
    }
    notifyListeners();
  }

  /// Load session list from the backend.
  Future<void> _loadSessionsFromBackend() async {
    try {
      final result = await _acp!.listSessions(cwd: Directory.current.path);
      sessions = result.sessions.map((s) {
        final sessionId = (s['sessionId'] ?? '').toString();
        final cwd = (s['cwd'] ?? '').toString();
        final title = (s['title'] ?? '').toString();
        final updatedAt = (s['updatedAt'] ?? '').toString();
        // final meta = s['_meta'] as Map?;  // reserved for future use
        return SessionInfo(
          id: sessionId,
          name: title.isNotEmpty ? title : 'Session $sessionId',
          cwd: cwd,
          createdAt: updatedAt,
        );
      }).toList();

      // Also save to local cache.
      if (sessions.isNotEmpty) {
        await config.saveSessions(sessions);
      }
    } catch (_) {
      // Fallback to local cache.
      sessions = await config.loadSessions();
    }
  }

  /// Switch to a session: load it from the backend, clearing local messages first.
  Future<void> _switchToSession(String id, String cwd) async {
    _clearMessages();
    // Load from backend – historical messages arrive as session/update notifications.
    try {
      await _acp?.loadSession(id, cwd, limit: _currentHistoryLimit);
      _backendSessionId = id;
    } catch (_) {
      // Fallback: create new session if load fails.
      _backendSessionId = id;
    }
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
      await _switchToSession(currentSessionId!, runtimeConfig.cwd);
    }
    notifyListeners();
  }

  Future<void> createSession(String cwd) async {
    try {
      final backendId = await _acp!.newSession(cwd);
      final session = SessionInfo(
        id: backendId,
        name: 'Session $backendId',
        cwd: cwd,
        createdAt: DateTime.now().toIso8601String(),
      );
      sessions.add(session);
      currentSessionId = backendId;
      _backendSessionId = backendId;
      _clearMessages();
      runtimeConfig = runtimeConfig.copyWith(cwd: cwd);
      await config.saveSessions(sessions);
      notifyListeners();
    } catch (e) {
      errorBanner = 'Failed to create session: $e';
      notifyListeners();
    }
  }

  Future<void> selectSession(String id) async {
    final s = sessions.firstWhere((e) => e.id == id, orElse: () => sessions.first);
    currentSessionId = id;
    runtimeConfig = runtimeConfig.copyWith(cwd: s.cwd);
    await _switchToSession(id, s.cwd);
    notifyListeners();
  }

  Future<void> loadMoreHistory() async {
    final sessionId = currentSessionId;
    if (sessionId == null) return;
    final s = sessions.firstWhere((e) => e.id == sessionId, orElse: () => sessions.first);
    final prevCount = messages.length;
    _currentHistoryLimit += 50;

    await _switchToSession(sessionId, s.cwd);

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
    // Close backend session.
    try {
      await _acp?.closeSession(id);
    } catch (_) {}

    sessions.removeWhere((s) => s.id == id);
    await config.saveSessions(sessions);
    if (currentSessionId == id) {
      if (sessions.isNotEmpty) {
        await selectSession(sessions.last.id);
      } else {
        currentSessionId = null;
        _backendSessionId = null;
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

  /// Send a user prompt to the backend via ACP.
  Future<void> prompt(String text) async {
    if (text.trim().isEmpty || isLoading || currentSessionId == null) return;

    isLoading = true;
    notifyListeners();

    final s = sessions.firstWhere((e) => e.id == currentSessionId,
        orElse: () => sessions.first);
    final sessionTarget = _backendSessionId ?? s.id;

    try {
      await _acp!.prompt(sessionTarget, text);
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

  /// Cancel the current backend prompt.
  void abort() {
    if (!isLoading) return;
    // Dismiss any pending permission request.
    if (_pendingPermissionCompleter != null && !_pendingPermissionCompleter!.isCompleted) {
      _pendingPermissionCompleter!.complete(false);
      _pendingPermissionCompleter = null;
      pendingPermission = null;
    }
    final sessionTarget = _backendSessionId;
    if (sessionTarget != null) {
      _acp?.cancel(sessionTarget);
    }
    _appendChunk('\n⏹️ *Stopped*', MessageRole.assistant);
    _finishStreaming();
    isLoading = false;
    notifyListeners();
  }

  Future<void> respondPermission(String optionId) async {
    // Send the response to the backend first.
    if (pendingPermission != null) {
      final reqId = pendingPermission!.requestId;
      if (reqId.isNotEmpty) {
        await _acp?.sendPermissionResponse(reqId, optionId);
      }
    }
    pendingPermission = null;
    _pendingPermissionCompleter = null;
    notifyListeners();
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
        final title = (event.data?['title'] as String?) ?? 'Calling tool...';
        _appendChunk('\n🔧 **$title**\n', MessageRole.assistant);
        break;
      case 'toolCallUpdate':
        final data = event.data;
        if (data != null && data['status'] == 'completed' && event.content.isNotEmpty) {
          _appendChunk('\n✅ **Result:**\n```\n${event.content}\n```\n', MessageRole.assistant);
        }
        break;
      case 'error':
        _appendChunk('\n❌ **Error:** ${event.error}', MessageRole.assistant);
        _finishStreaming();
        isLoading = false;
        notifyListeners();
        break;
      case 'permission_request':
        final data = event.data;
        if (data == null) return;
        final optionsRaw = data['options'] as List<dynamic>? ?? [];
        final options = optionsRaw.map((o) {
          final om = o is Map ? o : <String, dynamic>{};
          return PermissionOption(
            optionId: (om['optionId'] ?? '').toString(),
            name: (om['name'] ?? '').toString(),
            kind: (om['kind'] ?? '').toString(),
          );
        }).toList();
        pendingPermission = PermissionRequest(
          requestId: (data['requestId'] ?? '').toString(),
          sessionId: (data['sessionId'] ?? '').toString(),
          toolCallId: (data['toolCallId'] ?? '').toString(),
          title: (data['title'] ?? 'Permission request').toString(),
          kind: (data['kind'] ?? '').toString(),
          input: data['rawInput'] ?? {},
          options: options,
        );
        _pendingPermissionCompleter = Completer<bool>();
        notifyListeners();
        break;
      case 'usage_update':
        final data = event.data;
        if (data != null) {
          contextUsed = (data['used'] as num?)?.toInt() ?? 0;
          contextSize = (data['size'] as num?)?.toInt() ?? 0;
          final cost = data['cost'] as Map?;
          currentCost = cost?['amount']?.toDouble();
          notifyListeners();
        }
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

  void navigateToPage(String page) {
    currentPage = page;
    notifyListeners();
  }

  // ---- Serve mode stubs ----
  String get serveBaseUrl => '';
  String get serveAuthToken => '';
  Future<void> connectServeMode(String baseUrl, {String? authToken}) async {
    connectionMode = ConnectionMode.serve;
    serveUrl = baseUrl;
    isConnected = true;
    notifyListeners();
  }
  Future<void> disconnectServeMode() async {
    connectionMode = ConnectionMode.acp;
    serveUrl = null;
    notifyListeners();
  }

  // ---- Logs stubs ----
  final List<LogEntry> logs = [];
  bool logsConnected = false;
  void disconnectLogs() { logsConnected = false; notifyListeners(); }
  void clearLogs() { logs.clear(); notifyListeners(); }

  // ---- Cron stubs ----
  CronInfo? cronInfo;
  Future<void> loadCronForSession(String sessionId) async { cronInfo = CronInfo(); notifyListeners(); }
  Future<void> refreshCronInfo() async { cronInfo ??= CronInfo(); notifyListeners(); }
  Future<void> createCronJob({
    String? sessionId,
    String? name,
    String? prompt,
    String? schedule,
    bool? oneshot,
    String? mode,
  }) async { notifyListeners(); }
  Future<void> toggleCronJob(String jobId, [bool? enabled]) async { notifyListeners(); }
  Future<void> deleteCronJob(String jobId) async { notifyListeners(); }

  // ---- Stats stubs ----
  StatsSummary? statsSummary;
  String statsTimeRange = '7d';
  Future<void> refreshStats([String? range]) async {
    statsSummary = StatsSummary();
    if (range != null) statsTimeRange = range;
    notifyListeners();
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _acp?.close();
    super.dispose();
  }
}

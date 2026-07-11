import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'config_service.dart';
import 'serve_client.dart';

class AppState extends ChangeNotifier {
  final ConfigService config = ConfigService();

  ServeClient? _serve;
  StreamSubscription<ServeEvent>? _serveEventSub;
  StreamSubscription<Map<String, dynamic>>? _logsSub;

  Map<String, dynamic> settings = {};
  List<SessionInfo> sessions = [];
  String? currentSessionId;
  final List<ChatMessage> messages = [];
  bool isLoading = false;
  bool isConnected = false;
  String? serveUrl;
  String currentPage = 'chat';
  String theme = 'dark';
  String? errorBanner;

  int contextUsed = 0;
  int contextSize = 0;
  double? currentCost;

  SessionRuntimeConfig runtimeConfig = SessionRuntimeConfig();
  String? _streamingId;
  MessageRole? _lastChunkRole;
  bool _abortRequested = false;
  bool hasMoreHistory = false;

  Map<String, dynamic> serveStatus = {};
  Map<String, dynamic> serveCapabilities = {};
  Map<String, dynamic> serveConfig = {};
  Map<String, dynamic> memoryInfo = {};
  List<Map<String, dynamic>> serveModels = [];
  List<Map<String, dynamic>> channels = [];
  List<Map<String, dynamic>> sessionRunEvents = [];
  List<Map<String, dynamic>> sessionCapabilityEvents = [];
  List<Map<String, dynamic>> subAgents = [];
  final Map<String, List<ChatMessage>> subAgentMessages = {};
  final Map<String, Map<String, bool>> sessionTools = {};
  bool isRefreshingServeData = false;

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

    await connectServeMode(
      serveBaseUrl,
      authToken: serveAuthToken.isEmpty ? null : serveAuthToken,
    );
  }

  String get serveBaseUrl {
    final serveMode = settings['serveMode'];
    if (serveMode is Map && serveMode['baseUrl'] is String) {
      return serveMode['baseUrl'] as String;
    }
    return serveUrl ?? 'http://localhost:8080';
  }

  String get serveAuthToken {
    final serveMode = settings['serveMode'];
    if (serveMode is Map && serveMode['authToken'] is String) {
      return serveMode['authToken'] as String;
    }
    return '';
  }

  Future<void> connectServeMode(String baseUrl, {String? authToken}) async {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      throw ArgumentError.value(baseUrl, 'baseUrl', 'Expected an http(s) URL');
    }

    final normalizedUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final candidate = ServeClient(baseUrl: normalizedUrl, authToken: authToken);
    if (!await candidate.ping()) {
      candidate.dispose();
      isConnected = false;
      errorBanner = 'Unable to connect to mothx serve at $normalizedUrl.';
      notifyListeners();
      return;
    }

    await _serveEventSub?.cancel();
    _serve?.dispose();
    _serve = candidate;
    _serveEventSub = candidate.events.listen(_handleEvent);
    serveUrl = normalizedUrl;
    isConnected = true;
    errorBanner = null;
    await refreshServeData();
    notifyListeners();
  }

  Future<void> reconnectServe() async {
    await connectServeMode(
      serveBaseUrl,
      authToken: serveAuthToken.isEmpty ? null : serveAuthToken,
    );
  }

  Future<void> _loadServeSessions(ServeClient client) async {
    try {
      final remoteSessions = await client.listSessions();
      sessions = remoteSessions
          .map((session) => SessionInfo(
                id: (session['id'] ?? session['sessionId'] ?? '').toString(),
                name: (session['title'] ?? session['name'] ?? 'Session').toString(),
                cwd: (session['workDir'] ?? session['cwd'] ?? '').toString(),
                createdAt: (session['updatedAt'] ?? session['createdAt'] ?? '')
                    .toString(),
              ))
          .where((session) => session.id.isNotEmpty)
          .toList();

      if (sessions.isEmpty) {
        currentSessionId = null;
        _clearMessages();
        return;
      }

      final selected = sessions.firstWhere(
        (session) => session.id == currentSessionId,
        orElse: () => sessions.last,
      );
      runtimeConfig = runtimeConfig.copyWith(cwd: selected.cwd);
      if (await _loadSession(selected)) currentSessionId = selected.id;
    } catch (e) {
      errorBanner = 'Connected to serve, but could not load sessions: $e';
    }
  }

  Future<bool> _loadSession(SessionInfo session) async {
    final serve = _serve;
    if (serve == null) return false;
    _clearMessages();
    try {
      final history = await serve.getSessionMessages(session.id);
      messages.addAll(history.map((raw) {
        final message = ChatMessage.fromJson(Map<String, dynamic>.from(raw));
        if (message.id.isNotEmpty) return message;
        return ChatMessage(
          id: 'serve-${DateTime.now().microsecondsSinceEpoch}-${messages.length}',
          role: message.role,
          content: message.content,
          timestamp: message.timestamp,
          isStreaming: message.isStreaming,
          contents: message.contents,
          usage: message.usage,
          toolCalls: message.toolCalls,
        );
      }));
      hasMoreHistory = false;
      await loadSessionActivity(session.id);
      return true;
    } catch (e) {
      _clearMessages();
      errorBanner = 'Failed to load session: $e';
      return false;
    }
  }

  Future<void> refreshServeData() async {
    final serve = _serve;
    if (serve == null) return;
    isRefreshingServeData = true;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>([
        serve.getStatus(),
        serve.getCapabilities(),
        serve.getSettings(),
        serve.getServeConfig(),
        serve.getMemory(),
        serve.getChannels(),
        serve.listModels(),
      ]);
      serveStatus = results[0] as Map<String, dynamic>? ?? {};
      serveCapabilities = results[1] as Map<String, dynamic>? ?? {};
      final remoteSettings = results[2] as Map<String, dynamic>?;
      if (remoteSettings != null) {
        remoteSettings['serveMode'] = settings['serveMode'];
        settings = remoteSettings;
      }
      serveConfig = results[3] as Map<String, dynamic>? ?? {};
      memoryInfo = results[4] as Map<String, dynamic>? ?? {};
      channels = results[5] as List<Map<String, dynamic>>? ?? [];
      serveModels = results[6] as List<Map<String, dynamic>>? ?? [];
      await _loadServeSessions(serve);
    } catch (e) {
      errorBanner = 'Unable to refresh mothx serve data: $e';
    } finally {
      isRefreshingServeData = false;
      notifyListeners();
    }
  }

  Future<void> loadSessionActivity(String sessionId) async {
    final serve = _serve;
    if (serve == null || sessionId.isEmpty) return;
    final results = await Future.wait([
      serve.getRunEvents(sessionId),
      serve.getCapabilityEvents(sessionId),
      serve.getSubAgents(sessionId),
    ]);
    if (sessionId != currentSessionId && currentSessionId != null) return;
    sessionRunEvents = results[0];
    sessionCapabilityEvents = results[1];
    subAgents = results[2];
  }

  Map<String, bool> toolsForSession([String? sessionId]) {
    const defaults = {
      'webSearch': false,
      'browser': false,
      'a2aMaster': false,
      'delegate': false,
      'multiAgent': false,
      'workflows': false,
    };
    return {...defaults, ...?sessionTools[sessionId ?? currentSessionId ?? '__new__']};
  }

  Future<void> updateSessionTools(Map<String, bool> tools) async {
    final key = currentSessionId ?? '__new__';
    sessionTools[key] = {...toolsForSession(key), ...tools};
    final sessionId = currentSessionId;
    if (sessionId != null) {
      final updated = await _serve?.patchCapabilities(sessionId, sessionTools[key]!);
      if (updated == null) {
        errorBanner = 'Unable to update session tools on mothx serve.';
      } else {
        await loadSessionActivity(sessionId);
      }
    }
    notifyListeners();
  }

  Future<void> loadSubAgentMessages(String agentId) async {
    final sessionId = currentSessionId;
    if (sessionId == null || agentId.isEmpty) return;
    final raw = await _serve?.getSubAgentMessages(sessionId, agentId) ?? [];
    subAgentMessages[agentId] = raw
        .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    notifyListeners();
  }

  void _clearMessages() {
    messages.clear();
    _streamingId = null;
    _lastChunkRole = null;
    hasMoreHistory = false;
  }

  Future<void> createSession(String cwd) async {
    if (!isConnected) {
      errorBanner = 'Connect to mothx serve before creating a session.';
      notifyListeners();
      return;
    }
    currentSessionId = null;
    runtimeConfig = runtimeConfig.copyWith(cwd: cwd);
    _clearMessages();
    notifyListeners();
  }

  Future<void> selectSession(String id) async {
    final index = sessions.indexWhere((session) => session.id == id);
    if (index == -1) {
      errorBanner = 'Session "$id" was not found.';
      notifyListeners();
      return;
    }
    final session = sessions[index];
    if (await _loadSession(session)) {
      currentSessionId = id;
      runtimeConfig = runtimeConfig.copyWith(cwd: session.cwd);
    }
    notifyListeners();
  }

  Future<void> loadMoreHistory() async {
    final id = currentSessionId;
    if (id != null) await selectSession(id);
  }

  Future<void> renameSession(String id, String name) async {
    errorBanner = 'mothx serve does not expose a session rename endpoint.';
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    final serve = _serve;
    if (serve == null) return;
    if (!await serve.deleteSession(id)) {
      errorBanner = 'Unable to delete session "$id" from mothx serve.';
      notifyListeners();
      return;
    }
    sessions.removeWhere((session) => session.id == id);
    if (currentSessionId == id) {
      currentSessionId = null;
      _clearMessages();
      if (sessions.isNotEmpty) await selectSession(sessions.last.id);
    }
    notifyListeners();
  }

  String sessionName(String? id) {
    if (id == null) return 'New session';
    final index = sessions.indexWhere((session) => session.id == id);
    return index == -1 ? id : sessions[index].name;
  }

  List<ProviderInfo> get providers => config.providersFrom(settings);
  List<ModelInfo> modelsForProvider(String id) {
    final configured = config.modelsFrom(settings, id);
    if (configured.isNotEmpty) return configured;
    return serveModels
        .map((model) => ModelInfo(
              id: (model['id'] ?? '').toString(),
              name: (model['name'] ?? model['id'] ?? '').toString(),
              reasoning: model['reasoning'] == true,
              contextWindow: (model['contextWindow'] as num?)?.toInt() ?? 0,
              maxTokens: (model['maxTokens'] as num?)?.toInt() ?? 0,
            ))
        .where((model) => model.id.isNotEmpty)
        .toList();
  }

  Future<void> updateRuntimeConfig(SessionRuntimeConfig cfg) async {
    runtimeConfig = cfg.copyWith(cwd: runtimeConfig.cwd);
    final sessionId = currentSessionId;
    if (sessionId != null) {
      final mode = runtimeConfig.mode;
      final patched = await _serve?.patchCapabilities(sessionId, {'mode': mode});
      if (patched == null) {
        errorBanner = 'Unable to update session mode on mothx serve.';
      }
    }
    notifyListeners();
  }

  Future<void> prompt(String text, {List<Map<String, dynamic>> imageParts = const []}) async {
    final serve = _serve;
    if ((text.trim().isEmpty && imageParts.isEmpty) || isLoading || serve == null || !isConnected) {
      return;
    }

    isLoading = true;
    _abortRequested = false;
    final prompt = text.trim();
    _appendChunk(prompt, MessageRole.user);
    _finishStreaming();
    notifyListeners();

    try {
      await serve.streamChat(
        sessionId: currentSessionId,
        workDir: runtimeConfig.cwd,
        model: runtimeConfig.model.isEmpty ? 'default' : runtimeConfig.model,
        tools: toolsForSession(),
        messages: messages
            .where((message) =>
                message.content.isNotEmpty &&
                (message.role == MessageRole.user ||
                    message.role == MessageRole.assistant))
            .map((message) => {
                  'role': message.role.name,
                  'content': message == messages.last && imageParts.isNotEmpty
                      ? [
                          if (message.content.isNotEmpty)
                            {'type': 'text', 'text': message.content},
                          ...imageParts,
                        ]
                      : message.content,
                })
            .toList(),
        onSessionId: _registerSession,
      );
    } catch (e) {
      if (!_abortRequested) {
        _appendChunk('\nError: $e', MessageRole.assistant);
        _finishStreaming();
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _registerSession(String id) {
    if (id.isEmpty) return;
    final draftTools = sessionTools.remove('__new__');
    if (draftTools != null) sessionTools[id] = draftTools;
    if (sessions.every((session) => session.id != id)) {
      sessions.add(SessionInfo(
        id: id,
        name: 'Session $id',
        cwd: runtimeConfig.cwd,
        createdAt: DateTime.now().toIso8601String(),
      ));
    }
    currentSessionId = id;
    notifyListeners();
  }

  Future<void> sendMessage(String text, {List<Map<String, dynamic>> imageParts = const []}) =>
      prompt(text, imageParts: imageParts);

  void abort() {
    if (!isLoading) return;
    _abortRequested = true;
    _serve?.cancelActiveStream();
    _appendChunk('\nStopped', MessageRole.assistant);
    _finishStreaming();
    isLoading = false;
    notifyListeners();
  }

  void _handleEvent(ServeEvent event) {
    switch (event.type) {
      case 'content':
        _appendChunk(event.content, MessageRole.assistant);
        break;
      case 'user_content':
        if (messages.isEmpty ||
            messages.last.role != MessageRole.user ||
            messages.last.content != event.content) {
          _appendChunk(event.content, MessageRole.user);
        }
        break;
      case 'tool_call':
        final title = (event.data?['title'] ?? event.data?['tool'] ?? 'Calling tool').toString();
        _appendChunk('\nTool: $title\n', MessageRole.assistant);
        break;
      case 'toolCallUpdate':
        if (event.content.isNotEmpty) {
          _appendChunk('\n${event.content}\n', MessageRole.assistant);
        }
        break;
      case 'usage_update':
        final data = event.data;
        if (data != null) {
          contextUsed = (data['used'] as num?)?.toInt() ?? contextUsed;
          contextSize = (data['size'] as num?)?.toInt() ?? contextSize;
          final cost = data['cost'] as Map?;
          currentCost = (cost?['amount'] as num?)?.toDouble() ?? currentCost;
        }
        break;
      case 'error':
        _appendChunk('\nError: ${event.error}', MessageRole.assistant);
        _finishStreaming();
        isLoading = false;
        break;
    }
    notifyListeners();
  }

  void _appendChunk(String content, MessageRole role) {
    if (content.isEmpty) return;
    if (_streamingId == null || _lastChunkRole != role) {
      _finishStreaming();
      _streamingId = 'chunk-${DateTime.now().microsecondsSinceEpoch}-${messages.length}';
      _lastChunkRole = role;
      messages.add(ChatMessage(
        id: _streamingId!,
        role: role,
        content: content,
        timestamp: DateTime.now(),
        isStreaming: true,
      ));
    } else {
      messages.last.content += content;
    }
  }

  void _finishStreaming() {
    final id = _streamingId;
    if (id != null) {
      for (final message in messages) {
        if (message.id == id) message.isStreaming = false;
      }
    }
    _streamingId = null;
    _lastChunkRole = null;
  }

  Future<void> saveSettings(Map<String, dynamic> newSettings) async {
    settings = newSettings;
    await config.saveSettings(settings);
    final serve = _serve;
    if (serve != null && !await serve.saveSettings(settings)) {
      errorBanner = 'Saved settings locally, but mothx serve did not accept the update.';
    }
    notifyListeners();
  }

  Future<void> saveMemory(String content) async {
    final saved = await _serve?.saveMemory(content);
    if (saved == null) {
      errorBanner = 'Unable to save memory to mothx serve.';
    } else {
      memoryInfo = saved;
    }
    notifyListeners();
  }

  Future<void> saveServeConfig(Map<String, dynamic> nextConfig) async {
    final saved = await _serve?.saveServeConfig(nextConfig);
    if (saved == null) {
      errorBanner = 'Unable to save mothx serve configuration.';
    } else {
      serveConfig = saved;
      await refreshServeData();
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>?> browseDirectories({String? path}) async =>
      _serve?.browseDirectories(path: path);

  Future<void> refreshChannels() async {
    channels = await _serve?.getChannels() ?? [];
    notifyListeners();
  }

  Future<Map<String, dynamic>?> startWechatLogin() async {
    final status = await _serve?.startWechatLogin();
    await refreshChannels();
    return status;
  }

  Future<Map<String, dynamic>?> refreshWechatLogin() async =>
      _serve?.getWechatLogin();

  Future<void> cancelWechatLogin() async {
    await _serve?.cancelWechatLogin();
    await refreshChannels();
  }

  Future<void> setTheme(String value) async {
    theme = value;
    notifyListeners();
    try {
      await config.saveUiConfig({'theme': value});
    } catch (e) {
      errorBanner = 'Failed to save theme preference: $e';
      notifyListeners();
    }
  }

  void dismissError() {
    errorBanner = null;
    notifyListeners();
  }

  void reportError(String message) {
    errorBanner = message;
    notifyListeners();
  }

  void navigateToPage(String page) {
    currentPage = page;
    notifyListeners();
  }

  Future<void> disconnectServeMode() async {
    disconnectLogs();
    await _serveEventSub?.cancel();
    _serveEventSub = null;
    _serve?.dispose();
    _serve = null;
    serveUrl = null;
    isConnected = false;
    currentSessionId = null;
    _clearMessages();
    notifyListeners();
  }

  final List<LogEntry> logs = [];
  bool logsConnected = false;

  Future<void> connectLogs() async {
    final serve = _serve;
    if (serve == null) {
      errorBanner = 'Connect to mothx serve before opening logs.';
      notifyListeners();
      return;
    }
    await _logsSub?.cancel();
    logsConnected = true;
    _logsSub = serve.connectLogs().listen(
      (raw) {
        logs.add(LogEntry.fromJson(raw));
        if (logs.length > 1000) logs.removeRange(0, logs.length - 1000);
        notifyListeners();
      },
      onError: (Object error) {
        logsConnected = false;
        errorBanner = 'Log stream disconnected: $error';
        notifyListeners();
      },
      onDone: () {
        logsConnected = false;
        notifyListeners();
      },
    );
    notifyListeners();
  }

  void disconnectLogs() {
    _logsSub?.cancel();
    _logsSub = null;
    logsConnected = false;
    notifyListeners();
  }

  void clearLogs() {
    logs.clear();
    notifyListeners();
  }

  CronInfo? cronInfo;

  Future<void> loadCronForSession(String sessionId) =>
      refreshCronInfo(sessionId: sessionId);

  Future<void> refreshCronInfo({String? sessionId}) async {
    final serve = _serve;
    if (serve == null) return;
    final raw = await serve.getCronInfo(sessionId: sessionId ?? currentSessionId);
    if (raw == null) {
      errorBanner = 'Unable to load cron jobs from mothx serve.';
    } else {
      cronInfo = CronInfo.fromJson(raw);
    }
    notifyListeners();
  }

  Future<void> createCronJob({
    String? sessionId,
    String? name,
    String? prompt,
    String? schedule,
    bool? oneshot,
    String? mode,
  }) async {
    final serve = _serve;
    final targetSession = sessionId ?? currentSessionId;
    if (serve == null || targetSession == null || name == null || prompt == null) {
      errorBanner = 'Select a serve session before creating a cron job.';
      notifyListeners();
      return;
    }
    final created = await serve.createCronJob(
      sessionId: targetSession,
      name: name,
      prompt: prompt,
      schedule: schedule ?? '',
      oneshot: oneshot ?? false,
      mode: mode ?? 'yolo',
    );
    if (created == null) errorBanner = 'Unable to create cron job.';
    await refreshCronInfo(sessionId: targetSession);
  }

  Future<void> toggleCronJob(String jobId, [bool? enabled]) async {
    final serve = _serve;
    if (serve == null) return;
    final index = cronInfo?.jobs.indexWhere((job) => job.id == jobId) ?? -1;
    final current = index >= 0 ? cronInfo!.jobs[index].enabled : true;
    final result = await serve.updateCronJob(
      jobId,
      {'enabled': enabled ?? !current},
      sessionId: currentSessionId,
    );
    if (result == null) errorBanner = 'Unable to update cron job.';
    await refreshCronInfo();
  }

  Future<void> deleteCronJob(String jobId) async {
    final serve = _serve;
    if (serve == null) return;
    if (!await serve.deleteCronJob(jobId, sessionId: currentSessionId)) {
      errorBanner = 'Unable to delete cron job.';
    }
    await refreshCronInfo();
  }

  StatsSummary? statsSummary;
  String statsTimeRange = '7d';
  List<Map<String, dynamic>> statsTimeSeries = [];
  List<Map<String, dynamic>> statsByProvider = [];
  List<Map<String, dynamic>> statsByModel = [];
  Map<String, dynamic> statsRecent = {};

  Future<void> refreshStats([String? range]) async {
    if (range != null) statsTimeRange = range;
    final serve = _serve;
    if (serve == null) return;
    final now = DateTime.now().toLocal();
    final hours = switch (statsTimeRange) {
      '24h' => 24,
      '30d' => 24 * 30,
      '90d' => 24 * 90,
      _ => 24 * 7,
    };
    final from = now.subtract(Duration(hours: hours));
    String date(DateTime value) =>
        '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    final params = <String, String>{'from': date(from), 'to': date(now)};
    final results = await Future.wait<dynamic>([
      serve.getStatsSummary(from: params['from'], to: params['to']),
      serve.getStatsTimeSeries(
        from: params['from'],
        to: params['to'],
        groupBy: statsTimeRange == '24h' ? '1h' : 'day',
      ),
      serve.getStatsByProvider(from: params['from'], to: params['to']),
      serve.getStatsByModel(from: params['from'], to: params['to']),
      serve.getStatsRecent(from: params['from'], to: params['to'], page: 1, pageSize: 20),
    ]);
    final raw = results[0] as Map<String, dynamic>?;
    if (raw == null) {
      statsSummary = null;
      errorBanner = 'Unable to load usage statistics from mothx serve.';
    } else {
      statsSummary = StatsSummary.fromJson(raw);
      statsTimeSeries = results[1] as List<Map<String, dynamic>>;
      statsByProvider = results[2] as List<Map<String, dynamic>>;
      statsByModel = results[3] as List<Map<String, dynamic>>;
      statsRecent = results[4] as Map<String, dynamic>? ?? {};
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _serveEventSub?.cancel();
    _logsSub?.cancel();
    _serve?.dispose();
    super.dispose();
  }
}

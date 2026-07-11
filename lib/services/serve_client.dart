import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;


/// A streamed event decoded from a mothx serve SSE endpoint.
class ServeEvent {
  final String type;
  final String? sessionId;
  final String content;
  final Map<String, dynamic>? data;
  final String? error;

  ServeEvent({
    required this.type,
    this.sessionId,
    this.content = '',
    this.data,
    this.error,
  });
}

/// ServeClient communicates with a running `mothx serve` instance via HTTP/SSE.
///
/// The serve mode exposes:
///   - OpenAI-compatible `/v1/chat/completions` with SSE streaming
///   - REST API under `/api/*` for sessions, stats, settings, etc.
///   - WebSocket at `/ws` for logs
class ServeClient {
  final String baseUrl;
  final String? authToken;

  late http.Client _httpClient;
  bool _connected = false;

  // Broadcast stream for SSE events during chat streaming.
  final StreamController<ServeEvent> _events =
      StreamController<ServeEvent>.broadcast();

  Stream<ServeEvent> get events => _events.stream;
  bool get isConnected => _connected;

  ServeClient({
    required this.baseUrl,
    this.authToken,
  }) {
    _httpClient = http.Client();
  }

  /// Health check: GET /health
  Future<bool> ping() async {
    try {
      final res = await _httpClient
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      _connected = res.statusCode == 200;
      return _connected;
    } catch (_) {
      _connected = false;
      return false;
    }
  }

  /// GET /api/status - serve status with features
  Future<Map<String, dynamic>?> getStatus() async {
    final data = await _get('/api/status');
    return data;
  }

  Future<Map<String, dynamic>?> getCapabilities() => _get('/api/capabilities');

  Future<List<Map<String, dynamic>>> getChannels() => _getList('/api/channels');

  Future<Map<String, dynamic>?> getMemory() => _get('/api/memory');

  Future<Map<String, dynamic>?> saveMemory(String content) =>
      _sendJson('PUT', '/api/memory', {'content': content});

  Future<Map<String, dynamic>?> browseDirectories({String? path}) {
    final query = path == null || path.isEmpty
        ? ''
        : '?path=${Uri.encodeComponent(path)}';
    return _get('/api/browse$query');
  }

  Future<Map<String, dynamic>?> getWechatLogin() =>
      _get('/api/channels/wechat/login');

  Future<Map<String, dynamic>?> startWechatLogin() =>
      _sendJson('POST', '/api/channels/wechat/login', {});

  Future<Map<String, dynamic>?> cancelWechatLogin() =>
      _sendJson('DELETE', '/api/channels/wechat/login', null);

  /// GET /api/sessions - list active sessions
  Future<List<Map<String, dynamic>>> listSessions() async {
    final data = await _get('/api/sessions');
    if (data == null) return [];
    final sessions = data['sessions'];
    if (sessions is List) {
      return sessions.map((s) => s as Map<String, dynamic>).toList();
    }
    return [];
  }

  /// GET /api/sessions/{id}/messages - get session message history
  Future<List<Map<String, dynamic>>> getSessionMessages(String sessionId) async {
    final data = await _get('/api/sessions/${Uri.encodeComponent(sessionId)}/messages');
    if (data == null) return [];
    final messages = data['messages'];
    if (messages is List) {
      return messages.map((m) => m as Map<String, dynamic>).toList();
    }
    return [];
  }

  /// DELETE /api/sessions/{id} - permanently delete a serve session.
  Future<bool> deleteSession(String sessionId) async {
    try {
      final request = http.Request(
        'DELETE',
        Uri.parse('$baseUrl/api/sessions/${Uri.encodeComponent(sessionId)}'),
      );
      if (authToken != null && authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      final response = await _httpClient.send(request);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// GET /api/sessions/{id}/tool-results/{toolCallID} - get tool result detail
  Future<Map<String, dynamic>?> getToolResult(String sessionId, String toolCallID) async {
    final path = '/api/sessions/${Uri.encodeComponent(sessionId)}/tool-results/${Uri.encodeComponent(toolCallID)}';
    return _get(path);
  }

  /// GET /api/sessions/{id}/subagents - list sub-agents for a session
  Future<List<Map<String, dynamic>>> getSubAgents(String sessionId) async {
    final data = await _get('/api/sessions/${Uri.encodeComponent(sessionId)}/subagents');
    if (data == null) return [];
    final agents = data['subagents'];
    if (agents is List) {
      return agents.map((a) => a as Map<String, dynamic>).toList();
    }
    return [];
  }

  /// GET /api/sessions/{id}/subagents/{agentID}/messages - get sub-agent messages
  Future<List<Map<String, dynamic>>> getSubAgentMessages(String sessionId, String agentID) async {
    final data = await _get(
        '/api/sessions/${Uri.encodeComponent(sessionId)}/subagents/${Uri.encodeComponent(agentID)}/messages');
    if (data == null) return [];
    final messages = data['messages'];
    if (messages is List) {
      return messages.map((m) => m as Map<String, dynamic>).toList();
    }
    return [];
  }

  /// GET /api/sessions/{id}/run-events - get run events
  Future<List<Map<String, dynamic>>> getRunEvents(String sessionId) async {
    final data = await _get('/api/sessions/${Uri.encodeComponent(sessionId)}/run-events');
    if (data == null) return [];
    final events = data['events'];
    if (events is List) {
      return events.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  /// GET /api/sessions/{id}/capability-events - get capability events
  Future<List<Map<String, dynamic>>> getCapabilityEvents(String sessionId) async {
    final data = await _get('/api/sessions/${Uri.encodeComponent(sessionId)}/capability-events');
    if (data == null) return [];
    final events = data['events'];
    if (events is List) {
      return events.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  /// GET /api/stats/summary - get usage statistics summary
  Future<Map<String, dynamic>?> getStatsSummary({
    String? from,
    String? to,
    String? vendor,
    String? model,
  }) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    if (vendor != null) params['vendor'] = vendor;
    if (model != null) params['model'] = model;
    final query = params.isNotEmpty ? '?${_encodeQuery(params)}' : '';
    return _get('/api/stats/summary$query');
  }

  /// GET /api/stats/timeseries - get time series data
  Future<List<Map<String, dynamic>>> getStatsTimeSeries({
    String? from,
    String? to,
    String? groupBy,
  }) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    if (groupBy != null) params['groupBy'] = groupBy;
    final query = params.isNotEmpty ? '?${_encodeQuery(params)}' : '';
    final data = await _get('/api/stats/timeseries$query');
    if (data is List) return (data as List).map((e) => e as Map<String, dynamic>).toList();
    return [];
  }

  /// GET /api/stats/by-provider
  Future<List<Map<String, dynamic>>> getStatsByProvider({
    String? from,
    String? to,
  }) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    final query = params.isNotEmpty ? '?${_encodeQuery(params)}' : '';
    final data = await _get('/api/stats/by-provider$query');
    if (data is List) return (data as List).map((e) => e as Map<String, dynamic>).toList();
    return [];
  }

  /// GET /api/stats/by-model
  Future<List<Map<String, dynamic>>> getStatsByModel({
    String? from,
    String? to,
  }) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    final query = params.isNotEmpty ? '?${_encodeQuery(params)}' : '';
    final data = await _get('/api/stats/by-model$query');
    if (data is List) return (data as List).map((e) => e as Map<String, dynamic>).toList();
    return [];
  }

  /// GET /api/stats/recent
  Future<Map<String, dynamic>?> getStatsRecent({
    String? from,
    String? to,
    int? page,
    int? pageSize,
  }) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    if (page != null) params['page'] = '$page';
    if (pageSize != null) params['pageSize'] = '$pageSize';
    final query = params.isNotEmpty ? '?${_encodeQuery(params)}' : '';
    return _get('/api/stats/recent$query');
  }

  /// GET /v1/models - list available models
  Future<List<Map<String, dynamic>>> listModels() async {
    final data = await _get('/v1/models');
    if (data == null) return [];
    final list = data['data'];
    if (list is List) {
      return list.map((m) => m as Map<String, dynamic>).toList();
    }
    return [];
  }

  /// POST /v1/chat/completions with SSE streaming.
  ///
  /// [messages] is a list of {role, content} maps.
  /// [sessionId] optional existing session ID (null for new session).
  /// [workDir] working directory for new sessions.
  /// [model] model name.
  /// [tools] session tool toggles.
  /// [onSessionId] callback when a new session ID is assigned.
  Future<String> streamChat({
    required List<Map<String, dynamic>> messages,
    String? sessionId,
    String? workDir,
    String model = 'default',
    Map<String, bool>? tools,
    bool transcript = true,
    void Function(String newSessionId)? onSessionId,
  }) async {
    final body = <String, dynamic>{
      'model': model,
      'stream': true,
      'messages': messages,
      'x_transcript': transcript,
    };
    if (sessionId != null && sessionId.isNotEmpty) {
      body['x_session_id'] = sessionId;
    }
    if (workDir != null && workDir.isNotEmpty) {
      body['x_working_dir'] = workDir;
    }
    if (tools != null && tools.isNotEmpty) {
      body['x_tools'] = tools;
    }

    final uri = Uri.parse('$baseUrl/v1/chat/completions');
    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json';
    if (authToken != null && authToken!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $authToken';
    }
    request.body = jsonEncode(body);

    final streamedResponse = await _httpClient.send(request);

    if (streamedResponse.statusCode != 200) {
      final errorBody = await streamedResponse.stream.bytesToString();
      String errorMsg = '${streamedResponse.statusCode} ${streamedResponse.reasonPhrase}';
      try {
        final errJson = jsonDecode(errorBody) as Map<String, dynamic>;
        errorMsg = errJson['error']?['message'] ?? errJson['error'] ?? errorMsg;
      } catch (_) {}
      throw Exception(errorMsg);
    }

    return _consumeSSE(streamedResponse.stream, onSessionId: onSessionId);
  }

  /// GET /api/sessions/{id}/stream - SSE for an active session run.
  ///
  /// Used to tail an ongoing session's events (run events, capability events, transcript).
  Stream<ServeEvent> streamSessionEvents(String sessionId, {
    int? afterEntrySeq,
    int? afterRunSeq,
    int? afterCapabilitySeq,
  }) {
    final params = <String, String>{};
    if (afterEntrySeq != null && afterEntrySeq > 0) {
      params['after_entry_seq'] = '$afterEntrySeq';
    }
    if (afterRunSeq != null && afterRunSeq > 0) {
      params['after_run_seq'] = '$afterRunSeq';
    }
    if (afterCapabilitySeq != null && afterCapabilitySeq > 0) {
      params['after_capability_seq'] = '$afterCapabilitySeq';
    }
    final query = params.isNotEmpty ? '?${_encodeQuery(params)}' : '';
    final uri = Uri.parse(
        '$baseUrl/api/sessions/${Uri.encodeComponent(sessionId)}/stream$query');

    final controller = StreamController<ServeEvent>.broadcast();

    _httpClient.send(http.Request('GET', uri)).then((streamedResponse) {
      if (streamedResponse.statusCode != 200) {
        controller.addError(Exception('Stream failed: ${streamedResponse.statusCode}'));
        controller.close();
        return;
      }
      _consumeSSEForStream(streamedResponse.stream, controller);
    }).catchError((e) {
      controller.addError(e);
      controller.close();
    });

    return controller.stream;
  }

  /// PATCH /api/sessions/{id}/capabilities - update session tool capabilities
  Future<Map<String, dynamic>?> patchCapabilities(
    String sessionId,
    Map<String, dynamic> capabilities,
  ) async {
    final uri = Uri.parse('$baseUrl/api/sessions/${Uri.encodeComponent(sessionId)}/capabilities');
    final request = http.Request('PATCH', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(capabilities);
    if (authToken != null && authToken!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $authToken';
    }
    final response = await _httpClient.send(request);
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200) {
      return null;
    }
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// PUT /api/settings - update settings (triggers hot-reload)
  Future<bool> saveSettings(Map<String, dynamic> settings) async {
    try {
      final uri = Uri.parse('$baseUrl/api/settings');
      final request = http.Request('PUT', uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(settings);
      if (authToken != null && authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      final response = await _httpClient.send(request);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// GET /api/settings
  Future<Map<String, dynamic>?> getSettings() async {
    return _get('/api/settings');
  }

  /// GET /api/serve/config
  Future<Map<String, dynamic>?> getServeConfig() async {
    return _get('/api/serve/config');
  }

  /// PUT /api/serve/config - update serve configuration
  Future<Map<String, dynamic>?> saveServeConfig(Map<String, dynamic> config) async {
    try {
      final uri = Uri.parse('$baseUrl/api/serve/config');
      final request = http.Request('PUT', uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(config);
      if (authToken != null && authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      final response = await _httpClient.send(request);
      final body = await response.stream.bytesToString();
      if (response.statusCode != 200) return null;
      try {
        return jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  // -----------------------------------------------------------------------
  // Cron API methods
  // -----------------------------------------------------------------------

  /// GET /api/cron - list cron jobs
  Future<Map<String, dynamic>?> getCronInfo({String? sessionId}) async {
    final query = (sessionId != null && sessionId.isNotEmpty)
        ? '?sessionId=${Uri.encodeComponent(sessionId)}'
        : '';
    return _get('/api/cron$query');
  }

  /// POST /api/cron - create a new cron job
  Future<Map<String, dynamic>?> createCronJob({
    required String sessionId,
    required String name,
    required String prompt,
    String schedule = '',
    bool oneshot = false,
    String mode = 'yolo',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/cron');
      final body = <String, dynamic>{
        'sessionId': sessionId,
        'name': name,
        'prompt': prompt,
        'schedule': schedule,
        'oneshot': oneshot,
        'mode': mode,
      };
      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);
      if (authToken != null && authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      final response = await _httpClient.send(request);
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode != 200 && response.statusCode != 201) return null;
      try {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// PATCH /api/cron/{id} - toggle or update a cron job
  Future<Map<String, dynamic>?> updateCronJob(String jobId, Map<String, dynamic> updates, {String? sessionId}) async {
    try {
      final query = (sessionId != null && sessionId.isNotEmpty)
          ? '?sessionId=${Uri.encodeComponent(sessionId)}'
          : '';
      final uri = Uri.parse('$baseUrl/api/cron/${Uri.encodeComponent(jobId)}$query');
      final request = http.Request('PATCH', uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(updates);
      if (authToken != null && authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      final response = await _httpClient.send(request);
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode != 200) return null;
      try {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// DELETE /api/cron/{id} - delete a cron job
  Future<bool> deleteCronJob(String jobId, {String? sessionId}) async {
    try {
      final query = (sessionId != null && sessionId.isNotEmpty)
          ? '?sessionId=${Uri.encodeComponent(sessionId)}'
          : '';
      final uri = Uri.parse('$baseUrl/api/cron/${Uri.encodeComponent(jobId)}$query');
      final request = http.Request('DELETE', uri);
      if (authToken != null && authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      final response = await _httpClient.send(request);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// Connect a WebSocket for logs: /ws/logs
  /// Returns a stream of log entries.
  Stream<Map<String, dynamic>> connectLogs() {
    final wsUrl = baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    final uri = Uri.parse('$wsUrl/ws/logs');
    final headers = <String, String>{};
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();

    WebSocket.connect(uri.toString(), headers: headers).then((ws) {
      ws.listen(
        (data) {
          try {
            final msg = jsonDecode(data.toString()) as Map<String, dynamic>;
            if (msg['type'] == 'heartbeat') return;
            controller.add(msg);
          } catch (_) {
            controller.add({'type': 'log', 'message': data.toString()});
          }
        },
        onError: (e) => controller.addError(e),
        onDone: () => controller.close(),
      );
    }).catchError((e) {
      controller.addError(e);
      controller.close();
    });

    return controller.stream;
  }

  /// Dispose all resources.
  void dispose() {
    _httpClient.close();
    _events.close();
  }

  /// Stops the local HTTP stream. The server may continue work when it does
  /// not expose a cancellation endpoint, but the GUI stops consuming output.
  void cancelActiveStream() {
    _httpClient.close();
    _httpClient = http.Client();
  }

  // -----------------------------------------------------------------------
  // Internal helpers
  // -----------------------------------------------------------------------

  Future<Map<String, dynamic>?> _get(String path) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final headers = <String, String>{};
      if (authToken != null && authToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      final res = await _httpClient.get(uri, headers: headers);
      if (res.statusCode != 200) return null;
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final res = await _httpClient.get(uri, headers: _authHeaders());
      if (res.statusCode != 200 || res.body.isEmpty) return [];
      final value = jsonDecode(res.body);
      if (value is! List) return [];
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> _sendJson(
    String method,
    String path,
    Map<String, dynamic>? body,
  ) async {
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'));
      request.headers.addAll(_authHeaders());
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final response = await _httpClient.send(request);
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      if (responseBody.isEmpty) return {};
      final decoded = jsonDecode(responseBody);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _authHeaders() {
    if (authToken == null || authToken!.isEmpty) return {};
    return {'Authorization': 'Bearer $authToken'};
  }

  /// Parse SSE stream and emit ServeEvents. Returns stopReason.
  Future<String> _consumeSSE(
    Stream<List<int>> byteStream, {
    void Function(String newSessionId)? onSessionId,
  }) async {
    var buffer = '';
    String stopReason = '';

    await for (final chunk in byteStream.transform(utf8.decoder)) {
      buffer += chunk;
      buffer = _processSSEBuffer(buffer, (event, data) {
        if (event == 'done' || data == '[DONE]') {
          stopReason = 'stop';
          return;
        }
        if (event == 'heartbeat') return;
        if (event == 'error') {
          try {
            final err = jsonDecode(data) as Map<String, dynamic>;
            _events.add(ServeEvent(type: 'error', error: err['error'] ?? data));
          } catch (_) {
            _events.add(ServeEvent(type: 'error', error: data));
          }
          return;
        }

        try {
          final parsed = jsonDecode(data) as Map<String, dynamic>;
          final sessionId = (parsed['x_session_id'] ??
                  parsed['xSessionId'] ??
                  parsed['sessionId'])
              ?.toString();
          if (sessionId != null && sessionId.isNotEmpty) {
            onSessionId?.call(sessionId);
          }

          // Mothx serve emits WebUI transcript entries while a run is active.
          if (event == 'transcript') {
            final message = parsed['message'];
            if (message is Map) {
              final entry = Map<String, dynamic>.from(message);
              final role = entry['role']?.toString();
              final content = entry['content']?.toString() ?? '';
              if (content.isNotEmpty) {
                _events.add(ServeEvent(
                  type: role == 'user' ? 'user_content' : 'content',
                  sessionId: sessionId,
                  content: content,
                  data: entry,
                ));
              }
              return;
            }
            final entryType = parsed['type']?.toString() ?? '';
            final text = parsed['text']?.toString() ?? '';
            final content = parsed['content'] as Map<String, dynamic>?;
            final newText = content?['text']?.toString() ?? text;

            if (entryType == 'user_message' || entryType == 'user_message_chunk') {
              _events.add(ServeEvent(
                type: 'user_content',
                sessionId: parsed['sessionId']?.toString(),
                content: newText,
                data: {'chunkType': entryType},
              ));
            } else if (entryType == 'agent_message' ||
                entryType == 'agent_message_chunk' ||
                entryType == 'agent_thought' ||
                entryType == 'agent_thought_chunk') {
              _events.add(ServeEvent(
                type: 'content',
                sessionId: parsed['sessionId']?.toString(),
                content: newText,
                data: {'chunkType': entryType},
              ));
            } else if (entryType == 'tool_call') {
              _events.add(ServeEvent(
                type: 'tool_call',
                sessionId: parsed['sessionId']?.toString(),
                data: {
                  'id': parsed['toolCallId'],
                  'title': parsed['title'],
                  'kind': parsed['kind'],
                  'status': parsed['status'],
                  'input': parsed['rawInput'],
                },
              ));
            } else if (entryType == 'tool_call_update') {
              _events.add(ServeEvent(
                type: 'toolCallUpdate',
                sessionId: parsed['sessionId']?.toString(),
                content: parsed['content']?.toString() ?? '',
                data: {
                  'id': parsed['toolCallId'],
                  'title': parsed['title'],
                  'status': parsed['status'],
                  'output': parsed['rawOutput'],
                },
              ));
            } else if (entryType == 'session_created') {
              final sid = parsed['sessionId']?.toString();
              if (sid != null && sid.isNotEmpty) {
                onSessionId?.call(sid);
              }
            }

            return;
          }

          if (event == 'tool_status') {
            _events.add(ServeEvent(
              type: 'tool_call',
              sessionId: sessionId,
              data: {
                'title': parsed['tool'] ?? 'tool',
                'status': parsed['status'],
                'rawInput': parsed['args'],
              },
            ));
            return;
          }

          // Handle delta events (OpenAI-style streaming)
          if (event == 'delta' || event == 'message') {
            final choices = parsed['choices'] as List<dynamic>?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0] is Map
                  ? (choices[0] as Map<String, dynamic>)['delta']
                  : null;
              if (delta is Map) {
                final content = delta['content']?.toString() ?? '';
                if (content.isNotEmpty) {
                  _events.add(ServeEvent(
                    type: 'content',
                    sessionId: sessionId,
                    content: content,
                    data: {'chunkType': 'delta'},
                  ));
                }
                // Check for tool calls in delta
                final toolCalls = delta['tool_calls'];
                if (toolCalls is List) {
                  for (final tc in toolCalls) {
                    if (tc is Map) {
                      _events.add(ServeEvent(
                        type: 'tool_call',
                        sessionId: sessionId,
                        data: {
                          'id': tc['id'],
                          'title': tc['function']?['name'] ?? 'tool',
                          'kind': 'function',
                          'status': 'in_progress',
                          'input': tc['function']?['arguments'],
                        },
                      ));
                    }
                  }
                }
              }
              // Check finish_reason
              final finishReason = choices[0] is Map
                  ? (choices[0] as Map<String, dynamic>)['finish_reason']
                  : null;
              if (finishReason != null && stopReason.isEmpty) {
                stopReason = finishReason.toString();
              }
            }
            return;
          }

          // Handle generic content events
          final content = parsed['content']?.toString() ?? '';
          if (content.isNotEmpty) {
            _events.add(ServeEvent(
              type: 'content',
              sessionId: sessionId,
              content: content,
              data: parsed,
            ));
          }
        } catch (_) {
          // Ignore malformed JSON in SSE events
        }
      });

      if (stopReason.isNotEmpty) break;
    }

    // Process remaining buffer
    _processSSEBuffer(buffer, (event, data) {});

    return stopReason;
  }

  /// Process an SSE buffer, emitting complete events to [onEvent].
  /// Returns the remaining (incomplete) buffer.
  String _processSSEBuffer(
    String buffer,
    void Function(String event, String data) onEvent,
  ) {
    buffer = buffer.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    int idx = buffer.indexOf('\n\n');
    while (idx != -1) {
      final block = buffer.substring(0, idx);
      buffer = buffer.substring(idx + 2);

      final parsed = _parseSSEBlock(block);
      if (parsed != null) {
        onEvent(parsed.event, parsed.data);
      }

      idx = buffer.indexOf('\n\n');
    }

    return buffer;
  }

  ({String event, String data})? _parseSSEBlock(String raw) {
    final lines = raw.split('\n');
    final data = <String>[];
    var event = 'message';

    for (final line in lines) {
      if (line.isEmpty || line.startsWith(':')) continue;
      if (line.startsWith('event:')) {
        event = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        data.add(line.substring(5).trimLeft());
      }
    }

    if (data.isEmpty) return null;
    return (event: event, data: data.join('\n'));
  }

  /// Consume SSE for session event streaming (run events, capability events).
  void _consumeSSEForStream(
    Stream<List<int>> byteStream,
    StreamController<ServeEvent> controller,
  ) {
    var buffer = '';

    byteStream.transform(utf8.decoder).listen(
      (chunk) {
        buffer += chunk;
        buffer = _processSSEBufferForStream(buffer, controller);
      },
      onDone: () {
        // Emit final done event
        controller.add(ServeEvent(type: 'status', data: {'status': 'completed'}));
        controller.close();
      },
      onError: (e) {
        controller.addError(e);
        controller.close();
      },
    );
  }

  String _processSSEBufferForStream(
    String buffer,
    StreamController<ServeEvent> controller,
  ) {
    buffer = buffer.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    int idx = buffer.indexOf('\n\n');
    while (idx != -1) {
      final block = buffer.substring(0, idx);
      buffer = buffer.substring(idx + 2);

      final parsed = _parseSSEBlock(block);
      if (parsed == null) {
        idx = buffer.indexOf('\n\n');
        continue;
      }

      if (parsed.data == '[DONE]' || parsed.event == 'done') {
        idx = buffer.indexOf('\n\n');
        continue;
      }
      if (parsed.event == 'heartbeat') {
        idx = buffer.indexOf('\n\n');
        continue;
      }

      try {
        final data = jsonDecode(parsed.data) as Map<String, dynamic>;
        switch (parsed.event) {
          case 'transcript':
            final entryType = data['type']?.toString() ?? '';
            final text = data['text']?.toString() ?? '';
            if (entryType == 'agent_message' ||
                entryType == 'agent_message_chunk') {
              controller.add(ServeEvent(
                type: 'content',
                sessionId: data['sessionId']?.toString(),
                content: text,
                data: data,
              ));
            } else if (entryType == 'tool_call') {
              controller.add(ServeEvent(
                type: 'tool_call',
                sessionId: data['sessionId']?.toString(),
                data: data,
              ));
            } else if (entryType == 'tool_call_update') {
              controller.add(ServeEvent(
                type: 'toolCallUpdate',
                sessionId: data['sessionId']?.toString(),
                content: data['content']?.toString() ?? '',
                data: data,
              ));
            }
            break;
          case 'run_event':
            controller.add(ServeEvent(
              type: 'run_event',
              data: data,
            ));
            break;
          case 'capability_event':
            controller.add(ServeEvent(
              type: 'capability_event',
              data: data,
            ));
            break;
          case 'error':
            controller.add(ServeEvent(
              type: 'error',
              error: data['error'] ?? parsed.data,
            ));
            break;
        }
      } catch (_) {
        // Ignore malformed events
      }

      idx = buffer.indexOf('\n\n');
    }

    return buffer;
  }

  String _encodeQuery(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}

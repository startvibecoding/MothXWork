import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

/// An event emitted from the ACP stream, mirroring the Go ACP protocol.
class AcpEvent {
  final String type;
  final String? sessionId;
  final String content;
  final Map<String, dynamic>? data;
  final String? error;

  AcpEvent({
    required this.type,
    this.sessionId,
    this.content = '',
    this.data,
    this.error,
  });
}

/// Usage info from a usage_update notification.
class AcpUsage {
  final int used;
  final int size;
  final double? costAmount;

  AcpUsage({
    required this.used,
    required this.size,
    this.costAmount,
  });

  factory AcpUsage.fromData(Map<String, dynamic> data) {
    return AcpUsage(
      used: (data['used'] as num?)?.toInt() ?? 0,
      size: (data['size'] as num?)?.toInt() ?? 0,
      costAmount: (data['cost'] as Map?)?['amount']?.toDouble(),
    );
  }
}

/// AcpClient communicates with the `mothx acp` subprocess via JSON-RPC
/// over stdin/stdout, implementing the Agent Client Protocol (ACP).
///
/// Supported ACP methods:
///   - initialize
///   - session/new
///   - session/load
///   - session/prompt
///   - session/cancel
///   - session/close
///   - session/list
///
/// Server→client notifications:
///   - session/update (agent_message_chunk, agent_thought_chunk, tool_call,
///     tool_call_update, user_message_chunk, status, usage_update)
///   - session/request_permission
class AcpClient {
  Process? _process;
  IOSink? _stdin;
  final String mothxPath;

  int _nextId = 0;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  final Set<String> _sessions = {};
  Set<String> get sessions => UnmodifiableSetView(_sessions);

  final StreamController<AcpEvent> _events =
      StreamController<AcpEvent>.broadcast();

  Stream<AcpEvent> get events => _events.stream;

  StreamSubscription<String>? _stdoutSub;
  bool _closed = false;

  AcpClient(this.mothxPath);

  /// Starts the `mothx acp` subprocess and the stdout reader.
  Future<void> start() async {
    _process = await Process.start(
      mothxPath,
      ['acp'],
      mode: ProcessStartMode.normal,
    );

    _stdin = _process!.stdin;

    _process!.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => stderr.writeln('[MOTHX] $line'));

    _stdoutSub = _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleLine, onDone: _onDone, onError: (_) {});
  }

  void _onDone() {
    if (!_closed) {
      _events.add(AcpEvent(
        type: 'error',
        error: 'Mothx process exited',
      ));
    }
  }

  void _handleLine(String line) {
    if (line.trim().isEmpty) return;
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(line) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    // Response to a numeric-id request.
    final id = msg['id'];
    if (id is int &&
        (msg.containsKey('result') || msg.containsKey('error'))) {
      final completer = _pending.remove(id);
      if (completer != null && !completer.isCompleted) {
        completer.complete(msg);
        return;
      }
    }

    // Notification / server request (e.g. session/update, request_permission).
    final method = msg['method'];
    if (method is String && method.isNotEmpty) {
      _handleNotification(method, msg);
    }
  }

  void _handleNotification(String method, Map<String, dynamic> msg) {
    switch (method) {
      case 'session/update':
        _handleSessionUpdate(msg);
        break;
      case 'session/request_permission':
        _handlePermissionRequest(msg);
        break;
    }
  }

  void _handleSessionUpdate(Map<String, dynamic> msg) {
    final params = msg['params'] as Map<String, dynamic>?;
    if (params == null) return;
    final sessionId = params['sessionId']?.toString();
    final update = params['update'] as Map<String, dynamic>?;
    if (update == null) return;

    final sessionUpdate = (update['sessionUpdate'] ?? '').toString();

    switch (sessionUpdate) {
      case 'user_message_chunk':
        final content = update['content'] as Map<String, dynamic>?;
        final text = content?['text']?.toString() ?? '';
        _events.add(AcpEvent(
          type: 'user_content',
          sessionId: sessionId,
          content: text,
          data: {
            'type': content?['type'],
            'chunkType': sessionUpdate,
          },
        ));
        break;
      case 'agent_thought_chunk':
      case 'agent_message_chunk':
        final content = update['content'] as Map<String, dynamic>?;
        final text = content?['text']?.toString() ?? '';
        _events.add(AcpEvent(
          type: 'content',
          sessionId: sessionId,
          content: text,
          data: {
            'type': content?['type'],
            'chunkType': sessionUpdate,
          },
        ));
        break;
      case 'tool_call':
        _events.add(AcpEvent(
          type: 'tool_call',
          sessionId: sessionId,
          data: {
            'toolCallId': update['toolCallId'],
            'title': update['title'],
            'kind': update['kind'],
            'status': update['status'],
            'rawInput': update['rawInput'],
          },
        ));
        break;
      case 'tool_call_update':
        final rawOutput = update['rawOutput'];
        String content = '';
        if (rawOutput is Map && rawOutput['content'] is String) {
          content = rawOutput['content'] as String;
        }
        _events.add(AcpEvent(
          type: 'toolCallUpdate',
          sessionId: sessionId,
          content: content,
          data: {
            'toolCallId': update['toolCallId'],
            'title': update['title'],
            'status': update['status'],
            'rawOutput': rawOutput,
          },
        ));
        break;
      case 'status':
        _events.add(AcpEvent(
          type: 'status',
          sessionId: sessionId,
          content: update['status']?.toString() ?? '',
          data: {'status': update['status']},
        ));
        break;
      case 'usage_update':
        final used = (update['used'] as num?)?.toInt() ?? 0;
        final size = (update['size'] as num?)?.toInt() ?? 0;
        final cost = update['cost'] as Map?;
        _events.add(AcpEvent(
          type: 'usage_update',
          sessionId: sessionId,
          content: '$used/$size',
          data: {
            'used': used,
            'size': size,
            if (cost != null) 'cost': cost,
          },
        ));
        break;
    }
  }

  void _handlePermissionRequest(Map<String, dynamic> msg) {
    final requestId = msg['id']?.toString() ?? '';
    if (requestId.isEmpty) return;
    final params = msg['params'] as Map<String, dynamic>?;
    if (params == null) return;
    final toolCall = params['toolCall'] as Map<String, dynamic>? ?? {};
    final optionsRaw = params['options'] as List<dynamic>? ?? [];

    _events.add(AcpEvent(
      type: 'permission_request',
      data: {
        'requestId': requestId,
        'sessionId': params['sessionId'],
        'toolCallId': toolCall['toolCallId'],
        'title': toolCall['title'],
        'kind': toolCall['kind'],
        'rawInput': toolCall['rawInput'],
        'options': optionsRaw,
      },
    ));
  }

  /// Sends a JSON-RPC request and waits for the response result.
  Future<Map<String, dynamic>> _call(
      String method, Map<String, dynamic> params) async {
    final id = ++_nextId;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;

    final req = jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    });
    _stdin?.add(utf8.encode('$req\n'));
    await _stdin?.flush();

    final resp = await completer.future;
    if (resp['error'] != null) {
      final err = resp['error'] as Map<String, dynamic>;
      throw Exception('ACP error ${err['code']}: ${err['message']}');
    }
    final result = resp['result'];
    if (result is Map<String, dynamic>) return result;
    return {};
  }

  /// JSON-RPC initialize. Returns agent capabilities.
  Future<Map<String, dynamic>> initialize(
      String clientName, String clientVersion) {
    return _call('initialize', {
      'protocolVersion': 1,
      'clientInfo': {'name': clientName, 'version': clientVersion},
      'clientCapabilities': {
        'session': {'cancel': true, 'close': true, 'list': true}
      },
    });
  }

  /// Create a new session. Returns sessionId.
  Future<String> newSession(String cwd,
      {List<Map<String, dynamic>>? mcpServers}) async {
    final Map<String, dynamic> params = {'cwd': cwd};
    if (mcpServers != null) {
      params['mcpServers'] = mcpServers;
    }
    final result = await _call('session/new', params);
    final sessionId = result['sessionId']?.toString() ?? '';
    if (sessionId.isNotEmpty) _sessions.add(sessionId);
    return sessionId;
  }

  /// Load an existing session. Emits historical messages as notifications.
  Future<void> loadSession(String sessionId, String cwd,
      {int? limit, List<Map<String, dynamic>>? mcpServers}) async {
    final Map<String, dynamic> params = {
      'sessionId': sessionId,
      'cwd': cwd,
    };
    if (limit != null) {
      params['limit'] = limit;
    }
    if (mcpServers != null) {
      params['mcpServers'] = mcpServers;
    }
    await _call('session/load', params);
    _sessions.add(sessionId);
  }

  /// Send a prompt. Returns stopReason (e.g. "end_turn", "cancelled").
  /// This is a long-running call that resolves when the agent finishes.
  Future<String> prompt(String sessionId, String text) async {
    final result = await _call('session/prompt', {
      'sessionId': sessionId,
      'prompt': [
        {'type': 'text', 'text': text}
      ],
    });
    return result['stopReason']?.toString() ?? '';
  }

  /// Cancel an active prompt for a session.
  Future<void> cancel(String sessionId) async {
    await _call('session/cancel', {'sessionId': sessionId});
  }

  /// Close a session, freeing server-side resources.
  Future<void> closeSession(String sessionId) async {
    await _call('session/close', {'sessionId': sessionId});
    _sessions.remove(sessionId);
  }

  /// List sessions with pagination. Returns (sessions, nextCursor).
  Future<({List<Map<String, dynamic>> sessions, String? nextCursor})>
      listSessions({String? cwd, String? cursor}) async {
    final Map<String, dynamic> params = {};
    if (cwd != null) params['cwd'] = cwd;
    if (cursor != null) params['cursor'] = cursor;

    final result = await _call('session/list', params);
    final sessionsList = (result['sessions'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    final nextCursor = result['nextCursor']?.toString();
    return (sessions: sessionsList, nextCursor: nextCursor);
  }

  /// Send a JSON-RPC response to a server-initiated permission request.
  Future<void> sendPermissionResponse(
      String requestId, String optionId) async {
    final response = jsonEncode({
      'jsonrpc': '2.0',
      'id': requestId,
      'result': {
        'outcome': {'outcome': 'selected', 'optionId': optionId}
      },
    });
    _stdin?.add(utf8.encode('$response\n'));
    await _stdin?.flush();
  }

  Future<void> close() async {
    _closed = true;
    await _stdoutSub?.cancel();
    try {
      await _stdin?.close();
    } catch (_) {}
    _process?.kill();
    await _events.close();
  }
}

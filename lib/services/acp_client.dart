import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// An event emitted from the ACP stream, mirroring the Go ACPEvent/ChatEvent.
class AcpEvent {
  final String type;
  final String? sessionId;
  final String content;
  final dynamic data;
  final String? error;

  AcpEvent({
    required this.type,
    this.sessionId,
    this.content = '',
    this.data,
    this.error,
  });
}

/// ACPClient communicates with the `vibecoding acp` subprocess via JSON-RPC
/// over stdin/stdout. This is a direct Dart port of the Go implementation.
class AcpClient {
  Process? _process;
  IOSink? _stdin;
  final String vibecodingPath;
  final Map<String, String?> _args;

  int _nextId = 0;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  final Set<String> sessions = {};

  // Broadcast stream of session events (content / tool calls / permissions).
  final StreamController<AcpEvent> _events =
      StreamController<AcpEvent>.broadcast();

  Stream<AcpEvent> get events => _events.stream;

  StreamSubscription<String>? _stdoutSub;
  bool _closed = false;

  AcpClient(this.vibecodingPath, {this._args = const {}});

  /// Starts the subprocess and the stdout reader.
  Future<void> start() async {
    final cmdArgs = <String>['acp'];
    _args.forEach((key, value) {
      if (value != null && value.isNotEmpty) {
        cmdArgs.add('--$key');
        cmdArgs.add(value);
      }
    });

    _process = await Process.start(
      vibecodingPath,
      cmdArgs,
      mode: ProcessStartMode.normal,
    );

    _stdin = _process!.stdin;

    // Forward stderr for debugging.
    _process!.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => stderr.writeln('[VIBECODING] $line'));

    _stdoutSub = _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleLine, onDone: _onDone, onError: (_) {});
  }

  void _onDone() {
    if (!_closed) {
      _events.add(AcpEvent(
        type: 'error',
        error: 'VibeCoding process exited',
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
    if (id is int && msg.containsKey('result') || (id is int && msg.containsKey('error'))) {
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
      case 'content':
        final content = update['content'] as Map<String, dynamic>?;
        _events.add(AcpEvent(
          type: 'content',
          sessionId: sessionId,
          content: content?['text']?.toString() ?? '',
          data: {'type': content?['type']},
        ));
        break;
      case 'tool_call':
        _events.add(AcpEvent(
          type: 'tool_call',
          sessionId: sessionId,
          data: {
            'id': update['toolCallId'],
            'title': update['title'],
            'kind': update['kind'],
            'status': update['status'],
            'input': update['rawInput'],
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
            'id': update['toolCallId'],
            'title': update['title'],
            'status': update['status'],
            'output': rawOutput,
          },
        ));
        break;
      case 'status':
        _events.add(AcpEvent(
          type: 'status',
          sessionId: sessionId,
          data: {'status': update['status']},
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
        'input': toolCall['rawInput'],
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

  Future<Map<String, dynamic>> initialize(
      String clientName, String clientVersion) {
    return _call('initialize', {
      'protocolVersion': 1,
      'clientInfo': {'name': clientName, 'version': clientVersion},
      'clientCapabilities': {
        'session': {'cancel': true}
      },
    });
  }

  Future<String> newSession(String cwd) async {
    final result = await _call('session/new', {'cwd': cwd});
    final sessionId = result['sessionId']?.toString() ?? '';
    if (sessionId.isNotEmpty) sessions.add(sessionId);
    return sessionId;
  }

  Future<void> loadSession(String sessionId, String cwd) async {
    await _call('session/load', {'sessionId': sessionId, 'cwd': cwd});
    sessions.add(sessionId);
  }

  /// Sends a prompt and returns the stopReason.
  Future<String> prompt(String sessionId, String text) async {
    final result = await _call('session/prompt', {
      'sessionId': sessionId,
      'prompt': [
        {'type': 'text', 'text': text}
      ],
    });
    return result['stopReason']?.toString() ?? '';
  }

  Future<void> cancel(String sessionId) async {
    await _call('session/cancel', {'sessionId': sessionId});
  }

  /// Sends a JSON-RPC *response* to a server-initiated permission request.
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

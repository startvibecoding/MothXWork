import 'dart:convert';
import 'dart:io';
import '../models/models.dart';

class SessionManager {
  final String sessionId;
  final String cwd;
  final File file;

  SessionManager({required this.sessionId, required this.cwd})
      : file = File('${Platform.environment['HOME']}/.vibework/sessions/$sessionId.jsonl');

  Future<void> ensureExists() async {
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
  }

  Future<List<ChatMessage>> loadMessages({int? limit}) async {
    if (!await file.exists()) return [];

    final lines = await file.readAsLines();
    final result = <ChatMessage>[];

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        final json = jsonDecode(trimmed) as Map<String, dynamic>;
        if (json['role'] == null) continue;

        final roleStr = json['role'].toString();
        final role = roleStr == 'user' ? MessageRole.user : MessageRole.assistant;

        result.add(ChatMessage(
          id: json['id']?.toString() ?? 'msg-${result.length}',
          role: role,
          content: json['content']?.toString() ?? '',
          timestamp: json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
              : DateTime.now(),
          isStreaming: false,
        ));
      } catch (e) {
        // Skip malformed lines
      }
    }

    if (limit != null && result.length > limit) {
      return result.sublist(result.length - limit);
    }
    return result;
  }

  Future<String> appendMessage(ChatMessage msg) async {
    await ensureExists();
    final data = {
      'id': msg.id,
      'role': msg.role == MessageRole.user ? 'user' : 'assistant',
      'content': msg.content,
      'timestamp': msg.timestamp.toIso8601String(),
    };
    await file.writeAsString('${jsonEncode(data)}\n', mode: FileMode.append, flush: true);
    return msg.id;
  }
}

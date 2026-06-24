library;

/// Data models for VibeCoding GUI (Flutter)

enum MessageRole { user, assistant, system }

class ChatMessage {
  final String id;
  MessageRole role;
  String content;
  final DateTime timestamp;
  bool isStreaming;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
  });
}

class SessionInfo {
  String id;
  String name;
  String cwd;
  String? createdAt;

  SessionInfo({
    required this.id,
    required this.name,
    required this.cwd,
    this.createdAt,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['id'] ?? '').toString(),
      cwd: (json['cwd'] ?? '').toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cwd': cwd,
        if (createdAt != null) 'createdAt': createdAt,
      };
}

/// Runtime session config (matches Go SessionConfig)
class SessionRuntimeConfig {
  String cwd;
  String provider;
  String model;
  String mode;
  String thinking;

  SessionRuntimeConfig({
    this.cwd = '',
    this.provider = '',
    this.model = '',
    this.mode = 'agent',
    this.thinking = 'medium',
  });

  SessionRuntimeConfig copyWith({
    String? cwd,
    String? provider,
    String? model,
    String? mode,
    String? thinking,
  }) {
    return SessionRuntimeConfig(
      cwd: cwd ?? this.cwd,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      mode: mode ?? this.mode,
      thinking: thinking ?? this.thinking,
    );
  }
}

/// A permission option from session/request_permission
class PermissionOption {
  final String optionId;
  final String name;
  final String kind;

  PermissionOption({
    required this.optionId,
    required this.name,
    required this.kind,
  });

  factory PermissionOption.fromJson(Map<String, dynamic> json) {
    return PermissionOption(
      optionId: (json['optionId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      kind: (json['kind'] ?? '').toString(),
    );
  }
}

class PermissionRequest {
  final String requestId;
  final String sessionId;
  final String toolCallId;
  final String title;
  final String kind;
  final dynamic input;
  final List<PermissionOption> options;

  PermissionRequest({
    required this.requestId,
    required this.sessionId,
    required this.toolCallId,
    required this.title,
    required this.kind,
    required this.input,
    required this.options,
  });
}

/// Provider / Model models for settings UI
class ProviderInfo {
  final String id;
  final String name;
  final String api;

  ProviderInfo({required this.id, required this.name, required this.api});
}

class ModelInfo {
  final String id;
  final String name;
  final bool reasoning;
  final int contextWindow;
  final int maxTokens;

  ModelInfo({
    required this.id,
    required this.name,
    this.reasoning = false,
    this.contextWindow = 0,
    this.maxTokens = 0,
  });
}

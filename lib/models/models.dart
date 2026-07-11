library;

/// Data models for Mothx GUI (Flutter)

enum MessageRole { user, assistant, system }

class ToolCallBlock {
  final String id;
  final String name;
  final String arguments;
  final String? invalidArguments;

  ToolCallBlock({
    required this.id,
    required this.name,
    required this.arguments,
    this.invalidArguments,
  });

  factory ToolCallBlock.fromJson(Map<String, dynamic> json) {
    return ToolCallBlock(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      arguments: (json['arguments'] ?? '').toString(),
      invalidArguments: json['invalidArguments']?.toString() ?? json['invalid_arguments']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'arguments': arguments,
      if (invalidArguments != null) 'invalidArguments': invalidArguments,
    };
  }
}

class CacheControl {
  final String type; // e.g. "ephemeral" or ""

  CacheControl({this.type = 'ephemeral'});

  factory CacheControl.fromJson(Map<String, dynamic> json) {
    return CacheControl(
      type: (json['type'] ?? 'ephemeral').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
    };
  }
}

class ImageContent {
  final String mimeType;
  final String data; // base64 encoded data

  ImageContent({required this.mimeType, required this.data});

  factory ImageContent.fromJson(Map<String, dynamic> json) {
    return ImageContent(
      mimeType: (json['mimeType'] ?? json['mime_type'] ?? '').toString(),
      data: (json['data'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mimeType': mimeType,
      'data': data,
    };
  }
}

class ContentBlock {
  final String type; // "text", "thinking", "image", "tool_call", "tool_result", etc.
  final String? text;
  final String? thinking;
  final String? signature;
  final ImageContent? image;
  final ToolCallBlock? toolCall;
  final CacheControl? cacheControl;

  ContentBlock({
    required this.type,
    this.text,
    this.thinking,
    this.signature,
    this.image,
    this.toolCall,
    this.cacheControl,
  });

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    final imgJson = json['image'];
    final tcJson = json['toolCall'] ?? json['tool_call'];
    final ccJson = json['cacheControl'] ?? json['cache_control'];

    return ContentBlock(
      type: (json['type'] ?? '').toString(),
      text: json['text']?.toString(),
      thinking: json['thinking']?.toString(),
      signature: json['signature']?.toString(),
      image: imgJson != null ? ImageContent.fromJson(Map<String, dynamic>.from(imgJson as Map)) : null,
      toolCall: tcJson != null ? ToolCallBlock.fromJson(Map<String, dynamic>.from(tcJson as Map)) : null,
      cacheControl: ccJson != null ? CacheControl.fromJson(Map<String, dynamic>.from(ccJson as Map)) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (text != null) 'text': text,
      if (thinking != null) 'thinking': thinking,
      if (signature != null) 'signature': signature,
      if (image != null) 'image': image!.toJson(),
      if (toolCall != null) 'toolCall': toolCall!.toJson(),
      if (cacheControl != null) 'cacheControl': cacheControl!.toJson(),
    };
  }
}

class Cost {
  final double amount;
  final String currency;

  Cost({this.amount = 0.0, this.currency = 'USD'});

  factory Cost.fromJson(Map<String, dynamic> json) {
    return Cost(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: (json['currency'] ?? 'USD').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
    };
  }
}

class ModelPricing {
  final double promptPrice;
  final double completionPrice;
  final double cachedPrice;

  ModelPricing({
    this.promptPrice = 0.0,
    this.completionPrice = 0.0,
    this.cachedPrice = 0.0,
  });

  factory ModelPricing.fromJson(Map<String, dynamic> json) {
    return ModelPricing(
      promptPrice: (json['promptPrice'] ?? json['prompt_price'] as num?)?.toDouble() ?? 0.0,
      completionPrice: (json['completionPrice'] ?? json['completion_price'] as num?)?.toDouble() ?? 0.0,
      cachedPrice: (json['cachedPrice'] ?? json['cached_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'promptPrice': promptPrice,
      'completionPrice': completionPrice,
      'cachedPrice': cachedPrice,
    };
  }
}

class Usage {
  final int input;
  final int output;
  final int reasoning;
  final int cacheRead;
  final int cacheWrite;
  final int totalTokens;
  final Cost? cost;

  Usage({
    this.input = 0,
    this.output = 0,
    this.reasoning = 0,
    this.cacheRead = 0,
    this.cacheWrite = 0,
    this.totalTokens = 0,
    this.cost,
  });

  factory Usage.fromJson(Map<String, dynamic> json) {
    final costJson = json['cost'];
    return Usage(
      input: (json['input'] as num?)?.toInt() ?? 0,
      output: (json['output'] as num?)?.toInt() ?? 0,
      reasoning: (json['reasoning'] as num?)?.toInt() ?? 0,
      cacheRead: (json['cacheRead'] ?? json['cache_read'] as num?)?.toInt() ?? 0,
      cacheWrite: (json['cacheWrite'] ?? json['cache_write'] as num?)?.toInt() ?? 0,
      totalTokens: (json['totalTokens'] ?? json['total_tokens'] as num?)?.toInt() ?? 0,
      cost: costJson != null ? Cost.fromJson(Map<String, dynamic>.from(costJson as Map)) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'input': input,
      'output': output,
      'reasoning': reasoning,
      'cacheRead': cacheRead,
      'cacheWrite': cacheWrite,
      'totalTokens': totalTokens,
      if (cost != null) 'cost': cost!.toJson(),
    };
  }

  Usage calculateCost(ModelPricing pricing) {
    final double promptCost = (input - cacheRead) * pricing.promptPrice / 1000000.0;
    final double cachedCost = cacheRead * pricing.cachedPrice / 1000000.0;
    final double completionCost = output * pricing.completionPrice / 1000000.0;
    final double totalCostAmount = promptCost + cachedCost + completionCost;

    return Usage(
      input: input,
      output: output,
      reasoning: reasoning,
      cacheRead: cacheRead,
      cacheWrite: cacheWrite,
      totalTokens: totalTokens,
      cost: Cost(amount: totalCostAmount, currency: 'USD'),
    );
  }

  String get cacheInfo {
    if (cacheRead == 0 && cacheWrite == 0) return 'No caching';
    final int totalPrompt = input;
    final double hitRate = totalPrompt > 0 ? (cacheRead / totalPrompt) * 100.0 : 0.0;
    return 'Cache Read: $cacheRead, Cache Write: $cacheWrite (${hitRate.toStringAsFixed(1)}% hit rate)';
  }
}

class ChatMessage {
  final String id;
  MessageRole role;
  String content;
  final DateTime timestamp;
  bool isStreaming;
  List<ContentBlock>? contents;
  Usage? usage;
  List<ToolCallBlock>? toolCalls;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
    this.contents,
    this.usage,
    this.toolCalls,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final contentsList = json['contents'] as List?;
    final usageJson = json['usage'];

    MessageRole r = MessageRole.user;
    final roleStr = (json['role'] ?? 'user').toString().toLowerCase();
    if (roleStr == 'assistant') {
      r = MessageRole.assistant;
    } else if (roleStr == 'system') {
      r = MessageRole.system;
    }

    DateTime ts;
    if (json['timestamp'] != null) {
      ts = DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }

    final parsedContents = contentsList
        ?.map((c) => ContentBlock.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList();

    String contentText = (json['content'] ?? '').toString();
    if (contentText.isEmpty && parsedContents != null) {
      contentText = parsedContents
          .where((block) => block.type == 'text' || block.type == 'thinking')
          .map((block) => block.text ?? block.thinking ?? '')
          .join('\n');
    }

    final tcList = json['toolCalls'] ?? json['tool_calls'];
    final parsedToolCalls = tcList is List
        ? tcList.map((tc) => ToolCallBlock.fromJson(Map<String, dynamic>.from(tc as Map))).toList()
        : null;

    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      role: r,
      content: contentText,
      timestamp: ts,
      isStreaming: json['isStreaming'] == true || json['is_streaming'] == true,
      contents: parsedContents,
      usage: usageJson != null ? Usage.fromJson(Map<String, dynamic>.from(usageJson as Map)) : null,
      toolCalls: parsedToolCalls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isStreaming': isStreaming,
      if (contents != null) 'contents': contents!.map((c) => c.toJson()).toList(),
      if (usage != null) 'usage': usage!.toJson(),
      if (toolCalls != null) 'toolCalls': toolCalls!.map((tc) => tc.toJson()).toList(),
    };
  }
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

// ---------------------------------------------------------------------------
// Provider abstraction (used by ProviderRegistry / ProviderFactory)
// ---------------------------------------------------------------------------

/// Token usage information from a streaming LLM response.
class LLMUsage {
  final int promptTokens;
  final int completionTokens;
  final int cachedPromptTokens;
  final int totalTokens;

  LLMUsage({
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.cachedPromptTokens = 0,
    this.totalTokens = 0,
  });
}

/// A single tool-call delta from a streaming response.
class StreamToolCallDelta {
  final int index;
  final String? id;
  final String? name;
  final String? arguments;

  StreamToolCallDelta({
    this.index = 0,
    this.id,
    this.name,
    this.arguments,
  });
}

/// Stub type for cron job info.
class CronJobInfo {
  final String id;
  final String name;
  final String schedule;
  final String? command;
  final bool enabled;
  final String? sessionId;
  final String? mode;
  final int runCount;
  final String? lastError;
  final String? nextRun;
  final String? prompt;

  CronJobInfo({
    required this.id,
    this.name = '',
    this.schedule = '',
    this.command,
    this.enabled = true,
    this.sessionId,
    this.mode,
    this.runCount = 0,
    this.lastError,
    this.nextRun,
    this.prompt,
  });

  factory CronJobInfo.fromJson(Map<String, dynamic> json) {
    return CronJobInfo(
      id: (json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      schedule: (json['schedule'] ?? '').toString(),
      command: json['command']?.toString(),
      enabled: json['enabled'] != false,
      sessionId: json['sessionId']?.toString(),
      mode: json['mode']?.toString(),
      runCount: (json['runCount'] as num?)?.toInt() ?? 0,
      lastError: json['lastError']?.toString(),
      nextRun: json['nextRun']?.toString(),
      prompt: json['prompt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'schedule': schedule,
        if (command != null) 'command': command,
        'enabled': enabled,
        if (sessionId != null) 'sessionId': sessionId,
        if (mode != null) 'mode': mode,
        'runCount': runCount,
        if (lastError != null) 'lastError': lastError,
        if (nextRun != null) 'nextRun': nextRun,
        if (prompt != null) 'prompt': prompt,
      };
}

/// Stub container for cron state.
class CronInfo {
  final bool enabled;
  final bool running;
  final List<CronJobInfo> jobs;

  CronInfo({this.enabled = true, this.running = false, this.jobs = const []});

  factory CronInfo.fromJson(Map<String, dynamic> json) {
    final jobsList = json['jobs'] as List?;
    return CronInfo(
      enabled: json['enabled'] != false,
      running: json['running'] == true,
      jobs: jobsList != null
          ? jobsList.map((j) => CronJobInfo.fromJson(j as Map<String, dynamic>)).toList()
          : [],
    );
  }
}

/// Stats summary from the backend.
class StatsSummary {
  final int totalRequests;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;
  final double? totalCost;
  final List<ProviderStat>? byProvider;
  final List<ModelStat>? byModel;
  final List<RecentEntry>? recent;

  StatsSummary({
    this.totalRequests = 0,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.totalTokens = 0,
    this.totalCost,
    this.byProvider,
    this.byModel,
    this.recent,
  });

  factory StatsSummary.fromJson(Map<String, dynamic> json) {
    final bp = json['byProvider'] as List?;
    final bm = json['byModel'] as List?;
    final rr = json['recent'] as List?;
    return StatsSummary(
      totalRequests: (json['totalRequests'] as num?)?.toInt() ?? 0,
      inputTokens: (json['inputTokens'] as num?)?.toInt() ?? 0,
      outputTokens: (json['outputTokens'] as num?)?.toInt() ?? 0,
      totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
      totalCost: (json['totalCost'] as num?)?.toDouble(),
      byProvider: bp?.map((p) => ProviderStat.fromJson(Map<String, dynamic>.from(p as Map))).toList(),
      byModel: bm?.map((m) => ModelStat.fromJson(Map<String, dynamic>.from(m as Map))).toList(),
      recent: rr?.map((r) => RecentEntry.fromJson(Map<String, dynamic>.from(r as Map))).toList(),
    );
  }
}

class ProviderStat {
  final String provider;
  final int requests;
  final int tokens;
  final double? cost;

  ProviderStat({this.provider = '', this.requests = 0, this.tokens = 0, this.cost});

  factory ProviderStat.fromJson(Map<String, dynamic> json) {
    return ProviderStat(
      provider: (json['provider'] ?? '').toString(),
      requests: (json['requests'] as num?)?.toInt() ?? 0,
      tokens: (json['tokens'] as num?)?.toInt() ?? 0,
      cost: (json['cost'] as num?)?.toDouble(),
    );
  }
}

class ModelStat {
  final String model;
  final int requests;
  final int tokens;
  final double? cost;

  ModelStat({this.model = '', this.requests = 0, this.tokens = 0, this.cost});

  factory ModelStat.fromJson(Map<String, dynamic> json) {
    return ModelStat(
      model: (json['model'] ?? '').toString(),
      requests: (json['requests'] as num?)?.toInt() ?? 0,
      tokens: (json['tokens'] as num?)?.toInt() ?? 0,
      cost: (json['cost'] as num?)?.toDouble(),
    );
  }
}

class RecentEntry {
  final String sessionId;
  final String model;
  final String? vendor;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;
  final int durationMs;
  final String timestamp;

  RecentEntry({
    this.sessionId = '',
    this.model = '',
    this.vendor,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.totalTokens = 0,
    this.durationMs = 0,
    this.timestamp = '',
  });

  factory RecentEntry.fromJson(Map<String, dynamic> json) {
    return RecentEntry(
      sessionId: (json['sessionId'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
      vendor: json['vendor']?.toString(),
      inputTokens: (json['inputTokens'] as num?)?.toInt() ?? 0,
      outputTokens: (json['outputTokens'] as num?)?.toInt() ?? 0,
      totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      timestamp: (json['timestamp'] ?? '').toString(),
    );
  }
}

/// Stub type for a log entry.
class LogEntry {
  final DateTime timestamp;
  final String level;
  final String type;
  final String message;
  final String? source;

  LogEntry({
    required this.timestamp,
    required this.level,
    this.type = 'log',
    required this.message,
    this.source,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      level: (json['level'] ?? 'info').toString(),
      type: (json['type'] ?? 'log').toString(),
      message: (json['message'] ?? '').toString(),
      source: json['source']?.toString(),
    );
  }
}

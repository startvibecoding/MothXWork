

class ModelConfig {
  final String id;
  final String name;
  final bool reasoning;
  final int contextWindow;
  final int maxTokens;
  final double? temperature;
  final double? topP;
  final List<String> input;

  ModelConfig({
    required this.id,
    required this.name,
    this.reasoning = false,
    this.contextWindow = 128000,
    this.maxTokens = 4096,
    this.temperature,
    this.topP,
    this.input = const ['text'],
  });

  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    return ModelConfig(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['id'] ?? '').toString(),
      reasoning: json['reasoning'] == true,
      contextWindow: (json['contextWindow'] as num?)?.toInt() ?? 128000,
      maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 4096,
      temperature: (json['temperature'] as num?)?.toDouble(),
      topP: (json['top_p'] as num?)?.toDouble(),
      input: List<String>.from(json['input'] ?? ['text']),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'name': name,
      'reasoning': reasoning,
      'contextWindow': contextWindow,
      'maxTokens': maxTokens,
    };
    if (temperature != null) data['temperature'] = temperature;
    if (topP != null) data['top_p'] = topP;
    data['input'] = input;
    return data;
  }
}

class ProviderConfig {
  final String vendor;
  final String apiKey;
  final String baseUrl;
  final String httpProxy;
  final String api;
  final String thinkingFormat;
  final bool cacheControl;
  final List<ModelConfig> models;

  ProviderConfig({
    required this.vendor,
    required this.apiKey,
    required this.baseUrl,
    required this.httpProxy,
    required this.api,
    required this.thinkingFormat,
    this.cacheControl = false,
    this.models = const [],
  });

  factory ProviderConfig.fromJson(Map<String, dynamic> json) {
    final mList = (json['models'] as List?) ?? [];
    return ProviderConfig(
      vendor: (json['vendor'] ?? '').toString(),
      apiKey: (json['apiKey'] ?? '').toString(),
      baseUrl: (json['baseUrl'] ?? '').toString(),
      httpProxy: (json['httpProxy'] ?? '').toString(),
      api: (json['api'] ?? 'openai-chat').toString(),
      thinkingFormat: (json['thinkingFormat'] ?? '').toString(),
      cacheControl: json['cacheControl'] == true,
      models: mList.map((m) => ModelConfig.fromJson(Map<String, dynamic>.from(m as Map))).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor': vendor,
      'apiKey': apiKey,
      'baseUrl': baseUrl,
      'httpProxy': httpProxy,
      'api': api,
      'thinkingFormat': thinkingFormat,
      'cacheControl': cacheControl,
      'models': models.map((m) => m.toJson()).toList(),
    };
  }
}

class SandboxSettings {
  final bool enabled;
  final String level;
  final String bwrapPath;
  final bool allowNetwork;
  final List<String> allowedRead;
  final List<String> allowedWrite;
  final List<String> deniedPaths;
  final List<String> passEnv;
  final String tmpSize;

  SandboxSettings({
    this.enabled = false,
    this.level = 'none',
    this.bwrapPath = '',
    this.allowNetwork = true,
    this.allowedRead = const [],
    this.allowedWrite = const [],
    this.deniedPaths = const [],
    this.passEnv = const [],
    this.tmpSize = '128M',
  });

  factory SandboxSettings.fromJson(Map<String, dynamic> json) {
    return SandboxSettings(
      enabled: json['enabled'] == true,
      level: (json['level'] ?? 'none').toString(),
      bwrapPath: (json['bwrapPath'] ?? '').toString(),
      allowNetwork: json['allowNetwork'] != false,
      allowedRead: List<String>.from(json['allowedRead'] ?? []),
      allowedWrite: List<String>.from(json['allowedWrite'] ?? []),
      deniedPaths: List<String>.from(json['deniedPaths'] ?? []),
      passEnv: List<String>.from(json['passEnv'] ?? []),
      tmpSize: (json['tmpSize'] ?? '128M').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'level': level,
      'bwrapPath': bwrapPath,
      'allowNetwork': allowNetwork,
      'allowedRead': allowedRead,
      'allowedWrite': allowedWrite,
      'deniedPaths': deniedPaths,
      'passEnv': passEnv,
      'tmpSize': tmpSize,
    };
  }
}

class ApprovalSettings {
  final List<String> bashWhitelist;
  final List<String> bashBlacklist;
  final bool confirmBeforeWrite;

  ApprovalSettings({
    this.bashWhitelist = const [],
    this.bashBlacklist = const [],
    this.confirmBeforeWrite = false,
  });

  factory ApprovalSettings.fromJson(Map<String, dynamic> json) {
    return ApprovalSettings(
      bashWhitelist: List<String>.from(json['bashWhitelist'] ?? []),
      bashBlacklist: List<String>.from(json['bashBlacklist'] ?? []),
      confirmBeforeWrite: json['confirmBeforeWrite'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bashWhitelist': bashWhitelist,
      'bashBlacklist': bashBlacklist,
      'confirmBeforeWrite': confirmBeforeWrite,
    };
  }
}

class Settings {
  final Map<String, ProviderConfig> providers;
  final String defaultProvider;
  final String defaultModel;
  final String defaultThinkingLevel;
  final String defaultMode;
  final bool enablePlanTool;
  final int maxContextTokens;
  final int maxOutputTokens;
  final String skillsDir;
  final String shellPath;
  final String shellCommandPrefix;
  final String theme;
  final SandboxSettings sandbox;
  final ApprovalSettings approval;
  final bool updateCheck;

  Settings({
    required this.providers,
    required this.defaultProvider,
    required this.defaultModel,
    required this.defaultThinkingLevel,
    required this.defaultMode,
    this.enablePlanTool = true,
    this.maxContextTokens = 1000000,
    this.maxOutputTokens = 384000,
    this.skillsDir = '',
    this.shellPath = '',
    this.shellCommandPrefix = '',
    this.theme = 'dark',
    required this.sandbox,
    required this.approval,
    this.updateCheck = true,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    final provMap = <String, ProviderConfig>{};
    if (json['providers'] is Map) {
      (json['providers'] as Map).forEach((k, v) {
        provMap[k.toString()] = ProviderConfig.fromJson(Map<String, dynamic>.from(v as Map));
      });
    }
    return Settings(
      providers: provMap,
      defaultProvider: (json['defaultProvider'] ?? '').toString(),
      defaultModel: (json['defaultModel'] ?? '').toString(),
      defaultThinkingLevel: (json['defaultThinkingLevel'] ?? 'medium').toString(),
      defaultMode: (json['defaultMode'] ?? 'agent').toString(),
      enablePlanTool: json['enablePlanTool'] != false,
      maxContextTokens: (json['maxContextTokens'] as num?)?.toInt() ?? 1000000,
      maxOutputTokens: (json['maxOutputTokens'] as num?)?.toInt() ?? 384000,
      skillsDir: (json['skillsDir'] ?? '').toString(),
      shellPath: (json['shellPath'] ?? '').toString(),
      shellCommandPrefix: (json['shellCommandPrefix'] ?? '').toString(),
      theme: (json['theme'] ?? 'dark').toString(),
      sandbox: SandboxSettings.fromJson(Map<String, dynamic>.from((json['sandbox'] ?? {}) as Map)),
      approval: ApprovalSettings.fromJson(Map<String, dynamic>.from((json['approval'] ?? {}) as Map)),
      updateCheck: json['updateCheck'] != false,
    );
  }
}

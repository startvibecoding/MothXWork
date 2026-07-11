import 'dart:convert';
import 'dart:io';

import '../models/models.dart';

/// Locates the mothx binary, mirroring findMothxBinary() in Go.
class MothxLocator {
  static String? find() {
    final candidates = <String>[];

    // Next to the executable (bundled).
    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      candidates.add('$exeDir/mothx');
    } catch (_) {}

    final home = Platform.environment['HOME'] ?? '';
    candidates.addAll([
      'mothx',
      '/usr/local/bin/mothx',
      '$home/.local/bin/mothx',
      '$home/go/bin/mothx',
    ]);

    // Walk up from cwd.
    var dir = Directory.current.path;
    while (dir != '/' && dir.isNotEmpty) {
      candidates.add('$dir/mothx/build/bin/mothx');
      candidates.add('$dir/mothx/mothx');
      final parent = File(dir).parent.path;
      if (parent == dir) break;
      dir = parent;
    }

    for (final c in candidates) {
      if (c.contains('/') && File(c).existsSync()) return c;
    }

    // PATH lookup.
    final pathEnv = Platform.environment['PATH'] ?? '';
    for (final p in pathEnv.split(':')) {
      final f = File('$p/mothx');
      if (f.existsSync()) return f.path;
    }
    return null;
  }
}

/// Reads/writes config files used by the app.
class ConfigService {
  String get _home => Platform.environment['HOME'] ?? '';

  String get _guiDir => '$_home/.mothx-gui';
  String get _settingsPath => '$_guiDir/settings.json';
  String get _sessionsPath => '$_guiDir/sessions.json';
  String get _uiPath => '$_guiDir/ui.json';

  Future<void> _ensureGuiDir() async {
    final dir = Directory(_guiDir);
    if (!await dir.exists()) await dir.create(recursive: true);
  }

  // ---- Mothx settings (~/.mothx/settings.json) ----
  Future<Map<String, dynamic>> loadSettings() async {
    final f = File(_settingsPath);
    if (!await f.exists()) return _defaultSettings();
    try {
      return jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return _defaultSettings();
    }
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _ensureGuiDir();
    final encoder = const JsonEncoder.withIndent('  ');
    await File(_settingsPath).writeAsString(encoder.convert(settings));
  }

  // ---- Sessions metadata (~/.mothx-gui/sessions.json) ----
  Future<List<SessionInfo>> loadSessions() async {
    final f = File(_sessionsPath);
    if (!await f.exists()) return [];
    try {
      final raw = jsonDecode(await f.readAsString()) as List<dynamic>;
      return raw
          .map((e) => SessionInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSessions(List<SessionInfo> sessions) async {
    await _ensureGuiDir();
    final encoder = const JsonEncoder.withIndent('  ');
    await File(_sessionsPath)
        .writeAsString(encoder.convert(sessions.map((s) => s.toJson()).toList()));
  }

  // ---- UI config (~/.mothx-gui/ui.json) ----
  Future<Map<String, dynamic>> loadUiConfig() async {
    final f = File(_uiPath);
    if (!await f.exists()) return {'theme': 'dark'};
    try {
      return jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return {'theme': 'dark'};
    }
  }

  Future<void> saveUiConfig(Map<String, dynamic> config) async {
    await _ensureGuiDir();
    final encoder = const JsonEncoder.withIndent('  ');
    await File(_uiPath).writeAsString(encoder.convert(config));
  }

  // ---- Helpers to derive providers/models from settings ----
  List<ProviderInfo> providersFrom(Map<String, dynamic> settings) {
    final providers = settings['providers'];
    if (providers is! Map) return [];
    final result = <ProviderInfo>[];
    providers.forEach((id, value) {
      final api = (value is Map ? value['api'] : null)?.toString() ?? '';
      result.add(ProviderInfo(id: id.toString(), name: id.toString(), api: api));
    });
    result.sort((a, b) => a.id.compareTo(b.id));
    return result;
  }

  List<ModelInfo> modelsFrom(Map<String, dynamic> settings, String providerId) {
    final providers = settings['providers'];
    if (providers is! Map) return [];
    final p = providers[providerId];
    if (p is! Map) return [];
    final models = p['models'];
    if (models is! List) return [];
    return models.map((m) {
      final mm = m as Map<String, dynamic>;
      return ModelInfo(
        id: (mm['id'] ?? '').toString(),
        name: (mm['name'] ?? mm['id'] ?? '').toString(),
        reasoning: mm['reasoning'] == true,
        contextWindow: (mm['contextWindow'] is num)
            ? (mm['contextWindow'] as num).toInt()
            : 0,
        maxTokens:
            (mm['maxTokens'] is num) ? (mm['maxTokens'] as num).toInt() : 0,
      );
    }).toList();
  }

  Map<String, dynamic> _defaultSettings() => {
        'providers': {
          'deepseek-openai': {
            'baseUrl': 'https://api.deepseek.com',
            'apiKey': '\${DEEPSEEK_API_KEY}',
            'api': 'openai-chat',
            'models': [
              {
                'id': 'deepseek-v4-flash',
                'name': 'DeepSeek-V4-Flash',
                'contextWindow': 1000000,
                'maxTokens': 384000,
              },
              {
                'id': 'deepseek-v4-pro',
                'name': 'DeepSeek-V4-Pro',
                'reasoning': true,
                'contextWindow': 1000000,
                'maxTokens': 384000,
              },
            ],
          },
        },
        'defaultProvider': 'deepseek-openai',
        'defaultModel': 'deepseek-v4-flash',
        'defaultThinkingLevel': 'medium',
        'defaultMode': 'agent',
        'theme': 'dark',
      };
}

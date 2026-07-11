import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme/app_theme.dart';

class GlobalSettingsDialog extends StatefulWidget {
  const GlobalSettingsDialog({super.key});

  @override
  State<GlobalSettingsDialog> createState() => _GlobalSettingsDialogState();
}

class _GlobalSettingsDialogState extends State<GlobalSettingsDialog> {
  int _selectedTab = 0;
  late Map<String, dynamic> _settingsCopy;
  bool _loading = true;

  static const _tabs = [
    {'icon': Icons.cloud_outlined, 'label': 'Providers'},
    {'icon': Icons.tune, 'label': 'General'},
    {'icon': Icons.shield_outlined, 'label': 'Approval'},
    {'icon': Icons.storage_outlined, 'label': 'Sandbox'},
    {'icon': Icons.dns_outlined, 'label': 'Serve'},
  ];

  @override
  void initState() {
    super.initState();
    // Deep copy settings
    final app = context.read<AppState>();
    _settingsCopy = jsonDecode(jsonEncode(app.settings));
    _loading = false;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    if (_loading) return const SizedBox();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 950, maxHeight: 720),
        child: Container(
          decoration: BoxDecoration(
            color: c.primary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.separator),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.separator)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.settings, color: c.textPrimary, size: 20),
                    const SizedBox(width: 10),
                    Text('全局设置',
                        style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: c.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    // Sidebar tabs
                    Container(
                      width: 180,
                      decoration: BoxDecoration(
                        border: Border(
                            right: BorderSide(color: c.separator)),
                      ),
                      child: Column(
                        children: _tabs.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final tab = entry.value;
                          final selected = _selectedTab == idx;
                          return Material(
                            color: selected
                                ? c.accent.withValues(alpha: 0.15)
                                : Colors.transparent,
                            child: InkWell(
                              onTap: () => setState(() => _selectedTab = idx),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Icon(tab['icon'] as IconData,
                                        size: 18,
                                        color: selected
                                            ? c.accent
                                            : c.textSecondary),
                                    const SizedBox(width: 10),
                                    Text(tab['label'] as String,
                                        style: TextStyle(
                                            color: selected
                                                ? c.accent
                                                : c.textSecondary,
                                            fontSize: 14)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _buildTabContent(c),
                      ),
                    ),
                  ],
                ),
              ),
              // Footer
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.separator)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel',
                          style: TextStyle(color: c.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _save,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(AppColors c) {
    switch (_selectedTab) {
      case 0:
        return _ProvidersTab(
          settings: _settingsCopy,
          c: c,
          onChanged: () => setState(() {}),
        );
      case 1:
        return _GeneralTab(
          settings: _settingsCopy,
          c: c,
          onThemeChanged: (v) {
            context.read<AppState>().setTheme(v);
            setState(() {});
          },
          onChanged: () => setState(() {}),
        );
      case 2:
        return _ApprovalTab(
          settings: _settingsCopy,
          c: c,
          onChanged: () => setState(() {}),
        );
      case 3:
        return _SandboxTab(
          settings: _settingsCopy,
          c: c,
          onChanged: () => setState(() {}),
        );
      case 4:
        return _ServeTab(
          c: c,
          onChanged: () => setState(() {}),
        );
      default:
        return const SizedBox();
    }
  }

  void _save() {
    context.read<AppState>().saveSettings(_settingsCopy);
    Navigator.pop(context);
  }
}

// ===========================================================================
// Providers Tab
// ===========================================================================
class _ProvidersTab extends StatelessWidget {
  final Map<String, dynamic> settings;
  final AppColors c;
  final VoidCallback onChanged;

  const _ProvidersTab({
    required this.settings,
    required this.c,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final providers = settings['providers'] as Map<String, dynamic>? ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Providers',
                style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: c.accent, size: 20),
              tooltip: 'Add Provider',
              onPressed: () => _editProvider(context, null),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: providers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final id = providers.keys.elementAt(index);
              final p = providers[id] as Map<String, dynamic>;
              final modelCount = (p['models'] as List?)?.length ?? 0;
              final apiKey = (p['apiKey'] ?? '').toString();
              final masked = apiKey.length > 10
                  ? '${apiKey.substring(0, 6)}...${apiKey.substring(apiKey.length - 4)}'
                  : apiKey;

              return Material(
                color: c.secondary,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _editProvider(context, id),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: c.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text((p['api'] ?? '').toString(),
                                  style: TextStyle(
                                      color: c.accent, fontSize: 11)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(id,
                                  style: TextStyle(
                                      color: c.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                            ),
                            Text('$modelCount models',
                                style: TextStyle(
                                    color: c.textTertiary, fontSize: 12)),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  color: c.accentRed, size: 18),
                              onPressed: () {
                                providers.remove(id);
                                onChanged();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('API Key: $masked',
                            style: TextStyle(
                                color: c.textTertiary, fontSize: 12)),
                        Text('Base URL: ${p['baseUrl'] ?? ''}',
                            style: TextStyle(
                                color: c.textTertiary, fontSize: 12)),
                        if (p['vendor'] != null && p['vendor'].toString().isNotEmpty)
                          Text('Vendor: ${p['vendor']}',
                              style: TextStyle(
                                  color: c.textTertiary, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _editProvider(BuildContext context, String? id) {
    final isNew = id == null;
    final providerMap = settings['providers'] as Map<String, dynamic>;
    Map<String, dynamic> p;
    if (isNew) {
      p = {
        'vendor': '',
        'apiKey': '',
        'baseUrl': '',
        'httpProxy': '',
        'api': 'openai-chat',
        'thinkingFormat': '',
        'cacheControl': false,
        'models': <Map<String, dynamic>>[],
      };
    } else {
      p = Map<String, dynamic>.from(providerMap[id] as Map);
    }

    final idCtrl = TextEditingController(text: id ?? '');
    final vendorCtrl = TextEditingController(text: (p['vendor'] ?? '').toString());
    final keyCtrl = TextEditingController(text: (p['apiKey'] ?? '').toString());
    final urlCtrl = TextEditingController(text: (p['baseUrl'] ?? '').toString());
    final proxyCtrl = TextEditingController(text: (p['httpProxy'] ?? '').toString());
    final apiCtrl = TextEditingController(text: (p['api'] ?? 'openai-chat').toString());
    final formatCtrl = TextEditingController(text: (p['thinkingFormat'] ?? '').toString());
    
    bool cacheControlVal = p['cacheControl'] == true;
    String apiVal = apiCtrl.text;
    String formatVal = formatCtrl.text;

    // Load models as a stateful Dart List of Maps
    final modelsList = List<Map<String, dynamic>>.from(
      (p['models'] as List?)?.map((item) => Map<String, dynamic>.from(item as Map)) ?? []
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: c.secondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(isNew ? 'Add Provider' : 'Edit $id',
              style: TextStyle(color: c.textPrimary)),
          content: SizedBox(
            width: 580,
            height: 620,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isNew)
                    _settingField(c, 'Provider ID (e.g. my-openai)', idCtrl, 'my-openai'),
                  _settingField(c, 'Vendor Adapter (e.g. openai, anthropic, deepseek)', vendorCtrl, 'openai'),
                  _settingField(c, 'API Key', keyCtrl, '\${MY_API_KEY}'),
                  _settingField(c, 'Base URL', urlCtrl, 'https://api.openai.com/v1'),
                  _settingField(c, 'HTTP Proxy (Optional)', proxyCtrl, 'http://127.0.0.1:7890'),
                  _settingDropdown(c, 'API Type (api)', apiVal, ['openai-chat', 'anthropic-messages'], (v) {
                    setStateDialog(() {
                      apiVal = v;
                      apiCtrl.text = v;
                    });
                  }),
                  _settingDropdown(c, 'Thinking Format (thinkingFormat)', formatVal, ['', 'openai', 'anthropic', 'deepseek', 'xiaomi'], (v) {
                    setStateDialog(() {
                      formatVal = v;
                      formatCtrl.text = v;
                    });
                  }),
                  Row(
                    children: [
                      Checkbox(
                        value: cacheControlVal,
                        activeColor: c.accent,
                        onChanged: (v) {
                          setStateDialog(() {
                            cacheControlVal = v ?? false;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Text('Enable Prompt Cache (cacheControl)', style: TextStyle(color: c.textPrimary, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text('Models (CRUD Management)',
                            style: TextStyle(color: c.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            final newModel = <String, dynamic>{
                              'id': '',
                              'name': '',
                              'input': ['text'],
                            };
                            _editModelForm(context, newModel, () {
                              setStateDialog(() {
                                modelsList.add(newModel);
                              });
                            });
                          },
                          icon: Icon(Icons.add, size: 14, color: c.accent),
                          label: Text('Add Model', style: TextStyle(color: c.accent, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: c.primary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c.separator),
                    ),
                    child: modelsList.isEmpty
                        ? Center(
                            child: Text('No models configured for this provider.',
                                style: TextStyle(color: c.textTertiary, fontSize: 13)),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: modelsList.length,
                            separatorBuilder: (context, idx) => Divider(color: c.separator, height: 1),
                            itemBuilder: (context, idx) {
                              final m = modelsList[idx];
                              final mId = m['id'] ?? '';
                              final mName = m['name'] ?? mId;
                              
                              final infoParts = <String>[];
                              if (m['reasoning'] == true) infoParts.add('Reasoning');
                              if (m['contextWindow'] != null) {
                                final cw = m['contextWindow'];
                                infoParts.add('Ctx: ${cw >= 1000000 ? "${(cw/1000000).toStringAsFixed(1)}M" : "${(cw/1000).toStringAsFixed(0)}K"}');
                              }
                              if (m['temperature'] != null) infoParts.add('Temp: ${m['temperature']}');
                              if (m['input'] is List) {
                                infoParts.add('Inputs: ${(m['input'] as List).join(',')}');
                              }
                              
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.psychology_outlined, color: c.accent, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(mName, style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                                          if (mName != mId && mId.toString().isNotEmpty)
                                            Text(mId, style: TextStyle(color: c.textTertiary, fontSize: 10, fontFamily: 'monospace')),
                                          const SizedBox(height: 2),
                                          Text(infoParts.join(' | '), style: TextStyle(color: c.textSecondary, fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit, color: c.textSecondary, size: 16),
                                      tooltip: 'Edit Model',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        _editModelForm(context, modelsList[idx], () {
                                          setStateDialog(() {});
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline, color: c.accentRed, size: 16),
                                      tooltip: 'Delete Model',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        setStateDialog(() {
                                          modelsList.removeAt(idx);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: c.accent, foregroundColor: Colors.white),
              onPressed: () {
                final newId = idCtrl.text.trim();
                if (newId.isEmpty) return;
                p['vendor'] = vendorCtrl.text.trim();
                p['apiKey'] = keyCtrl.text.trim();
                p['baseUrl'] = urlCtrl.text.trim();
                p['httpProxy'] = proxyCtrl.text.trim();
                p['api'] = apiCtrl.text.trim();
                p['thinkingFormat'] = formatCtrl.text.trim();
                p['cacheControl'] = cacheControlVal;
                p['models'] = modelsList;

                if (!isNew && id != newId) providerMap.remove(id);
                providerMap[newId] = p;
                Navigator.pop(dialogCtx);
                onChanged();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingField(
      AppColors c, String label, TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        style: TextStyle(color: c.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
          hintText: hint,
          hintStyle: TextStyle(color: c.textTertiary, fontSize: 13),
          filled: true,
          fillColor: c.primary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: c.separator),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: c.separator),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: c.accent),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _settingDropdown(AppColors c, String label, String currentVal, List<String> items, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: c.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.separator),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: items.contains(currentVal) ? currentVal : items.first,
                dropdownColor: c.secondary,
                isExpanded: true,
                style: TextStyle(color: c.textPrimary, fontSize: 13),
                icon: Icon(Icons.keyboard_arrow_down, color: c.textSecondary),
                items: items.map((v) => DropdownMenuItem(value: v, child: Text(v == '' ? 'None (default)' : v))).toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editModelForm(BuildContext context, Map<String, dynamic> model, VoidCallback onSaved) {
    final idCtrl = TextEditingController(text: (model['id'] ?? '').toString());
    final nameCtrl = TextEditingController(text: (model['name'] ?? '').toString());
    final contextCtrl = TextEditingController(text: (model['contextWindow'] ?? '').toString());
    final maxTokensCtrl = TextEditingController(text: (model['maxTokens'] ?? '').toString());
    final tempCtrl = TextEditingController(text: (model['temperature'] ?? '').toString());
    final topPCtrl = TextEditingController(text: (model['top_p'] ?? '').toString());
    
    bool reasoningVal = model['reasoning'] == true;
    
    final inputList = List<String>.from(model['input'] ?? ['text']);
    bool hasText = inputList.contains('text');
    bool hasImage = inputList.contains('image');
    bool hasAudio = inputList.contains('audio');
    bool hasVideo = inputList.contains('video');

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setStateModel) => AlertDialog(
          backgroundColor: c.secondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(model['id'] == null || model['id'].toString().isEmpty ? 'Add Model' : 'Configure ${model['id']}',
              style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _settingField(c, 'Model ID', idCtrl, 'e.g. gpt-4o'),
                  _settingField(c, 'Display Name', nameCtrl, 'e.g. GPT-4o'),
                  Row(
                    children: [
                      Checkbox(
                        value: reasoningVal,
                        activeColor: c.accent,
                        onChanged: (v) {
                          setStateModel(() {
                            reasoningVal = v ?? false;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Text('Reasoning / Thinking Model (reasoning)', style: TextStyle(color: c.textPrimary, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _settingField(c, 'Context Window', contextCtrl, 'e.g. 128000')),
                      const SizedBox(width: 12),
                      Expanded(child: _settingField(c, 'Max Output Tokens', maxTokensCtrl, 'e.g. 4096')),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _settingField(c, 'Temperature (0.0 - 2.0)', tempCtrl, 'e.g. 0.7')),
                      const SizedBox(width: 12),
                      Expanded(child: _settingField(c, 'Top P (0.0 - 1.0)', topPCtrl, 'e.g. 0.9')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Input Modalities', style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _modalityCheckbox('Text', hasText, (v) => setStateModel(() => hasText = v)),
                      _modalityCheckbox('Image', hasImage, (v) => setStateModel(() => hasImage = v)),
                      _modalityCheckbox('Audio', hasAudio, (v) => setStateModel(() => hasAudio = v)),
                      _modalityCheckbox('Video', hasVideo, (v) => setStateModel(() => hasVideo = v)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: c.accent, foregroundColor: Colors.white),
              onPressed: () {
                final newId = idCtrl.text.trim();
                if (newId.isEmpty) return;
                model['id'] = newId;
                model['name'] = nameCtrl.text.trim().isEmpty ? newId : nameCtrl.text.trim();
                model['reasoning'] = reasoningVal;
                
                final ctxVal = int.tryParse(contextCtrl.text.trim());
                if (ctxVal != null) {
                  model['contextWindow'] = ctxVal;
                } else {
                  model.remove('contextWindow');
                }
                
                final maxTokVal = int.tryParse(maxTokensCtrl.text.trim());
                if (maxTokVal != null) {
                  model['maxTokens'] = maxTokVal;
                } else {
                  model.remove('maxTokens');
                }
                
                final tempVal = double.tryParse(tempCtrl.text.trim());
                if (tempVal != null) {
                  model['temperature'] = tempVal;
                } else {
                  model.remove('temperature');
                }
                
                final topPVal = double.tryParse(topPCtrl.text.trim());
                if (topPVal != null) {
                  model['top_p'] = topPVal;
                } else {
                  model.remove('top_p');
                }
                
                final selectedInputs = <String>[];
                if (hasText) selectedInputs.add('text');
                if (hasImage) selectedInputs.add('image');
                if (hasAudio) selectedInputs.add('audio');
                if (hasVideo) selectedInputs.add('video');
                model['input'] = selectedInputs;

                onSaved();
                Navigator.pop(dialogCtx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modalityCheckbox(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          activeColor: c.accent,
          onChanged: (v) => onChanged(v ?? false),
        ),
        Text(label, style: TextStyle(color: c.textPrimary, fontSize: 12)),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ===========================================================================
// General Tab
// ===========================================================================
class _GeneralTab extends StatefulWidget {
  final Map<String, dynamic> settings;
  final AppColors c;
  final ValueChanged<String> onThemeChanged;
  final VoidCallback onChanged;

  const _GeneralTab({
    required this.settings,
    required this.c,
    required this.onThemeChanged,
    required this.onChanged,
  });

  @override
  State<_GeneralTab> createState() => _GeneralTabState();
}

class _GeneralTabState extends State<_GeneralTab> {
  late TextEditingController _contextTokensCtrl;
  late TextEditingController _outputTokensCtrl;
  late TextEditingController _skillsDirCtrl;
  late TextEditingController _shellPathCtrl;
  late TextEditingController _shellPrefixCtrl;

  @override
  void initState() {
    super.initState();
    _contextTokensCtrl = TextEditingController(
        text: (widget.settings['maxContextTokens'] ?? 1000000).toString());
    _outputTokensCtrl = TextEditingController(
        text: (widget.settings['maxOutputTokens'] ?? 384000).toString());
    _skillsDirCtrl = TextEditingController(
        text: (widget.settings['skillsDir'] ?? '').toString());
    _shellPathCtrl = TextEditingController(
        text: (widget.settings['shellPath'] ?? '').toString());
    _shellPrefixCtrl = TextEditingController(
        text: (widget.settings['shellCommandPrefix'] ?? '').toString());
  }

  @override
  void dispose() {
    _contextTokensCtrl.dispose();
    _outputTokensCtrl.dispose();
    _skillsDirCtrl.dispose();
    _shellPathCtrl.dispose();
    _shellPrefixCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providerId = (widget.settings['defaultProvider'] ?? '').toString();
    final providersMap = widget.settings['providers'] as Map<String, dynamic>? ?? {};
    final modelsRaw = providersMap[providerId] is Map
        ? (providersMap[providerId]['models'] as List? ?? [])
        : [];
    final models = modelsRaw.whereType<Map>().toList();

    bool planToolVal = widget.settings['enablePlanTool'] != false;
    bool updateCheckVal = widget.settings['updateCheck'] != false;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('General Settings',
              style: TextStyle(
                  color: widget.c.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _section('Default Provider'),
          const SizedBox(height: 8),
          _dropdown(widget.c, 'Provider', providerId, providersMap.keys.toList(),
              (v) {
                widget.settings['defaultProvider'] = v;
                widget.onChanged();
              }),
          const SizedBox(height: 16),
          _section('Default Model'),
          const SizedBox(height: 8),
          _dropdown(
              widget.c,
              'Model',
              (widget.settings['defaultModel'] ?? '').toString(),
              models.map((m) => m['id'].toString()).toList(),
              (v) {
                widget.settings['defaultModel'] = v;
                widget.onChanged();
              }),
          const SizedBox(height: 16),
          _section('Default Mode'),
          const SizedBox(height: 8),
          _dropdown(widget.c, 'Mode', (widget.settings['defaultMode'] ?? 'agent').toString(),
              ['plan', 'agent', 'yolo'], (v) {
                widget.settings['defaultMode'] = v;
                widget.onChanged();
              }),
          const SizedBox(height: 16),
          _section('Default Thinking Level'),
          const SizedBox(height: 8),
          _dropdown(
              widget.c,
              'Thinking',
              (widget.settings['defaultThinkingLevel'] ?? 'medium').toString(),
              ['off', 'minimal', 'low', 'medium', 'high', 'xhigh'],
              (v) {
                widget.settings['defaultThinkingLevel'] = v;
                widget.onChanged();
              }),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section('Max Context Tokens'),
                    const SizedBox(height: 8),
                    _intField(widget.c, _contextTokensCtrl, (v) {
                      widget.settings['maxContextTokens'] = int.tryParse(v) ?? 1000000;
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section('Max Output Tokens'),
                    const SizedBox(height: 8),
                    _intField(widget.c, _outputTokensCtrl, (v) {
                      widget.settings['maxOutputTokens'] = int.tryParse(v) ?? 384000;
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _section('Skills Directory'),
          const SizedBox(height: 8),
          _textField(widget.c, _skillsDirCtrl, (v) {
            widget.settings['skillsDir'] = v;
          }, 'e.g. ~/.mothx/skills'),
          const SizedBox(height: 16),
          _section('Shell Path'),
          const SizedBox(height: 8),
          _textField(widget.c, _shellPathCtrl, (v) {
            widget.settings['shellPath'] = v;
          }, 'e.g. /bin/bash'),
          const SizedBox(height: 16),
          _section('Shell Command Prefix'),
          const SizedBox(height: 8),
          _textField(widget.c, _shellPrefixCtrl, (v) {
            widget.settings['shellCommandPrefix'] = v;
          }, 'e.g. bash -c'),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: planToolVal,
                activeColor: widget.c.accent,
                onChanged: (v) {
                  widget.settings['enablePlanTool'] = v ?? true;
                  widget.onChanged();
                },
              ),
              const SizedBox(width: 8),
              Text('Enable Plan Tool (enablePlanTool)', style: TextStyle(color: widget.c.textPrimary, fontSize: 13)),
            ],
          ),
          Row(
            children: [
              Checkbox(
                value: updateCheckVal,
                activeColor: widget.c.accent,
                onChanged: (v) {
                  widget.settings['updateCheck'] = v ?? true;
                  widget.onChanged();
                },
              ),
              const SizedBox(width: 8),
              Text('Check for updates on startup (updateCheck)', style: TextStyle(color: widget.c.textPrimary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          _section('Theme'),
          const SizedBox(height: 8),
          Row(
            children: [
              _themeChip('Dark', 'dark', widget.c),
              const SizedBox(width: 8),
              _themeChip('Light', 'light', widget.c),
            ],
          ),
        ],
      ),
    );
  }

  Widget _themeChip(String label, String value, AppColors c) {
    final current = widget.settings['theme'] ?? 'dark';
    final selected = current == value;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        widget.settings['theme'] = value;
        widget.onThemeChanged(value);
        widget.onChanged();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.accent : c.primary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? c.accent : c.separator),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : c.textSecondary,
                fontSize: 13)),
      ),
    );
  }

  Widget _section(String text) => Text(text,
      style: TextStyle(
          color: widget.c.textSecondary,
          fontSize: 11,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w500));

  Widget _dropdown(AppColors c, String label, String value, List<String> items,
      ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.secondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.separator),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : (items.isNotEmpty ? items.first : null),
          hint: Text('Select $label',
              style: TextStyle(color: c.textTertiary, fontSize: 13)),
          isExpanded: true,
          dropdownColor: c.secondary,
          style: TextStyle(color: c.textPrimary, fontSize: 13),
          icon: Icon(Icons.keyboard_arrow_down, color: c.textSecondary),
          items: items
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _intField(AppColors c, TextEditingController ctrl, ValueChanged<String> onChanged) {
    return TextField(
      controller: ctrl,
      style: TextStyle(color: c.textPrimary, fontSize: 14),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: c.secondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.separator),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.separator),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.accent),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _textField(AppColors c, TextEditingController ctrl, ValueChanged<String> onChanged, String hint) {
    return TextField(
      controller: ctrl,
      style: TextStyle(color: c.textPrimary, fontSize: 14),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textTertiary, fontSize: 13),
        filled: true,
        fillColor: c.secondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.separator),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.separator),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.accent),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

// ===========================================================================
// Approval Tab
// ===========================================================================
class _ApprovalTab extends StatelessWidget {
  final Map<String, dynamic> settings;
  final AppColors c;
  final VoidCallback onChanged;

  const _ApprovalTab({
    required this.settings,
    required this.c,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final approval = settings['approval'] as Map<String, dynamic>? ?? {};
    final whitelist = (approval['bashWhitelist'] as List?)?.cast<String>() ?? [];
    final blacklist = (approval['bashBlacklist'] as List?)?.cast<String>() ?? [];
    
    final confirmWrite = approval['confirmBeforeWrite'] == true;

    final whitelistCtrl = TextEditingController(text: whitelist.join('\n'));
    final blacklistCtrl = TextEditingController(text: blacklist.join('\n'));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Approval Settings',
              style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Text('Bash Command Whitelist',
              style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('One command prefix per line. Commands starting with these are auto-approved in agent mode.',
              style: TextStyle(color: c.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
            controller: whitelistCtrl,
            maxLines: 4,
            style: TextStyle(color: c.textPrimary, fontSize: 13,
                fontFamily: 'monospace'),
            onChanged: (v) {
              approval['bashWhitelist'] = v.split('\n')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              settings['approval'] = approval;
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: c.secondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.separator),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.separator),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.accent),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 20),
          Text('Bash Command Blacklist',
              style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('One command prefix per line. Commands starting with these always require approval.',
              style: TextStyle(color: c.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
            controller: blacklistCtrl,
            maxLines: 4,
            style: TextStyle(color: c.textPrimary, fontSize: 13,
                fontFamily: 'monospace'),
            onChanged: (v) {
              approval['bashBlacklist'] = v.split('\n')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              settings['approval'] = approval;
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: c.secondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.separator),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.separator),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.accent),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Checkbox(
                value: confirmWrite,
                activeColor: c.accent,
                onChanged: (v) {
                  approval['confirmBeforeWrite'] = v ?? false;
                  settings['approval'] = approval;
                  onChanged();
                },
              ),
              const SizedBox(width: 8),
              Text('Confirm before write/edit operations (confirmBeforeWrite)',
                  style: TextStyle(color: c.textPrimary, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Sandbox Tab
// ===========================================================================
class _SandboxTab extends StatelessWidget {
  final Map<String, dynamic> settings;
  final AppColors c;
  final VoidCallback onChanged;

  const _SandboxTab({
    required this.settings,
    required this.c,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sandbox = settings['sandbox'] as Map<String, dynamic>? ?? {};
    final enabled = sandbox['enabled'] == true;
    final level = (sandbox['level'] ?? 'none').toString();
    final allowNetwork = sandbox['allowNetwork'] == true;

    final bwrapCtrl = TextEditingController(text: (sandbox['bwrapPath'] ?? '').toString());
    final tmpSizeCtrl = TextEditingController(text: (sandbox['tmpSize'] ?? '').toString());

    final readPaths = (sandbox['allowedRead'] as List?)?.cast<String>() ?? [];
    final writePaths = (sandbox['allowedWrite'] as List?)?.cast<String>() ?? [];
    final deniedPaths = (sandbox['deniedPaths'] as List?)?.cast<String>() ?? [];
    final passEnv = (sandbox['passEnv'] as List?)?.cast<String>() ?? [];

    final readCtrl = TextEditingController(text: readPaths.join('\n'));
    final writeCtrl = TextEditingController(text: writePaths.join('\n'));
    final deniedCtrl = TextEditingController(text: deniedPaths.join('\n'));
    final envCtrl = TextEditingController(text: passEnv.join('\n'));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sandbox Settings',
              style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: enabled,
                activeColor: c.accent,
                onChanged: (v) {
                  sandbox['enabled'] = v ?? false;
                  settings['sandbox'] = sandbox;
                  onChanged();
                },
              ),
              const SizedBox(width: 8),
              Text('Enable sandbox execution (bubblewrap/bwrap)',
                  style: TextStyle(color: c.textPrimary, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Sandbox Protection Level',
              style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['none', 'strict', 'moderate'].map((l) {
              final selected = level == l;
              return ChoiceChip(
                label: Text(l),
                selected: selected,
                selectedColor: c.accent,
                backgroundColor: c.secondary,
                labelStyle: TextStyle(
                    color: selected ? Colors.white : c.textSecondary),
                onSelected: (_) {
                  sandbox['level'] = l;
                  settings['sandbox'] = sandbox;
                  onChanged();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: allowNetwork,
                activeColor: c.accent,
                onChanged: (v) {
                  sandbox['allowNetwork'] = v ?? false;
                  settings['sandbox'] = sandbox;
                  onChanged();
                },
              ),
              const SizedBox(width: 8),
              Text('Allow network access in sandbox',
                  style: TextStyle(color: c.textPrimary, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          _section('Bubblewrap Path (bwrapPath)'),
          const SizedBox(height: 8),
          _textField(c, bwrapCtrl, (v) {
            sandbox['bwrapPath'] = v;
            settings['sandbox'] = sandbox;
          }, 'e.g. /usr/bin/bwrap'),
          const SizedBox(height: 16),
          _section('Sandbox TmpFS Size (tmpSize)'),
          const SizedBox(height: 8),
          _textField(c, tmpSizeCtrl, (v) {
            sandbox['tmpSize'] = v;
            settings['sandbox'] = sandbox;
          }, 'e.g. 128M'),
          const SizedBox(height: 20),
          _sandboxPathField('Allowed Read Paths (allowedRead)', readCtrl, (paths) {
            sandbox['allowedRead'] = paths;
            settings['sandbox'] = sandbox;
          }),
          const SizedBox(height: 20),
          _sandboxPathField('Allowed Write Paths (allowedWrite)', writeCtrl, (paths) {
            sandbox['allowedWrite'] = paths;
            settings['sandbox'] = sandbox;
          }),
          const SizedBox(height: 20),
          _sandboxPathField('Explicitly Denied Paths (deniedPaths)', deniedCtrl, (paths) {
            sandbox['deniedPaths'] = paths;
            settings['sandbox'] = sandbox;
          }),
          const SizedBox(height: 20),
          _sandboxPathField('Passed Environment Variables (passEnv)', envCtrl, (vars) {
            sandbox['passEnv'] = vars;
            settings['sandbox'] = sandbox;
          }),
        ],
      ),
    );
  }

  Widget _section(String text) => Text(text,
      style: TextStyle(
          color: c.textSecondary,
          fontSize: 11,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w500));

  Widget _textField(AppColors c, TextEditingController ctrl, ValueChanged<String> onChanged, String hint) {
    return TextField(
      controller: ctrl,
      style: TextStyle(color: c.textPrimary, fontSize: 14),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textTertiary, fontSize: 13),
        filled: true,
        fillColor: c.secondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.separator),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.separator),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.accent),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _sandboxPathField(String label, TextEditingController ctrl, ValueChanged<List<String>> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: c.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('One path or item per line.',
            style: TextStyle(color: c.textTertiary, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: 3,
          style: TextStyle(color: c.textPrimary, fontSize: 13, fontFamily: 'monospace'),
          onChanged: (v) {
            final items = v.split('\n')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
            onChanged(items);
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: c.secondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: c.separator),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: c.separator),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: c.accent),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Serve Mode Tab
// ===========================================================================
class _ServeTab extends StatefulWidget {
  final AppColors c;
  final VoidCallback onChanged;

  const _ServeTab({
    required this.c,
    required this.onChanged,
  });

  @override
  State<_ServeTab> createState() => _ServeTabState();
}

class _ServeTabState extends State<_ServeTab> {
  late TextEditingController _baseUrlCtrl;
  late TextEditingController _authTokenCtrl;
  bool _connecting = false;
  String _statusMsg = '';

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _baseUrlCtrl = TextEditingController(text: app.serveBaseUrl);
    _authTokenCtrl = TextEditingController(text: app.serveAuthToken);
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    _authTokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final app = context.read<AppState>();
    final baseUrl = _baseUrlCtrl.text.trim();
    if (baseUrl.isEmpty) return;

    setState(() {
      _connecting = true;
      _statusMsg = '';
    });

    try {
      final authToken = _authTokenCtrl.text.trim();
      await app.connectServeMode(baseUrl, authToken: authToken.isEmpty ? null : authToken);
      final ok = app.isConnected;

      setState(() {
        _connecting = false;
        _statusMsg = ok ? 'Connected successfully!' : 'Connection failed. Check URL and auth token.';
      });

      // Save serve mode config to settings
      final settings = app.settings;
      settings['serveMode'] = {
        'enabled': ok,
        'baseUrl': baseUrl,
        'authToken': authToken.isEmpty ? null : authToken,
      };
      await app.saveSettings(settings);
      widget.onChanged();
    } catch (e) {
      setState(() {
        _connecting = false;
        _statusMsg = 'Error: $e';
      });
    }
  }

  Future<void> _disconnect() async {
    final app = context.read<AppState>();
    await app.disconnectServeMode();

    final settings = app.settings;
    settings['serveMode'] = {
      'enabled': false,
      'baseUrl': _baseUrlCtrl.text.trim(),
      'authToken': _authTokenCtrl.text.trim().isEmpty
          ? null
          : _authTokenCtrl.text.trim(),
    };
    await app.saveSettings(settings);

    setState(() {
      _statusMsg = 'Disconnected from serve mode.';
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isConnected = app.isConnected;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Serve Mode Connection',
              style: TextStyle(
                  color: widget.c.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Connect to a running "mothx serve" instance for shared sessions, stats, cron, and logs.',
            style: TextStyle(color: widget.c.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Connection status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isConnected ? widget.c.accentGreen : widget.c.textTertiary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (isConnected ? widget.c.accentGreen : widget.c.textTertiary)
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.circle_outlined,
                  size: 18,
                  color: isConnected ? widget.c.accentGreen : widget.c.textTertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isConnected ? 'Connected to mothx serve' : 'Not connected to mothx serve',
                    style: TextStyle(
                      color: isConnected ? widget.c.accentGreen : widget.c.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (isConnected)
                  TextButton.icon(
                    onPressed: _connecting ? null : _disconnect,
                    icon: const Icon(Icons.link_off, size: 16),
                    label: const Text('Disconnect', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: widget.c.accentRed,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Base URL
          _section('Serve Base URL'),
          const SizedBox(height: 8),
          TextField(
            controller: _baseUrlCtrl,
            enabled: !_connecting,
            style: TextStyle(color: widget.c.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'http://localhost:8080',
              hintStyle: TextStyle(color: widget.c.textTertiary),
              filled: true,
              fillColor: widget.c.secondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.c.separator),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.c.separator),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.c.accent),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Auth Token
          _section('Auth Token (Optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _authTokenCtrl,
            enabled: !_connecting,
            obscureText: true,
            style: TextStyle(color: widget.c.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'sk-...',
              hintStyle: TextStyle(color: widget.c.textTertiary),
              filled: true,
              fillColor: widget.c.secondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.c.separator),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.c.separator),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.c.accent),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Connect button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _connecting ? null : _connect,
              icon: _connecting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.link, size: 18),
              label: Text(_connecting ? 'Connecting...' : 'Connect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.c.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),

          if (_statusMsg.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _statusMsg,
              style: TextStyle(
                color: _statusMsg.contains('Error') || _statusMsg.contains('failed')
                    ? widget.c.accentRed
                    : widget.c.accentGreen,
                fontSize: 12,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Serve features info
          _section('Available in Serve Mode'),
          const SizedBox(height: 8),
          _featureItem(widget.c, Icons.bar_chart, 'Shared Usage Statistics', 'View token and request stats across all sessions'),
          _featureItem(widget.c, Icons.schedule, 'Cron Scheduled Tasks', 'Create and manage recurring agent tasks'),
          _featureItem(widget.c, Icons.terminal, 'Real-time Logs', 'Stream logs via WebSocket from the serve instance'),
          _featureItem(widget.c, Icons.people, 'Multi-session Support', 'Manage multiple sessions on a shared server'),
          _featureItem(widget.c, Icons.api, 'OpenAI-compatible API', 'Use serve endpoints with any OpenAI-compatible client'),
        ],
      ),
    );
  }

  Widget _section(String text) => Text(text,
      style: TextStyle(
          color: widget.c.textSecondary,
          fontSize: 11,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w500));

  Widget _featureItem(AppColors c, IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                Text(desc,
                    style: TextStyle(color: c.textTertiary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 680),
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
                        padding: const EdgeInsets.all(20),
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
        'apiKey': '',
        'baseUrl': '',
        'api': 'openai-chat',
        'models': <Map<String, dynamic>>[],
      };
    } else {
      p = Map<String, dynamic>.from(providerMap[id] as Map);
    }

    final idCtrl = TextEditingController(text: id ?? '');
    final keyCtrl = TextEditingController(text: (p['apiKey'] ?? '').toString());
    final urlCtrl = TextEditingController(text: (p['baseUrl'] ?? '').toString());
    final apiCtrl = TextEditingController(text: (p['api'] ?? 'openai-chat').toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(isNew ? 'Add Provider' : 'Edit $id',
            style: TextStyle(color: c.textPrimary)),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isNew)
                _settingField(c, 'Provider ID', idCtrl, 'e.g. my-openai'),
              _settingField(c, 'API Key', keyCtrl, '\${MY_API_KEY}'),
              _settingField(c, 'Base URL', urlCtrl, 'https://api.openai.com/v1'),
              _settingField(c, 'API Type', apiCtrl, 'openai-chat / anthropic-messages'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: c.accent, foregroundColor: Colors.white),
            onPressed: () {
              final newId = idCtrl.text.trim();
              if (newId.isEmpty) return;
              p['apiKey'] = keyCtrl.text;
              p['baseUrl'] = urlCtrl.text;
              p['api'] = apiCtrl.text;
              if (!isNew && id != newId) providerMap.remove(id);
              providerMap[newId] = p;
              Navigator.pop(context);
              onChanged();
            },
            child: const Text('Save'),
          ),
        ],
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

  @override
  void initState() {
    super.initState();
    _contextTokensCtrl = TextEditingController(
        text: (widget.settings['maxContextTokens'] ?? 1000000).toString());
    _outputTokensCtrl = TextEditingController(
        text: (widget.settings['maxOutputTokens'] ?? 384000).toString());
  }

  @override
  void dispose() {
    _contextTokensCtrl.dispose();
    _outputTokensCtrl.dispose();
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('General',
              style: TextStyle(
                  color: widget.c.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
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
          _section('Max Context Tokens'),
          const SizedBox(height: 8),
          _intField(widget.c, _contextTokensCtrl, (v) {
            widget.settings['maxContextTokens'] = int.tryParse(v) ?? 1000000;
          }),
          const SizedBox(height: 16),
          _section('Max Output Tokens'),
          const SizedBox(height: 8),
          _intField(widget.c, _outputTokensCtrl, (v) {
            widget.settings['maxOutputTokens'] = int.tryParse(v) ?? 384000;
          }),
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
    return SizedBox(
      width: 200,
      child: TextField(
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
    final whitelist =
        (approval['bashWhitelist'] as List?)?.cast<String>() ?? [];
    final confirmWrite = approval['confirmBeforeWrite'] == true;
    final confirmCtrl =
        TextEditingController(text: whitelist.join('\n'));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Approval',
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
          Text('One command prefix per line. Commands starting with these are auto-approved.',
              style: TextStyle(color: c.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
            controller: confirmCtrl,
            maxLines: 6,
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
              Text('Confirm before write operations',
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sandbox',
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
              Text('Enable sandbox execution',
                  style: TextStyle(color: c.textPrimary, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Level',
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
        ],
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme/app_theme.dart';

class ServePage extends StatefulWidget {
  const ServePage({super.key});

  @override
  State<ServePage> createState() => _ServePageState();
}

class _ServePageState extends State<ServePage> {
  final _memoryController = TextEditingController();
  final _configController = TextEditingController();
  String _tab = 'overview';
  String _memorySnapshot = '';
  String _configSnapshot = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshServeData();
    });
  }

  @override
  void dispose() {
    _memoryController.dispose();
    _configController.dispose();
    super.dispose();
  }

  void _sync(AppState app) {
    final memory = (app.memoryInfo['content'] ?? '').toString();
    if (memory != _memorySnapshot) {
      _memorySnapshot = memory;
      _memoryController.text = memory;
    }
    final config = const JsonEncoder.withIndent('  ').convert(app.serveConfig);
    if (config != _configSnapshot) {
      _configSnapshot = config;
      _configController.text = config;
    }
  }

  Future<void> _saveMemory(AppState app) async {
    setState(() => _saving = true);
    await app.saveMemory(_memoryController.text);
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _saveConfig(AppState app) async {
    Map<String, dynamic> config;
    try {
      config = Map<String, dynamic>.from(
        jsonDecode(_configController.text) as Map,
      );
    } catch (_) {
      app.reportError('Serve configuration must be valid JSON.');
      return;
    }
    setState(() => _saving = true);
    await app.saveServeConfig(config);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final app = context.watch<AppState>();
    _sync(app);
    return Container(
      color: c.primary,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.separator)),
            ),
            child: Row(
              children: [
                Icon(Icons.dns_outlined, color: c.accent, size: 22),
                const SizedBox(width: 10),
                Text('Mothx Serve',
                    style: TextStyle(color: c.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh serve data',
                  onPressed: app.isRefreshingServeData ? null : app.refreshServeData,
                  icon: const Icon(Icons.refresh),
                  color: c.textSecondary,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                for (final tab in const [
                  ('overview', 'Overview'),
                  ('memory', 'Memory'),
                  ('config', 'Config'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(tab.$2),
                      selected: _tab == tab.$1,
                      onSelected: (_) => setState(() => _tab = tab.$1),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: switch (_tab) {
              'memory' => _MemoryEditor(
                  controller: _memoryController,
                  enabled: app.isConnected && !_saving,
                  onSave: () => _saveMemory(app),
                ),
              'config' => _ConfigEditor(
                  controller: _configController,
                  enabled: app.isConnected && !_saving,
                  onSave: () => _saveConfig(app),
                ),
              _ => _Overview(status: app.serveStatus, capabilities: app.serveCapabilities),
            },
          ),
        ],
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  final Map<String, dynamic> status;
  final Map<String, dynamic> capabilities;

  const _Overview({required this.status, required this.capabilities});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final features = status['features'] is Map
        ? Map<String, dynamic>.from(status['features'] as Map)
        : <String, dynamic>{};
    final modes = capabilities['modes'] is List ? capabilities['modes'] as List : const [];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Metric(label: 'Status', value: (status['status'] ?? 'unknown').toString()),
            _Metric(label: 'Sessions', value: '${status['sessions'] ?? 0}'),
            _Metric(label: 'Listen', value: (status['listen'] ?? '-').toString()),
            _Metric(label: 'Modes', value: modes.isEmpty ? '-' : modes.join(', ')),
          ],
        ),
        const SizedBox(height: 24),
        Text('Features', style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: features.entries.map((entry) => Chip(
            avatar: Icon(entry.value == true ? Icons.check_circle : Icons.remove_circle_outline,
                size: 15, color: entry.value == true ? c.accentGreen : c.textTertiary),
            label: Text(entry.key),
          )).toList(),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.secondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.separator),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: c.textTertiary, fontSize: 12)),
        const SizedBox(height: 6),
        Text(value, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _MemoryEditor extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSave;

  const _MemoryEditor({required this.controller, required this.enabled, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Expanded(child: TextField(
          controller: controller,
          enabled: enabled,
          expands: true,
          maxLines: null,
          textAlignVertical: TextAlignVertical.top,
          style: TextStyle(color: c.textPrimary, fontFamily: 'monospace'),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        )),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerRight, child: FilledButton.icon(
          onPressed: enabled ? onSave : null,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save Memory'),
        )),
      ]),
    );
  }
}

class _ConfigEditor extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSave;

  const _ConfigEditor({required this.controller, required this.enabled, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Expanded(child: TextField(
          controller: controller,
          enabled: enabled,
          expands: true,
          maxLines: null,
          textAlignVertical: TextAlignVertical.top,
          style: TextStyle(color: c.textPrimary, fontFamily: 'monospace'),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        )),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerRight, child: FilledButton.icon(
          onPressed: enabled ? onSave : null,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save Serve Config'),
        )),
      ]),
    );
  }
}

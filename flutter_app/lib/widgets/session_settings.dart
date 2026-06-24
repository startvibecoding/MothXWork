import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

/// Header button that opens a popover for selecting mode/provider/model/thinking.
class SessionSettingsButton extends StatelessWidget {
  const SessionSettingsButton({super.key});

  static const modes = [
    {'id': 'plan', 'name': 'Plan', 'icon': '🗒️'},
    {'id': 'agent', 'name': 'Agent', 'icon': '🔧'},
    {'id': 'yolo', 'name': 'YOLO', 'icon': '🚀'},
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final app = context.watch<AppState>();
    final cfg = app.runtimeConfig;
    final mode = modes.firstWhere((m) => m['id'] == cfg.mode,
        orElse: () => modes[1]);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _openPopover(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: c.secondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mode['icon']!),
            const SizedBox(width: 6),
            Text(mode['name']!,
                style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            _divider(c),
            Text(cfg.provider,
                style: TextStyle(color: c.textSecondary, fontSize: 13)),
            _divider(c),
            Text(cfg.model,
                style: TextStyle(color: c.textSecondary, fontSize: 13)),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down, size: 18, color: c.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _divider(AppColors c) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text('|', style: TextStyle(color: c.separator)),
      );

  void _openPopover(BuildContext context) {
    final app = context.read<AppState>();
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => ChangeNotifierProvider.value(
        value: app,
        child: const _SettingsDialog(),
      ),
    );
  }
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog();

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late SessionRuntimeConfig _edit;

  static const thinkingLevels = [
    {'id': 'off', 'name': 'Off'},
    {'id': 'minimal', 'name': 'Min'},
    {'id': 'low', 'name': 'Low'},
    {'id': 'medium', 'name': 'Med'},
    {'id': 'high', 'name': 'High'},
    {'id': 'xhigh', 'name': 'XHigh'},
  ];

  @override
  void initState() {
    super.initState();
    _edit = context.read<AppState>().runtimeConfig.copyWith();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final app = context.watch<AppState>();
    final providers = app.providers;
    final models = app.modelsForProvider(_edit.provider);
    final base = app.runtimeConfig;
    final hasChanges = _edit.provider != base.provider ||
        _edit.model != base.model ||
        _edit.mode != base.mode ||
        _edit.thinking != base.thinking;

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 60, right: 16),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 340,
            decoration: BoxDecoration(
              color: c.secondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.separator),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 24)
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(c, 'MODE'),
                const SizedBox(height: 8),
                Row(
                  children: SessionSettingsButton.modes.map((m) {
                    final selected = _edit.mode == m['id'];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () =>
                              setState(() => _edit.mode = m['id']!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? c.accent.withValues(alpha: 0.2)
                                  : c.primary,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: selected
                                      ? c.accent.withValues(alpha: 0.5)
                                      : Colors.transparent),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(m['icon']!),
                                const SizedBox(width: 4),
                                Text(m['name']!,
                                    style: TextStyle(
                                        color: c.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _label(c, 'PROVIDER'),
                const SizedBox(height: 8),
                _Dropdown<String>(
                  value: _edit.provider.isEmpty ? null : _edit.provider,
                  hint: 'Select provider...',
                  items: providers
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text('${p.name} (${p.api})',
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _edit.provider = v ?? '';
                    _edit.model = '';
                  }),
                ),
                const SizedBox(height: 16),
                _label(c, 'MODEL'),
                const SizedBox(height: 8),
                _Dropdown<String>(
                  value: models.any((m) => m.id == _edit.model)
                      ? _edit.model
                      : null,
                  hint: 'Select model...',
                  items: models
                      .map((m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(_modelLabel(m),
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _edit.model = v ?? ''),
                ),
                const SizedBox(height: 16),
                _label(c, 'THINKING'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: thinkingLevels.map((t) {
                    final selected = _edit.thinking == t['id'];
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () =>
                          setState(() => _edit.thinking = t['id']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? c.accent : c.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(t['name']!,
                            style: TextStyle(
                                fontSize: 13,
                                color: selected
                                    ? Colors.white
                                    : c.textSecondary)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                if (hasChanges)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await app.updateRuntimeConfig(_edit);
                      },
                      child: const Text('Apply & Restart Session'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _modelLabel(ModelInfo m) {
    if (m.contextWindow > 0) {
      final ctx = m.contextWindow >= 1000000
          ? '${(m.contextWindow / 1000000).round()}M'
          : '${(m.contextWindow / 1000).round()}K';
      return '${m.name} ($ctx)';
    }
    return m.name;
  }

  Widget _label(AppColors c, String text) => Text(text,
      style: TextStyle(
          color: c.textSecondary,
          fontSize: 11,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w500));
}

class _Dropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.primary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.separator),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: TextStyle(color: c.textTertiary, fontSize: 13)),
          isExpanded: true,
          dropdownColor: c.secondary,
          style: TextStyle(color: c.textPrimary, fontSize: 13),
          icon: Icon(Icons.keyboard_arrow_down, color: c.textSecondary),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

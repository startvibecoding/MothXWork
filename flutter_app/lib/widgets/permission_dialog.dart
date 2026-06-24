import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class PermissionDialog extends StatefulWidget {
  final PermissionRequest request;
  const PermissionDialog({super.key, required this.request});

  @override
  State<PermissionDialog> createState() => _PermissionDialogState();
}

class _PermissionDialogState extends State<PermissionDialog> {
  bool _processing = false;

  String _formatInput(dynamic input) {
    if (input == null) return 'No input';
    if (input is String) return input;
    try {
      return const JsonEncoder.withIndent('  ').convert(input);
    } catch (_) {
      return input.toString();
    }
  }

  Future<void> _respond(String optionId) async {
    setState(() => _processing = true);
    await context.read<AppState>().respondPermission(optionId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final req = widget.request;

    // Determine reject/allow option IDs from available options, with fallbacks.
    String allowId = 'allow-once';
    String rejectId = 'reject-once';
    for (final o in req.options) {
      final k = o.kind.toLowerCase();
      if (k.contains('allow')) allowId = o.optionId;
      if (k.contains('reject') || k.contains('deny')) rejectId = o.optionId;
    }

    return Dialog(
      backgroundColor: c.secondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.separator)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c.accentOrange.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: Text('⚠️')),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Permission Required',
                          style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w600)),
                      Text('The AI wants to execute a command',
                          style: TextStyle(
                              color: c.textSecondary, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('COMMAND',
                      style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 11,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(req.title,
                        style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ),
                  if (req.input != null) ...[
                    const SizedBox(height: 16),
                    Text('INPUT',
                        style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 11,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 160),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(_formatInput(req.input),
                            style: TextStyle(
                                color: c.textSecondary,
                                fontSize: 12,
                                fontFamily: 'monospace')),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.accentOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: c.accentOrange.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('⚠️',
                            style: TextStyle(color: c.accentOrange)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              'Be careful when allowing command execution. Only allow commands you trust.',
                              style: TextStyle(
                                  color: c.accentOrange, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.separator)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _btn(c.accentRed, 'Reject',
                      _processing ? null : () => _respond(rejectId)),
                  const SizedBox(width: 12),
                  _btn(c.accentGreen, 'Allow',
                      _processing ? null : () => _respond(allowId)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(Color color, String label, VoidCallback? onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: Text(_processing ? 'Processing...' : label),
    );
  }
}

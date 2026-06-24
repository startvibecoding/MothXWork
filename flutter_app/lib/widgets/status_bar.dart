import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme/app_theme.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final app = context.watch<AppState>();
    final connected = app.isConnected;
    final session = app.currentSessionId;

    return Container(
      decoration: BoxDecoration(
        color: c.primary,
        border: Border(top: BorderSide(color: c.separator)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: connected ? c.accentGreen : c.accentRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(connected ? 'Connected' : 'Disconnected',
                  style: TextStyle(color: c.textSecondary, fontSize: 13)),
              if (session != null) ...[
                const SizedBox(width: 12),
                Text('|', style: TextStyle(color: c.separator)),
                const SizedBox(width: 12),
                Text(
                    'Session: ${session.length > 8 ? session.substring(0, 8) : session}...',
                    style: TextStyle(color: c.textTertiary, fontSize: 13)),
              ],
            ],
          ),
          Text('${app.messages.length} messages',
              style: TextStyle(color: c.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }
}

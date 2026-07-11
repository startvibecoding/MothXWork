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
    final serveUrl = app.serveUrl;

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: c.accentPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'SERVE',
                  style: TextStyle(
                    color: c.accentPurple,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(connected ? 'Connected' : 'Disconnected',
                  style: TextStyle(color: c.textSecondary, fontSize: 13)),
              if (serveUrl != null) ...[
                const SizedBox(width: 8),
                Text('|', style: TextStyle(color: c.separator)),
                const SizedBox(width: 8),
                Text(
                  serveUrl,
                  style: TextStyle(color: c.textTertiary, fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
              if (session != null) ...[
                const SizedBox(width: 12),
                Text('|', style: TextStyle(color: c.separator)),
                const SizedBox(width: 12),
                Text(
                    'Session: ${session.length > 8 ? session.substring(0, 8) : session}...',
                    style: TextStyle(color: c.textTertiary, fontSize: 13)),
              ],
              // Usage indicator
              if (app.contextSize > 0) ...[
                const SizedBox(width: 12),
                Text('|', style: TextStyle(color: c.separator)),
                const SizedBox(width: 12),
                _buildUsageIndicator(c, app.contextUsed, app.contextSize, app.currentCost),
              ],
            ],
          ),
          Row(
            children: [
              if (app.isLoading) ...[
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
              ],
              Text('${app.messages.length} messages',
                  style: TextStyle(color: c.textTertiary, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageIndicator(AppColors c, int used, int size, double? cost) {
    final pct = size > 0 ? (used / size * 100).toInt() : 0;
    final color = pct > 80 ? c.accentRed : pct > 60 ? c.accentOrange : c.accent;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mini progress bar
        SizedBox(
          width: 40,
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: size > 0 ? used / size : 0,
              backgroundColor: c.tertiary,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text('$used/$size',
            style: TextStyle(color: c.textTertiary, fontSize: 11, fontFamily: 'monospace')),
        if (cost != null && cost > 0) ...[
          const SizedBox(width: 6),
          Text('\$${cost.toStringAsFixed(4)}',
              style: TextStyle(color: c.textTertiary, fontSize: 11, fontFamily: 'monospace')),
        ],
      ],
    );
  }
}

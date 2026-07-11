import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

/// Real-time log viewer page with WebSocket connection.
class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final TextEditingController _filterCtrl = TextEditingController();
  String _filter = '';
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _filterCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final app = context.watch<AppState>();
    final logs = app.logs;
    final connected = app.logsConnected;

    final filtered = _filter.isEmpty
        ? logs
        : logs
            .where((e) =>
                e.type.toLowerCase().contains(_filter.toLowerCase()) ||
                e.message.toLowerCase().contains(_filter.toLowerCase()))
            .toList();

    return Container(
      color: c.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / toolbar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.separator)),
            ),
            child: Row(
              children: [
                Icon(Icons.terminal, size: 22, color: c.accent),
                const SizedBox(width: 10),
                Text(
                  'Logs',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Connection status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (connected ? c.accentGreen : c.textTertiary)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        connected ? Icons.circle : Icons.circle_outlined,
                        size: 8,
                        color: connected ? c.accentGreen : c.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        connected ? 'Connected' : 'Disconnected',
                        style: TextStyle(
                          color: connected ? c.accentGreen : c.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    if (connected) {
                      app.disconnectLogs();
                    } else {
                      if (!app.isConnected) {
                        await app.connectServeMode(
                          app.serveBaseUrl,
                          authToken: app.serveAuthToken.isEmpty
                              ? null
                              : app.serveAuthToken,
                        );
                      }
                      await app.connectLogs();
                    }
                  },
                  icon: Icon(
                    connected ? Icons.link_off : Icons.link,
                    size: 16,
                  ),
                  label: Text(connected ? 'Disconnect' : 'Connect',
                      style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.textSecondary,
                    side: BorderSide(color: c.separator),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => app.clearLogs(),
                  icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                  label: const Text('Clear', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.textSecondary,
                    side: BorderSide(color: c.separator),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ),

          // Filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _filterCtrl,
              onChanged: (v) => setState(() => _filter = v),
              style: TextStyle(color: c.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Filter logs...',
                hintStyle: TextStyle(color: c.textTertiary),
                filled: true,
                fillColor: c.secondary,
                prefixIcon: Icon(Icons.filter_list, color: c.textTertiary, size: 20),
                suffixIcon: _filter.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 18, color: c.textTertiary),
                        onPressed: () {
                          _filterCtrl.clear();
                          setState(() => _filter = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.separator),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.separator),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.accent),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),

          // Log count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              '${filtered.length} of ${logs.length} entries',
              style: TextStyle(color: c.textTertiary, fontSize: 11),
            ),
          ),

          // Log list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 48, color: c.textTertiary),
                        const SizedBox(height: 12),
                        Text(
                          'No log entries',
                          style: TextStyle(color: c.textSecondary, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          connected ? 'Waiting for new log entries...' : 'Connect to see logs',
                          style: TextStyle(color: c.textTertiary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final entry = filtered[filtered.length - 1 - index];
                      return _LogLine(entry: entry, c: c);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LogLine extends StatelessWidget {
  final LogEntry entry;
  final AppColors c;

  const _LogLine({required this.entry, required this.c});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm:ss').format(entry.timestamp);

    Color typeColor;
    switch (entry.type.toLowerCase()) {
      case 'error':
        typeColor = c.accentRed;
        break;
      case 'warn':
      case 'warning':
        typeColor = c.accentOrange;
        break;
      case 'info':
        typeColor = c.accent;
        break;
      case 'debug':
        typeColor = c.textTertiary;
        break;
      default:
        typeColor = c.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.separator.withValues(alpha: 0.3))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          SizedBox(
            width: 72,
            child: Text(
              timeStr,
              style: TextStyle(
                color: c.textTertiary,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              entry.type.toUpperCase(),
              style: TextStyle(
                color: typeColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Message
          Expanded(
            child: Text(
              entry.message,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

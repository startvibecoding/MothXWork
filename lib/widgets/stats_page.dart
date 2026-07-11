import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

/// Stats dashboard page showing usage statistics.
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  String get _timeRange => context.read<AppState>().statsTimeRange;

  @override
  void initState() {
    super.initState();
    // Load stats on first build if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final app = context.read<AppState>();
        if (app.statsSummary == null) {
          app.refreshStats(app.statsTimeRange);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final app = context.watch<AppState>();
    final stats = app.statsSummary;

    return Container(
      color: c.primary,
      child: Column(
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
                Icon(Icons.bar_chart, size: 22, color: c.accent),
                const SizedBox(width: 10),
                Text(
                  'Statistics',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Time range selector
                _TimeRangeSelector(
                  selected: _timeRange,
                  onChanged: (v) async {
                    final app = context.read<AppState>();
                    await app.refreshStats(v);
                  },
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: stats == null
                ? _EmptyStatsState()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Summary cards row
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.swap_calls,
                              label: 'Requests',
                              value: '${stats.totalRequests}',
                              color: c.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.input,
                              label: 'Input Tokens',
                              value: _formatTokens(stats.inputTokens),
                              color: c.accentGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.output,
                              label: 'Output Tokens',
                              value: _formatTokens(stats.outputTokens),
                              color: c.accentPurple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.data_usage,
                              label: 'Total Tokens',
                              value: _formatTokens(stats.totalTokens),
                              color: c.accentOrange,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Provider stats
                      if (stats.byProvider != null && stats.byProvider!.isNotEmpty) ...[
                        _SectionHeader(title: 'By Provider'),
                        const SizedBox(height: 8),
                        ...stats.byProvider!.map((p) => _ProviderStatRow(
                          provider: p.provider,
                          requests: p.requests,
                          tokens: p.tokens,
                        )),
                        const SizedBox(height: 20),
                      ],

                      // Model stats
                      if (stats.byModel != null && stats.byModel!.isNotEmpty) ...[
                        _SectionHeader(title: 'By Model'),
                        const SizedBox(height: 8),
                        ...stats.byModel!.take(8).map((m) => _ModelStatRow(
                          model: m.model,
                          requests: m.requests,
                          tokens: m.tokens,
                        )),
                      ],

                      // Recent requests
                      if (stats.recent != null && stats.recent!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _SectionHeader(title: 'Recent Activity'),
                        const SizedBox(height: 8),
                        ...stats.recent!.take(10).map((r) => _RecentEntryRow(entry: r)),
                      ],

                      if (app.statsTimeSeries.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const _SectionHeader(title: 'Usage Trend'),
                        const SizedBox(height: 8),
                        _ServeAggregateList(
                          entries: app.statsTimeSeries,
                          labelKey: 'label',
                        ),
                      ],
                      if (app.statsByProvider.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const _SectionHeader(title: 'By Provider'),
                        const SizedBox(height: 8),
                        _ServeAggregateList(
                          entries: app.statsByProvider,
                          labelKey: 'provider',
                        ),
                      ],
                      if (app.statsByModel.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const _SectionHeader(title: 'By Model'),
                        const SizedBox(height: 8),
                        _ServeAggregateList(
                          entries: app.statsByModel,
                          labelKey: 'model',
                        ),
                      ],
                      if (app.statsRecent['items'] is List &&
                          (app.statsRecent['items'] as List).isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const _SectionHeader(title: 'Recent Requests'),
                        const SizedBox(height: 8),
                        _ServeAggregateList(
                          entries: (app.statsRecent['items'] as List)
                              .whereType<Map>()
                              .map((item) => Map<String, dynamic>.from(item))
                              .toList(),
                          labelKey: 'model',
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTokens(int tokens) {
    if (tokens >= 1_000_000) {
      return '${(tokens / 1_000_000).toStringAsFixed(1)}M';
    }
    if (tokens >= 1_000) {
      return '${(tokens / 1_000).toStringAsFixed(1)}K';
    }
    return '$tokens';
  }
}

class _TimeRangeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _TimeRangeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final options = ['24h', '7d', '30d', '90d'];

    return Container(
      decoration: BoxDecoration(
        color: c.secondary,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isActive = opt == selected;
          return GestureDetector(
            onTap: () => onChanged(opt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? c.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                opt,
                style: TextStyle(
                  color: isActive ? Colors.white : c.textSecondary,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyStatsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_outlined, size: 56, color: c.textTertiary),
          const SizedBox(height: 12),
          Text(
            'No statistics available yet',
            style: TextStyle(color: c.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Start a conversation to see usage stats',
            style: TextStyle(color: c.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: c.textTertiary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Text(
      title,
      style: TextStyle(
        color: c.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ServeAggregateList extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  final String labelKey;

  const _ServeAggregateList({required this.entries, required this.labelKey});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Column(
      children: entries.take(20).map((entry) {
        final label = (entry[labelKey] ?? entry['vendor'] ?? entry['sessionId'] ?? 'unknown').toString();
        final requests = entry['requests'] ?? 0;
        final tokens = entry['totalTokens'] ?? entry['tokens'] ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(6)),
          child: Row(children: [
            Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c.textPrimary))),
            Text('$requests req', style: TextStyle(color: c.textTertiary, fontSize: 12)),
            const SizedBox(width: 12),
            Text('$tokens tok', style: TextStyle(color: c.textTertiary, fontSize: 12)),
          ]),
        );
      }).toList(),
    );
  }
}

class _ProviderStatRow extends StatelessWidget {
  final String provider;
  final int requests;
  final int tokens;

  const _ProviderStatRow({
    required this.provider,
    required this.requests,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.secondary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.dns, size: 16, color: c.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$requests requests · ${_fmtTokens(tokens)} tokens',
                    style: TextStyle(color: c.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTokens(int n) {
    if (n >= 1_000_000) return '${(n / 1_000_000).toStringAsFixed(1)}M';
    if (n >= 1_000) return '${(n / 1_000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _ModelStatRow extends StatelessWidget {
  final String model;
  final int requests;
  final int tokens;

  const _ModelStatRow({
    required this.model,
    required this.requests,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: c.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              model,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.textPrimary, fontSize: 13),
            ),
          ),
          Text(
            '$requests',
            style: TextStyle(color: c.textTertiary, fontSize: 12),
          ),
          const SizedBox(width: 12),
          Text(
            _fmtTokens(tokens),
            style: TextStyle(color: c.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _fmtTokens(int n) {
    if (n >= 1_000_000) return '${(n / 1_000_000).toStringAsFixed(1)}M';
    if (n >= 1_000) return '${(n / 1_000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _RecentEntryRow extends StatelessWidget {
  final RecentEntry entry;

  const _RecentEntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final model = entry.model.isNotEmpty ? entry.model : 'unknown';
    final input = entry.inputTokens;
    final output = entry.outputTokens;
    final duration = entry.durationMs;
    final sessionId = entry.sessionId;
    final vendor = entry.vendor ?? '';

    String? timeStr;
    if (entry.timestamp.isNotEmpty) {
      try {
        timeStr = DateFormat('MM-dd HH:mm').format(DateTime.parse(entry.timestamp));
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: c.tertiary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.chat, size: 14, color: c.textTertiary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$vendor / $model',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.textPrimary, fontSize: 12),
                ),
                if (sessionId.isNotEmpty)
                  Text(
                    '${sessionId.substring(0, sessionId.length > 8 ? 8 : sessionId.length)}...',
                    style: TextStyle(color: c.textTertiary, fontSize: 10),
                  ),
              ],
            ),
          ),
          Text(
            '↑${_fmtTokens(input)} ↓${_fmtTokens(output)}',
            style: TextStyle(color: c.textTertiary, fontSize: 11),
          ),
          const SizedBox(width: 10),
          Text(
            '${duration}ms',
            style: TextStyle(color: c.textTertiary, fontSize: 11),
          ),
          if (timeStr != null) ...[
            const SizedBox(width: 10),
            Text(timeStr, style: TextStyle(color: c.textTertiary, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  String _fmtTokens(int n) {
    if (n >= 1_000_000) return '${(n / 1_000_000).toStringAsFixed(1)}M';
    if (n >= 1_000) return '${(n / 1_000).toStringAsFixed(1)}K';
    return '$n';
  }
}

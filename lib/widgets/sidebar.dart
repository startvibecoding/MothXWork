import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme/app_theme.dart';

/// Sidebar navigation items.
const _primaryNavItems = [
  {'key': 'chat', 'icon': Icons.edit_outlined, 'iconActive': Icons.edit, 'label': 'Chat'},
  {'key': 'sessions', 'icon': Icons.history_outlined, 'iconActive': Icons.history, 'label': 'Sessions'},
  {'key': 'stats', 'icon': Icons.bar_chart_outlined, 'iconActive': Icons.bar_chart, 'label': 'Stats'},
  {'key': 'cron', 'icon': Icons.schedule_outlined, 'iconActive': Icons.schedule, 'label': 'Cron'},
  {'key': 'logs', 'icon': Icons.terminal_outlined, 'iconActive': Icons.terminal, 'label': 'Logs'},
];

class Sidebar extends StatelessWidget {
  final VoidCallback onNewSession;
  final VoidCallback onOpenSettings;

  const Sidebar({
    super.key,
    required this.onNewSession,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final app = context.watch<AppState>();
    final sessions = app.sessions.reversed.toList();

    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: c.primary,
        border: Border(right: BorderSide(color: c.separator)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.separator)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mothx',
                        style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                    Text('Powered by Mothx',
                        style:
                            TextStyle(color: c.textSecondary, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          // New session
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 42,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onNewSession,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Session',
                    style: TextStyle(fontWeight: FontWeight.w500)),
              ),
            ),
          ),

          // Navigation tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: _primaryNavItems.map((item) {
                final isActive = app.currentPage == item['key'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Material(
                    color: isActive ? c.accent.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => app.navigateToPage(item['key'] as String),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Icon(
                              isActive ? item['iconActive'] as IconData : item['icon'] as IconData,
                              size: 18,
                              color: isActive ? c.accent : c.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              item['label'] as String,
                              style: TextStyle(
                                color: isActive ? c.accent : c.textSecondary,
                                fontSize: 14,
                                fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Session list header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text('SESSIONS',
                    style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w500)),
                const Spacer(),
                if (app.currentPage != 'sessions')
                  InkWell(
                    onTap: () => app.navigateToPage('sessions'),
                    child: Text('All',
                        style: TextStyle(color: c.accent, fontSize: 11, fontWeight: FontWeight.w500)),
                  ),
              ],
            ),
          ),

          // Sessions list
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: sessions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text('No sessions yet',
                          style: TextStyle(
                              color: c.textTertiary, fontSize: 13)),
                    )
                  : ListView.separated(
                      itemCount: sessions.length > 12 ? 12 : sessions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 2),
                      itemBuilder: (context, i) {
                        final s = sessions[i];
                        final selected = app.currentSessionId == s.id;
                        return _SessionTile(
                          selected: selected,
                          idLabel: s.id.length > 20
                              ? '${s.id.substring(0, 20)}...'
                              : s.id,
                          name: s.name,
                          onTap: () {
                            app.selectSession(s.id);
                            if (app.currentPage != 'chat') {
                              app.navigateToPage('chat');
                            }
                          },
                          onDelete: () => app.deleteSession(s.id),
                        );
                      },
                    ),
            ),
          ),

          // Bottom bar: Settings
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.separator)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onOpenSettings,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.settings, size: 18, color: c.textSecondary),
                          const SizedBox(width: 8),
                          Text('Settings',
                              style: TextStyle(color: c.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final bool selected;
  final String idLabel;
  final String name;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionTile({
    required this.selected,
    required this.idLabel,
    required this.name,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Material(
      color: selected ? c.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        onSecondaryTapDown: (details) => _showMenu(context, details.globalPosition),
        hoverColor: selected ? c.accent : c.secondary,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(idLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: selected
                          ? Colors.white70
                          : c.textTertiary)),
              const SizedBox(height: 2),
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color:
                          selected ? Colors.white : c.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, Offset position) async {
    final c = AppTheme.of(context);
    final selected = await showMenu<String>(
      context: context,
      color: c.secondary,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(
          value: 'delete',
          child: Text('删除 Session', style: TextStyle(color: c.accentRed)),
        ),
      ],
    );
    if (selected == 'delete') onDelete();
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme/app_theme.dart';

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
                    Text('VibeWork',
                        style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                    Text('Power By VibeCoding',
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

          // Sessions list
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                    child: Text('SESSIONS',
                        style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 11,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    child: sessions.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text('No sessions yet',
                                style: TextStyle(
                                    color: c.textTertiary, fontSize: 13)),
                          )
                        : ListView.separated(
                            itemCount: sessions.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 4),
                            itemBuilder: (context, i) {
                              final s = sessions[i];
                              final selected = app.currentSessionId == s.id;
                              return _SessionTile(
                                selected: selected,
                                idLabel: s.id.length > 20
                                    ? '${s.id.substring(0, 20)}...'
                                    : s.id,
                                name: s.name,
                                onTap: () => app.selectSession(s.id),
                                onDelete: () => app.deleteSession(s.id),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Settings
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.separator)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onOpenSettings,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 18, color: c.textSecondary),
                    const SizedBox(width: 8),
                    Text('全局设置',
                        style:
                            TextStyle(color: c.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
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

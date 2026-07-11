import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

/// Sessions management page: lists all sessions with search, delete, and open actions.
class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final app = context.watch<AppState>();
    final sessions = app.sessions.reversed.toList();

    final filtered = _searchQuery.isEmpty
        ? sessions
        : sessions
            .where((s) =>
                s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                s.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                s.cwd.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, size: 22, color: c.accent),
                    const SizedBox(width: 10),
                    Text(
                      'Sessions',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${sessions.length}',
                        style: TextStyle(
                          color: c.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(color: c.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search sessions...',
                    hintStyle: TextStyle(color: c.textTertiary),
                    filled: true,
                    fillColor: c.secondary,
                    prefixIcon: Icon(Icons.search, color: c.textTertiary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18, color: c.textTertiary),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),

          // Session list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _searchQuery.isEmpty ? Icons.inbox_outlined : Icons.search_off,
                          size: 48,
                          color: c.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty ? 'No sessions yet' : 'No matching sessions',
                          style: TextStyle(color: c.textSecondary, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final s = filtered[i];
                      final isActive = app.currentSessionId == s.id;
                      return _SessionCard(
                        session: s,
                        isActive: isActive,
                        onTap: () {
                          app.selectSession(s.id);
                          app.navigateToPage('chat');
                        },
                        onDelete: () => _confirmDelete(context, s),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, SessionInfo s) async {
    final c = AppTheme.of(context);
    final app = context.read<AppState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Delete Session', style: TextStyle(color: c.textPrimary)),
        content: Text(
          'Are you sure you want to delete "${s.name}"? This action cannot be undone.',
          style: TextStyle(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: c.accentRed)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      app.deleteSession(s.id);
    }
  }
}

class _SessionCard extends StatelessWidget {
  final SessionInfo session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final createdAt = _formatDate(session.createdAt);

    return Material(
      color: isActive ? c.accent.withValues(alpha: 0.1) : c.secondary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive ? c.accent : c.tertiary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isActive ? Icons.chat_bubble : Icons.chat_bubble_outline,
                  size: 20,
                  color: isActive ? Colors.white : c.textSecondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isActive ? c.accent : c.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _compactPath(session.cwd),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.textTertiary, fontSize: 12),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        createdAt,
                        style: TextStyle(color: c.textTertiary, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: c.textTertiary),
                color: c.secondary,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'open',
                    child: Row(
                      children: [
                        Icon(Icons.open_in_new, size: 16, color: c.accent),
                        const SizedBox(width: 8),
                        Text('Open', style: TextStyle(color: c.textPrimary)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 16, color: c.accentRed),
                        const SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: c.accentRed)),
                      ],
                    ),
                  ),
                ],
                onSelected: (v) {
                  if (v == 'open') onTap();
                  if (v == 'delete') onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      return null;
    }
  }

  String _compactPath(String path) {
    if (path.isEmpty) return 'No directory';
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length <= 3) return path;
    return '.../${parts.sublist(parts.length - 3).join('/')}';
  }
}

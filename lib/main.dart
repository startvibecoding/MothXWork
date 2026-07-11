import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/chat_area.dart';
import 'widgets/channels_page.dart';
import 'widgets/cron_page.dart';
import 'widgets/global_settings.dart';
import 'widgets/input_area.dart';
import 'widgets/logs_page.dart';
import 'widgets/session_settings.dart';
import 'widgets/session_tools.dart';
import 'widgets/serve_page.dart';
import 'widgets/sessions_page.dart';
import 'widgets/stats_page.dart';
import 'widgets/sidebar.dart';
import 'widgets/status_bar.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const MothxApp(),
    ),
  );
}

/// Root widget: decides theme, wraps MaterialApp, shows permission overlay.
class MothxApp extends StatelessWidget {
  const MothxApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isDark = app.theme == 'dark';
    final colors = isDark ? AppColors.dark : AppColors.light;

    return AppTheme(
      colors: colors,
      isDark: isDark,
      child: MaterialApp(
        title: 'Mothx',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: isDark ? Brightness.dark : Brightness.light,
          scaffoldBackgroundColor: colors.primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: colors.accent,
            brightness: isDark ? Brightness.dark : Brightness.light,
            primary: colors.accent,
            surface: colors.primary,
          ),
          useMaterial3: true,
        ),
        home: const MainLayout(),
      ),
    );
  }
}

/// Main layout: Sidebar + content column.
class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            onNewSession: () => _showNewSessionDialog(context),
            onOpenSettings: () => _showGlobalSettingsDialog(context),
          ),
          Expanded(
            child: Column(
              children: [
                if (app.errorBanner != null)
                  _ErrorBanner(message: app.errorBanner!),
                Expanded(
                  child: _PageRouter(
                    onNewSession: () => _showNewSessionDialog(context),
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

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final app = context.read<AppState>();
    return Material(
      color: c.accentRed.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 18, color: c.accentRed),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: TextStyle(color: c.textPrimary, fontSize: 13)),
            ),
            if (!app.isConnected)
              IconButton(
                tooltip: 'Retry serve connection',
                onPressed: app.reconnectServe,
                icon: Icon(Icons.refresh, size: 18, color: c.textSecondary),
              ),
            IconButton(
              tooltip: 'Dismiss error',
              onPressed: app.dismissError,
              icon: Icon(Icons.close, size: 18, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page router: decides which page to show based on AppState.currentPage.
class _PageRouter extends StatelessWidget {
  final VoidCallback onNewSession;
  const _PageRouter({required this.onNewSession});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    switch (app.currentPage) {
      case 'chat':
        return Column(
          children: [
            const _Header(),
            Expanded(child: ChatArea()),
            InputArea(),
            StatusBar(),
          ],
        );
      case 'sessions':
        return const SessionsPage();
      case 'stats':
        return const StatsPage();
      case 'cron':
        return const CronPage();
      case 'logs':
        return const LogsPage();
      case 'serve':
        return const ServePage();
      case 'channels':
        return const ChannelsPage();
      default:
        return Column(
          children: [
            const _Header(),
            Expanded(child: ChatArea()),
            InputArea(),
            StatusBar(),
          ],
        );
    }
  }
}

/// Header bar: session name (double-click to rename) + SessionSettingsButton.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final app = context.watch<AppState>();
    final sessionName = app.sessionName(app.currentSessionId);

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.primary,
        border: Border(bottom: BorderSide(color: c.separator)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onDoubleTap: () => _showRenameDialog(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    sessionName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.edit, size: 14, color: c.textTertiary),
              ],
            ),
          ),
          const Spacer(),
          if (app.isConnected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: c.accentPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.dns, size: 12, color: c.accentPurple),
                  const SizedBox(width: 4),
                  Text(
                    'SERVE',
                    style: TextStyle(
                      color: c.accentPurple,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          const SessionActivityButton(),
          const SessionToolsButton(),
          const SessionSettingsButton(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogs
// ---------------------------------------------------------------------------

Future<void> _showNewSessionDialog(BuildContext context) async {
  final app = context.read<AppState>();
  final path = await showDialog<String>(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: app,
      child: const _ServeDirectoryDialog(),
    ),
  );
  if (path == null || path.isEmpty) return;

  await app.createSession(path);
}

class _ServeDirectoryDialog extends StatefulWidget {
  const _ServeDirectoryDialog();

  @override
  State<_ServeDirectoryDialog> createState() => _ServeDirectoryDialogState();
}

class _ServeDirectoryDialogState extends State<_ServeDirectoryDialog> {
  String _path = '';
  String _parent = '';
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load([String? path]) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final data = await context.read<AppState>().browseDirectories(path: path);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (data == null) {
        _error = 'Unable to browse directories on mothx serve.';
        return;
      }
      _path = (data['path'] ?? '').toString();
      _parent = (data['parent'] ?? '').toString();
      final entries = data['entries'];
      _entries = entries is List
          ? entries.whereType<Map>().map((entry) => Map<String, dynamic>.from(entry)).toList()
          : [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AlertDialog(
      backgroundColor: c.secondary,
      title: Text('Select Working Directory', style: TextStyle(color: c.textPrimary)),
      content: SizedBox(
        width: 540,
        height: 420,
        child: Column(children: [
          Row(children: [
            Expanded(child: Text(_path.isEmpty ? 'Loading...' : _path,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c.textSecondary, fontFamily: 'monospace'))),
            IconButton(
              tooltip: 'Parent directory',
              onPressed: _parent.isEmpty || _loading ? null : () => _load(_parent),
              icon: const Icon(Icons.arrow_upward),
            ),
            IconButton(
              tooltip: 'Refresh directory',
              onPressed: _loading ? null : () => _load(_path),
              icon: const Icon(Icons.refresh),
            ),
          ]),
          const Divider(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: TextStyle(color: c.accentRed)))
                    : ListView.builder(
                        itemCount: _entries.length,
                        itemBuilder: (_, index) {
                          final entry = _entries[index];
                          final entryPath = (entry['path'] ?? '').toString();
                          return ListTile(
                            leading: const Icon(Icons.folder_outlined),
                            title: Text((entry['name'] ?? entryPath).toString()),
                            onTap: entryPath.isEmpty ? null : () => _load(entryPath),
                            trailing: IconButton(
                              tooltip: 'Select this directory',
                              icon: const Icon(Icons.check),
                              onPressed: entryPath.isEmpty
                                  ? null
                                  : () => Navigator.of(context).pop(entryPath),
                            ),
                          );
                        },
                      ),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _path.isEmpty ? null : () => Navigator.of(context).pop(_path),
          child: const Text('Select'),
        ),
      ],
    );
  }
}

/// Rename session: showDialog with a TextField.
Future<void> _showRenameDialog(BuildContext context) async {
  final app = context.read<AppState>();
  final currentId = app.currentSessionId;
  if (currentId == null) return;

  final currentName = app.sessionName(currentId);
  final controller = TextEditingController(text: currentName);

  final newName = await showDialog<String>(
    context: context,
    builder: (ctx) {
      final c = AppTheme.of(ctx);
      return AlertDialog(
        backgroundColor: c.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Rename Session',
          style: TextStyle(color: c.textPrimary, fontSize: 17),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: c.textPrimary),
          decoration: InputDecoration(
            hintText: 'Session name',
            hintStyle: TextStyle(color: c.textTertiary),
            filled: true,
            fillColor: c.primary,
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
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text('Rename', style: TextStyle(color: c.accent)),
          ),
        ],
      );
    },
  );

  if (newName != null && newName.isNotEmpty && newName != currentName) {
    await app.renameSession(currentId, newName);
  }
}

/// Global settings dialog.
Future<void> _showGlobalSettingsDialog(BuildContext context) async {
  final app = context.read<AppState>();

  await showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: app,
      child: const GlobalSettingsDialog(),
    ),
  );
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/chat_area.dart';
import 'widgets/cron_page.dart';
import 'widgets/global_settings.dart';
import 'widgets/input_area.dart';
import 'widgets/logs_page.dart';
import 'widgets/permission_dialog.dart';
import 'widgets/session_settings.dart';
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

    // Show permission dialog as overlay when a pending request arrives.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final req = app.pendingPermission;
      if (req != null && Navigator.of(context).canPop() == false) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => ChangeNotifierProvider.value(
            value: app,
            child: PermissionDialog(request: req),
          ),
        ).then((_) => app.dismissPermission());
      }
    });

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            onNewSession: () => _showNewSessionDialog(context),
            onOpenSettings: () => _showGlobalSettingsDialog(context),
          ),
          Expanded(
            child: _PageRouter(
              onNewSession: () => _showNewSessionDialog(context),
            ),
          ),
        ],
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
          // Serve mode indicator
          if (app.connectionMode == ConnectionMode.serve)
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
          const SessionSettingsButton(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogs
// ---------------------------------------------------------------------------

/// New session: pick a directory via FilePicker, then create session.
Future<void> _showNewSessionDialog(BuildContext context) async {
  final app = context.read<AppState>();

  final path = await FilePicker.platform.getDirectoryPath(
    dialogTitle: 'Select Working Directory',
  );
  if (path == null || path.isEmpty) return;

  await app.createSession(path);
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

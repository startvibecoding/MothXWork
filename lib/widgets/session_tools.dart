import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme/app_theme.dart';

class SessionToolsButton extends StatelessWidget {
  const SessionToolsButton({super.key});

  static const _tools = [
    ('webSearch', 'Web Search', Icons.travel_explore),
    ('browser', 'Browser', Icons.language),
    ('a2aMaster', 'A2A Master', Icons.hub_outlined),
    ('delegate', 'Delegate', Icons.account_tree_outlined),
    ('multiAgent', 'Multi-agent', Icons.groups_outlined),
    ('workflows', 'Workflows', Icons.account_tree),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return IconButton(
      tooltip: 'Session tools',
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<AppState>(),
          child: const _ToolsDialog(),
        ),
      ),
      icon: Icon(Icons.tune, size: 19, color: c.textSecondary),
    );
  }
}

class _ToolsDialog extends StatelessWidget {
  const _ToolsDialog();

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final app = context.watch<AppState>();
    final tools = app.toolsForSession();
    return AlertDialog(
      backgroundColor: c.secondary,
      title: Text('Session Tools', style: TextStyle(color: c.textPrimary)),
      content: SizedBox(
        width: 380,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final tool in SessionToolsButton._tools)
            SwitchListTile(
              value: tools[tool.$1] ?? false,
              onChanged: app.isLoading
                  ? null
                  : (enabled) => app.updateSessionTools({tool.$1: enabled}),
              secondary: Icon(tool.$3, color: c.textSecondary),
              title: Text(tool.$2, style: TextStyle(color: c.textPrimary)),
            ),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done'))],
    );
  }
}

class SessionActivityButton extends StatelessWidget {
  const SessionActivityButton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return IconButton(
      tooltip: 'Session activity',
      onPressed: context.read<AppState>().currentSessionId == null
          ? null
          : () => showDialog<void>(
                context: context,
                builder: (_) => ChangeNotifierProvider.value(
                  value: context.read<AppState>(),
                  child: const _ActivityDialog(),
                ),
              ),
      icon: Icon(Icons.insights_outlined, size: 19, color: c.textSecondary),
    );
  }
}

class _ActivityDialog extends StatelessWidget {
  const _ActivityDialog();

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final app = context.watch<AppState>();
    return AlertDialog(
      backgroundColor: c.secondary,
      title: Row(children: [
        Expanded(child: Text('Session Activity', style: TextStyle(color: c.textPrimary))),
        IconButton(
          tooltip: 'Refresh activity',
          onPressed: app.currentSessionId == null
              ? null
              : () => app.loadSessionActivity(app.currentSessionId!),
          icon: const Icon(Icons.refresh),
        ),
      ]),
      content: SizedBox(
        width: 720,
        height: 520,
        child: DefaultTabController(
          length: 3,
          child: Column(children: [
            const TabBar(tabs: [Tab(text: 'Runs'), Tab(text: 'Capabilities'), Tab(text: 'Sub-agents')]),
            Expanded(child: TabBarView(children: [
              _EventList(events: app.sessionRunEvents),
              _EventList(events: app.sessionCapabilityEvents),
              _SubAgentList(),
            ])),
          ]),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
    );
  }
}

class _EventList extends StatelessWidget {
  final List<Map<String, dynamic>> events;

  const _EventList({required this.events});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    if (events.isEmpty) return Center(child: Text('No events', style: TextStyle(color: c.textTertiary)));
    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (_, _) => Divider(color: c.separator, height: 1),
      itemBuilder: (_, index) {
        final event = events[events.length - 1 - index];
        final title = (event['eventType'] ?? event['type'] ?? event['status'] ?? 'event').toString();
        final detail = (event['data'] ?? event['message'] ?? '').toString();
        return ListTile(
          title: Text(title, style: TextStyle(color: c.textPrimary)),
          subtitle: Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.textSecondary, fontFamily: 'monospace')),
          trailing: Text((event['timestamp'] ?? '').toString(),
              style: TextStyle(color: c.textTertiary, fontSize: 11)),
        );
      },
    );
  }
}

class _SubAgentList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final app = context.watch<AppState>();
    if (app.subAgents.isEmpty) return Center(child: Text('No sub-agents', style: TextStyle(color: c.textTertiary)));
    return ListView.separated(
      itemCount: app.subAgents.length,
      separatorBuilder: (_, _) => Divider(color: c.separator, height: 1),
      itemBuilder: (_, index) {
        final agent = app.subAgents[index];
        final id = (agent['id'] ?? '').toString();
        return ListTile(
          leading: Icon(Icons.smart_toy_outlined, color: c.accent),
          title: Text((agent['name'] ?? agent['title'] ?? id).toString(),
              style: TextStyle(color: c.textPrimary)),
          subtitle: Text((agent['status'] ?? '').toString(), style: TextStyle(color: c.textSecondary)),
          trailing: IconButton(
            tooltip: 'Load transcript',
            onPressed: id.isEmpty ? null : () => _openTranscript(context, id),
            icon: const Icon(Icons.article_outlined),
          ),
        );
      },
    );
  }

  Future<void> _openTranscript(BuildContext context, String id) async {
    final app = context.read<AppState>();
    await app.loadSubAgentMessages(id);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(value: app, child: _TranscriptDialog(agentId: id)),
    );
  }
}

class _TranscriptDialog extends StatelessWidget {
  final String agentId;

  const _TranscriptDialog({required this.agentId});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final messages = context.watch<AppState>().subAgentMessages[agentId] ?? [];
    return AlertDialog(
      backgroundColor: c.secondary,
      title: Text('Sub-agent Transcript', style: TextStyle(color: c.textPrimary)),
      content: SizedBox(
        width: 650,
        height: 420,
        child: ListView.builder(
          itemCount: messages.length,
          itemBuilder: (_, index) {
            final message = messages[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SelectableText('${message.role.name}: ${message.content}',
                  style: TextStyle(color: c.textPrimary)),
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
    );
  }
}

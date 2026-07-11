import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

/// Cron management page: create, list, enable/disable, delete scheduled tasks.
class CronPage extends StatefulWidget {
  const CronPage({super.key});

  @override
  State<CronPage> createState() => _CronPageState();
}

class _CronPageState extends State<CronPage> {
  final _nameCtrl = TextEditingController();
  final _promptCtrl = TextEditingController();
  final _scheduleCtrl = TextEditingController();
  bool _oneshot = false;
  String _mode = 'yolo';

  @override
  void initState() {
    super.initState();
    // Load cron info on first build if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final app = context.read<AppState>();
        final sessionId = app.currentSessionId;
        if (sessionId != null && app.cronInfo == null) {
          app.loadCronForSession(sessionId);
        }
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _promptCtrl.dispose();
    _scheduleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final app = context.watch<AppState>();
    final cron = app.cronInfo;
    final enabled = cron?.enabled ?? true;
    final sessionId = app.currentSessionId ?? '';

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
                Icon(Icons.schedule, size: 22, color: c.accent),
                const SizedBox(width: 10),
                Text(
                  'Cron Tasks',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (enabled ? c.accentGreen : c.textTertiary)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    enabled
                        ? (cron?.running == true ? 'Running' : 'Idle')
                        : 'Disabled',
                    style: TextStyle(
                      color: enabled ? c.accentGreen : c.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => app.refreshCronInfo(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.textSecondary,
                    side: BorderSide(color: c.separator),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // New task form
                _CronFormCard(
                  nameCtrl: _nameCtrl,
                  promptCtrl: _promptCtrl,
                  scheduleCtrl: _scheduleCtrl,
                  oneshot: _oneshot,
                  mode: _mode,
                  enabled: enabled && sessionId.isNotEmpty,
                  onOneshotChanged: (v) => setState(() => _oneshot = v),
                  onModeChanged: (v) => setState(() => _mode = v),
                  onCreate: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (_nameCtrl.text.trim().isEmpty ||
                        _promptCtrl.text.trim().isEmpty) {
                      return;
                    }
                    if (sessionId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Select a session first')),
                      );
                      return;
                    }
                    await app.createCronJob(
                      sessionId: sessionId,
                      name: _nameCtrl.text.trim(),
                      prompt: _promptCtrl.text.trim(),
                      schedule: _scheduleCtrl.text.trim(),
                      oneshot: _oneshot,
                      mode: _mode,
                    );
                    if (!mounted) return;
                    _nameCtrl.clear();
                    _promptCtrl.clear();
                    _scheduleCtrl.clear();
                    setState(() {
                      _oneshot = false;
                      _mode = 'yolo';
                    });
                    await app.refreshCronInfo();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Cron task created')),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Cron job list
                _CronJobList(
                  jobs: cron?.jobs ?? [],
                  enabled: enabled,
                  onToggle: (jobId, enabled) {
                    app.toggleCronJob(jobId, enabled);
                    app.refreshCronInfo();
                  },
                  onDelete: (jobId) async {
                    await app.deleteCronJob(jobId);
                    app.refreshCronInfo();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CronFormCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController promptCtrl;
  final TextEditingController scheduleCtrl;
  final bool oneshot;
  final String mode;
  final bool enabled;
  final ValueChanged<bool> onOneshotChanged;
  final ValueChanged<String> onModeChanged;
  final VoidCallback onCreate;

  const _CronFormCard({
    required this.nameCtrl,
    required this.promptCtrl,
    required this.scheduleCtrl,
    required this.oneshot,
    required this.mode,
    required this.enabled,
    required this.onOneshotChanged,
    required this.onModeChanged,
    required this.onCreate,
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
          Text(
            'New Scheduled Task',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Name
          _FormTextField(
            controller: nameCtrl,
            label: 'Name',
            hint: 'e.g. Daily code review',
            enabled: enabled,
          ),
          const SizedBox(height: 10),

          // Schedule
          _FormTextField(
            controller: scheduleCtrl,
            label: 'Schedule (cron expression)',
            hint: oneshot ? 'Not needed for one-shot' : 'e.g. 0 9 * * *',
            enabled: enabled && !oneshot,
          ),
          const SizedBox(height: 10),

          // Mode + Oneshot row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mode',
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: mode,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: c.primary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: c.separator),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'yolo', child: Text('Yolo')),
                        DropdownMenuItem(
                            value: 'agent', child: Text('Agent')),
                      ],
                      onChanged: enabled ? (v) { if (v != null) onModeChanged(v); } : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: oneshot,
                      onChanged: enabled
                          ? (v) => onOneshotChanged(v ?? false)
                          : null,
                      activeColor: c.accent,
                    ),
                    Text(
                      'One-shot',
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Prompt
          Text(
            'Prompt',
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: promptCtrl,
            enabled: enabled,
            maxLines: 4,
            style: TextStyle(color: c.textPrimary),
            decoration: InputDecoration(
              hintText: 'What should the agent do...',
              hintStyle: TextStyle(color: c.textTertiary),
              filled: true,
              fillColor: c.primary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.separator),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.separator),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.accent),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),

          // Create button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: enabled ? onCreate : null,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Task'),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool enabled;

  const _FormTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: c.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: enabled,
          style: TextStyle(color: c.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: c.textTertiary),
            filled: true,
            fillColor: c.primary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: c.separator),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: c.separator),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: c.accent),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }
}

class _CronJobList extends StatelessWidget {
  final List<CronJobInfo> jobs;
  final bool enabled;
  final void Function(String jobId, bool enabled) onToggle;
  final void Function(String jobId) onDelete;

  const _CronJobList({
    required this.jobs,
    required this.enabled,
    required this.onToggle,
    required this.onDelete,
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
              Text(
                'Scheduled Tasks',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${jobs.length} items',
                style: TextStyle(color: c.textTertiary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (jobs.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy_outlined,
                      size: 40, color: c.textTertiary),
                  const SizedBox(height: 8),
                  Text(
                    'No scheduled tasks yet',
                    style: TextStyle(color: c.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create a task above to get started',
                    style: TextStyle(color: c.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ...jobs.map((job) => _CronJobRow(
                  job: job,
                  onToggle: () => onToggle(job.id, !job.enabled),
                  onDelete: () => onDelete(job.id),
                )),
        ],
      ),
    );
  }
}

class _CronJobRow extends StatelessWidget {
  final CronJobInfo job;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _CronJobRow({
    required this.job,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.separator),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.name,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (job.enabled ? c.accentGreen : c.textTertiary)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    job.enabled ? 'Active' : 'Disabled',
                    style: TextStyle(
                      color: job.enabled ? c.accentGreen : c.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    job.schedule.isEmpty ? 'One-shot' : job.schedule,
                    style: TextStyle(
                      color: c.accent,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.tertiary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    job.mode ?? '',
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Run ${job.runCount} time${job.runCount == 1 ? '' : 's'}',
                  style: TextStyle(color: c.textTertiary, fontSize: 11),
                ),
                const Spacer(),
                if (job.lastError != null && job.lastError!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      job.lastError!,
                      style: TextStyle(
                        color: c.accentRed,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    job.enabled ? Icons.pause : Icons.play_arrow,
                    size: 18,
                    color: c.textSecondary,
                  ),
                  onPressed: onToggle,
                  tooltip: job.enabled ? 'Disable' : 'Enable',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: c.accentRed),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            if (job.nextRun != null) ...[
              const SizedBox(height: 4),
              Text(
                'Next run: ${job.nextRun}',
                style: TextStyle(color: c.textTertiary, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

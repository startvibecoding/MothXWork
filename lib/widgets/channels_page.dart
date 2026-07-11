import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme/app_theme.dart';

class ChannelsPage extends StatefulWidget {
  const ChannelsPage({super.key});

  @override
  State<ChannelsPage> createState() => _ChannelsPageState();
}

class _ChannelsPageState extends State<ChannelsPage> {
  Map<String, dynamic>? _wechatLogin;
  Timer? _poller;
  bool _loadingLogin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshChannels();
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _startWechat(AppState app) async {
    setState(() => _loadingLogin = true);
    final status = await app.startWechatLogin();
    if (!mounted) return;
    setState(() {
      _wechatLogin = status;
      _loadingLogin = false;
    });
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 2), (_) => _pollWechat(app));
  }

  Future<void> _pollWechat(AppState app) async {
    final status = await app.refreshWechatLogin();
    if (!mounted || status == null) return;
    setState(() => _wechatLogin = status);
    final state = status['state']?.toString();
    if (state == 'confirmed' || state == 'error' || state == 'cancelled') {
      _poller?.cancel();
      await app.refreshChannels();
    }
  }

  Future<void> _cancelWechat(AppState app) async {
    _poller?.cancel();
    await app.cancelWechatLogin();
    if (mounted) setState(() => _wechatLogin = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final app = context.watch<AppState>();
    final state = _wechatLogin?['state']?.toString() ?? 'idle';
    final qrUrl = _wechatLogin?['qrUrl']?.toString();
    final activeLogin = !{'idle', 'confirmed', 'error', 'cancelled'}.contains(state);

    return Container(
      color: c.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(children: [
            Icon(Icons.forum_outlined, color: c.accent, size: 22),
            const SizedBox(width: 10),
            Text('Channels', style: TextStyle(color: c.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(
              tooltip: 'Refresh channels',
              onPressed: app.refreshChannels,
              icon: Icon(Icons.refresh, color: c.textSecondary),
            ),
          ]),
          const SizedBox(height: 18),
          if (app.channels.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Center(child: Text('No messaging channels configured.',
                  style: TextStyle(color: c.textSecondary))),
            )
          else
            ...app.channels.map((channel) => _ChannelRow(channel: channel)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.secondary,
              border: Border.all(color: c.separator),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('WeChat Login', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('State: $state', style: TextStyle(color: c.textSecondary, fontSize: 13)),
              if ((_wechatLogin?['error'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_wechatLogin!['error'].toString(), style: TextStyle(color: c.accentRed)),
              ],
              if (qrUrl != null && qrUrl.isNotEmpty) ...[
                const SizedBox(height: 14),
                Image.network(
                  '${app.serveUrl}$qrUrl',
                  headers: app.serveAuthToken.isEmpty ? null : {'Authorization': 'Bearer ${app.serveAuthToken}'},
                  width: 220,
                  height: 220,
                  errorBuilder: (_, _, _) => Text('QR code is available at $qrUrl',
                      style: TextStyle(color: c.textSecondary)),
                ),
              ],
              const SizedBox(height: 12),
              Row(children: [
                FilledButton.icon(
                  onPressed: _loadingLogin || activeLogin ? null : () => _startWechat(app),
                  icon: const Icon(Icons.qr_code_2),
                  label: Text(_loadingLogin ? 'Starting...' : 'Start Login'),
                ),
                if (activeLogin) ...[
                  const SizedBox(width: 8),
                  TextButton(onPressed: () => _cancelWechat(app), child: const Text('Cancel')),
                ],
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  final Map<String, dynamic> channel;

  const _ChannelRow({required this.channel});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final enabled = channel['enabled'] == true;
    final connected = channel['connected'] == true;
    final color = connected ? c.accentGreen : enabled ? c.accentOrange : c.textTertiary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: c.secondary,
        border: Border.all(color: c.separator),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(connected ? Icons.check_circle : Icons.circle_outlined, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text((channel['name'] ?? 'channel').toString(),
            style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w500))),
        Text(connected ? 'Connected' : enabled ? 'Enabled' : 'Disabled',
            style: TextStyle(color: color, fontSize: 12)),
      ]),
    );
  }
}

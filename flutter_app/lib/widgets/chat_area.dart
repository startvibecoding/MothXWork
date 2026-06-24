import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class ChatArea extends StatefulWidget {
  const ChatArea({super.key});

  @override
  State<ChatArea> createState() => _ChatAreaState();
}

class _ChatAreaState extends State<ChatArea> {
  final ScrollController _scroll = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final app = context.watch<AppState>();
    final messages = app.messages;

    _scrollToBottom();

    return Container(
      color: c.primary,
      child: messages.isEmpty
          ? _EmptyState(loading: app.isLoading)
          : ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(24),
              itemCount: messages.length +
                  (app.isLoading && !messages.any((m) => m.isStreaming)
                      ? 1
                      : 0),
              itemBuilder: (context, index) {
                if (index >= messages.length) {
                  return const _TypingIndicator();
                }
                return _MessageBubble(message: messages[index]);
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool loading;
  const _EmptyState({required this.loading});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.bolt, size: 56, color: c.accent),
          ),
          const SizedBox(height: 16),
          Text('VibeCoding GUI',
              style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Start a conversation to begin coding with AI',
              style: TextStyle(color: c.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final isUser = message.role == MessageRole.user;
    final isSystem = message.role == MessageRole.system;

    final Color bg;
    final Color fg;
    if (isUser) {
      bg = c.accent;
      fg = Colors.white;
    } else if (isSystem) {
      bg = c.accentOrange.withValues(alpha: 0.2);
      fg = c.accentOrange;
    } else {
      bg = c.secondary;
      fg = c.textPrimary;
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: isSystem
              ? Border.all(color: c.accentOrange.withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isUser)
              SelectableText(message.content,
                  style: TextStyle(color: fg, fontSize: 15))
            else
              MarkdownBody(
                data: message.content.isEmpty ? '...' : message.content,
                selectable: true,
                styleSheet: _markdownStyle(context, fg),
              ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: TextStyle(
                      fontSize: 11,
                      color: isUser ? Colors.white70 : c.textTertiary),
                ),
                if (message.isStreaming) ...[
                  const SizedBox(width: 8),
                  _PulsingDot(color: isUser ? Colors.white70 : c.textTertiary),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  MarkdownStyleSheet _markdownStyle(BuildContext context, Color fg) {
    final c = AppTheme.of(context);
    return MarkdownStyleSheet(
      p: TextStyle(color: fg, fontSize: 14, height: 1.6),
      code: TextStyle(
        backgroundColor: c.tertiary,
        fontFamily: 'monospace',
        fontSize: 13,
        color: fg,
      ),
      codeblockDecoration: BoxDecoration(
        color: c.tertiary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.separator),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      h1: TextStyle(color: fg, fontSize: 22, fontWeight: FontWeight.w600),
      h2: TextStyle(color: fg, fontSize: 19, fontWeight: FontWeight.w600),
      h3: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w600),
      listBullet: TextStyle(color: fg, fontSize: 14),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: c.accent, width: 4)),
      ),
      a: TextStyle(color: c.accent),
      tableBorder: TableBorder.all(color: c.separator),
      tableHead: TextStyle(color: fg, fontWeight: FontWeight.w600),
      tableBody: TextStyle(color: fg),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Text('●', style: TextStyle(color: widget.color, fontSize: 10)),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.secondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _PulsingDot(color: c.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme/app_theme.dart';

class InputArea extends StatefulWidget {
  const InputArea({super.key});

  @override
  State<InputArea> createState() => _InputAreaState();
}

class _InputAreaState extends State<InputArea> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send(AppState app) {
    final text = _controller.text;
    if (text.trim().isEmpty || app.isLoading) return;
    _controller.clear();
    app.sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final app = context.watch<AppState>();
    final cwd = app.runtimeConfig.cwd;
    final canSend = !app.isLoading && app.currentSessionId != null;

    return Container(
      decoration: BoxDecoration(
        color: c.primary,
        border: Border(top: BorderSide(color: c.separator)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: c.secondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.separator),
                  ),
                  child: KeyboardListener(
                    focusNode: FocusNode(skipTraversal: true),
                    onKeyEvent: (event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter &&
                          !HardwareKeyboard.instance.isShiftPressed) {
                        _send(app);
                      }
                    },
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      enabled: !app.isLoading && app.currentSessionId != null,
                      minLines: 2,
                      maxLines: 6,
                      style: TextStyle(color: c.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: app.currentSessionId == null
                            ? 'Connecting/No Session...'
                            : 'Type your message...',
                        hintStyle: TextStyle(color: c.textTertiary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              app.isLoading
                  ? _ActionButton(
                      color: c.accentRed,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stop, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text('Stop',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                      onPressed: () => app.abort(),
                    )
                  : _ActionButton(
                      color: canSend ? c.accent : c.tertiary,
                      onPressed: canSend ? () => _send(app) : null,
                      child: Icon(Icons.send,
                          color: canSend ? Colors.white : c.textTertiary,
                          size: 20),
                    ),
            ],
          ),
          if (cwd.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Row(
                children: [
                  Icon(Icons.folder_outlined,
                      size: 14, color: c.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(cwd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(color: c.textTertiary, fontSize: 12)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Color color;
  final Widget child;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.color,
    required this.child,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

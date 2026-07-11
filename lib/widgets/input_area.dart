import 'dart:convert';

import 'package:file_picker/file_picker.dart';
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
  final List<_ImageAttachment> _images = [];

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send(AppState app) {
    final text = _controller.text;
    if ((text.trim().isEmpty && _images.isEmpty) || app.isLoading) return;
    final imageParts = _images
        .map((image) => {
              'type': 'image_url',
              'image_url': {'url': image.dataUrl, 'detail': 'auto'},
            })
        .toList();
    _controller.clear();
    setState(() => _images.clear());
    app.sendMessage(text, imageParts: imageParts);
  }

  Future<void> _pickImages(AppState app) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (!mounted || result == null) return;
    final selected = <_ImageAttachment>[];
    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null) continue;
      selected.add(_ImageAttachment(
        name: file.name,
        dataUrl: 'data:${_mimeType(file.extension)};base64,${base64Encode(bytes)}',
      ));
    }
    if (selected.isEmpty) {
      app.reportError('Unable to read selected image files.');
      return;
    }
    setState(() => _images.addAll(selected.take(6 - _images.length)));
  }

  String _mimeType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final app = context.watch<AppState>();
    final cwd = app.runtimeConfig.cwd;
    final canSend = !app.isLoading && app.isConnected;

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
                      enabled: canSend,
                      minLines: 2,
                      maxLines: 6,
                      style: TextStyle(color: c.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: !canSend
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
              IconButton(
                tooltip: 'Attach images',
                onPressed: canSend && _images.length < 6
                    ? () => _pickImages(app)
                    : null,
                icon: Icon(Icons.attach_file,
                    color: canSend ? c.textSecondary : c.textTertiary),
              ),
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
          if (_images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _images.asMap().entries.map((entry) => Chip(
                  avatar: const Icon(Icons.image_outlined, size: 16),
                  label: Text(entry.value.name, overflow: TextOverflow.ellipsis),
                  onDeleted: () => setState(() => _images.removeAt(entry.key)),
                )).toList(),
              ),
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

class _ImageAttachment {
  final String name;
  final String dataUrl;

  const _ImageAttachment({required this.name, required this.dataUrl});
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

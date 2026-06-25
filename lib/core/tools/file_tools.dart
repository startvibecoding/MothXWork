import 'dart:io';
import 'package:path/path.dart' as p;
import 'registry.dart';

class ReadTool extends DeveloperTool {
  @override
  String get name => 'read';

  @override
  String get description => 'Read the contents of a file.';

  @override
  Map<String, dynamic> get parameters => {
    'type': 'object',
    'properties': {
      'path': {
        'type': 'string',
        'description': 'Path to the file to read (can be absolute or relative to working directory)',
      },
    },
    'required': ['path'],
  };

  @override
  Future<String> execute(String cwd, Map<String, dynamic> arguments) async {
    final rawPath = arguments['path']?.toString() ?? '';
    final fullPath = p.isAbsolute(rawPath) ? rawPath : p.normalize(p.join(cwd, rawPath));
    final file = File(fullPath);
    if (!await file.exists()) {
      return 'Error: File does not exist at $fullPath';
    }
    try {
      return await file.readAsString();
    } catch (e) {
      return 'Error reading file: $e';
    }
  }
}

class WriteTool extends DeveloperTool {
  @override
  String get name => 'write';

  @override
  String get description => 'Write content to a file. Creates the file if it does not exist, overwrites if it does.';

  @override
  Map<String, dynamic> get parameters => {
    'type': 'object',
    'properties': {
      'path': {
        'type': 'string',
        'description': 'Path to the file to write',
      },
      'content': {
        'type': 'string',
        'description': 'Content to write to the file',
      },
    },
    'required': ['path', 'content'],
  };

  @override
  Future<String> execute(String cwd, Map<String, dynamic> arguments) async {
    final rawPath = arguments['path']?.toString() ?? '';
    final content = arguments['content']?.toString() ?? '';
    final fullPath = p.isAbsolute(rawPath) ? rawPath : p.normalize(p.join(cwd, rawPath));
    final file = File(fullPath);
    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
      return 'Success: File written to $fullPath';
    } catch (e) {
      return 'Error writing file: $e';
    }
  }
}

class EditTool extends DeveloperTool {
  @override
  String get name => 'edit';

  @override
  String get description => 'Edit a file using exact text replacement.';

  @override
  Map<String, dynamic> get parameters => {
    'type': 'object',
    'properties': {
      'path': {
        'type': 'string',
        'description': 'Path to the file to edit',
      },
      'edits': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'oldText': {
              'type': 'string',
              'description': 'Exact old text block to find',
            },
            'newText': {
              'type': 'string',
              'description': 'New text block to replace it with',
            },
          },
          'required': ['oldText', 'newText'],
        },
      },
    },
    'required': ['path', 'edits'],
  };

  @override
  Future<String> execute(String cwd, Map<String, dynamic> arguments) async {
    final rawPath = arguments['path']?.toString() ?? '';
    final fullPath = p.isAbsolute(rawPath) ? rawPath : p.normalize(p.join(cwd, rawPath));
    final file = File(fullPath);
    if (!await file.exists()) {
      return 'Error: File does not exist at $fullPath';
    }
    final editsList = arguments['edits'] as List?;
    if (editsList == null || editsList.isEmpty) {
      return 'Error: No edits provided';
    }

    try {
      var content = await file.readAsString();
      for (var edit in editsList) {
        if (edit is! Map) continue;
        final oldText = (edit['oldText'] ?? '').toString();
        final newText = (edit['newText'] ?? '').toString();
        if (oldText.isEmpty) continue;
        if (!content.contains(oldText)) {
          return 'Error: Could not find exact match for "oldText" block in the file.';
        }
        content = content.replaceFirst(oldText, newText);
      }
      await file.writeAsString(content);
      return 'Success: File $fullPath edited successfully.';
    } catch (e) {
      return 'Error editing file: $e';
    }
  }
}

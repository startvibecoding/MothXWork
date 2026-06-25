import 'dart:io';
import 'package:path/path.dart' as p;
import 'registry.dart';

class LsTool extends DeveloperTool {
  @override
  String get name => 'ls';

  @override
  String get description => 'List directory contents with details (sizes, types, etc.)';

  @override
  Map<String, dynamic> get parameters => {
    'type': 'object',
    'properties': {
      'path': {
        'type': 'string',
        'description': 'Directory to list (defaults to current directory if not specified)',
      },
    },
  };

  @override
  Future<String> execute(String cwd, Map<String, dynamic> arguments) async {
    final rawPath = arguments['path']?.toString() ?? '.';
    final fullPath = p.isAbsolute(rawPath) ? rawPath : p.normalize(p.join(cwd, rawPath));
    final dir = Directory(fullPath);
    if (!await dir.exists()) {
      return 'Error: Directory does not exist at $fullPath';
    }
    try {
      final buffer = StringBuffer();
      buffer.writeln('Contents of $fullPath:');
      final entities = await dir.list().toList();
      entities.sort((a, b) => a.path.compareTo(b.path));
      for (var e in entities) {
        final name = p.basename(e.path);
        if (e is Directory) {
          buffer.writeln('[DIR]  $name/');
        } else if (e is File) {
          final size = await e.length();
          buffer.writeln('[FILE] $name ($size bytes)');
        } else {
          buffer.writeln('[LINK] $name');
        }
      }
      return buffer.toString();
    } catch (e) {
      return 'Error listing directory: $e';
    }
  }
}

class FindTool extends DeveloperTool {
  @override
  String get name => 'find';

  @override
  String get description => 'Search for files by name pattern.';

  @override
  Map<String, dynamic> get parameters => {
    'type': 'object',
    'properties': {
      'pattern': {
        'type': 'string',
        'description': 'Glob or name pattern to search for (e.g. "*.dart")',
      },
    },
    'required': ['pattern'],
  };

  @override
  Future<String> execute(String cwd, Map<String, dynamic> arguments) async {
    final pattern = arguments['pattern']?.toString() ?? '';
    final dir = Directory(cwd);
    try {
      final results = <String>[];
      final regexStr = pattern.replaceAll('.', '\\.').replaceAll('*', '.*');
      final regex = RegExp('^$regexStr\$', caseSensitive: false);

      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final fileName = p.basename(entity.path);
          if (regex.hasMatch(fileName)) {
            results.add(p.relative(entity.path, from: cwd));
          }
        }
      }
      results.sort();
      if (results.isEmpty) {
        return 'No files found matching "$pattern" in $cwd';
      }
      return results.join('\n');
    } catch (e) {
      return 'Error searching files: $e';
    }
  }
}

class GrepTool extends DeveloperTool {
  @override
  String get name => 'grep';

  @override
  String get description => 'Search file contents using regex patterns.';

  @override
  Map<String, dynamic> get parameters => {
    'type': 'object',
    'properties': {
      'pattern': {
        'type': 'string',
        'description': 'Regex pattern to search for',
      },
    },
    'required': ['pattern'],
  };

  @override
  Future<String> execute(String cwd, Map<String, dynamic> arguments) async {
    final pattern = arguments['pattern']?.toString() ?? '';
    final dir = Directory(cwd);
    try {
      final regex = RegExp(pattern);
      final results = <String>[];

      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          if (entity.path.contains('/.git/') || entity.path.contains('/.dart_tool/')) {
            continue;
          }
          try {
            final content = await entity.readAsString();
            final lines = content.split('\n');
            for (var i = 0; i < lines.length; i++) {
              if (regex.hasMatch(lines[i])) {
                final relPath = p.relative(entity.path, from: cwd);
                results.add('$relPath:${i + 1}:${lines[i].trim()}');
              }
            }
          } catch (_) {}
        }
      }
      results.sort();
      if (results.isEmpty) {
        return 'No matches found for regex "$pattern" in $cwd';
      }
      return results.join('\n');
    } catch (e) {
      return 'Error grepping files: $e';
    }
  }
}

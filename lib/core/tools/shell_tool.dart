import 'dart:convert';
import 'dart:io';
import 'registry.dart';

class BashTool extends DeveloperTool {
  @override
  String get name => 'bash';

  @override
  String get description => 'Execute a bash command in the current workspace.';

  @override
  Map<String, dynamic> get parameters => {
    'type': 'object',
    'properties': {
      'command': {
        'type': 'string',
        'description': 'The bash shell command to execute',
      },
    },
    'required': ['command'],
  };

  @override
  Future<String> execute(String cwd, Map<String, dynamic> arguments) async {
    final command = arguments['command']?.toString() ?? '';
    if (command.isEmpty) {
      return 'Error: Empty command';
    }

    try {
      final result = await Process.run(
        'bash',
        ['-c', command],
        workingDirectory: cwd,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      final buffer = StringBuffer();
      if (result.stdout.toString().isNotEmpty) {
        buffer.write(result.stdout.toString().trim());
      }
      if (result.stderr.toString().isNotEmpty) {
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.writeln('STDERR:');
        buffer.write(result.stderr.toString().trim());
      }
      if (buffer.isEmpty && result.exitCode == 0) {
        return 'Command executed successfully with exit code 0 (no output).';
      }
      return buffer.toString();
    } catch (e) {
      return 'Error executing shell command: $e';
    }
  }
}

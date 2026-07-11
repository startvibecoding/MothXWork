import 'package:flutter_test/flutter_test.dart';
import 'package:mothx_gui/models/models.dart';

void main() {
  group('ChatMessage', () {
    test('parses OpenAI-style assistant content', () {
      final message = ChatMessage.fromJson({
        'id': 'message-1',
        'role': 'assistant',
        'content': 'Hello from mothx serve',
        'timestamp': '2026-07-12T12:00:00Z',
      });

      expect(message.id, 'message-1');
      expect(message.role, MessageRole.assistant);
      expect(message.content, 'Hello from mothx serve');
      expect(message.timestamp.toUtc(), DateTime.utc(2026, 7, 12, 12));
    });

    test('uses text content blocks when content is absent', () {
      final message = ChatMessage.fromJson({
        'id': 'message-2',
        'role': 'user',
        'contents': [
          {'type': 'text', 'text': 'First'},
          {'type': 'thinking', 'thinking': 'Second'},
        ],
      });

      expect(message.content, 'First\nSecond');
      expect(message.role, MessageRole.user);
    });
  });

  group('Serve payload models', () {
    test('parses cron jobs returned by mothx serve', () {
      final cron = CronInfo.fromJson({
        'enabled': true,
        'running': true,
        'jobs': [
          {
            'id': 'job-1',
            'name': 'Daily review',
            'schedule': '0 9 * * *',
            'enabled': false,
            'runCount': 4,
          },
        ],
      });

      expect(cron.running, isTrue);
      expect(cron.jobs, hasLength(1));
      expect(cron.jobs.single.enabled, isFalse);
      expect(cron.jobs.single.runCount, 4);
    });

    test('parses usage summary and breakdowns', () {
      final summary = StatsSummary.fromJson({
        'totalRequests': 3,
        'inputTokens': 100,
        'outputTokens': 50,
        'totalTokens': 150,
        'byProvider': [
          {'provider': 'openai', 'requests': 3, 'tokens': 150},
        ],
        'byModel': [
          {'model': 'gpt-test', 'requests': 3, 'tokens': 150},
        ],
      });

      expect(summary.totalTokens, 150);
      expect(summary.byProvider?.single.provider, 'openai');
      expect(summary.byModel?.single.model, 'gpt-test');
    });
  });
}

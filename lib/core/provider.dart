import 'dart:convert';
import 'dart:io';
import '../models/models.dart';
import 'settings.dart';

class LLMStreamEvent {
  final String textDelta;
  final String thinkDelta;
  final String? toolCallId;
  final String? toolName;
  final String? toolArgsDelta;
  final bool isDone;
  final String? error;

  LLMStreamEvent({
    this.textDelta = '',
    this.thinkDelta = '',
    this.toolCallId,
    this.toolName,
    this.toolArgsDelta,
    this.isDone = false,
    this.error,
  });
}

class LLMProviderClient {
  final ProviderConfig provider;
  final ModelConfig model;

  LLMProviderClient({required this.provider, required this.model});

  Stream<LLMStreamEvent> chat(
      List<ChatMessage> history, List<Map<String, dynamic>> tools, String systemPrompt) async* {
    final client = HttpClient();

    if (provider.httpProxy.isNotEmpty) {
      try {
        final proxyUri = Uri.parse(provider.httpProxy);
        client.findProxy = (uri) {
          return "PROXY ${proxyUri.host}:${proxyUri.port}";
        };
      } catch (_) {}
    }

    try {
      if (provider.api == 'openai-chat') {
        final url = Uri.parse('${provider.baseUrl}/chat/completions');
        final request = await client.postUrl(url);

        request.headers.set('Content-Type', 'application/json');
        request.headers.set('Authorization', 'Bearer ${provider.apiKey}');

        final messagesPayload = <Map<String, dynamic>>[];
        messagesPayload.add({'role': 'system', 'content': systemPrompt});
        for (var msg in history) {
          messagesPayload.add({
            'role': msg.role == MessageRole.user ? 'user' : 'assistant',
            'content': msg.content,
          });
        }

        final body = {
          'model': model.id,
          'messages': messagesPayload,
          'stream': true,
        };
        if (tools.isNotEmpty) {
          body['tools'] = tools.map((t) => {
            'type': 'function',
            'function': t,
          }).toList();
        }

        request.add(utf8.encode(jsonEncode(body)));
        final response = await request.close();

        if (response.statusCode != 200) {
          final errBody = await response.transform(utf8.decoder).join();
          yield LLMStreamEvent(error: 'LLM Error (${response.statusCode}): $errBody', isDone: true);
          client.close();
          return;
        }

        final lines = response.transform(utf8.decoder).transform(const LineSplitter());
        String currentToolCallId = '';
        String currentToolName = '';

        await for (var line in lines) {
          if (line.startsWith('data: ')) {
            final dataStr = line.substring(6).trim();
            if (dataStr == '[DONE]') {
              yield LLMStreamEvent(isDone: true);
              break;
            }
            try {
              final json = jsonDecode(dataStr) as Map<String, dynamic>;
              final choice = (json['choices'] as List?)?.first;
              if (choice != null) {
                final delta = choice['delta'] as Map<String, dynamic>?;
                if (delta != null) {
                  final text = delta['content']?.toString() ?? '';
                  final think = delta['reasoning_content']?.toString() ?? '';

                  final toolCalls = delta['tool_calls'] as List?;
                  if (toolCalls != null && toolCalls.isNotEmpty) {
                    final tc = toolCalls.first as Map<String, dynamic>;
                    final tcId = tc['id']?.toString();
                    final tcFunc = tc['function'] as Map<String, dynamic>?;
                    final tcName = tcFunc?['name']?.toString();
                    final tcArgs = tcFunc?['arguments']?.toString();

                    if (tcId != null) currentToolCallId = tcId;
                    if (tcName != null) currentToolName = tcName;

                    yield LLMStreamEvent(
                      toolCallId: currentToolCallId,
                      toolName: currentToolName,
                      toolArgsDelta: tcArgs,
                    );
                  }

                  if (text.isNotEmpty || think.isNotEmpty) {
                    yield LLMStreamEvent(textDelta: text, thinkDelta: think);
                  }
                }
              }
            } catch (_) {}
          }
        }
      } else if (provider.api == 'anthropic-messages') {
        final url = Uri.parse('${provider.baseUrl}/v1/messages');
        final request = await client.postUrl(url);

        request.headers.set('Content-Type', 'application/json');
        request.headers.set('x-api-key', provider.apiKey);
        request.headers.set('anthropic-version', '2023-06-01');

        final messagesPayload = <Map<String, dynamic>>[];
        for (var msg in history) {
          messagesPayload.add({
            'role': msg.role == MessageRole.user ? 'user' : 'assistant',
            'content': msg.content,
          });
        }

        final body = {
          'model': model.id,
          'messages': messagesPayload,
          'system': systemPrompt,
          'stream': true,
          'max_tokens': model.maxTokens,
        };
        if (tools.isNotEmpty) {
          body['tools'] = tools.map((t) => {
            'name': t['name'],
            'description': t['description'],
            'input_schema': t['parameters'],
          }).toList();
        }

        request.add(utf8.encode(jsonEncode(body)));
        final response = await request.close();

        if (response.statusCode != 200) {
          final errBody = await response.transform(utf8.decoder).join();
          yield LLMStreamEvent(error: 'Anthropic Error (${response.statusCode}): $errBody', isDone: true);
          client.close();
          return;
        }

        final lines = response.transform(utf8.decoder).transform(const LineSplitter());
        String currentEvent = '';
        String currentToolCallId = '';
        String currentToolName = '';

        await for (var line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('event: ')) {
            currentEvent = trimmed.substring(7);
          } else if (trimmed.startsWith('data: ')) {
            final dataStr = trimmed.substring(6);
            try {
              final json = jsonDecode(dataStr) as Map<String, dynamic>;
              if (currentEvent == 'content_block_start') {
                final block = json['content_block'] as Map<String, dynamic>?;
                if (block?['type'] == 'tool_use') {
                  currentToolCallId = block?['id']?.toString() ?? '';
                  currentToolName = block?['name']?.toString() ?? '';
                  yield LLMStreamEvent(
                    toolCallId: currentToolCallId,
                    toolName: currentToolName,
                    toolArgsDelta: '',
                  );
                }
              } else if (currentEvent == 'content_block_delta') {
                final delta = json['delta'] as Map<String, dynamic>?;
                if (delta?['type'] == 'text_delta') {
                  yield LLMStreamEvent(textDelta: delta?['text']?.toString() ?? '');
                } else if (delta?['type'] == 'thinking_delta') {
                  yield LLMStreamEvent(thinkDelta: delta?['thinking']?.toString() ?? '');
                } else if (delta?['type'] == 'input_json_delta') {
                  yield LLMStreamEvent(
                    toolCallId: currentToolCallId,
                    toolName: currentToolName,
                    toolArgsDelta: delta?['partial_json']?.toString() ?? '',
                  );
                }
              } else if (currentEvent == 'message_stop') {
                yield LLMStreamEvent(isDone: true);
                break;
              }
            } catch (_) {}
          }
        }
      } else {
        yield LLMStreamEvent(error: 'Unsupported provider API Type: ${provider.api}', isDone: true);
      }
    } catch (e) {
      yield LLMStreamEvent(error: 'Network Error: $e', isDone: true);
    } finally {
      client.close();
    }
  }
}

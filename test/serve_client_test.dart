import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mothx_gui/services/serve_client.dart';

void main() {
  late HttpServer server;
  late ServeClient client;
  String memory = '# Initial memory';

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = ServeClient(baseUrl: 'http://${server.address.address}:${server.port}');
    server.listen((request) async {
      request.response.headers.contentType = ContentType.json;
      switch ('${request.method} ${request.uri.path}') {
        case 'GET /health':
          request.response.write('{"status":"ok"}');
        case 'GET /api/channels':
          request.response.write('[{"name":"wechat","enabled":true,"connected":false}]');
        case 'GET /api/memory':
          request.response.write(jsonEncode({'enabled': true, 'content': memory}));
        case 'PUT /api/memory':
          final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
          memory = body['content'].toString();
          request.response.write(jsonEncode({'enabled': true, 'content': memory}));
        case 'GET /api/browse':
          request.response.write(jsonEncode({
            'path': '/workspace',
            'parent': '/',
            'entries': [
              {'name': 'project', 'path': '/workspace/project', 'isDir': true},
            ],
          }));
        default:
          request.response.statusCode = HttpStatus.notFound;
          request.response.write('{"error":"not found"}');
      }
      await request.response.close();
    });
  });

  tearDown(() async {
    client.dispose();
    await server.close(force: true);
  });

  test('reads channels and browses remote directories', () async {
    expect(await client.ping(), isTrue);
    final channels = await client.getChannels();
    final browse = await client.browseDirectories(path: '/workspace');

    expect(channels.single['name'], 'wechat');
    expect(browse?['path'], '/workspace');
    expect((browse?['entries'] as List).single['path'], '/workspace/project');
  });

  test('reads and writes serve memory', () async {
    expect((await client.getMemory())?['content'], '# Initial memory');
    final saved = await client.saveMemory('# Updated memory');

    expect(saved?['content'], '# Updated memory');
    expect((await client.getMemory())?['content'], '# Updated memory');
  });
}

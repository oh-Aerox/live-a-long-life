import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/services/data_boundary.dart';
import 'package:live_a_long_life/services/model_client.dart';

ModelConfig _config({
  required ModelProtocol protocol,
  required String baseUrl,
}) =>
    ModelConfig(
      id: 'cfg-1',
      userId: 'u',
      createdAt: 0,
      createdOnDevice: 'd',
      version: 1,
      preset: protocol == ModelProtocol.anthropic
          ? ModelPreset.anthropic
          : ModelPreset.openaiCompatible,
      protocol: protocol,
      baseUrl: baseUrl,
      model: 'test-model',
      capabilities: '[]',
      dataBoundary: DataBoundary.device,
      keychainRef: 'ref',
      isDefault: true,
    );

void main() {
  group('ModelClient · openai_compatible 协议', () {
    late HttpServer server;
    late List<({String path, String auth, Map<String, Object?> body})> seen;
    // 为真时拒绝多模态输入（content 是数组的请求），模拟纯文本模型。
    var rejectImages = false;

    setUp(() async {
      seen = [];
      rejectImages = false;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        final body = jsonDecode(await utf8.decoder.bind(req).join())
            as Map<String, Object?>;
        seen.add((
          path: req.uri.path,
          auth: req.headers.value('authorization') ?? '',
          body: body,
        ));
        final content =
            ((body['messages'] as List).first as Map)['content'];
        if (req.headers.value('authorization') != 'Bearer good-key') {
          req.response.statusCode = 401;
          req.response
              .write(jsonEncode({'error': {'message': 'invalid api key'}}));
        } else if (rejectImages && content is List) {
          req.response.statusCode = 400;
          req.response.write(
              jsonEncode({'error': {'message': 'image input not supported'}}));
        } else {
          req.response.write(jsonEncode({
            'choices': [
              {'message': {'role': 'assistant', 'content': 'OK'}},
            ],
            'usage': {'prompt_tokens': 5, 'completion_tokens': 2},
          }));
        }
        await req.response.close();
      });
    });

    tearDown(() => server.close(force: true));

    String base() => 'http://127.0.0.1:${server.port}/v1';

    test('请求打到 {base}/chat/completions，Bearer 认证，返回文本和用量', () async {
      final resp = await ModelClient().complete(
        config: _config(
            protocol: ModelProtocol.openaiCompatible, baseUrl: base()),
        apiKey: 'good-key',
        userText: 'ping',
      );
      expect(resp.text, 'OK');
      expect(resp.tokensIn, 5);
      expect(resp.tokensOut, 2);
      expect(seen.single.path, '/v1/chat/completions');
      expect(seen.single.auth, 'Bearer good-key');
      expect(seen.single.body['model'], 'test-model');
    });

    test('key 错误：不可重试的异常，带服务方错误信息', () async {
      await expectLater(
        ModelClient().complete(
          config: _config(
              protocol: ModelProtocol.openaiCompatible, baseUrl: base()),
          apiKey: 'bad-key',
          userText: 'ping',
        ),
        throwsA(isA<ModelClientException>()
            .having((e) => e.retriable, 'retriable', isFalse)
            .having((e) => e.message, 'message', contains('key 无效'))),
      );
    });

    test('testConnection：接受图片的服务标 text+image，失败时不抛异常', () async {
      final cfg = _config(
          protocol: ModelProtocol.openaiCompatible, baseUrl: base());
      final ok =
          await ModelClient().testConnection(config: cfg, apiKey: 'good-key');
      expect(ok.ok, isTrue);
      expect(ok.capabilities, ['text', 'image']);
      expect(ok.message, contains('支持图片'));
      // 两个请求：文本 + 图片探测。
      expect(seen, hasLength(2));

      final fail =
          await ModelClient().testConnection(config: cfg, apiKey: 'bad-key');
      expect(fail.ok, isFalse);
      expect(fail.message, contains('key 无效'));
    });

    test('testConnection：拒绝图片输入的纯文本模型只标 text（如 kimi）', () async {
      rejectImages = true;
      final cfg = _config(
          protocol: ModelProtocol.openaiCompatible, baseUrl: base());
      final result =
          await ModelClient().testConnection(config: cfg, apiKey: 'good-key');
      expect(result.ok, isTrue);
      expect(result.capabilities, ['text']);
      expect(result.message, contains('仅文本'));
    });

    test('HTTP 200 但返回非 JSON（中转站网关页）：错误信息带响应片段', () async {
      final gateway =
          await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      gateway.listen((req) async {
        await utf8.decoder.bind(req).join();
        req.response.headers.contentType = ContentType.html;
        req.response.write('<html><body>502 Bad Gateway 中转站维护中</body></html>');
        await req.response.close();
      });
      addTearDown(() => gateway.close(force: true));

      final result = await ModelClient().testConnection(
        config: _config(
            protocol: ModelProtocol.openaiCompatible,
            baseUrl: 'http://127.0.0.1:${gateway.port}/v1'),
        apiKey: 'k',
      );
      expect(result.ok, isFalse);
      // 片段能看出是网关页而非模型响应。
      expect(result.message, contains('Bad Gateway'));
      expect(result.message, contains('返回不是 JSON'));
    });

    test('服务不可达：可重试的网络错误（A-11 排队场景）', () async {
      final deadPort = server.port;
      await server.close(force: true);
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0); // 供 tearDown
      await expectLater(
        ModelClient().complete(
          config: _config(
              protocol: ModelProtocol.openaiCompatible,
              baseUrl: 'http://127.0.0.1:$deadPort/v1'),
          apiKey: 'good-key',
          userText: 'ping',
        ),
        throwsA(isA<ModelClientException>()
            .having((e) => e.retriable, 'retriable', isTrue)),
      );
    });
  });

  group('ModelClient · anthropic 协议', () {
    late HttpServer server;
    late List<({String path, String? key, String? version})> seen;

    setUp(() async {
      seen = [];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        await utf8.decoder.bind(req).join();
        seen.add((
          path: req.uri.path,
          key: req.headers.value('x-api-key'),
          version: req.headers.value('anthropic-version'),
        ));
        req.response.write(jsonEncode({
          'content': [
            {'type': 'text', 'text': 'OK'},
          ],
          'usage': {'input_tokens': 7, 'output_tokens': 3},
        }));
        await req.response.close();
      });
    });

    tearDown(() => server.close(force: true));

    test('请求打到 {base}/v1/messages，x-api-key 与版本头齐全', () async {
      final resp = await ModelClient().complete(
        config: _config(
            protocol: ModelProtocol.anthropic,
            baseUrl: 'http://127.0.0.1:${server.port}'),
        apiKey: 'sk-test',
        userText: 'ping',
      );
      expect(resp.text, 'OK');
      expect(resp.tokensIn, 7);
      expect(resp.tokensOut, 3);
      expect(seen.single.path, '/v1/messages');
      expect(seen.single.key, 'sk-test');
      expect(seen.single.version, ModelClient.anthropicVersion);
    });
  });

  group('数据边界推断（D-16、A-11）', () {
    test('本机、局域网、云端', () {
      expect(inferDataBoundary('http://localhost:11434/v1'),
          DataBoundary.device);
      expect(inferDataBoundary('http://127.0.0.1:11434/v1'),
          DataBoundary.device);
      expect(inferDataBoundary('http://mac.local:11434/v1'), DataBoundary.lan);
      expect(
          inferDataBoundary('http://192.168.1.5:11434/v1'), DataBoundary.lan);
      expect(inferDataBoundary('http://10.0.0.2/v1'), DataBoundary.lan);
      expect(inferDataBoundary('http://172.20.1.1/v1'), DataBoundary.lan);
      expect(inferDataBoundary('https://api.anthropic.com'),
          DataBoundary.cloud);
      expect(inferDataBoundary('https://api.deepseek.com/v1'),
          DataBoundary.cloud);
      // 172.32 不是私有段
      expect(
          inferDataBoundary('http://172.32.0.1/v1'), DataBoundary.cloud);
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:live_a_long_life/data/db/app_database.dart';
import 'package:live_a_long_life/services/data_boundary.dart';
import 'package:live_a_long_life/services/model_client.dart';
import 'package:live_a_long_life/services/tool_chat.dart';

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

    test('Kimi、智谱 GLM 预设：请求带上调低思考的参数，其他预设不带', () async {
      Future<Map<String, Object?>> send(ModelPreset preset) async {
        final c = _config(
            protocol: ModelProtocol.openaiCompatible, baseUrl: base());
        await ModelClient().complete(
            config: c.copyWith(preset: preset),
            apiKey: 'good-key',
            userText: 'hi');
        return seen.last.body;
      }

      expect((await send(ModelPreset.kimi))['reasoning_effort'], 'low');
      expect((await send(ModelPreset.glm))['thinking'], {'type': 'disabled'});
      final plain = await send(ModelPreset.openaiCompatible);
      expect(plain.containsKey('reasoning_effort'), isFalse);
      expect(plain.containsKey('thinking'), isFalse);
      expect(ModelPresetDefaults.byPreset[ModelPreset.kimi]!.baseUrl,
          'https://api.moonshot.cn/v1');
      expect(ModelPresetDefaults.byPreset[ModelPreset.glm]!.baseUrl,
          'https://open.bigmodel.cn/api/paas/v4');
    });

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

    test('带图片（识图兜底）：content 是文字 + data URL 图片；不带图片仍是纯文字', () async {
      final config =
          _config(protocol: ModelProtocol.openaiCompatible, baseUrl: base());
      await ModelClient().complete(
          config: config, apiKey: 'good-key', userText: '整理这张图',
          imagePngBase64: 'QUJD');
      final content =
          ((seen.single.body['messages'] as List).first as Map)['content'] as List;
      expect((content[0] as Map)['text'], '整理这张图');
      expect(((content[1] as Map)['image_url'] as Map)['url'],
          'data:image/png;base64,QUJD');

      await ModelClient()
          .complete(config: config, apiKey: 'good-key', userText: '纯文字');
      expect(((seen.last.body['messages'] as List).first as Map)['content'], '纯文字');
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

  group('ModelClient · 带工具的对话（D-43）', () {
    late HttpServer server;
    late List<Map<String, Object?>> bodies;
    late Object Function() respond;

    setUp(() async {
      bodies = [];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        bodies.add((jsonDecode(await utf8.decoder.bind(req).join()) as Map)
            .cast<String, Object?>());
        req.response.write(jsonEncode(respond()));
        await req.response.close();
      });
    });

    tearDown(() => server.close(force: true));

    const tool = ToolSpec(
      name: 'get_records',
      description: '查记录',
      parameters: {'type': 'object', 'properties': {}},
    );

    test('openai_compatible：工具定义、tool_calls 解析、思考内容与工具结果回传', () async {
      respond = () => {
            'choices': [
              {
                'message': {
                  'role': 'assistant',
                  'content': null,
                  'reasoning_content': '先查一下',
                  'refusal': null,
                  'tool_calls': [
                    {
                      'id': 'call_1',
                      'type': 'function',
                      'function': {
                        'name': 'get_records',
                        'arguments': '{"start_date":"2026-10-20"}',
                      },
                    },
                    {
                      'id': 'call_2',
                      'type': 'function',
                      'function': {'name': 'get_records', 'arguments': '{坏的'},
                    },
                  ],
                },
              },
            ],
            'usage': {'prompt_tokens': 50, 'completion_tokens': 9},
          };
      final client = ModelClient();
      final config = _config(
          protocol: ModelProtocol.openaiCompatible,
          baseUrl: 'http://127.0.0.1:${server.port}/v1');
      final first = await client.chatWithTools(
        config: config,
        apiKey: 'k',
        system: '系统',
        messages: const [UserText('问题')],
        tools: const [tool],
      );
      expect(first.toolCalls, hasLength(2));
      expect(first.toolCalls[0].arguments, {'start_date': '2026-10-20'});
      expect(first.toolCalls[1].argumentsError, contains('不是合法的 JSON'));
      expect(first.tokensIn, 50);

      final req = bodies.single;
      expect((req['tools'] as List).single, {
        'type': 'function',
        'function': {
          'name': 'get_records',
          'description': '查记录',
          'parameters': {'type': 'object', 'properties': {}},
        },
      });
      expect(req['tool_choice'], 'auto');

      respond = () => {
            'choices': [
              {'message': {'role': 'assistant', 'content': '回答'}},
            ],
          };
      final second = await client.chatWithTools(
        config: config,
        apiKey: 'k',
        messages: [
          const UserText('问题'),
          first.assistant,
          const ToolResults([ToolResult(callId: 'call_1', content: '{"records":[]}')]),
        ],
        tools: const [tool],
        allowTools: false,
      );
      expect(second.text, '回答');
      expect(second.toolCalls, isEmpty);
      final msgs = bodies.last['messages'] as List;
      final assistant = msgs[1] as Map;
      expect(assistant['reasoning_content'], '先查一下');
      expect(assistant.containsKey('refusal'), isFalse); // 只回传需要的字段
      expect((assistant['tool_calls'] as List), hasLength(2));
      expect(msgs[2], {
        'role': 'tool',
        'tool_call_id': 'call_1',
        'content': '{"records":[]}',
      });
      expect(bodies.last['tool_choice'], 'none');
    });

    test('anthropic：tool_use 解析，内容块原样回传，工具结果放在 user 消息里', () async {
      final blocks = [
        {'type': 'thinking', 'thinking': '想想', 'signature': 'sig'},
        {'type': 'text', 'text': '我查一下。'},
        {
          'type': 'tool_use',
          'id': 'toolu_1',
          'name': 'get_records',
          'input': {'start_date': '2026-10-20'},
        },
      ];
      respond = () => {
            'content': blocks,
            'usage': {'input_tokens': 30, 'output_tokens': 8},
          };
      final client = ModelClient();
      final config = _config(
          protocol: ModelProtocol.anthropic,
          baseUrl: 'http://127.0.0.1:${server.port}');
      final first = await client.chatWithTools(
        config: config,
        apiKey: 'k',
        system: '系统',
        messages: const [UserText('问题')],
        tools: const [tool],
      );
      expect(first.text, '我查一下。');
      expect(first.toolCalls.single.id, 'toolu_1');
      expect(first.toolCalls.single.arguments, {'start_date': '2026-10-20'});
      final req = bodies.single;
      expect(req['system'], '系统');
      expect((req['tools'] as List).single, {
        'name': 'get_records',
        'description': '查记录',
        'input_schema': {'type': 'object', 'properties': {}},
      });
      expect(req['tool_choice'], {'type': 'auto'});

      respond = () => {
            'content': [
              {'type': 'text', 'text': '回答'},
            ],
          };
      await client.chatWithTools(
        config: config,
        apiKey: 'k',
        messages: [
          const UserText('问题'),
          first.assistant,
          const ToolResults([ToolResult(callId: 'toolu_1', content: '结果')]),
        ],
        tools: const [tool],
        allowTools: false,
      );
      final msgs = bodies.last['messages'] as List;
      expect(msgs[1], {'role': 'assistant', 'content': blocks});
      expect(msgs[2], {
        'role': 'user',
        'content': [
          {'type': 'tool_result', 'tool_use_id': 'toolu_1', 'content': '结果'},
        ],
      });
      expect(bodies.last['tool_choice'], {'type': 'none'});
    });
  });

  group('ModelClient · 流式返回', () {
    late HttpServer server;
    late List<Map<String, Object?>> bodies;
    // 字符串按 SSE 原样写出，其他按 JSON 写出。
    late Object Function() respond;

    setUp(() async {
      bodies = [];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        bodies.add((jsonDecode(await utf8.decoder.bind(req).join()) as Map)
            .cast<String, Object?>());
        final r = respond();
        if (r is String) {
          req.response.headers.contentType =
              ContentType('text', 'event-stream', charset: 'utf-8');
          req.response.write(r);
        } else {
          req.response.write(jsonEncode(r));
        }
        await req.response.close();
      });
    });

    tearDown(() => server.close(force: true));

    String sse(List<Object> events) => [
          for (final e in events) 'data: ${e is String ? e : jsonEncode(e)}\n\n',
        ].join();

    const tool = ToolSpec(
      name: 'get_records',
      description: '查记录',
      parameters: {'type': 'object', 'properties': {}},
    );

    test('openai_compatible：文字增量逐段回调，工具调用分片拼回，带回思考内容与用量',
        () async {
      Map<String, Object?> delta(Map<String, Object?> d) => {
            'choices': [
              {'index': 0, 'delta': d},
            ],
          };
      respond = () => sse([
            delta({'role': 'assistant', 'reasoning_content': '先'}),
            delta({'reasoning_content': '查一下'}),
            delta({'content': '我查'}),
            delta({'content': '一下。'}),
            delta({
              'tool_calls': [
                {
                  'index': 0,
                  'id': 'call_1',
                  'type': 'function',
                  'function': {'name': 'get_records', 'arguments': '{"start'},
                },
              ],
            }),
            delta({
              'tool_calls': [
                {
                  'index': 0,
                  'function': {'arguments': '_date":"2026-10-20"}'},
                },
              ],
            }),
            {
              'choices': [],
              'usage': {'prompt_tokens': 50, 'completion_tokens': 9},
            },
            '[DONE]',
          ]);
      final got = <String>[];
      final r = await ModelClient().chatWithTools(
        config: _config(
            protocol: ModelProtocol.openaiCompatible,
            baseUrl: 'http://127.0.0.1:${server.port}/v1'),
        apiKey: 'k',
        messages: const [UserText('问题')],
        tools: const [tool],
        onText: got.add,
      );
      expect(got, ['我查', '一下。']);
      expect(r.text, '我查一下。');
      expect(r.toolCalls.single.id, 'call_1');
      expect(r.toolCalls.single.arguments, {'start_date': '2026-10-20'});
      expect(r.tokensIn, 50);
      expect(r.tokensOut, 9);
      expect((r.assistant.raw as Map)['reasoning_content'], '先查一下');
      expect(bodies.single['stream'], isTrue);
      expect(bodies.single['stream_options'], {'include_usage': true});
    });

    test('anthropic：思考、文字、工具参数按块拼回，用量取开头与结尾两处', () async {
      respond = () => sse([
            {
              'type': 'message_start',
              'message': {
                'usage': {'input_tokens': 30, 'output_tokens': 1},
              },
            },
            {
              'type': 'content_block_start',
              'index': 0,
              'content_block': {
                'type': 'thinking',
                'thinking': '',
                'signature': '',
              },
            },
            {
              'type': 'content_block_delta',
              'index': 0,
              'delta': {'type': 'thinking_delta', 'thinking': '想想'},
            },
            {
              'type': 'content_block_delta',
              'index': 0,
              'delta': {'type': 'signature_delta', 'signature': 'sig'},
            },
            {'type': 'content_block_stop', 'index': 0},
            {
              'type': 'content_block_start',
              'index': 1,
              'content_block': {'type': 'text', 'text': ''},
            },
            {
              'type': 'content_block_delta',
              'index': 1,
              'delta': {'type': 'text_delta', 'text': '我查'},
            },
            {
              'type': 'content_block_delta',
              'index': 1,
              'delta': {'type': 'text_delta', 'text': '一下。'},
            },
            {
              'type': 'content_block_start',
              'index': 2,
              'content_block': {
                'type': 'tool_use',
                'id': 'toolu_1',
                'name': 'get_records',
                'input': {},
              },
            },
            {
              'type': 'content_block_delta',
              'index': 2,
              'delta': {'type': 'input_json_delta', 'partial_json': '{"start_'},
            },
            {
              'type': 'content_block_delta',
              'index': 2,
              'delta': {
                'type': 'input_json_delta',
                'partial_json': 'date":"2026-10-20"}',
              },
            },
            {
              'type': 'message_delta',
              'usage': {'output_tokens': 8},
            },
            {'type': 'message_stop'},
          ]);
      final got = <String>[];
      final r = await ModelClient().chatWithTools(
        config: _config(
            protocol: ModelProtocol.anthropic,
            baseUrl: 'http://127.0.0.1:${server.port}'),
        apiKey: 'k',
        messages: const [UserText('问题')],
        tools: const [tool],
        onText: got.add,
      );
      expect(got, ['我查', '一下。']);
      expect(r.text, '我查一下。');
      expect(r.toolCalls.single.arguments, {'start_date': '2026-10-20'});
      expect(r.tokensIn, 30);
      expect(r.tokensOut, 8);
      // 内容块（含思考与签名）拼回原样，下一轮原样回传。
      expect(r.assistant.raw, [
        {'type': 'thinking', 'thinking': '想想', 'signature': 'sig'},
        {'type': 'text', 'text': '我查一下。'},
        {
          'type': 'tool_use',
          'id': 'toolu_1',
          'name': 'get_records',
          'input': {'start_date': '2026-10-20'},
        },
      ]);
      expect(bodies.single['stream'], isTrue);
    });

    test('服务不支持流式、直接回整段 JSON：照常解析', () async {
      respond = () => {
            'choices': [
              {'message': {'role': 'assistant', 'content': '整段回答'}},
            ],
          };
      final r = await ModelClient().complete(
        config: _config(
            protocol: ModelProtocol.openaiCompatible,
            baseUrl: 'http://127.0.0.1:${server.port}/v1'),
        apiKey: 'k',
        userText: 'hi',
        onText: (_) {},
      );
      expect(r.text, '整段回答');
    });

    test('流中途出错（过载）：可重试的异常，带服务方信息', () async {
      respond = () => sse([
            {
              'type': 'message_start',
              'message': {
                'usage': {'input_tokens': 3},
              },
            },
            {
              'type': 'error',
              'error': {'type': 'overloaded_error', 'message': 'Overloaded'},
            },
          ]);
      await expectLater(
        ModelClient().complete(
          config: _config(
              protocol: ModelProtocol.anthropic,
              baseUrl: 'http://127.0.0.1:${server.port}'),
          apiKey: 'k',
          userText: 'hi',
          onText: (_) {},
        ),
        throwsA(isA<ModelClientException>()
            .having((e) => e.retriable, 'retriable', isTrue)
            .having((e) => e.message, 'message', contains('Overloaded'))),
      );
    });

    test('不给 onText 时不请求流式', () async {
      respond = () => {
            'choices': [
              {'message': {'role': 'assistant', 'content': 'OK'}},
            ],
          };
      await ModelClient().complete(
        config: _config(
            protocol: ModelProtocol.openaiCompatible,
            baseUrl: 'http://127.0.0.1:${server.port}/v1'),
        apiKey: 'k',
        userText: 'hi',
      );
      expect(bodies.single.containsKey('stream'), isFalse);
    });
  });
}

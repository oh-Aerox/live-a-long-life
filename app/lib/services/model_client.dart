import 'dart:convert';
import 'dart:io';

import '../data/db/app_database.dart';
import 'app_log.dart';
import 'tool_chat.dart';

/// 一次模型调用的结果。
class ModelResponse {
  ModelResponse({required this.text, this.tokensIn, this.tokensOut});

  final String text;
  final int? tokensIn;
  final int? tokensOut;
}

/// 模型调用失败。`retriable` 为真时（网络、超时、5xx）整理批次可重排，
/// 假时（认证、参数错误）应提示用户检查配置。
class ModelClientException implements Exception {
  ModelClientException(this.message, {this.statusCode, this.retriable = false});

  final String message;
  final int? statusCode;
  final bool retriable;

  @override
  String toString() => 'ModelClientException($statusCode): $message';
}

/// 测试连接的结果（schema §4.3：capabilities 由测试结果写入）。
class TestConnectionResult {
  TestConnectionResult({
    required this.ok,
    required this.message,
    this.capabilities = const [],
  });

  final bool ok;
  final String message;

  /// 已验证的能力。测试只验证 text；image / pdf 待真正发送时按预设声明。
  final List<String> capabilities;
}

/// 模型 HTTP 客户端（D-16）。两种协议：
/// - `openai_compatible`：`POST {base}/chat/completions`，Bearer 认证。
///   覆盖 OpenAI / DeepSeek / Kimi / 智谱 GLM / Ollama / 自定义兼容服务；
/// - `anthropic`：`POST {base}/v1/messages`，x-api-key + anthropic-version。
///
/// 不引第三方 LLM SDK（减少依赖漂移），只用 dart:io。
class ModelClient {
  ModelClient({
    HttpClient Function()? httpClientFactory,
    this.timeout = const Duration(seconds: 60),
  }) : _newHttpClient = httpClientFactory ?? (() => HttpClient());

  final HttpClient Function() _newHttpClient;

  /// 单次请求超时。默认 60 秒；输出长的调用（医疗文件提取）单独放宽。
  final Duration timeout;
  static const anthropicVersion = '2023-06-01';

  /// 发送一轮对话，返回模型回复。整理管线在此之上组装。
  /// [imagePngBase64] 只由医疗文件"用模型识图"显式传入（D-24：图片永不
  /// 隐式发给模型）；其余调用都是纯文字。
  /// 给了 [onText] 就按流式请求，文字边到边回调增量；超时按两段数据之间
  /// 的空闲时间算，回答再长也不会整段超时。
  Future<ModelResponse> complete({
    required ModelConfig config,
    required String apiKey,
    String? system,
    required String userText,
    int maxTokens = 1024,
    String? imagePngBase64,
    void Function(String delta)? onText,
  }) {
    switch (config.protocol) {
      case ModelProtocol.openaiCompatible:
        return _openaiChat(config, apiKey,
            system: system,
            userText: userText,
            maxTokens: maxTokens,
            imagePngBase64: imagePngBase64,
            onText: onText);
      case ModelProtocol.anthropic:
        return _anthropicMessage(config, apiKey,
            system: system,
            userText: userText,
            maxTokens: maxTokens,
            imagePngBase64: imagePngBase64,
            onText: onText);
    }
  }

  /// 带工具的一轮对话（D-43 咨询 agent）。[messages] 是到目前为止的全部
  /// 往来；[allowTools] 为假时仍带上工具定义（历史里有工具调用时部分服务
  /// 要求），但禁止再调用，逼模型给出最终回答。[onText] 同 [complete]。
  Future<ToolChatResponse> chatWithTools({
    required ModelConfig config,
    required String apiKey,
    String? system,
    required List<ToolChatMessage> messages,
    required List<ToolSpec> tools,
    bool allowTools = true,
    int maxTokens = 4096,
    void Function(String delta)? onText,
  }) {
    switch (config.protocol) {
      case ModelProtocol.openaiCompatible:
        return _openaiToolChat(config, apiKey,
            system: system,
            messages: messages,
            tools: tools,
            allowTools: allowTools,
            maxTokens: maxTokens,
            onText: onText);
      case ModelProtocol.anthropic:
        return _anthropicToolChat(config, apiKey,
            system: system,
            messages: messages,
            tools: tools,
            allowTools: allowTools,
            maxTokens: maxTokens,
            onText: onText);
    }
  }

  Future<ToolChatResponse> _openaiToolChat(
    ModelConfig config,
    String apiKey, {
    String? system,
    required List<ToolChatMessage> messages,
    required List<ToolSpec> tools,
    required bool allowTools,
    required int maxTokens,
    void Function(String delta)? onText,
  }) async {
    final body = {
      ..._extraBody(config),
      'model': config.model,
      'max_tokens': maxTokens,
      'messages': [
        if (system != null) {'role': 'system', 'content': system},
        for (final m in messages)
          ...switch (m) {
            UserText(:final text) => [
                {'role': 'user', 'content': text}
              ],
            AssistantTurn(:final raw) => [raw],
            ToolResults(:final results) => [
                for (final r in results)
                  {'role': 'tool', 'tool_call_id': r.callId, 'content': r.content}
              ],
          },
      ],
      'tools': [
        for (final t in tools)
          {
            'type': 'function',
            'function': {
              'name': t.name,
              'description': t.description,
              'parameters': t.parameters,
            },
          },
      ],
      'tool_choice': allowTools ? 'auto' : 'none',
    };
    final json = await _post(
      _join(config.baseUrl, '/chat/completions'),
      headers: {'Authorization': 'Bearer $apiKey'},
      body: body,
      stream: onText == null ? null : _OpenaiStream(onText),
    );
    final choices = json['choices'] as List?;
    final message = choices == null || choices.isEmpty
        ? null
        : (choices.first as Map)['message'] as Map?;
    if (message == null) {
      throw ModelClientException('响应里没有消息内容');
    }
    final calls = <ToolCall>[];
    for (final c in (message['tool_calls'] as List?) ?? const []) {
      final fn = (c as Map)['function'] as Map? ?? const {};
      final (args, error) = _decodeArguments(fn['arguments']);
      calls.add(ToolCall(
        id: '${c['id']}',
        name: '${fn['name']}',
        arguments: args,
        argumentsError: error,
      ));
    }
    final text = message['content'] as String? ?? '';
    if (calls.isEmpty && text.trim().isEmpty) {
      throw ModelClientException('响应里没有消息内容');
    }
    final usage = json['usage'] as Map?;
    return ToolChatResponse(
      text: text,
      toolCalls: calls,
      // 只回传协议需要的字段；思考型模型（Kimi 等）要求带回 reasoning_content。
      assistant: AssistantTurn({
        'role': 'assistant',
        'content': message['content'],
        if (message['tool_calls'] != null) 'tool_calls': message['tool_calls'],
        if (message['reasoning_content'] != null)
          'reasoning_content': message['reasoning_content'],
      }),
      tokensIn: usage?['prompt_tokens'] as int?,
      tokensOut: usage?['completion_tokens'] as int?,
    );
  }

  /// OpenAI 兼容协议的参数是 JSON 字符串，个别服务直接给对象。
  static (Map<String, Object?>, String?) _decodeArguments(Object? raw) {
    if (raw is Map) return (raw.cast<String, Object?>(), null);
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return (const {}, null);
    }
    try {
      final v = jsonDecode('$raw');
      if (v is Map) return (v.cast<String, Object?>(), null);
    } on FormatException {
      // 落到下面
    }
    return (const {}, '参数不是合法的 JSON 对象：$raw');
  }

  Future<ToolChatResponse> _anthropicToolChat(
    ModelConfig config,
    String apiKey, {
    String? system,
    required List<ToolChatMessage> messages,
    required List<ToolSpec> tools,
    required bool allowTools,
    required int maxTokens,
    void Function(String delta)? onText,
  }) async {
    final body = {
      'model': config.model,
      'max_tokens': maxTokens,
      'system': ?system,
      'messages': [
        for (final m in messages)
          switch (m) {
            UserText(:final text) => {'role': 'user', 'content': text},
            AssistantTurn(:final raw) => {'role': 'assistant', 'content': raw},
            ToolResults(:final results) => {
                'role': 'user',
                'content': [
                  for (final r in results)
                    {
                      'type': 'tool_result',
                      'tool_use_id': r.callId,
                      'content': r.content,
                    },
                ],
              },
          },
      ],
      'tools': [
        for (final t in tools)
          {
            'name': t.name,
            'description': t.description,
            'input_schema': t.parameters,
          },
      ],
      'tool_choice': {'type': allowTools ? 'auto' : 'none'},
    };
    final json = await _post(
      _join(config.baseUrl, '/v1/messages'),
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': anthropicVersion,
      },
      body: body,
      stream: onText == null ? null : _AnthropicStream(onText),
    );
    final content = (json['content'] as List?)?.cast<Map>() ?? const [];
    final text = content
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String)
        .join();
    final calls = [
      for (final b in content)
        if (b['type'] == 'tool_use')
          ToolCall(
            id: '${b['id']}',
            name: '${b['name']}',
            arguments:
                (b['input'] as Map?)?.cast<String, Object?>() ?? const {},
          ),
    ];
    if (calls.isEmpty && text.trim().isEmpty) {
      throw ModelClientException('响应里没有文本内容');
    }
    final usage = json['usage'] as Map?;
    return ToolChatResponse(
      text: text,
      toolCalls: calls,
      // 内容块原样回传（含 thinking 块，开了扩展思考时必须带回）。
      assistant: AssistantTurn(json['content'] ?? const []),
      tokensIn: usage?['input_tokens'] as int?,
      tokensOut: usage?['output_tokens'] as int?,
    );
  }

  /// 1×1 透明 PNG，用于探测图片能力。
  static const _probePng =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
      'z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

  /// 测试连接：先发最小文本验证地址、key 和模型名；成功后再带一张
  /// 1×1 图片探测视觉能力（schema §4.3：capabilities 由测试结果写入）。
  /// 图片被拒绝不算失败，只是不标 image 能力。
  Future<TestConnectionResult> testConnection({
    required ModelConfig config,
    required String apiKey,
  }) async {
    try {
      await complete(
        config: config,
        apiKey: apiKey,
        userText: '收到请回复"OK"',
        maxTokens: 16,
      );
    } on ModelClientException catch (e) {
      return TestConnectionResult(ok: false, message: e.message);
    }
    var supportsImage = false;
    try {
      await _probeImage(config, apiKey);
      supportsImage = true;
    } on ModelClientException {
      // 服务拒绝图片输入：仅文本模型。
    }
    return TestConnectionResult(
      ok: true,
      message: supportsImage ? '连接成功（支持图片）' : '连接成功（仅文本）',
      capabilities: ['text', if (supportsImage) 'image'],
    );
  }

  Future<void> _probeImage(ModelConfig config, String apiKey) async {
    switch (config.protocol) {
      case ModelProtocol.openaiCompatible:
        await _post(
          _join(config.baseUrl, '/chat/completions'),
          headers: {'Authorization': 'Bearer $apiKey'},
          body: {
            ..._extraBody(config),
            'model': config.model,
            'max_tokens': 16,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': '这是图片能力测试，回复"OK"'},
                  {
                    'type': 'image_url',
                    'image_url': {'url': 'data:image/png;base64,$_probePng'},
                  },
                ],
              },
            ],
          },
        );
      case ModelProtocol.anthropic:
        await _post(
          _join(config.baseUrl, '/v1/messages'),
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': anthropicVersion,
          },
          body: {
            'model': config.model,
            'max_tokens': 16,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {
                    'type': 'image',
                    'source': {
                      'type': 'base64',
                      'media_type': 'image/png',
                      'data': _probePng,
                    },
                  },
                  {'type': 'text', 'text': '这是图片能力测试，回复"OK"'},
                ],
              },
            ],
          },
        );
    }
  }

  static Map<String, Object?> _extraBody(ModelConfig config) =>
      ModelPresetDefaults.byPreset[config.preset]?.extraBody ?? const {};

  Uri _join(String baseUrl, String path) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$base$path');
  }

  Future<ModelResponse> _openaiChat(
    ModelConfig config,
    String apiKey, {
    String? system,
    required String userText,
    required int maxTokens,
    String? imagePngBase64,
    void Function(String delta)? onText,
  }) async {
    final body = {
      ..._extraBody(config),
      'model': config.model,
      'max_tokens': maxTokens,
      'messages': [
        if (system != null) {'role': 'system', 'content': system},
        {
          'role': 'user',
          'content': imagePngBase64 == null
              ? userText
              : [
                  {'type': 'text', 'text': userText},
                  {
                    'type': 'image_url',
                    'image_url': {'url': 'data:image/png;base64,$imagePngBase64'},
                  },
                ],
        },
      ],
    };
    final json = await _post(
      _join(config.baseUrl, '/chat/completions'),
      headers: {'Authorization': 'Bearer $apiKey'},
      body: body,
      stream: onText == null ? null : _OpenaiStream(onText),
    );
    final choices = json['choices'] as List?;
    final content = choices == null || choices.isEmpty
        ? null
        : ((choices.first as Map)['message'] as Map?)?['content'] as String?;
    if (content == null) {
      throw ModelClientException('响应里没有消息内容');
    }
    final usage = json['usage'] as Map?;
    return ModelResponse(
      text: content,
      tokensIn: usage?['prompt_tokens'] as int?,
      tokensOut: usage?['completion_tokens'] as int?,
    );
  }

  Future<ModelResponse> _anthropicMessage(
    ModelConfig config,
    String apiKey, {
    String? system,
    required String userText,
    required int maxTokens,
    String? imagePngBase64,
    void Function(String delta)? onText,
  }) async {
    final body = {
      'model': config.model,
      'max_tokens': maxTokens,
      'system': ?system,
      'messages': [
        {
          'role': 'user',
          'content': imagePngBase64 == null
              ? userText
              : [
                  {
                    'type': 'image',
                    'source': {
                      'type': 'base64',
                      'media_type': 'image/png',
                      'data': imagePngBase64,
                    },
                  },
                  {'type': 'text', 'text': userText},
                ],
        },
      ],
    };
    final json = await _post(
      _join(config.baseUrl, '/v1/messages'),
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': anthropicVersion,
      },
      body: body,
      stream: onText == null ? null : _AnthropicStream(onText),
    );
    final content = json['content'] as List?;
    final text = content
        ?.cast<Map>()
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String)
        .join();
    if (text == null || text.isEmpty) {
      throw ModelClientException('响应里没有文本内容');
    }
    final usage = json['usage'] as Map?;
    return ModelResponse(
      text: text,
      tokensIn: usage?['input_tokens'] as int?,
      tokensOut: usage?['output_tokens'] as int?,
    );
  }

  /// 发请求并返回响应 JSON。给了 [stream] 就按流式请求，把 SSE 增量拼回
  /// 与非流式相同结构的 JSON，调用方的解析不用区分；服务不支持流式、
  /// 直接回整段 JSON 时照常解析。
  Future<Map<String, Object?>> _post(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
    _SseStream? stream,
  }) async {
    final client = _newHttpClient();
    // 只记地址与请求的模型，绝不记 key / Authorization（脱敏）。
    AppLog.I.d('model',
        'POST $uri model=${body['model']}${stream == null ? '' : ' 流式'}');
    try {
      final request = await client.postUrl(uri).timeout(timeout);
      request.headers.contentType = ContentType.json;
      headers.forEach(request.headers.set);
      request.write(jsonEncode({...body, ...?stream?.requestFields}));
      final response = await request.close().timeout(timeout);
      // 流式时 timeout 是两行数据之间的空闲上限，不限总时长。
      final lines = response
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final text = (await lines.toList()).join('\n');
        AppLog.I.w('model',
            'HTTP ${response.statusCode} ${uri.path} 返回 ${_snippet(text)}');
        throw ModelClientException(
          _errorMessage(response.statusCode, text),
          statusCode: response.statusCode,
          retriable: response.statusCode >= 500 || response.statusCode == 429,
        );
      }
      final plain = <String>[];
      final data = <String>[];
      bool? sse;
      await for (final line in lines) {
        if (stream == null || sse == false) {
          plain.add(line);
          continue;
        }
        if (sse == null) {
          if (line.trim().isEmpty) continue;
          // 首个非空行决定是不是 SSE：不是就当整段 JSON 读完。
          sse = line.startsWith('data:') ||
              line.startsWith('event:') ||
              line.startsWith(':');
          if (!sse) {
            plain.add(line);
            continue;
          }
        }
        if (line.isEmpty) {
          if (data.isNotEmpty) stream.add(data.join('\n'));
          data.clear();
        } else if (line.startsWith('data:')) {
          data.add(line.substring(5).trimLeft());
        }
      }
      if (sse == true) {
        if (data.isNotEmpty) stream!.add(data.join('\n'));
        AppLog.I.d('model', 'HTTP 200 ${uri.path} 流式完成');
        return stream!.result();
      }
      final text = plain.join('\n');
      try {
        final json = (jsonDecode(text) as Map).cast<String, Object?>();
        AppLog.I.d('model', 'HTTP 200 ${uri.path} ${text.length} 字节');
        return json;
      } on FormatException {
        // HTTP 2xx 但返回的不是 JSON（中转站网关页、包装层等）：
        // 带上响应片段和实际请求地址，方便定位。
        AppLog.I.w('model',
            'HTTP 200 ${uri.path} 非 JSON 返回：${_snippet(text)}');
        throw ModelClientException(
            '返回不是 JSON（HTTP ${response.statusCode}，请求 $uri）：'
            '${_snippet(text)}');
      }
    } on ModelClientException {
      rethrow;
    } catch (e) {
      // 连接失败、超时等网络层错误：可重试。
      AppLog.I.w('model', '网络错误 ${uri.path}：$e');
      throw ModelClientException('网络错误：$e', retriable: true);
    } finally {
      client.close(force: true);
    }
  }

  String _errorMessage(int status, String responseText) {
    String? detail;
    try {
      final json = jsonDecode(responseText) as Map;
      // OpenAI/Anthropic：{error:{message}}；部分中转站：顶层 {code,message}。
      detail = ((json['error'] as Map?)?['message'] ?? json['message'])
          as String?;
    } catch (_) {}
    final hint = switch (status) {
      401 || 403 => 'key 无效或没有权限',
      404 => '地址或模型名不对',
      429 => '请求过于频繁',
      _ => 'HTTP $status',
    };
    // 有结构化错误就带上它；否则附原文片段（中转站可能返回 HTML/网关页）。
    return '$hint：${detail ?? _snippet(responseText)}';
  }

  static String _snippet(String text) {
    final oneLine = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (oneLine.isEmpty) return '(空响应)';
    return oneLine.length > 300 ? '${oneLine.substring(0, 300)}…' : oneLine;
  }
}

/// 流式响应的拼装器：逐个吃 SSE 事件的 data，文字增量回调出去，
/// 结束时拼成与非流式响应相同结构的 JSON。
abstract class _SseStream {
  _SseStream(this.onText);

  final void Function(String delta) onText;

  /// 流式请求在请求体上追加的字段。
  Map<String, Object?> get requestFields;

  void add(String data) {
    if (data == '[DONE]') return;
    final Object? json;
    try {
      json = jsonDecode(data);
    } on FormatException {
      throw ModelClientException('流式返回无法解析：${ModelClient._snippet(data)}');
    }
    if (json is! Map) return;
    // 流中途出错（过载等）：两家都是 {error:{message}}。
    final error = json['error'];
    if (error != null) {
      throw ModelClientException(
          '${error is Map ? error['message'] ?? error : error}',
          retriable: true);
    }
    onEvent(json);
  }

  void onEvent(Map json);

  Map<String, Object?> result();
}

/// OpenAI 兼容：choices[0].delta 里的 content / reasoning_content /
/// tool_calls（按 index 分片，arguments 是逐段拼接的字符串）。
class _OpenaiStream extends _SseStream {
  _OpenaiStream(super.onText);

  final _content = StringBuffer();
  final _reasoning = StringBuffer();
  var _hasReasoning = false;
  final _calls = <int, ({String? id, StringBuffer name, StringBuffer args})>{};
  Object? _usage;

  @override
  Map<String, Object?> get requestFields => const {
        'stream': true,
        // 不加这个流式响应里没有 token 用量。
        'stream_options': {'include_usage': true},
      };

  @override
  void onEvent(Map json) {
    _usage = json['usage'] ?? _usage;
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) return;
    final delta = (choices.first as Map)['delta'] as Map?;
    if (delta == null) return;
    final text = delta['content'];
    if (text is String && text.isNotEmpty) {
      _content.write(text);
      onText(text);
    }
    final reasoning = delta['reasoning_content'];
    if (reasoning is String) {
      _reasoning.write(reasoning);
      _hasReasoning = true;
    }
    for (final c in (delta['tool_calls'] as List?) ?? const []) {
      c as Map;
      // 个别服务不给 index：带 id 的是新调用，否则续上一个。
      final index = c['index'] as int? ??
          (c['id'] != null || _calls.isEmpty
              ? _calls.length
              : _calls.keys.last);
      final call = _calls.putIfAbsent(
          index,
          () => (
                id: c['id'] as String?,
                name: StringBuffer(),
                args: StringBuffer(),
              ));
      final fn = c['function'] as Map? ?? const {};
      if (fn['name'] is String) call.name.write(fn['name']);
      if (fn['arguments'] is String) call.args.write(fn['arguments']);
    }
  }

  @override
  Map<String, Object?> result() {
    final indexes = _calls.keys.toList()..sort();
    return {
      'choices': [
        {
          'message': {
            'role': 'assistant',
            'content':
                _content.isEmpty && _calls.isNotEmpty ? null : '$_content',
            if (_calls.isNotEmpty)
              'tool_calls': [
                for (final i in indexes)
                  {
                    'id': _calls[i]!.id ?? 'call_$i',
                    'type': 'function',
                    'function': {
                      'name': '${_calls[i]!.name}',
                      'arguments': '${_calls[i]!.args}',
                    },
                  },
              ],
            if (_hasReasoning) 'reasoning_content': '$_reasoning',
          },
        },
      ],
      'usage': _usage,
    };
  }
}

/// Anthropic：content_block_start 开块，content_block_delta 按块追加
/// （文字、思考、工具参数 JSON 片段、签名），用量分在 message_start 与
/// message_delta 两处。
class _AnthropicStream extends _SseStream {
  _AnthropicStream(super.onText);

  final _blocks = <int, Map<String, Object?>>{};
  final _buffers = <int, StringBuffer>{};
  final _usage = <String, Object?>{};

  @override
  Map<String, Object?> get requestFields => const {'stream': true};

  @override
  void onEvent(Map json) {
    switch (json['type']) {
      case 'message_start':
        final usage = (json['message'] as Map?)?['usage'] as Map?;
        if (usage != null) _usage.addAll(usage.cast());
      case 'message_delta':
        final usage = json['usage'] as Map?;
        if (usage != null) _usage.addAll(usage.cast());
      case 'content_block_start':
        _blocks[json['index'] as int] =
            Map.of((json['content_block'] as Map).cast<String, Object?>());
      case 'content_block_delta':
        final index = json['index'] as int;
        final block = _blocks[index];
        final delta = json['delta'] as Map;
        if (block == null) return;
        final buffer = _buffers.putIfAbsent(index, StringBuffer.new);
        switch (delta['type']) {
          case 'text_delta':
            final text = delta['text'] as String;
            buffer.write(text);
            onText(text);
          case 'thinking_delta':
            buffer.write(delta['thinking']);
          case 'input_json_delta':
            buffer.write(delta['partial_json']);
          case 'signature_delta':
            block['signature'] = delta['signature'];
        }
    }
  }

  @override
  Map<String, Object?> result() {
    final indexes = _blocks.keys.toList()..sort();
    final content = <Map<String, Object?>>[];
    for (final i in indexes) {
      final block = _blocks[i]!;
      final buffered = '${_buffers[i] ?? ''}';
      switch (block['type']) {
        case 'text':
          block['text'] = '${block['text'] ?? ''}$buffered';
        case 'thinking':
          block['thinking'] = '${block['thinking'] ?? ''}$buffered';
        case 'tool_use':
          if (buffered.trim().isNotEmpty) {
            try {
              block['input'] = jsonDecode(buffered);
            } on FormatException {
              throw ModelClientException(
                  '工具参数不完整：${ModelClient._snippet(buffered)}');
            }
          }
      }
      content.add(block);
    }
    return {'content': content, 'usage': _usage};
  }
}

/// 各预设的默认值（product-spec §8：服务预设 → 填 key → 选模型）。
class ModelPresetDefaults {
  const ModelPresetDefaults({
    required this.label,
    required this.protocol,
    required this.baseUrl,
    required this.modelHint,
    required this.needsKey,
    this.extraBody = const {},
  });

  final String label;
  final ModelProtocol protocol;
  final String baseUrl;
  final String modelHint;
  final bool needsKey;

  /// 这家服务请求体里额外带的参数（OpenAI 兼容协议）。
  final Map<String, Object?> extraBody;

  static const byPreset = {
    ModelPreset.openai: ModelPresetDefaults(
      label: 'OpenAI',
      protocol: ModelProtocol.openaiCompatible,
      baseUrl: 'https://api.openai.com/v1',
      modelHint: '例如 gpt-5.2',
      needsKey: true,
    ),
    ModelPreset.anthropic: ModelPresetDefaults(
      label: 'Claude',
      protocol: ModelProtocol.anthropic,
      baseUrl: 'https://api.anthropic.com',
      modelHint: '例如 claude-opus-5',
      needsKey: true,
    ),
    ModelPreset.deepseek: ModelPresetDefaults(
      label: 'DeepSeek',
      protocol: ModelProtocol.openaiCompatible,
      baseUrl: 'https://api.deepseek.com/v1',
      modelHint: '例如 deepseek-chat',
      needsKey: true,
    ),
    // Kimi 与智谱 GLM 都是 OpenAI 兼容协议。两家的新模型默认深度思考：
    // kimi-k3 默认 max 档，体检报告一批就可能超过 180 秒提取超时，思考也
    // 占 max_tokens；整理与提取是按原文抄写归类，用不上深度思考，调低/关掉。
    ModelPreset.kimi: ModelPresetDefaults(
      label: 'Kimi（月之暗面）',
      protocol: ModelProtocol.openaiCompatible,
      baseUrl: 'https://api.moonshot.cn/v1',
      modelHint: '例如 kimi-k3',
      needsKey: true,
      extraBody: {'reasoning_effort': 'low'},
    ),
    ModelPreset.glm: ModelPresetDefaults(
      label: '智谱 GLM',
      protocol: ModelProtocol.openaiCompatible,
      baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
      modelHint: '例如 glm-5.3',
      needsKey: true,
      extraBody: {
        'thinking': {'type': 'disabled'},
      },
    ),
    ModelPreset.ollama: ModelPresetDefaults(
      label: 'Ollama（本地 / 局域网）',
      protocol: ModelProtocol.openaiCompatible,
      baseUrl: 'http://localhost:11434/v1',
      modelHint: '例如 qwen3',
      needsKey: false,
    ),
    ModelPreset.openaiCompatible: ModelPresetDefaults(
      label: '自定义（OpenAI 兼容）',
      protocol: ModelProtocol.openaiCompatible,
      baseUrl: '',
      modelHint: '按服务方文档填写',
      needsKey: true,
    ),
  };
}

import 'dart:convert';
import 'dart:io';

import '../data/db/app_database.dart';
import 'app_log.dart';

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
/// 不引第三方 LLM SDK（plan-v0.2 §2），只用 dart:io。
class ModelClient {
  ModelClient({
    HttpClient Function()? httpClientFactory,
    this.timeout = const Duration(seconds: 60),
  }) : _newHttpClient = httpClientFactory ?? (() => HttpClient());

  final HttpClient Function() _newHttpClient;

  /// 单次请求超时。默认 60 秒；输出长的调用（医疗文件提取）单独放宽。
  final Duration timeout;
  static const anthropicVersion = '2023-06-01';

  /// 发送一轮对话，返回模型回复。M2 的整理管线在此之上组装。
  /// [imagePngBase64] 只由医疗文件"用模型识图"显式传入（D-24：图片永不
  /// 隐式发给模型）；其余调用都是纯文字。
  Future<ModelResponse> complete({
    required ModelConfig config,
    required String apiKey,
    String? system,
    required String userText,
    int maxTokens = 1024,
    String? imagePngBase64,
  }) {
    switch (config.protocol) {
      case ModelProtocol.openaiCompatible:
        return _openaiChat(config, apiKey,
            system: system,
            userText: userText,
            maxTokens: maxTokens,
            imagePngBase64: imagePngBase64);
      case ModelProtocol.anthropic:
        return _anthropicMessage(config, apiKey,
            system: system,
            userText: userText,
            maxTokens: maxTokens,
            imagePngBase64: imagePngBase64);
    }
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

  Future<Map<String, Object?>> _post(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) async {
    final client = _newHttpClient();
    // 只记地址与请求的模型，绝不记 key / Authorization（脱敏）。
    AppLog.I.d('model', 'POST $uri model=${body['model']}');
    try {
      final request = await client.postUrl(uri).timeout(timeout);
      request.headers.contentType = ContentType.json;
      headers.forEach(request.headers.set);
      request.write(jsonEncode(body));
      final response = await request.close().timeout(timeout);
      final text = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        AppLog.I.w('model',
            'HTTP ${response.statusCode} ${uri.path} 返回 ${_snippet(text)}');
        throw ModelClientException(
          _errorMessage(response.statusCode, text),
          statusCode: response.statusCode,
          retriable: response.statusCode >= 500 || response.statusCode == 429,
        );
      }
      try {
        final json = (jsonDecode(text) as Map).cast<String, Object?>();
        AppLog.I.d('model', 'HTTP 200 ${uri.path} ${text.length} 字节');
        return json;
      } on FormatException {
        // HTTP 2xx 但返回的不是 JSON（中转站网关页、SSE 流、包装层等）：
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

/// 各预设的默认值（product-spec §4：服务预设 → 填 key → 选模型）。
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

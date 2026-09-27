import 'dart:convert';
import 'dart:io';

import '../data/db/app_database.dart';

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
///   覆盖 OpenAI / DeepSeek / Ollama / 自定义兼容服务；
/// - `anthropic`：`POST {base}/v1/messages`，x-api-key + anthropic-version。
///
/// 不引第三方 LLM SDK（plan-v0.2 §2），只用 dart:io。
class ModelClient {
  ModelClient({HttpClient Function()? httpClientFactory})
      : _newHttpClient = httpClientFactory ?? (() => HttpClient());

  final HttpClient Function() _newHttpClient;

  static const _timeout = Duration(seconds: 60);
  static const anthropicVersion = '2023-06-01';

  /// 发送一轮纯文字对话，返回模型回复。M2 的整理管线在此之上组装。
  Future<ModelResponse> complete({
    required ModelConfig config,
    required String apiKey,
    String? system,
    required String userText,
    int maxTokens = 1024,
  }) {
    switch (config.protocol) {
      case ModelProtocol.openaiCompatible:
        return _openaiChat(config, apiKey,
            system: system, userText: userText, maxTokens: maxTokens);
      case ModelProtocol.anthropic:
        return _anthropicMessage(config, apiKey,
            system: system, userText: userText, maxTokens: maxTokens);
    }
  }

  /// 测试连接：发一条最小消息，验证地址、key 和模型名。
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
      return TestConnectionResult(
          ok: true, message: '连接成功', capabilities: ['text']);
    } on ModelClientException catch (e) {
      return TestConnectionResult(ok: false, message: e.message);
    }
  }

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
  }) async {
    final body = {
      'model': config.model,
      'max_tokens': maxTokens,
      'messages': [
        if (system != null) {'role': 'system', 'content': system},
        {'role': 'user', 'content': userText},
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
  }) async {
    final body = {
      'model': config.model,
      'max_tokens': maxTokens,
      'system': ?system,
      'messages': [
        {'role': 'user', 'content': userText},
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
    try {
      final request = await client.postUrl(uri).timeout(_timeout);
      request.headers.contentType = ContentType.json;
      headers.forEach(request.headers.set);
      request.write(jsonEncode(body));
      final response = await request.close().timeout(_timeout);
      final text = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ModelClientException(
          _errorMessage(response.statusCode, text),
          statusCode: response.statusCode,
          retriable: response.statusCode >= 500 || response.statusCode == 429,
        );
      }
      return (jsonDecode(text) as Map).cast<String, Object?>();
    } on ModelClientException {
      rethrow;
    } on FormatException {
      throw ModelClientException('响应不是有效的 JSON');
    } catch (e) {
      // 连接失败、超时等网络层错误：可重试。
      throw ModelClientException('网络错误：$e', retriable: true);
    } finally {
      client.close(force: true);
    }
  }

  String _errorMessage(int status, String responseText) {
    String? detail;
    try {
      final json = jsonDecode(responseText) as Map;
      // OpenAI 形如 {error: {message}}；Anthropic 形如 {error: {type, message}}。
      detail = ((json['error'] as Map?)?['message']) as String?;
    } catch (_) {}
    final hint = switch (status) {
      401 || 403 => 'key 无效或没有权限',
      404 => '地址或模型名不对',
      429 => '请求过于频繁',
      _ => 'HTTP $status',
    };
    return detail == null ? hint : '$hint：$detail';
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
  });

  final String label;
  final ModelProtocol protocol;
  final String baseUrl;
  final String modelHint;
  final bool needsKey;

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

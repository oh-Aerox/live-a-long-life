// 带工具的多轮对话（D-43 咨询 agent）：协议无关的消息与工具描述，
// 由 ModelClient.chatWithTools 翻译成 OpenAI 兼容或 Anthropic 的请求体。

/// 一个可供模型调用的工具。[parameters] 是 JSON Schema（object）。
class ToolSpec {
  const ToolSpec({
    required this.name,
    required this.description,
    required this.parameters,
  });

  final String name;
  final String description;
  final Map<String, Object?> parameters;
}

/// 模型发起的一次工具调用。参数不是合法 JSON 时 [arguments] 为空、
/// [argumentsError] 说明原因，由调用方把错误回给模型。
class ToolCall {
  const ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
    this.argumentsError,
  });

  final String id;
  final String name;
  final Map<String, Object?> arguments;
  final String? argumentsError;
}

/// 一次工具调用的结果，[content] 原样发回模型。
class ToolResult {
  const ToolResult({required this.callId, required this.content});

  final String callId;
  final String content;
}

sealed class ToolChatMessage {
  const ToolChatMessage();
}

class UserText extends ToolChatMessage {
  const UserText(this.text);

  final String text;
}

/// 模型的一轮回复，按协议原样保存，下一轮原样发回（思考内容、
/// tool_use 块都要带上，否则部分服务会拒绝）。
class AssistantTurn extends ToolChatMessage {
  const AssistantTurn(this.raw);

  final Object raw;
}

class ToolResults extends ToolChatMessage {
  const ToolResults(this.results);

  final List<ToolResult> results;
}

/// 一轮回复：没有工具调用时 [text] 就是最终回答。
class ToolChatResponse {
  const ToolChatResponse({
    required this.text,
    required this.toolCalls,
    required this.assistant,
    this.tokensIn,
    this.tokensOut,
  });

  final String text;
  final List<ToolCall> toolCalls;
  final AssistantTurn assistant;
  final int? tokensIn;
  final int? tokensOut;
}

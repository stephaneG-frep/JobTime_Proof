import 'dart:convert';

import 'package:http/http.dart' as http;

class AiService {
  static const _openAiEndpoint = 'https://api.openai.com/v1/responses';
  static const _anthropicEndpoint = 'https://api.anthropic.com/v1/messages';
  static const _mistralEndpoint = 'https://api.mistral.ai/v1/chat/completions';
  static const _xaiEndpoint = 'https://api.x.ai/v1/chat/completions';
  static const _perplexityEndpoint = 'https://api.perplexity.ai/v1/agent';
  // Reasoning models and Perplexity web searches can take a while.
  static const _timeout = Duration(seconds: 120);

  static const _systemPrompt =
      'Tu es un assistant pour suivi de recherche d\'emploi. Réponds en français, style professionnel, concret et court. Donne: 1) résumé, 2) points clés, 3) suggestion postulé oui/non avec justification.';

  Future<String> generateSessionAssistantText({
    required String provider,
    required String apiKey,
    required String model,
    required String input,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw Exception('Clé API manquante.');
    }

    switch (provider) {
      case 'anthropic':
        return _generateWithAnthropic(
          apiKey: apiKey,
          model: model,
          input: input,
        );
      case 'gemini':
        return _generateWithGemini(apiKey: apiKey, model: model, input: input);
      case 'mistral':
        return _generateWithChatCompletions(
          endpoint: _mistralEndpoint,
          apiKey: apiKey,
          model: model,
          input: input,
        );
      case 'xai':
        return _generateWithChatCompletions(
          endpoint: _xaiEndpoint,
          apiKey: apiKey,
          model: model,
          input: input,
        );
      case 'perplexity':
        return _generateWithPerplexity(
          apiKey: apiKey,
          effort: model,
          input: input,
        );
      case 'openai':
      default:
        return _generateWithOpenAi(apiKey: apiKey, model: model, input: input);
    }
  }

  Future<Map<String, dynamic>> _postJson(
    String endpoint, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async {
    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/json', ...headers},
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    _checkStatus(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<String> _generateWithOpenAi({
    required String apiKey,
    required String model,
    required String input,
  }) async {
    final map = await _postJson(
      _openAiEndpoint,
      headers: {'Authorization': 'Bearer $apiKey'},
      body: {
        'model': model,
        'input': [
          {
            'role': 'system',
            'content': [
              {'type': 'input_text', 'text': _systemPrompt},
            ],
          },
          {
            'role': 'user',
            'content': [
              {'type': 'input_text', 'text': input},
            ],
          },
        ],
      },
    );

    final outputText = map['output_text'] as String?;
    if (outputText != null && outputText.trim().isNotEmpty) {
      return outputText.trim();
    }
    return _responsesOutputText(map);
  }

  Future<String> _generateWithAnthropic({
    required String apiKey,
    required String model,
    required String input,
  }) async {
    // On a safety decline, Opus and Sonnet can re-run the request on a
    // fallback model; Haiku has no server-side fallback.
    final withFallback = !model.contains('haiku');
    final map = await _postJson(
      _anthropicEndpoint,
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2026-10-21',
        if (withFallback) 'anthropic-beta': 'server-side-fallback-2026-07-01',
      },
      body: {
        'model': model,
        'max_tokens': 16000,
        'system': _systemPrompt,
        'messages': [
          {'role': 'user', 'content': input},
        ],
        if (withFallback) 'fallbacks': 'default',
      },
    );

    if (map['stop_reason'] == 'refusal') {
      throw Exception('Claude a refusé de traiter cette demande.');
    }
    // Thinking blocks may precede the answer: keep only the text blocks.
    final text = (map['content'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .where((block) => block['type'] == 'text')
        .map((block) => block['text'] as String? ?? '')
        .join('\n')
        .trim();
    if (text.isEmpty) throw Exception('Réponse IA vide.');
    return text;
  }

  Future<String> _generateWithGemini({
    required String apiKey,
    required String model,
    required String input,
  }) async {
    final map = await _postJson(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
      // Key sent as a header rather than in the URL, which may be logged.
      headers: {'x-goog-api-key': apiKey},
      body: {
        'contents': [
          {
            'parts': [
              {'text': '$_systemPrompt\n\n$input'},
            ],
          },
        ],
      },
    );
    final candidates = map['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) throw Exception('Réponse IA vide.');
    final content =
        (candidates.first as Map<String, dynamic>)['content']
            as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>? ?? [];
    if (parts.isEmpty) {
      throw Exception('Réponse IA vide.');
    }
    final text = (parts.first as Map<String, dynamic>)['text'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw Exception('Réponse IA vide.');
    }
    return text.trim();
  }

  /// OpenAI-compatible chat completions (Mistral, xAI).
  Future<String> _generateWithChatCompletions({
    required String endpoint,
    required String apiKey,
    required String model,
    required String input,
  }) async {
    final map = await _postJson(
      endpoint,
      headers: {'Authorization': 'Bearer $apiKey'},
      body: {
        'model': model,
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user', 'content': input},
        ],
      },
    );
    final choices = map['choices'] as List<dynamic>? ?? [];
    if (choices.isEmpty) {
      throw Exception('Réponse IA vide.');
    }
    final message =
        (choices.first as Map<String, dynamic>)['message']
            as Map<String, dynamic>?;
    final text = message?['content'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw Exception('Réponse IA vide.');
    }
    return text.trim();
  }

  /// Perplexity Agent API: [effort] is a preset (model + web search
  /// settings), used here in place of a model name.
  Future<String> _generateWithPerplexity({
    required String apiKey,
    required String effort,
    required String input,
  }) async {
    final map = await _postJson(
      _perplexityEndpoint,
      headers: {'Authorization': 'Bearer $apiKey'},
      body: {'effort': effort, 'instructions': _systemPrompt, 'input': input},
    );
    return _responsesOutputText(map);
  }

  /// Text of the `message` items of a Responses-style `output` array.
  String _responsesOutputText(Map<String, dynamic> map) {
    final text = (map['output'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .where((item) => item['type'] == 'message')
        .expand((item) => item['content'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((part) => part['text'] as String? ?? '')
        .join('\n')
        .trim();
    if (text.isEmpty) throw Exception('Réponse IA vide.');
    return text;
  }

  // Surface the provider's error message rather than the raw response body.
  void _checkStatus(http.Response response) {
    if (response.statusCode < 400) return;
    String? message;
    try {
      final error =
          (jsonDecode(response.body) as Map<String, dynamic>)['error'];
      message = error is Map ? error['message'] as String? : error as String?;
    } catch (_) {}
    throw Exception(
      'Erreur API (${response.statusCode})${message == null ? '' : ': $message'}',
    );
  }

  Future<void> testConnection({
    required String provider,
    required String apiKey,
    required String model,
  }) async {
    await generateSessionAssistantText(
      provider: provider,
      apiKey: apiKey,
      model: model,
      input: 'Test rapide de connexion API.',
    );
  }
}

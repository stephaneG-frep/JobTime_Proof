import 'dart:convert';

import 'package:http/http.dart' as http;

class AiService {
  static const _openAiEndpoint = 'https://api.openai.com/v1/responses';
  static const _mistralEndpoint = 'https://api.mistral.ai/v1/chat/completions';

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
      case 'gemini':
        return _generateWithGemini(apiKey: apiKey, model: model, input: input);
      case 'mistral':
        return _generateWithMistral(apiKey: apiKey, model: model, input: input);
      case 'openai':
      default:
        return _generateWithOpenAi(apiKey: apiKey, model: model, input: input);
    }
  }

  Future<String> _generateWithOpenAi({
    required String apiKey,
    required String model,
    required String input,
  }) async {
    final body = {
      'model': model,
      'input': [
        {
          'role': 'system',
          'content': [
            {
              'type': 'input_text',
              'text':
                  'Tu es un assistant pour suivi de recherche d\'emploi. Réponds en français, style professionnel, concret et court. Donne: 1) résumé, 2) points clés, 3) suggestion postulé oui/non avec justification.',
            },
          ],
        },
        {
          'role': 'user',
          'content': [
            {'type': 'input_text', 'text': input},
          ],
        },
      ],
    };

    final response = await http.post(
      Uri.parse(_openAiEndpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 400) {
      throw Exception('Erreur API (${response.statusCode}): ${response.body}');
    }

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final outputText = map['output_text'] as String?;
    if (outputText != null && outputText.trim().isNotEmpty) {
      return outputText.trim();
    }

    // Fallback parser for structured output blocks.
    final output = map['output'] as List<dynamic>? ?? [];
    for (final item in output) {
      final content =
          (item as Map<String, dynamic>)['content'] as List<dynamic>?;
      if (content == null) continue;
      for (final block in content) {
        final text = (block as Map<String, dynamic>)['text'] as String?;
        if (text != null && text.trim().isNotEmpty) {
          return text.trim();
        }
      }
    }

    throw Exception('Réponse IA vide.');
  }

  Future<String> _generateWithGemini({
    required String apiKey,
    required String model,
    required String input,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );
    final body = {
      'contents': [
        {
          'parts': [
            {
              'text':
                  'Tu es un assistant pour suivi de recherche d\'emploi. Réponds en français, style professionnel, concret et court. Donne: 1) résumé, 2) points clés, 3) suggestion postulé oui/non avec justification.\n\n$input',
            },
          ],
        },
      ],
    };
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode >= 400) {
      throw Exception('Erreur API (${response.statusCode}): ${response.body}');
    }
    final map = jsonDecode(response.body) as Map<String, dynamic>;
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

  Future<String> _generateWithMistral({
    required String apiKey,
    required String model,
    required String input,
  }) async {
    final body = {
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content':
              'Tu es un assistant pour suivi de recherche d\'emploi. Réponds en français, style professionnel, concret et court. Donne: 1) résumé, 2) points clés, 3) suggestion postulé oui/non avec justification.',
        },
        {'role': 'user', 'content': input},
      ],
    };
    final response = await http.post(
      Uri.parse(_mistralEndpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode >= 400) {
      throw Exception('Erreur API (${response.statusCode}): ${response.body}');
    }
    final map = jsonDecode(response.body) as Map<String, dynamic>;
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

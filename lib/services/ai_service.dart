import 'dart:convert';

import 'package:http/http.dart' as http;

class AiService {
  static const _endpoint = 'https://api.openai.com/v1/responses';

  Future<String> generateSessionAssistantText({
    required String apiKey,
    required String model,
    required String input,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw Exception('Clé API manquante.');
    }

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
      Uri.parse(_endpoint),
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

  Future<void> testConnection({
    required String apiKey,
    required String model,
  }) async {
    await generateSessionAssistantText(
      apiKey: apiKey,
      model: model,
      input: 'Test rapide de connexion API.',
    );
  }
}

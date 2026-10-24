import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jobtime_proof/services/ai_service.dart';

/// Runs [generate] against a fake server answering [responseBody], and returns
/// the generated text along with the request that was sent.
Future<(String, http.Request)> _call({
  required String provider,
  required String model,
  required Map<String, dynamic> responseBody,
  int status = 200,
}) async {
  late http.Request sent;
  final client = MockClient((request) async {
    sent = request;
    return http.Response(
      jsonEncode(responseBody),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
  final text = await http.runWithClient(
    () => AiService().generateSessionAssistantText(
      provider: provider,
      apiKey: 'test-key',
      model: model,
      input: 'Annonce développeur Flutter',
    ),
    () => client,
  );
  return (text, sent);
}

void main() {
  test('Claude : en-têtes, corps et blocs de texte seuls', () async {
    final (text, request) = await _call(
      provider: 'anthropic',
      model: 'claude-opus-5-5',
      responseBody: {
        'stop_reason': 'end_turn',
        'content': [
          {'type': 'thinking', 'thinking': ''},
          {'type': 'text', 'text': 'Résumé : poste Flutter.'},
        ],
      },
    );

    expect(request.url.toString(), 'https://api.anthropic.com/v1/messages');
    expect(request.headers['x-api-key'], 'test-key');
    expect(request.headers['anthropic-version'], isNotNull);
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    expect(body['model'], 'claude-opus-5-5');
    expect(body['system'], isNotEmpty);
    expect(body['max_tokens'], greaterThan(0));
    expect(body['fallbacks'], 'default');
    expect(body['messages'], [
      {'role': 'user', 'content': 'Annonce développeur Flutter'},
    ]);
    expect(text, 'Résumé : poste Flutter.');
  });

  test('Claude Haiku : pas de fallback serveur', () async {
    final (_, request) = await _call(
      provider: 'anthropic',
      model: 'claude-haiku-5-5',
      responseBody: {
        'stop_reason': 'end_turn',
        'content': [
          {'type': 'text', 'text': 'ok'},
        ],
      },
    );
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    expect(body.containsKey('fallbacks'), isFalse);
    expect(request.headers.containsKey('anthropic-beta'), isFalse);
  });

  test('Claude : un refus devient une erreur explicite', () async {
    await expectLater(
      _call(
        provider: 'anthropic',
        model: 'claude-opus-5-5',
        responseBody: {'stop_reason': 'refusal', 'content': []},
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('Grok : chat completions xAI', () async {
    final (text, request) = await _call(
      provider: 'xai',
      model: 'grok-4.7',
      responseBody: {
        'choices': [
          {
            'message': {'role': 'assistant', 'content': 'Réponse Grok'},
          },
        ],
      },
    );
    expect(request.url.toString(), 'https://api.x.ai/v1/chat/completions');
    expect(request.headers['authorization'], 'Bearer test-key');
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    expect(body['model'], 'grok-4.7');
    expect((body['messages'] as List).first['role'], 'system');
    expect(text, 'Réponse Grok');
  });

  test('Perplexity : Agent API avec preset et sortie message', () async {
    final (text, request) = await _call(
      provider: 'perplexity',
      model: 'fast',
      responseBody: {
        'object': 'response',
        'output': [
          {'type': 'search_results', 'results': []},
          {
            'type': 'message',
            'role': 'assistant',
            'content': [
              {'type': 'output_text', 'text': 'Réponse Perplexity'},
            ],
          },
        ],
      },
    );
    expect(request.url.toString(), 'https://api.perplexity.ai/v1/agent');
    expect(request.headers['authorization'], 'Bearer test-key');
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    expect(body['effort'], 'fast');
    expect(body['input'], 'Annonce développeur Flutter');
    expect(body['instructions'], isNotEmpty);
    expect(text, 'Réponse Perplexity');
  });

  test('une erreur API affiche le message du fournisseur', () async {
    await expectLater(
      _call(
        provider: 'anthropic',
        model: 'claude-opus-5-5',
        status: 401,
        responseBody: {
          'type': 'error',
          'error': {
            'type': 'authentication_error',
            'message': 'invalid x-api-key',
          },
        },
      ),
      throwsA(
        predicate((e) => e.toString().contains('(401): invalid x-api-key')),
      ),
    );
  });
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _openAiApiKeyKey = 'openai_api_key';
  static const _geminiApiKeyKey = 'gemini_api_key';
  static const _mistralApiKeyKey = 'mistral_api_key';

  String _keyForProvider(String provider) {
    switch (provider) {
      case 'gemini':
        return _geminiApiKeyKey;
      case 'mistral':
        return _mistralApiKeyKey;
      case 'openai':
      default:
        return _openAiApiKeyKey;
    }
  }

  Future<String> getApiKey(String provider) async {
    return (await _storage.read(key: _keyForProvider(provider))) ?? '';
  }

  Future<void> setApiKey(String provider, String value) async {
    if (value.trim().isEmpty) {
      await _storage.delete(key: _keyForProvider(provider));
      return;
    }
    await _storage.write(key: _keyForProvider(provider), value: value.trim());
  }

  Future<void> clearApiKey(String provider) async {
    await _storage.delete(key: _keyForProvider(provider));
  }
}

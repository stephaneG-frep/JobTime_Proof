import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _openAiApiKeyKey = 'openai_api_key';

  Future<String> getOpenAiApiKey() async {
    return (await _storage.read(key: _openAiApiKeyKey)) ?? '';
  }

  Future<void> setOpenAiApiKey(String value) async {
    if (value.trim().isEmpty) {
      await _storage.delete(key: _openAiApiKeyKey);
      return;
    }
    await _storage.write(key: _openAiApiKeyKey, value: value.trim());
  }

  Future<void> clearOpenAiApiKey() async {
    await _storage.delete(key: _openAiApiKeyKey);
  }
}

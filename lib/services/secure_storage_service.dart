import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  // e.g. 'openai_api_key', 'anthropic_api_key'.
  String _keyForProvider(String provider) => '${provider}_api_key';

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

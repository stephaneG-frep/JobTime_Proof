import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/hive_service.dart';
import '../services/secure_storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings.initial();
  final SecureStorageService _secureStorage = SecureStorageService();
  final Map<String, String> _apiKeysByProvider = {};

  AppSettings get settings => _settings;
  String get currentAiApiKey => _apiKeysByProvider[_settings.aiProvider] ?? '';
  String apiKeyForProvider(String provider) =>
      _apiKeysByProvider[provider] ?? '';

  List<String> get basePlatforms => const [
    'France Travail',
    'Indeed',
    'Hellowork',
    'LinkedIn',
    'Apec',
    'Welcome to the Jungle',
    'Autre',
  ];

  List<String> get allPlatforms {
    final merged = <String>{...basePlatforms, ..._settings.customPlatforms};
    return merged.toList()..sort();
  }

  List<String> get aiProviders => const ['openai', 'gemini', 'mistral'];

  List<String> aiModelsForProvider(String provider) {
    switch (provider) {
      case 'gemini':
        return const ['gemini-2.5-flash', 'gemini-2.5-pro', 'gemini-2.0-flash'];
      case 'mistral':
        return const [
          'mistral-small-latest',
          'mistral-medium-latest',
          'mistral-large-latest',
        ];
      case 'openai':
      default:
        return const ['gpt-4.1-mini', 'gpt-4.1', 'gpt-4o-mini'];
    }
  }

  Future<void> load() async {
    final box = HiveService.settingsBox;
    if (box.isEmpty) {
      _settings = AppSettings.initial();
      await box.put('main', _settings);
    } else {
      _settings = box.get('main') ?? AppSettings.initial();
    }
    for (final provider in aiProviders) {
      _apiKeysByProvider[provider] = await _secureStorage.getApiKey(provider);
    }
    notifyListeners();
  }

  Future<void> setWeeklyGoalHours(int value) async {
    _settings = _settings.copyWith(weeklyGoalHours: value);
    await HiveService.settingsBox.put('main', _settings);
    notifyListeners();
  }

  Future<void> addCustomPlatform(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _settings.customPlatforms.contains(trimmed)) return;
    final updated = [..._settings.customPlatforms, trimmed];
    _settings = _settings.copyWith(customPlatforms: updated);
    await HiveService.settingsBox.put('main', _settings);
    notifyListeners();
  }

  Future<void> removeCustomPlatform(String name) async {
    final updated = _settings.customPlatforms.where((e) => e != name).toList();
    _settings = _settings.copyWith(customPlatforms: updated);
    await HiveService.settingsBox.put('main', _settings);
    notifyListeners();
  }

  Future<void> replaceFromImport(AppSettings importedSettings) async {
    _settings = importedSettings;
    await HiveService.settingsBox.put('main', _settings);
    notifyListeners();
  }

  Future<void> setOtherLaunchTargets({
    required String webUrl,
    required String appScheme,
  }) async {
    _settings = _settings.copyWith(
      otherPlatformWebUrl: webUrl.trim(),
      otherPlatformAppScheme: appScheme.trim(),
    );
    await HiveService.settingsBox.put('main', _settings);
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    _settings = _settings.copyWith(darkModeEnabled: enabled);
    await HiveService.settingsBox.put('main', _settings);
    notifyListeners();
  }

  Future<void> setAiConfig({
    required String provider,
    required String apiKey,
    required String model,
  }) async {
    _apiKeysByProvider[provider] = apiKey.trim();
    await _secureStorage.setApiKey(provider, apiKey.trim());
    _settings = _settings.copyWith(
      aiProvider: provider.trim(),
      aiModel: model.trim(),
    );
    await HiveService.settingsBox.put('main', _settings);
    notifyListeners();
  }

  Future<void> clearAiApiKeyFor(String provider) async {
    _apiKeysByProvider[provider] = '';
    await _secureStorage.clearApiKey(provider);
    notifyListeners();
  }

  Future<void> setLastAutoBackupAt(DateTime when) async {
    _settings = _settings.copyWith(lastAutoBackupAt: when);
    await HiveService.settingsBox.put('main', _settings);
    notifyListeners();
  }
}

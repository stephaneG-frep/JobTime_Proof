import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/hive_service.dart';
import '../services/secure_storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings.initial();
  final SecureStorageService _secureStorage = SecureStorageService();
  String _openAiApiKey = '';

  AppSettings get settings => _settings;
  String get openAiApiKey => _openAiApiKey;

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

  List<String> get aiModels => const ['gpt-4.1-mini', 'gpt-4.1', 'gpt-4o-mini'];

  Future<void> load() async {
    final box = HiveService.settingsBox;
    if (box.isEmpty) {
      _settings = AppSettings.initial();
      await box.put('main', _settings);
    } else {
      _settings = box.get('main') ?? AppSettings.initial();
    }
    _openAiApiKey = await _secureStorage.getOpenAiApiKey();
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
    required String apiKey,
    required String model,
  }) async {
    _openAiApiKey = apiKey.trim();
    await _secureStorage.setOpenAiApiKey(_openAiApiKey);
    _settings = _settings.copyWith(openAiModel: model.trim());
    await HiveService.settingsBox.put('main', _settings);
    notifyListeners();
  }

  Future<void> clearAiApiKey() async {
    _openAiApiKey = '';
    await _secureStorage.clearOpenAiApiKey();
    notifyListeners();
  }

  Future<void> setLastAutoBackupAt(DateTime when) async {
    _settings = _settings.copyWith(lastAutoBackupAt: when);
    await HiveService.settingsBox.put('main', _settings);
    notifyListeners();
  }
}

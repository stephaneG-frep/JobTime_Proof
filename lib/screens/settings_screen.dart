import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../services/file_service.dart';
import 'ai_assistant_screen.dart';
import 'help_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _platformCtrl = TextEditingController();
  final _otherWebCtrl = TextEditingController();
  final _otherAppCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  final _fileService = FileService();
  final _aiService = AiService();
  bool _otherTargetsLoaded = false;

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final sessionProvider = context.watch<SessionProvider>();
    if (!_otherTargetsLoaded) {
      _otherWebCtrl.text = settingsProvider.settings.otherPlatformWebUrl;
      _otherAppCtrl.text = settingsProvider.settings.otherPlatformAppScheme;
      _apiKeyCtrl.text = settingsProvider.settings.openAiApiKey;
      _otherTargetsLoaded = true;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Paramètres', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 14),
        FilledButton.tonalIcon(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HelpScreen()));
          },
          icon: const Icon(Icons.menu_book_outlined),
          label: const Text('Ouvrir le mode d’emploi'),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Paramètres IA'),
                const SizedBox(height: 8),
                TextField(
                  controller: _apiKeyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Clé API OpenAI',
                    hintText: 'sk-...',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: settingsProvider.settings.openAiModel,
                  decoration: const InputDecoration(
                    labelText: 'Modèle IA',
                    border: OutlineInputBorder(),
                  ),
                  items: settingsProvider.aiModels
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (model) async {
                    if (model == null) return;
                    await settingsProvider.setAiConfig(
                      apiKey: _apiKeyCtrl.text,
                      model: model,
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () async {
                          await settingsProvider.setAiConfig(
                            apiKey: _apiKeyCtrl.text,
                            model: settingsProvider.settings.openAiModel,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Configuration IA sauvegardée.'),
                              ),
                            );
                          }
                        },
                        child: const Text('Enregistrer IA'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          try {
                            await _aiService.testConnection(
                              apiKey: _apiKeyCtrl.text.trim(),
                              model: settingsProvider.settings.openAiModel,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Connexion IA OK.'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur IA: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('Tester'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AiAssistantScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Ouvrir Assistant IA'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Thème sombre'),
                  subtitle: const Text(
                    'Active le mode sombre dans toute l’application',
                  ),
                  value: settingsProvider.settings.darkModeEnabled,
                  onChanged: (value) => settingsProvider.setDarkMode(value),
                ),
                const SizedBox(height: 8),
                Text(
                  'Objectif hebdomadaire (${settingsProvider.settings.weeklyGoalHours} h)',
                ),
                Slider(
                  min: 1,
                  max: 60,
                  divisions: 59,
                  value: settingsProvider.settings.weeklyGoalHours.toDouble(),
                  onChanged: (v) =>
                      settingsProvider.setWeeklyGoalHours(v.round()),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Plateforme "Autre" (personnalisée)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _otherWebCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL web (ex: https://exemple.com/jobs)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _otherAppCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Schéma app (ex: hellowork://)',
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () async {
                    await settingsProvider.setOtherLaunchTargets(
                      webUrl: _otherWebCtrl.text,
                      appScheme: _otherAppCtrl.text,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Configuration "Autre" sauvegardée.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Plateformes personnalisées'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _platformCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nom plateforme',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        await settingsProvider.addCustomPlatform(
                          _platformCtrl.text,
                        );
                        _platformCtrl.clear();
                      },
                      child: const Text('Ajouter'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...settingsProvider.settings.customPlatforms.map(
                  (p) => ListTile(
                    title: Text(p),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => settingsProvider.removeCustomPlatform(p),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final path = await _fileService.exportDataToJson(
                      sessions: sessionProvider.sessions,
                      settings: settingsProvider.settings,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Export JSON créé: $path')),
                      );
                    }
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Exporter JSON'),
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final path = await _fileService.pickJson();
                    if (path == null) return;
                    final (settings, sessions) = await _fileService
                        .importDataFromJson(path);
                    await settingsProvider.replaceFromImport(settings);
                    await sessionProvider.replaceAllSessions(sessions);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Import JSON terminé.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.download_for_offline),
                  label: const Text('Importer JSON'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Suppression complète'),
                        content: const Text(
                          'Confirmez la suppression de toutes les données locales.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Confirmer'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await sessionProvider.clearAll();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Données supprimées.')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Supprimer toutes les données'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _platformCtrl.dispose();
    _otherWebCtrl.dispose();
    _otherAppCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }
}

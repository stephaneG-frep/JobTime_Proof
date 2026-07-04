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
      _apiKeyCtrl.text = settingsProvider.currentAiApiKey;
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
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Clé API OpenAI',
                    hintText: 'sk-...',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: settingsProvider.settings.aiProvider,
                  decoration: const InputDecoration(
                    labelText: 'Provider IA',
                    border: OutlineInputBorder(),
                  ),
                  items: settingsProvider.aiProviders
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (provider) async {
                    if (provider == null) return;
                    final models = settingsProvider.aiModelsForProvider(
                      provider,
                    );
                    final selectedModel = models.first;
                    final apiKey = settingsProvider.apiKeyForProvider(provider);
                    _apiKeyCtrl.text = apiKey;
                    await settingsProvider.setAiConfig(
                      provider: provider,
                      apiKey: apiKey,
                      model: selectedModel,
                    );
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: settingsProvider.settings.aiModel,
                  decoration: const InputDecoration(
                    labelText: 'Modèle IA',
                    border: OutlineInputBorder(),
                  ),
                  items: settingsProvider
                      .aiModelsForProvider(settingsProvider.settings.aiProvider)
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (model) async {
                    if (model == null) return;
                    await settingsProvider.setAiConfig(
                      provider: settingsProvider.settings.aiProvider,
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
                            provider: settingsProvider.settings.aiProvider,
                            apiKey: _apiKeyCtrl.text,
                            model: settingsProvider.settings.aiModel,
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
                              provider: settingsProvider.settings.aiProvider,
                              apiKey: _apiKeyCtrl.text.trim(),
                              model: settingsProvider.settings.aiModel,
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
                OutlinedButton.icon(
                  onPressed: () async {
                    await settingsProvider.clearAiApiKeyFor(
                      settingsProvider.settings.aiProvider,
                    );
                    _apiKeyCtrl.clear();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Clé API supprimée.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.key_off),
                  label: const Text('Effacer la clé API'),
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
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final removed = await settingsProvider
                        .cleanCustomPlatforms();
                    final updatedSessions = await sessionProvider
                        .normalizePlatformNames(settingsProvider.allPlatforms);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Réparation terminée: $removed plateforme(s) nettoyée(s), $updatedSessions session(s) mise(s) à jour.',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.build_circle_outlined),
                  label: const Text('Réparer les données locales'),
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
                const Text('Import, export et données'),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _SettingsActionCard(
                      icon: Icons.upload_file,
                      title: 'Export JSON',
                      subtitle: 'Données seules',
                      onTap: () async {
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
                    ),
                    _SettingsActionCard(
                      icon: Icons.folder_zip_outlined,
                      title: 'Export ZIP',
                      subtitle: 'JSON + preuves',
                      onTap: () async {
                        final path = await _fileService.exportCompleteZip(
                          sessions: sessionProvider.sessions,
                          settings: settingsProvider.settings,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Export ZIP complet créé: $path'),
                            ),
                          );
                        }
                      },
                    ),
                    _SettingsActionCard(
                      icon: Icons.download_for_offline,
                      title: 'Import JSON',
                      subtitle: 'Restaurer',
                      onTap: () async {
                        final path = await _fileService.pickJson();
                        if (path == null) return;
                        final (settings, sessions) = await _fileService
                            .importDataFromJson(path);
                        await settingsProvider.replaceFromImport(settings);
                        await sessionProvider.replaceAllSessions(sessions);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Import JSON terminé.'),
                            ),
                          );
                        }
                      },
                    ),
                    _SettingsActionCard(
                      icon: Icons.delete_forever,
                      title: 'Supprimer',
                      subtitle: 'Tout effacer',
                      destructive: true,
                      onTap: () async {
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
                              const SnackBar(
                                content: Text('Données supprimées.'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
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

class _SettingsActionCard extends StatelessWidget {
  const _SettingsActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = destructive ? scheme.error : scheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../services/file_service.dart';
import '../theme/app_palette.dart';
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
      _syncControllers(settingsProvider);
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
          color: AppPalette.of(context).tint(AppPalette.of(context).purple),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  icon: Icons.auto_awesome,
                  color: AppPalette.of(context).purple,
                  title: 'Paramètres IA',
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _apiKeyCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText:
                        'Clé API ${settingsProvider.aiProviderLabel(settingsProvider.settings.aiProvider)}',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: ValueKey(
                    'provider-${settingsProvider.settings.aiProvider}',
                  ),
                  initialValue:
                      settingsProvider.aiProviders.contains(
                        settingsProvider.settings.aiProvider,
                      )
                      ? settingsProvider.settings.aiProvider
                      : settingsProvider.aiProviders.first,
                  decoration: const InputDecoration(
                    labelText: 'Provider IA',
                    border: OutlineInputBorder(),
                  ),
                  items: settingsProvider.aiProviders
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(settingsProvider.aiProviderLabel(p)),
                        ),
                      )
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
                  // Recreate the field when the provider changes: its model
                  // list changes and the previous value would not be in it.
                  key: ValueKey(
                    'model-${settingsProvider.settings.aiProvider}',
                  ),
                  initialValue: _modelValue(settingsProvider),
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
          color: AppPalette.of(context).tint(AppPalette.of(context).coral),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  icon: Icons.palette_outlined,
                  color: AppPalette.of(context).coral,
                  title: 'Apparence et objectif',
                ),
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
          color: AppPalette.of(context).tint(AppPalette.of(context).teal),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  icon: Icons.open_in_new,
                  color: AppPalette.of(context).teal,
                  title: 'Plateforme "Autre" (personnalisée)',
                ),
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
          color: AppPalette.of(context).tint(AppPalette.of(context).blue),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  icon: Icons.apps,
                  color: AppPalette.of(context).blue,
                  title: 'Plateformes personnalisées',
                ),
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
          color: AppPalette.of(context).tint(AppPalette.of(context).orange),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  icon: Icons.storage,
                  color: AppPalette.of(context).orange,
                  title: 'Import, export et données',
                ),
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
                      color: AppPalette.of(context).blue,
                      title: 'Export JSON',
                      subtitle: 'Données seules',
                      onTap: () async {
                        final path = await _fileService.exportDataToJson(
                          sessions: sessionProvider.sessions,
                          settings: settingsProvider.settings,
                        );
                        await _fileService.shareFile(
                          path,
                          subject: 'Export JobTime Proof',
                        );
                      },
                    ),
                    _SettingsActionCard(
                      icon: Icons.folder_zip_outlined,
                      color: AppPalette.of(context).purple,
                      title: 'Export ZIP',
                      subtitle: 'JSON + preuves',
                      onTap: () async {
                        final path = await _fileService.exportCompleteZip(
                          sessions: sessionProvider.sessions,
                          settings: settingsProvider.settings,
                        );
                        await _fileService.shareFile(
                          path,
                          subject: 'Export complet JobTime Proof',
                        );
                      },
                    ),
                    _SettingsActionCard(
                      icon: Icons.download_for_offline,
                      color: AppPalette.of(context).teal,
                      title: 'Import JSON',
                      subtitle: 'Restaurer',
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final path = await _fileService.pickJson();
                        if (path == null) return;
                        try {
                          final (settings, sessions) = await _fileService
                              .importDataFromJson(path);
                          if (!context.mounted) return;
                          final confirmed = await _confirm(
                            context,
                            title: 'Remplacer les données ?',
                            message:
                                'Les ${sessionProvider.sessions.length} session(s) actuelle(s) seront remplacées par les ${sessions.length} session(s) du fichier.',
                          );
                          if (!confirmed) return;
                          await settingsProvider.replaceFromImport(settings);
                          await sessionProvider.replaceAllSessions(sessions);
                          _syncControllers(settingsProvider);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Import JSON terminé.'),
                            ),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                e is FormatException
                                    ? e.message
                                    : 'Import impossible : $e',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    _SettingsActionCard(
                      icon: Icons.delete_forever,
                      color: AppPalette.of(context).coral,
                      title: 'Supprimer',
                      subtitle: 'Tout effacer',
                      onTap: () async {
                        final confirmed = await _confirm(
                          context,
                          title: 'Suppression complète',
                          message:
                              'Toutes les sessions, preuves (fichiers compris), exports, réglages et clés API seront définitivement supprimés.',
                        );
                        if (confirmed) {
                          await sessionProvider.clearAll();
                          await settingsProvider.resetAll();
                          await _fileService.deleteAllLocalFiles();
                          _syncControllers(settingsProvider);
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

  void _syncControllers(SettingsProvider settingsProvider) {
    _otherWebCtrl.text = settingsProvider.settings.otherPlatformWebUrl;
    _otherAppCtrl.text = settingsProvider.settings.otherPlatformAppScheme;
    _apiKeyCtrl.text = settingsProvider.currentAiApiKey;
  }

  // An imported or legacy model may not be offered for the current provider.
  String _modelValue(SettingsProvider settingsProvider) {
    final models = settingsProvider.aiModelsForProvider(
      settingsProvider.settings.aiProvider,
    );
    final current = settingsProvider.settings.aiModel;
    return models.contains(current) ? current : models.first;
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    return confirmed == true;
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.color,
    required this.title,
  });

  final IconData icon;
  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppPalette.of(context).badge(color),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _SettingsActionCard extends StatelessWidget {
  const _SettingsActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppPalette.of(context).tint(color),
      elevation: 0,
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

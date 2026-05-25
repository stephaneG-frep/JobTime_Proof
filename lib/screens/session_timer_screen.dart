import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

import '../providers/session_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/quick_start_card.dart';

class SessionTimerScreen extends StatefulWidget {
  const SessionTimerScreen({super.key});

  @override
  State<SessionTimerScreen> createState() => _SessionTimerScreenState();
}

class _SessionTimerScreenState extends State<SessionTimerScreen> {
  final _notesController = TextEditingController();
  final _manualUrlController = TextEditingController();
  final Map<String, Uri> _platformWebUrls = {
    'France Travail': Uri.parse('https://www.francetravail.fr'),
    'Indeed': Uri.parse('https://fr.indeed.com'),
    'Hellowork': Uri.parse('https://www.hellowork.com/fr-fr/emploi.html'),
    'LinkedIn': Uri.parse('https://www.linkedin.com/jobs'),
    'Apec': Uri.parse('https://www.apec.fr'),
    'Welcome to the Jungle': Uri.parse('https://www.welcometothejungle.com/fr'),
  };

  final Map<String, Uri> _platformAppUrls = {
    'France Travail': Uri.parse('francetravail://'),
    'Indeed': Uri.parse('indeed://'),
    'Hellowork': Uri.parse('hellowork://'),
    'LinkedIn': Uri.parse('linkedin://jobs'),
    'Apec': Uri.parse('apec://'),
    'Welcome to the Jungle': Uri.parse('welcometothejungle://'),
  };

  String _formatTime(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<bool> _openPlatform({
    required Uri? platformWebUrl,
    required Uri? platformAppUrl,
  }) async {
    var opened = false;
    final isMobile = Platform.isAndroid || Platform.isIOS;

    if (isMobile && platformAppUrl != null) {
      try {
        opened = await launchUrl(
          platformAppUrl,
          mode: LaunchMode.externalNonBrowserApplication,
        );
      } catch (_) {
        opened = false;
      }
    }

    if (!opened && platformWebUrl != null) {
      try {
        opened = await launchUrl(
          platformWebUrl,
          mode: LaunchMode.platformDefault,
        );
      } catch (_) {
        opened = false;
      }
    }

    return opened;
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    Uri? platformWebUrl = _platformWebUrls[sessionProvider.selectedPlatform];
    Uri? platformAppUrl = _platformAppUrls[sessionProvider.selectedPlatform];
    if (sessionProvider.selectedPlatform == 'Autre') {
      final webRaw = settingsProvider.settings.otherPlatformWebUrl.trim();
      final appRaw = settingsProvider.settings.otherPlatformAppScheme.trim();
      if (webRaw.isNotEmpty) {
        platformWebUrl = Uri.tryParse(webRaw);
      }
      if (appRaw.isNotEmpty) {
        platformAppUrl = Uri.tryParse(appRaw);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Session de recherche',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        if (sessionProvider.pendingSharedUrl != null)
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lien partagé reçu',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(sessionProvider.pendingSharedUrl!),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            final sharedUrl =
                                sessionProvider.consumePendingSharedUrl();
                            if (sharedUrl == null || sharedUrl.isEmpty) return;
                            sessionProvider.addDraftUrl(sharedUrl);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lien ajouté à la session en cours.'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_link),
                          label: const Text('Ajouter à la session en cours'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: sessionProvider.clearPendingSharedUrl,
                        icon: const Icon(Icons.close),
                        tooltip: 'Ignorer',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ajouter un lien (session en cours)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _manualUrlController,
                  decoration: const InputDecoration(
                    hintText: 'https://...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () async {
                    final raw = _manualUrlController.text.trim();
                    final uri = Uri.tryParse(raw);
                    final valid = uri != null &&
                        (uri.scheme == 'http' || uri.scheme == 'https') &&
                        uri.host.isNotEmpty;
                    if (!valid) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('URL invalide. Exemple: https://...'),
                          ),
                        );
                      }
                      return;
                    }
                    sessionProvider.addDraftUrl(raw);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lien ajouté à la session en cours.'),
                      ),
                    );
                    _manualUrlController.clear();
                  },
                  icon: const Icon(Icons.add_link),
                  label: const Text('Ajouter le lien'),
                ),
                if (sessionProvider.draftUrls.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'URLs en attente (seront sauvegardées à la fin)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  ...sessionProvider.draftUrls.asMap().entries.map(
                    (entry) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.link, size: 18),
                      title: Text(
                        entry.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        onPressed: () =>
                            sessionProvider.removeDraftUrlAt(entry.key),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: sessionProvider.selectedPlatform,
          decoration: const InputDecoration(
            labelText: 'Plateforme',
            border: OutlineInputBorder(),
          ),
          items: settingsProvider.allPlatforms
              .map(
                (platform) =>
                    DropdownMenuItem(value: platform, child: Text(platform)),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) sessionProvider.setPlatform(v);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: sessionProvider.selectedActionType,
          decoration: const InputDecoration(
            labelText: 'Type d\'action',
            border: OutlineInputBorder(),
          ),
          items: sessionProvider.actionTypes
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: (v) {
            if (v != null) sessionProvider.setActionType(v);
          },
        ),
        const SizedBox(height: 12),
        QuickStartCard(
          platform: sessionProvider.selectedPlatform,
          enabled: platformWebUrl != null,
          onPressed: platformWebUrl == null
              ? null
              : () async {
                  final opened = await _openPlatform(
                    platformWebUrl: platformWebUrl,
                    platformAppUrl: platformAppUrl,
                  );
                  if (opened && !sessionProvider.isRunning) {
                    sessionProvider.startSession();
                  }
                  if (!opened && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Impossible d’ouvrir la plateforme sur cet appareil.',
                        ),
                      ),
                    );
                  }
                },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Notes',
            hintText:
                'Ex: offres ciblées, retours recruteurs, actions réalisées',
            border: OutlineInputBorder(),
          ),
          onChanged: sessionProvider.setDraftNotes,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  _formatTime(sessionProvider.elapsedSeconds),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 6),
                Text(
                  sessionProvider.isPaused
                      ? 'Session en pause'
                      : (sessionProvider.isRunning
                            ? 'Session en cours'
                            : 'Prêt à démarrer'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    sessionProvider.isRunning && !sessionProvider.isPaused
                    ? null
                    : () {
                        sessionProvider.startSession();
                      },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Démarrer'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    sessionProvider.isRunning && !sessionProvider.isPaused
                    ? () {
                        sessionProvider.pauseSession();
                      }
                    : null,
                icon: const Icon(Icons.pause),
                label: const Text('Pause'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: sessionProvider.isRunning
              ? () async {
                  sessionProvider.setDraftNotes(_notesController.text);
                  final saved = await sessionProvider.endSession();
                  _notesController.clear();
                  if (saved != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Session sauvegardée automatiquement.'),
                      ),
                    );
                  }
                }
              : null,
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text('Terminer'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _manualUrlController.dispose();
    super.dispose();
  }
}

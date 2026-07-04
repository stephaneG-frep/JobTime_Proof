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
  int _estimatedMinutes = 30;
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

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (hours == 0) return '$minutes min';
    if (remaining == 0) return '${hours}h';
    return '${hours}h ${remaining.toString().padLeft(2, '0')}';
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
    final platforms = settingsProvider.allPlatforms;
    final selectedPlatform = _safeDropdownValue(
      sessionProvider.selectedPlatform,
      platforms,
      fallback: 'France Travail',
    );
    final actionTypes = sessionProvider.actionTypes;
    final selectedActionType = _safeDropdownValue(
      sessionProvider.selectedActionType,
      actionTypes,
      fallback: actionTypes.first,
    );

    Uri? platformWebUrl = _platformWebUrls[selectedPlatform];
    Uri? platformAppUrl = _platformAppUrls[selectedPlatform];
    if (selectedPlatform == 'Autre') {
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
          'Session estimée',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Déclarez le temps passé par tranches de 10 minutes, sans chronomètre.',
          style: Theme.of(context).textTheme.bodyMedium,
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
                            final sharedUrl = sessionProvider
                                .consumePendingSharedUrl();
                            if (sharedUrl == null || sharedUrl.isEmpty) return;
                            sessionProvider.addDraftUrl(sharedUrl);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Lien ajouté à la session en cours.',
                                ),
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
                    final valid =
                        uri != null &&
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
                    'URLs en attente',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  ...sessionProvider.draftUrls.asMap().entries.map(
                    (entry) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        sessionProvider.draftUrlDidApply.length > entry.key &&
                                sessionProvider.draftUrlDidApply[entry.key]
                            ? Icons.check_circle
                            : Icons.link,
                        size: 20,
                        color:
                            sessionProvider.draftUrlDidApply.length >
                                    entry.key &&
                                sessionProvider.draftUrlDidApply[entry.key]
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(
                        entry.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        sessionProvider.draftUrlDidApply.length > entry.key &&
                                sessionProvider.draftUrlDidApply[entry.key]
                            ? 'Postulé'
                            : 'Non postulé',
                      ),
                      trailing: Wrap(
                        spacing: 2,
                        children: [
                          IconButton(
                            tooltip:
                                sessionProvider.draftUrlDidApply.length >
                                        entry.key &&
                                    sessionProvider.draftUrlDidApply[entry.key]
                                ? 'Marquer non postulé'
                                : 'Marquer postulé',
                            onPressed: () {
                              final current =
                                  sessionProvider.draftUrlDidApply.length >
                                      entry.key &&
                                  sessionProvider.draftUrlDidApply[entry.key];
                              sessionProvider.setDraftUrlDidApplyAt(
                                entry.key,
                                !current,
                              );
                            },
                            icon: Icon(
                              sessionProvider.draftUrlDidApply.length >
                                          entry.key &&
                                      sessionProvider.draftUrlDidApply[entry
                                          .key]
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Retirer le lien',
                            onPressed: () =>
                                sessionProvider.removeDraftUrlAt(entry.key),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: selectedPlatform,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Plateforme',
            border: OutlineInputBorder(),
          ),
          items: platforms
              .map(
                (platform) => DropdownMenuItem(
                  value: platform,
                  child: Text(platform, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) sessionProvider.setPlatform(v);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: selectedActionType,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Type d\'action',
            border: OutlineInputBorder(),
          ),
          items: actionTypes
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(type, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) sessionProvider.setActionType(v);
          },
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Candidature',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Oui'),
                      icon: Icon(Icons.check_circle_outline),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Non'),
                      icon: Icon(Icons.radio_button_unchecked),
                    ),
                  ],
                  selected: {sessionProvider.draftDidApply},
                  onSelectionChanged: (selected) {
                    sessionProvider.setDraftDidApply(selected.first);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        QuickStartCard(
          platform: selectedPlatform,
          enabled: platformWebUrl != null,
          onPressed: platformWebUrl == null
              ? null
              : () async {
                  final opened = await _openPlatform(
                    platformWebUrl: platformWebUrl,
                    platformAppUrl: platformAppUrl,
                  );
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
                const Text(
                  'Temps estimé',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatMinutes(_estimatedMinutes),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _estimatedMinutes <= 10
                            ? null
                            : () => setState(() => _estimatedMinutes -= 10),
                        icon: const Icon(Icons.remove),
                        label: const Text('-10 min'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            setState(() => _estimatedMinutes += 10),
                        icon: const Icon(Icons.add),
                        label: const Text('+10 min'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [10, 20, 30, 60, 90, 120]
                      .map(
                        (minutes) => ChoiceChip(
                          label: Text(_formatMinutes(minutes)),
                          selected: _estimatedMinutes == minutes,
                          onSelected: (_) =>
                              setState(() => _estimatedMinutes = minutes),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () async {
            sessionProvider.setDraftNotes(_notesController.text);
            await sessionProvider.saveEstimatedSession(
              minutes: _estimatedMinutes,
            );
            _notesController.clear();
            _manualUrlController.clear();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Session sauvegardée avec ${_formatMinutes(_estimatedMinutes)}.',
                  ),
                ),
              );
            }
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text('Sauvegarder la session'),
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

  String _safeDropdownValue(
    String selected,
    List<String> values, {
    required String fallback,
  }) {
    if (values.contains(selected)) return selected;
    final selectedKey = selected.trim().toLowerCase();
    for (final value in values) {
      if (value.trim().toLowerCase() == selectedKey) return value;
    }
    return values.contains(fallback)
        ? fallback
        : values.isNotEmpty
        ? values.first
        : selected;
  }
}

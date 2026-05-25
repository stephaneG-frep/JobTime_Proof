import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../services/ai_service.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _inputCtrl = TextEditingController();
  final _aiService = AiService();
  String _result = '';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final settings = settingsProvider.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Assistant IA')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Collez les infos d\'annonce, notes de session ou texte libre. L\'IA génère un résumé pro + suggestion postulé oui/non.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _inputCtrl,
            maxLines: 8,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Entrée IA',
              hintText: 'Ex: annonce, notes, actions réalisées... ',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (settingsProvider.currentAiApiKey.trim().isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Ajoute d\'abord la clé API dans Paramètres IA.',
                          ),
                        ),
                      );
                      return;
                    }
                    if (_inputCtrl.text.trim().isEmpty) return;

                    setState(() => _loading = true);
                    try {
                      final text = await _aiService
                          .generateSessionAssistantText(
                            provider: settings.aiProvider,
                            apiKey: settingsProvider.currentAiApiKey,
                            model: settings.aiModel,
                            input: _inputCtrl.text.trim(),
                          );
                      if (mounted) {
                        setState(() => _result = text);
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Erreur IA: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  },
            icon: const Icon(Icons.auto_awesome),
            label: Text(
              _loading ? 'Génération en cours...' : 'Générer avec IA',
            ),
          ),
          const SizedBox(height: 14),
          if (_result.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résultat IA',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(_result),
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: _result));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Résultat copié.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copier le résultat'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }
}

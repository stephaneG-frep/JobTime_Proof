import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/job_proof.dart';
import '../models/job_session.dart';
import '../providers/session_provider.dart';
import '../services/file_service.dart';
import '../widgets/proof_card.dart';

class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final _fileService = FileService();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SessionProvider>();
    JobSession? session;
    for (final s in provider.sessions) {
      if (s.id == widget.sessionId) {
        session = s;
        break;
      }
    }

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session')),
        body: const Center(child: Text('Session introuvable')),
      );
    }
    final activeSession = session;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail session'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await provider.deleteSession(activeSession.id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (provider.pendingSharedUrl != null)
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lien partagé détecté',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(provider.pendingSharedUrl!),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () async {
                        final sharedUrl = provider.consumePendingSharedUrl();
                        if (sharedUrl == null || sharedUrl.isEmpty) return;
                        final proof = JobProof(
                          id: DateTime.now().microsecondsSinceEpoch.toString(),
                          sessionId: activeSession.id,
                          title: 'Annonce partagée',
                          type: JobProofType.url,
                          url: sharedUrl,
                          createdAt: DateTime.now(),
                        );
                        await provider.addProof(activeSession.id, proof);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Lien ajouté en preuve URL.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.link),
                      label: const Text('Ajouter en preuve URL'),
                    ),
                  ],
                ),
              ),
            ),
          Text(
            '${activeSession.platform} - ${activeSession.actionType}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Notes: ${activeSession.notes.isEmpty ? 'Aucune' : activeSession.notes}',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _addProofDialog(context, activeSession),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une preuve'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (activeSession.proofs.isEmpty)
            const Text('Aucune preuve pour cette session.')
          else
            ...activeSession.proofs.map(
              (p) => ProofCard(
                proof: p,
                onShowQr: p.url != null && p.url!.trim().isNotEmpty
                    ? () => _showQrDialog(context, p.title, p.url!)
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showQrDialog(
    BuildContext context,
    String title,
    String url,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('QR - $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(data: url, version: QrVersions.auto, size: 220),
            const SizedBox(height: 8),
            SelectableText(url, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _addProofDialog(BuildContext context, JobSession session) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    JobProofType type = JobProofType.note;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle preuve'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Titre'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<JobProofType>(
                  initialValue: type,
                  items: JobProofType.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setStateDialog(() => type = v);
                  },
                ),
                if (type == JobProofType.url) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: urlCtrl,
                    decoration: const InputDecoration(labelText: 'URL'),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              String? path;
              String? url;

              if (type == JobProofType.image) {
                path = await _fileService.pickImage();
              }
              if (type == JobProofType.pdf) path = await _fileService.pickPdf();
              if (type == JobProofType.url) url = urlCtrl.text.trim();
              if ((type == JobProofType.pdf || type == JobProofType.image) &&
                  (path == null || path.trim().isEmpty)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Aucun fichier sélectionné pour la preuve.',
                      ),
                    ),
                  );
                }
                return;
              }
              if (type == JobProofType.url && (url == null || url.isEmpty)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez saisir une URL valide.'),
                    ),
                  );
                }
                return;
              }

              final proof = JobProof(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                sessionId: session.id,
                title: titleCtrl.text.trim(),
                type: type,
                filePath: path,
                url: url,
                description: descCtrl.text.trim().isEmpty
                    ? null
                    : descCtrl.text.trim(),
                createdAt: DateTime.now(),
              );

              if (!context.mounted) return;
              final sessionProvider = context.read<SessionProvider>();
              await sessionProvider.addProof(session.id, proof);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}

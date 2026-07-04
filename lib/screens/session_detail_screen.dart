import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'J\'ai postulé',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(value: true, label: Text('Oui')),
                      ButtonSegment<bool>(value: false, label: Text('Non')),
                    ],
                    selected: {activeSession.didApply},
                    onSelectionChanged: (selected) async {
                      final value = selected.first;
                      await provider.updateSession(
                        activeSession.copyWith(didApply: value),
                      );
                    },
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
                onDidApplyChanged: p.url != null && p.url!.trim().isNotEmpty
                    ? (value) => provider.setProofDidApply(
                        sessionId: activeSession.id,
                        proofId: p.id,
                        didApply: value,
                      )
                    : null,
                onTap: () => _openProof(context, p),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openProof(BuildContext context, JobProof proof) async {
    switch (proof.type) {
      case JobProofType.image:
        if (proof.filePath == null || proof.filePath!.trim().isEmpty) {
          _showInfo(context, 'Aucune image associée à cette preuve.');
          return;
        }
        await _showImagePreview(context, proof.title, proof.filePath!);
        break;
      case JobProofType.pdf:
        if (proof.filePath == null || proof.filePath!.trim().isEmpty) {
          _showInfo(context, 'Aucun PDF associé à cette preuve.');
          return;
        }
        final opened = await launchUrl(
          Uri.file(proof.filePath!),
          mode: LaunchMode.externalApplication,
        );
        if (!opened && context.mounted) {
          _showInfo(context, 'Impossible d’ouvrir le PDF sur cet appareil.');
        }
        break;
      case JobProofType.url:
        if (proof.url == null || proof.url!.trim().isEmpty) {
          _showInfo(context, 'Aucune URL associée à cette preuve.');
          return;
        }
        final uri = Uri.tryParse(proof.url!.trim());
        if (uri == null) {
          _showInfo(context, 'URL invalide.');
          return;
        }
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!opened && context.mounted) {
          _showInfo(context, 'Impossible d’ouvrir ce lien.');
        }
        break;
      case JobProofType.note:
        _showInfo(
          context,
          proof.description?.trim().isNotEmpty == true
              ? proof.description!
              : 'Cette preuve ne contient pas de texte.',
        );
        break;
    }
  }

  Future<void> _showImagePreview(
    BuildContext context,
    String title,
    String filePath,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.file(
                  File(filePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Impossible de charger cette image.'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showInfo(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
              String? path;
              String? url;

              if (type == JobProofType.image) {
                path = await _pickImageSource(context);
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
              final title = titleCtrl.text.trim().isNotEmpty
                  ? titleCtrl.text.trim()
                  : _defaultProofTitle(type);

              final proof = JobProof(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                sessionId: session.id,
                title: title,
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
              final updated = await sessionProvider.addProof(session.id, proof);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Preuve ajoutée à la session (${updated?.proofCount ?? 1}).',
                    ),
                  ),
                );
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickImageSource(BuildContext context) async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
          ],
        ),
      ),
    );

    if (source == 'camera') {
      return _fileService.pickImageFromCamera();
    }
    if (source == 'gallery') {
      return _fileService.pickImageFromGallery();
    }
    return null;
  }

  String _defaultProofTitle(JobProofType type) {
    switch (type) {
      case JobProofType.image:
        return 'Capture d’écran';
      case JobProofType.pdf:
        return 'Document PDF';
      case JobProofType.url:
        return 'Lien';
      case JobProofType.note:
        return 'Note';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/job_proof.dart';
import '../theme/app_palette.dart';

class ProofCard extends StatelessWidget {
  const ProofCard({
    super.key,
    required this.proof,
    this.onShowQr,
    this.onTap,
    this.onDidApplyChanged,
  });

  final JobProof proof;
  final VoidCallback? onShowQr;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onDidApplyChanged;

  IconData _icon(JobProofType type) {
    switch (type) {
      case JobProofType.image:
        return Icons.image;
      case JobProofType.pdf:
        return Icons.picture_as_pdf;
      case JobProofType.url:
        return Icons.link;
      case JobProofType.note:
        return Icons.note;
    }
  }

  Color _color(AppPalette palette) {
    if (proof.didApply) return palette.green;
    switch (proof.type) {
      case JobProofType.image:
        return palette.purple;
      case JobProofType.pdf:
        return palette.coral;
      case JobProofType.url:
        return palette.blue;
      case JobProofType.note:
        return palette.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final accent = _color(palette);
    return Card(
      color: palette.tint(accent),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: palette.badge(accent),
          child: Icon(
            proof.didApply ? Icons.check_circle : _icon(proof.type),
            color: accent,
          ),
        ),
        title: Text(proof.title),
        subtitle: Text(
          '${proof.didApply ? 'Postulé\n' : ''}${proof.description ?? ''}\n${DateFormat('dd/MM/yyyy HH:mm').format(proof.createdAt)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: proof.url != null && proof.url!.trim().isNotEmpty
            ? Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    onPressed: onShowQr,
                    icon: const Icon(Icons.qr_code_2),
                    tooltip: 'Afficher QR',
                  ),
                  IconButton(
                    onPressed: onDidApplyChanged == null
                        ? null
                        : () => onDidApplyChanged!(!proof.didApply),
                    icon: Icon(
                      proof.didApply
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                    ),
                    tooltip: proof.didApply
                        ? 'Marquer non postulé'
                        : 'Marquer postulé',
                  ),
                ],
              )
            : null,
      ),
    );
  }
}

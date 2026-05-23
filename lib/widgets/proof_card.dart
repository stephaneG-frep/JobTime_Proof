import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/job_proof.dart';

class ProofCard extends StatelessWidget {
  const ProofCard({super.key, required this.proof});

  final JobProof proof;

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

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(_icon(proof.type)),
        title: Text(proof.title),
        subtitle: Text(
          '${proof.description ?? ''}\n${DateFormat('dd/MM/yyyy HH:mm').format(proof.createdAt)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

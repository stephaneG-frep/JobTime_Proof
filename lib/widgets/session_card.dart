import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/job_session.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({super.key, required this.session, this.onTap});

  final JobSession session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final start = DateFormat('dd/MM/yyyy HH:mm').format(session.startTime);
    final duration = '${(session.durationSeconds / 60).toStringAsFixed(0)} min';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          session.proofs.isEmpty
              ? Icons.warning_amber_outlined
              : Icons.verified_outlined,
          color: session.proofs.isEmpty
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          '${session.platform} - ${session.actionType}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$start • $duration\nPreuves: ${session.proofs.length}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

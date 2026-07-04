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
          session.hasProofs
              ? Icons.verified_outlined
              : Icons.warning_amber_outlined,
          color: session.hasProofs
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        title: Text(
          '${session.platform} - ${session.actionType}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$start • $duration\n${session.hasProofs ? 'Preuves: ${session.proofCount}' : 'Aucune preuve'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: Icon(
          session.hasProofs ? Icons.check_circle_outline : Icons.chevron_right,
          color: session.hasProofs
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
      ),
    );
  }
}

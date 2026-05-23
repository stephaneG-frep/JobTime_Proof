import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/job_session.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({super.key, required this.session, this.onTap});

  final JobSession session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final start = DateFormat('dd/MM HH:mm').format(session.startTime);
    final duration = '${(session.durationSeconds / 60).toStringAsFixed(0)} min';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        title: Text('${session.platform} - ${session.actionType}'),
        subtitle: Text('$start • $duration\nPreuves: ${session.proofs.length}'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/job_session.dart';
import '../theme/app_palette.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({super.key, required this.session, this.onTap});

  final JobSession session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final accent = palette.forActionType(session.actionType);
    final start = DateFormat('dd/MM/yyyy HH:mm').format(session.startTime);
    final duration = '${(session.durationSeconds / 60).toStringAsFixed(0)} min';

    return Card(
      color: palette.tint(accent),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        // Colored edge: the action type at a glance.
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: accent, width: 5)),
        ),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: palette.badge(accent),
            child: Icon(
              AppPalette.iconForActionType(session.actionType),
              color: accent,
            ),
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
            session.hasProofs
                ? Icons.verified_outlined
                : Icons.warning_amber_outlined,
            color: session.hasProofs ? palette.green : palette.orange,
          ),
        ),
      ),
    );
  }
}

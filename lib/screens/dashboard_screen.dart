import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_palette.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _hms(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<SessionProvider>();
    final settings = context.watch<SettingsProvider>();
    final palette = AppPalette.of(context);

    final today = sessions.totalSecondsToday();
    final week = sessions.totalSecondsWeek();
    final goalSeconds = settings.settings.weeklyGoalHours * 3600;
    final missingProofs = sessions.sessionsWithoutProofCount();
    final progress = goalSeconds == 0
        ? 0.0
        : (week / goalSeconds).clamp(0, 1).toDouble();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Tableau de bord',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            StatCard(
              title: 'Aujourd\'hui',
              value: _hms(today),
              icon: Icons.today,
              color: palette.blue,
            ),
            StatCard(
              title: 'Semaine',
              value: _hms(week),
              icon: Icons.date_range,
              color: palette.teal,
            ),
            StatCard(
              title: 'Sessions',
              value: '${sessions.sessions.length}',
              icon: Icons.timer,
              color: palette.purple,
            ),
            StatCard(
              title: 'Sans preuve',
              value: '$missingProofs',
              icon: Icons.warning_amber_outlined,
              color: missingProofs == 0 ? palette.green : palette.orange,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          color: palette.tint(palette.green),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.flag_outlined, color: palette.green),
                    const SizedBox(width: 8),
                    Text(
                      'Objectif hebdomadaire: ${settings.settings.weeklyGoalHours} h',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  color: palette.green,
                  backgroundColor: palette.badge(palette.green),
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 8),
                Text('${(progress * 100).toStringAsFixed(0)}% atteint'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/job_session.dart';
import '../providers/session_provider.dart';
import '../services/pdf_report_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTimeRange? _range;
  final _pdfService = PdfReportService();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SessionProvider>();
    final from = _range?.start;
    final to = _range?.end;
    final sessions = (from != null && to != null)
        ? provider.sessionsForPeriod(from, to)
        : <JobSession>[];
    final totalSeconds = sessions.fold<int>(
      0,
      (sum, s) => sum + s.durationSeconds,
    );
    final applicationsCount = sessions
        .where((s) => s.actionType.toLowerCase().contains('candidature'))
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Rapport PDF', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _range == null
                      ? 'Sélectionnez une période'
                      : 'Période: ${_dateFormat.format(_range!.start)} - ${_dateFormat.format(_range!.end)}',
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(now.year - 2),
                      lastDate: DateTime(now.year + 1),
                    );
                    if (picked != null) {
                      setState(() => _range = picked);
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: const Text('Choisir la période'),
                ),
                if (_range != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.timer_outlined, size: 18),
                        label: Text(
                          'Temps total: ${_formatDuration(totalSeconds)}',
                        ),
                      ),
                      Chip(
                        avatar: const Icon(Icons.history, size: 18),
                        label: Text('Sessions: ${sessions.length}'),
                      ),
                      Chip(
                        avatar: const Icon(Icons.send_outlined, size: 18),
                        label: Text('Candidatures: $applicationsCount'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _range == null || sessions.isEmpty
                      ? null
                      : () async {
                          final sessions = provider.sessionsForPeriod(
                            _range!.start,
                            _range!.end,
                          );
                          await _pdfService.exportReport(
                            from: _range!.start,
                            to: _range!.end,
                            sessions: sessions,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Prévisualisation PDF ouverte.'),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Générer le rapport PDF'),
                ),
                if (_range != null && sessions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      'Aucune session sur cette période. Choisissez une autre plage de dates.',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

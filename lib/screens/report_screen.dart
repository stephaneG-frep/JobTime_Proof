import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SessionProvider>();

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
                      : 'Période: ${_range!.start.day}/${_range!.start.month}/${_range!.start.year} - ${_range!.end.day}/${_range!.end.month}/${_range!.end.year}',
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
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _range == null
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}

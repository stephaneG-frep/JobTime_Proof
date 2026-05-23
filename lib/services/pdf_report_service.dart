import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/job_session.dart';

class PdfReportService {
  Future<void> exportReport({
    required DateTime from,
    required DateTime to,
    required List<JobSession> sessions,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final totalSeconds = sessions.fold<int>(
      0,
      (sum, s) => sum + s.durationSeconds,
    );
    final totalHours = (totalSeconds / 3600).toStringAsFixed(2);
    final candidatures = sessions
        .where((s) => s.actionType.toLowerCase().contains('candidature'))
        .length;
    final platforms = sessions.map((e) => e.platform).toSet().toList()..sort();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'JobTime Proof - Rapport d\'activité',
              style: pw.TextStyle(fontSize: 22),
            ),
          ),
          pw.Text(
            'Période: ${DateFormat('dd/MM/yyyy').format(from)} au ${DateFormat('dd/MM/yyyy').format(to)}',
          ),
          pw.SizedBox(height: 10),
          pw.Text('Date de génération: ${dateFormat.format(DateTime.now())}'),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Temps total: $totalHours h'),
                pw.Text('Nombre de sessions: ${sessions.length}'),
                pw.Text('Candidatures envoyées: $candidatures'),
                pw.Text('Plateformes utilisées: ${platforms.join(', ')}'),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Détail des sessions',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          ...sessions.map(
            (s) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${s.platform} - ${s.actionType}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Début: ${dateFormat.format(s.startTime)} | Fin: ${dateFormat.format(s.endTime)}',
                  ),
                  pw.Text(
                    'Durée: ${(s.durationSeconds / 60).toStringAsFixed(1)} min',
                  ),
                  if (s.notes.trim().isNotEmpty)
                    pw.Text('Notes: ${s.notes.trim()}'),
                  if (s.proofs.isNotEmpty)
                    pw.Text(
                      'Preuves: ${s.proofs.map((p) => p.title).join(' | ')}',
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }
}

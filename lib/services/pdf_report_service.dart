import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
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
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    final shortDateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');

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
            'Période: ${shortDateFormat.format(from)} au ${shortDateFormat.format(to)}',
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
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.2),
              1: pw.FlexColumnWidth(2.4),
              2: pw.FlexColumnWidth(2.4),
              3: pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Plateforme / Action',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Début',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Fin',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Durée',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              ...sessions.map(
                (s) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('${s.platform}\n${s.actionType}'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(dateFormat.format(s.startTime)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(dateFormat.format(s.endTime)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        '${(s.durationSeconds / 60).toStringAsFixed(1)} min',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          ...sessions.map(
            (s) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.4)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (s.notes.trim().isNotEmpty)
                    pw.Text('Notes: ${s.notes.trim()}'),
                  if (s.proofs.isNotEmpty) ...[
                    pw.Text(
                      'Preuves: ${s.proofs.map((p) => p.title).join(' | ')}',
                    ),
                    pw.SizedBox(height: 6),
                    ...s.proofs
                        .where(
                          (p) =>
                              p.url != null &&
                              p.url!.trim().isNotEmpty &&
                              p.type.name == 'url',
                        )
                        .map(
                          (p) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 6),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Container(
                                  width: 56,
                                  height: 56,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(width: 0.5),
                                  ),
                                  child: pw.BarcodeWidget(
                                    barcode: pw.Barcode.qrCode(),
                                    data: p.url!.trim(),
                                  ),
                                ),
                                pw.SizedBox(width: 8),
                                pw.Expanded(
                                  child: pw.Text(
                                    'QR ${p.title}: ${p.url!.trim()}',
                                    style: const pw.TextStyle(fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
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

import 'dart:io';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/job_proof.dart';
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
    final candidatures = sessions.where((s) => s.didApply).length;
    final platforms = sessions.map((e) => e.platform).toSet().toList()..sort();
    final sessionsByStart = [...sessions]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final totalsByPlatform = <String, int>{};
    for (final s in sessions) {
      totalsByPlatform[s.platform] =
          (totalsByPlatform[s.platform] ?? 0) + s.durationSeconds;
    }

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
            'Total par plateforme',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Plateforme',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Temps',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              ...totalsByPlatform.entries.map(
                (entry) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(entry.key),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(_formatDuration(entry.value)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Chronologie des sessions',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          ...sessionsByStart.map(
            (s) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                '${dateFormat.format(s.startTime)} - ${s.platform} - ${s.actionType} (${_formatDuration(s.durationSeconds)})',
                style: const pw.TextStyle(fontSize: 10),
              ),
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
                  if (s.proofs.isNotEmpty) ..._buildProofWidgets(s.proofs),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  Future<void> exportPresentationReport({
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
    final applicationsCount = sessions.where((s) => s.didApply).length;
    final byPlatform = <String, int>{};
    for (final s in sessions) {
      byPlatform[s.platform] =
          (byPlatform[s.platform] ?? 0) + s.durationSeconds;
    }
    final topSessions = [...sessions]
      ..sort((a, b) => b.durationSeconds.compareTo(a.durationSeconds));

    pdf.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'JobTime Proof - Rapport de présentation',
              style: pw.TextStyle(fontSize: 22),
            ),
          ),
          pw.Text(
            'Période: ${shortDateFormat.format(from)} au ${shortDateFormat.format(to)}',
          ),
          pw.Text('Généré le: ${dateFormat.format(DateTime.now())}'),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Temps total: ${_formatDuration(totalSeconds)}'),
                pw.Text('Sessions: ${sessions.length}'),
                pw.Text('Candidatures envoyées: $applicationsCount'),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Synthèse par plateforme',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          ...byPlatform.entries.map(
            (e) => pw.Text('• ${e.key}: ${_formatDuration(e.value)}'),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Sessions principales',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          ...topSessions
              .take(10)
              .map(
                (s) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    '• ${dateFormat.format(s.startTime)} - ${s.platform} - ${s.actionType} (${_formatDuration(s.durationSeconds)})',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  List<pw.Widget> _buildProofWidgets(List<JobProof> proofs) {
    final widgets = <pw.Widget>[
      pw.Text(
        'Preuves détaillées',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 6),
    ];

    for (final proof in proofs) {
      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 6),
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.3)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${_proofTypeLabel(proof.type)} - ${proof.title}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              if (proof.description != null &&
                  proof.description!.trim().isNotEmpty)
                pw.Text(
                  'Description: ${proof.description!.trim()}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ..._proofContentWidgets(proof),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  String _proofTypeLabel(JobProofType type) {
    switch (type) {
      case JobProofType.image:
        return 'Image';
      case JobProofType.pdf:
        return 'PDF';
      case JobProofType.url:
        return 'Lien';
      case JobProofType.note:
        return 'Note';
    }
  }

  List<pw.Widget> _proofContentWidgets(JobProof proof) {
    switch (proof.type) {
      case JobProofType.image:
        final path = proof.filePath?.trim();
        if (path == null || path.isEmpty) {
          return [
            pw.Text(
              'Image: non disponible',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ];
        }
        final file = File(path);
        if (!file.existsSync()) {
          return [
            pw.Text(
              'Image introuvable: $path',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ];
        }
        final bytes = file.readAsBytesSync();
        final image = pw.MemoryImage(bytes);
        return [
          pw.SizedBox(height: 4),
          pw.Container(
            height: 120,
            width: 120,
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.3)),
            child: pw.Image(image, fit: pw.BoxFit.cover),
          ),
        ];
      case JobProofType.pdf:
        final path = proof.filePath?.trim();
        if (path == null || path.isEmpty) {
          return [
            pw.Text(
              'PDF: non disponible',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ];
        }
        final filename = path.split('/').isNotEmpty
            ? path.split('/').last
            : path;
        return [
          pw.Text(
            'Fichier PDF: $filename',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ];
      case JobProofType.url:
        final url = proof.url?.trim();
        if (url == null || url.isEmpty) {
          return [
            pw.Text(
              'Lien: non disponible',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ];
        }
        return [
          pw.SizedBox(height: 4),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 52,
                height: 52,
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: url,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Text(url, style: const pw.TextStyle(fontSize: 9)),
              ),
            ],
          ),
        ];
      case JobProofType.note:
        return [
          pw.Text(
            'Note: ${(proof.description?.trim().isNotEmpty == true) ? proof.description!.trim() : proof.title}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ];
    }
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}';
  }
}

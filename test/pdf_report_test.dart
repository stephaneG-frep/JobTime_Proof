import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jobtime_proof/models/job_proof.dart';
import 'package:jobtime_proof/models/job_session.dart';
import 'package:jobtime_proof/services/pdf_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => initializeDateFormatting('fr_FR'));

  final when = DateTime(2026, 3, 4, 9, 30);
  final sessions = [
    JobSession(
      id: 's1',
      platform: 'Welcome to the Jungle',
      actionType: 'candidature envoyée',
      startTime: when,
      endTime: when.add(const Duration(minutes: 30)),
      durationSeconds: 1800,
      // Characters outside Latin-1 that the default PDF font cannot draw.
      notes: 'Relance prévue • l’offre « Dév » à 45 k€, cœur de métier',
      proofs: [
        JobProof(
          id: 'p1',
          sessionId: 's1',
          title: 'Annonce',
          type: JobProofType.url,
          url: 'https://exemple.fr/offre',
          didApply: true,
          createdAt: when,
        ),
        JobProof(
          id: 'p2',
          sessionId: 's1',
          title: 'Capture absente',
          type: JobProofType.image,
          filePath: '/inexistant/capture.jpg',
          createdAt: when,
        ),
      ],
      didApply: true,
      createdAt: when,
      updatedAt: when,
    ),
  ];

  test('le rapport détaillé se génère avec des caractères Unicode', () async {
    final bytes = await PdfReportService().buildReport(
      from: DateTime(2026, 3, 1),
      to: DateTime(2026, 3, 31),
      sessions: sessions,
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('le rapport de présentation se génère', () async {
    final bytes = await PdfReportService().buildPresentationReport(
      from: DateTime(2026, 3, 1),
      to: DateTime(2026, 3, 31),
      sessions: sessions,
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jobtime_proof/models/app_settings.dart';
import 'package:jobtime_proof/models/job_proof.dart';
import 'package:jobtime_proof/models/job_session.dart';

void main() {
  late Directory dir;

  setUpAll(() {
    Hive
      ..registerAdapter(JobProofTypeAdapter())
      ..registerAdapter(JobProofAdapter())
      ..registerAdapter(JobSessionAdapter())
      ..registerAdapter(AppSettingsAdapter());
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('jobtime_hive_test');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  final when = DateTime(2026, 3, 4, 9, 30);

  JobSession buildSession() => JobSession(
    id: 's1',
    platform: 'Indeed',
    actionType: 'entretien',
    startTime: when,
    endTime: when.add(const Duration(minutes: 40)),
    durationSeconds: 2400,
    notes: 'Entretien RH',
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
        title: 'Capture',
        type: JobProofType.image,
        filePath: '/tmp/capture.jpg',
        description: 'Écran de confirmation',
        createdAt: when,
      ),
    ],
    didApply: true,
    createdAt: when,
    updatedAt: when,
  );

  test('une session survit à la fermeture et réouverture de la box', () async {
    var box = await Hive.openBox<JobSession>('sessions');
    await box.put('s1', buildSession());
    await Hive.close();

    box = await Hive.openBox<JobSession>('sessions');
    final s = box.get('s1')!;

    expect(s.platform, 'Indeed');
    expect(s.actionType, 'entretien');
    expect(s.startTime, when);
    expect(s.durationSeconds, 2400);
    expect(s.notes, 'Entretien RH');
    expect(s.didApply, isTrue);
    expect(s.proofs, hasLength(2));
    expect(s.proofs[0].type, JobProofType.url);
    expect(s.proofs[0].url, 'https://exemple.fr/offre');
    expect(s.proofs[0].didApply, isTrue);
    expect(s.proofs[1].type, JobProofType.image);
    expect(s.proofs[1].filePath, '/tmp/capture.jpg');
    expect(s.proofs[1].description, 'Écran de confirmation');
  });

  test(
    'les réglages survivent à la fermeture et réouverture de la box',
    () async {
      final backupAt = DateTime(2026, 3, 5, 8);
      var box = await Hive.openBox<AppSettings>('settings');
      await box.put(
        'main',
        AppSettings.initial().copyWith(
          weeklyGoalHours: 25,
          customPlatforms: ['Cadremploi'],
          otherPlatformWebUrl: 'https://exemple.fr/jobs',
          otherPlatformAppScheme: 'exemple://',
          darkModeEnabled: true,
          aiProvider: 'mistral',
          aiModel: 'mistral-small-latest',
          lastAutoBackupAt: backupAt,
        ),
      );
      await Hive.close();

      box = await Hive.openBox<AppSettings>('settings');
      final a = box.get('main')!;

      expect(a.weeklyGoalHours, 25);
      expect(a.customPlatforms, ['Cadremploi']);
      expect(a.otherPlatformWebUrl, 'https://exemple.fr/jobs');
      expect(a.otherPlatformAppScheme, 'exemple://');
      expect(a.darkModeEnabled, isTrue);
      expect(a.aiProvider, 'mistral');
      expect(a.aiModel, 'mistral-small-latest');
      expect(a.lastAutoBackupAt, backupAt);
    },
  );

  test('aller-retour JSON d\'une session', () {
    final original = buildSession();
    final restored = JobSession.fromJson(original.toJson());

    expect(restored.toJson(), original.toJson());
  });
}

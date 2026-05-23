import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_settings.dart';
import '../models/job_proof.dart';
import '../models/job_session.dart';

class HiveService {
  static const sessionsBoxName = 'job_sessions_box';
  static const settingsBoxName = 'app_settings_box';

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive
      ..registerAdapter(JobProofTypeAdapter())
      ..registerAdapter(JobProofAdapter())
      ..registerAdapter(JobSessionAdapter())
      ..registerAdapter(AppSettingsAdapter());

    await Hive.openBox<JobSession>(sessionsBoxName);
    await Hive.openBox<AppSettings>(settingsBoxName);
  }

  static Box<JobSession> get sessionsBox =>
      Hive.box<JobSession>(sessionsBoxName);
  static Box<AppSettings> get settingsBox =>
      Hive.box<AppSettings>(settingsBoxName);
}

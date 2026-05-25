import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_settings.dart';
import '../models/job_proof.dart';
import '../models/job_session.dart';

class HiveService {
  static const sessionsBoxName = 'job_sessions_box';
  static const settingsBoxName = 'app_settings_box';
  static const runtimeBoxName = 'runtime_state_box';

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive
      ..registerAdapter(JobProofTypeAdapter())
      ..registerAdapter(JobProofAdapter())
      ..registerAdapter(JobSessionAdapter())
      ..registerAdapter(AppSettingsAdapter());

    await _openBoxSafe<JobSession>(sessionsBoxName);
    await _openBoxSafe<AppSettings>(settingsBoxName);
    await _openBoxSafe<dynamic>(runtimeBoxName);
  }

  // Prevent app startup freeze if local Hive data becomes incompatible.
  static Future<void> _openBoxSafe<T>(String boxName) async {
    try {
      await Hive.openBox<T>(boxName);
    } catch (_) {
      await Hive.deleteBoxFromDisk(boxName);
      await Hive.openBox<T>(boxName);
    }
  }

  static Box<JobSession> get sessionsBox =>
      Hive.box<JobSession>(sessionsBoxName);
  static Box<AppSettings> get settingsBox =>
      Hive.box<AppSettings>(settingsBoxName);
  static Box<dynamic> get runtimeBox => Hive.box<dynamic>(runtimeBoxName);
}

import '../models/app_settings.dart';
import '../models/job_session.dart';
import 'file_service.dart';

class AutoBackupService {
  final FileService _fileService = FileService();

  bool shouldRunDailyBackup(DateTime? lastAutoBackupAt) {
    if (lastAutoBackupAt == null) return true;
    final now = DateTime.now();
    return now.difference(lastAutoBackupAt).inHours >= 24;
  }

  Future<String?> runDailyBackupIfNeeded({
    required List<JobSession> sessions,
    required AppSettings settings,
    required Future<void> Function(DateTime when) onBackupDone,
  }) async {
    if (!shouldRunDailyBackup(settings.lastAutoBackupAt)) return null;
    final path = await _fileService.exportDataToJson(
      sessions: sessions,
      settings: settings,
    );
    await onBackupDone(DateTime.now());
    return path;
  }
}
